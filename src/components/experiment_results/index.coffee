z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Tabs = require '../../components/tabs'

if window?
  require './index.styl'

forkJoin = (observables...) ->
  Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

queryify = ({select, from, where, groupBy}) ->
  q = "SELECT #{select} FROM #{from}"
  if where
    q += " WHERE #{where}"
  if groupBy
    q += " GROUP BY #{groupBy}"

  return q

MS_IN_DAY = 1000 * 60 * 60 * 24

module.exports = class ExperimentResults
  constructor: ({model, experiment}) ->
    selectedIndex = new Rx.BehaviorSubject 0
    @$tabs = new Tabs({selectedIndex})

    metricQuery = ({namespace, query, isRunningAverage, filter}) ->
      if isRunningAverage
        forkJoin _.map(_.range(7), (day) ->
          model.event.query queryify {
            select: query.select
            from: namespace
            where: query.where Date.now() - MS_IN_DAY * day
          }
        )
        .map (partials) ->
          values = _.map partials, (partial) ->
            partial.series?[0].values[0][1]

          values = [_.sum(values) / values.length]

          {values}

      else
        model.event.query queryify {
          select: query.select
          from: namespace
          where: "#{query.where} AND time >= now() - 7d" +
                 "#{if filter then " AND #{filter}" else ''}"
        }
        .map (query) ->
          [dates, values] = _.zip query.series?[0].values...
          {values}

    metricResults = (metric, namespace, filter) ->
      numerator = metricQuery {
        namespace
        query: metric.numerator
        isRunningAverage: metric.isRunningAverage
        filter: filter
      }

      denominator = if metric.denominator
        metricQuery {
          namespace
          query: metric.denominator
          isRunningAverage: metric.isRunningAverage
          filter: filter
        }
      else
        Rx.Observable.just null

      forkJoin numerator, denominator
      .map ([numerator, denominator]) ->
        values = if denominator
          _.zipWith numerator.values, denominator.values, (num, den) ->
            num / den
        else
          numerator.values

        return values[0]

    @state = z.state
      experiment: experiment
      results: forkJoin model.metric.getAll(), experiment
        .flatMapLatest ([metrics, experiment]) ->
          forkJoin _.map metrics, (metric) ->
            forkJoin _.map experiment.choices, (choice) ->
              filter = "#{experiment.key}='#{choice}'"
              metricResults metric, experiment.namespace, filter
            .map (results) ->
              {
                metric: metric
                results: results
              }

  render: =>
    {experiment, results} = @state.getValue()

    tabs = ['overview', 'explore']

    table = _.map results, ({metric, results}) ->
      [metric.name].concat results

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
