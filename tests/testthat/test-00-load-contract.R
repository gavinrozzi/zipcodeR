test_that("legacy spatial namespaces are not eagerly imported", {
  namespace <- readLines(system.file("NAMESPACE", package = "zipcodeR"))
  expect_false(any(grepl("^import\\(tidycensus\\)$", namespace)))
  expect_false(any(grepl("^importFrom\\(raster,", namespace)))
})
