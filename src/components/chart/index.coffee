z = require 'zorium'

if window?
  require './index.styl'

class ChartWidget
  constructor: ({@state}) ->
    @disposable = null
  type: 'Widget'
  init: =>
    $$el = document.createElement 'div'
    chart = new google.charts.Line $$el

    @disposable = @state.subscribe ({data, options}) ->
      # Wait for insertion into the DOM
      setTimeout ->
        chart.draw(data, options)

    return $$el

  update: (previous, $$el) -> $$el
  destroy: => @disposable?.dispose()

module.exports = class Chart
  constructor: ({data, options}) ->
    @state = z.state
      data: data
      options: options

    @widget = new ChartWidget({@state})

  render: =>
    z '.z-chart',
      @widget
