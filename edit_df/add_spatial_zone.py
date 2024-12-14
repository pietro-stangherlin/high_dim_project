# add spatial set to a dataset previously cleaned using "filter_core.py"

import geopandas as gpd
import pandas as pd
import sys
from shapely.geometry import Point # used to find the corresponding spatial zone

core_csv_path = sys.argv[1] # core csv dataset path

# assume is a geojson
zone_coordinates_json_path = sys.argv[2]

# variables to keep from the zone_coordinates_json dataframe
vars_to_keep_coord = sys.argv[3]

output_path = sys.argv[4] # output file path

# spatial coordinates names of core
# if None use default
# latitude_name_var = sys.argv[3]
# longitude_name_var = sys.argv[4]

df = pd.read_csv(core_csv_path)

# Read the GeoJSON file into a GeoDataFrame
gdf = gpd.read_file(zone_coordinates_json_path)

# Extract the CRS (coordinates system)
crs = gdf.crs


# Create a GeoDataFrame from the CSV data
geometry = [Point(xy) for xy in zip(df['Longitude'], df['Latitude'])]
# convert original data frame to geo pandas data frame
gdf_core = gpd.GeoDataFrame(df, geometry = geometry)

# Perform the spatial join
joined_gdf = gpd.sjoin(gdf_core, gdf, how="left", predicate="within")

# Select the relevant columns
# all
# result = joined_gdf[['Latitude', 'Longitude', 'NTA2020']]

# debug
print(joined_gdf.columns)

# joined_gdf.to_csv(output_path, index = False)