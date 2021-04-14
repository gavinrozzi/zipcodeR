###########################
# Helper functions tests #
##########################

testthat::expect_equal(
  normalize_zip(
    c("1", "10", "101", "3420", "34205", "943032", "2340594", "23495420", "999999999", NA)
  ),
  c("00001", "00010", "00101", "03420", "34205", "00094", "00234", "02349", "99999", NA)
)
testthat::expect_equal(
  normalize_zip(
    c("1", "10", "101", "3420", "34205", "3-4205", "94-3032", "234-0594", "2349-5420", "99999-9999", NA)
  ),
  c("00001", "00010", "00101", "03420", "34205", "00003", "00094", "00234", "02349", "99999", NA)
)
testthat::expect_equal(
  normalize_zip(
    c(1, 10, 101, 3420, 34205, 943032, 2340594, 23495420, 999999999, NA)
  ),
  c("00001", "00010", "00101", "03420", "34205", "00094", "00234", "02349", "99999", NA)
)
# check that wrong input generates errors
testthat::expect_error(
  normalize_zip(NULL),
  "input must be character or numeric"
)
testthat::expect_error(
  normalize_zip(list()),
  "input must be character or numeric"
)
