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
```

