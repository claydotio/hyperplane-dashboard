_ = require 'lodash'
Rx = require 'rx-lite'

util = require '../lib/util'

ONE_WEEK_DAYS = 7
DEFAULT_TIME_RANGE_DAYS = 14

partialWhereFn = (whereFn, where) ->
  return (args...) ->
    result = whereFn args...
    unless where?
      return result

    "#{result} AND #{where}"

dayRangeQuery = (model, {query, days, shouldStream}) ->
  join = if shouldStream then util.streamJoin else util.forkJoin
  join _.map(days, (day) ->
    model.event.query _.defaults {
      where: query.where(day)
    }, query
  )
  .map (partials) ->
    dates = _.map days, (day) ->
      new Date util.dayToMS day
    values = _.map partials, (partial) ->
      if _.isEmpty(partial) or partial.error?
        return null
      partial.series?[0].values[0][1] or 0

    {dates, values}

class MetricService
  query: (model, {
    metric
    where
    hasViews
    isOnlyToday
    shouldStream
    numDays
  }) ->
    hasViews ?= true
    isOnlyToday ?= false
    shouldStream ?= false
    numDays ?= DEFAULT_TIME_RANGE_DAYS

    toDay = util.dateToDay new Date()
    fromDay = toDay - numDays

    # TODO: this is ugly
    if isOnlyToday
      toDay = util.dateToDay(new Date()) + 1
      fromDay = toDay - 1

    # [fromDay, toDay)
    days = _.range(fromDay, toDay)

    numerator = dayRangeQuery model, {
      shouldStream
      days
      query:
        select: metric.numerator.select
        from: metric.numerator.from
        where: partialWhereFn metric.numerator.where, where
    }

    conversionCount = if not metric.denominator and
        not metric.isGroupSizeDependent
      dayRangeQuery model, {
        shouldStream
        days
        query:
          select: 'count(userId)'
          from: metric.numerator.from
          where: partialWhereFn metric.numerator.where, where
      }
    else
      Rx.Observable.just null

    denominator = if metric.denominator
      dayRangeQuery model, {
        shouldStream
        days
        query:
          select: metric.denominator.select
          from: metric.denominator.from
          where: partialWhereFn metric.denominator.where, where
      }
    else
      Rx.Observable.just null

    views = if hasViews
      dayRangeQuery model, {
        shouldStream
        days
        query:
          select: 'count(distinct(userId))'
          from: 'view'
          where: partialWhereFn (day) ->
            "time >= #{util.dayToMS day}ms AND time < #{util.dayToMS day + 1}ms"
          , where
      }
    else
      Rx.Observable.just null

    util.forkJoin numerator, denominator, views, conversionCount
    .map ([numerator, denominator, views, conversionCount]) ->
      unless numerator
        return null

      dates = numerator.dates
      values = if denominator?
        _.zipWith numerator.values, denominator.values, (num, den) ->
          quotient = num / den
          if _.isNaN(quotient) or not _.isFinite(quotient)
            null
          else
            quotient
      else
        numerator.values

      weights = if denominator?
        _.map denominator.values, (den) ->
          den or 0
      else if metric.isGroupSizeDependent
        _.map numerator.values, -> 1
      else
        _.map conversionCount.values, (conversions) ->
          conversions or 0

      weightedValues = _.zipWith values, weights, (value, weight) ->
        value * weight
      weightedAverage = _.sum(weightedValues) / _.sum(weights)

      weeklyValues = _.chunk(weightedValues, ONE_WEEK_DAYS)
      weeklyWeights = _.chunk(weights, ONE_WEEK_DAYS)
      weeklyChunks = _.zip(weeklyValues, weeklyWeights)

      weeklyAggregates = _.map weeklyChunks, ([vals, weights]) ->
        if _.sum(weights) is 0
          return 0
        _.sum(vals) / _.sum(weights)

      aggregate = if metric.isGroupSizeDependent
        _.sum(values) / values.length
      else
        weightedAverage
      aggregateViews = if hasViews then _.sum(views.values) else null
      averageViews =  if hasViews then aggregateViews / views.values.length \
        else null
      return {
        values
        dates
        aggregate
        aggregateViews
        weeklyAggregates
        averageViews
      }

module.exports = new MetricService()
