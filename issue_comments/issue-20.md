<!-- Draft comment for issue #20 — review before posting. Suggested action: post + close. -->

Thanks for the detailed report and the reprexes — they made this easy to verify.

The ordering bug you reported was fixed in the 0.3.4 release (PR contributed by
Nicholas X Lee), and I've now confirmed both of your exact examples return correctly
paired results:

```r
zip_distance(c("08731", "08734"), c("08901", "08005"))
#>   zipcode_a zipcode_b distance
#> 1     08731     08901    40.75
#> 2     08734     08005     8.05

zip_distance(c("08731", "08731"), c("08731", "08005"))
#>   zipcode_a zipcode_b distance
#> 1     08731     08731      0.0
#> 2     08731     08005      6.9
```

What was missing was a regression test locking this in — the upcoming 0.4.0 release
adds tests built directly from your reprexes, and `zip_distance()` now looks up
coordinates positionally (no join involved), so input order is preserved by
construction. Closing as fixed; please reopen if you can still reproduce a swap on
0.3.4 or later.
