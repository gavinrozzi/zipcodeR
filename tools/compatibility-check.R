#!/usr/bin/env Rscript

# Install the frozen baseline and the candidate into isolated libraries, run
# the same calls in separate R processes, and require byte-level R-object
# identity. This intentionally compares conditions as well as return values.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
repo <- if (length(file_arg)) {
  normalizePath(file.path(dirname(sub("^--file=", "", file_arg[[1]])), ".."))
} else {
  normalizePath(".")
}
cli_args <- commandArgs(trailingOnly = TRUE)
baseline_arg <- grep("^--baseline-ref=", cli_args, value = TRUE)
baseline_ref <- if (length(baseline_arg)) {
  sub("^--baseline-ref=", "", baseline_arg[[1]])
} else {
  Sys.getenv("ZIPCODER_BASELINE_REF", "master")
}
if (!nzchar(baseline_ref)) stop("The baseline git ref must not be empty.")
keep <- identical(Sys.getenv("KEEP_COMPAT_ARTIFACTS"), "true")
root <- tempfile("zipcodeR-compat-")
dir.create(root)
if (!keep) on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)

base_src <- file.path(root, "baseline-source")
base_lib <- file.path(root, "baseline-library")
candidate_lib <- file.path(root, "candidate-library")
dir.create(base_src)
dir.create(base_lib)
dir.create(candidate_lib)

archive <- file.path(root, "baseline.tar")
archive_log <- file.path(root, "baseline-archive.log")
status <- system2(
  "git", c("-C", shQuote(repo), "archive", "--format=tar", baseline_ref),
  stdout = archive, stderr = archive_log
)
if (!identical(status, 0L)) {
  cat(readLines(archive_log, warn = FALSE), sep = "\n")
  stop("Could not archive baseline git ref '", baseline_ref, "'.")
}
utils::untar(archive, exdir = base_src)

install_one <- function(source, library, log) {
  r_bin <- file.path(R.home("bin"), "R")
  status <- system2(
    r_bin,
    c("CMD", "INSTALL", "--no-multiarch", "--with-keep.source",
      "-l", shQuote(library), shQuote(source)),
    stdout = log, stderr = log
  )
  if (!identical(status, 0L)) {
    cat(readLines(log, warn = FALSE), sep = "\n")
    stop("Package installation failed; see ", log)
  }
}

install_one(base_src, base_lib, file.path(root, "baseline-install.log"))
install_one(repo, candidate_lib, file.path(root, "candidate-install.log"))

