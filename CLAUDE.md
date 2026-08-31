# CLAUDE.md

This file provides repository guidance for coding agents.

## Package contract

zipcodeR provides offline U.S. ZIP-code lookups and basic spatial analysis.
The existing exported API is a frozen research-reproducibility contract: legacy
functions, conditions, ordering, side effects, and the three bundled datasets
must remain exactly compatible with zipcodeR 0.3.5.

Corrected behavior and refreshed data are opt-in through the `_ng` functions.
Every data-dependent `_ng` function takes an explicit, validated data bundle as
its first argument. Never add an implicit "latest" version, automatic download,
global option, or fallback to the bundled legacy data.

## Development commands

```bash
devtools::test()
Rscript tools/compatibility-check.R --baseline-ref=origin/master
Rscript bench/search_radius_bench.R
devtools::check(args = "--as-cran")
devtools::document()
```

## Architecture

### Frozen legacy data (`data/`)

- `zip_code_db`: 41,877 rows and 24 columns, data date 2021-06-08.
- `zcta_crosswalk`: 148,897 legacy ZCTA-to-tract relationships.
- `zip_to_cd`: 45,914 legacy ZIP-to-district relationships.

These objects must remain `identical()` to the 0.3.5 objects. Modern data is
never written into `data/`.

### R code (`R/`)

- `zip_lookups.r`, `zip_helper_functions.R`, and `download_data.r` implement
  the frozen legacy contract. Legacy distance calculations intentionally retain
  `raster::pointDistance()` WGS84 behavior.
- `ng_functions.R` implements corrected lookups and modern haversine distance
  calculations against an explicit bundle.
- `data_bundle.R` validates, reads, downloads, and reports metadata for pinned
  data bundles.
- `data_version.R` contains the legacy metadata and comprehensive-asset API.
- `distance.R` is an internal helper used only by the `_ng` path.

`download_zip_data()` intentionally retains its 0.3.5 observable behavior.
Discourage it in documentation only during this compatibility release.

### External data pipeline (`data-raw/`)

The pipeline creates versioned data-only release assets, not package datasets.
Deterministic rebuilds require `PIPELINE_MODE=rebuild`, an explicit
`PIPELINE_DATA_VERSION`, and an explicit `PIPELINE_BUILD_TIMESTAMP`. Exact raw
responses, source checksums, the dependency lock, and the build container are
archived with each release. `refresh_sources.R` proposes new source pins but
does not build or publish anything.

## Tests and release gates

- `tools/compatibility-check.R` installs the baseline and candidate into
  isolated libraries and compares datasets, results, conditions, and formals.
- `tests/testthat/test-04-data-bundles.R` covers integrity and download failure
  cases.
- `tests/testthat/test-05-ng-api.R` covers the corrected API contract.
- `.github/workflows/R-CMD-check.yaml` runs compatibility and normal package
  checks on Windows, macOS, Ubuntu release/devel/oldrel.
- `.github/workflows/refresh-data.yaml` is manual. It can refresh source
  proposals or run a two-pass deterministic rebuild, but never publishes.

Do not claim a data version is available or enable its downloader until its
release and checksum-verified asset are public and smoke-tested from a clean
machine.
