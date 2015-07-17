Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'

module.exports = class Metric
  constructor: ({@accessTokenStream}) -> null

  getAll: ->
    Rx.Observable.just \
      [
        {
          name: 'DAU'
          numerator:
            select: 'count(distinct(userId))'
            from: 'view'
        }
        {
          name: 'egp / view'
          numerator:
            select: 'count(userId)'
            from: 'egp'
          denominator:
            select: 'count(userId)'
            from: 'view'
        }
        {
          name: 'Revenue / User'
          numerator:
            select: 'sum(value)'
            from: 'revenue'
          denominator:
            select: 'count(distinct(userId))'
            from: 'revenue'
        }
        {
          name: 'D1 Retention'
          isRunningAverage: true
          numerator:
            select: 'count(distinct(userId))'
            from: 'view'
            where: (day) ->
              "time >= #{day}d AND time < #{day + 1}d AND " +
              "joinDay = '#{day - 1}'"
          denominator:
            select: 'count(distinct(userId))'
            from: 'view'
            where: (day) ->
              "time >= #{day - 1}d AND time < #{day}d AND " +
              "joinDay = '#{day - 1}'"
        }
        {
          name: '3d LTV'
          isRunningAverage: true
          numerator:
            select: 'sum(value)'
            from: 'revenue'
            where: (day) ->
              "time >= #{day - 2}d AND time < #{day + 1}d AND " +
              "joinDay = '#{day - 2}'"
        }
        {
          name: '2d SPS'
          isRunningAverage: true
          numerator:
            select: 'count(userId)'
            from: 'send'
            where: (day) ->
              "time >= #{day - 1}d AND time < #{day + 1}d AND " +
              "joinDay = '#{day - 1}'"
          denominator:
            select: 'count(distinct(userId))'
            from: 'send'
            where: (day) ->
              "time >= #{day - 1}d AND time < #{day}d AND " +
              "joinDay = '#{day - 1}'"
        }
        {
          name: '3d k-factor'
          isRunningAverage: true
          numerator:
            select: 'count(userId)'
            from: 'join'
            where: (day) ->
              "time >= #{day - 2}d AND time < #{day + 1}d AND " +
              "inviterJoinDay = '#{day - 2}'"
          denominator:
            select: 'count(userId)'
            from: 'join'
            where: (day) ->
              "time >= #{day - 2}d AND time < #{day - 1}d"
        }
        {
          name: 'session length (ms)'
          numerator:
            select: 'sum(value)'
            from: 'session'
          denominator:
            select: 'count(distinct(sessionId))'
            from: 'session'
        }
        {
          name: 'pages / session'
          numerator:
            select: 'count(userId)'
            from: 'pageview'
          denominator:
            select: 'count(distinct(sessionId))'
            from: 'pageview'
        }
        {
          name: 'un-bounce rate'
          numerator:
            select: 'count(distinct(sessionId))'
            from: 'session'
            where: -> 'sessionEvents=\'1\''
          denominator:
            select: 'count(distinct(sessionId))'
            from: 'session'
        }
      ]
