#' Search ZIP codes for a given state
#'
#'
#' @param state_abb Two-digit code for a U.S. state
#' @return dataframe of all ZIP codes for state defined in state_abb
#' @examples
#' search_state('NJ')
#' search_state('CA')
#'
#' @export
search_state <- function(state_abb){
  # Test if state abbreviation input is capitalized, capitalize if lowercase
  if (stringr::str_detect(state_abb, "^[:upper:]+$") == FALSE) {
    state_abb <- toupper(state_abb)
  }
  # Get matching ZIP codes for state
  state_zips <- zip_code_db %>% dplyr::filter(.data$state == state_abb)
  # Throw an error if nothing found
  if (nrow(state_zips) == 0) {
    stop(paste('No ZIP codes found for state:',state_abb))
  }
  # Print number of ZIP codes found to console
  print(paste(nrow(state_zips), 'ZIP codes found for', state_abb))
  return(state_zips)
}
#' Search ZIP codes for a county
#'
#'
#' @param state_abb Two-digit code for a U.S. state
#' @param county_name Name of a county within a U.S. state
#' @return dataframe of all ZIP codes found for given county
#'
#' @examples
#' middlesex <- search_county('Middlesex','NJ')
#' alameda <- search_county('alameda','CA')
#' @importFrom stringr str_detect
#' @export
search_county <- function(county_name, state_abb) {
  # Test if state abbreviation input is capitalized, capitalize if lowercase
  if (stringr::str_detect(state_abb, "^[:upper:]+$") == FALSE) {
    state_abb <- toupper(state_abb)
  }
  # Test if first letter of county  input is capitalized, capitalize if input is lowercase
  if (stringr::str_detect(county_name, "^[:upper:]") == FALSE) {
    first_char <- toupper(substring(county_name,0,1))
    remainder <- substring(county_name,2,nchar(county_name))
    county_name <- paste0(first_char,remainder)
  }
  # Create full name of county from name input
  county_name_proper <- paste(county_name,'County')
  # Get matching ZIP codes for county
  county_zips <- zip_code_db %>% dplyr::filter(.data$state == state_abb & .data$county == county_name_proper)
  # Throw an error if nothing found
  if (nrow(county_zips) == 0) {
    stop(paste('No ZIP codes found for county:',county_name,',',.data$state))
  }
  # Print number of ZIP codes found to console
  print(paste(nrow(county_zips), 'ZIP codes found for', county_name_proper,',',state_abb))
  return(county_zips)
}
#' Search ZIP codes for a city within a state
#'
#'
#' @param state_abb Two-digit code for a U.S. state
#' @param city_name Name of major city to search
#' @return dataframe of all ZIP code data found for given city
#'
#' @examples
#' search_city('Spring Lake','NJ')
#' search_city('Chappaqua','NY')
#' @importFrom stringr str_detect
#' @export
search_city <- function(city_name, state_abb) {
  # Test if state name input is capitalized, capitalize if lowercase
  if (stringr::str_detect(state_abb, "^[:upper:]+$") == FALSE) {
    state_abb <- toupper(state_abb)
  }
  # Test if first letter of city name  input is capitalized, capitalize if input is lowercase
  if (stringr::str_detect(city_name, "^[:upper:]") == FALSE) {
    first_char <- toupper(substring(city_name,0,1))
    remainder <- substring(city_name,2,nchar(city_name))
    city_name <- paste0(first_char,remainder)
  }
  # Get matching ZIP codes for city
  city_zips <- zip_code_db %>% dplyr::filter(.data$state == state_abb & .data$major_city == city_name)
  # Throw an error if nothing found
  if (nrow(city_zips) == 0) {
    stop(paste('No ZIP codes found for city:',city_name,',', state_abb))
  }
  # Print number of ZIP codes found to console
  print(paste(nrow(city_zips), 'ZIP codes found for', city_name,',', state_abb))
  return(city_zips)
}
#' Search ZIP codes for a timezone
#'
#' @param tz Timezone
#' @return dataframe of all ZIP codes found for given timezone
#'
#' @examples
#' eastern <- search_tz('Eastern')
#' pacific <- search_tz('Mountain')
#' @export
search_tz <- function(tz) {
  # Get matching ZIP codes for timezone
  tz_zips <- zip_code_db %>% dplyr::filter(.data$timezone == tz)
  # Throw an error if nothing found
  if (nrow(tz_zips) == 0) {
    stop(paste('No ZIP codes found for timezone:',tz))
  }
  # Print number of ZIP codes found to console
  print(paste(nrow(tz_zips), 'ZIP codes found for', tz,'timezone'))
  return(tz_zips)
}
#' Get all Census tracts within a given ZIP code
#'
#' @param zip_code A U.S. ZIP code
#' @return dataframe of Census tracts and data from Census crosswalk file found for given ZIP code
#'
#' @examples
#' get_tracts('08731')
#' get_tracts('90210')
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
get_tracts <- function(zip_code) {
  # Validate input, raise error if input is not a 5-digit ZIP code
  if (nchar(zip_code) != 5) {
    stop("Invalid input detected. Please enter a 5-digit U.S. ZIP code.")
  }
  # Get tract data given ZCTA
  tracts <- zcta_crosswalk %>% dplyr::filter(.data$ZCTA5 == zip_code)
  if (nrow(tracts) == 0) {
    stop(paste("No Census tracts found for ZIP code", zip_code))
  }
  # Print number of tracts found to console
  print(paste(nrow(tracts), 'Census tracts found for ZIP code', zip_code))
  return(tracts)
}


