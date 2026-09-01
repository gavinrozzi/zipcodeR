#' Read a versioned zipcodeR data bundle
#'
#' Reads and validates a previously downloaded zipcodeR data bundle. Bundles
#' are explicit, immutable inputs for the next-generation (`_ng`) API; reading
#' one never changes the datasets used by the legacy API.
#'
#' @param path Path to a bundle `.rds` file.
#' @param sha256 Optional expected SHA256 checksum. Supplying the checksum is
#'   strongly recommended when the file did not come from
#'   [download_zip_data_bundle()].
#' @return An object of class `zipcodeR_data_bundle`.
#' @export
read_zip_data_bundle <- function(path, sha256 = NULL) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("`path` must be one non-empty file path.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop("Data bundle does not exist: ", path, call. = FALSE)
  }
  if (!is.null(sha256)) {
    validate_sha256(sha256, "sha256")
    got <- file_sha256(path)
    if (!identical(got, tolower(sha256))) {
      stop(
        "Checksum verification failed for data bundle.\n  expected: ",
        tolower(sha256), "\n  got:      ", got,
        call. = FALSE
      )
    }
  } else {
    got <- file_sha256(path)
  }

  bundle <- readRDS(path)
  bundle <- validate_zip_data_bundle(bundle)
  attr(bundle, "bundle_sha256") <- got
  attr(bundle, "bundle_path") <- normalizePath(path, mustWork = TRUE)
  bundle
}

#' Download a versioned zipcodeR data bundle
#'
#' Downloads one explicitly requested data release, verifies its checksum, and
#' caches it in the user's data directory on R 4.0 or newer. On older supported
#' R versions, CRAN policy does not permit a package-managed persistent cache,
#' so the verified file is retained only for the current R session. The
#' function never resolves aliases such as `"latest"`, and no lookup function
#' downloads data implicitly.
#'
#' @param version Exact registered data version, for example `"2026.09"`.
#' @param force Re-download and replace a verified cached copy.
#' @return A validated `zipcodeR_data_bundle`.
#' @export
download_zip_data_bundle <- function(version, force = FALSE) {
  meta <- registered_zip_data_bundle(version)
  cache_dir <- zipcodeR_user_data_dir()
  download_zip_data_bundle_from(meta, force = force, cache_dir = cache_dir)
}

#' Report zipcodeR data-version metadata
#'
#' With no argument, reports the immutable data bundled with the legacy API.
#' Given a downloaded data bundle, reports that bundle's metadata and verified
#' checksum.
#'
#' @param x `NULL` for the legacy bundled data, or a
#'   `zipcodeR_data_bundle` object.
#' @return A named metadata list.
#' @export
zip_data_version <- function(x = NULL) {
  if (is.null(x)) {
    return(legacy_zip_data_meta())
  }
  x <- validate_zip_data_bundle(x)
  out <- x$metadata
  out$bundle_sha256 <- attr(x, "bundle_sha256", exact = TRUE)
  out
}

#' Inspect the provenance supplied with a zipcodeR data bundle
#'
#' @param bundle A `zipcodeR_data_bundle`.
#' @param dataset Optional dataset name (`"zip_code_db"`,
#'   `"zcta_crosswalk"`, or `"zip_to_cd"`).
#' @param key Optional record key (ZIP or ZCTA) to select.
#' @return A provenance data frame combining source/method records with
#'   record-level quality status and reasons.
#' @export
zip_data_provenance <- function(bundle, dataset = NULL, key = NULL) {
  bundle <- validate_zip_data_bundle(bundle)
  provenance_columns <- c(
    "dataset", "key", "field", "source_id", "method", "quality", "note"
  )
  quality <- data.frame(
    dataset = bundle$quality$dataset,
    key = bundle$quality$key,
    field = bundle$quality$field,
    source_id = NA_character_,
    method = bundle$quality$status,
    quality = bundle$quality$status,
    note = bundle$quality$reason,
    stringsAsFactors = FALSE
  )
  provenance <- rbind(
    bundle$provenance[, provenance_columns, drop = FALSE],
    quality[, provenance_columns, drop = FALSE]
  )
  if (!is.null(dataset)) {
    if (!is.character(dataset) || length(dataset) != 1L || is.na(dataset)) {
      stop("`dataset` must be one dataset name.", call. = FALSE)
    }
    allowed <- c("zip_code_db", "zcta_crosswalk", "zip_to_cd")
    if (!dataset %in% allowed) {
      stop(
        "Unknown `dataset`; choose one of: ", paste(allowed, collapse = ", "),
        call. = FALSE
      )
    }
    provenance <- provenance[provenance$dataset == dataset, , drop = FALSE]
  }
  if (!is.null(key)) {
    key <- as.character(key)
    provenance <- provenance[provenance$key %in% c("*", key), , drop = FALSE]
  }
  provenance
}

