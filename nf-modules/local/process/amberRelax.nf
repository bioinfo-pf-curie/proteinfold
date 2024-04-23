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

// Compte the amber relaxtion from a PDB file
process amberRelax {
  tag "${protein}-${toolFold}" 
  label 'afMassive'
  label 'medMem'
  label 'medCpu'
  publishDir path: "${params.outDir}/afMassive/${protein}/",
             mode: 'copy'
  containerOptions { (params.useGpu) ? "--nv --env NVIDIA_VISIBLE_DEVICES=all --env TF_FORCE_UNIFIED_MEMORY=1 --env XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 -B \$PWD:/tmp" : "-B \$PWD:/tmp" }

  input:
  tuple val(protein), val(toolFold), path("predictions/*"), val(model)
  
  output:
  path("amber/*.pdb")

  script:
  """
  mkdir amber
  amber_relax.py --pdb_file=predictions/${protein}/unrelaxed_${model}.pdb --use_gpu_relax=${params.useGpu} --relaxed_pdb_file=amber/relaxed_${model}.pdb
  """

}

