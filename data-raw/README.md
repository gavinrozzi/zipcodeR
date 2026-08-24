# zipcodeR data pipeline

This directory makes zipcodeR's datasets fully reproducible. The package no
longer depends on a frozen snapshot: every dataset in `data/` can be rebuilt
from primary sources with

```sh
Rscript data-raw/run_pipeline.R
```

run from the package root. Build-time-only requirements (never runtime
dependencies): `dplyr`, `DBI`, `RSQLite`, `jsonlite`, and a `CENSUS_API_KEY`
in the environment ([free registration](https://api.census.gov/data/key_signup.html)).

## Pipeline stages

| Script | Purpose |
|---|---|
| `sources.R` | Registry of every source: pinned URL, SHA256, license. Also pins the ACS vintage and the data release version. |
| `01_acquire.R` | Download all sources into `cache/` (gitignored), verify checksums, pull ACS estimates. Idempotent. |
| `02_build_zip_code_db.R` | Build `zip_code_db` (see strategy below). |
| `03_build_zcta_crosswalk.R` | Build `zcta_crosswalk` from the Census 2020 ZCTA↔tract relationship file. |
| `04_build_zip_to_cd.R` | Build `zip_to_cd` from the Census 119th-Congress↔ZCTA relationship file (method from PR #30 by @awallender, updated vintage). |
| `05_validate.R` | **Validation gate** — hard-fails the pipeline unless every check passes; writes `refresh_summary.md` for the release PR. |
| `06_finalize.R` | Write `data/*.rda` + version metadata into `R/sysdata.rda`, recompress. |
| `fips_codes.R` | Regenerate the internal Census FIPS table (independent of the main pipeline). |

## zip_code_db build strategy: carry-forward + refresh

The shipped database (proven in `AUDIT.md` to be byte-identical to the
uszipcode 0.2.6 snapshot) is the base, which guarantees **no ZIP code is ever
silently dropped**. On top of it, each run:

1. appends rows new in upstream uszipcode 1.0.1 (`zipcode_type` normalized to
   the shipped titleized values; adds the `Military` type),
2. appends any 2020 Census ZCTA still missing (Gazetteer + county
   relationship + GeoNames place names),
3. appends curated USPS-only ZIPs from `supplemental_zips.csv` (each row
   carries its own source note),
4. refreshes, for every ZCTA-backed row: coordinates + land/water area from
   the Census Gazetteer and five demographic attributes from the pinned ACS
   5-year vintage; recomputes population density,
5. clears provably-impossible coordinates inherited from upstream.

Columns with no current public source (`bounds_*`, `radius_in_miles`,
`area_code_list`, `common_city_list`) carry forward unchanged and are `NA`
for new rows.

## The validation gate

`05_validate.R` enforces, among ~20 checks: row count within sane bounds and
never below the previous release; zero dropped ZIP codes; unique zipcodes;
column names/classes identical to the compatibility contract; the regression
ZIPs from issues #19/#25/#26 present **with coordinates**; distance
spot-checks on the issue #20 pairs (range-based, robust to vintage precision
changes, and asserting no pair swap); coordinate envelope sanity; schema and
format checks on both crosswalks. A refresh that fails any check does not
ship.

## Licensing and provenance decisions

- **U.S. Census Bureau** files and API (relationship files, Gazetteer, ACS):
  U.S. public domain.
- **uszipcode-project** snapshots (base rows + validation reference): MIT,
  attribution retained in the dataset docs.
- **GeoNames** (place names for post-2021 additions): CC BY 4.0, attribution
  retained in the dataset docs.
- **USPS-derived naming columns** (`major_city`, `post_office_city`,
  `common_city_list`, `zipcode_type`): carried forward from the MIT-licensed
  upstream snapshots; NOT refreshed from USPS-licensed products. New
  USPS-only ZIPs enter only via `supplemental_zips.csv` (manually sourced,
  per-row provenance) or — once a maintainer configures a free
  [HUD API token](https://www.huduser.gov/portal/dataset/uspszip-api.html) —
  a future HUD-USPS crosswalk stage, which is the designated authoritative
  replacement for the supplement file.

## Refresh automation

`.github/workflows/refresh-data.yaml` runs this pipeline on manual dispatch
and quarterly, then opens a PR with `refresh_summary.md` as the description.
**A human merges; nothing ships automatically.** Requirements:

- repository secret `CENSUS_API_KEY`
- a runner with R ≥ 4.2 and ~2 GB free disk; the job is single-matrix and
  cache-friendly to stay light on hosted minutes, and can be pointed at the
  self-hosted runner by changing one `runs-on` line (commented in the
  workflow).

## Data releases

Data ships in two tiers, mirroring upstream's simple/comprehensive split:

- the **simple** tier is `data/zip_code_db.rda`, inside the package;
- the **comprehensive** tier (~450 MB SQLite with full ACS profiles) is an
  asset of the `data-YYYY.MM` GitHub release, fetched on demand by
  `download_comprehensive_data()` with checksum verification and cached under
  `tools::R_user_dir("zipcodeR", "data")`.

`zip_data_version()` reports the loaded data release; the release tag,
asset name, and SHA256 live in `R/sysdata.rda` (written by `06_finalize.R`).
