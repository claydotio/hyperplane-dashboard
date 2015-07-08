z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Chart = require '../chart'
MetricService = require '../../services/metric'
util = require '../../lib/util'

if window?
  require './index.styl'

module.exports = class Metrics
  constructor: ({model}) ->
    namespaces = model.event.query 'SHOW MEASUREMENTS'
    .map (result) ->
      _.flatten result.series[0].values

    metrics = model.metric.getAll()

    chartedMetrics = util.forkJoin [metrics, namespaces]
      .flatMapLatest ([metrics, namespaces]) ->
        util.forkJoin _.map metrics, (metric) ->
          util.forkJoin _.map namespaces, (namespace) ->
            MetricService.query model, {metric, namespace, groupBy: 'time(1d)'}
          .map (series) ->
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            _.map namespaces, (result) ->
              data.addColumn 'number', namespaces

            values = _.pluck series, 'values'
            dates = series[0].dates

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
