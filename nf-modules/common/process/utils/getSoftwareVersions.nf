/*
 * getSoftwareVersions
 */


process getSoftwareVersions{
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'

  input:
  path versions

  output:
  path 'software_versions_mqc.yaml', emit: versionsYaml

  when:
  task.ext.when == null || task.ext.when

  script:
  String pipelineVersion = workflow.manifest.version.replaceAll(' ', '')
  """
  echo "Pipeline $pipelineVersion" > all_versions.txt
  echo "Nextflow $workflow.nextflow.version" >> all_versions.txt
  cat ${versions} >> all_versions.txt
  scrape_software_versions.py -i all_versions.txt > software_versions_mqc.yaml
  """
}

