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

// This process launches AlphaFold:
//   - https://github.com/GBLille/MassiveFold
// The AlphaFold options are generated by the process alphaFoldOptions
// Note that chainIdNum is only consider with the multimer mode,
// otherwise, it has no effect.
process massiveFoldSearch {
  tag "${protein}-chain${chainIdNum}" 
  label 'massiveFold'
  label 'highMem'
  label 'highCpu'
  publishDir path: "${params.outDir}/massiveFoldSearch",
             mode: 'copy',
             saveAs: {
               String msasDirName = it.replaceAll(".*/", "")
               msasDirName = "${protein}/${msasDirName}"
               return msasDirName
           }
  containerOptions "--env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} -B \$PWD:/tmp"

  input:
  tuple val(protein), path(fastaFile), val(chainIdNum)
  path alphaFoldOptions
  path massiveFoldDatabase

  output:
  tuple val(protein), path(fastaFile), path("predictions/${protein}/msas/*"), emit: msas

  script:
  // massiveFold is alphaFold-like, therefore some variables contain alphaFold on purpose
  """
  alphafold_options=\$(cat ${alphaFoldOptions} | sed -e 's|num_multimer_predictions_per_model|end_prediction|g')
  launch_alphafold.sh --fasta_paths=${fastaFile} \${alphafold_options} --only_msas --chain_id_num ${chainIdNum}
  if [[ -f "predictions/${protein}/msas/chain_id_map.json" ]]; then
    mv predictions/${protein}/msas/chain_id_map.json predictions/${protein}/msas/chain_id_map_${chainIdNum}.json
  fi
  """
}

