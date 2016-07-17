z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
paperColors = require 'zorium-paper/colors.json'
Dialog = require 'zorium-paper/dialog'
moment = require 'moment'

Chart = require '../../chart'
MetricService = require '../../../services/metric'
util = require '../../../lib/util'

Promise = if window?
  window.Promise
else
  # Avoid webpack include
  bluebird = 'bluebird'
  require bluebird

if window?
  require './index.styl'

module.exports = class TradingCardsSubmissions
  constructor: ({@model, user, @key}) ->

    unless window?
      @state = z.state {skip: true}
      return # no server-side rendering...

    @state = z.state
      submissions: @model[@key].getSubmissions()
      winners: @model[@key].getSubmissionWinners()

  render: =>
    {submissions, winners} = @state.getValue()

    z '.z-trading-cards-submissions',
      z 'h3', 'Top 2',
        _.map winners, (winner) ->
          z '.winner',
            z 'div', winner.name
            z 'div', winner.id
            z 'div', _.sum winner.votes, 'count'
            z 'div',
              z 'img', {
                src: winner.image.originalUrl#versions[0].url
                width: 300
              }
      z 'h3', 'Submissions'
      _.map submissions, (submission) =>
        z '.submission',
          z 'div',
            submission.name or '_no name_'
            ' | '
            z 'a', {
              href: '#'
              onclick: (e) =>
                e?.preventDefault()
                @model[@key].approveSubmission submission.id
            }, 'Approve'
            ' | '
            z 'a', {
              href: '#'
              onclick: (e) =>
                e?.preventDefault()
                reason = window.prompt 'Reason'
                if reason
                  @model[@key].rejectSubmission submission.id, {reason}
            }, 'Reject'
          z 'img', {
            src: submission.image.originalUrl#versions[0].url
            width: 300
          }
          z '.preview', {
            style:
              backgroundImage: "url(#{submission.image.versions[0].url})"
          }
