<!-- Draft comment for issue #33 — review before posting. Suggested action: post now; close after the Phase 3 benchmark lands (or close at 0.4.0 if satisfied). -->

Thanks for the analysis and the proposed fix — you were exactly right that the
per-row loop was the problem.

As of 0.4.0, `search_radius()` computes all ~42k distances in a single vectorized
call using an internal haversine implementation (the `raster` dependency is gone
entirely), taking a typical query from multiple seconds to ~10 ms on my machine —
in line with the ~40× speedup you measured, plus the constant-factor win from
dropping the `raster` dispatch overhead. Your fix also surfaced a latent bug: the
`filter(lat != "NA")` line was a no-op due to argument shadowing, and the NA
filtering now actually happens.

A bounding-box prefilter (cheap lat/lng window before the haversine pass) and a
formal benchmark script are planned as a follow-up. Leaving this open until those
land — but the pathological slowness is fixed in 0.4.0.
