####################################################
# Return-schema snapshots (forward-compat contract) #
####################################################
# These snapshots freeze the shape of every exported function's return
# value: column names, column classes, and object class. A change here is a
# breaking API change and must be deliberate (delete the snapshot to accept).

schema <- function(x) {
  if (is.data.frame(x)) {
    paste0(
      class(x)[1], ": ",
      paste(names(x), vapply(x, function(col) class(col)[1], ""),
        sep = "=", collapse = ", "
      )
    )
  } else {
    paste0(class(x)[1], " length ", length(x))
  }
}

test_that("lookup function return schemas are stable", {
  expect_snapshot({
    cat("search_state:     ", schema(search_state("NJ")), "\n")
    cat("search_county:    ", schema(search_county("Ocean", "NJ")), "\n")
    cat("search_city:      ", schema(search_city("Chappaqua", "NY")), "\n")
    cat("search_tz:        ", schema(search_tz("Eastern")), "\n")
    cat("search_fips:      ", schema(search_fips("34", "029")), "\n")
    cat("search_cd:        ", schema(search_cd("34", "02")), "\n")
    cat("search_radius:    ", schema(search_radius(39.9, -74.3, 5)), "\n")
    cat("reverse_zipcode:  ", schema(reverse_zipcode("08731")), "\n")
    cat("geocode_zip:      ", schema(geocode_zip("08731")), "\n")
    cat("get_tracts:       ", schema(get_tracts("08731")), "\n")
    cat("zip_distance:     ", schema(zip_distance("08731", "08901")), "\n")
    cat("normalize_zip:    ", schema(normalize_zip("8731")), "\n")
    cat("is_zcta:          ", schema(is_zcta("08731")), "\n")
  })
})

test_that("get_cd return shape is stable", {
  result <- get_cd("08731")
  expect_type(result, "list")
  expect_named(result, c("state_fips", "district"))
})

test_that("input validation raises informative errors", {
  expect_error(search_radius("a", -74.3), "lat")
  expect_error(search_radius(39.9, -74.3, radius = -1), "radius")
  expect_error(search_radius(139.9, -74.3), "lat")
  expect_error(zip_distance("08731", "08901", units = "furlongs"))
  expect_error(zip_distance(c("08731", "08734"), c("08901", "08005", "07762")), "length")
})

test_that("download_zip_data() is deprecated", {
  # Deprecation must fire before any network access is attempted
  expect_warning(
    try(download_zip_data(), silent = TRUE),
    "deprecated"
  )
})
