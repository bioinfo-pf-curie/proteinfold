#! /usr/bin/env python

""" Check the format of the json required by AlphaFold3 """
import json
import re
from absl import app, flags

FLAGS = flags.FLAGS

flags.DEFINE_string('json', None, 'Path to the JSON file')

flags.mark_flag_as_required('json')


"""
This functions checks:
    - the file exists
    - it has the extension .json
    - the json is correctly formatted
    - the file name contains only allowd characters
"""
def is_valid_file(file_path):
    
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            file_basename=file.name.split('/')[-1]
    except json.JSONDecodeError:
        print("ERROR: JSON file is not correctly formatted.")
        exit(1)
    except FileNotFoundError:
        print("ERROR: File not found.")
        exit(1)


    # Check if the file has a .json extension
    if file_basename.endswith('.json'):
        print("OK: The file has a .json extension.")
    else:
        print("ERROR: The file does not have a .json extension.")
        exit(1)

    # Define the allowed characters
    allowed_chars = re.compile(r'^[a-zA-Z0-9_.-]+$')
    
    # Find all invalid characters
    invalid_chars = re.findall(r'[^a-zA-Z0-9_.-]', file_basename)
    
    if invalid_chars:
        print(f"ERROR: Invalid characters found: \"{', '.join(invalid_chars)}\"")
        exit(1)
    else:
        return [data, file_basename]

"""
This functions checks:
    - the field name value corresponds to the filename without the extension
    - it sets the name value properly or add it if missing
"""
def check_and_update_json(data, file_basename):
   
    new_name = file_basename.rsplit('.',1)[0]
    if 'name' not in data:
        print("ERROR: 'name' field is missing in the JSON file.")
        exit(1)
    else:
        if data['name'] != new_name:
            print(f"ERROR: The content of the 'name' field in the JSON file must be set to '{new_name}' which is the name of the JSON file without its extension.")
            exit(1)
    

def main(argv):
    del argv  # Unused.
    [data, file_basename] = is_valid_file(FLAGS.json)
    check_and_update_json(data, file_basename)

if __name__ == "__main__":
    app.run(main)

