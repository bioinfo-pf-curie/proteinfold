/*
Copyright Institut Curie 2024

This software is a computer program whose purpose is to
provide a demo with geniac.
You can use, modify and/ or redistribute the software under the terms
of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful,
but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards
their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge
of the license and that you accept its terms.

*/


/***********************************************
 * Some process with a software that has to be *
 * installed with a custom conda yml file      *
 ***********************************************/

// This process predicts the protein structure with alphaFold
process massiveFold {
  label 'massiveFold'
  label 'extraMem'
  label 'highCpu'
  publishDir "${params.outDir}/massiveFold/", mode: 'copy'
  containerOptions { (params.useGpu) ? '--nv --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp' : '-B \$PWD:/tmp' }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }
  
  output:
  path "help.txt"

  script:
  """
  colabfold_batch -h > help.txt
  """
}

