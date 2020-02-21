# This python file is meant to use the functions from 'read_demand.py' to read in
#   provide fitted results. This should be a cleansheet to provide final results

# ==============================================================================
#                           IMPORTING PACKAGES
# ==============================================================================

import pandas as pd
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
import sys
import re
# analysis_path = "/Users/AndyJones/Documents/GitHub/master_proj/Analysis"
analysis_path = "C:/Users/agjones6/Documents/GitHub/master_proj/Analysis"
if not analysis_path in sys.path:
    sys.path.append(analysis_path)
import demand_functions as rd

import statsmodels.tsa.api as sm
from statsmodels.tsa.api import ExponentialSmoothing as ExpSmooth

import scipy
from scipy.stats import beta
from scipy.stats import norm

date_range = ["05-01-2019","07-30-2019"]
date_range = ["01-01-2019","03-30-2019"]
region_name = ["CAL"]

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

sub_source_list = [""]

# Calling a class to get all of the model values
load_obj = rd.load_profile(date_range,region_name[0])

# Adding information about the hourly differences to the class
load_obj.calc_diff_info(diff_fit_type="norm") # Puts stuff into .diff_stats
rd.take_deriv(load_obj.hr_obs, load_obj.norm_data)

# Plotting the subplot of all demand distributions
plt.figure()
for hr in range(len(load_obj.diff_stats[:,0])):
    plt.subplot(4,6,hr+1)
    rd.plt_dist(load_obj.diff_stats[hr,:],
            hist_data=load_obj.diff_data[:,hr],
            hist_bins=20)
    plt.title(str(hr))

# plt.close()

# NOTES
    # So the things to keep into consideration are:
    #   - scale_val in predict_from_diff. This changes the maximum value produced from
    #       the method used. This should either be 1 (which makes the max value 1 with
    #       adding) or 'norm' which normalizes the values to 1.

# Getting estimated hourly ramp rates
st_point = load_obj.mean_obs[0] # Starting point for the prediction
st_point = 1 # Starting point for the prediction
new_slopes = load_obj.diff_from_stats(num_sig=2)
time_hr = np.arange(len(new_slopes))
slope_likelihood = rd.check_likelihood(time_hr,new_slopes,load_obj.diff_stats)
# print(slope_likelihood)
# exit()

# Back caluclating a new demand profile
new_demand = rd.predict_from_diff(new_slopes, st_point,scale_val=1)

# Fitting the new demand profile with a polynomial
new_demand = [0.9, 0.75, 0.62, 0.55, 0.6, 0.72, 0.83, 0.94, 1.0, 0.92,
                0.80, 0.70, 0.58, 0.50, 0.45, 0.52, 0.60, 0.75, 0.88, 1.0,
                0.95, 0.88, 0.80, 0.70, 0.6 ]
# new_demand = load_obj.norm_data[38]
new_coef, new_coef_SD, _,_ = rd.poly_fit([new_demand],
                                         type_of_fit="avg",
                                         poly_order=9)

# Using the model to get a mesh
test_dist = np.polyval(new_coef,load_obj.tmesh)

# Getting the slopes of the model
disc_der = rd.take_deriv(load_obj.tmesh,test_dist)
l_test = rd.check_likelihood(load_obj.tmesh,disc_der,load_obj.diff_stats)
# print(new_slopes)
l_str = []
name_str = []
i = 1
for l in l_test:
    name_str.append(str(i).ljust(10))
    l_str.append(str(round(l,3)).ljust(10))
    i += 1
    print(name_str[-1],l_str[-1])
# print(name_str)
# print(l_str)
print("\nMean likelihood: ", np.mean(l_test))
# plt.figure()
# plt.plot(l_test)
# exit()


plt.figure()
plt.plot(load_obj.hr_obs,np.transpose(load_obj.norm_data),'.k')
plt.plot(load_obj.mean_obs,linewidth=3,label="Mean Observations")
plt.plot(load_obj.tmesh,test_dist,linewidth=3,label="Ramp fit")
plt.plot(new_demand,'*c',markersize=10,linewidth=3,label="Ramp Extremes")
plt.legend()
# plt.show()
# Next steps:
    # add the hourly differences to the object.
    # get the distributions of the hourly changes
    # generate new load profiles based on the distributions of hourly changes
        # This might mean generating new hourly points and doing another polyfit.


# Options for writing a demand profile
save_load_picture = ""
save_load_name = "default"
num_points = 100

# %%
# Input for the writing demand function is:
    # q, num_time, directory, filename, st_time, en_time
if save_load_name != "":
    rd.write_demand(new_coef, num_points,
                    filename=save_load_name,
                    connect_time=0)

exit()
## %%
t = np.arange(len(data_list[0]))
my_plots = []
plt.figure()

avg_day = np.polyval(q,tmesh)

# for i in range(len(AVG_vals)):
plt.plot(t,np.transpose(norm_data[0]),'.k',markersize=1.0)#,color=rd.pull_color(i))
plt.plot(t,np.transpose(norm_data[0][0]),'.k',markersize=1.0,label="All Data")#,color=rd.pull_color(i))

# for i in range(len(AVG_vals)):
#     plt.plot(tmesh,mesh_vals[i],linewidth=3,color=rd.pull_color(i),label=region_name[i])
#     plt.plot(t,bounds[i],'--',color=rd.pull_color(i))

