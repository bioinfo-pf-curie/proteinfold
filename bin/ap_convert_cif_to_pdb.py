#! /usr/bin/env python

""" Convert the best prediction of  """
import argparse
import os
import pymol

def convert_cif_to_pdb(input_file ):
    if not os.path.isfile(input_file):
        raise FileNotFoundError(f"File not found: {input_file}")

    # Determine output path
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    output_file = os.path.join(os.path.dirname(input_file), f"{base_name}.pdb")

    # Launch PyMOL in command-line mode (no GUI)
    pymol.finish_launching(['pymol', '-c'])
    pymol.cmd.load(input_file)
    pymol.cmd.save(output_file)
    pymol.cmd.quit()



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Convert CIF file to PDB using PyMOL")
    parser.add_argument('--input', required=True, help="Path to the .cif file")
    args = parser.parse_args()

    convert_cif_to_pdb(args.input)

