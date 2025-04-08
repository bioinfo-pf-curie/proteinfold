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
  label 'medMem'
  label 'highCpu'
  publishDir path: "${params.outDir}/nanoBert/${protein}",
             mode: 'copy'

  input:
  tuple val(protein), path(fastaFile)
  // this is: path nanoBertDatabase
  // but renames as 'models''
  path('models')
  val jsonOK

  output:
  tuple val("${protein}"), path("nanobert"), emit: scores

  script:
  """
  mkdir nanobert
  ap_nanobert.py --fasta_file=${fastaFile} --model_dir=models/nanoBERT --output_dir=nanobert --model_name=nanobert
  ap_nanobert.py --fasta_file=${fastaFile} --model_dir=models/nanoBERT --output_dir=nanobert --model_name=human_heavy
  """

  stub:
  """
  mkdir nanobert
  ap_nanobert.py --fasta_file=${fastaFile} --model_dir=models/nanoBERT --output_dir=nanobert --model_name=nanobert
  ap_nanobert.py --fasta_file=${fastaFile} --model_dir=models/nanoBERT --output_dir=nanobert --model_name=human_heavy
  """

}

