#' Generate a State-Level Map of County Population-Corrected Genotypic Frequencies
#'
#' This function creates a map visualizing the genotypic frequencies of a specified allele 
#' across counties within a given state. The frequencies are adjusted based on census data.
#'
#' @param state_name A string specifying the name of the state (e.g., 'Texas').
#' @param query_allele A string specifying the allele to query (e.g., 'A*11:01').
#'
#' @return A list containing:
#' \item{out_data}{A data frame with the processed allele frequency data for the specified state.}
#' \item{p1}{A ggplot2 object representing the map of allele frequencies.}
#' @export
#'
#' @examples
#' \dontrun{
#' result <- make_state_by_county_allele_frequency_map(
#'   state_name = 'Texas',
#'   query_allele = 'A*11:01'
#' )
#' print(result$p1)  # To display the map
#' }
make_state_by_county_allele_frequency_map <- function(
  state_name,
  query_allele) {

  # Filter the census-adjusted HLA frequencies for the specified state and allele
  state_county_frequencies <-
  census_adjusted_nmdp_hla_frequencies_by_county |> 
  dplyr::filter(state == state_name & allele == query_allele)

  # Query state codes and extract the code for the specified state
  state_codes <- query_state_codes()
  state_code <- dplyr::filter(state_codes, STATE_NAME == state_name) |> 
        dplyr::pull(STATEFP)

  # Define the path to the shapefile containing county geometries
  shapefile_path <- paste0(
  system.file(package = "CensusHLA"),
  "/extdata/tiger_2020/county/tl_2020_us_county.shp"
  )

  # Read the shapefile using the sf package
  sf_data <- sf::st_read(shapefile_path)

  # Process the allele frequency data
  out_data <- state_county_frequencies |>
  dplyr::ungroup() |>  # Remove grouping if any exists
  dplyr::filter(allele == query_allele) |>  # Ensure the data is filtered for the query allele
  dplyr::group_by(region, state, census_region, county, fips, loci, allele) |>  # Group by relevant columns
  dplyr::summarize(
    us_2020_nmdp_gf_sum = sum(us_2020_nmdp_gf)  # Summarize genotypic frequencies
  ) |> 
  dplyr::filter(!(is.na(us_2020_nmdp_gf_sum))) |>  # Remove rows with NA frequencies
  dplyr::mutate(
    # Extract state and county FIPS codes from the full FIPS code
    STATEFP = substr(fips, 1, 2),
    COUNTYFP = substr(fips, 3, nchar(fips))
  ) |> 
  # Join the processed data with the shapefile data
  dplyr::inner_join(sf_data)

  # Create the map using ggplot2
  p1 <- out_data |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(
    aes(geometry = geometry, fill = us_2020_nmdp_gf_sum)  # Map geometry and fill by frequency
  ) +
  coord_sf() +  # Use a coordinate system suitable for spatial data
  viridis::scale_fill_viridis(
    option = "plasma",  # Use the 'plasma' color scale
    direction = 1  # Set the color scale direction
  ) +
  labs(
    title = paste0(
    state_name,
    "\nCensus-Adjusted ",
    query_allele
    ),
    fill = paste0(query_allele, " GF")  # Label for the color scale
  ) +
  theme_minimal()  # Apply a minimal theme to the plot

  # Return the processed data and the plot as a list
  return(list(
  out_data = out_data,
  p1 = p1
  ))
}
