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
  base::cat(paste(nrow(state_zips), 'ZIP codes found for state:', state_abb))
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
  base::cat(paste(nrow(county_zips), 'ZIP codes found for', county_name_proper,',',state_abb,'\n'))
  return(county_zips)
}
#' Returns the county name + state for a given ZIP code
#'
#'
#' @param zip_code A 5-digit U.S. ZIP code
#' @return A named list consisting of the county name and state for the ZIP code
#'
#' @examples
#' zip_to_county('90210')
#' zip_to_county('08731')
#' zip_to_county('07762')$county
#' #' zip_to_county('07762')$state
#' @export
zip_to_county <- function(zip_code) {
  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)
  # Get matching ZIP code record for
  zip_code_data <- zip_code_db %>% dplyr::filter(.data$zipcode == zip_code)
  # Throw an error if nothing found
  if (nrow(zip_code_data) == 0) {
    stop(paste('No county name found for',.data$zip_code,',',.data$state))
  }
  county <- zip_code_data$county
  state <- zip_code_data$state
  return(list(county = county, state = state))
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
  base::cat(paste(nrow(city_zips), 'ZIP codes found for', city_name,',', state_abb,'\n'))
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
  base::cat(paste(nrow(tz_zips), 'ZIP codes found for', tz,'timezone','\n'))
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
  base::cat(paste(nrow(tracts), 'Census tracts found for ZIP code', zip_code,'\n'))
  return(tracts)
}
#' Get all congressional districts for a given ZIP code
#'
#' @param zip_code A U.S. ZIP code
#' @return a named list of two-digit state code and two digit district code
#'
#' @examples
#' get_cd('08731')
#' get_cd('90210')
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
get_cd <- function(zip_code) {
  # Get state FIPS codes data from tidycensus library
  state_fips <- tidycensus::fips_codes
  # Match ZIP codes with congressional districts located within this ZIP
  matched_cds <- zip_to_cd %>% dplyr::filter(.data$ZIP == zip_code)
  # Break out the match from the ZIP to congressional district lookup into state FIPS code and congressional district codes
  district <- stringr::str_sub(matched_cds$CD,-2)
  state <- stringr::str_sub(matched_cds$CD, 1,2)
  # Bind the separated district and state codes together as a dataframe
  result <- data.frame(cbind(district,state))
  # Join the lookup result with tidycensus FIPS code data for more info
  joined <- result %>% dplyr::left_join(state_fips, by=c('state'='state_code'))
  output <- data.frame(joined$state.y[1],district) %>% dplyr::rename('state_fips' = 'joined.state.y.1.')

  return(list(state_fips = joined$state.y[1], district = district))
}
#' Get all ZIP codes that fall within a given congressional district
#'
#' @param state_fips_code A two-digit U.S. FIPS code for a state
#' @param congressional_district A two digit number specifying a congressional district in a given
#' @return dataframe of all congressional districts found for given ZIP code, including state code
#'
#' @examples
#' cd_to_zip('34','03')
#' cd_to_zip('36','05')
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#' @export
cd_to_zip <- function(state_fips_code,congressional_district) {
  # Create code from state and congressional district to match lookup table
  cd_code <- base::paste0(state_fips_code,congressional_district)
  matched_zips <- zip_to_cd %>% dplyr::filter(.data$CD == cd_code)
  if (nrow(matched_zips) == 0) {
    stop(paste('No ZIP codes found for congressional district:', congressional_district))
  }
  # Print number of ZIP codes found to console
  base::cat(base::paste(nrow(matched_zips), 'ZIP codes found for', 'congressional district', congressional_district,'\n'))
  output <- matched_zips %>% dplyr::select(-.data$CD)
  output$state_fips <- state_fips_code
  output$congressional_district <- congressional_district
  return(output)
}
#' Returns true if the given ZIP code is also a ZIP code tabulation area (ZCTA)
#'
#'
#' @param zip_code A 5-digit U.S. ZIP code
#' @return Boolean TRUE or FALSE based upon whether provided ZIP code is a ZCTA by testing whether it exists in the U.S. Census crosswalk data
#'
#' @examples
#' is_zcta('90210')
#' is_zcta('99999')
#' is_zcta('07762')
#' @export
is_zcta <- function(zip_code) {
  # Convert to character so leading zeroes are preserved
  zip_code <- as.character(zip_code)
  # Validate input
  if (nchar(zip_code) != 5) {
    stop("Invalid input detected. Please enter a 5-digit U.S. ZIP code")
  }
  # Test if provided ZIP code exists within Census ZCTA crosswalk
  result <- zip_code %in% zcta_crosswalk$ZCTA5
  return(result)
}


