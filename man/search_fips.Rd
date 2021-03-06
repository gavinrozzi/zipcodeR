% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zip_lookups.r
\name{search_fips}
\alias{search_fips}
\title{Returns all ZIP codes found within a given FIPS code}
\usage{
search_fips(state_fips, county_fips)
}
\arguments{
\item{state_fips}{A U.S. FIPS code}

\item{county_fips}{A 1-3 digit county FIPS code (optional)}
}
\value{
tibble of Census tracts and data from Census crosswalk file found for given ZIP code
}
\description{
Returns all ZIP codes found within a given FIPS code
}
\examples{
search_fips('34')
search_fips('34','03')
search_fips('34','3')
search_fips('36','003')
}
