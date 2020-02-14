from sim_functions import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re
import shutil
import subprocess

src_dir = "./Results/CAR_winter2"

# Pulling all of the ".dat" files in a directory
rawData, runNames = get_folder_rawData(src_dir)

new_Names = []
new_Data = []
for i in range(len(runNames)):
    if not "0" in runNames[i]:
        new_Names.append(runNames[i])
        new_Data.append(rawData[i])
        # del runNames[i]
        # runNames.del(i)

runNames = new_Names
rawData = new_Data

# Normalizing
norm = False

# List of thinks to plot
data_list = ["MDNBR"]
ylabel_list = ["MDNBR"
               ]
figure_names = ["MDNBR.png"
                ]

for i in range(len(data_list)):
    data_name = data_list[i]
    comp_plot(rawData, data_name ,
               keep_fig=True,
               case_names=runNames,
               normalized=norm,
               ylabel=ylabel_list[i])
    if figure_names[i] != "":
        plt.savefig("./pictures/" + "winter_" +  figure_names[i])
# plt.show()
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
