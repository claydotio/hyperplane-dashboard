z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
moment = require 'moment'

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
  constructor: ({model, userId}) ->
    userInfo = userId.flatMapLatest model.bot.getUserInfoById

    @state = z.state
      userInfo: userInfo

  render: =>
    {userInfo} = @state.getValue()

    sortedFlows = _.sortBy(userInfo?.flows, 'reduction').reverse()

    z '.z-bot-user',
      z '.g-grid',
        _.map sortedFlows, ({group, reduction}) ->
          z 'div', "#{group}: #{reduction}"
