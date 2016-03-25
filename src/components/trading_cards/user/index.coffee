z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
Dialog = require 'zorium-paper/dialog'
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
  if _.isEmpty data
    return data

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

module.exports = class TradingCardsUser
  constructor: ({@model, user, @key}) ->

    unless window?
      @state = z.state {skip: true}
      return # no server-side rendering...

    @revenueGraphStreams = new Rx.ReplaySubject 1
    @$dialog = new Dialog()

    @giveGoldValue = new Rx.BehaviorSubject ''
    @$giveGoldInput = new Input {value: @giveGoldValue}
    @$giveGoldButton = new Button()

    @giveItemValue = new Rx.BehaviorSubject ''
    @$giveItemInput = new Input {value: @giveItemValue}
    @$giveItemButton = new Button()

    @state = z.state
      user: user
      dialog: null
      newPassword: null
      flaggedTradesStr: null
      giveGoldValue: @giveGoldValue
      giveItemValue: @giveItemValue
      revenueGraph: user.flatMapLatest (user) =>
        @model[@key].getRevenueGraphByUserId user.id
        .catch Rx.Observable.just []
        .map (results) ->
          dataToChart results, user, user.username + ' revenue'

      chatGraph: user.flatMapLatest (user) =>
        @model[@key].getChatGraphByUserId user.id
        .catch Rx.Observable.just []
        .map (results) ->
          dataToChart results, user, user.username + ' chat messages'

      tradesGraph: user.flatMapLatest (user) =>
        @model[@key].getTradesGraphByUserId user.id
        .catch Rx.Observable.just []
        .map (results) ->
          dataToChart results, user, user.username + ' trades'

  render: =>
    {user, revenueGraph, chatGraph, tradesGraph, dialog, giveItemValue,
      giveGoldValue, newPassword, flaggedTradesStr} = @state.getValue()

    z '.z-trading-cards-user',
      z 'h3', 'Actions'
      z 'ul.actions',
        if user?.flags.hasCheated
          z 'li',
            z 'a', {
              href: '#'
              onclick: =>
                if user
                  @model[@key].unresetByUserId user.id
            },
              'Restore cards (not a cheater)'
        if user?.flags.isChatBanned
          z 'li',
            z 'a', {
              href: '#'
              onclick: =>
                if user
                  @model[@key].unbanByUserId user.id
            },
              'Unban from chat'
        z 'li',
          z 'a', {
            href: '#'
            onclick: =>
              if user and confirm('You sure?')
                @model[@key].resetPasswordByUserId user.id
                .then ({newPassword}) =>
                  @state.set
                    dialog: 'resetPassword'
                    newPassword: newPassword
          },
            'Reset password'
        z 'li',
          z 'a', {
            href: '#'
            onclick: =>
              @state.set
                dialog: 'giveGold'
          },
            'Give gold'
        z 'li',
          z 'a', {
            href: '#'
            onclick: =>
              @state.set
                dialog: 'giveItem'
          },
            'Give item'
        z 'li',
          z 'a', {
            href: '#'
            onclick: =>
              @model[@key].getFlaggedTradesStrByUserId user.id
              .take(1).toPromise()
              .then (flaggedTradesStr) =>
                @state.set
                  flaggedTradesStr: flaggedTradesStr
          },
            'View flagged trades'

      z 'h3', 'Info'
      z 'ul',
        z 'li', "Gold: #{user?.gold}"
        z 'li', "Items: #{_.sum(user?.itemIds, 'count')}"
        z 'li', "Email: #{user?.email}"
        z 'li', "Phone: #{user?.phone}"
        z 'li', "Kik username: #{user?.kikUsername}"
        z 'li', "Facebook id: #{user?.facebookId}"
        z 'li', "Flagged for cheating: #{user?.flags.hasCheated}"
      revenueGraph?.$chart.render()
      chatGraph?.$chart.render()
      tradesGraph?.$chart.render()

      if dialog
        z @$dialog,
          title: if dialog is 'resetPassword' \
                 then 'Reset password'
                 else if dialog is 'giveGold'
                 then 'Give gold'
                 else if dialog is 'giveItem'
                 then 'Give item'
                 else ''
          $content:
            z 'div',
              if dialog is 'resetPassword'
                z 'div',
                  'Password is:'
                  z 'input',
                    type: 'text'
                    value: newPassword

              else if dialog is 'giveGold'
                z 'div',
                  z @$giveGoldInput,
                    hintText: 'Gold amount'
                    value: giveGoldValue
                  z @$giveGoldButton,
                    text: 'Give gold'
                    onclick: =>
                      if user
                        @model[@key].giveGoldByUserId user.id, giveGoldValue
                        .then =>
                          @state.set dialog: null

              else if dialog is 'giveItem'
                z 'div',
                  z @$giveItemInput,
                    hintText: 'Item ID'
                    value: giveItemValue
                  z @$giveItemButton,
                    text: 'Give item'
                    onclick: =>
                      if user
                        @model[@key].giveItemByUserId user.id, giveItemValue
                        .then =>
                          @state.set dialog: null

              z 'a', {
                href: '#'
                onclick: =>
                  @state.set dialog: null
              }, 'Close'

      if flaggedTradesStr
        z 'div',
          z 'div', "username: #{flaggedTradesStr.username}"
          z 'div', "ip: #{flaggedTradesStr.ip}"
          z 'div', "flagged: #{flaggedTradesStr.flagged}"
          z 'div', "unfair: #{flaggedTradesStr.unfair}"
          z 'div', "fairForSelfPercent: #{flaggedTradesStr.fairForSelfPercent}"
