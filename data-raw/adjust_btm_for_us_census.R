# requires data-raw/import_bethemnatch_data.R and data-raw/import_us_census_data.R first
btm_freq <- affincases::btm_hla_frequencies_by_race
btm_racegroups <- affincases::btm_racegroups
us_pop_multirace_adjusted_in_btm_codes <- affincases::us_pop_multirace_adjusted_in_btm_codes

unique(btm_freq$btm_race_code)
table(unique(btm_freq$btm_race_code) %in% unique(btm_racegroups$btm_race_code))
unique(btm_freq$btm_race_code)[!(unique(btm_freq$btm_race_code) %in% unique(btm_racegroups$btm_race_code))]
# Wow - so these are included in here as race_codes, even though according to table 1 they are race_groups.
#
# We're going to move forward with the 5 labels which are more akin to 'race groups', but which match populations in the US census, and for which also we have alleleic frequencies from BTM.
btm_census_code_freq_names <-
  unique(btm_freq$btm_race_code)[!(unique(btm_freq$btm_race_code) %in% unique(btm_racegroups$btm_race_code))]
btm_census_code_freq_names
btm_freq_subset <-
  btm_freq %>%
  dplyr::filter(btm_race_code %in% btm_census_code_freq_names)
unique(btm_freq_subset$btm_race_code)

# We're going to calculate a percentage of the US population in 2020 so we can multiply the calculate gf to get a genotype frequency adjusted for the overall US population by race code
us_population_race_code_percentages <-
  # Now we need to join the `btm_race_code`-matched US Census data.  For this see `data-raw/import_us_census_data.R`
  us_pop_multirace_adjusted_in_btm_codes %>%
  dplyr::mutate(us_2020_percent_pop = total_2020_pop / sum(total_2020_pop))
btm_freq_subset <-
  btm_freq_subset %>%
  dplyr::left_join(
    dplyr::select(
      us_population_race_code_percentages,
      btm_race_code,
      us_2020_percent_pop
    ),
    by = "btm_race_code"
  )
btm_freq_subset

(btm_hla_frequencies_by_race_us_2020_census_adjusted <- btm_freq_subset %>%
    # Now we adjust the calculated genomic frequencies for the us population percentage
    dplyr::mutate(us_2020_btm_gf = btm_calc_gf * us_2020_percent_pop) %>%
    #dplyr::mutate(us_2020_btm_gf = format(us_2020_btm_gf, scientific = FALSE)) %>%
    dplyr::arrange(desc(us_2020_btm_gf))
  )
#btm_hla_frequencies_by_race_us_2020_census_adjusted

btm_hla_frequencies_us_2020_census_adjusted <-
# And now we will sum up the af by region and allele to give a us-level prepared dataset
  btm_hla_frequencies_by_race_us_2020_census_adjusted |>
  dplyr::group_by(region,loci,allele) |>
  dplyr::mutate(us_census_adjusted_af_by_race = btm_af * us_2020_percent_pop) |>
  # Sum up the us-pop adjusted by race allele frequencies
  # This get's us the US-level af
  dplyr::summarize(af = sum(us_census_adjusted_af_by_race), .groups = "keep") |>
  # Now calculate the genotypic frequency from this new us-level and census adjusted af
  dplyr::mutate(calc_gf = (1 - (1 - af) ^ 2)) |>
  dplyr::arrange(desc(calc_gf)) |>
  dplyr::ungroup()

btm_hla_frequencies_us_2020_census_adjusted <-
  btm_hla_frequencies_us_2020_census_adjusted |>
  dplyr::mutate(
    hla_source = 'us_census_adjusted_btm_summed_by_race'
  )

usethis::use_data(btm_hla_frequencies_us_2020_census_adjusted, overwrite = TRUE)

