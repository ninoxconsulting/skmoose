% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fire.R
\name{fires_recent}
\alias{fires_recent}
\title{Select recent fire years for Moose habitat}
\usage{
fires_recent(fires, fire_min_yr = 10, fire_max_yr = 25)
}
\arguments{
\item{fires}{sf object with all fires}

\item{fire_min_yr}{numeric minimum age since fire, default = 10.}

\item{fire_max_yr}{numeric maximum age since fire, default = 25}
}
\value{
sf object with filtered fires
}
\description{
Select recent fire years for Moose habitat
}
\examples{
\dontrun{
fires_recent(fires, 10, 25 )
}

}
