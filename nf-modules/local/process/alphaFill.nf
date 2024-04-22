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
  publishDir path: "${params.outDir}/alphaFill/${protein}", mode: 'copy'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")
  path alphaFillDatabase

  output:
  tuple val(protein), path("*.cif"), path("*.json"), emit: predictions


  script:
  """
  identity=0.25
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphafillDatabase}/mmcif_files --pdb-fasta ${alphafilldatabase}/fasta/pdb-redo.fasta --ligands ${alphafilldatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  identity=0.30
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  identity=0.40
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  identity=0.50
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  identity=0.60
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  identity=0.7
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb identity\${identity}.cif
  """

  stub:
  """
  identity=0.25
  echo alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/ranked_0.pdb ${protein}-identity\${identity}.cif
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  identity=0.30
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  identity=0.40
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  identity=0.50
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  identity=0.60
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  identity=0.70
  touch identity\${identity}.cif
  cp $projectDir/test/data/alphafill/json/alphafill-res.json identity\${identity}.json
  """
}

