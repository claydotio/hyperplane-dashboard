z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'

Chart = require '../chart'
MetricService = require '../../services/metric'
util = require '../../lib/util'

if window?
  require './index.styl'

module.exports = class Metrics
  constructor: ({model}) ->
    metrics = model.metric.getAll()
    appNames = model.event.getAppNames()
    @currentFilter = new Rx.BehaviorSubject ''
    userFilter = new Rx.BehaviorSubject ''
    @$userFilter = new Input {value: userFilter}
    @$userFilterSubmit = new Button()

    chartedMetrics = util.forkJoin [metrics, appNames, @currentFilter]
      .flatMapLatest ([metrics, appNames, currentFilter]) ->
        util.forkJoin _.map metrics, (metric) ->
          util.forkJoin _.map appNames, (appName) ->
            where = "app = '#{appName}'" +
              if currentFilter then ' AND ' + currentFilter else ''
            MetricService.query model, {
              metric
              where
              hasViews: false
              shouldStream: true
            }
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
      userFilter: userFilter

  filter: =>
    {userFilter} = @state.getValue()
    @currentFilter.onNext userFilter

  render: =>
    {chartedMetrics} = @state.getValue()
    aggregateByApp = _.reduce chartedMetrics, (appResults, charted) ->
      _.map charted.results, (result) ->
        appResults[result.appName] ?= {}
        appResults[result.appName][charted.metric.name] = result.aggregate
      return appResults
    , {}

    z '.z-metrics',
      z 'form.user-filter',
        onsubmit: (e) =>
          e.preventDefault()
          @filter()
        z @$userFilter,
          hintText: 'custom filter,
          e.g. uaBrowserName=\'Chrome\' AND uaOSName=\'Android\''
          isFloating: true
          colors:
            c500: paperColors.$blue500
        z @$userFilterSubmit,
          $content: 'filter'
          isRaised: true
          type: 'submit'
          colors:
            cText: paperColors.$blue500Text
            c200: paperColors.$blue200
            c500: paperColors.$blue500
            c600: paperColors.$blue600
            c700: paperColors.$blue700
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
