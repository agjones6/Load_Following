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
from scipy.stats import norm
from scipy.stats import beta
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

    # This little section makes the end of one day the same as the previous day
    endpoint_shit = True
    if endpoint_shit:
        first_hour = data_array[:,0]
        shifted_data = np.zeros(len(first_hour))
        shifted_data[0:-1] = first_hour[1:]
        dum_arr = np.column_stack((data_array,shifted_data))
        data_array = np.delete(dum_arr,-1,axis=0)

    # If the data is desired to be normalized
    if normalized == "range":
        max_val = np.nanmax(data_array)
        data_array = np.divide(data_array,max_val)
    elif normalized == "day":
        for i in range(len(data_array)):
            max_val = np.nanmax(data_array[i])
            data_array[i] = data_array[i]/max_val

    if return_df:
        # converting to a data frame
        return pd.DataFrame(data_array)
    else:
        return data_array

def normalize_data(data_list,**kwargs):
# This function is made to normalize the data passed through in different ways
    norm_type = kwargs.get("norm_type","range")

    if norm_type == "range":
        max_val = np.nanmax(data_list)
        norm_data = np.divide(data_list,max_val)
    elif norm_type == "day":
        max_list = [np.max(data_list[i]) for i in range(len(data_list)) ]
        norm_data = []
        for i in range(len(data_list)):
            norm_data.append(data_list[i]/max_list[i])

    return np.array(norm_data)
def check_data(data_array):
# This function is made to check all of the days for missing data and remove the
#   days that are missing.
    data_array = np.array(data_array)
    # This gets the number of hours and days as variables
    try:
        dum_sz = data_array.shape
    except:
        dum_sz = np.shape(data_array)

    try:
        num_days = int(dum_sz[0])
        num_hrs  = int(dum_sz[1])
    except:
        num_days = 1
        num_hrs = int(dum_sz[0])
        return data_array

    # Going through every day to find nan's
    new_data = []
    for i in range(num_days):
        curr_data = data_array[i]
        if not np.isnan(curr_data).any():
            new_data.append(curr_data)

    new_data = np.array(new_data)

    return new_data

def avg_coef(time_array,data_array,num_days,poly_order, **kwargs):

    return_all = kwargs.get("return_all",False)

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

    if return_all:
        return all_coef, Problem_Data
    else:
        return coef, Problem_Data

def poly_fit(data_array, **kwargs):
# This function is made to return the coefficients of the desired polynomial.
#   The input data_array should be a row x col = day x hr matrix

    poly_order = kwargs.get("poly_order",5)
    confidence_value = kwargs.get("confidence_value",0.98)
    type_of_fit = kwargs.get("type_of_fit","avg")
    return_all = kwargs.get("return_option",False)

    # Removing days with nan's in them
    data_array = check_data(data_array)

    # This gets the number of hours and days as variables
    dum_sz = data_array.shape
    try:
        num_days = dum_sz[0]
        num_hrs  = dum_sz[1]
    except:
        num_days = 1
        num_hrs = dum_sz[0]


    DOF = num_hrs - (poly_order + 1)

    # Gets a singular array of times (0-23) hours
    dum_times = [np.array(np.arange(num_hrs))]
    # Time array is built
    time_array = dum_times
    for i in range(num_days-1):
        time_array = np.concatenate((time_array,dum_times))

    # Getting flat arrays
    time_flat = np.array(time_array).flatten()
    data_flat = np.array(data_array).flatten()

    # Getting a polynomial fit coefficients for the data array
    try:
        if type_of_fit == "avg": # Using all of the data at the same time
            coef = np.polyfit(time_flat, data_flat, poly_order)
            all_coef = [coef]
        elif type_of_fit.lower() == "ind":
            all_coef, _ = avg_coef(time_array,data_array,num_days,poly_order,return_all=True)
        else: # Individual but averaged later
            coef, _ = avg_coef(time_array,data_array,num_days,poly_order)
            all_coef = [coef]
    except Exception as e:
        print("error in fitting polynomial")
        coef,Problem_Data = avg_coef(time_array,data_array,num_days,poly_order)

    # Adding a loop to do all of these actions for each individual set of parameters
    SD_mat_list = []
    AVG_vals_list = []
    fun_SD_list = []
    coef_list = []
    for coef in all_coef:
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
        #
        # # Getting the t distribution value
        # t_dist = t(df=DOF)
        # t_val = t_dist.ppf(confidence_value)
        #
        # dq = []
        # for d in SD_mat:
        #     dq.append(t_val*d)
        #
        # dq = np.array(dq)
        #
        # q_UB = coef + dq
        # q_LB = coef - dq
        #
        # model_UB = np.polyval(q_UB,t_mesh)
        # model_LB = np.polyval(q_LB,t_mesh)

        # Trying a different method for calculating the function's uncertainty
        fun_V = []
        for i in range(len(X_0)):
            S = np.transpose(X_0[i,:])
            fun_V.append(np.matmul(np.matmul(np.transpose(S),V),S))

        fun_V = np.array(fun_V)

        # Functional Standard Deviation
        fun_SD = np.power(fun_V,0.5)
        fun_SD = fun_SD[0:num_hrs]

        # Getting bounds
        time_short = time_flat[0:num_hrs]
        AVG_vals = np.polyval(coef,time_short)

        SD_mat_list.append(SD_mat)
        AVG_vals_list.append(AVG_vals)
        fun_SD_list.append(fun_SD)
        coef_list.append(coef)

    # coef - an array fitted parameters from polyfit
    # SD_mat - an array of parameter standard deviations
    # AVG_vals - model evaluation for each hour
    # fun_SD - standard deviation for every hour
    if type_of_fit.lower() == "avg":
        return coef, SD_mat, AVG_vals, fun_SD
    else:
        return coef_list, SD_mat_list, AVG_vals_list, fun_SD_list

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

