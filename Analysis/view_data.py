# import pandas as pd
from pandas import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re

def get_df(filename):
    # Getting the file as an object
    my_file = open(filename,'r')

    # Pulling the first line of the file to seperate the headers
    first_line = my_file.readline()

    # Seperating the headers using regex
    regex_header = r'\s\s(\w.*?\(?\w\)?)\s\s'
    header_list = re.findall(regex_header,first_line)
    header_list.append("TES_TBV(4)")

    # Reading in the data from the file
    rawData = pd.read_table(filename, skiprows=1, header=None, delim_whitespace=True)

    # Changing the name of the headers to match what they are in the file
    rawData.columns = header_list

    # Creating a pandas dataframe
    df_file = pd.DataFrame({"file_name":[filename]*len(rawData.index)})

    final_data = pd.concat([df_file,rawData], axis=1, sort=False)


    # Returning the data frame
    return final_data


def basic_plot(df, ystring , **kwargs):
    # Handling the optional inputs
    xstring = kwargs.get('xstring', "Time")
    # ylabel = kwargs.get('ylabel', "")
    title = kwargs.get('title', "")
    dest_folder = kwargs.get('dest_folder',"")
    keep_fig = kwargs.get('keep_fig',True)

    # Plotting the desired data
    dum_fig = plt.figure()
    plt.plot(df[xstring],df[ystring])
    plt.xlabel(xstring)
    plt.ylabel(ystring)

    # --> Future functionality for saving output directly
    # if file_name != "":
    #     plt.savefig(os.path.join(case_dest,
    #                 str(burnup[case_count][i]) + "_" + file_name))

    # Closing the figure if it is not desired to keep it
    if not keep_fig:
        plt.close(dum_fig)

# Defining the file name
filename = "./Results/tst_file.dat"

# Putting the data into a data
rawData = get_df(filename)

# %%
basic_plot(rawData,"Qsteam" ,
           keep_fig=True)
plt.show()
