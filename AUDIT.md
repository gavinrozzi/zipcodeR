# zipcodeR Phase 0 Audit

> **Historical discovery document.** This audit predates differential testing
> against the installed 0.3.5 package. That later testing showed that replacing
> datasets, distance algorithms, conditions, and side effects would break the
> research-reproducibility contract. Recommendations below such as removing
> `raster`, changing distance math, or refreshing bundled data are therefore
> superseded for the 0.4.0 legacy API. They may inform the explicit `_ng` API or
> a future major release only; see `ROADMAP.md` and `NEWS.md` for current policy.

**Date:** 2026-08-24 · **Branch:** `modernization-2026` · **Package version audited:** 0.3.5 (master @ 48ed689)

This document records the discovery phase of the modernization effort: the current state of
the package, its dependency tree, the provenance and reproducibility of its bundled data,
the exact transformation contract between upstream and the shipped datasets, and a
classification of every data-related issue report. **No code changes accompany this
document.** The recommended branch decision for Phase 2 is at the end.

---

## 1. R CMD check --as-cran baseline

_(Environment: R 4.6.1 aarch64-apple-darwin, Homebrew; all Imports/Suggests installed from
source.)_

`R CMD check --as-cran zipcodeR_0.3.5.tar.gz` → **Status: 1 ERROR, 2 WARNINGs, 3 NOTEs**,
of which the package-substantive findings are:

- **WARNING (CRAN incoming):** `Package CITATION file contains call(s) to old-style
  citEntry(). Please use bibentry() instead.` → Phase 1 fix.
- **WARNING (CRAN incoming):** `Insufficient package version (submitted: 0.3.5, existing:
  0.3.5)` → expected pre-bump; resolved by the Phase 1 version increment.
- **NOTE (top-level files):** `AUDIT.md`, `CLAUDE.md` non-standard at top level → add to
  `.Rbuildignore` in Phase 1.

Environmental noise on this machine (not package defects): PDF-manual ERROR/WARNING
(`pdflatex is not available` — no TeX installed), HTML-validation NOTE (old HTML Tidy),
and a `zipcodeR-manual.tex` leftover NOTE consequent on the missing TeX. No errors,
warnings, or notes in code checks, examples, tests, or vignette rebuilds.

**Test suite baseline** (`devtools::test()`): **51 PASS / 0 FAIL / 28 WARN** — every
warning is the tidyselect `.data`-in-`select()` deprecation (§5 misc hygiene).

## 2. Dependency audit

### 2.1 Declared dependencies (DESCRIPTION @ 0.3.5)

- **Depends:** R (>= 3.5.0)
- **Imports:** rlang, stringr, raster, tidycensus, tidyr, dplyr, jsonlite, httr, curl, RSQLite, DBI (no version pins)
- **Suggests:** knitr, rmarkdown, markdown, readr, testthat (>= 3.0.0), covr, tibble
- **Undeclared but used:** `utils` (`utils::download.file`, `utils::globalVariables`)

### 2.2 What each import is actually used for

| Package | Every usage site | Verdict |
|---|---|---|
| `raster` | `raster::pointDistance()` only — `R/zip_helper_functions.R:102` (`zip_distance`), `R/zip_lookups.r:364` (`search_radius`) | **Remove.** Replace with ~10-line vectorized haversine (base R). |
| `tidycensus` | `tidycensus::fips_codes` dataset only — `R/zip_lookups.r:185` (`search_fips`), `:249` (`get_cd`). Imported *wholesale* (`@import tidycensus` → `import(tidycensus)` in NAMESPACE). | **Remove.** Vendor the ~3,200-row FIPS table (public-domain Census data) as package data via a `data-raw/` script. |
| `tidyr` | `tidyr::extract()` once, inside `normalize_zip()`'s `capture_group()` helper (`R/zip_helper_functions.R:16`) | **Remove.** One base-R regex call. |
| `jsonlite`, `httr`, `curl`, `RSQLite`, `DBI` | `download_zip_data()` only (`R/download_data.r`) | **Demote/remove** with the `download_zip_data()` redesign (see §5.4) — either Suggests + `rlang::check_installed()` or dropped entirely when the refresh moves to `data-raw/`. |
| `dplyr` | Pervasive in all lookup functions | Keep. |
| `rlang` | `.data` pronoun; `list2()` at `zip_lookups.r:38` | Keep (shrink usage). |
| `stringr` | `str_detect` in search functions | Keep (or base-R; low priority). |

