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

// This process launches DynamicBind
//   - https://github.com/luwei0917/DynamicBind/
process dynamicBind {
  label 'dynamicBind'
  label 'medMem'
  label 'medCpu'
  publishDir path: "${params.outDir}/dynamicBind/${protein}", mode: 'copy'
  containerOptions { (params.useGpu) ? "--nvi --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp" : "-B \$PWD:/tmp" }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  script:
  """
  launch_dynamicbind.sh protein.pdb ligand.csv --savings_per_complex 40 --inference_steps 20 --header test --device $1 --python /gxr/luwei/anaconda3/envs/dynamicbind/bin/python --relax_python /gxr/luwei/anaconda3/envs/relax/bin/python
  """
}

