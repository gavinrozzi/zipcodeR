# Step 6: write the validated candidates into data/ and R/sysdata.rda,
# stamping data-version metadata, then recompress to CRAN-preferred formats.
# Run ONLY after 05_validate.R passes.

source(file.path("data-raw", "sources.R"))
cache_dir <- file.path("data-raw", "cache")

zip_code_db <- readRDS(file.path(cache_dir, "zip_code_db_candidate.rds"))
zcta_crosswalk <- readRDS(file.path(cache_dir, "zcta_crosswalk_candidate.rds"))
zip_to_cd <- readRDS(file.path(cache_dir, "zip_to_cd_candidate.rds"))

save(zip_code_db, file = file.path("data", "zip_code_db.rda"))
save(zcta_crosswalk, file = file.path("data", "zcta_crosswalk.rda"))
save(zip_to_cd, file = file.path("data", "zip_to_cd.rda"))

# Internal metadata: keep the legacy zip_code_db_version object (a Date) for
# backward compatibility and add the structured zip_data_meta consumed by
# zip_data_version().
fips_env <- new.env()
load(file.path("R", "sysdata.rda"), envir = fips_env)
fips_codes <- fips_env$fips_codes

zip_code_db_version <- Sys.Date()
zip_data_meta <- list(
  data_version = DATA_VERSION,
  build_date = format(Sys.Date()),
  zip_code_db_rows = nrow(zip_code_db),
  sources = list(
    base = "uszipcode-project 0.2.6-db-file (2021-06-08) + 1.0.1.db (2022-01-05), MIT",
    coordinates_area = sprintf("U.S. Census Bureau 2024 Gazetteer (2020 ZCTAs)"),
    acs = sprintf("U.S. Census Bureau ACS 5-year estimates, vintage %d", ACS_VINTAGE),
    place_names = "GeoNames (CC BY 4.0) for post-2021 additions",
    zcta_crosswalk = "Census 2020 ZCTA-to-tract relationship file",
    zip_to_cd = "Census 119th Congressional District-to-ZCTA relationship file"
  ),
  comprehensive = list(
    release_tag = paste0("data-", DATA_VERSION),
    asset = "comprehensive_db.sqlite",
    sha256 = "d85ed4e25884bc27bdd339d57dd9e2d1763531d4c050acb7a05a3d5aca90668d"
  )
)
save(
  zip_code_db_version, fips_codes, zip_data_meta,
  file = file.path("R", "sysdata.rda"), compress = "bzip2"
)

tools::resaveRdaFiles("data", compress = "auto")
message("finalize: data/ written. Sizes:")
for (f in list.files("data", full.names = TRUE)) {
  message(sprintf("  %s: %.2f MB", basename(f), file.size(f) / 1e6))
}
