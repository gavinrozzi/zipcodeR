test_that("next-generation reverse lookup preserves order, duplicates, and misses", {
  bundle <- make_test_bundle()
  expect_warning(
    result <- reverse_zipcode_ng(bundle, c("08731", "99999", "08731")),
    "99999"
  )
  expect_identical(result$zipcode, c("08731", "99999", "08731"))
  expect_identical(result$state_fips, c("34", NA_character_, "34"))
  expect_identical(result$county_fips, c("34029", NA_character_, "34029"))
  expect_true(is.na(result$state[[2]]))
  expect_identical(attr(result, "zipcodeR_data_version"), "test-2026.08")
  expect_identical(attr(result, "zipcodeR_bundle_sha256"), paste(rep("a", 64), collapse = ""))
})

test_that("next-generation geocoding preserves one row per input", {
  bundle <- make_test_bundle()
  expect_warning(
    result <- geocode_zip_ng(bundle, c("08731", "99999", "08731")),
    "99999"
  )
  expect_identical(result$zipcode, c("08731", "99999", "08731"))
  expect_true(is.na(result$lat[[2]]))
  expect_error(geocode_zip_ng(bundle, "99999"), "No results")
  expect_equal(nrow(geocode_zip_ng(bundle, character())), 0L)
})

test_that("next-generation radius search handles antimeridian and boundaries", {
  bundle <- make_test_bundle()
  result <- search_radius_ng(bundle, 0, 180, radius = 20)
  expect_setequal(result$zipcode, c("99001", "99002"))

  wide <- search_radius_ng(bundle, 0, 180, radius = 20)
  threshold <- wide$distance[wide$zipcode == "99001"]
  expect_true("99001" %in% search_radius_ng(bundle, 0, 180, threshold)$zipcode)
  expect_false("99001" %in% suppressWarnings(
    search_radius_ng(bundle, 0, 180, threshold - 1e-8)
  )$zipcode)
  expect_error(search_radius_ng(bundle, 91, 0, 1), "lat")
  expect_error(search_radius_ng(bundle, 0, 181, 1), "lng")
  expect_error(search_radius_ng(bundle, 0, 0, -1), "radius")
  expect_error(search_radius_ng(bundle, 0, 0, Inf), "radius")
})

test_that("unavailable coordinates remain explicit", {
  bundle <- make_test_bundle()
  distance <- zip_distance_ng(bundle, "99004", "08731")
  expect_true(is.na(distance$distance))
  radius <- search_radius_ng(bundle, 0, 180, 200)
  expect_false("99004" %in% radius$zipcode)
})

test_that("next-generation tract and district results use authoritative bundle rows", {
  bundle <- make_test_bundle()
  tracts <- get_tracts_ng(bundle, "08731")
  expect_identical(tracts$GEOID, c("34029010100", "34029010200"))

  cd <- get_cd_ng(bundle, "08731")
  expect_identical(cd$state_fips, c("NJ", "NJ"))
  expect_identical(cd$district, c("02", "04"))

  expect_warning(unmapped <- get_cd_ng(bundle, "99004"), "No authoritative")
  expect_length(unmapped$district, 0L)
  expect_error(get_cd_ng(bundle, "1234"), "5 digits")
})

test_that("next-generation distance recycling and normalization are explicit", {
  bundle <- make_test_bundle()
  result <- zip_distance_ng(
    bundle,
    c("08731", "08734"),
    c("08901", "08005", "90210", "99004")
  )
  expect_equal(nrow(result), 4L)
  expect_error(
    zip_distance_ng(bundle, c("08731", "08734"), c("08901", "08005", "90210")),
    "incompatible"
  )
  expect_error(zip_distance_ng(bundle, "08731", "08901", units = "furlongs"))
  expect_error(zip_distance_ng(bundle, "08731", "08901", lonlat = NA), "lonlat")
  expect_identical(normalize_zip_ng(100000), "00010")
  expect_identical(normalize_zip_ng(c("99999-9999", NA)), c("99999", NA_character_))
})

test_that("next-generation searches use only the supplied bundle", {
  bundle <- make_test_bundle()
  expect_setequal(search_state_ng(bundle, "ak")$zipcode, c("99001", "99002", "99003", "99004"))
  expect_identical(search_city_ng(bundle, "east Edge", "ak")$zipcode, "99001")
  expect_true(all(search_fips_ng(bundle, "2")$state == "AK"))
  expect_error(search_fips_ng(bundle, "XX"), "digits")
  expect_error(search_fips_ng(bundle, "02", "not-a-code"), "digits")
  expect_identical(search_cd_ng(bundle, "34", "2")$ZIP, "08731")
  expect_error(search_cd_ng(bundle, "NJ", "2"), "digits")
})

test_that("vector searches preserve query order and duplicates", {
  bundle <- make_test_bundle()
  states <- search_state_ng(bundle, c("NJ", "AK", "NJ"))
  nj_count <- sum(bundle$zip_code_db$state == "NJ")
  ak_count <- sum(bundle$zip_code_db$state == "AK")
  expect_identical(
    states$state,
    c(rep("NJ", nj_count), rep("AK", ak_count), rep("NJ", nj_count))
  )

  zones <- bundle$zip_code_db$timezone[
    match(c("08731", "90210"), bundle$zip_code_db$zipcode)
  ]
  tz_result <- search_tz_ng(bundle, zones[c(2, 1, 2)])
  expected <- unlist(lapply(zones[c(2, 1, 2)], function(zone) {
    bundle$zip_code_db$zipcode[bundle$zip_code_db$timezone == zone]
  }), use.names = FALSE)
  expect_identical(tz_result$zipcode, expected)
  expect_warning(search_state_ng(bundle, c("NJ", "ZZ")), "ZZ")
  expect_error(search_state_ng(bundle, character()), "one or more")
  expect_error(search_county_ng(bundle, "Ocean", "NJ", surprise = TRUE), "Unknown")
})
