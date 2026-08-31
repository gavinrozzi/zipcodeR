# Next-generation lookup API. Every data-dependent function requires an
# explicit, validated bundle as its first argument. The legacy API remains in
# zip_lookups.r and zip_helper_functions.R without behavioral changes.

#' Search a state using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param state_abb Two-letter state abbreviation(s).
#' @return A tibble grouped in query order; repeated states repeat their rows.
#' @export
search_state_ng <- function(data, state_abb) {
  db <- ng_zip_db(data)
  state_abb <- toupper(as.character(state_abb))
  validate_ng_query_vector(state_abb, "state_abb", "^[A-Z]{2}$")
  matched <- lapply(state_abb, function(state) which(db$state == state))
  missing_values <- unique(state_abb[!lengths(matched)])
  if (length(missing_values)) {
    warning(
      "No ZIP codes found for state(s): ",
      paste(missing_values, collapse = ", "),
      call. = FALSE
    )
  }
  result <- db[unlist(matched, use.names = FALSE), , drop = FALSE]
  if (!nrow(result)) stop("No ZIP codes found for requested state(s).", call. = FALSE)
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Search a county using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param county_name County name.
#' @param state_abb Two-letter state abbreviation.
#' @param ... Set `similar = TRUE` and optionally `max.distance` for approximate matching.
#' @return A tibble from the selected data vintage.
#' @export
search_county_ng <- function(data, county_name, state_abb, ...) {
  db <- ng_zip_db(data)
  assert_scalar(county_name, "county_name")
  assert_scalar(state_abb, "state_abb")
  county_name <- as.character(county_name)
  state_abb <- toupper(as.character(state_abb))
  if (!grepl("^[A-Z]{2}$", state_abb)) {
    stop("`state_abb` must contain exactly two letters.", call. = FALSE)
  }
  dots <- rlang::list2(...)
  unknown_dots <- setdiff(names(dots), c("similar", "max.distance"))
  if (length(unknown_dots)) {
    stop("Unknown argument(s): ", paste(unknown_dots, collapse = ", "), call. = FALSE)
  }
  similar <- dots$similar %||% FALSE
  if (!is.logical(similar) || length(similar) != 1L || is.na(similar)) {
    stop("`similar` must be TRUE or FALSE.", call. = FALSE)
  }
  state_rows <- db[db$state == state_abb, , drop = FALSE]
  if (similar) {
    max_distance <- dots$max.distance %||% 0.1
    if (!is.numeric(max_distance) || length(max_distance) != 1L ||
        is.na(max_distance) || !is.finite(max_distance) || max_distance < 0) {
      stop("`max.distance` must be one non-negative number.", call. = FALSE)
    }
    matched <- agrep(
      county_name, state_rows$county, ignore.case = TRUE, value = TRUE,
      max.distance = max_distance
    )
    result <- state_rows[state_rows$county %in% matched, , drop = FALSE]
  } else {
    requested <- sub("\\s+County$", "", county_name, ignore.case = TRUE)
    result <- state_rows[
      tolower(state_rows$county) == tolower(paste(requested, "County")),
      , drop = FALSE
    ]
  }
  if (!nrow(result)) {
    stop("No ZIP codes found for county: ", county_name, ", ", state_abb)
  }
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Reverse-geocode ZIP codes using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zip_code Five-digit ZIP code(s).
#' @return One row per input, in input order, with duplicates preserved.
#' @export
reverse_zipcode_ng <- function(data, zip_code) {
  db <- ng_zip_db(data)
  zip_code <- as.character(zip_code)
  matched <- match(zip_code, db$zipcode)
  missing_values <- unique(zip_code[is.na(matched)])
  if (length(missing_values)) {
    warning(
      "No data found for ZIP code(s): ", paste(missing_values, collapse = ", "),
      call. = FALSE
    )
  }
  result <- db[matched, , drop = FALSE]
  result$zipcode <- zip_code
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Search a city using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param city_name City name.
#' @param state_abb Two-letter state abbreviation.
#' @return A tibble from the selected data vintage.
#' @export
search_city_ng <- function(data, city_name, state_abb) {
  db <- ng_zip_db(data)
  assert_scalar(city_name, "city_name")
  assert_scalar(state_abb, "state_abb")
  city_name <- as.character(city_name)
  state_abb <- toupper(as.character(state_abb))
  if (!grepl("^[A-Z]{2}$", state_abb)) {
    stop("`state_abb` must contain exactly two letters.", call. = FALSE)
  }
  result <- db[
    db$state == state_abb & tolower(db$major_city) == tolower(city_name),
    , drop = FALSE
  ]
  if (!nrow(result)) stop("No ZIP codes found for city: ", city_name, ", ", state_abb)
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Search a timezone using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param tz Timezone value(s).
#' @return A tibble grouped in query order; repeated timezones repeat their rows.
#' @export
search_tz_ng <- function(data, tz) {
  db <- ng_zip_db(data)
  tz <- as.character(tz)
  validate_ng_query_vector(tz, "tz")
  matched <- lapply(tz, function(zone) which(db$timezone == zone))
  missing_values <- unique(tz[!lengths(matched)])
  if (length(missing_values)) {
    warning(
      "No ZIP codes found for timezone(s): ",
      paste(missing_values, collapse = ", "),
      call. = FALSE
    )
  }
  result <- db[unlist(matched, use.names = FALSE), , drop = FALSE]
  if (!nrow(result)) stop("No ZIP codes found for requested timezone(s).", call. = FALSE)
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Search FIPS codes using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param state_fips One state FIPS code.
#' @param county_fips Optional one- to three-digit county FIPS code.
#' @return A tibble from the selected data vintage.
#' @export
search_fips_ng <- function(data, state_fips, county_fips) {
  db <- ng_zip_db(data)
  assert_scalar(state_fips, "state_fips")
  state_fips <- as.character(state_fips)
  if (!grepl("^[0-9]{1,2}$", state_fips)) {
    stop("`state_fips` must contain one or two digits.", call. = FALSE)
  }
  state_fips <- sprintf("%02d", as.integer(state_fips))
  if (missing(county_fips)) {
    fips_result <- fips_codes[fips_codes$state_code == state_fips, , drop = FALSE]
  } else {
    assert_scalar(county_fips, "county_fips")
    county_fips <- as.character(county_fips)
    if (!grepl("^[0-9]{1,3}$", county_fips)) {
      stop("`county_fips` must contain one to three digits.", call. = FALSE)
    }
    county_fips <- sprintf("%03d", as.integer(county_fips))
    fips_result <- fips_codes[
      fips_codes$state_code == state_fips & fips_codes$county_code == county_fips,
      , drop = FALSE
    ]
  }
  if (!nrow(fips_result)) stop("No matching FIPS code found.")
  result <- db[db$state == fips_result$state[[1]], , drop = FALSE]
  if (!missing(county_fips)) {
    result <- result[result$county == fips_result$county[[1]], , drop = FALSE]
  }
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Get Census tracts using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zip_code One five-digit ZIP or ZCTA code.
#' @return A tract crosswalk tibble.
#' @export
get_tracts_ng <- function(data, zip_code) {
  data <- validate_zip_data_bundle(data)
  assert_scalar(zip_code, "zip_code")
  zip_code <- as.character(zip_code)
  if (!grepl("^[0-9]{5}$", zip_code)) {
    stop("`zip_code` must contain exactly 5 digits.", call. = FALSE)
  }
  result <- data$zcta_crosswalk[data$zcta_crosswalk$ZCTA5 == zip_code, , drop = FALSE]
  if (!nrow(result)) stop("No Census tracts found for ZIP code ", zip_code)
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Get congressional districts using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zip_code One five-digit ZIP code.
#' @return A named list with parallel `state_fips` and `district` vectors.
#' @export
get_cd_ng <- function(data, zip_code) {
  data <- validate_zip_data_bundle(data)
  assert_scalar(zip_code, "zip_code")
  zip_code <- as.character(zip_code)
  if (!grepl("^[0-9]{5}$", zip_code)) {
    stop("`zip_code` must contain exactly 5 digits.", call. = FALSE)
  }
  matched <- data$zip_to_cd[data$zip_to_cd$ZIP == zip_code, , drop = FALSE]
  if (!nrow(matched)) {
    reason <- data$quality[
      data$quality$dataset == "zip_to_cd" & data$quality$key == zip_code,
      "reason", drop = TRUE
    ]
    warning(
      "No authoritative congressional district found for ZIP code ", zip_code,
      if (length(reason)) paste0(": ", reason[[1]]) else ".",
      call. = FALSE
    )
  }
  state_code <- substr(matched$CD, 1, 2)
  district <- substr(matched$CD, 3, 4)
  state_abb <- fips_codes$state[match(state_code, fips_codes$state_code)]
  stamp_ng_result(list(state_fips = state_abb, district = district), data)
}

#' Search a congressional district using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param state_fips_code One state FIPS code.
#' @param congressional_district One two-digit district code.
#' @return A ZIP-to-district tibble.
#' @export
search_cd_ng <- function(data, state_fips_code, congressional_district) {
  data <- validate_zip_data_bundle(data)
  assert_scalar(state_fips_code, "state_fips_code")
  assert_scalar(congressional_district, "congressional_district")
  state_fips_code <- as.character(state_fips_code)
  congressional_district <- as.character(congressional_district)
  if (!grepl("^[0-9]{1,2}$", state_fips_code)) {
    stop("`state_fips_code` must contain one or two digits.", call. = FALSE)
  }
  if (!grepl("^[0-9]{1,2}$", congressional_district)) {
    stop("`congressional_district` must contain one or two digits.", call. = FALSE)
  }
  state_fips_code <- sprintf("%02d", as.integer(state_fips_code))
  congressional_district <- sprintf("%02d", as.integer(congressional_district))
  district_codes <- congressional_district
  if (congressional_district %in% c("00", "98")) district_codes <- c("00", "98")
  codes <- paste0(state_fips_code, district_codes)
  result <- data$zip_to_cd[data$zip_to_cd$CD %in% codes, , drop = FALSE]
  if (!nrow(result)) stop("No ZIP codes found for congressional district: ", congressional_district)
  result$CD <- NULL
  result$state_fips <- state_fips_code
  result$congressional_district <- congressional_district
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Test ZCTA membership using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zip_code ZIP code(s).
#' @return A logical vector.
#' @export
is_zcta_ng <- function(data, zip_code) {
  data <- validate_zip_data_bundle(data)
  stamp_ng_result(as.character(zip_code) %in% data$zcta_crosswalk$ZCTA5, data)
}

#' Geocode ZIP codes using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zip_code ZIP code(s).
#' @return One coordinate row per input, preserving order and duplicates.
#' @export
geocode_zip_ng <- function(data, zip_code) {
  db <- ng_zip_db(data)
  zip_code <- as.character(zip_code)
  matched <- match(zip_code, db$zipcode)
  if (!length(matched)) {
    return(stamp_ng_result(dplyr::tibble(
      zipcode = character(), lat = numeric(), lng = numeric()
    ), data))
  }
  if (all(is.na(matched))) {
    stop("No results found for ZIP code ", paste(zip_code, collapse = ", "))
  }
  if (anyNA(matched)) {
    warning(
      "No results found for ZIP code(s): ",
      paste(unique(zip_code[is.na(matched)]), collapse = ", "),
      call. = FALSE
    )
  }
  result <- dplyr::tibble(
    zipcode = zip_code,
    lat = db$lat[matched],
    lng = db$lng[matched]
  )
  stamp_ng_result(result, data)
}

#' Search within a radius using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param lat,lng Query coordinates.
#' @param radius Radius in miles.
#' @return A tibble of ZIP codes and haversine distances.
#' @export
search_radius_ng <- function(data, lat, lng, radius = 1) {
  db <- ng_zip_db(data)
  validate_point_radius(lat, lng, radius)
  keep <- !is.na(db$lat) & !is.na(db$lng)
  lat_delta <- radius / 69 * 1.05
  edge_lat <- min(abs(lat) + lat_delta, 90)
  if (edge_lat < 89) {
    lng_delta <- radius / (69.172 * cos(edge_lat * pi / 180)) * 1.05
    keep <- keep & db$lat >= lat - lat_delta & db$lat <= lat + lat_delta
    if (lng_delta < 180) {
      lng_diff <- abs(((db$lng - lng + 180) %% 360) - 180)
      keep <- keep & lng_diff <= lng_delta
    }
  }
  distance <- haversine_distance(db$lat[keep], db$lng[keep], lat, lng) * 0.000621371
  result <- data.frame(zipcode = db$zipcode[keep], distance = distance)
  result <- result[result$distance <= radius, , drop = FALSE]
  result <- result[order(result$distance), , drop = FALSE]
  if (!nrow(result)) warning("No ZIP codes found within the requested radius.", call. = FALSE)
  stamp_ng_result(dplyr::as_tibble(result), data)
}

#' Normalize ZIP codes with corrected boundary behavior
#' @param zipcode Character or numeric ZIP values.
#' @return Normalized five-character ZIP values.
#' @export
normalize_zip_ng <- function(zipcode) {
  capture_group <- function(values, regex) {
    matches <- regmatches(values, regexec(regex, values))
    vapply(matches, function(x) if (length(x) >= 2L) x[[2]] else NA_character_, character(1))
  }
  if (is.character(zipcode)) {
    zipcode <- ifelse(
      grepl("^\\s*(\\d+)-.*", zipcode),
      capture_group(zipcode, "^\\s*(\\d+)-.*"), zipcode
    )
    missing_values <- is.na(zipcode)
    zipcode <- ifelse(
      nchar(zipcode) > 5L,
      capture_group(zipcode, "(.*)\\d\\d\\d\\d"), zipcode
    )
    zipcode <- ifelse(nchar(zipcode) < 5L, sprintf("%05i", as.numeric(zipcode)), zipcode)
    zipcode[missing_values] <- NA_character_
    return(zipcode)
  }
  if (!is.numeric(zipcode)) stop("input must be character or numeric")
  zipcode <- ifelse(zipcode >= 100000, floor(zipcode / 10000), zipcode)
  missing_values <- is.na(zipcode)
  zipcode <- sprintf("%05i", as.numeric(zipcode))
  zipcode[missing_values] <- NA_character_
  zipcode
}

#' Calculate ZIP-to-ZIP distance using an explicit data bundle
#' @param data A `zipcodeR_data_bundle`.
#' @param zipcode_a,zipcode_b ZIP vectors.
#' @param lonlat Use great-circle haversine distance; `FALSE` uses a planar
#'   equirectangular approximation.
#' @param units `"miles"` or `"meters"`.
#' @return A data frame of paired ZIP codes and distances.
#' @export
zip_distance_ng <- function(data, zipcode_a, zipcode_b, lonlat = TRUE,
                            units = c("miles", "meters")) {
  db <- ng_zip_db(data)
  units <- match.arg(units)
  if (!is.logical(lonlat) || length(lonlat) != 1L || is.na(lonlat)) {
    stop("`lonlat` must be TRUE or FALSE.", call. = FALSE)
  }
  zipcode_a <- as.character(zipcode_a)
  zipcode_b <- as.character(zipcode_b)
  if (length(zipcode_a) != length(zipcode_b)) {
    n <- max(length(zipcode_a), length(zipcode_b))
    m <- min(length(zipcode_a), length(zipcode_b))
    if (!m || n %% m) stop("ZIP vectors have incompatible lengths.")
    zipcode_a <- rep_len(zipcode_a, n)
    zipcode_b <- rep_len(zipcode_b, n)
  }
  a <- match(zipcode_a, db$zipcode)
  b <- match(zipcode_b, db$zipcode)
  lat_a <- db$lat[a]; lng_a <- db$lng[a]
  lat_b <- db$lat[b]; lng_b <- db$lng[b]
  if (isTRUE(lonlat)) {
    distance <- haversine_distance(lat_a, lng_a, lat_b, lng_b)
  } else {
    meters_per_degree <- 6371008.8 * pi / 180
    dlng <- ((lng_b - lng_a + 180) %% 360) - 180
    dx <- dlng * cos((lat_a + lat_b) / 2 * pi / 180)
    dy <- lat_b - lat_a
    distance <- sqrt(dx^2 + dy^2) * meters_per_degree
  }
  if (units == "miles") distance <- distance * 0.000621371
  result <- data.frame(zipcode_a, zipcode_b, distance = round(distance, 2))
  stamp_ng_result(result, data)
}

#' @noRd
ng_zip_db <- function(data) {
  validate_zip_data_bundle(data)$zip_code_db
}

#' @noRd
stamp_ng_result <- function(x, data) {
  data <- validate_zip_data_bundle(data)
  attr(x, "zipcodeR_data_version") <- data$metadata$data_version
  checksum <- attr(data, "bundle_sha256", exact = TRUE)
  if (!is.null(checksum)) attr(x, "zipcodeR_bundle_sha256") <- checksum
  x
}

#' @noRd
assert_scalar <- function(x, name) {
  if (length(x) != 1L || is.na(x)) {
    stop("`", name, "` must be one non-missing value.", call. = FALSE)
  }
  invisible(x)
}

#' @noRd
validate_point_radius <- function(lat, lng, radius) {
  if (!is.numeric(lat) || length(lat) != 1L || is.na(lat) ||
      !is.finite(lat) || abs(lat) > 90) {
    stop("`lat` must be one latitude between -90 and 90.", call. = FALSE)
  }
  if (!is.numeric(lng) || length(lng) != 1L || is.na(lng) ||
      !is.finite(lng) || abs(lng) > 180) {
    stop("`lng` must be one longitude between -180 and 180.", call. = FALSE)
  }
  if (!is.numeric(radius) || length(radius) != 1L || is.na(radius) ||
      !is.finite(radius) || radius < 0) {
    stop("`radius` must be one non-negative number of miles.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @noRd
validate_ng_query_vector <- function(x, name, pattern = NULL) {
  if (!length(x) || anyNA(x) || any(!nzchar(x))) {
    stop("`", name, "` must contain one or more non-missing values.", call. = FALSE)
  }
  if (!is.null(pattern) && any(!grepl(pattern, x))) {
    stop("`", name, "` contains an invalid value.", call. = FALSE)
  }
  invisible(x)
}
