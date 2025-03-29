# a11_catchment_summed <-
#   summarize_tract_genotypic_frequencies_by_delNero2022_catchment(query_allele = 'A*11:01')
# usethis::use_data(a11_catchment_summed, overwrite = TRUE)
library(CensusHLA)
b58_catchment_summed <-
  summarize_tract_genotypic_frequencies_by_delNero2022_catchment(query_allele = 'B*58:01')
 usethis::use_data(b58_catchment_summed,overwrite = TRUE)
a02_catchment_summed <-
  summarize_tract_genotypic_frequencies_by_delNero2022_catchment(query_allele = 'A*02:01')
usethis::use_data(a02_catchment_summed, overwrite = TRUE)
