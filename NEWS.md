# zipcodeR 0.4.0

## Reproducibility contract

- Every pre-existing exported function retains the zipcodeR 0.3.5 signature,
  return value, class, attributes, row order, rounding, warnings, messages,
  errors, and edge-case behavior. This deliberately includes historical
  defects where changing them could alter published research.
- The bundled `zip_code_db`, `zcta_crosswalk`, and `zip_to_cd` objects are
  identical to 0.3.5: 41,877 ZIP rows, 148,897 ZCTA-to-tract rows, and 45,914
  ZIP-to-district rows.
- `zip_distance()` and `search_radius()` retain the legacy
  `raster::pointDistance()` WGS84 calculation. `search_radius()` now invokes
  that same calculation in a vectorized call; the differential gate requires
  exact object identity with 0.3.5 before accepting the speedup.
- `Depends: R (>= 3.5.0)` and the legacy runtime dependencies are retained.
  `download_zip_data()` keeps its prior observable behavior. Documentation,
  rather than a runtime warning or no-op, discourages its use.

## Explicit next-generation API

- The `_ng` API is the recommended interface for new analyses. Its suffix
  makes the opt-in visible in code: callers choose newer, versioned data and
  corrected semantics while existing unsuffixed calls stay historical.
- Corrected behavior and modern data are opt-in through the `_ng`
  functions: `search_state_ng()`, `search_county_ng()`, `search_city_ng()`,
  `search_tz_ng()`, `search_fips_ng()`, `search_cd_ng()`,
  `search_radius_ng()`, `reverse_zipcode_ng()`, `geocode_zip_ng()`,
  `get_tracts_ng()`, `get_cd_ng()`, `is_zcta_ng()`, `normalize_zip_ng()`, and
  `zip_distance_ng()`.
- Every data-dependent `_ng` function requires an explicit validated data
  bundle as its first argument. No lookup resolves a `latest` alias, consults
  a global option, mutates the session, falls back to another vintage, or
  performs an implicit network request.
- `_ng` never means an unpinned "latest" dataset. A project selects and records
  one immutable bundle version and checksum.
- `download_zip_data_bundle(version)`, `read_zip_data_bundle(path)`,
  `zip_data_version(x)`, and `zip_data_provenance()` support checksum-pinned,
  offline, and auditable research workflows.
- `_ng` lookups preserve input order and duplicates, represent missing rows
  explicitly, validate inputs consistently, use modern geodesic behavior,
  keep GEOIDs as character identifiers, and expose authoritative/unmapped
  district status.
- `reverse_zipcode_ng()` adds the two-digit state FIPS code and full five-digit
  county FIPS code for the record's predominant county.
- `raster` and `tidycensus` remain installed legacy dependencies, but are no
  longer imported when `zipcodeR` starts. They load only when a legacy function
  actually calls them, avoiding the historical `raster`/`terra` and GDAL/Arrow
  startup failures without changing legacy results.

## Versioned data assets

- Refreshed data is no longer substituted into the package defaults. The
  pipeline writes one external RDS bundle with dataset, metadata, provenance,
  and quality sidecars, plus a manifest and reproducibility archive.
- Static sources, the raw ACS response, and the derived ACS table are archived
  and checksummed. GeoNames is pinned rather than floating. The data version
  and build timestamp are explicit inputs; the full package dependency graph
  is locked.
- ZIP candidates absent from an authoritative ZCTA source are quarantined.
  Proxy city points are not published as ZIP centroids. District assignments
  use the Census relationship file only; USPS-only ZIPs without an
  authoritative relationship remain unmapped with a reason.
- Upstream inspection and deterministic rebuilds are separate workflow modes.
  The workflow uploads unpublished candidates for review and never chooses a
  version or publishes automatically.
- Bundle download registries remain disabled until their assets are public and
  have passed clean-machine URL and checksum smoke tests. Likewise,
  `download_comprehensive_data()` fails before network access while its
  currently referenced release is still a draft.

## Tests, documentation, and infrastructure

- `tools/compatibility-check.R` installs 0.3.5 and the candidate in isolated
  libraries, then compares the public datasets, legacy calls, conditions, and
  function signatures with `identical()`.
- Independent tests cover bundle schema/checksum failures, cache corruption,
  explicit version handling, `_ng` order/duplicate/missing behavior,
  antimeridian and threshold searches, unavailable coordinates, and
  authoritative/unmapped district behavior.
- CI runs ordinary vignette-building `R CMD check --as-cran` on Windows,
  macOS, Ubuntu release/devel/oldrel and runs the differential gate. The
  Windows SHA fallback ignores non-portable `shasum.bat` wrappers.
- A migration vignette documents unchanged legacy calls, explicit bundle
  pinning, `_ng` calls, and recording both data version and bundle SHA in
  research outputs.
- `inst/CITATION` uses `bibentry()` rather than deprecated `citEntry()`.

# zipcodeR 0.3.5

- Hotfix to address a failing vignette and prevent archival by CRAN.

# zipcodeR 0.3.4

- Fixed ordering of `zip_distance()` results (contributed by Nicholas X Lee).

# zipcodeR 0.3.3

- Vectorized `zip_distance()` across two vectors or columns of ZIP codes.
- Added the `units` argument to return miles or meters.

# zipcodeR 0.3.2

- Updated `zip_code_db`.
- Refactored `download_zip_data()` to download directly from upstream.
- Added the `lonlat` distance-calculation argument.
- Added package citation data.

# zipcodeR 0.3.1

- Removed the `{udunits2}` dependency from distance and radius functions.

# zipcodeR 0.3.0

- Added `search_radius()`, `zip_distance()`, `geocode_zip()`, and
  `normalize_zip()`.
- Updated `reverse_zipcode()` to return a blank row for unmatched ZIP codes.
- Made the `search_` family quieter.

# zipcodeR 0.2.0

- Added approximate county matching, vectorized state/timezone searches,
  reverse lookup, congressional-district helpers, ZCTA testing, and FIPS
  searches.
- Updated the ZIP database and added the introductory vignette.

# zipcodeR 0.1.0

- Initial CRAN release.
