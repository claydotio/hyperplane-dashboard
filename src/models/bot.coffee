Rx = require 'rx-lite'

config = require '../config'

PATH = config.PULSAR_API_URL
AUTH = "admin:#{config.PULSAR_ADMIN_PASSWORD}"

b64encode = (str) ->
  if window?
    window.btoa str
  else
    new Buffer(str).toString('base64')

module.exports = class Bot
  constructor: ({@accessTokenStream, @netox}) -> null

  getStats: =>
    @netox.stream PATH + '/adminMetrics/stats',
      headers:
        Authorization: "Basic #{b64encode AUTH}"

  getMessagesByChatId: (chatId) =>
    @netox.stream PATH + '/adminMetrics/messages',
      qs:
        chatId: chatId
      headers:
        Authorization: "Basic #{b64encode AUTH}"

  getUserById: (id) =>
    @netox.stream PATH + "/adminMetrics/user/#{id}",
      headers:
        Authorization: "Basic #{b64encode AUTH}"
