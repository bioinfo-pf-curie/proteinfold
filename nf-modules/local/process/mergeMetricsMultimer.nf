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

// This process merge all the multimer metrics into a single file
process mergeMetricsMultimer {
  tag "${protein}" 
  label 'onlyLinux'
  label 'minMem'
  label 'minCpu'
  publishDir path: "${params.outDir}/multimerMetrics/${protein}",
             mode: 'copy'

  input:
  tuple val(protein), path(multimerMetrics)

  output:
  tuple val("${protein}"), path("ranking_debug.tsv"), emit: ranking

  script:
  """
  sed -n '1p' \$(ls qc_metrics*tsv | head -1) >  ranking_debug.tsv
  for file in \$(ls -v qc_metrics*.tsv); do sed '1d' \$file >> ranking_debug.tsv; done
  """

}

