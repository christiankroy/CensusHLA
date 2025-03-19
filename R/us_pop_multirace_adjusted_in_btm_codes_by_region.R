#' Obtain US Population numbers by nmdp Racecodes and by Region
#'
#' @return Data Frame of per nmdp Race code population numbers per input region
#' \itemize{
#'   \item region - used in downstream tables to denote regions - this is only US
#'   \item nmdp_race_code - Value used by nmdp to denote races in their studies
#'   \item total_single_race_pop - Sum of individuals in given region with given race code - who reported being just 1 race
#'   \item total_multiple_race_pop - Sum of individuals in given region with given race code - who reported being >1 race
#'   \item total_2020_pop - Sum of individuals (regardless of # of reported races), that included the given race on their report, by census_region
#'   \item census_region - function used in this function to call up US 2020 census data can be adjusted for states - if a state is chosen it is put here

#' }
#' @param in_region A string of either 'us', 'all states' (not useful), or a valid state name like 'Alaska'
#' @param census_region_level A string of either 'state' or 'county' to specify if the data for region should be divided by state or by county inside the state. The default is state.
#' @export
#' @examples us_pop_multirace_adjusted_in_nmdp_codes_by_region(in_region = 'Alaska')
us_pop_multirace_adjusted_in_nmdp_codes_by_region <- function(in_region, census_region_level = "state") {
  if (!(in_region %in% c("us", "all states", "all counties", valid_state_names)))
  {
    return(
      c(
        "var 'in_region' needs to specificy 'us', 'all states', or a valid state name",
        "valid state names: ",
        paste0(valid_state_names, collapse = ",")
      )
    )
  }  else {
    if (!(census_region_level %in% c("county", "state"))) {
      return(c(
        "var 'census_region_level' needs to specificy as 'state' or 'county'"
      ))
    } else{
      dec_pl_endpoint_vars <- censusapi::listCensusMetadata(name = '2020/dec/pl', type = "variables")

      p2_vars <-
        dplyr::filter(dec_pl_endpoint_vars, grepl(pattern = "^P2_", name))

      p2_values <-
        censusapi::getCensus(
          #show_call = TRUE,
          name = "2020/dec/pl",
          vars =  c("NAME", p2_vars$name),
          region = census_region_level
        )

      p2_values <-
        p2_values |>
        tidyr::pivot_longer(
          cols = starts_with("P2_"),
          names_to = 'name',
          values_to = 'value'
        ) |>
        dplyr::arrange(desc(value))

      us_census_2020_race_details <-
        dec_pl_endpoint_vars |>
        # Join the var labels to var values
        dplyr::inner_join(p2_values, by = "name") |>
        # RENAME the NAME column to region
        dplyr::rename(region = NAME)
      if (census_region_level == "state") {
        us_census_2020_race_details <- us_census_2020_race_details |>
          dplyr::mutate(fips = state)
      } else{
        us_census_2020_race_details <- us_census_2020_race_details |>
          dplyr::mutate(fips = paste0(state, county))
      }
      us_census_2020_race_details <- us_census_2020_race_details |>
        # Create a column with fips codes for counties
        # Only select some of the columns
        dplyr::select(region , name, fips, label, group, attributes, value) |>
        # Trim off the leader for this information - duplicated in most cases
        dplyr::mutate(
          short_label = gsub(
            pattern = "!!Total:!!Not Hispanic or Latino:!!Population of two or more races:!!Population of ",
            replacement = "",
            x = label
          )
        ) |> #View()
        # Now all the records that end with a ':' are totals - we will make those again
        # Exception is hispanic - which still has a total, we use that later
        dplyr::filter(!grepl(pattern = ":$", x = short_label)) |> #View()
        # Now select just the columns we need
        dplyr::select(region, name, fips, short_label, value) |>
        # Here we do a bunch of logical greps and case_whens to find mentions
        # of the number of races mentioned in the record
        dplyr::mutate(
          num_reported_races =  dplyr::case_when(
            # One race is mentioned - gets a 1
            grepl(pattern = "one", x = short_label) ~ 1,
            # two gets a 2...
            grepl(pattern = "two", x = short_label) ~ 2,
            grepl(pattern = "three", x = short_label) ~ 3,
            grepl(pattern = "four", x = short_label) ~ 4,
            grepl(pattern = "five", x = short_label) ~ 5,
            grepl(pattern = "six", x = short_label) ~ 6,
            # This is the hispanic, and gets a 1
            grepl(pattern = "!!Total:!!Hispanic or Latino", x = short_label) ~ 1
          )
        ) |>
        dplyr::mutate(
          # Here we want to make a logical grid which identifies *which*
          # races are mentioned per row
          # Not immediately using this, but useful to have
          # First is whether or not it's multiple races, need this for AFND freq.
          MLT = ifelse(num_reported_races > 1, TRUE , 0),
          # Then we find if hispanic is mentioned
          HIS = grepl(pattern = " !!Total:!!Hispanic ", x = short_label),
          # And the rest
          NAM = grepl(pattern = "American Indian", x = short_label),
          API = grepl(pattern = "(Asian)|(Pacific)", x = short_label),
          #P_API = grepl(pattern = "Pacific",x = short_label),
          AFA = grepl(pattern = "Black or African American", x = short_label),
          CAU = grepl(pattern = "White", x = short_label),
          UNK = grepl(pattern = "Some Other", x = short_label)
        )

      us_census_2020_race_details_race_num_adjusted_long <-
        us_census_2020_race_details |>
        # Here we'll be simple and divide the overall count by the number of races reported
        # So single race records get /1, 2 races /2, etc.
        dplyr::mutate(value_reported_race_adjusted = as.integer(value / num_reported_races)) |>
        # Now we'll pivot the table so we can sum up on the occurance table
        tidyr::pivot_longer(
          names_to = "nmdp_race_code",
          values_to = "has_race_code",
          cols = c(HIS, NAM, API, AFA, CAU, UNK)
        ) |>
        # Some of these are empty combinations, we don't want to count those
        dplyr::filter(has_race_code == TRUE)

      us_census_2020_race_details_race_num_adjusted_long_multirace <-
        us_census_2020_race_details_race_num_adjusted_long |>
        # Filter for those with >1 race
        dplyr::filter(num_reported_races > 1) |>
        # Group by the nmdp race codes
        dplyr::group_by(region, fips, nmdp_race_code) |>
        # Sum the multi-race records by the race code
        # So here we're adding all *adjusted* counts with fractional counts of their
        # Assigned races, be they 2...6, so that we can count multi-race people people
        # *by race*.... not great, but a good way to catch the ~13M people that have
        # multiple races
        dplyr::summarize(
          total_multiple_race_pop = sum(value_reported_race_adjusted),
          .groups = "keep"
        )

      us_pop_multirace_adjusted_in_nmdp_codes <-
        us_census_2020_race_details_race_num_adjusted_long |>
        # Filter for those with >1 race
        dplyr::filter(num_reported_races == 1) |>
        # Group by the nmdp race codes
        dplyr::group_by(region, fips, nmdp_race_code) |>
        dplyr::summarize(
          total_single_race_pop = sum(value_reported_race_adjusted),
          .groups = "keep"
        ) |>
        dplyr::full_join(
          us_census_2020_race_details_race_num_adjusted_long_multirace,
          by = c("region", "nmdp_race_code", "fips")
        ) |>
        # Correct for NA from the HIS multi_race join (there is no HIS multirace)
        dplyr::mutate_at(
          .vars = c("total_single_race_pop", "total_multiple_race_pop"),
          .funs = dplyr::coalesce,
          0
        ) |>
        # Add it all up!
        dplyr::mutate(total_2020_pop = total_single_race_pop + total_multiple_race_pop)


      if (in_region == 'us') {
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::mutate(region = 'us') |>
          dplyr::group_by(region, nmdp_race_code) |>
          dplyr::summarize_all(sum) |>
          dplyr::mutate(census_region = "us")
      } else if (in_region == 'all states' &
                 census_region_level == "state") {
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::mutate(census_region = region, region = 'all states')
      } else if (in_region == 'all states' &
                 census_region_level != "state") {
        futile.logger::flog.info(
          "When in_region == 'all states' census_region_level must be set to 'state'. Switching to summary by state"
        )
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::mutate(region = stringr::str_split(region, ",") |> purrr::map_chr(2)) |>
          dplyr::group_by(region, nmdp_race_code) |>
          dplyr::summarize_all(sum) |>
          dplyr::rename("census_region" = region) |>
          dplyr::mutate(region = 'us')
      } else if (in_region == 'all counties' &
                 census_region_level == "county") {
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::mutate(census_region = region, region = 'all counties')
      } else if (in_region == 'all counties' &
                 census_region_level != "county") {
        futile.logger::flog.info(
          "When in_region == 'all counties' census_region_level must be set to 'county'. Switching to summary by state"
        )
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::mutate(census_region = "all states") |>
          dplyr::mutate(region = 'us')
      } else if (in_region %in% valid_state_names &
                 census_region_level == "state") {
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::filter(region == in_region) |>
          dplyr::mutate(census_region = region) |>
          dplyr::mutate(region = 'us')
      } else if (in_region %in% valid_state_names &
                 census_region_level == "county") {
        us_pop_multirace_adjusted_in_nmdp_codes <-
          us_pop_multirace_adjusted_in_nmdp_codes |>
          dplyr::filter(stringr::str_split(region, ", ") |> purrr::map_chr(2) == in_region) |>
          dplyr::mutate(census_region = region) |>
          dplyr::mutate(region = 'us')
      }

      us_pop_multirace_adjusted_in_nmdp_codes <-
        dplyr::ungroup(us_pop_multirace_adjusted_in_nmdp_codes)

      return(us_pop_multirace_adjusted_in_nmdp_codes)
    }
  }
}
