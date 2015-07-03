z = require 'zorium'

if window?
  require './index.styl'

module.exports = class Chart
  constructor: ({data, options}) ->
    @mountDisposable = null

    @state = z.state
      data: data
      options: options

  afterMount: ($$el) =>
    chart = new google.charts.Line $$el

    @mountDisposable = @state.subscribe ({data, options}) ->
      chart.draw(data, options)

  beforeUnmount: =>
    @mountDisposable?.dispose()

  render: ->
    z '.z-chart'
