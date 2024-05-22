/*
 * MultiQC for dynamicBind scores
*/

process mqcDynamicBind {
  tag "dynamicBind"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/dynamicBind/", mode: 'copy'

  input:
  path(scores)
  path(multiqcConfigDynamicBind)
  path ('softwareOptions/*')
  path ('softwareVersions/*')
            

  output:
  path "*report.html", emit: report

  script:
  """
  ls -al
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition "Confidence scores for DynamicBind" > multiqc-config-header.yaml
  cat $multiqcConfigDynamicBind >> multiqc-config-header.yaml
  echo "name,protein,ligand,affinity" > header_affinity.csv
  cat affinity_*  | grep -v "name,protein,ligand,affinity" > affinity.csv
  cat header_affinity.csv affinity.csv > affinity_dynamicbind.csv 
  echo "name,protein,ligand,rank,lddt,affinity" > header_complete_affinity.csv
  cat complete_affinity_* | grep -v "name,protein,ligand,rank,lddt,affinity" > complete_affinity.csv
  cat header_complete_affinity.csv complete_affinity.csv > complete_affinity_dynamicbind.csv 
  multiqc -c multiqc-config-header.yaml .
  """    
}
