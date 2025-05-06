/*
Copyright Institut Curie 2024

This software is a computer program whose purpose is to
predict 3D structure of proteins.
You can use, modify and/ or redistribute the software under the terms
of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful,
but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards
their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge
of the license and that you accept its terms.

*/

// This process generates the plots from AlphaFold or MassiveFols results:
// It uses the code from https://github.com/GBLille/AfMassive with a minor patch to
// check whether PAEs are available within the picle data
process alphaBridge {
  maxRetries 0
  debug true
  tag { ("${toolFold}".isEmpty()) ? "${protein}" : "${protein}-${toolFold}" }
  label 'alphaBridge'
  label 'lowMem'
  label 'lowCpu'
  publishDir path: "${params.outDir}/AlphaBridge/${protein}", mode: 'copy'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")
  val(abbr_toolFold)

  output:
  tuple val(protein), path("*.png"), emit: png

  script:
  """
  set -e
  trap 'touch empty.txt; exit 0' ERR #if there is an error in the execution of alphabridge, the program will be coninued

  # there is no possibility to choose where the out are profided we must copy the working folder outside a symbolic link
  cp -rL predictions/${protein} ${protein}

  define_interfaces.sh -i ${protein} -m ${abbr_toolFold}

  mv ${protein}/AlphaBridge/*.png .

  IMAGES=(*_ribbon_plot.png)  
  MAX_WIDTH=1800
  COLS=3
  ROW=\$(awk -v i="\${#IMAGES[@]}" -v c="\$COLS" 'BEGIN { print int((i+c-1)/c) }')
  WIDTH_PER_IMAGE=\$((MAX_WIDTH / COLS))
  
  mkdir -p resized temp_rows
  
  for img in "\${IMAGES[@]}"; do
    convert "\$img" -resize "\${WIDTH_PER_IMAGE}" "resized/\$img"
  done
  
  for ((i=0; i<ROW; i++)); do
    row_images=()
    for ((j=0; j<COLS; j++)); do
      index=\$((i * COLS + j))
      if [ \$index -lt \${#IMAGES[@]} ]; then
        row_images+=( "resized/\${IMAGES[\$index]}" )
      else
        row_images+=( "xc:white" )
      fi
    done
    convert +append "\${row_images[@]}" "temp_rows/row_\$i.png"
  done

  convert -append temp_rows/row_*.png ribbon_plot.png

  rm -rf temp_rows resized

  IMAGES=(*_matrix.png *contact_plot.png)
  MAX_WIDTH=1200
  COLS=2
  ROW=\$(awk -v i="\${#IMAGES[@]}" -v c="\$COLS" 'BEGIN { print int((i+c-1)/c) }')
  WIDTH_PER_IMAGE=\$((MAX_WIDTH / COLS))
  
  mkdir -p resized temp_rows
  
  for img in "\${IMAGES[@]}"; do
    convert "\$img" -resize "\${WIDTH_PER_IMAGE}" "resized/\$img"
  done
  
 
  for ((i=0; i<ROW; i++)); do
    row_images=()
    for ((j=0; j<COLS; j++)); do
      index=\$((i * COLS + j))
      if [ \$index -lt \${#IMAGES[@]} ]; then
        row_images+=( "resized/\${IMAGES[\$index]}" )
      else
        row_images+=( "xc:white" )
      fi
    done
    convert +append "\${row_images[@]}" "temp_rows/row_\$i.png"
  done
  
  convert -append temp_rows/row_*.png quality_matrix.png

  rm -rf temp_rows resized
  
  """
}

