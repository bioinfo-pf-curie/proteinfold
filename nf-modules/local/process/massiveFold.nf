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

// This process launches massiveFold
// - it uses the massiveFoldOptions
process massiveFold {
  tag "${protein}" 
  label 'massiveFold'
  label 'highMem'
  label 'medCpu'
  publishDir path: "${params.outDir}/massiveFold/${protein}", mode: 'copy'
  containerOptions { (params.useGpu) ? "--nv --env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp" : "--env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} -B \$PWD:/tmp" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  tuple val(protein), path(fastaFile), path("msas/*")
  path alphaFoldOptions
  path massiveFoldDatabase

  output:
  tuple val(protein), val("massiveFold"), path("predictions/*", type: 'dir'), emit: predictions
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  // massiveFold is alphaFold-like, therefore some variables contain alphaFold on purpose
  """
  mkdir -p predictions/${protein}
  ln -s \$(realpath msas/) predictions/${protein}/msas
  alphafold_options="\$(cat ${alphaFoldOptions} | sed -e 's|num_multimer_predictions_per_model|end_prediction|g' -e 's|use_precomputed_msas=False|use_precomputed_msas=True|g') --fasta_paths=${fastaFile}"
  launch_alphafold.sh \${alphafold_options}
  echo "AFmassive \$(get_version.sh)" > versions.txt
  echo "AFmassive (prediction) options=\${alphafold_options}" > options.txt
  """

  stub:
  """
  mkdir -p predictions/${protein}
  ln -s \$(realpath msas/) predictions/${protein}/msas
  alphafold_options="\$(cat ${alphaFoldOptions} | sed -e 's|num_multimer_predictions_per_model|end_prediction|g' -e 's|use_precomputed_msas=False|use_precomputed_msas=True|g') --fasta_paths=${fastaFile}"
  touch predictions/${protein}/${protein}.txt
  echo "AFmassive \$(get_version.sh)" > versions.txt
  echo "AFmassive (prediction) options=\${alphafold_options}" > options.txt
  """

}

