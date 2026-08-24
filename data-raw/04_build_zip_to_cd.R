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

# One shared eligibility predicate: military ZIPs (overseas APO/FPO) have no
# geographic district; NA-typed ZIPs remain eligible for derivation
eligible <- zipdb %>% filter(!.data$zipcode_type %in% "Military")

# One covered-ZIP intermediate feeds both derivation lookups
covered <- zipdb %>%
  select(zipcode, major_city, state) %>%
  inner_join(zcta_cd, by = c("zipcode" = "ZIP"))

city_cd <- covered %>% distinct(.data$major_city, .data$state, .data$CD)

# Second fallback: in states/territories with exactly one district among
# their covered ZIPs (at-large states, Puerto Rico, DC), every ZIP in the
# state is in that district by construction
state_cd <- covered %>%
  distinct(.data$state, .data$CD) %>%
  group_by(.data$state) %>%
  filter(n() == 1) %>%
  ungroup()

derived_cd <- eligible %>%
  filter(
    !.data$zipcode %in% zcta_cd$ZIP,
    !is.na(.data$major_city), !is.na(.data$state)
  ) %>%
  select(ZIP = zipcode, major_city, state) %>%
  inner_join(city_cd, by = c("major_city", "state"),
             relationship = "many-to-many") %>%
  distinct(ZIP, CD)

state_derived_cd <- eligible %>%
  filter(
    !.data$zipcode %in% c(zcta_cd$ZIP, derived_cd$ZIP),
    !is.na(.data$state)
  ) %>%
  select(ZIP = zipcode, state) %>%
  inner_join(state_cd, by = "state") %>%
  distinct(ZIP, CD)

# Named counts, computed once and used for the message, the stats file, and
# the refresh summary
counts <- list(
  zcta_mapped = length(unique(zcta_cd$ZIP)),
  city_derived = length(unique(derived_cd$ZIP)),
  state_derived = length(unique(state_derived_cd$ZIP)),
  unmapped_nonmilitary = length(setdiff(
    eligible$zipcode, c(zcta_cd$ZIP, derived_cd$ZIP, state_derived_cd$ZIP)
  ))
)
message(
  "zip_to_cd: ", counts$zcta_mapped, " ZCTA-mapped ZIPs, ",
  counts$city_derived, " city-derived + ",
  counts$state_derived, " single-district-state USPS-only ZIPs, ",
  counts$unmapped_nonmilitary,
  " non-military ZIPs unmapped (no ZCTA, no covered city peer)"
)

# The three tiers are pairwise disjoint by construction; assert rather than
# papering over an overlap with distinct()
stopifnot(
  !any(derived_cd$ZIP %in% zcta_cd$ZIP),
  !any(state_derived_cd$ZIP %in% c(zcta_cd$ZIP, derived_cd$ZIP))
)
zip_to_cd_new <- bind_rows(zcta_cd, derived_cd, state_derived_cd) %>%
  arrange(.data$ZIP, .data$CD) %>%
  as.data.frame()

saveRDS(zip_to_cd_new, file.path(cache_dir, "zip_to_cd_candidate.rds"))
saveRDS(counts, file.path(cache_dir, "zip_to_cd_stats.rds"))
message("zip_to_cd candidate: ", nrow(zip_to_cd_new), " rows (CD119 vintage)")
