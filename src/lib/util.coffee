_ = require 'lodash'
Rx = require 'rx-lite'

MS_IN_DAY = 1000 * 60 * 60 * 24

module.exports =
  forkJoin: (observables...) ->
    Rx.Observable.combineLatest _.flatten(observables), (results...) -> results

  dayToMS: (day) ->
    timeZoneOffsetMS = (new Date()).getTimezoneOffset() * 60 * 1000
    day * MS_IN_DAY + timeZoneOffsetMS

  dateToDay: (date) ->
    timeZoneOffsetMS = (new Date()).getTimezoneOffset() * 60 * 1000
    Math.floor((date - timeZoneOffsetMS) / MS_IN_DAY)
