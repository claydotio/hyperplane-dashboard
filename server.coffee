express = require 'express'
_ = require 'lodash'
compress = require 'compression'
log = require 'loglevel'
helmet = require 'helmet'
z = require 'zorium'
Promise = require 'bluebird'
request = require 'clay-request'
Rx = require 'rx-lite'
cookieParser = require 'cookie-parser'

config = require './src/config'
gulpConfig = require './gulp_config'
App = require './src/app'
Model = require './src/models'
CookieService = require './src/services/cookie'

MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS = 10886400000 # 18 weeks
HEALTHCHECK_TIMEOUT = 1000

Rx.config.Promise = Promise

app = express()
router = express.Router()

log.enableAll()

app.use compress()

webpackDevHost = "#{gulpConfig.WEBPACK_DEV_HOSTNAME}:" +
                 "#{gulpConfig.WEBPACK_DEV_PORT}"
scriptSrc = [
  '\'self\''
  '\'unsafe-inline\''
  '\'unsafe-eval\''
  'www.google-analytics.com'
  'www.google.com'
  if config.ENV is config.ENVS.DEV then webpackDevHost
]
stylesSrc = [
  '\'unsafe-inline\''
  if config.ENV is config.ENVS.DEV then webpackDevHost
]
app.use helmet.contentSecurityPolicy
  scriptSrc: scriptSrc
  stylesSrc: stylesSrc
app.use helmet.xssFilter()
app.use helmet.frameguard()
app.use helmet.hsts
  # https://hstspreload.appspot.com/
  maxAge: MIN_TIME_REQUIRED_FOR_HSTS_GOOGLE_PRELOAD_MS
  includeSubdomains: true # include in Google Chrome
  preload: true # include in Google Chrome
  force: true
app.use helmet.noSniff()
app.use helmet.crossdomain()
app.disable 'x-powered-by'
app.use cookieParser()

app.use '/healthcheck', (req, res, next) ->
  Promise.settle [
    Promise.cast(request(config.HYPERPLANE_API_URL + '/ping'))
      .timeout HEALTHCHECK_TIMEOUT
  ]
  .spread (hyperplane) ->
    result =
      hyperplane: hyperplane.isFulfilled()

    isHealthy = _.every _.values result
    if isHealthy
      res.json {healthy: isHealthy}
    else
      res.status(500).json _.defaults {healthy: isHealthy}, result
  .catch next

app.use '/ping', (req, res) ->
  res.send 'pong'

app.use '/demo', (req, res) ->
  res.json {name: 'Zorium'}

if config.ENV is config.ENVS.PROD
then app.use express.static(gulpConfig.paths.dist, {maxAge: '4h'})
else app.use express.static(gulpConfig.paths.build, {maxAge: '4h'})

app.use router
app.use (req, res, next) ->
  accessTokenStream = new Rx.BehaviorSubject req.cookies.accessToken
  accessTokenStream.subscribeOnNext (accessToken) ->
    res.cookie \
      config.AUTH_COOKIE, accessToken, CookieService.getAuthCookieOpts()

  model = new Model({accessTokenStream})

  model.user.getMe()
  .take(1).toPromise()
  .catch ->
    model.user.create()
  .then ({accessToken}) ->
    accessTokenStream.onNext accessToken
  .then ->
    z.renderToString new App({requests: Rx.Observable.just({req, res}), model})
  .then (html) ->
    res.send '<!DOCTYPE html>' + html
  .catch (err) ->
    console.log err
    if err.html
      # FIXME: use syncronous zorium rendering
      # log.error err
      res.send '<!DOCTYPE html>' + err.html
    else
      next err

module.exports = app
