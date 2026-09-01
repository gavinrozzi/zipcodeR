test_that("bundle files are schema- and checksum-validated", {
  bundle <- make_test_bundle()
  path <- tempfile(fileext = ".rds")
  saveRDS(bundle, path, version = 3)
  sha <- zipcodeR:::file_sha256(path)

  loaded <- read_zip_data_bundle(path, sha256 = sha)
  expect_s3_class(loaded, "zipcodeR_data_bundle")
  expect_identical(attr(loaded, "bundle_sha256"), sha)
  expect_identical(zip_data_version(loaded)$data_version, "test-2026.08")

  con <- file(path, open = "ab")
  writeBin(as.raw(0), con)
  close(con)
  expect_error(read_zip_data_bundle(path, sha256 = sha), "Checksum verification failed")
})

test_that("malformed bundles and version aliases are rejected", {
  bundle <- make_test_bundle()
  bundle$quality <- data.frame(nope = "x")
  expect_error(zipcodeR:::validate_zip_data_bundle(bundle), "quality")

  bundle <- make_test_bundle()
  bundle$zcta_crosswalk$GEOID <- as.numeric(bundle$zcta_crosswalk$GEOID)
  expect_error(zipcodeR:::validate_zip_data_bundle(bundle), "types")

  expect_error(download_zip_data_bundle("latest"), "Aliases")
  expect_error(download_zip_data_bundle("not-registered"), "Unknown")
})

test_that("release manifest tampering is rejected", {
  bundle <- make_test_bundle()
  asset <- tempfile(pattern = "zipcodeR-data-", fileext = ".rds")
  saveRDS(bundle, asset, version = 3)
  manifest <- list(
    data_version = bundle$metadata$data_version,
    asset = basename(asset),
    asset_sha256 = zipcodeR:::file_sha256(asset),
    rows = list(
      zip_code_db = nrow(bundle$zip_code_db),
      zcta_crosswalk = nrow(bundle$zcta_crosswalk),
      zip_to_cd = nrow(bundle$zip_to_cd)
    ),
    schemas = list(
      zip_code_db = lapply(names(bundle$zip_code_db), function(name) {
        list(name = name, type = class(bundle$zip_code_db[[name]])[1])
      }),
      zcta_crosswalk = lapply(names(bundle$zcta_crosswalk), function(name) {
        list(name = name, type = class(bundle$zcta_crosswalk[[name]])[1])
      }),
      zip_to_cd = lapply(names(bundle$zip_to_cd), function(name) {
        list(name = name, type = class(bundle$zip_to_cd[[name]])[1])
      })
    ),
    sources = list(list(id = "fixture", sha256 = paste(rep("6", 64), collapse = ""))),
    output_hashes = bundle$metadata$output_hashes,
    pipeline_commit = "fixture",
    r_version = R.version.string,
    dependency_lock_sha256 = paste(rep("7", 64), collapse = "")
  )
  manifest_path <- tempfile(fileext = ".json")
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE)
  expect_s3_class(
    zipcodeR:::validate_zip_data_release_manifest(manifest_path, asset),
    "zipcodeR_data_bundle"
  )

  pinned_manifest_sha <- zipcodeR:::file_sha256(manifest_path)
  manifest$rows$zip_code_db <- manifest$rows$zip_code_db + 1L
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE)
  expect_error(
    zipcodeR:::validate_zip_data_release_manifest(
      manifest_path, asset, manifest_sha256 = pinned_manifest_sha
    ),
    "Manifest checksum"
  )
  expect_error(
    zipcodeR:::validate_zip_data_release_manifest(manifest_path, asset),
    "row counts"
  )
})

test_that("provenance can be selected by dataset and key", {
  bundle <- make_test_bundle()
  result <- zip_data_provenance(bundle, "zip_to_cd", "08731")
  expect_equal(nrow(result), 1L)
  expect_identical(result$source_id, "test_cd")
  expect_error(zip_data_provenance(bundle, "made_up"), "Unknown")
})

