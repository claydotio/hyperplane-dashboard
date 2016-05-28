z = require 'zorium'
Rx = require 'rx-lite'
moment = require 'moment'

Head = require '../../../components/head'
Menu = require '../../../components/menu'
TradingCardsSubmissions = require '../../../components/trading_cards/submissions'
if window?
  require './index.styl'

module.exports = class SubmissionsPage
  constructor: ({model, requests, key}) ->


    @$head = new Head()
    @$menu = new Menu()
    @$tradingCardsSubmissions = new TradingCardsSubmissions({model, key})

    @state = z.state {}


  renderHead: (params) =>
    z @$head, params

  render: =>

    z '.p-kc-user',
      z @$menu, {
        $tools: z '.p-home_title',
          z 'span.back', {
            onclick: ->
              window.history.back()
          }, '(back)'
          'Submissions'
      }

      @$tradingCardsSubmissions
