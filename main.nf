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

// Check that any option to print the help of any tool is set to true
Boolean printToolHelp = false
if (params.collect().join(' ').find('Help=true')) {
  printToolHelp = true
}

// Check that the option --fastaPath has been provided and contains the path to the fasta files
if (params.fastaPath != null ) {
  System.out.println('has a value')
  File fastaPath = new File(params.fastaPath)
  if (!fastaPath.exists()){
    exit 1, "ERROR: the path to the fasta file(s) '" + params.fastaPath + "' does not exist."
  }
  if (!fastaPath.isDirectory()){
    exit 1, "ERROR: the path to the fasta file(s) '" + params.fastaPath + "' is not a directory."
  }
} else {
  if (!printToolHelp) {
    exit 1, "ERROR: the fastaPath options is 'null'. Provide a value using the --fastaPath options."
  }
}

// Check that alphaFoldOptions defines max_template_date=YYYY-MM-DD
if (!params.alphaFoldOptions.find("--max_template_date=(?:\\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])")){
  exit 1, "ERROR: 'params.alphaFoldOptions' must define '--max_template_date=YYYY-MM-DD', e.g.: '--max_template_date=2024-01-01'"
}

// Get realpath for the annotations to avoid symlink issues in bindings with apptainer
if (params.launchAlphaFold){
  File alphaFoldDB = new File(params.genomes.alphafold.database)
  params.alphaFoldDatabase = alphaFoldDB.getCanonicalPath()
}

if (params.launchColabFold){
  if (!params.useGpu){
    exit 1, "ERROR: ColabFold works only using GPU. Launch the pipeline with the '--useGpu true' option."
  }

File colabFoldDB = new File(params.genomes.colabfold.database)
params.colabFoldDatabase = colabFoldDB.getCanonicalPath()
}

if (params.launchMassiveFold){
  File massiveFoldDB = new File(params.genomes.massivefold.database)
  params.massiveFoldDatabase = massiveFoldDB.getCanonicalPath()
}

/*
==========================
 BUILD CHANNELS
==========================
*/

fastaFilesCh = Channel.fromPath("${params.fastaPath}/*.fasta")

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
  'MassiveFold Database' : params.launchMassiveFold ? params.massiveFoldDatabase : null,
  'MassiveFold Options' : params.launchMassiveFold ? params.massiveFoldOptions : null,
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
include { alphaFold } from './nf-modules/local/process/alphaFold'
include { alphaFoldHelp } from './nf-modules/local/process/alphaFoldHelp'
include { alphaFoldOptions } from './nf-modules/local/process/alphaFoldOptions'
include { alphaFoldSearch } from './nf-modules/local/process/alphaFoldSearch'
include { colabFold } from './nf-modules/local/process/colabFold'
include { colabFoldHelp } from './nf-modules/local/process/colabFoldHelp'
include { colabFoldSearch } from './nf-modules/local/process/colabFoldSearch'
include { fastaChecker } from './nf-modules/local/process/fastaChecker'
include { massiveFold } from './nf-modules/local/process/massiveFold'
include { massiveFoldSearch } from './nf-modules/local/process/massiveFoldSearch'
include { massiveFoldHelp } from './nf-modules/local/process/massiveFoldHelp'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {
  main:

  // Check the format of the fasta files
  fastaChecker(fastaFilesCh)

  // Launch the prediction of the protein 3D structure
  if (params.launchAlphaFold){
    alphaFoldOptions(params.alphaFoldOptions, params.alphaFoldDatabase)
    alphaFoldSearch(fastaFilesCh, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
    alphaFold(alphaFoldSearch.out.msas, alphaFoldSearch.out.fastaFile, alphaFoldOptions.out.alphaFoldOptions, params.alphaFoldDatabase)
  }
  if (params.launchColabFold){
    colabFoldSearch(fastaFilesCh, params.colabFoldDatabase)
    colabFold(colabFoldSearch.out.msas, params.colabFoldDatabase)
  }
  if (params.launchMassiveFold){
    // massiveFold is alphaFold-like, it uses alphaFold's options too
    alphaFoldOptions(params.alphaFoldOptions, params.massiveFoldDatabase)
    massiveFoldSearch(fastaFilesCh, alphaFoldOptions.out.alphaFoldOptions, params.massiveFoldDatabase)
    massiveFold(massiveFoldSearch.out.msas, massiveFoldSearch.out.fastaFile, alphaFoldOptions.out.alphaFoldOptions, params.massiveFoldDatabase)
  }

  // Generate the help for each tool
  if(params.alphaFoldHelp){
    alphaFoldHelp()
  }
  if(params.colabFoldHelp){
    colabFoldHelp()
  }
  if(params.massiveFoldHelp){
    massiveFoldHelp()
  }
}

// Function to print the help of the tools
def printFileContent(file) {
    def inputFile = new File(file)
    
    if (inputFile.exists()) {
        inputFile.eachLine { line ->
            println line
        }
    } else {
        System.out.println("File not found: $file")
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
    if (params.massiveFoldHelp) {
      NFTools.printGreenText("\n\n=====================================\nMassiveFold help, list of options:\n=====================================\n")
      printFileContent("${params.outDir}/massiveFoldHelp.txt")
      NFTools.printGreenText("\n\n=====================================\nMassiveFold help, see options above.\n=====================================\n")
    }
  } else {
    NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
  }
}
