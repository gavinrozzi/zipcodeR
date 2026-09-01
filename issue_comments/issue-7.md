<!-- Draft comment for issue #7 — review before posting. Suggested action: post + close after 0.4.0 and the first modern bundle ship. -->

The recommended modern interface now includes FIPS identifiers in
`reverse_zipcode_ng(bundle, ...)`. It returns a two-digit `state_fips` and the
full five-digit `county_fips` for the predominant county represented by the
ZIP-level record. For example, Alexandria city is represented by county FIPS
`51510`.

The unsuffixed `reverse_zipcode()` output remains exactly as it was in 0.3.5 so
existing code that depends on its column schema is not silently changed. The
new columns are therefore available through the explicit `_ng` contract.
