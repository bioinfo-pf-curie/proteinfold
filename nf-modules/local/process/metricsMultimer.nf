/*
 * MultiQC for ProteinFold report
 */

process metricsMultimer {
  tag "QC"
  label 'python'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/metricsMultimer/", mode: 'copy'

  input:
  path('*')

  output:
  path "qc_metrics_multimer.csv", emit: metrics

  when:
  params.metricsMultimer == true

  script:
  """
  qc_metrics_multimer.py --output_dir=.
  """    

  stub:
  """
  echo metrics
  mkdir afmassive
  cp -r $projectDir/test/data/afmassive/multimer/BTB-domain/ afmassive
  cd afmassive
  qc_metrics_multimer.py --output_dir=.
  mv qc_metrics_multimer.csv ..
  """

}
