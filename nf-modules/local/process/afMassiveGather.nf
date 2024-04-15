
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

process afMassiveGather {
  tag "${protein}"
  label 'afMassive'
  label 'minMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/afMassive/",
             mode: 'copy',
             saveAs: { it.replaceAll('predictions/', '') }

  input:
  tuple val(protein), val(toolFold), path('predictions_parallel/*')

  output:
  tuple val(protein), val("afMassive"), path("predictions/*", type: 'dir'), emit: predictions
  tuple val(protein), path("predictions/${protein}/ranking_best.txt"), emit: best
  tuple val(protein), path("predictions/${protein}/ranking_debug.tsv"), emit: ranking

  script:
  """
  mkdir -p predictions/${protein}
  cd predictions_parallel
  gather_predictions.py --predictions_path=.
  cp \$(ls features*.pkl | head -1) ../predictions/${protein}/features.pkl
  cp ranking_debug.json ../predictions/${protein}/
  cp ranking_debug.tsv ../predictions/${protein}/
  cp ranking_best.txt ../predictions/${protein}/
  for pdb in \$(ls *.pdb); do ln -s \$(realpath \${pdb}) ../predictions/${protein}/\${pdb}; done
  for pkl in \$(ls result*.pkl); do ln -s \$(realpath \${pkl}) ../predictions/${protein}/\${pkl}; done
  """
}

