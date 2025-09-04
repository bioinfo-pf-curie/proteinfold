#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

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
========================================================================================
                         proteinfold
========================================================================================
 proteinfold analysis Pipeline.
 #### Homepage / Documentation
 https://gitlab.curie.fr/data-analysis/proteinfold.git
----------------------------------------------------------------------------------------
*/

// Custom functions/variables
include { checkInput4Docking ; buildFastaPathCh } from './lib/functions'
include { createFromCh as createMsasCh } from './lib/functions'
include { createFromCh as createPredictionsCh } from './lib/functions'
include { createFromCh as createRankingCh } from './lib/functions'
include { createFromCh as createPdbFileCh } from './lib/functions'

/*
==================================
           INCLUDE
==================================
*/
include { massiveFoldPlots } from "./nf-modules/local/process/massiveFoldPlots"
include { pymolPng } from "./nf-modules/local/process/pymolPng"
include { afMassiveHelp } from "./nf-modules/local/process/afMassiveHelp"
include { alphaFillHelp } from "./nf-modules/local/process/alphaFillHelp"
include { alphaFoldHelp } from "./nf-modules/local/process/alphaFoldHelp"
include { alphaFold3Help } from "./nf-modules/local/process/alphaFold3Help"
include { colabFoldHelp } from "./nf-modules/local/process/colabFoldHelp"
include { dynamicBindHelp } from "./nf-modules/local/process/dynamicBindHelp"



include { afMassiveWkfl } from "./nf-modules/local/subworkflow/afMassiveWkfl"
include { alphaFoldWkfl } from "./nf-modules/local/subworkflow/alphaFoldWkfl"
include { alphaFold3Wkfl } from "./nf-modules/local/subworkflow/alphaFold3Wkfl"
include { colabFoldWkfl } from "./nf-modules/local/subworkflow/colabFoldWkfl"
include { diffDockWkfl } from "./nf-modules/local/subworkflow/diffDockWkfl"
include { dynamicBindWkfl } from "./nf-modules/local/subworkflow/dynamicBindWkfl"
include { alphaFillWkfl } from "./nf-modules/local/subworkflow/alphaFillWkfl"
include { nanoBertWkfl } from "./nf-modules/local/subworkflow/nanoBertWkfl"
include { mqcProteinStructWkfl } from "./nf-modules/local/subworkflow/mqcProteinStructWkfl"


