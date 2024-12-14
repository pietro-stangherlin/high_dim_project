import pandas as pd
import json
import sys

 # for each metadata file check if it contains exactly the selected rows
 # a second possibility is to check only the presence of the column description


# used function
def MakeOccurenceDf(full_path_file_names_list:str,
                    list_only_description:list,
                    dict_synonymous: dict,
                    years_list: list) -> pd.DataFrame:
    '''
    Args:
    - full_path_file_names_list (str): list of file names to scan
    - list_only_description (str): each element is a column name of a unique
    reference file
    - dict_synonymous (dict): each key is one element of list_only_description
    and the value is a list of possibile synonymous of the same column description
    used in other files
    - years_list (list): list of integers corresponding to different years
    
    Return:
    - pandas dataframe with columns corresponding to list_only_description elements
    and rows corresponding to years (i.e different files),
    each cell is 1 if the a column description (or one of its synonymous) has been found
    in the year's file, 0 otherwise
    '''
    
    # allocate the dictionary from which the dataframe is made
    dict_only_description = dict()
    for desc in list_only_description:
        dict_only_description[desc] = [0 for i in range(len(years_list))]
    
    for i in range(len(full_path_file_names_list)):
        with open(file = full_path_file_names_list[i], mode = "r") as fin:
            lines = fin.readlines()
            
            # each set contains all the column description names
            # for a specific file (year)
            set_only_description = set()
        
            for line in lines:
                cleaned_line = line.split(sep = ",")[1].replace("\"", "").replace("\n","")
                set_only_description.add(cleaned_line)
        
            for desc in list_only_description:
                
                is_name_present = False
                
                if desc in set_only_description:
                    is_name_present = True
                
                # try with synonymous
                if not is_name_present and desc in dict_synonymous:
                    for syn in dict_synonymous[desc]:
                        if syn in set_only_description:
                            is_name_present = True
                    
                if is_name_present:
                    dict_only_description[desc][i] = 1
    
    dict_only_description["year"] = years_list
    
    return pd.DataFrame(dict_only_description)



if __name__ == "__main__":
    
    # files to scan names:
    args = sys.argv[1:]

    # assumed to be a txt
    # each row has a different file name
    file_with_relative_metadata_file_names = args[0]

    with open(file = file_with_relative_metadata_file_names, mode = "r") as fin:
        no_path_metadata_file_names_list = fin.readlines()
        # remove "\n" char
        no_path_metadata_file_names_list = [char.replace("\n", "") for char in no_path_metadata_file_names_list]

    metadata_files_path_folder = args[1]

    full_path_metadata_files_list = [f"{metadata_files_path_folder}{char}" for char in no_path_metadata_file_names_list]

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
    
    
    # now the hard part
    # but the rows are few so we can use brute force

    # we notice that a lot of cells are 0
    # we start to examine each case manually to find fixes

    # the approach chosen is to build a dictionary of alternative 
    # column descriptions
    with open(full_path_synonimous_dictionary, 'r') as json_file:
        my_dict_syn = json.load(json_file)

    # debug
    # print(alternative_cols_dict)

    # manual and tedious fixing

    # the first 0 is about the 2018 year
    # relative to variables (referred to 2011 coding):
    # Percent!!SEX AND AGE!!Total population
    # Percent!!HISPANIC OR LATINO AND RACE!!Total population

    # test the function
    occurence_df = MakeOccurenceDf(full_path_file_names_list = full_path_metadata_files_list,
                       list_only_description = list_only_description,
                       dict_synonymous = my_dict_syn,
                       years_list = years_list)
    
    # make live diagnostic
    # check if all cells execpt for the column relative to year 
    # are equal to one
    
    except_year_df = occurence_df.drop(columns = ["year"])
    
    # Check if all values in all columns are equal to 1
    all_equal = (except_year_df == 1).all().all()
    
    if(all_equal):
        print("All elements equal to 1: nice!")
    else:
        print("WARNING: NOT all elements are equal to one, diagnostic needed")
    

    occurence_df.to_csv(output_file_path, index = False)
