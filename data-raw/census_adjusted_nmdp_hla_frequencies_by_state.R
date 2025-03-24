census_adjusted_nmdp_hla_frequencies_by_state <-
  lapply(names(valid_state_names), function(state) {
    futile.logger::flog.info("Processing ", state, capture = T)
    state_freq <-
      obtain_census_adjusted_nmdp_hla_frequencies_by_region(in_region = state)
  })

census_adjusted_nmdp_hla_frequencies_by_state <-
  dplyr::bind_rows(census_adjusted_nmdp_hla_frequencies_by_state)
usethis::use_data(census_adjusted_nmdp_hla_frequencies_by_state, overwrite = TRUE)

