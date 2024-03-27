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

  script:
  """
  qc_metrics_multimer.py --output_dir=.
  """    

  stub:
  """
  qc_metrics_multimer.py --output_dir=.
  """

}
