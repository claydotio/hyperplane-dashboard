Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'

module.exports = class Event
  constructor: ({@accessTokenStream}) -> null

  query: (q) =>
    Rx.Observable.defer =>
      request config.HYPERPLANE_API_URL + '/events',
        method: 'get'
        qs:
          q: q
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"
      .then (res) ->
        unless res.results
          throw new Error 'Something went wrong...'

        res.results[0]
