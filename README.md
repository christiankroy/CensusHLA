
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CensusHLA

<!-- badges: start -->

<!-- badges: end -->

# Setup

## Census API Key

- Get US Census API Code, Follow instructions
  [here](https://www.hrecht.com/censusapi/articles/getting-started.html#api-key-setup),
  get your key [here](http://api.census.gov/data/key_signup.html)

``` r
# Add key to .Renviron
# CENSUS_KEY=<YOUR CODE HERE>
```

## Gragert 2013 Frequency Data

``` r
# nmdp_a_freq <-
#   readxl::read_excel(path = "./inst/ext/nmdp-HLA-A-Frequencies.xlsx", sheet = "A")
# nmdp_b_freq <-
#   readxl::read_excel(path = "./inst/ext/nmdp-HLA-B-Frequencies.xlsx", sheet = "B")
# nmdp_c_freq <-
#   readxl::read_excel(path = "./inst/ext/nmdp-HLA-C-Frequencies.xlsx", sheet = "C")
```

## Catchment Spatial Files

‘/mnt/efs/prj/christian.roy/tiger_2020_census_tract_shape_files/tl_2020\_’,

## Prepare `data` files

Run `data-raw/*.R` files.

# Examples
