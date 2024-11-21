#!/usr/bin/env nextflow

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
                         @git_repo_name@
========================================================================================
 @git_repo_name@ analysis Pipeline.
 #### Homepage / Documentation
 @git_url@
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

// Note that several functions used in the main.nf scripts
// are defined in the 'lib' folder

// Initialize lintedParams and paramsWithUsage
NFTools.welcome(workflow, params)

// Use lintedParams as default params object
paramsWithUsage = NFTools.readParamsFromJsonSettings("${projectDir}/parameters.settings.json")
params.putAll(NFTools.lint(params, paramsWithUsage))

// Run name
customRunName = NFTools.checkRunName(workflow.runName, params.name)

// Custom functions/variables
include { checkInput4Docking } from './lib/functions'
include { printFileContent } from './lib/functions'
include { elementsNotPresent } from './lib/functions'
include { createFromCh as createMsasCh } from './lib/functions'
include { createFromCh as createPredictionsCh } from './lib/functions'
include { createFromCh as createRankingCh } from './lib/functions'
include { createFromCh as createPdbFileCh } from './lib/functions'

/*
===================================
  SET UP CONFIGURATION VARIABLES
===================================
*/


// Define a variable to test whether the pipeline has been launched with -stub-run
// or -stub
Boolean isStubRun = false
if ( workflow.commandLine.contains('-stub')) {
  isStubRun = true
}

// Define a variable to track settings for which the fastaPath can be null
Boolean allowFastaPathNull = false

// Check that any option to print the help of a tool has been set to true
Boolean printToolHelp = false
if (params.collect().join(' ').find('Help=true')) {
  printToolHelp = true
  allowFastaPathNull = true
}

// DynamicBind, DiffDock do not require fastaPath
// but they require a proteinLigandFile
if(params.launchDynamicBind || params.launchDiffDock) {
  allowFastaPathNull = true
  if(params.proteinLigandFile == null) {
    exit 1, "The option --proteinLigandFile has not been set"
  }
}

// DynamicBind works only with GPU
if(params.launchDynamicBind) {
  if (!params.useGpu && !isStubRun){
    exit 1, "DynamicBind works only using GPU. Launch the pipeline with the '--useGpu true' option."
  }
}

// If the option --fastaPath has been provided, check that it contains a valid path
if (params.fastaPath != null ) {
  File fastaPath = new File(params.fastaPath)
  if (!fastaPath.exists()){
    exit 1, "The path to the fasta file(s) '" + params.fastaPath + "' does not exist."
  }
  if (!fastaPath.isDirectory()){
    exit 1, "The path to the fasta file(s) '" + params.fastaPath + "' is not a directory."
  }
} else {
  if (!allowFastaPathNull) {
    exit 1, "The fastaPath options is 'null'. Provide a value using the --fastaPath option."
  }
}

// If the option --proteinLigandFile has been provided, check that the file is correctly formatted
if (params.proteinLigandFile != null) {
  if (checkInput4Docking(params.proteinLigandFile)) {
    proteinLigandCh = Channel
                        .fromPath(params.proteinLigandFile)
                        .splitCsv(header: true)
                        .unique()
                        .map {
                          tuple(file(it.protein).getBaseName(), file(it.protein), file(it.ligand).getBaseName(), file(it.ligand))
                        }
  }
}

// Check that alphaFoldOptions defines max_template_date=YYYY-MM-DD
if (!params.alphaFoldOptions.find("--max_template_date=(?:\\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])")){
  exit 1, "'params.alphaFoldOptions' must define '--max_template_date=YYYY-MM-DD', e.g.: '--max_template_date=2024-01-01'"
}

// Get realpath for the annotations to avoid symlink issues in bindings with apptainer
if (params.launchAfMassive){
  File afMassiveDB = new File(params.genomes.afmassive.database)
  params.afMassiveDatabase = afMassiveDB.getCanonicalPath()

  if(params.numberOfModels > 5) {
    exit 1, "the option numberOfModels must not be greater than 5."
  }
}

if (params.launchAlphaFill){
  File alphaFillDB = new File(params.genomes.alphafill.database)
  params.alphaFillDatabase = alphaFillDB.getCanonicalPath()
}

