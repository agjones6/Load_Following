# This python file is made to generate the more specific input used in the code
import re
import os

def find_val(raw_text,kw):
    # This function is designed to pull the very next space deliminated value
    #   after the given text key word
    # regex = re.escape(kw) + r' +([A-Z]*\.?[A-Z]*[a-z]) '
    regex = re.escape(kw) + r'[ \t]+([^ \t\n]*)[ \n\t]'

    found_text = re.search(regex, raw_text)

    try:
        found_val = found_text.group(1)
    except:
        print("error getting " + kw)
        found_val = "ERROR"

    return found_val

def write_file(dest_file, raw_text):
# This function is made to write a file to be used as an input for the code

    # Redefining the function to only need the key word
    def fv(kw):
        return find_val(raw_text,kw)

    # Opening the file
    f = open(dest_file, "w")

    # Writing the files portions
    f.write(fv("GEOMETRY_FILE") + "\n")
    f.write(fv("REACTOR_DATA_FILE") + "\n")
    f.write(fv("COMPONENT_FILE") + "\n")
    f.write(fv("CONTROLLER_GAINS_FILE") + "\n")
    f.write(fv("SENSOR_DATA_FILE") + "\n")
    f.write(fv("VALVE_DATA_FILE") + "\n")
    f.write(fv("BOP_GEOMETRY_FILE") + "\n")
    f.write(fv("TRIP_SET_POINTS_FILE") + "\n")
    f.write(fv("INITIAL_CONDITIONS_FILE") + "\n")
    f.write(fv("TES_PARAMETER_FILES") + "\n")

    # Writing the number portions
    f.write(fv("INIT_MODE") + "\n")
    f.write(fv("IDEMAND") + "," +  fv("START_TIME") + "\n")
    f.write(fv("DEMAND_PARAMETER") + "\n")
    f.write(fv("UPSET_CONDITIONS") + "\n")
    f.write(fv("CONTROL_ROD_MODE") + "\n")
    f.write(fv("SIMULATION_TIME") + "," +  fv("WRITE_OUT_INTERVAL") + "," +  fv("WRITE_RESTART_INTERVAL") + "\n")

def replace_text(raw_text,kw, new_value):

    # Defining the regular expresssion to be used
    regex = r'(' + re.escape(kw) + r'[ \t]+)([^ \t\n]*)([ \n\t])'

    # Replacing the old value + (str(new_value))
    my_str_val = str(new_value)
    try:
        new_text = re.sub(regex,  r"\1 " + my_str_val + r"\3", raw_text, flags=re.IGNORECASE)
    except:
        print("WARNING WARNING: The substitution messed up")
        new_text = raw_text

    return new_text


my_filetxt = open("./Nice Input/Base_input.txt").read()

# tst_new = replace_text(my_filetxt, "INITIAL_CONDITIONS_FILE", "yOyO.DAT")


write_file("tst_file.txt", tst_new)
