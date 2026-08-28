###########################
# Helper functions tests #
##########################

test_that("normalize_zip handles messy character input", {
  expect_equal(
    normalize_zip(
      c("1", "10", "101", "3420", "34205", "943032", "2340594", "23495420", "999999999", NA)
    ),
    c("00001", "00010", "00101", "03420", "34205", "00094", "00234", "02349", "99999", NA)
  )
  expect_equal(
    normalize_zip(
      c("1", "10", "101", "3420", "34205", "3-4205", "94-3032", "234-0594", "2349-5420", "99999-9999", NA)
    ),
    c("00001", "00010", "00101", "03420", "34205", "00003", "00094", "00234", "02349", "99999", NA)
  )
})

test_that("normalize_zip handles numeric input with leading zero restoration", {
  expect_equal(
    normalize_zip(
      c(1, 10, 101, 3420, 34205, 943032, 2340594, 23495420, 999999999, NA)
    ),
    c("00001", "00010", "00101", "03420", "34205", "00094", "00234", "02349", "99999", NA)
  )
})

test_that("normalize_zip numeric boundary matches the character branch", {
  expect_equal(normalize_zip(100000), "00010")
  expect_equal(normalize_zip(100000), normalize_zip("100000"))
  expect_equal(normalize_zip(99999), "99999")
})

test_that("normalize_zip rejects non-character, non-numeric input", {
  expect_error(normalize_zip(NULL), "input must be character or numeric")
  expect_error(normalize_zip(list()), "input must be character or numeric")
})

test_that("zip_distance preserves input pairing and order (#20)", {
  # Reprex 1 from issue #20: the README example. Pre-0.3.4 the two
  # distances came back swapped between the pairs.
  result <- zip_distance(c("08731", "08734"), c("08901", "08005"))
  expect_equal(result$zipcode_a, c("08731", "08734"))
  expect_equal(result$zipcode_b, c("08901", "08005"))
  # 08731 -> 08901 is the long leg (~40mi), 08734 -> 08005 the short (~8mi)
  expect_gt(result$distance[1], 30)
  expect_lt(result$distance[2], 15)

  # Reprex 2 from issue #20: repeated values on one side
  result <- zip_distance(c("08731", "08731"), c("08731", "08005"))
  expect_equal(result$distance[1], 0)
  expect_gt(result$distance[2], 0)

  # Distance is symmetric and stable under row permutation
  ab <- zip_distance(c("08731", "90210"), c("08005", "10001"))
  ba <- zip_distance(c("90210", "08731"), c("10001", "08005"))
  expect_equal(ab$distance, rev(ba$distance))
})

test_that("zip_distance returns NA distance for ZIP codes without coordinates", {
  # PO Box-type ZIPs have no lat/lng in zip_code_db
  no_coords <- zip_code_db$zipcode[is.na(zip_code_db$lat)][1]
  result <- zip_distance(no_coords, "08731")
  expect_equal(nrow(result), 1)
  expect_true(is.na(result$distance))
})

test_that("zip_distance recycles divisible input lengths like data.frame()", {
  result <- zip_distance(c("08731", "08734"), c("08901", "08005", "07762", "08731"))
  expect_equal(nrow(result), 4)
  expect_equal(result$zipcode_a, c("08731", "08734", "08731", "08734"))
  expect_error(zip_distance(c("08731", "08734"), c("08901", "08005", "07762")), "length")
})

test_that("zip_distance supports meters and planar mode arguments", {
  miles <- zip_distance("08731", "08901")
  meters <- zip_distance("08731", "08901", units = "meters")
  expect_equal(miles$distance, round(meters$distance * 0.000621371, 2), tolerance = 0.01)
  # lonlat = FALSE is deprecated; it now returns a planar approximation in
  # real units (historically a unit bug made it return ~0 for every pair)
  expect_warning(
    planar <- zip_distance("08731", "08901", lonlat = FALSE),
    "deprecated"
  )
  expect_equal(planar$distance, miles$distance, tolerance = 0.02)
  # antimeridian pair (Guam -> Adak): the wrapped longitude difference keeps
  # the planar approximation in the same ballpark as the great circle
  gc <- zip_distance("96910", "99546")
  expect_warning(
    planar_am <- zip_distance("96910", "99546", lonlat = FALSE),
    "deprecated"
  )
  expect_lt(abs(planar_am$distance - gc$distance) / gc$distance, 0.35)
})

test_that("every available SHA256 backend returns a plain, comparable hash", {
  # The hashes are compared with identical(), so a backend that returns an
  # equal-looking but classed string (openssl's hash objects do) would reject
  # a correct download as corrupted
  path <- tempfile()
  on.exit(unlink(path), add = TRUE)
  # writeBin, not writeLines: text-mode writes translate the newline on
  # Windows and would change the hash
  writeBin(charToRaw("zipcodeR checksum fixture\n"), path)
  expected <- "b9b1a4801eda57c56674d2f00f853e5fad6060c1bc50b345fa8c578f7d543697"

  expect_identical(file_sha256(path), expected)
  if (requireNamespace("openssl", quietly = TRUE)) {
    expect_identical(sha256_openssl(path), expected)
  }
  if (any(nzchar(Sys.which(c("shasum", "sha256sum"))))) {
    expect_identical(sha256_system(path), expected)
  }
})
