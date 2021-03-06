% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/phylo.to.sim.R
\name{phylo.to.sim}
\alias{phylo.to.sim}
\title{Converting a phylogeny in a paleobuddy object}
\usage{
phylo.to.sim(
  phy,
  mothers,
  extant,
  dateFromPresent = TRUE,
  stemAge = NULL,
  stemLength = NULL
)
}
\arguments{
\item{phy}{A \code{phylo} object, which may contain only extant or extant and
extinct lineages.}

\item{mothers}{Vector containing the mother of each tip in the phylogeny. 
First species' mother should be \code{NA}.}

\item{extant}{Logical vetor indicating which lineages are extant and extinct.}

\item{dateFromPresent}{Logical vector indicating if TS/TE events should be 
dated from present-to-root (\code{TRUE}, default value) of from root-to- 
present. Please see "dating" section in "details", below. It is internally set 
to \code{FALSE} and prints a message in the prompt if there are no extant
species in the \code{extant} vector.}

\item{stemAge}{Numeric vetor indicating the age, in absolute geological time
(Mya), when the first lineage of the clade originated. It is not needed when
\code{dateFromPresent} is \code{TRUE} and \code{stemLength} is provided, or 
when \code{phy} has a \code{root.edge}. This argument is required if 
\code{dateFromPresent} is \code{FALSE}.}

\item{stemLength}{Numeric vector indicating the time difference between the 
\code{stemAge} and the appearance of its first "daughter" lineage (that is, the
second lineage to originate in the phylogeny). This argument is required if 
\code{dateFromPresent} is \code{FALSE}, but users have no need to assign values
in this parameter if \code{phy} have a \code{$root.edge}, which is taken by the
function as the \code{stemLength} value.}
}
\value{
A \code{sim} object. For details, see \code{?sim}. Items in the object 
follow their tip assignment in the phylogeny.
}
\description{
Generates a \code{sim} object using a \code{phylo} object and some additional 
information (depending on other inputs). It is the inverse of the 
\code{make.phylo} function. Input is (1) a phylogeny, following a "evolutionary
Hennigian" (sensu Ezard et al 2011) format, (2) information on the "mother 
lineage" of each tip in the phylogeny (see "mothers" section in "details" 
below), (3) the status ("extant" or "extinct") of each lineage, (4) the stem 
age (or age of origination of the clade), and (5) the "stem length" (or time 
interval between the stem age and the appearance of the first "daughter"). The 
user can also choose if the event dating should be done from root to tips or 
from tips-to-root (this choice is important - see "dating" section in "details"
below. The function returns a \code{sim} object (which contains speciation and
extinction times, parent, and status information). The function does not accept
more than one species having \code{NA} as parent (which is interpreted as if 
there were no single common ancestor in the phylogeny).
}
\details{
Mothers:

The function needs the indication of a mother lineage for every tip in the 
phylogeny but one (which is interpreted as the first known lineage in the 
clade, which should have \code{NA} as the mother). This assignment might be 
straightforward for simulations (as in the examples section below), but is 
evidently a non-trivial task for empirical phylogenies. As there are many 
ways to assign impossible combinations of motherthood, the function does not
return any specific error message if the provided motherhood does not map to
possible lineages given the phylogeny. Instead, simulations conducted by the 
author showed the function tends to crash when an "impossible" motherhood is 
assigned, but is not guaranteed that this will happen because of the enormous
universe of "impossible" ways to assign motherhood. However, if the function 
crashes when all lineages have reasonable motherhood, users are invited to 
contact the author.

Dating:

Phylogenies store relative distances between speciation (and possibly 
extinction) times of each lineage. However, to get absolute times for those 
events (which are required to construct the output of this function), users 
should provide a moment in absolute geological time to position the phylogeny. 
This could be (1) the present, in the case at least one lineage in the 
phylogeny is extant, or (2) some time in the past, which is the \code{stemAge} 
parameter. Those two possible dating methods are used by setting 
\code{dateFromPresent} to \code{TRUE} or \code{FALSE}, respectively (see 
\code{dateFromPresent} above). If users do not have a reasonable value for 
\code{stemAge}, they are encouraged to use present-to-root dating 
(\code{dateFromPresent = TRUE}), as deviations in the value of 
\code{stemLength} will only affect the speciation time of the first lineage of
the clade. When \code{dateFromPresent} is set to \code{FALSE}, eventual errors 
in \code{stemAge} or \code{stemLength} will bias the absolute (but not the
relative) dating of all nodes in the phylogeny.
}
\examples{

# to check the usage of the function, let us make sure it transforms a 
# phylogeny generated with make.phylo back into the original simulation

### 
# birth-death process

# simulate the clade
tmax <- 10
sim <- bd.sim(1, lambda = 0.3, mu = 0.1, tMax = tmax, nFinal = c(10, Inf))

# convert birth-death into phylo
phy <- make.phylo(sim)

# convert phylo into birth-death again
res <- phylo.to.sim(phy = phy, extant = sim$EXTANT, mothers = sim$PAR)

# test if simulation and converted object are the same
all.equal(sim, res)


###
# pure birth process

# simulate the clade
tmax <- 10
sim <- bd.sim(1, lambda = 0.2, mu = 0, tMax = tmax, nFinal = c(10, Inf))

# convert birth-death into phylo
phy <- make.phylo(sim)

# convert phylo into birth-death again
# note we can supply optional arguments, see description above
res <- phylo.to.sim(phy = phy, extant = sim$EXTANT, mothers = sim$PAR, 
                stemAge = tmax, stemLength = (tmax-sim$TS[2]), 
                dateFromPresent = TRUE)

# testing if simulation and converted object are the same
all.equal(sim, res)

}
\references{
Ezard, T. H., Pearson, P. N., Aze, T., & Purvis, A. (2012). The meaning of 
birth and death (in macroevolutionary birth-death models). Biology letters, 
8(1), 139-142.
}
\author{
Matheus Januario.
}
