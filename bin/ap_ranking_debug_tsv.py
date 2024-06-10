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

"""Gather the ranking_debug.json file into a single one"""

import csv
import os
import json

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
    ranked_value = 0
    for model, score in sorted_predictions:
        scores_csv.append({'rank': ranked_value, 'model': model, s_type: score})
        ranked_value = ranked_value + 1

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
    """Gather the ranking_debug.json file into a single one"""
    FLAGS.predictions_path = os.path.abspath(FLAGS.predictions_path)
    create_ranking_global(FLAGS.predictions_path)


if __name__ == "__main__":
    app.run(main)
