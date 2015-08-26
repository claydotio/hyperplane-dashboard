_ = require 'lodash'
Rx = require 'rx-lite'

util = require '../lib/util'

MS_IN_DAY = 1000 * 60 * 60 * 24
DEFAULT_TIME_RANGE_DAYS = 7

dateToDay = (date) ->
  Math.floor(date / 1000 / 60 / 60 / 24)

dayToMS = (day) ->
  timeZoneOffsetMS = (new Date()).getTimezoneOffset() * 60 * 1000
  day * MS_IN_DAY + timeZoneOffsetMS

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where?
    q += " WHERE #{where}"
  if groupBy?
    q += " GROUP BY #{groupBy}"

  return q

partialWhereFn = (whereFn = null, where) ->
  return (args...) ->
    unless whereFn?
      return where

    result = whereFn args...
    unless where?
      return result

    "#{result} AND #{where}"

dayRangeQuery = (model, {query, fromDay, toDay}) ->
  util.forkJoin _.map(_.range(fromDay, toDay), (day) ->
    model.event.query queryify _.defaults {
      where: query.where(day)
    }, query
  )
  .map (partials) ->
    dates = _.map _.range(fromDay, toDay), (day) ->
      new Date dayToMS day
    values = _.map partials, (partial) ->
      if _.isEmpty(partial) or partial.error?
        return null
      partial.series?[0].values[0][1]

    {dates, values}

class MetricService
  query: (model, {metric, where, hasViews}) ->
    hasViews ?= true

    fromDay = dateToDay new Date(
      Date.now() - MS_IN_DAY * DEFAULT_TIME_RANGE_DAYS
    )
    toDay = dateToDay new Date()

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
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
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
          if _.isNaN(quotient)
            null
          else
            quotient
      else
        numerator.values

      aggregate = _.sum(values) / values.length
      aggregateViews = if hasViews then _.sum(views.values) else null
      return {values, dates, aggregate, aggregateViews}

module.exports = new MetricService()
