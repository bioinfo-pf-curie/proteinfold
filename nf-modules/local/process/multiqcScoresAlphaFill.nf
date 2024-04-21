/*
 * MultiQC for AlphaFill scores
 */

process multiqcScoresAlphaFill {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/scoresAlphaFill/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  tuple val(protein), path(tsv), path(multiqcConfigScoresAlphaFill)
            

  output:
  path "*report.html", emit: report

  script:
  """
  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > multiqc-config-header.yaml
  cat $multiqcConfigScoresAlphaFill >> multiqc-config-header.yaml
  multiqc -c multiqc-config-header.yaml .
  """    
}
