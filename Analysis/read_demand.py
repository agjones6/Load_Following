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
import scipy
from scipy.stats import t
import matplotlib.patheffects as pe

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
    # print(num_points)
    # exit()

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
            # print(i+i2,start_index)
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
        if i <= pd_date:
            # print("here",i.ctime())
            break

        c += 1
    return c

def get_data(general_folder, data_name, region_name, date_range, interval, **kwargs):

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

def final_data(date_range,data_name,region_name,**kwargs):

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
                                               region_name, date_range, interval)

    # NOTE: This is where the time data needs to be checks to ensure there no missing parts

    if not "" in sub_source_list:
        if data_name != "Net generation by energy source":
            tst, sliced_sub_data, sub_info = get_data(general_folder, sub_source_loc,
                                                      region_name, date_range, interval)
            # print("sliced_sub_data =",len(tst))
            # for i in range(len(sliced_time)):
            #     print(sliced_time[i])
            #     try:
            #         print(tst[i])
            #     except:
            #         print("miss")
            #         pass
            # exit()

            # sliced_ydata = [np.squeeze(i) for i in sliced_ydata]
            sliced_ydata = np.hstack(sliced_ydata)
            sub_load = get_gen_source(sub_info, sliced_sub_data, sub_source_list)

            print("sub_load =",len(sub_load))
            print("sliced_ydata =",len(sliced_ydata))
            print(len(sub_load))
            print(sliced_ydata)
            print("This is not ready yet")
            # basically the sub-demand from the specified source is not lining
            #   up properly with the source. The size and orientation of the matrix
            #   needs to be checked and fixed.
            exit()

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
    data_bins = get_hour_bins(sliced_ydata)

    # print((data_bins))
    # exit()
    # Converting the bins of data to a numpy array
    data_array = np.hstack(data_bins)

    # If the data is desired to be normalized
    if normalized:
        max_val = np.nanmax(data_array)
        data_array = np.divide(data_array,max_val)

    if return_df:
        # converting to a data frame
        return pd.DataFrame(data_array)
    else:
        return data_array

def check_data(data_array):
# This function is made to check all of the days for missing data and remove the
#   days that are missing.

    # This gets the number of hours and days as variables
    dum_sz = data_array.shape
    num_days = dum_sz[0]
    num_hrs  = dum_sz[1]

    # Going through every day to find nan's
    new_data = []
    for i in range(num_days):
        curr_data = data_array[i,:]
        if not np.isnan(curr_data).any():
            new_data.append(curr_data)

    new_data = np.array(new_data)

    return new_data

def avg_coef(time_array,data_array,num_days,poly_order):
    all_coef = []
    Problem_Data = []
    for i in range(num_days):
        curr_data = data_array[i,:]
        curr_time = time_array[i,:]
        try:
            all_coef.append(np.polyfit(curr_time,curr_data,poly_order))
        except:
            print("problem using element ", i)
            Problem_Data.append(curr_data)
            pass

        # print(all_coef)
        # print(np.mean(all_coef,axis=0))
        coef = np.mean(all_coef,axis=0)
        Problem_Data = np.transpose(np.array(Problem_Data))
        # print(Problem_Data.shape)
        # exit()

    return coef, Problem_Data

