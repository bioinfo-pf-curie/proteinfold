/*
Copyright Institut Curie 2024

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

// This process generates a command line to launch alphaFold with apptainer:
// - it sets the appropriate bindings with fasta files and annotations, etc.
// - it uses the alphaFoldOptions
process alphaFoldOptions {
  tag "${fastaFile}"
  label 'alphaFoldOptions'
  label 'minMem'
  label 'minCpu'
  publishDir "${params.outDir}/alphaFoldOptions", mode: 'copy'

  input:
  path fastaFile

  output:
  path "*.sh"

  script:
  String fastaFilePrefix = "${fastaFile}".replace('.fasta', '')
  String apptainerRun = "${params.apptainerRun}"
  String alphaFoldOptions = "${params.alphaFoldOptions}" + " "
  if (params.useGpu) {
    apptainerRun += " --nv" 
  }
  """
  echo -e "#! /bin/bash\n" > ${fastaFilePrefix}.sh
  echo -e "set -oeu pipefail\n" >> ${fastaFilePrefix}.sh
  echo -e "WORKDIR_NXF=\\\"\\\$1\\\"" >> ${fastaFilePrefix}.sh
  echo -e "ALPHAFOLD_SIF=\\\""${params.geniac.singularityImagePath}/alphafold.sif"\\\"" >> ${fastaFilePrefix}.sh
  echo -e "ALPHAFOLD_TMPDIR=\\\"\\\$WORKDIR_NXF/alphafold_tmpdir\\\"\n" >> ${fastaFilePrefix}.sh
  echo -e "mkdir -p \\\"\\\$ALPHAFOLD_TMPDIR\\\"\n" >> ${fastaFilePrefix}.sh
  apptainer_options=\$(generate_launcher.py --data_dir=${params.alphaFoldDatabase} --fasta_paths=${params.fastaPath}/${fastaFile} ${alphaFoldOptions} --use_gpu=${params.useGpu} --output_dir=\\\$WORKDIR_NXF)
  echo ${apptainerRun} \${apptainer_options} >> ${fastaFilePrefix}.sh
  echo -e "rm -rf \\\"\\\$ALPHAFOLD_TMPDIR\\\"\n" >> ${fastaFilePrefix}.sh
  echo -e "rm -rf ld.so.cache\n" >> ${fastaFilePrefix}.sh
  """
}

