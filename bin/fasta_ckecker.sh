#!/bin/bash

set -oeu pipefail

allowed_characters="ACDEFGHIKLMNPQRSTUVWY"

check_fasta_format() {
    file="$1"
   
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found."
        exit 1
    fi

    while IFS= read -r line; do
        if [[ "$line" =~ ^\> ]]; then
            # Header line
            header="$line"
            sequence=""
        else
            # Sequence line
            sequence="$line"
            # Check if sequence contains only valid amino acid characters
            if [[ ! "$sequence" =~ ^["$allowed_characters"]+$ ]]; then
                echo "Error: Invalid characters in sequence for header '$header'."
								unexpected_characters=$(echo "$sequence" | sed -e "s/["$allowed_characters"]//g" | grep -o '.' | sort -u | paste -sd '')
								echo "Remove '$unexpected_characters' character(s) from the sequence."
                exit 1
            fi
        fi
    done < "$file"

    echo "Validation successful: Protein FASTA file is correctly formatted."
}

# Usage example
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <protein_fasta_file>"
    exit 1
fi

check_fasta_format "$1"
