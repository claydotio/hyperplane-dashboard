z = require 'zorium'
paperColors = require 'zorium-paper/colors.json'
Rx = require 'rx-lite'
Routes = require 'routes'
Qs = require 'qs'

config = require './config'
gulpConfig = require '../gulp_config'
HomePage = require './pages/home'
TradingCardsUserPage = require './pages/trading_cards/user'
BotMessagesPage = require './pages/bot/messages'
FourOhFourPage = require './pages/404'

ANIMATION_TIME_MS = 500

styles = if not window? and config.ENV is config.ENVS.PROD
  # Avoid webpack include
  _fs = 'fs'
  fs = require _fs
  fs.readFileSync gulpConfig.paths.dist + '/bundle.css', 'utf-8'
else
  null

bundlePath = if not window? and config.ENV is config.ENVS.PROD
  # Avoid webpack include
  _fs = 'fs'
  fs = require _fs
  stats = JSON.parse \
    fs.readFileSync gulpConfig.paths.dist + '/stats.json', 'utf-8'

  "/#{stats.hash}.bundle.js?#{Date.now()}"
else
  null

module.exports = class App
  constructor: ({requests, model}) ->
    router = new Routes()

    requests = requests.map ({req, res}) ->
      route = router.match req.path
      $page = route.fn()

      return {req, res, route, $page}

    $homePage = new HomePage({
      requests: requests.filter ({$page}) -> $page instanceof HomePage
      model
    })
    $kittenCardsUserPage = new TradingCardsUserPage({
      requests: requests.filter ({$page}) ->
        $page is $kittenCardsUserPage
      model
      key: 'kittencards'
    })
    $trumpCardsUserPage = new TradingCardsUserPage({
      requests: requests.filter ({$page}) ->
        $page is $trumpCardsUserPage
      model
      key: 'trumpcards'
    })
    $botMessagesPage = new BotMessagesPage({
      requests: requests.filter ({$page}) ->
        $page is $botMessagesPage
      model
    })
    $fourOhFourPage = new FourOhFourPage({
      requests: requests.filter ({$page}) -> $page instanceof FourOhFourPage
      model
    })

    router.addRoute '/', -> $homePage
    router.addRoute '/kittenCards/user/:id', -> $kittenCardsUserPage
    router.addRoute '/trumpCards/user/:id', -> $trumpCardsUserPage
    router.addRoute '/bot/messages/:userId', -> $botMessagesPage
    router.addRoute '*', -> $fourOhFourPage

    handleRequest = requests.doOnNext ({req, res, route, $page}) =>
      {$currentPage} = @state.getValue()

      if $page instanceof FourOhFourPage
        res.status? 404

      @state.set
        $currentPage: $page

    @state = z.state {
      handleRequest: handleRequest
      $currentPage: null
    }

  render: =>
    {$currentPage} = @state.getValue()

    z 'html',
      $currentPage?.renderHead {styles, bundlePath}
      z 'body',
        z '#zorium-root',
          z '.z-root',
            $currentPage
