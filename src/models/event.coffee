_ = require 'lodash'
Rx = require 'rx-lite'

config = require '../config'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where?
    q += " WHERE #{where}"
  if groupBy?
    q += " GROUP BY #{groupBy}"

  return q

module.exports = class Event
  constructor: ({@accessTokenStream, @proxy}) ->
    @queryQueue = []

  getAppNames: =>
    Rx.Observable.defer =>
      @proxy config.HYPERPLANE_API_URL + '/events',
        proxyCache: true
        method: 'post'
        body:
          q: 'SHOW TAG VALUES FROM view WITH KEY = app'
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"
      .then (res) ->
        unless res.results
          throw new Error 'Something went wrong...'

        _.flatten res.results[0].series[0].values

  getTags: =>
    Rx.Observable.defer =>
      @proxy config.HYPERPLANE_API_URL + '/events',
        proxyCache: true
        method: 'post'
        body:
          q: 'SHOW TAG KEYS FROM view'
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"
      .then (res) ->
        unless res.results
          throw new Error 'Something went wrong...'

        _.flatten res.results[0].series[0].values

  getTagValues: (tag) =>
    Rx.Observable.defer =>
      @proxy config.HYPERPLANE_API_URL + '/events',
        proxyCache: true
        method: 'post'
        body:
          q: "SHOW TAG VALUES FROM view WITH KEY = '#{tag}'"
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"
      .then (res) ->
        unless res.results
          throw new Error 'Something went wrong...'

        _.flatten res.results[0].series[0].values

  query: ({select, from, where, groupBy}) =>
    Rx.Observable.defer =>
      unless window?
        return Rx.Observable.just null
      if _.isEmpty @queryQueue
        setTimeout =>
          @_batchQuery(@queryQueue)
          @queryQueue = []

      resolver = null
      rejecter = null
      promise = new Promise (resolve, reject) ->
        resolver = resolve
        rejecter = reject

      @queryQueue.push {
        q: queryify {select, from, where, groupBy}
        deferred:
          resolve: resolver
          reject: rejecter
          promise: promise
      }

      return promise

  _batchQuery: (queue) =>
    q = _.pluck(queue, 'q').join '\n'

    @proxy config.HYPERPLANE_API_URL + '/events',
      proxyCache: true
      method: 'post'
      body:
        q: q
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .then (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.map queue, (queued, index) ->
        queued.deferred.resolve res.results[index]

    .catch (err) ->
      _.map queue, (queued) ->
        queued.deferred.reject err
