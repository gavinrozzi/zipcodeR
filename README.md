
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zipcodeR <a href='https://gavinrozzi.github.io/zipcodeR/'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/gavinrozzi/zipcodeR/workflows/R-CMD-check/badge.svg)](https://github.com/gavinrozzi/zipcodeR/actions)
[![codecov](https://codecov.io/gh/gavinrozzi/zipcodeR/branch/master/graph/badge.svg?token=9HDL7QUPCE)](https://codecov.io/gh/gavinrozzi/zipcodeR)
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

## Examples

``` r
# Load zipcodeR into R
library(zipcodeR)
```

### Find all ZIP codes for a state

``` r
search_state('NJ')
#> # A tibble: 732 x 24
#>    zipcode zipcode_type major_city   post_office_city common_city_list county   
#>    <chr>   <chr>        <chr>        <chr>                 <list<raw>> <chr>    
#>  1 07001   Standard     Avenel       Avenel, NJ                   [18] Middlese…
#>  2 07002   Standard     Bayonne      Bayonne, NJ                  [19] Hudson C…
#>  3 07003   Standard     Bloomfield   Bloomfield, NJ               [22] Essex Co…
#>  4 07004   Standard     Fairfield    Fairfield, NJ                [21] Essex Co…
#>  5 07005   Standard     Boonton      Boonton, NJ                  [36] Morris C…
#>  6 07006   Standard     Caldwell     Caldwell, NJ                 [39] Essex Co…
#>  7 07007   PO Box       Caldwell     <NA>                         [30] Essex Co…
#>  8 07008   Standard     Carteret     Carteret, NJ                 [20] Middlese…
#>  9 07009   Standard     Cedar Grove  Cedar Grove, NJ              [23] Essex Co…
#> 10 07010   Standard     Cliffside P… Cliffside Park,…             [32] Bergen C…
#> # … with 722 more rows, and 18 more variables: state <chr>, lat <dbl>,
#> #   lng <dbl>, timezone <chr>, radius_in_miles <dbl>,
#> #   area_code_list <list<raw>>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>
```

### Calculate the distance between two ZIP codes in miles

``` r
zip_distance('08901','08731')
#> [1] 40.7
```

### Geocode a ZIP code to get its centroid

``` r
geocode_zip('08901')
#> # A tibble: 1 x 3
#>   zipcode   lat   lng
#>   <chr>   <dbl> <dbl>
#> 1 08901    40.5 -74.4
```

### Get data about a ZIP code

``` r
reverse_zipcode('08901')
#> # A tibble: 1 x 24
#>   zipcode zipcode_type major_city post_office_city common_city_list county state
#>   <chr>   <chr>        <chr>      <chr>                 <list<raw>> <chr>  <chr>
#> 1 08901   Standard     New Bruns… New Brunswick, …             [25] Middl… NJ   
#> # … with 17 more variables: lat <dbl>, lng <dbl>, timezone <chr>,
#> #   radius_in_miles <dbl>, area_code_list <list<raw>>, population <int>,
#> #   population_density <dbl>, land_area_in_sqmi <dbl>,
#> #   water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>
```

### Find all ZIP codes for a county

``` r
search_county('Ocean','NJ')
#> # A tibble: 32 x 24
#>    zipcode zipcode_type major_city   post_office_city  common_city_list county  
#>    <chr>   <chr>        <chr>        <chr>                  <list<raw>> <chr>   
#>  1 08005   Standard     Barnegat     Barnegat, NJ                  [20] Ocean C…
#>  2 08006   PO Box       Barnegat Li… Barnegat Light, …             [33] Ocean C…
#>  3 08008   Standard     Beach Haven  Beach Haven, NJ               [61] Ocean C…
#>  4 08050   Standard     Manahawkin   Manahawkin, NJ                [47] Ocean C…
#>  5 08087   Standard     Tuckerton    Tuckerton, NJ                 [51] Ocean C…
#>  6 08092   Standard     West Creek   West Creek, NJ                [22] Ocean C…
#>  7 08527   Standard     Jackson      Jackson, NJ                   [19] Ocean C…
#>  8 08533   Standard     New Egypt    New Egypt, NJ                 [21] Ocean C…
#>  9 08701   Standard     Lakewood     Lakewood, NJ                  [20] Ocean C…
#> 10 08721   Standard     Bayville     Bayville, NJ                  [20] Ocean C…
#> # … with 22 more rows, and 18 more variables: state <chr>, lat <dbl>,
#> #   lng <dbl>, timezone <chr>, radius_in_miles <dbl>,
#> #   area_code_list <list<raw>>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>
```

### Find all ZIP codes for a city

``` r
search_city('Jersey City','NJ')
#> # A tibble: 13 x 24
#>    zipcode zipcode_type major_city  post_office_city common_city_list county    
#>    <chr>   <chr>        <chr>       <chr>                 <list<raw>> <chr>     
#>  1 07097   Unique       Jersey City <NA>                         [23] Hudson Co…
#>  2 07302   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#>  3 07303   PO Box       Jersey City <NA>                         [23] Hudson Co…
#>  4 07304   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#>  5 07305   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#>  6 07306   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#>  7 07307   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#>  8 07308   PO Box       Jersey City <NA>                         [23] Hudson Co…
#>  9 07309   Standard     Jersey City <NA>                         [23] Hudson Co…
#> 10 07310   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#> 11 07311   Standard     Jersey City Jersey City, NJ              [23] Hudson Co…
#> 12 07395   Unique       Jersey City <NA>                         [23] Hudson Co…
#> 13 07399   Unique       Jersey City <NA>                         [23] Hudson Co…
#> # … with 18 more variables: state <chr>, lat <dbl>, lng <dbl>, timezone <chr>,
#> #   radius_in_miles <dbl>, area_code_list <list<raw>>, population <int>,
#> #   population_density <dbl>, land_area_in_sqmi <dbl>,
#> #   water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>
```

### Find all ZIP codes for a timezone

``` r
search_tz('Eastern')
#> # A tibble: 14,025 x 24
#>    zipcode zipcode_type major_city  post_office_city  common_city_list county   
#>    <chr>   <chr>        <chr>       <chr>                  <list<raw>> <chr>    
#>  1 06001   Standard     Avon        Avon, CT                      [16] Hartford…
#>  2 06002   Standard     Bloomfield  Bloomfield, CT                [22] Hartford…
#>  3 06010   Standard     Bristol     Bristol, CT                   [19] Hartford…
#>  4 06013   Standard     Burlington  Burlington, CT                [36] Hartford…
#>  5 06016   Standard     Broad Brook Broad Brook, CT               [46] Hartford…
#>  6 06018   Standard     Canaan      Canaan, CT                    [18] Litchfie…
#>  7 06019   Standard     Canton      Canton, CT                    [34] Hartford…
#>  8 06020   Standard     Canton Cen… Canton Center, CT             [25] Hartford…
#>  9 06021   Standard     Colebrook   Colebrook, CT                 [21] Litchfie…
#> 10 06022   Standard     Collinsvil… Collinsville, CT              [24] Hartford…
#> # … with 14,015 more rows, and 18 more variables: state <chr>, lat <dbl>,
#> #   lng <dbl>, timezone <chr>, radius_in_miles <dbl>,
#> #   area_code_list <list<raw>>, population <int>, population_density <dbl>,
#> #   land_area_in_sqmi <dbl>, water_area_in_sqmi <dbl>, housing_units <int>,
#> #   occupied_housing_units <int>, median_home_value <int>,
#> #   median_household_income <int>, bounds_west <dbl>, bounds_east <dbl>,
#> #   bounds_north <dbl>, bounds_south <dbl>
```

### Get all Census tracts for a given ZIP code

``` r
get_tracts('08731')
#> # A tibble: 6 x 3
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
