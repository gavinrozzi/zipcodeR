#' Report the version of the bundled ZIP code data
#'
#' zipcodeR versions its data releases separately from its code releases.
#' This accessor reports exactly which data build is loaded, so users can
#' cite it and bug reports can pin the vintage.
#'
#' @return A named list with the data release version, build date, row count
#'   of \code{zip_code_db}, and the primary sources (with vintages) that
#'   produced each dataset.
#' @examples
#' zip_data_version()
#' @export
zip_data_version <- function() {
  zip_data_meta
}

#' Download the comprehensive ZIP code database
#'
#' The bundled \code{zip_code_db} is the lightweight ("simple") dataset. A
#' much larger companion database with detailed ACS demographic profiles per
#' ZIP code (the "comprehensive" database, ~450 MB SQLite) is published as an
#' asset of the zipcodeR data releases on GitHub rather than shipped in the
#' package.
#'
#' This function downloads that database once, verifies its SHA256 checksum,
#' and caches it under \code{tools::R_user_dir("zipcodeR", "data")}; later
#' calls return the cached path immediately. It never downloads without being
#' called explicitly. For offline use, copy the file to that directory
#' yourself (the expected file name is the asset name from the data release).
#'
#' @param force If TRUE, re-download even if a verified copy is cached.
#' @return Invisibly, the path to the downloaded SQLite database. Query it
#'   with DBI/RSQLite, e.g.
#'   \code{DBI::dbConnect(RSQLite::SQLite(), download_comprehensive_data())}.
#' @examples
#' \dontrun{
#' path <- download_comprehensive_data()
#' }
#' @export
download_comprehensive_data <- function(force = FALSE) {
  rlang::check_installed(
    c("curl", "utils"),
    reason = "to download the comprehensive ZIP code database"
  )
  meta <- zip_data_meta$comprehensive
  cache_dir <- tools::R_user_dir("zipcodeR", "data")
  dest <- file.path(cache_dir, meta$asset)

  if (file.exists(dest) && !force) {
    if (identical(file_sha256(dest), meta$sha256)) {
      message("zipcodeR: using cached comprehensive database at ", dest)
      return(invisible(dest))
    }
    message("zipcodeR: cached file failed checksum verification; re-downloading")
  }

  if (!curl::has_internet()) {
    stop("No internet connection. Please connect to the internet and try again.")
  }

  url <- sprintf(
    "https://github.com/gavinrozzi/zipcodeR/releases/download/%s/%s",
    meta$release_tag, meta$asset
  )
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  message(
    "zipcodeR: downloading the comprehensive database (~450 MB) from the ",
    meta$release_tag, " data release.\nThis is a one-time download cached in ",
    cache_dir
  )
  tmp <- paste0(dest, ".download")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb")

  got <- file_sha256(tmp)
  if (!identical(got, meta$sha256)) {
    stop(
      "Checksum verification failed for the downloaded database.\n  expected: ",
      meta$sha256, "\n  got:      ", got,
      "\nThe download may be corrupted or tampered with; not keeping it."
    )
  }
  # file.rename() cannot overwrite an existing file on Windows; clear the
  # destination first and verify the move actually happened
  if (file.exists(dest)) unlink(dest)
  moved <- file.rename(tmp, dest) ||
    (file.copy(tmp, dest, overwrite = TRUE) && file.remove(tmp))
  if (!moved || !file.exists(dest)) {
    stop("Failed to move the verified download into place at ", dest)
  }
  message("zipcodeR: download complete and verified: ", dest)
  invisible(dest)
}

# SHA256 of a file without adding a package dependency: prefer
# tools::sha256sum (R >= 4.5), fall back to the openssl package if installed,
# then to the system shasum/sha256sum binaries.
#' @noRd
file_sha256 <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    return(as.character(openssl::sha256(con)))
  }
  bin <- Sys.which(c("shasum", "sha256sum"))
  bin <- bin[nzchar(bin)][1]
  if (is.na(bin)) {
    stop("No SHA256 tool available: need R >= 4.5, the openssl package, or a system shasum/sha256sum binary.")
  }
  # shasum (incl. shasum.exe / shasum.bat on Windows) defaults to SHA-1 and
  # needs the algorithm flag; sha256sum does not
  is_shasum <- grepl("^shasum", basename(bin), ignore.case = TRUE)
  args <- if (is_shasum) c("-a", "256", shQuote(path)) else shQuote(path)
  out <- strsplit(system2(bin, args, stdout = TRUE), " ")[[1]][1]
  if (!grepl("^[0-9a-f]{64}$", out)) {
    stop("Unexpected output from ", bin, " while computing SHA256: ", out)
  }
  out
}
