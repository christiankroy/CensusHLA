library(dplyr)
apis <- censusapi::listCensusApis()
#View(apis)
apis |>
  tibble::as_tibble() |>
  dplyr::filter(title == 'Decennial Census: Redistricting Data (PL 94-171)') |>
  dplyr::filter(vintage == 2020) |>
  t()

dec_pl_endpoint_url <-
  apis |> tibble::as_tibble() |> dplyr::filter(title == 'Decennial Census: Redistricting Data (PL 94-171)') |> dplyr::filter(vintage == 2020) |> dplyr::pull(url)
#Here we find what geography options there are for this table
censusapi::listCensusMetadata(name = '2020/dec/pl', type = "geography") |>
  tibble::as_tibble()
# We will use name=='us' here for the first call
#Grab all the vars for this API endpoint
dec_pl_endpoint_vars <- censusapi::listCensusMetadata(name = '2020/dec/pl', type = "variables")
# The P2 Table variables are we we're looking for.  So we'll grab those
p2_vars <-
  dplyr::filter(dec_pl_endpoint_vars, grepl(pattern = "^P2_", name))
# Here we'll grab the values for those vars
p2_values <-
  censusapi::getCensus(
    show_call = TRUE,
    name = "2020/dec/pl",
    vars =  p2_vars$name,
    region = "us"
  )
#vars =  c(p2_vars$name, "STATE"),
#region = "state") # here we can switch to state, but we''ll need to join to the values
## It gives you back State FIPS Code
colnames(p2_values)

p2_values  <-
  p2_values |>
  tidyr::pivot_longer(cols = dplyr::starts_with("P2_"),
                      names_to = 'name',
                      values_to = 'value') |>
  dplyr::arrange(desc(value))

# Now we make the detailed race table with sums I wish I could get from the API
us_census_2020_race_details <-
  dec_pl_endpoint_vars |>
  # Join the var labels to var values
  dplyr::inner_join(p2_values) |>
  # Only select some of the columns
  dplyr::select(name, label, group, attributes, value) |>
  # Trim off the leader for this information - duplicated in most cases
  dplyr::mutate(
    short_label = gsub(
      pattern = "!!Total:!!Not Hispanic or Latino:!!Population of two or more races:!!Population of ",
      replacement = "",
      x = label
    )
  ) |> #View()
  # Now all the records that end with a ':' are totals - we will make those again
  # Exception is hispanic - which still has a total, we use that later
  dplyr::filter(!grepl(pattern = ":$", x = short_label)) |> #View()
  # Now select just the columns we need
  dplyr::select(name, short_label, value) |>
  # Here we do a bunch of logical greps and case_whens to find mentions
  # of the number of races mentioned in the record
  dplyr::mutate(
    num_reported_races = dplyr::case_when(
      # One race is mentioned - gets a 1
      grepl(pattern = "one", x = short_label) ~ 1,
      # two gets a 2...
      grepl(pattern = "two", x = short_label) ~ 2,
      grepl(pattern = "three", x = short_label) ~ 3,
      grepl(pattern = "four", x = short_label) ~ 4,
      grepl(pattern = "five", x = short_label) ~ 5,
      grepl(pattern = "six", x = short_label) ~ 6,
      # This is the hispanic, and gets a 1
      grepl(pattern = "!!Total:!!Hispanic or Latino", x = short_label) ~ 1
    )
  ) |>
  dplyr::mutate(
    # Here we want to make a logical grid which identifies *which*
    # races are mentioned per row
    # Not immediately using this, but useful to have
    # First is whether or not it's multiple races, need this for AFND freq.
    MLT = ifelse(num_reported_races > 1, TRUE , 0),
    # Then we find if hispanic is mentioned
    HIS = grepl(pattern = " !!Total:!!Hispanic ", x = short_label),
    # And the rest
    NAM = grepl(pattern = "American Indian", x = short_label),
    API = grepl(pattern = "(Asian)|(Pacific)", x = short_label),
    #P_API = grepl(pattern = "Pacific",x = short_label),
    AFA = grepl(pattern = "Black or African American", x = short_label),
    CAU = grepl(pattern = "White", x = short_label),
    UNK = grepl(pattern = "Some Other", x = short_label)
  )
us_census_2020_race_details
# In order to match the BeTheMatch (nmdp) frequencies best, we need to sum up some of the multiple race records
us_census_2020_race_details_race_num_adjusted_long <-

  us_census_2020_race_details |>
  # Here we'll be simple and divide the overall count by the number of races reported
  # So single race records get /1, 2 races /2, etc.
  dplyr::mutate(value_reported_race_adjusted = as.integer(value / num_reported_races)) |>
  # Now we'll pivot the table so we can sum up on the occurance table
  tidyr::pivot_longer(
    names_to = "nmdp_race_code",
    values_to = "has_race_code",
    cols = c(HIS, NAM, API, AFA, CAU, UNK)
  ) |>
  # Some of these are empty combinations, we don't want to count those
  dplyr::filter(has_race_code == TRUE)
#Now we take the multi-race records, where we adjusted their counts by the number of reported races, and
#some by the AFND race codes we assigned to the label strings
us_census_2020_race_details_race_num_adjusted_long_multirace <-
  us_census_2020_race_details_race_num_adjusted_long |>
  # Filter for those with >1 race
  dplyr::filter(num_reported_races > 1) |>
  # Group by the BeTheMatch race codes
  dplyr::group_by(nmdp_race_code) |>
  # Sum the multi-race records by the race code
  # So here we're adding all *adjusted* counts with fractional counts of their
  # Assigned races, be they 2...6, so that we can count multi-race people people
  # *by race*.... not great, but a good way to catch the ~13M people that have
  # multiple races
  dplyr::summarize(total_multiple_race_pop = sum(value_reported_race_adjusted))
us_census_2020_race_details_race_num_adjusted_long_multirace
sum(
  us_census_2020_race_details_race_num_adjusted_long_multirace$total_multiple_race_pop
)
# Let's make our final table of counts and fractions to join
us_pop_multirace_in_nmdp_codes <-
  us_census_2020_race_details_race_num_adjusted_long |>
  # Filter for those with >1 race
  dplyr::filter(num_reported_races == 1) |>
  # Group by the BeTheMatch race codes
  dplyr::group_by(nmdp_race_code) |>
  dplyr::summarize(total_single_race_pop = sum(value_reported_race_adjusted)) |>
  dplyr::full_join(us_census_2020_race_details_race_num_adjusted_long_multirace) |>
  # Correct for NA from the HIS multi_race join (there is no HIS multirace)
  dplyr::mutate_if(is.numeric, coalesce, 0) |>
  # Add it all up!
  dplyr::mutate(total_2020_pop = total_single_race_pop + total_multiple_race_pop)

# So that's what we export
usethis::use_data(us_pop_multirace_in_nmdp_codes, overwrite = TRUE)
