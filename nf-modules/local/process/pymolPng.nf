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

// This process generates a png plot from a pdb file:
process pymolPng {
  tag "${protein}" 
  label 'pymol'
  label 'medMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/pymolPng/${protein}",
             mode: 'copy'

  input:
  tuple val(protein), path(pdbFile)

  output:
  tuple val("${protein}"), path("*.png"), emit: png

  script:
  """
  # Generate the png image and the best oriented visualization of the reference protein
  # Align the other proteins on the reference and generate the png image
  ap_plot_3d_structure.py --pdb_list \$(echo "${pdbFile}" | tr ' ' ',' | sort) --output_dir \$PWD

  # Add the name of the pdb file on the png image 
  for pdb in ${pdbFile}; do ap_plot_3d_structure.sh \${pdb}; done
  ap_mosaic_3d_structure.sh . mosaic.png
  """

}

