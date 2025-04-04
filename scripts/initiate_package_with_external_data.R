# Load necessary libraries
library(fs)  # For file system operations

# Define file paths for required external data files
file_paths <- c("inst/extdata/A.xlsx", "inst/extdata/B.xlsx", "inst/extdata/C.xlsx")

# Check if the required files exist in the specified paths
missing_files <- file_paths[!file_exists(file_paths)]

# If any files are missing, notify the user and provide instructions to download them
if (length(missing_files) > 0) {
  cat("The following files are missing:\n")  # Inform the user about missing files
  cat(paste(missing_files, collapse = "\n"), "\n")  # List missing files
  cat("Please download the files from https://frequency.nmdp.org/ and place them in the 'inst/extdata/' directory.\n")
} else {
  # If all required files are present, proceed with running the necessary scripts

  # Import data from Gragert 2013 study
  source("data-raw/import_gragert2013_data.R")

  # Check if delNero2022 Catchment shapefile exists; if not, download and process it
  if (!file_exists("inst/extdata/delNero2022/NCI_Catchment_Areas_fall2024.shp")) {
    futile.logger::flog.info("Downloading data for delNero2022 Catchment")  # Log the action
    source("data-raw/import_delNero2024_catchment.R")  # Run the script to download and process the data
  } else {
    futile.logger::flog.info("delNero2022 Catchment data already exists")  # Log that the data is already available
  }

  # Download and process Census 2020 TIGER shapefiles
  futile.logger::flog.info("Downloading data for Census 2020")
  source("data-raw/import_census2020_tiger_shapefiles.R")

  # Run scripts for additional data processing and validation
  source("data-raw/nmdp_racegroups.R")  # Process NMDP race groups
  source("data-raw/valid_state_names.R")  # Validate state names
  source("data-raw/us_pop_multirace_in_nmdp_codes.R")  # Process US population data for multi-race groups

  # Load all package functions and data
  devtools::load_all()

  # Process HLA frequencies adjusted for the 2020 Census
  source("data-raw/nmdp_hla_frequencies_us_2020_census_adjusted.R")

  # Calculate HLA frequencies by state if the data file doesn't already exist
  if (!file_exists("data/census_adjusted_nmdp_hla_frequencies_by_state.rda")) {
    futile.logger::flog.info("Calculating HLA frequencies by state")
    source("data-raw/census_adjusted_nmdp_hla_frequencies_by_state.R")
  } else {
    futile.logger::flog.info("census_adjusted_nmdp_hla_frequencies_by_state.rda already exists")
  }

  # Calculate HLA frequencies by county if the data file doesn't already exist
  if (!file_exists("data/census_adjusted_nmdp_hla_frequencies_by_county.rda")) {
    futile.logger::flog.info("Calculating HLA frequencies by county")
    source("data-raw/census_adjusted_nmdp_hla_frequencies_by_county.R")
  } else {
    futile.logger::flog.info("census_adjusted_nmdp_hla_frequencies_by_county.rda already exists")
  }

  # Perform calculations for catchment areas if the data file doesn't already exist
  if (!file_exists("data/a11_catchment_summed.rda")) {
    futile.logger::flog.info("Calculating a11 catchment areas")
    source("data-raw/add_catchment_calculations_and_data.R")
  } else {
    futile.logger::flog.info("a11_catchment_summed.rda already exists")
  }

  # Notify the user that all scripts have been successfully executed
  cat("All scripts have been successfully run.\n")
  
}
