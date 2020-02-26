# MASTER FILE FOR RUNNING SIMULATOR
# This contains all of the functions used for running the simulator and reading the output

from pandas import *
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import os
import re
import shutil
import subprocess
# import ./Analysis/read_demand as rd

#  =============================================================================
#                              OUTPUT ANALYSIS
#  =============================================================================

def get_df(filename):
    # Getting the file as an object
    my_file = open(filename,'r')

    # Pulling the first line of the file to seperate the headers
    first_line = my_file.readline()

    # Seperating the headers using regex
    regex_header = r'\s\s(\w.*?\(?\w\)?)\s\s'
    header_list = re.findall(regex_header,first_line)

    if not "TES_TBV(4)" in header_list:
        header_list.append("TES_TBV(4)")
    if not "Time" in header_list:
        header_list.insert(0,"Time")

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
    norm_source = kwargs.get('norm_source',"default")
    ylabel = kwargs.get("ylabel",ystring)

    # Pulling Nominal Operation values if they are desired
    if normalized:
        nom_NuScale, nom_MPower = pull_FP_data(source=norm_source, num_points=20)

    # Plotting the desired data
    dum_fig = plt.figure()
    i = 0
    for df in df_list:
        xvals = df[xstring]

        if normalized:
            # Normalizing based on reactor
            if case_names != "" and len(case_names) == len(df_list):
                try:
                    first_letter = case_names[i][0]
                    if first_letter.upper() == "N":
                        yvals = df[ystring]/nom_NuScale[ystring]
                    elif first_letter.upper() == "M":
                        yvals = df[ystring]/nom_MPower[ystring]

                except Exception as e:
                    print(e)
                    yvals = df[ystring]
                    pass
        else:
            yvals = df[ystring]

        if i != 0:
            plt.plot(xvals,yvals,"-.",linewidth=2)
        else:
            plt.plot(xvals,yvals,linewidth=3)

        plt.xlabel(xstring + " (s)")
        plt.ylabel(ylabel)

        i += 1

    if case_names != "" and len(case_names) == len(df_list):
        plt.legend(case_names)

    # --> Future functionality for saving output directly
    # if file_name != "":
    #     plt.savefig(os.path.join(case_dest,
    #                 str(burnup[case_count][i]) + "_" + file_name))

    # Closing the figure if it is not desired to keep it
    if not keep_fig:
        plt.close(dum_fig)

def check_steady_state(data_filename, **kwargs):
# This function is made to check if the current run has reached steady state

    # Defining a list of values to check
    check_vals = ["Qrx", "Qth", "Qtrans", "Flowv", "Pp", "Px", "PRZLVL", "THL",
                  "TCL", "TaveREF", "Tave", "Wload", "Wturb", "Trx"]

    # Number of points to check going back from the end
        # NOTE: if the code is writing an output for every second, this is 10 seconds
    num_points = kwargs.get("num_points",10)
    slope_tolerance = kwargs.get("slope_tolerance",1e-5)

    # Importing the data as a dataframe
    df = get_df(data_filename)

    # For every value to check, the slope of the data is calculated
    t = np.array(df["Time"])
    logic_list = []
    for val in check_vals:

        voi = np.array(df[val])
        voi = voi / np.amax(voi)

        # Getting a matrix of the discrete slopes between all points
        dvdt_mat = (voi[1:] - voi[:-1]) / (t[1:] - t[:-1])

        # Averaging the last section of slopes to get an average for a desired range
        avg_slope = np.mean(dvdt_mat[-num_points:])

        # Checking if the slope is less than the tolerance
        logic_list.append(abs(avg_slope) < slope_tolerance)

        # print(val)
        # if logic_list[-1]:
        #     print("Rx is at Steady State with ")
        #     print("slope: ", avg_slope)
        #     print("time: ", t[-1])
        # else:
        #     print("Rx is not Steady State: ", avg_slope)

    # Getting the values that are not steady state WILL BE USED LATER
    changing_vals = []
    for i in range(len(check_vals)):
        if not logic_list[i]:
            changing_vals.append(check_vals[i])
    # inv_logic_list = [not i for i in logic_list]

    # print(changing_vals)
    # Returning wether all of the values were steady state or not
    return np.all(logic_list)

