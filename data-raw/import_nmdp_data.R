input_workbook_path <- "./inst/ext/hla_population_term_map.xlsx"
nmdp_ethnicity_map <- readxl::read_excel(path = input_workbook_path,sheet = "ethnicity_map")
nmdp_racegroups <- readxl::read_excel(path = input_workbook_path,sheet = "nmdp_table1_racegroups")
nmdp_census_adjustments <- readxl::read_excel(path = input_workbook_path,sheet = "census_adjustments_nmdp")
usethis::use_data(nmdp_ethnicity_map,overwrite = TRUE)
usethis::use_data(nmdp_racegroups,overwrite = TRUE)
usethis::use_data(nmdp_census_adjustments,overwrite = TRUE)

nmdp_a_freq <-
  readxl::read_excel(path = "./inst/ext/nmdp-HLA-A-Frequencies.xlsx", sheet = "A")
nmdp_b_freq <-
  readxl::read_excel(path = "./inst/ext/nmdp-HLA-B-Frequencies.xlsx", sheet = "B")
nmdp_c_freq <-
  readxl::read_excel(path = "./inst/ext/nmdp-HLA-C-Frequencies.xlsx", sheet = "C")

reformat_freq <- function(nmdp_freq_table, loci){
  nmdp_freq_table %>%
    dplyr::rename(allele = loci) %>%
    dplyr::select(allele, ends_with("_freq")) %>%
    tidyr::pivot_longer(-allele,
                        names_to = "nmdp_race_code",
                        values_to = "nmdp_af") %>%
    dplyr::mutate(nmdp_race_code = gsub(
      pattern = "_freq$",
      replacement = "",
      x = nmdp_race_code
    ))
}
nmdp_a_freq <- reformat_freq(nmdp_a_freq,"A")
nmdp_b_freq <- reformat_freq(nmdp_b_freq,"B")
nmdp_c_freq <- reformat_freq(nmdp_c_freq,"C")

nmdp_freq <- rbind(nmdp_a_freq,nmdp_b_freq,nmdp_c_freq)

add_genotypic_frequency <- function(intable){
  dplyr::mutate(intable,nmdp_calc_gf = (1 - (1 - nmdp_af) ^ 2))
}

nmdp_hla_frequencies_by_race <- nmdp_freq %>% add_genotypic_frequency()

nmdp_hla_frequencies_by_race <-
  nmdp_hla_frequencies_by_race %>%
  dplyr::mutate(is_g = ifelse(
    test = grepl(pattern = "g$", x = allele),
    yes = 1,
    no = 0
  )) %>%
  dplyr::select(allele,is_g,everything()) %>%
  dplyr::mutate(allele = gsub(pattern = "g$", replacement = "", x = allele)) %>%
  dplyr::mutate(region = 'us') %>%
  dplyr::mutate(loci = substr(allele,0,1)) %>%
  dplyr::select(
    region, loci, allele,is_g, nmdp_race_code, everything())

#nmdp_hla_frequencies_by_race

usethis::use_data(nmdp_hla_frequencies_by_race,overwrite = TRUE)
