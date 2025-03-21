# Create a data frame that contains the nmdp race groups and save as a data file
input_workbook_path <- "./inst/extdata/hla_population_term_map.xlsx"
nmdp_racegroups <- readxl::read_excel(path = input_workbook_path, sheet = "nmdp_table1_racegroups")
usethis::use_data(nmdp_racegroups, overwrite = TRUE)
