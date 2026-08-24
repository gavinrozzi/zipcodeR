# Source registry for the zipcodeR data pipeline.
#
# Every static source is pinned by URL and SHA256. When a source publisher
# updates a file in place (Census relationship files are stable; Gazetteer and
# GeoNames get new vintages), update the URL/sha256 here and record the change
# in the data release notes. API sources (Census ACS) cannot be checksummed;
# their vintage is pinned via the endpoint year.

PIPELINE_SOURCES <- list(
  zcta_tract_rel = list(
    description = "Census 2020 ZCTA-to-tract national relationship file",
    url = "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_tract20_natl.txt",
    sha256 = "6a25d8c3fff4cf612c4d2dccc2c0cd6cb5bc99b807ff3d5d107a2e9b9d68dde0",
    license = "U.S. public domain (U.S. Census Bureau)"
  ),
  zcta_county_rel = list(
    description = "Census 2020 ZCTA-to-county national relationship file",
    url = "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt",
    sha256 = "3ed41278d637dc249e0323306f68be8a6c234e3090f4de88ef328dee71aeaaaf",
    license = "U.S. public domain (U.S. Census Bureau)"
  ),
  cd_zcta_rel = list(
    description = "Census 119th Congressional District-to-ZCTA national relationship file",
    url = "https://www2.census.gov/geo/docs/maps-data/data/rel2020/cd-sld/tab20_cd11920_zcta520_natl.txt",
    sha256 = "57fad59f65af5179ddd18dcfb8f72482dc0cf04fe26e2b9b2b34c51c04405f77",
    license = "U.S. public domain (U.S. Census Bureau)"
  ),
  gazetteer_zcta = list(
    description = "Census 2024 Gazetteer, national ZCTA file (2020 ZCTAs)",
    url = "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2024_Gazetteer/2024_Gaz_zcta_national.zip",
    sha256 = "7b85c04a131672f58b38a950eb82855d5fd4054f0bd9bc3f69aa28897a714e3d",
    license = "U.S. public domain (U.S. Census Bureau)"
  ),
  geonames_us = list(
    description = "GeoNames U.S. postal codes (place names, admin areas, coordinates)",
    url = "https://download.geonames.org/export/zip/US.zip",
    # GeoNames regenerates this file in place (near-daily), so its checksum
    # cannot be enforced without breaking every scheduled refresh. floating =
    # TRUE makes 01_acquire.R RECORD the downloaded hash (in the acquire log
    # and refresh summary) instead of failing on mismatch; the hash below is
    # the one from the 2026.08 build, kept for provenance.
    floating = TRUE,
    sha256 = "34bf4144bf1231c2da500127bbbf7020920bb4331de403b5d850b77f45a8f509",
    license = "CC BY 4.0 (GeoNames) - attribution required, kept in data docs"
  ),
  uszipcode_simple_101 = list(
    description = "uszipcode-project 1.0.1 simple_db.sqlite (validation reference + row source for post-2021-06 additions)",
    url = "https://github.com/MacHu-GWU/uszipcode-project/releases/download/1.0.1.db/simple_db.sqlite",
    sha256 = "43383f108ef14dccd925107bc77705f622b1014111ad5c9e5e2a6837bb7f64ff",
    license = "MIT (MacHu-GWU/uszipcode-project) - attribution kept in data docs"
  )
)

# API-based sources (no checksum possible; vintage pinned by endpoint)
ACS_VINTAGE <- 2023 # ACS 5-year estimates, 2019-2023
ACS_ENDPOINT <- sprintf("https://api.census.gov/data/%d/acs/acs5", ACS_VINTAGE)
ACS_VARIABLES <- c(
  population = "B01003_001E",
  housing_units = "B25001_001E",
  occupied_housing_units = "B25002_002E",
  median_home_value = "B25077_001E",
  median_household_income = "B19013_001E"
)

# Data release identity. Derived from the build date so scheduled refreshes
# stamp a new version automatically; override with PIPELINE_DATA_VERSION for
# a rebuild of an existing release.
DATA_VERSION <- Sys.getenv("PIPELINE_DATA_VERSION", format(Sys.Date(), "%Y.%m"))

# The comprehensive-database release asset that download_comprehensive_data()
# should fetch. This is pinned EXPLICITLY - not derived from DATA_VERSION -
# because the comprehensive asset is republished less often than the bundled
# data refreshes. When (and only when) a new comprehensive asset is uploaded
# to a data release, update all three fields together; 05_validate.R checks
# their consistency.
COMPREHENSIVE_RELEASE <- list(
  release_tag = "data-2026.08",
  asset = "comprehensive_db.sqlite",
  sha256 = "d85ed4e25884bc27bdd339d57dd9e2d1763531d4c050acb7a05a3d5aca90668d"
)

# One-time accepted loss of congressional-district coverage for the 2026.08
# rebuild: the USPS-only ZIPs enumerated in accepted_cd_coverage_loss.txt
# were mapped by the old pre-2020 HUD crosswalk but have no principled
# current-vintage derivation (no ZCTA, no covered same-city peer,
# multi-district state). Their stale district numbers were deliberately NOT
# carried forward (see NEWS 0.4.0); the planned HUD-USPS stage restores them
# with current data. The gate accepts losing ONLY the ZIPs on this exact
# list - any other coverage loss fails - so the acceptance cannot mask a
# future regression. Empty the file after the 2026.08 release ships.
ACCEPTED_CD_COVERAGE_LOSS_FILE <- file.path("data-raw", "accepted_cd_coverage_loss.txt")
