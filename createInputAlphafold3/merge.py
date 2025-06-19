import os
import json
import errno
import string
import itertools
from typing import Iterator
from createInputAlphafold3.list import list_json


def load_sample_plan(file_path: str) -> list[list[str]]:
    """
    Charge un fichier CSV contenant des groupes de protéines.

    Args:
        file_path (str): Chemin vers le fichier CSV.

    Returns:
        list[list[str]]: Liste de groupes de noms de protéines.

    Raises:
        FileNotFoundError: Si le fichier n'existe pas.
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
    Crée un fichier JSON AlphaFold3 à partir de plusieurs protéines.

    Args:
        proteins (list[str]): Liste des noms de protéines.
        seeds (list[int]): Liste de graines aléatoires.
        input_folder (str): Répertoire contenant les fichiers JSON des protéines.
        output_folder (str): Répertoire de sortie.

    Returns:
        str: Nom du fichier généré (sans extension).

    Raises:
        ValueError: Si une protéine n'a pas de fichier d'entrée associé.
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
    Crée un fichier `params-file` JSON pour exécuter AlphaFold3 avec Nextflow.

    Args:
        name (str): Nom de l'échantillon.
        output_folder (str): Dossier local de sortie.
        model_dir (str): Répertoire du modèle AlphaFold.
        server_path (str): Répertoire côté serveur pour accéder aux fichiers.
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
    Génère une séquence infinie d'ID de type A, B, ..., Z, AA, AB, ..., AAA, etc.

    Yields:
        str: Identifiant unique.
    """
    chars = string.ascii_uppercase
    length = 1
    while True:
        for combo in itertools.product(chars, repeat=length):
            yield ''.join(combo)
        length += 1


def create_output_dir(base_folder: str, name: str, subfolder: str) -> None:
    """
    Crée récursivement les dossiers nécessaires à l'écriture des fichiers.

    Args:
        base_folder (str): Répertoire de base.
        name (str): Nom de l'échantillon.
        subfolder (str): Sous-dossier à créer (ex: "fasta", "params-file").
    """
    os.makedirs(os.path.join(base_folder, name, subfolder), exist_ok=True)
