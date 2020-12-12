# *News*

# zipcodeR 0.2.0
- `search_county()` function now allows for approximate matching of county names using agrep (Andre Mikulec)
- `search_state()` is now vectorized and will accept a vector of state abbreviations
- `search_tz()` is now vectorized and will accept a vector of timezones
- `zip_code_db` has been updated to use latest upstream data
- Added `reverse_zipcode()` function for obtaining metadata about a given ZIP code.
- Added `search_cd()` function for searching ZIP codes contained within a given congressional district.
- Added `is_zcta()` function for testing whether a given ZIP code is a ZIP code tabulation area (ZCTA).
- Added `search_fips()` function for searching ZIP codes by state and county FIPS codes.
- Added `get_cd()` and `search_cd()` functions for relating ZIP codes to congressional districts
- Added the first vignette, "Introduction to zipcodeR"

# zipcodeR 0.1.0
Initial public release, first version accepted by CRAN.
