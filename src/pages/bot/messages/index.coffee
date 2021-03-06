z = require 'zorium'
Rx = require 'rx-lite'
moment = require 'moment'

Head = require '../../../components/head'
Menu = require '../../../components/menu'
BotMessages = require '../../../components/bot/messages'
if window?
  require './index.styl'

module.exports = class UserPage
  constructor: ({model, requests, key}) ->

    chatId = requests.map ({route}) ->
      route.params.chatId

    @$head = new Head()
    @$menu = new Menu()
    @$botMessages = new BotMessages({model, chatId, key})


  renderHead: (params) =>
    z @$head, params

  render: =>
    z '.p-bot-messages',
      z @$menu, {
        $tools: z '.p-home_title',
          z 'span.back', {
            onclick: ->
              window.history.back()
          }, '(back)'
      }

      @$botMessages
