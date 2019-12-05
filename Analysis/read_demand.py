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

def get_demand_data(filename):
# This function is made to get the data from a file and put it into a pandas dataframe

    # Checking to make sure the file entered exists
    if not os.path.exists(filename):
        return ""

    # Importing the data as a dataframe
    rawData = pd.read_csv(filename, index_col=0)#, skiprows=1, header=None, delim_whitespace=True)

    return rawData

def get_data_lists(df, **kwargs):

    # Getting the time data
    time_data = df.index.to_numpy()
    value_data = df.to_numpy()
    column_names = list(df.columns)

    return time_data, value_data, column_names


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
# This plots SINGLED VALUED data lists. It was made for plotting demand curves

    # Handling optional input arguments
    line_type = kwargs.get("line_type", "*--")
    my_linewidth = kwargs.get("my_linewidth", 2)
    legend = kwargs.get("legend", "")
    xdata_list = kwargs.get("xdata_list", "")
    title = kwargs.get("title","")

    dum_plot = [[]]*len(ydata_list)
    for i in range(len(ydata_list)):
        ydata = ydata_list[i]
        if not "" in xdata_list:
            xdata = xdata_list[i]
            dum_plot[i], = plt.plot(xdata, ydata,line_type,linewidth=my_linewidth)
        else:
            dum_plot[i], = plt.plot(ydata,line_type,linewidth=my_linewidth)
        # ax.plot(xdata,ydata,line_type,linewidth=my_linewidth)

    plt.title(title)

    if legend != "":
        plt.legend(dum_plot,legend)

def slice_up_data(time_data, y_values, date_range, **kwargs):
# This function is made to slice up the x values and y values into groups.
#   This works for single valued variables and multiple value variables.
#
    # Handling optional inputs
    interval = kwargs.get("interval",24)

    # Getting the start and end index
    start_index = find_date_index(time_data, date_range[0])
    end_index = find_date_index(time_data, date_range[1])
    # end_index = find_date_index(time_data, time_data[end_index].date())

    interval_start = find_date_index(time_data, time_data[start_index].date())

    # interval_end = find_date_index(time_data, time_data[end_index].date())

    # Note the dates are in REVERSE ORDER (end is old) and this loop pulls them
    #   so that they are in normal order
    i = interval_start
    desired_dates = []
    final_data = []

    while i > end_index:
        dum_list = []
        dum_dlist = []

        st = i
        en = i
        c = 0
        for i2 in range(0,-interval,-1):
            # print(i+i2)
            if ((i+i2) <= start_index):
                # print(i2)
                if c == 0:
                    st = (i+i2+1)
                c += 1
                en = (i+i2)
                dum_list.append(time_data[i+i2].ctime())
                # dum_dlist.append(y_values[i+i2,:].item())

        desired_dates.append(dum_list)
        final_data.append(np.flip(y_values[en:st,:],axis=0))
        # final_data.append(np.array(dum_dlist))
        i -= interval

    return desired_dates, final_data

def find_date_index(time_data,date):

    # Getting the date entry as a Timestamp
    pd_date = pd.Timestamp(date,tzinfo=time_data[0].tz)
    # print("comparing ", pd_date.ctime())
    c = 0
    for i in time_data:
        # print(i.ctime())
        if i < pd_date:
            # print("here",i.ctime())
            break

        c += 1
    return c

def get_data(general_folder, data_name, region_name, interval, normalized, **kwargs):

    # Defining source directory
    src_folder = os.path.join(general_folder,data_name)

    # The data as a dataframe
    df = get_demand_data(os.path.join(src_folder,region_name + ".csv"))

    # Geeting the time (ydata), values (xdata), and column info (info)
    #   Note: This are in reverse cronological order
    xdata, ydata, info = get_data_lists(df)
    time_data = [pd.Timestamp(i) for i in xdata]

    # This slices up the data lists into intervals of a given length (24 hours) and
    #   puts the data in cronological order
    sliced_time, sliced_ydata = slice_up_data(time_data, ydata, date_range, interval=interval)

    # Normalizing the data if the input is given
    if normalized:
        sliced_ydata = np.divide(sliced_ydata,np.nanmax(sliced_ydata))

    return sliced_time, sliced_ydata, info

