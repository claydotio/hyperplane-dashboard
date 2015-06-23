z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

Tabs = require '../../components/tabs'

if window?
  require './index.styl'


module.exports = class ExperimentResults
  constructor: ({experiment}) ->
    selectedIndex = new Rx.BehaviorSubject 0
    @$tabs = new Tabs({selectedIndex})

    @state = z.state
      metrics: [{name: 'egp'}, {name: 'sps'}]
      experiment: experiment

  render: =>
    {experiment} = @state.getValue()

    tabs = ['overview', 'explore']

    z '.z-experiment-results',
      z '.name',
        experiment?.name
      z '.graph'
      z '.tabs',
        z @$tabs,
          items: tabs
      z '.data',
        z 'table',
          z 'tr',
            z 'th',
              'Metric'
            z 'th',
              'group A',
            z 'th',
              'group B'
          z 'tr',
            z 'td',
              'egp'
            z 'td',
              100
            z 'td',
              50
          z 'tr',
            z 'td',
              'sps'
            z 'td',
              90
            z 'td',
              40