# --> This will be a subroutine to write demand curves to text files to be used in Dr. Doster's code
def write_demand(q,num_time,**kwargs):
    # Handling optional key words
    directory = kwargs.get("directory","./Load_Profiles") # Directory Location
    filename = kwargs.get("filename","default")           # File name. 'default' will open one named load_profile#.txt
    st_time = kwargs.get("st_time", 0)                    # Starting time to write
    en_time = kwargs.get("en_time", 24)                   # Ending time
    connect_time = kwargs.get("connect_time", 0)            # Continuous days. This makes the last point match the first this time

    # Checking if the directory exists, if not it is created
    if not os.path.isdir(directory):
        os.mkdir(directory)

    # Checking if the file name is "default"
    if filename.lower() == "default":
        num_list = []
        for file in os.listdir(directory):
            if "load_file" in file:
                # Getting the name of the file without the extension
                base_name = file.split(".")[0]

                # Checking the number at the end of the base name
                regex = r'load_file(\d*)'

                found_text = re.search(regex, base_name)
                try:
                    num_list.append(int(found_text.group(1)))
                except:
                    pass

        # Finding the maximum number
        if len(num_list) == 0:
            new_num = 0
        else:
            new_num = max(num_list) + 1

        # Getting the new filename
        filename = "load_file" + str(new_num) + ".txt"

    # Defining a time mesh
    t_mesh = np.linspace(st_time,en_time - connect_time, num_time)

    # Calculating values using the polyval function
    model_vals = np.polyval(q,t_mesh)

    # Fixing values if connecting start and end is desired
    if connect_time != 0:
        num_time = num_time + 1
        model_vals = np.append(model_vals,model_vals[0])
        t_mesh = np.append(t_mesh,en_time)

    # Putting the time and model values into a matrix
    print_mat = np.vstack((t_mesh,model_vals*100))

    # Writing to the file
    filepath = os.path.join(directory,filename)
    f = open(filepath,"w")
    f.write(str(num_time) + " \n")
    for i in range(num_time):
        f.write(str(t_mesh[i]) + ", " + str(model_vals[i]*100))
        f.write(" \n")

    f.close()

def plt_dist(stats,**kwargs):
# This function is designed to plot a given distribution either normal or beta
#   depending on the stats passed through and set the bounds for the plot
# If desired, a histogram is also plotted against the distribution
    hist_data = kwargs.get("hist_data",[])
    hist_bins = kwargs.get("hist_bins",10)
    bounds = kwargs.get("bounds",3)
    num_points = kwargs.get("num_points",1000)

    # Getting the values for the desired distribution
    if len(stats) == 2: # Normal Distribution
        # Calculating an x distribution
        LB = stats[0] - stats[1]*bounds
        UB = stats[0] + stats[1]*bounds
        x_dist = np.linspace(LB,UB,num_points)
        dist_vals = norm.pdf(x_dist,stats[0],stats[1])
    elif len(stats) == 4: # Beta distribution
        # Calculating an x distribution
        LB = stats[2] - 0.01
        UB = stats[2] + stats[3] + 0.01
        x_dist = np.linspace(LB,UB,num_points)
        dist_vals = beta.pdf(x_dist,stats[0],stats[1],loc=stats[2],scale=stats[3])
    else:
        return

    # Plotting the distributions
    # plt.figure()
    plt.plot(x_dist,dist_vals)

    if hist_data != []:
        plt.hist(hist_data, density=True, bins=hist_bins)

    plt.xlim((LB,UB))

