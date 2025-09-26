import argparse
import logging
from pathlib import Path
import re
from typing import Generator, List

SUCCESS_RE = re.compile(r"Success(?:\s|\.)*:\s*true\b", re.IGNORECASE)


def cmd_verif(args: argparse.Namespace) -> int:
    """
    Vérifie quels projets présents sous --input ont un workflow terminé avec succès
    (d'après 'results/workflowOnComplete.txt') et compare à la liste du samplePlan.

    Affiche les expériences attendues mais non terminées ou non encore lancées.
    Si --output est fourni, écrit la liste (une par ligne).
    """
    root = Path(args.input).resolve()
    if not root.exists():
        logging.error(f"Dossier d'entrée introuvable : {root}")
        return 2

    # Projets ayant un fichier workflowOnComplete.txt ET marqués comme Success:true
    successful_projects: List[str] = []
    for project in iter_af3_workflowOnComplete_path(root):
        if _project_success(project):
            successful_projects.append(project.name)
        else:
            logging.debug(f"[{project.name}] Pas de succès détecté dans workflowOnComplete.txt")

    # Charge la liste d'attendus
    sample_plan_path = Path(args.samplePlan).resolve()
    expected_names = _load_sample_plan(sample_plan_path)
    if not expected_names:
        logging.warning("Liste des expériences attendues vide ou illisible.")

    # Diff = attendus - succès
    missing = sorted(set(expected_names) - set(successful_projects))

    # Écriture optionnelle
    if getattr(args, "output", None):
        out_path = Path(args.output).resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with out_path.open("w", encoding="utf-8", newline="\n") as f:
                f.write("\n".join(missing))
            logging.info(f"Liste des expériences non terminées écrite dans : {out_path}")
        except Exception as e:
            logging.error(f"Impossible d'écrire le fichier de sortie {out_path}: {e}")
            return 2
    else:
        for name in missing:
            logging.warning(
                f"L'expérience '{name}' n'a pas été terminée avec succès ou n'a pas encore eu lieu."
            )
    # Petit résumé
    logging.info(
        f"Attendus: {len(expected_names)} | Succès: {len(successful_projects)} | Manquants: {len(missing)}"
    )
    return 0


def iter_af3_workflowOnComplete_path(root: Path) -> Generator[Path, None, None]:
    """
    Itère sur les projets <root>/<project> qui contiennent le fichier :
        <project>/results/workflowOnComplete.txt

    Yields
    ------
    Path
        Le chemin du dossier <project>.
    """
    if not root.exists():
        logging.debug(f"Racine inexistante: {root}")
        return

    for project in root.iterdir():
        if not project.is_dir():
            continue
        wf_file = project / "results" / "workflowOnComplete.txt"
        if wf_file.is_file():
            yield project


def _project_success(project: Path) -> bool:
    """
    Lit <project>/results/workflowOnComplete.txt et retourne True si le succès est détecté.
    Retourne False si non trouvé ou fichier illisible.
    """
    wf_file = project / "results" / "workflowOnComplete.txt"
    try:
        text = wf_file.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        logging.warning(f"[{project.name}] Impossible de lire {wf_file}: {e}")
        return False

    # Détection robuste : 'Success....: true' (variantes acceptées)
    return SUCCESS_RE.search(text) is not None


def _load_sample_plan(sample_plan_path: Path) -> List[str]:
    """
    Charge la liste des expériences attendues depuis un fichier texte.
    - Ignore lignes vides/commentaires (#)
    - Remplace les virgules par '_' (comportement initial conservé)
    """
    names: List[str] = []
    try:
        with sample_plan_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                names.append(line.replace(",", "-"))
    except Exception as e:
        logging.error(f"Erreur lecture samplePlan {sample_plan_path}: {e}")
        return []
    return names
