library(tidyverse)

cen = read.csv("cen.csv", header = T)
econ = read.csv("econ.csv", header = T)

# keep only selected variables

econ$CaseAbit = NULL
econ$X = NULL
colnames(econ)

econ = econ %>% rename(NTA2020 = NTA, YEAR = Year, MIncome = RedditoM)
colnames(econ)

colnames(cen)

cen$X = NULL
cen$Borough = NULL
cen$Name = NULL

cen = cen %>% select(Year, GeoID, Pop1, MaleP, MdAge, Hsp1P, WNHP, BNHP, ANHP, OthNHP)

cen = cen %>% rename(YEAR = Year, NTA2020 = GeoID)

colnames(cen)

# Join the dataframes based on YEAR and NTA2020
joined_df <- cen %>% inner_join(econ, by = c("YEAR", "NTA2020"))
colnames(joined_df)

write.csv(joined_df, file = "cen_econ.csv", row.names = FALSE)

