_ = require 'lodash'
Rx = require 'rx-lite'
request = require 'clay-request'

config = require '../config'
util = require '../lib/util'

dayToMS = util.dayToMS

metrics = [

  {
    name: 'chat messages'
    apps: ['clay-bot']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'SPS per day'
    apps: ['clay-bot']
    isRunningAverage: true
    numerator:
      select: 'count(userId)'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day }ms AND time < #{dayToMS day + 1}ms"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: '1st day SPS'
    apps: ['clay-bot']
    isRunningAverage: true
    numerator:
      select: 'count(userId)'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 1}ms AND time < #{dayToMS day}ms AND " +
        "joinDay = '#{day - 1}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 1}ms AND time < #{dayToMS day}ms AND " +
        "joinDay = '#{day - 1}'"
  }
  {
    name: '2nd day SPS'
    apps: ['clay-bot']
    isRunningAverage: true
    numerator:
      select: 'count(userId)'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 2}ms AND time < #{dayToMS day - 1}ms AND " +
        "joinDay = '#{day - 2}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 2}ms AND time < #{dayToMS day - 1}ms AND " +
        "joinDay = '#{day - 2}'"
  }
  {
    name: '5th day SPS'
    apps: ['clay-bot']
    isRunningAverage: true
    numerator:
      select: 'count(userId)'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 5}ms AND time < #{dayToMS day - 4}ms AND " +
        "joinDay = '#{day - 5}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 5}ms AND time < #{dayToMS day - 4}ms AND " +
        "joinDay = '#{day - 5}'"
  }
  {
    name: 'chat games'
    apps: [
      'indecency', 'nhtd', 'doodleDraw', 'trivia', 'hangman', 'tic-tac-toe'
      'frotz'
    ]
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'gameCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'chat game rounds'
    apps: [
      'indecency', 'nhtd', 'doodleDraw', 'trivia', 'hangman', 'tic-tac-toe'
      'frotz'
    ]
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'gameRoundCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'chat game complete'
    apps: ['nhtd']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'gameComplete'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }

  {
    name: 'D1 Retention'
    apps: ['clay-bot']
    format: '0.00%'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 1}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 1}ms AND time < #{dayToMS day}ms AND " +
        "joinDay = '#{day - 1}'"
  }
  {
    name: 'D3 Retention'
    apps: ['clay-bot']
    format: '0.00%'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 3}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 3}ms AND time < #{dayToMS day - 2}ms AND " +
        "joinDay = '#{day - 3}'"
  }
  {
    name: 'D7 Retention'
    apps: ['clay-bot']
    format: '0.00%'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 7}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'chatMessageCreate'
      where: (day) ->
        "time >= #{dayToMS day - 7}ms AND time < #{dayToMS day - 6}ms AND " +
        "joinDay = '#{day - 7}'"
  }


  {
    name: 'Revenue (USD)'
    apps: ['kitten-cards', 'puppy-cards']
    format: '$0.00'
    isGroupSizeDependent: true
    numerator:
      select: 'sum(value) / 100'
      from: 'revenue'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'ARPDAU (USD)'
    apps: ['kitten-cards', 'puppy-cards']
    format: '$0.000'
    isGroupSizeDependent: true
    numerator:
      select: 'sum(value) / 100'
      from: 'revenue'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: '7d LTV (USD)'
    apps: ['kitten-cards', 'puppy-cards']
    format: '$0.000'
    isGroupSizeDependent: true
    numerator:
      select: 'sum(value) / 100'
      from: 'revenue'
      where: (day) ->
        "time >= #{dayToMS day - 6}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 6}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'join'
      where: (day) ->
        "time >= #{dayToMS day - 6}ms AND time < #{dayToMS day - 5}ms"
  }
  # TODO: enable once database can handle it
  # {
  #   name: 'session length (min) / session'
  #   format: '0.00'
  #   numerator:
  #     select: 'sum(value) / 1000 / 60'
  #     from: 'session'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  #   denominator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'session'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  # {
  #   name: 'Retained DAU %'
  #   format: '0.00%'
  #   isPercent: true
  #   numerator:
  #     select: 'count(distinct(userId))'
  #     from: 'view'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
  #       "joinDay <> '#{day}'"
  #   denominator:
  #     select: 'count(distinct(userId))'
  #     from: 'view'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  {
    name: 'DAU'
    apps: ['kitten-cards', 'puppy-cards', 'clay']
    format: '0'
    isExperimentHidden: true
    isGroupSizeDependent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'D1 Retention'
    apps: ['kitten-cards', 'puppy-cards', 'clay']
    format: '0.00%'
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
    name: 'D7 Retention'
    apps: ['kitten-cards', 'puppy-cards', 'clay']
    format: '0.00%'
    isPercent: true
    numerator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
        "joinDay = '#{day - 7}'"
    denominator:
      select: 'count(distinct(userId))'
      from: 'view'
      where: (day) ->
        "time >= #{dayToMS day - 7}ms AND time < #{dayToMS day - 6}ms AND " +
        "joinDay = '#{day - 7}'"
  }
  {
    name: 'shares / DAU'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0.00'
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
    name: 'open pack'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'openPack'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'claim reward'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'claimReward'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'create trade'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'createTrade'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'complete trade'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'completeTrade'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'decline trade'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'declineTrade'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  {
    name: 'share'
    apps: ['kitten-cards', 'puppy-cards']
    format: '0'
    isGroupSizeDependent: true
    numerator:
      select: 'count(userId)'
      from: 'share'
      where: (day) ->
        "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  }
  # {
  #   name: 'request time 95% (ms)'
  #   apps: ['kitten-cards', 'puppy-cards']
  #   format: '0'
  #   isExperimentHidden: true
  #   numerator:
  #     select: 'percentile(value, 95)'
  #     from: 'requestTime'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  # {
  #   name: 'un-bounce rate'
  #   apps: ['kitten-cards', 'puppy-cards']
  #   format: '0.00%'
  #   isExperimentHidden: true
  #   isPercent: true
  #   numerator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'session'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
  #       "sessionEvents = '2'"
  #   denominator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'session'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms AND " +
  #       "sessionEvents = '1'"
  # }
  # {
  #   name: 'sessions / DAU'
  #   format: '0.00'
  #   numerator:
  #     select: 'count(distinct(sessionId))'
  #     from: 'view'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  #   denominator:
  #     select: 'count(distinct(userId))'
  #     from: 'view'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  # {
  #   name: 'nps'
  #   format: '0.00'
  #   numerator:
  #     select: 'mean(value)'
  #     from: 'nps'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
  # {
  #   name: 'interstitial impression'
  #   format: '0'
  #   isGroupSizeDependent: true
  #   numerator:
  #     select: 'count(userId)'
  #     from: 'interstitialImpression'
  #     where: (day) ->
  #       "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
  # }
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
