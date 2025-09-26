import argparse

from af3Utils.clean import cmd_clean
from af3Utils.verification import cmd_verif
from af3Utils.selection import cmd_select
from af3Utils.list import display_json
from af3Utils.merge import cmd_merge


def build_parser() -> argparse.ArgumentParser:
    """
    Parse command-line arguments for the jsonCreator tool.

    Returns:
        argparse.Namespace: The parsed arguments with values for the selected command.
    """
    parser = argparse.ArgumentParser(
        prog="af3_tools",
        description="AlphaFold3 utils : nettoyer les fichiers ranked_* (version simplifiée).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Verboser les logs.")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # list command
    list_parser = subparsers.add_parser("list", help="Display all available JSON files.")
    list_parser.add_argument(
        "directory", nargs="?", default="./fasta", help="Folder containing JSON files."
    )
    list_parser.set_defaults(func=display_json)

    # merge command
    merge_parser = subparsers.add_parser(
        "merge", help="Combine multiple fasta files into a JSON file."
    )
    merge_parser.add_argument(
        "sample_plan", nargs="?", help="CSV file with proteins separated by commas."
    )
    merge_parser.add_argument("--protein", help="List of proteins separated by commas.")
    merge_parser.add_argument(
        "--seeds",
        "-s",
        required=True,
        type=int,
        nargs="+",
        help="List of random seeds (space-separated integers).",
    )
    merge_parser.add_argument(
        "--input", "-i", default="./fasta", help="Input folder with JSON files."
    )
    merge_parser.add_argument(
        "--output", "-o", default="./inputFile", help="Output folder for results."
    )
    merge_parser.add_argument(
        "--model_dir",
        default="/lustre/fswork/.../alphafold3/params",
        help="Path to AlphaFold model directory.",
    )
    merge_parser.add_argument(
        "--server_path", default=".", help="Path to input files on the server."
    )
    merge_parser.set_defaults(func=cmd_merge)

    # launcher command
    launcher_parser = subparsers.add_parser("launcher", help="Create SLURM launcher script.")

    launcher_parser.add_argument(
        "--input", "-i", default=".", help="Input folder containing param files."
    )

    launcher_parser.add_argument(
        "--pipeline_dir",
        default="/mnt/beegfs/RECHERCHE/u900pf-bioinfo/common/pipelines/cubicpipes/dev/proteinfold/pipeline/",
        help="Path to the proteinFold pipeline directory",
    )

    launcher_parser.add_argument("--server_path", default=".", help="Server path to input files.")

    launcher_parser.add_argument(
        "--nextflow_path",
        default="/mnt/beegfs/common/apps/nextflow/nextflow-24.10.4",
        help="Path to Nextflow executable.",
    )

    launcher_parser.add_argument(
        "--singularity_path",
        default="/mnt/beegfs/common/apps/singularity/singularity-3.8.5/bin",
        help="Path to Singularity executable.",
    )

    launcher_parser.add_argument(
        "--java_path",
        default="/usr/lib/jvm/java-24-openjdk/bin",
        help="Path to java executable.",
    )

    launcher_parser.add_argument(
        "--queue_cpu", default="recherche_batch", help="Queue cpu (partition)"
    )

    launcher_parser.add_argument("--account_gpu", default="dev_gpu", help="Account gpu")

    launcher_parser.add_argument("--queue_gpu", default="batch_gpu", help="Queue gpu (partition)")

    launcher_parser.add_argument(
        "--genome_path",
        default="/mnt/beegfs/common/annotations/pipelines_CDR",
        help="Path to the annotation for proteinFold",
    )

    launcher_parser.add_argument(
        "--singularity_img",
        default="/mnt/beegfs/RECHERCHE/u900pf-bioinfo/common/pipelines/cubicpipes/dev/proteinfold/singularity/images",
        help="Path to the singularity images for proteinFold",
    )

    launcher_parser.add_argument(
        "--output", "-o", default="./inputFile", help="Output folder for launcher."
    )

    p_clean = subparsers.add_parser(
        "clean",
        help="Garder les N meilleures structures et supprimer le reste.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p_clean.add_argument(
        "-i", "--input", required=True, help="Dossier racine contenant les projets."
    )
    p_clean.add_argument(
        "-k",
        "--keep",
        type=int,
        default=5,
        help="Nombre de meilleurs rangs à garder (0..keep-1).",
    )
    p_clean.add_argument(
        "--dry-run", action="store_true", help="Ne supprime rien, affiche seulement."
    )
    p_clean.set_defaults(func=cmd_clean)

    # --- verification subcommand ---
    p_verif = subparsers.add_parser(
        "verif",
        help="Verification for all the execution in a plan.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p_verif.add_argument(
        "-i", "--input", required=True, help="Dossier racine contenant les projets."
    )
    p_verif.add_argument("-s", "--samplePlan", required=True, help="CVS sample Plan")
    p_verif.add_argument("-o", "--output", help="Fichier TSV de sortie.")
    p_verif.set_defaults(func=cmd_verif)

    # --- select subcommand ---
    p_select = subparsers.add_parser(
        "select",
        help="Agrège iptm/ptm par run et filtre sur un seuil iptm.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p_select.add_argument(
        "-i", "--input", required=True, help="Dossier racine contenant les projets."
    )
    p_select.add_argument("-o", "--output", required=True, help="Fichier TSV de sortie.")
    p_select.add_argument(
        "--iptm-threshold",
        type=float,
        default=0.5,
        help="Seuil de sélection sur iptm (>= seuil).",
    )
    p_select.add_argument(
        "--ptm-threshold",
        type=float,
        default=0,
        help="Seuil de sélection sur iptm (>= seuil).",
    )
    p_select.add_argument(
        "--pattern",
        type=str,
        default=r"^seed[_-]\d+[_-]sample[_-]\d+$",
        help="Regex des sous-dossiers seed/sample.",
    )
    p_select.set_defaults(func=cmd_select)

    return parser
