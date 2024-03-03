/*
Copyright Institut Curie 2024

This software is a computer program whose purpose is to
predict 3D structure of proteins.
You can use, modify and/ or redistribute the software under the terms
of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful,
but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards
their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge
of the license and that you accept its terms.

*/

// This process generates the plots from AlphaFold or MassiveFols results:
// It uses the code from https://github.com/GBLille/MassiveFold with a minor patch to
// check whether PAEs are available within the picle data
process massiveFoldPlots {
  tag "${protein}-${toolFold}" 
  label 'massiveFoldPlots'
  label 'lowMem'
  label 'lowCpu'
  publishDir path: "${params.outDir}/${toolFold}Plots/", mode: 'copy'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")

  output:
  path("${protein}", type: 'dir')

  script:
  """
  massivefold_plots.py --input_path predictions/${protein} --output_path ${protein}  --chosen_plots coverage,CF_PAEs,CF_plddts,score_distribution,DM_plddt_PAE --top_n_predictions 5
  """

  stub:
  """
  echo "plots"  
  mkdir ${protein}
  """
}

