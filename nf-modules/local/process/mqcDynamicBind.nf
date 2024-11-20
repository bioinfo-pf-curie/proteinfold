/*
 * MultiQC for dynamicBind scores
*/

process mqcDynamicBind {
  tag "dynamicBind"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/DynamicBind/", mode: 'copy'

  input:
  path(scores)
  path(mqcCfgDynamicBind)
  path ('softwareOptions/*')
  path ('softwareVersions/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Affinity predicted by DynamicBind" > mqcCfgHeader.yaml
  cat $mqcCfgDynamicBind >> mqcCfgHeader.yaml
  echo "name,protein,ligand,affinity" > header_affinity.csv
  cat affinity_* | grep -v "name,protein,ligand,affinity" > affinity.csv
  cat header_affinity.csv affinity.csv > affinity_dynamicbind.csv 
  echo "name,protein,ligand,rank,lddt,affinity" > header_complete_affinity.csv
  cat complete_affinity_* | grep -v "name,protein,ligand,rank,lddt,affinity" > complete_affinity.csv
  cat header_complete_affinity.csv complete_affinity.csv > complete_affinity_dynamicbind.csv 
  multiqc -n dynamicbind_mqc_report.html -c mqcCfgHeader.yaml .
  """    
}
