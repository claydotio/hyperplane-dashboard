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

module.exports = class ExperimentResults
  constructor: ({model, experiment}) ->
    metrics = model.metric.getAll()
    selectedIndex = new Rx.BehaviorSubject 0
    @$tabs = new Tabs({selectedIndex})
    @$deleteButton = new Button()

    @state = z.state
      model: model
      experiment: experiment
      results: util.forkJoin metrics, experiment
        .flatMapLatest ([metrics, experiment]) ->
          queries = util.forkJoin _.map metrics, (metric) ->
            util.forkJoin _.map experiment.choices, (choice) ->
              where = if _.isEmpty(experiment.apps) # LEGACY
                "#{experiment.key}='#{choice}'"
              else
                experimentFilter = _.map(experiment.apps, (app) ->
                  "#{app}_#{experiment.key}='#{choice}'"
                ).join(' OR ')
                "(#{experimentFilter})"

              MetricService.query model, {metric, where}
              .map (result) ->
                {metric, choice, result}
            .map (row) ->
              controlResult = row[0].result
              _.map row, (cell) ->
                _.defaults {controlResult}, cell

          queries
          .map _.flatten
          .map StatisticsService.resultAnalysis


  delete: (model, experiment) ->
    model.experiment.deleteById experiment.id
    .catch log.error

  render: =>
    {model, experiment, results} = @state.getValue()

    resultsByMetricName = _.groupBy results, ({cell}) ->
      cell.metric.name

    tabs = ['overview', 'explore']

    headers = ['Metric \\ Group'].concat(experiment?.choices)
    table = _.map resultsByMetricName, (results, metricName) ->
      [metricName].concat _.map _.rest(headers), (experimentChoice) ->
        _.find results, ({cell}) ->
          cell.choice is experimentChoice

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
              _.map headers, (header) ->
                z 'th',
                  header
          ].concat _.map table, (row) ->
            z 'tr',
              _.map row, (element) ->
                if _.isString element
                  z 'td.is-label',
                    element
                else if element?
                  {conclusivity, cell, FDR, confidence} = element
                  aggregate = cell.result.aggregate

                  z 'td',
                    className: z.classKebab {
                      isConclusive: conclusivity.isConclusive
                      isSignificant: FDR.isSignificant
                      isBetter: conclusivity.yBar > conclusivity.xBar
                    }
                    z 'span',
                      if aggregate % 1 isnt 0
                        aggregate.toFixed(2)
                      else
                        aggregate
                    ' ('
                    z 'span.percent',
                      className: z.classKebab {
                        isNegative: confidence.percentChange < 0
                        isNeutral: confidence.percentChange is 0
                      }
                      "#{if confidence.percentChange > 0 then '+' else ''}" +
                      "#{(confidence.percentChange * 100).toFixed(2)}%"
                    " ±#{confidence.interval.toFixed(2)})"
