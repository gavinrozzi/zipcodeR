#' Normalize ZIP codes
#'
#'
#' @param zipcode messy ZIP code to be normalized
#' @return Normalized zipcode
#' @examples
#' normalize_zip(0008731)
#' @importFrom tidyr extract
#' @importFrom dplyr pull
#' @importFrom dplyr tibble
#' @export
normalize_zip <- function(zipcode) {
  capture_group <- function(data, regex) {
    tibble(data) %>%
      extract(col = data, into = "captured", regex = regex) %>%
      pull(.data$captured)
  }

  # input can be numeric or character
  # we need to treat these differently
  if (is.character(zipcode)) {
    zipcode <- ifelse( # remove parts after - if there is one
      grepl("^\\s*(\\d+)-.*", zipcode),
      capture_group(zipcode, "^\\s*(\\d+)-.*"),
      zipcode
    )

    nas <- is.na(zipcode)
    # remove trailing four digits if too long
    zipcode <- ifelse(
      nchar(zipcode) > 5,
      capture_group(zipcode, "(.*)\\d\\d\\d\\d"),
      zipcode
    )
    # pad with zeros if too short
    zipcode <- ifelse(
      nchar(zipcode) < 5,
      sprintf("%05i", as.numeric(zipcode)),
      zipcode
    )
    # restor NA values
    zipcode[nas] <- NA_character_
    return(zipcode)
  }

  if (!isTRUE(is.numeric(zipcode))) {
    stop("input must be character or numeric")
  }

  zipcode <- ifelse(
    zipcode > 100000,
    floor(zipcode/10000),
    zipcode
  )
  # keep position of NAs to recover later
  nas <- is.na(zipcode)

  # pad with zeros where needed
  zipcode <- sprintf("%05i", as.numeric(zipcode))
  zipcode[nas] <- NA_character_

  zipcode
}
