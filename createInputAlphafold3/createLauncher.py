import glob
import os
from pathlib import Path
from createInputAlphafold3.merge import create_output_dir

def create_launcher(input_dir: str, server_path: str, nextflow_path: str, output_dir: str) -> None:
    """
   Generates Nextflow launch SLURM scripts for each parameter file found.

    Args:
        input_dir (str): Folder containing subfolders with parameter files.
        server_path (str): Path to the server-side files (used in the script).
        nextflow_path (str): Path to the Nextflow executable.
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
            f.write("""\
#! /bin/bash
#SBATCH -A kci@cpu
#SBATCH -c 3
#SBATCH -t 05:00:00
set -oeu pipefail

module load openjdk/11.0.2
module load singularity/3.8.5

export MEM_GIGA_PER_CORE=4

""")
            f.write(f"export PATH={nextflow_path}:$PATH\n\n")
            f.write(
                f"NXF_DISABLE_CHECK_LATEST=true nextflow run {os.path.join(server_path, "main.nf")} "
                "-profile singularity,cluster "
                f"-params-file {os.path.join(server_path, param_file)} "
                "-process.clusterOptions '-A kci@cpu' "
                "--useGpu true\n"
            )
