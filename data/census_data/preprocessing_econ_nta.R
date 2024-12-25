library(tidyverse)
library(sf)
library(sp)
library(gstat)

# Dataset per passare da Census Tract a NTA
ct_to_nta = read.csv("Datasets/2020_Census_Tracts_to_2020_NTAs_and_CDTAs_Equivalency_20241203.csv")
years = c(2010:2016, 2019:2022) # Anni di cui abbiamo i dataset
econ = data.frame() # Dataframe finale
for(i in 1:length(years)) {
  file_path = paste0("Datasets/ACSST5Y", years[i], ".S2503-Data.csv")
  econ_temp = read.csv(file_path) # Dataframe di un certo anno per i CT
  
  # Considero solo i dati sulle unità abitate e sul loro reddito mediano
  econ_temp = econ_temp[-1, c(1:3, grep("S2503_C01_013E", names(econ_temp)))]
  names(econ_temp)[3:4] = c("CaseAbit", "RedditoMed")
  # Sostituisco il reddito mediano delle unità disabitate con 0
  econ_temp$RedditoMed[(econ_temp$RedditoMed == "-" & econ_temp$CaseAbit == 0)] = 0
  econ_temp$RedditoMed = as.numeric(econ_temp$RedditoMed)
  econ_temp$CaseAbit = as.numeric(econ_temp$CaseAbit)
  
  # Ottengo il codice del Census Tract e faccio il merge con ct_to_nta per
  # avere l'NTA
  econ_temp$GEO_ID = gsub("1400000US", "", econ_temp$GEO_ID) %>% as.numeric()
  econ_temp = merge.data.frame(econ_temp, ct_to_nta, 
                               by.x = "GEO_ID", by.y = "GEOID")
  econ_temp = econ_temp[, c(1:4, 11)]
  
  # Dataframe di un certo anno aggregato per NTA
  econ_temp_nta = data.frame()
  ntas = unique(econ_temp$NTACode)
  for(nta in ntas) {
    econ_nta = econ_temp[econ_temp$NTACode == nta,]
    # Le case abitate per NTA sono la somma di quelle abitate per CT
    CaseAbit = sum(econ_nta$CaseAbit, na.rm = T)
    # Il reddito medio è una media di quello mediano per CT pesata per il numero
    # di case abitate del CT 
    RedditoM = weighted.mean(econ_nta$RedditoMed, econ_nta$CaseAbit, na.rm = T)
    
    new = data.frame(
      NTA = nta,
      Year = years[i],
      CaseAbit = CaseAbit,
      RedditoM = RedditoM
    )
    
    econ_temp_nta = rbind.data.frame(econ_temp_nta, new)
  }
  
  # Stimo i valori mancanti delle case e del reddito usando il kriging
  nta_map = st_read("Datasets/nta.geojson") # mappa degli NTA
  nta_map$centr = st_centroid(nta_map$geometry) # Calcolo i centroidi
  nta_map = merge(nta_map, econ_temp_nta, by.x = "NTA2020", by.y = "NTA")
  centr = st_as_sf(
    data.frame(
      st_coordinates(nta_map$centr),
      CaseAbit = nta_map$CaseAbit,
      RedditoM = nta_map$RedditoM
    ),
    coords = c("X", "Y"),
    crs = st_crs(nta_map)
  )
  
  # Variogramma e kriging per le case abitate
  variogram_emp_case = variogram(CaseAbit ~ 1, centr[!is.na(centr$CaseAbit),])
  variogram_model_case = fit.variogram(variogram_emp_case, model = vgm("Sph"))
  kriging_result_case = krige(CaseAbit ~ 1, centr[!is.na(centr$CaseAbit),], 
                              centr, model = variogram_model_case)
  # Sostituisco i valori mancanti
  nta_map$CaseAbit[is.na(nta_map$CaseAbit)] = kriging_result_case$var1.pred[is.na(centr$CaseAbit)]
  # Variogramma e kriging per il reddito
  variogram_emp_redd = variogram(RedditoM ~ 1, centr[!is.na(centr$RedditoM),])
  variogram_model_redd = fit.variogram(variogram_emp_redd, model = vgm("Sph"))
  kriging_result_redd = krige(RedditoM ~ 1, centr[!is.na(centr$RedditoM),], 
                              centr, model = variogram_model_redd)
  # Sostituisco i valori mancanti
  nta_map$RedditoM[is.na(nta_map$RedditoM)] = kriging_result_redd$var1.pred[is.na(centr$RedditoM)]
  
  new = data.frame(
    NTA = nta_map$NTA2020,
    Year = years[i],
    CaseAbit = nta_map$CaseAbit %>% round(digits = 0) %>% pmax(., 0),
    RedditoM = nta_map$RedditoM %>% round(digits = 2) %>% pmax(., 0)
  )
  
  # Unisco i dati sistemati al dataframe principale
  econ = rbind.data.frame(econ, new)
}

# Stimo i valori per gli anni mancanti interpolando i dati per gli anni che
# abbiamo con una regressione lineare
ntas = unique(econ$NTA)
for(nta in ntas) {
  econ_nta = econ[econ$NTA == nta,]
  y = setdiff(2010:2022, econ_nta$Year) # anni mancanti per un dato NTA
  
  # Regressione lineare
  case_pr = predict(lm(CaseAbit ~ Year, data = econ_nta),
                    newdata = data.frame(Year = y)) %>% 
    round(digits = 0) %>% pmax(., 0)
  redd_pr = predict(lm(RedditoM ~ Year, data = econ_nta),
                    newdata = data.frame(Year = y)) %>% 
    round(digits = 2) %>% pmax(., 0)

  new = data.frame(
    NTA = nta,
    Year = y,
    CaseAbit = case_pr,
    RedditoM = redd_pr
  )
  econ = rbind.data.frame(econ, new)
}

# Sostituisco il reddito mediano delle unità disabitate con 0
econ$RedditoM[econ$CaseAbit == 0] = 0
# Ordino le righe per NTA e per anno
econ = econ[order(econ$NTA, econ$Year),]
row.names(econ) = 1:NROW(econ)

# write.csv(econ, "Datasets/econ.csv")
