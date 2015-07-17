_ = require 'lodash'
Rx = require 'rx-lite'

util = require '../lib/util'

MS_IN_DAY = 1000 * 60 * 60 * 24

dateToDay = (date) ->
  Math.floor(date / 1000 / 60 / 60 / 24)

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where
    q += " WHERE #{where}"
  if groupBy
    q += " GROUP BY #{groupBy}"

  return q

partialWhereFn = (whereFn = null, where) ->
  return (args...) ->
    unless whereFn
      return where

    result = whereFn args...
    unless where
      return result

    "#{result} AND #{where}"

singleQuery = (model, {query, fromDay, toDay}) ->
  hasWhere = Boolean query.where()
  where = "#{if hasWhere then query.where() + ' AND ' else ''}" +
          "time >= #{fromDay}d AND time < #{toDay + 1}d"
  model.event.query queryify _.defaults {
    where: where
  }, query
  .map (query) ->
    if _.isEmpty(query) or query.error?
      return null
    [dates, values] = _.zip query.series?[0].values...
    dates = _.map dates, (date) -> new Date date
    {dates, values}

runningAverageQuery = (model, {query, fromDay, toDay}) ->
  util.forkJoin _.map(_.range(toDay - fromDay), (day) ->
    model.event.query queryify _.defaults {
      where: query.where toDay - day
    }, query
  )
  .map (partials) ->
    dates = _.map _.range(toDay - fromDay), (day) ->
      new Date Date.now() - MS_IN_DAY * day
    values = _.map partials, (partial) ->
      if _.isEmpty(partial) or partial.error?
        return null
      partial.series?[0].values[0][1]

    {dates, values}

class MetricService
  # FIXME: cyclomatic complexity
  query: (model, {metric, where}) ->
    # FIXME: magic number 7
    fromDay = dateToDay new Date Date.now() - MS_IN_DAY * 7
    toDay = dateToDay new Date()
    numeratorQuery = {
      select: metric.numerator.select
      from: metric.numerator.from
      where: partialWhereFn metric.numerator.where, where
      groupBy: if metric.isRunningAverage then null else 'time(1d)'
    }

    denominatorQuery = if metric.denominator
      {
        select: metric.denominator.select
        from: metric.denominator.from
        where: partialWhereFn metric.denominator.where, where
        groupBy: if metric.isRunningAverage then null else 'time(1d)'
      }
    else
      null

    viewsQuery =
      select: 'count(distinct(userId))'
      from: 'view'
      where: -> where or ''

    numerator = if metric.isRunningAverage
      runningAverageQuery model, {fromDay, toDay, query: numeratorQuery}
    else
      singleQuery model, {fromDay, toDay, query: numeratorQuery}

    denominator = if denominatorQuery
      if metric.isRunningAverage
        runningAverageQuery model, {fromDay, toDay, query: denominatorQuery}
      else
        singleQuery model, {fromDay, toDay, query: denominatorQuery}
    else
      Rx.Observable.just null

    views = if metric.isRunningAverage
      runningAverageQuery model, {fromDay, toDay, query: viewsQuery}
    else
      singleQuery model, {fromDay, toDay, query: viewsQuery}

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
      aggregateViews = _.sum(views)

      return {values, dates, aggregate, aggregateViews}

module.exports = new MetricService()
