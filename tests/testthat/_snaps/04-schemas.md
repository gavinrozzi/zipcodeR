# lookup function return schemas are stable

    Code
      cat("search_state:     ", schema(search_state("NJ")), "\n")
    Output
      search_state:      tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("search_county:    ", schema(search_county("Ocean", "NJ")), "\n")
    Output
      search_county:     tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("search_city:      ", schema(search_city("Chappaqua", "NY")), "\n")
    Output
      search_city:       tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("search_tz:        ", schema(search_tz("Eastern")), "\n")
    Output
      search_tz:         tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("search_fips:      ", schema(search_fips("34", "029")), "\n")
    Output
      search_fips:       tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("search_cd:        ", schema(search_cd("34", "02")), "\n")
    Output
      search_cd:         tbl_df: ZIP=character, state_fips=character, congressional_district=character 
    Code
      cat("search_radius:    ", schema(search_radius(39.9, -74.3, 5)), "\n")
    Output
      search_radius:     tbl_df: zipcode=character, distance=numeric 
    Code
      cat("reverse_zipcode:  ", schema(reverse_zipcode("08731")), "\n")
    Output
      reverse_zipcode:   tbl_df: zipcode=character, zipcode_type=character, major_city=character, post_office_city=character, common_city_list=blob, county=character, state=character, lat=numeric, lng=numeric, timezone=character, radius_in_miles=numeric, area_code_list=blob, population=integer, population_density=numeric, land_area_in_sqmi=numeric, water_area_in_sqmi=numeric, housing_units=integer, occupied_housing_units=integer, median_home_value=integer, median_household_income=integer, bounds_west=numeric, bounds_east=numeric, bounds_north=numeric, bounds_south=numeric 
    Code
      cat("geocode_zip:      ", schema(geocode_zip("08731")), "\n")
    Output
      geocode_zip:       tbl_df: zipcode=character, lat=numeric, lng=numeric 
    Code
      cat("get_tracts:       ", schema(get_tracts("08731")), "\n")
    Output
      get_tracts:        tbl_df: ZCTA5=character, TRACT=character, GEOID=numeric 
    Code
      cat("zip_distance:     ", schema(zip_distance("08731", "08901")), "\n")
    Output
      zip_distance:      data.frame: zipcode_a=character, zipcode_b=character, distance=numeric 
    Code
      cat("normalize_zip:    ", schema(normalize_zip("8731")), "\n")
    Output
      normalize_zip:     character length 1 
    Code
      cat("is_zcta:          ", schema(is_zcta("08731")), "\n")
    Output
      is_zcta:           logical length 1 