def combine_output_files(src_folder):
# This function is purposed to combine files that are being run until steady state
#   The spead out outputs should be something like N0, N0_a, N0_b --> N0

    # Checking to ensure the input is a directory
    if not os.path.isdir(src_folder):
        return

    # Getting a list of the files
    dir_list = os.listdir(src_folder)

    name_list = []
    path_list = []
    for obj in dir_list:
        if os.path.isfile(os.path.join(src_folder,obj)):
            name_list.append(obj.split(".")[0].split("_"))
            path_list.append(os.path.join(src_folder,obj))


    # for i in range(len(name_list)):
    i = 0
    while i < len(name_list):
        file1 = name_list[i]
        dlt_names = []
        dlt_files = []
        if len(file1) == 1:
            main_df = get_df(path_list[i])
            new_df = main_df
            # for i2 in range(len(name_list)):
            i2 = 0
            while i2 < len(name_list):
                file2 = name_list[i2]
                if len(file2) > 1:
                    if file2[0] == file1[0]:
                        sub_df = get_df(path_list[i2])
                        new_df = pd.concat([new_df, sub_df])

                        # Getting list of files to delete
                        dlt_names.append(name_list[i2])
                        dlt_files.append(path_list[i2])
                i2 += 1

        # Saving the new data
        try:
            # Erasing Duplicate Values
            new_df = new_df.drop_duplicates()

            # Dropping the file_name column
            if "file_name" in new_df.columns:
                new_df = new_df.drop(columns=["file_name"])

            # Saving the new dataframe as a csv
            new_df.to_csv(path_list[i], index=False)

            # Replacing the text in the csv with spaces like Doster's .dat files
            new_text = open(path_list[i]).read().replace(",","    ")

            open(path_list[i],"w").write(new_text)
            for del_i in range(len(dlt_files)):
                # print(d_file)
                # Removing the values from the lists
                name_list.remove(dlt_names[del_i])
                path_list.remove(dlt_files[del_i])

                # Deleting the files
                os.remove(dlt_files[del_i])

        except Exception as e:
            print(e)
            # This keeps the original files without erasing the original files
            # Dropping the file_name column
            if "file_name" in new_df.columns:
                main_df = main_df.drop(columns=["file_name"])

            # Saving the new dataframe as a csv
            main_df.to_csv(path_list[i], index=False)

            # Replacing the text in the csv with spaces like Doster's .dat files
            new_text = open(path_list[i]).read().replace(",","    ")

            open(path_list[i],"w").write(new_text)

        i += 1

def get_folder_rawData(src_dir):
# This pulls all of the .dat file data and names from a given directory

    rawData = []
    runNames = []
    dir_list = os.listdir(src_dir)
    dir_list.sort()
    for file in dir_list:
        # Getting the file extenion
        ext = file.split(".")[-1]

        # If the file is a .dat file, pull the data
        if ext == "dat":
            rawData.append(get_df(os.path.join(src_dir,file)))
            runNames.append(file.split(".")[0])

    return rawData, runNames

def pull_FP_data(**kwargs):
# This function pulls the data from a nominal location to use in normalizing the
#   output data.

    # Loacation of the source file is this by default
    source_dir = kwargs.get("source","default")
    num_points = kwargs.get("num_points",10)
    save_new = kwargs.get('norm_source',False)

    if source_dir == "default":
        # This is pulling from smaller files to
        NuScale_data = pd.read_csv("./NuScale/nom_cond.csv",header=None,squeeze=True,index_col=0)
        MPower_data = pd.read_csv("./MPower/nom_cond.csv",header=None,squeeze=True,index_col=0)
    else:
        # Pulling the data
        rawData_list, runName_list = get_folder_rawData(source_dir)

        NuScale_data = 0
        MPower_data = 0
        for i in range(len(rawData_list)):
            if "N" in runName_list[i]:
                NuScale_data = rawData_list[i].iloc[-num_points:-1,:]
                NuScale_data = NuScale_data.mean()
            elif "M" in runName_list[i]:
                MPower_data = rawData_list[i].iloc[-num_points:-1,:]
                MPower_data = MPower_data.mean()

    if save_new:
        NuScale_data.to_csv("./NuScale/nom_cond.csv",header=False)
        MPower_data.to_csv("./MPower/nom_cond.csv",header=False)

    return NuScale_data, MPower_data




#  =============================================================================
#                     GENERATING INPUT AND RUNNING SIMULATOR
#  =============================================================================
def get_line_value(file,num):

    file = file.strip('"')
    if not os.path.isfile(file):
        print("The file doesn't exist")
        return

    # Opening the file
    f=open(file)

    # Reading in the lines
    lines=f.readlines()
    f.close()
    return lines[num]
