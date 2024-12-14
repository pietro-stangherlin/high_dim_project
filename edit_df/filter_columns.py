# filter csv columns

import pandas as pd
import sys

def FilterColumns(df, var_df):
    '''Filter pandas dataframe columns.
    
    Args:
    - df (pd.dataframe): pandas dataframe object
    - var_df (list): pandas dataframe with variables to keep 
    two columns: name, keep (0 or 1): if 1 keep, else discard
    
    Return: 
    pd.dataframe of filtered pandas dataframe with only the columns
    for which keep == 1 in var_df
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
