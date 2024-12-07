# Stratification variables instructions

For motivation read Description.md

1) Go in file_names and execute the script (or do nothing beacause some file_names file are already present).
2) Check if your synonimous file is correct by running *extract_col.py* and saving the result in *diagnostic* folder: a correct output should be a csv filled with 1 and no 0 in each column and row except for column names and years column.
Example for our case: lunch the script from the stratification folder.
The script accepts many arguments (see the script for a description):
For ACS 1 year: social (macro)
```python extract_cols.py .\file_names\\acs1_dp_file_column_metadata_names.txt acs1_social\boro_2010-2023\ .\acs1_social\col_names_to_keep_dp_2011.txt years_acs1.csv .\acs1_social\synonimous.json .\diagnostic\acs1_presence_only_desc_boro.csv```
For ACS 5 years: economical (micro)
```python extract_cols.py .\file_names\\acs5_econ_file_column_metadata_names.txt .\acs5_econ\acs5_econ_2010-2022\ .\acs5_econ\acs5_cols_to_keep.txt years_acs5.csv .\acs5_econ\acs5_synonimous.json .\diagnostic\acs5_presence_only_desc_econ.csv```


3) To make the actual aggregated data file lunch *make_unique_csv.py* script with a similar syntax to the previuos script, only changing the file with the actual data file names and the output:
For ACS 1 year: social
```python make_unique_csv.py .\file_names\\acs1_dp_file_data_names.txt acs1_social\boro_2010-2023\ .\acs1_social\col_names_to_keep_dp_2011.txt years_acs1.csv .\acs1_social\synonimous.json .\final_datasets\acs1_selected_boro.csv```
For ACS 5 years: economical (micro)
```python extract_cols.py .\file_names\\acs5_econ_file_data_names.txt .\acs5_econ\acs5_econ_2010-2022\ .\acs5_econ\acs5_cols_to_keep.txt years_acs5.csv .\acs5_econ\acs5_synonimous.json ..\final_datasets\acs5_selected_boro.csv```
