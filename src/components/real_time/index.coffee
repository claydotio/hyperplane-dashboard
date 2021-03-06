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

module.exports = class RealTime
  constructor: ({model}) ->
    metrics = model.metric.getAll()
    appNames = model.event.getAppNames()
    @currentFilter = new Rx.BehaviorSubject ''
    userFilter = new Rx.BehaviorSubject ''
    @$userFilter = new Input {value: userFilter}
    @$userFilterSubmit = new Button()

    realTimeResults = util.forkJoin [metrics, appNames, @currentFilter]
      .flatMapLatest ([metrics, appNames, currentFilter]) ->
        util.streamFilterJoin _.map metrics, (metric) ->
          unless google?
            return Rx.Observable.just null
          formatter = new google.visualization.NumberFormat
            pattern: metric.format

          targetAppNames = if metric.apps?
            _.intersection appNames, metric.apps
          else
            appNames
          util.streamFilterJoin _.map targetAppNames, (appName) ->
            where = "app = '#{appName}'" +
              if currentFilter then ' AND ' + currentFilter else ''
            MetricService.query model, {
              metric,
              where,
              hasViews: false,
              isOnlyToday: true,
              shouldStream: false
            }
            .map ({dates, values, aggregate} = {}) ->
              {dates, values, aggregate, appName}
          .map (results) ->
            {
              metric
              results
              formatter
            }

    @state = z.state
      realTimeResults: realTimeResults
      userFilter: userFilter

  filter: =>
    {userFilter} = @state.getValue()
    @currentFilter.onNext userFilter

  render: =>
    {realTimeResults} = @state.getValue()
    aggregateByApp = _.reduce realTimeResults, (appResults, realTime) ->
      _.map realTime.results, (result) ->
        appResults[result.appName] ?= {}
        appResults[result.appName][realTime.metric.name] = {
          aggregate: result.aggregate
          formatter: realTime.formatter
        }
      return appResults
    , {}

    z '.z-real-time',
      z 'form.user-filter',
        onsubmit: (e) =>
          e.preventDefault()
          @filter()
        z @$userFilter,
          hintText: 'filter'
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
            _.map aggregates, ({aggregate, formatter}, metric) ->
              z 'tr.aggregate',
                z 'td.name',
                  metric
                z 'td.value',
                  formatter.formatValue aggregate
