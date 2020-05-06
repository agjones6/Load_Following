from sim_functions import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re
import shutil
import subprocess

my_ylim = None #[0.55,1.05]
run_name = "TES_extreme"
src_dir = "./Results/" + run_name
src_sub_dir = ["Case0","Case1","Case2","Case3","Case4","Case5"]
src_sub_dir = ["Case1","Case2","Case3"]
# src_sub_dir = ["Case3"]
# src_dir = "./Results/extreme_cases/Case0"

all_rawData = []
all_runNames = []
for s in src_sub_dir:
    c_src = src_dir + "/" + s
    if not os.path.isdir(c_src):
        continue
    print(c_src)

    # Pulling all of the ".dat" files in a directory
    rawData, runNames = get_folder_rawData(c_src)

    new_Names = []
    new_Data = []
    skip0s = True
    for i in range(len(runNames)):
        if skip0s:
            if not "0" in runNames[i]:
                new_Names.append(runNames[i])
                new_Data.append(rawData[i])
                # del runNames[i]
                # runNames.del(i)
        else:
            new_Names.append(runNames[i])
            new_Data.append(rawData[i])

    # runNames = new_Names
    # rawData = new_Data
    for r,nN in zip(new_Data,new_Names):
        all_rawData.append(r)
        all_runNames.append(nN)

# Normalizing
norm = True

# List of thinks to plot
data_list = ["Wload","Wturb","Steam Flow - norm","Steam Flow - raw","Qrx","MDNBR - raw","TCL Hot - raw"]
# data_list = ["Wload"]
# data_list = ["MDNBR - raw","Steam Flow"]

ylabel_list = ["Normalized Turbine Load", "Normalized Turbine Output",
               "Normalized Steam Flow Rate", "Steam Flow Rate (lbm/hr)",
               "Normalized Reactor Power", "MDNBR", "Peak Fuel Centerline Temperature (degrees F)"
               ]
save_figures = True

# Making a folder for pictures
pic_dest = "./pictures/" + run_name

if not os.path.isdir(pic_dest):
    os.mkdir(pic_dest)

print(all_runNames)
# plt.figure()
for i in range(len(data_list)):
    data_name = data_list[i]

    # Normalizing if desired
    opt = data_name.split("-")

    # If an option is given
    if len(opt) > 1:
        data_name = opt[0].strip()
        opt = opt[-1].strip()
    else:
        opt = "norm"
        data_name = data_name.strip()

    if opt == "norm":
        norm = True
        pic_name = data_name + "_" + opt
    else:
        norm = False
        pic_name = data_name

    comp_plot(all_rawData, data_name ,
               keep_fig=True,
               case_names=all_runNames,
               normalized=norm,
               create_fig=True,
               colors=[0,1],
               linewidth=[1.6,2.5], # [n,m]
               ylabel=ylabel_list[i]
               )
    plt.legend(["mPower","NuScale"])
    # plt.ylim(my_ylim)
    # plt.xlim([15000,16000])
    if save_figures:
        # plt.savefig("./pictures/realizations/" + run_name + "_" + data_name.replace(" ","-"))
        plt.savefig(pic_dest + "/" + pic_name)
plt.show()
exit()
# %% Checking output
# current_df = get_df("./System.dat")

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
