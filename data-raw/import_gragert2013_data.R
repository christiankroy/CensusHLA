nmdp_a_freq <-
  readxl::read_excel(path = "./inst/extdata/A.xlsx", sheet = "A")
nmdp_b_freq <-
  readxl::read_excel(path = "./inst/extdata/B.xlsx", sheet = "B")
nmdp_c_freq <-
  readxl::read_excel(path = "./inst/extdata/C.xlsx", sheet = "C")

reformat_freq <- function(nmdp_freq_table, loci){
  nmdp_freq_table |>
    dplyr::rename(allele = loci) |>
    dplyr::select(allele, ends_with("_freq")) |>
    tidyr::pivot_longer(-allele,
                        names_to = "nmdp_race_code",
                        values_to = "nmdp_af") |>
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

nmdp_hla_frequencies_by_race <- nmdp_freq |> add_genotypic_frequency()

nmdp_hla_frequencies_by_race <-
  nmdp_hla_frequencies_by_race |>
  dplyr::mutate(is_g = ifelse(
    test = grepl(pattern = "g$", x = allele),
    yes = 1,
    no = 0
  )) |>
  dplyr::select(allele,is_g,everything()) |>
  dplyr::mutate(allele = gsub(pattern = "g$", replacement = "", x = allele)) |>
  dplyr::mutate(region = 'us') |>
  dplyr::mutate(loci = substr(allele,0,1)) |>
  dplyr::select(
    region, loci, allele,is_g, nmdp_race_code, everything())

usethis::use_data(nmdp_hla_frequencies_by_race,overwrite = TRUE)
