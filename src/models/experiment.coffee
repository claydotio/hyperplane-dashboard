Rx = require 'rx-lite'

config = require '../config'

module.exports = class Experiment
  constructor: ({@accessTokenStream, @proxy}) -> null

  getAll: (q) =>
    Rx.Observable.defer =>
      accessToken = @accessTokenStream.getValue()
      @proxy config.HYPERPLANE_API_URL + '/experiments',
        method: 'get'
        qs: if accessToken? then {accessToken} else {}

  create: (body) =>
    accessToken = @accessTokenStream.getValue()
    @proxy config.HYPERPLANE_API_URL + '/experiments',
      method: 'post'
      body: body
      qs: if accessToken? then {accessToken} else {}
      headers:
        'Content-Type': 'text/plain' # Avoid CORS preflight

  deleteById: (id) =>
    accessToken = @accessTokenStream.getValue()
    @proxy config.HYPERPLANE_API_URL + "/experiments/#{id}",
      method: 'delete'
      qs: if accessToken? then {accessToken} else {}
