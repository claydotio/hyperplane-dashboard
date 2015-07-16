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
    metrics = model.metric.getAll()

    chartedMetrics = metrics
      .flatMapLatest (metrics) ->
        util.forkJoin _.map metrics, (metric) ->
          MetricService.query model, {metric}
          .map ({values, dates} = {}) ->
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            data.addColumn 'number', metric.name

            data.addRows _.zip dates, values

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
