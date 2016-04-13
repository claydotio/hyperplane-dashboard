_ = require 'lodash'
Rx = require 'rx-lite'
request = require 'clay-request'
Netox = require 'netox'

User = require './user'
Event = require './event'
Experiment = require './experiment'
Metric = require './metric'
Bot = require './bot'
TradingCard = require './trading_card'

Promise = if window?
  window.Promise
else
  # TODO: remove once v8 is updated
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

module.exports = class Model
  constructor: ({accessTokenStream}) ->
    @netox = new Netox()
    @user = new User({accessTokenStream, proxy: request})
    @event = new Event({accessTokenStream, @netox})
    @experiment = new Experiment({accessTokenStream, proxy: request})
    @metric = new Metric({accessTokenStream, @event})
    @bot = new Bot({accessTokenStream, @netox})
    @kittencards = new TradingCard({
      accessTokenStream, @netox, backend: 'mittens'
    })
    @trumpcards = new TradingCard({
      accessTokenStream, @netox, backend: 'donald'
    })
