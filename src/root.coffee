require './polyfill'

_ = require 'lodash'
z = require 'zorium'
log = require 'loglevel'
Rx = require 'rx-lite'
cookie = require 'cookie'

require './root.styl'
config = require './config'
ErrorReportService = require './services/error_report'
App = require './app'
Model = require './models'
CookieService = require './services/cookie'

###########
# LOGGING #
###########

if config.ENV isnt config.ENVS.PROD
  log.enableAll()
else
  # TODO: Configure ErrorReportService before usage
  # originalFactory = log.methodFactory
  # log.methodFactory = (methodName, logLevel) ->
  #   rawMethod = originalFactory(methodName, logLevel)
  #   (args...) ->
  #     ErrorReportService.report args...
  #     return rawMethod args...
  log.setLevel 'warn' # Note: required to apply plugin

# Note: window.onerror != window.addEventListener('error')
oldOnError = window.onerror
window.onerror = (message, file, line, column, error) ->
  log.error error or message
  if oldOnError
    return oldOnError arguments...

#################
# ROUTING SETUP #
#################

getAccessToken = ->
  cookie.parse(document.cookie)[config.AUTH_COOKIE]

setAccessToken = (accessToken) ->
  document.cookie = cookie.serialize \
      config.AUTH_COOKIE,
      accessToken,
      CookieService.getAuthCookieOpts()

init = ->
  z.router.init
    $$root: document.getElementById 'zorium-root'

  requests = new Rx.ReplaySubject(1)
  accessTokenStream = new Rx.BehaviorSubject getAccessToken()
  accessTokenStream.subscribeOnNext setAccessToken

  model = new Model({accessTokenStream})

  model.user.getMe()
  .take(1).toPromise()
  .catch ->
    model.user.create()
  .then ({accessToken}) ->
    accessTokenStream.onNext accessToken
  .then ->
    $app = new App({requests, model})
    z.router.use (req, res) ->
      requests.onNext {req, res}
      res.send $app
    z.router.go()
  .catch log.error

if document.readyState isnt 'complete' and
    not document.getElementById 'zorium-root'
  window.addEventListener 'load', init
else
  init()

#############################
# ENABLE WEBPACK HOT RELOAD #
#############################

if module.hot
  module.hot.accept()
  init()
