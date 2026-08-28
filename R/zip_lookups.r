#' Search for ZIP codes located within a given state
#'
#'
#' @param state_abb Two-digit code representing a U.S. state
#' @return tibble of all ZIP codes for each state code defined in state_abb
#' @examples
#' search_state("NJ")
#' search_state(c("NJ", "NY", "CT"))
#' @export
search_state <- function(state_abb) {
  # Ensure state abbreviation is capitalized for consistency
  state_abb <- toupper(state_abb)
  # Get matching ZIP codes for state
  state_zips <- zip_code_db %>%
    dplyr::filter(.data$state %in% state_abb)
  # Throw an error if nothing found
  if (nrow(state_zips) == 0) {
    stop(paste("No ZIP codes found for state:", state_abb))
  }
  return(dplyr::as_tibble(state_zips))
}
#' Search ZIP codes for a county
#'
#'
#' @param state_abb Two-digit code for a U.S. state
#' @param county_name Name of a county within a U.S. state
#' @param ... if the parameter similar = TRUE, then send the parameter max.distance to the base function agrep. Default is 0.1.
#' @return tibble of all ZIP codes for given county name
#'
#' @examples
#' middlesex <- search_county("Middlesex", "NJ")
#' alameda <- search_county("alameda", "CA")
#' search_county("ST BERNARD", "LA", similar = TRUE)$zipcode
#' @importFrom stringr str_detect
#' @importFrom rlang list2
#' @export
search_county <- function(county_name, state_abb, ...) {
  dots <- rlang::list2(...)

  if (stringr::str_detect(state_abb, "^[:upper:]+$") == FALSE) {
    state_abb <- toupper(state_abb)
  }

  if ("similar" %in% names(dots) && dots$similar == TRUE) {
    if ("max.distance" %in% names(dots)) {
      max.distance <- dots$max.distance
    } else {
      max.distance <- 0.1
    }
    state_counties <- zip_code_db %>% dplyr::filter(.data$state == state_abb)
    county_name_proper <- agrep(county_name, state_counties$county,
      ignore.case = TRUE, value = TRUE, max.distance = max.distance
    )

    county_zips <- zip_code_db %>% dplyr::filter(.data$state ==
      state_abb & .data$county %in% county_name_proper)
  } else {
    if (stringr::str_detect(county_name, "^[:upper:]") == FALSE) {
      first_char <- toupper(substring(county_name, 0, 1))
      remainder <- substring(county_name, 2, nchar(county_name))
      county_name <- paste0(first_char, remainder)
    }
    county_name_proper <- paste(county_name, "County")
    county_zips <- zip_code_db %>% dplyr::filter(.data$state ==
      state_abb & .data$county == county_name_proper)
  }

  if (nrow(county_zips) == 0) {
    stop(paste(
      "No ZIP codes found for county:", county_name,
      ",", state_abb
    ))
  }
  return(dplyr::as_tibble(county_zips))
}
#' Given a ZIP code, returns columns of metadata about that ZIP code
#'
#'
#' @param zip_code A 5-digit U.S. ZIP code or character vector with multiple ZIP codes
#' @return A tibble with one row per element of \code{zip_code}, in input order
#'   (duplicates preserved). ZIP codes with no match in \code{zip_code_db} return
#'   a row of NA values (with a warning), so the output is always the same length
#'   as the input and safe to use inside \code{dplyr::mutate()}.
#'
#' @examples
#' reverse_zipcode("90210")
#' reverse_zipcode("08731")
#' reverse_zipcode(c("08734", "08731"))
#' reverse_zipcode("07762")$county
#' reverse_zipcode("07762")$state
#' @export
reverse_zipcode <- function(zip_code) {
  # Sanity check: validate input for single ZIP before doing anything else
  # (NA input is not an error - it yields an NA row, as in the vector case)
  if (length(zip_code) == 1 && !is.na(zip_code)) {
    zip_char <- nchar(as.character(zip_code))
    if (zip_char != 5) {
      stop(paste("Invalid ZIP code detected, expected 5 digit ZIP code, got", zip_char))
    }
  }

  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)

  # Match each input against the database, preserving input order and
  # duplicates so the result always has one row per input element
  matched <- match(zip_code, zip_code_db$zipcode)

  for (missing_zip in unique(zip_code[is.na(matched)])) {
    warning(paste("No data found for ZIP code", missing_zip))
  }

  zip_code_data <- zip_code_db[matched, , drop = FALSE]
  # Unmatched inputs become NA rows; keep the queried ZIP in the zipcode column
  zip_code_data$zipcode <- zip_code

  return(dplyr::as_tibble(zip_code_data))
}
#' Search ZIP codes for a given city within a state
#'
#'
#' @param state_abb Two-digit code for a U.S. state
#' @param city_name Name of major city to search
#' @return tibble of all ZIP code data found for given city
#'
#' @examples
#' search_city("Spring Lake", "NJ")
#' search_city("Chappaqua", "NY")
#' @importFrom stringr str_detect
#' @export
search_city <- function(city_name, state_abb) {
  # Test if state name input is capitalized, capitalize if lowercase
  if (stringr::str_detect(state_abb, "^[:upper:]+$") == FALSE) {
    state_abb <- toupper(state_abb)
  }
  # Test if first letter of city name  input is capitalized, capitalize if input is lowercase
  if (stringr::str_detect(city_name, "^[:upper:]") == FALSE) {
    first_char <- toupper(substring(city_name, 0, 1))
    remainder <- substring(city_name, 2, nchar(city_name))
    city_name <- paste0(first_char, remainder)
  }
  # Get matching ZIP codes for city
  city_zips <- zip_code_db %>%
    dplyr::filter(.data$state == state_abb & .data$major_city == city_name)
  # Throw an error if nothing found
  if (nrow(city_zips) == 0) {
    stop(paste("No ZIP codes found for city:", city_name, ",", state_abb))
  }
  return(dplyr::as_tibble(city_zips))
}
#' Search all ZIP codes located within a given timezone
#'
#' @param tz Timezone
#' @return tibble of all ZIP codes found for given timezone
#'
#' @examples
#' eastern <- search_tz("Eastern")
#' pacific <- search_tz("Mountain")
#' @export
search_tz <- function(tz) {
  # Get matching ZIP codes for timezone
  tz_zips <- zip_code_db %>%
    dplyr::filter(.data$timezone %in% tz)
  # Throw an error if nothing found
  if (nrow(tz_zips) == 0) {
    stop(paste("No ZIP codes found for timezone:", tz))
  }
  return(dplyr::as_tibble(tz_zips))
}
#' Returns all ZIP codes found within a given FIPS code
#'
#' @param state_fips A U.S. FIPS code
#' @param county_fips A 1-3 digit county FIPS code (optional)
#' @return tibble of Census tracts and data from Census crosswalk file found for given ZIP code
#'
#' @examples
#' search_fips("34")
#' search_fips("34", "03")
#' search_fips("34", "3")
#' search_fips("36", "003")
#' @importFrom rlang .data
#' @export
search_fips <- function(state_fips, county_fips) {
  # Both arguments index a single row of the FIPS table, so they are defined
  # for one code at a time; a vector would silently recycle against the lookup
  if (length(state_fips) != 1) {
    stop(
      "`state_fips` must be a single state FIPS code, not a vector of length ",
      length(state_fips), ". Iterate (e.g. lapply) for multiple states."
    )
  }
  # Census FIPS code table bundled as internal data (see data-raw/fips_codes.R)
  fips_data <- fips_codes
  # Separate routine if only state_fips code provided
  if (missing(county_fips)) {
    # Get matching FIPS data for provided state FIPS code
    fips_result <- fips_data %>%
      dplyr::filter(.data$state_code == state_fips)
    if (nrow(fips_result) == 0) {
      stop("No state found for FIPS code ", state_fips)
    }
    # Compare ZIP code database against provided state FIPS code, store matching ZIP code entries
    result <- zip_code_db %>%
      dplyr::filter(.data$state == fips_result$state[1])
    return(dplyr::as_tibble(result))
  } else {
    # Clean up county FIPS code input by adding leading zeroes to match FIPS code data if not present
    if (length(county_fips) != 1) {
      stop(
        "`county_fips` must be a single county FIPS code, not a vector of ",
        "length ", length(county_fips),
        ". Iterate (e.g. lapply) for multiple counties."
      )
    }
    county_fips <- as.character(county_fips)
    if (nchar(county_fips) > 3) {
      stop("`county_fips` must be a 1-3 digit county FIPS code, got: ", county_fips)
    }
    if (nchar(county_fips) < 3) {
      county_fips <- base::paste0(strrep("0", 3 - nchar(county_fips)), county_fips)
    }
    # Get matching FIPS data for provided state & county FIPS code
    fips_result <- fips_data %>%
      dplyr::filter(.data$state_code == state_fips & .data$county_code == county_fips)
    if (nrow(fips_result) == 0) {
      stop("No county found for FIPS code ", state_fips, county_fips)
    }
    # Compare ZIP code database against provided state FIPS code, store matching ZIP code entries
    result <- zip_code_db %>%
      dplyr::filter(.data$state == fips_result$state[1] & .data$county == fips_result$county[1])
    return(dplyr::as_tibble(result))
  }
}

