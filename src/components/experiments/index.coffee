z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
FloatingActionButton = require 'zorium-paper/floating_action_button'
Icon = require 'zorium-paper/icon'
Input = require 'zorium-paper/input'
Dialog = require 'zorium-paper/dialog'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
log = require 'loglevel'

ExperimentResults = require '../experiment_results'

if window?
  require './index.styl'


module.exports = class Experiments
  constructor: ({model}) ->
    experiments = model.experiment.getAll()

    @$fab = new FloatingActionButton()
    @$plus = new Icon()

    newExperimentForm = _.transform
      key:
        subject: new Rx.BehaviorSubject ''
      globalPercent:
        subject: new Rx.BehaviorSubject ''
      choices:
        subject: new Rx.BehaviorSubject ''
    , (result, val, key) ->
      result[key] = _.defaults {$input: new Input value: val.subject}, val
    , {}

    @$formDialog = new Dialog()
    @$createButton = new Button()
    @$cancelButton = new Button()

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
      model: model
      experiments: experiments
      selectedId: @selectedId
      newExperimentForm: newExperimentForm
      isCreating: false

  select: (experimentId) =>
    @selectedIdStreams.onNext Rx.Observable.just experimentId

  defaultId: (experiments = []) ->
    experiments[0]?.id

  createExperiment: (model, form) ->
    body = _.transform form, (result, value, key) ->
      subjectValue = value.subject.getValue()
      result[key] = switch key
        when 'globalPercent'
          parseInt subjectValue
        when 'choices'
          _.map subjectValue.split(','), (choice) -> choice.trim()
        else
          subjectValue
    , {}

    model.experiment.create body

  render: =>
    {model, experiments, selectedId, newExperimentForm, isCreating} =
      @state.getValue()
    selectedId ?= @defaultId experiments

    z '.z-experiments',
      className: z.classKebab {isCreating}
      z '.create-experiment',
        z @$formDialog,
          $content: z '.form',
            _.map newExperimentForm, (val, key) ->
              z val.$input,
                hintText: key
                colors:
                  c500: paperColors.$blue500
          actions: [
            {
              $el: z @$cancelButton,
                text: 'cancel'
                isShort: true
                colors:
                  ink: paperColors.$blue500
                onclick: =>
                  @state.set isCreating: false
            }
            {
              $el: z @$createButton,
                text: 'create'
                isShort: true
                colors:
                  ink: paperColors.$blue500
                onclick: =>
                  @createExperiment model, newExperimentForm
                  .catch log.error
                  @state.set isCreating: false
            }
          ]
      z '.list',
        z '.fab',
          z @$fab,
            colors:
              c500: paperColors.$red500
            $icon: z @$plus, {icon: 'plus', isDark: true}
            onclick: =>
              @state.set isCreating: true
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
