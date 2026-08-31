# Orchestrator for the zipcodeR data pipeline. Run from the package root:
#
#   PIPELINE_MODE=rebuild PIPELINE_DATA_VERSION=2026.08 \
#     PIPELINE_BUILD_TIMESTAMP=2026-08-24T00:00:00Z \
#     Rscript data-raw/run_pipeline.R
#
# See data-raw/README.md. CENSUS_API_KEY is needed only when the archived raw
# ACS response is absent.

if (!identical(Sys.getenv("PIPELINE_MODE"), "rebuild")) {
  stop(
    "run_pipeline.R only performs deterministic rebuilds. Set ",
    "PIPELINE_MODE=rebuild, or run data-raw/refresh_sources.R to inspect ",
    "upstream sources for a future version."
  )
}

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
message("pipeline complete. Review data-raw/refresh_summary.md and data-raw/release/.")
