<!-- Draft comment for issue #14 — review before posting. Suggested action: post + close. -->

Thanks for the kind words! The negative longitudes are correct: the United States is
in the western hemisphere, and the standard geographic sign convention makes
longitudes west of the prime meridian negative. Mapping libraries and spatial packages
all expect this, so please don't multiply by -1 — a positive 74° longitude would place
a New Jersey ZIP code in Central Asia.

The 0.4.0 release documents this in `?geocode_zip` and in a new FAQ vignette
(`vignette("faq", package = "zipcodeR")`), so closing this as resolved by
documentation.
