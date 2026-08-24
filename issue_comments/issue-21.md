<!-- Draft comment for issue #21 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

Closing the loop on this one: the load failure was a class-registration collision
between stale `raster`/`terra` binaries (`coerce` methods for Raster/SpatRaster),
which zipcodeR was exposed to only because it imported `raster` for two distance
calculations.

As of 0.4.0, zipcodeR no longer imports `raster` (or any package in the sp/terra/GDAL
chain) — distance math is an internal haversine implementation — so this failure mode
can no longer occur through zipcodeR. If you hit it in other contexts, reinstalling
`raster` and `terra` together usually resolves the stale-binary mismatch.
