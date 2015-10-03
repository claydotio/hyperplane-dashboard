z = require 'zorium'

if window?
  require './index.styl'

class ChartWidget
  constructor: ({@state}) ->
    @disposable = null
  type: 'Widget'
  init: =>
    $$el = document.createElement 'div'
    @chart = new google.visualization.LineChart $$el

    @disposable = @state.subscribe ({@data, @options}) =>
      @redraw()

    return $$el

  redraw: =>
    # Wait for insertion into the DOM
    setTimeout =>
      @chart.draw(@data, @options)

  update: (previous, $$el) -> $$el
  destroy: => @disposable?.dispose()

module.exports = class Chart
  constructor: ({data, options}) ->
    @state = z.state
      data: data
      options: options

    @widget = new ChartWidget({@state})

  render: =>
    # doesn't scale dynamically in fluid layout so must redraw every time
    @widget.redraw()
    z '.z-chart',
      @widget
