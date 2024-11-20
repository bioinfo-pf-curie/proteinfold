/*
 * getSoftwareOptions
 */


process getSoftwareOptions{
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'

  input:
  path options

  output:
  path 'software_options_mqc.yaml', emit: optionsYaml

  when:
  task.ext.when == null || task.ext.when

  script:
  """
  scrape_software_versions.py -i ${options}  --split ' options=' --id 'software_options' --name 'Options' > software_options_mqc.yaml
  """
}

