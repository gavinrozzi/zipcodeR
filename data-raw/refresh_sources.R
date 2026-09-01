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
if (!nzchar(key)) {
  stop("CENSUS_API_KEY is required to inspect a proposed ACS response.")
}
acs_url <- paste0(
  ACS_ENDPOINT, "?get=", paste(ACS_VARIABLES, collapse = ","),
  "&for=zip%20code%20tabulation%20area:*&key=",
  utils::URLencode(key, reserved = TRUE)
)
acs_path <- file.path(out_dir, sprintf("acs5_%d_zcta.json", ACS_VINTAGE))
tryCatch(
  utils::download.file(acs_url, acs_path, mode = "wb", quiet = TRUE),
  error = function(e) {
    message_text <- gsub(key, "<CENSUS_API_KEY>", conditionMessage(e), fixed = TRUE)
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
    created_at = Sys.getenv("PIPELINE_BUILD_TIMESTAMP"),
    sources = proposal
  ),
  file.path(out_dir, "proposed-sources.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)
message("source-refresh proposal written to ", out_dir)
