# zipcodeR versioned data assets

The datasets in `data/` are the frozen zipcodeR 0.3.5 compatibility contract.
This pipeline never replaces them. It builds an opt-in, versioned RDS bundle
for the `_ng` API and a separate reproducibility archive for a data-only
GitHub release.

## Two deliberately separate modes

`refresh_sources.R` inspects mutable upstream URLs for a proposed *new* data
version. Before running it, update prospective URLs and vintages in
`sources.R` while leaving their old checksums (or an all-zero placeholder).
It downloads candidate source bytes and writes `proposed-sources.json` plus a
deterministic `zipcodeR-sources-VERSION.tar.gz`; it does not change pins,
build data, or publish. A Census API key is optional and increases API limits.

```sh
PIPELINE_MODE=refresh \
PIPELINE_DATA_VERSION=2027.01 \
PIPELINE_PROPOSED_VERSION=2027.01 \
PIPELINE_BUILD_TIMESTAMP=2027-01-15T00:00:00Z \
Rscript data-raw/refresh_sources.R
```

After human review, a maintainer updates `sources.R` with exact URLs,
vintages, and SHA256 values. Restore the reviewed archive, then
`run_pipeline.R` performs a network-free deterministic rebuild:

```sh
PIPELINE_MODE=rebuild \
PIPELINE_DATA_VERSION=2026.08 \
PIPELINE_BUILD_TIMESTAMP=2026-08-24T00:00:00Z \
PIPELINE_COMMIT=609d16358127a7096d11b1b9a64a1f1fab858921 \
PIPELINE_SOURCE_ARCHIVE=/path/to/zipcodeR-sources-2026.08.tar.gz \
PIPELINE_SOURCE_ARCHIVE_SHA256=SHA256 \
Rscript data-raw/restore_rebuild_inputs.R

PIPELINE_MODE=rebuild \
PIPELINE_DATA_VERSION=2026.08 \
PIPELINE_BUILD_TIMESTAMP=2026-08-24T00:00:00Z \
PIPELINE_COMMIT=609d16358127a7096d11b1b9a64a1f1fab858921 \
Rscript data-raw/run_pipeline.R
```

There is no `latest` alias and no release identity derived from the current
date. The pipeline commit is also an explicit input and must match
`git rev-parse HEAD` in a checkout; outside a git checkout, set
`PIPELINE_WORKING_TREE_DIRTY=false` after verifying the archive. Rebuild mode
never downloads from an upstream data publisher. The raw
ACS JSON response and its deterministically derived CSV are both checksummed
and archived. Published version identities cannot be reused.

## Pipeline stages

| File | Purpose |
|---|---|
| `sources.R` | Explicit data identity, source URLs, vintages, SHA256 values, and licenses. |
| `restore_rebuild_inputs.R` | Verify a source/reproducibility archive and restore only allowlisted raw inputs. |
| `01_acquire.R` | Verify exact static sources and the archived raw ACS response without network access. |
| `02_build_zip_code_db.R` | Refresh Census-backed attributes; add only independently corroborated ZCTAs; quarantine other candidates. |
| `03_build_zcta_crosswalk.R` | Build the 2020 ZCTA-to-tract relationship with character GEOIDs. |
| `04_build_zip_to_cd.R` | Build authoritative CD119-to-ZCTA relationships only. |
| `05_validate.R` | Reject schema, identifier, coordinate, quarantine, or mapping-policy violations. |
| `06_finalize.R` | Write the external bundle, manifest, hashes, quality tables, and reproducibility archive. |

The pinned R toolchain is described by `Dockerfile`; all pipeline package
dependencies, including transitive dependencies, are locked with source
archive hashes in `pkg.lock`. The exact `pak` bootstrap source is vendored in
`vendor/` and checksum-verified before installation.

Build and run the pinned environment with every release identity supplied
explicitly (the source archive may instead be a read-only mounted local file):

```sh
docker build -f data-raw/Dockerfile -t zipcoder-data .
docker run --rm \
  -e PIPELINE_DATA_VERSION=2026.09 \
  -e PIPELINE_BUILD_TIMESTAMP=2026-09-01T00:00:00Z \
  -e PIPELINE_COMMIT=FULL_40_CHARACTER_PIPELINE_COMMIT \
  -e PIPELINE_WORKING_TREE_DIRTY=false \
  -e PIPELINE_SOURCE_ARCHIVE=HTTPS_ARCHIVE_URL \
  -e PIPELINE_SOURCE_ARCHIVE_SHA256=ARCHIVE_SHA256 \
  zipcoder-data
```

## ZIP and ZCTA policy

ZIP codes are USPS delivery constructs; ZCTAs are Census statistical areas.
The pipeline does not present a city point as a ZIP centroid and does not
assume that an entry in a third-party ZIP database is a Census ZCTA.

- Rows independently present in the pinned Census ZCTA Gazetteer may enter the
  modern `zip_code_db`.
- Uncorroborated upstream and supplemental candidates—including proxy or
  placeholder records such as 91230, 88888, and 72643—are quarantined and
  exposed in provenance artifacts, not published as authoritative rows.
- Coordinates come from Census ZCTA internal points. A non-ZCTA ZIP without an
  authoritative coordinate remains missing.
- Congressional districts come only from the Census relationship file.
  USPS-only ZIPs that cannot be derived authoritatively remain unmapped with an
  explicit quality reason; city-wide inference is prohibited.

## Release contents and gate

`06_finalize.R` creates under `data-raw/release/`:

- `zipcodeR-data-VERSION.rds`, containing `zip_code_db`, `zcta_crosswalk`,
  `zip_to_cd`, metadata, provenance, and quality sidecars;
- `manifest-VERSION.json`, containing the release tag, bundle SHA256, source
  URLs and SHA256 values, licenses, vintages, pipeline commit, R version,
  dependency-lock checksum, schemas, row counts, and canonical output hashes;
- `zipcodeR-reproducibility-VERSION.tar.gz`, containing the complete pipeline,
  lock/container definitions, license notices, manifest, validation report,
  exact raw source archives, byte-pinned 0.3.5 baseline datasets, and the
  checksum-pinned internal FIPS table used during construction.

`data-raw/` is intentionally excluded from the CRAN package tarball to keep the
runtime package small. The complete directory and raw inputs accompany every
data release through the reproducibility archive instead.

An asset is not publishable until all of these are true:

1. the working tree and recorded pipeline commit are clean and reviewed;
2. two clean pinned-environment rebuilds produce the same bundle, manifest,
   reproducibility archive, and canonical output hashes;
3. package compatibility, `_ng`, integrity, and platform checks pass;
4. the release is public rather than draft, and every public URL and checksum
   succeeds from a clean machine.

The workflow in `.github/workflows/refresh-data.yaml` uploads unpublished
candidates for review. It does not update package datasets, open an automatic
data PR, select a version, or publish a release.

## Licenses

See `LICENSES.md`. Census material is U.S. public domain, GeoNames material is
CC BY 4.0 with attribution, and uszipcode-project snapshots are MIT-licensed.
