#' Valid State Names
#'
#' @description A dataset containing the list of valid state names used when interacting with the US Census API. 
#' This ensures consistency and accuracy when querying state-level data.
#' 
#' @source US Census
"valid_state_names"

#' US Population by Multi-Race in NMDP Codes
#'
#' @description A dataset providing the 2020 US Census population counts categorized by NMDP race codes. 
#' It includes both single-race and multi-race populations, with fractional adjustments for individuals identifying with multiple races.
#' 
#' @field nmdp_race_code NMDP race code.
#' @field total_single_race_pop Total population identifying as only that race according to the 2020 Census.
#' @field total_multiple_race_pop Total population identifying as multiple races, adjusted fractionally. 
#'        For example, a person identifying as two races contributes 0.5 to each race's count.
#' @field total_2020_pop Total 2020 Census population, including both single-race and multi-race individuals.
#' 
#' @source US Census - see `data-raw/import_us_census_data.R`
"us_pop_multirace_in_nmdp_codes"

#' NMDP HLA Frequencies Adjusted by US 2020 Census
#'
#' @description A dataset containing NMDP allele frequencies adjusted by race according to the 2020 US Census. 
#' The data provides a US-level summary of race-adjusted allelic frequencies, including calculated genotypic frequencies.
#' 
#' @field region The region considered (e.g., US-level).
#' @field loci The HLA loci (e.g., A, B, or C).
#' @field allele The specific HLA allele.
#' @field af US Census-adjusted allelic frequency, calculated as the sum of race-adjusted frequencies.
#' @field calc_gf Genotypic frequencies calculated from the adjusted allelic frequencies.
#' @field hla_source The source of the data, indicating it was derived from `us_census_adjusted_nmdp_summed_by_race`.
#' 
#' @source See `data-raw/adjust_nmdp_for_us_census.R`
"nmdp_hla_frequencies_us_2020_census_adjusted"
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


#' NMDP HLA Frequencies by Race (US 2020 Census Adjusted)
#'
#' This dataset contains HLA allele frequencies adjusted based on the 2020 US Census data. 
#' It provides information on allele frequencies across different racial groups as defined 
#' by the National Marrow Donor Program (NMDP).
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{region}{Geographical region associated with the data.}
#'   \item{loci}{HLA loci (e.g., A, B, C, DRB1).}
#'   \item{allele}{HLA allele name.}
#'   \item{is_g}{Indicator if the allele is a G group (logical).}
#'   \item{nmdp_race_code}{Race code as defined by the NMDP.}
#'   \item{nmdp_af}{Allele frequency as reported by the NMDP.}
#'   \item{nmdp_calc_gf}{Genotype frequency calculated by the NMDP.}
#'   \item{us_2020_percent_pop}{Percentage of the US population in 2020 for the given race.}
#'   \item{us_2020_nmdp_gf}{Genotype frequency adjusted for the 2020 US Census population.}
#' }
#'
#' @details
#' This dataset is useful for analyzing HLA allele distributions and their representation 
#' across different racial groups in the US, adjusted for the 2020 Census population data. 
#' It can be used in studies related to population genetics, transplantation, and donor 
#' matching.
#'
#' @source National Marrow Donor Program (NMDP) and US Census 2020 data. and nmdp_hla_frequencies_us_2020_census_adjusted.R
'nmdp_hla_frequencies_by_race_us_2020_census_adjusted'