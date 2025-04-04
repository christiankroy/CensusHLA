#' Summarize Genotypic Frequency by H3 Hexagon and State
#'
#' This function calculates and visualizes the genotypic frequencies of a specified allele 
#' across H3 hexagons within a given state. It uses census tract data, H3 hexagon resolution, 
#' and NMDP HLA frequencies to compute adjusted genotypic frequencies.
#'
#' @param state_abbreviation A string representing the state abbreviation, e.g., 'MA'.
#' @param query_allele A string representing the allele to query, e.g., 'A*11:01'.
#' @param h3_resolution An integer specifying the resolution of the H3 hexagon, e.g., 5.
#'
#' @return A list containing:
#' \item{genotypic_frequencies_by_hexon}{A data frame with genotypic frequencies summarized by H3 hexagon.}
#' \item{p1}{A ggplot object visualizing the genotypic frequencies by H3 hexagon.}
#' @export
#'
#' @examples 
#' \dontrun{
#' summarize_tract_genotypic_frequencies_by_h3_hexagon('MA', 'A*11:01', 5)
#' }
summarize_tract_genotypic_frequencies_by_h3_hexagon <- function(state_abbreviation, query_allele, h3_resolution) {
  # Construct the resolution query string for H3 hexagon resolution
  resolution_query <- paste0("h3_resolution_", h3_resolution)
  
  # Calculate allele frequencies for census tracts in the specified state
  state_census_tract_frequencies <- calculate_county_census_tract_allele_frequencies(state_abbreviation, query_allele)
  
  # Retrieve census tract information and H3 hexagon mapping for the state
  state_info <- get_census_tract_info_and_map_by_state(state_abbreviation, h3_resolution)
  
  # Extract shapefile data for visualization
  shape_file <- state_census_tract_frequencies$sf_data
  
  # Join census tract data with H3 hexagon centroids
  tract_data_with_hexon_centroids <- state_census_tract_frequencies$us_population_race_code_percentages |>
    dplyr::left_join(as.data.frame(state_info$tract_centroids_with_hexongs), by = c('tract' = 'TRACTCE'))
  
  # Filter NMDP HLA frequencies for the queried allele
  nmdp_freq <- nmdp_hla_frequencies_by_race |>
    dplyr::filter(allele %in% query_allele)
  
  # Calculate genotypic frequencies by H3 hexagon
  genotypic_frequencies_by_hexon <- tract_data_with_hexon_centroids |>
    dplyr::mutate(census_region = tract) |>
    dplyr::rename(hex = !!sym(resolution_query)) |>
    dplyr::group_by(state, hex) |>
    dplyr::mutate(us_2020_hex_pop = sum(total_2020_pop)) |>
    dplyr::ungroup() |>
    dplyr::group_by(state, hex, nmdp_race_code, us_2020_hex_pop) |>
    dplyr::summarize(
      us_2020_single_race_hex_pop = sum(total_single_race_pop),
      us_2020_multiple_race_hex_pop = sum(total_multiple_race_pop)
    ) |>
    dplyr::mutate(
      us_2020_hex_by_race_pop = us_2020_single_race_hex_pop + us_2020_multiple_race_hex_pop
    ) |>
    dplyr::mutate(
      us_2020_hex_by_race_percentage = us_2020_hex_by_race_pop / us_2020_hex_pop
    ) |>
    dplyr::left_join(nmdp_freq) |>
    dplyr::mutate(us_2020_hex_adjusted_race_gf = nmdp_calc_gf * us_2020_hex_by_race_percentage) |>
    dplyr::filter(allele == query_allele) |>
    dplyr::group_by(region, state, loci, allele, hex) |>
    dplyr::summarize(
      total_2020_pop = sum(us_2020_hex_by_race_pop),
      us_2020_nmdp_gf_sum = sum(us_2020_hex_adjusted_race_gf)
    ) |>
    dplyr::filter(!(is.na(us_2020_nmdp_gf_sum)))
  
  # Convert H3 hexagon IDs to polygons for visualization
  genotypic_frequencies_by_hexon$geometry <- h3jsr::cell_to_polygon(genotypic_frequencies_by_hexon$hex)
  
  # Load USA state boundaries and filter for the target state
  options(tigris_use_cache = TRUE)
  usa_states <- rnaturalearth::ne_states(country = 'United States of America')
  target_state_df <- as.data.frame(usa_states) |>
    dplyr::filter(postal %in% state_abbreviation)
  target_state_sf <- st_as_sf(target_state_df)
  
  # Transform the target state's geometry to match the CRS of the census data
  target_crs <- 4269 # EPSG code for NAD83
  target_state_transformed <- st_transform(target_state_sf, target_crs)
  
  # Create a ggplot visualization of genotypic frequencies by H3 hexagon
  p1 <- genotypic_frequencies_by_hexon |>
    ggplot2::ggplot() +
    geom_sf(aes(geometry = geometry, fill = us_2020_nmdp_gf_sum)) +
    geom_sf(data = target_state_transformed, linewidth = 3, fill = NA) +
    labs(
      title = paste0(
        state_abbreviation,
        " US-census\n adjusted Genotypic Frequency\n by H3 Hexagon ",
        h3_resolution,
        " for Allele ",
        query_allele
      ),
      x = "Longitude",
      y = "Latitude",
      fill = paste0(query_allele, " GF")
    ) +
    viridis::scale_fill_viridis(option = "plasma", direction = 1) +
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
    )
  
  # Return the summarized data and the plot
  return(list(genotypic_frequencies_by_hexon = genotypic_frequencies_by_hexon, p1 = p1))
}
