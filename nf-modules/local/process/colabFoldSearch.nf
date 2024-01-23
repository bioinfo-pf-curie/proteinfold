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


/***********************************************
 * Some process with a software that has to be *
 * installed with a custom conda yml file      *
 ***********************************************/

// This process predicts the protein structure with alphaFold
process colabFoldSearch {
  label 'colabFold'
  label 'extraMem'
  label 'highCpu'
  publishDir "${params.outDir}/colabFoldSearch/", mode: 'copy'
  
  input:
  path fastaFile
  path colabFoldDatabase

  output:
  path "help.txt"
  path "search.txt"

  script:
  String fastaFilePrefix = "${fastaFile}".replace('.fasta', '')
  """
  echo colabfold_search --threads "${task.cpus}" "${fastaFile}" "${params.colabFoldDatabase}" "${fastaFilePrefix}" > search.txt
  colabfold_batch -h > help.txt
  echo "${colabFoldDatabase}/"
  """
}

