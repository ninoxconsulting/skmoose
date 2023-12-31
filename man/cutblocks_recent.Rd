% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cutblocks.R
\name{cutblocks_recent}
\alias{cutblocks_recent}
\title{Select recent cutblocks for Moose habitat}
\usage{
cutblocks_recent(cutblocks, cutblock_min_yr = 5, cutblock_max_yr = 25)
}
\arguments{
\item{cutblocks}{sf object with all cutblocks}

\item{cutblock_min_yr}{numeric minimum age since date, default = 5.}

\item{cutblock_max_yr}{numeric maximum age since harvest, default = 25}
}
\value{
sf object with filtered cutblocks
}
\description{
Select recent cutblocks for Moose habitat
}
\examples{
\dontrun{
cutblocks_recent(cutblocks, 5, 25 )
}

}
