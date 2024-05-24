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

// This process launches afMassive
// - it uses the afMassiveOptions
process afMassive {
  tag "${protein}-${modelsToUse}-${predNumber}-${randomSeed}" 
  label 'afMassive'
  label 'highMem'
  label 'medCpu'
  containerOptions { (params.useGpu) ? "--nv --env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp" : "--env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} -B \$PWD:/tmp" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  tuple val(protein), path(fastaFile), path("msas/*"), val(predNumber), val(modelsToUse), val(randomSeed)
  path alphaFoldOptions
  path afMassiveDatabase

  output:
  tuple val(protein), val("afMassive"), path("predictions/${protein}/*", type: 'file'), emit: predictions
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  // afMassive is alphaFold-like, therefore some variables contain alphaFold on purpose
  """
  mkdir -p predictions/${protein}
  ln -s \$(realpath msas/) predictions/${protein}/msas
  alphafold_options="\$(cat ${alphaFoldOptions} | sed -e 's|num_multimer_predictions_per_model|end_prediction|g' -e 's|use_precomputed_msas=False|use_precomputed_msas=True|g')"
  launch_alphafold.sh \${alphafold_options} ${params.afMassiveOptions} --start_prediction ${predNumber} --end_prediction ${predNumber} --models_to_use=${modelsToUse} --random_seed=${randomSeed} --fasta_paths=${fastaFile}
  bash ap_rename_json_by_model.sh predictions/${protein} _${modelsToUse}_pred_${predNumber}
  mv predictions/${protein}/features.pkl predictions/${protein}/features_${modelsToUse}_pred_${predNumber}.pkl
  mv predictions/${protein}/ranked_0.pdb predictions/${protein}/ranked_0_${modelsToUse}_pred_${predNumber}.pdb
  echo "AFmassive \$(get_version.sh)" > versions.txt
  echo "AFmassive (prediction) options=\${alphafold_options} ${params.afMassiveOptions}" > options.txt
  """

  stub:
  """
  mkdir -p predictions/${protein}
  ln -s \$(realpath msas/) predictions/${protein}/msas
  alphafold_options="\$(cat ${alphaFoldOptions} | sed -e 's|num_multimer_predictions_per_model|end_prediction|g' -e 's|use_precomputed_msas=False|use_precomputed_msas=True|g')"
  # We copy here the predictions
  if [[ "\$alphafold_options" =~ "preset=multimer" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi
  cp $projectDir/test/data/afmassive/\$folder/${protein}/* predictions/${protein}
  echo "AFmassive \$(get_version.sh)" > versions.txt
  echo "AFmassive (prediction) options=\${alphafold_options} ${params.afMassiveOptions}" > options.txt
  cd predictions/${protein}
  mv features.pkl features_${modelsToUse}_pred_${predNumber}.pkl
  rm ranked_0.pdb
  mv *.pdb unrelaxed_${modelsToUse}_pred_${predNumber}.pdb
  if [[ ! -f result_${modelsToUse}_pred_${predNumber}.pkl ]]; then mv result* result_${modelsToUse}_pred_${predNumber}.pkl; fi
  head -2 ranking_debug.json > ranking_debug_${modelsToUse}_pred_${predNumber}.json
  grep "${modelsToUse}_pred_${predNumber}" ranking_debug.json | head -1 | sed -e 's/,//g' >> ranking_debug_${modelsToUse}_pred_${predNumber}.json
  grep "}," ranking_debug.json >> ranking_debug_${modelsToUse}_pred_${predNumber}.json
  grep "order" ranking_debug.json >> ranking_debug_${modelsToUse}_pred_${predNumber}.json
  grep "${modelsToUse}_pred_${predNumber}" ranking_debug.json | tail -1 | sed -e 's/,//g' >> ranking_debug_${modelsToUse}_pred_${predNumber}.json
  tail -2 ranking_debug.json >> ranking_debug_${modelsToUse}_pred_${predNumber}.json
  rm ranking_debug.json
  """

}

