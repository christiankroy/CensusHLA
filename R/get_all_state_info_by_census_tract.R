#' get_all_state_info_by_census_tract
#'
#' Retrieves census tract information and maps for all states in the United States.
#' This function queries state codes, iterates through each state, and retrieves
#' the corresponding census tract information and map. If an error occurs during
#' the process, it is caught and logged, and
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
