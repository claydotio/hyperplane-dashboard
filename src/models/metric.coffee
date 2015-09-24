_ = require 'lodash'
Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'
util = require '../lib/util'

dayToMS = util.dayToMS

metrics = [
  {
    name: 'Revenue (USD)'
    numerator:
      select: 'sum(value) / 100'
      from: 'revenue'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'Retained DAU %'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay <> '#{day}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'DAU'
    isGroupSizeDependent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'D1 Retention'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 1}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day - 1}ms AND time < #{dayToMS day}ms AND " +
        "joinDay = '#{day - 1}'"
  }
  {
    name: 'sessions / DAU'
    numerator:
      select: 'count(distinct(sessionId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'shares / DAU'
    numerator:
      select: 'count(userId)'
      from: 'share, botShare'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'nps'
    numerator:
      select: 'mean(value)'
      from: 'nps'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'un-bounce rate'
    isPercent: true
    numerator:
      select: 'count(distinct(sessionId))'
      from: 'session'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "sessionEvents = '2'"
    denominator:
      select: 'count(distinct(sessionId))'
      from: 'session'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "sessionEvents = '1'"
  }
  # {
  #   name: 'egp / view'
  #   numerator:
  #     select: 'count(userId)'
  #     from: 'egp'
  #   denominator:
  #     select: 'count(userId)'
  #     from: 'view'
  # }
  # {
  #   name: 'Revenue / User'
  #   numerator:
  #     select: 'sum(value)'
  #     from: 'revenue'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  #   denominator:
  #     select: 'count(distinct(userId))'
  #     from: 'revenue'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  # {
  #   name: '3d LTV'
  #   isRunningAverage: true
  #   numerator:
  #     select: 'sum(value)'
  #     from: 'revenue'
  #     where: (day) ->
  #       "time >= #{day - 2}d AND time < #{day + 1}d AND " +
  #       "joinDay = '#{day - 2}'"
  # }
  # {
  #   name: '2d SPS'
  #   isRunningAverage: true
  #   numerator:
  #     select: 'count(userId)'
  #     from: 'send'
  #     where: (day) ->
  #       "time >= #{day - 1}d AND time < #{day + 1}d AND " +
  #       "joinDay = '#{day - 1}'"
  #   denominator:
  #     select: 'count(distinct(userId))'
  #     from: 'send'
  #     where: (day) ->
  #       "time >= #{day - 1}d AND time < #{day}d AND " +
  #       "joinDay = '#{day - 1}'"
  # }
  # {
  #   name: '3d k-factor'
  #   isRunningAverage: true
  #   numerator:
  #     select: 'count(userId)'
  #     from: 'join'
  #     where: (day) ->
  #       "time >= #{day - 2}d AND time < #{day + 1}d AND " +
  #       "inviterJoinDay = '#{day - 2}'"
  #   denominator:
  #     select: 'count(userId)'
  #     from: 'join'
  #     where: (day) ->
  #       "time >= #{day - 2}d AND time < #{day - 1}d"
  # }
  # {
  #   name: 'session length (ms)'
  #   numerator:
  #     select: 'sum(value)'
  #     from: 'session'
  #   denominator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'session'
  # }
  # {
  #   name: 'pages / session'
  #   numerator:
  #     select: 'count(userId)'
  #     from: 'pageview'
  #   denominator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'pageview'
  # }
]

module.exports = class Metric
  # FIXME: shouldn't depend on event
  constructor: ({@accessTokenStream, @event}) -> null

  getAll: =>
    @event.getMeasurements()
    .map (measurements) ->
      _.filter metrics, (metric) ->
        froms = _.filter([
          metric.numerator.from, metric.denominator?.from
        ])
        .join(',')
        .split(',')

        isMissingMeasurement = _.some froms, (from) ->
          not _.includes measurements, from

        return not isMissingMeasurement
