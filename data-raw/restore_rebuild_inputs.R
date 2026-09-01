# Restore exact raw inputs for a deterministic, network-free rebuild.
#
# Set PIPELINE_SOURCE_ARCHIVE to a local path or HTTPS URL and
# PIPELINE_SOURCE_ARCHIVE_SHA256 to its independently recorded checksum.
# Only allowlisted source files are copied from the archive; pipeline code in
# the archive can never overwrite the checked-out implementation.

source(file.path("data-raw", "sources.R"))

archive_source <- Sys.getenv("PIPELINE_SOURCE_ARCHIVE")
archive_expected <- tolower(Sys.getenv("PIPELINE_SOURCE_ARCHIVE_SHA256"))
if (!nzchar(archive_source)) {
  stop("PIPELINE_SOURCE_ARCHIVE must name a local file or HTTPS URL.")
}
if (!grepl("^[0-9a-f]{64}$", archive_expected)) {
  stop("PIPELINE_SOURCE_ARCHIVE_SHA256 must be a 64-character SHA256 value.")
}

sha256_file <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    return(unclass(as.character(openssl::sha256(con))))
  }
  bin <- Sys.which(c("sha256sum", "shasum"))
  bin <- bin[nzchar(bin)][1]
  if (is.na(bin)) stop("No SHA256 implementation is available.")
  args <- if (grepl("^shasum", basename(bin), ignore.case = TRUE)) {
    c("-a", "256", shQuote(path))
  } else {
    shQuote(path)
  }
  strsplit(system2(bin, args, stdout = TRUE), " ")[[1]][1]
}

archive_path <- archive_source
downloaded <- FALSE
if (grepl("^https://", archive_source)) {
  archive_path <- tempfile(fileext = ".tar.gz")
  downloaded <- TRUE
  old_timeout <- options(timeout = max(600, getOption("timeout")))
  on.exit(options(old_timeout), add = TRUE)
  utils::download.file(archive_source, archive_path, mode = "wb", quiet = TRUE)
} else if (grepl("^[a-zA-Z]+://", archive_source)) {
  stop("Only HTTPS URLs or local paths are accepted for source archives.")
}
if (downloaded) on.exit(unlink(archive_path), add = TRUE)
if (!file.exists(archive_path)) stop("Source archive does not exist: ", archive_path)

archive_got <- sha256_file(archive_path)
if (!identical(archive_got, archive_expected)) {
  stop(
    "Source archive checksum verification failed.\n  expected: ",
    archive_expected, "\n  got:      ", archive_got
  )
}

members <- utils::untar(archive_path, list = TRUE)
unsafe <- startsWith(members, "/") |
  grepl("(^|/)\\.\\.(/|$)", members) |
  grepl("^[A-Za-z]:", members)
if (any(unsafe)) stop("Source archive contains an unsafe path.")

static_names <- vapply(PIPELINE_SOURCES, function(x) basename(x$url), character(1))
acs_raw_name <- sprintf("acs5_%d_zcta.json", ACS_VINTAGE)
acs_derived_name <- sprintf("acs5_%d_zcta.csv", ACS_VINTAGE)
cache_names <- c(static_names, acs_raw_name)
expected_members <- file.path("data-raw", "cache", cache_names)
if (!all(expected_members %in% members)) {
  stop(
    "Source archive is incomplete; missing: ",
    paste(setdiff(expected_members, members), collapse = ", ")
  )
}

stage <- tempfile("zipcodeR-source-restore-")
dir.create(stage)
on.exit(unlink(stage, recursive = TRUE), add = TRUE)
utils::untar(archive_path, files = expected_members, exdir = stage)

expected_hashes <- c(
  vapply(PIPELINE_SOURCES, function(x) x$sha256, character(1)),
  ACS_RESPONSE_SHA256
)
names(expected_hashes) <- cache_names
for (name in cache_names) {
  source_path <- file.path(stage, "data-raw", "cache", name)
  got <- sha256_file(source_path)
  if (!identical(got, expected_hashes[[name]])) {
    stop(
      "Archived rebuild input failed checksum verification: ", name,
      "\n  expected: ", expected_hashes[[name]], "\n  got:      ", got
    )
  }
}

# A final reproducibility archive contains the derived ACS CSV as an
# additional cross-environment check. A source-refresh archive intentionally
# contains only the raw API response; 01_acquire.R derives the CSV itself.
derived_member <- file.path("data-raw", "cache", acs_derived_name)
if (derived_member %in% members) {
  utils::untar(archive_path, files = derived_member, exdir = stage)
  derived_got <- sha256_file(file.path(stage, derived_member))
  if (!identical(derived_got, ACS_DERIVED_SHA256)) {
    stop(
      "Archived derived ACS input failed checksum verification: ",
      acs_derived_name, "\n  expected: ", ACS_DERIVED_SHA256,
      "\n  got:      ", derived_got
    )
  }
  cache_names <- c(cache_names, acs_derived_name)
}

cache_dir <- file.path("data-raw", "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
for (name in cache_names) {
  if (!file.copy(
    file.path(stage, "data-raw", "cache", name),
    file.path(cache_dir, name), overwrite = TRUE
  )) {
    stop("Failed to restore rebuild input: ", name)
  }
}
message(
  "restored and verified ", length(cache_names),
  " rebuild inputs from archive sha256 ", archive_got
)
