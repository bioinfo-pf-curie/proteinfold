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
Load two proteins (ref and test) in PDB format, align test on ref
Save the PNG image of test color with plDDT colors
"""

#####################################################################################
import argparse
import os
import pymol
from pymol import cmd

# Function to parse command-line arguments
def parse_args():
    parser = argparse.ArgumentParser(description='PyMOL script to color structure based on B-factors and save an image.')
    parser.add_argument('--pdb_list', required=True, type=str, help='Input directory where are locate the PDB files.')
    parser.add_argument('--output_dir', required=True, type=str, help='Output directory where will be written the PNG files.')
    return parser.parse_args()

# Main function
def main():
    # Parse the command-line arguments
    args = parse_args()
     
    # Define custom colors (using AlphaFold plDDT)
    cmd.set_color("n0", [0.051, 0.341, 0.827])
    cmd.set_color("n1", [0.416, 0.796, 0.945])
    cmd.set_color("n2", [0.996, 0.851, 0.212])
    cmd.set_color("n3", [0.992, 0.490, 0.302])

    # Filter files with .pdb extension
    pdb_files = args.pdb_list.split(',')

    for pdb in range(len(pdb_files)):
        if pdb == 0:
            # Load the reference structure
            cmd.load(pdb_files[pdb], "ref")
            # Orient the view to show the best orientation of the loaded structures
            cmd.orient("all")
            # Color the structure based on B-factor values
            cmd.color("n0", "b < 100")
            cmd.color("n1", "b < 90")
            cmd.color("n2", "b < 70")
            cmd.color("n3", "b < 50")
            # Best fit the view to the entire structure
            cmd.zoom()
            # Save the image
            cmd.png(args.output_dir + '/' + pdb_files[pdb].replace('.pdb', '.png'))
        else:
            # Load the reference structure
            cmd.load(pdb_files[pdb], "test")
            # Align the test structure to the reference structure
            cmd.align("test", "ref")
            # Color the structure based on B-factor values
            cmd.color("n0", "b < 100")
            cmd.color("n1", "b < 90")
            cmd.color("n2", "b < 70")
            cmd.color("n3", "b < 50")
            # Ensure only test protein is active
            cmd.disable("ref")
            # Best fit the view to the entire structure
            cmd.zoom()
            # Save the image
            cmd.png(args.output_dir + '/' + pdb_files[pdb].replace('.pdb', '.png'))
            cmd.delete('test')

if __name__ == '__main__':
    main()

