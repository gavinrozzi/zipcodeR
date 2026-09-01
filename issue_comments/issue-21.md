<!-- Draft comment for issue #21 — review before posting. Suggested action: post + close after 0.4.0 ships. -->

The stale `raster`/`terra` class-registration failure is real. In 0.4.0,
`raster` remains an installed dependency so legacy distance functions retain
their exact WGS84 results, but its namespace is no longer loaded by
`library(zipcodeR)`. It is loaded lazily only if a legacy distance function is
called. A clean-process installation test confirms that `zipcodeR` loads
without loading `raster`, `terra`, `sp`, `sf`, or `tidycensus`.

New analyses can use the `_ng` distance functions, which do not invoke
`raster`. This resolves the reported package-load failure without silently
changing prior numerical results.
