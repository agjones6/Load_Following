# This python file is made to generate the more specific input used in the code
import re
import os

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


my_filetxt = open("./Nice Input/short_input.txt").read()

my_filetxt = replace_text(my_filetxt, "SOURCE_FOLDER", "")


write_file("./runFiles/tst_file.txt", my_filetxt)
