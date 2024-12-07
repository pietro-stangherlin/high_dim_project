For more context please read Description.md.

First download the wanted dataset along with their columns description metadata files from https://www.nyc.gov/site/planning/planning-level/nyc-population/american-community-survey.page.

After having identified a subset of variables of intereset create a dictionary in json format where the key is the description for the reference year chosen and the value is a list of alternative descriptions for the same variables in the other year Datasets.

The exctrat_cols.py sctipt can be useful for checking the correspondence: given a dictonary of synonimous.
