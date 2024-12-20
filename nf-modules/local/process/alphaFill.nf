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
  publishDir path: "${params.outDir}/AlphaFill/${protein}", mode: 'copy'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")
  path alphaFillDatabase

  output:
  tuple val(protein), path("*.cif"), path("*.json"), emit: predictions


  script:
  """
  if [[ -f predictions/${protein}/ranked_0.pdb ]]; then ranked_0="ranked_0.pdb"; else ranked_0="ranked_0.cif"; fi
  identity=0.25
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  identity=0.30
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  identity=0.40
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  identity=0.50
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  identity=0.60
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  identity=0.70
  alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} identity\${identity}.cif
  """

  stub:
  """
  if [[ -f predictions/${protein}/ranked_0.pdb ]]; then ranked_0="ranked_0.pdb"; else ranked_0="ranked_0.cif"; fi
  identity=0.25
  echo alphafill process -t ${task.cpus} --min-hsp-identity \${identity} --pdb-dir ${alphaFillDatabase}/mmcif_files --pdb-fasta ${alphaFillDatabase}/fasta/pdb-redo.fasta --ligands ${alphaFillDatabase}/ligands/af-ligands.cif predictions/${protein}/\${ranked_0} ${protein}-identity\${identity}.cif
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

