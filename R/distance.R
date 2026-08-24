#' Great-circle distance between coordinate pairs (haversine formula)
#'
#' Vectorized over all four arguments (recycled as needed). Returns the
#' spherical (haversine) distance in meters using the mean Earth radius
#' of 6,371,008.8 m. Distances involving NA coordinates return NA.
#'
#' Note: versions of zipcodeR prior to the removal of the raster
#' dependency computed WGS84 geodesic distances; haversine results can
#' differ from those by up to ~0.5%.
#'
#' @param lat_a,lng_a coordinates of the first point(s), decimal degrees
#' @param lat_b,lng_b coordinates of the second point(s), decimal degrees
#' @return numeric vector of distances in meters
#' @noRd
haversine_distance <- function(lat_a, lng_a, lat_b, lng_b) {
  earth_radius_m <- 6371008.8
  to_rad <- pi / 180

  dlat <- (lat_b - lat_a) * to_rad
  dlng <- (lng_b - lng_a) * to_rad

  h <- sin(dlat / 2)^2 +
    cos(lat_a * to_rad) * cos(lat_b * to_rad) * sin(dlng / 2)^2

  2 * earth_radius_m * asin(pmin(1, sqrt(h)))
}
