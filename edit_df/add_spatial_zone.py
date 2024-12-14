# add spatial set to a dataset previously cleaned using "filter_core.py"

import geopandas as gpd
import pandas as pd
import sys
from shapely.geometry import Point # used to find the corresponding spatial zone

def ConvertToGeodf(df, long = "Longitude", lat = "Latitude", crs = "EPSG:4326"):
    '''
    Args:
        - crs (str): coordinates system
    '''
    # Create a GeoDataFrame from the CSV data
    geometry = [Point(xy) for xy in zip(df[long], df[lat])]
    # convert original data frame to geo pandas data frame
    
    gpdf = gpd.GeoDataFrame(df, geometry = geometry)
    gpdf.crs = crs
    
    return(gpdf)

def SJoinWithinGeo(geodf_units, geodf2_polygons):
    '''Join two geopandas dataframes by latitude and longitude coordinates.
    More specifically join by checking the which rows of geodf_units
    fall inside poligons of geodf_polygons.
    '''
    return(gpd.sjoin(geodf_units, geodf2_polygons, how="left", predicate="within"))

if __name__ == "__main__":
    core_csv_path = sys.argv[1] # core csv dataset path

    # assume is a geojson
    zone_coordinates_json_path = sys.argv[2]

    output_path = sys.argv[3] # output file path

    # spatial coordinates names of core
    # if None use default
    # latitude_name_var = sys.argv[3]
    # longitude_name_var = sys.argv[4]

    df = pd.read_csv(core_csv_path)

    # Read the GeoJSON file into a GeoDataFrame
    gdf = gpd.read_file(zone_coordinates_json_path)

    df_to_gpdf = ConvertToGeodf(df, crs = gdf.crs)

    # debug
    joined_gdf = SJoinWithinGeo(df_to_gpdf, gdf)

    joined_gdf.to_csv(output_path, index = False)