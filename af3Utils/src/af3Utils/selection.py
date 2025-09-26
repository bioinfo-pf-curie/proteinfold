import argparse
import csv
import json
import logging
from pathlib import Path
import re
from re import Pattern
from statistics import fmean
from typing import Generator, List, Optional, Tuple

import pandas as pd
import plotly


def cmd_select(args: argparse.Namespace) -> int:
    """
    Parcourt tous les <root>/<project>/results/alphaFold3/<run_dir>/
    et agrège iptm/ptm depuis chaque <run_dir>/<seed-sample>/workflowOnComplete_path_confidences.json.

    Écrit un TSV avec :
      - Experiences : nom du run_dir
      - mean select iptm : moyenne iptm des échantillons iptm >= threshold
      - mean select ptm  : moyenne ptm correspondante
      - number select     : nombre sélectionné (iptm >= threshold)
      - all               : nombre total d'échantillons présents
    """
    root = Path(args.input).resolve()
    if not root.exists():
        logging.error(f"Dossier d'entrée introuvable : {root}")
        return 2

    # Paramètres
    iptm_threshold: float = getattr(args, "iptm_threshold", 0.5)
    ptm_threshold: float = getattr(args, "ptm_threshold", 0.0)
    pattern_str: str = getattr(args, "pattern", r"^seed[_-]\d+[_-]sample[_-]\d+$")
    try:
        seed_sample_re = re.compile(pattern_str, re.IGNORECASE)
    except re.error as e:
        logging.error(f"Regex invalide pour --pattern: {e}")
        return 2

    rows: List[Tuple[str, float, float, float, float, int, int]] = []

    total_runs = 0
    total_json = 0
    total_json_bad = 0

    for run_dir in iter_af3_run_dirs(root):
        total_runs += 1
        name_exp = run_dir.name

        iptm_selected: List[float] = []
        ptm_selected: List[float] = []
        iptm_all: List[float] = []
        ptm_all: List[float] = []

        seed_dirs = _iter_seed_dirs(run_dir, seed_sample_re)
        if not seed_dirs and args.verbose:
            logging.debug(f"[{name_exp}] Aucun dossier seed/sample trouvé")

        for sd in seed_dirs:
            summary_file = sd / "summary_confidences.json"
            if not summary_file.is_file():
                if args.verbose:
                    logging.debug(
                        f"[{name_exp}] Fichier absent: {summary_file.name} dans {sd.name}"
                    )
                continue

            try:
                with open(summary_file, "r", encoding="utf-8") as f:
                    js = json.load(f)
                total_json += 1
            except Exception as e:
                total_json_bad += 1
                logging.warning(f"[{name_exp}] JSON illisible: {summary_file} ({e})")
                continue

            iptm = _safe_float(js.get("iptm"))
            ptm = _safe_float(js.get("ptm"))

            if iptm is None:
                total_json_bad += 1
                if args.verbose:
                    logging.debug(f"[{name_exp}] 'iptm' manquant/non-numérique dans {summary_file}")
                continue
            if ptm is None:
                total_json_bad += 1
                if args.verbose:
                    logging.debug(f"[{name_exp}] 'iptm' manquant/non-numérique dans {summary_file}")
                continue

            iptm_all.append(iptm)
            ptm_all.append(ptm)
            if iptm >= iptm_threshold and ptm >= ptm_threshold:
                iptm_selected.append(iptm)
                ptm_selected.append(ptm)

        max_iptm = _safe_max(iptm_selected)
        max_ptm = _safe_max(ptm_selected)
        mean_sel_iptm = _safe_mean(iptm_selected)
        mean_sel_ptm = _safe_mean(ptm_selected)
        n_sel = len(iptm_selected)
        n_all = len(iptm_all)

        create_graph(name_exp, iptm_all, ptm_all, args.output)

        rows.append((name_exp, mean_sel_iptm, max_iptm, mean_sel_ptm, max_ptm, n_sel, n_all))

    # Sortie
    out_path = Path(args.output).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Tri par nom d'expérience pour stabilité
    rows.sort(key=lambda r: r[0])

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(
            [
                "Experiences",
                "mean select iptm",
                "max select iptm",
                "mean select ptm",
                "max select ptm",
                "number select",
                "all",
            ]
        )
        for name_exp, mean_iptm, max_iptm, mean_ptm, max_ptm, n_sel, n_all in rows:
            # Écrit NaN tels quels si listes vides (cohérent pour analyse ultérieure)
            writer.writerow([name_exp, mean_iptm, max_iptm, mean_ptm, max_ptm, n_sel, n_all])

    logging.info(
        f"{total_runs} run(s) traités. JSON lus: {total_json}, JSON problématiques: {total_json_bad}. "
        f"Résultats écrits dans: {out_path}"
    )
    return 0


def _iter_seed_dirs(run_dir: Path, pattern: Pattern[str]) -> List[Path]:
    """Retourne les sous-dossiers d'un run qui matchent le pattern seed/sample."""
    subdirs: list[Path] = []
    for p in run_dir.iterdir():
        if p.is_dir() and pattern.match(p.name):  
            subdirs.append(p)  
    return subdirs  


def _safe_float(x: float) -> Optional[float]:
    """Convertit en float si possible, sinon None."""
    try:
        return float(x)
    except Exception:
        return None


def _safe_mean(values: List[float]) -> float:
    """Moyenne pour liste possiblement vide (retourne NaN si vide)."""
    return fmean(values) if values else float("nan")


def _safe_max(values: List[float]) -> float:
    """Moyenne pour liste possiblement vide (retourne NaN si vide)."""
    return max(values) if values else float("nan")


def create_graph(name: str, iptm: list[float], ptm: list[float], output: Path) -> None:
    output_name = Path(output).name.split(".")[0]
    output_path = Path.joinpath(Path(output).parent, output_name, name + ".html")
    if not output_path.parent.exists():
        Path(output_path.parent).mkdir()
    df: pd.DataFrame = pd.DataFrame(dict(iptm=iptm, ptm=ptm)).melt(var_name="type")  

    fig = plotly.violin(
        df,
        y="value",
        color="type",  
        box=True,
        points="all",
    )
    fig.write_html(output_path)  


def iter_af3_run_dirs(root: Path) -> Generator[Path, None, None]:
    """
    Itère sur tous les répertoires <root>/<project>/results/alphaFold3/<run_dir>/.
    """
    if not root.exists():
        return
    for project in root.iterdir():
        if not project.is_dir():
            continue
        af3_root = project / "results" / "alphaFold3"
        if not af3_root.is_dir():
            continue
        for run_dir in af3_root.iterdir():
            if run_dir.is_dir():
                yield run_dir
