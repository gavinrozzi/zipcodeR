# Step 4: build the refreshed zip_to_cd (ZIP <-> 119th-Congress district) in
# the exact schema of the shipped dataset: data.frame(ZIP chr, CD chr(4) =
# state FIPS + 2-digit district), multiple rows for multi-district ZIPs.
#
# Method follows PR #30 by @awallender (which used the CD118 vintage),
# updated to the 119th-Congress relationship file, with two additions:
#
# - Census "ZZ" pseudo-district rows (the not-in-any-district offshore/water
#   remainder) are excluded - they are not congressional districts.
# - The relationship file covers 2020 ZCTAs, not all USPS ZIP codes. USPS-only
#   codes are deliberately left unmapped: city-wide and state-wide inference
#   can over-assign districts and is not defensible for research use.

suppressMessages(library(dplyr))
cache_dir <- file.path("data-raw", "cache")

rel <- utils::read.delim(
  file.path(cache_dir, "tab20_cd11920_zcta520_natl.txt"),
  sep = "|", fileEncoding = "UTF-8-BOM",
  colClasses = c(GEOID_CD119_20 = "character", GEOID_ZCTA5_20 = "character")
)

zcta_cd <- rel %>%
  filter(
    .data$GEOID_ZCTA5_20 != "",
    grepl("^[0-9]{4}$", .data$GEOID_CD119_20) # drops "" and ZZ pseudo-districts
  ) %>%
  transmute(ZIP = .data$GEOID_ZCTA5_20, CD = .data$GEOID_CD119_20) %>%
  distinct()

# Load the candidate only to document which ZIPs remain unmapped.
zipdb <- readRDS(file.path(cache_dir, "zip_code_db_candidate.rds"))
unmapped <- setdiff(zipdb$zipcode, zcta_cd$ZIP)
counts <- list(
  zcta_mapped = length(unique(zcta_cd$ZIP)),
  city_derived = 0L,
  state_derived = 0L,
  unmapped = length(unmapped)
)
message(
  "zip_to_cd: ", counts$zcta_mapped, " authoritative ZCTA-mapped ZIPs; ",
  counts$unmapped, " ZIPs intentionally unmapped (not represented by a ZCTA)"
)
zip_to_cd_new <- zcta_cd %>%
  arrange(.data$ZIP, .data$CD) %>%
  as.data.frame()

saveRDS(zip_to_cd_new, file.path(cache_dir, "zip_to_cd_candidate.rds"))
saveRDS(counts, file.path(cache_dir, "zip_to_cd_stats.rds"))
message("zip_to_cd candidate: ", nrow(zip_to_cd_new), " rows (CD119 vintage)")
