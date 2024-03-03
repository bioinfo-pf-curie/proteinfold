/*
 * MultiQC for ProteinFold report
 */

process multiqc {
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'

  input:
  path multiqcConfig

  output:
  path "*report.html", emit: report

  script:
  """
  #mqc_header.py --name "RNA-seq" --version ${workflow.manifest.version} ${metadataOpts} ${splanOpts} --nbreads \${medianReadNb} ${warn} > multiqc-config-header.yaml
  #multiqc . -f $rtitle $rfilename -c $multiqcConfig -c multiqc-config-header.yaml $modulesList
  """    
}
