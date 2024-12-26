# functions used in the analysis


library(tidyverse)
library(Matrix)
library(glmnet)
# library(ncvreg)
library(picasso) # sparse model matrix scad and mcp
library(gglasso)
library(viridis)

# Groub by months indexes
GroupByMONTHSets = function(mydf, month_indexes){
  month_grouped = mydf %>%
    filter(MONTH %in% month_indexes) %>% 
    dplyr::select(-MONTH) %>% 
    group_by_all() %>% 
    summarise(count = n())
  
  return(month_grouped)
}