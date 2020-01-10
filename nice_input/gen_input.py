# This python file is made to generate the more specific input used in the code
import re
import os
import shutil
import subprocess
# import view_data as vd


def find_val(raw_text,kw):
    # This function is designed to pull the very next space deliminated value
    #   after the given text key word
    # regex = re.escape(kw) + r' +([A-Z]*\.?[A-Z]*[a-z]) '
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

def write_file(dest_file, raw_text, **kwargs):
# This function is made to write a file to be used as an input for the code

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
    c = 0
    while c <= len(spec_files):
        try:
            if int(spec_numbers[c]) != c:
                final_name = first_letter + str(c)
                break
        except:
            final_name = first_letter + str(c)
            break
            # pass

        c += 1

    # print(final_name)
    return final_name

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

def check_steady_state(data_file):
# This function is made to check if the current run has reached steady state

    # Defining a list of values to check
    check_vals = ["Qrx"]

    # For every value to check, the slope of the data is calculated
    # for val in check_vals:


# =============================================================================

# This reads my base input file to make all of the combinations of options
myFile_name = "my_input0.txt"
read_my_input(myFile_name) # Actually makes the files

# %% This moves files and runs the code from the runfiles in the run folders
run_location = "./runFiles"
for file in os.listdir(run_location):
    path_to_source = os.path.join(run_location,file) #.replace("\\","/")

    # Reading in the input file
    input_deck = open(path_to_source).read()
    # input_deck = input_deck.replace("/","\\")
    # print(input_deck)
    # exit()

    # Getting the file name from the input file and the output folder
    my_file_name = find_val(input_deck,"RUN_NAME")
    if my_file_name.lower() == "default":
        my_file_name = get_default_name(input_deck)

    # Making a folder and copying the input deck into a folder
    dest_dir = find_val(input_deck,"DESTINATION_FOLDER")
    copy_input_deck(dest_dir,path_to_source,my_file_name)

    # Running the code
    running_code(path_to_source, input_deck)

    # --> Performing options enacted by the outer shell
    # This is the time that will be at the top of the restart file
    restart_time = find_val(input_deck,"RESTART_TIME")
    if restart_time != "" and restart_time.strip(" ") != "default":
        change_restart_time("Restart.dat", restart_time)

    # Copying the files
    copy_fin_files(dest_dir,"System.dat",my_file_name)
    copy_fin_files(os.path.join(dest_dir,"Summary"),"Summary.dat",my_file_name)
    copy_fin_files(os.path.join(dest_dir,"Restart"),"Restart.dat",my_file_name)

    # Removing the run files from the 'runFile' directory
    os.remove(os.path.join(run_location,file))

    # Moving the code output
    # curr_file = open(os.path.join(dest_dir,my_file_name),"w")

    # exit()





# write_file("./runFiles/tst_file.txt", my_filetxt)
