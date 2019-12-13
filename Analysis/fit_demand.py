# This python file is meant to use the functions from 'read_demand.py' to read in
#   provide fitted results. This should be a cleansheet to provide final results

import pandas as pd
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
import read_demand as rd

date_range = ["01-01-2019","01-30-2019"]
region_name = ["CAR","CENT","CAL","PJM"]#["CISO","DUK","FLA"]

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

# region_name = ["DUK"] #, "CISO", "SWPP"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]


# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
coef = []
SD_mat = []
AVG_vals = []
fun_SD = []
data = []
bounds = []
for reg in region_name:
    data_list = rd.final_data(date_range, data_type, reg,
                  sub_source_list=sub_source_list,
                  normalized=True,
                  interval=24,
                  return_df=False )

    dum_tup = rd.poly_fit(data_list,
                          type_of_fit="avg",
                          poly_order=7)

    coef.append(dum_tup[0])
    SD_mat.append(dum_tup[1])
    AVG_vals.append(dum_tup[2])
    fun_SD.append(dum_tup[3])

    data.append(data_list)
    bounds.append(rd.data_bounds(AVG_vals[-1],fun_SD[-1],num_sigmas=2))

# Converting to numpy arrays
# coef = np.transpose(np.array(coef))
# SD_mat = np.transpose(np.array(SD_mat))
# AVG_vals = np.transpose(np.array(AVG_vals))
# fun_SD = np.transpose(np.array(fun_SD))

t = np.arange(24)
my_plots = []
plt.figure()

# for i in range(len(AVG_vals)):
#     plt.plot(t,np.transpose(data[i]),'.',color=rd.pull_color(i))

for i in range(len(AVG_vals)):
    plt.plot(t,AVG_vals[i],linewidth=3,color=rd.pull_color(i),label=region_name[i])
    plt.plot(t,bounds[i],'--',color=rd.pull_color(i))


plt.legend()
plt.show()
