Rx = require 'rx-lite'

config = require '../config'

module.exports = class Experiment
  constructor: ({@accessTokenStream, @proxy}) -> null

  getAll: (q) =>
    Rx.Observable.defer =>
      @proxy config.HYPERPLANE_API_URL + '/experiments',
        method: 'get'
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"

  create: (body) =>
    @proxy config.HYPERPLANE_API_URL + '/experiments',
      method: 'post'
      body: body
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"

  deleteById: (id) =>
    @proxy config.HYPERPLANE_API_URL + "/experiments/#{id}",
      method: 'delete'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
