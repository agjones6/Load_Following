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
    rawData = pd.read_csv(filename,skiprows=1, header=None, delim_whitespace=True)

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
    i = 0
    for df in df_list:
        xvals = df[xstring]

        if normalized:
            # Normalizing based on reactor
            # if case_names != "" and len(case_names) == len(df_list):
                # try:
                #     first_letter = case_names[i][0]
                #     if first_letter.upper() == "N":
                #         nom_pwr =
                #
                # except Exception as e:
                #     print(e)
                #     pass
            yvals = df[ystring]/df[ystring][0]
        else:
            yvals = df[ystring]

        i += 1

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

norm = True

comp_plot(rawData,"Wload" ,
           keep_fig=True,
           case_names=runNames,
           normalized=norm)

comp_plot(rawData,"Wturb" ,
           keep_fig=True,
           case_names=runNames,
           normalized=norm)

comp_plot(rawData,"Qrx" ,
           keep_fig=True,
           case_names=runNames,
           normalized=norm)

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

# ---> This is the order of the initial conditions file. I will used these values for normalizing
# --> Or I can just let it ride for a while at full power and pull the full power values directly into a dataframe
# Read(2,*)Time
# Read(2,*)Qrx,Qth,Qtrans,Trx,Tclad
# Read(2,*)NI,NX
# Read(2,*)(Precursor(j),j=1,6)
# Read(2,*)(gammaDH(j),j=1,11)
# Read(2,*)Flowv,Flow1,Flow2
# Read(2,*)(Told(i),i=1,26)
# Read(2,*)THLIND,TCLIND
# Read(2,*)Pp,Px
# Read(2,*)VOL(1),VOL(2),VOL(3),VOL(4),Ax5,PRZLVL
# Read(2,*)alphagPx(1),alphagPx(2),alphagPx(3),alphagPx(4)
# Read(2,*)rholPx(1),rholPx(2),rholPx(3),rholPx(4)
# Read(2,*)ulPx(1),ulPx(2),ulPx(3),ulPx(4)
# Read(2,*)rhogPx(1),rhogPx(2),rhogPx(3),rhogPx(4)
# Read(2,*)ugPx(1),ugPx(2),ugPx(3),ugPx(4)
# Read(2,*)rhoPx(1),rhoPx(2),rhoPx(3),rhoPx(4)
# Read(2,*)rhouPx(1),rhouPx(2),rhouPx(3),rhouPx(4)
# Read(2,*)VelPx(1),VelPx(2),VelPx(3),VelPx(4),VelPx(5)
# Read(2,*)VSRVPx(1),VSRVPx(2),VSRVPx(3),VSRVPx(4)
# Read(2,*)PRZMass(1),PRZMass(2),PRZMass(3),PRZMass(4)
# Read(2,*)PRZE(1),PRZE(2),PRZE(3),PRZE(4)
# Read(2,*)QHTRP,QHTRB,SCVPosition,Vspray
# Read(2,*)mdotCHRG,mdotLD
# do j=1,26
# do i=1,nodesSG(j)
# read(2,*)TSG(i,j),hSG(i,j)
# enddo
# enddo
# Read(2,*)CriticalLength1,CriticalLength2
# Read(2,*)SGMass1,SGMass2
# do i=1,4
# Read(2,*)BANKPOSITION(i)
# enddo
# Read(2,*)DeltaPFHSG1,DeltaPEHSG1,DeltaPHSG1
# Read(2,*)DeltaPFHSG2,DeltaPEHSG2,DeltaPHSG2
# Read(2,*)Qsteam,Wload,Wturb,PSGIND,Pimpulse,p_hdr
# do i=1,60
# read(2,*) velocity_kk(i),pressure_kk(i),ie_kk(i),
# %	kafa_kk(i),aj_kk(i),density_kk(i)
# enddo
# c
# Read(2,*) FlowSG,FlowFDInd,FlowDEMAND,FlowSteamInd,FeedSHIM
# Read(2,*) OmegaFP, FCV, FBV
# Read(2,*) TBVposition
# Read(2,*) Tfeed
# Read(2,*)TCVposition
# Read(2,*)TfuelAVE
# Read(2,*)TfuelHOT
# Read(2,*)uHOT
# Read(2,*)MDNBR
# c.
# Read(2,*)TESLoad,TESFlowDemand,TESSHIM,FlowAUX1,FlowAUX2,
# %         FlowAUX3,PTAP,rhoTAP,hTAP,PTES											   !Konor
# Read(2,*)IOPENTES(1),IOPENTES(2),IOPENTES(3),IOPENTES(4)
# Read(2,*)TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)
# Read(2,*)ICLOSETBV,LockTBV
