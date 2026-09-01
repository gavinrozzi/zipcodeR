# Step 2: build the refreshed zip_code_db.
#
# Strategy: "carry-forward + refresh". The last committed zip_code_db is the
# base, guaranteeing no ZIP is ever silently dropped. For the 0.4.0 build that
# base is the database AUDIT.md proves byte-identical to the uszipcode 0.2.6
# snapshot; every later refresh carries forward from the previous data
# release, so a value in a carry-forward-only column can only be corrected by
# fixing it in a release rather than by rerunning the pipeline. On top of it:
#   1. Rows new in upstream 1.0.1 are appended only when independently
#      corroborated by the pinned Census ZCTA Gazetteer. Uncorroborated
#      USPS-only and placeholder rows are quarantined, not published.
#   2. 2020 Census ZCTAs absent from both snapshots are appended, built from
#      the Gazetteer + county relationship file + GeoNames place names.
#   3. Curated supplemental USPS-only ZIPs are retained as review evidence but
#      are not published without an authoritative source.
#   4. For every row whose ZIP is a 2020 ZCTA: coordinates and land/water area
#      are refreshed from the Census Gazetteer, and the five ACS attributes
#      are refreshed from the pinned ACS 5-year vintage.
# Columns with no current public source (bounds, radius, area codes, city
# alias lists) carry forward unchanged and are NA for new rows.

suppressMessages({
  library(dplyr)
})
source(file.path("data-raw", "sources.R"))
cache_dir <- file.path("data-raw", "cache")

# --- load inputs -----------------------------------------------------------
# The carry-forward base is a tracked, byte-pinned 0.3.5 input. It is included
# in the reproducibility archive, so this stage works without git metadata.
base_path <- file.path("data", "zip_code_db.rda")
base_expected <- LEGACY_BASELINE_FILES[["zip_code_db.rda"]]$sha256
base_got <- if (file.exists(base_path)) sha256_file(base_path) else "<missing>"
if (!identical(base_got, base_expected)) {
  stop(
    "Legacy carry-forward input failed checksum verification: ", base_path,
    "\n  expected: ", base_expected, "\n  got:      ", base_got
  )
}
message("carry-forward base: immutable zipcodeR 0.3.5 input")
base_env <- new.env()
load(base_path, envir = base_env)
base <- base_env$zip_code_db
stopifnot(ncol(base) == 24)

conn <- DBI::dbConnect(RSQLite::SQLite(), file.path(cache_dir, "simple_db.sqlite"))
upstream101 <- DBI::dbGetQuery(conn, "SELECT * FROM simple_zipcode")
DBI::dbDisconnect(conn)

gaz <- utils::read.delim(
  file.path(cache_dir, "2024_Gaz_zcta_national.txt"),
  colClasses = c(GEOID = "character"), strip.white = TRUE
)
names(gaz) <- trimws(names(gaz))

county_rel <- utils::read.delim(
  file.path(cache_dir, "tab20_zcta520_county20_natl.txt"),
  sep = "|", fileEncoding = "UTF-8-BOM",
  colClasses = c(GEOID_ZCTA5_20 = "character", GEOID_COUNTY_20 = "character")
)

geonames <- utils::read.delim(
  file.path(cache_dir, "US.txt"), header = FALSE, quote = "",
  colClasses = "character"
)
names(geonames) <- c(
  "country", "zipcode", "place", "state_name", "state", "county_name",
  "county_code", "admin3", "admin3_code", "lat", "lng", "accuracy"
)

acs <- utils::read.csv(
  file.path(cache_dir, sprintf("acs5_%d_zcta.csv", ACS_VINTAGE)),
  colClasses = c(zcta = "character")
)

supplement <- utils::read.csv(
  file.path("data-raw", "supplemental_zips.csv"),
  colClasses = "character"
)

fips_path <- file.path("R", "sysdata.rda")
fips_expected <- LEGACY_INTERNAL_FILES[[fips_path]]$sha256
fips_got <- if (file.exists(fips_path)) sha256_file(fips_path) else "<missing>"
if (!identical(fips_got, fips_expected)) {
  stop(
    "Immutable internal input failed checksum verification: ", fips_path,
    "\n  expected: ", fips_expected, "\n  got:      ", fips_got
  )
}
fips_env <- new.env()
load(fips_path, envir = fips_env)
fips_codes <- fips_env$fips_codes

# --- helper: an empty row in the exact schema of `base` --------------------
empty_rows <- function(n) {
  out <- base[rep(NA_integer_, n), , drop = FALSE]
  rownames(out) <- NULL
  out
}

