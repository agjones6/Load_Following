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
# analysis_path = "/Users/AndyJones/Documents/GitHub/master_proj/Analysis"
analysis_path = "C:/Users/agjones6/Documents/GitHub/master_proj/Analysis"
if not analysis_path in sys.path:
    sys.path.append(analysis_path)

# TESTING for checking the steady state condition of the reactor
# fileName = "./Results/myCase8/N4.dat"
# ss = check_steady_state(fileName)


# %%
# This reads my base input file to make all of the combinations of options
myFile_name = "full_day_input.txt"
read_my_input(myFile_name) # Actually makes the files

# %% This moves files and runs the code from the runfiles in the run folders
run_location = "./runFiles"
ss_restart_deck = []
run_dir_list = os.listdir(run_location)
c = 0
r_count = 0 # Tracker to count how many times it restarts
max_r_count = 20

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

    # TESTING for combining files
    # combine_output_files(dest_dir)
    # exit()

    copy_input_deck(dest_dir,path_to_source,my_file_name)

    # Running the code
    print("running -> ", my_file_name)
    running_code(path_to_source, input_deck)

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

    # exit()
#
combine_output_files(dest_dir)
# exit()



# write_file("./runFiles/tst_file.txt", my_filetxt)
