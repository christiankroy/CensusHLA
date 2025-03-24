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

# Function to download and unzip files with retry mechanism
download_and_unzip <- function(url, dest_dir, retries = 3, check_file = NULL) {
  file_name <- basename(url)
  dest_file <- file.path(dest_dir, file_name)
  
  # Check if the specific file already exists in the destination directory
  if (!is.null(check_file) && file.exists(file.path(dest_dir, check_file))) {
    message(paste("File", check_file, "already exists. Skipping download."))
    return()
  }
  
  # Check if the contents of the zip file already exist in the destination directory
  temp_file <- tempfile()
  download.file(url, temp_file, timeout = 300)  # Increase timeout to 300 seconds
  unzip_files <- unzip(temp_file, list = TRUE)$Name
  unlink(temp_file)
  
  if (all(file.exists(file.path(dest_dir, unzip_files)))) {
    message(paste("Contents of", file_name, "already exist. Skipping download."))
    return()
  }
  
  attempt <- 1
  success <- FALSE
  
  while (attempt <= retries && !success) {
    tryCatch({
      download.file(url, temp_file, timeout = 300)  # Increase timeout to 300 seconds
      unzip(temp_file, exdir = dest_dir)
      unlink(temp_file)
      success <- TRUE
    }, error = function(e) {
      message(paste("Attempt", attempt, "failed:", e$message))
      attempt <- attempt + 1
      if (attempt > retries) {
        stop(paste("Failed to download file after", retries, "attempts"))
      }
    })
  }
}

# Download and unzip the state file if `tl_2020_us_state.shp` is not present
download_and_unzip(tiger_state_ftp, state_dest_dir, check_file = "tl_2020_us_state.shp")

# Download and unzip the county file if `tl_2020_us_county.shp` is not present
download_and_unzip(tiger_county_ftp, county_dest_dir, check_file = "tl_2020_us_county.shp")

# Get the list of files from the FTP directory for tracts
file_list <- getURL(tiger_tract_ftp, ftp.use.epsv = FALSE, dirlistonly = TRUE)
file_list <- strsplit(file_list, "\r*\n")[[1]]
file_list <- file_list[file_list != ""]

# Download and unzip each tract file if `tl_2020_78_tract.shx` is not present
lapply(file_list, function(file) {
  if (!file.exists(file.path(tract_dest_dir, "tl_2020_78_tract.shx"))) {
    download_and_unzip(paste0(tiger_tract_ftp, file), tract_dest_dir)
  } else {
    message("File tl_2020_78_tract.shx already exists. Skipping download.")
  }
})