titleize_type <- c(
  "STANDARD" = "Standard", "PO BOX" = "PO Box",
  "UNIQUE" = "Unique", "MILITARY" = "Military"
)

# --- 1. rows new in upstream 1.0.1 ----------------------------------------
new101_all <- upstream101[!upstream101$zipcode %in% base$zipcode, , drop = FALSE]
new101 <- new101_all[new101_all$zipcode %in% gaz$GEOID, , drop = FALSE]
quarantined101 <- new101_all[!new101_all$zipcode %in% gaz$GEOID, , drop = FALSE]
new101$zipcode_type <- unname(titleize_type[new101$zipcode_type])
# 1.0.1 uses 0.0 for unknown coordinates; normalize to NA
new101$lat[new101$lat == 0 & new101$lng == 0] <- NA_real_
new101$lng[is.na(new101$lat)] <- NA_real_
new101 <- new101[, names(base)]
message(
  "rows new in upstream 1.0.1 corroborated as Census ZCTAs: ", nrow(new101),
  "; quarantined non-ZCTA rows: ", nrow(quarantined101)
)

# --- 2. 2020 ZCTAs missing from both snapshots ----------------------------
known <- c(base$zipcode, new101$zipcode)
missing_zcta <- setdiff(gaz$GEOID, known)
message("2020 ZCTAs absent from both snapshots: ", length(missing_zcta))

