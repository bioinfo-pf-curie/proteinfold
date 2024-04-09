/*
 * MultiQC for ProteinFold report
 */

process multiqcProteinStruct {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/proteinStruct/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  tuple val(protein), path('plots/*'), path ('softwareVersions/*')
  tuple val(protein), path ('softwareOptions/*')
  tuple val(protein), path ('workflowSummary/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  bash generate_yaml_4_plots.sh plots softwareVersions/software_versions_mqc.yaml > multiqcConfig.yaml
  apMqcHeader.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > multiqc-config-header.yaml
  multiqc -c multiqcConfig.yaml -c multiqc-config-header.yaml . plots
  """    

}
