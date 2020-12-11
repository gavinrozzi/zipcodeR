---
title: 'zipcodeR: An all-in-one toolkit of functions & data for working with U.S. ZIP codes in R'
tags:
    - R
    - ZIP codes
    - Census data
    - social science

authors:
    - name: Gavin C. Rozzi
      orcid: 0000-0002-9969-8175
      affiliation: 1
affiliations:
    - name: Rutgers Urban & Civic Informatics Lab, Edward J. Bloustein School of Planning & Public Policy, Rutgers, The State University of New Jersey, New Brunswick, NJ, USA
      index: 1
date: 12 December 2020
bibliography: paper.bib


---

# Summary


# Statement of need 
The most popular previous R library that had a degree of overlap with zipcodeR was the package zipcode, which has since been archived from the CRAN repository and no longer actively supported [@Breen:2012]. Because ZIP code boundaries and service areas can change over time, researchers cannot accurately rely upon older packages that have not been updated for their workflows, necessitating the development of a new solution like `zipcodeR`. 

To the best of the author's knowledge, there are also no other R packages that are primarily geared toward relating ZIP codes to other units commonly encountered in social science informatics workflows, such as FIPS codes and Census Tract.

There is a currently a lack of a general-purpose library for working with ZIP codes currently listed in CRAN.

`zipcodeR` has already been used in graduate-level courses in data science for relating ZIP codes to other data sources & administrative boundaries [@Green:2020], in addition to graduate-level coursework in urban informatics [@Wang:2020].

# Acknowledgements
The author would like to acknowledge Sanhe Hu, author of the Python package uszipcode, whose work provided a foundation for the development of this package.