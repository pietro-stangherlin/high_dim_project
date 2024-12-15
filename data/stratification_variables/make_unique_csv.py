import json
import pandas as pd
import sys

# assuming the column names of 2011 file,
# along with synonimous.json are enough to find
# correspondence between all years files
# the goal here is to merge the data of all the files
# for the selected columns and keeping track of the year

# files to scan names:
# for each csv file (each year)
# find the corresponding columns to the one selected 
# and save those data on a df row

# first find the columns to filter
# given the fixed ones and the ones on synonimous
def ColFilter(base_cols: list, 
              dict_cols: list,
              obj_cols: list) -> list:
    '''Args:
    - base_cols (list): list of col names (ideally the one to be searched)
    - dict_cols (dict): dict of backup col names in case some of the base cols
    are not found in obj_cols (key = some cols in base_cols, value = alternative
    value)
    - obj_cols = the objective col names where the elements of base_cols are searched
    
    Return:
    - list with the str of cols found, if one col is not found an error is returned
    
    Example: ColFilter(["a", "b", "c"], {"a":["ab"]}, ["ab", "b", "c", "d"]) -> ['ab', 'b', 'c']
    '''
    result = [None for i in range(len(base_cols))]
    
    for i in range(len(base_cols)):
        
        if base_cols[i] in obj_cols:
            result[i] = base_cols[i]
        
        elif(base_cols[i] not in obj_cols and base_cols[i] in dict_cols):
            # search in the elements of dict_cols
            for el in dict_cols[base_cols[i]]:
                if el in obj_cols:
                    result[i] = el
        else:
            return None
    
    return result

if __name__ == "__main__":
    
    args = sys.argv[1:]

    # assumed to be a txt
    # each row has a different file name
    file_with_relative_data_file_names = args[0]

    with open(file = file_with_relative_data_file_names, mode = "r") as fin:
        no_path_data_file_names_list = fin.readlines()
        # remove "\n" char
        no_path_data_file_names_list = [char.replace("\n", "") for char in no_path_data_file_names_list]

        data_files_path_folder = args[1]

        full_path_data_files_list = [f"{data_files_path_folder}{char}" for char in no_path_data_file_names_list]

        # make a key for each different column in 
        # include relative path
        full_path_col_names_to_keep_file = args[2] # "col_names_to_keep_dp_2011.txt"

        # complete path 
        years_list = pd.read_csv(args[3])["year"]

        full_path_synonimous_dictionary = args[4]

        output_file_path = args[5]

    # example of only description = "Estimate!!SEX AND AGE!!Total population"
    list_only_description = []
 
    n_years = len(years_list)
 
    with open(file = full_path_col_names_to_keep_file, mode = "r") as fin:
        lines = fin.readlines()
    
        for i in range(len(lines)):
            line_only_description = lines[i].split(sep = ",")[1].replace("\"", "").replace("\n","") # take second element
            # preallocation
            list_only_description.append(line_only_description)


    # allocate the empty data.frame
    df = pd.DataFrame(columns = list_only_description)
    # add year column
    df["year"] = []

    
    with open(file = full_path_synonimous_dictionary, mode = "r") as fin:
        dict_json = json.load(fin)

    for i in range(len(full_path_data_files_list)):
    
        temp_df = pd.read_csv(full_path_data_files_list[i], skiprows = 1)
    
        filter_cols = ColFilter(base_cols = list_only_description,
                                dict_cols = dict_json,
                                obj_cols = temp_df.columns)
    
        temp_df = temp_df[filter_cols]
        temp_df.columns = list_only_description
        temp_df["year"] = years_list[i]
    
        df = df._append(temp_df, ignore_index = True)
       
    df["year"] = df["year"].astype("int")   

    df.to_csv(path_or_buf = output_file_path, index = False)