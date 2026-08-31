<!-- Draft comment for issue #28 — review before posting. Leave open for future major-version work. -->

0.4.0 cannot remove the legacy geospatial stack without changing WGS84 distance
results and package-load behavior that existing analyses may observe. It retains
`raster` for the frozen API. The explicit `_ng` implementation uses a small
internal haversine helper and modern bundles, so new code can avoid that spatial
calculation path. Removing the package-level dependency remains future
major-version work.
