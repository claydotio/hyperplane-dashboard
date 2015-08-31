z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Button = require 'zorium-paper/button'
RadioButton = require 'zorium-paper/radio_button'
paperColors = require 'zorium-paper/colors.json'
log = require 'loglevel'

Chart = require '../chart'
util = require '../../lib/util'
MetricService = require '../../services/metric'
StatisticsService = require '../../services/statistics'

if window?
  require './index.styl'

module.exports = class ExperimentResults
  constructor: ({model, experiment}) ->
    metrics = model.metric.getAll()
    @$deleteButton = new Button()

    selectedMetricIndex = new Rx.BehaviorSubject(0)

    resultsByMetricName = util.forkJoin metrics, experiment
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
        .map (results) ->
          _.groupBy results, ({cell}) ->
            cell.metric.name

    @state = z.state
      model: model
      metrics: metrics
      experiment: experiment
      radios: metrics.flatMapLatest (metrics) ->
        util.forkJoin _.map metrics, (metric, index) ->
          isChecked = new Rx.BehaviorSubject(false)
          # TODO: ugly
          indexListener = selectedMetricIndex.doOnNext (selectedIndex) ->
            if index is selectedIndex
              isChecked.onNext true
            else
              isChecked.onNext false
          checkListener = isChecked.doOnNext (isChecked) ->
            if isChecked and selectedMetricIndex.getValue() isnt index
              selectedMetricIndex.onNext index
          util.forkJoin [isChecked, indexListener, checkListener]
          .map ->
            {
              $el: new RadioButton({isChecked})
              metricName: metric.name
            }
      $chart: util.forkJoin [metrics, selectedMetricIndex, resultsByMetricName]
      .map ([metrics, selectedMetricIndex, resultsByMetricName]) ->
        metricName = metrics[selectedMetricIndex].name
        results = resultsByMetricName[metricName]
        unless google?
          return null
        data = new google.visualization.DataTable()

        data.addColumn 'date', 'Date'
        _.map results, ({cell}) ->
          data.addColumn 'number', cell.choice

        dates = results[0].cell.result.dates
        values = _.map results, ({cell}) ->
          cell.result.values

        data.addRows _.zip dates, values...

        new Chart({
          data: data
          options: {
            tooltip: {isHtml: true}
            chart: {
              title: metricName
            }
            height: 500
          }
        })

      resultsByMetricName: resultsByMetricName


  delete: (model, experiment) ->
    model.experiment.deleteById experiment.id
    .catch log.error

  render: =>
    {model, metrics, experiment, radios,
    resultsByMetricName, $chart} = @state.getValue()

    headers = ['Metric \\ Group'].concat(experiment?.choices)
    table = _.map metrics, (metric) ->
      results = resultsByMetricName?[metric.name]
      [metric.name].concat _.map _.rest(headers), (experimentChoice) ->
        _.find results, ({cell}) ->
          cell.choice is experimentChoice

    z '.z-experiment-results',
      z '.about',
        _.map experiment, (val, key) ->
          z '.tag', "#{key}: #{val}"
      z '.actions',
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
                  radio = _.find radios, (radio) ->
                    radio.metricName is element

                  z 'td.is-label',
                    radio.$el
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
      z '.chart',
        $chart
