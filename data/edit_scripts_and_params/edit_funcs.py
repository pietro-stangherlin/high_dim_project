import pandas as pd
import geopandas as gpd
from shapely.geometry import Point # used to find the corresponding spatial zone


def FilterColumns(df, var_df):
    '''Filter pandas dataframe columns.
    
    Args:
        - df (pd.dataframe): pandas dataframe object
        - var_df (list): pandas dataframe with variables to keep 
        two columns: name, keep (0 or 1): if 1 keep, else discard
    
    Return: 
        pd.dataframe of filtered pandas dataframe with only the columns
        for which keep == 1 in var_df
    '''
    
    var_to_keep_list = var_df[var_df["keep"] == 1]
    var_to_keep_list = list(var_to_keep_list["name"])
    
    return(df.loc[:, var_to_keep_list])

def FilterRowsContains(df, var_name, accepted_var_values):
    '''Filter pandas dataframe rows by keeping only the rows for which
    the var_name column contains at least one the accepted values.
    Example accepted_var_values = ["ab", "bc", "cd"]
    and one row has var_name value = "abc" -> it's gonna be kept because it contains
    both "ab" both "bc" so at least one of the values in ["ab", "bc", "cd"].
    
    Args:
        - df (pd.dataframe): pandas dataframe object
        - var_name (str): name of the variable where the condition is checked 
        - accepted_var_values: 
    
    Return: 
        - pd.dataframe of filtered pandas dataframe with only the rows satisfying the condition
    '''
    
    return(df[df[var_name].apply(lambda x: any(val in x for val in accepted_var_values))])

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

def AddMONTH(df, date_var_name, date_format = '%m/%d/%Y'):
    # Convert the date column to datetime 
    df[date_var_name] = pd.to_datetime(df[date_var_name], format= date_format)
    # Extract the month
    df['MONTH'] = df[date_var_name].dt.month
    
    return(df)

def AddYEAR(df, date_var_name, date_format = '%m/%d/%Y'):
    # Convert the date column to datetime 
    df[date_var_name] = pd.to_datetime(df[date_var_name], format= date_format)
    # Extract the month
    df['YEAR'] = df[date_var_name].dt.year
    
    return(df)