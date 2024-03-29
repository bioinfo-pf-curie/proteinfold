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
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { multiqcProteinStruct } from '../process/multiqcProteinStruct'

workflow multiqcProteinStructWkfl {

  take:

  optionsCh
  versionsCh
  plotsCh
  workflowSummaryCh


  main:
  
  // Perform multiqc by protein structure
  getSoftwareVersions(versionsCh.unique().collectFile())
  getSoftwareOptions(optionsCh.unique().collectFile())
  multiqcProteinStruct(
    plotsCh
      .combine(getSoftwareVersions.out.versionsYaml.collect().ifEmpty([])),
    plotsCh
      .map {
        it[0]
      }
      .combine(getSoftwareOptions.out.optionsYaml.collect().ifEmpty([])),
    plotsCh
      .map {
        it[0]
      }
      .combine(workflowSummaryCh.collectFile(name: "workflow_summary_mqc.yaml"))
  )

}
