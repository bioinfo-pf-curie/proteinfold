import argparse

def parse_args() -> argparse.Namespace:
    """
    Parse command-line arguments for the jsonCreator tool.

    Returns:
        argparse.Namespace: The parsed arguments with values for the selected command.
    """
    parser = argparse.ArgumentParser(description="Create JSON for AlphaFold3 with a sample plan")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # list command
    list_parser = subparsers.add_parser("list", help="Display all available JSON files.")
    list_parser.add_argument("directory", nargs="?", default="./fasta", help="Folder containing JSON files.")

    # merge command
    merge_parser = subparsers.add_parser("merge", help="Combine multiple fasta files into a JSON file.")
    merge_parser.add_argument("sample_plan", nargs="?", help="CSV file with proteins separated by commas.")
    merge_parser.add_argument("--protein", help="List of proteins separated by commas.")
    merge_parser.add_argument("--seeds", "-s", required=True, type=int, nargs="+",
                              help="List of random seeds (space-separated integers).")
    merge_parser.add_argument("--input", "-i", default="./fasta", help="Input folder with JSON files.")
    merge_parser.add_argument("--output", "-o", default="./inputFile", help="Output folder for results.")
    merge_parser.add_argument("--model_dir", default="/lustre/fswork/.../alphafold3/params",
                              help="Path to AlphaFold model directory.")
    merge_parser.add_argument("--server_path", default=".", help="Path to input files on the server.")

    # launcher command
    launcher_parser = subparsers.add_parser("launcher", help="Create SLURM launcher script.")
    launcher_parser.add_argument("--server_path", default=".", help="Server path to input files.")
    launcher_parser.add_argument("--nextflow_path", default="$WORK/../commun/bin/nextflow/nextflow-24.10.2",
                                 help="Path to Nextflow executable.")
    launcher_parser.add_argument("--output", "-o", default="./inputFile", help="Output folder for launcher.")
    launcher_parser.add_argument("--input", "-i", default=".", help="Input folder containing param files.")

    return parser.parse_args()
