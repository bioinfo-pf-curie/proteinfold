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

process convertCifToPdb {
  tag "${protein}"
  label 'pymol'
  label 'minMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/alphaFold3/",
             mode: 'copy',
             saveAs: { filename -> if(filename == "*.pdb" ) filename  else null}


  input:
  tuple val(protein), val(toolFold), path("predictions/*")

  output:
  tuple val(protein), path("predictions/${protein}/*.pdb"), emit: pdb


  script:
  """
  ap_convert_cif_to_pdb.py --input="./predictions/${protein}/ranked_0.cif"
  """

  stub:
  """
  if [[ "${protein}" =~ "domain" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi

  cp -r $projectDir/test/data/afmassive/\$folder/${protein}/ranked_0.pdb predictions/${protein}
  """
}


