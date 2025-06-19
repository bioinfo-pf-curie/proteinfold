"""
jsonCreator
===========

Package permettant de :
- Lister les fichiers JSON pour AlphaFold3
- Fusionner des séquences en un fichier JSON compatible AlphaFold3
- Générer des fichiers de paramètres pour Nextflow
- Créer des scripts SLURM de lancement

Modules principaux :
- cli : Analyse des arguments
- merge : Génération des fichiers JSON
- list : Affichage des fichiers disponibles
- createLauncher : Génération des scripts SLURM
"""

from createInputAlphafold3.cli import parse_args
from createInputAlphafold3.merge import (
    create_json,
    create_json_params,
    load_sample_plan
)
from createInputAlphafold3.list import (
    list_json,
    display_json
)
from createInputAlphafold3.createLauncher import create_launcher

__all__ = [
    "parse_args",
    "create_json",
    "create_json_params",
    "load_sample_plan",
    "list_json",
    "display_json",
    "create_launcher"
]
