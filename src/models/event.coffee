Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'

module.exports = class Event
  constructor: ({@accessTokenStream}) -> null

  query: (q) =>
    request config.HYPERPLANE_API_URL + '/event',
      method: 'get'
      qs:
        q: q
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
