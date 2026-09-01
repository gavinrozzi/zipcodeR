# Inspect upstream bytes for a proposed future data version. This mode never
# builds datasets, mutates source pins, or reuses an existing release identity.
# A maintainer reviews proposed-sources.json, updates sources.R deliberately,
# and only then runs the deterministic rebuild pipeline.

if (!identical(Sys.getenv("PIPELINE_MODE"), "refresh")) {
  stop("Set PIPELINE_MODE=refresh to inspect upstream source bytes.")
}
proposed_version <- Sys.getenv("PIPELINE_PROPOSED_VERSION")
if (!nzchar(proposed_version) || proposed_version %in% c("latest", "current", "stable")) {
  stop("PIPELINE_PROPOSED_VERSION must be a new explicit immutable version.")
}
if (!identical(Sys.getenv("PIPELINE_DATA_VERSION"), proposed_version)) {
  stop("PIPELINE_DATA_VERSION must equal PIPELINE_PROPOSED_VERSION in refresh mode.")
}

source(file.path("data-raw", "sources.R"))
if (proposed_version %in% PUBLISHED_DATA_VERSIONS) {
  stop(
    "PIPELINE_PROPOSED_VERSION has already been published and cannot be reused: ",
    proposed_version
  )
}
build_timestamp <- Sys.getenv("PIPELINE_BUILD_TIMESTAMP")
archive_time <- as.POSIXct(
  build_timestamp, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
)
if (!nzchar(build_timestamp) || is.na(archive_time)) {
  stop("PIPELINE_BUILD_TIMESTAMP must be an explicit ISO-8601 UTC timestamp.")
}
out_dir <- file.path("data-raw", "refresh-candidate", proposed_version)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)))
  }
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  unclass(as.character(openssl::sha256(con)))
}

download_candidate <- function(id, source) {
  destination <- file.path(out_dir, basename(source$url))
  utils::download.file(source$url, destination, mode = "wb", quiet = TRUE)
  list(
    id = id,
    file = basename(destination),
    url = source$url,
    configured_sha256 = source$sha256,
    proposed_sha256 = sha256_file(destination),
    changed = !identical(sha256_file(destination), source$sha256),
    license = source$license
  )
}

proposal <- Map(download_candidate, names(PIPELINE_SOURCES), PIPELINE_SOURCES)

key <- Sys.getenv("CENSUS_API_KEY")
acs_url <- paste0(
  ACS_ENDPOINT, "?get=", paste(ACS_VARIABLES, collapse = ","),
  "&for=zip%20code%20tabulation%20area:*",
  if (nzchar(key)) paste0("&key=", utils::URLencode(key, reserved = TRUE)) else ""
)
acs_path <- file.path(out_dir, sprintf("acs5_%d_zcta.json", ACS_VINTAGE))
tryCatch(
  utils::download.file(acs_url, acs_path, mode = "wb", quiet = TRUE),
  error = function(e) {
    message_text <- conditionMessage(e)
    if (nzchar(key)) {
      message_text <- gsub(key, "<CENSUS_API_KEY>", message_text, fixed = TRUE)
    }
    stop("ACS refresh download failed: ", message_text, call. = FALSE)
  }
)
proposal[[length(proposal) + 1L]] <- list(
  id = "acs_response",
  file = basename(acs_path),
  url = ACS_ENDPOINT,
  configured_sha256 = ACS_RESPONSE_SHA256,
  proposed_sha256 = sha256_file(acs_path),
  changed = !identical(sha256_file(acs_path), ACS_RESPONSE_SHA256),
  license = "U.S. public domain (U.S. Census Bureau)",
  vintage = ACS_VINTAGE
)

jsonlite::write_json(
  list(
    format = 1,
    proposed_data_version = proposed_version,
    created_at = build_timestamp,
    sources = proposal
  ),
  proposal_path <- file.path(out_dir, "proposed-sources.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Package the exact candidate bytes for human review and a later offline
# rebuild. The archive is deterministic for a fixed timestamp and contains no
# executable pipeline code.
stage <- tempfile("zipcodeR-source-candidate-")
dir.create(stage)
on.exit(unlink(stage, recursive = TRUE), add = TRUE)
cache_stage <- file.path(stage, "data-raw", "cache")
data_stage <- file.path(stage, "data")
dir.create(cache_stage, recursive = TRUE)
dir.create(data_stage, recursive = TRUE)

candidate_files <- c(
  vapply(PIPELINE_SOURCES, function(x) basename(x$url), character(1)),
  basename(acs_path)
)
for (name in candidate_files) {
  source_path <- file.path(out_dir, name)
  if (!file.copy(source_path, file.path(cache_stage, name), overwrite = TRUE)) {
    stop("Failed to stage refreshed source: ", name)
  }
}
for (name in names(LEGACY_BASELINE_FILES)) {
  source_path <- file.path("data", name)
  if (!file.copy(source_path, file.path(data_stage, name), overwrite = TRUE)) {
    stop("Failed to stage immutable legacy baseline: ", name)
  }
}
manifest_stage <- file.path(stage, "data-raw", basename(proposal_path))
if (!file.copy(proposal_path, manifest_stage, overwrite = TRUE)) {
  stop("Failed to stage the proposed source manifest.")
}

members <- c(
  file.path("data-raw", "cache", candidate_files),
  file.path("data", names(LEGACY_BASELINE_FILES)),
  file.path("data-raw", basename(proposal_path))
)
staged_paths <- file.path(stage, members)
time_results <- vapply(
  staged_paths,
  Sys.setFileTime,
  logical(1),
  time = archive_time
)
staged_times <- file.info(staged_paths)$mtime
if (!all(time_results) || anyNA(staged_times) ||
    any(abs(as.numeric(staged_times) - as.numeric(archive_time)) > 1)) {
  stop(
    "PIPELINE_BUILD_TIMESTAMP cannot be represented consistently on this ",
    "filesystem; refusing to create a malformed source archive."
  )
}
invisible(lapply(staged_paths, Sys.chmod, mode = "0644"))
archive_path <- file.path(
  normalizePath(out_dir),
  sprintf("zipcodeR-sources-%s.tar.gz", proposed_version)
)
write_source_archive <- function() {
  old_working_directory <- setwd(stage)
  on.exit(setwd(old_working_directory), add = TRUE)
  utils::tar(
    archive_path,
    files = members,
    compression = "gzip",
    tar = "internal"
  )
}
write_source_archive()

# Refuse an archive that is repeatable but unusable. Exercise the same default
# extractor used by restore_rebuild_inputs.R, then compare every extracted
# member with the staged byte stream before reporting a candidate checksum.
archive_members <- utils::untar(archive_path, list = TRUE)
if (length(archive_members) != length(members) ||
    !setequal(archive_members, members)) {
  stop("Source-refresh archive member verification failed.")
}
verify_stage <- tempfile("zipcodeR-source-verify-")
dir.create(verify_stage)
on.exit(unlink(verify_stage, recursive = TRUE), add = TRUE)
utils::untar(archive_path, exdir = verify_stage)
for (member in members) {
  original_sha <- sha256_file(file.path(stage, member))
  extracted_sha <- sha256_file(file.path(verify_stage, member))
  if (!identical(original_sha, extracted_sha)) {
    stop("Source-refresh archive content verification failed for: ", member)
  }
}
archive_sha <- sha256_file(archive_path)
writeLines(
  paste(archive_sha, basename(archive_path)),
  file.path(out_dir, sprintf("zipcodeR-sources-%s.sha256", proposed_version))
)
message(
  "source-refresh proposal and deterministic source archive written to ",
  out_dir, " (sha256 ", archive_sha, ")"
)
