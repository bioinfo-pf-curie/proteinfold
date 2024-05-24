/*
 * MultiQC for diffDock scores
 */

process mqcDiffDock {
  tag "diffDock"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/DiffDock/", mode: 'copy'

  input:
  path(scores)
  path(mqcCfgDiffDock)
  path ('softwareOptions/*')
  path ('softwareVersions/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Confidence scores for DiffDock" > mqcCfgHeader.yaml
  cat $mqcCfgDiffDock >> mqcCfgHeader.yaml
  echo "name,protein,ligand,rank,confidence" > header.csv
  cat scores_* | grep -v "name,protein,ligand,rank,confidence" > scores.csv
  cat header.csv scores.csv > scores_diffdock.csv 
  multiqc -n diffdock_mqc_report.html -c mqcCfgHeader.yaml .
  """    
}
