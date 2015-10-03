_ = require 'lodash'
Rx = require 'rx-lite'
log = require 'loglevel'

config = require '../config'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

BATCH_POLL_DELAY_MS = 10000 # 10s

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

      _.flatten res.results[0].series?[0].values

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

      _.flatten res.results[0].series?[0].values

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

      _.flatten res.results[0].series?[0].values

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

      _.flatten res.results[0].series?[0].values

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
    queue = @queryQueue
    if _.isEmpty queue
      return
    @queryQueue = []

    accessToken = @accessTokenStream.getValue()
    @netox.fetch config.HYPERPLANE_API_URL + '/events/_batch',
      method: 'post'
      body:
        queries: queue
      qs: if accessToken? then {accessToken} else {}
      headers:
        # Avoid CORS preflight
        'Content-Type': 'text/plain'
      isIdempotent: true
    .then (res) =>
      pending = _.filter res.results, 'isPending'
      resolved = _.filter res.results, ({isPending}) -> not isPending

      _.map resolved, ({response, query}) =>
        @batchCache[query].onNext \
          Rx.Observable.just response.results[0]

      # re-fetch
      log.info {
        event: 'batch'
        resolved: resolved.length
        pending: pending.length
      }
      @queryQueue = @queryQueue.concat _.pluck pending, 'query'
      shouldFetchMore = not _.isEmpty @queryQueue
      if shouldFetchMore
        setTimeout =>
          @_batchQuery()
        , BATCH_POLL_DELAY_MS
