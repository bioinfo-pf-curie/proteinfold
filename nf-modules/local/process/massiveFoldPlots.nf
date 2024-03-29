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
// It uses the code from https://github.com/GBLille/AfMassive with a minor patch to
// check whether PAEs are available within the picle data
process massiveFoldPlots {
  tag "${protein}-${toolFold}" 
  label 'python'
  label 'lowMem'
  label 'lowCpu'
  publishDir path: "${params.outDir}/${toolFold}Plots/${protein}", mode: 'copy'

  input:
  tuple val(protein), val(toolFold), path("predictions/*")

  output:
  tuple val(protein), path("*.png"), emit: plots

  script:
  """
  massivefold_plots.py --input_path predictions/${protein} --output_path .  --chosen_plots coverage,CF_PAEs,CF_plddts,score_distribution,DM_plddt_PAE --top_n_predictions 5
  """

  stub:
  String toolFoldOptions
  if (toolFold == "afMassive") {
    toolFoldOptions = params["alphaFoldOptions"]
  } else {
    toolFoldOptions = params[toolFold + "Options"]
  }
  """
  echo ${toolFoldOptions}
  if [[ "${toolFoldOptions}" =~ "multimer" ]]; then
    folder="multimer"
  else
    folder="monomer2"
  fi
  tool_fold=${toolFold}
  echo \$tool_fold
  echo "plots"
  cp -r ${projectDir}/test/data/plots/\${tool_fold,,}/\$folder/${protein}/* .
  """
}

