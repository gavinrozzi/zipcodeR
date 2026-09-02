# zipcodeR 0.4.0

## Test environments

* local macOS Tahoe 26.6.2 (arm64), R 4.6.1
* Ubuntu 24.04 (amd64), R release, R 4.7.0-devel, and R 4.5.3 oldrel-1,
  using the repository's GitHub Actions workflow through Act
* Debian 9 (amd64), R 3.5.3, using a coherent historical dependency snapshot
* win-builder, Windows Server 2022 x64, R-devel r90457 UCRT

The complete hosted Windows/macOS/Ubuntu matrix remains an operational CI gate
and will be run when GitHub Actions capacity is available.

## R CMD check results

The normal vignette-building source package passed `R CMD check --as-cran`
locally, including the indexed PDF and HTML manuals, with:

* 0 errors
* 0 warnings
* 0 notes

The Ubuntu release, devel, and oldrel-1 workflows also passed their differential
compatibility gates and `R CMD check --as-cran --no-manual` checks. A genuine
R 3.5.3 check passed with a coherent 2022-10-03 dependency snapshot, including
raster 3.4-13. This verifies the declared minimum interpreter against an
installable historical dependency set; it does not claim that all current CRAN
dependency releases continue to support R 3.5.

Official win-builder R-devel/UCRT completed with `Status: OK`: 0 errors,
0 warnings, and 0 notes. Installation, examples, all 132 tests, vignettes, and
the PDF and HTML manuals passed.

## Compatibility

zipcodeR is used in published research. An automated differential harness
installs version 0.3.5 from its immutable Git commit and this candidate into
isolated libraries. It requires exact identity of the three public datasets,
legacy function values, classes, attributes, ordering, signatures, warnings,
errors, messages, and the legacy downloader implementation. That gate passes.

Corrected behavior and updated data are exposed only through new `_ng`
functions and an explicitly selected, immutable, checksum-verified external
data bundle. Existing functions retain the 0.3.5 contract.

## Downstream dependencies

CRAN currently lists one reverse dependency, `geospatialsuite` 0.2.0 (Reverse
Suggests). Its source package passed `R CMD check --no-manual` with the
candidate installed. A targeted check of its zipcodeR geocoding integration
also exactly matched the frozen legacy result.
