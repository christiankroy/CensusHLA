#' Query Census 2020 State Codes
#'
#' @return a data frame of 2020 state codes
#' @export
#'
#' @examples query_state_codes()
query_state_codes <- function(){
  # Read the txt file from a url
  state_codes <- read.csv("https://www2.census.gov/geo/docs/reference/codes2020/national_state2020.txt",sep = "|")
  # Left pad a 0 on all single digit records in the STATEFP column
  state_codes$STATEFP <- sprintf("%02d", state_codes$STATEFP)
  state_codes
}