#' Get all Census tracts within a given ZIP code
#'
#' @param zip_code A U.S. ZIP code
#' @return tibble of Census tracts and data from Census crosswalk file found for given ZIP code
#'
#' @examples
#' get_tracts("08731")
#' get_tracts("90210")
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
get_tracts <- function(zip_code) {
  # Validate input, raise error if input is not a 5-digit ZIP code
  if (nchar(zip_code) != 5) {
    stop("Invalid input detected. Please enter a 5-digit U.S. ZIP code.")
  }
  # Get tract data given ZCTA
  tracts <- zcta_crosswalk %>%
    dplyr::filter(.data$ZCTA5 == zip_code)
  if (nrow(tracts) == 0) {
    stop(paste("No Census tracts found for ZIP code", zip_code))
  }
  return(tracts)
}
#' Get all congressional districts for a given ZIP code
#'
#' @param zip_code A single U.S. ZIP code
#' @return a named list with \code{state_fips} (state abbreviations) and
#'   \code{district} (two-digit district codes). The two vectors are parallel:
#'   ZIP codes spanning multiple districts return one element per district,
#'   each labeled with its own state (some ZIP codes cross state lines).
#'   Non-voting delegate districts (DC and the territories) use the Census
#'   code \code{"98"}.
#'
#' @examples
#' get_cd("08731")
#' get_cd("90210")
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
get_cd <- function(zip_code) {
  # get_cd() returns a single list, so it is defined for one ZIP at a time;
  # recycling a vector against the lookup table would silently mis-match
  if (length(zip_code) != 1) {
    stop(
      "`zip_code` must be a single ZIP code, not a vector of length ",
      length(zip_code), ". Iterate (e.g. lapply) for multiple ZIP codes."
    )
  }
  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)
  # Match ZIP codes with congressional districts located within this ZIP
  matched_cds <- zip_to_cd %>%
    dplyr::filter(.data$ZIP == zip_code)
  if (nrow(matched_cds) == 0) {
    if (zip_code %in% zip_code_db$zipcode) {
      warning(paste(
        "No congressional district found for ZIP code", zip_code,
        "- military and some USPS-only ZIP codes have no district mapping"
      ))
    } else {
      warning(paste(
        "ZIP code", zip_code, "not found in zip_code_db -",
        "check the input (5-digit character ZIP, leading zeros preserved)"
      ))
    }
  }
  # Break out the match from the ZIP to congressional district lookup into state FIPS code and congressional district codes
  district <- stringr::str_sub(matched_cds$CD, -2)
  state_code <- stringr::str_sub(matched_cds$CD, 1, 2)
  # Resolve state abbreviations from the bundled Census FIPS table (see
  # data-raw/fips_codes.R). state_fips is parallel to district so that ZIP
  # codes spanning a state line (e.g. 02861 in both RI-01 and MA-04) label
  # every district with its own state.
  state_abb <- fips_codes$state[match(state_code, fips_codes$state_code)]

  return(list(state_fips = state_abb, district = district))
}
#' Get all ZIP codes that fall within a given congressional district
#'
#' @param state_fips_code A two-digit U.S. FIPS code for a state
#' @param congressional_district A two digit number specifying a congressional district in a given
#' @return tibble of all congressional districts found for given ZIP code, including state code
#'
#' @examples
#' search_cd("34", "03")
#' search_cd("36", "05")
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
search_cd <- function(state_fips_code, congressional_district) {
  # One district at a time: the arguments are pasted into a single lookup code
  # and stamped onto the result, so a vector would silently recycle
  if (length(state_fips_code) != 1) {
    stop(
      "`state_fips_code` must be a single state FIPS code, not a vector of ",
      "length ", length(state_fips_code),
      ". Iterate (e.g. lapply) for multiple states."
    )
  }
  if (length(congressional_district) != 1) {
    stop(
      "`congressional_district` must be a single district code, not a vector ",
      "of length ", length(congressional_district),
      ". Iterate (e.g. lapply) for multiple districts."
    )
  }
  # "00" (the pre-2020 at-large convention this package used to ship) and
  # "98" (the Census delegate/resident-commissioner code now in zip_to_cd for
  # DC and the territories) are accepted as aliases of one another
  district_codes <- congressional_district
  if (congressional_district %in% c("00", "98")) {
    district_codes <- c("00", "98")
  }
  # Create codes from state and congressional district to match lookup table
  cd_code <- base::paste0(state_fips_code, district_codes)
  matched_zips <- zip_to_cd %>%
    dplyr::filter(.data$CD %in% cd_code)
  if (nrow(matched_zips) == 0) {
    stop(paste("No ZIP codes found for congressional district:", congressional_district))
  }
  output <- matched_zips %>%
    dplyr::select(-"CD")
  output$state_fips <- state_fips_code
  output$congressional_district <- congressional_district
  return(dplyr::as_tibble(output))
}

