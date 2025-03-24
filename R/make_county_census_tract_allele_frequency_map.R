#' Make a plot by County of Census Tract Population corrected genotypic frequencies
#'
#' @param state_abbreviation 2-letter state abbreviation. E.g. 'TX'
#' @param county_code 3-digit county code. E.g. '157'
#' @param county_name County name. E.g. 'Fort Bend'
#' @param query_allele HLA allele to query. E.g. 'A*11:01'
#'
#' @return an_object
#' @export
#'
#' @examples  \dontrun{texus_fort_bend <- make_county_census_tract_allele_frequency_map(
#' state_abbreviation = 'TX',
#' query_allele = 'A*11:01',
#' county_code = '157',
#' county_name = 'Fort Bend'
#' )}
make_county_census_tract_allele_frequency_map <-  function(
    state_abbreviation,
    county_code,
    county_name,
    query_allele) {
  library(ggplot2)
  state_census_tract_frequencies <- calculate_county_census_tract_allele_frequencies(state_abbreviation, query_allele)
  nmdp_freq_subset <- state_census_tract_frequencies$nmdp_freq_subset
  sf_data <- state_census_tract_frequencies$sf_data

  out_data <- nmdp_freq_subset |>
    dplyr::ungroup() |>
    dplyr::filter(allele == query_allele) |>
    dplyr::group_by(region, state, county, tract, tract_name, loci, allele) |>
    dplyr::summarize(
      total_2020_pop = sum(total_2020_pop),
      us_2020_nmdp_gf_sum = sum(us_2020_nmdp_gf)
    ) |>
    dplyr::filter(!(is.na(us_2020_nmdp_gf_sum))) |>
    dplyr::mutate(us_2020_nmdp_gf_sum = ifelse(total_2020_pop >= 1000, us_2020_nmdp_gf_sum, NA)) |>
    dplyr::inner_join(sf_data,
                      by = c(
                        "tract" = "TRACTCE",
                        "county" = "COUNTYFP",
                        "state" = "STATEFP"
                      )) |>
    dplyr::filter(county == county_code)

  p1 <- out_data |>
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      aes(geometry = geometry,
          fill = us_2020_nmdp_gf_sum)
    ) +
    viridis::scale_fill_viridis(option = "plasma",
                                direction = 1) +
    labs(
      title = paste0(
        county_name,
        "\nCensus-Adjusted ",
        query_allele,
        " Genotypic frequency\nby Census Tract"
      ),
      fill = paste0(query_allele, " GF")
    ) +
    theme_minimal()
  return(list(
    out_data = out_data,
    p1 = p1))
}
