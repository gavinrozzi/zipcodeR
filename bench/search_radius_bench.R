# Benchmark for the reproducibility-safe search_radius() optimization.
# Run from the package root: Rscript bench/search_radius_bench.R

suppressMessages(devtools::load_all(quiet = TRUE))
`%>%` <- dplyr::`%>%`

legacy_loop <- function(lat, lng, radius = 1) {
  zip_data <- zip_code_db %>% dplyr::filter(lat != "NA")
  for (i in seq_len(nrow(zip_data))) {
    zip_data$distance[i] <- raster::pointDistance(
      c(lng, lat), c(zip_data$lng[i], zip_data$lat[i]), lonlat = TRUE
    )
  }
  zip_data$distance <- zip_data$distance * 0.000621371
  zip_data %>%
    dplyr::filter(.data$distance <= radius) %>%
    dplyr::select(.data$zipcode, .data$distance) %>%
    dplyr::as_tibble() %>%
    dplyr::arrange(.data$distance)
}

cases <- list(
  suburban_10mi = list(lat = 39.9, lng = -74.3, radius = 10),
  urban_25mi = list(lat = 40.71, lng = -74.01, radius = 25),
  rural_50mi = list(lat = 44.5, lng = -110.0, radius = 50)
)

for (name in names(cases)) {
  case <- cases[[name]]
  legacy <- legacy_loop(case$lat, case$lng, case$radius)
  optimized <- search_radius(case$lat, case$lng, case$radius)
  stopifnot(identical(legacy, optimized))

  result <- bench::mark(
    legacy_loop = legacy_loop(case$lat, case$lng, case$radius),
    vectorized_wgs84 = search_radius(case$lat, case$lng, case$radius),
    check = TRUE,
    min_iterations = 3
  )
  cat("\n==", name, sprintf("(%d ZIPs in radius)\n", nrow(optimized)))
  print(result[, c("expression", "median", "itr/sec", "mem_alloc")])
}