#' Returns true if the given ZIP code is also a ZIP code tabulation area (ZCTA)
#'
#'
#' @param zip_code A 5-digit U.S. ZIP code
#' @return Boolean TRUE or FALSE based upon whether provided ZIP code is a ZCTA by testing whether it exists in the U.S. Census crosswalk data
#'
#' @examples
#' is_zcta("90210")
#' is_zcta("99999")
#' is_zcta("07762")
#' @export
is_zcta <- function(zip_code) {
  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)
  # Test if provided ZIP code exists within Census ZCTA crosswalk
  result <- zip_code %in% zcta_crosswalk$ZCTA5
  return(result)
}

#' Returns the lat / lon pair of the centroid of a given ZIP code
#'
#' Note on sign convention: longitudes in the United States are negative
#' because the U.S. lies in the western hemisphere (west of the prime
#' meridian). This is the standard convention, not an error; do not flip
#' the sign of \code{lng}.
#'
#' @param zip_code A 5-digit U.S. ZIP code or character vector with multiple ZIP codes
#' @return A tibble of coordinates with one row per element of \code{zip_code},
#'   in input order (duplicates preserved). ZIP codes with no match return a row
#'   of NA coordinates (with a warning); an error is raised only when no input
#'   ZIP code matches at all.
#'
#' @examples
#' geocode_zip("07762")
#' geocode_zip("90210")
#' geocode_zip("90210")$lat
#' geocode_zip("90210")$lng
#' @export
geocode_zip <- function(zip_code) {

  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)

  # Match against the database, preserving input order and duplicates
  matched <- match(zip_code, zip_code_db$zipcode)

  if (all(is.na(matched))) {
    stop(paste("No results found for ZIP code", paste(zip_code, collapse = ", ")))
  }

  if (anyNA(matched)) {
    warning(paste(
      "No results found for ZIP code(s):",
      paste(unique(zip_code[is.na(matched)]), collapse = ", ")
    ))
  }

  # Unmatched inputs come back as NA rows rather than being dropped
  result <- dplyr::tibble(
    zipcode = zip_code,
    lat = zip_code_db$lat[matched],
    lng = zip_code_db$lng[matched]
  )

  return(result)
}
#' Search for ZIP codes that are within a given radius from a point
#'
#'
#' @param lat latitude
#' @param lng longitude
#' @param radius distance to search in miles, set by default to 1
#' @return a tibble containing the ZIP code(s) within the provided radius and distance from the provided coordinates in miles
#'
#' @examples
#' \dontrun{
#' search_radius(39.9, -74.3, 10)
#' }
#' @export
search_radius <- function(lat, lng, radius = 1) {
  if (!is.numeric(lat) || length(lat) != 1 || is.na(lat) || abs(lat) > 90) {
    stop("`lat` must be a single latitude between -90 and 90")
  }
  if (!is.numeric(lng) || length(lng) != 1 || is.na(lng) || abs(lng) > 180) {
    stop("`lng` must be a single longitude between -180 and 180")
  }
  if (!is.numeric(radius) || length(radius) != 1 || is.na(radius) || radius <= 0) {
    stop("`radius` must be a single positive number of miles")
  }

  # Work on just the three needed columns; the full database carries heavy
  # list columns that are expensive to subset
  keep <- !is.na(zip_code_db$lat) & !is.na(zip_code_db$lng)

  # Cheap bounding-box prefilter before the exact haversine pass, sized so no
  # candidate inside the radius can be excluded:
  # - the latitude window uses 69 statute miles per degree (constant),
  # - the longitude window is computed at the highest-|latitude| edge of the
  #   search circle (where meridians are closest together), not at the query
  #   point, so it is wide enough for every candidate latitude in the window,
  # - longitude differences are wrapped onto [-180, 180] so circles crossing
  #   the antimeridian (western Aleutians, Guam) keep their candidates,
  # - if the circle nears a pole or spans all longitudes, skip the prefilter.
  lat_delta <- radius / 69.0 * 1.05
  edge_lat <- min(abs(lat) + lat_delta, 90)
  if (edge_lat < 89) {
    lng_delta <- radius / (69.172 * cos(edge_lat * pi / 180)) * 1.05
    keep <- keep &
      zip_code_db$lat >= lat - lat_delta & zip_code_db$lat <= lat + lat_delta
    if (lng_delta < 180) {
      lng_diff <- abs(((zip_code_db$lng - lng + 180) %% 360) - 180)
      keep <- keep & lng_diff <= lng_delta
    }
  }

  zip_data <- dplyr::tibble(
    zipcode = zip_code_db$zipcode[keep],
    lat = zip_code_db$lat[keep],
    lng = zip_code_db$lng[keep]
  )

  # Calculate the distance between all points and the provided coordinate
  # pair, converting meters to miles
  zip_data$distance <-
    haversine_distance(zip_data$lat, zip_data$lng, lat, lng) * 0.000621371

  # Get matching ZIP codes within specified search radius
  result <- zip_data %>%
    # Filter results to those less than or equal to the search radius
    dplyr::filter(.data$distance <= radius) %>%
    dplyr::select("zipcode", "distance") %>%
    dplyr::arrange(.data$distance)

  # Warn if there is nothing found
  if (nrow(result) == 0) {
    warning(paste("No ZIP codes found for coordinates", paste0(lat, ",", lng), "with radius", radius, "mi"))
  }
  return(result)
}
