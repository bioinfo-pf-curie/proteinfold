/*
 * MultiQC for AlphaFill scores
 */

process mqcAlphaFill {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/scoresAlphaFill/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  tuple val(protein), path(tsv), path(mqcCfgAlphaFill)
            

  output:
  path "*report.html", emit: report

  script:
  """
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > mqcCfgHeader.yaml
  cat $mqcCfgAlphaFill >> mqcCfgHeader.yaml
  multiqc -n AlphaFill_mqc_report.html -c mqcCfgHeader.yaml .
  """    
}
