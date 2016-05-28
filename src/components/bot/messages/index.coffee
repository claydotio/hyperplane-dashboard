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
  constructor: ({model, chatId}) ->
    messages = chatId.flatMapLatest model.bot.getMessagesByChatId
    # user = userId.flatMapLatest model.bot.getUserById

    @state = z.state
      messages: messages
      # user: user

  render: =>
    {messages, user} = @state.getValue()

    z '.z-bot-messages',
      z '.g-grid',
        # z 'strong', user?.name
        _.map messages, (message) ->
          z '.message-group',
            z '.responses',
              _.map message.responses, ({text}) ->
                z '.response', "bot: #{text}"
            z '.message',
              "#{message.userId}: #{(message.message.text or 'app-link')}"
