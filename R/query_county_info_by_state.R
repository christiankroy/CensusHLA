#' Query County 2020 Census Codes by State
#'
#' @param query_state_abbreviation
#'
#' @return A data frame of county codes by query state
#' @export
#'
#' @examples tx_codes <- query_county_info_by_state(query_state_abbreviation = "TX")
query_county_info_by_state <- function(query_state_abbreviation){
  state_codes <- query_state_codes()
  state_info <- state_codes |> dplyr::filter(STATE == query_state_abbreviation)
  county_codes <- read.csv(sep = "|",
                           paste0("https://www2.census.gov/geo/docs/reference/codes2020/cou/st",
                                  unique(state_info$STATEFP),"_",tolower(unique(state_info$STATE)),"_cou2020.txt"))
  # Left pad the COUNTYFP values to be at least 3 digits, with a 0 in the front,
  county_codes$COUNTYFP <- sprintf("%03d", county_codes$COUNTYFP)
  return(county_codes)
}