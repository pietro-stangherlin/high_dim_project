# check unique values for each column

import pandas as pd
import sys

core_path = sys.argv[1]

df = pd.read_csv(core_path)

# Loop through each column and print unique values
for column in df.columns:
    unique_values = df[column].unique()
    print(f"Unique values in column '{column}': {unique_values}")