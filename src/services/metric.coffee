_ = require 'lodash'
Rx = require 'rx-lite'

util = require '../lib/util'

DEFAULT_TIME_RANGE_DAYS = 7

partialWhereFn = (whereFn, where) ->
  return (args...) ->
    result = whereFn args...
    unless where?
      return result

    "#{result} AND #{where}"

dayRangeQuery = (model, {query, fromDay, toDay}) ->
  util.forkJoin _.map(_.range(fromDay, toDay), (day) ->
    model.event.query _.defaults {
      where: query.where(day)
    }, query
  )
  .map (partials) ->
    dates = _.map _.range(fromDay, toDay), (day) ->
      new Date util.dayToMS day
    values = _.map partials, (partial) ->
      if _.isEmpty(partial) or partial.error?
        return null
      partial.series?[0].values[0][1]

    {dates, values}

class MetricService
  query: (model, {metric, where, hasViews, isOnlyToday}) ->
    hasViews ?= true
    isOnlyToday ?= false


    toDay = util.dateToDay new Date()
    fromDay = toDay - DEFAULT_TIME_RANGE_DAYS

    # TODO: this is ugly
    if isOnlyToday
      toDay = util.dateToDay(new Date()) + 1
      fromDay = toDay - 1

    numerator = dayRangeQuery model, {
      fromDay
      toDay
      query:
        select: metric.numerator.select
        from: metric.numerator.from
        where: partialWhereFn metric.numerator.where, where
    }

    denominator = if metric.denominator
      dayRangeQuery model, {
        fromDay
        toDay
        query:
          select: metric.denominator.select
          from: metric.denominator.from
          where: partialWhereFn metric.denominator.where, where
      }
    else
      Rx.Observable.just null

    views = if hasViews
      dayRangeQuery model, {
        fromDay
        toDay
        query:
          select: 'count(distinct(userId))'
          from: 'view'
          where: partialWhereFn (day) ->
            "time >= #{util.dayToMS day}ms AND time < #{util.dayToMS day + 1}ms"
          , where
      }
    else
      Rx.Observable.just null

    util.forkJoin numerator, denominator, views
    .map ([numerator, denominator, views]) ->
      unless numerator
        return null

      dates = numerator.dates
      values = if denominator
        _.zipWith numerator.values, denominator.values, (num, den) ->
          quotient = num / den
          if _.isNaN(quotient) or not _.isFinite(quotient)
            null
          else
            quotient
      else
        numerator.values

      aggregate = _.sum(values) / values.length
      aggregateViews = if hasViews then _.sum(views.values) else null
      return {values, dates, aggregate, aggregateViews}

module.exports = new MetricService()