test_that("verified cache works offline and corrupt cache is replaced atomically", {
  bundle <- make_test_bundle()
  source <- tempfile(fileext = ".rds")
  saveRDS(bundle, source, version = 3)
  sha <- zipcodeR:::file_sha256(source)
  cache <- tempfile("bundle-cache-")
  dir.create(cache)
  meta <- list(
    version = "test-2026.08", asset = "bundle.rds",
    url = "test://bundle", sha256 = sha
  )
  file.copy(source, file.path(cache, meta$asset))

  testthat::local_mocked_bindings(
    zipcodeR_has_internet = function() stop("network should not be consulted"),
    .package = "zipcodeR"
  )
  expect_s3_class(
    zipcodeR:::download_zip_data_bundle_from(meta, FALSE, cache),
    "zipcodeR_data_bundle"
  )
})

test_that("offline, corrupt, and interrupted downloads cannot become cache hits", {
  bundle <- make_test_bundle()
  source <- tempfile(fileext = ".rds")
  saveRDS(bundle, source, version = 3)
  sha <- zipcodeR:::file_sha256(source)
  meta <- list(
    version = "test-2026.08", asset = "bundle.rds",
    url = "test://bundle", sha256 = sha
  )

  offline_cache <- tempfile("offline-cache-")
  dir.create(offline_cache)
  testthat::local_mocked_bindings(
    zipcodeR_has_internet = function() FALSE,
    .package = "zipcodeR"
  )
  expect_error(
    zipcodeR:::download_zip_data_bundle_from(meta, FALSE, offline_cache),
    "No internet connection"
  )
  expect_false(file.exists(file.path(offline_cache, meta$asset)))

  testthat::local_mocked_bindings(
    zipcodeR_has_internet = function() TRUE,
    download_zip_data_file = function(url, path) {
      writeBin(as.raw(c(1, 2, 3)), path)
      stop("simulated interruption")
    },
    .package = "zipcodeR"
  )
  expect_error(
    zipcodeR:::download_zip_data_bundle_from(meta, FALSE, offline_cache),
    "simulated interruption"
  )
  expect_false(file.exists(file.path(offline_cache, meta$asset)))

  writeBin(as.raw(c(9, 9, 9)), file.path(offline_cache, meta$asset))
  testthat::local_mocked_bindings(
    zipcodeR_has_internet = function() TRUE,
    download_zip_data_file = function(url, path) file.copy(source, path),
    .package = "zipcodeR"
  )
  expect_message(
    loaded <- zipcodeR:::download_zip_data_bundle_from(meta, FALSE, offline_cache),
    "failed checksum"
  )
  expect_s3_class(loaded, "zipcodeR_data_bundle")
  expect_identical(zipcodeR:::file_sha256(file.path(offline_cache, meta$asset)), sha)
})

test_that("Windows SHA selection excludes batch wrappers", {
  bins <- c(sha256sum = "C:/tools/sha256sum.exe", shasum = "C:/Strawberry/shasum.bat")
  expect_identical(
    zipcodeR:::sha256_system_binary("windows", bins),
    "C:/tools/sha256sum.exe"
  )
  expect_length(
    zipcodeR:::sha256_system_binary("windows", c(shasum = "C:/Strawberry/shasum.bat")),
    0L
  )
})

test_that("published registries pin the independently verified assets", {
  bundle_meta <- zipcodeR:::registered_zip_data_bundle("2026.08")
  expect_identical(
    bundle_meta$sha256,
    "9059026c159a4d1311ad9c61ba5193a6123299503efb5d867b8303c9d23627e4"
  )
  expect_match(bundle_meta$url, "/data-2026.08/zipcodeR-data-2026.08\\.rds$")

  comprehensive_meta <- zipcodeR:::comprehensive_data_registry()
  expect_true(comprehensive_meta$published)
  expect_identical(
    comprehensive_meta$sha256,
    "d85ed4e25884bc27bdd339d57dd9e2d1763531d4c050acb7a05a3d5aca90668d"
  )

  cache <- tempfile("comprehensive-cache-")
  dir.create(cache)
  cached_file <- file.path(cache, comprehensive_meta$asset)
  writeBin(as.raw(1), cached_file)
  testthat::local_mocked_bindings(
    zipcodeR_user_data_dir = function() cache,
    file_sha256 = function(path) comprehensive_meta$sha256,
    ensure_sha256_available = function() invisible(TRUE),
    .package = "zipcodeR"
  )
  expect_message(
    result <- download_comprehensive_data(),
    "using cached comprehensive database"
  )
  expect_identical(result, cached_file)
})
