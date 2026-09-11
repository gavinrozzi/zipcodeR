# zipcodeR 0.4.1

## Resubmission

This is a test-only resubmission that fixes the ERROR reported for 0.4.0 on
the CRAN `r-devel-linux-x86_64-debian-gcc` and `r-patched-linux-x86_64`
flavors:

```
Failure ('test-04-data-bundles.R:236:3'): old R uses only the session
temporary directory for new caches
Expected `grepl(path.expand("~"), old_r_cache, fixed = TRUE)` to be FALSE.
```

As the CRAN maintainer noted, one cannot assume that the session temporary
directory is outside the user's home. On the Debian check hosts it is under
the checker's home directory, so the test's "not under `~`" assertion was an
environmental assumption rather than a package contract. The package itself
behaved correctly on every flavor.

The test now asserts the real contract: on R < 4.0 the cache path is
`file.path(tempdir(), "zipcodeR-data")`, and it differs from the persistent
`tools::R_user_dir()` location used on R >= 4.0. No assertion depends on where
`tempdir()` or the home directory is located.

No package code, documentation, exported API, or bundled dataset changed
between 0.4.0 and 0.4.1. The 0.4.0 CITATION file already uses `bibentry()`;
the `citEntry()` NOTE in the check results applies only to the 0.3.5 file.

## Test environments

* local macOS Tahoe 26.6.2 (arm64), R 4.6.1, with `TMPDIR` set to a directory
  under `$HOME` to reproduce the Debian CRAN host layout. Before the fix this
  reproduced the reported failure exactly; after the fix the full suite passes
  (0 failures, 132 passing) under both the default and the under-`$HOME`
  temporary directory.
* Hosted GitHub Actions matrix on the submitted commit: windows-latest
  (R release), macos-latest (R release), and ubuntu-latest (R release,
  R devel, and oldrel-1). The Ubuntu jobs now place the session temporary
  directory under `$HOME` so this class of assumption cannot regress.

## R CMD check results

`R CMD check --as-cran` on the source package, run locally with the
temporary directory under `$HOME`, including the indexed PDF and HTML manuals:

* 0 errors
* 0 warnings
* 1 note: "Days since last update: 3", expected for this resubmission

## Compatibility

The differential harness that installs zipcodeR 0.3.5 from its immutable Git
commit and this candidate into isolated libraries passed: all three public
datasets, legacy function values, classes, attributes, ordering, signatures,
warnings, errors, messages, and the legacy downloader implementation are
identical.

## Downstream dependencies

CRAN lists one reverse dependency, `geospatialsuite` 0.2.0 (Reverse Suggests).
Nothing in the installed package changed between 0.4.0 and 0.4.1, so the
0.4.0 reverse dependency check result stands.
