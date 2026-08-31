<!-- Draft comment for issue #25 — review before posting. Close only after the external bundle is public. -->

97003 is not added to the default 0.4.0 database because that object remains
byte-identical to 0.3.5 for reproducibility. The deterministic data pipeline
does corroborate 97003 against the Census ZCTA Gazetteer for the opt-in modern
bundle. After that bundle is public and checksum-verified, it will be available
through `reverse_zipcode_ng(bundle, "97003")` without changing legacy calls.
