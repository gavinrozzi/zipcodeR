# Step 4: build the refreshed zip_to_cd (ZIP <-> 119th-Congress district) in
# the exact schema of the shipped dataset: data.frame(ZIP chr, CD chr(4) =
# state FIPS + 2-digit district), multiple rows for multi-district ZIPs.
#
# Method follows PR #30 by @awallender (which used the CD118 vintage),
# updated to the 119th-Congress relationship file, with two additions:
#
# - Census "ZZ" pseudo-district rows (the not-in-any-district offshore/water
#   remainder) are excluded - they are not congressional districts.
# - The relationship file covers only 2020 ZCTAs, but zip_code_db also holds
#   USPS-only ZIP codes (P.O. Box / unique codes) that the previous
#   HUD-crosswalk-era dataset mapped. For those, districts are derived from
#   the districts of the same USPS city (major_city + state) among
#   ZCTA-covered ZIPs - a ZIP code's post office lies in its city, so the
#   city's district set bounds its possible districts (single-district cities,
#   the common case, give an exact assignment). Military ZIPs are left
#   unmapped: overseas APO/FPO codes have no geographic district.

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

# Derive districts for USPS-only (non-ZCTA) ZIPs from their city's districts
zipdb <- readRDS(file.path(cache_dir, "zip_code_db_candidate.rds"))
city_cd <- zipdb %>%
  filter(.data$zipcode %in% zcta_cd$ZIP) %>%
  select(zipcode, major_city, state) %>%
  inner_join(zcta_cd, by = c("zipcode" = "ZIP")) %>%
  distinct(.data$major_city, .data$state, .data$CD)

derived_cd <- zipdb %>%
  filter(
    !.data$zipcode %in% zcta_cd$ZIP,
    .data$zipcode_type != "Military",
    !is.na(.data$major_city), !is.na(.data$state)
  ) %>%
  select(ZIP = zipcode, major_city, state) %>%
  inner_join(city_cd, by = c("major_city", "state"),
             relationship = "many-to-many") %>%
  select(ZIP, CD) %>%
  distinct()

# Second fallback: in states/territories with exactly one district among
# their covered ZIPs (at-large states, Puerto Rico, DC), every ZIP in the
# state is in that district by construction
state_cd <- zipdb %>%
  filter(.data$zipcode %in% zcta_cd$ZIP) %>%
  select(zipcode, state) %>%
  inner_join(zcta_cd, by = c("zipcode" = "ZIP")) %>%
  distinct(.data$state, .data$CD) %>%
  group_by(.data$state) %>%
  filter(n() == 1) %>%
  ungroup()

state_derived_cd <- zipdb %>%
  filter(
    !.data$zipcode %in% c(zcta_cd$ZIP, derived_cd$ZIP),
    .data$zipcode_type != "Military",
    !is.na(.data$state)
  ) %>%
  select(ZIP = zipcode, state) %>%
  inner_join(state_cd, by = "state") %>%
  select(ZIP, CD) %>%
  distinct()

unmapped <- setdiff(
  zipdb$zipcode[zipdb$zipcode_type != "Military" | is.na(zipdb$zipcode_type)],
  c(zcta_cd$ZIP, derived_cd$ZIP, state_derived_cd$ZIP)
)
message(
  "zip_to_cd: ", length(unique(zcta_cd$ZIP)), " ZCTA-mapped ZIPs, ",
  length(unique(derived_cd$ZIP)), " city-derived + ",
  length(unique(state_derived_cd$ZIP)), " single-district-state USPS-only ZIPs, ",
  length(unmapped), " non-military ZIPs unmapped (no ZCTA, no covered city peer)"
)

zip_to_cd_new <- bind_rows(zcta_cd, derived_cd, state_derived_cd) %>%
  distinct() %>%
  arrange(.data$ZIP, .data$CD) %>%
  as.data.frame()

saveRDS(zip_to_cd_new, file.path(cache_dir, "zip_to_cd_candidate.rds"))
saveRDS(
  list(
    zcta_mapped = length(unique(zcta_cd$ZIP)),
    city_derived = length(unique(derived_cd$ZIP)) +
      length(unique(state_derived_cd$ZIP)),
    unmapped_nonmilitary = length(unmapped)
  ),
  file.path(cache_dir, "zip_to_cd_stats.rds")
)
message("zip_to_cd candidate: ", nrow(zip_to_cd_new), " rows (CD119 vintage)")
