# add month variable
# called "MONTH"
# from complete date time variable "month/day/year"

import pandas as pd
import sys

def AddMONTH(df, date_var_name, date_format = '%m/%d/%Y'):
    # Convert the date column to datetime 
    df[date_var_name] = pd.to_datetime(df[date_var_name], format= date_format)
    # Extract the month
    df['MONTH'] = df[date_var_name].dt.month
    
    return(df)

if __name__ == "__main__":
    # core dataset path
    core_path = sys.argv[1]

    var_date_name = sys.argv[2]
    
    output_path = sys.argv[3]
    
    temp_df = AddMONTH(pd.read_csv(core_path), var_date_name)
    
    temp_df.to_csv(output_path, index = False)
    

