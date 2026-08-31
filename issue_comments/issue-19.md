<!-- Draft comment for issue #19 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

The package's default database is intentionally still the 2021-06-08 snapshot
in 0.4.0. Changing it under existing function names changed results for most
records and would invalidate reproducible analyses.

0.4.0 instead adds `zip_data_version()` and an explicit, checksum-pinned data
bundle API. The public `2026.08` bundle contains refreshed authoritative ZCTA
coordinates and can be selected with `download_zip_data_bundle("2026.08")`,
then used through `_ng` functions without changing old scripts. ZIPs without
authoritative coordinates remain unavailable rather than receiving city-center
proxy coordinates.
