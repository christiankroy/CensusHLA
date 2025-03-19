#' Calculate country census tract allele frequencies
#'
#' This function calculates the allele frequencies for each census tract in all states of the country.
#'
#' @param query_allele The allele to query for frequencies.
#'
#' @return A list containing the following elements:
#'   \itemize{
#'     \item \code{us_population_race_code_percentages_by_tract}: A data frame with the allele frequencies for each census tract.
#'     \item \code{sf_tract_data_for_all_states}: A data frame with additional data for each census tract.
#'   }
#'
#' @examples
#' \dontrun{
#' calculate_country_census_tract_allele_frequencies("A")
#' }
#'
#' @export
calculate_country_census_tract_allele_frequencies <- function(query_allele) {
  state_codes <- query_state_codes()
  state_census_tract_frequencies <- tryCatch(
    lapply(
      state_codes$STATE[1:51],
      calculate_county_census_tract_allele_frequencies,
      query_allele
    ),
    error = function(e) {
      message(
        "An error occurred while calculating county census tract allele frequencies: ",
        conditionMessage(e)
      )
      return(NULL)
    }
  )
  names(state_census_tract_frequencies) <- state_codes$STATE[1:51]
  # From each element of list, take the us_population_race_code_percentages
  tmp <- lapply(state_census_tract_frequencies, function
                (x)
    x$us_population_race_code_percentages)
  us_population_race_code_percentages_by_tract <- dplyr::bind_rows(tmp)
  # Now do the same for the sf_data
  tmp <- lapply(state_census_tract_frequencies, function
                (x)
    x$sf_data)
  sf_tract_data_for_all_states <- dplyr::bind_rows(tmp)
  return(
    list(
      us_population_race_code_percentages_by_tract = us_population_race_code_percentages_by_tract,
      sf_tract_data_for_all_states = sf_tract_data_for_all_states
    )
  )
}