**End state:** `Imports: dplyr, rlang, stringr, utils` — zero GDAL, zero arrow, zero
retired-lineage packages at load time.

### 2.3 The legacy-stack chains (issues #21, #24, #28)

- `raster` → **`sp`** (emits the rgdal/rgeos retirement startup message = issue **#28**) and
  → `terra` (links GDAL/GEOS/PROJ system libraries). The #21 load failure
  ("`coerce` … Raster, SpatRaster") is a classic stale-binary collision between `raster`
  and `terra` — impossible once `raster` is gone.
- `tidycensus` → **`sf`** (GDAL at load; on distros whose GDAL links libarrow this produces
  the issue **#24** `libarrow.so.800` warnings) plus tigris, rvest, units, and a long tail.
- Neither chain is needed: one is two distance calls, the other is a static lookup table.
- Measured cost on this machine (R 4.6.1/arm64): attaching `raster` + `tidycensus` takes
  ~2.6 s and loads **54 namespaces** vs 21 for a dplyr-only baseline — all incurred by
  `library(zipcodeR)` today. (Modern `sp` ≥2.x no longer prints the #28 retirement
  banner, but the GDAL/PROJ/GEOS load-time exposure and install burden remain.)

## 3. Upstream reproducibility (uszipcode-project)

### 3.1 Verdict: build scripts for the current data are NOT public — reconstruct

- `MacHu-GWU/uszipcode-project` (MIT license, last data release Jan 2022) today contains
  only the client library (`uszipcode/model.py`, `search.py`, `db.py` which downloads the
  prebuilt SQLite from GitHub releases).
- Full git history (82 commits, back to 2015) was scanned. A deleted `dataset/` directory
  was recovered from the parent of the `1.0.1 pre CI commit` (`d4ede94^`), containing
  `step1_geocoding.py`, `step2_merge_zipcode_data.py`, `step3_make_database.py` plus two
  source archives (`federalgovernmentzipcodes.zip` from federalgovernmentzipcodes.us,
  2012 vintage; `zcta2010.zip` Census 2010 ZCTA data). **These are the v0.0.8-era (2016)
  scripts** for the *old* schema (IRS wages, Google-geocoded bounds) — not the pipeline
  that produced the 2021/2022 `simple_db`/`comprehensive_db` (ACS-era schema with
  median_household_income, timezone, area codes, …). They also depend on dead packages
  (`geomate`, `sqlite4dummy`) and personal Google API keys. Recovered copies are archived
  for provenance but are **not runnable and do not produce the current schema**.
- No sibling/crawler repo exists under the author's account; the data.census.gov crawler
  behind the 1.0.1 release was never published.

**Conclusion:** the Phase 2 pipeline must be a reconstruction in R from primary sources,
using the upstream SQLite snapshots as a *validation reference*, not as a build input.
MIT licensing on upstream and public-domain status of the underlying Census/IRS data make
this unproblematic; attribution to uszipcode-project stays in the docs.

### 3.2 Upstream snapshots (validation references)

| Release | Asset | Size | SHA256 | Rows (`simple_zipcode`) |
|---|---|---|---|---|
| `0.2.6-db-file` (2021-06-08) | simple_db.sqlite | 9,965,568 | `f7c1c9461f9ef648e83e243e6bbe4abe1d116e70e6e4a92aa52f9ea2ae80b3ba` | **41,877** |
| `1.0.1.db` (2022-01-05) | simple_db.sqlite | 10,727,424 | `43383f108ef14dccd925107bc77705f622b1014111ad5c9e5e2a6837bb7f64ff` | **42,724** |
| `1.0.1.db` (2022-01-05) | comprehensive_db.sqlite | 456,556,544 | `d85ed4e25884bc27bdd339d57dd9e2d1763531d4c050acb7a05a3d5aca90668d` | 42,724 (see §3.4) |

Set difference: 1.0.1 = 0.2.6 + 847 new ZIPs (787 MILITARY — a type absent from 0.2.6 —
plus 30 PO BOX, 20 STANDARD, 10 UNIQUE), **zero ZIPs dropped**.

⚠ Value-compat caveat: 0.2.6 stores `zipcode_type` titleized (`Standard`, `PO Box`,
`Unique`); 1.0.1 switched to uppercase (`STANDARD`, `PO BOX`, `UNIQUE`, `MILITARY`).
Shipped `zip_code_db` has the titleized values, and `reverse_zipcode()` tests match on
them — any refresh from 1.0.1-schema data must normalize case to preserve the contract.

### 3.3 simple_zipcode schema (both releases identical)

24 columns: `zipcode` (TEXT, PK), `zipcode_type`, `major_city`, `post_office_city`,
`common_city_list` (BLOB: zlib-compressed JSON array), `county`, `state`, `lat`, `lng`
(FLOAT, indexed), `timezone`, `radius_in_miles`, `area_code_list` (BLOB: zlib JSON),
`population`, `population_density`, `land_area_in_sqmi`, `water_area_in_sqmi`,
`housing_units`, `occupied_housing_units`, `median_home_value`,
`median_household_income`, `bounds_west/east/north/south`.

Most plausible primary sources per field (for the reconstruction pipeline):

| Field(s) | Source |
|---|---|
| zipcode, zipcode_type, major_city, post_office_city, common_city_list | USPS ZIP data (via a licensed-free mirror such as the HUD-USPS crosswalk for existence/city, GeoNames, or federalgovernmentzipcodes-style compilations; needs a licensing check — see §7) |
| county, state | USPS city/state + Census county assignment of the ZCTA |
| lat, lng, bounds_* , land/water_area | Census 2020 ZCTA Gazetteer + TIGER/Line ZCTA shapefiles |
| population, population_density, housing_units, occupied_housing_units, median_home_value, median_household_income | Census ACS 5-year at ZCTA level (tables B01003, B25001/2, B25077, B19013) |
| timezone | point-in-polygon of centroid vs IANA tz boundaries (e.g. timezone-boundary-builder data) |
| radius_in_miles | derived: sqrt(land_area/π) or bounds-based |
| area_code_list | NANPA area-code data (or drop-forward as frozen; roadmap decision) |

### 3.4 comprehensive_db schema

Two tables: `simple_zipcode` (identical to the simple DB) and `comprehensive_zipcode`
(42,724 rows, 54 columns): the same 24 base columns, plus `polygon` (ZCTA boundary,
compressed JSON) and 29 rich ACS-profile columns stored as zlib-compressed JSON blobs —
`population_by_year`, `population_by_age/gender/race`, `head_of_household_by_age`,
`families_vs_singles`, `households_with_kids`, `children_by_age`, `housing_type`,
`year_housing_was_built`, `housing_occupancy`, `vacancy_reason`,
`owner_occupied_home_values`, `rental_properties_by_number_of_rooms`,
`monthly_rent_including_utilities_{studio,1b,2b,3plus_b}`, `employment_status`,
`average_household_income_over_time`, `household_income`, `annual_individual_earnings`,
four `sources/investment/retirement_income` pairs, `source_of_earnings`,
`means_of_transportation_to_work_for_workers_16_and_over`,
`travel_time_to_work_in_minutes`, `educational_attainment_for_population_25_and_over`,
`school_enrollment_age_3_to_17`. All are data.census.gov ACS profile aggregates keyed by
ZCTA — the source set for the Phase 2 "comprehensive" release asset and the #7 FIPS/
enrichment roadmap items.

## 4. The transformation contract (upstream → zip_code_db)

`download_zip_data()` (`R/download_data.r:80-83`) reveals the original derivation:

```r
zip_code_db <- DBI::dbGetQuery(conn, "SELECT * FROM simple_zipcode")
save(zip_code_db, file = ...)
```

i.e. an **identity transformation**: all 24 columns, upstream order, RSQLite default type
mapping (TEXT→character, FLOAT→numeric, INTEGER→integer, BLOB→`blob` list-column of
zlib-compressed raw vectors), rows in SQLite storage order, class `data.frame`.
`R/sysdata.rda` stores `zip_code_db_version = "2021-06-08"` — exactly the publish date of
the `0.2.6-db-file` release, confirming the shipped data is the **0.2.6 snapshot** (41,877
rows match; row 1 = 35004 Moody AL matches; `zipcode_type` titleization matches).

**Verified 2026-08-24:** loading the 0.2.6 `simple_db.sqlite` via
`DBI::dbGetQuery(conn, "SELECT * FROM simple_zipcode")` and comparing to the shipped
`data/zip_code_db.rda` yields `identical() == TRUE` — zero differences per
`waldo::compare()`. The compatibility contract is therefore precisely: *the 24-column
`simple_zipcode` schema, RSQLite default type mapping, SQLite storage order, class
`data.frame`, titleized `zipcode_type` values, blob list-columns for the two JSON fields.*

Note the `blob` class on `common_city_list`/`area_code_list` exists only because the
data was built through RSQLite; nothing in Imports provides the `blob` package that
defines the class, so those columns print as raw zlib bytes for end users. This is an
existing wart to address (with compatibility care) in the data-pipeline phase.

The other two datasets:

- `zcta_crosswalk` (tibble, 148,897 × 3: ZCTA5, TRACT, GEOID) — selected columns of the
  Census **2010** ZCTA↔tract relationship file. 2010 vintage; a 2020 refresh changes
  GEOIDs (Phase 2, with a documented migration note).
- `zip_to_cd` (data.frame, 45,914 × 2: ZIP, CD = state FIPS + district) — HUD-USPS
  crosswalk vintage pre-2020 redistricting (issue #29). PR #30 (@awallender) demonstrates
  the modern method with the Census 2020 CD118↔ZCTA relationship file; Phase 2 should use
  the same method with the current CD119 file and credit the contribution.

## 5. Function-level defect inventory

(Each maps to a Phase 1/3 fix with a regression test and a staged issue comment.)

| # | Function / site | Defect |
|---|---|---|
| #27 | `reverse_zipcode()` `R/zip_lookups.r:89-118` | **Reproduced on master 2026-08-24**: the issue's 13-row `mutate()` reprex fails with `county must be size 13 or 1, not 12`, and `reverse_zipcode(c("08734","08731"))` returns 08731 first (database order). Output ordered by database order, not input order (`%in%` filter); **duplicate inputs collapse to one row**, breaking `mutate()`'s length contract (the reported error). NA-row insertion is an O(n²) `add_row` loop; `.data` misused inside `stop()` at :115 (would itself error); scalar-only length check at :91-96 skips vectors. |
| #20 | `zip_distance()` `R/zip_helper_functions.R:80-116` | Reported swap **already fixed in 0.3.4 — verified on master 2026-08-24** with both reprexes from the issue: `zip_distance(c("08731","08734"), c("08901","08005"))` → 40.70 / 8.06 mi (correct pairing) and the repeated-pair case → 0.0 / 6.9 (correct). Phase 1 = regression tests + staged closing comment. Remaining latent defects: relies on `zipcode` uniqueness with no guard; `filter(lat != "NA")` string comparison at :90; `lonlat = FALSE` documents planar distance on raw degrees (meaningless units). |
| #33 | `search_radius()` `R/zip_lookups.r:355-383` | ~42k-iteration R loop calling `raster::pointDistance` per row (reporter measured ~40× speedup from vectorizing alone). Additional bug at :360: `filter(lat != "NA")` resolves `lat` to the *function argument*, so the intended NA-coordinate filter is a no-op. Phase 3: vectorized haversine + bounding-box prefilter. |
| — | `geocode_zip()` `R/zip_lookups.r:324-340` | Same order bug as reverse_zipcode; silently drops unmatched ZIPs (output shorter than input). |
| — | `download_zip_data()` `R/download_data.r` | Writes into the installed package directory via `system.file()` — CRAN policy violation, fails on read-only libraries, and under `LazyData: true` the written `.rda` is **never loaded** (installed data lives in `data/Rdata.rdb`), so the refresh mechanism has never actually worked post-install. All `file.exists(system.file("data", "*.rda"))` guards are permanently FALSE on installed packages. Crosswalk URLs point at the abandoned `gavinrozzi/zipcodeR-data` repo. Internet check happens *after* the first network call. |
| — | `get_cd()` `R/zip_lookups.r:261-264` | Computed `output` (with a fragile hardcoded rename) discarded; returns a bare `list()`. Also `nchar(county_fips < 3)` misplaced parenthesis at :197 (`search_fips`) — always-true condition, harmless only by accident. |
| #14 | `geocode_zip()` docs | Not a bug: negative longitude is the western hemisphere sign convention. Fix via docs + pkgdown FAQ. |
| #13 | data access | `zip_code_db not found` reports trace to broken/partial installs of lazy-loaded data; add FAQ + `R CMD check`-clean reinstall guidance. |
| — | Misc hygiene | tidyselect `.data`-in-`select()` deprecation warnings (`zip_lookups.r:287,332,374`, `zip_helper_functions.R:89`); deprecated `citEntry()` in `inst/CITATION`; `test-03-helper-functions.R` assertions outside `test_that()`; duplicated `%>%` importFrom; `R/data.r:20` documents `zipcode_type` as "2010 State FIPS Code" (copy-paste error). |
| — | CI | `R-CMD-check.yaml` uses r-lib/actions **v1** on retired `ubuntu-20.04` images with focal RSPM URLs; no oldrel job. `pkgdown.yaml` is already modern (v2). |

## 6. Missing-ZIP forensics (#25, #26, #19)

Authoritative reference: distinct 2020 ZCTAs from the Census CD118↔ZCTA national
relationship file = **33,791 ZCTAs**.

| Report | ZIP(s) | Shipped 0.2.6 data | Upstream 1.0.1 | 2020 ZCTA? | Classification |
|---|---|---|---|---|---|
| #26 | 91230 (Glendale CA) | absent | absent | **no** | USPS-only (PO-Box-type) ZIP, never covered by upstream's ZCTA-centric sources. Genuinely valid ZIP; needs a USPS-derived source (HUD crosswalk has it) in the reconstruction pipeline. |
| #25 | 97003 (Beaverton OR) | absent | present but **lat/lng = 0.0** | yes | Missing upstream in 0.2.6; added in 1.0.1 with a bad (0,0) geocode. Fix = reconstruction with Census Gazetteer coordinates. The "dozen other Oregon ZIPs" were never enumerated in the issue (empty body); Oregon otherwise fully covered — 97003 is the *only* 2020 OR ZCTA absent from shipped data. |
| #19 | "many ZIPs" in `zip_distance` | — | — | — | Two causes: (a) staleness above; (b) **8,773 of 41,877 shipped rows have NULL lat/lng** (PO Box/Unique ZIPs without geocodes) and `zip_distance` returns NA for them. Documentation + data-refresh issue, not a code bug. |
| — | All 2020 ZCTAs | 23 missing nationwide | **0 missing** | — | The 23: US Virgin Islands (00802/20/30/40/50/51), American Samoa (96799), Guam (96910-96929), N. Mariana (96950-52), and 5 new mainland ZCTAs (72405, 72713, 75036, 75072, 89437) + 97003. Data refresh resolves all. |

## 7. Licensing & provenance notes

- **uszipcode-project:** MIT — reuse/derivation fine with attribution (already credited in
  README/docs; keep it).
- **Census (ACS, decennial, gazetteer, TIGER, relationship files), HUD-USPS crosswalk
  (free registration/API token), IRS SOI:** U.S. Government public domain / freely
  redistributable. HUD crosswalk requires a token for API access; files are
  redistributable with citation.
- ⚠ **Open question for the maintainer:** USPS city/alias names (`major_city`,
  `post_office_city`, `common_city_list`, `zipcode_type`). USPS licenses its raw products;
  the public compilations upstream used (federalgovernmentzipcodes.us, 2012) are of
  unclear provenance. The reconstruction pipeline can source ZIP existence/type/city from
  the HUD-USPS crosswalk (public) + GeoNames (CC-BY) instead. **Flagged per the
  constraint: decide the acceptable source before Phase 2 builds these columns.**

## 8. Recommended Phase 2 branch decision

**Reconstruct the pipeline in R** (`data-raw/`, targets-style staged scripts):

1. Primary sources: Census 2020 Gazetteer + ACS 5-yr (ZCTA level), HUD-USPS crosswalk,
   Census relationship files (tract, CD119), tz-boundary data. Pinned URLs + SHA256.
2. Output the exact 24-column contract of §4 (titleized `zipcode_type`, blob-compatible
   list columns or a documented forward-compatible representation), validated against
   both upstream snapshots (0.2.6 for backward compat, 1.0.1 for coverage).
3. Validation gate: row count ≥ 41,877 and ~42-43k sanity band; every shipped ZIP retained
   (retirements flagged, never dropped); regression ZIPs (91230, 97003, VI/Guam set)
   present with coordinates; schema identical; #20-reprex distance spot-checks.
4. Interim quick win available at any time: the 1.0.1 snapshot itself fixes 22 of 23
   missing ZCTAs (not 91230) — but it is *also* 4 years stale; prefer going straight to
   reconstruction.

## 9. Risks

- USPS-derived naming columns need a licensing decision (§7) before they can be refreshed.
- `zipcode_type`/military ZIPs: introducing MILITARY rows changes `search_*` result sets —
  additive, but should be release-noted as data (not API) change.
- blob list-columns: exotic (`blob` class from an implicit RSQLite dependency at build
  time); consider migrating to plain character-JSON or list columns in a *data-major*
  release with a compatibility shim, since the `blob` class currently arrives without the
  package that defines it being declared anywhere.
- 2020 ZCTA/tract GEOID changes will shift `get_tracts()` results — document as data
  vintage change.
