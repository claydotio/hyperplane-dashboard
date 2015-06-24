z = require 'zorium'
Rx = require 'rx-lite'

Head = require '../../components/head'
Menu = require '../../components/menu'
Tabs = require '../../components/tabs'
Experiments = require '../../components/experiments'
Metrics = require '../../components/metrics'

if window?
  require './index.styl'

module.exports = class HomePage
  constructor: ({model}) ->
    selectedIndex = new Rx.BehaviorSubject(0)

    @$head = new Head()
    @$menu = new Menu()
    @$tabs = new Tabs({selectedIndex})
    @$experiments = new Experiments({model})
    @$metrics = new Metrics()

    @state = z.state
      selectedIndex: selectedIndex

  renderHead: (params) =>
    z @$head, params

  render: =>
    {selectedIndex} = @state.getValue()

    tabs = ['experiments', 'metrics']

    z '.p-home',
      z @$menu,
        $tools: z '.p-home_title',
          'Hyperplane'
        $tabs: z @$tabs,
          items: tabs
      switch tabs[selectedIndex]
        when 'experiments'
          @$experiments
        when 'metrics'
          @$metrics
