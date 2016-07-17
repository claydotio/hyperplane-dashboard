Rx = require 'rx-lite'

config = require '../config'

b64encode = (str) ->
  if window?
    window.btoa str
  else
    new Buffer(str).toString('base64')

# HACK: (any kc access token works)
ACCESS_TOKEN = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJ1c2VySWQiOiJkNTg5NzViZi1lMmUwLTRlNWQtYmRhMi0xZmY4ZTAxOWEyMjAiLCJzY29wZXMiOlsiKiJdLCJpYXQiOjE0NTU4MjQ3MTMsImlzcyI6ImNsYXkiLCJzdWIiOiJkNTg5NzViZi1lMmUwLTRlNWQtYmRhMi0xZmY4ZTAxOWEyMjAifQ.SkEiEk4pqsz42nOEglTIPjcqvFi_k5IRk6NDeJcWC09S7NHvqEPPkocLK1MgKo1JEcAgv-gVXMqJIsgQByjlhA'
MITTENS_PATH = config.MITTENS_API_URL
PAWS_PATH = config.PAWS_API_URL
DONALD_PATH = config.DONALD_API_URL

module.exports = class TradingCard
  constructor: ({@accessTokenStream, @netox, backend}) ->
    @path = switch backend
      when 'mittens' then MITTENS_PATH
      when 'paws' then PAWS_PATH
      else DONALD_PATH
    pass = switch backend
      when 'mittens' then config.MITTENS_ADMIN_PASSWORD
      when 'paws' then config.PAWS_ADMIN_PASSWORD
      else config.DONALD_ADMIN_PASSWORD

    @auth = "admin:#{pass}"

  getTopSpenders: ({duration}) =>
    @netox.stream @path + '/adminMetrics/topSpenders',
      qs:
        duration: duration
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getGenericStats: ({date}) =>
    @netox.stream @path + '/adminMetrics/genericStats',
      qs:
        date: date
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getRevenueGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream @path + "/adminMetrics/userRevenueGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getChatGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream @path + "/adminMetrics/userChatGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getTradesGraphByUserId: (userId) =>
    console.log 'get'
    @netox.stream @path + "/adminMetrics/userTradesGraph/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getSubmissions: =>
    @netox.stream @path + '/adminSubmissions',
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getSubmissionWinners: =>
    @netox.stream @path + '/adminSubmissionWinners',
      headers:
        Authorization: "Basic #{b64encode @auth}"

  approveSubmission: (submissionId) =>
    @netox.fetch @path + '/adminSubmissions/approve',
      method: 'POST'
      isIdempotent: true
      body: {submissionId}
      headers:
        Authorization: "Basic #{b64encode @auth}"

  rejectSubmission: (submissionId, {reason}) =>
    @netox.fetch @path + '/adminSubmissions/reject',
      method: 'POST'
      isIdempotent: true
      body: {submissionId, reason}
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getUserById: (userId) =>
    @netox.stream @path + "/adminMetrics/users/#{userId}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getUserByUsername: (username) =>
    @netox.stream @path + "/adminMetrics/users/username/#{username}",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  getFlaggedTradesStrByUserId: (userId) =>
    @netox.stream @path + "/adminMetrics/users/#{userId}/flaggedTradesStr",
      headers:
        Authorization: "Basic #{b64encode @auth}"

  giveGoldByUserId: (userId, gold) =>
    @netox.fetch @path + "/adminMetrics/users/#{userId}/giveGold",
      method: 'POST'
      body: {gold}
      headers:
        Authorization: "Basic #{b64encode @auth}"

  giveItemByUserId: (userId, itemId) =>
    @netox.fetch @path + "/adminMetrics/users/#{userId}/giveItem",
      method: 'POST'
      body: {itemId}
      headers:
        Authorization: "Basic #{b64encode @auth}"

  unresetByUserId: (userId) =>
    @netox.fetch @path + "/adminMetrics/users/#{userId}/unreset",
      method: 'PUT'
      headers:
        Authorization: "Basic #{b64encode @auth}"

  unbanByUserId: (userId) =>
    @netox.fetch @path + "/adminMetrics/users/#{userId}/unban",
      method: 'PUT'
      headers:
        Authorization: "Basic #{b64encode @auth}"

  resetPasswordByUserId: (userId) =>
    @netox.fetch @path + "/adminMetrics/users/#{userId}/resetPassword",
      method: 'PUT'
      headers:
        Authorization: "Basic #{b64encode @auth}"