if (params.launchAlphaFold){
  File alphaFoldDB = new File(params.genomes.alphafold.database)
  params.alphaFoldDatabase = alphaFoldDB.getCanonicalPath()
}

if (params.launchColabFold){
  if (!params.useGpu && !isStubRun){
    exit 1, "ColabFold works only using GPU. Launch the pipeline with the '--useGpu true' option."
  }

  File colabFoldDB = new File(params.genomes.colabfold.database)
  params.colabFoldDatabase = colabFoldDB.getCanonicalPath()
}

if (params.launchDiffDock){
  File diffDockDB = new File(params.genomes.diffdock.database)
  params.diffDockDatabase = diffDockDB.getCanonicalPath()
}

if (params.launchDynamicBind){
  File dynamicBindDB = new File(params.genomes.dynamicbind.database)
  params.dynamicBindDatabase = dynamicBindDB.getCanonicalPath()
}

if (params.launchOpenFold){
  File openFoldDB = new File(params.genomes.openfold.database)
  params.openFoldDatabase = openFoldDB.getCanonicalPath()
}

if (params.launchNanoBert){
  File nanoBertDB = new File(params.genomes.nanobert.database)
  params.nanoBertDatabase = nanoBertDB.getCanonicalPath()
}

if (params.onlyMsas && params.fromMsas != null){
  exit 1, "The --fromMsas option is set with '" + params.fromMsas + "' and --onlyMsas is set to true. Choose either one of these two options."
}

/*
==========================
 BUILD CHANNELS
==========================
*/


fastaPathCh = Channel.fromPath("${params.fastaPath}/*.fasta")

// This allows the processing of msas chain by chain
// in the multimer mode to speedup computation
fastaFilesCh = fastaPathCh
                 .map { fastaFile -> 
                   String protein = fastaFile.toString()
                                      .replaceAll(".*/", "")
                                      .replaceFirst('\\.fasta$', "")
                   tuple(protein, file(fastaFile))
                 }

fastaChainsCh = fastaFilesCh
                  .map { protein, fastaFile ->
                    int nbChain = fastaFile.countFasta()
                    (1..nbChain).collect { chainIdNum ->
                      tuple(protein, file(fastaFile), chainIdNum)
                    }
                  }.collect()
                   .flatten()
                   .collate(3)

// set the msasCh when the pipeline is launched using existing msas
msasCh = Channel.empty()
if(params.fromMsas != null){
  msasCh = createMsasCh('fromMsas', fastaFilesCh)
}

