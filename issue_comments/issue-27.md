<!-- Draft comment for issue #27 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

Thanks for the clear reprex — this was a real vectorization bug, now fixed for the
0.4.0 release.

The root cause: `reverse_zipcode()` filtered the database with `%in%`, which returns
rows in *database* order and collapses duplicate inputs — so your 13 ZIP codes (with
96817 appearing twice) produced 12 rows, and `mutate()` correctly refused the length
mismatch. The `rowwise()` workaround mentioned above worked because it forced one call
per row.

As of 0.4.0, `reverse_zipcode()` guarantees one output row per input element, in input
order, with duplicates preserved and NA rows (plus a warning) for ZIP codes not in the
database. Your exact example now works inside `mutate()` without `rowwise()`:

```r
df %>% mutate(county = reverse_zipcode(zipcode)$county)
# 13 rows; NA county for the "00000" entries, matching values for both 96817 rows
```

`geocode_zip()` received the same treatment (it previously dropped unmatched ZIP codes
silently, shortening its output). Both behaviors are covered by regression tests built
from this issue's reprex.
