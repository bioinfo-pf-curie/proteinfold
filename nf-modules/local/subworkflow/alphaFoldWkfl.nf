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
include { alphaFold } from '../process/alphaFold'
include { alphaFoldOptions } from '../process/alphaFoldOptions'
include { alphaFoldSearch } from '../process/alphaFoldSearch'
include { fastaChecker } from '../process/fastaChecker'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { massiveFoldPlots } from '../process/massiveFoldPlots'
include { metricsMultimer } from '../process/metricsMultimer'
include { multiqcMetricsMultimer } from '../process/multiqcMetricsMultimer'

// Subworkflows
include { alphaFillWkfl } from '../subworkflow/alphaFillWkfl'
include { multiqcMetricsMultimerWkfl } from '../subworkflow/multiqcMetricsMultimerWkfl'
include { multiqcProteinStructWkfl } from '../subworkflow/multiqcProteinStructWkfl'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow alphaFoldWkfl {

  take:

  fastaChainsCh
  fastaFilesCh
  fastaPathCh
  msasCh
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
  alphaFoldOptions(params.alphaFoldOptions, params.alphaFoldDatabase)
  if (params.onlyMsas){
    // step - MSAS when onlyMsas
    alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
    versionsCh = versionsCh.mix(alphaFoldSearch.out.versions)
    optionsCh = optionsCh.mix(alphaFoldSearch.out.options)
  } else {
    if (params.fromMsas != null){
      // step MSAS when fromMsas
      msasCh = fastaFilesCh.join(msasCh)
    } else {
      // step - MSAS
      alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
      versionsCh = versionsCh.mix(alphaFoldSearch.out.versions)
      optionsCh = optionsCh.mix(alphaFoldSearch.out.options)
      msasCh = alphaFoldSearch.out.msas
                 .groupTuple()
                 .map { it ->
                   it[1] = it[1].flatten()
                   it
                 }
      msasCh = fastaFilesCh.join(msasCh)
    }
    // step - structure prediction
    alphaFold(msasCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
    versionsCh = versionsCh.mix(alphaFold.out.versions)
    optionsCh = optionsCh.mix(alphaFold.out.options)
    // step generate plots
    massiveFoldPlots(alphaFold.out.predictions)
    plotsCh = massiveFoldPlots.out.plots
  }
 
   
  ////////////////////
  // Software infos //
  ////////////////////
  getSoftwareOptions(optionsCh.unique().collectFile(sort: true))
  getSoftwareVersions(versionsCh.unique().collectFile(sort: true))
  optionsYamlCh = getSoftwareOptions.out.optionsYaml.collect(sort: true).ifEmpty([])
  versionsYamlCh = getSoftwareVersions.out.versionsYaml.collect(sort: true).ifEmpty([])


  //////////////////////////////////
  // multiqc by protein structure //
  //////////////////////////////////
  multiqcProteinStructWkfl(
    optionsYamlCh,
    versionsYamlCh,
    plotsCh,
    alphaFold.out.ranking,
    workflowSummaryCh
  )

  /////////////////////////////////////////
  // metrics for the multimer prediction //
  /////////////////////////////////////////
  if(params.alphaFoldOptions.contains('multimer')){
    multiqcMetricsMultimerWkfl(
      optionsYamlCh,
      versionsYamlCh,
      alphaFold.out.predictions,
      workflowSummaryCh
    )
  }

  ///////////////
  // AlphaFill //
  ///////////////
  if(params.launchAlphaFill){
    alphaFillWkfl(alphaFold.out.predictions)
  }

}
