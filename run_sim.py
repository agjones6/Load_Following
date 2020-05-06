# Python File to Running the simulator

from sim_functions import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re
import shutil
import subprocess
import sys
import time
# analysis_path = "/Users/AndyJones/Documents/GitHub/master_proj/Analysis"
analysis_path = "C:/Users/agjones6/Documents/GitHub/master_proj/Analysis"
if not analysis_path in sys.path:
    sys.path.append(analysis_path)

# TESTING for checking the steady state condition of the reactor
# fileName = "./Results/myCase8/N4.dat"
# ss = check_steady_state(fileName)


# %%
# This reads my base input file to make all of the combinations of options
myFile_name = "FD_input2.txt"
read_my_input(myFile_name) # Actually makes the files from './nice_input/short_input.txt'

# %% This moves files and runs the code from the runfiles in the run folders
run_location = "./runFiles"
ss_restart_deck = []
run_dir_list = os.listdir(run_location)

# Fixing the dumb sorting issue
new_run_dir_list = [r.strip("r").strip(".txt") for r in run_dir_list]
new_run_dir_list.sort(key=int)
run_dir_list = ["r" + r + ".txt" for r in new_run_dir_list]

c = 0
r_count = 0 # Tracker to count how many times it restarts
max_r_count = 20

# Setting a start time
time_start = time.time()
while (c < len(run_dir_list) or len(ss_restart_deck) > 0) and c < 1e6:

    # --> Reading in the input file
    # if there is a restart deck needed, use the deck in the ss_restart_deck variable
    if len(ss_restart_deck) > 0:
        input_deck = ss_restart_deck
        ss_restart_deck = []
        f = open(path_to_source,"w")
        f.write(input_deck)
        f.close()
        r_count += 1
    else:
        file = run_dir_list[c]
        path_to_source = os.path.join(run_location,file) #.replace("\\","/")
        input_deck = open(path_to_source).read()
        c += 1
    # input_deck = input_deck.replace("/","\\")
    # print(input_deck)
    # exit()

    # Getting the file name from the input file and the output folder
    my_file_name = find_val(input_deck,"RUN_NAME")
    if my_file_name.lower() == "default":
        my_file_name = get_default_name(input_deck)

    # Making a folder and copying the input deck into a folder
    dest_dir = find_val(input_deck,"DESTINATION_FOLDER")

    # Changing the step change of the power level.
    #   Note: if IDEMAND is 0 (step change), it just uses the first line.
    #         if IDEMAND is 2 (load follow), a new load file is made and placed
    #           in a folder in the output
    power_level = find_val(input_deck, "DEMAND_PARAMETER")
    if power_level.split("-")[0] == "first_line":
        power_level_options = power_level.split("-")
        if len(power_level_options) >= 2:
            new_demand = get_line_value(power_level_options[1], 1)
            new_demand = new_demand.strip("\n").split(",")[1].strip(" ")

            if find_val(input_deck,"IDEMAND") == "0":
                input_deck = replace_text(input_deck, "DEMAND_PARAMETER", new_demand)
            elif find_val(input_deck,"IDEMAND") == "2":
                if not os.path.isdir(dest_dir):
                    os.mkdir(dest_dir)
                temp_load_folder = dest_dir + "/load_profiles"#os.path.join(dest_dir,"load_profiles")
                if not os.path.isdir(temp_load_folder):
                    os.mkdir(temp_load_folder)
                temp_ld_file_name = temp_load_folder + "/" +my_file_name+".txt"#os.path.join(temp_load_folder,my_file_name+".txt")
                temp_ld_file_obj = open(temp_ld_file_name,"w")
                temp_ld_file_obj.write("3\n")
                temp_ld_file_obj.write(find_val(input_deck,"START_TIME") + ",100 \n")
                temp_ld_file_obj.write("0.1," + str(new_demand) + "\n")
                temp_ld_file_obj.write(str(float(find_val(input_deck,"SIMULATION_TIME"))/3600) +"," + str(new_demand) + "\n")
                temp_ld_file_obj.close()
                input_deck = replace_text(input_deck, "DEMAND_PARAMETER", '"' + temp_ld_file_name + '"')

    copy_input_deck(dest_dir,path_to_source,my_file_name)

    # Running the code
    t0 = time.time()
    print("running -> ", my_file_name)
    running_code(path_to_source, input_deck)
    print("\t elapsed time ---> ", time.time() - t0)

    # --> Performing options enacted by the outer shell
    # This checks the output to see if it is steady state
    ss_option_name = find_val(input_deck,"RUN_TO_STEADY_STATE")
    if ss_option_name.lower() == "true":
        ss_condition = check_steady_state("System.dat", slope_tolerance=1e-5
        )
        if not ss_condition and r_count < max_r_count:
            ss_restart_deck = input_deck
            ss_restart_deck = replace_text(ss_restart_deck, "INITIAL_CONDITIONS_FILE", "./Restart.dat")
            ss_restart_deck = replace_text(ss_restart_deck, "RUN_NAME", get_default_letter(my_file_name))
            # print(test)
        else:
            combine_output_files(dest_dir)


    # This is the time that will be at the top of the restart file
    restart_time = find_val(input_deck,"RESTART_TIME")
    # restart_file = find_val(input_deck,"INITIAL_CONDITIONS_FILE")
    if restart_time != "" and restart_time.strip(" ") != "default":
        change_restart_time("Restart.dat", restart_time)


    # Copying the files
    copy_fin_files(dest_dir,"System.dat",my_file_name)
    copy_fin_files(os.path.join(dest_dir,"Summary"),"Summary.dat",my_file_name)
    copy_fin_files(os.path.join(dest_dir,"Restart"),"Restart.dat",my_file_name)

    # Removing the run files from the 'runFile' directory
    if len(ss_restart_deck) == 0:
        r_count = 0
        os.remove(os.path.join(run_location,file))

    # Moving the code output
    # curr_file = open(os.path.join(dest_dir,my_file_name),"w")


print("total time = ", time.time() - time_start)


# write_file("./runFiles/tst_file.txt", my_filetxt)
