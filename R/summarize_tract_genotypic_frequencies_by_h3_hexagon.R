#' Summarize Genotypic frequency by H3 Hexagon and State
#'
#' @param state_abbreviation The state abbreviation, e.g. 'MA'
#' @param query_allele The allele to query, e.g. 'A*11:01'
#' @param h3_resolution The resolution of the H3 hexagon, e.g. 5
#'
#' @return an_object
#' @export
#'
#' @examples \dontrun{summarize_tract_genotypic_frequencies_by_h3_hexagon('MA','A*11:01',5)}
summarize_tract_genotypic_frequencies_by_h3_hexagon <- function(state_abbreviation, query_allele, h3_resolution){
  resolution_query <- paste0("h3_resolution_", h3_resolution)
  state_census_tract_frequencies <- calculate_county_census_tract_allele_frequencies(state_abbreviation,query_allele)
  state_info <- get_census_tract_info_and_map_by_state(state_abbreviation, h3_resolution)
  shape_file <- state_census_tract_frequencies$sf_data

  tract_data_with_hexon_centroids <-
    state_census_tract_frequencies$us_population_race_code_percentages |>
    dplyr::left_join(as.data.frame(state_info$tract_centroids_with_hexongs),
                     by = c('tract' = 'TRACTCE'))

  nmdp_freq <- nmdp_hla_frequencies_by_race |>
    dplyr::filter(allele %in% query_allele)

  genotypic_frequencies_by_hexon <-
    tract_data_with_hexon_centroids |>
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
    dplyr::mutate(us_2020_hex_adjusted_race_gf =  nmdp_calc_gf * us_2020_hex_by_race_percentage) |>
    dplyr::filter(allele == query_allele) |>
    dplyr::group_by(region, state, loci, allele, hex) |>
    dplyr::summarize(
      total_2020_pop = sum(us_2020_hex_by_race_pop),
      us_2020_nmdp_gf_sum = sum(us_2020_hex_adjusted_race_gf)
    ) |>
    dplyr::filter(!(is.na(us_2020_nmdp_gf_sum)))

  genotypic_frequencies_by_hexon$geometry <- h3jsr::cell_to_polygon(genotypic_frequencies_by_hexon$hex)

  options(tigris_use_cache = TRUE)
  usa_states <- rnaturalearth::ne_states(country = 'United States of America')
  target_state_df <- as.data.frame(usa_states) |>
    dplyr::filter(postal %in% state_abbreviation)
  target_state_sf <- st_as_sf(target_state_df)
  target_crs <- 4269 # This the coordinate code for the census data
  target_state_transformed <- st_transform(target_state_sf, target_crs)

  p1 <-
    genotypic_frequencies_by_hexon |>
    ggplot2::ggplot() +
    geom_sf(aes(geometry = geometry, fill = us_2020_nmdp_gf_sum)) +
    geom_sf(data = target_state_transformed,linewidth = 3,fill=NA) +
    #geom_sf(data = shape_file, fill = "lightgreen", color = "black", alpha = 0.2) +
    labs(
      title = paste0(
        state_abbreviation,
        " US-census\n adjusted Genotypic Frequency\n by H3 Hexagon ",
        h3_resolution,
        "for Allele",
        query_allele
      ),
      x = "Longitude",
      y = "Latitude",
      fill = paste0(query_allele, " GF")) +
    viridis::scale_fill_viridis(option = "plasma",
                                direction = 1) +
    # Adjust the theme to remove the coordinate lines
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
    )

  return(list(genotypic_frequencies_by_hexon = genotypic_frequencies_by_hexon, p1 = p1))
}
