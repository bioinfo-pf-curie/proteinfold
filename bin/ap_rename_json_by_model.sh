#! /bin/bash

set -euo pipefail
#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <folder> <prefix>"
    exit 1
fi

folder="$1"
suffix="$2"
json_files=()

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    exit 1
fi

# Search for json files and populate the array
while IFS= read -r -d '' file; do
  # Use basename to extract the filename
  filename=$(basename "$file" | sed -e "s/\.json//g")
	echo $file
	echo $filename
    json_files+=("$filename")
done < <(find "$folder" -maxdepth 1 \( -type f -o -type l \) -name "*.json" -print0)

json_files=($(printf "%s\n" "${json_files[@]}" | sort -r))


for json in ${json_files[@]}; do
	echo ${json}
	mv ${folder}/${json}.json ${folder}/${json}${suffix}.json
done
