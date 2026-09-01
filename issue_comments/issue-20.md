<!-- Draft comment for issue #20 — review before posting. Suggested action: post + close after 0.4.0 ships. -->

Thanks for the detailed report and reprexes. The ordering fix shipped in 0.3.4,
and 0.4.0 adds an isolated differential test that locks the existing behavior
to the 0.3.5 contract. In particular, the legacy WGS84 calculation remains
unchanged:

```r
zip_distance("08731", "08901")
# distance: 40.70 miles
```

The opt-in `zip_distance_ng(bundle, ...)` function preserves duplicates and
input order while using the bundle's coordinates and modern haversine method.
It is deliberately a separate name so an old analysis never changes silently.
