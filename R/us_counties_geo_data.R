#' US Counties Complementary Geo Data
#' 
#' @description
#' This function retrieves and processes geographic data for US counties, 
#' including FIPS codes and GEOID information, to complement census data.
#' 
#' @details
#' The function uses the `tigris` package to fetch geographic data for states 
#' and counties, processes the data to include relevant columns, and merges 
#' state-level information with county-level data. The resulting data frame 
#' contains information such as state names, state abbreviations, county names, 
#' FIPS codes, and GEOIDs.
#' 
#' @import dplyr
#' @import sf
#' @importFrom tigris states counties
#' @export
#' 
#' @return A data frame containing US counties' complementary geographic data, 
#' including state and county names, FIPS codes, and GEOIDs.
#' 
#' @examples
#' \dontrun{
#'   counties_data <- us_counties_geo_data()
#'   head(counties_data)
#' }
us_counties_geo_data <- function() {
  # Fetch state-level geographic data
  states_geo <- tigris::states() |> 
    dplyr::ungroup() |> 
    # Drop geometry column to simplify the data
    sf::st_drop_geometry() |> 
    # Select relevant columns: state abbreviation, name, and state FIPS code
    dplyr::select(STUSPS, NAME, STATEFP) |> 
    # Rename the NAME column to STATE for clarity
    dplyr::rename("STATE" = NAME)

  # Fetch county-level geographic data
  counties_geo <- tigris::counties() |> 
    # Create a full FIPS code by concatenating state and county FIPS codes
    dplyr::mutate(FIPS = paste0(STATEFP, COUNTYFP)) |> 
    # Drop geometry column to simplify the data
    sf::st_drop_geometry() |> 
    # Merge county data with state data using the STATEFP column
    dplyr::left_join(states_geo, by = "STATEFP") |> 
    # Select relevant columns for the final output
    dplyr::select(STATE, STUSPS, NAME, NAMELSAD, FIPS, GEOID)

  # Return the processed data frame
  return(counties_geo)
}
