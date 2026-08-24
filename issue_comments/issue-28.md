<!-- Draft comment for issue #28 — review before posting. Suggested action: post + close when 0.4.0 ships.
     Also suitable (lightly adapted) for #21 and #24 — see issue-21.md / issue-24.md. -->

The plan is now implemented: as of 0.4.0, zipcodeR no longer depends on the legacy
geospatial stack at all.

The warning you saw came from `sp`, loaded transitively through `raster` — which
zipcodeR imported solely for two `pointDistance()` calls. Those are now an internal
haversine implementation in plain R, and the other heavy chain (`tidycensus` → `sf`,
imported only for its static FIPS code table) is gone too — the table is bundled as
package data.

zipcodeR's Imports are now just `dplyr`, `rlang`, `stringr`, and `utils`: no `sp`, no
`raster`, no GDAL/GEOS/PROJ, no arrow, and a package load that went from ~2.7 s / 54
namespaces to ~0.15 s / 25 namespaces on my machine. Note that distances are now
spherical (haversine) rather than WGS84 geodesic, so values can differ from previous
releases by up to ~0.5% — see NEWS for details.
