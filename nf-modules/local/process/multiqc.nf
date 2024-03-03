/*
 * MultiQC for ProteinFold report
 */

process multiqc {
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'

  input:
  //path multiqcConfig
  tuple val(protein), path('plots/*'), path ('softwareVersions/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  for plot in \$(ls plots/*.png); do cp \$plot \${plot%%.png}_mqc.png ; done
  multiqc -c "${projectDir}/assets/multiqcConfig.yaml" .
  """    
}
