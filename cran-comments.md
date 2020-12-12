# cran-comments (2020-12-12)

## Resubmission
This is a resubmission. In this version I have added several new features. See the NEWS.md file for details on changes.

## Test environments
* local macOS Big Sur install, R 3.6.1
* win-builder (oldrelease, devel, release)
* Ubuntu 16.04 Xenial, R 4.0.3 via TravisCI
* local Windows 10 development machine, R 4.0.3

## R CMD check results
There were no ERRORs, NOTEs or WARNINGs. 

## Downstream dependencies
I have also run R CMD check on all downstream dependencies used by zipcodeR using revdep. There were no errors.

# Previous cran-comments (2020-09-08)

## Resubmission
This is a resubmission. In this version I have:

* Deleted the LICENSE file from the package
* Update URLs in the DESCRIPTION file to include trailing slashes to address comments and eliminate error


## Initial submission notes
This is a new package that facilitates working with ZIP code data in R through an integrated set of data and functions.

## Test environments
* local macOS Catalina install, R 3.6.1
* win-builder (oldrelease, devel, release)
* Ubuntu 16.04 Xenial, R 4.0.2 via TravisCI - https://travis-ci.com/github/gavinrozzi/zipcodeR/builds/183279729
* local Windows 10 development machine, R 4.0.2

## R CMD check results
There were no ERRORs or WARNINGs. 

There was 1 NOTE:

* checking for future file timestamps ... NOTE
  unable to verify current time

  This was a spurious note because the API used by the function to check the current time is currently down, making it impossible to verify the current time to check for this issue.

## Downstream dependencies
I have also run R CMD check on all downstream dependencies used by zipcodeR (dplyr and stringr)

All packages that I could install & build passed with no failures.

