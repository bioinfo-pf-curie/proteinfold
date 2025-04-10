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



process createAf3ModelsCh {
	tag "${protein}"
  label 'python'
  label 'minMem'
  label 'minCpu'
	
	debug true 

  input:
  tuple val(protein), path(fastaFileJson)
  val(jsonOK)

  output:
  tuple val(protein), path("seeds_json/*.json"), val(jsonOK)
  

  script:
  def num_seed = null
  if (params.alphaFold3Options.contains("--num_seeds")){
    num_seed = (params.alphaFold3Options =~ /--num_seeds=\w+/)[0]
  }
  """
  ap_create_alphafold3_json_seed.py --protein=$protein --json=$fastaFileJson $num_seed
  """
}


// mkdir -p seeds_json
//   _seed = jq -c '.modelSeeds[]' $fastaFileJson

//   jq -c '.modelSeeds[]' $fastaFileJson | while read seed; do
//       content=\$(jq --argjson seed \$seed '.modelSeeds = \$seed' $fastaFileJson)
//       echo \$content > seeds_json/${protein}_seed_\${seed}.json
//   done  
//  $params.alphaFold3Options
