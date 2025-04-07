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
include { mergeMetricsMultimer } from '../process/mergeMetricsMultimer'
include { metricsMultimer } from '../process/metricsMultimer'
include { pymolPng } from '../process/pymolPng'

// Subworkflows
include { alphaFillWkfl } from '../subworkflow/alphaFillWkfl'
include { mqcProteinStructWkfl } from '../subworkflow/mqcProteinStructWkfl'

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
    alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase, fastaChecker.out.jsonOK)

  } else {
    if (params.fromMsas != null){
      // step MSAS when fromMsas
      // after the join operator, msasCh contains:
      // [protein, /path/to/fasta/protein.fasta, [/path/to/msas/protein/file1, ..., /path/to/msas/protein/fileX]]
      // example: 
      // [MISFA, [/proteinfold/test/data/msas/monomer2/alphafold/MISFA/uniref90_hits.sto, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/pdb_hits.hhr, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/bfd_uniref_hits.a3m, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/mgnify_hits.sto]]
      // [MRLN, [/proteinfold/test/data/msas/monomer2/alphafold/MRLN/uniref90_hits.sto, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/pdb_hits.hhr, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/bfd_uniref_hits.a3m, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/mgnify_hits.sto]]
      msasCh = fastaFilesCh.join(msasCh)
    } else {
      // step - MSAS
      alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase, fastaChecker.out.jsonOK)
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

    ////////////////////
    // Software infos //
    ////////////////////
    getSoftwareOptions(optionsCh.unique().collectFile(sort: true))
    getSoftwareVersions(versionsCh.unique().collectFile(sort: true))
    optionsYamlCh = getSoftwareOptions.out.optionsYaml.collect(sort: true).ifEmpty([])
    versionsYamlCh = getSoftwareVersions.out.versionsYaml.collect(sort: true).ifEmpty([])
 
    ///////////////////////
    // plot 3D structure //
    ///////////////////////
    pymolPng(alphaFold.out.pdb)
    
    // rankModelCh contains:
    // [protein, rank, model, tool, pathToprediction]
    // for example:
    // [BTB-domain, 67, model_1_multimer_v3_pred_5, alphaFold, /path/to/work/70/fb3e7/predictions/BTB-domain]
    rankModelCh = alphaFold.out.ranking
      .map {
        File rankingTsv = new File(it[1].toString())
        int lineNumber = 0 
        List rankModel = [] 
        for(line in rankingTsv.readLines()) {
          if (lineNumber != 0) {
            def (rank, model, score) = line.tokenize('\t')
            rankModel.add(tuple (it[0], rank, model))
          }
          lineNumber = lineNumber + 1 
        }
        rankModel
      }
      .flatten()
      .collate(3)
      .combine(alphaFold.out.predictions, by: 0)
      // The map is needed for adaptive memory resource
      .map {
        // size in Bytes of the pickle file
        long pickleSize = 0
        def pickle = new File(it[4].toString() + "/result_" + it[2] + ".pkl")
        pickleSize = pickle.length()
        it.add(pickleSize)
        it
      }


    /////////////////////////////////////////
    // metrics for the multimer prediction //
    /////////////////////////////////////////

    if(params.alphaFoldOptions.contains('multimer')){
      metricsMultimer(rankModelCh)
      mergeMetricsMultimer(metricsMultimer.out.metrics
                            .groupTuple()
                            .map { tuple(it[0], it[1], it[2][0])}
                          )
      rankingCh = mergeMetricsMultimer.out.ranking
    } else {
      rankingCh = alphaFold.out.ranking
    }


    //////////////////////////////////
    // multiqc by protein structure //
    //////////////////////////////////
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
      alphaFillWkfl(alphaFold.out.predictions)
    }
  }

}
