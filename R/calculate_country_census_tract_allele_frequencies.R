#' Calculate country census tract allele frequencies
#'
#' This function calculates the allele frequencies for each census tract across all states in the country.
#' It aggregates data from individual states and combines it into a unified result.
#'
#' @param query_allele A character string representing the allele for which frequencies are to be calculated.
#'
#' @return A list containing the following elements:
#'   \itemize{
#'     \item \code{us_population_race_code_percentages_by_tract}: A data frame with the allele frequencies for each census tract across all states.
#'     \item \code{sf_tract_data_for_all_states}: A data frame with spatial and additional data for each census tract across all states.
#'   }
#'
#' @examples
#' \dontrun{
#' calculate_country_census_tract_allele_frequencies("A*11:01")
#' }
#'
#' @export
calculate_country_census_tract_allele_frequencies <- function(query_allele) {
  # Query the state codes for all states
  state_codes <- query_state_codes()

  # Calculate allele frequencies for each state using a helper function
  state_census_tract_frequencies <- tryCatch(
    lapply(
      state_codes$STATE[1:51], # Iterate over the first 51 state codes
      calculate_county_census_tract_allele_frequencies, # Function to calculate frequencies for a state
      query_allele # Pass the query allele as an argument
    ),
    error = function(e) {
      # Handle errors gracefully and log a message
      message(
        "An error occurred while calculating county census tract allele frequencies: ",
        conditionMessage(e)
      )
      return(NULL)
    }
  )

  # Assign state codes as names to the list of results
  names(state_census_tract_frequencies) <- state_codes$STATE[1:51]

  # Extract and combine the `us_population_race_code_percentages` data from all states
  tmp <- lapply(state_census_tract_frequencies, function(x) x$us_population_race_code_percentages)
  us_population_race_code_percentages_by_tract <- dplyr::bind_rows(tmp)

  # Extract and combine the `sf_data` (spatial data) from all states
  tmp <- lapply(state_census_tract_frequencies, function(x) x$sf_data)
  sf_tract_data_for_all_states <- dplyr::bind_rows(tmp)

  # Return the combined results as a list
  return(
    list(
      us_population_race_code_percentages_by_tract = us_population_race_code_percentages_by_tract,
      sf_tract_data_for_all_states = sf_tract_data_for_all_states
    )
  )
}
