<!-- Draft comment for issue #33 — review before posting. Suggested action: close after CI confirms exact parity. -->

The per-row distance loop has been replaced by one vectorized
`raster::pointDistance()` call, with a conservative bounding-box prefilter for
ordinary valid scalar inputs. This retains the exact legacy WGS84 algorithm,
membership, ordering, distances, and invalid-input conditions while reducing
representative calls from about one second to roughly 10–15 ms locally.

The benchmark asserts `identical()` results before reporting speed, and the
isolated 0.3.5 compatibility harness covers radius boundaries and antimeridian
cases. The legacy dependency remains because replacing the algorithm with
haversine would change scientific results.
