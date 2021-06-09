# cran-comments (2021-06-09)

## Resubmission
This is a resubmission. In this version I have modified the package so that it no longer depends on {udunits2} because of problems with that package on the latest R release on macOS. See the NEWS.md file for details on changes.

## Test environments
* local M1 macOS Big Sur install, R 4.1
* r-Hub (Windows-devel & oldrelease on Windows Server 2008)
* Ubuntu 16.04 Xenial, R 4.0.5 via GitHub Actions
* local Windows 10 development machine, R 4.0.5

## R CMD check results
There were no ERRORs, NOTEs or WARNINGs. 

## Downstream dependencies
I have also run R CMD check on all downstream dependencies used by zipcodeR using revdep. There were no errors.
