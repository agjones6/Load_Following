# This python file is meant to use the functions from 'read_demand.py' to read in
#   provide fitted results. This should be a cleansheet to provide final results

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
import read_demand as rd

import statsmodels.tsa.api as sm
from statsmodels.tsa.api import ExponentialSmoothing as ExpSmooth

import scipy
from scipy.stats import beta
from scipy.stats import norm

date_range = ["01-01-2019","02-28-2019"]
date_range = ["05-01-2019","06-28-2019"]
date_range = ["01-01-2019","01-31-2019"]
region_name = ["CAR","CENT","CAL","US48"]#["CISO","DUK","FLA"]
region_name = [region_name[0]]

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]

# Options for writing a demand profile
save_load_picture = ""
save_load_name = ""
num_points = 100

poly_order = 9
# =================== THIS USES POLYNOMIAL FITS ============================
# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
coef = []
SD_mat = []
AVG_vals = []
fun_SD = []
data = []
norm_data = []
AVG_obs = []
bounds = []
mesh_vals = []
tmesh = np.linspace(0,24,1000)
type_of_fit = "ind"
for reg in region_name:
# Note: at the end of this loop, the data is stored in a list. Each different region
#       makes up the list. Inside the region list, there is another list of each day
#       if the type_of_fit is set to "ind". This stores data protaining to each day
#       for every region. So it follows DATA[REGION] or DATA[REGION][DAY]
    data_list = rd.final_data(date_range, data_type, reg,
                  sub_source_list=sub_source_list,
                  normalized=False,
                  interval=24,
                  return_df=False )

    # Normalizing data
    norm_data.append(rd.normalize_data(data_list,norm_type="day"))

    # Fitting polynomial (un normalized and normalized)
    # dum_tup2 = rd.poly_fit(data_list,
    #                       type_of_fit=type_of_fit,
    #                       poly_order=5)

    dum_tup = rd.poly_fit(norm_data[-1],
                          type_of_fit=type_of_fit,
                          poly_order=poly_order)

    # Getting the values from the polynomial fit
    coef.append(dum_tup[0])
    SD_mat.append(dum_tup[1])
    AVG_vals.append(dum_tup[2])
    fun_SD.append(dum_tup[3])

    # Appending the data do a list
    data.append(data_list)

    # Calculating the average observation value
    AVG_obs.append(np.mean(data[-1],axis=0))

    # This stores data for every day if the type of fit is "individual"
    if type_of_fit.lower() == "ind":
        for i in range(len(coef)):
            bounds.append(rd.data_bounds(AVG_vals[-1][i],fun_SD[-1][i],num_sigmas=2))
            mesh_vals.append(np.polyval(coef[-1][i],tmesh))
    else:
        bounds.append(rd.data_bounds(AVG_vals[-1],fun_SD[-1],num_sigmas=2))
        mesh_vals.append(np.polyval(coef[-1],tmesh))


# %% FINDING THE MAXIMUM DEMAND PER DAY
max_list = [np.max(data_list[i]) for i in range(len(data_list)) ]
# plt.hist(max_list,bins=45)


# %%
# Setting the variable for the coefficients of the polynomial
q = np.squeeze(np.mean(coef,axis=1))
# plt.plot(np.array(range(24)),np.array(norm_data))
# Input for the writing demand function is:
    # q, num_time, directory, filename, st_time, en_time
if save_load_name != "":
    rd.write_demand(q,num_points,filename=save_load_name)

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
