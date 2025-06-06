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

// This process predicts the protein structure with ColabFold
// see:
//   - https://github.com/sokrypton/ColabFold
//   - https://github.com/YoshitakaMo/localcolabfold
// The process takes as input the directory (i.e. msas) where is located
// the a3m file created by the process colabFoldSearch 
process openFold {
  tag "${msas}"
  label 'colabFold'
  label 'medMem'
  label 'medCpu'
  publishDir "${params.outDir}/openFold/", mode: 'copy', saveAs: { "${msas}" }
  containerOptions { (params.useGpu) ? "--nv" : '' }
  clusterOptions { (params.useGpu) ? params.executor.gpu[task.executor] : '' }

  input:
  path msas 
  path openFoldDatabase

  output:
  path("predictions", type: 'dir')

  script:
  """
  echo openfold ${msas} predictions
  """
}