// set the predictionsCh when the pipeline is launched using existing predicted structures
predictionsCh = Channel.empty()
if(params.fromPredictions != null){
  predictionsCh = createPredictionsCh('fromPredictions', fastaFilesCh)
                    .map { tuple(it[0], '', file(file(it[1][0]).getParent())) }

  // rankingCh is not needed if we launch only AlphaFill
  if (!params.launchAlphaFill){
    rankingCh = createRankingCh('fromPredictions', fastaFilesCh)
                  .map {
                         def rankingTsvMonomer = it[1]
                                                   .findAll { fileName ->
                                                              fileName.toString().endsWith('ranking_debug.tsv')
	  																				      					}
                         def rankingTsvMultimer = it[1]
                                                   .findAll { fileName ->
                                                              fileName.toString().endsWith('ranking_debug_multimer.tsv')
	  																				      					}
                         def rankingTsv
                         if (rankingTsvMultimer) {
                           rankingTsv = rankingTsvMultimer
                         } else if (rankingTsvMonomer) {
                           rankingTsv = rankingTsvMonomer
                         } else {
                           error("ERROR: there is no 'ranking_debug.tsv' nor 'ranking_debug_multimer.tsv' file for protein: " + it[0])
                         }

 	  									   tuple(it[0], file(rankingTsv[0]))
                       }
  }

  pdbFileCh = createPdbFileCh('fromPredictions', fastaFilesCh)
                .map { def pdbFile = it[1]
                                       .findAll { fileName ->
                                                  fileName.toString().matches(/.*ranked_.*\.pdb$/)
																								}
                   if (!pdbFile) {
                         error("ERROR: there is no pdb files file for protein: " + it[0])
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
  'Pipeline' : workflow.manifest.name ?: null,
  'Version': workflow.manifest.version ?: null,
  'DOI': workflow.manifest.doi ?: null,
  'Run Name': customRunName,
  'Inputs' : params.fastaPath ?: null,
  'AfMassive Database' : params.launchAfMassive ? params.afMassiveDatabase : null,
  'AfMassive Options' : params.launchAfMassive ? params.afMassiveOptions : null,
  'AlphaFill Database' : params.launchAlphaFill ? params.alphaFillDatabase : null,
  'AlphaFold Database' : params.launchAlphaFold ? params.alphaFoldDatabase : null,
  'AlphaFold Options' : params.launchAlphaFold || params.launchAfMassive ? params.alphaFoldOptions : null,
  'ColabFold Database' : params.launchColabFold ? params.colabFoldDatabase : null,
  'ColabFold Options' : params.launchColabFold ? params.colabFoldOptions : null,
  'DiffDock Database' : params.launchDiffDock ? params.diffDockDatabase : null,
  'DiffDock Options' : params.launchDiffDock ? params.diffDockArgsYamlFile : null,
  'DynamicBind Database' : params.launchDynamicBind ? params.dynamicBindDatabase : null,
  'DynamicBind Options' : params.launchDynamicBind ? params.dynamicBindOptions : null,
  'Use existing msas' : params.fromMsas != null ? params.fromMsas : null,
  'Use existing predictions' : params.fromPredictions != null ? params.fromPredictions : null,
  'Perform only msas' : params.onlyMsas ? "True" : "False",
  'Use GPU' : params.useGpu ? "True" : "False",
  'Max Resources': "${params.maxMemory} memory, ${params.maxCpus} cpus, ${params.maxTime} time per job",
  'Container': workflow.containerEngine && workflow.container ? "${workflow.containerEngine} - ${workflow.container}" : null,
  'Profile' : workflow.profile,
  'OutDir' : params.outDir,
  'WorkDir': workflow.workDir,
  'CommandLine': workflow.commandLine
].findAll{ it.value != null }

workflowSummaryCh = NFTools.summarize(summary, workflow, params)
                      .collectFile(name: "workflow_summary_mqc.yaml", sort: true)

/*
==================================
           INCLUDE
==================================
*/ 

// Processes
include { afMassive } from './nf-modules/local/process/afMassive'
include { afMassiveSearch } from './nf-modules/local/process/afMassiveSearch'
include { afMassiveHelp } from './nf-modules/local/process/afMassiveHelp'
include { alphaFillHelp } from './nf-modules/local/process/alphaFillHelp'
include { alphaFoldHelp } from './nf-modules/local/process/alphaFoldHelp'
include { alphaFold3Help } from './nf-modules/local/process/alphaFold3Help'
include { colabFold } from './nf-modules/local/process/colabFold'
include { colabFoldHelp } from './nf-modules/local/process/colabFoldHelp'
include { colabFoldSearch } from './nf-modules/local/process/colabFoldSearch'
include { dynamicBind } from './nf-modules/local/process/dynamicBind'
include { dynamicBindHelp } from './nf-modules/local/process/dynamicBindHelp'
include { fastaChecker } from './nf-modules/local/process/fastaChecker'
include { getSoftwareOptions } from './nf-modules/common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from './nf-modules/common/process/utils/getSoftwareVersions'
include { massiveFoldPlots } from './nf-modules/local/process/massiveFoldPlots'
include { metricsMultimer } from './nf-modules/local/process/metricsMultimer'
include { pymolPng } from './nf-modules/local/process/pymolPng'

// Subworkflows
include { alphaFillWkfl } from './nf-modules/local/subworkflow/alphaFillWkfl'
include { alphaFoldWkfl } from './nf-modules/local/subworkflow/alphaFoldWkfl'
include { afMassiveWkfl } from './nf-modules/local/subworkflow/afMassiveWkfl'
include { colabFoldWkfl } from './nf-modules/local/subworkflow/colabFoldWkfl'
include { diffDockWkfl } from './nf-modules/local/subworkflow/diffDockWkfl'
include { dynamicBindWkfl } from './nf-modules/local/subworkflow/dynamicBindWkfl'
include { mqcProteinStructWkfl } from './nf-modules/local/subworkflow/mqcProteinStructWkfl'
include { nanoBertWkfl } from './nf-modules/local/subworkflow/nanoBertWkfl'


/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {

  versionsCh = Channel.empty()
  optionsCh = Channel.empty()
  plotsCh = Channel.empty()

  main:

  // ********************************** //
  // *        Prediction models       * //
  // ********************************** //

  // Launch the prediction of the protein 3D structure with AfMassive
  if (params.launchAfMassive){
    afMassiveWkfl(
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh
    )
  }

  // Launch the prediction of the protein 3D structure with AlphaFold
  if (params.launchAlphaFold){
    alphaFoldWkfl(
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh
    )
  }

  // Launch the prediction of the protein 3D structure with ColabFold
  if (params.launchColabFold){
    colabFoldWkfl(
      fastaChainsCh,
      fastaFilesCh,
      fastaPathCh,
      msasCh,
      workflowSummaryCh
    )
  }

  // Launch the molecular docking with DiffDock
  if (params.launchDiffDock){
    diffDockWkfl(proteinLigandCh, params.diffDockDatabase, params.diffDockArgsYamlFile)
  }

  // Launch the molecular docking with DynamicBind
  if (params.launchDynamicBind){
    dynamicBindWkfl(proteinLigandCh, params.dynamicBindDatabase)
  }

  // Launch AlphaFill using existing predicted structure
  if (params.launchAlphaFill && params.fromPredictions != null ){
    alphaFillWkfl(predictionsCh)
  }

  // Launch the nanoBERT predictions
  if (params.launchNanoBert){
    nanoBertWkfl(
      fastaFilesCh,
      fastaPathCh
    )
  }

  // **************************************************************** //
  // * Generate HTML reports from existing predicted pdb structures * //
  // **************************************************************** //

  // Launch the generation of multiqc ProteinStruct HTML reports
  // using existing predicted structure
  // yaml files for multiqc are set to empty
  if (params.htmlProteinStruct && params.fromPredictions != null ){
    massiveFoldPlots(predictionsCh)
    pymolPng(pdbFileCh)
    mqcProteinStructWkfl(
      Channel.of('').collectFile(name: 'software_options_mqc.yaml'),
      Channel.of('').collectFile(name: 'software_versions_mqc.yaml'),
      massiveFoldPlots.out.plots,
      rankingCh,
      pymolPng.out.png,
      fastaFilesCh,
      Channel.of('').collectFile(name: 'empty.txt')
    )
  }


  // *********************************** //
  // * Generate help of different tool * //
  // *********************************** //

  // Generate the help for each tool
  if(params.afMassiveHelp){
    afMassiveHelp()
  }
  if(params.alphaFillHelp){
    alphaFillHelp()
  }
  if(params.alphaFoldHelp){
    alphaFoldHelp()
  }
  if(params.alphaFold3Help){
    alphaFold3Help()
  }
  if(params.colabFoldHelp){
    colabFoldHelp()
  }
  if(params.dynamicBindHelp){
    dynamicBindHelp()
  }
}


workflow.onComplete {
  if(printToolHelp){
    if (params.alphaFillHelp) {
      NFTools.printGreenText("\n\n=====================================\nAlphaFill help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/alphaFillHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nAlphaFill help, see options above.\n=====================================\n")
    }
    if (params.afMassiveHelp) {
      NFTools.printGreenText("\n\n=====================================\nAfMassive help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/afMassiveHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nAfMassive help, see options above.\n=====================================\n")
    }
    if (params.alphaFoldHelp) {
      NFTools.printGreenText("\n\n=====================================\nAlphaFold help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/alphaFoldHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nAlphaFold help, see options above.\n=====================================\n")
    }
    if (params.alphaFold3Help) {
      NFTools.printGreenText("\n\n=====================================\nAlphaFold3 help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/alphaFold3Help.txt")
      NFTools.printGreenText("\n\n=====================================\nAlphaFold3 help, see options above.\n=====================================\n")
    }
    if (params.colabFoldHelp) {
      NFTools.printGreenText("\n\n=====================================\nColabFold help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/colabFoldHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nColabFold help, see options above.\n=====================================\n")
    }
    if (params.dynamicBindHelp) {
      NFTools.printGreenText("\n\n=====================================\nDynamicBind help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/dynamicBindHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nDynamicBind help, see options above.\n=====================================\n")
    }
  } else {
    NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
  }
}
