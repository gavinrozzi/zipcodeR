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
#' @importFrom dplyr left_join
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
    floor(zipcode / 10000),
    zipcode
  )
  # keep position of NAs to recover later
  nas <- is.na(zipcode)

  # pad with zeros where needed
  zipcode <- sprintf("%05i", as.numeric(zipcode))
  zipcode[nas] <- NA_character_

  zipcode
}

#' Calculate the distance between two ZIP codes in miles
#'
#'
#' @param zipcode_a First vector of ZIP codes
#' @param zipcode_b Second vector of ZIP codes
#' @param lonlat If TRUE (the default), calculate the great-circle distance
#'   between the ZIP code centroids using the haversine formula. FALSE computes
#'   the Euclidean distance between the raw coordinate pairs in degree units
#'   and is retained only for backward compatibility.
#' @param units Specify which units to return distance calculations in. Choices include meters or miles.
#' @return a data.frame containing a column for each ZIP code and a new column containing the distance between the two columns of ZIP code
#'
#' @examples
#' zip_distance("08731", "08901")
#'
#' @export
zip_distance <- function(zipcode_a, zipcode_b, lonlat = TRUE, units = "miles") {
  zipcode_a <- as.character(zipcode_a)
  zipcode_b <- as.character(zipcode_b)

  # Look up coordinates for both vectors, preserving input order and
  # duplicates (ZIP codes without coordinates yield NA distances)
  matched_a <- match(zipcode_a, zip_code_db$zipcode)
  matched_b <- match(zipcode_b, zip_code_db$zipcode)

  lat_a <- zip_code_db$lat[matched_a]
  lng_a <- zip_code_db$lng[matched_a]
  lat_b <- zip_code_db$lat[matched_b]
  lng_b <- zip_code_db$lng[matched_b]

  # Calculate the distance between both sets of points in meters
  if (lonlat) {
    distance <- haversine_distance(lat_a, lng_a, lat_b, lng_b)
  } else {
    distance <- sqrt((lng_b - lng_a)^2 + (lat_b - lat_a)^2)
  }

  # Convert the distance matrix from meters to miles
  if (units == "miles") {
    distance <- distance * 0.000621371
  }

  # Round to 2 decimal places to match search_radius()
  distance <- round(distance, digits = 2)

  # Put together the results in a data.frame
  result <- data.frame(zipcode_a, zipcode_b, distance)

  return(result)
}