#' @noRd
legacy_zip_data_meta <- function() {
  list(
    data_version = "legacy-0.3.5",
    package_version = "0.3.5",
    zip_code_db_rows = 41877L,
    zcta_crosswalk_rows = 148897L,
    zip_to_cd_rows = 45914L,
    sources = list(
      zip_code_db = "uszipcode-project 0.2.6-db-file (2021-06-08)",
      zcta_crosswalk = "U.S. Census 2010 ZCTA-to-tract relationship file",
      zip_to_cd = "pre-2020 HUD-USPS congressional-district crosswalk"
    ),
    compatibility_contract = "Exact zipcodeR 0.3.5 defaults"
  )
}

#' @noRd
registered_zip_data_bundle <- function(version) {
  if (!is.character(version) || length(version) != 1L || is.na(version) ||
      !nzchar(version)) {
    stop("`version` must be one explicit data version.", call. = FALSE)
  }
  if (version %in% c("latest", "current", "stable")) {
    stop(
      "Aliases such as '", version, "' are not supported; pin an exact data version.",
      call. = FALSE
    )
  }
  registry <- zip_data_bundle_registry()
  if (!version %in% names(registry)) {
    stop(
      "Unknown zipcodeR data version '", version, "'. Registered versions: ",
      paste(names(registry), collapse = ", "),
      call. = FALSE
    )
  }
  registry[[version]]
}

# Registry entries are updated only after the corresponding public release
# asset has been downloaded and independently checksum-verified.
#' @noRd
zip_data_bundle_registry <- function() {
  list(
    "2026.09" = list(
      version = "2026.09",
      asset = "zipcodeR-data-2026.09.rds",
      url = paste0(
        "https://github.com/gavinrozzi/zipcodeR/releases/download/",
        "data-2026.09/zipcodeR-data-2026.09.rds"
      ),
      sha256 = "0805a5be5fe826c4c8e3a3bab65f2d311671f96a2e1aa2c84d8571b0b9f3bd23"
    ),
    "2026.08" = list(
      version = "2026.08",
      asset = "zipcodeR-data-2026.08.rds",
      url = paste0(
        "https://github.com/gavinrozzi/zipcodeR/releases/download/",
        "data-2026.08/zipcodeR-data-2026.08.rds"
      ),
      sha256 = "9059026c159a4d1311ad9c61ba5193a6123299503efb5d867b8303c9d23627e4"
    )
  )
}

