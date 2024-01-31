#! /bin/bash

#SBATCH --mem=6gb
#SBATCH --array=3-4

export PATH=/mnt/beegfs/common/apps/apptainer/apptainer-1.2.2/bin:$PATH
export PATH=/mnt/beegfs/common/apps/nextflow/nextflow-22.10.6:$PATH
PIPELINE_DIR="$HOME/proteinfold/pipeline"
PARAMS_FILE="$( ls ${PIPELINE_DIR}/test/params-file/*.json | sed -n ${SLURM_ARRAY_TASK_ID}p)"
PARAMS_FILE=$(basename ${PARAMS_FILE})
OUT_DIR="$HOME/empt/test/proteinfold/$(basename ${PARAMS_FILE})"

mkdir -p $OUT_DIR
cd $OUT_DIR
cp -r $PIPELINE_DIR/test .
nextflow run ${PIPELINE_DIR}/main.nf -profile singularity,cluster -params-file ${PIPELINE_DIR}/test/params-file/${PARAMS_FILE} --outDir ${OUT_DIR}/results -w ${OUT_DIR}/work --useGpu true
