# cran-comments (2022-10-02)

## Resubmission
I am submitting this version in response to a concern raised by Brian Ripley. This version eliminates an error involving internet resources on the zipcodeR.Rmd vignette.

## Test environments
* local M1 macOS Big Sur install, R release
* r-Hub (Windows-devel & oldrelease on Windows Server 2008)
* Ubuntu 20.04, R release via GitHub Actions
* Ubuntu 20.04 Xenial, R devel via GitHub Actions
* local Windows 10 development machine, R 4.2.1

## R CMD check results
There were no ERRORs, NOTEs or WARNINGs. 

## Downstream dependencies
I have also run R CMD check on all downstream dependencies used by zipcodeR using revdep. There were no errors.