#' @noRd
download_zip_data_bundle_from <- function(meta, force, cache_dir) {
  if (!is.logical(force) || length(force) != 1L || is.na(force)) {
    stop("`force` must be TRUE or FALSE.", call. = FALSE)
  }
  validate_bundle_registry_entry(meta)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(cache_dir, meta$asset)

  if (file.exists(dest) && !force) {
    if (identical(file_sha256(dest), meta$sha256)) {
      bundle <- read_zip_data_bundle(dest, sha256 = meta$sha256)
      return(validate_registered_bundle_version(bundle, meta))
    }
    message("zipcodeR: cached bundle failed checksum verification; re-downloading")
  }
  if (!zipcodeR_has_internet()) {
    stop("No internet connection. The requested data bundle was not cached.", call. = FALSE)
  }

  tmp <- tempfile(paste0(basename(dest), "-"), tmpdir = cache_dir)
  on.exit(unlink(tmp), add = TRUE)
  old_timeout <- options(timeout = max(600, getOption("timeout")))
  on.exit(options(old_timeout), add = TRUE)
  tryCatch(
    download_zip_data_file(meta$url, tmp),
    error = function(e) {
      stop("Data bundle download failed: ", conditionMessage(e), call. = FALSE)
    }
  )
  got <- file_sha256(tmp)
  if (!identical(got, meta$sha256)) {
    stop(
      "Checksum verification failed for downloaded data bundle.\n  expected: ",
      meta$sha256, "\n  got:      ", got,
      call. = FALSE
    )
  }
  if (!file.rename(tmp, dest) && !file.copy(tmp, dest, overwrite = TRUE)) {
    stop("Failed to move the verified bundle into the cache: ", dest, call. = FALSE)
  }
  bundle <- read_zip_data_bundle(dest, sha256 = meta$sha256)
  validate_registered_bundle_version(bundle, meta)
}

# Small wrappers keep download failure, interruption, and offline behavior
# testable without allowing tests to contact the network.
#' @noRd
zipcodeR_has_internet <- function() curl::has_internet()

#' @noRd
download_zip_data_file <- function(url, path) {
  utils::download.file(url, path, mode = "wb", quiet = TRUE)
}

#' @noRd
validate_registered_bundle_version <- function(bundle, meta) {
  if (!identical(bundle$metadata$data_version, meta$version)) {
    stop(
      "Registered bundle version mismatch. Expected '", meta$version,
      "' but the bundle reports '", bundle$metadata$data_version, "'.",
      call. = FALSE
    )
  }
  bundle
}

#' @noRd
validate_bundle_registry_entry <- function(meta) {
  required <- c("version", "asset", "url", "sha256")
  if (!is.list(meta) || !all(required %in% names(meta))) {
    stop("Malformed zipcodeR data-bundle registry entry.", call. = FALSE)
  }
  validate_sha256(meta$sha256, "registered sha256")
  invisible(meta)
}

#' @noRd
validate_sha256 <- function(x, label) {
  if (!is.character(x) || length(x) != 1L || is.na(x) ||
      !grepl("^[0-9a-fA-F]{64}$", x)) {
    stop("`", label, "` must be a 64-character SHA256 value.", call. = FALSE)
  }
  invisible(tolower(x))
}