def find_val(raw_text,kw,**kwargs):
    # This function is designed to pull the very next space deliminated value
    #   after the given text key word
    # regex = re.escape(kw) + r' +([A-Z]*\.?[A-Z]*[a-z]) '
    replace_val = kwargs.get("replace_val",None)
    regex = re.escape(kw) + r'[ \t]+([^ \t\n]*)[ \n\t]'

    found_text = re.search(regex, raw_text,flags=re.IGNORECASE)

    try:
        found_val = found_text.group(1)
    except:
        # print("error getting " + kw)
        found_val = ""

    return found_val

def find_auto(src_dir, kw, **kwargs):
    exclude = kwargs.get('exclude', "")
# This function is meant to find the file names associated with standards for the input
    for file_name in os.listdir(src_dir):
        if ( (kw.lower() in file_name.lower()) and
           (exclude.lower() not in file_name.lower() or exclude == "") ):
            desired_file = file_name
            break

    return os.path.join(src_dir,desired_file).replace("\\","/")

def write_file(dest_file, raw_text, **kwargs):# This function is made to write a file to be used as an input for the code

    abs_path = kwargs.get('abs_path', False)

    # Redefining the function to only need the key word
    def fv(kw):
        return find_val(raw_text,kw)

    # Opening the file
    f = open(dest_file, "w")

    # Getting the source Folder for the input files
    src_folder = fv("SOURCE_FOLDER")

    # Checking to ensure the input is a directory
    if os.path.isdir(src_folder):
        if abs_path:
            src_folder = os.path.abspath(src_folder)
        else:
            src_folder = src_folder
    else:
        src_folder = ""

    # Getting the Variable to auto-populate the files
    auto_files = fv("CHANGE_FILES")
    if auto_files.lower() == "true":
        auto_files = True
    else:
        auto_files = False

    # --> Writing the files portions
    input_file_list = ["Geometry", "Core", "Component",
                       "Gains", "Sensors", "Valves",
                       "BOPGeometry", "Trips", "Init",
                       "TESMode"]
    deck_file_list = ["GEOMETRY_FILE", "REACTOR_DATA_FILE", "COMPONENT_FILE",
                      "CONTROLLER_GAINS_FILE", "SENSOR_DATA_FILE", "VALVE_DATA_FILE",
                      "BOP_GEOMETRY_FILE", "TRIP_SET_POINTS_FILE", "INITIAL_CONDITIONS_FILE",
                      "TES_PARAMETER_FILES"]
    for i in range(len(input_file_list)):
        c_val = fv(deck_file_list[i])
        if c_val == "" or c_val == "default":
            if "Geometry" == input_file_list[i]:
                f.write('"' + find_auto(src_folder, input_file_list[i], exclude="BOP") + '"' + "\n")
            else:
                f.write('"' + find_auto(src_folder, input_file_list[i]) + '"' + "\n")
        else:
            # f.write('"' + os.path.join(src_folder, c_val).replace("\\","/") + '"' + "\n")
            f.write('"' + c_val + '"' + "\n")
    # if auto_files and (src_folder != ""):
    #     f.write('"' + find_auto(src_folder, "Geometry",exclude="BOP") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Core") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Component") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Gains") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Sensors") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Valves") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "BOPGeometry") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Trips") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "Init") + '"' + "\n")
    #     f.write('"' + find_auto(src_folder, "TESMode") + '"' + "\n")
    # else:
    #     f.write('"' + os.path.join(src_folder, fv("GEOMETRY_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("REACTOR_DATA_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("COMPONENT_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("CONTROLLER_GAINS_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("SENSOR_DATA_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("VALVE_DATA_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("BOP_GEOMETRY_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("TRIP_SET_POINTS_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("INITIAL_CONDITIONS_FILE")).replace("\\","/") + '"' + "\n")
    #     f.write('"' + os.path.join(src_folder, fv("TES_PARAMETER_FILES")).replace("\\","/") + '"' + "\n")

    # Writing the number portions
    f.write(fv("INIT_MODE") + "\n")
    f.write(fv("IDEMAND") + "," +  fv("START_TIME") + "\n")
    f.write(fv("DEMAND_PARAMETER") + "\n")
    f.write(fv("UPSET_CONDITIONS") + "\n")
    f.write(fv("CONTROL_ROD_MODE") + "\n")
    f.write(fv("SIMULATION_TIME") + "," +  fv("WRITE_OUT_INTERVAL") + "," +  fv("WRITE_RESTART_INTERVAL") + "\n")

