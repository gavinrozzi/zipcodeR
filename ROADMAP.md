# zipcodeR Roadmap

zipcodeR is a research dependency. Reproducibility therefore takes precedence
over correcting historical behavior under an existing function or dataset
name.

## 0.4.0 — compatibility-first infrastructure

The release is mergeable only after every required gate below passes.

| Item | Status |
|---|---|
| Restore the three exact 0.3.5 datasets and `Depends: R (>= 3.5.0)` | implemented |
| Preserve exact legacy values, ordering, warnings, errors, and side effects | implemented; differential harness required in CI |
| Speed up legacy `search_radius()` without changing its WGS84 results | implemented; exact benchmark parity required |
| Vendor the exact FIPS table without changing legacy FIPS/CD results | implemented |
| Add explicit `_ng` functions for corrected behavior and modern data | implemented |
| Add checksum-verified, explicitly versioned bundle I/O | implemented; registry remains disabled pending publication |
| Build modern data as an external bundle with provenance and quality sidecars | implemented locally |
| Pin and archive raw inputs, dependencies, container, and build manifest | implemented locally; two clean rebuilds required for every release |
| Normal Windows, macOS, and Ubuntu release/devel/oldrel checks | passing on pushed commit `81d77cc` |
| Public `data-2026.08` bundle and comprehensive assets, clean-machine smoke test | blocking; not yet public |

The core package continues to ship the 2021-06-08 legacy data. Refreshed ZCTA,
tract, and 119th-Congress relationships are available only through an explicit
versioned bundle and `_ng` calls. USPS-only records without authoritative
coordinates or district relationships remain unavailable or unmapped with a
recorded reason; city-wide district inference and proxy centroids are forbidden.

Documentation presents `_ng` plus an explicitly pinned modern bundle as the
recommended path for new community code. The unsuffixed API is the historical
compatibility path. "Recommended" never means an implicit latest version or an
automatic data refresh: each analysis selects and records immutable bundle
bytes.

`download_zip_data()` retains its historical runtime behavior in 0.4.0.
Documentation may discourage it, but warnings, no-ops, and removal are not
compatible changes.

## Release checklist

1. Run the isolated 0.3.5 differential harness on every required CI platform.
2. Run normal vignette-building `R CMD check --as-cran` on Windows, macOS, and
   Ubuntu release/devel/oldrel.
3. Build the data bundle twice in a clean pinned container and compare canonical
   content and asset hashes.
4. Commit the pipeline state used by the manifest so `working_tree_dirty` is
   false and `pipeline_commit` names the release commit.
5. Publish the simple bundle, manifest, reproducibility archive, and
   comprehensive asset under an immutable data tag.
6. Download every public asset from a clean machine and verify its checksum,
   schema, version, and representative `_ng` calls.
7. Only then add that exact version and checksum to the downloader registry.
8. Rerun required CI after the registry commit. Merge only when all gates are
   green and release claims match the evidence.

## Later releases

- Add data enrichments through versioned bundle schemas without changing the
  legacy package datasets.
- Refresh a source only through a reviewed manifest update and new immutable
  data version.
- Consider removing legacy dependencies or behavior only in a future major
  version with an explicit research-migration policy. Do not silently retcon
  the 0.3.5 contract.
- Keep heavyweight geospatial dependencies out of package startup and the
  `_ng` runtime path. They may remain installed and load lazily for a legacy
  call when exact compatibility requires them; never substitute a different
  scientific algorithm under a legacy name.
