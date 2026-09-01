<!-- Draft comment for issue #27 — review before posting. Do not close as a legacy fix. -->

The reported duplicate/order behavior is part of the installed 0.3.5 contract,
so changing `reverse_zipcode()` or `geocode_zip()` in 0.4.0 would silently
change existing research. Those names intentionally remain unchanged.

0.4.0 adds `reverse_zipcode_ng(bundle, ...)` and
`geocode_zip_ng(bundle, ...)`, which preserve input order and duplicates and
return explicit missing rows. The separate suffix makes the correction opt-in.
