#' Download updated data files needed for library functionality to the package's data directory (deprecated)
#'
#' @description
#' **Deprecated.** This function attempts to
#' write refreshed data into the installed package directory, which violates
#' CRAN policy, fails on read-only libraries, and — because the package uses
#' lazy data — never actually changes the data the package loads. It is
#' retained for backward compatibility only and will be removed in a future
#' release.
#'
#' Bundled data is now refreshed through the reproducible pipeline in the
#' package repository (`data-raw/`, shipped with each release; see
#' `zip_data_version()`), and the large companion database is available via
#' [download_comprehensive_data()].
#'
#' @param force Ignored (retained for backward compatibility).
#' @return Invisibly returns NULL; the function performs no action beyond the deprecation warning.
#' @examples
#' \dontrun{
#' download_zip_data()
#' }
#' @export
download_zip_data <- function(force = FALSE) {
  .Deprecated(
    msg = paste(
      "download_zip_data() is deprecated and no longer downloads anything:",
      "it could never refresh the data of an installed package (lazy data is",
      "baked in at install time), and running it from a source checkout",
      "overwrote pipeline-built data files. Bundled data is refreshed with",
      "package releases (see zip_data_version()); for the large companion",
      "database use download_comprehensive_data()."
    )
  )
  invisible(NULL)
}
