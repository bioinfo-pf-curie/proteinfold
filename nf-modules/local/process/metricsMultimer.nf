/*
 * MultiQC for ProteinFold report
 */

import java.lang.Math

process metricsMultimer {
  tag "QC"
  label 'python'
  label 'minCpu'
  memory {
    def memValue = 0.64*Math.log((float)pickleSize)/Math.log(2.0)
    memValue = 14.0 + memValue
    memValue = Math.pow(2, memValue)
    memValue = memValue / Math.pow(10, 9)
    memValue = 4 + memValue
    memValue = memValue * task.attempt
    memValue = memValue.toString() + ' GB'
    return memValue
  }


  publishDir "${params.outDir}/metricsMultimer/${protein}", mode: 'copy'

  input:
  tuple val(protein), val(rank), val(model), val(toolName), path(predictions), val(pickleSize)

  output:
  tuple val(protein), path("qc_metrics_multimer*.tsv"), val(toolName), emit: metrics

  script:
  """
  qc_metrics_multimer.py --output_dir=. --rank=${rank}
  """    

  stub:
  """
  qc_metrics_multimer.py --output_dir=. --rank=${rank}
  """

}
