z = require 'zorium'

if window?
  require './index.styl'

module.exports = class Menu
  render: ({$tools, $tabs}) ->
    z '.z-menu',
      className:
        z.classKebab
          hasTabs: Boolean $tabs
          hasTools: Boolean $tools
      z '.stub'
      z '.float',
        if $tools
          z '.tool-bar',
            $tools
        if $tabs
          z '.tab-bar',
            $tabs
