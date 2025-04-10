
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

process alphaFold3Gather {
  tag "${protein}"
  label 'python'
  label 'minMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/alphaFold3/",
             mode: 'copy',
             saveAs: { it.replaceAll('predictions/', '') }

  input:
  tuple val(protein), val(toolFold), path('predictions_parallel/*'), path(fastaFileJson)

  output:
  tuple val(protein), val("alphaFold3"), path("predictions/*", type: 'dir'), emit: predictions
  tuple val(protein), path("predictions/${protein}/ordered_ranking_scores.tsv"), emit: ranking
  tuple val(protein), path("predictions/${protein}/ranked_*.cif"), emit: pdb

  script:
  """
  mkdir -p predictions/${protein}
  protein_lowercase=\$(echo ${protein} | tr '[:upper:]' '[:lower:]')
  mv ${protein}.json predictions/${protein}/\${protein_lowercase}_data.json
  cp -rf predictions_parallel/* predictions/${protein}
  
  
  awk '(NR == 1) || (FNR > 1)' predictions_parallel/ranking_scores*.csv > predictions/${protein}/ranking_scores.csv
  cd predictions/${protein}

  mv "\$(ls TERMS_OF_USE_seed_* | head -n 1)" 'TERMS_OF_USE.md'
  find . -name '*_seed_*' -exec rm {} +
  ap_format_ranking_alphafold3.py --input_file ranking_scores.csv --output_file ordered_ranking_scores.tsv --cif_dir .
  best=\$(awk 'NR==2 {print \$2}' ordered_ranking_scores.tsv)
  if [ -n "\$best" ]; then
    for file in \${best}/*; do
      filename=\$(basename "\$file")
      cp "\$file" "./\${protein_lowercase}_\${filename}"
    done
  fi
  """
}
