z = require 'zorium'
_ = require 'lodash'

if window?
  require './index.styl'

module.exports = class Metrics
  constructor: ->
    @state = z.state
      metrics: [{
        name: 'gameplays'
        numerator:
          select: 'count(value)'
          where:
            event: 'gameplay'
        denominator:
          select: 'count(value)'
          where:
            event: 'view'
      }]

  render: =>
    {metrics} = @state.getValue()

    z '.z-metrics',
      _.map metrics, (metric) ->
        z '.metric',
          metric.name
