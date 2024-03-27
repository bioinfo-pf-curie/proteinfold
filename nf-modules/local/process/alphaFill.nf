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

  input:
  tuple val(protein), val(toolFold), path("predictions/*"), path(jsonPae)
  path alphaFillDatabase

  output:
  tuple val(protein), path("${protein}.cif"), path("${protein}.json"), emit: predictions


  script:
  """
  alphafill process -t ${task.cpus} ${params.alphaFillOptions} --pae-file ${jsonPae} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb ${protein}.cif
  """

  stub:
  """
  echo alphafill process -t ${task.cpus} ${params.alphaFillOptions} --pae-file ${jsonPae} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb ${protein}.cif
  touch ${protein}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json ${protein}.json
  """
}

