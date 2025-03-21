nmdp_census_code_freq_names <-
  unique(nmdp_freq$nmdp_race_code)[!(unique(nmdp_freq$nmdp_race_code) %in% unique(nmdp_racegroups$nmdp_race_code))]

nmdp_freq_subset <-
  nmdp_hla_frequencies_by_race |>
  dplyr::filter(nmdp_race_code %in% nmdp_census_code_freq_names)

us_population_race_code_percentages <-
  us_pop_multirace_in_nmdp_codes |>
  dplyr::mutate(us_2020_percent_pop = total_2020_pop / sum(total_2020_pop))

nmdp_freq_subset <-
  nmdp_freq_subset |>
  dplyr::left_join(
    dplyr::select(
      us_population_race_code_percentages,
      nmdp_race_code,
      us_2020_percent_pop
    ),
    by = "nmdp_race_code"
  )

nmdp_hla_frequencies_by_race_us_2020_census_adjusted <- nmdp_freq_subset |>
    # Now we adjust the calculated genomic frequencies for the us population percentage
    dplyr::mutate(us_2020_nmdp_gf = nmdp_calc_gf * us_2020_percent_pop) |>
    #dplyr::mutate(us_2020_nmdp_gf = format(us_2020_nmdp_gf, scientific = FALSE)) |>
    dplyr::arrange(desc(us_2020_nmdp_gf))



nmdp_hla_frequencies_us_2020_census_adjusted <-
  # And now we will sum up the af by region and allele to give a us-level prepared dataset
  nmdp_hla_frequencies_by_race_us_2020_census_adjusted |>
  dplyr::group_by(region,loci,allele) |>
  dplyr::mutate(us_census_adjusted_af_by_race = nmdp_af * us_2020_percent_pop) |>
  # Sum up the us-pop adjusted by race allele frequencies
  # This get's us the US-level af
  dplyr::summarize(af = sum(us_census_adjusted_af_by_race), .groups = "keep") |>
  # Now calculate the genotypic frequency from this new us-level and census adjusted af
  dplyr::mutate(calc_gf = (1 - (1 - af) ^ 2)) |>
  dplyr::arrange(desc(calc_gf)) |>
  dplyr::ungroup()

nmdp_hla_frequencies_us_2020_census_adjusted <-
  nmdp_hla_frequencies_us_2020_census_adjusted |>
  dplyr::mutate(
    hla_source = 'us_census_adjusted_nmdp_summed_by_race'
  )

usethis::use_data(nmdp_hla_frequencies_us_2020_census_adjusted, overwrite = TRUE)

