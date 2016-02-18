z = require 'zorium'
Rx = require 'rx-lite'
moment = require 'moment'

Head = require '../../../components/head'
Menu = require '../../../components/menu'
KCUser = require '../../../components/kc/user'
if window?
  require './index.styl'

module.exports = class UserPage
  constructor: ({model, requests}) ->

    userId = requests.map ({route}) ->
      route.params.id

    user = userId.flatMapLatest (userId) ->
      model.mittens.getUserById userId

    @$head = new Head()
    @$menu = new Menu()
    @$kcUser = new KCUser({model, user})

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

      @$kcUser
