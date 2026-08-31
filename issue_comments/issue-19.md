<!-- Draft comment for issue #19 — review before posting. Do not close until a modern data asset is public and smoke-tested. -->

The package's default database is intentionally still the 2021-06-08 snapshot
in 0.4.0. Changing it under existing function names changed results for most
records and would invalidate reproducible analyses.

0.4.0 instead adds `zip_data_version()` and an explicit, checksum-pinned data
bundle API. Once a modern bundle is published and verified, refreshed data can
be used through the `_ng` functions without changing old scripts. ZIPs without
authoritative coordinates remain unavailable rather than receiving city-center
proxy coordinates.
