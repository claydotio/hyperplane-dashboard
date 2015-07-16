Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'

module.exports = class Experiment
  constructor: ({@accessTokenStream}) -> null

  getAll: (q) =>
    Rx.Observable.defer =>
      request config.HYPERPLANE_API_URL + '/experiments',
        method: 'get'
        headers:
          Authorization: "Token #{@accessTokenStream.getValue()}"

  create: (body) =>
    request config.HYPERPLANE_API_URL + '/experiments',
      method: 'post'
      body: body
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"

  deleteById: (id) =>
    request config.HYPERPLANE_API_URL + "/experiments/#{id}",
      method: 'delete'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
