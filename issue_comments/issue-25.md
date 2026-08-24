<!-- Draft comment for issue #25 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

Fixed in the 0.4.0 data release. 97003 (Beaverton) was missing from the 2021 data
snapshot the package shipped; it's now present with authoritative Census Gazetteer
coordinates:

```r
reverse_zipcode("97003")
#> 1 97003  Standard  Beaverton  OR  45.50  -122.86 ...
```

I audited Oregon coverage against the full 2020 Census ZCTA list while fixing this:
97003 was the only Oregon ZCTA missing. If you still have the list of the other ~dozen
ZIP codes you found missing, I'd welcome it as a check — they may have been USPS-only
(non-ZCTA) codes, which the new data pipeline handles through a separate supplement
(see the FAQ vignette for the distinction). As of 0.4.0, every 2020 ZCTA nationwide is
present, and the pipeline's validation gate prevents regressions.
