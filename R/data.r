#' ZCTA to Census Tract (2010) Crosswalk
#'
#' A dataset containing the relationships between ZIP code tabulation areas (ZCTA) and Census Tracts. This contains selected variables from the official crosswalk file.
#'
#' @format A data frame with 148897 rows and 4 variables:
#' \describe{
#'   \item{ZCTA5}{2010 ZIP Code Tabulation Area}
#'   \item{TRACT}{2010 Census Tract Code}
#'   \item{GEOID}{Concatenation of 2010 State, County, and Tract}
#' }
#' @source \url{https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.html}
"zcta_crosswalk"
#' ZIP Code Database
#'
#' A dataset containing detailed information for U.S. ZIP codes
#'
#' @format A data frame with 41877 rows and 24 variables:
#' \describe{
#'   \item{zipcode}{5 digit U.S. ZIP code}
#'   \item{zipcode_type}{2010 State FIPS Code}
#'   \item{major_city}{Major city serving the ZIP code}
#'   \item{post_office_city}{City of post office serving the ZIP code}
#'   \item{common_city_list}{List of common cities represented by the ZIP code}
#'   \item{county}{Name of county containing the ZIP code}
#'   \item{state}{Two-digit state code for ZIP code location}
#'   \item{lat}{Latitude of the centroid for the ZIP code}
#'   \item{lng}{Longitude of the centroid for the ZIP code}
#'   \item{timezone}{Timezone of the ZIP code}
#'   \item{radius_in_miles}{Radius of the ZIP code in miles}
#'   \item{area_code_list}{List of area codes for telephone numbers within this ZIP code}
#'   \item{population}{Total population of the ZIP code}
#'   \item{population_density}{Population density of the ZIP code (persons per square mile)}
#'   \item{land_area_in_sqmi}{Area of the land contained within the ZIP code in square miles}
#'   \item{water_area_in_sqmi}{Area of the waters contained within the ZIP code in square miles}
#'   \item{housing_units}{Number of housing units within the ZIP code}
#'   \item{occupied_housing_units}{Number of housing units within the ZIP code}
#'   \item{median_home_value}{Median home price within the ZIP code}
#'   \item{median_household_income}{Median household income within the ZIP code}
#'   \item{bounds_west}{Bounding box coordinates}
#'   \item{bounds_east}{Bounding box coordinates}
#'   \item{bounds_north}{Bounding box coordinates}
#'   \item{bounds_south}{Bounding box coordinates}
#' }
#' @source \url{https://github.com/MacHu-GWU/uszipcode-project/files/5183256/simple_db.log}
"zip_code_db"
#' ZIP Code to Congressional District Relationship File
#'
#' A dataset containing mappings between ZIP codes and congressional districts
#'
#' @format A data frame with 45914 rows and 2 variables:
#' \describe{
#'   \item{ZIP}{5 digit U.S. ZIP code}
#'   \item{CD}{Four digit congressional district code (State FIPS code + district number)}
#' }
#' @source \url{https://www.huduser.gov/portal/datasets/usps_crosswalk.html}
"zip_to_cd"
