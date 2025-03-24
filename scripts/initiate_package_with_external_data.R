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
  if (!file_exists("inst/extdata/delNero2022/NCI_Catchment_Areas_fall2024.shp")) {
    futile.logger::flog.info("Downloading data for delNero2022 Catchment")
    source("data-raw/import_delNero2024_catchment.R")
  } else {
    futile.logger::flog.info("delNero2022 Catchment data already exists")
  }
  futile.logger::flog.info("Downloading data for Census 2020")
  source("data-raw/import_census2020_tiger_shapefiles.R")
  source("data-raw/nmdp_racegroups.R")
  source("data-raw/valid_state_names.R")
  source("data-raw/us_pop_multirace_in_nmdp_codes.R")
  # US-wide
  devtools::load_all()
  #devtools::document(roclets = c('rd', 'collate', 'namespace', 'vignette'))
  source("data-raw/nmdp_hla_frequencies_us_2020_census_adjusted.R")
  # Futile logg that we're calculated by state
  futile.logger::flog.info("Calculating HLA frequencies by state")
  # State
  if (!file_exists("data/census_adjusted_nmdp_hla_frequencies_by_state.rda")) {
    futile.logger::flog.info("Calculating HLA frequencies by state")
    source("data-raw/census_adjusted_nmdp_hla_frequencies_by_state.R")
  } else {
    futile.logger::flog.info("census_adjusted_nmdp_hla_frequencies_by_state.rda already exists")
  }
  # County
  if (!file_exists("data/census_adjusted_nmdp_hla_frequencies_by_county.rda")) {
    futile.logger::flog.info("Calculating HLA frequencies by county")
    source("data-raw/census_adjusted_nmdp_hla_frequencies_by_county.R")
  } else {
    futile.logger::flog.info("census_adjusted_nmdp_hla_frequencies_by_county.rda already exists")
  }

  # Catchment
  if (!file_exists("data/a11_catchment_summed.rda")) {
    futile.logger::flog.info("Calculating a11 catchment areas")
    source("data-raw/add_catchment_calculations_and_data.R")
  } else {
    futile.logger::flog.info("a11_catchment_summed.rda already exists")
  }
  cat("All scripts have been successfully run.\n")
  # Now print that we're doing to document objects and functions in the package
  cat("Now documenting objects and functions in the package.\n")
}
