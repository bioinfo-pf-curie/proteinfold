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

/*
==================================
           INCLUDE
==================================
*/ 

// Processes
include { afMassive } from '../process/afMassive'
include { afMassiveSearch } from '../process/afMassiveSearch'
include { alphaFoldOptions } from '../process/alphaFoldOptions'
include { fastaChecker } from '../process/fastaChecker'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { massiveFoldPlots } from '../process/massiveFoldPlots'
include { metricsMultimer } from '../process/metricsMultimer'
include { multiqcMetricsMultimer } from '../process/multiqcMetricsMultimer'

// Subworkflows
include { multiqcProteinStructWkfl } from '../subworkflow/multiqcProteinStructWkfl'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow afMassiveWkfl {

  take:

  fastaChainsCh
  fastaFilesCh
  fastaPathCh
  workflowSummaryCh

  main:
  
  ///////////////////
  // Init channels //
  ///////////////////

  optionsCh = Channel.empty()
  versionsCh = Channel.empty()
  plotsCh = Channel.empty()

  /////////////////////////////////////////////////////////
  // Check that the fasta files are correctly formatted  //
  /////////////////////////////////////////////////////////
  fastaChecker(fastaPathCh)

  //////////////////////////
  // Structure prediction //
  //////////////////////////
  // afMassive is alphaFold-like, it uses alphaFold's options too
  alphaFoldOptions(params.alphaFoldOptions, params.afMassiveDatabase)
  if (params.onlyMsas){
    // step - MSAS when onlyMsas
    afMassiveSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.afMassiveDatabase)
    versionsCh = versionsCh.mix(afMassiveSearch.out.versions)
    optionsCh = optionsCh.mix(afMassiveSearch.out.options)
  } else {
    if (params.fromMsas != null){
      // step MSAS when fromMsas
      msasCh = fastaFilesCh.join(msasCh)
    } else {
      // step - MSAS
      afMassiveSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.afMassiveDatabase)
      versionsCh = versionsCh.mix(afMassiveSearch.out.versions)
      optionsCh = optionsCh.mix(afMassiveSearch.out.options)
      msasCh = afMassiveSearch.out.msas
                 .groupTuple()
                 .map { it ->
                   it[1] = it[1].flatten()
                   it
                 }
      msasCh = fastaFilesCh.join(msasCh)
    }
    // step - structure prediction
    afMassive(msasCh, alphaFoldOptions.out.alphaFoldOptions, params.afMassiveDatabase)
    versionsCh = versionsCh.mix(afMassive.out.versions)
    optionsCh = optionsCh.mix(afMassive.out.options)
    // step generate plots
    massiveFoldPlots(afMassive.out.predictions)
    plotsCh = massiveFoldPlots.out.plots
  }

  //////////////////////////////////
  // multiqc by protein structure //
  //////////////////////////////////
  multiqcProteinStructWkfl(
    optionsCh,
    versionsCh,
    plotsCh,
    workflowSummaryCh
  )

  /////////////////////////////////////////
  // metrics for the multimer prediction //
  /////////////////////////////////////////
  if(params.alphaFoldOptions.contains('multimer')){
    // step - compute the metrics 
    metricsMultimer(
      afMassive.out.predictions
        .map { it[2] }
        .collect()
    )
    
    // step - multiqc report with the metric table
    getSoftwareOptions(optionsCh.unique().collectFile())
    getSoftwareVersions(versionsCh.unique().collectFile())
    multiqcMetricsMultimer(
      metricsMultimer.out.metrics,
      getSoftwareOptions.out.optionsYaml.collect().ifEmpty([]),
      getSoftwareVersions.out.versionsYaml.collect().ifEmpty([]),
      Channel.fromPath("${projectDir}/assets/multiqcConfigMetricsMultimer.yaml") 
    )
  }

}
