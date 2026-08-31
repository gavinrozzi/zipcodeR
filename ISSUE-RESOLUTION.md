# PR #34 open-issue resolution matrix

This is the review record for every issue open on 2026-08-30. “Addressed” does
not always mean changing a historical function: the release contract keeps
unsuffixed 0.3.5 calls reproducible, recommends `_ng` for new analyses, and
documents reports that are data-model limitations or invalid assumptions.

| Issue | Resolution in PR #34 | Acceptance evidence | Release disposition |
|---|---|---|---|
| #7 FIPS in reverse lookup | `reverse_zipcode_ng()` returns two-digit `state_fips` and full five-digit `county_fips` for the predominant county. The legacy output schema is frozen. | `_ng` regression test includes Ocean County `34029`; vendored FIPS table includes Alexandria city `51510`. | Close after package and first bundle ship. |
| #13 `zip_code_db` not found | Package data remains namespace-accessible and byte-identical to 0.3.5; FAQ gives reinstall guidance for a broken lazy-load database. | Clean installed-package calls and the isolated compatibility harness invoke lookup exports without assigning the dataset globally. | Close as stale/documented after release. |
| #14 negative longitude | Negative values are the correct west-of-Greenwich convention. | `?geocode_zip`, data documentation, and FAQ explain the sign; no data mutation is made. | Close as answered. |
| #19 missing ZIP distances | Modern bundles refresh authoritative ZCTA coordinates; USPS-only ZIPs without defensible coordinates remain unavailable with provenance instead of proxy points. | Pipeline coordinate gate, record quality sidecar, missing-coordinate `_ng` tests, and explicit bundle version metadata. | Keep open until public bundle smoke test, then close with limitation noted. |
| #20 vector distance order | The reporter's swap was fixed in 0.3.4; 0.4.0 freezes the 0.3.5 result. `_ng` additionally specifies input-order, duplicate, recycling, and missing-coordinate behavior. | Exact differential cases plus `_ng` pairing/recycling tests. | Close after release. |
| #21 `raster`/`terra` load failure | `raster` remains installed for exact legacy WGS84 calls but is no longer imported at startup; a legacy distance call loads it lazily. | Clean installed process loads none of `raster`, `terra`, `sp`, `sf`, or `tidycensus`, then returns legacy distance 40.70 exactly. | Close after release. |
| #24 GDAL `libarrow` warnings | `tidycensus`/`sf` and `raster` are no longer loaded by `library(zipcodeR)`; legacy functions load their namespace only when needed. | Clean installed-process namespace inspection and NAMESPACE regression test. | Close after release. |
| #25 missing `97003` | The modern pipeline corroborates `97003` as a Census ZCTA and publishes its authoritative internal point only in the versioned bundle. | Candidate bundle contains `97003`, Census coordinate quality `authoritative`, and ACS quality `authoritative_current_vintage`. | Keep open until public bundle smoke test, then close. |
| #26 `91230` | The stated San Diego ZIP is `92130`, which is present. `91230` is absent from pinned Census ZCTA/ACS sources and remains quarantined rather than receiving a Glendale proxy centroid. | Pipeline quarantine list, absence checks in archived sources, and validation gate prohibiting uncorroborated additions. | Close as corrected/explained; reconsider only with authoritative USPS evidence. |
| #27 duplicates in `reverse_zipcode()` | Historical behavior remains reproducible. `reverse_zipcode_ng()` and `geocode_zip_ng()` return one row per input in input order, preserving duplicates and explicit misses. | `_ng` tests cover duplicate-valid and missing ZIPs; differential gate locks the legacy condition and output. | Close after bundle publication, explicitly noting the legacy behavior. |
| #28 legacy spatial warning | Spatial namespaces are lazy rather than startup imports; `_ng` distance code never invokes them. | Same clean-load evidence as #21/#24, plus exact legacy distance differential tests. | Close after release. |
| #29 outdated districts | The modern bundle uses the pinned Census 119th-Congress ZCTA relationship and refuses city-wide inference for USPS-only ZIPs. Legacy mappings remain unchanged. | Source SHA in manifest, mapping-policy validation, authoritative and unmapped `_ng` tests; `08731` maps to NJ-02 and NJ-04 in the candidate. | Keep open until public bundle smoke test, then close. |
| #32 jurisdiction accuracy | ZIP city is a mailing name and ZCTA is not a municipal boundary; ZIP-only input cannot yield authoritative address jurisdiction. | Data docs and FAQ direct users to full-address geocoding against boundary files and label county as predominant. | Close as answered/documented. |
| #33 radius performance | One vectorized legacy WGS84 call plus conservative prefilter replaces the per-row loop. | Benchmark first requires `identical()` result; differential tests include boundaries and antimeridian cases. Representative local calls are roughly 10–15 ms instead of about 1 second. | Close after required CI. |

## Merge gates

The issue-level code is complete only when all of the following are true:

1. isolated 0.3.5 differential tests pass on all required CI platforms;
2. normal vignette-building checks pass on Windows, macOS, Ubuntu release,
   devel, and oldrel;
3. a clean commit builds the modern bundle, manifest, and reproducibility
   archive twice with identical hashes;
4. the bundle, manifest, reproducibility archive, and comprehensive database
   are public at immutable URLs and pass clean-machine checksum/schema calls;
5. the verified bundle checksum is enabled in the package registry and CI is
   rerun on that registry commit.

Until gates 3–5 pass, issues #19, #25, and #29 are implemented but not delivered,
and PR #34 is not merge-ready.
