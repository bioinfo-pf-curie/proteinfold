#! /bin/bash

PNG_FOLDER=$1
PNG_OUTPUT_FILE=$2
PNG_LIST=$(ls -v ${PNG_FOLDER}/*.png)


COUNTER=0

for PNG_FILE in ${PNG_LIST}; do
	COUNTER=$((${COUNTER} + 1))
	if [[ $((${COUNTER}%5)) -eq 1 ]]; then
		OPTS="${OPTS} \("
		CLOSE_BRACKET=0
	fi
	OPTS="${OPTS} ${PNG_FILE}"
	if [[ $((${COUNTER}%5)) -eq 0 ]]; then
		OPTS="${OPTS} +append \)"
		CLOSE_BRACKET=1
	fi
done

if [[ ${CLOSE_BRACKET} -eq 0 ]]; then
	OPTS="${OPTS} +append \)"
fi

CMD="magick ${OPTS} -background none -append ${PNG_OUTPUT_FILE}"
eval ${CMD}

# Usage example
if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 <png_folder> <output_png_file>"
    exit 1
fi
