# Stratification variables instructions

For motivation read Description.md

1) Go in file_names and execute the script (or do nothing beacause some file_names file are already present).
2) Check if your synonimous file is correct by running *extract_col.py* and saving the result in *diagnostic* folder: a correct output should be a csv filled with 1 and no 0 in each column and row except for column names and years column.
Example for our case: lunch the script from the stratification folder.
The script accepts many arguments (see the script for a description):
```python extract_cols.py .\file_names\\acs_dp_file_column_metadata_names.txt boro_social\boro_2010-2023\ .\boro_social\col_names_to_keep_dp_2011.txt years.csv .\boro_social\synonimous.json .\diagnostic\presence_only_desc_boro.csv```


3) To make the actual aggregated data file