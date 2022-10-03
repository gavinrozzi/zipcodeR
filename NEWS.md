# *News*

# zipcodeR 0.3.5
- Hotfix to address failing vignette to prevent package being archived by CRAN team.

# zipcodeR 0.3.4
-  Bug fix. Resolved an issue with ordering `zip_distance()` results (Pull request contributed by Nicholas X Lee).

# zipcodeR 0.3.3
- This update vectorizes the `zip_distance()` function to allow distance calculations between two vectors or columns of ZIP codes. The function now returns a data.frame of the resulting distance calculation.
- `zip_distance()` now includes an additional argument, units, which allows selection between miles and meters for distance calculations.

# zipcodeR 0.3.2
- `zip_code_db` has been updated.
- `download_zip_data()` has been refactored to make data updates more easily accessible and compare against existing data. Data is now directly downloaded from the upstream source and the existing data GitHub repository will no longer be updated.
- `zip_distance()` has been updated to allow changing the type of distance calculation performed if specified via the lonlat argument.
- Citation data is now included with package. If using `{zipcodeR}` in a publication, you can obtain citation info by running `citation("zipcodeR")`.
- Misc updates to documentation and package reference info.

# zipcodeR 0.3.1
- Hotfix to address a problem for Mac users on the latest R release, the package no longer depends on `{udunits2}` for the `zip_distance()` and `search_radius()` functions.

# zipcodeR 0.3.0
- Added `search_radius()` function to allow searching for ZIP codes around a radius of lat / lon coordinates.
- Added `zip_distance()` function for calculating the distance between ZIP codes using their centroids.
- Added `geocode_zip()` function that returns the lat / lng centroid of a given ZIP code.
- Added `normalize_zip()` function for normalizing messy ZIP code input (Contributed by Claus Wilke).
- The `reverse_zipcode()` function has been updated to return a blank row for invalid ZIP codes with no matches in the zip code database.
- The `search_` family of functions are now quieter.

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
