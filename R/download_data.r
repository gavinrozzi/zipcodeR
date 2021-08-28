#' Download updated data files needed for library functionality to the package's data directory. To be implemented for future updates.
#'
#' @param force Boolean, if set to TRUE will force overwrite existing data files with new version
#' @return Data files needed for package functionality, stored in data directory of package install
#' @examples
#' \dontrun{
#' download_zip_data()
#' }
#' @importFrom RSQLite dbConnect
#' @importFrom DBI dbGetQuery
#' @importFrom jsonlite fromJSON
#' @importFrom httr http_error
#' @importFrom dplyr `%>%`
#' @importFrom dplyr filter
#' @importFrom curl has_internet
#' @export
download_zip_data <- function(force = FALSE) {

  # Define URLs for downloading external datasets used in the package
  url_crosswalk <- "https://github.com/gavinrozzi/zipcodeR-data/blob/master/zip_to_cd.rda?raw=true"
  url_cd <- "https://github.com/gavinrozzi/zipcodeR-data/blob/master/zip_to_cd.rda?raw=true"

  # Test if data dir exists and create
  if (dir.exists(paste0(system.file(package = "zipcodeR"), "/data")) == TRUE) {
    cat("Data directory exists - moving to download phase")
  } else if (dir.exists(paste0(system.file(package = "zipcodeR"), "/data")) == FALSE) {
    cat("Creating data directory")
    dir.create(paste0(system.file(package = "zipcodeR"), "/data"))
  }

  # Test if ZCTA crosswalk file exists, download if not present
  if (file.exists(system.file("data", "zcta_crosswalk.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
    cat("Crosswalk file found, skipping")
  } else if (file.exists(system.file("data", "zcta_crosswalk.rda", package = "zipcodeR")) == FALSE) {
    cat("Downloading ZCTA crosswalk file")
    utils::download.file(url_crosswalk, paste0(system.file("data", package = "zipcodeR"), "/zcta_crosswalk.rda"))
  } else if (force == TRUE) {
    cat("Forcing Download of ZCTA crosswalk file")
    utils::download.file(url_crosswalk, paste0(system.file("data", package = "zipcodeR"), "/zcta_crosswalk.rda"))
  }

  # Test if ZIP code db file exists, download if not present
  # if (file.exists(system.file("data", "zip_code_db.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
  #  cat("ZIP code database file found, skipping")
  # } else if (file.exists(system.file("data", "zip_code_db.rda", package = "zipcodeR")) == FALSE) {
  #  cat("Downloading ZIP code database file")
  #  utils::download.file(url_zip_db, paste0(system.file("data", package = "zipcodeR"), "/zip_code_db.rda"))
  # } else if (force == TRUE) {
  #  cat("Forcing download of ZIP code database file")
  #  utils::download.file(url_zip_db, paste0(system.file("data", package = "zipcodeR"), "/zip_code_db.rda"))
  # }

  # Get the latest SQLite zipcode database from the GitHub API
  file_data <- jsonlite::fromJSON("https://api.github.com/repos/MacHu-GWU/uszipcode-project/releases/latest")
  assets <- file_data$assets

  # Get URL to download simple ZIP code dataset
  zip_db_url <- assets %>%
    dplyr::filter(.data$name == "simple_db.sqlite")

  # Store the latest download URL from GitHub
  file_name <- zip_db_url$browser_download_url

  # Store the latest version of zip_code_db to internal package data
  version <- as.Date(zip_db_url$created_at)
  save(version, file = paste0(system.file("R", package = "zipcodeR"), "/sysdata.rda"))

  # create a temporary directory and file for downloading the data
  td <- tempdir()
  zip_file <- tempfile(fileext = ".sqlite", tmpdir = tempdir())

  # Check if internet connection exists before attempting data download
  if (curl::has_internet() == FALSE) {
    message("No internet connection. Please connect to the internet and try again.")
    return(NULL)
  }

  # Check if data is available and download the data
  if (httr::http_error(file_name)) {
    message("zip_code_db data source broken. Please try again.")
    return(NULL)
  } else {
    message("zipcodeR: downloading zip_code_db")
    utils::download.file(file_name, zip_file, mode = "wb")
  }

  # Connect to the database
  conn <- RSQLite::dbConnect(RSQLite::SQLite(), dbname = zip_file)

  # Read in the new data
  zip_code_db <- dbGetQuery(conn, "SELECT * FROM simple_zipcode")

  # Save the updated RData file to package data directory
  save(zip_code_db, file = paste0(system.file("data", package = "zipcodeR"), "/zip_code_db.rda"))

  # Tear down the database connection
  RSQLite::dbDisconnect(conn)

  # Test if congressional district relationship file exists, download if not present
  if (file.exists(system.file("data", "zip_to_cd.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
    cat("Congressional district file found, skipping")
  } else if (file.exists(system.file("data", "zip_to_cd.rda", package = "zipcodeR")) == FALSE) {
    cat("Downloading congressional district data file")
    utils::download.file(url_cd, paste0(system.file("data", package = "zipcodeR"), "/zip_to_cd.rda"))
  } else if (force == TRUE) {
    cat("Forcing download of congressional district data file")
    utils::download.file(url_cd, paste0(system.file("data", package = "zipcodeR"), "/zip_to_cd.rda"))
  }
}
