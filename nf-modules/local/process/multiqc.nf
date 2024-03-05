/*
 * MultiQC for ProteinFold report
 */

process multiqc {
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
  for plot in \$(ls plots/*.png); do cp \$plot \${plot%%.png}_mqc.png ; done
  apMqcHeader.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > multiqc-config-header.yaml
  multiqc -c "${projectDir}/assets/multiqcConfig.yaml" -c multiqc-config-header.yaml .
  """    
}
