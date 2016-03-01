z = require 'zorium'
paperColors = require 'zorium-paper/colors.json'
Rx = require 'rx-lite'
Routes = require 'routes'
Qs = require 'qs'

config = require './config'
gulpConfig = require '../gulp_config'
HomePage = require './pages/home'
KCUserPage = require './pages/kc/user'
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
    $kcUserPage = new KCUserPage({
      requests: requests.filter ({$page}) -> $page instanceof KCUserPage
      model
    })
    $fourOhFourPage = new FourOhFourPage({
      requests: requests.filter ({$page}) -> $page instanceof FourOhFourPage
      model
    })

    router.addRoute '/', -> $homePage
    router.addRoute '/kc/user/:id', -> $kcUserPage
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