# Validate a published manifest against its bundle. This is intentionally
# internal: callers pin bundle bytes through download_zip_data_bundle() or
# read_zip_data_bundle(), while release automation uses this additional gate
# before a registry entry is enabled.
#' @noRd
validate_zip_data_release_manifest <- function(manifest_path, bundle_path,
                                               manifest_sha256 = NULL) {
  for (item in c("manifest_path", "bundle_path")) {
    value <- get(item)
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(value) || !file.exists(value)) {
      stop("`", item, "` must name one existing file.", call. = FALSE)
    }
  }
  if (!is.null(manifest_sha256)) {
    validate_sha256(manifest_sha256, "manifest_sha256")
    got_manifest <- file_sha256(manifest_path)
    if (!identical(got_manifest, tolower(manifest_sha256))) {
      stop("Manifest checksum verification failed.", call. = FALSE)
    }
  }

  manifest <- tryCatch(
    jsonlite::fromJSON(manifest_path, simplifyVector = FALSE),
    error = function(e) {
      stop("Invalid data-release manifest: ", conditionMessage(e), call. = FALSE)
    }
  )
  required <- c(
    "data_version", "asset", "asset_sha256", "rows", "schemas",
    "sources", "output_hashes", "pipeline_commit", "r_version",
    "dependency_lock_sha256"
  )
  if (!is.list(manifest) || !all(required %in% names(manifest))) {
    stop(
      "Invalid data-release manifest: missing required fields: ",
      paste(setdiff(required, names(manifest)), collapse = ", "),
      call. = FALSE
    )
  }
  validate_sha256(manifest$asset_sha256, "manifest asset_sha256")
  if (!identical(basename(bundle_path), manifest$asset)) {
    stop("Manifest asset name does not match the bundle file.", call. = FALSE)
  }
  bundle <- read_zip_data_bundle(bundle_path, sha256 = manifest$asset_sha256)
  if (!identical(bundle$metadata$data_version, manifest$data_version)) {
    stop("Manifest data version does not match the bundle.", call. = FALSE)
  }

  expected_rows <- c(
    zip_code_db = nrow(bundle$zip_code_db),
    zcta_crosswalk = nrow(bundle$zcta_crosswalk),
    zip_to_cd = nrow(bundle$zip_to_cd)
  )
  manifest_rows <- unlist(manifest$rows[ names(expected_rows) ], use.names = TRUE)
  if (!identical(as.numeric(manifest_rows), as.numeric(expected_rows))) {
    stop("Manifest row counts do not match the bundle.", call. = FALSE)
  }

  expected_schemas <- list(
    zip_code_db = vapply(bundle$zip_code_db, function(x) class(x)[1], character(1)),
    zcta_crosswalk = vapply(bundle$zcta_crosswalk, function(x) class(x)[1], character(1)),
    zip_to_cd = vapply(bundle$zip_to_cd, function(x) class(x)[1], character(1))
  )
  for (dataset in names(expected_schemas)) {
    schema <- manifest$schemas[[dataset]]
    if (!is.list(schema) || !length(schema) ||
        !all(vapply(schema, function(x) {
          is.list(x) && all(c("name", "type") %in% names(x))
        }, logical(1)))) {
      stop("Manifest schema is malformed for `", dataset, "`.", call. = FALSE)
    }
    schema_names <- vapply(schema, function(x) x$name, character(1))
    schema_types <- vapply(schema, function(x) x$type, character(1))
    if (!identical(schema_names, names(expected_schemas[[dataset]])) ||
        !identical(schema_types, unname(expected_schemas[[dataset]]))) {
      stop("Manifest schema does not match `", dataset, "`.", call. = FALSE)
    }
  }
  bundle_hashes <- bundle$metadata$output_hashes
  if (!is.list(bundle_hashes) ||
      !identical(unlist(manifest$output_hashes), unlist(bundle_hashes))) {
    stop("Manifest canonical output hashes do not match the bundle.", call. = FALSE)
  }
  invisible(bundle)
}

