# Instructions

Create file names to use for succesive operations.
Use or edit *years.csv* to include the desired years and *file_pre_and_suffix.csv* to include the desired census data.
Text files are created, each one for one non header row of *file_pre_and_suffix.csv* containing the content file names for each year with the specified prefix and suffix (assuming they have all the same format across different years)

To use the script lunch:
ACSDP1 year (macro) dp:
```python .\file_names\make_file_names_list.py years_acs1.csv .\file_names\acsdp1_file_pre_and_suffix.csv file_names\```

ACSST5 year (micro) (one year less) st:
```python .\file_names\make_file_names_list.py years_acs5.csv .\file_names\acsst5_file_pre_and_suffix.csv file_names\```