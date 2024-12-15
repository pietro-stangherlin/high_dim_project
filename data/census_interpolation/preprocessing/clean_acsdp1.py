import pandas as pd
import sys

file_name = sys.argv[1] # "acsdp1_selected.csv"
name_var_conversion_names_dict = sys.argv[2] # "acsdp1_var_dict.csv"
out_file_name = sys.argv[3]

df = pd.read_csv(filepath_or_buffer = file_name, sep = ",")
var_conv_dict = pd.read_csv(name_var_conversion_names_dict)

# select variables to keep
cols_to_keep = var_conv_dict["old_name"]

# convert to actual dictionary
var_conv_dict = var_conv_dict.set_index("old_name")["new_name"].to_dict()

# remove margin of error columns
substring = 'Margin of Error' 
# Remove columns containing the substring 
df = df.drop(df.filter(like=substring).columns, axis=1)

# replace county names
county_dict = {
    "Bronx County, New York" : "Bronx",
    "Kings County, New York" : "Brooklyn",
    "New York County, New York": "Manhattan",
    "Richmond County, New York" : "Staten Island",
    "Queens County, New York" : "Queens"
    }

# Replace names in the 'name' column using the dictionary 
df["Geographic Area Name"] = df["Geographic Area Name"].replace(county_dict)

# Remove New York city
# Value to filter out
value_to_remove = "New York city, New York" 
# Remove rows where the 'name' column has the specified value
df = df[df["Geographic Area Name"] != value_to_remove]

# Drop all not to keep variables 
df = df.loc[:, cols_to_keep]

# rename all the other columns according to dictionary
df = df.rename(columns = var_conv_dict)

# save as csv
df.to_csv(path_or_buf = out_file_name, index = False)