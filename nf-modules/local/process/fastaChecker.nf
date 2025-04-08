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

/***********************************************
 * Some process with a software that has to be *
 * installed with a custom conda yml file      *
 ***********************************************/

// This process checks that the fasta files are correctly formatted
process fastaChecker {
  tag "${fastaFile}"
  label 'onlyLinux'
  label 'minMem'
  label 'minCpu'

  input:
  path fastaFile

  output:
  val(true), emit: jsonOK
  
  script:
  """
  ap_fasta_checker.sh ${fastaFile}
  """

  stub:
  """
  echo ap_fasta_checker.sh ${fastaFile}
  """

}

