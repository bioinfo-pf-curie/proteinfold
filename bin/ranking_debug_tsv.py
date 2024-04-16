#!/usr/bin/env python

"""Gather the rankig_debug.json file into a single one"""

import csv
import os
import sys
import json

from shutil import copy as cp

from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string('predictions_path', '',
                    "Path containing the runs you want to gather.")


def create_ranking_global(predictions_path):
    """Gather the rankig_debug.json file into a single one"""

    with open(f"{predictions_path}/ranking_debug.json", 'r', encoding="utf-8") as ranking_file:
        scores = json.load(ranking_file)
        order = scores['order']

        try:
            scores = scores['iptm+ptm']
            s_type = 'iptm+ptm'
        except KeyError:
            scores = scores['plddts']
            s_type = "plddts"


    sorted_predictions = sorted(scores.items(),
                                key=lambda x: x[1],
                                reverse=True)

    scores_csv = []
    for model, score in sorted_predictions:
        scores_csv.append({'model': model, s_type: score})

    with open(f"{FLAGS.predictions_path}/ranking_best.txt",
              'w',
              newline='',
              encoding="utf-8") as txt_file:
        txt_file.write(order[0])

    with open(f"{FLAGS.predictions_path}/ranking_debug.tsv",
              'w',
              newline='',
              encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file,
                                fieldnames=list(scores_csv[0].keys()),
                                delimiter='\t')
        writer.writeheader()

        for row in scores_csv:
            writer.writerow(row)



def main(argv):
    """Gather the rankig_debug.json file into a single one"""
    FLAGS.predictions_path = os.path.abspath(FLAGS.predictions_path)
    create_ranking_global(FLAGS.predictions_path)


if __name__ == "__main__":
    app.run(main)
