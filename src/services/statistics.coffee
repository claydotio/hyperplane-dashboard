ERROR_RATE = 0.05
TAU = 0.5 # ???????? - free variable in significance
FDR_THRESHOLD = 0.10

class Statistics
  ##############################################################################
  # A/B test calculations                                                      #
  #                                                                            #
  # Based on Stats Engine                                                      #
  # //pages.optimizely.com/rs/optimizely/images/stats_engine_technical_paper.pdf
  ##############################################################################
  resultGridAnalysis: (results) ->
    #######################
    # Conclusive Results  #
    # See (2) in paper    #
    #######################
    conclusiveResults = _.flatten _.map results, (result) ->
      control = result.series[0]
      _.map result.series, (alternate, index) ->
        # TODO: verify conversion rate makes sense and distributions make sense
        xBar = control.aggregate /
          (control.aggregateViews + control.aggregate + alternate.aggregate)
        yBar = alternate.aggregate /
          (alternate.aggregateViews + control.aggregate + alternate.aggregate)
        n = control.aggregateViews + alternate.aggregateViews

        thetaHat = yBar - xBar
        alpha = ERROR_RATE
        V = 2 * (xBar * (1 - xBar) + yBar * (1 - yBar)) / n

        pHat = Math.sqrt(
          (2 * Math.log(1 / alpha) - Math.log(V / (V + TAU))) *
          (V * (V + TAU) / TAU)
        )

        isConclusive = Math.abs(thetaHat) > pHat

        {
          isConclusive
          pHat
          xBar
          yBar
          metricName: result.metric.name
          seriesIndex: index
        }

    ######################
    # Actionable Results #
    # See (4) in paper   #
    ######################
    proportionTrueNull = (results) ->
      trueNull = _.sum results, ({isConclusive}) ->
        if not isConclusive
          return 1
        else
          return 0

      trueNull / results.length

    N = conclusiveResults.length
    piZero = proportionTrueNull(conclusiveResults)

    FDRresults =
    _.map _.sortBy(conclusiveResults, 'pHat'), (result, index) ->
      {pHat} = result

      i = index + 1
      FDR = piZero * pHat / (i * N)
      isSignificant = (1 - FDR) > FDR_THRESHOLD

      _.defaults {FDR, isSignificant}, result

    # Note that de-grouping removed series order information
    groupedResults = _.groupBy FDRresults, 'metricName'
    finalResults = _.map results, (result) ->
      rowResults = \
        _.sortBy groupedResults[result.metric.name], 'seriesIndex'
      {
        metric: result.metric
        series: _.map result.series, (element, index) ->
          _.defaults _.cloneDeep(element), rowResults[index]
      }

    return finalResults

module.exports = new Statistics()
