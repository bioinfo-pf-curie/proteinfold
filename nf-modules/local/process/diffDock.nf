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

// This process launches DiffDock
//   - https://github.com/luwei0917/DiffDock/
process diffDock {
  tag "${protein}-${ligand}"
  label 'diffDock'
  label 'medMem'
  label 'medCpu'
  publishDir path: "${params.outDir}/diffDock/${protein}/${ligand}", mode: 'copy'
  containerOptions { (params.useGpu) ? "--nv --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp -B ${params.diffDockDatabase}/.p.npy:\$PWD/.p.npy -B ${params.diffDockDatabase}/.score.npy:\$PWD/.score.npy -B ${params.diffDockDatabase}/.so3_cdf_vals4.npy:\$PWD/.so3_cdf_vals4.npy -B ${params.diffDockDatabase}/.so3_exp_score_norms4.npy:\$PWD/.so3_exp_score_norms4.npy -B ${params.diffDockDatabase}/.so3_omegas_array4.npy:\$PWD/.so3_omegas_array4.npy -B ${params.diffDockDatabase}/.so3_score_norms4.npy:\$PWD/.so3_score_norms4.npy -B ${params.diffDockDatabase}/workdir:/app/diffdock/workdir -B ${params.diffDockDatabase}/torch_home:/app/diffdock/torch_home" : "-B \$PWD:/tmp -B ${params.diffDockDatabase}/.p.npy:\$PWD/.p.npy -B ${params.diffDockDatabase}/.score.npy:\$PWD/.score.npy -B ${params.diffDockDatabase}/.so3_cdf_vals4.npy:\$PWD/.so3_cdf_vals4.npy -B ${params.diffDockDatabase}/.so3_exp_score_norms4.npy:\$PWD/.so3_exp_score_norms4.npy -B ${params.diffDockDatabase}/.so3_omegas_array4.npy:\$PWD/.so3_omegas_array4.npy -B ${params.diffDockDatabase}/.so3_score_norms4.npy:\$PWD/.so3_score_norms4.npy -B ${params.diffDockDatabase}/workdir:/app/diffdock/workdir -B ${params.diffDockDatabase}/torch_home:/app/diffdock/torch_home" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  tuple val(protein), path(proteinPdb), val(ligand), path(ligandSdf)
  path diffDockDatabase
  path diffDockArgsYamlFile

  output:
  path("${protein}-${ligand}/*.sdf")

  script:
  """
  launch_diffdock.sh --config ${diffDockArgsYamlFile} --complex_name ${protein}-${ligand} --protein_path ${proteinPdb} --ligand_description ${ligandSdf} --out_dir \$PWD
  """

  stub:
  """
  echo launch_diffdock.sh --config ${diffDockArgsYamlFile} --complex_name ${protein}-${ligand} --protein_path ${proteinPdb} --ligand_description ${ligandSdf} --out_dir \$PWD
  mkdir -p ${protein}-${ligand}
  cp $projectDir/test/data/diffdock/results/${protein}-${ligand}/* ${protein}-${ligand}
  """
}

