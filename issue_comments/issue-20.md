<!-- Draft comment for issue #20 — review before posting. Suggested action: post + close. -->

Thanks for the detailed report and the reprexes — they made this easy to verify.

The ordering bug you reported was fixed in the 0.3.4 release (PR contributed by
Nicholas X Lee), and I've confirmed both of your exact examples return correctly
paired results on the upcoming 0.4.0:

```r
zip_distance(c("08731", "08734"), c("08901", "08005"))
#>   zipcode_a zipcode_b distance
#> 1     08731     08901    43.82
#> 2     08734     08005    10.49

zip_distance(c("08731", "08731"), c("08731", "08005"))
#>   zipcode_a zipcode_b distance
#> 1     08731     08731     0.00
#> 2     08731     08005     7.23
```

(The absolute values differ slightly from older releases because 0.4.0 refreshes
coordinates to authoritative Census ZCTA centroids and computes haversine distances —
the 08731→08901 leg lands at 43.8 mi, close to the ~45 mi you estimated.)

What was missing was a regression test locking the ordering in — 0.4.0 adds tests
built directly from your reprexes, and `zip_distance()` now looks up coordinates
positionally (no join involved), so input order is preserved by construction. Closing
as fixed; please reopen if you can still reproduce a swap on 0.3.4 or later.
