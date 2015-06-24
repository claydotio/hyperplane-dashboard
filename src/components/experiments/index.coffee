z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

ExperimentResults = require '../experiment_results'

if window?
  require './index.styl'


module.exports = class Experiments
  constructor: ({model}) ->
    experiments = model.experiment.getAll()

    @selectedIndex = new Rx.BehaviorSubject 0
    @$experimentResults = new ExperimentResults({
      experiment: @selectedIndex.flatMapLatest (index) ->
        experiments.map (experiments) ->
          experiments[index]
    })

    @state = z.state
      experiments: experiments
      selectedIndex: @selectedIndex

  select: (index) =>
    @selectedIndex.onNext index

  render: =>
    {experiments, selectedIndex} = @state.getValue()

    z '.z-experiments',
      z '.list',
        _.map experiments, (experiment, index) =>
          z '.list-item',
            className: z.classKebab {isSelected: index is selectedIndex}
            onclick: =>
              @select index
            experiment.key
      z '.results',
        @$experimentResults
