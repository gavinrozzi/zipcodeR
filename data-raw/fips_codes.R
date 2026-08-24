# Regenerate the internal `fips_codes` table bundled in R/sysdata.rda
#
# Provenance: U.S. Census Bureau state and county FIPS codes (public
# domain), as compiled in the `tidycensus` package (MIT license, Kyle
# Walker), which builds the table from the Census reference files at
# https://www.census.gov/library/reference/code-lists/ansi.html
#
# zipcodeR previously depended on the whole tidycensus package (and its
# sf/GDAL dependency chain) solely to read this static 3,256-row table.
# It is now vendored as internal data. Re-run this script to refresh it,
# then rebuild the package.
#
# Requires: tidycensus (only at data-build time, never at runtime)

fips_codes <- tidycensus::fips_codes
stopifnot(
  is.data.frame(fips_codes),
  identical(
    names(fips_codes),
    c("state", "state_code", "state_name", "county_code", "county")
  ),
  nrow(fips_codes) > 3000
)

# sysdata.rda carries other internal objects (zip_code_db_version,
# zip_data_meta, ...); load them all and re-save everything so nothing is
# silently dropped
sysdata_env <- new.env()
load(file.path("R", "sysdata.rda"), envir = sysdata_env)
assign("fips_codes", fips_codes, envir = sysdata_env)
save(
  list = ls(sysdata_env),
  envir = sysdata_env,
  file = file.path("R", "sysdata.rda"),
  compress = "bzip2"
)
