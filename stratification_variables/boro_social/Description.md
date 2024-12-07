# Description

Date: 2024-12-07

## Description: stratification variables issues

In our project it's essential to consider stratification variables for each New York area,ideally the more the better.
If one considers only the two decennal census data for years 2010 and 2020 (yeah, covid year) then no major problem emerges other then selecting a subset of meaningful data beacuse detailed data are avaible for really small geographical areas (Census Blocks).
Census data lack, theorically, statistical error, other then the one due to differential privacy (2020 Census), for more details see for example "Census Bureau Adopts Cutting Edge Privacy Protections for 2020 Census" Dr. Ron Jarmin, February 15, 2019.

Problems are due to consideration of all other years (in our case from 2011 to 2023) for which the main consultation data are the American Community Survey (ACS).
Quoting Walker 2023 "The Census Bureau releases two ACS datasets to the public: the 1-year ACS, which covers areas of population 65,000 and greater, and the 5-year ACS, which is a moving average of data over a 5-year period that covers geographies down to the Census block group. ACS data are distinct from decennial Census data in that data represent estimates rather than precise counts, and in turn are characterized by margins of error around those estimates."

One sub-optimal possibility is to get each of one year estimates (ACS1) (for which only macro areas are avaible), interpolate the variation of each variable of interest and use this trend to modify each corresponding corresponding variable in each micro area for which we don't have data. Of course the assumptions made here are strong and some bias (hopefully not much) is introduced on the covariates. Due to time constraints we choose this approach.

If variables codings and descriptions would be constants through years the task would be easy, it's not simple as that.
Codings and descriptions can arbitrarily vary across years in random like way, for example the variable with code "DP05_0081E" has description "Estimate!!Total housing units" in 2011 ACS while the same code for 2017 has description "Estimate!!HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Native Hawaiian and Other Pacific Islander alone", descriptions also can change by a little, like a small phrase can be added or removed across different years.
Theoretically for years 2021, 2022 and 2023 (as today) id conversion tables for consecutive years exist in csv format but the files are really in binary format and not readable.
For all other years qualitative change description exists on the ACS web pages (example: https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes.2019.html#list-tab-71983198 ) so with a lot of time or with some large language models support something can be done.

Again due to time constraint we use another manual approach.
Having selected a small subset of variables we manually check its description for each year and create a dictionary of correspondences where the reference descriptions are relative to 2011 year (using description as new variable name). Using the dictionary we're able to aggregate data by selecting the desired variable in each year dataset.
Instructions are contained in the README.md file.