library(readxl)
library(tidyverse)

cen20 = read_xlsx("Datasets/nyc_decennialcensusdata_2010_2020_change-core-geographies.xlsx", 
                  sheet = 1)
cen10 = read_xlsx("Datasets/nyc_decennialcensusdata_2010_2020_change-core-geographies.xlsx", 
                  sheet = 2)

# Unisco i due dataset considerando solo gli NTA
cen20 = cen20[cen20$GeoType == "NTA2020",]
cen10 = cen10[cen10$GeoType == "NTA2020",]
cen = rbind.data.frame(cen10, cen20)
# Seleziono le variabili di interesse su sesso, età ed etnia
vars_keep = c(1, 3, 4, 6, 9, 11:14, 51, 67:78)
cen = cen[, vars_keep]
cen = as.data.frame(cen) # Da tibble a data.frame
names(cen)[7] = "MaleP"
# Gli NA sono solo le percentuali di gruppi quando gli abitandi di un NTA
# sono 0, quindi li pongo a 0
cen[is.na(cen)] = 0
# Unisco le var. su 'altre etnie' e 'due o più etnie' in una var. sola
cen$OthNH = cen$ONH + cen$TwoPlNH
cen$OthNHP = ifelse(cen$OthNH != 0, round(cen$OthNH / cen$Pop1 * 100, 1), 0)
cen = cen[, -c(19:22)]

# Calcolo i dati per gli anni dal 2011 al 2019 interpolando i dati dal 2010 al
# 2020 con una regressione lineare
ntas = unique(cen$GeoID)
years = 2011:2019
cen_temp = data.frame()

for (nta in ntas) {
  pop_pr = predict(lm(Pop1 ~ Year, data = cen[cen$GeoID == nta,]),
                 newdata = data.frame(Year = years))
  malep_pr = predict(lm(MaleP ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  mdage_pr = predict(lm(MdAge ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  hispp_pr = predict(lm(Hsp1P ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  whitep_pr = predict(lm(WNHP ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  blackp_pr = predict(lm(BNHP ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  asianp_pr = predict(lm(ANHP ~ Year, data = cen[cen$GeoID == nta,]),
                     newdata = data.frame(Year = years))
  otherp_pr = 100 - (round(hispp_pr, 2) + round(whitep_pr, 2) + 
                        round(blackp_pr, 2) + round(asianp_pr, 2))
  
  new = data.frame(
    Year = years,
    Borough = cen[cen$GeoID == nta,]$Borough[1],
    GeoID = nta,
    Name = cen[cen$GeoID == nta,]$Name[1],
    Pop1 = pop_pr %>% round(digits = 0),
    MaleP = malep_pr,
    Male = NA,
    FemP = NA,
    Fem = NA,
    MdAge = mdage_pr %>% round(digits = 1),
    Hsp1 = NA,
    Hsp1P = hispp_pr,
    WNH = NA,
    WNHP = whitep_pr,
    BNH = NA,
    BNHP = blackp_pr,
    ANH = NA,
    ANHP = asianp_pr,
    OthNH = NA,
    OthNHP = NA
  )
  cen_temp = rbind.data.frame(cen_temp, new)
}
cen_temp$Male = (cen_temp$Pop1 * cen_temp$MaleP / 100) %>% round(digits = 0)
cen_temp$MaleP = cen_temp$MaleP %>% round(digits = 2)
cen_temp$Fem = cen_temp$Pop1 - cen_temp$Male
cen_temp$FemP = 100 - cen_temp$MaleP
cen_temp$Hsp1 = (cen_temp$Pop1 * cen_temp$Hsp1P / 100) %>% round(digits = 0)
cen_temp$Hsp1P = cen_temp$Hsp1P %>% round(digits = 2)
cen_temp$WNH = (cen_temp$Pop1 * cen_temp$WNHP / 100) %>% round(digits = 0)
cen_temp$WNHP = cen_temp$WNHP %>% round(digits = 2)
cen_temp$BNH = (cen_temp$Pop1 * cen_temp$BNHP / 100) %>% round(digits = 0)
cen_temp$BNHP = cen_temp$BNHP %>% round(digits = 2)
cen_temp$ANH = (cen_temp$Pop1 * cen_temp$ANHP / 100) %>% round(digits = 0)
cen_temp$ANHP = cen_temp$ANHP %>% round(digits = 2)
cen_temp$OthNH = cen_temp$Pop1 - cen_temp$Hsp1 - cen_temp$WNH - cen_temp$BNH - cen_temp$ANH
cen_temp$OthNHP = 100 - cen_temp$Hsp1P - cen_temp$WNHP - cen_temp$BNHP - cen_temp$ANHP

cen = rbind.data.frame(cen, cen_temp)
cen = cen[order(cen$GeoID, cen$Year),] # ordino lo oss. per NTA ed anno
rownames(cen) = 1:NROW(cen)

# Sistemo le proporzioni
cols = c(7, 9, seq(12, 20, by = 2))
cen[, cols] = ((cen[, cols-1] / cen$Pop1 * 100)) %>% round(., digits = 2)
# Pongo tutte le quantità a 0 quando la popolazione è 0
cen[cen$Pop1 == 0, 6:NCOL(cen)] = 0
# Pongo l'età minima a 18 anni
cen$MdAge = ifelse(cen$Pop1 != 0, pmax(18, cen$MdAge), 0)

# write.csv(cen, "Datasets/cen.csv")

# # Controllo NTA che sono passati da 0 a più abit. o viceversa dal 2010 al 2020
# con1 = cen[cen$Year == 2010,]$Pop1 == 1 & cen[cen$Year == 2020,]$Pop1 > 0
# con2 = cen[cen$Year == 2010,]$Pop1 > 0 & cen[cen$Year == 2020,]$Pop1 == 1
# con3 = cen[cen$Year == 2010,]$Pop1 == 0 & cen[cen$Year == 2020,]$Pop1 == 0
# sum(con1) + sum(con2)
# con = cen$GeoID %in% ntas[con1 | con2]