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

"""
Compute amber relaxation from a PDB file
- code inspired from: https://github.com/google-deepmind/alphafold/issues/721
"""


import os
import sys

from absl import app
from absl import flags
from alphafold.common import protein
from alphafold.relax import relax


FLAGS = flags.FLAGS
flags.DEFINE_string('pdb_file', None,
                    "Path to the pdb file you want to relax.")
flags.DEFINE_string('relaxed_pdb_file', None,
                    'Name of the file to write the relaxed PDB file.')
flags.DEFINE_boolean(
    'use_gpu_relax', False, 'Whether to relax on GPU. '
    'Relax on GPU can be much faster than CPU, so it is '
    'recommended to enable if possible. GPUs must be available'
    ' if this setting is enabled.')


def relax_with_amber(model_name: str, relaxed_pdb_file: str, use_gpu_relax: bool):
    """
    Compute structure relaxation
     - model_name: path to the PDB file
     - relaxed_pdb_file: name of the file to write the relaxed PDB file.'
     - output_dir: directory in which the relaxed od file is written
     - use_gpu_relax: whether to use GPU or not
    """
    relax_max_iterations = 0
    relax_energy_tolerance = 2.39
    relax_stiffness = 10.0
    relax_exclude_residues = []
    relax_max_outer_iterations = 20
    amber_relax = relax.AmberRelaxation(
        max_iterations=relax_max_iterations,
        tolerance=relax_energy_tolerance,
        stiffness=relax_stiffness,
        exclude_residues=relax_exclude_residues,
        max_outer_iterations=relax_max_outer_iterations,
        use_gpu=use_gpu_relax)
    with open(str(model_name), encoding="utf-8") as f:
        test_prot = protein.from_pdb_string(f.read())
        pdb_min, _, _ = amber_relax.process(prot=test_prot)
        with open(relaxed_pdb_file, 'w', encoding="utf-8") as rel_f:
            rel_f.write(str(pdb_min))


def main(argv):
    """
    Compute amber relaxation from a PDB file

    Example:
     {argv[0]} --pdb_file=my_file.pdb --relaxed_pdb_file=relaxed_my_file.pdb --use_gpu_relax

    Output:
     It will generate the file 'relaxed_my_file.pdb'
    
    Help:
     amber_relax.py --helpshort

    """

    if not os.path.exists(f'{FLAGS.pdb_file}'):
        print(f'{FLAGS.pdb_file} does not exist.')
        sys.exit(1)

    if os.path.exists(f'{FLAGS.relaxed_pdb_file}'):
        print(f'{FLAGS.relaxed_pdb_file} already exists.')
        sys.exit(1)

    relax_with_amber(FLAGS.pdb_file, FLAGS.relaxed_pdb_file, FLAGS.use_gpu_relax)


if __name__ == "__main__":

    flags.mark_flags_as_required([
        'pdb_file',
        'relaxed_pdb_file',
    ])

    app.run(main)
