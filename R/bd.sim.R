#' General rate Birth-Death simulation
#' 
#' Simulates a species birth-death process with general rates for any number of
#' starting species. Allows for the speciation/extinction rate to be (1) a 
#' constant, (2) a function of time, (3) a function of time and an environmental
#' variable, or (4) a vector of numbers representing a step function. 
#' Allows for constraining results on the number of species at the end of the 
#' simulation, either total or extant. The function can also take an optional 
#' shape argument to generate age-dependence on speciation and/or extinction, 
#' assuming a Weibull distribution as a model of  age-dependence. Returns a 
#' \code{sim} object (see \code{?sim}). It may return true extinction times or 
#' simply information on whether species lived after the  maximum simulation time, 
#' depending on input. \code{bd.sim} calls \code{bd.sim.constant} or 
#' \code{bd.sim.general} depending on the nature of the birth and death rates 
#' supplied. For more information on the code used for the birth-death process, 
#' see those corresponding functions.
#' Please note while time runs from \code{0} to \code{tMax} in the simulation, it 
#' returns speciation/extinction times as \code{tMax} (origin of the group) to 
#' \code{0} (the "present" and end of simulation), so as to conform to other
#' packages in the literature.
#'
#' @param n0 Initial number of species. Usually 1, in which case the simulation 
#' will describe the full diversification of a monophyletic lineage. Note that
#' when \code{lambda} is less than or equal to \code{mu},  many simulations will
#' go extinct before speciating even once. One way of generating large sample
#' sizes in this case is to increase \code{n0}, which will simulate the
#' diversification of a paraphyletic group.
#'
#' @param lambda Speciation rate (per species per million years) over time. It can
#' be a \code{numeric} describing a constant rate, a \code{function(t)} describing 
#' the variation in speciation over time \code{t}, a \code{function(t, env)} 
#' describing the variation in speciation over time following both time AND 
#' an environmental variable (please see \code{envL} for details) or a 
#' \code{vector} containing rates that correspond to each rate between speciation
#' rate shift times times (please see \code{lShifts}). Note that \code{lambda}
#' should always be greater than or equal to zero.
#'
#' @param mu Similar to \code{lambda}, but for the extinction rate.
#' 
#' Note: rates should be considered as running from \code{0} to \code{tMax}, as
#' the simulation runs in that direction even though the function inverts times
#' before returning in the end.
#'
#' @param tMax Ending time of simulation, in million years after the clade origin. 
#' Any species still living after \code{tMax} is considered extant, and any 
#' species that would be generated after \code{tMax} is not born.
#'
#' @param lShape Shape of the age-dependency in speciation rate. This will be 
#' equal to the shape parameter in a Weibull distribution: when smaller than one, 
#' speciation rate will decrease along each species' age (negative 
#' age-dependency). When larger than one, speciation rate will increase along each
#' species's age (positive age-dependency). It may be a function of time, but 
#' see note below for caveats therein. Default is \code{NULL}, equivalent to 
#' an age-independent process. For \code{lShape != NULL} (including when equal to 
#' one), \code{lambda} will be considered a scale (= 1/rate), and \code{rexp.var} 
#' will draw a Weibull distribution instead of an exponential. This means 
#' Weibull(rate, 1) = Exponential(1/rate). Note that even when 
#' \code{lShape != NULL}, \code{lambda} may still be time-dependent. 
#'
#' @param mShape Similar to \code{lShape}, but for the extinction rate.
#'
#' Note: Time-varying shape is within expectations for most cases, but if it is
#' lower than 1 and varies too much (e.g. \code{0.5 + 0.5*t}), it can be biased
#' for higher waiting times due to computational error. Slopes (or equivalent,
#' since it can be any function of time) of the order of 0.01 are advisable.
#' It rarely also displays small biases for abrupt variations. In both cases,
#' error is still quite low for the purposes of the package.
#' 
#' Note: Shape must be greater than 0. We arbitrarily chose 0.01 as the minimum
#' accepted value, so if shape is under 0.01 for any reasonable time in the 
#' simulation, it returns an error.
#' 
#' @param envL A \code{data.frame} representing the variation of an environmental
#' variable (e.g. CO2, temperature, available niches, etc) with time. The first 
#' column of this \code{data.frame} must be time, and the second column must be 
#' the values of the variable. This will be internally passed to the 
#' \code{make.rate} function, to create a speciation rate variation in time 
#' following the interaction between the environmental variable and the function.
#' Note \code{paleobuddy} has two environmental data frames, \code{temp} and
#' \code{co2}. One can check \code{RPANDA} for more examples.
#'
#' @param envM Similar to \code{envL}, but for the extinction rate.
#'
#' @param lShifts Vector of rate shifts. First element must be the starting
#' time for the simulation (\code{0} or \code{tMax}). It must have the same length
#' as \code{lambda}. \code{c(0, x, tMax)} is equivalent to 
#' \code{c(tMax, tMax - x, 0)} for the purposes of \code{make.rate}.
#' 
#' @param mShifts Similar to \code{mShifts}, but for the extinction rate.
#' 
#' @param nFinal A \code{vector} of length \code{2}, indicating an interval of 
#' acceptable number of species at the end of the simulation. Default value is 
#' \code{c(0, Inf)}, so that any number of species (including zero, the extinction
#' of the whole clade) is accepted. If different from default value, the process
#' will run until the number of total species reaches a number in the interval
#' \code{nFinal}. 
#' 
#' @param nExtant A \code{vector} of length \code{2}, indicating an interval of
#' acceptable number of extant species at the end of the simulation. Equal to 
#' \code{nFinal} in every respect except for that.
#' 
#' Note: The function returns \code{NA} if it runs for more than \code{100000}
#' iterations without fulfilling the requirements of \code{nFinal} and 
#' \code{nExtant}.
#' 
#' @param trueExt A \code{logical} indicating whether the function should return
#' true or truncated extinction times. When \code{TRUE}, time of extinction of 
#' extant species will be the true time, otherwise it will be \code{NA} if a 
#' species is alive at the end of the simulation.
#' 
#' Note: This is interesting to use to test age-dependent extinction. 
#' Age-dependent speciation would require all speciation times (including
#' the ones after extinction) to be recorded, so we do not attempt to add an
#' option to account for that. Since age-dependent extinction and speciation
#' use the same underlying process, however, if one is tested to satisfacton
#' the other should also be in expectations.
#'
#' @return A \code{sim} object, containing extinction times, speciation times,
#' parent, and status information for each species in the simulation. See 
#' \code{?sim}.
#'
#' @author Bruno do Rosario Petrucci.
#'
#' @examples
#' 
#' # we will showcase here some of the possible scenarios for diversification,
#' # touching on all the kinds of rates
#' 
#' ###
#' # consider first the simplest regimen, constant speciation and extinction
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.11
#' 
#' # extinction
#' mu <- 0.08
#' 
#' # run the simulation, making sure we have more than 1 species in the end
#' sim <- bd.sim(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # now let us complicate speciation more, maybe a linear function
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation rate
#' lambda <- function(t) {
#'   return(0.03 + 0.005*t)
#' }
#' 
#' # extinction rate
#' mu <- 0.08
#' 
#' # run the simulation, making sure we have more than 1 species in the end
#' sim <- bd.sim(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   # full phylogeny
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # what if we want q to be a step function?
#' 
#' # vector of extinction rates
#' mList <- c(0.09, 0.08, 0.1)
#' 
#' # vector of shift times. Note mShifts could be c(40, 20, 5) for identical 
#' # results
#' mShifts <- c(0, 20, 35)
#' 
#' # let us take a look at how make.rate will make it a step function
#' mu <- make.rate(mList, tMax = tMax, rateShifts = mShifts)
#' 
#' # and plot it
#' plot(seq(0, tMax, 0.1), mu(seq(0, tMax, 0.1)), type = 'l',
#'      main = "Extintion rate as a step function", xlab = "Time (My)",
#'      ylab = "Rate (species/My)")
#' 
#' # looking good, we will keep everything else the same
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # speciation
#' lambda <- function(t) {
#'   return(0.02 + 0.005*t)
#' }
#' 
#' # a different way to define the same extinction function
#' mu <- function(t) {
#'   ifelse(t < 20, 0.09,
#'          ifelse(t < 35, 0.08, 0.1))
#' }
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' # we could instead have used mList and mShifts
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # we can also supply a shape parameter to try age-dependent rates
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - here note it is a Weibull scale
#' lambda <- 10
#' 
#' # speciation shape
#' lShape <- 2
#' 
#' # extinction
#' mu <- 0.08
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, lShape = lShape, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # scale can be a time-varying function
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - here note it is a Weibull scale
#' lambda <- function(t) {
#'   return(2 + 0.25*t)
#' }
#' 
#' # speciation shape
#' lShape <- 2
#' 
#' # extinction
#' mu <- 0.2
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, lShape = lShape, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # and so can shape
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - here note it is a Weibull scale
#' lambda <- function(t) {
#'   return(2 + 0.25*t)
#' }
#' 
#' # speciation shape
#' lShape <- function(t) {
#'   return(1 + 0.02*t)
#' }
#' 
#' # extinction
#' mu <- 0.2
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, lShape = lShape, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#'  
#' ###
#' # finally, we can also have a rate dependent on an environmental variable,
#' # like temperature data
#' 
#' # get temperature data
#' data(temp)
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - a scale
#' lambda <- 10
#' 
#' # note the scale for the age-dependency can be a time-varying function
#' 
#' # speciation shape
#' lShape <- 2
#' 
#' # extinction, dependent on temperature exponentially
#' mu <- function(t, env) {
#'   return(0.1*exp(0.01*env))
#' }
#' 
#' # need a data frame describing the temperature at different times
#' envM <- temp
#' 
#' # by passing q and envM to bd.sim, internally bd.sim will make q into a
#' # function dependent only on time, using make.rate
#' m <- make.rate(mu, tMax = tMax, envRate = envM)
#' 
#' # take a look at how the rate itself will be
#' plot(seq(0, tMax, 0.1), m(seq(0, tMax, 0.1)),
#'      main = "Extinction rate varying with temperature", xlab = "Time (My)",
#'      ylab = "Rate", type = 'l')
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, lShape = lShape, envM = envM,
#'               nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # one can mix and match all of these scenarios as they wish - age-dependency
#' # and constant rates, age-dependent and temperature-dependent rates, etc. The
#' # only combination that is not allowed is a vector rate and environmental
#' # data, but one can get around that as follows
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # speciation - a step function of temperature built using ifelse()
#' lambda <- function(t, env) {
#'   ifelse(t < 20, env,
#'          ifelse(t < 30, env / 4, env / 3))
#' }
#' 
#' # speciation shape
#' lShape <- 2
#' 
#' # environment variable to use - temperature
#' envL <- temp
#' 
#' # this is kind of a complicated scale, let us take a look
#' 
#' # make it a function of time
#' l <- make.rate(lambda, tMax = tMax, envRate = envL)
#' 
#' # plot it
#' plot(seq(0, tMax, 0.1), l(seq(0, tMax, 0.1)),
#'      main = "Speciation scale varying with temperature", xlab = "Time (My)",
#'      ylab = "Scale", type = 'l')
#' 
#' # extinction - high so this does not take too long to run
#' mu <- 0.2
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # run the simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, lShape = lShape, envL = envL,
#'               nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' # after presenting the possible models, we can consider how to
#' # create mixed models, where the dependency changes over time
#' 
#' ###
#' # consider speciation that becomes environment dependent
#' # in the middle of the simulation
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # time and temperature-dependent speciation
#' lambda <- function(t, temp) {
#'   return(
#'     ifelse(t < 20, 0.1 - 0.005*t,
#'            0.05 + 0.1*exp(0.02*temp))
#'   )
#' }
#' 
#' # extinction
#' mu <- 0.1
#' 
#' # get the temperature data
#' data(temp)
#' 
#' # run simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, envL = temp, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # we can also change the environmental variable
#' # halfway into the simulation
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.1
#' 
#' # temperature-dependent extinction
#' m_t1 <- function(t, temp) {
#'   return(0.05 + 0.1*exp(0.02*temp))
#' }
#' 
#' # get the temperature data
#' data(temp)
#' 
#' # make first function
#' mu1 <- make.rate(m_t1, tMax = tMax, envRate = temp)
#' 
#' # co2-dependent extinction
#' m_t2 <- function(t, co2) {
#'   return(0.02 + 0.14*exp(0.01*co2))
#' }
#' 
#' # get the co2 data
#' data(co2)
#' 
#' # make second function
#' mu2 <- make.rate(m_t2, tMax = tMax, envRate = co2)
#' 
#' # final extinction function
#' mu <- function(t) {
#'   ifelse(t < 20, mu1(t), mu2(t))
#' }
#' 
#' # run simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' # note one can also use this mu1 mu2 workflow to create a rate
#' # dependent on more than one environmental variable, by decoupling
#' # the dependence of each in a different function and putting those
#' # together
#' 
#' ###
#' # finally, note one could create an extinction rate that turns age-dependent
#' # in the middle, by making shape time-dependent
#'
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.15
#' 
#' # extinction - a Weibull scale
#' mu <- function(t) {
#'   return(8 + 0.05*t)
#' }
#' 
#' # speciation shape
#' mShape <- function(t) {
#'   return(
#'     ifelse(t < 30, 1, 2)
#'   )
#' }
#' 
#' # run simulation
#' sim <- bd.sim(n0, lambda, mu, tMax, mShape = mShape,
#'                nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # note nFinal has to be sensible
#' \dontrun{
#' # this would return a warning, since it is virtually impossible to get 100
#' # species at a process with diversification rate -0.09 starting at n0 = 1
#' sim <- bd.sim(1, lambda = 0.01, mu = 1, tMax = 100, nFinal = c(100, Inf))
#' }
#' 
#' @name bd.sim
#' @rdname bd.sim
#' @export

bd.sim <- function(n0, lambda, mu, tMax, 
                  lShape = NULL, mShape = NULL, 
                  envL = NULL, envM = NULL, 
                  lShifts = NULL, mShifts = NULL, 
                  nFinal = c(0, Inf), nExtant = c(0, Inf),
                  trueExt = FALSE) {
  
  # if we have ONLY numbers for lambda and mu, it is constant
  if ((is.numeric(lambda) & length(lambda) == 1) &
      (is.numeric(mu) & length(mu) == 1) &
       (is.null(c(lShape, mShape, envL, envM, lShifts, mShifts)))) {
    l <- lambda
    m <- mu
    
    # call bd.sim.constant
    return(bd.sim.constant(n0, l, m, tMax, nFinal, nExtant, trueExt))
  }

  # else it is not constant
  # note even if lambda or mu is constant this may call bd.sim.general, since we
  # might have a shape parameter or the other rate might not be constant
  else {
    # use make.rate to create the rates we want
    l <- make.rate(lambda, tMax, envL, lShifts)
    m <- make.rate(mu, tMax, envM, mShifts)

    # call bd.sim.general
    return(bd.sim.general(n0, l, m, tMax, lShape, mShape, 
                          nFinal, nExtant, trueExt))
  }
}