worker <- file.path(root, "worker.R")
writeLines(c(
  "args <- commandArgs(trailingOnly = TRUE)",
  "lib <- args[[1]]; output <- args[[2]]",
  "suppressPackageStartupMessages(library(zipcodeR, lib.loc = lib))",
  "capture_call <- function(expr) {",
  "  conditions <- list()",
  "  add_condition <- function(kind, condition) {",
  "    conditions[[length(conditions) + 1L]] <<- list(",
  "      kind = kind, class = class(condition),",
  "      message = conditionMessage(condition),",
  "      call = paste(deparse(conditionCall(condition)), collapse = ' ')",
  "    )",
  "  }",
  "  result <- withCallingHandlers(",
  "    tryCatch(",
  "      list(ok = TRUE, value = eval(expr, envir = .GlobalEnv)),",
  "      error = function(e) { add_condition('error', e); list(ok = FALSE) }",
  "    ),",
  "    warning = function(w) { add_condition('warning', w); invokeRestart('muffleWarning') },",
  "    message = function(m) { add_condition('message', m); invokeRestart('muffleMessage') }",
  "  )",
  "  list(result = result, conditions = conditions)",
  "}",
  "cases <- list(",
  "  state_one = quote(search_state('NJ')),",
  "  state_vector = quote(search_state(c('NJ', 'NY', 'CT'))),",
  "  state_invalid = quote(search_state('XY')),",
  "  county = quote(search_county('Ocean', 'NJ')),",
  "  county_similar = quote(search_county('ST BERNARD', 'LA', similar = TRUE, max.distance = 0.5)),",
  "  county_invalid = quote(search_county('Kenosha', 'NJ')),",
  "  city = quote(search_city('wayne', 'nj')),",
  "  city_invalid = quote(search_city('anytown', 'NJ')),",
  "  timezone = quote(search_tz('Mountain')),",
  "  timezone_invalid = quote(search_tz('Western')),",
  "  fips_state = quote(search_fips('34')),",
  "  fips_county = quote(search_fips('34', '3')),",
  "  fips_invalid = quote(search_fips('99')),",
  "  tracts = quote(get_tracts('08731')),",
  "  tracts_invalid = quote(get_tracts('999999')),",
  "  cd = quote(get_cd('08731')),",
  "  cd_cross_state = quote(get_cd('02861')),",
  "  cd_missing = quote(get_cd('99999')),",
  "  search_cd = quote(search_cd('34', '03')),",
  "  zcta_vector = quote(is_zcta(c('07762', '08999', NA))),",
  "  reverse_one = quote(reverse_zipcode('08731')),",
  "  reverse_duplicates = quote(reverse_zipcode(c('08731', '08999', '08731'))),",
  "  reverse_bad_width = quote(reverse_zipcode('099999')),",
  "  reverse_na = quote(reverse_zipcode(NA)),",
  "  reverse_empty = quote(reverse_zipcode()),",
  "  geocode_one = quote(geocode_zip('08731')),",
  "  geocode_vector = quote(geocode_zip(c('08731', '08721', '08731'))),",
  "  geocode_missing = quote(geocode_zip(c('08731', '99999'))),",
  "  geocode_all_missing = quote(geocode_zip('99999')),",
  "  radius_nj = quote(search_radius(39.9, -74.3, 10)),",
  "  radius_nyc = quote(search_radius(40.7128, -74.0060, 25)),",
  "  radius_la = quote(search_radius(34.0522, -118.2437, 50)),",
  "  radius_antimeridian = quote(search_radius(52, 179.5, 500)),",
  "  radius_zero = quote(search_radius(39.9, -74.3, 0)),",
  "  radius_empty = quote(search_radius(0, 0, 1)),",
  "  radius_negative = quote(search_radius(39.9, -74.3, -1)),",
  "  normalize_character = quote(normalize_zip(c('1', '99999-9999', NA))),",
  "  normalize_numeric = quote(normalize_zip(c(1, 100000, NA))),",
  "  normalize_null = quote(normalize_zip(NULL)),",
  "  distance = quote(zip_distance('08731', '08901')),",
  "  distance_vector = quote(zip_distance(c('08731', '08734'), c('08901', '08005'))),",
  "  distance_planar = quote(zip_distance('08731', '08901', lonlat = FALSE)),",
  "  distance_invalid_units = quote(zip_distance('08731', '08901', units = 'furlongs'))",
  ")",
  "ns <- asNamespace('zipcodeR')",
  "exports <- getNamespaceExports('zipcodeR')",
  "functions <- exports[vapply(exports, function(x) is.function(get(x, ns)), logical(1))]",
  "functions <- stats::setNames(functions, functions)",
  "out <- list(",
  "  datasets = list(",
  "    zip_code_db = get('zip_code_db', ns),",
  "    zcta_crosswalk = get('zcta_crosswalk', ns),",
  "    zip_to_cd = get('zip_to_cd', ns)",
  "  ),",
  "  cases = lapply(cases, capture_call),",
  "  formals = lapply(functions, function(x) formals(get(x, ns))),",
  "  download_zip_data_body = deparse(body(get('download_zip_data', ns)))",
  ")",
  "saveRDS(out, output, version = 2)"
), worker)

run_worker <- function(library, output, log) {
  rscript <- file.path(R.home("bin"), "Rscript")
  status <- system2(
    rscript, c(shQuote(worker), shQuote(library), shQuote(output)),
    stdout = log, stderr = log
  )
  if (!identical(status, 0L)) {
    cat(readLines(log, warn = FALSE), sep = "\n")
    stop("Compatibility worker failed; see ", log)
  }
}

base_output <- file.path(root, "baseline.rds")
candidate_output <- file.path(root, "candidate.rds")
run_worker(base_lib, base_output, file.path(root, "baseline-worker.log"))
run_worker(candidate_lib, candidate_output, file.path(root, "candidate-worker.log"))
baseline <- readRDS(base_output)
candidate <- readRDS(candidate_output)

failures <- character()
check_identical <- function(label, x, y) {
  if (!identical(x, y)) {
    failures <<- c(failures, label)
    cat("FAIL: ", label, "\n", sep = "")
    print(all.equal(x, y, tolerance = 0, check.attributes = TRUE))
  } else {
    cat("PASS: ", label, "\n", sep = "")
  }
}

for (name in names(baseline$datasets)) {
  check_identical(paste0("dataset ", name), baseline$datasets[[name]], candidate$datasets[[name]])
}
for (name in names(baseline$cases)) {
  check_identical(paste0("call ", name), baseline$cases[[name]], candidate$cases[[name]])
}
for (name in names(baseline$formals)) {
  check_identical(paste0("formals ", name), baseline$formals[[name]], candidate$formals[[name]])
}
check_identical(
  "download_zip_data implementation",
  baseline$download_zip_data_body,
  candidate$download_zip_data_body
)

if (length(failures)) {
  if (keep) cat("Artifacts retained at: ", root, "\n", sep = "")
  stop("Legacy compatibility failed for ", length(failures), " comparison(s).")
}
cat("Legacy compatibility passed: all datasets, calls, conditions, and formals are identical.\n")
if (keep) cat("Artifacts retained at: ", root, "\n", sep = "")
