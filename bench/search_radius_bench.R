# Benchmark for search_radius() (issue #33).
# Run from the package root: Rscript bench/search_radius_bench.R
#
# Compares three implementations against the bundled zip_code_db:
#   loop       - the pre-0.4.0 implementation (per-row distance calls)
#   vectorized - one haversine pass over all ~34k coordinate rows
#   boxed      - 0.4.0+: bounding-box prefilter, then haversine on candidates

suppressMessages(devtools::load_all(quiet = TRUE))
hav <- zipcodeR:::haversine_distance

zip_data_all <- zip_code_db[!is.na(zip_code_db$lat) & !is.na(zip_code_db$lng), ]

loop_impl <- function(lat, lng, radius = 1) {
  zip_data <- zip_data_all
  zip_data$distance <- NA_real_
  for (i in seq_len(nrow(zip_data))) {
    zip_data$distance[i] <- hav(zip_data$lat[i], zip_data$lng[i], lat, lng) * 0.000621371
  }
  zip_data <- zip_data[zip_data$distance <= radius, c("zipcode", "distance")]
  zip_data[order(zip_data$distance), ]
}

vectorized_impl <- function(lat, lng, radius = 1) {
  zip_data <- zip_data_all
  zip_data$distance <- hav(zip_data$lat, zip_data$lng, lat, lng) * 0.000621371
  zip_data <- zip_data[zip_data$distance <= radius, c("zipcode", "distance")]
  zip_data[order(zip_data$distance), ]
}

cases <- list(
  suburban_10mi = list(lat = 39.9, lng = -74.3, radius = 10),
  urban_25mi = list(lat = 40.71, lng = -74.01, radius = 25),
  rural_50mi = list(lat = 44.5, lng = -110.0, radius = 50)
)

for (nm in names(cases)) {
  cs <- cases[[nm]]
  # correctness: boxed must return the same set as the full vectorized pass
  full <- vectorized_impl(cs$lat, cs$lng, cs$radius)
  boxed <- search_radius(cs$lat, cs$lng, cs$radius)
  stopifnot(identical(sort(full$zipcode), sort(boxed$zipcode)))

  res <- bench::mark(
    loop = loop_impl(cs$lat, cs$lng, cs$radius),
    vectorized = vectorized_impl(cs$lat, cs$lng, cs$radius),
    boxed = search_radius(cs$lat, cs$lng, cs$radius),
    check = FALSE, min_iterations = 5
  )
  cat("\n==", nm, sprintf("(%d ZIPs in radius)\n", nrow(boxed)))
  print(res[, c("expression", "median", "itr/sec", "mem_alloc")])
}
