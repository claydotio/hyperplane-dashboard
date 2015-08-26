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
    appNames = model.event.getAppNames()

    chartedMetrics = util.forkJoin [metrics, appNames]
      .flatMapLatest ([metrics, appNames]) ->
        util.forkJoin _.map metrics, (metric) ->
          util.forkJoin _.map appNames, (appName) ->
            where = "app = '#{appName}'"
            MetricService.query model, {metric, where, hasViews: false}
            .map ({dates, values, aggregate} = {}) ->
              {dates, values, aggregate, appName}
          .map (results) ->
            unless google?
              return null
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            _.map results, ({appName}) ->
              data.addColumn 'number', appName

            dates = results[0].dates
            data.addRows _.zip dates, _.pluck(results, 'values')...

            {
              metric
              results
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
    aggregateByApp = _.reduce chartedMetrics, (appResults, charted) ->
      _.map charted.results, (result) ->
        appResults[result.appName] ?= {}
        appResults[result.appName][charted.metric.name] = result.aggregate
      return appResults
    , {}

    z '.z-metrics',
      z '.overview',
        _.map aggregateByApp, (aggregates, appName) ->
          z '.app',
            z '.name',
              appName
            _.map aggregates, (aggregate, metric) ->
              z 'tr.aggregate',
                z 'td.name',
                  metric
                z 'td.value',
                  aggregate.toFixed(2)
      z '.graphs',
        _.map chartedMetrics, ({metric, $chart}) ->
          z '.metric',
            $chart