def predict_from_diff(s_list,P0,**kwargs):
# This function is designed to predict a load profile with given values for
#   a given list of slopes and an intial starting load
#
# s_list = a list of slopes
# P0 = the starting point

    dx = kwargs.get("dx",1)
    scale_val = kwargs.get("scale_val",1)

    P_list = [P0]
    for i in range(len(s_list)):
        s = s_list[i]
        P_list.append(s*dx + P_list[-1])

    P_list = np.array(P_list)

    if scale_val != None:
        if scale_val == "norm":
            P_list = P_list/np.amax(P_list)
        else:
            P_list = P_list + (scale_val - np.amax(P_list))

    return P_list

def check_likelihood(tmesh, V, stats, **kwargs):
# This funciton is made to check the likelihood of a model. This is done by
    # comparing the model realization versus the hourly distribution for the
    # observations.

    time_hr = kwargs.get("time_hr",np.arange(len(stats)))

    # This loop pulls the values to directly compare to the discrete hours.
        # The weird structure basically only adds to the compare value list when
        # the time mesh is equal to the course mesh.
    r = 0
    comp_vals = []
    dum_V = []
    checked_slopes = []
    for i in range(len(tmesh)):
        t = tmesh[i]

        # print(t,time_hr[r],time_hr[r+1])
        if r <= len(time_hr) - 2:
            if t >= time_hr[r] and t < time_hr[r+1]:
                dum_V.append(V[i])
            elif t >= time_hr[r+1]:
                checked_slopes.append(np.nanmean(dum_V))
                comp_vals.append(checked_slopes[-1])
                dum_V = [V[i]]
                r += 1
        elif r <= len(time_hr) - 1:
            if i != len(tmesh) - 1:
                if t >= time_hr[r] and t < time_hr[r] + 1:
                    dum_V.append(V[i])
                elif t >= time_hr[r] + 1:
                    checked_slopes.append(np.nanmean(dum_V))
                    comp_vals.append(checked_slopes[-1])
                    dum_V = []
                    r += 1
            else:
                checked_slopes.append(np.nanmean(dum_V))
                comp_vals.append(checked_slopes[-1])
        else:
            break
    # print(np.array(checked_slopes))
        # if r > len(time_hr) - 1:
        #     break

    # Discerning the type of distribution
    if len(stats[0]) == 2:
        dist_name = "norm"
    elif len(stats[0]) == 4:
        dist_name = "beta"
    else:
        print("Unkown distribution")
        return

    # At this point, comp_vals should be the same length as stats
    res_val = []
    for i in range(len(comp_vals)):
        if dist_name == "norm":
            mean = stats[i,0]
            sigma = stats[i,1]

            res_val.append(abs(comp_vals[i] - mean)/sigma)

    return np.array(res_val)

def take_deriv(time, fx):
    # This calculates the discrete hourly derivative for each day
    # Handling the case of one day or multiple days
    if len(fx.shape) == 1:
        der = (fx[1:] - fx[0:-1])/(time[1:] - time[0:-1])
    else:
        der = (fx[:,1:] - fx[:,0:-1])/(time[1:] - time[0:-1])

    return der

