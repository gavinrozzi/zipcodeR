<!-- Draft comment for issue #24 — review before posting. Suggested action: post + close after 0.4.0 ships. -->

The warnings came from eagerly loading the legacy spatial dependency graph,
not from a ZIP lookup itself. In 0.4.0, `library(zipcodeR)` no longer loads
`tidycensus`, `sf`, `raster`, `terra`, or their GDAL bindings. The legacy
packages remain installed dependencies for compatibility and are loaded only
when a legacy function that actually needs one is called. The `_ng` FIPS path
uses the vendored static FIPS table and does not invoke `tidycensus`.

This isolates package startup from a system GDAL/Arrow mismatch while keeping
legacy calls and installation requirements reproducible.
