#' US Counties complementary geo data
#' @description
#' A function that returns county fips and GEOID information to complement census data
#' @import dplyr
#' @import sf
#' @export
#' @returns Data frame with us counties complementary
us_counties_geo_data <- function(){
  states_geo <- tigris::states() |>
    dplyr::ungroup() |>
    sf::st_drop_geometry(states_geo) |>
    dplyr::select(STUSPS, NAME, STATEFP) |>
    dplyr::rename("STATE" = NAME)

  counties_geo <- tigris::counties() |>
    dplyr::mutate(FIPS = paste0(STATEFP, COUNTYFP)) |>
    sf::st_drop_geometry(states_geo) |>
    dplyr::left_join(states_geo, by = "STATEFP") |>
    dplyr::select(STATE, STUSPS, NAME, NAMELSAD, FIPS, GEOID)
  return(counties_geo)
}
