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

// This process checks that the json files for required by AlphaFold3 are correctly formatted
process jsonChecker {
  tag "${fastaFileJson}"
  label 'python'
  label 'minMem'
  label 'minCpu'

  input:
  path fastaFileJson

  output:
  val(true), emit: jsonOK

  script:
  """
  ap_json_checker.py --json=${fastaFileJson} 
  """

}

