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
include { alphaFold3 } from '../process/alphaFold3'
//include { alphaFold3Options } from '../process/alphaFoldOptions'
include { alphaFold3Search } from '../process/alphaFold3Search'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { jsonChecker } from '../process/jsonChecker'
include { massiveFoldPlots } from '../process/massiveFoldPlots'
include { pymolPng } from '../process/pymolPng'

// Subworkflows
include { mqcProteinStructWkfl } from '../subworkflow/mqcProteinStructWkfl'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow alphaFold3Wkfl {

  take:

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

  ////////////////////////////////////////////////////////////////////////
  // Check that the fasta files in JSON format are correctly formatted  //
  ////////////////////////////////////////////////////////////////////////
  jsonChecker(fastaPathCh)

  //////////////////////////
  // Structure prediction //
  //////////////////////////
  //alphaFoldOptions(params.alphaFoldOptions, params.alphaFoldDatabase)
  if (params.onlyMsas){
    // step - MSAS when onlyMsas
    alphaFold3Search(fastaFilesCh, params.alphaFold3Database)
    versionsCh = versionsCh.mix(alphaFold3Search.out.versions)
    optionsCh = optionsCh.mix(alphaFold3Search.out.options)
  } else {
      if (params.fromMsas != null){
        // Do nothing (just to have the same if/else condition as in the alphaFold.nf file
        msasCh = msasCh
      } else {
        // step - MSAS
        alphaFold3Search(fastaFilesCh, params.alphaFold3Database)
        versionsCh = versionsCh.mix(alphaFold3Search.out.versions)
        optionsCh = optionsCh.mix(alphaFold3Search.out.options)
        msasCh = alphaFold3Search.out.msas
      }
    // msasCh contains:
    // [protein, /path/to/msas/protein.json]
    // the file  /path/to/msas/protein.json contains the msas in a dedicated field
    //created by the process alphaFold3Search
    alphaFold3(msasCh, params.alphaFold3Database, jsonChecker.out.jsonOK)
    versionsCh = versionsCh.mix(alphaFold3.out.versions)
    optionsCh = optionsCh.mix(alphaFold3.out.options)
    }

  rankingCh = alphaFold3.out.ranking

  massiveFoldPlots(alphaFold3.out.predictions)
  plotsCh = massiveFoldPlots.out.plots

  ///////////////////////
  // plot 3D structure //
  ///////////////////////
  pymolPng(alphaFold3.out.pdb)

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
  Channel.empty()
  mqcProteinStructWkfl(
    optionsYamlCh,
    versionsYamlCh,
    plotsCh,
    rankingCh,
    pymolPng.out.png,
    fastaFilesCh,
    workflowSummaryCh
  )
}