# predominant county per ZCTA by land-area overlap
county_rel <- county_rel[county_rel$GEOID_ZCTA5_20 != "", ]
predominant <- county_rel %>%
  group_by(zcta = GEOID_ZCTA5_20) %>%
  slice_max(AREALAND_PART, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(zcta, county_geoid = GEOID_COUNTY_20, county_name = NAMELSAD_COUNTY_20)

state_by_fips <- fips_codes %>% distinct(state_code, state)
tz_by_state <- base %>%
  filter(!is.na(timezone)) %>%
  count(state, timezone) %>%
  group_by(state) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(state, timezone)

nz <- empty_rows(length(missing_zcta))
if (length(missing_zcta) > 0) {
  nz$zipcode <- missing_zcta
  nz$zipcode_type <- "Standard" # by construction these are 2020 ZCTAs
  gi <- match(missing_zcta, gaz$GEOID)
  nz$lat <- gaz$INTPTLAT[gi]
  nz$lng <- gaz$INTPTLONG[gi]
  nz$land_area_in_sqmi <- gaz$ALAND_SQMI[gi]
  nz$water_area_in_sqmi <- gaz$AWATER_SQMI[gi]
  pi_ <- match(missing_zcta, predominant$zcta)
  nz$county <- predominant$county_name[pi_]
  nz$state <- state_by_fips$state[
    match(substr(predominant$county_geoid[pi_], 1, 2), state_by_fips$state_code)
  ]
  gn <- geonames[!duplicated(geonames$zipcode), ]
  gni <- match(missing_zcta, gn$zipcode)
  nz$major_city <- gn$place[gni]
  nz$post_office_city <- ifelse(
    is.na(nz$major_city) | is.na(nz$state), NA_character_,
    paste0(nz$major_city, ", ", nz$state)
  )
  nz$timezone <- tz_by_state$timezone[match(nz$state, tz_by_state$state)]
}

# --- 3. curated supplemental USPS-only ZIPs -------------------------------
# These rows are review leads, not authoritative data. In particular, a point
# chosen from a ZIP's city must not be published as that ZIP's centroid.
supplement <- supplement[!supplement$zipcode %in% c(known, nz$zipcode), , drop = FALSE]
message("supplemental USPS-only ZIPs quarantined: ", nrow(supplement))

# Timezones for brand-new rows are IMPUTED as the modal timezone of the
# state (no free authoritative per-ZIP source yet; the ROADMAP's
# point-in-polygon stage replaces this). Wrong for new ZIPs in the minority
# zone of split-timezone states - the count is tracked in the refresh summary
# so reviewers can judge the exposure on every refresh.
imputed_tz <- c(
  nz$zipcode[!is.na(nz$timezone)]
)

# --- combine ---------------------------------------------------------------
additions <- bind_rows(new101, nz)
additions <- additions[order(additions$zipcode), ]
zip_code_db_new <- bind_rows(base, additions)

# --- 4. refresh ZCTA-backed attributes ------------------------------------
zi <- match(zip_code_db_new$zipcode, gaz$GEOID)
is_zcta_row <- !is.na(zi)
zip_code_db_new$lat[is_zcta_row] <- gaz$INTPTLAT[zi[is_zcta_row]]
zip_code_db_new$lng[is_zcta_row] <- gaz$INTPTLONG[zi[is_zcta_row]]
zip_code_db_new$land_area_in_sqmi[is_zcta_row] <- gaz$ALAND_SQMI[zi[is_zcta_row]]
zip_code_db_new$water_area_in_sqmi[is_zcta_row] <- gaz$AWATER_SQMI[zi[is_zcta_row]]

# A coordinate from the legacy third-party database is not an authoritative
# centroid for a USPS-only ZIP. Modern bundles therefore publish coordinates
# only for Census-backed ZCTAs; every unavailable record receives a quality
# reason in 06_finalize.R.
non_zcta_row <- !is_zcta_row
zip_code_db_new$lat[non_zcta_row] <- NA_real_
zip_code_db_new$lng[non_zcta_row] <- NA_real_

ai <- match(zip_code_db_new$zipcode, acs$zcta)
ar <- !is.na(ai)
as_int <- function(x) as.integer(round(x))
zip_code_db_new$population[ar] <- as_int(acs$population[ai[ar]])
zip_code_db_new$housing_units[ar] <- as_int(acs$housing_units[ai[ar]])
zip_code_db_new$occupied_housing_units[ar] <- as_int(acs$occupied_housing_units[ai[ar]])
zip_code_db_new$median_home_value[ar] <- as_int(acs$median_home_value[ai[ar]])
zip_code_db_new$median_household_income[ar] <- as_int(acs$median_household_income[ai[ar]])
zip_code_db_new$population_density <- ifelse(
  !is.na(zip_code_db_new$population) &
    !is.na(zip_code_db_new$land_area_in_sqmi) &
    zip_code_db_new$land_area_in_sqmi > 0,
  round(zip_code_db_new$population / zip_code_db_new$land_area_in_sqmi, 2),
  zip_code_db_new$population_density
)

# --- clean upstream garbage coordinates -----------------------------------
# Coordinates must come in pairs: a row with only one of lat/lng is not
# usable, so NA both rather than shipping a half-coordinate.
half_coord <- xor(is.na(zip_code_db_new$lat), is.na(zip_code_db_new$lng))
if (any(half_coord)) {
  message(
    "clearing half-specified coordinates for ", sum(half_coord), " row(s): ",
    paste(zip_code_db_new$zipcode[half_coord], collapse = ", ")
  )
  zip_code_db_new$lat[half_coord] <- NA_real_
  zip_code_db_new$lng[half_coord] <- NA_real_
}

# A handful of upstream military rows carry junk coordinates (e.g. 09323 at
# lat -44). NA them out rather than shipping impossible positions.
bad_coord <- !is.na(zip_code_db_new$lat) & !is.na(zip_code_db_new$lng) &
  (zip_code_db_new$lat < -15 | zip_code_db_new$lat > 72 |
     zip_code_db_new$lng < -180 | zip_code_db_new$lng > 180)
if (any(bad_coord)) {
  message(
    "clearing implausible coordinates for ",
    sum(bad_coord), " row(s): ",
    paste(zip_code_db_new$zipcode[bad_coord], collapse = ", ")
  )
  zip_code_db_new$lat[bad_coord] <- NA_real_
  zip_code_db_new$lng[bad_coord] <- NA_real_
}

# --- enforce the schema contract ------------------------------------------
zip_code_db_new <- zip_code_db_new[, names(base)]
for (col in names(base)) {
  if (is.integer(base[[col]])) zip_code_db_new[[col]] <- as.integer(zip_code_db_new[[col]])
  if (is.character(base[[col]])) zip_code_db_new[[col]] <- as.character(zip_code_db_new[[col]])
}
zip_code_db_new <- as.data.frame(zip_code_db_new)
rownames(zip_code_db_new) <- NULL

saveRDS(zip_code_db_new, file.path(cache_dir, "zip_code_db_candidate.rds"))
saveRDS(
  list(
    imputed_timezone_zips = imputed_tz,
    quarantined_upstream_zips = quarantined101$zipcode,
    quarantined_supplemental_zips = supplement$zipcode,
    coordinate_unavailable_zips = zip_code_db_new$zipcode[non_zcta_row]
  ),
  file.path(cache_dir, "zip_code_db_stats.rds")
)
saveRDS(
  list(upstream_1_0_1 = quarantined101, supplemental = supplement),
  file.path(cache_dir, "quarantined_zip_candidates.rds")
)
message(
  "zip_code_db candidate: ", nrow(zip_code_db_new), " rows (was ",
  nrow(base), "; +", nrow(additions), "); state-modal timezone imputed for ",
  length(imputed_tz), " new ZIP(s)"
)
