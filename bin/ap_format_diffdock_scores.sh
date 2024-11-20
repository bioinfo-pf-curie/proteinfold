#! /bin/bash

set -euo pipefail

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <folder> <protein> <ligand>"
    exit 1
fi

folder="$1"
protein="$2"
ligand="$3"

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    exit 1
fi

# File header
echo "name,protein,ligand,rank,confidence"

# Parse value for each rank
for sdf in $(find ${folder} -type f -regextype egrep -regex '.*/rank[0-9]{1,}_.*\.sdf' -printf "%f\n"); do
	rank=$(echo ${sdf} | sed -e 's/rank//g' | sed -e 's/_.*//g')
	confidence=$(echo ${sdf} | sed -e 's/.*confidence//g' | sed -e 's/\.sdf*//g')
	echo ${protein}-${ligand}-rank${rank},${protein},${ligand},${rank},${confidence}
done
