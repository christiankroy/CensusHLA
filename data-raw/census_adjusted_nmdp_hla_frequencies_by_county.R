frequencies_by_county <-
  lapply(names(valid_state_names), function(state) {
    futile.logger::flog.info("Processing ", state, capture = T)
    state_freq <-
      obtain_census_adjusted_nmdp_hla_frequencies_by_region(in_region = state, region_level = "county")
  })
names(frequencies_by_county) <- names(valid_state_names)

# Filter for the top 20 alleles by county
nmdp_freq_top_20 <-
  nmdp_hla_frequencies_us_2020_census_adjusted |>
  dplyr::group_by(allele, loci) |>
  dplyr::summarise(
    mean_nmdp_gf = mean(calc_gf),
    median_nmdp_gf = median(calc_gf)
  ) |>
  dplyr::group_by(loci) |>
  dplyr::mutate(rank_mean = rank(-mean_nmdp_gf),
                rank_median = rank(-median_nmdp_gf)) |>
  dplyr::filter(rank_median <= 20)

frequencies_by_county <-
  dplyr::bind_rows(frequencies_by_county, .id = "id") |>
  dplyr::filter(allele %in% unique(nmdp_freq_top_20$allele)) |>
  dplyr::mutate(county = stringr::str_split(census_region, ", ") |> purrr::map_chr(1)) |>
  dplyr::rename("state" = id)

census_adjusted_nmdp_hla_frequencies_by_county <- frequencies_by_county

usethis::use_data(census_adjusted_nmdp_hla_frequencies_by_county, overwrite = TRUE)



