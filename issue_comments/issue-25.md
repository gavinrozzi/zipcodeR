<!-- Draft comment for issue #25 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

97003 is not added to the default 0.4.0 database because that object remains
byte-identical to 0.3.5 for reproducibility. The deterministic data pipeline
corroborates 97003 against the Census ZCTA Gazetteer, and the public
checksum-verified `2026.08` bundle includes its Census internal point. In 0.4.0
it is available through `reverse_zipcode_ng(bundle, "97003")` without changing
legacy calls.
