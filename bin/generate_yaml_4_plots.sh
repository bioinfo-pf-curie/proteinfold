#! /bin/bash

set -euo pipefail
#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <folder>"
    exit 1
fi

folder="$1"
png_files=()

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    exit 1
fi

# Search for png files and populate the array
while IFS= read -r -d '' file; do
    # Use basename to extract the filename
    filename=$(basename "$file" | sed -e "s/\.png//g")
    png_files+=("$filename")
done < <(find "$folder" \( -type f -o -type l \) -name "*.png" -print0)

png_files=($(printf "%s\n" "${png_files[@]}" | sort -r))

##########################
# generate the yaml file #
##########################

echo "custom_data:"

# Print the array elements
for file in "${png_files[@]}"; do
    echo ""
    echo "  $file:"
    echo "    id: \"$file\""
    echo "    parent_id: prediction_structure_plots"
    echo "    parent_name: \"Plots\""
done

echo ""
echo "sp:"

for file in "${png_files[@]}"; do
    echo ""
    echo "  $file:"
    echo "    fn: \"${file}.png\""
done

echo ""
echo "ignore_images: false"
echo ""
echo "report_section_order:"
echo "  prediction_structure_plots:"
echo "    order: -1000"


counter=-1000
for file in "${png_files[@]}"; do
    counter=$((counter + 10))
    echo "  ${file}:"
    echo "    order: ${counter}"
done

echo "  software:"
echo "    order: -2000"
echo "  software_versions:"
echo "    order: -1990"
echo "  software_options:"
echo "    order: -1980"
echo "  summary:"
echo "    order: -2300"

