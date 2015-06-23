z = require 'zorium'

if window?
  require './index.styl'

module.exports = class Metrics
  render: ->
    z '.z-metrics',
      'metrics'
