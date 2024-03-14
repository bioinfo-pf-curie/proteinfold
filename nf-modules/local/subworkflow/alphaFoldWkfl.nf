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
include { alphaFoldOptions } from '../process/alphaFoldOptions'
include { alphaFoldSearch } from '../process/alphaFoldSearch'
include { massiveFoldPlots } from '../process/massiveFoldPlots'

// Subworkflows
include { multiqcProteinStructWkfl } from '../subworkflow/multiqcProteinStructWkfl'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow alphaFoldWkfl {

  take:

  fastaChainsCh
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
  alphaFoldOptions(params.alphaFoldOptions, params.alphaFoldDatabase)
  if (params.onlyMsas){
    // step MSAS when onlyMsas
    alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
    versionsCh = versionsCh.mix(alphaFoldSearch.out.versions)
    optionsCh = optionsCh.mix(alphaFoldSearch.out.options)
  } else {
    if (params.fromMsas != null){
      // step MSAS when fromMsas
      msasCh = fastaFilesCh.join(msasCh)
    } else {
      // step MSAS
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
    // step structure prediction
    alphaFold(msasCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
    versionsCh = versionsCh.mix(alphaFold.out.versions)
    optionsCh = optionsCh.mix(alphaFold.out.options)
    // step generate plots
    massiveFoldPlots(alphaFold.out.predictions)
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

}
