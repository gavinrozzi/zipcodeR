#' Download the comprehensive ZIP code database
#'
#' The bundled \code{zip_code_db} is the lightweight ("simple") dataset. A
#' much larger companion database with detailed ACS demographic profiles per
#' ZIP code (the "comprehensive" database, ~450 MB SQLite) is published as a
#' checksum-pinned asset of a zipcodeR data release rather than shipped in the
#' package. Its public URL, checksum, and SQLite integrity have passed a
#' clean-machine smoke test.
#'
#' This function downloads that database, verifies its SHA256 checksum,
#' and, on R 4.0 or newer, caches it under
#' \code{tools::R_user_dir("zipcodeR", "data")}; later calls return the cached
#' path immediately. On older supported R versions the verified file is kept
#' only in the session temporary directory. It never downloads without being
#' called explicitly. For offline use on R 4.0 or newer, copy the file to that
#' user data directory yourself (the expected file name is the asset name from
#' the data release).
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
  meta <- comprehensive_data_registry()
  if (!isTRUE(meta$published)) {
    stop(
      "The comprehensive data asset is not registered for public download. ",
      "Use only a release whose URL and checksum have been verified.",
      call. = FALSE
    )
  }
  # Verify SHA256 capability BEFORE any download: discovering its absence
  # after a ~450 MB transfer would discard the download on every attempt
  ensure_sha256_available()
  cache_dir <- zipcodeR_user_data_dir()
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
  tmp <- tempfile(paste0(meta$asset, "-"), tmpdir = cache_dir)
  on.exit(unlink(tmp), add = TRUE)
  # R's default download timeout (60s) is far too short for ~450 MB;
  # raise it for this call only
  old_timeout <- options(timeout = max(3600, getOption("timeout")))
  on.exit(options(old_timeout), add = TRUE)
  tryCatch(
    utils::download.file(url, tmp, mode = "wb"),
    error = function(e) {
      stop(
        "Download failed: ", conditionMessage(e),
        "\nIf this is a 404, the '", meta$release_tag, "' data release may ",
        "not have been published on GitHub yet - see ",
        "https://github.com/gavinrozzi/zipcodeR/releases",
        call. = FALSE
      )
    }
  )

  got <- file_sha256(tmp)
  if (!identical(got, meta$sha256)) {
    stop(
      "Checksum verification failed for the downloaded database.\n  expected: ",
      meta$sha256, "\n  got:      ", got,
      "\nThe download may be corrupted or tampered with; not keeping it."
    )
  }
  # Prefer an atomic rename; it cannot overwrite an existing file on
  # Windows, so fall back to an overwriting copy. The old cache is only
  # replaced, never deleted ahead of a successful move, and leftover tmp
  # cleanup is handled by on.exit (a failed cleanup is not a failure).
  if (!file.rename(tmp, dest)) {
    if (!file.copy(tmp, dest, overwrite = TRUE)) {
      stop("Failed to move the verified download into place at ", dest)
    }
  }
  message("zipcodeR: download complete and verified: ", dest)
  invisible(dest)
}

# Updated only after a public-release smoke test succeeds.
#' @noRd
comprehensive_data_registry <- function() {
  list(
    published = TRUE,
    release_tag = "data-2026.08",
    asset = "comprehensive_db.sqlite",
    sha256 = "d85ed4e25884bc27bdd339d57dd9e2d1763531d4c050acb7a05a3d5aca90668d"
  )
}

# Stop with an informative error when no SHA256 mechanism exists, so the
# capability is established before any large download
#' @noRd
ensure_sha256_available <- function() {
  ok <- exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE) ||
    requireNamespace("openssl", quietly = TRUE) ||
    length(sha256_system_binary()) == 1L
  if (!ok) {
    stop(
      "No SHA256 tool available to verify the download. Install the ",
      "'openssl' package (install.packages(\"openssl\")), upgrade to ",
      "R >= 4.5, or ensure a shasum/sha256sum binary is on the PATH."
    )
  }
  invisible(TRUE)
}

# SHA256 of a file without adding a package dependency: prefer
# tools::sha256sum (R >= 4.5), fall back to the openssl package if installed,
# then to the system shasum/sha256sum binaries. Every backend must return a
# PLAIN character string: the results are compared with identical(), which is
# FALSE for an equal-looking string carrying attributes.
#' @noRd
file_sha256 <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    # Resolve dynamically so R 3.5's static checker does not treat this
    # version-gated R >= 4.5 API as an unexported object.
    sha256sum <- get(
      "sha256sum",
      envir = asNamespace("tools"),
      inherits = FALSE
    )
    return(unname(sha256sum(path)))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    return(sha256_openssl(path))
  }
  sha256_system(path)
}

#' @noRd
sha256_openssl <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  # as.character() on an openssl hash keeps its c("hash", "sha256") class.
  # Without unclass() the result is never identical() to the expected plain
  # string, so on R < 4.5 with openssl installed every checksum comparison
  # would fail - rejecting a correct download as corrupted.
  unclass(as.character(openssl::sha256(con)))
}

#' @noRd
sha256_system <- function(path) {
  bin <- sha256_system_binary()
  if (!length(bin)) {
    stop("No SHA256 tool available: need R >= 4.5, the openssl package, or a system shasum/sha256sum binary.")
  }
  # shasum (incl. shasum.exe / shasum.bat on Windows) defaults to SHA-1 and
  # needs the algorithm flag; sha256sum does not
  is_shasum <- grepl("^shasum", basename(bin), ignore.case = TRUE)
  native_path <- normalizePath(
    path,
    winslash = if (.Platform$OS.type == "windows") "\\" else "/",
    mustWork = TRUE
  )
  args <- if (is_shasum) c("-a", "256", shQuote(native_path)) else shQuote(native_path)
  out <- suppressWarnings(system2(bin, args, stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop(
      "SHA256 command failed with status ", status, ": ",
      paste(out, collapse = "\n"),
      call. = FALSE
    )
  }
  if (!length(out)) {
    stop("SHA256 command produced no output: ", bin, call. = FALSE)
  }
  out <- strsplit(out[[1]], "[[:space:]]+")[[1]][1]
  if (!grepl("^[0-9a-f]{64}$", out)) {
    stop("Unexpected output from ", bin, " while computing SHA256: ", out)
  }
  out
}

# Strawberry Perl exposes shasum.bat on Windows, but invoking that wrapper via
# system2() is not portable and caused the package's Windows check failure.
# R >= 4.5 and openssl remain cross-platform; system fallback on Windows is
# used only for a real sha256sum executable.
#' @noRd
sha256_system_binary <- function(os_type = .Platform$OS.type,
                                 bins = Sys.which(c("sha256sum", "shasum"))) {
  bins <- unname(bins[nzchar(bins)])
  if (identical(os_type, "windows")) {
    bins <- bins[!grepl("\\.(bat|cmd)$", bins, ignore.case = TRUE)]
  }
  if (!length(bins)) character(0) else bins[[1]]
}
