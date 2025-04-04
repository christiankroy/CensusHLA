#' Get Census Tract Information and Map by State
#'
#' This function retrieves census tract information for a specified state and maps it using H3 hexagons at a given resolution.
#'
#' @param state_abbreviation A two-letter state abbreviation, e.g., 'TX'.
#' @param h3_resolution The resolution of the H3 hexagons to use. Must be an integer between 0 and 15, e.g., 5.
#'
#' @return A list containing:
#' \describe{
#'   \item{sf_data}{The spatial data (sf object) for the census tracts.}
#'   \item{p1}{A ggplot object showing the census tracts with H3 hexagons.}
#'   \item{centroid_plot}{A ggplot object showing the centroids of the census tracts.}
#'   \item{centroid_hex_assignments}{A data frame mapping centroids to H3 hexagons.}
#'   \item{tract_centroids_with_hexongs}{A combined sf object of centroids and their corresponding H3 hexagons.}
#'   \item{shape_centroids}{The centroids of the census tracts as an sf object.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' tx_5 <- get_census_tract_info_and_map_by_state(
#'   state_abbreviation = 'TX',
#'   h3_resolution = 5
#' )
#' }
#'
get_census_tract_info_and_map_by_state <- function(state_abbreviation, h3_resolution) {
  library(ggplot2)
  
  # Log the state being processed
  futile.logger::flog.info(paste0("Working with state: ", state_abbreviation))
  
  # Construct the resolution query string for H3 hexagons
  resolution_query <- paste0("h3_resolution_", h3_resolution)
  
  # Retrieve the state code corresponding to the state abbreviation
  state_code <- query_state_codes() |>
    dplyr::filter(STATE == state_abbreviation) |>
    dplyr::pull(STATEFP)
  
  # Load the shapefile for the state's census tracts
  shape_file <- sf::st_read(
    paste0(
      system.file(package = "CensusHLA"),
      "/extdata/tiger_2020/tract/tl_2020_",
      state_code,
      '_tract.shp'
    ),
    quiet = TRUE
  )
  
  # Convert the census tract polygons to H3 hexagons
  fillers <- h3jsr::polygon_to_cells(
    geometry = shape_file$geometry,
    res = h3_resolution,
    simple = FALSE
  )
  
  # Create a ggplot map of the census tracts with H3 hexagons
  p1 <- ggplot2::ggplot() +
    geom_sf(data = shape_file, fill = "lightgreen", color = "black", alpha = 0.2) +
    labs(title = "H3 Hexagon", x = "Longitude", y = "Latitude") +
    theme_minimal()
  
  # Compute the centroids of the census tracts
  shape_centroids <- st_centroid(shape_file)
  
  # Create a ggplot map showing the centroids of the census tracts
  centroid_plot <- ggplot() +
    geom_sf(data = shape_file, fill = "lightgreen", color = "black", alpha = 0.2) +
    geom_sf(data = shape_centroids, fill = "red", color = "black", alpha = 1) +
    labs(title = "H3 Hexagon", x = "Longitude", y = "Latitude") +
    theme_minimal()
  
  # Assign H3 hexagons to the centroids at multiple resolutions
  centroid_hex_assignments <- h3jsr::point_to_cell(
    shape_centroids$geometry,
    res = c(3, 4, 5, 6, 7, 8),
    simple = FALSE
  )
  
  # Select the column corresponding to the specified H3 resolution
  centroid_hex_assignments <- dplyr::select(
    centroid_hex_assignments,
    all_of(resolution_query)
  )
  
  # Combine the centroids with their corresponding H3 hexagon assignments
  tract_centroids_with_hexongs <- cbind(
    shape_centroids,
    centroid_hex_assignments
  )
  
  # Return the results as a list
  return(list(
    sf_data = shape_file,
    p1 = p1,
    centroid_plot = centroid_plot,
    centroid_hex_assignments = centroid_hex_assignments,
    tract_centroids_with_hexongs = tract_centroids_with_hexongs,
    shape_centroids = shape_centroids
  ))
}
