#' Download updated data files needed for library functionality to the package's data directory. To be implemented for future updates.
#'
#' @param force Boolean, if set to TRUE will force overwrite existing data files with new version
#' @return Data files needed for package functionality, stored in data directory of package install
#' @examples
#' \dontrun{
#' download_zip_data()
#' }
#' @export
download_zip_data <- function(force = FALSE) {

  # Define URLs for downloading external data
  url_crosswalk <- "https://github.com/gavinrozzi/zipcodeR-data/blob/master/zip_to_cd.rda?raw=true"
  url_zip_db <- "https://github.com/gavinrozzi/zipcodeR-data/blob/master/zip_code_db.rda?raw=true"
  url_cd <- "https://github.com/gavinrozzi/zipcodeR-data/blob/master/zip_to_cd.rda?raw=true"

  # Test if data dir exists and create
  if (dir.exists(paste0(system.file(package = "zipcodeR"), "/data")) == TRUE) {
    print("Data directory exists - moving to download phase")
  } else if (dir.exists(paste0(system.file(package = "zipcodeR"), "/data")) == FALSE) {
    print("Creating data directory")
    dir.create(paste0(system.file(package = "zipcodeR"), "/data"))
  }

  # Test if ZCTA crosswalk file exists, download if not present
  if (file.exists(system.file("data", "zcta_crosswalk.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
    print("Crosswalk file found, skipping")
  } else if (file.exists(system.file("data", "zcta_crosswalk.rda", package = "zipcodeR")) == FALSE) {
    print("Downloading ZCTA crosswalk file")
    utils::download.file(url_crosswalk, paste0(system.file("data", package = "zipcodeR"), "/zcta_crosswalk.rda"))
  } else if (force == TRUE) {
    print("Forcing Download of ZCTA crosswalk file")
    utils::download.file(url_crosswalk, paste0(system.file("data", package = "zipcodeR"), "/zcta_crosswalk.rda"))
  }

  # Test if ZIP code db file exists, download if not present
  if (file.exists(system.file("data", "zip_code_db.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
    print("ZIP code database file found, skipping")
  } else if (file.exists(system.file("data", "zip_code_db.rda", package = "zipcodeR")) == FALSE) {
    print("Downloading ZIP code database file")
    utils::download.file(url_zip_db, paste0(system.file("data", package = "zipcodeR"), "/zip_code_db.rda"))
  } else if (force == TRUE) {
    print("Forcing download of ZIP code database file")
    utils::download.file(url_zip_db, paste0(system.file("data", package = "zipcodeR"), "/zip_code_db.rda"))
  }

  # Test if congressional district relationship file exists, download if not present
  if (file.exists(system.file("data", "zip_to_cd.rda", package = "zipcodeR")) == TRUE && force == FALSE) {
    print("Congressional district file found, skipping")
  } else if (file.exists(system.file("data", "zip_to_cd.rda", package = "zipcodeR")) == FALSE) {
    print("Downloading congressional district data file")
    utils::download.file(url_cd, paste0(system.file("data", package = "zipcodeR"), "/zip_to_cd.rda"))
  } else if (force == TRUE) {
    print("Forcing download of congressional district data file")
    utils::download.file(url_cd, paste0(system.file("data", package = "zipcodeR"), "/zip_to_cd.rda"))
  }
}
