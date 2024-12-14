# filter csv rows
# by a single variable condition

import pandas as pd
import sys

def FilterRowsContains(df, var_name, accepted_var_values):
    '''Filter pandas dataframe rows by keeping only the rows for which
    the var_name column contains at least one the accepted values.
    Example accepted_var_values = ["ab", "bc", "cd"]
    and one row has var_name value = "abc" -> it's gonna be kept because it contains
    both "ab" both "bc" so at least one of the values in ["ab", "bc", "cd"].
    
    Args:
        - df (pd.dataframe): pandas dataframe object
        - var_name (str): name of the variable where the condition is checked 
        - accepted_var_values: 
    
    Return: 
        - pd.dataframe of filtered pandas dataframe with only the rows satisfying the condition
    '''
    
    return(df[df[var_name].apply(lambda x: any(val in x for val in accepted_var_values))])
    

if __name__ == "__main__":
    # core dataset path
    core_path = sys.argv[1]
    
    # name of filtering variable
    filter_var_name = sys.argv[2]
    
    # values separated by ";" character
    # for example years: 2018;2019;2020
    acc_var_values = sys.argv[3].split(";")
     
    # output file path
    output_path = sys.argv[4]
    
    df = pd.read_csv(core_path)
    

    FilterRowsContains(df, filter_var_name, acc_var_values).to_csv(output_path, index = False)