# ==============================================================================
#                           MAKING A CLASS
# ==============================================================================
class load_profile:
    def __init__(self,date_range,region_name, **kwargs):
        self.date_range = date_range
        self.region_name = region_name


        self.data_type = kwargs.get("data_type","Demand")

        # OPTIONAL ARGUMENTS
        #
        # sub_source_list = The subset of data to subtract to show instabilities
        # poly_order = the order of polynomial to use in the fit
        # type of fit = [ind,avg] This is how the function makes polynomial fits.
        #                   'ind' does every day seperately. 'avg' puts all of the data together
        # norm_type = ["day","range"] This determines how the data is normalized.
        #                   'day' normalizes based on each day's max. 'range' normalizes
        #                   based on the max value in the desired range
        #

        self.sub_source_list = kwargs.get("sub_source_list",[""])
        # sub_source_list = ["wind","solar"]

        self.poly_order = kwargs.get("poly_order",9)
        self.type_of_fit = kwargs.get("type_of_fit","ind")
        self.norm_type = kwargs.get("norm_type","day")

        self.get_polyfit()

    def get_polyfit(self):
        # =================== THIS USES POLYNOMIAL FITS ============================
        # This either returns a pandas Data frame or numpy array
        #   scheme is row = day, column = hr
        self.tmesh = np.linspace(0,24,1000)
        self.hr_obs = np.arange(25)

        #       for every region. So it follows DATA[REGION] or DATA[REGION][DAY]
        self.raw_data = final_data(self.date_range, self.data_type, self.region_name,
                                       sub_source_list=self.sub_source_list,
                                       normalized=False,
                                       interval=24,
                                       return_df=False )

        # Normalizing data
        self.norm_data = normalize_data(self.raw_data,norm_type="day")

        # fitting the polynomial and getting some basic stats about it
        dum_tup = poly_fit(self.norm_data,
                              type_of_fit=self.type_of_fit,
                              poly_order=self.poly_order)

        # Getting the values from the polynomial fit
        self.coef = dum_tup[0]
        self.coef_SD = dum_tup[1]
        self.model_mean = dum_tup[2]
        self.model_SD = dum_tup[3]

        # Calculating the average observation value
        self.mean_obs = np.mean(self.norm_data,axis=0)

        # This stores data for every day if the type of fit is "individual"
        if self.type_of_fit.lower() == "ind":
            self.model_bounds = []
            self.mesh_vals = []
            for i in range(len(self.coef)):
                self.model_bounds.append(data_bounds(self.model_mean[i],self.model_SD[i],num_sigmas=2))
                self.mesh_vals.append(np.polyval(self.coef[i],self.tmesh))
        else:
            self.model_bounds = data_bounds(self.model_mean,self.model_SD,num_sigmas=2)
            self.mesh_vals = np.polyval(coef[-1],tmesh)


        # %% FINDING THE MAXIMUM DEMAND PER DAY
        self.daily_max_list = [np.max(self.raw_data[i]) for i in range(len(self.raw_data)) ]
        # plt.hist(max_list,bins=45)

    def calc_diff_info(self, **kwargs):
    # This function is made to calculate the differences in electricity demand per hour
    #   to apply to calculating ramp rates
    # Results in the distribution stats as well:
    #   norm: [mean, standard deviation]
    #   beta: [a, b, mLoc, sca]

        self.diff_fit_type = kwargs.get("diff_fit_type","norm")

        # This calculates the discrete hourly derivative for each day
        self.diff_data = self.norm_data[:,1:] - self.norm_data[:,0:-1]

        # Calculating distributions for each of the hourly differences
        # self.diff_mean_list = []
        # self.diff_SD_list = []
        self.diff_stats = []
        for i in range(len(self.diff_data[0,:])):
            if self.diff_fit_type.lower() == "norm":
                self.diff_stats.append(norm.fit(self.diff_data[:,i]))
            elif self.diff_fit_type.lower() == "beta":
                self.diff_stats.append(beta.fit(self.diff_data[:,i]))


        # self.diff_mean_list = np.array(self.diff_mean_list)
        # self.diff_SD_list = np.array(self.diff_SD_list)
        self.diff_stats = np.array(self.diff_stats)

    def diff_from_stats(self,**kwargs):
    # This is made to find reasonable slopes from the calculated slope distributions
        num_sig = kwargs.get("num_sig",2)

        # Making sure that
        try:
            self.diff_stats
        except:
            print("make sure to run calc_diff_info. Without it, the neccessary info is not availible")
            return

        s_list = []
        if len(self.diff_stats[0,:]) == 2:
            for i in range(len(self.diff_stats[:,0])):
                mu = self.diff_stats[i,0]
                sig = self.diff_stats[i,1]

                if mu >= 0:
                    new_s = mu + num_sig * sig
                else:
                    new_s = mu - num_sig * sig

                s_list.append(new_s)
        else:
            return

        return np.array(s_list)
