# Create a data frame to store the mapping between NMDP codes and US Census race/ethnic terms
nmdp_census_term_mapping
 <- data.frame(
  NMDP_Code = c("AFA", "API", "CAU", "HIS", "NAM", "UNK", "MLT"),
  Census_Race_Ethnic_Term = c(
    "Black or African American",
    "Asian or Pacific Islander",
    "White",
    "Hispanic or Latino",
    "American Indian or Alaska Native",
    "Some Other Race",
    "Multi-Race (adjusted for individuals reporting multiple races)"
  ),
  stringsAsFactors = FALSE
)

usethis::use_data(nmdp_census_term_mapping, overwrite = TRUE)
