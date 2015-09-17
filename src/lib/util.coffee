_ = require 'lodash'
Rx = require 'rx-lite'

MS_IN_DAY = 1000 * 60 * 60 * 24

streamJoin = (observables...) ->
  streams = _.map _.flatten(observables), (sourceStream) ->
    Rx.Observable.just(null) .concat sourceStream
  Rx.Observable.combineLatest streams, (results...) -> results
  .filter (results) -> not _.isEmpty _.filter results

module.exports =
  streamJoin: streamJoin

  streamFilterJoin: (observables...) ->
    streamJoin observables...
    .map (results) -> _.filter results
    .filter (results) -> not _.isEmpty results

  forkJoin: (observables...) ->
    Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

  dayToMS: (day) ->
    timeZoneOffsetMS = (new Date()).getTimezoneOffset() * 60 * 1000
    day * MS_IN_DAY + timeZoneOffsetMS

  dateToDay: (date) ->
    timeZoneOffsetMS = (new Date()).getTimezoneOffset() * 60 * 1000
    Math.floor((date - timeZoneOffsetMS) / MS_IN_DAY)
