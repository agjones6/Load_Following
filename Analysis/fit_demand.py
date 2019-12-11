# This python file is meant to use the functions from 'read_demand.py' to read in
#   provide fitted results. This should be a cleansheet to provide final results

import pandas as pd
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
import read_demand as rd

date_range = ["10-01-2019","10-30-2019"]
my_month = "October"
region_name = "CISO"

data_type = "Net generation by energy source" # "Demand"
data_type = "Demand"

# region_name = ["DUK"] #, "CISO", "SWPP"

sub_source_list = [""]
# sub_source_list = ["wind","solar"]


# This either returns a pandas Data frame or numpy array
#   scheme is row = day, column = hr
my_list = rd.final_data(date_range, data_type, region_name,
              sub_source_list=sub_source_list,
              normalized=True,
              interval=24,
              return_df=False )

# Creates a datafram rows=day, column=hr
# my_df = pd.DataFrame(my_list)
# test = np.array(np.hstack(my_list))
rd.poly_fit(my_list)
# t = [np.arange(24)]*4
# print(np.hstack(t))
# exit()
