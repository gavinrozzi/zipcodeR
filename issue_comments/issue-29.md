<!-- Draft comment for issue #29 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

Fixed in 0.4.0: `zip_to_cd` is now built from the Census 119th-Congress ↔ 2020 ZCTA
relationship file, so it reflects post-2020-census redistricting. The rebuild happens
inside the new reproducible data pipeline (`data-raw/04_build_zip_to_cd.R`) rather
than as a one-off, so future congresses are a scheduled refresh away instead of a
manual chore.

Credit where due: @awallender's PR #30 established exactly this method with the
118th-Congress file back in 2023 — the pipeline implementation follows it, updated to
the current vintage. Thank you!
