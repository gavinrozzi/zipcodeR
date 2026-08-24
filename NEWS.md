# *News*

# zipcodeR 0.4.0

## Breaking changes / behavior changes

- Distance calculations (`zip_distance()`, `search_radius()`) now use an
  internal haversine implementation (mean Earth radius 6,371,008.8 m) instead
  of `raster::pointDistance()`'s WGS84 geodesic. Distances may differ from
  previous releases by up to ~0.5% (typically ~0.1%). (#21, #24, #28)
- `reverse_zipcode()` now returns exactly one row per input element, in input
  order, with duplicates preserved and NA rows (plus a warning) for ZIP codes
  not found in `zip_code_db`. Previously results came back in database order
  and duplicate inputs were collapsed, which made the function unusable inside
  `dplyr::mutate()`. (#27)
- `geocode_zip()` likewise now preserves input order and duplicates and
  returns NA-coordinate rows (with a warning) for unmatched ZIP codes instead
  of silently dropping them; it still errors when no input ZIP matches. (#27)

## Dependency changes

- `raster` and `tidycensus` have been removed from Imports. Loading zipcodeR
  no longer pulls in the retired `sp` lineage or any GDAL/GEOS/PROJ/arrow
  system dependency, resolving the namespace load failure (#21), the
  `libarrow` GDAL warnings on load (#24), and the legacy-package retirement
  warning (#28). The Census FIPS code table previously read from
  `tidycensus::fips_codes` is now bundled as internal data
  (see `data-raw/fips_codes.R`).
- `tidyr` removed from Imports (replaced by base R in `normalize_zip()`).
- `jsonlite`, `httr`, `curl`, `RSQLite` and `DBI` moved from Imports to
  Suggests; they are only needed by `download_zip_data()`, which now prompts
  to install them via `rlang::check_installed()`.
- Imports is now: `dplyr`, `rlang`, `stringr`, `utils`.

## Performance

- `search_radius()` computes distances in a single vectorized call instead of
  a ~42,000-iteration loop, reducing a typical query from seconds to
  milliseconds. Further optimization is planned. (#33, with thanks to the
  reporter for the vectorization proposal)

## Bug fixes

- `search_radius()`'s filter for ZIP codes without coordinates was a no-op
  due to argument shadowing; it now correctly excludes coordinate-less rows.
- Fixed a latent error in `reverse_zipcode()`'s no-match path and removed the
  quadratic row-insertion loop.

## Documentation

- New FAQ vignette covering the western-hemisphere longitude sign convention
  (#14), missing ZIP codes and the ZIP-vs-ZCTA distinction (#19, #25, #26),
  jurisdiction accuracy limitations (#32), and the lazy-data installation
  error (#13).
- `zip_code_db` documentation now includes a provenance-and-limitations
  section (#32) and corrects the `zipcode_type` description; `zip_to_cd`
  documentation discloses its pre-2020-redistricting vintage (#29).
- Added regression tests for the `zip_distance()` ordering fix shipped in
  0.3.4. (#20)

## Infrastructure

- GitHub Actions workflows modernized to r-lib/actions v2 with an
  ubuntu/macOS/windows check matrix across release, devel, and oldrel-1,
  plus a Codecov test-coverage workflow.
- `inst/CITATION` migrated from the deprecated `citEntry()` to `bibentry()`.

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
