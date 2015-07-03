z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Chart = require '../chart'

if window?
  require './index.styl'

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"

  if where
    q += " WHERE #{where}"

  if groupBy
    q += " GROUP BY #{groupBy}"

  return q

module.exports = class Metrics
  constructor: ({model}) ->
    namespaces = model.event.query 'SHOW MEASUREMENTS'
    .map (result) ->
      _.flatten result.series[0].values

    metrics = Rx.Observable.just [{
      name: 'gameplays / view'
      numerator:
        select: 'count(value)'
        where: 'event=\'gameplay\''
      denominator:
        select: 'count(value)'
        where: 'event=\'view\''
    }]

    data = metrics.flatMapLatest (metrics) ->
      metrics = _.map metrics, (metric) ->
        namespaces.flatMapLatest (namespaces) ->
          numerators = Rx.Observable.combineLatest \
          _.map(namespaces, (namespace) ->
            {select, where} = metric.numerator

            model.event.query queryify {
              select
              from: namespace
              where: "#{where} AND time > now() - 7d"
              groupBy: 'time(1d)'
            }
          ), (results...) -> results

          denominators = Rx.Observable.combineLatest \
          _.map(namespaces, (namespace) ->
            {select, where} = metric.denominator

            model.event.query queryify {
              select
              from: namespace
              where: "#{where} AND time > now() - 7d"
              groupBy: 'time(1d)'
            }
          ), (results...) -> results

          Rx.Observable.combineLatest numerators, denominators,
            (results...) -> results
          .map ([numerators, denominators]) ->
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            _.map numerators, (result) ->
              data.addColumn 'number', result.series[0].name

            dates = _.map numerators[0].series[0].values, ([date, count]) ->
              new Date date

            values = _.map numerators, (result, resultIndex) ->
              _.map result.series[0].values, ([date, count], valueIndex) ->
                denominatorCount = denominators[resultIndex]
                  .series[0].values[valueIndex][1]
                count / denominatorCount

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
      Rx.Observable.combineLatest metrics, (results...) -> results

    @state = z.state
      data: data

  render: =>
    {data} = @state.getValue()

    z '.z-metrics',
      _.map data, ({metric, $chart}) ->
        z '.metric',
          $chart
