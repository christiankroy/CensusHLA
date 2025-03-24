#' Plot delNero2022 Catchment Areas
#'
#' @param query_allele A character string with the allele to plot
#'
#' @return an_object
#' @export
#'
#' @examples \dontrun{plot_delNero2022_catchment_areas('A*11:01')}
plot_delNero2022_catchment_areas <- function(query_allele, sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract_summed) {
  library(ggplot2)
  options(tigris_use_cache = TRUE)
  states <- rnaturalearth::ne_states(country = 'United States of America')
  continental_states <- as.data.frame(states) |>
    dplyr::filter(!(postal %in% c("HI", "AK", "AS", "GU", "MP", "PR", "VI")))
  continental_us <- sf::st_as_sf(continental_states)
  target_crs <- 4269 # This the coordinate code for the census data
  continental_us <- sf::st_transform(continental_us, target_crs)
  p1 <-
    sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract_summed |>
    dplyr::mutate(name_short = substr(name, 1, 30)) |>
    dplyr::filter(!(name %in% c("University of Hawai'i Cancer Center"))) |>
    ggplot2::ggplot(label = name) +
    geom_sf(data = continental_us,
            alpha = 75,
            line = 'black') +
    geom_sf(aes(geometry = geometry, fill = us_2020_nmdp_gf_sum), alpha =
              0.85) +
    labs(
      title = paste0(
        "US-census\n adjusted Genotypic Frequency\n by NCI Catchment Area ",
        "for Allele ",
        query_allele
      ),
      x = "Longitude",
      y = "Latitude",
      fill = paste0(query_allele, " GF")
    ) +
    viridis::scale_fill_viridis(option = "plasma", direction = 1) +
    theme_minimal()
  return(p1)
}
