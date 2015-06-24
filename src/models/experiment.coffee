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
