#!/bin/bash

set -oeu pipefail


PDB_FILE=$1

pymol -cq ${PDB_FILE} -d "set_color n0, [0.051, 0.341, 0.827]; set_color n1, [0.416, 0.796, 0.945]; set_color n2, [0.996, 0.851, 0.212]; set_color n3, [0.992, 0.490, 0.302]; color n0, b < 100; color n1, b < 90; color n2, b < 70;  color n3, b < 50; save ${PDB_FILE%%.pdb}.png"

IMAGE_TITLE=$(basename ${PDB_FILE%%.pdb})
magick ${PDB_FILE%%.pdb}.png -font Verdana -pointsize 15 -draw "text 20,20 '${IMAGE_TITLE}'" ${PDB_FILE%%.pdb}.png

# Usage example
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <protein_pdb_file>"
    exit 1
fi

