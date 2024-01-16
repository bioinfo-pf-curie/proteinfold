#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2020-2023
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data. 
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.
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

// Check that the option --fastaPath has been provided and contains the path to the fasta files
if (params.fastaPath == null | params.fastaPath.getClass().toString().contains('Boolean')){
  exit 1, "ERROR: provide the path to the fasta file(s)."
}

// Check that alphaFoldOptions defines max_template_date=YYYY-MM-DD
if (!params.alphaFoldOptions.find("max_template_date=(?:\\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])")){
  exit 1, "ERROR: '--alphaFoldOptions' must define 'max_template_date=YYYY-MM-DD', e.g.: --alphaFoldOptions 'max_template_date=2024-01-01'"
}

// Get realpath for the annotations to avoid symlink issues in bindings with apptainer
File alphaFoldDB = new File(params.genomes['alphafold'].database)
params.alphaFoldDatabase = alphaFoldDB.getCanonicalPath()


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
  'AlphaFold Database' : params.alphaFoldDatabase,
  'AlphaFold Options' : params.alphaFoldOptions,
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
include { alphaFoldLauncher } from './nf-modules/local/process/alphaFoldLauncher'
include { alphaFold } from './nf-modules/local/process/alphaFold'
include { fastaChecker } from './nf-modules/local/process/fastaChecker'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {
    main:

    fastaChecker(fastaFilesCh)
    alphaFoldLauncher(fastaFilesCh) | alphaFold

}

workflow.onComplete {
  NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
}
