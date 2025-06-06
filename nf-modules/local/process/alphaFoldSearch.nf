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
//   - https://github.com/google-deepmind/alphafold
// The AlphaFold options are generated by the process alphaFoldOptions
// Note that chainIdNum is only consider with the multimer mode,
// otherwise, it has no effect.
process alphaFoldSearch {
  tag "${protein}-chain${chainIdNum}" 
  label 'alphaFold'
  label 'extraMem'
  label 'highCpu'
  publishDir path: "${params.outDir}/alphaFoldSearch",
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
  path alphaFoldDatabase
  val jsonOK

  output:
  tuple val(protein), path("predictions/${protein}/msas/*"), emit: msas
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  """
  alphafold_options="\$(cat ${alphaFoldOptions}) --only_msas"
  launch_alphafold.sh \${alphafold_options}  --fasta_paths=${fastaFile} --chain_id_num ${chainIdNum}
  if [[ -f "predictions/${protein}/msas/chain_id_map.json" ]]; then
    mv predictions/${protein}/msas/chain_id_map.json predictions/${protein}/msas/chain_id_map_${chainIdNum}.json
  fi
  echo "AlphaFold \$(get_version.sh)" > versions.txt
  echo "AlphaFold (MSAS) options=\${alphafold_options}" > options.txt
  """

  stub:
  """
  alphafold_options="\$(cat ${alphaFoldOptions}) --only_msas"
  mkdir -p predictions/${protein}/msas
  touch predictions/${protein}/msas/${protein}-${chainIdNum}.txt
  echo "AlphaFold \$(get_version.sh)" > versions.txt
  echo "AlphaFold (MSAS) options=\${alphafold_options}" > options.txt
  """

}

