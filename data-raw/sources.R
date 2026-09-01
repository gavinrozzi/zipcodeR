# Source registry for the zipcodeR data pipeline.
#
# Every static source is pinned by URL and SHA256. When a source publisher
# updates a file in place (Census relationship files are stable; Gazetteer and
# GeoNames get new vintages), update the URL/sha256 here and record the change
# in the data release notes. The exact Census ACS response is also archived
# and checksummed; its endpoint, variables, geography, and vintage are pinned.

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
    # GeoNames regenerates this URL in place. Published releases therefore pin
    # and archive the exact downloaded bytes; a refresh requires a deliberate
    # checksum update and creates a new data version.
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

# Immutable legacy inputs used both as carry-forward data and as the
# compatibility-validation baseline. Rebuilds load these tracked files
# directly and verify their bytes; they never resolve a mutable git branch.
LEGACY_BASELINE_COMMIT <- "48ed689f4ee1694b1ec5fdffef02bed117938398"
LEGACY_BASELINE_FILES <- list(
  "zip_code_db.rda" = list(
    sha256 = "6ed347deb7cc958b0c9cb7d67f78d23ad33af867c4288838ec3eda1c40747e0d",
    license = "MIT (MacHu-GWU/uszipcode-project)"
  ),
  "zcta_crosswalk.rda" = list(
    sha256 = "cdf2befc7b34f327c608362935e719a10ac79249fb189b43a584e6d8b6b2b51c",
    license = "U.S. public domain (U.S. Census Bureau)"
  ),
  "zip_to_cd.rda" = list(
    sha256 = "4cf542a3b8692eee3110cdfb9f7dec0492fa6036a3f12d9019a209dd08f6f6ac",
    license = "U.S. public domain (HUD-USPS-derived relationship data)"
  )
)

# Internal package data used by the builder is pinned separately because it is
# not part of the public legacy-data contract, but a standalone rebuild still
# needs the exact vendored FIPS table stored in this file.
LEGACY_INTERNAL_FILES <- list(
  "R/sysdata.rda" = list(
    sha256 = "7b194f8dfb75f4739859991e6b2b2b15fcbc241c82d141e21c8165fd4cc8c84e",
    license = "U.S. public domain (U.S. Census Bureau)"
  )
)

# Refresh mode must not reuse an already-published identity. Add a version
# only after its public assets have been independently checksum-verified.
PUBLISHED_DATA_VERSIONS <- c("2026.08")

# The ACS request is archived and checksummed just like a static source. The
# endpoint and vintage document how a maintainer creates a deliberately new
# archive; deterministic rebuilds consume the archived bytes.
ACS_VINTAGE <- 2023 # ACS 5-year estimates, 2019-2023
ACS_ENDPOINT <- sprintf("https://api.census.gov/data/%d/acs/acs5", ACS_VINTAGE)
ACS_RESPONSE_SHA256 <- "e3abe3892e69d907d179a01f1c605372425cedaab59defba5e337770467db50c"
ACS_DERIVED_SHA256 <- "93579acf61ca194170990f720b1fbdc7e1d0d0dbf7696fa502e83633bd02deb4"
ACS_VARIABLES <- c(
  population = "B01003_001E",
  housing_units = "B25001_001E",
  occupied_housing_units = "B25002_002E",
  median_home_value = "B25077_001E",
  median_household_income = "B19013_001E"
)

# A published data identity is always explicit. Dates and aliases such as
# "latest" are deliberately rejected because the same research script must
# resolve to the same bytes indefinitely.
DATA_VERSION <- Sys.getenv("PIPELINE_DATA_VERSION")
if (!nzchar(DATA_VERSION)) {
  stop("PIPELINE_DATA_VERSION must be set to an explicit version such as 2026.08.")
}
if (DATA_VERSION %in% c("latest", "current", "stable")) {
  stop("PIPELINE_DATA_VERSION must be immutable, not an alias such as 'latest'.")
}

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
