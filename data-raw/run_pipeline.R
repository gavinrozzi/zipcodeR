# Orchestrator for the zipcodeR data pipeline. Run from the package root:
#
#   Rscript data-raw/run_pipeline.R
#
# Requires: CENSUS_API_KEY in the environment (free registration at
# https://api.census.gov/data/key_signup.html). See data-raw/README.md.

steps <- c(
  "01_acquire.R",
  "02_build_zip_code_db.R",
  "03_build_zcta_crosswalk.R",
  "04_build_zip_to_cd.R",
  "05_validate.R",
  "06_finalize.R"
)
for (step in steps) {
  message("== ", step, " ==")
  source(file.path("data-raw", step))
}
message("pipeline complete. Review data-raw/refresh_summary.md and the git diff.")
