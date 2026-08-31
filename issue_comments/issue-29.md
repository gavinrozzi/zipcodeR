<!-- Draft comment for issue #29 — review before posting. Suggested action: post + close when 0.4.0 ships. -->

The default `zip_to_cd` object remains the exact 0.3.5 snapshot; replacing it
changed and removed thousands of existing mappings. The modern pipeline now
builds a separate 119th-Congress ZCTA relationship using only the authoritative
Census file. It deliberately leaves non-derivable USPS-only ZIPs unmapped rather
than assigning every district in the same city. The public checksum-verified
`2026.08` bundle is available to 0.4.0 callers through
`get_cd_ng(bundle, ...)`.
