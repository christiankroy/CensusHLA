#' Valid State Names
#' @source US Census
#' @description List of the valid state names when using the Census API
'valid_state_names'

#' us_pop_multirace_in_nmdp_codes
#' @source US census  - see data-raw/import_us_cenus_data.R
#' @description 2020 US Census counts per nmdp race code
#' @field nmdp_race_code - nmdp race code
#' @field total_single_race_pop Total individates identifying as only that race according to 2020 census
#' @field total_multiple_race_pop - For individuates identifying as multiple races, fractional persons were added to this count. A person identifying as 2 races was divded by 2, with 0.5 added to the corresponding race count, and so on for 3,4, and more races.
#' @field total_2020_pop Total 2020 census population (including single and multi-races identifying individuals)
'us_pop_multirace_in_nmdp_codes'

#' nmdp_hla_frequencies_us_2020_census_adjusted
#' @source data-raw/adjust_nmdp_for_us_census.R
#' @description nmdp allele frequencies  adjusted by race according to the US census. This table contains those race-adjusted alleleic frequencies summed up so we have a us-level summarization
#' @field region - What region was considered
#' @field loci - -what loci A,B, or C
#' @field allele - What allele
#' @field af - US-census adjusted alleleic frequency (sum of us-census adjsuted by race afs)
#' @field calc_gf - genotypic frequencies calcualted from the af
#' @field hla_source - us_census_adjusted_nmdp_summed_by_race
'nmdp_hla_frequencies_us_2020_census_adjusted'

#' census_adjusted_nmdp_hla_frequencies_by_state
#' @source data-raw/census_adjusted_nmdp_hla_frequencies_by_state.R and obtain_census_adjusted_nmdp_hla_frequencies_by_region
#' @description - US Census-adjusted per nmdp race group hla allelic frequencies by State
#' @field region - What region
#' @field loci - what HLA loci
#' @field allele - what HLA allele
#' @field is_g - is group allele
#' @field nmdp_race_code - nmdp race code
#' @field nmdp_af - nmdp allelic frequiency
#' @field nmdp_calc_gf - nmdp genotypic frequency
#' @field fips - State fips
#' @field census_region - census region - in this case the state
#' @field us_2020_percent_pop - Percent of given race code population within the state
#' @field us_2020_nmdp_gf - adjusted genotypic frequency based on race pop percentage in the state
'census_adjusted_nmdp_hla_frequencies_by_state'

#' census_adjusted_nmdp_hla_frequencies_by_county
#' @source data-raw/census_adjusted_nmdp_hla_frequencies_by_state.R and obtain_census_adjusted_nmdp_hla_frequencies_by_region. This set is filter to contain the 10 more frequent alleles adjusted by population in the US.
#' @description - US Census-adjusted per nmdp race group hla allelic frequencies by State
#' @field state US State
#' @field region - What region
#' @field loci - what HLA loci
#' @field allele - what HLA allele
#' @field is_g - is group allele
#' @field nmdp_race_code - nmdp race code
#' @field nmdp_af - nmdp allelic frequiency
#' @field nmdp_calc_gf - nmdp genotypic frequency
#' @field fips - County fips
#' @field census_region - census region - in this case the county
#' @field us_2020_percent_pop - Percent of given race code population within the state
#' @field us_2020_nmdp_gf - adjusted genotypic frequency based on race pop percentage in the state
#' @field county US County
'census_adjusted_nmdp_hla_frequencies_by_county'

#' A*11:01 Catchment Summed
#' @seealso data-raw/add_catchment_calculations_and_data.R
#' @source delNero2022
'a11_catchment_summed'

