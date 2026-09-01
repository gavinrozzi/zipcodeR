# Reverse-dependency validation

Validation was run on 2026-09-01 with R 4.6.1 on macOS Tahoe 26.6.2
(arm64). The candidate zipcodeR 0.4.0 package was installed into an isolated
library before checking the current CRAN source of `geospatialsuite` 0.2.0,
the only reverse dependency listed by CRAN (a reverse Suggests).

`R CMD check --no-manual` completed with status OK. Four optional Suggests of
`geospatialsuite` were unavailable and `_R_CHECK_FORCE_SUGGESTS_=false` was
used; none is needed for its zipcodeR integration. A separate targeted call to
`geospatialsuite:::geocode_zipcodes()` used the candidate package and matched
zipcodeR's frozen legacy `zip_code_db` contract exactly.
