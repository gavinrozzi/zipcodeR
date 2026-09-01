# Step 6: package validated candidates as an immutable external data bundle.
# This stage never writes data/ or R/sysdata.rda; those files are the frozen
# zipcodeR 0.3.5 compatibility contract.

source(file.path("data-raw", "sources.R"))
cache_dir <- file.path("data-raw", "cache")
release_dir <- file.path("data-raw", "release")
dir.create(release_dir, recursive = TRUE, showWarnings = FALSE)

zip_code_db <- readRDS(file.path(cache_dir, "zip_code_db_candidate.rds"))
zcta_crosswalk <- readRDS(file.path(cache_dir, "zcta_crosswalk_candidate.rds"))
zip_to_cd <- readRDS(file.path(cache_dir, "zip_to_cd_candidate.rds"))
stats <- readRDS(file.path(cache_dir, "zip_code_db_stats.rds"))

build_timestamp <- Sys.getenv("PIPELINE_BUILD_TIMESTAMP")
if (!nzchar(build_timestamp)) {
  stop("PIPELINE_BUILD_TIMESTAMP must be an explicit ISO-8601 timestamp.")
}

hash_file <- function(path) {
  if (exists("sha256_file", mode = "function")) return(sha256_file(path))
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)))
  }
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  unclass(as.character(openssl::sha256(con)))
}

hash_object <- function(object) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(object, path, version = 3, compress = "xz")
  hash_file(path)
}

