/*
 * MultiQC for nanoBERT scores
 */

process multiqcScoresNanoBert {
  tag "${protein}"
  label 'multiqc'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/multiqc/scoresNanoBert/", mode: 'copy', saveAs: { "${protein}.html" }

  input:
  tuple val(protein), path("nanobert"), path(multiqcConfigScoresNanoBert)
            

  output:
  path "*report.html", emit: report

  script:
  """
  cat << EOF > scores_nanobert_plot_mqc.yaml
  id: 'scores_nanobert_plot'
  parent_id: scores_nanobert
  section_name: 'Plot'
  description: 'nanoBERT scores along the protein sequence.'
  plot_type: 'scatter'
  pconfig:
      id: 'nanobert_scores_scatter_plot'
      title: 'nanoBERT scores'
      ylab: 'Probability'
      xlab: 'Position'
      ymin: 0
      ymax: 1.05
  EOF
  cat nanobert/nanobert_scores.yaml >> scores_nanobert_plot_mqc.yaml

  cat << EOF > scores_human_heavy_plot_mqc.yaml
  id: 'scores_human_heavy_plot'
  parent_id: scores_human_heavy
  section_name: 'Plot'
  description: 'human_heavy scores along the protein sequence.'
  plot_type: 'scatter'
  pconfig:
      id: 'human_heavy_scores_scatter_plot'
      title: 'human_heavy scores'
      ylab: 'Probability'
      xlab: 'Position'
      ymin: 0
      ymax: 1.05
  EOF
  cat nanobert/human_heavy_scores.yaml >> scores_human_heavy_plot_mqc.yaml

  ap_mqc_header.py --name "ProteinFold" --version "${workflow.manifest.version}" --condition ${protein} > multiqc-config-header.yaml
  cat $multiqcConfigScoresNanoBert >> multiqc-config-header.yaml
  multiqc -c multiqc-config-header.yaml .
  """    
}
