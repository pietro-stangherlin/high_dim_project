# filter core datasets
import pandas as pd
import sys

core_path = sys.argv[1] # core dataset path

csv_var_to_keep_path = sys.argv[2] # csv with variables to keep 
# two columns: name, keep (0 or 1): if 1 keep, else discard

time_name = sys.argv[3] # time data variable_name (assumed) in the US format: month/day/year

years_to_keep = sys.argv[4] # years to keep separated by ";": example 2019;2020
output_path = sys.argv[5] # output file path


# make years list
years = years_to_keep.split(";")

# make column names to keep list
var_df = pd.read_csv(csv_var_to_keep_path)

var_to_keep_list = var_df[var_df["keep"] == "1"]
var_to_keep_list = list(var_to_keep_list["name"])

df = pd.read_csv(core_path)

# Column to filter
column_to_filter = 'your_column_name'

# Filter rows
df = df[df[time_name].apply(lambda x: any(year in x for year in years))]

# filter columns
df = df.loc[:, var_to_keep_list]

df.to_csv(output_path, index = False)

