# Getting an API to use
# http://api.eia.gov/category/?api_key=YOUR_API_KEY_HERE&category_id=0
# key = d1dc5bf9effa0cab55bca470266b6339

import pandas as pd
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
# import view_data as vd
from pandas.plotting import register_matplotlib_converters
register_matplotlib_converters()
import statistics as stats
import re
import requests

my_key = "d1dc5bf9effa0cab55bca470266b6339"
def series_API(series_key):
    return "http://api.eia.gov/series/?series_id=" + series_key + "&api_key=" + my_key #+ "[&num=][&out=xml|json]"

def category_API(category_key):
    return "http://api.eia.gov/category/?api_key=" + my_key + "&category_id=" + category_key

def get_json(key):
    return requests.get(key).json()

def gen_source_name(raw_string):
    regex = r'.*?Net generation from (.*?) for'

    try:
        found_val = re.search(regex,raw_string).group(1)
    except Exception as e:
        print(e)
        found_val = ""

    return found_val

def region_name(raw_string):
    regex = r'.*?\((.*?)\)'

    try:
        found_val = re.search(regex,raw_string).group(1)
    except Exception as e:
        print(e)
        found_val = ""

    return found_val

def save_csv(df,dest_folder,file_name):
    # Making sure the folder exists
    if not os.path.isdir(dest_folder):
        os.mkdir(dest_folder)

    full_path_name = os.path.join(dest_folder,file_name.split(".")[0] + ".csv")

    df.to_csv(full_path_name,index=True)

# Defining a destination folder
dest_folder = "./Grid_Information"


# Setting a list of things to actually pull
# Options: "Net generation by energy source", "Demand", "Day-ahead demand forecast"
#          "Total interchange"
pull_list = ["Demand"]#,
             # "Demand"]

# Defining an overarching key
Elec_Sys_Oper_Key = "2123635"
Elec_Sys_json = get_json(category_API(Elec_Sys_Oper_Key))
for data_set in Elec_Sys_json["category"]["childcategories"]:
    data_name = data_set["name"]
    print(data_name)
    curr_key = str(data_set["category_id"])
    set_json =  get_json(category_API(curr_key))

    # if data_name in ["Day-ahead demand forecast", "Demand by BA subregion"]:
    #     continue

    if not data_name in pull_list:
        continue
    tcount = 0
    for location in set_json["category"]["childcategories"]:
        # Getting the lacation details
        loc_name = location["name"]
        loc_child_id = str(location["category_id"])
        loc_cat_json = get_json(category_API(loc_child_id))

        # Getting the region name
        reg_name = region_name(loc_name)

        # Using the location category json to get a series json
        df = pd.DataFrame()
        for i in range(0,len(loc_cat_json["category"]["childseries"]),2):
            series_obj = loc_cat_json["category"]["childseries"][i]
            loc_series_id = series_obj["series_id"]
            loc_series_json = get_json(series_API(loc_series_id))
            curr_units = loc_series_json["series"][0]["units"]
            curr_data = loc_series_json["series"][0]["data"]

            # Getting the name of the column to be used in the dataframe
            if data_name == "Net generation by energy source":
                col_name = gen_source_name(series_obj["name"])
            else:
                if i == 0:
                    col_name = data_name
                else:
                    col_name = data_name + str(i)

            curr_time = np.array([point[0] for point in curr_data])
            curr_vals = np.array([point[1] for point in curr_data])
            # Building the dataframe
            if i == 0:
                df = pd.DataFrame(curr_vals,columns=[col_name],index=curr_time)
            else:
                try:
                    dum_df_series = pd.Series(curr_vals, index=curr_time, name=col_name)#,columns=[col_name],index=curr_time)
                    df = pd.concat([df,dum_df_series], axis=1,sort=False)
                except:
                    print("Data is not correct length --> " + reg_name)
                    break
                    exit()

        # Saving the data frame as a csv
        tcount += 1
        save_csv(df,os.path.join(dest_folder,data_name),reg_name)
        print(tcount)
        # if tcount >= 3:
        #     exit()
        # exit()
        # curr_data =
        # loc_series_json
        # print(loc_series_json)
        # break

    # break
