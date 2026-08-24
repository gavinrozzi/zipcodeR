# Step 1: acquire all pipeline sources into data-raw/cache/, verifying
# checksums for every static file. Idempotent: verified files are not
# re-downloaded.

source(file.path("data-raw", "sources.R"))

cache_dir <- file.path("data-raw", "cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

sha256_file <- function(path) {
  # tools::sha256sum requires R >= 4.5; use openssl-free fallback via system
  out <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE)
  strsplit(out, " ")[[1]][1]
}

acquire <- function(src) {
  dest <- file.path(cache_dir, basename(src$url))
  floating <- isTRUE(src$floating)
  if (file.exists(dest) && (floating || identical(sha256_file(dest), src$sha256))) {
    message("cached", if (!floating) " & verified", ": ", basename(dest))
    return(dest)
  }
  message("downloading: ", src$url)
  utils::download.file(src$url, dest, mode = "wb", quiet = TRUE)
  got <- sha256_file(dest)
  if (floating) {
    # Publisher regenerates this file in place; record the hash for
    # provenance instead of enforcing it
    message(
      "floating source ", basename(dest), ": sha256 ", got,
      if (!identical(got, src$sha256)) " (differs from the pinned build hash in sources.R)"
    )
  } else if (!identical(got, src$sha256)) {
    stop(
      "Checksum mismatch for ", basename(dest), "\n  expected: ", src$sha256,
      "\n  got:      ", got,
      "\nThe publisher may have updated the file in place. Inspect the new ",
      "file, then update sources.R and the data release notes."
    )
  }
  dest
}

paths <- lapply(PIPELINE_SOURCES, acquire)

# Unpack archives
utils::unzip(paths$gazetteer_zcta, exdir = cache_dir, overwrite = TRUE)
utils::unzip(paths$geonames_us, exdir = cache_dir, overwrite = TRUE)

# ACS pull (API source; requires CENSUS_API_KEY)
acs_cache <- file.path(cache_dir, sprintf("acs5_%d_zcta.csv", ACS_VINTAGE))
if (!file.exists(acs_cache)) {
  key <- Sys.getenv("CENSUS_API_KEY")
  if (!nzchar(key)) {
    stop(
      "CENSUS_API_KEY is not set. Register a free key at ",
      "https://api.census.gov/data/key_signup.html and set it in ~/.Renviron ",
      "or as a repository secret for the refresh workflow."
    )
  }
  message("downloading: ACS ", ACS_VINTAGE, " 5-year estimates for all ZCTAs")
  url <- paste0(
    ACS_ENDPOINT, "?get=", paste(ACS_VARIABLES, collapse = ","),
    "&for=zip%20code%20tabulation%20area:*&key=", key
  )
  tf <- tempfile(fileext = ".json")
  utils::download.file(url, tf, quiet = TRUE)
  j <- jsonlite::fromJSON(tf)
  acs <- as.data.frame(j[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(acs) <- c(names(ACS_VARIABLES), "zcta")
  for (v in names(ACS_VARIABLES)) {
    x <- suppressWarnings(as.numeric(acs[[v]]))
    x[!is.na(x) & x < 0] <- NA # ACS sentinel values (-666666666 etc.)
    acs[[v]] <- x
  }
  utils::write.csv(acs, acs_cache, row.names = FALSE)
}

message("acquire: done (", length(paths), " static sources + ACS)")
