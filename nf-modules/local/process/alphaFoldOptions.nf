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

// This process generates a command line to launch alphaFold with apptainer:
// - it sets the appropriate bindings with fasta files and annotations, etc.
// - it uses the alphaFoldOptions
process alphaFoldOptions {
  tag "${fastaFile}"
  label 'alphaFoldOptions'
  label 'minMem'
  label 'minCpu'
  publishDir "${params.outDir}/alphaFoldOptions", mode: 'copy'

  input:
  val alphaFoldOptions
  val alphaFoldDatabase

  output:
  path "alphafold_options.txt", emit: alphaFoldOptions

  script:
  """
  alphafold_options=\$(alphafold_options.py --data_dir=${alphaFoldDatabase} ${alphaFoldOptions} --use_gpu=${params.useGpu} --output_dir=predictions)
  echo \${alphafold_options} >> alphafold_options.txt
  """
}

