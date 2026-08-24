<!-- Draft comment for issue #32 — review before posting. Suggested action: post + close (documentation), noting the limitation is inherent. -->

You've diagnosed it exactly right: this is inherent to how ZIP codes work rather than
something zipcodeR can fully fix. ZIP codes are postal delivery constructs — routes
and delivery points, not polygons — and the "city" attached to a ZIP code is the
USPS's preferred *mailing* name, which routinely extends beyond municipal limits
(addresses outside a city's boundary often still carry that city's name).

For accurate jurisdiction assignment you need the full street address geocoded against
boundary files (e.g., Census TIGER/Line places), not the ZIP code alone. ZIP-code-level
attributes in this package are estimated at the ZCTA level, which is itself an
approximation.

The 0.4.0 release documents these limitations honestly in `?zip_code_db` (new
"Provenance and limitations" section) and in the FAQ vignette, so users hit this
caveat before relying on the jurisdiction columns. Closing as addressed by
documentation — happy to reopen if a concrete improvement to the data itself emerges
(a place-based crosswalk is on the roadmap for consideration).
