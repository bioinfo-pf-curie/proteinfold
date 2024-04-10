/*
 * MultiQC for ProteinFold report
 */

import java.lang.Math

process metricsMultimer {
  tag "QC"
  label 'python'
  label 'minCpu'
  memory {
    def memValue = 0.64*Math.log((float)maxPickleSize)/Math.log(2.0)
    memValue = 14.0 + memValue
    memValue = Math.pow(2, memValue)
    memValue = memValue / Math.pow(10, 9)
    memValue = 4 + memValue
    memValue = memValue.toString() + ' GB'
    return memValue
  }
  publishDir "${params.outDir}/metricsMultimer/", mode: 'copy'

  input:
  path('*')
  // max size in Bytes of the pickle file
  val(maxPickleSize)

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
