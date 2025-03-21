#' Obtain US Census-adjusted nmdp Alleleic Frequencies by Region
#'
#' @return Data Frame of US Census Adjusted HLA Alleleic Frequencies
#' \itemize{
#'   \item allele - the Allele in question
#'   \item is_g - This trailing `g` on some of the alleles to include they are inclusive of multiple alleles ( see Maiers2007 for details)
#'   \item nmdp_race_code - Value used by nmdp to denote races in their studies
#'   \item nmdp_af - Allelic frequency measured by nmdp within a race
#'   \item nmdp_calc_gf - Genotypic frequency calculated righ toff the allelic frequency using hardy-weinburg
#'   \item region - used in downstream tables to denote regions - this is only US
#'   \item census_region - function used in this function to call up US 2020 census data can be adjusted for states - if a state is chosen it is put here
#'   \item us_2020_percent_pop - percentage of the overall population with the given nmdp code in a given region. Should sum close to 1 for a specific HLA Allele
#'   \item us_2020_nmdp_gf - The US-Census race-adjusted genotypic frequency value - used in downstream applications
#' }
#' @param in_region A string of either 'us', 'all states' (not useful), or a valid state name like 'Alaska'
#' @note - relies on preprocessing performed in 'preprocessing/nmdpFrequencies.Rmd'
#' @export
#' @examples obtain_census_adjusted_nmdp_hla_frequencies_by_region(in_region = 'Alaska')
obtain_census_adjusted_nmdp_hla_frequencies_by_region <- function(in_region, region_level = "state") {
  # See data-raw/adjust_nmdp_for_us_census for this workflow applied to whole US as a pre-computed table
  # making it a function which adjusted for per state us census values

  if (!(in_region %in% c("us", "all states", valid_state_names)))
  {
    return(
      c(
        "var 'in_region' needs to specificy 'us', 'all states', or a valid state name",
        "valid state names: ",
        paste0(valid_state_names, collapse = ",")
      )
    )
  }  else {
    nmdp_freq <- nmdp_hla_frequencies_by_race

    nmdp_census_code_freq_names <-
      unique(nmdp_freq$nmdp_race_code)[!(unique(nmdp_freq$nmdp_race_code) %in% unique(nmdp_racegroups$nmdp_race_code))]


    us_population_race_code_percentages <-
      us_pop_multirace_in_nmdp_codes_by_region(in_region, census_region_level = region_level) |>
      dplyr::group_by(census_region) |>
      dplyr::mutate(us_2020_percent_pop = total_2020_pop / sum(total_2020_pop))


    nmdp_freq_subset <-
      nmdp_freq |>
      dplyr::filter(nmdp_race_code %in% nmdp_census_code_freq_names) |>
      dplyr::left_join(
        dplyr::select(
          us_population_race_code_percentages,
          fips,
          region,
          census_region,
          nmdp_race_code,
          us_2020_percent_pop
        ),
        by = c("region", "nmdp_race_code")
      )

    #Now we adjust the calculated genomic frequencies for the us population percentage
    nmdp_freq_subset <-
      nmdp_freq_subset |>
      dplyr::mutate(us_2020_nmdp_gf = nmdp_calc_gf * us_2020_percent_pop) |>
      dplyr::arrange(desc(us_2020_nmdp_gf))

    nmdp_hla_a_frequencies_us_2020_census_adjusted <- nmdp_freq_subset

    return(nmdp_hla_a_frequencies_us_2020_census_adjusted)
  }
}