workflow {
  // Note that several functions used in the main.nf scripts
  // are defined in the 'lib' folder

  // Initialize lintedParams and paramsWithUsage
  NFTools.welcome(workflow, params)

  // Use lintedParams as default params object
  paramsWithUsage = NFTools.readParamsFromJsonSettings("${projectDir}/parameters.settings.json")
  params.putAll(NFTools.lint(params, paramsWithUsage))

  // Run name
  customRunName = NFTools.checkRunName(workflow.runName, params.name)

  /*
  ===================================
    SET UP CONFIGURATION VARIABLES
  ===================================
  */

  // Define a variable to test whether the pipeline has been launched with -stub-run
  // or -stub
  def Boolean isStubRun = false
  if (workflow.commandLine.contains('-stub')) {
    isStubRun = true
  }

  // Define a variable to track settings for which the fastaPath can be null
  def Boolean allowFastaPathNull = false

  // Check that any option to print the help of a tool has been set to true
  def Boolean printToolHelp = false
  if (params.collect().join(' ').find('Help=true')) {
    printToolHelp = true
    allowFastaPathNull = true
  }

  // DynamicBind, DiffDock do not require fastaPath
  // but they require a proteinLigandFile
  if (params.launchDynamicBind || params.launchDiffDock) {
    allowFastaPathNull = true
    if (params.proteinLigandFile == null) {
      exit(1, "The option --proteinLigandFile has not been set")
    }
  }

  // AlphaFold3 do not take fasta file as input
  if (params.launchAlphaFold3) {
    allowFastaPathNull = true
  }

  // DynamicBind works only with GPU
  if (params.launchDynamicBind) {
    if (!params.useGpu && !isStubRun) {
      exit(1, "DynamicBind works only using GPU. Launch the pipeline with the '--useGpu true' option.")
    }
  }

  // If the option --fastaPath has been provided, check that it contains a valid path
  if (params.fastaPath != null) {
    def File fastaPath = new File(params.fastaPath)
    if (!fastaPath.exists()) {
      exit(1, "The path to the fasta file(s) '" + params.fastaPath + "' does not exist.")
    }
    if (!fastaPath.isDirectory()) {
      exit(1, "The path to the fasta file(s) '" + params.fastaPath + "' is not a directory.")
    }
  }
  else {
    if (!allowFastaPathNull) {
      exit(1, "The fastaPath options is 'null'. Provide a value using the --fastaPath option.")
    }
  }

  // If the option --proteinLigandFile has been provided, check that the file is correctly formatted
  if (params.proteinLigandFile != null) {
    if (checkInput4Docking(params.proteinLigandFile)) {
      proteinLigandCh = Channel.fromPath(params.proteinLigandFile)
        .splitCsv(header: true)
        .unique()
        .map {
          tuple(file(it.protein).getBaseName(), file(it.protein), file(it.ligand).getBaseName(), file(it.ligand))
        }
    }
  }

  // Check that alphaFoldOptions defines max_template_date=YYYY-MM-DD
  if (!params.alphaFoldOptions.find("--max_template_date=(?:\\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])")) {
    exit(1, "'params.alphaFoldOptions' must define '--max_template_date=YYYY-MM-DD', e.g.: '--max_template_date=2024-01-01'")
  }

  // Get realpath for the annotations to avoid symlink issues in bindings with apptainer
  if (params.launchAfMassive) {
    def File afMassiveDB = new File(params.genomes.afmassive.database)
    afMassiveDatabase = afMassiveDB.getCanonicalPath()

    if (params.numberOfModels > 5) {
      exit(1, "the option numberOfModels must not be greater than 5.")
    }
  }

  if (params.launchAlphaFill) {
    def File alphaFillDB = new File(params.genomes.alphafill.database)
    alphaFillDatabase = alphaFillDB.getCanonicalPath()
  }

  if (params.launchAlphaFold) {
    def File alphaFoldDB = new File(params.genomes.alphafold.database)
    alphaFoldDatabase = alphaFoldDB.getCanonicalPath()
  }

  if (params.launchAlphaFold3) {
    def File alphaFold3DB = new File(params.genomes.alphafold3.database)
    alphaFold3Database = alphaFold3DB.getCanonicalPath()
  }

  if (params.launchColabFold) {
    if (!params.useGpu && !isStubRun) {
      exit(1, "ColabFold works only using GPU. Launch the pipeline with the '--useGpu true' option.")
    }

    def File colabFoldDB = new File(params.genomes.colabfold.database)
    colabFoldDatabase = colabFoldDB.getCanonicalPath()
  }

  if (params.launchDiffDock) {
    def File diffDockDB = new File(params.genomes.diffdock.database)
    diffDockDatabase = diffDockDB.getCanonicalPath()
  }

  if (params.launchDynamicBind) {
    def File dynamicBindDB = new File(params.genomes.dynamicbind.database)
    dynamicBindDatabase = dynamicBindDB.getCanonicalPath()
  }

  if (params.launchOpenFold) {
    def File openFoldDB = new File(params.genomes.openfold.database)
    openFoldDatabase = openFoldDB.getCanonicalPath()
  }

  if (params.launchNanoBert) {
    def File nanoBertDB = new File(params.genomes.nanobert.database)
    nanoBertDatabase = nanoBertDB.getCanonicalPath()
  }

  if (params.onlyMsas && params.fromMsas != null) {
    exit(1, "The --fromMsas option is set with '" + params.fromMsas + "' and --onlyMsas is set to true. Choose either one of these two options.")
  }

  // Check random_seed value
  if ((params.launchAfMassive || params.launchAlphaFold) && !params.alphaFoldOptions.find("--random_seed=\\d+")) {
    msg = "ERROR : The --random_seed parameter is not specified, AlphaFold Options " + params.alphaFoldOptions
    exit(1, NFTools.printRedText(msg))
  }

  if (params.launchColabFold && !(params.colabFoldOptions.find("--random-seed \\d+") || params.colabFoldOptions.find("--random-seed=\\d+"))) {
    msg = "ERROR : The --random-seed parameter is not specified, ColabFold Options " + params.colabFoldOptions
    exit(1, NFTools.printRedText(msg))
  }


  /*
  ==========================
  BUILD CHANNELS
  ==========================
  */

  // The fastaPathCh contains:
  // /path/to/protein.fasta
  // or in the case of AlphaFold3
  // /path/to/protein.json
  // example:
  // /proteinfold/test/data/fasta/monomer2/MRLN.fasta
  // /proteinfold/test/data/fasta/monomer2/MISFA.fasta

  // In the fastaPath we want either json or fasta but not both
  fastaPathCh = buildFastaPathCh("${params.fastaPath}/*.{json,fasta}")

  // The fastaFilesCh contains:
  // [protein, /path/to/protein.fasta]
  // or in the case of AlphaFold3
  // [protein, /path/to/protein.json]
  // example:
  // [MRLN, /proteinfold/test/data/fasta/monomer2/MRLN.fasta]
  // [MISFA, /proteinfold/test/data/fasta/monomer2/MISFA.fasta]
  fastaFilesCh = fastaPathCh.map { fastaFile ->
    def String protein = fastaFile
      .toString()
      .replaceAll(".*/", "")
      .replaceFirst('\\.fasta$', "")
      .replaceFirst('\\.json$', "")
    tuple(protein, file(fastaFile))
  }


  // The fastaChainCh allows the processing of msas chain by chain
  // in the multimer mode to speedup computation.
  // The fastaChainCh contains:
  // [protein, /path/to/protein.fasta, chainIdNum]
  // example:
  // [BTB-domain, /proteinfold/test/data/fasta/multimer/alphafold/BTB-domain.fasta, 1]
  // [BTB-domain, /proteinfold/test/data/fasta/multimer/alphafold/BTB-domain.fasta, 2]
  fastaChainsCh = fastaFilesCh
    .map { protein, fastaFile ->
      def int nbChain = 1
      // this will be the default for Alphafold3 as the parallelisation by chain is not implemeted in the nextflow pipeline
      if (fastaFile.toString().endsWith('.fasta')) {
        nbChain = fastaFile.countFasta()
      }
      (1..nbChain).collect { chainIdNum ->
        tuple(protein, file(fastaFile), chainIdNum)
      }
    }
    .collect()
    .flatten()
    .collate(3)

  // Set the msasCh when the pipeline is launched using existing msas.
  // The msasCh contains:
  // [protein, [/path/to/msas/protein/file1, ... , /path/to/msas/protein/fileX]]
  // example:
  // [MISFA, [/proteinfold/test/data/msas/monomer2/alphafold/MISFA/uniref90_hits.sto, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/pdb_hits.hhr, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/bfd_uniref_hits.a3m, /proteinfold/test/data/msas/monomer2/alphafold/MISFA/mgnify_hits.sto]]
  // [MRLN, [/proteinfold/test/data/msas/monomer2/alphafold/MRLN/uniref90_hits.sto, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/pdb_hits.hhr, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/bfd_uniref_hits.a3m, /proteinfold/test/data/msas/monomer2/alphafold/MRLN/mgnify_hits.sto]]
  msasCh = Channel.empty()
  if (params.fromMsas != null) {
    msasCh = createMsasCh('fromMsas', fastaFilesCh)
  }

  // Set the predictionsCh when the pipeline is launched using existing predicted structures
  predictionsCh = Channel.empty()
  if (params.fromPredictions != null) {

    // The predictionsCh contains:
    // [protein, toolFold, /path/to/predictions/results/protein]
    // The toolFold is empty as we don't knowd what was used hen using the fromPredictions option
    // example:
    // [MISFA, , /home/phupe/git/gitlab/data-analysis/proteinfold/test/data/afmassive/monomer2/MISFA]
    // [MRLN, , /home/phupe/git/gitlab/data-analysis/proteinfold/test/data/afmassive/monomer2/MRLN]
    predictionsCh = createPredictionsCh('fromPredictions', fastaFilesCh).map { tuple(it[0], '', file(file(it[1][0]).getParent())) }


    // rankingCh is not needed if we only launch AlphaFill
    if (!params.launchAlphaFill) {
      rankingCh = createRankingCh('fromPredictions', fastaFilesCh).map {
        def rankingTsvMonomer = it[1].findAll { fileName ->
          fileName.toString().endsWith('ranking_debug.tsv')
        }
        def rankingTsvMultimer = it[1].findAll { fileName ->
          fileName.toString().endsWith('ranking_debug_multimer.tsv')
        }
        def rankingTsvAF3 = it[1].findAll { fileName ->
          fileName.toString().endsWith('ordered_ranking_scores.tsv')
        }

        def rankingTsv
        if (rankingTsvMultimer) {
          rankingTsv = rankingTsvMultimer
        }
        else if (rankingTsvMonomer) {
          rankingTsv = rankingTsvMonomer
        }
        else if (rankingTsvAF3) {
          rankingTsv = rankingTsvAF3
        }
        else {
          error("ERROR: there is no 'ranking_debug.tsv' (AlphaFold2), nor 'ranking_debug_multimer.tsv' (AlphaFold2), nor 'ordered_ranking_scores.tsv' (AlphaFold3) file for protein: " + it[0])
        }

        tuple(it[0], file(rankingTsv[0]))
      }
    }

    pdbFileCh = createPdbFileCh('fromPredictions', fastaFilesCh).map {
      def pdbFile = it[1].findAll { fileName ->
        fileName.toString().matches(/.*ranked_.*\.pdb$|.*ranked_.*\.cif$/)
      }
      if (!pdbFile) {
        error("ERROR: there is no pdb files  nor cif files for protein: " + it[0])
      }
      tuple(it[0], pdbFile)
    }
  }

  /*
  ===========================
    SUMMARY
  ===========================
  */

  summary = [
    'Pipeline': workflow.manifest.name ?: null,
    'Version': workflow.manifest.version ?: null,
    'DOI': workflow.manifest.doi ?: null,
    'Run Name': customRunName,
    'Inputs': params.fastaPath ?: null,
    'AfMassive Database': params.launchAfMassive ? afMassiveDatabase : null,
    'AfMassive Options': params.launchAfMassive ? params.afMassiveOptions : null,
    'AlphaFill Database': params.launchAlphaFill ? alphaFillDatabase : null,
    'AlphaFold Database': params.launchAlphaFold ? alphaFoldDatabase : null,
    'AlphaFold Options': params.launchAlphaFold || params.launchAfMassive ? params.alphaFoldOptions : null,
    'AlphaFold3 Database': params.launchAlphaFold3 ? alphaFold3Database : null,
    'AlphaFold3 Options': params.launchAlphaFold3 ? params.alphaFold3Options : null,
    'ColabFold Database': params.launchColabFold ? colabFoldDatabase : null,
    'ColabFold Options': params.launchColabFold ? params.colabFoldOptions : null,
    'DiffDock Database': params.launchDiffDock ? diffDockDatabase : null,
    'DiffDock Options': params.launchDiffDock ? params.diffDockArgsYamlFile : null,
    'DynamicBind Database': params.launchDynamicBind ? dynamicBindDatabase : null,
    'DynamicBind Options': params.launchDynamicBind ? params.dynamicBindOptions : null,
    'Use existing msas': params.fromMsas != null ? params.fromMsas : null,
    'Use existing predictions': params.fromPredictions != null ? params.fromPredictions : null,
    'Perform only msas': params.onlyMsas ? "True" : "False",
    'Use GPU': params.useGpu ? "True" : "False",
    'Max Resources': "${params.maxMemory} memory, ${params.maxCpus} cpus, ${params.maxTime} time per job",
    'Container': workflow.containerEngine && workflow.container ? "${workflow.containerEngine} - ${workflow.container}" : null,
    'Profile': workflow.profile,
    'OutDir': params.outDir,
    'WorkDir': workflow.workDir,
    'CommandLine': workflow.commandLine,
  ].findAll { it.value != null }

  workflowSummaryCh = NFTools.summarize(summary, workflow, params)
    .collectFile(name: "workflow_summary_mqc.yaml", sort: true)

  versionsCh = Channel.empty()
  optionsCh = Channel.empty()
  plotsCh = Channel.empty()


  // ********************************** //
  // *        Prediction models       * //
  // ********************************** //

  // Launch the prediction of the protein 3D structure with AfMassive
  if (params.launchAfMassive) {
    afMassiveWkfl(
      afMassiveDatabase,
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh,
    )

    if (!params.onlyMsas) {
      //////////////////////////////////
      // multiqc by protein structure //
      //////////////////////////////////
      mqcProteinStructWkfl(
        afMassiveWkfl.out.options,
        afMassiveWkfl.out.versions,
        afMassiveWkfl.out.plots,
        afMassiveWkfl.out.ranking,
        afMassiveWkfl.out.pymolPng,
        afMassiveWkfl.out.alphaBridgePng,
        afMassiveWkfl.out.fastaFiles,
        afMassiveWkfl.out.workflowSummary,
      )

      ///////////////
      // AlphaFill //
      ///////////////
      if (params.launchAlphaFill) {
        alphaFillWkfl(afMassiveWkfl.out.predictions)
      }
    }
  }

  // Launch the prediction of the protein 3D structure with AlphaFold
  if (params.launchAlphaFold) {
    alphaFoldWkfl(
      alphaFoldDatabase,
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh,
    )

    if (!params.onlyMsas) {
      //////////////////////////////////
      // multiqc by protein structure //
      //////////////////////////////////
      mqcProteinStructWkfl(
        alphaFoldWkfl.out.options,
        alphaFoldWkfl.out.versions,
        alphaFoldWkfl.out.plots,
        alphaFoldWkfl.out.ranking,
        alphaFoldWkfl.out.pymolPng,
        alphaFoldWkfl.out.alphaBridgePng,
        alphaFoldWkfl.out.fastaFiles,
        alphaFoldWkfl.out.workflowSummary,
      )

      ///////////////
      // AlphaFill //
      ///////////////
      if (params.launchAlphaFill) {
        alphaFillWkfl(alphaFoldWkfl.out.predictions)
      }
    }
  }

  // Launch the prediction of the protein 3D structure with AlphaFold3
  if (params.launchAlphaFold3) {
    alphaFold3Wkfl(
      alphaFold3Database,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh,
    )

    if (!params.onlyMsas) {
      //////////////////////////////////
      // multiqc by protein structure //
      //////////////////////////////////
      mqcProteinStructWkfl(
        alphaFold3Wkfl.out.options,
        alphaFold3Wkfl.out.versions,
        alphaFold3Wkfl.out.plots,
        alphaFold3Wkfl.out.ranking,
        alphaFold3Wkfl.out.pymolPng,
        alphaFold3Wkfl.out.alphaBridgePng,
        alphaFold3Wkfl.out.fastaFiles,
        alphaFold3Wkfl.out.workflowSummary,
      )
      ///////////////
      // AlphaFill //
      ///////////////
      if (params.launchAlphaFill) {
        alphaFillWkfl(alphaFold3Wkfl.out.predictions)
      }
    }
  }

  // Launch the prediction of the protein 3D structure with ColabFold
  if (params.launchColabFold) {
    colabFoldWkfl(
      colabFoldDatabase,
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh,
    )

    if (!params.onlyMsas) {
      //////////////////////////////////
      // multiqc by protein structure //
      //////////////////////////////////
      mqcProteinStructWkfl(
        alphaFoldWkfl.out.options,
        alphaFoldWkfl.out.versions,
        alphaFoldWkfl.out.plots,
        alphaFoldWkfl.out.ranking,
        alphaFoldWkfl.out.pymolPng,
        alphaFoldWkfl.out.alphaBridgePng,
        alphaFoldWkfl.out.fastaFiles,
        alphaFoldWkfl.out.workflowSummary,
      )
    }
  }

  // Launch the molecular docking with DiffDock
  if (params.launchDiffDock) {
    diffDockWkfl(proteinLigandCh, diffDockDatabase, params.diffDockArgsYamlFile)
  }

  // Launch the molecular docking with DynamicBind
  if (params.launchDynamicBind) {
    dynamicBindWkfl(proteinLigandCh, dynamicBindDatabase)
  }

  // Launch AlphaFill using existing predicted structure
  if (params.launchAlphaFill && params.fromPredictions != null) {
    alphaFillWkfl(predictionsCh)
  }

  // Launch the nanoBERT predictions
  if (params.launchNanoBert) {
    nanoBertWkfl(
      fastaFilesCh,
      fastaPathCh,
    )
  }

  // **************************************************************** //
  // * Generate HTML reports from existing predicted pdb structures * //
  // **************************************************************** //

  // Launch the generation of multiqc ProteinStruct HTML reports
  // using existing predicted structure
  // yaml files for multiqc are set to empty
  if (params.htmlProteinStruct && params.fromPredictions != null) {
    massiveFoldPlots(predictionsCh)
    pymolPng(pdbFileCh)
    mqcProteinStructWkfl(
      Channel.of('').collectFile(name: 'software_options_mqc.yaml'),
      Channel.of('').collectFile(name: 'software_versions_mqc.yaml'),
      massiveFoldPlots.out.plots,
      rankingCh,
      pymolPng.out.png,
      fastaChainsCh.map { protein, _file, _n -> [protein] }.combine(Channel.of('').collectFile(name: 'software_options_mqc.yaml', storeDir: "AlphaBridge")),
      fastaFilesCh,
      Channel.of('').collectFile(name: 'empty.txt'),
    )
  }


  // *********************************** //
  // * Generate help of different tool * //
  // *********************************** //

  // Generate the help for each tool
  if (params.afMassiveHelp) {
    afMassiveHelp()
  }
  if (params.alphaFillHelp) {
    alphaFillHelp()
  }
  if (params.alphaFoldHelp) {
    alphaFoldHelp()
  }
  if (params.alphaFold3Help) {
    alphaFold3Help()
  }
  if (params.colabFoldHelp) {
    colabFoldHelp()
  }
  if (params.dynamicBindHelp) {
    dynamicBindHelp()
  }
}
