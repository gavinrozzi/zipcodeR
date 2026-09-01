<!-- Draft comment for issue #13 — review before posting. Suggested action: post + close (stale + documented). -->

Following up on an old one: this error (`object 'zip_code_db' not found` from a
lookup function) indicates a broken or partial installation — the datasets are
lazy-loaded with the package, and this symptom typically appears after migrating a
package library between R versions or an interrupted install. A clean
`install.packages("zipcodeR")` resolves it.

The 0.4.0 FAQ vignette (`vignette("faq", package = "zipcodeR")`) now documents this.
Closing as stale/documented — please open a fresh issue if it recurs on a current
release with a clean install.
