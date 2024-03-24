#!/usr/bin/env python

import os
import sys
import csv
import json
from absl import flags
from absl import app

FLAGS = flags.FLAGS

flags.DEFINE_string('input_file', None, 
                    'Path to the json file created by alphafill.')
flags.DEFINE_string('output_file', None, 
                    'Path to csv file with the score values for each transplant.')
#flags.DEFINE_list('runs_to_compare', [], 'Runs that you want to compare on a same distribution plot')

def extract_hits():

  if not os.path.exists(f'{FLAGS.input_file}'):
    print(f'{FLAGS.input_file} does not exist.')
    sys.exit(1)

  if os.path.exists(f'{FLAGS.output_file}'):
    print(f'{FLAGS.output_file} exists. Choose another file.')
    sys.exit(1)

  with open(f'{FLAGS.input_file}', 'r') as json_file:
    scores = json.load(json_file)

  transplants = []
  for hit in range(len(scores['hits'])):
    transplant = {}
    pdb_id = scores['hits'][hit]['pdb_id']
    pdb_asym_id = scores['hits'][hit]['pdb_asym_id']
    global_rmsd = scores['hits'][hit]['global_rmsd']
    analogue_id = scores['hits'][hit]['transplants'][0]['analogue_id']
    asym_id = scores['hits'][hit]['transplants'][0]['asym_id']
    local_rmsd = scores['hits'][hit]['transplants'][0]['local_rmsd']
    transplant['Hit'] =  'hit' + f'{hit}'
    transplant['Compound'] = analogue_id
    transplant['PDBID'] = pdb_id + "." + pdb_asym_id
    transplant['g-RMSd'] = global_rmsd
    transplant['asym_id'] = asym_id
    transplant['l-RMSd'] = local_rmsd
    transplants.append(transplant)

  transplants = sorted(transplants, key=lambda x: (x['Compound'], x['g-RMSd']))
  with open(f'{FLAGS.output_file}', 'w', newline='') as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(transplant.keys()))
       
    writer.writeheader()

    for row in transplants:
        writer.writerow(row)
  
def main(argv):
    extract_hits()

if __name__ == "__main__":
  """ 
  Create a csv file with transplat scores
  """
  app.run(main)
