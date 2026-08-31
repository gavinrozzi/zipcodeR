<!-- Draft comment for issue #21 — review before posting. Leave open for a future major-version dependency policy. -->

The stale `raster`/`terra` class-registration failure is real, but removing
`raster` from 0.4.0 would also change legacy scientific distance results.
The compatibility release therefore retains the dependency and exact WGS84
behavior. The new `_ng` distance path does not use `raster`, but that does
not remove the package-level legacy dependency. A full removal needs a future
major-version migration policy rather than a silent result change.
