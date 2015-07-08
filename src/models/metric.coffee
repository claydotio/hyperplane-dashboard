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
            where: -> 'event=\'view\''
        }
        {
          name: 'egp / view'
          numerator:
            select: 'count(value)'
            where: -> 'event=\'egp\''
          denominator:
            select: 'count(value)'
            where: -> 'event=\'view\''
        }
        {
          name: 'Revenue'
          numerator:
            select: 'count(value)'
            where: -> 'event=\'revenue\''
        }
        {
          name: 'D1 Retention'
          isRunningAverage: true
          numerator:
            select: 'count(distinct(userId))'
            where: (day) ->
              "event=\'view\' AND " +
              "time >= #{day}d AND time < #{day + 1}d AND " +
              "joinDay = '#{day - 1}'"
          denominator:
            select: 'count(distinct(userId))'
            where: (day) ->
              "event=\'view\' AND " +
              "time >= #{day - 1}d AND time < #{day}d AND " +
              "joinDay = '#{day - 1}'"
        }
        {
          name: '3d LTV'
          isRunningAverage: true
          numerator:
            select: 'sum(value)'
            where: (day) ->
              "event=\'revenue\' AND " +
              "time >= #{day - 3}d AND time < #{day}d AND " +
              "joinDay = '#{day - 3}'"
        }
        {
          name: '2d SPS'
          isRunningAverage: true
          numerator:
            select: 'count(value)'
            where: (day) ->
              "event=\'send\' AND " +
              "time >= #{day - 2}d AND time < #{day}d AND " +
              "joinDay = '#{day - 2}'"
          denominator:
            select: 'count(distinct(userId))'
            where: (day) ->
              "event=\'send\' AND " +
              "time >= #{day - 2}d AND time < #{day - 1}d AND " +
              "joinDay = '#{day - 2}'"
        }
        {
          name: '3d k-factor'
          isRunningAverage: true
          numerator:
            select: 'count(value)'
            where: (day) ->
              "event=\'join\' AND " +
              "time >= #{day - 3}d AND time < #{day}d AND " +
              "inviterJoinDay = '#{day - 3}'"
          denominator:
            select: 'count(value)'
            where: (day) ->
              "event=\'join\' AND " +
              "time >= #{day - 3}d AND time < #{day - 2}d"
        }
        {
          name: 'session length (ms)'
          numerator:
            select: 'sum(value)'
            where: -> 'event=\'session\''
          denominator:
            select: 'count(distinct(sessionId))'
            where: -> 'event=\'session\''
        }
        {
          name: 'pages / session'
          numerator:
            select: 'count(value)'
            where: -> 'event=\'pageview\''
          denominator:
            select: 'count(distinct(sessionId))'
            where: -> 'event=\'pageview\''
        }
        {
          name: 'un-bounce rate'
          numerator:
            select: 'count(distinct(sessionId))'
            where: -> 'event=\'session\' AND sessionEvents=\'1\''
          denominator:
            select: 'count(distinct(sessionId))'
            where: -> 'event=\'session\''
        }
      ]
