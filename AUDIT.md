# zipcodeR 0.4.0 release validation

Evidence recorded on 2026-09-01. This file distinguishes local and Act proof
from checks that still require external infrastructure.

## Research compatibility

- `tools/compatibility-check.R` installed the immutable 0.3.5 baseline commit
  `48ed689f4ee1694b1ec5fdffef02bed117938398` and the candidate into isolated
  libraries. All three public datasets, representative/vector/edge-case calls,
  conditions, formals, and the legacy downloader implementation compared with
  `identical()`.
- Unit tests completed with 132 passes, no failures, and no skips. The 28
  captured tidyselect deprecation warnings are observable legacy behavior and
  are therefore retained; `R CMD check` itself remains warning-free.
- The vectorized `search_radius()` benchmark first required exact object
  identity, then measured 13.4--14.0 ms versus 1.14--1.52 seconds for the three
  legacy reference searches.

## Published modern data

The authoritative evidence is the public `data-2026.09` release downloaded to
a clean temporary directory, not any ignored files left in
`data-raw/release/` by an earlier local build.

- bundle SHA256:
  `0805a5be5fe826c4c8e3a3bab65f2d311671f96a2e1aa2c84d8571b0b9f3bd23`
- manifest SHA256:
  `e3e630efa0352e3efe63bb0d96f5f020a2899091548ea47904f747f8595f74e5`
- reproducibility archive SHA256:
  `71d4ec1906cffe96c84cfe1e5aa7f2e7e0c68bb3215e2044566b13a8b41c29db`
- platform: `x86_64-pc-linux-gnu`; pipeline commit:
  `70cb4834c2084e818291ce7c84b63e674b7cfd6b`
- rows: 41,900 ZIP records, 168,212 ZCTA--tract relationships, and
  40,116 ZCTA--district relationships

The downloaded manifest names the downloaded bundle SHA and size; its schema,
row counts, source checksums, and canonical output hashes validate against the
bundle. The package registry independently pins the same public URL and SHA.
Two clean Linux-amd64 rebuilds produced exact artifact and canonical-content
hashes. Wrong archive SHA, missing archive, mutated legacy data, corrupted
cache, interrupted download, and manifest-tampering controls all failed closed.

All 41,877 legacy ZIP keys remain in the modern bundle and 23 reviewed ZCTAs
are added. The 24 `zip_code_db` column names and first classes are identical to
legacy. The relationship tables retain their column names; the modern
`zcta_crosswalk$GEOID` is deliberately character rather than numeric so leading
zeroes cannot be lost. Modern values and relationships do change by design:
33,965 existing ZIP rows change at least one scientific/demographic field,
48,692 legacy ZCTA--tract rows and 17,928 legacy ZIP--district rows are absent
from the authoritative current-vintage relationships. That is why these bytes
are reachable only through an explicitly selected bundle and `_ng` call.

For a visible contract example, the legacy call remains 40.70 miles and NJ-03:

```r
zip_distance("08731", "08901")
get_cd("08731")
```

The explicit 2026.09 `_ng` calls return 43.82 miles and NJ-02/NJ-04, and stamp
the result with data version `2026.09` and the bundle SHA:

```r
bundle <- download_zip_data_bundle("2026.09")
zip_distance_ng(bundle, "08731", "08901")
get_cd_ng(bundle, "08731")
```

## Refresh and rebuild behavior

- The actual `.github/workflows/refresh-data.yaml` workflow completed under
  Act with artifact upload disabled; it ran inspect-only refresh, two clean
  pinned rebuilds, artifact comparison, validation, and negative controls.
- A proposed `2026.10` refresh with timestamp `2026-09-01T00:00:00Z` produced
  the same valid 11-member source archive twice, SHA256
  `4720f165d4d90018bfa7d14706dabd236997c83806157675fe63e4dd5c718a76`.
- Current upstream inspection found only mutable GeoNames `US.zip` changed,
  from the published pin
  `34bf4144bf1231c2da500127bbbf7020920bb4331de403b5d850b77f45a8f509`
  to candidate
  `bff0d919820ec54e6295f2b5d57d727686cf22ca55bda823ca08d7cd559e03af`.
  The other ten pinned inputs were unchanged.
- Refresh did not edit `sources.R`, build data, or publish. Rebuild with the
  old pin rejected the candidate archive at `US.zip`; a maintainer must review
  the changed bytes, update the pin, choose a new version, and rebuild.
- Published identity `2026.09`, unrepresentable timestamps, malformed source
  archives, and archives whose extracted member bytes differ from staging are
  rejected before a candidate checksum is reported.

## Package and downstream checks

- macOS Tahoe 26.6.2 arm64, R 4.6.1: a normal vignette-building source tarball
  passed full `R CMD check --as-cran`, including the indexed PDF and HTML
  manuals, with status OK.
- Ubuntu 24.04 amd64, R release, running the repository's actual
  `R-CMD-check.yaml` through Act: exact differential gate and `R CMD check
  --as-cran` passed with status OK.
- Ubuntu 24.04 amd64, R 4.7.0-devel and R 4.5.3 oldrel-1, running the same
  workflow through Act: the exact differential gate passed, normal vignettes
  built, and `R CMD check --as-cran --no-manual` completed successfully. The
  only post-job warning was Act's expected inability to reach its local cache
  service; it was not package-check output.
- Debian 9 amd64, genuine R 3.5.3, using a coherent 2022-10-03 historical
  dependency snapshot including raster 3.4-13: the latest source tarball passed
  `R CMD check --as-cran --no-manual` with status OK. This establishes that the
  declared minimum interpreter works with a historically coherent dependency
  set; it does not claim that today's complete CRAN dependency universe still
  installs on R 3.5.
- The first R 3.5 adversarial pass exposed two version-gated `tools` APIs that
  its static checker could not resolve and ancient-pandoc TLS failures on
  remote badge images. Those paths were made version-safe and the badges were
  converted to ordinary text links before the successful run. A subsequent
  oldrel pass exposed and removed the now-unused `tools` import.
- `geospatialsuite` 0.2.0, the only current CRAN reverse dependency (Reverse
  Suggests), passed `R CMD check --no-manual`; its actual zipcodeR geocoding
  integration exactly matched the frozen legacy data.

## Remaining external release gates

Local Act cannot execute a native Windows runner or prove GitHub-hosted secret,
cache, artifact, and Codecov/OIDC behavior. Before CRAN submission, run the
restored five-platform hosted matrix and an official win-builder check. Do not
submit while either reports a package warning, error, or significant note.
