# *News*

# zipcodeR 0.4.0

## Data refresh & reproducible pipeline

- The bundled datasets are now built by a fully reproducible pipeline in
  `data-raw/` (pinned, checksummed sources; a hard validation gate; see
  `data-raw/README.md`), replacing the previously unscripted snapshot. A new
  `zip_data_version()` accessor reports exactly which data release is loaded.
- `zip_code_db` grows from 41,877 to 42,725 ZIP codes: every 2020 Census ZCTA
  is now present — including the Oregon ZIP 97003 (#25) and the ~2 dozen
  territory/new-development ZCTAs behind many reports of missing ZIPs (#19) —
  plus 787 `Military` ZIP codes (a new `zipcode_type` value) and curated
  USPS-only ZIP codes such as 91230 (#26). No ZIP codes were removed.
- Coordinates and land/water areas are refreshed from the Census 2024
  Gazetteer (authoritative 2020 ZCTA internal points, 6-decimal precision;
  previously 2-decimal geocodes), and demographic attributes from ACS 5-year
  estimates (vintage 2023). Distance results change accordingly — e.g. the
  README example pair 08731→08901 is now 43.8 mi (previously 40.75 mi with
  the coarser 2021 coordinates).
- `zcta_crosswalk` is rebuilt on the 2020 ZCTA/tract vintage (was 2010);
  tract GEOIDs change accordingly.
- `zip_to_cd` now maps to 119th-Congress districts, fixing the outdated
  pre-2020 crosswalk (#29). Thanks to @awallender, whose PR #30 established
  the method with the 118th-Congress file. ZCTA-backed ZIPs come straight
  from the Census relationship file (Census "ZZ" not-in-any-district
  pseudo-rows excluded); USPS-only ZIPs (P.O. Box/unique codes) are assigned
  the district(s) of their USPS city, or of their state where it has a
  single district. Military ZIPs have no mapping (overseas APO/FPO codes
  have no geographic district), and 1,266 USPS-only codes that the old
  pre-2020 crosswalk mapped have no principled current-vintage derivation;
  rather than carry their stale district numbers forward, they ship
  unmapped and `get_cd()` warns instead of silently returning an empty
  result. The planned HUD-USPS crosswalk stage will restore them with
  current data.
- New `download_comprehensive_data()` fetches the ~450 MB comprehensive
  database (full ACS profiles per ZIP code) from a versioned GitHub data
  release on demand, with SHA256 verification and caching in
  `tools::R_user_dir("zipcodeR", "data")`. Requires R >= 4.0 (Depends bumped
  from 3.5).
- A `refresh-data` GitHub Actions workflow (manual dispatch + quarterly)
  reruns the pipeline and opens a draft PR with a diff summary; a human
  always reviews and merges.

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

## Deprecations

- `zip_distance(lonlat = FALSE)` is deprecated. This mode had a unit bug in
  every previous release — it computed Euclidean distance in degree units and
  then applied the meters-to-miles conversion, returning 0.00 for essentially
  every pair of ZIP codes — so no historical result from it can have been
  meaningful. Until removal it warns and returns a planar equirectangular
  approximation in the requested units.
- `download_zip_data()` is deprecated and now performs no action beyond the
  deprecation warning. It could never refresh the data of an installed
  package (lazy data is baked in at install time), and when run from a
  source checkout it silently overwrote data files. Bundled data is
  refreshed with package releases through the `data-raw/` pipeline; the
  large companion database is available via `download_comprehensive_data()`.
  The function will be removed in a future release.

## Dependency changes

- `raster` and `tidycensus` have been removed from Imports. Loading zipcodeR
  no longer pulls in the retired `sp` lineage or any GDAL/GEOS/PROJ/arrow
  system dependency, resolving the namespace load failure (#21), the
  `libarrow` GDAL warnings on load (#24), and the legacy-package retirement
  warning (#28). The Census FIPS code table previously read from
  `tidycensus::fips_codes` is now bundled as internal data
  (see `data-raw/fips_codes.R`).
- `tidyr` removed from Imports (replaced by base R in `normalize_zip()`).
- `jsonlite`, `curl`, `RSQLite`, `DBI` and `openssl` moved from Imports to
  Suggests (`httr` is no longer used at all); they are needed only by
  `download_comprehensive_data()` (curl, optionally openssl) and by the
  `data-raw/` build pipeline, never by the core lookup functions.
- Imports is now: `dplyr`, `rlang`, `stringr`, `tools`, `utils`.

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
- `get_cd()` now warns informatively on a no-match, distinguishing ZIP codes
  absent from `zip_code_db` (likely typos or numeric input that lost its
  leading zero) from known ZIP codes that have no district mapping (military
  and some USPS-only codes).

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
