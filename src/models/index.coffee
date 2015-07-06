User = require './user'
Event = require './event'
Experiment = require './experiment'
Metric = require './metric'

module.exports = class Model
  constructor: ({accessTokenStream}) ->
    @user = new User({accessTokenStream})
    @event = new Event({accessTokenStream})
    @experiment = new Experiment({accessTokenStream})
    @metric = new Metric({accessTokenStream})
