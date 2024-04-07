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

// This process launches nanoBERT:
process nanoBert {
  tag "${protein}" 
  label 'nanoBert'
  label 'minMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/nanoBert/${protein}",
             mode: 'copy'

  input:
  tuple val(protein), path(fastaFile)
  path nanoBertDatabase

  output:
  path("*.tsv"), emit: scores
  path("*.yaml"), emit: yaml


  script:
  """
  nanobert.py --fasta_file=${fastaFile} --model_dir=${nanoBertDatabase}/nanoBERT --output_dir=.
  """

  stub:
  """
  nanobert.py --fasta_file=${fastaFile} --model_dir=${nanoBertDatabase}/nanoBERT --output_dir=.
  """

}

