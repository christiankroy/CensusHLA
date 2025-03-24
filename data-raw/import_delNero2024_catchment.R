# URLs to download
urls <- c(
  "https://gis.cancer.gov/ncicatchment/cb_2020_us_county_500k.zip",
  "https://gis.cancer.gov/ncicatchment/NCI_Catchment_Areas_fall2024.zip",
  "https://gis.cancer.gov/ncicatchment/cb_2020_us_county_500k.zip"
)

# Destination directory
dest_dir <- "inst/extdata/delNero2022"

# Create the destination directory if it doesn't exist
if (!dir.exists(dest_dir)) {
  dir.create(dest_dir, recursive = TRUE)
}

# Function to download and unzip files
download_and_unzip <- function(url, dest_dir) {
  temp_file <- tempfile()
  download.file(url, temp_file)
  unzip(temp_file, exdir = dest_dir)
  unlink(temp_file)
}

# Download and unzip each file
lapply(urls, download_and_unzip, dest_dir = dest_dir)
