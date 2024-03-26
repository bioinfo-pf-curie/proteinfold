#! /usr/bin/ev python

from absl import flags
from absl import app
import json
import numpy as np
import os
import pickle
import sys

FLAGS = flags.FLAGS

flags.DEFINE_string('pickle_file', None, 
                    'Path to the pickle file created by AlphaFold.')
flags.DEFINE_string('output_file', None, 
                    'Path to json file to write the PAE.')

# Function from:
#   - https://github.com/google-deepmind/alphafold/blob/main/alphafold/common/confidence.py
def pae_json(pae: np.ndarray, max_pae: float) -> str:
  """Returns the PAE in the same format as is used in the AFDB.

  Note that the values are presented as floats to 1 decimal place, whereas AFDB
  returns integer values.

  Args:
    pae: The n_res x n_res PAE array.
    max_pae: The maximum possible PAE value.

  Returns:
    PAE output format as a JSON string.
  """
  # Check the PAE array is the correct shape.
  if pae.ndim != 2 or pae.shape[0] != pae.shape[1]:
    raise ValueError(f'PAE must be a square matrix, got {pae.shape}')

  # Round the predicted aligned errors to 1 decimal place.
  rounded_errors = np.round(pae.astype(np.float64), decimals=1)
  formatted_output = [{
      'predicted_aligned_error': rounded_errors.tolist(),
      'max_predicted_aligned_error': max_pae,
  }]
  return json.dumps(formatted_output, indent=None, separators=(',', ':'))


def main(argv):

  if not os.path.exists(f'{FLAGS.pickle_file}'):
    print(f'ERROR: in option --pickle_file, the file \'{FLAGS.pickle_file}\' does not exist.')
    sys.exit(1)

  if not os.path.exists(os.path.dirname(os.path.realpath(f'{FLAGS.output_file}'))):
    print("ERROR: in option --output_file, the directory '" + os.path.dirname(os.path.realpath(f'{FLAGS.output_file}')) + "\' does not exist.")
    sys.exit(1)

  _, extension = os.path.splitext(f'{FLAGS.output_file}')
  print(extension)
  if extension != '.json':
    print(f'ERROR: in option --output_file, the extension of the file {FLAGS.output_file} must be \'json\'.')
    sys.exit(1)
  print(f'{FLAGS.pickle_file}')
  with open(f'{FLAGS.pickle_file}', 'rb') as pkl_file:
     data = pickle.load(pkl_file)
  
  pae = data['predicted_aligned_error']
  max_pae = data['max_predicted_aligned_error']
  pae_data = pae_json(pae=pae, max_pae=max_pae.item())
  
  with open(f'{FLAGS.output_file}', 'w') as json_file:
    json_file.write(pae_data)


if __name__ == "__main__":
  """ 
  Create a json file with the PAE
  """
  app.run(main)
