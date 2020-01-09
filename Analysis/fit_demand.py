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

date_range = ["01-03-2019","05-30-2019"]
region_name = ["CAR","CENT","CAL"]#["CISO","DUK","FLA"]
region_name = ["CAL"]

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

# region_name = ["DUK"] #, "CISO", "SWPP"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]

# =================== Testing for time series analysis ========================
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


# =================== THIS USES POLYNOMIAL FITS ============================
# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
coef = []
SD_mat = []
AVG_vals = []
fun_SD = []
data = []
AVG_obs = []
bounds = []
mesh_vals = []
tmesh = np.linspace(0,23,1000)
type_of_fit = "ind"
for reg in region_name:
# Note: at the end of this loop, the data is stored in a list. Each different region
#       makes up the list. Inside the region list, there is another list of each day
#       if the type_of_fit is set to "ind". This stores data protaining to each day
#       for every region. So it follows DATA[REGION] or DATA[REGION][DAY]
    data_list = rd.final_data(date_range, data_type, reg,
                  sub_source_list=sub_source_list,
                  normalized=True,
                  interval=24,
                  return_df=False )

    dum_tup = rd.poly_fit(data_list,
                          type_of_fit=type_of_fit,
                          poly_order=5)

    coef.append(dum_tup[0])
    SD_mat.append(dum_tup[1])
    AVG_vals.append(dum_tup[2])
    fun_SD.append(dum_tup[3])

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


# Setting the variable for the coefficients of the polynomial
q = np.squeeze(np.mean(coef,axis=1))

rd.write_demand(q,100,filename="default")

# Converting to numpy arrays
# coef = np.transpose(np.array(coef))
# SD_mat = np.transpose(np.array(SD_mat))
# AVG_vals = np.transpose(np.array(AVG_vals))
# fun_SD = np.transpose(np.array(fun_SD))

# ****** January 6 Testing for Dr. Smith
# AVG_vals holds the model evaluations for each hour
# np.mean(data[0], axis=0)
# plt.plot(t,np.mean(data[0], axis=0))
# plt.plot(t,np.transpose(data[0]),'*')

# This is finding the sum of squared errors
SS_error = np.sum((AVG_vals[0] - AVG_obs[0])**2,axis=1)
# bnds = a[1]
# hist_loc = np.digitize(test,bnds)
# my_groups = [[]]*30

# Testing a histogram of the sum of squares
# a = plt.hist(test,bins=30,range=(0,0.5))
# plt.show()

# len(coef[0][0,:])
AVG_test = np.array(data[0])
len(AVG_test)
len(np.delete(AVG_test,[0,3,4],axis=0))

del_ind = []
x = np.linspace(0,1,1000)
for i in range(len(AVG_test)):
    if np.any(AVG_test[i,:] < 0.2):
        del_ind.append(i)

AVG_test = np.delete(AVG_test,del_ind,axis=0)
for i in range(24):
    a, b, mloc, sca = beta.fit(AVG_test[:,i])

    t_dist = beta.pdf(x,a,b,loc=mloc,scale=sca)
    plt.figure()
    plt.plot(x,t_dist)
    plt.hist(AVG_test[:,i],density=True,bins=30)
    plt.title(i)
    print(a, b, mloc, sca)

    plt.show()


# --> This was trying to use the observed squared error distribution to relate each parameter in the group
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

## %%
t = np.arange(24)
my_plots = []
plt.figure()

for i in range(len(AVG_vals)):
    plt.plot(t,np.transpose(data[i]),'.k')#,color=rd.pull_color(i))

for i in range(len(AVG_vals)):
    plt.plot(tmesh,mesh_vals[i],linewidth=3,color=rd.pull_color(i),label=region_name[i])
    plt.plot(t,bounds[i],'--',color=rd.pull_color(i))

plt.plot(t,AVG_obs[0],'r')
# plt.plot(t,np.transpose(AVG_vals[0]))
plt.plot(t,AVG_vals[0][15],'c--',linewidth=5)
test[15]
plt.legend()
plt.show()
