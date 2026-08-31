<!-- Draft comment for issue #24 — review before posting. Do not claim the dependency is removed in 0.4.0. -->

The static FIPS table is now vendored, which lets the corrected `_ng` path
avoid using `tidycensus` for that lookup. However, 0.4.0 retains the legacy
dependency set because existing functions and `download_zip_data()` are frozen
to the 0.3.5 runtime contract. This issue should remain open until dependency
removal can be done under a major-version policy without changing old results
or conditions.
