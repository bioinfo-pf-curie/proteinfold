import os
import errno

def list_json(directory: str) -> dict[str, str]:
    """
    Recursively browses a directory to list all .json files.

    Args:
        directory (str): Root directory to browse.

    Returns:
        dict[str, str]: Dictionary associating file names (without extension) with their full path.

    Raises:
        FileNotFoundError: If the specified directory does not exist.s.
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
    Displays the JSON files in a directory in formatted for.

    Args:
        directory (str): Directory to scan.
    """
    json_files = list_json(directory)
    for protein, path in json_files.items():
        print(f"{protein:30} : {path:100}")
