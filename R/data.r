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
#' @section Provenance and limitations:
#' This dataset is a snapshot of the \code{simple_zipcode} table of the
#' \href{https://github.com/MacHu-GWU/uszipcode-project}{uszipcode} project's
#' database (release of 2021-06-08), which aggregates U.S. Census Bureau data
#' (decennial census, ACS, gazetteer files) with USPS-derived ZIP code
#' attributes. Users should be aware of inherent limitations of ZIP-code-level
#' data: ZIP codes are postal delivery constructs, not polygons or
#' jurisdictions. They can cross city, county, and state boundaries, and the
#' \code{major_city}/\code{county} columns reflect the predominant postal
#' assignment, not legal jurisdiction. Census-derived attributes are estimated
#' at the ZIP Code Tabulation Area (ZCTA) level, which only approximates USPS
#' ZIP codes; USPS-only codes (P.O. Box and unique codes) may lack coordinates
#' and demographic attributes. See \code{vignette("faq", package = "zipcodeR")}.
#'
#' @format A data frame with 41877 rows and 24 variables:
#' \describe{
#'   \item{zipcode}{5 digit U.S. ZIP code}
#'   \item{zipcode_type}{Type of ZIP code: Standard, PO Box or Unique}
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
#'   \item{occupied_housing_units}{Number of occupied housing units within the ZIP code}
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
#' A dataset containing mappings between ZIP codes and congressional districts.
#'
#' Note: this crosswalk predates the post-2020-census redistricting cycle and
#' reflects the district boundaries in force at the time it was built. A
#' refresh from the current Census ZCTA-to-congressional-district relationship
#' files is planned as part of the reproducible data pipeline (see issue #29).
#'
#' @format A data frame with 45914 rows and 2 variables:
#' \describe{
#'   \item{ZIP}{5 digit U.S. ZIP code}
#'   \item{CD}{Four digit congressional district code (State FIPS code + district number)}
#' }
#' @source \url{https://www.huduser.gov/portal/datasets/usps_crosswalk.html}
"zip_to_cd"
