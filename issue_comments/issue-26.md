<!-- Draft comment for issue #26 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

Fixed in the 0.4.0 data release. 91230 is a USPS-only ZIP code (Glendale, CA — a
P.O. Box-type code with no Census ZCTA), which is why it was absent from the upstream
ZCTA-oriented database. It's now included via the new data pipeline's curated
supplement for USPS-only codes:

```r
reverse_zipcode("91230")
#> 1 91230  PO Box  Glendale  CA  34.14  -118.26 ...
```

More broadly, 0.4.0 rebuilds the database through a reproducible pipeline whose
validation gate requires this ZIP (and the other reported missing ones) to be present
with coordinates before any data refresh can ship. Note the FAQ vignette now explains
the ZIP-vs-ZCTA distinction behind this class of gap.
