#' Normalize ZIP codes
#'
#'
#' @param zipcode messy ZIP code to be normalized
#' @return Normalized zipcode
#' @examples
#' normalize_zip(0008731)
#' @export
normalize_zip <- function(zipcode) {
  capture_group <- function(data, regex) {
    matches <- regmatches(data, regexec(regex, data))
    vapply(
      matches,
      function(m) if (length(m) >= 2) m[[2]] else NA_character_,
      character(1)
    )
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
#'   between the ZIP code centroids using the haversine formula. FALSE
#'   (deprecated) computes a planar equirectangular approximation instead;
#'   note that before the deprecation this mode had a unit bug that made it
#'   return near-zero values, so no result from it should be relied on.
#' @param units Specify which units to return distance calculations in. Choices include meters or miles.
#' @return a data.frame containing a column for each ZIP code and a new column containing the distance between the two columns of ZIP code
#'
#' @examples
#' zip_distance("08731", "08901")
#'
#' @export
zip_distance <- function(zipcode_a, zipcode_b, lonlat = TRUE, units = "miles") {
  units <- match.arg(units, c("miles", "meters"))
  zipcode_a <- as.character(zipcode_a)
  zipcode_b <- as.character(zipcode_b)
  # Recycle the shorter vector when its length divides the longer one,
  # matching historical data.frame() recycling; anything else is an error
  if (length(zipcode_a) != length(zipcode_b)) {
    n <- max(length(zipcode_a), length(zipcode_b))
    m <- min(length(zipcode_a), length(zipcode_b))
    if (m == 0 || n %% m != 0) {
      stop(
        "`zipcode_a` and `zipcode_b` must have compatible lengths ",
        "(equal, or one a multiple of the other): got ",
        length(zipcode_a), " and ", length(zipcode_b)
      )
    }
    zipcode_a <- rep_len(zipcode_a, n)
    zipcode_b <- rep_len(zipcode_b, n)
  }

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
    warning(
      "zip_distance(lonlat = FALSE) is deprecated. Historical versions had ",
      "a unit bug that made this mode return near-zero values; it now ",
      "returns a planar equirectangular approximation in the requested ",
      "units, and will be removed in a future release."
    )
    # equirectangular: scale degree offsets to meters at the mean latitude
    meters_per_degree <- 6371008.8 * pi / 180
    dx <- (lng_b - lng_a) * cos((lat_a + lat_b) / 2 * pi / 180)
    dy <- lat_b - lat_a
    distance <- sqrt(dx^2 + dy^2) * meters_per_degree
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
