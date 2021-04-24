
# Create data for testing
zipcodeData <- c(
  "98092", "98027", "98801", "98037", "99206", "98686", "98382",
  "98040", "98312", "98110", "98115", "99223", "98499", "98439",
  "98607", "98503", "98531", "98686", "98101", "99362", "99403",
  "REMVD", "REMVD", "98103", "99109", "98290", "98465", "98284",
  "98371", "98375", "98552", "98055", "98292", "98370", "98248",
  "98126", "98368", "98375", "98292", "99206", "98030", "98273",
  "98531", "98445", "98589", "98043", "98125", "99635", "99301",
  "98632", "98391", "REMVD", "98032", "98272", "97402", "99328",
  "98546", "99362", "98368", "98858", "98801", "98020", "98178",
  "98383", "98045", "REMVD", "98038", "98115", "98059", "98116",
  "98248", "98001", "98626", "98030", "98014", "99218", "98136",
  "98284", "98028", "98373", "98030", "98038", "98055", "98632",
  "98374", "98499", "98665", "98501", "98201", "98382", "98499",
  "98683", "98203", "99362", "98620", "97862", "98003", "99352",
  "99206", "98199"
)

# Filter to unique observations - should be 76 total rows
zipcodeData <- unique(zipcodeData)

#############
# is_zcta() #
#############

test_that("is_zcta() works - TRUE", {
  result <- is_zcta("07762")
  expect_true(result)
})

test_that("is_zcta() works - FALSE", {
  result <- is_zcta("08999")
  expect_false(result)
})

test_that("is_zcta() outputs proper length of data", {
  result <- length(is_zcta("08999"))
  expect_equal(result, 1)
})

test_that("is_zcta() outputs proper structure data", {
  result <- class(is_zcta("08999"))
  expect_equal(result, "logical")
})

##################
# geocode_zip()  #
##################

test_that("geocode_zip() works - lat", {
  result <- geocode_zip("08731")$lat
  expect_equal(result, 39.9)
})

test_that("geocode_zip() works - lng", {
  result <- geocode_zip("08731")$lng
  expect_equal(result, -74.3)
})

test_that("geocode_zip() outputs proper number of columns", {
  result <- ncol(geocode_zip("08731"))
  expect_equal(result, 3)
})

test_that("geocode_zip() outputs proper number of rows", {
  result <- nrow(geocode_zip("08731"))
  expect_equal(result, 1)
})

test_that("geocode_zip() outputs proper structure data", {
  result <- class(geocode_zip("08731"))[1]
  expect_equal(result, "tbl_df")
})

#####################
# reverse_zipcode() #
#####################

test_that("reverse_zipcode() output is vectorized", {
  result <- suppressWarnings(reverse_zipcode(zipcodeData))
  expect_equal(nrow(result), length(zipcodeData))
})

test_that("reverse_zipcode() outputs proper structure data", {
  result <- class(reverse_zipcode("08731"))[1]
  expect_equal(result, "tbl_df")
})

test_that("reverse_zipcode() filters results to a single ZIP code", {
  result <- reverse_zipcode("08731")$zipcode %>%
    unique()
  expect_equal(length(result), 1)
})

test_that("reverse_zipcode() works with the pipe operator when chained with other zipcodeR functions", {
  result <- search_state("NJ")$zipcode %>%
    reverse_zipcode()
  state <- result$state %>%
    unique()
  expect_equal(state, "NJ")
})

test_that("reverse_zipcode() warns on invalid ZIP code input", {
  expect_warning(reverse_zipcode("08999"))
})

test_that("reverse_zipcode() returns NA data on invalid ZIP code input", {
  result <- suppressWarnings(reverse_zipcode("08999"))
  expect_equal(result$zipcode_type, NA_character_)
})

test_that("reverse_zipcode() errors on ZIP code input with invalid number of characters", {
  expect_error(reverse_zipcode("099999"))
})

test_that("reverse_zipcode() errors on empty input", {
  expect_error(reverse_zipcode())
})






###################
# search_county() #
###################

test_that("search_county() outputs proper structure data", {
  result <- class(search_county("Ocean", "NJ"))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_county() can handle lowercase input", {
  result <- search_county("ocean", "nj")$county
  expect_equal(result[1], "Ocean County")
})

test_that("search_county() filters results to a single county", {
  result <- search_county("Ocean", "NJ")$county %>%
    unique()
  expect_equal(length(result), 1)
})

test_that("search_county() similar matching works (Issue #1)", {
  result <- search_county("ST BERNARD", "LA", similar = TRUE)$state[1]
  expect_equal(result, "LA")
})

test_that("search_county() similar works for different distances", {
  result <- search_county("ST BERNARD", "LA", similar = TRUE, max.distance = 0.5)$state[1]
  expect_equal(result, "LA")
})

test_that("search_county() errors on invalid input", {
  expect_error(search_county("Kenosha", "NJ"))
})



###################
# search_state() #
###################

test_that("search_state() outputs proper structure data", {
  result <- class(search_state("NJ"))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_state() filters results to a single state when given single state", {
  result <- search_state("NJ")$state %>%
    unique()
  expect_equal(length(result), 1)
})

test_that("search_state() output is vectorized when given vector of states", {
  result <- search_state(c("NJ", "NY", "CT"))$state %>%
    unique()
  expect_equal(length(result), 3)
})

test_that("search_state() errors on invalid input", {
  expect_error(search_state("XY"))
})



#################
# search_city() #
#################

test_that("search_city() outputs proper structure data", {
  result <- class(search_city("Spring Lake", "NJ"))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_city() filters results to a single city when given single city", {
  result <- search_city("Spring Lake", "NJ")$state %>%
    unique()
  expect_equal(length(result), 1)
})

test_that("search_city() filters results to a single city when given single city (lowercase input)", {
  result <- search_city("wayne", "nj")$major_city %>%
    unique()
  expect_equal(length(result), 1)
})

test_that("search_city() outputs proper structure data", {
  result <- class(search_city("Spring Lake", "NJ"))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_city() errors on invalid city name", {
  expect_error(search_city("anytown", "NJ"))
})





###############
# search_tz() #
###############

test_that("search_tz() outputs proper structure data", {
  result <- class(search_tz("Mountain"))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_tz() errors on invalid timezone input", {
  expect_error(search_tz("Western"))
})

###################
# search_radius() #
###################

test_that("search_radius() outputs proper structure data", {
  result <- class(search_radius(39.9, -74.3, 10))[1]
  expect_equal(result, "tbl_df")
})

test_that("search_radius() returns a single ZIP code when centroid of ZIP is submitted", {
  result <- search_radius(39.9, -74.3, 1)
  expect_equal(nrow(result), 1)
})

test_that("search_radius() output is consistent with zip_distance()", {
  result <- search_radius(39.9, -74.3, 10)
  expect_equal(
    zip_distance(result$zipcode[1], result$zipcode[2]),
    round(result$distance[2], digits = 2)
  )
})

################
# geocode_zip()#
################

test_that("geocode_zip() outputs proper structure data", {
  result <- class(geocode_zip("08731"))[1]
  expect_equal(result, "tbl_df")
})

test_that("geocode_zip() errors on single invalid ZIP", {
  expect_error(geocode_zip("08999"))
})


test_that("geocode_zip() outputs proper structure data", {
  result <- class(geocode_zip("08731"))[1]
  expect_equal(result, "tbl_df")
})
##################
# normalize_zip()#
##################
test_that("normalize_zip() fixes missing leading zeroes ", {
  # test with a zipcode missing leading zero
  result <- normalize_zip("8731")
  expect_equal(result, "08731")
})
