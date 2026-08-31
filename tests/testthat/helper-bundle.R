make_test_bundle <- function() {
  ns <- asNamespace("zipcodeR")
  legacy_db <- get("zip_code_db", ns)
  wanted <- c("08731", "08901", "08734", "08005", "90210")
  db <- legacy_db[match(wanted, legacy_db$zipcode), , drop = FALSE]

  synthetic <- db[rep(1L, 4L), , drop = FALSE]
  synthetic$zipcode <- c("99001", "99002", "99003", "99004")
  synthetic$state <- c("AK", "AK", "AK", "AK")
  synthetic$county <- c("Test County", "Test County", "Test County", "Test County")
  synthetic$major_city <- c("East Edge", "West Edge", "Far Point", "No Point")
  synthetic$lat <- c(0, 0, 0, NA_real_)
  synthetic$lng <- c(179.9, -179.9, 0, NA_real_)
  db <- rbind(db, synthetic)
  rownames(db) <- NULL

  zcta <- data.frame(
    ZCTA5 = c("08731", "08731", "90210", "99001", "99002"),
    TRACT = c("010100", "010200", "700100", "000100", "000200"),
    GEOID = c(
      "34029010100", "34029010200", "06037700100",
      "02013000100", "02013000200"
    ),
    stringsAsFactors = FALSE
  )
  cd <- data.frame(
    ZIP = c("08731", "08731", "90210", "99001"),
    CD = c("3402", "3404", "0636", "0200"),
    stringsAsFactors = FALSE
  )
  provenance <- data.frame(
    dataset = c("zip_code_db", "zip_to_cd"),
    key = c("08731", "08731"),
    field = c("coordinates", "record"),
    source_id = c("test_gazetteer", "test_cd"),
    method = c("test fixture", "authoritative relationship"),
    quality = c("authoritative_source", "authoritative_source"),
    note = c("", ""),
    stringsAsFactors = FALSE
  )
  quality <- data.frame(
    dataset = "zip_to_cd",
    key = "99004",
    field = "CD",
    status = "unmapped",
    reason = "No authoritative relationship in test fixture",
    stringsAsFactors = FALSE
  )
  structure(
    list(
      zip_code_db = db,
      zcta_crosswalk = zcta,
      zip_to_cd = cd,
      metadata = list(
        data_version = "test-2026.08",
        build_timestamp = "2026-08-24T00:00:00Z",
        output_hashes = list(
          zip_code_db = paste(rep("1", 64), collapse = ""),
          zcta_crosswalk = paste(rep("2", 64), collapse = ""),
          zip_to_cd = paste(rep("3", 64), collapse = ""),
          provenance = paste(rep("4", 64), collapse = ""),
          quality = paste(rep("5", 64), collapse = "")
        )
      ),
      provenance = provenance,
      quality = quality
    ),
    class = c("zipcodeR_data_bundle", "list"),
    bundle_sha256 = paste(rep("a", 64), collapse = "")
  )
}
