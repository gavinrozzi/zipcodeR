#' zipcodeR: reproducible U.S. ZIP-code analysis
#'
#' zipcodeR provides two deliberately separate interfaces.
#'
#' @section Recommended interface for new analyses:
#' Use functions ending in `_ng` with an explicitly selected data bundle. Start
#' with [download_zip_data_bundle()] for a registered immutable version or
#' [read_zip_data_bundle()] for a local checksum-pinned file. Passing the bundle
#' as the first argument makes the chosen data vintage visible in every call.
#' `_ng` never resolves an implicit `latest` version or downloads during a
#' lookup.
#'
#' @section Historical compatibility interface:
#' Unsuffixed functions and the datasets in `data/` retain the exact zipcodeR
#' 0.3.5 contract for existing scripts and research reproduction. This includes
#' historical data, scientific algorithms, conditions, ordering, and known edge
#' cases. Use [zip_data_version()] to record which contract an analysis used.
#'
#' @docType package
#' @name zipcodeR-package
#' @aliases zipcodeR
#' @keywords internal
"_PACKAGE"
