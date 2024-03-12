/*
 * MultiQC for ProteinFold report
 */

process multiqc {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  //path multiqcConfig
  tuple val(protein), path('plots/*'), path ('softwareVersions/*')
  tuple val(protein), path ('softwareOptions/*')
  tuple val(protein), path ('workflowSummary/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  bash generate_yaml_4_plots.sh plots > multiqcConfig.yaml
  apMqcHeader.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > multiqc-config-header.yaml
  multiqc -c multiqcConfig.yaml -c multiqc-config-header.yaml . plots
  """    
}
