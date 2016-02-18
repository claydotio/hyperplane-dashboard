z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
moment = require 'moment'

Chart = require '../../chart'
MetricService = require '../../../services/metric'
util = require '../../../lib/util'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

if window?
  require './index.styl'

MIN_START_DATE = new Date('2015-10-1')

fillInGapsAdding0 = (data, startDate, endDate = new Date()) ->
  if Date.parse(startDate) < Date.parse(MIN_START_DATE)
    startDate = MIN_START_DATE

  daysUntilStart = moment(data[0].date).diff(moment(startDate), 'day')

  newData = _.map _.range(daysUntilStart), (i) ->
    {date: moment(startDate).add(i, 'day').toDate(), amount: 0}

  startDate = new Date(data[0].date)

  newData.push data[0]
  i = 1
  while i < data.length
    diff = moment(data[i].date).diff(moment(data[i - 1].date), 'day')

    startDate = new Date(data[i - 1].date)
    if diff > 1
      j = 1
      while j < diff
        fillDate = moment(startDate).add(j, 'day').toDate()
        newData.push {
          date: fillDate
          amount: 0
        }
        j += 1
    newData.push data[i]
    i += 1

  lastDate = data[data.length - 1].date
  daysUntilEnd = moment(endDate)
    .diff(moment(lastDate), 'day')

  newData = newData.concat _.map _.range(daysUntilEnd), (i) ->
    {date: moment(lastDate).add(i + 1, 'day').toDate(), amount: 0}

  console.log newData[newData.length - 1]

  newData

dataToChart = (results, user, title) ->
  results = fillInGapsAdding0 results, user.joinTime
  data = new google.visualization.DataTable()

  data.addColumn 'date', 'Date'
  data.addColumn 'number', 'Value'
  data.addRows _.map results, ({date, amount}) ->
    [new Date(date), amount]

  dateFormatter = new google.visualization.DateFormat
    formatType: 'short'

  dateFormatter.format data, 0

  # numberFormatter = new google.visualization.NumberFormat
  #   pattern: metric.format

  # _.map _.range(results.length), (column) ->
  #   numberFormatter.format data, column + 1

  {
    # formatter: numberFormatter
    $chart: new Chart({
      data: data
      interpolateNulls: false

      options:
        title: title
        legend:
          position: 'none'
        # vAxis:
        #   format: metric.format
        hAxis:
          format: 'M/d'
        height: 250
      })
    }

module.exports = class KCUser
  constructor: ({model, user}) ->

    unless window?
      @state = z.state {skip: true}
      return # no server-side rendering...

    @revenueGraphStreams = new Rx.ReplaySubject 1

    @state = z.state
      revenueGraph: user.flatMapLatest (user) ->
        model.mittens.getRevenueGraphByUserId user.id
        .map (results) ->
          dataToChart results, user, user.username + ' revenue'

      chatGraph: user.flatMapLatest (user) ->
        model.mittens.getChatGraphByUserId user.id
        .map (results) ->
          dataToChart results, user, user.username + ' chat messages'

      tradesGraph: user.flatMapLatest (user) ->
        model.mittens.getTradesGraphByUserId user.id
        .map (results) ->
          dataToChart results, user, user.username + ' trades'

  render: =>
    {revenueGraph, chatGraph, tradesGraph} = @state.getValue()

    console.log revenueGraph

    z '.z-kc-user',
      revenueGraph?.$chart.render()
      chatGraph?.$chart.render()
      tradesGraph?.$chart.render()
