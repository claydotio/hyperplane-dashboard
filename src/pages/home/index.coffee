z = require 'zorium'
Rx = require 'rx-lite'

Head = require '../../components/head'
Menu = require '../../components/menu'
Tabs = require '../../components/tabs'
Experiments = require '../../components/experiments'
Metrics = require '../../components/metrics'
MetaInfo = require '../../components/meta_info'
RealTime = require '../../components/real_time'

if window?
  require './index.styl'

module.exports = class HomePage
  constructor: ({model}) ->
    selectedIndex = new Rx.BehaviorSubject(1)

    @$head = new Head()
    @$menu = new Menu()
    @$tabs = new Tabs({selectedIndex})
    @$experiments = new Experiments({model})
    @$metrics = new Metrics({model})
    @$metaInfo = new MetaInfo({model})
    @$realTime = new RealTime({model})

    @state = z.state
      selectedIndex: selectedIndex

  renderHead: (params) =>
    z @$head, params

  render: =>
    {selectedIndex} = @state.getValue()

    tabs = ['metrics', 'experiments', 'real-time', 'meta']

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
        when 'meta'
          @$metaInfo
        when 'real-time'
          @$realTime
