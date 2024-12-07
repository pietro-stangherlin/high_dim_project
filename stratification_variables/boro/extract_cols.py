import pandas as pd
import json

# for year ACSDP1YYEAR.DP05-Data.csv
# extract only relevant columns
# and save the file in a cleaned file.csv

# then the idea is to merge all the dataset created this way in
# a unique file used to extrapolate population trends

# the reference columns (variables) to keep 
# are the one stored in cen.csv file
# (which is a column subset of
# nyc_decennialcensusdata_2010_2020_change-core-geographies)
# avaible at link:
# https://www.nyc.gov/site/planning/planning-level/nyc-population/2020-census.page

# include both absolute value and relative value
# also keep track of the statistical sampling error
# in the annual surveys

# and are about:

# total population
# male population
# female population (note that in theory we can get )
# median age

# race:
# hispanic
# white non hispanic
# black non hispanic
# asian non hispanic
# some other races non hispanic
# non hispanic of two or more races

# maybe aggregate those two

# first conduct an expection of column names
# first identify columns of intereset in the first (2011 file)
# written as csv (code, description in col_names)

# then check if those columns (with same name) are present in all other
# year files

# I've just noticed the col names diferrent across each year.... :(
# but still we can check how for how many years we have the same coding
# up to "DP05_0075PM" column comparing the metadata files

# files to scan names:
years_list = [2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 
              2021, 2022, 2023]

metadata_file_names = [None for i in range(len(years_list))]

prefix = "boro_2010-2023/"

for i in range(len(years_list)):
    metadata_file_names[i] = f"ACSDP1Y{years_list[i]}.DP05-Column-Metadata.csv"

metadata_file_names_prefix = [None for i in range(len(years_list))]

for i in range(len(years_list)):
    metadata_file_names_prefix[i] = f"{prefix}{metadata_file_names[i]}"
 
 # for each metadata file check if it contains exactly the
 # the selected rows
 # a second possibility is to check only the presence of the column description
 
 # first make a dataframe to store the query result
 # ideally it's a data frame but I need pandas for that
 
 # we can temporaly store this in a dictionary
 # and then convert it to a pandas data.frame or csv later
 
 # make a key for each different column in 
col_names_to_keep_file = "col_names_to_keep_2011_nospace.txt"


# example of only description = "Estimate!!SEX AND AGE!!Total population"
list_only_description = []
 
n_years = len(metadata_file_names)
 
with open(file = col_names_to_keep_file, mode = "r") as fin:
    lines = fin.readlines()
    
    for i in range(len(lines)):
        line_only_description = lines[i].split(sep = ",")[1].replace("\"", "").replace("\n","") # take second element
        # preallocation
        list_only_description.append(line_only_description)

# used function
def MakeOccurenceDf(file_names_list:str,
                    list_only_description:list,
                    dict_synonymous: dict,
                    years_list: list) -> pd.DataFrame:
    '''
    Args:
    - file_name_list (str): list of file names to scan
    - list_only_description (str): each element is a column name of a unique
    reference file
    - dict_synonymous (dict): each key is one element of list_only_description
    and the value is a list of possibile synonymous of the same column description
    used in other files
    - years_list (list): list of integers corresponding to different years
    
    Return:
    - pandas dataframe with columns corresponding to list_only_description elements
    and rows corresponding to years (i.e different files),
    each cell is 1 if the a column description (or one of its synonymous) has been found
    in the year's file, 0 otherwise
    '''
    
    # allocate the dictionary from which the dataframe is made
    dict_only_description = dict()
    for desc in list_only_description:
        dict_only_description[desc] = [0 for i in range(len(years_list))]
    
    for i in range(len(file_names_list)):
        with open(file = file_names_list[i], mode = "r") as fin:
            lines = fin.readlines()
            
            # each set contains all the column description names
            # for a specific file (year)
            set_only_description = set()
        
            for line in lines:
                cleaned_line = line.split(sep = ",")[1].replace("\"", "").replace("\n","")
                set_only_description.add(cleaned_line)
        
            for desc in list_only_description:
                
                is_name_present = False
                
                if desc in set_only_description:
                    is_name_present = True
                
                # try with synonymous
                if not is_name_present and desc in dict_synonymous:
                    for syn in dict_synonymous[desc]:
                        if syn in set_only_description:
                            is_name_present = True
                    
                if is_name_present:
                    dict_only_description[desc][i] = 1
    
    dict_only_description["year"] = years_list
    
    return pd.DataFrame(dict_only_description)


# now the hard part
# but the rows are few so we can use brute force

# we notice that a lot of cells are 0
# we start to examine each case manually to find fixes

# the approach chosen is to build a dictionary of alternative 
# column descriptions
with open("synonimous.json", 'r') as json_file:
    my_dict_syn = json.load(json_file)

# debug
# print(alternative_cols_dict)

# manual and tedious fixing

# the first 0 is about the 2018 year
# relative to variables (referred to 2011 coding):
# Percent!!SEX AND AGE!!Total population
# Percent!!HISPANIC OR LATINO AND RACE!!Total population

# test the function
test = MakeOccurenceDf(file_names_list = metadata_file_names_prefix,
                       list_only_description= list_only_description,
                       dict_synonymous = my_dict_syn,
                       years_list = years_list)

test.to_csv('presence_only_desc.csv', index = False)
