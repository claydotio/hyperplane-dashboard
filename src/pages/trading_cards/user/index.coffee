z = require 'zorium'
Rx = require 'rx-lite'
moment = require 'moment'

Head = require '../../../components/head'
Menu = require '../../../components/menu'
TradingCardsUser = require '../../../components/trading_cards/user'
if window?
  require './index.styl'

module.exports = class UserPage
  constructor: ({model, requests, key}) ->

    userId = requests.map ({route}) ->
      route.params.id

    user = userId.flatMapLatest (userId) ->
      model[key].getUserById userId

    @$head = new Head()
    @$menu = new Menu()
    @$tradingCardsUser = new TradingCardsUser({model, user, key})

    @state = z.state
      userId: userId
      user: user


  renderHead: (params) =>
    z @$head, params

  render: =>
    {user} = @state.getValue()

    joinDate = moment(user?.joinTime).format('MM/DD/YYYY')

    z '.p-kc-user',
      z @$menu, {
        $tools: z '.p-home_title',
          z 'span.back', {
            onclick: ->
              window.history.back()
          }, '(back)'
          "#{user?.username} (join: #{joinDate})"
      }

      @$tradingCardsUser
