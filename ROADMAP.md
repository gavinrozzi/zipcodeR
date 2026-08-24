# zipcodeR Roadmap

zipcodeR is a solo-maintained civic open-source package. This roadmap favors
boring, low-maintenance solutions over clever ones, and keeps backward
compatibility sacred: no signature changes, column renames, or return-type
changes without a deprecation cycle.

## 0.4.0 — correctness, dependency hygiene, reproducible data *(this release)*

Everything on the `modernization-2026` branch (PR #34). Highlights, mapped to
issues:

| Item | Issues | Status |
|---|---|---|
| Vectorization contract for `reverse_zipcode()` / `geocode_zip()` (input order, duplicates, NA rows) | #27 | done |
| Regression tests for the `zip_distance()` ordering fix | #20 | done |
| Remove raster/tidycensus/tidyr; Imports = dplyr, rlang, stringr, utils; internal haversine | #21 #24 #28 | done |
| `search_radius()`: vectorized + bounding-box prefilter (~280× faster, `bench/`) | #33 | done |
| Reproducible data pipeline (`data-raw/`), validation gate, quarterly refresh workflow | #19 #25 #26 | done |
| Data refresh: every 2020 ZCTA, Military ZIPs, 91230-class USPS-only ZIPs, ACS 2023 attributes | #19 #25 #26 | done |
| `zip_to_cd` rebuilt on the 119th-Congress relationship file | #29 (PR #30 credited) | done |
| Data versioning: `zip_data_version()`, `data-YYYY.MM` release tags | — | done |
| Comprehensive DB as GitHub release asset + `download_comprehensive_data()` | — | done (draft release awaits publishing) |
| FAQ vignette; provenance/limitations docs | #13 #14 #32 | done |
| `download_zip_data()` deprecated (no-op) | — | done; remove in 0.6.0 |
| CI: r-lib/actions v2 matrix + coverage; pkgdown fix | — | done |

**Release checklist:** review/merge PR #34 → post the staged `issue_comments/`
drafts and close the referenced issues → publish the `data-2026.08` draft
release (activates `download_comprehensive_data()`; until published the
function fails with an explanatory error) → CRAN submission → tag `v0.4.0` →
reset `ACCEPTED_CD_COVERAGE_LOSS` to 0 in `data-raw/sources.R` (the 1,266-ZIP
one-time acceptance documented there and in NEWS).

## 0.4.x — patch follow-ups (as needed, small)

- HUD-USPS crosswalk stage in the pipeline (needs maintainer's free HUD API
  token as repo secret `HUD_API_KEY`): authoritative USPS-only ZIP universe,
  replacing `supplemental_zips.csv`. *(sized: 1 pipeline script + gate rule)*
- Set the `CENSUS_API_KEY` repository secret and do one manual
  `refresh-data` workflow run to validate the automation end to end.
- Backfill `bounds_*` for post-2021 ZIPs from TIGER/Line ZCTA bounding boxes
  (build-time-only sf dependency in `data-raw/`). *(sized: 1 script, ~1 GB
  download at build time; keep off hosted runners)*

## 0.5.0 — data-enrichment minor release

- **FIPS codes in `reverse_zipcode()` output** (#7): county FIPS is already
  derivable from the pipeline's county-relationship stage; add as new
  column(s) — additive, so backward compatible. *(sized: pipeline column +
  docs + tests)*
- **ZCTA crosswalk vignette**: worked examples joining `zip_code_db` to ACS
  tract data via `zcta_crosswalk`, with the ZIP≠ZCTA caveats front and
  center. *(sized: 1 vignette)*
- **Comprehensive-DB-backed enrichment**: a small family of functions reading
  the cached comprehensive database (e.g. `zip_demographics(zip, table)`),
  gated on `download_comprehensive_data()` having been run; consider
  rebuilding the comprehensive asset from current ACS via the pipeline
  instead of redistributing the 2022 upstream snapshot. *(sized: medium;
  design first)*
- **Timezone refresh**: replace carried-forward timezones with a build-time
  point-in-polygon pass against timezone-boundary-builder data. *(sized: 1
  pipeline script)*

## 0.6.0 — cleanup

- Remove `download_zip_data()` (deprecated no-op since 0.4.0).
- sf-native optional outputs (e.g. `search_radius(..., as_sf = TRUE)`) with
  sf in Suggests only — never in Imports. *(decide based on user demand;
  default is not to do it)*
- Revisit the blob list-columns (`common_city_list`, `area_code_list`):
  migrate to plain character JSON or list columns in a data-major release
  with a compatibility note.

## Standing policy

- **Data refreshes**: quarterly via the `refresh-data` workflow; a human
  always reviews the gate output and diff summary before merging. Data
  releases are tagged `data-YYYY.MM`, independent of code versions;
  `zip_data_version()` reports the loaded release.
- **Deprecation policy**: deprecate with a warning for at least one minor
  release before removal; NEWS documents every step.
- **Dependency policy**: core lookups must work with Imports = dplyr, rlang,
  stringr, utils. Anything heavier lives in Suggests behind
  `rlang::check_installed()` or in `data-raw/` (build-time only). No
  GDAL-linked or retired packages, ever.
