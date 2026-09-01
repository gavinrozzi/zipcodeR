# Step 1: verify all archived pipeline sources under data-raw/cache/.
# Deterministic rebuild mode is deliberately network-free. Populate this
# directory with restore_rebuild_inputs.R or extract a reproducibility archive;
# refresh_sources.R is the only pipeline entry point allowed to contact
# mutable upstream sources.

source(file.path("data-raw", "sources.R"))

cache_dir <- file.path("data-raw", "cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

# SHA256 without adding a package dependency, mirroring file_sha256() in
# R/data_version.R: tools::sha256sum (R >= 4.5), then the openssl package,
# then a system binary. Minimal Linux images (r-base, Debian/Alpine slim)
# ship sha256sum but not the shasum Perl script, so neither name can be
# hardcoded.
sha256_file <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    # unclass(): as.character() on an openssl hash keeps its c("hash",
    # "sha256") class, and a classed string is never identical() to the plain
    # pinned hash it is compared against
    return(unclass(as.character(openssl::sha256(con))))
  }
  bin <- Sys.which(c("shasum", "sha256sum"))
  bin <- bin[nzchar(bin)][1]
  if (is.na(bin)) {
    stop(
      "No SHA256 tool available to verify pipeline sources: need R >= 4.5, ",
      "the openssl package, or a shasum/sha256sum binary on the PATH."
    )
  }
  # shasum defaults to SHA-1 and needs the algorithm flag; sha256sum does not
  args <- if (grepl("^shasum", basename(bin), ignore.case = TRUE)) {
    c("-a", "256", shQuote(path))
  } else {
    shQuote(path)
  }
  out <- strsplit(system2(bin, args, stdout = TRUE), " ")[[1]][1]
  if (!grepl("^[0-9a-f]{64}$", out)) {
    stop("Unexpected output from ", bin, " while computing SHA256: ", out)
  }
  out
}

acquire <- function(src) {
  dest <- file.path(cache_dir, basename(src$url))
  if (file.exists(dest) && identical(sha256_file(dest), src$sha256)) {
    message("cached & verified: ", basename(dest))
    return(dest)
  }
  got <- if (file.exists(dest)) sha256_file(dest) else "<missing>"
  stop(
    "Pinned rebuild input is missing or corrupt: ", basename(dest),
    "\n  expected: ", src$sha256,
    "\n  got:      ", got,
    "\nRebuild mode never contacts mutable upstream URLs. Restore a ",
    "checksum-verified source or reproducibility archive first."
  )
}

paths <- lapply(PIPELINE_SOURCES, acquire)

# Unpack archives
utils::unzip(paths$gazetteer_zcta, exdir = cache_dir, overwrite = TRUE)
utils::unzip(paths$geonames_us, exdir = cache_dir, overwrite = TRUE)

# ACS response archive (API source; requires CENSUS_API_KEY only when the
# pinned raw response is not already present). The raw JSON is the source of
# record. The CSV consumed by later stages is deterministically derived from
# it and separately checksummed.
acs_raw <- file.path(cache_dir, sprintf("acs5_%d_zcta.json", ACS_VINTAGE))
acs_cache <- file.path(cache_dir, sprintf("acs5_%d_zcta.csv", ACS_VINTAGE))
if (!file.exists(acs_raw)) {
  stop(
    "Pinned raw ACS response is missing: ", acs_raw,
    "\nRebuild mode never calls the Census API. Restore the archived response ",
    "with data-raw/restore_rebuild_inputs.R first."
  )
}
acs_raw_hash <- sha256_file(acs_raw)
if (!identical(acs_raw_hash, ACS_RESPONSE_SHA256)) {
  stop(
    "Raw ACS response checksum mismatch. A source refresh must use a new ",
    "explicit data version and update ACS_RESPONSE_SHA256 after review.\n",
    "  expected: ", ACS_RESPONSE_SHA256, "\n  got:      ", acs_raw_hash
  )
}

j <- jsonlite::fromJSON(acs_raw)
acs <- as.data.frame(j[-1, , drop = FALSE], stringsAsFactors = FALSE)
names(acs) <- c(names(ACS_VARIABLES), "zcta")
for (v in names(ACS_VARIABLES)) {
  x <- suppressWarnings(as.numeric(acs[[v]]))
  x[!is.na(x) & x < 0] <- NA # ACS sentinel values (-666666666 etc.)
  acs[[v]] <- x
}
utils::write.csv(acs, acs_cache, row.names = FALSE)
acs_hash <- sha256_file(acs_cache)
if (!identical(acs_hash, ACS_DERIVED_SHA256)) {
  stop(
    "Derived ACS CSV checksum mismatch. The transformation or R serialization ",
    "environment changed.\n  expected: ", ACS_DERIVED_SHA256,
    "\n  got:      ", acs_hash
  )
}

message("acquire: done (", length(paths), " static sources + ACS)")
