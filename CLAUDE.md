# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

zipcodeR is an R package that simplifies working with U.S. ZIP codes. It provides an offline database of 41,877 ZIP codes with 24 attributes each, plus functions for geographic search, distance calculations, and Census data integration.

## Development Commands

```bash
# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-01-zip-lookups.R")

# Check package (as CRAN would)
devtools::check()

# Build documentation from roxygen comments
devtools::document()

# Install package locally for testing
devtools::install()

# Load package during development (without installing)
devtools::load_all()
```

## Architecture

### Data Layer (`data/`)
Three bundled `.rda` datasets loaded lazily:
- `zip_code_db` - Main ZIP code database (41,877 rows, 24 columns)
- `zcta_crosswalk` - ZCTA-to-Census Tract mapping (148,897 rows)
- `zip_to_cd` - ZIP-to-Congressional District mapping (45,914 rows)

### Source Files (`R/`)
- `data.r` - Roxygen documentation for the three datasets
- `zip_lookups.r` - 14 search/lookup functions that filter the datasets
- `zip_helper_functions.R` - Utility functions: `normalize_zip()`, `zip_distance()`, `geocode_zip()`
- `download_data.r` - `download_zip_data()` to fetch updated data from upstream
- `globals.r` - Global variable declarations for NSE compliance

### Function Patterns
All lookup functions return tibbles and accept vectors for batch operations. They use tidyverse-style programming with dplyr and the `.data` pronoun for NSE.

## Testing

Tests are in `tests/testthat/` using testthat v3:
- `test-01-zip-lookups.R` - Tests for all 14 lookup functions
- `test-02-data.R` - Data integrity tests
- `test-03-helper-functions.R` - Utility function tests

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `R-CMD-check.yaml` - Runs `R CMD check` on Windows, macOS, and Ubuntu with multiple R versions
- `pkgdown.yaml` - Builds and deploys documentation site to GitHub Pages
