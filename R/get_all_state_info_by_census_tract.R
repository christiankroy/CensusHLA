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
