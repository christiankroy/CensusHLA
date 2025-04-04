#' Generate a Map of Census Tract Population-Corrected Genotypic Frequencies by County
#'
#' This function creates a map visualizing the genotypic frequencies of a specified HLA allele 
#' across census tracts within a given county. The frequencies are adjusted based on population data.
#'
#' @param state_abbreviation A 2-letter state abbreviation. E.g., 'TX'.
#' @param county_code A 3-digit county code. E.g., '157'.
#' @param county_name The name of the county. E.g., 'Fort Bend'.
#' @param query_allele The HLA allele to query. E.g., 'A*11:01'.
#'
#' @return A list containing:
#' \item{out_data}{A data frame with processed allele frequency data for the specified county.}
#' \item{p1}{A ggplot2 object representing the map of genotypic frequencies.}
#' @export
#'
#' @examples
#' \dontrun{
#' texus_fort_bend <- make_county_census_tract_allele_frequency_map(
#'   state_abbreviation = 'TX',
#'   query_allele = 'A*11:01',
#'   county_code = '157',
#'   county_name = 'Fort Bend'
#' )
#' }
make_county_census_tract_allele_frequency_map <- function(
  state_abbreviation,
  county_code,
  county_name,
  query_allele) {
  library(ggplot2)

  # Calculate allele frequencies for all census tracts in the state
  state_census_tract_frequencies <- calculate_county_census_tract_allele_frequencies(state_abbreviation, query_allele)
  nmdp_freq_subset <- state_census_tract_frequencies$nmdp_freq_subset
  sf_data <- state_census_tract_frequencies$sf_data

  # Process and filter the data for the specified allele and county
  out_data <- nmdp_freq_subset |>
  dplyr::ungroup() |> # Remove grouping to allow further transformations
  dplyr::filter(allele == query_allele) |> # Filter for the queried allele
  dplyr::group_by(region, state, county, tract, tract_name, loci, allele) |> # Group by relevant columns
  dplyr::summarize(
    total_2020_pop = sum(total_2020_pop), # Sum the total population for each group
    us_2020_nmdp_gf_sum = sum(us_2020_nmdp_gf) # Sum the genotypic frequencies
  ) |>
  dplyr::filter(!(is.na(us_2020_nmdp_gf_sum))) |> # Remove rows with missing frequency data
  dplyr::mutate(
    # Set genotypic frequency to NA if the population is below 1000
    us_2020_nmdp_gf_sum = ifelse(total_2020_pop >= 1000, us_2020_nmdp_gf_sum, NA)
  ) |>
  dplyr::inner_join(
    sf_data, # Join with spatial data
    by = c(
    "tract" = "TRACTCE",
    "county" = "COUNTYFP",
    "state" = "STATEFP"
    )
  ) |>
  dplyr::filter(county == county_code) # Filter for the specified county

  # Create the map visualization
  p1 <- out_data |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(
    aes(
    geometry = geometry, # Use spatial geometry for plotting
    fill = us_2020_nmdp_gf_sum # Fill color based on genotypic frequency
    )
  ) +
  viridis::scale_fill_viridis(
    option = "plasma", # Use the "plasma" color scale
    direction = 1 # Set color scale direction
  ) +
  labs(
    title = paste0(
    county_name,
    "\nCensus-Adjusted ",
    query_allele,
    " Genotypic Frequency\nby Census Tract"
    ),
    fill = paste0(query_allele, " GF") # Legend label
  ) +
  theme_minimal() # Apply a minimal theme to the plot

  # Return the processed data and the plot
  return(list(
  out_data = out_data,
  p1 = p1
  ))
}
