<!-- Draft comment for issue #24 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

The `libarrow.so.800` warnings came from `sf`'s GDAL initialization (your distro's
GDAL was built against a different arrow version) — and zipcodeR only touched that
chain because it imported `tidycensus` (which depends on `sf`) just to read its static
FIPS code table.

As of 0.4.0 that table is bundled directly in zipcodeR and the `tidycensus`/`sf`
dependency is gone, along with `raster`/`sp`. Loading zipcodeR no longer initializes
GDAL at all, so these warnings can no longer appear via zipcodeR regardless of the
system arrow/GDAL pairing.
