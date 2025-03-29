#' Query County 2020 Census Codes by State
#'
#' This function retrieves the 2020 Census county codes for a specified state 
#' using its state abbreviation. It fetches the state information, constructs 
#' the appropriate URL for the county codes file, and processes the data.
#'
#' @param query_state_abbreviation A character string representing the two-letter 
#' state abbreviation (e.g., "TX" for Texas).
#'
#' @return A data frame containing county codes and related information for the 
#' specified state.
#' 
#' @export
#'
#' @examples 
#' # Query county codes for Texas
#' tx_codes <- query_county_info_by_state(query_state_abbreviation = "TX")
query_county_info_by_state <- function(query_state_abbreviation) {
  # Retrieve state codes data
  state_codes <- query_state_codes()
  
  # Filter the state codes to get information for the specified state
  state_info <- state_codes |> dplyr::filter(STATE == query_state_abbreviation)
  
  # Construct the URL for the county codes file based on the state information
  county_codes <- read.csv(
    sep = "|",
    paste0(
      "https://www2.census.gov/geo/docs/reference/codes2020/cou/st",
      unique(state_info$STATEFP), "_", tolower(unique(state_info$STATE)), "_cou2020.txt"
    )
  )
  
  # Left-pad the COUNTYFP values to ensure they are at least 3 digits, adding leading zeros if necessary
  county_codes$COUNTYFP <- sprintf("%03d", county_codes$COUNTYFP)
  
  # Return the processed county codes data frame
  return(county_codes)
}