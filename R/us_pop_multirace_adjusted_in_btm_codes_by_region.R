#' Obtain US Population Numbers by NMDP Race Codes and Region
#'
#' This function retrieves and processes US Census 2020 population data to calculate population numbers
#' by NMDP (National Marrow Donor Program) race codes and by region. It supports filtering by state or county
#' and adjusts for individuals reporting multiple races.
#'
#' @param in_region A string specifying the region of interest. Valid values are:
#'   \itemize{
#'     \item "us" - Entire United States
#'     \item "all states" - All states (not recommended for use)
#'     \item "all counties" - All counties
#'     \item A valid state name (e.g., "Alaska")
#'   }
#' @param census_region_level A string specifying the granularity of the data:
#'   \itemize{
#'     \item "state" - Data divided by state (default)
#'     \item "county" - Data divided by county within a state
#'   }
#' @return A data frame containing population numbers by NMDP race codes and region, with the following columns:
#'   \itemize{
#'     \item region - The specified region (e.g., state or county)
#'     \item nmdp_race_code - NMDP race code
#'     \item total_single_race_pop - Population reporting a single race
#'     \item total_multiple_race_pop - Population reporting multiple races
#'     \item total_2020_pop - Total population (single + multiple race)
#'     \item census_region - Census region corresponding to the input region
#'   }
#' @export
#' @examples
#' # Get population data for Alaska
#' us_pop_multirace_in_nmdp_codes_by_region(in_region = "Alaska")
#'
us_pop_multirace_in_nmdp_codes_by_region <- function(in_region, census_region_level = "state") {
  # Validate the input for 'in_region'
  if (!(in_region %in% c("us", "all states", "all counties", valid_state_names))) {
    return(
      c(
        "var 'in_region' needs to specify 'us', 'all states', or a valid state name",
        "valid state names: ",
        paste0(valid_state_names, collapse = ",")
      )
    )
  } else {
    # Validate the input for 'census_region_level'
    if (!(census_region_level %in% c("county", "state"))) {
      return(c(
        "var 'census_region_level' needs to specify 'state' or 'county'"
      ))
    } else {
      # Fetch metadata for Census 2020 PL endpoint
      dec_pl_endpoint_vars <- censusapi::listCensusMetadata(name = '2020/dec/pl', type = "variables")

      # Filter variables for P2_ (race-related variables)
      p2_vars <- dplyr::filter(dec_pl_endpoint_vars, grepl(pattern = "^P2_", name))

      # Fetch Census data for the specified region level
      p2_values <- censusapi::getCensus(
        name = "2020/dec/pl",
        vars = c("NAME", p2_vars$name),
        region = census_region_level
      )

      # Reshape the data to a long format for easier processing
      p2_values <- p2_values |>
        tidyr::pivot_longer(
          cols = starts_with("P2_"),
          names_to = 'name',
          values_to = 'value'
        ) |>
        dplyr::arrange(desc(value))

      # Join metadata with Census data and rename columns
      us_census_2020_race_details <- dec_pl_endpoint_vars |>
        dplyr::inner_join(p2_values, by = "name") |>
        dplyr::rename(region = NAME)

      # Add FIPS codes based on the region level
      if (census_region_level == "state") {
        us_census_2020_race_details <- us_census_2020_race_details |>
          dplyr::mutate(fips = state)
      } else {
        us_census_2020_race_details <- us_census_2020_race_details |>
          dplyr::mutate(fips = paste0(state, county))
      }

      # Process and clean the data
      us_census_2020_race_details <- us_census_2020_race_details |>
        dplyr::select(region, name, fips, label, group, attributes, value) |>
        dplyr::mutate(
          short_label = gsub(
            pattern = "!!Total:!!Not Hispanic or Latino:!!Population of two or more races:!!Population of ",
            replacement = "",
            x = label
          )
        ) |>
        dplyr::filter(!grepl(pattern = ":$", x = short_label)) |>
        dplyr::select(region, name, fips, short_label, value) |>
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

      # Adjust population counts for multiple races
      us_census_2020_race_details_race_num_adjusted_long <- us_census_2020_race_details |>
        dplyr::mutate(value_reported_race_adjusted = as.integer(value / num_reported_races)) |>
        tidyr::pivot_longer(
          names_to = "nmdp_race_code",
          values_to = "has_race_code",
          cols = c(HIS, NAM, API, AFA, CAU, UNK)
        ) |>
        dplyr::filter(has_race_code == TRUE)

      # Summarize multi-race population
      us_census_2020_race_details_race_num_adjusted_long_multirace <- us_census_2020_race_details_race_num_adjusted_long |>
        dplyr::filter(num_reported_races > 1) |>
        dplyr::group_by(region, fips, nmdp_race_code) |>
        dplyr::summarize(
          total_multiple_race_pop = sum(value_reported_race_adjusted),
          .groups = "keep"
        )

      # Summarize single-race population and combine with multi-race data
      us_pop_multirace_in_nmdp_codes <- us_census_2020_race_details_race_num_adjusted_long |>
        dplyr::filter(num_reported_races == 1) |>
        dplyr::group_by(region, fips, nmdp_race_code) |>
        dplyr::summarize(
          total_single_race_pop = sum(value_reported_race_adjusted),
          .groups = "keep"
        ) |>
        dplyr::full_join(
          us_census_2020_race_details_race_num_adjusted_long_multirace,
          by = c("region", "nmdp_race_code", "fips")
        ) |>
        dplyr::mutate_at(
          .vars = c("total_single_race_pop", "total_multiple_race_pop"),
          .funs = dplyr::coalesce,
          0
        ) |>
        dplyr::mutate(total_2020_pop = total_single_race_pop + total_multiple_race_pop)

      # Adjust the data based on the input region
      if (in_region == 'us') {
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::mutate(region = 'us') |>
          dplyr::group_by(region, nmdp_race_code) |>
          dplyr::summarize_all(sum) |>
          dplyr::mutate(census_region = "us")
      } else if (in_region == 'all states' & census_region_level == "state") {
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::mutate(census_region = region, region = 'all states')
      } else if (in_region == 'all states' & census_region_level != "state") {
        futile.logger::flog.info(
          "When in_region == 'all states' census_region_level must be set to 'state'. Switching to summary by state"
        )
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::mutate(region = stringr::str_split(region, ",") |> purrr::map_chr(2)) |>
          dplyr::group_by(region, nmdp_race_code) |>
          dplyr::summarize_all(sum) |>
          dplyr::rename("census_region" = region) |>
          dplyr::mutate(region = 'us')
      } else if (in_region == 'all counties' & census_region_level == "county") {
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::mutate(census_region = region, region = 'all counties')
      } else if (in_region == 'all counties' & census_region_level != "county") {
        futile.logger::flog.info(
          "When in_region == 'all counties' census_region_level must be set to 'county'. Switching to summary by state"
        )
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::mutate(census_region = "all states") |>
          dplyr::mutate(region = 'us')
      } else if (in_region %in% valid_state_names & census_region_level == "state") {
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::filter(region == in_region) |>
          dplyr::mutate(census_region = region) |>
          dplyr::mutate(region = 'us')
      } else if (in_region %in% valid_state_names & census_region_level == "county") {
        us_pop_multirace_in_nmdp_codes <- us_pop_multirace_in_nmdp_codes |>
          dplyr::filter(stringr::str_split(region, ", ") |> purrr::map_chr(2) == in_region) |>
          dplyr::mutate(census_region = region) |>
          dplyr::mutate(region = 'us')
      }

      # Ungroup the final data frame and return the result
      us_pop_multirace_in_nmdp_codes <- dplyr::ungroup(us_pop_multirace_in_nmdp_codes)
      return(us_pop_multirace_in_nmdp_codes)
    }
  }
}