git_output <- function(args) {
  out <- suppressWarnings(system2("git", args, stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status"))) return(NA_character_)
  paste(out, collapse = "\n")
}

pipeline_commit <- git_output(c("rev-parse", "HEAD"))
working_tree_dirty <- nzchar(git_output(c("status", "--porcelain")))

source_files <- c(
  zcta_tract_rel = file.path(cache_dir, basename(PIPELINE_SOURCES$zcta_tract_rel$url)),
  zcta_county_rel = file.path(cache_dir, basename(PIPELINE_SOURCES$zcta_county_rel$url)),
  cd_zcta_rel = file.path(cache_dir, basename(PIPELINE_SOURCES$cd_zcta_rel$url)),
  gazetteer_zcta = file.path(cache_dir, basename(PIPELINE_SOURCES$gazetteer_zcta$url)),
  geonames_us = file.path(cache_dir, basename(PIPELINE_SOURCES$geonames_us$url)),
  uszipcode_simple_101 = file.path(cache_dir, basename(PIPELINE_SOURCES$uszipcode_simple_101$url)),
  acs_2023_raw = file.path(cache_dir, sprintf("acs5_%d_zcta.json", ACS_VINTAGE)),
  acs_2023_derived = file.path(cache_dir, sprintf("acs5_%d_zcta.csv", ACS_VINTAGE))
)
if (!all(file.exists(source_files))) {
  stop("Cannot finalize: one or more archived source files are missing.")
}

source_manifest <- lapply(names(source_files), function(id) {
  registry <- PIPELINE_SOURCES[[id]]
  is_acs_raw <- identical(id, "acs_2023_raw")
  is_acs_derived <- identical(id, "acs_2023_derived")
  list(
    id = id,
    file = basename(source_files[[id]]),
    kind = if (is_acs_raw) {
      "archived_api_response"
    } else if (is_acs_derived) {
      "deterministically_derived_artifact"
    } else {
      "archived_download"
    },
    url = if (is_acs_raw) ACS_ENDPOINT else if (is_acs_derived) NULL else registry$url,
    request = if (is_acs_raw) {
      list(
        get = unname(ACS_VARIABLES),
        geography = "zip code tabulation area:*",
        authentication = "Census API key required but never archived"
      )
    } else {
      NULL
    },
    derived_from = if (is_acs_derived) "acs_2023_raw" else NULL,
    sha256 = hash_file(source_files[[id]]),
    license = if (is.null(registry)) {
      "U.S. public domain (U.S. Census Bureau)"
    } else {
      registry$license
    },
    vintage = if (grepl("^acs_2023", id)) as.character(ACS_VINTAGE) else NULL
  )
})

unmapped_cd <- setdiff(zip_code_db$zipcode, zip_to_cd$ZIP)
cd_quality <- data.frame(
  dataset = "zip_to_cd",
  key = unmapped_cd,
  field = "CD",
  status = "unmapped",
  reason = paste(
    "No authoritative 2020-ZCTA-to-CD119 relationship;",
    "no city/state inference applied"
  ),
  stringsAsFactors = FALSE
)
zcta_keys <- unique(zcta_crosswalk$ZCTA5)
coordinate_is_authoritative <- zip_code_db$zipcode %in% zcta_keys &
  !is.na(zip_code_db$lat) & !is.na(zip_code_db$lng)
coordinate_quality <- data.frame(
  dataset = "zip_code_db",
  key = zip_code_db$zipcode,
  field = "lat,lng",
  status = ifelse(coordinate_is_authoritative, "authoritative", "unavailable"),
  reason = ifelse(
    coordinate_is_authoritative,
    "Census ZCTA internal point",
    "No authoritative coordinate for this non-ZCTA or unavailable ZCTA"
  ),
  stringsAsFactors = FALSE
)
acs_keys <- utils::read.csv(
  file.path(cache_dir, sprintf("acs5_%d_zcta.csv", ACS_VINTAGE)),
  colClasses = c(zcta = "character")
)$zcta
demographic_quality <- data.frame(
  dataset = "zip_code_db",
  key = zip_code_db$zipcode,
  field = "demographics",
  status = ifelse(
    zip_code_db$zipcode %in% acs_keys,
    "authoritative_current_vintage",
    "legacy_carried_forward_or_missing"
  ),
  reason = ifelse(
    zip_code_db$zipcode %in% acs_keys,
    paste0("ACS ", ACS_VINTAGE, " 5-year ZCTA estimates"),
    "No matching ACS ZCTA; values may be legacy carry-forward or missing"
  ),
  stringsAsFactors = FALSE
)
quality <- rbind(cd_quality, coordinate_quality, demographic_quality)
quarantine <- unique(c(
  stats$quarantined_upstream_zips,
  stats$quarantined_supplemental_zips
))
quarantine_provenance <- data.frame(
  dataset = "zip_code_db",
  key = quarantine,
  field = "record",
  source_id = "quarantine",
  method = "excluded pending authoritative corroboration",
  quality = "quarantined",
  note = "Not present in the published bundle",
  stringsAsFactors = FALSE
)
dataset_provenance <- data.frame(
  dataset = c("zip_code_db", "zip_code_db", "zcta_crosswalk", "zip_to_cd"),
  key = "*",
  field = c("coordinates_and_area", "demographics", "record", "record"),
  source_id = c("gazetteer_zcta", "acs_2023_derived", "zcta_tract_rel", "cd_zcta_rel"),
  method = c(
    "Census ZCTA internal points and area",
    "ACS 5-year ZCTA estimates",
    "direct Census relationship",
    "direct Census relationship; ZZ pseudo-districts excluded"
  ),
  quality = "authoritative_source",
  note = c(
    "Applies only to Census-backed ZCTA rows",
    "Applies only to rows matched to the archived ACS response",
    "",
    "USPS-only ZIPs are intentionally unmapped"
  ),
  stringsAsFactors = FALSE
)
provenance <- rbind(dataset_provenance, quarantine_provenance)
output_hashes <- list(
  zip_code_db = hash_object(zip_code_db),
  zcta_crosswalk = hash_object(zcta_crosswalk),
  zip_to_cd = hash_object(zip_to_cd),
  provenance = hash_object(provenance),
  quality = hash_object(quality)
)

metadata <- list(
  data_version = DATA_VERSION,
  build_timestamp = build_timestamp,
  pipeline_commit = pipeline_commit,
  working_tree_dirty = working_tree_dirty,
  r_version = R.version.string,
  dependency_lock_sha256 = hash_file(file.path("data-raw", "pkg.lock")),
  pak_bootstrap_sha256 = hash_file(file.path("data-raw", "vendor", "pak_0.11.1.tar.gz")),
  output_hashes = output_hashes,
  rows = list(
    zip_code_db = nrow(zip_code_db),
    zcta_crosswalk = nrow(zcta_crosswalk),
    zip_to_cd = nrow(zip_to_cd)
  ),
  sources = source_manifest,
  policies = list(
    legacy_defaults = "zipcodeR 0.3.5 datasets remain bundled in the package",
    non_zcta_additions = "quarantined unless authoritatively corroborated",
    congressional_districts = "authoritative Census ZCTA relationships only"
  )
)

bundle <- structure(
  list(
    zip_code_db = zip_code_db,
    zcta_crosswalk = zcta_crosswalk,
    zip_to_cd = zip_to_cd,
    metadata = metadata,
    provenance = provenance,
    quality = quality
  ),
  class = c("zipcodeR_data_bundle", "list")
)

asset <- sprintf("zipcodeR-data-%s.rds", DATA_VERSION)
asset_path <- file.path(release_dir, asset)
saveRDS(bundle, asset_path, version = 3, compress = "xz")
asset_sha256 <- hash_file(asset_path)

manifest <- list(
  format = 1,
  data_version = DATA_VERSION,
  release_tag = paste0("data-", DATA_VERSION),
  asset = asset,
  asset_sha256 = asset_sha256,
  asset_size = unname(file.info(asset_path)$size),
  build_timestamp = build_timestamp,
  pipeline_commit = pipeline_commit,
  working_tree_dirty = working_tree_dirty,
  r_version = metadata$r_version,
  dependency_lock_sha256 = metadata$dependency_lock_sha256,
  pak_bootstrap_sha256 = metadata$pak_bootstrap_sha256,
  output_hashes = output_hashes,
  schemas = list(
    zip_code_db = lapply(names(zip_code_db), function(name) {
      list(name = name, type = class(zip_code_db[[name]])[1])
    }),
    zcta_crosswalk = lapply(names(zcta_crosswalk), function(name) {
      list(name = name, type = class(zcta_crosswalk[[name]])[1])
    }),
    zip_to_cd = lapply(names(zip_to_cd), function(name) {
      list(name = name, type = class(zip_to_cd[[name]])[1])
    })
  ),
  rows = metadata$rows,
  sources = source_manifest
)
manifest_path <- file.path(release_dir, sprintf("manifest-%s.json", DATA_VERSION))
jsonlite::write_json(
  manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE, null = "null"
)

repro_files <- c(
  list.files(
    "data-raw", pattern = "\\.(R|md|json|csv|txt)$", full.names = TRUE
  ),
  file.path("data-raw", "Dockerfile"),
  file.path("data-raw", "pkg.lock"),
  file.path("data-raw", "LICENSES.md"),
  file.path("data-raw", "vendor", "pak_0.11.1.tar.gz"),
  source_files,
  manifest_path,
  "DESCRIPTION"
)
repro_files <- unique(repro_files[file.exists(repro_files)])
repro_path <- file.path(
  release_dir, sprintf("zipcodeR-reproducibility-%s.tar.gz", DATA_VERSION)
)

# Archive from a staging tree with a fixed timestamp and mode. Several files
# above are deterministically regenerated on every pass; archiving their live
# filesystem mtimes would make the reproducibility archive itself change even
# when every byte of its content is identical.
repro_stage <- tempfile("zipcodeR-repro-")
dir.create(repro_stage)
for (source in repro_files) {
  destination <- file.path(repro_stage, source)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(source, destination, overwrite = TRUE, copy.mode = FALSE,
                 copy.date = FALSE)) {
    stop("Failed to stage reproducibility input: ", source)
  }
  Sys.chmod(destination, mode = "0644")
}
archive_time <- as.POSIXct(build_timestamp, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
if (is.na(archive_time)) stop("PIPELINE_BUILD_TIMESTAMP is not valid ISO-8601 UTC.")
staged_files <- file.path(repro_stage, repro_files)
invisible(lapply(staged_files, Sys.setFileTime, time = archive_time))
repro_path_absolute <- file.path(normalizePath(release_dir), basename(repro_path))
write_reproducibility_archive <- function() {
  old_working_directory <- setwd(repro_stage)
  on.exit(setwd(old_working_directory), add = TRUE)
  utils::tar(
    repro_path_absolute,
    files = repro_files,
    compression = "gzip",
    tar = "internal"
  )
}
write_reproducibility_archive()
unlink(repro_stage, recursive = TRUE)

message("bundle: ", asset_path, " (sha256 ", asset_sha256, ")")
message("manifest: ", manifest_path)
message("reproducibility archive: ", repro_path)
if (working_tree_dirty) {
  message(
    "NOTE: working tree is dirty; artifacts are test candidates and must not be published."
  )
}
