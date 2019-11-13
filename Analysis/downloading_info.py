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

my_key = "d1dc5bf9effa0cab55bca470266b6339"
def series_API(series_key):
    return "http://api.eia.gov/series/?series_id=" + series_key + "&api_key=" + my_key #+ "[&num=][&out=xml|json]"

category_API = "http://api.eia.gov/category/?api_key=d1dc5bf9effa0cab55bca470266b6339&category_id="


test = requests.get("http://api.eia.gov/category/?api_key=d1dc5bf9effa0cab55bca470266b6339&category_id=2123635")
test = requests.get("http://api.eia.gov/category/?api_key=d1dc5bf9effa0cab55bca470266b6339&category_id=2122628")
test_json = test.json()

# duke_json = requests.get(base_API + "")
duke_cat = (test_json["category"]["childcategories"][23]["category_id"])
duke_json = requests.get(category_API + str(duke_cat)).json()
duke_json

duke_demand_series = "EBA.DUK-ALL.D.H"
duke_demand_json = requests.get(series_API(duke_demand_series)).json()
duke_demand_data = duke_demand_json["series"][0]["data"]
test_array = np.array(duke_demand_data)
test_array[0]
t = np.array([i[0] for i in test_array])
d = np.array([i[1] for i in test_array])
print(np.divide(len(d),24))
# plt.plot(d[0:500])
# plt.show()


# %%
exit()
