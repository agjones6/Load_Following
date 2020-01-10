from sim_functions import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re
import shutil
import subprocess

src_dir = "./Results/myCase8"

rawData = []
runNames = []
for file in os.listdir(src_dir):
    # Getting the file extenion
    ext = file.split(".")[-1]

    # If the file is a .dat file, pull the data
    if ext == "dat":
        rawData.append(get_df(os.path.join(src_dir,file)))
        runNames.append(file.split(".")[0])

norm = False

data_list = ["Qrx"]

for data_name in data_list:
    comp_plot(rawData, data_name ,
               keep_fig=True,
               case_names=runNames,
               normalized=norm)

plt.show()

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
