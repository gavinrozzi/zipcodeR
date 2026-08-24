# Step 5: validation gate. Every check here must pass before refreshed data
# ships. Aborts with a full failure list otherwise, and writes
# data-raw/refresh_summary.md describing the diff for the release PR.

suppressMessages(library(dplyr))
source(file.path("data-raw", "sources.R"))
cache_dir <- file.path("data-raw", "cache")

candidate <- readRDS(file.path(cache_dir, "zip_code_db_candidate.rds"))
zcta_candidate <- readRDS(file.path(cache_dir, "zcta_crosswalk_candidate.rds"))
cd_candidate <- readRDS(file.path(cache_dir, "zip_to_cd_candidate.rds"))

shipped_env <- new.env()
load(file.path("data", "zip_code_db.rda"), envir = shipped_env)
load(file.path("data", "zcta_crosswalk.rda"), envir = shipped_env)
load(file.path("data", "zip_to_cd.rda"), envir = shipped_env)
shipped <- shipped_env$zip_code_db

failures <- character()
check <- function(ok, label) {
  status <- if (isTRUE(ok)) "PASS" else "FAIL"
  message(sprintf("[%s] %s", status, label))
  if (!isTRUE(ok)) failures <<- c(failures, label)
  invisible(ok)
}

# --- zip_code_db -----------------------------------------------------------
check(
  nrow(candidate) >= nrow(shipped) && nrow(candidate) <= 46000,
  sprintf("row count in sane bounds (%d, was %d)", nrow(candidate), nrow(shipped))
)
dropped <- setdiff(shipped$zipcode, candidate$zipcode)
check(length(dropped) == 0, sprintf("no silent drops (%d dropped)", length(dropped)))
check(!anyDuplicated(candidate$zipcode), "zipcode is unique")
check(identical(names(candidate), names(shipped)), "column names identical")
check(
  identical(unname(sapply(candidate, function(x) class(x)[1])),
            unname(sapply(shipped, function(x) class(x)[1]))),
  "column classes identical"
)
check(identical(class(candidate), class(shipped)), "object class identical (data.frame)")

allowed_types <- c("Standard", "PO Box", "Unique", "Military", NA)
check(
  all(candidate$zipcode_type %in% allowed_types),
  "zipcode_type values within the documented set"
)

# regression ZIPs from #25 / #26 / #19 must be present WITH coordinates
regression_zips <- c(
  "97003", "91230",
  "00802", "00820", "00830", "00840", "00850", "00851", # USVI
  "96799", # American Samoa
  "96910", "96913", "96915", "96916", "96917", "96928", "96929", # Guam
  "96950", "96951", "96952", # N. Mariana
  "72405", "72713", "75036", "75072", "89437" # new mainland ZCTAs
)
ri <- match(regression_zips, candidate$zipcode)
check(!anyNA(ri), "all regression ZIPs (#19/#25/#26) present")
check(
  !anyNA(candidate$lat[ri]) && !anyNA(candidate$lng[ri]),
  "all regression ZIPs have coordinates"
)

# known-good distance spot checks (the #20 examples), via the package's own
# haversine; tolerance covers coordinate-precision refreshes
hav <- function(lat1, lng1, lat2, lng2) {
  tr <- pi / 180
  h <- sin((lat2 - lat1) * tr / 2)^2 +
    cos(lat1 * tr) * cos(lat2 * tr) * sin((lng2 - lng1) * tr / 2)^2
  2 * 6371008.8 * asin(pmin(1, sqrt(h))) * 0.000621371
}
dist_zip <- function(a, b) {
  ia <- match(a, candidate$zipcode); ib <- match(b, candidate$zipcode)
  hav(candidate$lat[ia], candidate$lng[ia], candidate$lat[ib], candidate$lng[ib])
}
# Ranges catch pair swaps and coordinate corruption while tolerating
# legitimate centroid-precision changes between data vintages. The #20
# reprex distinguishes a ~44mi leg from a ~10mi leg.
d1 <- dist_zip("08731", "08901")
d2 <- dist_zip("08734", "08005")
check(d1 > 35 && d1 < 50, sprintf("distance spot check 08731->08901 in [35,50] (%.1f)", d1))
check(d2 > 5 && d2 < 15, sprintf("distance spot check 08734->08005 in [5,15] (%.1f)", d2))
check(d1 > 2 * d2, "distance spot check: long leg dominates short leg (no pair swap)")
check(dist_zip("08731", "08731") == 0, "distance spot check identity = 0")

# coordinate sanity: US bounding envelope (incl. territories/military NA-safe)
with_coords <- !is.na(candidate$lat)
check(
  all(candidate$lat[with_coords] >= -15 & candidate$lat[with_coords] <= 72) &&
    all(candidate$lng[with_coords] >= -180 & candidate$lng[with_coords] <= 180),
  "coordinates within plausible envelope"
)
check(
  sum(!with_coords) <= sum(is.na(shipped$lat)) + 1000,
  "share of coordinate-less ZIPs did not grow materially"
)

