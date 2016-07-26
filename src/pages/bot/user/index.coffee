z = require 'zorium'
Rx = require 'rx-lite'
moment = require 'moment'

Head = require '../../../components/head'
Menu = require '../../../components/menu'
BotUser = require '../../../components/bot/user'
if window?
  require './index.styl'

module.exports = class UserPage
  constructor: ({model, requests, key}) ->

    userId = requests.map ({route}) ->
      route.params.userId

    @$head = new Head()
    @$menu = new Menu()
    @$botUser = new BotUser({model, userId, key})


  renderHead: (params) =>
    z @$head, params

  render: =>
    z '.p-bot-messages',
      z @$menu, {
        $tools: z '.p-home_title',
          z 'span.back', {
            onclick: ->
              # window.history.back()
              z.router.go '/'
          }, '(back)'
      }

      @$botUser
