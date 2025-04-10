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
include { alphaBridge } from '../process/alphaBridge'
include { alphaFold3 } from '../process/alphaFold3'
include { alphaFold3Gather } from '../process/alphaFold3Gather'
include { alphaFold3Search } from '../process/alphaFold3Search'
include { createAf3ModelsCh } from '../process/createAf3ModelsCh'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { jsonChecker } from '../process/jsonChecker'
include { massiveFoldPlots } from '../process/massiveFoldPlots'
include { pymolPng } from '../process/pymolPng'

// Subworkflows
include { alphaFillWkfl } from '../subworkflow/alphaFillWkfl'
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

  /////////////////////////////////////////////////////////
  // Check that the fasta files are correctly formatted  //
  /////////////////////////////////////////////////////////
  jsonChecker(fastaPathCh)
	  
  ///////////////////
  // Init channels //
  ///////////////////

  // empty channel
  optionsCh = Channel.empty()
  versionsCh = Channel.empty()
  plotsCh = Channel.empty()
 
  if (params.onlyMsas){
    // step - MSAS when onlyMsas
    alphaFold3Search(fastaFilesCh, params.alphaFold3Database, jsonChecker.out.jsonOK)
  } else {
    if (params.fromMsas != null){
      // Do nothing (just to have the same if/else condition as in the alphaFold.nf file
      msasCh = msasCh
    } else {
      // step - MSAS
      alphaFold3Search(fastaFilesCh, params.alphaFold3Database, jsonChecker.out.jsonOK)
      versionsCh = versionsCh.mix(alphaFold3Search.out.versions)
      optionsCh = optionsCh.mix(alphaFold3Search.out.options)
      msasCh = alphaFold3Search.out.msas
    }
    // afMassive options for parallelization
    // create on json file per seeds
    afModels = createAf3ModelsCh(msasCh, jsonChecker.out.jsonOK)
                | transpose()
                | map { prot, file, jsonOK -> 
                        def seed = file.getName()
                                       .replaceFirst(/\.[^\.]+$/, '')
                                       .replaceFirst(/.*_seed_/, '')
                        [prot, file, seed, jsonOK]
                    }

    // afModels contains:
    // [protein, /path/to/msas/protein_seed.json, seed, true]
    
    // json quality recovery
    jsonOK = afModels.map{ prot, file, seed, jsonOK -> [jsonOK]}
    // json quality suppression
    afModels = afModels.map{ prot, file, seed, jsonOK -> [prot, file, seed]}
    // afModels contains:
    // [protein, /path/to/msas/protein_seed.json, seed]

    alphaFold3(afModels, params.alphaFold3Database,jsonOK)
    versionsCh = versionsCh.mix(alphaFold3.out.versions)
    optionsCh = optionsCh.mix(alphaFold3.out.options)

    //step - gather the predcition after parallelization
    afMassiveGatherCh = alphaFold3.out.predictions
                          .groupTuple()
                          .map { it ->
                            it[1] =it[1].unique().sort()
                            it[2] = it[2].flatten().sort()
                            it
                          }
                          .join(msasCh)

    alphaFold3Gather(afMassiveGatherCh)
    ////////////////////
    // Software infos //
    ////////////////////
    getSoftwareOptions(optionsCh.unique().collectFile(sort: true))
    getSoftwareVersions(versionsCh.unique().collectFile(sort: true))
    optionsYamlCh = getSoftwareOptions.out.optionsYaml.collect(sort: true).ifEmpty([])
    versionsYamlCh = getSoftwareVersions.out.versionsYaml.collect(sort: true).ifEmpty([])

    rankingCh = alphaFold3Gather.out.ranking
    //alphaBridge(alphaFold3Gather.out.predictions)
    massiveFoldPlots(alphaFold3Gather.out.predictions)
    plotsCh = massiveFoldPlots.out.plots

    ///////////////////////
    // plot 3D structure //
    ///////////////////////
    pymolPng(alphaFold3Gather.out.pdb)

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

    ///////////////
    // AlphaFill //
    ///////////////
    if(params.launchAlphaFill){
      alphaFillWkfl(alphaFold3Gather.out.predictions)
    }
  }
  
}