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
