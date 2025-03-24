#' Get Census Tract Info and Map by State
#'
#' @param state_abbreviation
#' @param h3_resolution
#'
#' @return an_object
#' @export
#'
#' @examples \dontrun{tx_5 <- get_census_tract_info_and_map_by_state(state_abbreviation = 'TX',h3_resolution = 5)}
#'
get_census_tract_info_and_map_by_state <- function(state_abbreviation, h3_resolution) {
  # Flog that we're working with a given state
  futile.logger::flog.info(paste0("Working with state: ", state_abbreviation))
  # Find out the state code from the abbreviation
  resolution_query <- paste0("h3_resolution_", h3_resolution)
  state_code <- query_state_codes() |>
    dplyr::filter(STATE == state_abbreviation) |>
    dplyr::pull(STATEFP)
  shape_file <-
    sf::st_read(
      paste0(
        system.file(package = "CensusHLA"),
        "/extdata/tiger_2020/tract/tl_2020_",
        state_code,
        '_tract.shp'),
      quiet = TRUE
    )
  fillers <-
    h3jsr::polygon_to_cells(geometry = shape_file$geometry,
                            res = h3_resolution,
                            simple = FALSE)
  p1 <- ggplot() +
    geom_sf(data = shape_file, fill = "lightgreen", color = "black", alpha = 0.2) +
    labs(title = "H3 Hexagon", x = "Longitude", y = "Latitude") +
    theme_minimal()
  shape_centroids <- st_centroid(shape_file)
  centroid_plot <- ggplot() +
    geom_sf(data = shape_file, fill = "lightgreen", color = "black", alpha = 0.2) +
    geom_sf(data = shape_centroids, fill = "red", color = "black", alpha = 1) +
    labs(title = "H3 Hexagon", x = "Longitude", y = "Latitude") +
    theme_minimal()

  centroid_hex_assignments <- h3jsr::point_to_cell(shape_centroids$geometry, res = c(3,4,5,6,7,8), simple = FALSE)
  # Evaluate the value stored in h3_resolution in a dplyr 'ends_with' select statement to pull just 1 column
  dplyr::select(centroid_hex_assignments,resolution_query)

  tract_centroids_with_hexongs <- cbind(shape_centroids, dplyr::select(centroid_hex_assignments,all_of(resolution_query)))
  return(list(sf_data = shape_file, p1 = p1,
              # Also return the centroids
              centroid_plot = centroid_plot,
              centroid_hex_assignments = centroid_hex_assignments,
              tract_centroids_with_hexongs= tract_centroids_with_hexongs,
              shape_centroids = shape_centroids))
}
