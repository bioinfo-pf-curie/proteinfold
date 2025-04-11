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
  tag { ("${toolFold}".isEmpty()) ? "${protein}" : "${protein}-${toolFold}" }
  label 'alphabridge'
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
  # there is no possibility to choose where the out are profided we must copy the working folder outside a symbolic link
  cp -rL predictions/${protein} ${protein}

  define_interfaces.sh -i ${protein} -m ${abbr_toolFold}

  mv ${protein}/AlphaBridge/*.png .

  IMAGES=(*_ribbon_plot.png)  
  MAX_WIDTH=1800
  COLS=3
  WIDTH_PER_IMAGE=\$((MAX_WIDTH / COLS))
  
  mkdir -p resized temp_rows
  
  for img in "\${IMAGES[@]}"; do
    convert "\$img" -resize "\${WIDTH_PER_IMAGE}" "resized/\$img"
  done
  
  i=0
  row=0
  
  for ((i=0; i<\${#IMAGES[@]}; i+=3)); do
      row=\$((i / 3))
      convert +append \
      resized/"\${IMAGES[\$i]}" \
      resized/"\${IMAGES[\$((i + 1))]:-xc:white}" \
      resized/"\${IMAGES[\$((i + 2))]:-xc:white}" \
      "temp_rows/row_\$row.png"
  done

  convert -append temp_rows/row_*.png ribbon_plot.png

  rm -rf temp_rows resized

  IMAGES=(*_matrix.png)  
  MAX_WIDTH=1200
  COLS=2
  WIDTH_PER_IMAGE=\$((MAX_WIDTH / COLS))
  
  mkdir -p resized temp_rows
  
  for img in "\${IMAGES[@]}"; do
    convert "\$img" -resize "\${WIDTH_PER_IMAGE}" "resized/\$img"
  done
  
  i=0
  row=0
  
  for ((i=0; i<\${#IMAGES[@]}; i+=\$COLS)); do
      row=\$((i / \$COLS))
      convert +append \
      resized/"\${IMAGES[\$i]}" \
      resized/"\${IMAGES[\$((i + 1))]:-xc:white}" \
      "temp_rows/row_\$row.png"
  done

  convert -append temp_rows/row_*.png quality_matrix.png

  rm -rf temp_rows resized
  
  """
}

