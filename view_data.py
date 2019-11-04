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

def comp_plot(df_list, ystring , **kwargs):
    # Handling the optional inputs
    xstring = kwargs.get('xstring', "Time")
    title = kwargs.get('title', "")
    dest_folder = kwargs.get('dest_folder',"")
    keep_fig = kwargs.get('keep_fig',True)
    case_names = kwargs.get('case_names',"")
    normalized = kwargs.get('normalized',False)

    # Plotting the desired data
    dum_fig = plt.figure()
    for df in df_list:
        xvals = df[xstring]

        if normalized:
            yvals = df[ystring]/df[ystring][0]
        else:
            yvals = df[ystring]

        plt.plot(xvals,yvals)
        plt.xlabel(xstring)
        plt.ylabel(ystring)

    if case_names != "" and len(case_names) == len(df_list):
        plt.legend(case_names)

    # --> Future functionality for saving output directly
    # if file_name != "":
    #     plt.savefig(os.path.join(case_dest,
    #                 str(burnup[case_count][i]) + "_" + file_name))

    # Closing the figure if it is not desired to keep it
    if not keep_fig:
        plt.close(dum_fig)

#  ============================================================================

# Defining a source folder
src_dir = "./Results/myCase2"

rawData = []
runNames = []
for file in os.listdir(src_dir):
    # Getting the file extenion
    ext = file.split(".")[-1]

    # If the file is a .dat file, pull the data
    if ext == "dat":
        rawData.append(get_df(os.path.join(src_dir,file)))
        runNames.append(file.split(".")[0])



comp_plot(rawData,"Demand" ,
           keep_fig=True,
           case_names=runNames,
           normalized=True)


plt.show()
# %%

# ['Time', 'Qrx', 'Qth', 'Qtrans', 'Flowv', 'Pp', 'Px', 'PxIND', 'PRZLVL',
#'PRZLVLIND', 'VelSRG', 'QHTRP', 'QHTRB', 'SCV Position', 'Spray GPM', 'THL',
#'THL Ind', 'TCL', 'TCL Ind', 'TaveREF', 'Tave', 'Tave Ind', 'Tmod', 'Flow SFWS',
#'Flow FD', 'Flow FD Ind', 'Demand', 'Steam Flow', 'Steam Flow Ind', 'Wload',
# 'Wturb', 'Omega FP', 'Texit SG 1', 'Texit SG IND', 'SG Exit Void', 'Dryout 1',
#'SGLVL Ind', 'Trx', 'TCL Hot', 'MDNBR', 'Tfeed', 'TfeedIND', 'Qsteam', 'PSG',
#'PSG Ind', 'Pimp', 'DeltaP SG', 'DeltaP SG IND', 'DP elev SG', 'Deltat', 'rho',
#'rhoX', 'FCV', 'FBV', 'SFWV', 'TCV 1', 'TCV 2', 'TCV 3', 'TCV 4', 'TBV 1',
#'TBV 2', 'TBV 3', 'TBV 4', 'BANK A', 'BANK B', 'BANK C', 'BANK D', 'RhoCBA',
#'RhoCBB', 'RhoCBC', 'RhoCBD', 'TESLoad', 'TESFlowDemand', 'FlowAUX1', 'FlowAUX2',
# 'FlowAUX3', 'PTAP', 'Tsat Tap', 'PTES', 'TES_TBV(1)', 'TES_TBV(2)', 'TES_TBV(3)',
#'TES_TBV(4)']
