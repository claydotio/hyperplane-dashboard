z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
moment = require 'moment'

Chart = require '../chart'
MetricService = require '../../services/metric'
util = require '../../lib/util'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

if window?
  require './index.styl'

PT_UTC_OFFSET = -8 * 60

module.exports = class Bot
  constructor: ({@model}) ->
    unless window?
      @state = z.state {skip: true}
      return # no server-side rendering...

    today = moment().utcOffset(PT_UTC_OFFSET).startOf('day')

    @state = z.state
      stats:
        @model.bot.getStats()
        .catch Rx.Observable.just null

  render: =>
    {stats} = @state.getValue()

    console.log stats

    z '.z-bot',
      z '.g-grid',
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Unknown responses'
          _.map stats?.unknownResponses, (response) ->
            z '.response', {
              onclick: ->
                alert(
                  _.pluck(response.reduction, 'feedback').join(' | ') + '...' +
                  _.pluck(response.reduction, 'userId').join(' | ')
                )
            },
              z 'span.count', "#{response.reduction.length} "
              z 'span.message', response.group
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Popular messages'
          _.map stats?.botMessages, (message) ->
            z '.message',
              z 'span.count', "#{message.reduction} "
              z 'span.message', message.group
        z '.g-col.g-xs-12.g-md-3',
          z '.title', 'Recent messages'
          _.map stats?.recentMessages, (message) ->
            z 'div',
              z 'a.message', {
                href: "/bot/messages/#{message.chatId}"
                onclick: (e) ->
                  e.preventDefault()
                  z.router.go e.target.href
              },
                message.message.text or 'app-link'
