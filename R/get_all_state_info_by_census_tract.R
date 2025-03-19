#' get_all_state_info_by_census_tract
#'
#' Retrieves census tract information and map for all states.
#'
#' @return A list containing census tract information and map for each state.
#' @export
get_all_state_info_by_census_tract <- function(){
  state_codes <- query_state_codes()
  state_info <- tryCatch(
    lapply(state_codes$STATE[1:51], get_census_tract_info_and_map_by_state,5),
    error = function(e) {
      message("An error occurred while getting census tract info and map by state: ", conditionMessage(e))
      return(NULL)
    }
  )
  names(state_info) <- state_codes$STATE[1:51]
  return(state_info)
}

#' Summarize Tract Genotypic Frequencies by delNero2022 Catchment
#'
#' This function calculates the genotypic frequencies for a given query allele
#' within census tracts based on the delNero2022 catchment areas. It performs
#' the following steps:
#'
#' 1. Imports nmdp data for the query allele.
#' 2. Checks if there are values in the nmdp data.
#' 3. Calculates nmdp frequencies for each census tract for all states.
#' 4. Imports delNero2022 catchment areas and formats them appropriately.
#' 5. Pulls in state geographic area including tract data with centroids.
#' 6. Joins the delNero2022 catchment areas with the tract centroids.
#' 7. Joins the nmdp info by tract to the tract geographic info.
#' 8. Summarizes the nmdp data per catchment area based on tract data.
#' 9. Returns a list of multiple objects including the summarized data.
#'
#' @param query_allele The allele for which genotypic frequencies are calculated.
#' @return A list containing the summarized data, nmdp frequencies, and tract data.
#' @export
summarize_tract_genotypic_frequencies_by_delNero2022_catchment <- function(query_allele) {
  # Flog that we're importing nmdp data for the query allele, include a paste call to state the value of query allele
  futile.logger::flog.info(paste0("Importing nmdp data for the query allele: ", query_allele))
  nmdp_freq <- nmdp_hla_frequencies_by_race |>
    dplyr::filter(allele %in% query_allele)
  # Check that there are values in nmdp_freq
  if(nrow(nmdp_freq) == 0){
    futile.logger::flog.error("No values in nmdp_freq - check formating of query_allele!")
    return(NULL)
  }
  # Flog that we're going to calculate nmdp frequencies for each census tract for *all states*
  futile.logger::flog.info("Calculating nmdp frequencies for each census tract for all states. This will take some time")
  tmp <- calculate_country_census_tract_allele_frequencies(query_allele)
  sf_tract_data_for_all_states <- tmp$sf_tract_data_for_all_states
  us_population_race_code_percentages_by_tract <- tmp$us_population_race_code_percentages_by_tract
  # Flog that we're importing delNero2022 catchment areas and formatting appropriately
  futile.logger::flog.info("Importing delNero2022 catchment areas and formatting appropriately")
  target_crs <- 4269 # This the coordinate code for the census data
  delNero2022_sf <- sf::st_read("inst/ext/delNero2022/NCI_Catchment_Areas_fall2024.shp")
  # Transform the sf object to the target CRS
  # We need to do this because NCI/delNero2022 used a different coordinate unit
  delNero2022_sf <- st_transform(delNero2022_sf, target_crs)
  # Flog that we're going to pull in state geographic area including tract data with centroids
  futile.logger::flog.info("Pulling in state geographic area including tract data with centroids. This will take some time")
  state_info <- get_all_state_info_by_census_tract()
  # Pull out the tract centroids
  tract_centroids <- lapply(state_info, function
                            (x)
    x$shape_centroids)
  sf_tract_centroids_for_all_states <- dplyr::bind_rows(tract_centroids)
  # Flog that we're going to join the delNero2022 catchment areas with the tract centroids
  futile.logger::flog.info("Joining the delNero2022 catchment areas with the tract centroids")
  sf_tract_centroids_for_all_states_with_catchment <- sf::st_join(
    #sparse = TRUE,
    x = delNero2022_sf,
    y = sf_tract_centroids_for_all_states
  )
  # Flog that we're joining the nmdp info by tract to the tract geographic info
  futile.logger::flog.info("Joining nmdp info by tract to tract geographic info. This will take some time")
  sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract <-
    sf_tract_centroids_for_all_states_with_catchment |>
    dplyr::left_join(us_population_race_code_percentages_by_tract,
                     by = c("STATEFP" = "state",
                            "COUNTYFP" = "county",
                            "TRACTCE" = "tract"))

  # Flog that we're going to summarize the nmdp data per catchment area based on Tract data
  futile.logger::flog.info("Summarizing the nmdp data per catchment area based on Tract data")
  # Now we group by the catchment area and sum the us_2020_percent_pop
  sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract_summed <-
    sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract |>
    dplyr::group_by(geometry, name, ) |>
    dplyr::mutate(us_2020_catchment_pop = sum(total_2020_pop)) |> #View()
    dplyr::ungroup() |>
    dplyr::group_by(name, geometry, nmdp_race_code, us_2020_catchment_pop) |>
    dplyr::summarize(
      us_2020_single_race_catchment_pop = sum(total_single_race_pop),
      us_2020_multiple_race_catchment_pop = sum(total_multiple_race_pop)
    ) |>
    dplyr::mutate(us_2020_catchment_by_race_pop = us_2020_single_race_catchment_pop + us_2020_multiple_race_catchment_pop) |>
    dplyr::mutate(us_2020_catchment_by_race_percentage = us_2020_catchment_by_race_pop / us_2020_catchment_pop) |>
    dplyr::left_join(nmdp_freq) |>
    dplyr::mutate(us_2020_catchment_adjusted_race_gf =  nmdp_calc_gf * us_2020_catchment_by_race_percentage) |>
    dplyr::group_by(name, geometry, loci, allele) |>
    dplyr::summarize(
      total_2020_pop = sum(us_2020_catchment_by_race_pop),
      us_2020_nmdp_gf_sum = sum(us_2020_catchment_adjusted_race_gf)
    ) |>
    dplyr::filter(!(is.na(us_2020_nmdp_gf_sum)))
  # Flog that we're done and returning a list of multiple objects
  futile.logger::flog.info("Done and returning a list of multiple objects")

  return(
    list(
      sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract_summed = sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract_summed,
      nmdp_freq = nmdp_freq,
      sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract = sf_tract_centroids_for_all_states_with_catchment_with_us_population_race_code_percentages_by_tract
    )
  )

}