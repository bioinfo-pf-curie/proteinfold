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

// Processes
include { metricsMultimer } from '../process/metricsMultimer'
include { multiqcMetricsMultimer } from '../process/multiqcMetricsMultimer'

workflow multiqcMetricsMultimerWkfl {

  take:

  optionsYamlCh
  versionsYamlCh
  predictionsCh
  workflowSummaryCh


  main:
  
  // step - compute the metrics 
  metricsMultimer(
    predictionsCh
      .map { it[2] }
      .collect(sort: true)
  )
  
  // step - multiqc report with the metric table
  multiqcMetricsMultimer(
    metricsMultimer.out.metrics,
    optionsYamlCh,
    versionsYamlCh,
    Channel.fromPath("${projectDir}/assets/multiqcConfigMetricsMultimer.yaml") 
  )

}
