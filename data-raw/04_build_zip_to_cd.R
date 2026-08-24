# Step 4: build the refreshed zip_to_cd (ZIP <-> 119th-Congress district) in
# the exact schema of the shipped dataset: data.frame(ZIP chr, CD chr(4) =
# state FIPS + 2-digit district), multiple rows for multi-district ZIPs.
#
# Method follows PR #30 by @awallender (which used the CD118 vintage),
# updated to the 119th-Congress relationship file.

suppressMessages(library(dplyr))
cache_dir <- file.path("data-raw", "cache")

rel <- utils::read.delim(
  file.path(cache_dir, "tab20_cd11920_zcta520_natl.txt"),
  sep = "|", fileEncoding = "UTF-8-BOM",
  colClasses = c(GEOID_CD119_20 = "character", GEOID_ZCTA5_20 = "character")
)

zip_to_cd_new <- rel %>%
  filter(.data$GEOID_ZCTA5_20 != "", .data$GEOID_CD119_20 != "") %>%
  transmute(ZIP = .data$GEOID_ZCTA5_20, CD = .data$GEOID_CD119_20) %>%
  distinct() %>%
  arrange(.data$ZIP, .data$CD) %>%
  as.data.frame()

saveRDS(zip_to_cd_new, file.path(cache_dir, "zip_to_cd_candidate.rds"))
message("zip_to_cd candidate: ", nrow(zip_to_cd_new), " rows (CD119 vintage)")
