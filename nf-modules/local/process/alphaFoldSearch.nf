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

// This process launches AlphaFold:
//   - https://github.com/google-deepmind/alphafold
// The AlphaFold options are generated by the process alphaFoldOptions
process alphaFoldSearch {
  tag { "${fastaFile}".replace('.fasta', '') }
  label 'alphaFold'
  label 'highMem'
  label 'highCpu'
  publishDir path: { "${params.outDir}/alphaFoldSearch/${fastaFile}".replace('.fasta', '') }, mode: 'copy'
  containerOptions "--env AF_HHBLITS_N_CPU=${task.cpus} --env AF_JACKHMMER_N_CPU=${task.cpus} -B \$PWD:/tmp"

  input:
  path fastaFile
  path alphaFoldOptions
  path alphaFoldDatabase

  output:
  path("predictions", type: 'dir', emit: msas)
  path(fastaFile, emit: fastaFile)

  script:
  """
  alphafold_options=\$(cat ${alphaFoldOptions})
  launch_alphafold.sh --fasta_paths=${fastaFile} \${alphafold_options} --only_msas
  """
}

