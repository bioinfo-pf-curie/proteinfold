import os
import json
import errno
import string
import itertools
from typing import Iterator
from createInputAlphafold3.list import list_json


def load_sample_plan(file_path: str) -> list[list[str]]:
    """
    Loads a CSV file containing groups of proteins.

    Args:
        file_path (str): Path to the CSV file.

    Returns:
        list[list[str]]: List of groups of protein names.

    Raises:
        FileNotFoundError:  If the file does not exist
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), file_path)

    sample_plan: list[list[str]] = []
    with open(file_path, "r") as f:
        for line in f.read().splitlines():
            sample_plan.append(line.split(","))

    return sample_plan


def create_json(proteins: list[str], seeds: list[int], input_folder: str, output_folder: str) -> str:
    """
    Creates an AlphaFold3 JSON file from several proteins.

    Args:
        proteins (list[str]): List of protein names.
        seeds (list[int]): List of random seeds.
        input_folder (str): Directory containing protein JSON files.
        output_folder (str): Output directory.

    Returns:
        str: Name of the generated file (without extension).

    Raises:
        ValueError: If a protein has no associated input file.
    """
    json_files = list_json(input_folder)
    available_proteins = json_files.keys()

    fasta_files: list[str] = []
    for protein in proteins:
        if protein not in available_proteins:
            raise ValueError(f"Protein '{protein}' not found in {input_folder}")
        fasta_files.append(json_files[protein])

    contents = []
    af3_id_generator = generate_af3_id()
    name = '-'.join(proteins)

    for file_path in fasta_files:
        with open(file_path, 'r') as f:
            json_content = json.load(f)
            json_content["protein"]["id"] = next(af3_id_generator)
            contents.append(json_content)

    af3_json = {
        "dialect": "alphafold3",
        "version": 1,
        "name": name,
        "modelSeeds": seeds,
        "sequences": contents
    }

    json_output = json.dumps(af3_json, indent=4, sort_keys=True)
    create_output_dir(output_folder, name, "fasta")

    output_path = os.path.join(output_folder, name, "fasta", f"{name}.json")
    with open(output_path, "w") as outfile:
        outfile.write(json_output)

    return name


def create_json_params(name: str, output_folder: str, model_dir: str, server_path: str) -> None:
    """
    Creates a JSON `params-file` to run AlphaFold3 with Nextflow.

    Args:
        name (str): Sample name.
        output_folder (str): Local output folder.
        model_dir (str): AlphaFold model directory.
        server_path (str): Server-side directory for accessing files.
    """
    create_output_dir(output_folder, name, "params-file")

    params = {
        "launchAlphaFold3": True,
        "alphaFold3Options": f"--model_dir={model_dir}",
        "fastaPath": os.path.join(server_path, output_folder, name, "fasta"),
        "outDir": os.path.join(server_path, output_folder, name)
    }

    params_path = os.path.join(output_folder, name, "params-file", f"{name}.json")
    with open(params_path, "w") as f:
        json.dump(params, f, indent=4, sort_keys=True)


def generate_af3_id() -> Iterator[str]:
    """
    Generates an infinite sequence of IDs of type A, B, ..., Z, AA, AB, ..., AAA, etc.

    Yields:
        str: Unique identifier.
    """
    chars = string.ascii_uppercase
    length = 1
    while True:
        for combo in itertools.product(chars, repeat=length):
            yield ''.join(combo)
        length += 1


def create_output_dir(base_folder: str, name: str, subfolder: str) -> None:
    """
    Recursively creates the folders needed to write files.

    Args:
        base_folder (str): Base directory.
        name (str): Sample name.
        subfolder (str): Subfolder to be created (e.g. "fasta", "params-file").
    """
    os.makedirs(os.path.join(base_folder, name, subfolder), exist_ok=True)
