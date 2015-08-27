_ = require 'lodash'
log = require 'loglevel'

ERROR_RATE = 0.05
TAU = 0.5 # ???????? - free variable in significance
FDR_THRESHOLD = 0.10
Z_MAX = 6 # Maxium +/- z value

##################
# Helper Methods #
##################

#
# probability of normal z value
# Adapted from a polynomial approximation in:
# Ibbetson D, Algorithm 209 Collected Algorithms of the CACM 1963 p. 616
# Note: This routine has six digit accuracy, so it is only useful for absolute
# z values <= 6.  For z values > to 6.0, poz() returns 0.0
#
# source: https://www.fourmilab.ch/rpkp/experiments/analysis/zCalc.html
#
poz = (z) ->
  y = undefined
  x = undefined
  w = undefined
  if z is 0.0
    x = 0.0
  else
    y = 0.5 * Math.abs(z)
    if y > Z_MAX * 0.5
      x = 1.0
    else if y < 1.0
      w = y * y
      x = ((((((((0.000124818987 * w \
                - 0.001075204047) * w + 0.005198775019) * w \
                - 0.019198292004) * w + 0.059054035642) * w \
                - 0.151968751364) * w + 0.319152932694) * w \
                - 0.531923007300) * w + 0.797884560593) * y * 2.0
    else
      y -= 2.0
      x = (((((((((((((-0.000045255659 * y \
                      + 0.000152529290) * y - 0.000019538132) * y \
                      - 0.000676904986) * y + 0.001390604284) * y \
                      - 0.000794620820) * y - 0.002034254874) * y \
                      + 0.006549791214) * y - 0.010557625006) * y \
                      + 0.011630447319) * y - 0.009279453341) * y \
                      + 0.005353579108) * y - 0.002141268741) * y \
                      + 0.000535310849) * y + 0.999936657524
  if z > 0.0
    return (x + 1.0) * 0.5
  else
    return (1.0 - x) * 0.5

#
# Compute critical normal z value to produce given p.
# We just do a bisection search for a value within CHI_EPSILON,
# relying on the monotonicity of pochisq().
#
# source: https://www.fourmilab.ch/rpkp/experiments/analysis/zCalc.html
#
critz = (p) ->
  Z_EPSILON = 0.000001 # Accuracy of z approximation

  minz = -Z_MAX
  maxz = Z_MAX
  zval = 0.0
  pval = undefined
  if p < 0.0 or p > 1.0
    return -1
  while maxz - minz > Z_EPSILON
    pval = poz(zval)
    if pval > p
      maxz = zval
    else
      minz = zval
    zval = (maxz + minz) * 0.5
  zval

#######################
# Conclusive Results  #
# See (2) in paper    #
#######################
getCellConclusivity = (cell) ->
  {result, controlResult} = cell

  # TODO: verify conversion rate makes sense and distributions make sense
  xBar = controlResult.aggregate / (
    controlResult.aggregateViews +
    controlResult.aggregate +
    result.aggregate
  )
  yBar = result.aggregate /
    (result.aggregateViews + controlResult.aggregate + result.aggregate)
  n = controlResult.aggregateViews + result.aggregateViews

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
  }

proportionTrueNull = (results) ->
  trueNull = _.sum results, ({conclusivity}) ->
    if not conclusivity.isConclusive
      return 1
    else
      return 0

  trueNull / results.length

class Statistics
  ##############################################################################
  # A/B test calculations                                                      #
  #                                                                            #
  # Based on Stats Engine                                                      #
  # //pages.optimizely.com/rs/optimizely/images/stats_engine_technical_paper.pdf
  ##############################################################################
  resultAnalysis: (cells) ->
    conclusiveResults = _.map cells, (cell) ->
      {
        cell: cell
        conclusivity: getCellConclusivity cell
      }


    ######################
    # Actionable Results #
    # See (4) in paper   #
    ######################
    N = conclusiveResults.length
    piZero = proportionTrueNull(conclusiveResults)

    getPHat = ({conclusivity}) -> conclusivity.pHat

    FDRresults = _.map _.sortBy(conclusiveResults, getPHat), (result, index) ->
      {pHat} = result.conclusivity

      i = index + 1
      FDR = piZero * pHat / (i * N)
      isSignificant = (1 - FDR) > FDR_THRESHOLD

      _.defaults {
        FDR: {
          value: FDR
          isSignificant
        }
      }, result

    confidenceResults = _.map FDRresults, (result) ->
      {xBar, yBar, isConclusive} = result.conclusivity
      {isSignificant} = result.FDR

      mu = (xBar + yBar) / 2
      delta = Math.sqrt(
        1 / 2 *
        _.sum [xBar, yBar], (xi) ->
          Math.pow(xi - mu, 2)
      )

      q = ERROR_RATE
      m = _.countBy(FDRresults, ({FDR}) -> FDR.isSignificant)
      coverageLevel = if isSignificant
      then (1 - q * m / N)
      else (1 - q * (m + 1) / N)

      z = critz(coverageLevel)

      low = yBar - z * delta / Math.sqrt(N)
      high = yBar + z * delta / Math.sqrt(N)

      interval = z * delta / Math.sqrt(N) / yBar

      # xBar and yBar are hacked to be between 0 and 1, here it's not
      # necessary to do that so the data is better
      # TODO: make sure this is valid
      xBar2 = result.cell.controlResult.aggregate
      yBar2 = result.cell.result.aggregate
      # account for different group sizes when dealing with metrics
      # that sum group totals (e.g. DAU)
      if result.cell.metric.isGroupSizeDependent
        xBar2 /= result.cell.controlResult.aggregateViews
        yBar2 /= result.cell.result.aggregateViews

      percentChange = -1 * (1 - yBar2 / xBar2)

      _.defaults {
        confidence: {low, high, interval, percentChange}
      }, result

    return confidenceResults

module.exports = new Statistics()
