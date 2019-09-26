# import pandas as pd
from pandas import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt

filename = "./1/System.dat"
# pd.read_csv(src_file,index_col=0)
tst = read_table(filename, skiprows=1, header=None, delim_whitespace=True)


plt.plot(tst[0],tst[2])
plt.show()
