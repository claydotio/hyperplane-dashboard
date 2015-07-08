z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Tabs = require '../tabs'
util = require '../../lib/util'
MetricService = require '../../services/metric'

if window?
  require './index.styl'

util.forkJoin = (observables...) ->
  Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

module.exports = class ExperimentResults
  constructor: ({model, experiment}) ->
    selectedIndex = new Rx.BehaviorSubject 0
    @$tabs = new Tabs({selectedIndex})

    @state = z.state
      experiment: experiment
      results: util.forkJoin model.metric.getAll(), experiment
        .flatMapLatest ([metrics, experiment]) ->
          util.forkJoin _.map metrics, (metric) ->
            util.forkJoin _.map experiment.choices, (choice) ->
              MetricService.query model, {
                metric
                namespace: experiment.namespace
                where: "#{experiment.key}='#{choice}'"
              }
            .map (series) ->
              {
                metric: metric
                series: series
              }

  render: =>
    {experiment, results} = @state.getValue()

    tabs = ['overview', 'explore']

    table = _.map results, ({metric, series}) ->
      [metric.name].concat _.pluck series, 'aggregate'

    z '.z-experiment-results',
      z '.name',
        "#{experiment?.namespace} : #{experiment?.key}"
      z '.graph'
      z '.tabs',
        z @$tabs,
          items: tabs
      z '.data',
        z 'table',
          [
            z 'tr',
              _.map ['Metric \\ Group'].concat(experiment?.choices), (header) ->
                z 'th',
                  header
          ].concat _.map table, (row) ->
            z 'tr',
              _.map row, (value) ->
                if _.isNumber(value) and value % 1 isnt 0
                  value = value.toFixed 2
                z 'td',
                  value
