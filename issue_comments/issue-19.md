<!-- Draft comment for issue #19 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

To answer the original question: the data had last been updated 2021-06-08 — and as of
0.4.0 you can always check this yourself with the new `zip_data_version()`.

Two things were behind "many missing ZIP codes" in `zip_distance()`:

1. **Data staleness** — fixed in 0.4.0: the database now covers every 2020 Census ZCTA
   (42,725 ZIP codes, up from 41,877), rebuilt through a reproducible pipeline with
   scheduled refreshes, so it can no longer drift years out of date.
2. **ZIP codes without coordinates** — about 20% of ZIP codes (P.O. Box and "unique"
   codes) are postal-only constructs with no Census geography, and `zip_distance()`
   returns `NA` for them by design. The FAQ vignette now documents this.
