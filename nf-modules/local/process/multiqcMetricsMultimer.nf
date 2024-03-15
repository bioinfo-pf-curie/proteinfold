/*
 * MultiQC for ProteinFold report
 */

process multiqcMetricsMultimer {
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqcMetricsMultimer/", mode: 'copy'

  input:
  path(metrics) 
  path('softwareOptions/*')
  path('softwareVersions/*')
  path(multiqcConfigMetricsMultimer)
            

  output:
  path "*report.html", emit: report

  script:
  """
  apMqcHeader.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Quality metrics of the multimer structure" > multiqc-config-header.yaml
  cat $multiqcConfigMetricsMultimer >> multiqc-config-header.yaml
  multiqc -c multiqc-config-header.yaml .
  """    
}
