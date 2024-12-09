# Description

## Idea

Because we have census data for years 2010 and 2020 and ACS data for years ranging from 2010 to 2023 the strategy adopted is:

1) Select one baseline year (in true two): baseline year 2010 for years 2011-2019 and baseline year 2020 for years 2021-2023.
For each baseline year consider the demographic indicator by county (macro areas) in particular
    a) absolute population
    b) median age
    c) other variable as percent variables (but considering the total wouldn't change)
2) For each one of those variables (j = 1,...,p) and for each subsequent non baseline year compute the ratio: variable_j_year_(i) / variable_j_year_(baseline); example for hispanic population variable for Bronx 2015: ratio_bronx_2015_hispanic = hispanic_bronx_2015 / hispanic_bronx_2010. We use the ration beacuse it's independent of the absolute values
3) For each NTA for each year interpolate each variable like the this: consider a NTA in Bronx for year 2015, remeber that we only have (considering 2015) the 2010 NTA estimate: 
nta_hispanic_2015 = nta_hispanic_2010 * ratio_bronx_2015_hispanic.
4) Renormalize percentages and throw away one redundant percentage variable (example -> chose one between male and female population percentage)