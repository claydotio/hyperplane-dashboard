z = require 'zorium'
_ = require 'lodash'

util = require '../../lib/util'

if window?
  require './index.styl'

module.exports = class MetaInfo
  constructor: ({model}) ->
    tagValues = model.event.getTags().flatMapLatest (tags) ->
      util.streamFilterJoin _.map tags, (tag) ->
        model.event.getTagValues tag
        .map (values) ->
          {tag, values: _.take(values, 10)}

    @state = z.state
      tagValues: tagValues

  render: =>
    {tagValues} = @state.getValue()

    z '.z-meta-info',
      _.map tagValues, ({tag, values}) ->
        z '.tag',
          tag
          _.map values, (value) ->
            z '.value',
              value
