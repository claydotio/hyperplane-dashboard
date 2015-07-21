Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'

module.exports = class Event
  constructor: ({@accessTokenStream}) ->
    @queryQueue = []

  query: (q) =>
    Rx.Observable.defer =>
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
        q: q
        deferred:
          resolve: resolver
          reject: rejecter
          promise: promise
      }

      return promise

  _batchQuery: (queue) =>
    q = _.pluck(queue, 'q').join '\n'

    request config.HYPERPLANE_API_URL + '/events',
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
