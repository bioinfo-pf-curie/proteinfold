#! /bin/bash

set -euo pipefail

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file> <protein> <ligand>"
    exit 1
fi

file="$1"
protein="$2"
ligand="$3"

# Check if the file exists
if [[ ! -f "$file" ]]; then
    echo "File '$file' does not exist."
    exit 1
fi

if [[ $(head -1 ${file} | awk -F, '{print $2}') == "rank" ]]; then
	echo "name,protein,ligand,rank,lddt,affinity"
	for line in $(tail -n +2 ${file}); do
		rank=$(echo ${line} | awk -F, '{print $2}')
		echo ${protein}-${ligand}-rank${rank},${protein},${ligand},$(echo ${line} | sed -e "s/idx_0,//g")
	done
else
	echo "name,protein,ligand,affinity"
	for line in $(tail -n +2 ${file}); do
		echo ${protein}-${ligand},${protein},${ligand},$(echo ${line} | sed -e "s/idx_0,//g")
	done
fi