# plt.plot(t,AVG_obs[0],'r')
# plt.plot(t,np.transpose(AVG_vals[0]))
di = 15
# plt.plot(t,AVG_vals[0][di],'c--',linewidth=5)
plt.plot(t,np.transpose(norm_data[0][di]),'*r',linewidth=5,label="Single Day's Data")
plt.plot(tmesh,avg_day,'-',linewidth=3,label="Average Behavior")
plt.xlabel("Time of Day (hour)")
plt.ylabel("Normalized Electricity Demand")
# Labeling

plt.grid()
plt.legend()
if save_load_picture != "":
    plt.savefig(save_load_picture)

plt.show()

# ****** January 6 Testing for Dr. Smith
# AVG_vals holds the model evaluations for each hour
# np.mean(data[0], axis=0)
# plt.plot(t,np.mean(data[0], axis=0))
# plt.plot(t,np.transpose(data[0]),'*')



# len(coef[0][0,:])

# %%
# AVG_test = np.array(norm_data[0])
# len(AVG_test[0,:])
#
# del_ind = []
# x = np.linspace(0.3,1.1,1000)
# for i in range(len(AVG_test)):
#     if np.any(AVG_test[i,:] < 0.2):
#         del_ind.append(i)
#
# AVG_test = np.delete(AVG_test,del_ind,axis=0)
# hour_delta = np.squeeze(AVG_test[:,1:] - AVG_test[:,0:-1]) # This is the difference bewtween each hour. Kind of a discrete derivative
# hour_acc = np.squeeze(hour_delta[:,1:] - hour_delta[:,0:-1]) # Basically the discrete acceleration of the grid demand
# my_dist = np.array([0.7, 0.6, 0.52, 0.48, 0.45, 0.48, 0.55, 0.73, 0.84, 0.80, 0.82, 0.72, 0.50,
#            0.58, 0.72, 0.81, 0.82, 0.84, 0.80, 0.78, 0.76, 0.74, 0.72, 0.70])
# my_delta = my_dist[1:] - my_dist[0:-1]
# my_delta
#
# for i in range(len(AVG_test[:,0])):
#     a, b, mloc, sca = beta.fit(AVG_test[:,i])
#
#     t_dist = beta.pdf(x,a,b,loc=mloc,scale=sca)
#     plt.figure()
#     plt.plot(x,t_dist)
#     # plt.hist(AVG_test[:,i],density=True,bins=30)
#     plt.hist(AVG_test[:,i],density=True,bins=30)
#     plt.title(i)
#     # print(a, b, mloc, sca)
#
#     # if i != 4:
#     #     plt.close()
#     # else:
#     #     plt.show()
#     #     exit()
#     # plt.close()
# plt.show()
# # %% test_cdf = beta.cdf(x,a,b,loc=mloc,scale=sca)
# # plt.plot(x,test_cdf)
# x2 = np.linspace(-0.2,0.2,1000)
# mu, std = norm.fit(hour_delta[:,7])
# mu, std
# test = abs(mu - my_delta[7])/std
# test
# my_delta[7]
# plt.plot(x2,norm.pdf(x2,mu,std))
#
# plt.hist(hour_delta[:,7])
# norm.stats(hour_delta[:,i],moments='mvsk')



# len(hour_delta)
# hour_delta[:,0]
# plt.hist(hour_delta[:,0])
# %% ========================= SQUARED ERROR ABOUT THE MEAN =======================
# This is finding the sum of squared errors
# SS_error = np.sum((AVG_vals[0] - AVG_obs[0])**2,axis=1)
#
# # Testing a histogram of the sum of squares
# a = plt.hist(SS_error,bins=30,range=(0,0.5))
# plt.show()
#
# bnds = a[1]
# hist_loc = np.digitize(SS_error,bnds)
# my_groups = [[]]*30
#
# # --> This was trying to use the observed squared error distribution to relate each parameter in the group
# beta_coef = []
# for i in range(len(my_groups)):
#     n = i + 1
#     curr_set_logic = hist_loc == n #coef[0][hist_loc == n]
#     i2 = 0
#     curr_set_val = []
#     for c_log in curr_set_logic:
#         if c_log:
#             curr_set_val.append(coef[0][i2])
#         i2 += 1
#
#     beta_coef.append(np.array(curr_set_val))
#
# for i in range(len(beta_coef)):
#     b = beta_coef[i]
#     if not len(b) == 0:
#         plt.hist(b[:,1])
#         plt.show()




# plt.show()
# a, b = 2, 5
# t2 = beta.pdf(test,a,b)
# t2
# # t2 = beta.rvs(5,2)
# # t3 = beta.fit(t3)
# plt.hist(t2,bins=30,range=(0,0.1))
# **********

# %% =================== Testing for time series analysis ========================
# data_df = rd.final_data(date_range, data_type, region_name[0],
#               sub_source_list=sub_source_list,
#               normalized=True,
#               interval=1,
#               return_df=True )
# pred_df = rd.final_data(date_range, "Day-ahead demand forecast", region_name[0],
#               sub_source_list=sub_source_list,
#               normalized=True,
#               interval=1,
#               return_df=True )
#
# fit1 = ExpSmooth(data_df[0:-48],
#                  seasonal_periods=24*7,
#                  trend='add',
#                  damped=True,
#                  seasonal='add').fit(use_boxcox=True)
#
# # Plotting the forecasting
# plt.plot(data_df,'*--')
# plt.plot(pred_df,'.k')
# fit1.forecast(48).plot()
# fit1.predict(0,len(fit1.fittedvalues)).plot(style='--', color='red')
# plt.show()
