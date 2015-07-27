Rx = require 'rx-lite'

config = require '../config'

b64encode = (str) ->
  if window?
    window.btoa str
  else
    new Buffer(str).toString('base64')

module.exports = class User
  constructor: ({@accessTokenStream, @proxy}) -> null

  getMe: =>
    auth = "admin:#{config.HYPERPLANE_ADMIN_PASSWORD}"

    Rx.Observable.defer =>
      @proxy config.HYPERPLANE_API_URL + '/users',
        method: 'post'
        headers:
          Authorization: "Basic #{b64encode auth}"

  create: =>
    @proxy config.HYPERPLANE_API_URL + '/users',
      method: 'post'
