## Data refresh summary

- `zip_code_db`: 41900 rows (was 41877): **23 added, 0 removed**
  - added by type: PO Box (8), Standard (15)
  - coordinates refreshed for 32907 existing ZIPs; ACS attributes refreshed for 33637 ZIPs
- `zcta_crosswalk`: 168212 rows, 2020 ZCTA/tract vintage (previously 148897 rows)
- `zip_to_cd`: 40116 rows, 119th-Congress vintage (previously 45914 rows)
  - 33791 authoritative ZCTA-mapped ZIPs; 8109 ZIPs intentionally unmapped; no city/state-derived assignments
  - 5631 pre-2020 legacy mappings not carried into the authoritative-only crosswalk
- state-modal timezone imputed for 0 new ZIP(s)

Candidate data validation gate: **passed**
