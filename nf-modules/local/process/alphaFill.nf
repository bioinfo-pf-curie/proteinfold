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

// This process launches AlphaFill
//   - https://github.com/PDB-REDO/alphafill
process alphaFill {
  tag "${protein}"
  label 'alphaFill'
  label 'medMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/alphaFill/", mode: 'copy'
  containerOptions { "-B ${params.colabFoldDatabase}/mmcif_files:/app/alphafill/database/pdb-redo/mmcif_files" -B ${params.colabFoldDatabase}/fasta/pdb-redos.fasta }

  input:
  tuple val(protein), path(proteinPdb), path(proteinPae)
  path alphaFillDatabase

  output:
  tuple path("${protein}.cif"), path("${protein}.json")


  script:
  """
  alphafill process -t ${task.cpus} ${params.alphaFillOptions} --pae-file ${proteinPae} ${proteinPdb} ${protein}.cif
  """
}

