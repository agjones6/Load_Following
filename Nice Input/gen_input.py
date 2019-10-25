# This python file is made to generate the more specific input used in the code
import re
import os
import shutil

def find_val(raw_text,kw):
    # This function is designed to pull the very next space deliminated value
    #   after the given text key word
    # regex = re.escape(kw) + r' +([A-Z]*\.?[A-Z]*[a-z]) '
    regex = re.escape(kw) + r'[ \t]+([^ \t\n]*)[ \n\t]'

    found_text = re.search(regex, raw_text,flags=re.IGNORECASE)

    try:
        found_val = found_text.group(1)
    except:
        print("error getting " + kw)
        found_val = "ERROR"

    return found_val

def find_auto(src_dir, kw, **kwargs):
    exclude = kwargs.get('exclude', "")

# This function is meant to find the file names associated with standards for the input
    for file_name in os.listdir(src_dir):
        if ( (kw.lower() in file_name.lower()) and
           (exclude.lower() not in file_name.lower() or exclude == "") ):
            desired_file = file_name
            break

    return os.path.join(src_dir,desired_file)

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
    auto_files = fv("AUTO_CHOOSE_FILES")
    if auto_files.lower() == "true":
        auto_files = True
    else:
        auto_files = False

    # --> Writing the files portions
    if auto_files and (src_folder != ""):
        f.write(find_auto(src_folder, "Geometry",exclude="BOP") + "\n")
        f.write(find_auto(src_folder, "Core") + "\n")
        f.write(find_auto(src_folder, "Component") + "\n")
        f.write(find_auto(src_folder, "Gains") + "\n")
        f.write(find_auto(src_folder, "Sensors") + "\n")
        f.write(find_auto(src_folder, "Valves") + "\n")
        f.write(find_auto(src_folder, "BOPGeometry") + "\n")
        f.write(find_auto(src_folder, "Trips") + "\n")
        f.write(find_auto(src_folder, "Init") + "\n")
        f.write(find_auto(src_folder, "TESMode") + "\n")
    else:
        f.write(os.path.join(src_folder, fv("GEOMETRY_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("REACTOR_DATA_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("COMPONENT_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("CONTROLLER_GAINS_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("SENSOR_DATA_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("VALVE_DATA_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("BOP_GEOMETRY_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("TRIP_SET_POINTS_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("INITIAL_CONDITIONS_FILE")) + "\n")
        f.write(os.path.join(src_folder, fv("TES_PARAMETER_FILES")) + "\n")

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
        except:
            print("WARNING WARNING: The substitution messed up")
            new_text = raw_text
    else:
        new_text = raw_text

    return new_text

def read_my_input(myFile_name):
    # myFile = open(myFile_name).read()

    base_file_txt = open("./Nice Input/short_input.txt").read()

    for line in open(myFile_name).readlines():
        # Each of the options are split up by semi colons
        all_options = line.split(";")

        case_name = "test"

        c = 0
        # Getting options and values to handle later
        options = []
        vals = []
        for o in all_options:

            # Making the options into an array to be used
            o = (o.split(","))
            o = [i.strip(" \n") for i in o]

            # Handling the First entry because it is the name of the run
            if c == 0:
                if o[0].lower() != "default":
                    case_name = o[0]
            else:
                options.append(o[0])
                vals.append(o[1:])

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


        c = 0
        for comb in all_comb:
            # Setting the text of the file to the base file
            curr_file_text = base_file_txt

            # Changing the file for every option in the combination
            for val_i in range(len(comb)):
                curr_file_text = replace_text(curr_file_text, options[val_i] ,comb[val_i])


            # Saving the file general run naming scheme
            new_file = open("./runFiles/r" + str(c) + ".txt","w")
            new_file.write(curr_file_text)
            new_file.close()

            c += 1



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
    regex = r'.*(\d+).*'
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


def running_code(runFile_name, inputFile_txt):

    # Taking my input file and making Dr. Doster's
    write_file(runFile_name, inputFile_txt)

    os.system("./Code/*.exe << " + runFile_name)
    exit()






# new_file = open("./runFiles/test2.txt","w")
# new_file.write(my_filetxt)

# This reads my base input file to make all of the combinations of options
myFile_name = "my_input.txt"
read_my_input(myFile_name)

# This moves files and runs the code
run_location = "./runFiles"
for file in os.listdir(run_location):
    path_to_source = os.path.join(run_location,file)

    # Reading in the input file
    input_deck = open(path_to_source).read()

    # Getting the file name from the input file and the output folder
    my_file_name = get_default_name(input_deck)

    # Making a folder and copying the input deck into a folder
    dest_dir = find_val(input_deck,"DESTINATION_FOLDER")
    copy_input_deck(dest_dir,path_to_source,my_file_name)

    # Running the code
    running_code(path_to_source, input_deck)

    # Moving the code output
    # curr_file = open(os.path.join(dest_dir,my_file_name),"w")

    # exit()





# write_file("./runFiles/tst_file.txt", my_filetxt)
