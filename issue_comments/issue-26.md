<!-- Draft comment for issue #26 — review before posting. Suggested action: leave open pending authoritative evidence. -->

The report appears to transpose two digits: `92130` is the San Diego ZIP and is
present in both the historical database and the modern pipeline. `91230` is not
present in the pinned Census ZCTA Gazetteer or ACS ZCTA response. A third-party
source described it as a Glendale P.O. Box ZIP, but that is not sufficient
evidence for a Census-derived centroid or district.

The new pipeline therefore records `91230` as a quarantined lead rather than
publishing a city-center proxy point. It can enter a future versioned bundle
only after authoritative USPS validation, with an explicit coordinate method
and quality status. This answers the San Diego case without inventing spatial
data for a different identifier.
