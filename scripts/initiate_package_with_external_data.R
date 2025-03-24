# Load necessary libraries
library(fs)

# Define file paths
file_paths <- c("inst/extdata/A.xlsx", "inst/extdata/B.xlsx", "inst/extdata/C.xlsx")

# Check if files exist
missing_files <- file_paths[!file_exists(file_paths)]

# If any files are missing, provide the URL to download them
if (length(missing_files) > 0) {
  cat("The following files are missing:\n")
  cat(paste(missing_files, collapse = "\n"), "\n")
  cat("Please download the files from https://frequency.nmdp.org/ and place them in the 'inst/extdata/' directory.\n")
} else {
  # If all files are present, run the rest of the R scripts in data-raw
  source("data-raw/import_gragert2013_data.R")
  source("data-raw/import_delNero2024_catchment.R")
  source("data-raw/import_census2020_tiger_shapefiles.R")
  source("data-raw/nmdp_racegroups.R")
  source("data-raw/valid_state_names.R")
  source("data-raw/us_pop_multirace_in_nmdp_codes.R")
  source("data-raw/nmdp_hla_frequencies_us_2020_census_adjusted.R")
  source("data-raw/census_adjusted_nmdp_hla_frequencies_by_state.R")
  source("data-raw/census_adjusted_nmdp_hla_frequencies_by_county.R")
  source("data-raw/add_catchment_calculations_and_data.R") 

  cat("All scripts have been successfully run.\n")
  # Now print that we're doing to document objects and functions in the package
  cat("Now documenting objects and functions in the package.\n")
  devtools::document(roclets = c('rd', 'collate', 'namespace', 'vignette'))
  cat("Documentation has been successfully generated.\n")
}