# --- zcta_crosswalk --------------------------------------------------------
check(
  nrow(zcta_candidate) > 100000,
  sprintf("zcta_crosswalk row count sane (%d)", nrow(zcta_candidate))
)
check(
  identical(names(zcta_candidate), names(shipped_env$zcta_crosswalk)),
  "zcta_crosswalk schema identical"
)
check(
  all(nchar(zcta_candidate$TRACT) == 6),
  "zcta_crosswalk TRACT codes are 6 characters"
)

# --- zip_to_cd -------------------------------------------------------------
check(
  identical(names(cd_candidate), names(shipped_env$zip_to_cd)),
  "zip_to_cd schema identical"
)
check(
  all(grepl("^[0-9]{4}$", cd_candidate$CD)),
  "zip_to_cd CD codes are 4 digits (no ZZ pseudo-districts)"
)
check(
  length(setdiff(zcta_candidate$ZCTA5, cd_candidate$ZIP)) < 500,
  "zip_to_cd covers (nearly) all 2020 ZCTAs"
)
# no silent shrinkage of CD coverage: every non-military ZIP that had a
# district mapping in the shipped release must still have one
prev_covered <- intersect(shipped_env$zip_to_cd$ZIP, candidate$zipcode)
prev_covered <- setdiff(
  prev_covered,
  candidate$zipcode[candidate$zipcode_type %in% "Military"]
)
lost_cd <- setdiff(prev_covered, cd_candidate$ZIP)
check(
  length(lost_cd) == 0,
  sprintf("no ZIPs lost congressional-district coverage (%d lost)", length(lost_cd))
)

# --- release metadata ------------------------------------------------------
check(
  is.list(COMPREHENSIVE_RELEASE) &&
    grepl("^data-", COMPREHENSIVE_RELEASE$release_tag) &&
    grepl("^[0-9a-f]{64}$", COMPREHENSIVE_RELEASE$sha256),
  "COMPREHENSIVE_RELEASE registry is well-formed"
)
if (!identical(COMPREHENSIVE_RELEASE$release_tag, paste0("data-", DATA_VERSION))) {
  message(
    "[NOTE] comprehensive asset pinned to ", COMPREHENSIVE_RELEASE$release_tag,
    " (data release is data-", DATA_VERSION,
    ") - expected unless a new comprehensive asset was published"
  )
}

# --- summary for the release PR -------------------------------------------
added <- setdiff(candidate$zipcode, shipped$zipcode)
common <- intersect(candidate$zipcode, shipped$zipcode)
ci <- match(common, candidate$zipcode); si <- match(common, shipped$zipcode)
coord_changed <- sum(
  !is.na(candidate$lat[ci]) & !is.na(shipped$lat[si]) &
    (abs(candidate$lat[ci] - shipped$lat[si]) > 1e-6 |
       abs(candidate$lng[ci] - shipped$lng[si]) > 1e-6)
)
pop_changed <- sum(
  !identical(candidate$population[ci], shipped$population[si]) &
    (is.na(candidate$population[ci]) != is.na(shipped$population[si]) |
       coalesce(candidate$population[ci] != shipped$population[si], FALSE))
)

summary_md <- c(
  "## Data refresh summary",
  "",
  sprintf("- `zip_code_db`: %d rows (was %d): **%d added, 0 removed**",
          nrow(candidate), nrow(shipped), length(added)),
  sprintf("  - added by type: %s",
          paste(sprintf("%s (%d)", names(table(candidate$zipcode_type[match(added, candidate$zipcode)], useNA = "ifany")),
                        table(candidate$zipcode_type[match(added, candidate$zipcode)], useNA = "ifany")), collapse = ", ")),
  sprintf("  - coordinates refreshed for %d existing ZIPs; ACS attributes refreshed for %d ZIPs",
          coord_changed, pop_changed),
  sprintf("- `zcta_crosswalk`: %d rows, 2020 ZCTA/tract vintage (was %d rows, 2010)",
          nrow(zcta_candidate), nrow(shipped_env$zcta_crosswalk)),
  sprintf("- `zip_to_cd`: %d rows, 119th-Congress vintage (was %d rows, pre-2020)",
          nrow(cd_candidate), nrow(shipped_env$zip_to_cd)),
  local({
    s <- readRDS(file.path(cache_dir, "zip_to_cd_stats.rds"))
    sprintf(
      "  - %d ZCTA-mapped ZIPs + %d city-derived USPS-only ZIPs; %d non-military ZIPs unmapped",
      s$zcta_mapped, s$city_derived, s$unmapped_nonmilitary
    )
  }),
  local({
    s <- readRDS(file.path(cache_dir, "zip_code_db_stats.rds"))
    sprintf(
      "- state-modal timezone imputed for %d new ZIP(s)%s",
      length(s$imputed_timezone_zips),
      if (length(s$imputed_timezone_zips) > 0 && length(s$imputed_timezone_zips) <= 20) {
        paste0(": ", paste(s$imputed_timezone_zips, collapse = ", "))
      } else ""
    )
  }),
  "",
  sprintf("Validation gate: %s", if (length(failures) == 0) "**all checks passed**" else "**FAILED**")
)
writeLines(summary_md, file.path("data-raw", "refresh_summary.md"))

if (length(failures) > 0) {
  stop("Validation gate FAILED:\n  - ", paste(failures, collapse = "\n  - "))
}
message("validation gate: all checks passed")
