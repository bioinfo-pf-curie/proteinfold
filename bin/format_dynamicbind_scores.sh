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
if [ ! -f "$file" ]; then
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

#name,rank,lddt,affinity
#idx_0,1,0.6090541,7.37494
#idx_0,2,0.6064814,7.6047406
#idx_0,3,0.60660785,7.5212903
#idx_0,4,0.5943595,7.4116
#idx_0,5,0.5997138,7.5957
#idx_0,6,0.6059134,7.362788
#idx_0,7,0.60360414,7.383279
#idx_0,8,0.5946559,7.414966
#idx_0,9,0.5854747,7.636363

