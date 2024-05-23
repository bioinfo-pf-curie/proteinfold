/*
 * MultiQC for ProteinFold report
 */

process mqcMetricsMultimer {
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/MetricsMultimer/", mode: 'copy', saveAs: { "metrics_multimer.html" }

  input:
  path(metrics) 
  path('softwareOptions/*')
  path('softwareVersions/*')
  path(mqcCfgMetricsMultimer)
            

  output:
  path "*report.html", emit: report

  script:
  """
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Quality metrics of the multimer structure" > mqcCfgHeader.yaml
  cat $mqcCfgMetricsMultimer >> mqcCfgHeader.yaml
  multiqc -n MetricsMultimer_mqc_report.html -c mqcCfgHeader.yaml .
  """    
}
