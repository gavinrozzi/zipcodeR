
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zipcodeR <a href='https://gavinrozzi.github.io/zipcodeR/'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/gavinrozzi/zipcodeR/workflows/R-CMD-check/badge.svg)](https://github.com/gavinrozzi/zipcodeR/actions)
[![codecov](https://codecov.io/gh/gavinrozzi/zipcodeR/branch/master/graph/badge.svg?token=9HDL7QUPCE)](https://app.codecov.io/gh/gavinrozzi/zipcodeR)
[![CRAN
Status](https://www.r-pkg.org/badges/version-last-release/zipcodeR)](https://www.r-pkg.org/badges/version-last-release/zipcodeR)
[![CRAN
Downloads](https://cranlogs.r-pkg.org/badges/grand-total/zipcodeR)](https://cranlogs.r-pkg.org/badges/grand-total/zipcodeR)
[![CRAN Downloads Per
Month](https://cranlogs.r-pkg.org/badges/last-month/zipcodeR)](https://cranlogs.r-pkg.org/badges/grand-total/zipcodeR)
<!-- badges: end -->

### Makes dealing with U.S. ZIP codes painless.

`{zipcodeR}` is an R package that makes working with ZIP codes in R
easier. It provides data on all U.S. ZIP codes using multiple open data
sources, making it easier for social science researchers and data
scientists to work with ZIP code-level data in data science projects
using R.

The latest update to `{zipcodeR}` includes new functions for [searching
ZIP codes at various geographic levels &
geocoding.](https://gavinrozzi.github.io/zipcodeR/articles/geographic.html)

## Installation

You can install the released version of zipcodeR from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("zipcodeR")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("gavinrozzi/zipcodeR")
```

## Citing `{zipcodeR}` in Publications

If you use `{zipcodeR}` in a publication, please cite the following
[journal
article](https://www.sciencedirect.com/science/article/pii/S2665963821000373/).

A BibTeX entry for LaTeX users is:

``` bibtex
@article{ROZZI2021100099,
title = {zipcodeR: Advancing the analysis of spatial data at the ZIP code level in R},
journal = {Software Impacts},
volume = {9},
pages = {100099},
year = {2021},
issn = {2665-9638},
doi = {https://doi.org/10.1016/j.simpa.2021.100099},
url = {https://www.sciencedirect.com/science/article/pii/S2665963821000373},
author = {Gavin C. Rozzi},
keywords = {ZIP code, R, ZCTA, ZIP code tabulation area, zipcodeR},
abstract = {The United States Postal Service (USPS) assigns unique identifiers for postal service areas known as ZIP codes which are commonly used to identify cities and regions throughout the United States in datasets. Despite the widespread use of ZIP codes, there are challenges in using them for geospatial analysis in the social sciences. This paper presents zipcodeR, an R package that facilitates analysis of ZIP code-level data by providing an offline database of ZIP codes and functions for geocoding, normalizing and retrieving data about ZIP codes and relating them to other geographies in R without depending on any external services.}
}
```

## Examples

``` r
# Load zipcodeR into R
library(zipcodeR)
```

### Find all ZIP codes for a state

``` r
search_state('NJ')
#> # A tibble: 732 × 24
#>    zipcode zipcode…¹ major…² post_…³ common_c…⁴ county state   lat   lng timez…⁵
#>    <chr>   <chr>     <chr>   <chr>       <blob> <chr>  <chr> <dbl> <dbl> <chr>  
#>  1 07001   Standard  Avenel  Avenel… <raw 18 B> Middl… NJ     40.6 -74.3 Eastern
#>  2 07002   Standard  Bayonne Bayonn… <raw 19 B> Hudso… NJ     40.7 -74.1 Eastern
#>  3 07003   Standard  Bloomf… Bloomf… <raw 22 B> Essex… NJ     40.8 -74.2 Eastern
#>  4 07004   Standard  Fairfi… Fairfi… <raw 21 B> Essex… NJ     40.9 -74.3 Eastern
#>  5 07005   Standard  Boonton Boonto… <raw 36 B> Morri… NJ     40.9 -74.4 Eastern
#>  6 07006   Standard  Caldwe… Caldwe… <raw 39 B> Essex… NJ     40.8 -74.3 Eastern
#>  7 07007   PO Box    Caldwe… <NA>    <raw 30 B> Essex… NJ     NA    NA   <NA>   
#>  8 07008   Standard  Carter… Carter… <raw 20 B> Middl… NJ     40.6 -74.2 Eastern
#>  9 07009   Standard  Cedar … Cedar … <raw 23 B> Essex… NJ     40.9 -74.2 Eastern
#> 10 07010   Standard  Cliffs… Cliffs… <raw 32 B> Berge… NJ     40.8 -74.0 Eastern
#> # … with 722 more rows, 14 more variables: radius_in_miles <dbl>,
#> #   area_code_list <blob>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>, and abbreviated variable names
#> #   ¹​zipcode_type, ²​major_city, ³​post_office_city, ⁴​common_city_list, …
```

### Calculate the distance between two ZIP codes in miles

``` r
zip_distance('08901','08731')
#>   zipcode_a zipcode_b distance
#> 1     08901     08731     40.7
```

### Calculate the distance between vectors of ZIP codes

``` r
zip_codes <- tribble(~zip_a,  ~zip_b,
"08731",  "08901",
"08734",  "08005")

zip_distance(zip_codes$zip_a,zip_codes$zip_b)
#>   zipcode_a zipcode_b distance
#> 1     08731     08901    40.70
#> 2     08734     08005     8.06
```

### Geocode a ZIP code to get its centroid

``` r
geocode_zip('08901')
#> # A tibble: 1 × 3
#>   zipcode   lat   lng
#>   <chr>   <dbl> <dbl>
#> 1 08901    40.5 -74.4
```

### Get data about a ZIP code

``` r
reverse_zipcode('08901')
#> # A tibble: 1 × 24
#>   zipcode zipcode_…¹ major…² post_…³ common_c…⁴ county state   lat   lng timez…⁵
#>   <chr>   <chr>      <chr>   <chr>       <blob> <chr>  <chr> <dbl> <dbl> <chr>  
#> 1 08901   Standard   New Br… New Br… <raw 25 B> Middl… NJ     40.5 -74.4 Eastern
#> # … with 14 more variables: radius_in_miles <dbl>, area_code_list <blob>,
#> #   population <int>, population_density <dbl>, land_area_in_sqmi <dbl>,
#> #   water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>, and abbreviated variable names
#> #   ¹​zipcode_type, ²​major_city, ³​post_office_city, ⁴​common_city_list, …
```

### Find all ZIP codes for a county

``` r
search_county('Ocean','NJ')
#> # A tibble: 32 × 24
#>    zipcode zipcode…¹ major…² post_…³ common_c…⁴ county state   lat   lng timez…⁵
#>    <chr>   <chr>     <chr>   <chr>       <blob> <chr>  <chr> <dbl> <dbl> <chr>  
#>  1 08005   Standard  Barneg… Barneg… <raw 20 B> Ocean… NJ     39.8 -74.3 Eastern
#>  2 08006   PO Box    Barneg… Barneg… <raw 33 B> Ocean… NJ     39.8 -74.1 Eastern
#>  3 08008   Standard  Beach … Beach … <raw 61 B> Ocean… NJ     39.6 -74.2 Eastern
#>  4 08050   Standard  Manaha… Manaha… <raw 47 B> Ocean… NJ     39.7 -74.3 Eastern
#>  5 08087   Standard  Tucker… Tucker… <raw 51 B> Ocean… NJ     39.6 -74.4 Eastern
#>  6 08092   Standard  West C… West C… <raw 22 B> Ocean… NJ     39.7 -74.3 Eastern
#>  7 08527   Standard  Jackson Jackso… <raw 19 B> Ocean… NJ     40.1 -74.4 Eastern
#>  8 08533   Standard  New Eg… New Eg… <raw 21 B> Ocean… NJ     40.0 -74.5 Eastern
#>  9 08701   Standard  Lakewo… Lakewo… <raw 20 B> Ocean… NJ     40.1 -74.2 Eastern
#> 10 08721   Standard  Bayvil… Bayvil… <raw 20 B> Ocean… NJ     39.9 -74.2 Eastern
#> # … with 22 more rows, 14 more variables: radius_in_miles <dbl>,
#> #   area_code_list <blob>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>, and abbreviated variable names
#> #   ¹​zipcode_type, ²​major_city, ³​post_office_city, ⁴​common_city_list, …
```

### Find all ZIP codes for a city

``` r
search_city('Jersey City','NJ')
#> # A tibble: 13 × 24
#>    zipcode zipcode…¹ major…² post_…³ common_c…⁴ county state   lat   lng timez…⁵
#>    <chr>   <chr>     <chr>   <chr>       <blob> <chr>  <chr> <dbl> <dbl> <chr>  
#>  1 07097   Unique    Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#>  2 07302   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.0 Eastern
#>  3 07303   PO Box    Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#>  4 07304   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.1 Eastern
#>  5 07305   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.1 Eastern
#>  6 07306   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.1 Eastern
#>  7 07307   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.8 -74.0 Eastern
#>  8 07308   PO Box    Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#>  9 07309   Standard  Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#> 10 07310   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.0 Eastern
#> 11 07311   Standard  Jersey… Jersey… <raw 23 B> Hudso… NJ     40.7 -74.0 Eastern
#> 12 07395   Unique    Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#> 13 07399   Unique    Jersey… <NA>    <raw 23 B> Hudso… NJ     NA    NA   <NA>   
#> # … with 14 more variables: radius_in_miles <dbl>, area_code_list <blob>,
#> #   population <int>, population_density <dbl>, land_area_in_sqmi <dbl>,
#> #   water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>, and abbreviated variable names
#> #   ¹​zipcode_type, ²​major_city, ³​post_office_city, ⁴​common_city_list, …
```

### Find all ZIP codes for a timezone

``` r
search_tz('Eastern')
#> # A tibble: 14,025 × 24
#>    zipcode zipcode…¹ major…² post_…³ common_c…⁴ county state   lat   lng timez…⁵
#>    <chr>   <chr>     <chr>   <chr>       <blob> <chr>  <chr> <dbl> <dbl> <chr>  
#>  1 06001   Standard  Avon    Avon, … <raw 16 B> Hartf… CT     41.8 -72.9 Eastern
#>  2 06002   Standard  Bloomf… Bloomf… <raw 22 B> Hartf… CT     41.8 -72.7 Eastern
#>  3 06010   Standard  Bristol Bristo… <raw 19 B> Hartf… CT     41.7 -72.9 Eastern
#>  4 06013   Standard  Burlin… Burlin… <raw 36 B> Hartf… CT     41.8 -73.0 Eastern
#>  5 06016   Standard  Broad … Broad … <raw 46 B> Hartf… CT     41.9 -72.6 Eastern
#>  6 06018   Standard  Canaan  Canaan… <raw 18 B> Litch… CT     42.0 -73.3 Eastern
#>  7 06019   Standard  Canton  Canton… <raw 34 B> Hartf… CT     41.9 -72.9 Eastern
#>  8 06020   Standard  Canton… Canton… <raw 25 B> Hartf… CT     41.8 -72.9 Eastern
#>  9 06021   Standard  Colebr… Colebr… <raw 21 B> Litch… CT     42.0 -73.1 Eastern
#> 10 06022   Standard  Collin… Collin… <raw 24 B> Hartf… CT     41.8 -72.9 Eastern
#> # … with 14,015 more rows, 14 more variables: radius_in_miles <dbl>,
#> #   area_code_list <blob>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>, and abbreviated variable names
#> #   ¹​zipcode_type, ²​major_city, ³​post_office_city, ⁴​common_city_list, …
```

### Get all Census tracts for a given ZIP code

``` r
get_tracts('08731')
#> # A tibble: 6 × 3
#>   ZCTA5 TRACT        GEOID
#>   <chr> <chr>        <dbl>
#> 1 08731 732001 34029732001
#> 2 08731 732002 34029732002
#> 3 08731 732101 34029732101
#> 4 08731 732103 34029732103
#> 5 08731 732104 34029732104
#> 6 08731 733000 34029733000
```

## Documentation

Documentation for the current release [is available
here.](https://gavinrozzi.github.io/zipcodeR/) See the [reference
section](https://gavinrozzi.github.io/zipcodeR/reference/) for full
details on how to use each of the functions provided by zipcodeR.

## Data Sources

This project was inspired by the excellent
[uszipcode](https://uszipcode.readthedocs.io/index.html) library for
Python and utilizes the same backend database released by its author
under the MIT license. This project also incorporates open data from the
U.S. Census Bureau and Department of Housing & Urban Development.
