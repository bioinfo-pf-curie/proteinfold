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

// This process launches AlphaFold3 to perform msas only:
//   - https://github.com/google-deepmind/alphafold3
process alphaFold3Search {
  tag "${protein}"
  label 'alphaFold3'
  label 'extraMem'
  label 'highCpu'
  publishDir path: "${params.outDir}/alphaFold3Search/", mode: 'copy'
  containerOptions "-B \$PWD:/tmp"

  input:
  tuple val(protein), path(fastaFileJson)
  path alphaFold3Database
  val jsonOK

  output:
  tuple val(protein), path("${protein}/${protein}.json"), emit: msas
  path("versions.txt"), emit: versions
  path("options.txt"), emit: options

  script:
  """
  # AlphaFold3 converts the value in the name field into lowercase (sanitised name)
  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')
  launch_alphafold.sh --run_data_pipeline --db_dir ${alphaFold3Database.target.toString()} --norun_inference --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=\$PWD
  mv \${protein_lowercase} ${protein}
  mv ${protein}/\${protein_lowercase}_data.json ${protein}/${protein}.json 
  echo "AlphaFold3 \$(get_version.sh)" > versions.txt
  echo "AlphaFold3 (MSAS) options=--run_data_pipeline --db_dir ${alphaFold3Database.target.toString()} --norun_inference --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=msas" > options.txt
  """

  stub:
  """
  # AlphaFold3 converts the value in the name field into lowercase (sanitised name)
  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')
  if [[ "${protein}" =~ "domain" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi
  cp -r ${projectDir}/test/data/msas/\$folder/alphafold3/${protein} .
  echo launch_alphafold.sh --run_data_pipeline --db_dir ${alphaFold3Database.target.toString()} --norun_inference --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=msas
  echo "AlphaFold3 \$(get_version.sh)" > versions.txt
  echo "AlphaFold3 (MSAS) options=--run_data_pipeline --db_dir ${alphaFold3Database.target.toString()} --norun_inference --pdb_database_path ${alphaFold3Database.target.toString()}/mmcif_files --jackhmmer_n_cpu ${task.cpus} --nhmmer_n_cpu ${task.cpus} --json_path ${fastaFileJson} --output_dir=msas" > options.txt
  """

}

