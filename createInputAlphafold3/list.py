import os
import errno

def list_json(directory: str) -> dict[str, str]:
    """
    Parcourt récursivement un dossier pour lister tous les fichiers .json.

    Args:
        directory (str): Répertoire racine à explorer.

    Returns:
        dict[str, str]: Dictionnaire associant les noms de fichiers (sans extension) à leur chemin complet.

    Raises:
        FileNotFoundError: Si le répertoire spécifié n'existe pas.
    """
    if not os.path.exists(directory):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), directory)

    json_files: dict[str, str] = {}
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                name = os.path.splitext(file)[0]
                json_files[name] = os.path.join(root, file)
    return json_files


def display_json(directory: str) -> None:
    """
    Affiche sous forme formatée les fichiers JSON présents dans un répertoire.

    Args:
        directory (str): Répertoire à scanner.
    """
    json_files = list_json(directory)
    for protein, path in json_files.items():
        print(f"{protein:30} : {path:100}")
