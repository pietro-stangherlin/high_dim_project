# filter csv rows
# by a single variable condition

import pandas as pd
import sys

def FilterRowsHasValue(df, var_name, accepted_var_values):
    '''Filter pandas dataframe rows by keeping only the rows for which
    the var_name column contains at least one the accepted values.
    Example accepted_var_values = ["ab", "bc", "cd"]
    and one row has var_name = "abc" -> it's gonna kept because it contains
    both "ab" both "bc".
    
    Args:
    - df (pd.dataframe): pandas dataframe object
    - var_name (str): name of the variable where the condition is checked 
    - accepted_var_values: 
    
    Return: 
    pd.dataframe of filtered pandas dataframe with only the rows satisfying the condition
    '''
    
    var_to_keep_list = var_df[var_df["keep"] == 1]
    var_to_keep_list = list(var_to_keep_list["name"])
    
    return(df.loc[:, var_to_keep_list])
    

if __name__ == "__main__":
    # core dataset path
    core_path = sys.argv[1]

    # csv with variables to keep 
    # two columns: name, keep (0 or 1): if 1 keep, else discard
    csv_var_to_keep_path = sys.argv[2] 
    
     # output file path
    output_path = sys.argv[3]

    # make column names to keep list
    var_df = pd.read_csv(csv_var_to_keep_path)
    
    df = pd.read_csv(core_path)

    # filter columns
    df = FilterColumns(df, var_df)

    df.to_csv(output_path, index = False)