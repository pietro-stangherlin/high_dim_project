# Complaints

## Complaints variable selection

Here is a list with the kept complaints variables along with a brief description.

- CRM_ATPT_CPTD_CD: Indicator of whether crime was successfully completed or attempted, but failed or was interrupted prematurely.
- KY_CD: Three digit offense classification code.
- LAW_CAT_CD: Level of offense: felony, misdemeanor, violation.
- LOC_OF_OCCUR_DESC: Specific location of occurrence in or around the premises; inside, opposite of, front of, rear of.
- JURISDICTION_CODE: Jurisdiction responsible for incident. Either internal, like Police(0), Transit(1), and Housing(2); or external(3), like Correction, Port Authority, etc.
- SUSP_AGE_GROUP: Suspect’s Age Group
- SUSP_RACE: Suspect’s Race Description
- SUSP_SEX: Suspect’s Sex Description
- VIC_AGE_GROUP: Victim’s Age Group
- VIC_RACE: Victim’s Race Description
- VIC_SEX: Victim’s Sex Description

Note to aggregate the data also latitude, longitude and the data the event was reported to police (RPT_DT) were considered: this implicitly introduced a bias because sometimes the event is not reported immediatly so, an analysis on its own can be made about the delay of the censoring between the actual event and reporting; to keep things simple we use the report time.

## Data aggregation

Here we focus on 2020 year, using only census and not ACS data for stratification variables.
There are many possibilities of including:

1) spatial data: here the two main choices are between NTAs (about 260) and census tracts (about 2600)
2) time data: possible time aggregation are grouped by month or week.
3) stratification covariates: there are many stratification variables, a first choice could be to simply select a small set of variable we consider important (this introduce bias).

Note that the smaller the spatial and time subdivisions we consider the less bias and the more variance in estimates we get.

For each spatial and time category combination and non redundant complaints variable we aggregate the number of complaints

Seems reasonale to define the response as the number of complaints of a specific type divided by the "population for that specific area + 1" (to include areas with no population).
An additional assumpion is that for locations in which complaints missing values are present a zero is considered instead.

## Scenarios

For scenarios data preparation go to the ```scenarios``` folder.

### Few variables

In this first scenario the smallest number of covariates is chosen:

1) NTAs for spatial data
2) months for time data
3) set of "importan" covariates

#### Instructions to reproduce the dataset used

1) To get the 2020 data for select variables of complaints + time and spatial coordinates.
From main project folder launch:
```python edit_df/filter_core.py core_datasets/complaints/NYPD_Complaint_Data_Historic_20241202.csv complaints/complaints_var_to_keep.csv RPT_DT 2020 core_datasets/complaints_2020.csv```

2) Add NTA indicator variables.
From main project folder launch:
```python  edit_df/add_spatial_zone.py core_datasets/complaints_2020.csv coordinates_maps/nta.geojson core_datasets/complaints_2020_nta.csv```

3) Remove latidude and longitude coordinates variables.
Add month variable and remove complete date time variable.
Count by grouping all other variables (qualitative).

## Explorative Data analysis

## Models

### Model selection criterion