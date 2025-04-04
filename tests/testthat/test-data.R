# File: tests/testthat/test-data.R

library(testthat)

test_that("valid_state_names dataset is loaded correctly", {
  data(valid_state_names, package = "CensusHLA")
  expect_true(exists("valid_state_names"))
  expect_type(valid_state_names, "character")
  expect_true(length(valid_state_names) > 0)
})

test_that("us_pop_multirace_in_nmdp_codes dataset structure is correct", {
  data(us_pop_multirace_in_nmdp_codes, package = "CensusHLA")
  expect_true(exists("us_pop_multirace_in_nmdp_codes"))
  expect_s3_class(us_pop_multirace_in_nmdp_codes, "data.frame")
  expect_named(us_pop_multirace_in_nmdp_codes, c(
    "nmdp_race_code", "total_single_race_pop",
    "total_multiple_race_pop", "total_2020_pop"
  ))
  expect_type(us_pop_multirace_in_nmdp_codes$nmdp_race_code, "character")
  expect_type(us_pop_multirace_in_nmdp_codes$total_single_race_pop, "double")
  expect_type(us_pop_multirace_in_nmdp_codes$total_multiple_race_pop, "double")
  expect_type(us_pop_multirace_in_nmdp_codes$total_2020_pop, "double")
})

test_that("nmdp_hla_frequencies_us_2020_census_adjusted dataset structure is correct", {
  data(nmdp_hla_frequencies_us_2020_census_adjusted, package = "CensusHLA")
  expect_true(exists("nmdp_hla_frequencies_us_2020_census_adjusted"))
  expect_s3_class(nmdp_hla_frequencies_us_2020_census_adjusted, "data.frame")
  expect_named(nmdp_hla_frequencies_us_2020_census_adjusted, c(
    "region", "loci", "allele", "af", "calc_gf", "hla_source"
  ))
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$region, "character")
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$loci, "character")
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$allele, "character")
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$af, "double")
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$calc_gf, "double")
  expect_type(nmdp_hla_frequencies_us_2020_census_adjusted$hla_source, "character")
})

test_that("nmdp_hla_frequencies_by_race_us_2020_census_adjusted dataset structure is correct", {
  data(nmdp_hla_frequencies_by_race_us_2020_census_adjusted, package = "CensusHLA")
  expect_true(exists("nmdp_hla_frequencies_by_race_us_2020_census_adjusted"))
  expect_s3_class(nmdp_hla_frequencies_by_race_us_2020_census_adjusted, "data.frame")
  expect_named(nmdp_hla_frequencies_by_race_us_2020_census_adjusted, c(
    "region", "loci", "allele", "is_g", "nmdp_race_code",
    "nmdp_af", "nmdp_calc_gf", "us_2020_percent_pop", "us_2020_nmdp_gf"
  ))
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$region, "character")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$loci, "character")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$allele, "character")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$is_g, "double")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$nmdp_race_code, "character")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$nmdp_af, "double")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$nmdp_calc_gf, "double")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$us_2020_percent_pop, "double")
  expect_type(nmdp_hla_frequencies_by_race_us_2020_census_adjusted$us_2020_nmdp_gf, "double")
})

test_that("nmdp_census_term_mapping dataset is loaded correctly", {
  data(nmdp_census_term_mapping, package = "CensusHLA")
  expect_true(exists("nmdp_census_term_mapping"))
  expect_s3_class(nmdp_census_term_mapping, "data.frame")
  expect_true(nrow(nmdp_census_term_mapping) > 0)
})