#' @noRd
validate_zip_data_bundle <- function(bundle) {
  required <- c(
    "zip_code_db", "zcta_crosswalk", "zip_to_cd", "metadata",
    "provenance", "quality"
  )
  if (!is.list(bundle) || !all(required %in% names(bundle))) {
    stop(
      "Invalid zipcodeR data bundle: required entries are ",
      paste(required, collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (!is.data.frame(bundle$zip_code_db) ||
      !identical(names(bundle$zip_code_db), legacy_zip_code_db_columns())) {
    stop("Invalid `zip_code_db` schema in data bundle.", call. = FALSE)
  }
  if (anyDuplicated(bundle$zip_code_db$zipcode)) {
    stop("Invalid data bundle: `zip_code_db$zipcode` is not unique.", call. = FALSE)
  }
  if (!is.character(bundle$zip_code_db$zipcode) ||
      !all(grepl("^[0-9]{5}$", bundle$zip_code_db$zipcode))) {
    stop("Invalid data bundle: ZIP identifiers must be five characters.", call. = FALSE)
  }
  if (!is.numeric(bundle$zip_code_db$lat) || !is.numeric(bundle$zip_code_db$lng) ||
      any(xor(is.na(bundle$zip_code_db$lat), is.na(bundle$zip_code_db$lng))) ||
      any(abs(bundle$zip_code_db$lat) > 90, na.rm = TRUE) ||
      any(abs(bundle$zip_code_db$lng) > 180, na.rm = TRUE)) {
    stop("Invalid data bundle: malformed coordinate values.", call. = FALSE)
  }
  if (!is.data.frame(bundle$zcta_crosswalk) ||
      !identical(names(bundle$zcta_crosswalk), c("ZCTA5", "TRACT", "GEOID"))) {
    stop("Invalid `zcta_crosswalk` schema in data bundle.", call. = FALSE)
  }
  if (!is.character(bundle$zcta_crosswalk$ZCTA5) ||
      !is.character(bundle$zcta_crosswalk$TRACT) ||
      !is.character(bundle$zcta_crosswalk$GEOID)) {
    stop("Invalid `zcta_crosswalk` types in data bundle.", call. = FALSE)
  }
  if (!all(grepl("^[0-9]{5}$", bundle$zcta_crosswalk$ZCTA5)) ||
      !all(grepl("^[0-9]{6}$", bundle$zcta_crosswalk$TRACT)) ||
      !all(grepl("^[0-9]{11}$", bundle$zcta_crosswalk$GEOID)) ||
      anyDuplicated(bundle$zcta_crosswalk)) {
    stop("Invalid identifier values in `zcta_crosswalk`.", call. = FALSE)
  }
  if (!is.data.frame(bundle$zip_to_cd) ||
      !identical(names(bundle$zip_to_cd), c("ZIP", "CD"))) {
    stop("Invalid `zip_to_cd` schema in data bundle.", call. = FALSE)
  }
  if (!is.character(bundle$zip_to_cd$ZIP) || !is.character(bundle$zip_to_cd$CD) ||
      !all(grepl("^[0-9]{5}$", bundle$zip_to_cd$ZIP)) ||
      !all(grepl("^[0-9]{4}$", bundle$zip_to_cd$CD)) ||
      anyDuplicated(bundle$zip_to_cd)) {
    stop("Invalid identifier values in `zip_to_cd`.", call. = FALSE)
  }
  if (!is.list(bundle$metadata) ||
      !is.character(bundle$metadata$data_version %||% NULL) ||
      length(bundle$metadata$data_version) != 1L ||
      is.na(bundle$metadata$data_version) ||
      !nzchar(bundle$metadata$data_version)) {
    stop("Invalid data bundle: metadata must contain `data_version`.", call. = FALSE)
  }
  provenance_columns <- c(
    "dataset", "key", "field", "source_id", "method", "quality", "note"
  )
  if (!is.data.frame(bundle$provenance) ||
      !all(provenance_columns %in% names(bundle$provenance))) {
    stop("Invalid data bundle: malformed provenance table.", call. = FALSE)
  }
  quality_columns <- c("dataset", "key", "field", "status", "reason")
  if (!is.data.frame(bundle$quality) ||
      !all(quality_columns %in% names(bundle$quality))) {
    stop("Invalid data bundle: malformed quality table.", call. = FALSE)
  }
  class(bundle) <- unique(c("zipcodeR_data_bundle", class(bundle)))
  bundle
}

#' @noRd
legacy_zip_code_db_columns <- function() {
  c(
    "zipcode", "zipcode_type", "major_city", "post_office_city",
    "common_city_list", "county", "state", "lat", "lng", "timezone",
    "radius_in_miles", "area_code_list", "population", "population_density",
    "land_area_in_sqmi", "water_area_in_sqmi", "housing_units",
    "occupied_housing_units", "median_home_value", "median_household_income",
    "bounds_west", "bounds_east", "bounds_north", "bounds_south"
  )
}

#' @noRd
zipcodeR_user_data_dir <- function(r_version = getRversion()) {
  if (r_version >= "4.0.0") {
    # Resolve dynamically so the package remains checkable on R 3.5, where
    # this version-gated R >= 4.0 API is not yet exported by tools.
    r_user_dir <- get(
      "R_user_dir",
      envir = asNamespace("tools"),
      inherits = FALSE
    )
    return(r_user_dir("zipcodeR", "data"))
  }
  file.path(tempdir(), "zipcodeR-data")
}

# Base R 3.5 does not provide the null-coalescing helper used internally.
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
