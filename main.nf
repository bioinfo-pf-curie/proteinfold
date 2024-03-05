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

/*
===================================
  SET UP CONFIGURATION VARIABLES
===================================
*/

// Define a variable to track settings for which the fastaPath can be null
Boolean allowFastaPathNull = false

// Check that any option to print the help of a tool has been set to true
Boolean printToolHelp = false
if (params.collect().join(' ').find('Help=true')) {
  printToolHelp = true
  allowFastaPathNull = true
}

// DynamicBind does not require fastaPath
// but it requires a proteinLigandFile
if(params.launchDynamicBind) {
  allowFastaPathNull = true
  if(params.proteinLigandFile == null) {
    exit 1, "To launch DynamicBind you must define the --proteinLigandFile option"
  }
  if (!params.useGpu){
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
if (params.launchAlphaFold){
  File alphaFoldDB = new File(params.genomes.alphafold.database)
  params.alphaFoldDatabase = alphaFoldDB.getCanonicalPath()
}

if (params.launchDynamicBind){
  File dynamicBindDB = new File(params.genomes.dynamicbind.database)
  params.dynamicBindDatabase = dynamicBindDB.getCanonicalPath()
}

if (params.launchColabFold){
  if (!params.useGpu){
    exit 1, "ColabFold works only using GPU. Launch the pipeline with the '--useGpu true' option."
  }

  File colabFoldDB = new File(params.genomes.colabfold.database)
  params.colabFoldDatabase = colabFoldDB.getCanonicalPath()
}

if (params.launchOpenFold){
  File openFoldDB = new File(params.genomes.openfold.database)
  params.openFoldDatabase = openFoldDB.getCanonicalPath()
}

if (params.launchMassiveFold){
  File massiveFoldDB = new File(params.genomes.massivefold.database)
  params.massiveFoldDatabase = massiveFoldDB.getCanonicalPath()
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
                                      .replaceAll(".fasta", "")
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
if(params.fromMsas != null){

  File fromMsas = new File(params.fromMsas)
  if (!fromMsas.exists()){
    exit 1, "The path to the msas folder '" + params.fromMsas + "' does not exist."
  }
  if (!fromMsas.isDirectory()){
    exit 1, "The path to the msas folder '" + params.fromMsas + "' is not a directory."
  }

  msasCh = Channel.fromPath("${params.fromMsas}/*", type: 'dir')
                .map { msas -> 
                  String protein = msas.toString()
                                    .replaceAll(".*/", "")
                  File proteinMsasDir = new File("${params.fromMsas}/${protein}")
                  msasFileList = [] 
                  proteinMsasDir.eachFile {file -> msasFileList.add(file.getAbsolutePath())}
                  tuple(protein, msasFileList)
                }
 
  proteinInMsas = msasCh.map { it[0]}.collect().map { tuple ('list', it) }
  proteinInFasta = fastaFilesCh.map { it[0]}.collect().map { tuple ('list', it) }
  proteinUnion = proteinInMsas.join(proteinInFasta)


  // Print warning if the msas is present but not the fasta file  
  proteinUnion
    .map{
      elementsNotPresent(it[2].toList(), it[1].toList())
        .each{ prot ->
                 String msg
                 msg = "WARNING - MSAS folder is present but not FASTA file available for protein '"
                 msg = msg + prot + "'. The protein will be ignored."
                 NFTools.printOrangeText(msg)
        }
    }
    
  // Print warning if the fasta file is present but not the msas folder
  proteinUnion
    .map{
      elementsNotPresent(it[1].toList(), it[2].toList())
        .each{ prot ->
          String msg
          msg = "WARNING - FASTA file is present but no MSAS folder available for protein '"
          msg = msg + prot + "'. The protein will be ignored."
          NFTools.printOrangeText(msg)
        }
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
  'AlphaFold Options' : params.launchAlphaFold || params.launchMassiveFold ? params.alphaFoldOptions : null,
  'ColabFold Database' : params.launchColabFold ? params.colabFoldDatabase : null,
  'ColabFold Options' : params.launchColabFold ? params.colabFoldOptions : null,
  'DynamicBind Database' : params.launchDynamicBind ? params.dynamicBindDatabase : null,
  'DynamicBind Options' : params.launchDynamicBind ? params.dynamicBindOptions : null,
  'MassiveFold Database' : params.launchMassiveFold ? params.massiveFoldDatabase : null,
  'MassiveFold Options' : params.launchMassiveFold ? params.massiveFoldOptions : null,
  'Use existing msas' : params.fromMsas != null ? params.fromMsas : null,
  'Perform only msas' : params.onlyMsas,
  'Use GPU' : params.useGpu,
  'Max Resources': "${params.maxMemory} memory, ${params.maxCpus} cpus, ${params.maxTime} time per job",
  'Container': workflow.containerEngine && workflow.container ? "${workflow.containerEngine} - ${workflow.container}" : null,
  'Profile' : workflow.profile,
  'OutDir' : params.outDir,
  'WorkDir': workflow.workDir,
  'CommandLine': workflow.commandLine
].findAll{ it.value != null }

workflowSummaryCh = NFTools.summarize(summary, workflow, params)

/*
==================================
           INCLUDE
==================================
*/ 

// Processes
include { getSoftwareOptions } from './nf-modules/common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from './nf-modules/common/process/utils/getSoftwareVersions'
include { alphaFold } from './nf-modules/local/process/alphaFold'
include { alphaFoldHelp } from './nf-modules/local/process/alphaFoldHelp'
include { alphaFoldOptions } from './nf-modules/local/process/alphaFoldOptions'
include { alphaFoldSearch } from './nf-modules/local/process/alphaFoldSearch'
include { colabFold } from './nf-modules/local/process/colabFold'
include { colabFoldHelp } from './nf-modules/local/process/colabFoldHelp'
include { colabFoldSearch } from './nf-modules/local/process/colabFoldSearch'
include { dynamicBind } from './nf-modules/local/process/dynamicBind'
include { dynamicBindHelp } from './nf-modules/local/process/dynamicBindHelp'
include { fastaChecker } from './nf-modules/local/process/fastaChecker'
include { massiveFold } from './nf-modules/local/process/massiveFold'
include { massiveFoldSearch } from './nf-modules/local/process/massiveFoldSearch'
include { massiveFoldHelp } from './nf-modules/local/process/massiveFoldHelp'
include { massiveFoldPlots } from './nf-modules/local/process/massiveFoldPlots'
include { multiqc } from './nf-modules/local/process/multiqc'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {

  versionsCh = Channel.empty() 
  optionsCh = Channel.empty() 

  main:

  // Launch the prediction of the protein 3D structure with AlphaFold
  if (params.launchAlphaFold){
    fastaChecker(fastaPathCh)
    alphaFoldOptions(params.alphaFoldOptions, params.alphaFoldDatabase)
    if (params.onlyMsas){
      alphaFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
      versionsCh = versionsCh.mix(alphaFoldSearch.out.versions)
      optionsCh = optionsCh.mix(alphaFoldSearch.out.options)
    } else {
      if (params.fromMsas != null){
        msasCh = fastaFilesCh.join(msasCh)
      } else {
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
      alphaFold(msasCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
      versionsCh = versionsCh.mix(alphaFold.out.versions)
      optionsCh = optionsCh.mix(alphaFold.out.options)
      massiveFoldPlots(alphaFold.out.predictions)
      plotsCh = massiveFoldPlots.out.plots
    }
  }

  // Launch the molecular docking with DynamicBind
  if (params.launchDynamicBind){
    dynamicBind(proteinLigandCh, params.dynamicBindDatabase)
  }

  // Launch the prediction of the protein 3D structure with ColabFold
  if (params.launchColabFold){
    fastaChecker(fastaPathCh)
    if (params.onlyMsas){
      colabFoldSearch(fastaFilesCh, params.colabFoldDatabase)
    } else {
      if (params.fromMsas == null){
        colabFoldSearch(fastaFilesCh, params.colabFoldDatabase)
        msasCh = colabFoldSearch.out.msas
      }
      colabFold(msasCh, params.colabFoldDatabase)
    }
  }


  // Launch the prediction of the protein 3D structure with MassiveFold
  if (params.launchMassiveFold){
    fastaChecker(fastaPathCh)
    // massiveFold is alphaFold-like, it uses alphaFold's options too
    alphaFoldOptions(params.alphaFoldOptions, params.massiveFoldDatabase)
    if (params.onlyMsas){
      massiveFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.massiveFoldDatabase)
      versionsCh = versionsCh.mix(massiveFoldSearch.out.versions)
      optionsCh = optionsCh.mix(massiveFoldSearch.out.options)
    } else {
      if (params.fromMsas != null){
        msasCh = fastaFilesCh.join(msasCh)
      } else {
        massiveFoldSearch(fastaChainsCh, alphaFoldOptions.out.alphaFoldOptions, params.massiveFoldDatabase)
        versionsCh = versionsCh.mix(massiveFoldSearch.out.versions)
        optionsCh = optionsCh.mix(massiveFoldSearch.out.options)
        msasCh = massiveFoldSearch.out.msas
                   .groupTuple()
                   .map { it ->
                     it[1] = it[1].flatten()
                     it
                   }
        msasCh = fastaFilesCh.join(msasCh)
      }
      massiveFold(msasCh, alphaFoldOptions.out.alphaFoldOptions, params.massiveFoldDatabase)
      versionsCh = versionsCh.mix(massiveFold.out.versions)
      optionsCh = optionsCh.mix(massiveFold.out.options)
      massiveFoldPlots(massiveFold.out.predictions)
    }
  }
  
  // MULTIQC
  getSoftwareVersions(versionsCh.unique().collectFile())
  getSoftwareOptions(optionsCh.unique().collectFile())
  multiqc(
    plotsCh
      .combine(getSoftwareVersions.out.versionsYaml.collect().ifEmpty([])),
    plotsCh
      .map {
        it[0]
      }
      .combine(workflowSummaryCh.collectFile(name: "workflow_summary_mqc.yaml")),
    plotsCh
      .map {
        it[0]
      }
      .combine(getSoftwareOptions.out.optionsYaml.collect().ifEmpty([]))
  )

  // Generate the help for each tool
  if(params.alphaFoldHelp){
    alphaFoldHelp()
  }
  if(params.colabFoldHelp){
    colabFoldHelp()
  }
  if(params.dynamicBindHelp){
    dynamicBindHelp()
  }
  if(params.massiveFoldHelp){
    massiveFoldHelp()
  }
}


workflow.onComplete {
  if(printToolHelp){
    if (params.alphaFoldHelp) {
      NFTools.printGreenText("\n\n=====================================\nAlphaFold help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/alphaFoldHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nAlphaFold help, see options above.\n=====================================\n")
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
    if (params.massiveFoldHelp) {
      NFTools.printGreenText("\n\n=====================================\nMassiveFold help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/massiveFoldHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nMassiveFold help, see options above.\n=====================================\n")
    }
  } else {
    NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
  }
}
