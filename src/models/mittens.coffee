Rx = require 'rx-lite'

config = require '../config'

b64encode = (str) ->
  if window?
    window.btoa str
  else
    new Buffer(str).toString('base64')

# HACK: (any kc access token works)
ACCESS_TOKEN = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJ1c2VySWQiOiJkNTg5NzViZi1lMmUwLTRlNWQtYmRhMi0xZmY4ZTAxOWEyMjAiLCJzY29wZXMiOlsiKiJdLCJpYXQiOjE0NTU4MjQ3MTMsImlzcyI6ImNsYXkiLCJzdWIiOiJkNTg5NzViZi1lMmUwLTRlNWQtYmRhMi0xZmY4ZTAxOWEyMjAifQ.SkEiEk4pqsz42nOEglTIPjcqvFi_k5IRk6NDeJcWC09S7NHvqEPPkocLK1MgKo1JEcAgv-gVXMqJIsgQByjlhA'
PATH = config.MITTENS_API_URL

module.exports = class Mittens
  constructor: ({@accessTokenStream, @netox}) ->
    @auth = "admin:#{config.MITTENS_ADMIN_PASSWORD}"

  getTopSpenders: ({duration}) =>
    @netox.stream PATH + '/adminMetrics/topSpenders',
      qs:
        duration: duration
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getGenericStats: ({date}) =>
    @netox.stream PATH + '/adminMetrics/genericStats',
      qs:
        date: date
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getRevenueGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream PATH + "/adminMetrics/userRevenueGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getChatGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream PATH + "/adminMetrics/userChatGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getTradesGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream PATH + "/adminMetrics/userTradesGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getUserById: (userId) =>
    @netox.stream PATH + "/adminMetrics/users/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"
