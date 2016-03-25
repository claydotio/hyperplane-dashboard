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

PT_UTC_OFFSET = -8 * 60

module.exports = class TradingCardsHome
  constructor: ({@model, @key}) ->
    unless window?
      @state = z.state {skip: true}
      return # no server-side rendering...

    today = moment().utcOffset(PT_UTC_OFFSET).startOf('day')

    @searchUserValue = new Rx.BehaviorSubject ''
    @$searchUserInput = new Input {value: @searchUserValue}
    @$searchUserButton = new Button()

    @state = z.state
      searchUserValue: @searchUserValue

      # chartedMetrics: chartedMetrics
      topSpendersAll:
        @model[@key].getTopSpenders({duration: 'all'})
        .catch Rx.Observable.just null
      topSpendersWeek:
        @model[@key].getTopSpenders({duration: 'week'})
        .catch Rx.Observable.just null
      topSpendersDay:
        @model[@key].getTopSpenders({duration: 'day'})
        .catch Rx.Observable.just null
      genericStatsYesterday:
        @model[@key].getGenericStats {
          date: today.clone().subtract(1, 'days').toDate()
        }
        .catch Rx.Observable.just null
      genericStatsToday:
        @model[@key].getGenericStats {
          date: today.clone().toDate()
        }
        .catch Rx.Observable.just null

  render: =>
    {topSpendersWeek, topSpendersAll, topSpendersDay, genericStatsYesterday,
      genericStatsToday, searchUserValue} = @state.getValue()

    z '.z-trading-cards-home',
      z '.g-grid',

        z '.g-col.g-xs-12.g-md-3',
          z 'h3', 'Search user'
          z @$searchUserInput,
            hintText: 'username'
          z @$searchUserButton,
            text: 'Search'
            value: searchUserValue
            onclick: =>
              @model[@key].getUserByUsername searchUserValue
              .take(1)
              .toPromise()
              .then (user) =>
                if user
                  z.router.go "/#{@key}/user/#{user.id}"
              # show new password (6 chars)


      z '.g-grid',
        # TODAY
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Today'
          _.map genericStatsToday, ({actual, scaled}, key) =>
            actual = Math.round(actual * 100) / 100
            scaled = Math.round(scaled * 100) / 100
            z '.stat', {
              style:
                fontWeight: if key is 'revenue' then 500 else 400
                color: if key is 'revenue' then 'blue' else 'black'
            },
              "#{@key}: #{actual} (#{scaled})"

        # YESTERDAY
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Yesterday'
          _.map genericStatsYesterday, ({actual, scaled}, key) =>
            actual = Math.round(actual * 100) / 100
            z '.stat',
              "#{@key}: #{actual}"

        # TOP SPENDERS DAY
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Top spenders (day)'
          _.map topSpendersDay, ({id, username, amount}) =>
            amount = Math.round(amount * 100) / 100
            z 'a.user', {
              href: "/#{@key}/user/#{id}"
              onclick: (e) =>
                e.preventDefault()
                z.router.go "/#{@key}/user/#{id}"
            },
              "#{username}: $#{amount}"


        # TOP SPENDERS WEEK
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Top spenders (week)'
          _.map topSpendersWeek, ({id, username, amount}) =>
            amount = Math.round(amount * 100) / 100
            z 'a.user', {
              href: "/#{@key}/user/#{id}"
              onclick: (e) =>
                e.preventDefault()
                z.router.go "/#{@key}/user/#{id}"
            },
              "#{username}: $#{amount}"
        # TOP SPENDERS ALL
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Top spenders (all)'
          _.map topSpendersAll, ({id, username, amount}) =>
            amount = Math.round(amount * 100) / 100
            z 'a.user', {
              href: "/#{@key}/user/#{id}"
              onclick: (e) =>
                e.preventDefault()
                z.router.go "/#{@key}/user/#{id}"
            },
              "#{username}: $#{amount}"

      # z '.graphs',
      #   _.map chartedMetrics, ({metric, $chart}) ->
      #     z '.metric',
      #       $chart.render() # doesn't scale with fluid layout so re-draw