def replace_text(raw_text,kw, new_value):

    # Only replacing stuff if the new value is different
    if new_value != "":
        # Defining the regular expresssion to be used
        regex = r'(' + re.escape(kw) + r'[ \t]+)([^ \t\n]*)([ \n\t])'

        # Replacing the old value
        my_str_val = str(new_value)
        try:
            new_text = re.sub(regex,  r"\1 " + my_str_val + r"\3", raw_text, flags=re.IGNORECASE)
        except Exception as e:
            print(e)
            print(my_str_val)
            print("WARNING WARNING: The substitution messed up")
            new_text = raw_text
    else:
        new_text = raw_text

    return new_text

def read_my_input(myFile_name):
    # myFile = open(myFile_name).read()

    base_file_txt = open("./nice_input/short_input.txt").read()

    c_outer = 0

    # Getting each of the designated sections of roptions into a list to be used
    c = 0
    section_list = []
    for line in open(myFile_name).read().split("\n"):
        # Taking off leading and trailing spaces
        line = line.strip(" ")

        # Handinling of the line is blank
        if len(line) == 0:
            continue

        # If this is the first time the string has been encountered
        if c == 0:
            c_text = ""
            c += 1

        # Adding the current text to the string of text
        c_text = c_text + line
        if not line[-1] == ";":
            section_list.append(c_text)
            c = 0

    # Handling the options that act to duplicate the run but not mix up the option

    for line in section_list:
        # Each of the options are split up by semi colons
        all_options = line.split(";")

        c = 0
        # Getting options and values to handle later
        options = []
        vals = []
        for o in all_options:

            # Making the options into an array to be used
            o = (o.split(","))
            o = [i.replace("\n","") for i in o]
            o = [i.strip(" ") for i in o]

            # The Option names are put in options and the values for the options are in vals
            options.append(o[0])
            vals.append(o[1:])

            # --> Handling special default cases
            # Case for pulling demand curves
            if options[-1].upper() == "DEMAND_PARAMETER":
                try:
                    potential_path = vals[-1][0]
                    potential_path = potential_path.replace('"','')
                    if os.path.isdir(potential_path):
                        demand_filenames = os.listdir(potential_path)

                        new_file_opt = ['"' + potential_path + "/" + f + '"' for f in demand_filenames]
                        if len(new_file_opt) == 0:
                            print("No Demand File in directory: " + potential_path)
                            break

                        # Setting the grabbed filenames to the value to be used in generating runfiles
                        vals[-1] = new_file_opt

                except Exception as e:
                    print(e)
                    pass

            c += 1

        # Getting the number of combinations for making files
        num_comb = 1
        num_el = []
        for i in vals:
            num_comb = num_comb*len(i)
            num_el.append(len(i))

        # Getting all of the possible combinations for input files
        counts = [0]*len(options)
        all_comb = []
        for i in range(num_comb):
            all_comb.append([])
            for i2 in range(len(vals)):
                all_comb[i].append(vals[i2][counts[i2]])
                if i2 == len(vals) - 1:
                    counts[i2] += 1
                    if counts[i2] >= num_el[i2]:
                        counts[i2] = 0
                        for c in range(len(counts[0:i2]), 0,-1):
                            counts[c-1] += 1
                            if counts[c-1] < num_el[c-1]:
                                break
                            else:
                                counts[c-1] = 0
            # print(all_comb[i])

        new_combo_list = []
        for comb in all_comb:
            new_v_list = []
            v_index = []
            r = 0
            for v in comb:
                # Checking that there is a
                if "|" in v:
                    new_v_list.append(v.split("|"))
                    v_index.append(r)
                r += 1

            if len(new_v_list) != 0:
                num_additions = len(new_v_list[0])
                try:
                    for a in range(num_additions):
                        new_comb = []
                        for v in range(len(comb)):
                            if v in v_index:
                                new_comb.append(new_v_list[v_index.index(v)][a])
                            else:
                                new_comb.append(comb[v])
                        new_combo_list.append(new_comb)
                except Exception as e:
                    print(e)
                    new_combo_list = []

        if len(new_combo_list) != 0:
            all_comb = new_combo_list

        # c = 0
        for comb in all_comb:
            # Setting the text of the file to the base file
            curr_file_text = base_file_txt

            # Changing the file for every option in the combination
            for val_i in range(len(comb)):
                curr_file_text = replace_text(curr_file_text, options[val_i] ,comb[val_i])


            # Saving the file general run naming scheme
            new_file = open("./runFiles/r" + str(c_outer) + ".txt","w")
            new_file.write(curr_file_text)
            new_file.close()

            c_outer += 1



        # print(options)
        # print(vals)
