#!/usr/bin/env python

# Copyright Institut Curie 202GG4
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

    # Filter JSON files
    json_files = [
        file for file in os.listdir(predictions_path)
        if file.startswith('ranking_debug') and file.endswith('.json')
    ]
    json_files = sorted(json_files)

    ranking_global = {}
    for json_file in json_files:

        with open(json_file, 'r', encoding="utf-8") as ranking_file:
            scores = json.load(ranking_file)

            try:
                scores = scores['iptm+ptm']
                s_type = 'iptm+ptm'
            except KeyError:
                scores = scores['plddts']
                s_type = "plddts"

            if len(list(scores.keys())) > 1:
                print(f"There are more than one model in {json_file}")
                sys.exit(1)

            model_name = list(scores.keys())[0]
            score = scores[model_name]
            ranking_global.update({model_name: score})

    sorted_predictions = sorted(ranking_global.items(),
                                key=lambda x: x[1],
                                reverse=True)
    print(sorted_predictions)
    print(type(sorted_predictions))
    print(type(sorted_predictions[0]))
    order = sorted(ranking_global, reverse=True, key=ranking_global.get)

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

    with open(f"{FLAGS.predictions_path}/ranking_debug.json",
              'w',
              encoding="utf-8") as fileout:
        fileout.write(
            json.dumps({
                s_type: ranking_global,
                'order': order
            }, indent=4))

    rank_i = 0
    for ranked_model in order:
        cp(f"unrelaxed_{ranked_model}.pdb", f"ranked_{rank_i}.pdb")
        rank_i = rank_i + 1


def main(argv):
    """Gather the rankig_debug.json file into a single one"""
    FLAGS.predictions_path = os.path.abspath(FLAGS.predictions_path)
    create_ranking_global(FLAGS.predictions_path)


if __name__ == "__main__":
    app.run(main)
