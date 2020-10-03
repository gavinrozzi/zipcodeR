# zipcodeR <a href='https://gavinrozzi.github.io/zipcodeR/'><img src='man/figures/logo.png' align="right" height="139" /></a>
[![Build Status](https://travis-ci.com/gavinrozzi/zipcodeR.svg?branch=master)](https://travis-ci.com/gavinrozzi/zipcodeR)
[![CRAN Status](https://www.r-pkg.org/badges/version-last-release/zipcodeR)](https://www.r-pkg.org/badges/version-last-release/zipcodeR)
[![CRAN Downloads](https://cranlogs.r-pkg.org/badges/grand-total/zipcodeR)](https://cranlogs.r-pkg.org/badges/grand-total/zipcodeR)

### Makes dealing with U.S. ZIP codes painless.

**zipcodeR** is an R library that makes working with ZIP codes in R easier. It provides data on all U.S. ZIP codes using multiple open data sources, making it easier for social science researchers and data scientists to work with ZIP code-level data in projects. 

## Installation
Install the current release from CRAN:
```r
install.packages('zipcodeR')
```

The latest development version can be installed like so using devtools:
``` r
library(devtools)
install_github("gavinrozzi/zipcodeR")
```
## Usage
``` r
# Load the zipcodeR library into R
library(zipcodeR)

# Find all ZIP codes for a state
search_state('NJ')

# Find all ZIP codes for a county
search_county('Ocean','NJ')

# Find ZIP codes for a city
search_city('Chappaqua','NY')

# Find all ZIP codes for a timezone
search_tz('Eastern')

# Get all Census tracts for a given ZIP code
get_tracts('08731')
```

## Documentation
Documentation for the current release [is available here.](https://gavinrozzi.github.io/zipcodeR/)
See the [reference section](https://gavinrozzi.github.io/zipcodeR/reference/) for full details on how to use each of the functions provided by zipcodeR.

Documentation for the current development version [can be viewed here.](https://zipcoder-documentation-dev.netlify.app) This version contains new features and functions that may have not been fully tested, but may be used in a future release.

## Data Sources
This project was inspired by the excellent [uszipcode](https://uszipcode.readthedocs.io/index.html) library for Python and utilizes the same backend database released by its author under the MIT license. This project also incorporates open data from the U.S. Census Bureau and Department of Housing & Urban Development.
