/*
 * MultiQC for diffDock scores
 */

process mqcDiffDock {
  tag "diffDock"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/diffDock/", mode: 'copy'

  input:
  path(scores)
  path(multiqcConfigDiffDock)
  path ('softwareOptions/*')
  path ('softwareVersions/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  ls -al
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Confidence scores for DiffDock" > multiqc-config-header.yaml
  cat $multiqcConfigDiffDock >> multiqc-config-header.yaml
  echo "Name,Protein,Ligand,Rank,Confidence" > header.csv
  cat scores_* > scores.csv
  cat header.csv scores.csv > scores_diffdock.csv 
  multiqc -c multiqc-config-header.yaml .
  """    
}
