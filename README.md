# zipcodeR <a href='https://dplyr.tidyverse.org'><img src='man/figures/logo.png' align="right" height="139" /></a>

### Makes dealing with U.S. ZIP codes easier. **Work in progress.**

## Installation
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

# Find all ZIP codes for a timezone
search_tz('Eastern')

# Get all Census tracts for a given ZIP code
get_tracts('08731')
```

## Documentation
Documentation for the project [is available here.](https://gavinrozzi.github.io/zipcodeR/)
See the [function reference](https://gavinrozzi.github.io/zipcodeR/reference/) for full details on how to use each of the functions provided by zipcodeR.

## Data Sources
This project was inspired by the excellent [uszipcode](https://uszipcode.readthedocs.io/index.html) library for Python and utilizes the same backend database released by its author. This project also incorporates open data from the U.S. Census Bureau.