def get_gen_source(info, data_list, source_list):

    my_indices = []
    # print(source_list)
    # print(info)
    # Going through every desired source to find the columns where it matches the info
    for source in source_list:
        for i in range(len(info)):
            if source in info[i]:
                my_indices.append(i)
    # print(my_indices)
    # sub_load = np.zeros([1,len(data)])
    sub_load_list = []
    for data in data_list:
        for i in range(len(my_indices)):
            if i == 0:
                sub_load = data[:, my_indices[i]]
            else:
                sub_load = np.add(sub_load, data[:,my_indices[i]])

        if my_indices:
            sub_load_list.append(sub_load)
        else:
            sub_load_list.append(np.zeros(len(data)))

    return sub_load_list

def do_everything(date_range,data_name,region_name,**kwargs):

    # Handling optional inputs
    interval = kwargs.get("interval",24)
    general_folder = kwargs.get("general_folder","./Grid_Information/")
    normalized = kwargs.get("normalized",False)
    title = kwargs.get("title","")
    xlabel = kwargs.get("xlabel","")
    sub_source_list = kwargs.get("sub_source_list",[""])
    sub_source_loc = kwargs.get("sub_source_loc","Net generation by energy source")
    return_df = kwargs.get("return_df",False)

    sliced_time, sliced_ydata, info = get_data(general_folder, data_name,
                                            region_name, interval, normalized)

    if not "" in sub_source_list:
        if data_name != "Net generation by energy source":
            tst, sliced_sub_data, sub_info = get_data(general_folder, sub_source_loc,
                                                    region_name, interval, normalized)
            # print("sliced_sub_data =",len(tst))
            # for i in range(len(sliced_time)):
            #     print(sliced_time[i])
            #     try:
            #         print(tst[i])
            #     except:
            #         print("miss")
            #         pass
            # exit()

            sliced_ydata = [np.squeeze(i) for i in sliced_ydata]
            sub_load = get_gen_source(sub_info, sliced_sub_data, sub_source_list)

            print("sub_load =",len(sub_load))
            print("sliced_ydata =",len(sliced_ydata))
            # exit()

            try:
                if not sub_load:
                    print("No source in ", region_name)
                else:
                    sliced_ydata = np.subtract(sliced_ydata,sub_load)
            except Exception as e:
                print(e)
                print("there was a problem subtracting sub-demands", region_name)
                pass
        else:
            sliced_ydata = get_gen_source(info, sliced_ydata, sub_source_list)

    # Getting the hourly data in an hourly basis
    hr_bins = get_hour_bins(sliced_ydata)

    # Getting statistic parameters about the demand curves
    sigma = [np.nanstd(i) for i in hr_bins]
    avg = [np.nanmean(i) for i in hr_bins]
    median = [np.nanmedian(i) for i in hr_bins]


    # Getting a list of plotting lines
    plt_lines = [avg,
                 np.subtract(avg,np.multiply(2,sigma)),
                 np.add(avg,np.multiply(2,sigma)) ]

    plot_data_lists(sliced_ydata,line_type="k.")#,xdata_list=xdata)
    plot_data_lists(plt_lines,
                    line_type="--",
                    my_linewidth=3,
                    legend=["mean","-2 sigma","+2 sigma"])

    plt.title(title)
    plt.xlabel(xlabel)

    if return_df:
        return hr_bins

# ==============================================================================

date_range = ["04-01-2019","04-30-2019"]

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

region_name = ["DUK"] #, "CISO", "SWPP"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]

max_subplot_wide = 2

h = np.ceil(len(region_name)/max_subplot_wide).astype(int)
w = min([len(region_name),max_subplot_wide])

region_name = "DUK"
my_list = do_everything(date_range, data_type, region_name,
              sub_source_list=sub_source_list,
              normalized=False,
              # title=r,
              interval=24,
              return_df=True )

# Creates a datafram rows=day, column=hr
my_df = pd.DataFrame(np.hstack(my_list))

my_df.to_csv("./Grid_Information/Curve_Fitting/" + region_name + ".csv",index=False,header=False)


# %%

c = 1
for r in region_name:
    print(r)
    plt.subplot(h, w, c)
    do_everything(date_range, data_type, r,
                  sub_source_list=sub_source_list,
                  normalized=False,
                  title=r,
                  interval=24 )
    c += 1
plt.suptitle((date_range[0] + " -> " + date_range[1]))
plt.show()

# NOTE: Figure out what is going on with the greater than/greater than or equal to in the slice up data function
