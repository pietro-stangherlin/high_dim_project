# make file names list
# given a list of years as comma separated values 
import sys
import pandas as pd

args = sys.argv[1:] # exclude script name
# first arg csv of years 
# each year is in a new line

years_list = list(pd.read_csv(args[0])["year"])

years_list = years_list
years_list = [int(el) for el in years_list] # convert to int

# make file names files.csv
# naming them as csv with their tag name in file_pre_and_suffix.csv

names_pre_suffix = pd.read_csv(args[1])

# make file names
for index, row in names_pre_suffix.iterrows():
    prefix = row["prefix"]
    suffix = row["suffix"]
    file_name = row["tag"]
    
    with open(file = f"{file_name}.txt", mode = "w") as fout:
        for i in range(len(years_list) - 1):
            fout.write(f"{prefix}{years_list[i]}{suffix}\n")
        fout.write(f"{prefix}{years_list[-1]}{suffix}")
        


