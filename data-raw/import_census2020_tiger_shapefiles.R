# Load necessary library
library(RCurl)

# Define the FTP URLs for the TIGER 2020 shapefiles
tiger_state_ftp <- "ftp://ftp2.census.gov//geo/tiger/TIGER2020/STATE/tl_2020_us_state.zip"
tiger_county_ftp <- "ftp://ftp2.census.gov//geo/tiger/TIGER2020/COUNTY/tl_2020_us_county.zip"
tiger_tract_ftp <- "ftp://ftp2.census.gov//geo/tiger/TIGER2020/TRACT/"

# Destination directories
state_dest_dir <- "inst/extdata/tiger_2020/state/"
county_dest_dir <- "inst/extdata/tiger_2020/county/"
tract_dest_dir <- "inst/extdata/tiger_2020/tract/"

# Create the destination directories if they don't exist
dirs <- c(state_dest_dir, county_dest_dir, tract_dest_dir)
lapply(dirs, function(dir) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
})

# Set global timeout option
options(timeout = 3000)  # Increase timeout to 3000 seconds

# Function to download and unzip files
download_and_unzip <- function(url, dest_dir) {
  temp_file <- tempfile()
  download.file(url, temp_file, timeout = 300)  # Increase timeout to 300 seconds
  unzip(temp_file, exdir = dest_dir)
  unlink(temp_file)
}

# Download and unzip the state file
download_and_unzip(tiger_state_ftp, state_dest_dir)

# Download and unzip the county file
download_and_unzip(tiger_county_ftp, county_dest_dir)

# Get the list of files from the FTP directory for tracts
file_list <- getURL(tiger_tract_ftp, ftp.use.epsv = FALSE, dirlistonly = TRUE)
file_list <- strsplit(file_list, "\r*\n")[[1]]
file_list <- file_list[file_list != ""]

# Download and unzip each tract file
lapply(file_list, function(file) {
  download_and_unzip(paste0(tiger_tract_ftp, file), tract_dest_dir)
})
