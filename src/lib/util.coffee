_ = require 'lodash'
Rx = require 'rx-lite'

module.exports =
  forkJoin: (observables...) ->
    Rx.Observable.combineLatest _.flatten(observables), (results...) -> results
