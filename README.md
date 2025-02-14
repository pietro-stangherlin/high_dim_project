# Project description

## Data

Analysis of New York City crimes data: two possibilities, for which exist two main datasets [official open data sources](https://opendata.cityofnewyork.us/):

1) [arrests]( https://data.cityofnewyork.us/Public-Safety/NYPD-Arrests-Data-Historic-/8h9b-rp9u/about_data)
2) [complaints](https://data.cityofnewyork.us/Public-Safety/NYPD-Complaint-Data-Historic/qgea-i56i/about_data)

Both of them contain essential informations about each event (respectively 19 and 39 variables, some are reduntant): day and spatial coordinates, crime type classification, some perpetrator or suspect and victim key features (age group, sex and race).
Each dataset starts from 2006 and is updated annualy.

It's also reasonable to get population stratification variables for each city area.
Before describing a graph of [census geographic area hierachy](https://www.census.gov/programs-surveys/geography/about/glossary.html) could be usufeul (see links for a more detailed description): [geo_hierarchy](\images\census-hierarchies.png).

One source data is the [census data](https://www.nyc.gov/site/planning/planning-level/nyc-population/2020-census.page) which containts many variables for each census tract (small population area, about 2300 areas) which can be aggregated in Neighborhood Tabulation Areas (NTAs) (areas with dimension between counties and census tracts, about 260 areas) by the this [equivalence dataset](https://data.cityofnewyork.us/City-Government/2020-Census-Tracts-to-2020-NTAs-and-CDTAs-Equivale/hm78-6dwm/about_data).
Census are decennal, so the two closest census are about years 2010 and 2020.
Concerning other years not covered by census one data source are the [American Community Survey (ACS)](https://www.nyc.gov/site/planning/planning-level/nyc-population/american-community-survey.page). There two types of ACS: one yearly at macro level: in our case one for each of the six NYC Borought or quinquennial for micro areas and each data is an average of the previous 5 years, for more details see the official site.
On bias source is that we assume each stratification variable fixed for each year.

## Goals

The goals of this project are many.
The first goal of the project is to try to describe the evolution of crime in time and space using promoting sparsity models to look for specific variables (including spatial and time ones) correlating with a particulare increase or decrease of the crime ratio (definitions will follow).

The second goal, strongly linked with the first is to actually see if the inducing sparsity model are amenable for this kind of analysis, both in term of interpretation and in computational resources needed and in regulation parameter selection.
A third goal is to compare many models with a different choice of covariates: for example considering smaller or bigger spatial areas.

### Arrests

The arrests dataset comes with some interpretation problems: we don't know if the arrest has happened near (in space and time) the actual crime, but this is not a problem if we're more interested in the arrest itself. The goal is then to see if its arrests' rate is correlated with some specific variables: in particular it's of interest to see if interaction terms between spatial zone and crime charateristics seems relevant or not.

### Complaints

## Methods

For the sake of simplicity we first focus on one census year and aggregate by time using months interval.
If possible an analysis is done on all years from 2010 to 2023.
For details see description files in each folder.

## Issues

## Instructions

1) Follow instructions on stratification_variables
2) Follow instructions on census_interpolation.
