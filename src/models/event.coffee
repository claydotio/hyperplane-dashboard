_ = require 'lodash'
Rx = require 'rx-lite'

config = require '../config'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where?
    q += " WHERE #{where}"
  if groupBy?
    q += " GROUP BY #{groupBy}"

  return q

module.exports = class Event
  constructor: ({@accessTokenStream, @netox}) -> null

  getAppNames: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW TAG VALUES FROM view WITH KEY = app'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getTags: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW TAG KEYS FROM view'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getMeasurements: =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: 'SHOW MEASUREMENTS'
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  getTagValues: (tag) =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: "SHOW TAG VALUES FROM view WITH KEY = \"#{tag}\""
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      _.flatten res.results[0].series[0].values

  query: ({select, from, where, groupBy}) =>
    @netox.stream config.HYPERPLANE_API_URL + '/events',
      method: 'post'
      body:
        q: queryify {select, from, where, groupBy}
      headers:
        Authorization: "Token #{@accessTokenStream.getValue()}"
    .map (res) ->
      unless res.results
        throw new Error 'Something went wrong...'

      res.results[0]
