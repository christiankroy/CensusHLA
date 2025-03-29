#' Calculate a NMDP Genotypic Frequency Table by Census Tracts within a State
#'
#' This function calculates a genotypic frequency table for a specified HLA allele 
#' by census tracts within a given state, adjusted to the 2020 Census population data. 
#' It also provides a shapefile for visualization.
#'
#' @param state_abbreviation A two-letter postal code representing the state.
#' @param query_allele The HLA allele to be analyzed and plotted from NMDP data.
#'
#' @return A list containing:
#' \item{us_population_race_code_percentages}{A data frame with population percentages by race codes.}
#' \item{nmdp_freq_subset}{A data frame with adjusted genotypic frequencies for the specified allele.}
#' \item{sf_data}{Spatial data (shapefile) for the state's census tracts.}
#' \item{shapefile_path}{The file path to the shapefile used.}
#' 
#' @export
calculate_county_census_tract_allele_frequencies <- function(state_abbreviation, query_allele) {
  
  # Query state codes and filter for the given state abbreviation
  state_codes <- query_state_codes()
  state_code <- dplyr::filter(state_codes, STATE == state_abbreviation) |> dplyr::pull(STATEFP)
  
  # Log the state being processed
  futile.logger::flog.info(paste0("Working with state: ", state_abbreviation))
  
  # Retrieve metadata for the 2020 Census PL endpoint
  dec_pl_endpoint_vars <- censusapi::listCensusMetadata(name = '2020/dec/pl', type = "variables")
  
  # Filter for variables in the P2 group (race-related data)
  p2_vars <- dplyr::filter(dec_pl_endpoint_vars, group == "P2")
  
  # Query census data for the specified state and tracts
  p2_values <- censusapi::getCensus(
  region = "tract",
  regionin = paste0("state:", state_code),
  name = "2020/dec/pl",
  vars = c("NAME", p2_vars$name)
  )
  
  # Reshape the data to long format for easier processing
  p2_values <- p2_values |>
  tidyr::pivot_longer(cols = starts_with("P2_"), names_to = 'name', values_to = 'value') |>
  dplyr::arrange(desc(value))
  
  # Join metadata with census data and clean up columns
  us_census_2020_race_details <- dec_pl_endpoint_vars |>
  dplyr::inner_join(p2_values, by = "name") |>
  dplyr::rename(tract_name = NAME) |>
  dplyr::select(name, tract_name, state, county, tract, label, group, attributes, value) |>
  dplyr::mutate(
    short_label = gsub(
    pattern = "!!Total:!!Not Hispanic or Latino:!!Population of two or more races:!!Population of ",
    replacement = "",
    x = label
    )
  ) |>
  dplyr::filter(!grepl(pattern = ":$", x = short_label)) |>
  dplyr::select(name, state, county, tract, tract_name, short_label, value) |>
  dplyr::mutate(
    num_reported_races = dplyr::case_when(
    grepl(pattern = "one", x = short_label) ~ 1,
    grepl(pattern = "two", x = short_label) ~ 2,
    grepl(pattern = "three", x = short_label) ~ 3,
    grepl(pattern = "four", x = short_label) ~ 4,
    grepl(pattern = "five", x = short_label) ~ 5,
    grepl(pattern = "six", x = short_label) ~ 6,
    grepl(pattern = "!!Total:!!Hispanic or Latino", x = short_label) ~ 1
    )
  ) |>
  dplyr::mutate(
    MLT = ifelse(num_reported_races > 1, TRUE, 0),
    HIS = grepl(pattern = " !!Total:!!Hispanic ", x = short_label),
    NAM = grepl(pattern = "American Indian", x = short_label),
    API = grepl(pattern = "(Asian)|(Pacific)", x = short_label),
    AFA = grepl(pattern = "Black or African American", x = short_label),
    CAU = grepl(pattern = "White", x = short_label),
    UNK = grepl(pattern = "Some Other", x = short_label)
  )
  
  # Adjust population counts based on the number of reported races
  us_census_2020_race_details_race_num_adjusted_long <- us_census_2020_race_details |>
  dplyr::mutate(value_reported_race_adjusted = as.integer(value / num_reported_races)) |>
  tidyr::pivot_longer(
    names_to = "nmdp_race_code",
    values_to = "has_race_code",
    cols = c(HIS, NAM, API, AFA, CAU, UNK)
  ) |>
  dplyr::filter(has_race_code == TRUE)
  
  # Summarize multi-race population counts by race code
  us_census_2020_race_details_race_num_adjusted_long_multirace <- us_census_2020_race_details_race_num_adjusted_long |>
  dplyr::filter(num_reported_races > 1) |>
  dplyr::group_by(state, county, tract, tract_name, nmdp_race_code) |>
  dplyr::summarize(
    total_multiple_race_pop = sum(value_reported_race_adjusted),
    .groups = "keep"
  )
  
  # Summarize single-race population counts and combine with multi-race data
  us_pop_multirace_in_nmdp_codes <- us_census_2020_race_details_race_num_adjusted_long |>
  dplyr::filter(num_reported_races == 1) |>
  dplyr::group_by(state, county, tract, tract_name, nmdp_race_code) |>
  dplyr::summarize(
    total_single_race_pop = sum(value_reported_race_adjusted),
    .groups = "keep"
  ) |>
  dplyr::full_join(
    us_census_2020_race_details_race_num_adjusted_long_multirace,
    by = c("state", "county", "tract", "tract_name", "nmdp_race_code")
  ) |>
  dplyr::mutate_at(
    .vars = c("total_single_race_pop", "total_multiple_race_pop"),
    .funs = dplyr::coalesce,
    0
  ) |>
  dplyr::mutate(total_2020_pop = total_single_race_pop + total_multiple_race_pop)
  
  # Filter NMDP frequencies for the queried allele
  nmdp_freq <- nmdp_hla_frequencies_by_race |>
  dplyr::filter(allele %in% query_allele)
  
  # Identify race codes not in the NMDP race groups
  nmdp_census_code_freq_names <- unique(nmdp_freq$nmdp_race_code)[!(
  unique(nmdp_freq$nmdp_race_code) %in% unique(nmdp_racegroups$nmdp_race_code)
  )]
  
  # Calculate population percentages by race codes
  us_population_race_code_percentages <- us_pop_multirace_in_nmdp_codes |>
  dplyr::mutate(census_region = tract) |>
  dplyr::group_by(state, county, census_region) |>
  dplyr::mutate(us_2020_percent_pop = total_2020_pop / sum(total_2020_pop))
  
  # Subset and adjust NMDP frequencies based on population percentages
  nmdp_freq_subset <- nmdp_freq |>
  dplyr::filter(nmdp_race_code %in% nmdp_census_code_freq_names) |>
  dplyr::left_join(
    dplyr::select(
    us_population_race_code_percentages,
    state,
    county,
    tract,
    tract_name,
    nmdp_race_code,
    total_2020_pop,
    us_2020_percent_pop
    ),
    by = c("nmdp_race_code")
  ) |>
  dplyr::mutate(us_2020_nmdp_gf = nmdp_calc_gf * us_2020_percent_pop) |>
  dplyr::arrange(desc(us_2020_nmdp_gf))
  
  # Load the shapefile for the state's census tracts
  shapefile_path <- paste0(
  system.file(package = "CensusHLA"),
  "/extdata/tiger_2020/tract/",
  "tl_2020_",
  state_code,
  "_tract.shp"
  )
  sf_data <- st_read(shapefile_path)
  
  # Return the results as a list
  list(
  us_population_race_code_percentages = us_population_race_code_percentages,
  nmdp_freq_subset = nmdp_freq_subset,
  sf_data = sf_data,
  shapefile_path = shapefile_path
  )
}
