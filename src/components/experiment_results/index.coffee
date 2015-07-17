z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
log = require 'loglevel'

Tabs = require '../tabs'
util = require '../../lib/util'
MetricService = require '../../services/metric'
StatisticsService = require '../../services/statistics'

if window?
  require './index.styl'

util.forkJoin = (observables...) ->
  Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

module.exports = class ExperimentResults
  constructor: ({model, experiment}) ->
    selectedIndex = new Rx.BehaviorSubject 0
    @$tabs = new Tabs({selectedIndex})
    @$deleteButton = new Button()

    @state = z.state
      model: model
      experiment: experiment
      results: util.forkJoin model.metric.getAll(), experiment
        .flatMapLatest ([metrics, experiment]) ->
          util.forkJoin _.map metrics, (metric) ->
            util.forkJoin _.map experiment.choices, (choice) ->
              MetricService.query model, {
                metric
                where: "#{experiment.key}='#{choice}'"
              }
            .map (series) ->
              {
                metric: metric
                series: series
              }
          .map StatisticsService.resultGridAnalysis


  delete: (model, experiment) ->
    model.experiment.deleteById experiment.id
    .catch log.error

  render: =>
    {model, experiment, results} = @state.getValue()

    tabs = ['overview', 'explore']

    table = _.map results, ({metric, series}) ->
      [metric.name].concat series

    z '.z-experiment-results',
      z '.about',
        _.map experiment, (val, key) ->
          z '.tag', "#{key}: #{val}"
      z @$deleteButton,
        $content: 'delete'
        isRaised: true
        colors:
          cText: paperColors.$red500Text
          c200: paperColors.$red200
          c500: paperColors.$red500
          c600: paperColors.$red600
          c700: paperColors.$red700
        onclick: =>
          @delete model, experiment
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
              _.map row, (cell) ->
                if _.isString cell
                  z 'td.is-label',
                    cell
                else
                  {aggregate, isConclusive, isSignificant, xBar, yBar} = cell
                  if aggregate % 1 isnt 0
                    aggregate = aggregate.toFixed 2
                  z 'td',
                    className: z.classKebab {
                      isConclusive
                      isSignificant
                      isBetter: yBar > xBar
                    }
                    aggregate
