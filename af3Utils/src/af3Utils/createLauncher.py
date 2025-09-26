import glob
import os
from pathlib import Path
from af3Utils.merge import create_output_dir


def create_launcher(
    input_dir: str,
    pipeline_dir: str,
    server_path: str,
    nextflow_path: str,
    singularity_path: str,
    java_path: str,
    queue_cpu: str,
    account_gpu: str,
    queue_gpu: str,
    genome_path: str,
    singularity_img: str,
    output_dir: str,
) -> None:
    """
    Generates Nextflow launch SLURM scripts for each parameter file found.

     Args:
         input_dir (str): Folder containing subfolders with parameter files.
         pipeline_dir (str): Path to the proteinFold pipeline directory
         server_path (str): Path to the server-side files (used in the script).
         nextflow_path (str): Path to the Nextflow executable.
         singularity_path (str): Path to the Singularity executable.
         java_path (str): Path to the Java executable.
         queue_cpu (str): Queue cpu (partition).
         account_gpu (str): Account gpu.
         queue_gpu (str): Queue gpu (partition).
         genome_path (str): Path to the annotation for proteinFold
         singularity_img (str): Path to the singularity images for proteinFold
         output_dir (str): Folder where SLURM scripts will be generated.
    """
    # Recherche récursive de tous les fichiers dans des sous-dossiers `params-file`
    params_files = glob.glob(os.path.join(input_dir, "**", "params-file", "*"), recursive=True)

    # Crée le dossier `launcher` dans le répertoire de sortie
    create_output_dir(output_dir, "", "launcher")

    for param_file in params_files:
        file_name = Path(param_file).stem  # nom sans extension
        launcher_path = Path(output_dir) / "launcher" / f"{file_name}.sh"

        with open(launcher_path, "w") as f:
            f.write(f"""\
#! /bin/bash
#SBATCH --partition={queue_cpu}
#SBATCH --mem=20G
#SBATCH -t 20:00:00
set -oeu pipefail

export JAVA_CMD={Path(java_path)}/java
export JAVA_HOME={Path(java_path)}
export PATH={Path(singularity_path)}
export MEM_GIGA_PER_CORE=4
export PATH={Path(nextflow_path)}
export MEM_GIGA_PER_CORE=4

""")

            f.write(f"""\

PIPELINE_DIR="{Path(pipeline_dir)}"
OUTDIR="{Path(server_path)}/{file_name}/results"
WORKDIR="{Path(server_path)}/{file_name}/work"
""")
            f.write("""\
mkdir -p ${OUTDIR}
mkdir -p ${WORKDIR}
export JAVA_OPTS="-Xmx100g -Xms10g"

""")
            f.write(f"""\
NXF_DISABLE_CHECK_LATEST=true nextflow run ${{PIPELINE_DIR}}/main.nf -profile singularity,cluster -params-file  {param_file} --queue "{queue_cpu}" --useGpu true --executor.gpu.slurm "--nodes=1 --partition={queue_gpu} --account={account_gpu} --gres=gpu:1" --outDir ${{OUTDIR}} -w ${{WORKDIR}} --singularityImagePath "{Path(singularity_img)}" --genomeAnnotationPath "{Path(genome_path)}"

""")
