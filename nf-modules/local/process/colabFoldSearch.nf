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
  tag "${protein}"
  label 'colabFold'
  label 'supraMem'
  label 'highCpu'
  publishDir "${params.outDir}/colabFoldSearch/", mode: 'copy'
  
  input:
  tuple val(protein), path(fastaFile)
  path colabFoldDatabase

  output:
  tuple val(protein), path("*", type: 'dir'), emit: msas
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  String colabfold_options = "--threads ${task.cpus} ${fastaFile} ${params.colabFoldDatabase} ${protein}"
  """
  colabfold_search ${colabfold_options}
  echo "ColabFold \$(get_version.sh)" > versions.txt
  echo "colabfold_search options=${colabfold_options}" > options.txt
  """

  stub:
  String colabfold_options = "--threads ${task.cpus} ${fastaFile} ${params.colabFoldDatabase} ${protein}"
  """
  mkdir ${protein}
  touch ${protein}/${protein}.txt
  echo "ColabFold \$(get_version.sh)" > versions.txt
  echo "colabfold_search options=${colabfold_options}" > options.txt
  """

}

