<!-- Draft comment for issue #29 — review before posting. Close only after the modern bundle is public. -->

The default `zip_to_cd` object remains the exact 0.3.5 snapshot; replacing it
changed and removed thousands of existing mappings. The modern pipeline now
builds a separate 119th-Congress ZCTA relationship using only the authoritative
Census file. It deliberately leaves non-derivable USPS-only ZIPs unmapped rather
than assigning every district in the same city. Once the versioned asset is
public, callers can opt in with `get_cd_ng(bundle, ...)`.
