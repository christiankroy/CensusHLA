#' Calculate a nmdp Genotypic Frequency table by Census Tracks within a state, adjusted to 2020 Census Population Data
#'
#' @param state_abbreviation A State 2-letter postal code
#' @param query_allele What HLA you'd like plotted from nmdp
#'
#' @return a list containing data to be plotted as a table and a ggplot plot of the census adjusted GF
#' @export
calculate_county_census_tract_allele_frequencies <-  function(
  state_abbreviation, query_allele) {

  

  state_codes <- query_state_codes()
  state_code <- dplyr::filter(state_codes,STATE == state_abbreviation) |> dplyr::pull(STATEFP)
  # Flog that we're working with a given state
  futile.logger::flog.info(paste0("Working with state: ", state_abbreviation))

  dec_pl_endpoint_vars <- censusapi::listCensusMetadata(name = '2020/dec/pl',
                                                        type = "variables")

  p2_vars <-
    dplyr::filter(dec_pl_endpoint_vars, group == "P2")

  p2_values <-
    censusapi::getCensus(
      region = "tract",
      regionin = paste0("state:", state_code),
      #show_call = TRUE,
      name = "2020/dec/pl",
      vars =  c("NAME", p2_vars$name)
    )

  p2_values <-
    p2_values |>
    tidyr::pivot_longer(cols = starts_with("P2_"),
                        names_to = 'name',
                        values_to = 'value') |>
    dplyr::arrange(desc(value))

  us_census_2020_race_details <-
    dec_pl_endpoint_vars |>
    # Join the var labels to var values
    dplyr::inner_join(p2_values, by = "name") |>
    dplyr::rename(tract_name = NAME)


  us_census_2020_race_details <-
    us_census_2020_race_details |>
    # Only select some of the columns
    dplyr::select(name,
                  tract_name,
                  state,
                  county,
                  tract,
                  label,
                  group,
                  attributes,
                  value) |>
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
    dplyr::select(name, state, county, tract, tract_name, short_label, value) |>
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
    dplyr::group_by(state, county, tract, tract_name, nmdp_race_code) |>
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
    dplyr::group_by(state, county, tract, tract_name, nmdp_race_code) |>
    dplyr::summarize(
      total_single_race_pop = sum(value_reported_race_adjusted),
      .groups = "keep"
    ) |>
    dplyr::full_join(
      us_census_2020_race_details_race_num_adjusted_long_multirace,
      by = c("state", "county", "tract", "tract_name", "nmdp_race_code")
    ) |>
    # Correct for NA from the HIS multi_race join (there is no HIS multirace)
    dplyr::mutate_at(
      .vars = c("total_single_race_pop", "total_multiple_race_pop"),
      .funs = dplyr::coalesce,
      0
    ) |>
    # Add it all up!
    dplyr::mutate(total_2020_pop = total_single_race_pop + total_multiple_race_pop)

  nmdp_freq <- nmdp_hla_frequencies_by_race |>
    dplyr::filter(allele %in% query_allele)

  nmdp_census_code_freq_names <-
    unique(nmdp_freq$nmdp_race_code)[!(
      unique(nmdp_freq$nmdp_race_code) %in% unique(nmdp_racegroups$nmdp_race_code)
    )]


  us_population_race_code_percentages <-
    us_pop_multirace_adjusted_in_nmdp_codes |>
    dplyr::mutate(census_region = tract) |>
    dplyr::group_by(state, county, census_region) |>
    dplyr::mutate(us_2020_percent_pop = total_2020_pop / sum(total_2020_pop))


  nmdp_freq_subset <-
    nmdp_freq |>
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
    )

  #Now we adjust the calculated genomic frequencies for the us population percentage
  nmdp_freq_subset <-
    nmdp_freq_subset |>
    dplyr::mutate(us_2020_nmdp_gf = nmdp_calc_gf * us_2020_percent_pop) |>
    dplyr::arrange(desc(us_2020_nmdp_gf))

  shapefile_path <-
    paste0(
      "/mnt/efs/prj/christian.roy/tiger_2020_census_tract_shape_files/",
      "tl_2020_",
      state_code,
      "_tract.shp"
    )
  sf_data <- st_read(shapefile_path)
  list(
    us_population_race_code_percentages = us_population_race_code_percentages,
    nmdp_freq_subset = nmdp_freq_subset,
    sf_data = sf_data,
    shapefile_path = shapefile_path)
}

