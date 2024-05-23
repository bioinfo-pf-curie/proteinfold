#!/usr/bin/env python

# Copyright Institut Curie 2024
#
# This software is a computer program whose purpose is to
# predict 3D structure of proteins.
# You can use, modify and/ or redistribute the software under the terms
# of license (see the LICENSE file for more details).
# The software is distributed in the hope that it will be useful,
# but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
# Users are therefore encouraged to test the software's suitability as regards
# their requirements in conditions enabling the security of their systems and/or data.
# The fact that you are presently reading this means that you have had knowledge
# of the license and that you accept its terms.

"""
Create a tsv file with the scores provided by AlphaFill.
"""

import os
import sys
import csv
import json
from absl import flags
from absl import app

FLAGS = flags.FLAGS

flags.DEFINE_string('input_file', None,
                    'Path to the json file created by AlphaFill.')
flags.DEFINE_string('ligand_file', None,
                    'Path to the ligand file used by AlphaFill.')
flags.DEFINE_string(
    'output_file', None,
    'Path to tsv file with the score values for each transplant.')


def extract_hits(ligand_description):

    """
    Extract the hits identified by AlphaFill
    """

    if not os.path.exists(f'{FLAGS.input_file}'):
        print(f'{FLAGS.input_file} does not exist.')
        sys.exit(1)

    if os.path.exists(f'{FLAGS.output_file}'):
        print(f'{FLAGS.output_file} exists. Choose another file.')
        sys.exit(1)

    with open(f'{FLAGS.input_file}', 'r', encoding="utf-8") as json_file:
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
        transplant['Hit'] = 'hit' + f'{hit}'
        transplant['Compound'] = analogue_id
        transplant['Description'] = ligand_description[analogue_id][
            'Description']
        transplant['PDBID'] = pdb_id + "." + pdb_asym_id
        transplant['g-RMSd'] = global_rmsd
        transplant['asym_id'] = asym_id
        transplant['l-RMSd'] = local_rmsd
        transplants.append(transplant)

    if len(scores['hits']) == 0:
        transplant = {
            'Hit': 'None',
            'Compound': 'nothing predicted by AlphaFill'
        }
        transplants.append(transplant)

    with open(f'{FLAGS.output_file}', 'w', newline='', encoding="utf-8") as csv_file:
        #transplants = sorted(transplants, key=lambda x: (x['Compound'], x['g-RMSd']))
        writer = csv.DictWriter(csv_file,
                                fieldnames=list(transplant.keys()),
                                delimiter='\t')
        writer.writeheader()

        for row in transplants:
            writer.writerow(row)


def parse_ligand_file(ligand_file):

    """
    Extract the compounds from the ligand file used by AlphaFill
    """
    data = {}
    ligands = {}

    with open(ligand_file, 'r', encoding="utf-8") as cif_file:
        current_section = None
        for line in cif_file:
            line = line.strip()
            if line.startswith("data_"):
                current_section = line
                data[current_section] = {
                    "Compound": None,
                    "Description": None,
                    "Name": None
                }
            elif line.startswith("_ligand.id"):
                _, ligand_id = line.split(None, 1)
                data[current_section]["Compound"] = ligand_id.strip("'\"")
            elif line.startswith("_ligand.description"):
                _, description = line.split(None, 1)
                data[current_section]["Description"] = description.strip("'\"")
            elif line.startswith("_ligand.name"):
                _, name = line.split(None, 1)
                data[current_section]["Name"] = name.strip("'\"")
            if data[current_section]["Name"] is not None:
                data[current_section]["Description"] = data[current_section][
                    "Name"]

    for k in data.keys():
        ligands[data[k]["Compound"]] = {"Description": data[k]["Description"]}

    return ligands


def main(argv):

    """
    Main function to format the AlphaFill results in tsv format.
    """

    if not os.path.exists(f'{FLAGS.ligand_file}'):
        print(f'{FLAGS.ligand_file} does not exist.')
        sys.exit(1)

    ligand_description = parse_ligand_file(FLAGS.ligand_file)
    extract_hits(ligand_description)


if __name__ == "__main__":

    app.run(main)
