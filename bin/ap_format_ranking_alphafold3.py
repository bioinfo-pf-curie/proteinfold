#!/usr/bin/env python

import csv
import os
import shutil

from absl import flags
from absl import app


FLAGS = flags.FLAGS

flags.DEFINE_string(
    'input_file', None,
    'Path to input ranking file.')

flags.DEFINE_string(
    'output_file', None,
    'Path to the output the ordered ranking file.')

flags.DEFINE_string(
    'cif_dir', None,
    'Path where to copy the cif files.')

def order_ranking_scores_af3(ranking_scores):
    with open(ranking_scores, 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file)  # Use DictReader to work with named columns
        # Sort rows by 'ranking_score' in descending order
        sorted_rows = sorted(csv_reader, key=lambda row: float(row['ranking_score']), reverse=True)
    rank = 0
    for row in sorted_rows:
        row['model'] = f"seed-{row['seed']}_sample-{row['sample']}"
        row['rank'] = rank
        rank = rank + 1

    return sorted_rows

def write_order_ranking_scores_af3(ordered_ranking_scores, ordered_ranking_scores_file):
    new_column_order = ['rank', 'model', 'seed', 'sample', 'ranking_score']
    with open(ordered_ranking_scores_file, mode='w', newline='', encoding='utf-8') as outfile:
        # Create a DictWriter object with tab as the delimiter
        writer = csv.DictWriter(outfile, fieldnames=new_column_order, delimiter='\t')

        # Write the header row to the output file
        writer.writeheader()

        # Write rows from the DictReader to the output file
        for row in ordered_ranking_scores:
            writer.writerow({key: row[key] for key in new_column_order})


def main(argv):
    """ 
    These functions are a combination of MassiveFold's team work and the following scripts from ColabFold repository and DeepMind colab notebook:
    https://github.com/sokrypton/ColabFold/blob/main/colabfold/plot.py
    https://github.com/sokrypton/ColabFold/blob/main/colabfold/colabfold.py
    https://colab.research.google.com/github/deepmind/alphafold/blob/main/notebooks/AlphaFold.ipynb
    
    Here are some basic commands:
    python MF_plots.py --input_path ./jobname --chosen_plots coverage,CF_PAEs
      -> regardless of the plot type, plot alignment coverage and group PAE for top 10 predictions
    """
    FLAGS.input_file = os.path.realpath(FLAGS.input_file)
    FLAGS.output_file = os.path.realpath(FLAGS.output_file)
    FLAGS.cif_dir = os.path.realpath(FLAGS.cif_dir)

    sorted_scores = order_ranking_scores_af3(FLAGS.input_file)
    write_order_ranking_scores_af3(sorted_scores, FLAGS.output_file)

    for row in sorted_scores:
        cif_src = f"{os.path.dirname(FLAGS.input_file)}/{row['model']}/model.cif"
        cif_dest = f"{FLAGS.cif_dir}/ranked_{row['rank']}.cif"
        shutil.copy(cif_src, cif_dest)


if __name__ == "__main__":
    app.run(main)
