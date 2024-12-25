library(sf)
library(tidyverse)

arr = read.csv("Datasets/NYPD_Arrests_Data_Historic_20241202.csv")
neighb = st_read("Datasets/nta.geojson")
points_coords = data.frame(lon = arr$Longitude, lat = arr$Latitude)

points = st_as_sf(points_coords, coords = c("lon", "lat"), crs = 4326, na.fail = F)
neighb = st_transform(neighb, 4326)

result = st_join(points, neighb, join = st_within)

print(result)