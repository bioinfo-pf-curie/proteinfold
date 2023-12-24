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
                         proteinfold
========================================================================================
 proteinfold analysis Pipeline.
 #### Homepage / Documentation
 ssh://git@gitlab.curie.fr:2222/phupe/proteinfold.git
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

File file = new File(params.genomes['alphafold'].database)
params.alphaFoldDatabase = file.getCanonicalPath()
System.out.println(params.alphaFoldDatabase)

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
  'Inputs' : params.samplePlan ?: params.reads ?: null,
  'Genome' : params.genome,
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

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {
    main:

    alphaFoldLauncher(fastaFilesCh) | alphaFold

}

workflow.onComplete {
  NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
}
