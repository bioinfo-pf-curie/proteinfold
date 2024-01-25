/*
Copyright Institut Curie 2023

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

// This process predicts the protein structure with colabFold
process colabFold {
  label 'colabFold'
  label 'extraMem'
  label 'highCpu'
  publishDir "${params.outDir}/colabFold/", mode: 'copy'
  containerOptions { (params.useGpu) ? '--nv' : '' }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  path msas  

  output:
  path("prediction/*", type: 'dir')

  script:
  """
  colabfold_batch ${msas} prediction
  """
}

