_ = require 'lodash'
Rx = require 'rx-lite'
request = require 'clay-request'

User = require './user'
Event = require './event'
Experiment = require './experiment'
Metric = require './metric'

Promise = if window?
  window.Promise
else
  # TODO: remove once v8 is updated
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

PROXY_CACHE_KEY = 'ZORIUM_PROXY_CACHE'

isCacheable = (opts) ->
  not opts.method or opts.method.toLowerCase() is 'get' or opts.proxyCache

module.exports = class Model
  constructor: ({accessTokenStream}) ->
    proxyCache = new Rx.BehaviorSubject(window?[PROXY_CACHE_KEY] or {})

    proxy = (url, opts = {}) ->
      cacheKey = JSON.stringify(opts) + '__z__' + url
      cached = proxyCache.getValue()[cacheKey]

      if not isCacheable(opts)
        proxyCache.onNext {}
      else if cached
        return Promise.resolve cached

      proxyOpts = opts

      req = request url, proxyOpts
      if isCacheable(opts)
        entry = {}
        entry[cacheKey] = req
        proxyCache.onNext _.defaults entry, proxyCache.getValue()
      return req

    @user = new User({accessTokenStream, proxy})
    @event = new Event({accessTokenStream, proxy})
    @experiment = new Experiment({accessTokenStream, proxy})
    @metric = new Metric({accessTokenStream, @event})
