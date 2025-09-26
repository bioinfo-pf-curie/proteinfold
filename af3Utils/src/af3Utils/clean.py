import argparse
import csv
from dataclasses import dataclass
import logging
from pathlib import Path
import re
import shutil
from typing import List, Tuple

from af3Utils.selection import iter_af3_run_dirs


@dataclass
class CleanReport:
    run_dir: Path
    kept: List[Path]
    deleted: List[Path]
    skipped: List[Path]


RANK_RE = re.compile(r"^ranked_(\d+)\.(?:cif|pdb|mmcif)$", re.IGNORECASE)


def cmd_clean(args: argparse.Namespace) -> int:
    root = Path(args.input).resolve()
    if not root.exists():
        logging.error(f"Dossier d'entrée introuvable : {root}")
        return 2

    total_deleted = total_skipped = total_runs = 0

    for run_dir in iter_af3_run_dirs(root):
        total_runs += 1
        report = clean_run_dir(run_dir, keep=args.keep, dry_run=args.dry_run)

        if args.verbose:
            if report.kept:
                logging.info(f"[KEEP] ({len(report.kept)}) dans {run_dir}")
                for p in report.kept:
                    logging.info(f"  - {p.name}")
            to_remove = report.skipped if args.dry_run else report.deleted
            label = "WOULD DELETE" if args.dry_run else "DELETED"
            if to_remove:
                logging.info(f"[{label}] ({len(to_remove)}) dans {run_dir}")
                for p in to_remove:
                    logging.info(f"  - {p.name}")

        total_deleted += len(report.deleted)
        total_skipped += len(report.skipped)

    label = "seraient supprimés" if args.dry_run else "supprimés"
    logging.info(
        f"{total_runs} run(s) traités. {total_deleted} fichier(s) {label}. "
        f"{total_skipped} fichier(s) ignoré(s)."
    )
    return 0


def clean_run_dir(run_dir: Path, keep: int, dry_run: bool) -> CleanReport:
    """
    Garde les fichiers 'ranked_<idx>' avec idx < keep. Supprime le reste (sauf en dry-run).
    Supprime aussi les dossiers seed-<seed>-<sample> listés dans best_rank.csv pour les rangs >= keep.
    """
    ranked = find_ranked_files(run_dir)
    kept: list[Path] = []
    deleted: list[Path] = []
    skipped: list[Path] = []

    if not ranked:
        logging.debug(f"[SKIP] Aucun fichier ranked_* dans {run_dir}")
        return CleanReport(run_dir, kept, deleted, skipped)

    # --- Suppression des ranked_* fichiers ---
    for idx, path in ranked:
        if idx < keep:
            kept.append(path)
        else:
            if dry_run:
                skipped.append(path)
            else:
                try:
                    path.unlink()
                    deleted.append(path)
                except Exception as e:
                    logging.warning(f"Suppression impossible {path}: {e}")
                    skipped.append(path)

    # --- NEW : lecture de best_rank.csv ---
    best_rank = run_dir / "ordered_ranking_scores.tsv"
    if best_rank.is_file():
        try:
            with best_rank.open(newline="") as f:
                reader = csv.DictReader(f, delimiter="\t")
                for idx, row in enumerate(reader):
                    if idx < keep:
                        continue  # garder les top N
                    seed_num = row["seed"].strip()
                    sample_num = row["sample"].strip()
                    seed_dir_name = f"seed-{seed_num}_sample-{sample_num}"
                    seed_dir = run_dir / seed_dir_name
                    if seed_dir.is_dir():
                        if dry_run:
                            skipped.append(seed_dir)
                        else:
                            try:
                                shutil.rmtree(seed_dir)
                                deleted.append(seed_dir)
                            except Exception as e:
                                logging.warning(f"Suppression impossible {seed_dir}: {e}")
                                skipped.append(seed_dir)
        except Exception as e:
            logging.warning(f"Impossible de lire {best_rank}: {e}")

    return CleanReport(run_dir, kept, deleted, skipped)


def find_ranked_files(run_dir: Path) -> List[Tuple[int, Path]]:
    """
    Retourne la liste triée (index, chemin) des fichiers ranked_*.* dans run_dir.
    """
    ranked: List[Tuple[int, Path]] = []
    for p in run_dir.iterdir():
        if p.is_file():
            m = RANK_RE.match(p.name)
            if m:
                ranked.append((int(m.group(1)), p))
    ranked.sort(key=lambda t: t[0])
    return ranked
