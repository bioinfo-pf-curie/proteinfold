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
include { colabFold } from '../process/colabFold'
include { colabFoldSearch } from '../process/colabFoldSearch'
include { fastaChecker } from '../process/fastaChecker'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { massiveFoldPlots } from '../process/massiveFoldPlots'
include { pymolPng } from '../process/pymolPng'

// Subworkflows
include { mqcProteinStructWkfl } from '../subworkflow/mqcProteinStructWkfl'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow colabFoldWkfl {

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
  if (params.onlyMsas){
    colabFoldSearch(fastaFilesCh, params.colabFoldDatabase)
    versionsCh = versionsCh.mix(colabFoldSearch.out.versions)
    optionsCh = optionsCh.mix(colabFoldSearch.out.options)
  } else {
    if (params.fromMsas == null){
      colabFoldSearch(fastaFilesCh, params.colabFoldDatabase)
      versionsCh = versionsCh.mix(colabFoldSearch.out.versions)
      optionsCh = optionsCh.mix(colabFoldSearch.out.options)
      msasCh = colabFoldSearch.out.msas
    }
    colabFold(msasCh, params.colabFoldDatabase)
    versionsCh = versionsCh.mix(colabFold.out.versions)
    optionsCh = optionsCh.mix(colabFold.out.options)
    plotsCh = colabFold.out.plots
 
    ///////////////////////
    // plot 3D structure //
    ///////////////////////
    pymolPng(colabFold.out.pdb)
    
    //////////////////////////////////
    // multiqc by protein structure //
    //////////////////////////////////
    mqcProteinStructWkfl(
      optionsYamlCh,
      versionsYamlCh,
      plotsCh,
      colabFold.out.ranking,
      pymolPng.out.png,
      fastaFilesCh,
      workflowSummaryCh
    )

  }

  ////////////////////
  // Software infos //
  ////////////////////
  getSoftwareOptions(optionsCh.unique().collectFile(sort: true))
  getSoftwareVersions(versionsCh.unique().collectFile(sort: true))
  optionsYamlCh = getSoftwareOptions.out.optionsYaml.collect(sort: true).ifEmpty([])
  versionsYamlCh = getSoftwareVersions.out.versionsYaml.collect(sort: true).ifEmpty([])

}
