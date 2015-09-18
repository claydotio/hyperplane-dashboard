_ = require 'lodash'
Rx = require 'rx-lite'

config = require '../config'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

BATCH_SIZE = 25 # should take 5s based on 200ms (worst case) per query

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where?
    q += " WHERE #{where}"
  if groupBy?
    q += " GROUP BY #{groupBy}"

  return q

module.exports = class Event
  constructor: ({@accessTokenStream, @netox}) ->
    @queryQueue = []
    @batchCache = {}

  getAppNames: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW TAG VALUES FROM view WITH KEY = app'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getTags: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW TAG KEYS FROM view'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getMeasurements: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW MEASUREMENTS'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getTagValues: (tag) =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: "SHOW TAG VALUES FROM view WITH KEY = \"#{tag}\""
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  query: ({select, from, where, groupBy}) =>
    query = queryify {select, from, where, groupBy}

    Rx.Observable.defer =>
      unless window?
        return Rx.Observable.just null

      if _.isEmpty @queryQueue
        setTimeout =>
          @_batchQuery()

      unless @batchCache[query]?
        @batchCache[query] = new Rx.ReplaySubject(1)
        @queryQueue.push query

      return @batchCache[query].switch()

  _batchQuery: =>
    queue = _.take @queryQueue, BATCH_SIZE
    if _.isEmpty queue
      return
    @queryQueue = _.slice @queryQueue, BATCH_SIZE
    queries = queue.join '\n'

    batchStream = @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: queries
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"

    _.map queue, (query, index) =>
      @batchCache[query].onNext batchStream.map (res) ->
        unless res.results
          throw new Error 'Something went wrong...'

        res.results[index]

    shouldFetchMore = not _.isEmpty @queryQueue
    batchStream.take(1).toPromise().then =>
      if shouldFetchMore
        @_batchQuery()
