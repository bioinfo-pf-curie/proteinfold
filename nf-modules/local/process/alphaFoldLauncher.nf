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

process alphaFoldLauncher {
  tag "${fastaFile}"
  label 'alphaFoldLauncher'
  label 'minMem'
  label 'minCpu'
  publishDir "${params.outDir}/alphaFoldLauncher", mode: 'copy'

  input:
  path fastaFile

  output:
  path "alphaFoldLauncher-*.sh"

  // TODO
  // - params hard are coded in the nextflow,config, this has to be changed
  // - the alphafold parameters are also hard-coded in the script section, they have to be passed with a parameter
  // - we need to use the annotations symlink proposed by geniac to set the path to the alphafold database
  // - name of fasta is hard-coded in the --fasta_paths option
  // - check that data_dir is an absolute path
  // NB
  // It seems that the run_apptainer.py script expects that we are in the folder with the fatas file
  // set the random seed to ensure results reproducibility

  script:
  String fastaFilePrefix = "${fastaFile}".replace('.fasta', '')
  """
  export ALPHAFOLD_DIR=${params.geniac.singularityImagePath}
  export TMPDIR=${params.tmpDir}
  echo -e "#! /bin/bash\n" > alphaFoldLauncher-${fastaFilePrefix}.sh
  echo -e "set -oeu pipefail\n" >> alphaFoldLauncher-${fastaFilePrefix}.sh
  echo -e "WORKDIR_NXF=\\\"\\\$1\\\"" >> alphaFoldLauncher-${fastaFilePrefix}.sh
  echo -e "ALPHAFOLD_SIF=\\\""${params.geniac.singularityImagePath}/alphafold.sif"\\\"" >> alphaFoldLauncher-${fastaFilePrefix}.sh
  echo -e "ALPHAFOLD_TMPDIR=\\\"\\\$WORKDIR_NXF/alphafold_tmpdir\\\"\n" >> alphaFoldLauncher-${fastaFilePrefix}.sh
  echo -e "mkdir -p \\\"\\\$ALPHAFOLD_TMPDIR\\\"\n" >> alphaFoldLauncher-${fastaFilePrefix}.sh
  generate_launcher.py --data_dir=${params.alphaFoldDatabase} --fasta_paths=${params.fastaPath}/${fastaFile} --max_template_date=2022-01-01 --use_gpu=false --output_dir=\\\$WORKDIR_NXF >> alphaFoldLauncher-${fastaFilePrefix}.sh
  """
}