def poly_fit(data_array, **kwargs):
# This function is made to return the coefficients of the desired polynomial.
#   The input data_array should be a row x col = day x hr matrix

    poly_order = kwargs.get("poly_order",5)
    confidence_value = kwargs.get("confidence_value",0.98)
    type_of_fit = kwargs.get("type_of_fit","avg")

    # Removing days with nan's in them
    data_array = check_data(data_array)

    # This gets the number of hours and days as variables
    dum_sz = data_array.shape
    num_days = dum_sz[0]
    num_hrs  = dum_sz[1]

    DOF = num_hrs - (poly_order + 1)

    # Gets a singular array of times (0-23) hours
    dum_times = [np.array(np.arange(num_hrs))]
    # Time array is built
    time_array = dum_times
    for i in range(num_days-1):
        time_array = np.concatenate((time_array,dum_times))

    # Getting flat arrays
    time_flat = time_array.flatten()
    data_flat = data_array.flatten()

    # Getting a polynomial fit coefficients for the data array
    try:
        if type_of_fit == "avg":
            coef = np.polyfit(time_flat, data_flat, poly_order)
        else: # Individual
            coef, _ = avg_coef(time_array,data_array,num_days,poly_order)
    except Exception as e:
        print("error in fitting polynomial")
        coef,Problem_Data = avg_coeff(time_array,data_array,num_days,poly_order)


    # Getting the values of the model that correspond to the observation data
    t_mesh = np.linspace(0,23,500)
    model_eval = np.polyval(coef,time_flat)
    model_mesh = np.polyval(coef,t_mesh)


    # --> Determining the uncertainty in the polynomial fit for every hour
    # Getting Sum of Squares error
    SS_error = np.sum( np.power(np.subtract(data_flat, model_eval),2) )

    # Getting the observation Sigma I think
    s_0 = ((1/DOF) * SS_error)**(0.5)

    # Calculating a sensitivity matrix
    num_param = len(coef)
    c = 0
    h = 0.0001
    X_0 = []
    for q in coef:
        base_mat = np.ones(num_param)
        base_mat[c] = base_mat[c] + h
        denom = h * q
        diff_vals = np.polyval(np.multiply(coef,base_mat),time_flat)

        X_0.append(np.divide(np.subtract(diff_vals, model_eval),denom))

        c += 1

    # Turning the X_0 array into a numpy array
    X_0 = np.transpose((X_0))

    # Getting an R matrix for calculating the Variance
    R = data_flat - model_eval

    # Sigma^2 for the function
    sig2 = np.multiply((1/DOF), np.matmul(np.transpose(R),R))
    # print(sig2)

    # Calculating the V matrix (covariance)
    V = np.multiply(sig2, np.linalg.inv(np.matmul(np.transpose(X_0),X_0)))

    # Getting the delta Matrix
    delta = np.diag(V)
    SD_mat = np.power(np.diag(V),0.5)

    # Getting the t distribution value
    t_dist = t(df=DOF)
    t_val = t_dist.ppf(confidence_value)

    dq = []
    for d in SD_mat:
        dq.append(t_val*d)

    dq = np.array(dq)

    q_UB = coef + dq
    q_LB = coef - dq

    model_UB = np.polyval(q_UB,t_mesh)
    model_LB = np.polyval(q_LB,t_mesh)

    # Trying a different method for calculating the function's uncertainty
    fun_V = []
    for i in range(len(X_0)):
        S = np.transpose(X_0[i,:])
        fun_V.append(np.matmul(np.matmul(np.transpose(S),V),S))

    fun_V = np.array(fun_V)

    # Functional Standard Deviation
    fun_SD = np.power(fun_V,0.5)

    # Getting bounds
    time_short = time_flat[0:num_hrs]
    AVG_vals = np.polyval(coef,time_short)

    # coef - an array fitted parameters from polyfit
    # SD_mat - an array of parameter standard deviations
    # AVG_vals - model evaluation for each hour
    # fun_SD - standard deviation for every hour
    return coef, SD_mat, AVG_vals, fun_SD[0:num_hrs]

def data_bounds(AVG_vals, fun_SD,**kwargs):
# This function is purely to get the bounds associated with the functional fitting
#   The model is assumed to have already been evaluated
#
# AVG_vals - each hour's model value
# SD_vals  - the standard deviation at each hour

    num_sigmas = kwargs.get("num_sigmas",3)

    UB_vals = AVG_vals + num_sigmas*fun_SD
    LB_vals = AVG_vals - num_sigmas*fun_SD

    bounds = np.transpose(np.vstack([UB_vals,LB_vals]))

    return bounds

def pull_color(color_count):

    col_tup = ( '#1f77b4',
                '#ff7f0e',
                '#2ca02c',
                '#d62728',
                '#9467bd',
                '#8c564b',
                '#e377c2',
                '#7f7f7f',
                '#bcbd22',
                '#17becf',
                (0.3 , 0.5 , 0.2),
                (0.2 , 0.4 , 0.6),
                (0.2 , 0.2 , 0.5) )

    col_val = col_tup[color_count%len(col_tup)]

    return col_val


# ==============================================================================
date_range = ["02-15-2018","03-30-2018"]
my_month = "October"
region_name = "CISO"

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

# region_name = ["DUK"] #, "CISO", "SWPP"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]


# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
data_list = final_data(date_range, data_type, region_name,
                       sub_source_list=sub_source_list,
                       normalized=True,
                       interval=24,
                       return_df=False )

# Creates a datafram rows=day, column=hr
# my_df = pd.DataFrame(my_list)
# test = np.array(np.hstack(my_list))
coef, SD_mat, AVG_vals, fun_SD = poly_fit(data_list,
                                          type_of_fit="avg",
                                          poly_order=7)

bounds = data_bounds(AVG_vals, fun_SD)


# time_short = np.arange(24)
# plt.figure()
# plt.plot(time_short,np.transpose(data_list),'.k')
# plt.plot(time_short, AVG_vals,LineWidth=3,Color=pull_color(0),path_effects=[pe.Stroke(linewidth=3, foreground='k'), pe.Normal()])
# plt.plot(time_short,bounds,"--",LineWidth=3,Color=pull_color(0))
# plt.show()



# NOTE: Figure out what is going on with the greater than/greater than or equal to in the slice up data function
