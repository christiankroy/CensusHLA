#' Valid State Names
#' @source US Census
#' @description List of the valid state names when using the Census API
'valid_state_names'

#' us_pop_multirace_adjusted_in_nmdp_codes
#' @source US census  - see data-raw/import_us_cenus_data.R
#' @description 2020 US Census counts per nmdp race code
#' @field nmdp_race_code - nmdp race code
#' @field total_single_race_pop Total individates identifying as only that race according to 2020 census
#' @field total_multiple_race_pop - For individuates identifying as multiple races, fractional persons were added to this count. A person identifying as 2 races was divded by 2, with 0.5 added to the corresponding race count, and so on for 3,4, and more races.
#' @field total_2020_pop Total 2020 census population (including single and multi-races identifying individuals)
'us_pop_multirace_adjusted_in_nmdp_codes'

#' nmdp_ethnicity_map
#' @source data-raw/import_nmdp_data.R
#' @description nmdp information on race groups/codes, Allele Frequency.net names, numbers, urls and links to deposited studies
#' @field nmdp_broad_race_group - Broad Race group
#' @field nmdp_race_code - More detailed race group
#' @field afnd_pop_name - Allele Frequency.net (afnd) population name
#' @field afnd_pop_number - Unique ID for each population name within afnd
#' @field afnd_start_url - URL linking to the study
#' @field afnd_pop_hla_a_link - URL linking to the AFND HLA A study for the given race
'nmdp_ethnicity_map'

#' nmdp_race_groups
#' @source data-raw/import_nmdp_data.R
#' @description - nmdp Racegroup information
#' @field nmdp_broad_race_group - Broad Race group
#' @field nmdp_race_code - More detailed race group
#' @field Detailed_Race_Ethnic_Description - More detailed wording describing the group
#' @field Count - Number of individuals typed
#' @field Typed  - Number typed for HLA-C
#' @field Typed_DQB1 - Number typed for BQB1
#' @field Typed_DRB3_4_5- Number typed
'nmdp_racegroups'


#' nmdp_census_adjustments
#' @source data-raw/import_nmdp_data.R
#' @description nmdp adjustments for given race groups based on 2010 census numbers and estimations
#' @field nmdp_broad_race_group - nmdp race codes
#' @field us_pop - 2010 US Census population per group
#' @field us_pop_pct - 2010 US Census percent of population per group
#' @field census_ad_source - Source of the estimations (options include martin and martin_2020_adj)
#' @field census_ad_source_pop_total - total for the given source - usefil to know the demoninator used.
'nmdp_census_adjustments'

#' nmdp_hla_frequencies_by_race
#' @source data-raw/import_nmdp_data.R
#' @description - An import of 3 tables, one per HLA loci (A,B, and C) of nmdp frequencies by race code.
#' @field region - these are all us data
#' @field loci - which of the HLAs - A,B, or C
#' @field allele - full HLA alllele name
#' @field is_g - nmdp included a trailing _g to account for multiple allele groupings - see Maiers2007 for details
#' @field nmdp_race_code - nmdp race code for the record
#' @field nmdp_af - nmdp Alleleic Frequency (_af) for the record
#' @field nmdp_calc_gf - Calculated Genotypic Frequency (_calc_gf) based on simple (1 - (1 - nmdp_af) ^ 2))
'nmdp_hla_frequencies_by_race'

#' nmdp_hla_frequencies_by_race_us_2020_census_adjusted
#' @source data-raw/adjust_nmdp_for_us_census.R
#' @description nmdp per race allelic frequencies adjusted for matching race group percent population in the US 2020 census. Also calculate genotypic frequencies.
#' @field region - What region is the data from? Right now just US
#' @field loci - What HLA Locus/Gene.  A,B, or C
#' @field allele - name of the allele out to two fields
#' @field is_g - allele regpresents multiple alleles - see Maiers2007. 0 or 1
#' @field nmdp_race_code - nmdp race code for the record - matched to the US Census population codes
#' @field nmdp_af - nmdp Alleleic Frequency (_af) for the record
#' @field nmdp_calc_gf - Calculated Genotypic Frequency (_calc_gf) based on simple (1 - (1 - nmdp_af) ^ 2))
#' @field us_2020_percent_pop - Percent population of the given race according to US 2020 Census
#' @field us_2020_nmdp_gf - nmdp_calc_gf * us_2020_percent_pop to give the us-census adjusted genotypic frequency for the allele and race
'nmdp_hla_frequencies_by_race_us_2020_census_adjusted'


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
'census_adjusted_nmdp_hla_frequencies_by_state'

#' A*11:01 Catchment Summed
#' @seealso data-raw/add_catchment_calculations_and_data.R
#' @source delNero2022
'a11_catchment_summed'

#' A*02:01 Catchment Summed
#' @seealso data-raw/add_catchment_calculations_and_data.R
#' @source delNero2022
'a02_catchment_summed'