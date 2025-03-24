#' Make a plot by State of County Population corrected genotypic frequencies
#'
#' @param state_name
#' @param query_allele
#'
#' @return an_object
#' @export
#'
#' @examples  \dontrun{ca_by_county <- make_state_by_county_allele_frequency_map(
#' state_name = 'Texas',
#' query_allele = 'A*11:01',
#' )}
make_state_by_county_allele_frequency_map <-  function(
    state_name,
    query_allele) {

  state_county_frequencies <-
    census_adjusted_nmdp_hla_frequencies_by_county |> dplyr::filter(state == state_name &
                                                                                 allele == query_allele)

  state_codes <- query_state_codes()
  state_code <- dplyr::filter(state_codes,STATE_NAME == state_name) |> dplyr::pull(STATEFP)


  shapefile_path <-    
      paste0(
        system.file(package = "CensusHLA"),
        "/extdata/tiger_2020/county/tl_2020_us_county.shp")
        
  sf_data <- sf::st_read(shapefile_path)

  out_data <- state_county_frequencies |>
    dplyr::ungroup() |>
    dplyr::filter(allele == query_allele) |>
    dplyr::group_by(region, state, census_region, county, fips, loci, allele) |>
    dplyr::summarize(
      us_2020_nmdp_gf_sum = sum(us_2020_nmdp_gf)
    ) |>
    dplyr::filter(!(is.na(us_2020_nmdp_gf_sum))) |>
    # Create a STATEFP and COUNTYFP column by breaking the fips column on the 3rd character to the end
    dplyr::mutate(
      STATEFP = substr(fips, 1, 2),
      COUNTYFP = substr(fips, 3, nchar(fips))
    ) |>
    #dplyr::mutate(us_2020_nmdp_gf_sum = ifelse(total_2020_pop >= 1000, us_2020_nmdp_gf_sum, NA)) |>
    dplyr::inner_join(sf_data)

  p1 <- out_data |>
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      aes(geometry = geometry,
          fill = us_2020_nmdp_gf_sum)
    ) +
    coord_sf() +
    viridis::scale_fill_viridis(option = "plasma",
                                direction = 1) +
    labs(
      title = paste0(
        state_name,
        "\nCensus-Adjusted ",
        query_allele
      ),
      fill = paste0(query_allele, " GF")
    ) +
    theme_minimal()
  return(list(
    out_data = out_data,
    p1 = p1))
}