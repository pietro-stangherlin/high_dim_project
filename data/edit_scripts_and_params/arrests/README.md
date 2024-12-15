# Arrests

## Arrests variable selection

Here is a list with the kept arrests variables (other than time and spatial ones) along with a brief description.

- KY_CD: Three digit offense classification code.
- LAW_CAT_CD: Level of offense: felony, misdemeanor, violation.
- AGE_GROUP: Perpetrator’s Age Group
- PERP_RACE: Perpetrator’s Race Description
- PERP_SEX: Perpetrator’s Sex Description

## Data aggregation

Here we focus on year from 2010 to 2023

1) spatial data: here the two main choices are between NTAs (about 260) and census tracts
2) time data: possible time aggregation are grouped by year or month.
3) stratification covariates: there are many stratification variables, a first choice could be to simply select a small set of variable we consider important (this introduces bias).

Note that the smaller the spatial and time subdivisions we consider the less bias and the more variance in estimates we get.

For each spatial and time category combination and non redundant arrests variable we aggregate the number of arrests

Seems reasonale to define the response as the number of arrests of a specific type divided by the "population for that specific area + 1" (to include areas with no population).
An additional assumpion is that for locations in which arrest missing values are present a zero is considered instead.

## Scenarios

For scenarios data preparation go to the ```scenarios``` folder.

### Few variables

In this first scenario the smallest number of covariates is chosen:

1) NTAs for spatial data
2) months for time data
3) set of "important" covariates

#### Instructions to reproduce the dataset used

Follow the jupyper notebook.

## Explorative Data analysis

## Models

### Model selection criterion