def get_default_name(file_text):
# Basically counting what is already in the destination folder and what is being generated
#   so each of the files generated will have a different arbitrary name

    # Determining the first letter of the output file name
    dest_dir = find_val(file_text,"DESTINATION_FOLDER")
    source_folder = find_val(file_text,"SOURCE_FOLDER")

    source_name = source_folder.split("/")[-1].split(".")[0]
    if source_name[0].lower() == "n":
        # NuScale
        first_letter = "N"
    elif source_name[0].lower() == "m":
        # MPower
        first_letter = "M"
    else:
        # General Run
        first_letter = "r"

    # Checking if the directory exists, if not it is created
    if not os.path.isdir(dest_dir):
        os.mkdir(dest_dir)

    # Going through the directory to check names and name the file
    all_files = [i for i in os.listdir(dest_dir) if os.path.isfile(os.path.join(dest_dir,i))]

    # Filtering out the files that arent from the same source
    spec_files = [i for i in all_files if i[0].lower() == first_letter.lower()]

    # Getting just the numbers from the strings
    regex = r'.(\d+).*'
    try:
        spec_numbers = [int(re.search(regex,i).group(1)) for i in spec_files]
    except Exception as e:
        spec_numbers = []
        print("Error Getting Files --> " + e)
    spec_numbers.sort()

    # Getting the new file name
    try:
        max_num = np.amax(spec_numbers)
        final_name = first_letter + str(max_num + 1)
    except:
        final_name = first_letter + str(0)

    # c = 0
    # while c <= len(spec_files):
    #     try:
    #         if int(spec_numbers[c]) != c:
    #             final_name = first_letter + str(c)
    #             break
    #     except:
    #         final_name = first_letter + str(c)
    #         break
    #         # pass
    #
    #     c += 1

    # print(final_name)
    return final_name

def get_default_letter(run_name):
# This function is made to get the letter of the alphabet needed to make the
#   current filename's name different
#   EX) N0 -> N0_a -> N0_b
    # First splitting based on underscore
    fl = "a"
    try:
        name_list = run_name.split("_")
        run_name = name_list[0]
        cletter = name_list[-1]
        cnum = ord(cletter[-1])
        if len(name_list) <= 1:
            nletter = fl
        elif cnum < ord(fl) + 25:
            if len(cletter) == 1:
                nletter = chr(cnum+1)
            else:
                nletter = cletter[:-1] + chr(cnum+1)
            # print(chr(cnum))
        else:
            nletter = cletter + fl

    except:
        nletter = "a"

    new_run_name = run_name + "_" + nletter
    return new_run_name

def copy_input_deck(dest_dir,filename,special_name):
    # This copies the current file into a input_deck directory

    deck_fold_name = "input_decks"
    special_name = special_name + "_deck.txt"

    # Checking to make sure the directory is there
    if not os.path.isdir(dest_dir):
        os.mkdir(dest_dir)

    # Making the sub-directory
    if not os.path.isdir(os.path.join(dest_dir,deck_fold_name)):
        os.mkdir(os.path.join(dest_dir,deck_fold_name))

    # Copying the desired file
    shutil.copy(filename,os.path.join(dest_dir,deck_fold_name,special_name))

def copy_fin_files(dest_dir, source_file, new_file_name):
    # This copies the results from the code into a desired location
    if not os.path.isdir(dest_dir):
        os.mkdir(dest_dir)

    # Adding the .dat file extention to the name of the file
    new_file_name = new_file_name + ".dat"

    # Copying the file
    shutil.copy(source_file,os.path.join(dest_dir,new_file_name))

def change_restart_time(restart_file,restart_time):
# This function changes the first line of the restart file to the restart time given
    f_orig = open(restart_file).readlines()

    f_new = open(restart_file,"w")

    c = 0
    for line in f_orig:
        if c == 0:
            f_new.write(restart_time + " \n")
        else:
            f_new.write(line)

        c += 1

    f_new.close()


def running_code(runFile_name, inputFile_txt):

    # Taking my input file and making Dr. Doster's
    #   NOTEL This overwrites the file in the run-file location
    runFile_name = runFile_name.replace("\\","/")

    write_file(runFile_name, inputFile_txt)

    cmd = 'echo ' + "'" + runFile_name.replace("/","\\") + "'" +  ' | .\\Code\\base_exec2.exe'
    subprocess.call(cmd,shell=True)


#  =============================================================================
