/*
 * MultiQC for ProteinFold report
 */

process mqcProteinStruct {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/proteinStruct/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  tuple val(protein), path('plots/*'), path('ranking_debug.tsv'), path('pymolPng/*'), path('AlphaBridge/*'), path('protein.fasta'), path('softwareVersions/*'), path ('softwareOptions/*'), path ('workflowSummary/*')

  output:
  path "*report.html", emit: report

  script:
  """
  bash ap_generate_yaml_4_plots.sh plots softwareVersions/software_versions_mqc.yaml > mqcCfg.yaml
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > mqcCfgHeader.yaml
  multiqc -n ProteinStruct_mqc_report.html -c mqcCfg.yaml -c mqcCfgHeader.yaml . plots
  """    

}
