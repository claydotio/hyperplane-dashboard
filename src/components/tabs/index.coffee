_ = require 'lodash'
z = require 'zorium'
paperColors = require 'zorium-paper/colors.json'

if window?
  require './index.styl'

module.exports = class Tabs
  constructor: ({@selectedIndex}) ->
    @state = z.state
      selectedIndex: @selectedIndex

  render: ({items}) =>
    {selectedIndex} = @state.getValue()

    z '.z-tabs',
      z '.selector',
        style:
          width: "#{100 / items.length}%"
          left: "#{selectedIndex / items.length * 100}%"
      _.map items, (text, i) =>
        z '.tab',
          key: i
          className: z.classKebab {isSelected: i is selectedIndex}
          onclick: (e) =>
            e.preventDefault()
            e.stopPropagation()
            @selectedIndex.onNext(i)
          "#{text}"
