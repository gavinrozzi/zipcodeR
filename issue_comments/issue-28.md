<!-- Draft comment for issue #28 — review before posting. Suggested action: post + close after 0.4.0 ships. -->

0.4.0 retains `raster` for the frozen distance API but no longer imports it at
package startup. Consequently, `library(zipcodeR)` does not load `sp`, `raster`,
`terra`, `sf`, or emit their retirement message. A legacy distance call loads
`raster` lazily and retains the exact 0.3.5 WGS84 result; the recommended `_ng`
distance path uses the internal modern calculation and never invokes it.

This removes the reported startup warning without rewriting historical
scientific output.
