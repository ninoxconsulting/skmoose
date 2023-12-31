% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/high_elev.R
\name{high_elev}
\alias{high_elev}
\title{Get high elevation areas}
\usage{
high_elev(dem, elev_thresh = 1300)
}
\arguments{
\item{dem}{an tif with elevation data}

\item{elev_thresh}{default elevation at which moose would be unlikely to pass, default = 1300m}
}
\value{
a geopackage with single polygon that shows elevation above the given threshold
}
\description{
Get high elevation areas
}
\examples{
\dontrun{
high_elev(dem, 1300)
}
}
