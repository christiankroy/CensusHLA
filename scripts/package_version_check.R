# Define the required packages and their minimum versions
required_packages <- list(
  tidyverse = "1.3.1",
  ggplot2 = "3.3.5",
  rmarkdown = "2.14",
  testthat = "3.1.4",
  knitr = "1.49",
  assertthat = "0.2.1",
  data.table = "1.14.2",
  forcats = "0.5.1",
  usmap = "0.6.0",
  h3jsr = "1.0.0",
  sf = "1.0-8",
  rnaturalearth = "0.1.0",
  RCurl = "1.98-1.6",
  DT = "0.20",
  dplyr = "1.0.9",
  futile.logger = "1.4.3",
  usethis = "2.1.6",
  censusapi = "0.8.0",
  viridis = "0.6.2",
  tigris = "1.5",
  crayon = "1.5.1",
  tibble = "3.1.7",
  tidyr = "1.2.0",
  stringr = "1.4.0",
  janitor = "2.1.0",
  readr = "2.1.3",
  readxl = "1.4.1",
  purrr = "0.3.4",
  pkgdown = "2.0.6",
  todor = "0.1.2",
  broom = "1.0.1",
  fs = "1.5.2"
)

# Initialize an empty data frame to store packages that do not meet the criteria
packages_to_follow_up <- data.frame(
  Package = character(),
  InstalledVersion = character(),
  RequiredVersion = character(),
  stringsAsFactors = FALSE
)

# Check each package
for (pkg in names(required_packages)) {
  required_version <- required_packages[[pkg]]
  
  # Check if the package is installed
  if (pkg %in% rownames(installed.packages())) {
    installed_version <- as.character(packageVersion(pkg))
    
    # Compare versions if a minimum version is specified
    if (!is.na(required_version) && installed_version < required_version) {
      packages_to_follow_up <- rbind(packages_to_follow_up, data.frame(
        Package = pkg,
        InstalledVersion = installed_version,
        RequiredVersion = required_version,
        stringsAsFactors = FALSE
      ))
    }
  } else {
    packages_to_follow_up <- rbind(packages_to_follow_up, data.frame(
      Package = pkg,
      InstalledVersion = "Not Installed",
      RequiredVersion = required_version,
      stringsAsFactors = FALSE
    ))
  }
}

# Print the data frame with packages to follow up
print(packages_to_follow_up)