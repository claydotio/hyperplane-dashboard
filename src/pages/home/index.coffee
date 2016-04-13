z = require 'zorium'
Rx = require 'rx-lite'

Head = require '../../components/head'
Menu = require '../../components/menu'
Tabs = require '../../components/tabs'
Experiments = require '../../components/experiments'
Metrics = require '../../components/metrics'
TradingCards = require '../../components/trading_cards/home'
Bot = require '../../components/bot'
MetaInfo = require '../../components/meta_info'
RealTime = require '../../components/real_time'
Games = require '../../components/games'

if window?
  require './index.styl'

module.exports = class HomePage
  constructor: ({model}) ->
    selectedIndex = new Rx.BehaviorSubject(0)

    @$head = new Head()
    @$menu = new Menu()
    @$tabs = new Tabs({selectedIndex})
    @$experiments = new Experiments({model})
    @$metrics = new Metrics({model})
    @$bot = new Bot({model})
    @$kittenCards = new TradingCards({model, key: 'kittencards'})
    @$trumpCards = new TradingCards({model, key: 'trumpcards'})
    @$metaInfo = new MetaInfo({model})
    @$realTime = new RealTime({model})
    @$games = new Games({model})

    @state = z.state
      selectedIndex: selectedIndex

  renderHead: (params) =>
    z @$head, params

  render: =>
    {selectedIndex} = @state.getValue()

    tabs = ['bot', 'kittencards', 'trumpcards', 'metrics', 'experiments']
    #, 'games', 'real-time', 'meta']

    z '.p-home',
      z @$menu,
        $tools: z '.p-home_title',
          'Hyperplane'
        $tabs: z @$tabs,
          items: tabs
      switch tabs[selectedIndex]
        when 'bot'
          @$bot
        when 'experiments'
          @$experiments
        when 'metrics'
          @$metrics
        when 'kittencards'
          @$kittenCards
        when 'trumpcards'
          @$trumpCards
        when 'meta'
          @$metaInfo
        when 'real-time'
          @$realTime
        when 'games'
          @$games
