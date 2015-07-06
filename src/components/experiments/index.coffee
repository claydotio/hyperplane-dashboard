z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'

ExperimentResults = require '../experiment_results'

if window?
  require './index.styl'


module.exports = class Experiments
  constructor: ({model}) ->
    experiments = model.experiment.getAll()

    @selectedIdStreams = new Rx.BehaviorSubject experiments.map (experiments) ->
      _.first(experiments).id
    @selectedId = @selectedIdStreams.switch()
    @$experimentResults = new ExperimentResults({
      model
      experiment: @selectedId.flatMapLatest (id) =>
        experiments.map (experiments) =>
          id ?= @defaultId experiments
          _.find experiments, {id}
    })

    @state = z.state
      experiments: experiments
      selectedId: @selectedId

  select: (experimentId) =>
    @selectedIdStreams.onNext Rx.Observable.just experimentId

  defaultId: (experiments = []) ->
    experiments[0]?.id

  render: =>
    {experiments, selectedId} = @state.getValue()
    selectedId ?= @defaultId experiments

    z '.z-experiments',
      z '.list',
        _.map _.groupBy(experiments, 'namespace'), (experiments, namespace) =>
          z '.namespace',
            namespace
            _.map experiments, (experiment) =>
              z '.experiment',
                className: z.classKebab {
                  isSelected: experiment.id is selectedId
                }
                onclick: =>
                  @select experiment.id
                experiment.key

      z '.results',
        @$experimentResults
