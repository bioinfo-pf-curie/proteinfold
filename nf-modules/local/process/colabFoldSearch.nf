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

// This process search the ColabFold database to generate a a3m file
// used by ColabFold to predict the proteini 3D structure with
// see:
//   - https://github.com/sokrypton/ColabFold
//   - https://github.com/YoshitakaMo/localcolabfold
process colabFoldSearch {
  tag { "${fastaFile}".replace('.fasta', '') }
  label 'colabFold'
  label 'supraMem'
  label 'highCpu'
  publishDir "${params.outDir}/colabFoldSearch/", mode: 'copy'
  
  input:
  path fastaFile
  path colabFoldDatabase

  output:
  path("*", type: 'dir', emit: msas)

  script:
  String fastaFilePrefix = "${fastaFile}".replace('.fasta', '')
  """
  colabfold_search --threads "${task.cpus}" "${fastaFile}" "${params.colabFoldDatabase}" "${fastaFilePrefix}"
  """
}

