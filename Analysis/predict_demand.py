# This file is going to be used to predict demand curves
#
# Created: February 18, 2020
#

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

# import statsmodels.tsa.api as sm
# from statsmodels.tsa.api import ExponentialSmoothing as ExpSmooth

import scipy
from scipy.stats import beta
from scipy.stats import norm

# ==============================================================================
#                           DEFINING CONTROL VARIABLES
# ==============================================================================
# Defining how many days to predict out to
num_days = 1
num_trials = 50

# Defining the date range of data to pull in
date_range = ["01-01-2019","03-30-2019"]

# Desired Region Name
region_name = ["FLA"]

# The type of data (should always be demand for the time being )
data_type = "Demand"

# Sub source my later be used to exclude solar/wind/etc, but right now, it is not.
sub_source_list = [""]

# Calling a class to get all of the model values
load_obj = rd.load_profile(date_range,region_name[0])
    # coef = coefficients for each day [day]x[hour]x[coef]
    # mean_obs = the mean observations over the entire date range [hour]
    # daily_max_list = the maximum for each day [hour]
UB_LB = np.array(np.mean(load_obj.model_bounds,axis=0))

# plt.plot(load_obj.hr_obs, load_obj.mean_obs)
# plt.plot(load_obj.hr_obs,UB_LB[:,0],'--k')
# plt.plot(load_obj.hr_obs,UB_LB[:,1],'--k')
# plt.show()
# exit()

# Getting the ramp rates for each hour
load_obj.calc_diff_info(diff_fit_type="norm")
    # diff_stats = normal: [mean, standard deviation]
    #                beta: [a, b, mLoc, sca]
    #              ** for each hour **

# --> Getting all of the hourly ramp rates from each hourly distribution
st_point = load_obj.mean_obs[0] # Starting point for the prediction
hourly_ramps = []
for stat in load_obj.diff_stats:
    hourly_ramps.append(np.random.normal(stat[0],stat[1],(num_days,num_trials)))

# This an array of hourly ramp rates determined by the distributions at each hour
    # (hr, days, trials)
hourly_ramps = np.array(hourly_ramps)

# Getting the mean ramp rates into an array
mean_ramps = load_obj.diff_stats[:,0]

# --> Stacking the days so the produced demand will be continuous
new_slopes = []
a, b, c = hourly_ramps.shape # a is hours, b is number of days out, c is the number of trials
for i2 in range(c):
    dum_stack = []
    for i in range(num_days):
        dum_stack = np.hstack((dum_stack, hourly_ramps[0:,i,i2]))
    new_slopes.append(dum_stack)

# Mean response
mean_slopes = []
for i in range(num_days):
    mean_slopes = np.hstack((mean_slopes, mean_ramps[0:]))

# --> Calculating the new demand values based on the ramp rates
new_demand = []
for trial_slopes in new_slopes:
    new_demand.append(rd.predict_from_diff(trial_slopes, st_point,scale_val="norm"))

# Mean response
mean_demand = rd.predict_from_diff(mean_slopes, st_point,scale_val=None)

new_demand = np.array(new_demand)
plt.plot(range(25),np.transpose(load_obj.norm_data), '.k',linewidth=3)
plt.plot(range(len(new_demand[0])),new_demand.T)
# plt.plot(range(len(new_demand[0])),mean_demand, '--k',linewidth=3)
# plt.plot(load_obj.hr_obs,UB_LB[:,0],'--k')
# plt.plot(load_obj.hr_obs,UB_LB[:,1],'--k')
plt.show()
exit()
print(load_obj.diff_stats[0],load_obj.diff_stats[23])
new_slopes = load_obj.diff_from_stats(num_sig=2)
time_hr = np.arange(len(new_slopes))
slope_likelihood = rd.check_likelihood(time_hr,new_slopes,load_obj.diff_stats)
