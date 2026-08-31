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
#' @param lonlat lonlat argument to pass to raster::pointDistance() to select method of distance calculation. Default is TRUE to calculate distance over a spherical projection. FALSE will calculate the distance in Euclidean (planar) space.
#' @param units Specify which units to return distance calculations in. Choices include meters or miles.
#' @return a data.frame containing a column for each ZIP code and a new column containing the distance between the two columns of ZIP code
#'
#' @examples
#' zip_distance("08731", "08901")
#'
#' @importFrom raster pointDistance
#' @export
zip_distance <- function(zipcode_a, zipcode_b, lonlat = TRUE, units = "miles") {
  zipcode_a <- as.character(zipcode_a)
  zipcode_b <- as.character(zipcode_b)

  # assemble zipcodes in dataframe
  zip_data <- data.frame(zipcode_a, zipcode_b)

  # create subset of zip_code_db with only zipcode, lat, and lng
  zip_db_small <- zip_code_db %>%
    dplyr::select(.data$zipcode, .data$lat, .data$lng) %>%
    dplyr::filter(.data$lat != "NA" & .data$lng != "NA")

  # join input data with zip_code_db
  zip_data <- zip_data %>%
    dplyr::left_join(zip_db_small, by = c('zipcode_a' = 'zipcode')) %>%
    dplyr::left_join(zip_db_small, by = c('zipcode_b' = 'zipcode'), suffix = c('.a', '.b'))

  # assemble matrices for distance calculation
  points_a <- cbind(cbind(zip_data$lng.a, zip_data$lat.a))
  points_b <- cbind(cbind(zip_data$lng.b, zip_data$lat.b))

  # Calculate the distance matrix between both sets of points
  distance <- raster::pointDistance(points_a, points_b, lonlat = lonlat)

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
