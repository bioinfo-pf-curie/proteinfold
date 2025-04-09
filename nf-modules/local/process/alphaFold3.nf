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

// This process launches AlphaFold3:
//   - https://github.com/google-deepmind/alphafold3
process alphaFold3 {
  tag "${protein}_seed_${seed}" 
  label 'alphaFold3'
  label 'highMem'
  label 'medCpu'
  
  containerOptions { (params.useGpu) ? "--nv --env NVIDIA_VISIBLE_DEVICES=all -B \$PWD:/tmp" : "-B \$PWD:/tmp" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  tuple val(protein), path(fastaFileJson), val(seed)
  path alphafold3Database
  val(jsonOK)

  output:
  tuple val(protein), val("alphaFold3"), path("predictions/${protein}/*"), emit: predictions
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  """
  #remove num_seeds from parameters as it has already been taken into account in json creation
  if [[ ${params.alphaFold3Options} == *"--num_seeds"* ]]; then
      seed_data=\$(echo ${params.alphaFold3Options} | grep -oP '--num_seeds=\\w+')
      alphaFold3Options=\$(echo ${params.alphaFold3Options} | sed "s/\$seed_data//")
  else
      alphaFold3Options=${params.alphaFold3Options}
  fi



  # AlphaFold3 converts the value in the name field into lowercase (sanitised name)
  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')
  launch_alphafold.sh --norun_data_pipeline --run_inference --db_dir ${alphafold3Database.target.toString()} \$alphaFold3Options --pdb_database_path ${alphafold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions
  
  mv predictions/\${protein_lowercase}_seed_${seed} predictions/${protein}
  mv predictions/${protein}/ranking_scores.csv predictions/${protein}/ranking_scores_seed_${seed}.csv
  mv predictions/${protein}/TERMS_OF_USE.md predictions/${protein}/TERMS_OF_USE_seed_${seed}.md
  
  echo "AlphaFold3 \$(get_version.sh)" > versions.txt
  echo "AlphaFold3 (prediction) options=--norun_data_pipeline --run_inference --db_dir ${alphafold3Database.target.toString()} \$alphaFold3Options --pdb_database_path ${alphafold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions" > options.txt
  """

  stub:
  """
  #remove num_seeds from parameters as it has already been taken into account in json creation
  if [[ ${params.alphaFold3Options} == *"--num_seeds"* ]]; then
      seed_data=\$(echo ${params.alphaFold3Options} | grep -oP '--num_seeds=\\w+')
      alphaFold3Options=\$(echo ${params.alphaFold3Options} | sed "s/\$seed_data//")
  else
      alphaFold3Options=${params.alphaFold3Options}
  fi

  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')

  mkdir -p predictions/${protein}
  # We copy here the predictions
  if [[ "${protein}" =~ "domain" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi

  cp -r $projectDir/test/data/alphafold3/\$folder/${protein}/seed-${seed}_* predictions/${protein}
  cp $projectDir/test/data/alphafold3/\$folder/${protein}/TERMS_OF_USE.md predictions/${protein}
  awk 'NR==1 || \$1 ~ /${seed}/' $projectDir/test/data/alphafold3/\$folder/${protein}/ranking_scores.csv > predictions/${protein}/ranking_scores.csv
  ls $projectDir/test/data/alphafold3/\$folder/${protein}/\${protein_lowercase}_* | xargs -I {} sh -c 'cp \$1 \${protein_lowercase}_seed_${seed}_\${1##*/}' sh {}

  mv predictions/${protein}/ranking_scores.csv predictions/${protein}/ranking_scores_seed_${seed}.csv
  mv predictions/${protein}/TERMS_OF_USE.md predictions/${protein}/TERMS_OF_USE_seed_${seed}.md
  
  echo "AlphaFold3 \$(get_version.sh)" > versions.txt
  echo "AlphaFold3 (prediction) options=--norun_data_pipeline --run_inference --db_dir ${alphafold3Database.target.toString()} \$alphaFold3Options --pdb_database_path ${alphafold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions" > options.txt
  """
}

