# This python script is made to read csv files from the eia

# Website to get the information
# https://www.eia.gov/beta/electricity/gridmonitor/dashboard/electric_overview/regional/REG-CAR

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

test = requests.get("http://api.eia.gov/category/?api_key=d1dc5bf9effa0cab55bca470266b6339&category_id=2123635")
print(test.json())

def get_demand_data(filename):
# This function is made to get the data from a file and put it into a pandas dataframe

    # Checking to make sure the file entered exists
    if not os.path.exists(filename):
        return ""

    # Importing the data as a dataframe
    rawData = pd.read_csv(filename)#, skiprows=1, header=None, delim_whitespace=True)

    # Removing the timezone information if it is there
    dum_list = []
    regex = r'(\d{1,2}\/\d{1,2}\/\d{1,4} \d{1,4} \D.\D.) '
    for i in range(len(rawData["Timestamp (Hour Ending)"])):
        try:
            match_val = re.search(regex,rawData["Timestamp (Hour Ending)"][i]).group(1)
            dum_list.append(pd.Timestamp(match_val))
        except Exception as e:
            dum_list.append(rawData["Timestamp (Hour Ending)"][i])
            pass

    rawData["Timestamp (Hour Ending)"] = dum_list
    # rawData["Timestamp (Hour Ending)"] = [pd.Timestamp(" ".join(i.split(" ")[0:-1])) for i in rawData["Timestamp (Hour Ending)"]]
    return rawData

def get_data_lists(df, **kwargs):
# This function is made to plot multiple lines from the demand dataframe at a given interval

    # Handling optional inputs
    xstring = kwargs.get("xstring", "")
    ystring = kwargs.get("ystring", "Demand (MWh)")
    interval = kwargs.get("interval",24)

    # Getting the data from the strings
    if xstring != "":
        base_xdata = df[xstring]
    else:
        base_xdata = np.arange(interval)

    # Getting the y data
    all_ydata = df[ystring]

    # Building the plotting value lists
    count = 0
    ydata_list = []
    xdata_list = []

    for i in range(len(all_ydata)//interval + 1):
        # Starting index
        st = (i*interval)
        if st == len(all_ydata):
            break

        # Ending Index
        fin = st + interval
        if fin > len(all_ydata):
            fin = len(all_ydata)

        # List of x and y data
        ydata_list.append(np.array(all_ydata[st:fin][:]))
        xdata_list.append(base_xdata[0:(fin - st)])

    return [xdata_list, ydata_list]


def get_hour_bins(ydata_list):
# This is made to get bins that contain each of the data points for each hour
#   in the day. So all points for hour 00:00, 01:00, ...

    # Number of data points (days for 24 hour cycle)
    num_points = len(ydata_list[0])

    my_bins = []
    for i in range(num_points): # 24 for 24 hours
        dum_bin = []
        for ydata in ydata_list:
            if len(ydata) > i:
                dum_bin.append(ydata[i])

        my_bins.append(dum_bin)

    return my_bins


def plot_data_lists(ydata_list, **kwargs):
    # Handling optional input arguments
    line_type = kwargs.get("line_type", "*--")
    my_linewidth = kwargs.get("my_linewidth", 2)
    legend = kwargs.get("legend", "")
    xdata_list = kwargs.get("xdata_list", "")

    dum_plot = [[]]*len(ydata_list)

    # _, ax = plt.subplots()
    for i in range(len(ydata_list)):
        ydata = ydata_list[i]

        if xdata_list != "":
            xdata = xdata_list[i]
            dum_plot[i], = plt.plot(xdata, ydata,line_type,linewidth=my_linewidth)
        else:
            dum_plot[i], = plt.plot(ydata,line_type,linewidth=my_linewidth)
        # ax.plot(xdata,ydata,line_type,linewidth=my_linewidth)

    # if len(legend) > i:
    #     ax.legend(legend)
    if legend != "":
        plt.legend(dum_plot,legend)

def combine_sources(source_folder):
# This is designed to get a pandas dataframe from all of the files in a folder

    # Checking to make sure the entered folder exists
    if not os.path.isdir(source_folder):
        return

    # Going through every file and adding to a dataframe
    count = 0
    for file in os.listdir(source_folder):
        # Going to the next file if it is not a csv
        if file.split(".")[-1] != "csv":
            continue

        # Getting the total file path
        file = os.path.join(source_folder,file)

        # Creating the dataframe if it is the first time in the loop
        if count == 0:
            df = get_demand_data(file)
        else:
            dum = get_demand_data(file)
            df = df.append(dum,sort=False)

        # Removing the file
        os.remove(file)


        # Adding to the counter variable
        count += 1

    # Erasing the duplicate rows from the dataframe
    df = df.drop_duplicates(keep=False)

    # Saving the data to a new file. This is done to consilate information
    df.to_csv(os.path.join(source_folder,"summary.csv"),index=False)



# Defining source directory
src_folder = "./Grid_Information/Demand/"
summary_file_name = "summary.csv"

# Grabbing all of the data from the specified folder and consolidating sources
# combine_sources(src_folder)

# Grabbing the consolodated data
df = get_demand_data(os.path.join(src_folder,summary_file_name))


# Getting both the x and y data from a function
dum_list = get_data_lists(df, ystring="Demand (MWh)",interval=24)
xdata = dum_list[0]
ydata = dum_list[1]


# Getting the hourly data in an hourly basis
hr_bins = get_hour_bins(ydata)


# Getting statistic parameters about the demand curves
sigma = [np.nanstd(i) for i in hr_bins]
avg = [np.nanmean(i) for i in hr_bins]
median = [np.nanmedian(i) for i in hr_bins]

# Getting a list of plotting lines
plt_lines = [avg,
             np.subtract(avg,np.multiply(2,sigma)),
             np.add(avg,np.multiply(2,sigma)),
             median ]

plt.figure()
# plot_data_lists(ydata,line_type="k.",xdata_list=xdata)
plot_data_lists(plt_lines,
                line_type="--",
                my_linewidth=3,
                legend=["mean","-2 sigma","+2 sigma", "median"])

plt.show()

# %%
# plt.plot(df["Demand (MWh)"])
# vd.basic_plot(df, "Demand (MWh)", xstring=0)
