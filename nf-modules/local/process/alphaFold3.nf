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
  tag "${protein}" 
  label 'alphaFold3'
  label 'highMem'
  label 'medCpu'
  publishDir path: "${params.outDir}/alphaFold3/",
             mode: 'copy',
             saveAs: { it.replaceAll('predictions/', '') }
  containerOptions { (params.useGpu) ? "--nv --env NVIDIA_VISIBLE_DEVICES=all -B \$PWD:/tmp" : "-B \$PWD:/tmp" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  tuple val(protein), path(fastaFileJson)
  path alphaFold3Database
  val(jsonOK)

  output:
  tuple val(protein), val("alphaFold3"), path("predictions/*", type: 'dir'), emit: predictions
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  """
  # AlphaFold3 converts the value in the name field into lowercase (sanitised name)
  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')
  launch_alphafold.sh --norun_data_pipeline --run_inference --db_dir ${alphaFold3Database.target.toString()} ${params.alphaFold3Options} --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions
  mv predictions/\${protein_lowercase} predictions/${protein}
  echo "AlphaFold \$(get_version.sh)" > versions.txt
  echo "AlphaFold (prediction) options=--norun_data_pipeline --run_inference --db_dir ${alphaFold3Database.target.toString()} ${params.alphaFold3Options} --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions" > options.txt
  """

  stub:
  """
  mkdir -p predictions/
  # We copy here the predictions
  if [[ "${protein}" =~ "domain" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi
  cp -r $projectDir/test/data/alphafold3/\$folder/${protein} predictions/
  echo "AlphaFold \$(get_version.sh)" > versions.txt
  echo "AlphaFold (prediction) options=--norun_data_pipeline --run_inference --db_dir ${alphaFold3Database.target.toString()} ${params.alphaFold3Options} --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=predictions" > options.txt
  """
}

