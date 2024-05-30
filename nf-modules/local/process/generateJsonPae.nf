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

// This process generates the PAE from the multimer prediction in json fornmat
process generateJsonPae {
  tag "${protein}-${toolFold}" 
  label 'python'
  label 'lowMem'
  label 'lowCpu'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")

  output:
  tuple val(protein), path("${protein}_pae.json"), emit: jsonPae

  script:
  """
  ap_generate_pae_json.py --prediction_dir=predictions/${protein} --output_file=${protein}_pae.json
  """

  stub:
  """
  ap_generate_pae_json.py --prediction_dir=predictions/${protein} --output_file=${protein}_pae.json
  """
}

