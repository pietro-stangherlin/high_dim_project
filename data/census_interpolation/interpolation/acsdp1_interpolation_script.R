rm(list = ls())
library(tidyverse)

# set working directory to upper level ("census_interpolation" dir)
# in order to simplfy file callings

# in my case
# setwd("~/Progetti/NYC/census_interpolation")

# load acsdp1
acsdp1_df = read.csv(file = "acsdp1_cleaned.csv",
                     sep = ",", header = T)

str(acsdp1_df)
head(acsdp1_df)

# load census data
census_2010_2020_df = read.csv(file = "nta_interpolated_two_census.csv",
                     sep = ",", header = T)

str(census_2010_2020_df)

# select baseline year from census: 2010 year
census_baseline = census_2010_2020_df %>% filter(Year == 2010)
head(census_baseline)

census_baseline
