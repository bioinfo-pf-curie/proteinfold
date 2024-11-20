#!/bin/bash

set -oeu pipefail


PDB_FILE=$1

IMAGE_TITLE=$(basename ${PDB_FILE%%.pdb})
### Rename for AlphaFold and AFMassive outputs
IMAGE_TITLE=$(echo ${IMAGE_TITLE}| sed -e 's/ranked_/rank: /g')
### Rename for ColabFold outputs
IMAGE_TITLE=$(echo ${IMAGE_TITLE}| sed -e 's/.*_relaxed_rank_\([[:digit:]]\{3\}\).*/relaxed_rank: \1/g')
IMAGE_TITLE=$(echo ${IMAGE_TITLE}| sed -e 's/.*_unrelaxed_rank_\([[:digit:]]\{3\}\).*/unrelaxed_rank: \1/g')
magick ${PDB_FILE%%.pdb}.png -font DejaVu-Sans -pointsize 25 -draw "text 20,20 '${IMAGE_TITLE}'" ${PDB_FILE%%.pdb}.png

# Usage example
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <protein_pdb_file>"
    exit 1
fi

