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


/***********************************************
 * Some process with a software that has to be *
 * installed with a custom conda yml file      *
 ***********************************************/

process alphaFold {
  tag "${alphaFoldLauncher}"
  label 'alphaFold'
  label 'extraMem'
  label 'highCpu'
  publishDir {
    String protein = "${alphaFoldLauncher}".replaceAll(/\.sh$/, '')
    "${params.outDir}/alphaFold/${protein}"
    }, mode: 'copy'
  
  input:
  path alphaFoldLauncher

  output:
  path("*", type: 'dir')

  script:
  """
  bash "${alphaFoldLauncher}" \$PWD
  """
}

