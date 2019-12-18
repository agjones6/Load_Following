# This python file is meant to use the functions from 'read_demand.py' to read in
#   provide fitted results. This should be a cleansheet to provide final results

import pandas as pd
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
import sys
# analysis_path = "/Users/AndyJones/Documents/GitHub/master_proj/Analysis"
analysis_path = "C:/Users/agjones6/Documents/GitHub/master_proj/Analysis"
if not analysis_path in sys.path:
    sys.path.append(analysis_path)
import read_demand as rd

import statsmodels.tsa.api as sm
from statsmodels.tsa.api import ExponentialSmoothing as ExpSmooth

date_range = ["01-03-2019","01-06-2019"]
region_name = ["CAR","CENT","CAL"]#["CISO","DUK","FLA"]
region_name = ["CAR"]

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


# %% =================== THIS USES POLYNOMIAL FITS ============================
# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
coef = []
SD_mat = []
AVG_vals = []
fun_SD = []
data = []
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
                          poly_order=7)

    coef.append(dum_tup[0])
    SD_mat.append(dum_tup[1])
    AVG_vals.append(dum_tup[2])
    fun_SD.append(dum_tup[3])

    data.append(data_list)

    # This stores data for every day if the type of fit is "individual"
    if type_of_fit.lower() == "ind":
        for i in range(len(coef)):
            bounds.append(rd.data_bounds(AVG_vals[-1][i],fun_SD[-1][i],num_sigmas=2))
            mesh_vals.append(np.polyval(coef[-1][i],tmesh))
    else:
        bounds.append(rd.data_bounds(AVG_vals[-1],fun_SD[-1],num_sigmas=2))
        mesh_vals.append(np.polyval(coef[-1],tmesh))

# Converting to numpy arrays
# coef = np.transpose(np.array(coef))
# SD_mat = np.transpose(np.array(SD_mat))
# AVG_vals = np.transpose(np.array(AVG_vals))
# fun_SD = np.transpose(np.array(fun_SD))

t = np.arange(24)
my_plots = []
plt.figure()

for i in range(len(AVG_vals)):
    plt.plot(t,np.transpose(data[i]),'.k')#,color=rd.pull_color(i))

for i in range(len(AVG_vals)):
    plt.plot(tmesh,mesh_vals[i],linewidth=3,color=rd.pull_color(i),label=region_name[i])
    plt.plot(t,bounds[i],'--',color=rd.pull_color(i))


plt.legend()
plt.show()
