% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make.rate.R
\name{make.rate}
\alias{make.rate}
\title{Create a flexible rate for birth-death or sampling simulations}
\usage{
make.rate(rate, tMax = NULL, envRate = NULL, rateShifts = NULL)
}
\arguments{
\item{rate}{The baseline function with which to make the rate.
It can be a

\describe{
\item{A number}{For constant birth-death rates.}

\item{A function of time}{For rates that vary with time. Note that this can be
any function of time.} 

\item{A function of time and an environmental variable}{For rates varying with
time and an environmental variable, such as temperature. Note that supplying a
function on more than one variable without an accompanying \code{envRate} will
result in an error.}

\item{A numeric vector}{To create step function rates. Note this must be
 accompanied by a corresponding vector of shifts \code{rateShifts}.}}}

\item{tMax}{Ending time of simulation, in million years after the clade's 
origin. Needed to ensure \code{rateShifts} runs the correct way.}

\item{envRate}{A \code{data.frame} representing the variation of an 
environmental variable (e.g. CO2, temperature, available niches, etc) with 
time. The first column of this \code{data.frame} must be time, and the second 
column must be the values of the variable. The function will return an error if
supplying \code{envRate} without \code{rate} being a function of two variables.
Note \code{paleobuddy} has two environmental data frames, \code{temp} and 
\code{co2}. One can check \code{RPANDA} for more examples.

Acknowledgements: The strategy to transform a function of \code{t} and 
\code{env} into a function of \code{t} only using \code{envRate} was adapted 
from RPANDA.}

\item{rateShifts}{A vector indicating the time placement of rate shifts in a 
step function. The first element must be the first time point for the 
simulation. This may be \code{0} or \code{tMax}. Since functions in paleobuddy 
run from \code{0} to \code{tMax}, if \code{rateShifts} runs from past to 
present (\code{rateShifts[2] < rateShifts[1]}), we take 
\code{tMax - rateShifts} as the shifts vector. Note that supplying 
\code{rateShifts} when \code{rate} is not a numeric vector of the same length 
will result in an error.}
}
\value{
A constant or time-varying function (depending on input) that can
then be used as a rate in the other \code{paleobuddy} functions.
}
\description{
Generates a rate to be used on birth-death or sampling functions. Takes as the 
base rate (1) a constant, (2) a function of time, (3) a function of time 
interacting with an environmental variable, or (4) a vector of numbers 
describing rates as a step function. Requires information regarding the maximum
simulation time, and allows for optional extra parameters to tweak the baseline
rate.
}
\examples{

# first we need a time vector to use on plots
time <- seq(0, 50, 0.1)

# make.rate will leave some types of functions unaltered, like the following

###
# let us start simple: create a constant rate
r <- make.rate(0.5)

# plot it
plot(time, rep(r, length(time)), type = 'l')

###
# something a bit more complex: a linear rate

# function
rate <- function(t) {
  return(0.01*t)
}

# create rate
r <- make.rate(rate)

# plot it
plot(time, r(time), type = 'l')

###
# remember: this can be any time-varying function!

# function
rate <- function(t) {
  return(sin(t)*0.01)
}

# create rate
r <- make.rate(rate)

# plot it
plot(time, r(time), type = 'l')

###
# we can use ifelse() to make a step function like this
rate <- function(t) {
  return(ifelse(t < 10, 0.1,
                ifelse(t < 20, 0.3,
                       ifelse(t < 30, 0.2,
                              ifelse(t < 40, 0.05, 0)))))
}

# and make it into a rate - in this case, as the previous, it does not alter
# rate. We put it here as a contrast to the other way to make a step function
r <- make.rate(rate)

# plot it
plot(time, r(time), type = 'l')

# important note: this method of creating a step function might be annoying,
# but when running thousands of simulations it will provide a much faster
# integration than when using our method of transforming a rates and shifts
# vector into a function of time

# this is a good segway into the cases where make.rate actually makes a rate!
# note that while the previous ones seemed useless, we need that implementation
# so that the birth-death functions work

###
# now we can demonstrate the other way of making a step function

# vector of rates
rate <- c(0.1, 0.2, 0.3, 0.2)

# vector of rate shifts
rateShifts <- c(0, 10, 20, 35)
# this could be c(50, 40, 30, 15) for equivalent results

# make the rate
r <- make.rate(rate, tMax = 50, rateShifts = rateShifts)

# plot it
plot(time, r(time),type = 'l')

# as mentioned above, while this works well it will be a pain to integrate.
# Furthermore, it is impractical to supply a rate and a shifts vector and
# have an environmental dependency, so in cases where one looks to run
# more than a couple dozen simulations, or when one is looking to have a
# step function modified by an environmental variable, consider using ifelse()

###
# finally let us see what we can do with environmental variables

# temperature data
data(temp)

# function
rate <- function(t, env) {
  return(0.05*env)
}

# make the rate
r <- make.rate(rate, envRate = temp)

# plot it
plot(time, r(time), type = 'l')

###
# we can also have a function that depends on both time AND temperature

# function
rate <- function(t, env) {
  return(0.001*exp(0.1*t) + 0.05*env)
}

# make a rate
r <- make.rate(rate, envRate = temp)

# plot it
plot(time, r(time), type = 'l')

###
# as mentioned above, we could also use ifelse() to construct a step function
# that is modulated by temperature

# function
rate <- function(t, env) {
  return(ifelse(t < 10, 0.1 + 0.01*env,
                ifelse(t < 30, 0.2 - 0.005*env,
                       ifelse(t <= 50, 0.1 + 0.005*env, 0))))
}

# rate
r <- make.rate(rate, envRate = temp)

# plot it
plot(time, r(time), type = 'l')

}
\references{
Morlon H. et al (2016) RPANDA: an R package for macroevolutionary analyses on 
phylogenetic trees. \emph{Methods in Ecology and Evolution} 7: 589-597.
}
\author{
Bruno do Rosario Petrucci
}
