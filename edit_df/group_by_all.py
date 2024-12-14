# group by all columns value 
# and get a count

import pandas as pd
import sys

# Group by all columns and count the rows

core_path = sys.argv[1]
    
output_path = sys.argv[2]

df = pd.read_csv(core_path)

grouped_df = df.groupby(list(df.columns)).size().reset_index(name='count')

print(grouped_df.shape)
print(grouped_df.columns)
print(grouped_df.head(10))
print(grouped_df.nunique())
print(sum(grouped_df.nunique()))



# Loop through each column and print unique values
for column in grouped_df.columns:
    unique_values = df[column].unique()
    print(f"Unique values in column '{column}': {unique_values}")
