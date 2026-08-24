# Step 3: build the refreshed zcta_crosswalk (2020 ZCTA <-> 2020 tract) in
# the exact schema of the shipped dataset: tibble(ZCTA5 chr, TRACT chr(6),
# GEOID numeric(11-digit state+county+tract)).

suppressMessages(library(dplyr))
cache_dir <- file.path("data-raw", "cache")

rel <- utils::read.delim(
  file.path(cache_dir, "tab20_zcta520_tract20_natl.txt"),
  sep = "|", fileEncoding = "UTF-8-BOM",
  colClasses = c(GEOID_ZCTA5_20 = "character", GEOID_TRACT_20 = "character")
)

zcta_crosswalk_new <- rel %>%
  filter(.data$GEOID_ZCTA5_20 != "") %>%
  transmute(
    ZCTA5 = .data$GEOID_ZCTA5_20,
    TRACT = substr(.data$GEOID_TRACT_20, 6, 11),
    GEOID = as.numeric(.data$GEOID_TRACT_20)
  ) %>%
  distinct() %>%
  arrange(.data$ZCTA5, .data$GEOID) %>%
  as_tibble()

saveRDS(zcta_crosswalk_new, file.path(cache_dir, "zcta_crosswalk_candidate.rds"))
message("zcta_crosswalk candidate: ", nrow(zcta_crosswalk_new), " rows (2020 vintage)")
