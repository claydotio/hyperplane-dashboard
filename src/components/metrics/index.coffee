z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Chart = require '../chart'

if window?
  require './index.styl'

MS_IN_DAY = 1000 * 60 * 60 * 24

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where
    q += " WHERE #{where}"
  if groupBy
    q += " GROUP BY #{groupBy}"

  return q

dateToDay = (date) ->
  Math.floor(date / 1000 / 60 / 60 / 24)

forkJoin = (observables...) ->
  Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

module.exports = class Metrics
  constructor: ({model}) ->
    namespaces = model.event.query 'SHOW MEASUREMENTS'
    .map (result) ->
      _.flatten result.series[0].values

    metrics = Rx.Observable.just [
      {
        name: 'egp / view'
        numerator:
          select: 'count(value)'
          where: 'event=\'egp\''
        denominator:
          select: 'count(value)'
          where: 'event=\'view\''
      }
      {
        name: 'DAU'
        numerator:
          select: 'count(distinct(userId))'
          where: 'event=\'view\''
      }
      {
        name: 'Revenue'
        numerator:
          select: 'count(value)'
          where: 'event=\'revenue\''
      }
      {
        name: 'D1 Retention'
        isRunningAverage: true
        numerator:
          select: 'count(distinct(userId))'
          where: (date) ->
            day = dateToDay date
            "event=\'view\' AND " +
            "time >= #{day}d AND time < #{day + 1}d AND " +
            "joinDay = '#{day - 1}'"
        denominator:
          select: 'count(distinct(userId))'
          where: (date) ->
            day = dateToDay date
            "event=\'view\' AND " +
            "time >= #{day - 1}d AND time < #{day}d AND " +
            "joinDay = '#{day - 1}'"
      }
      {
        name: '3d LTV'
        isRunningAverage: true
        numerator:
          select: 'sum(value)'
          where: (date) ->
            day = dateToDay date
            "event=\'revenue\' AND " +
            "time >= #{day - 3}d AND time < #{day + 1}d AND " +
            "joinDay = '#{day - 3}'"
      }
      {
        name: '2d SPS'
        isRunningAverage: true
        numerator:
          select: 'count(value)'
          where: (date) ->
            day = dateToDay date
            "event=\'send\' AND " +
            "time >= #{day - 2}d AND time < #{day + 1}d AND " +
            "joinDay = '#{day - 2}'"
        denominator:
          select: 'count(distinct(userId))'
          where: (date) ->
            day = dateToDay date
            "event=\'send\' AND " +
            "time >= #{day - 2}d AND time < #{day - 1}d AND " +
            "joinDay = '#{day - 2}'"
      }
      {
        name: '3d k-factor'
        isRunningAverage: true
        numerator:
          select: 'count(value)'
          where: (date) ->
            day = dateToDay date
            "event=\'join\' AND " +
            "time >= #{day - 3}d AND time < #{day + 1}d AND " +
            "inviterJoinDay = '#{day - 3}'"
        denominator:
          select: 'count(value)'
          where: (date) ->
            day = dateToDay date
            "event=\'join\' AND " +
            "time >= #{day - 3}d AND time < #{day - 2}d"
      }
      {
        name: 'session length (ms)'
        numerator:
          select: 'sum(value)'
          where: 'event=\'session\''
        denominator:
          select: 'count(distinct(sessionId))'
          where: 'event=\'session\''
      }
      {
        name: 'pages / session'
        numerator:
          select: 'count(value)'
          where: 'event=\'pageview\''
        denominator:
          select: 'count(distinct(sessionId))'
          where: 'event=\'pageview\''
      }
      {
        name: 'un-bounce rate'
        numerator:
          select: 'count(distinct(sessionId))'
          where: 'event=\'session\' AND sessionEvents=\'1\''
        denominator:
          select: 'count(distinct(sessionId))'
          where: 'event=\'session\''
      }
    ].reverse()

    metricQuery = ({namespace, query, isRunningAverage}) ->
      if isRunningAverage
        forkJoin _.map(_.range(7), (day) ->
          model.event.query queryify {
            select: query.select
            from: namespace
            where: query.where Date.now() - MS_IN_DAY * day
          }
        )
        .map (partials) ->
          dates = _.map _.range(7), (day) ->
            Date.now() - MS_IN_DAY * day
          values = _.map partials, (partial) ->
            partial.series?[0].values[0][1]

          {dates, values}

      else
        model.event.query queryify {
          select: query.select
          from: namespace
          where: "#{query.where} AND time >= now() - 7d"
          groupBy: 'time(1d)'
        }
        .map (query) ->
          [dates, values] = _.zip query.series?[0].values...
          {dates, values}

    metricResults = (metric, namespace) ->
      numerator = metricQuery {
        namespace
        query: metric.numerator
        isRunningAverage: metric.isRunningAverage
      }

      denominator = if metric.denominator
        metricQuery {
          namespace
          query: metric.denominator
          isRunningAverage: metric.isRunningAverage
        }
      else
        Rx.Observable.just null

      forkJoin numerator, denominator
      .map ([numerator, denominator]) ->
        dates = numerator.dates
        values = if denominator
          _.zipWith numerator.values, denominator.values, (num, den) ->
            num / den
        else
          numerator.values

        return {values, dates}

    chartedMetrics = forkJoin [metrics, namespaces]
      .flatMapLatest ([metrics, namespaces]) ->
        forkJoin _.map metrics, (metric) ->
          forkJoin _.map namespaces, (namespace) ->
            metricResults metric, namespace
          .map (series) ->
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            _.map namespaces, (result) ->
              data.addColumn 'number', namespaces

            values = _.pluck series, 'values'
            dates = _.map series[0].dates, (date) -> new Date date

            data.addRows _.zip [dates].concat(values)...

            {
              metric
              $chart: new Chart({
                data: data
                options: {
                  tooltip: {isHtml: true}
                  chart: {
                    title: metric.name
                  }
                  height: 500
                }
              })
            }

    @state = z.state
      chartedMetrics: chartedMetrics

  render: =>
    {chartedMetrics} = @state.getValue()

    z '.z-metrics',
      _.map chartedMetrics, ({metric, $chart}) ->
        z '.metric',
          $chart
