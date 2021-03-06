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

module.exports = class Games
  constructor: ({model}) ->
    dayToMS = util.dayToMS
    metrics = Rx.Observable.just [
      {
        name: 'game plays'
        format: '0'
        numerator:
          select: 'count(userId)'
          from: 'game_play'
          where: (day) ->
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
      }
      {
        name: 'engaged play ratio'
        format: '0.00%'
        numerator:
          select: 'count(userId)'
          from: 'engaged_game_play'
          where: (day) ->
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
        denominator:
          select: 'count(userId)'
          from: 'game_play'
          where: (day) ->
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
      }
      {
        name: 'average session length (min)'
        format: '0.00'
        numerator:
          select: 'sum(value) / 60'
          from: 'game_play_session'
          where: (day) ->
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
        denominator:
          select: 'count(userId)'
          from: 'game_play'
          where: (day) ->
            "time >= #{dayToMS day}ms AND time < #{dayToMS day + 1}ms"
      }
    ]
    appNames = model.event.query {
      select: 'count(userId)'
      from: 'game_play'
      where: 'time >= now() - 1d'
      groupBy: 'game'
    }
    .map (result) ->
      filtered = _.filter result.series, (row) ->
        row.values[0][1] > 200
      _.map filtered, ({tags}) -> tags.game
    @currentFilter = new Rx.BehaviorSubject ''
    userFilter = new Rx.BehaviorSubject ''
    @$userFilter = new Input {value: userFilter}
    @$userFilterSubmit = new Button()

    chartedMetrics = util.forkJoin [metrics, appNames, @currentFilter]
      .flatMapLatest ([metrics, appNames, currentFilter]) ->
        util.streamFilterJoin _.map metrics, (metric) ->
          util.streamFilterJoin _.map appNames, (appName) ->
            where = "game = '#{appName}'" +
              if currentFilter then ' AND ' + currentFilter else ''
            MetricService.query model, {
              metric
              where
              hasViews: false
              shouldStream: true
            }
            .map ({dates, values, weeklyAggregates} = {}) ->
              {dates, values, weeklyAggregates, appName}
          .map (results) ->
            unless google?
              return null
            data = new google.visualization.DataTable()

            data.addColumn 'date', 'Date'
            _.map results, ({appName}) ->
              data.addColumn 'number', appName

            dates = results[0].dates
            data.addRows _.zip dates, _.pluck(results, 'values')...

            dateFormatter = new google.visualization.DateFormat
              formatType: 'short'

            dateFormatter.format data, 0

            numberFormatter = new google.visualization.NumberFormat
              pattern: metric.format

            _.map _.range(results.length), (column) ->
              numberFormatter.format data, column + 1

            {
              formatter: numberFormatter
              metric
              results
              $chart: new Chart({
                data: data
                options:
                  title: metric.name
                  legend:
                    position: 'none'
                  vAxis:
                    format: metric.format
                  hAxis:
                    format: 'M/d'
                  height: 500
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

    metricsByApp = _.reduce chartedMetrics, (resultsByApp, charted) ->
      _.map charted.results, (result) ->
        resultsByApp[result.appName] ?= {}
        resultsByApp[result.appName][charted.metric.name] = {
          currentWeek: result.weeklyAggregates[1]
          lastWeek: result.weeklyAggregates[0]
          formatter: charted.formatter
        }
      return resultsByApp
    , {}

    z '.z-games',
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
      z '.user-filter-text',
        'custom filter, e.g. uaBrowserName=\'Chrome\' AND uaOSName=\'Android\''
      z '.overview',
        _.map metricsByApp, (metrics, appName) ->
          z '.app',
            z '.name',
              appName
            _.map metrics, ({currentWeek, lastWeek, formatter}, metric) ->
              delta = currentWeek - lastWeek
              deltaPercent = (delta / lastWeek * 100).toFixed(2)
              z 'tr.aggregate',
                className: z.classKebab
                  isIncrease: delta > 0
                z 'td.name',
                  metric
                z 'td.value',
                  formatter.formatValue currentWeek
                z 'td.delta',
                  "#{if deltaPercent > 0 then '+' else ''}#{deltaPercent}%"
      z '.graphs',
        _.map chartedMetrics, ({metric, $chart}) ->
          z '.metric',
            $chart.render() # doesn't scale with fluid layout so re-draw
