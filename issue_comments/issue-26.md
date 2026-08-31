<!-- Draft comment for issue #26 — review before posting. Suggested action: leave open pending authoritative evidence. -->

91230 is reported as a USPS-only ZIP rather than a Census ZCTA. It is not safe
to represent a central-Glendale point as an authoritative ZIP centroid, so the
new pipeline quarantines this record and assigns neither coordinates nor
districts. It can be added to a future versioned bundle only after authoritative
ZIP validation, with an explicit coordinate method and quality status. The
default 0.3.5-compatible data remains unchanged.
