# Stratification variables instructions

For motivation read Description.md

1) Go in file_names and execute the script (or do nothing beacause some file_names file are already present).
2) Check if your synonimous file is correct by running *extract_col.py* and saving the result in *diagnostic* folder: a correct output should be a csv filled with 1 and no 0 in each column and row except for column names and years column.
Example for our case: lunch the script from the stratification folder.
The script accepts many arguments (see the script for a description):

For ACS 1 year: social (macro)
```python extract_cols.py .\file_names\\acsdp1_file_column_metadata_names.txt acsdp1\acsdp1_2010-2023\ .\acsdp1\acsdp1_col_names_to_keep_dp_2011.txt years_acs1.csv .\acsdp1\acsdp1_synonimous.json .\diagnostic\acsdp1_presence_only_desc.csv```

For ACS 5 years: economical (micro)
```python extract_cols.py .\file_names\\acsst5_file_column_metadata_names.txt .\acsst5\acsst5_2010-2022\ .\acsst5\acsst5_cols_to_keep.txt years_acs5.csv .\acsst5\acsst5_synonimous.json .\diagnostic\acsst5_presence_only_desc.csv```

3) To make the actual aggregated data file lunch *make_unique_csv.py* script with a similar syntax to the previuos script, only changing the file with the actual data file names and the output:

For ACS 1 year: social
```python make_unique_csv.py .\file_names\\acsdp1_file_data_names.txt acsdp1\acsdp1_2010-2023\ .\acsdp1\acsdp1_col_names_to_keep_dp_2011.txt years_acs1.csv .\acsdp1\acsdp1_synonimous.json .\final_datasets\acsdp1_selected.csv```

For ACS 5 years: economical (micro)
```python extract_cols.py .\file_names\\acsst5_file_data_names.txt .\acsst5\acsst5_2010-2022\ .\acsst5\acsst5_cols_to_keep.txt years_acs5.csv .\acsst5\acsst5_synonimous.json ..\final_datasets\acsst5_selected.csv```
