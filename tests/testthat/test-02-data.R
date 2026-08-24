##############
# Data Files #
##############

# Load in needed data files
data(zip_code_db)
data(zcta_crosswalk)
data(zip_to_cd)

################
# zip_code_db  #
################

test_that("zip_code_db outputs proper structure data", {
  result <- class(zip_code_db)[1]
  expect_equal(result, "data.frame")
})

test_that("zip_code_db has proper number of columns", {
  result <- ncol(zip_code_db)
  expect_equal(result, 24)
})

##################
# zcta_crosswalk #
##################

test_that("zcta_crosswalk outputs proper structure data", {
  result <- class(zcta_crosswalk)[1]
  expect_equal(result, "tbl_df")
})

test_that("zcta_crosswalk has proper number of columns", {
  result <- ncol(zcta_crosswalk)
  expect_equal(result, 3)
})

##############
# zip_to_cd  #
##############

test_that("zip_to_cd outputs proper structure data", {
  result <- class(zip_to_cd)[1]
  expect_equal(result, "data.frame")
})

test_that("zip_to_cd  has proper number of columns", {
  result <- ncol(zip_to_cd)
  expect_equal(result, 2)
})

###################################
# Data regression checks (issues) #
###################################

test_that("zip_code_db schema matches the compatibility contract", {
  expect_equal(
    names(zip_code_db),
    c(
      "zipcode", "zipcode_type", "major_city", "post_office_city",
      "common_city_list", "county", "state", "lat", "lng", "timezone",
      "radius_in_miles", "area_code_list", "population", "population_density",
      "land_area_in_sqmi", "water_area_in_sqmi", "housing_units",
      "occupied_housing_units", "median_home_value", "median_household_income",
      "bounds_west", "bounds_east", "bounds_north", "bounds_south"
    )
  )
  expect_false(anyDuplicated(zip_code_db$zipcode) > 0)
  expect_true(all(
    zip_code_db$zipcode_type %in% c("Standard", "PO Box", "Unique", "Military", NA)
  ))
})

test_that("previously missing ZIP codes are present with coordinates (#19, #25, #26)", {
  regression_zips <- c("97003", "91230", "96910", "00802", "96799", "96950")
  found <- match(regression_zips, zip_code_db$zipcode)
  expect_false(anyNA(found))
  expect_false(anyNA(zip_code_db$lat[found]))
  expect_false(anyNA(zip_code_db$lng[found]))
})

test_that("zip_to_cd reflects post-2020 redistricting (#29)", {
  # 4-char state FIPS + district codes; the 119th-Congress relationship file
  # assigns 08731 (Ocean County, NJ) to districts 02/04, not the pre-2020 03
  expect_true(all(nchar(zip_to_cd$CD) == 4))
  nj_08731 <- zip_to_cd$CD[zip_to_cd$ZIP == "08731"]
  expect_true(all(substr(nj_08731, 1, 2) == "34"))
  expect_false("3403" %in% nj_08731)
})

test_that("zip_data_version() reports the data release", {
  meta <- zip_data_version()
  expect_type(meta, "list")
  expect_true(nzchar(meta$data_version))
  expect_equal(meta$zip_code_db_rows, nrow(zip_code_db))
})
