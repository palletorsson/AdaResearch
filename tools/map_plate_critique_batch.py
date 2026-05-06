#!/usr/bin/env python
"""map_plate_critique_batch.py — run map_plate_critique over a curated edge map.

Produces a single JSON summary and prints a scoreboard so the project can see
which late-spine plates teach their edges and which need revision.

Usage:
  python tools/map_plate_critique_batch.py
  python tools/map_plate_critique_batch.py --jobs custom_jobs.json
  python tools/map_plate_critique_batch.py --no-capture     # reuse existing shots
  python tools/map_plate_critique_batch.py --skip-existing  # only run new combos
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REPORTS = REPO / "doc" / "reports"
SUMMARY_PATH = REPORTS / "plate_critique_batch.json"

# Curated subset: one signature map per edge so the first run is informative.
# Each (map, edge) pair targets the sequence_home named in EDGES_OF_ALGORITHM.md.
DEFAULT_JOBS = [
    # Edge A — formal impossibility (foundationscrisis)
    {"map": "Godel_Incompleteness",     "edge": "A"},
    # Edge B — tractability cliff (searchpathfinding)
    {"map": "SearchPathfinding_Intro",  "edge": "B"},
    # Edge C — local-vs-global (machinelearning)
    {"map": "ML_Gradient_Landscape",    "edge": "C"},
    # Edge D — representational silence (criticalalgorithms)
    {"map": "CriticalAlgorithms_Bias_Gallery",  "edge": "D"},
    # Edge E — embodiment / continuous-discrete (bodyprogression)
    {"map": "BodyProg_Hands",           "edge": "E"},
    # Edge F — folding (qfeplaboratory) — Fold_Theatre is the exemplar
    {"map": "Fold_Theatre",             "edge": "F"},
    # Edge H — apparatus-as-phenomenon (qfeplaboratory paired with F)
    {"map": "QFEP_Lambda_Spectrum",     "edge": "H"},
    # Edge L — failure as method (machinelearning / criticalalgorithms)
    {"map": "ML_Synthesis",             "edge": "L"},
]


def report_path(map_name: str, edge: str) -> Path:
    return REPORTS / f"plate_critique_{map_name}_{edge}.json"


def run_one(map_name: str, edge: str, no_capture: bool) -> dict:
    cmd = [sys.executable, "tools/map_plate_critique.py",
           f"--map={map_name}", f"--edge={edge}"]
    if no_capture:
        cmd.append("--no-capture")
    print(f"\n──── {map_name} / edge {edge} ────")
    proc = subprocess.run(cmd, cwd=REPO, capture_output=False)
    if proc.returncode != 0:
        return {"map": map_name, "edge": edge, "error": f"rc={proc.returncode}"}
    rp = report_path(map_name, edge)
    if not rp.exists():
        return {"map": map_name, "edge": edge, "error": "no report file"}
    data = json.loads(rp.read_text(encoding="utf-8"))
    crit = data.get("result", {}).get("critique", {})
    return {
        "map": map_name,
        "edge": edge,
        "score": crit.get("score"),
        "verdict": crit.get("verdict"),
        "edge_reads_as": crit.get("edge_reads_as"),
        "paragraph": crit.get("paragraph", "")[:280],
        "hints": crit.get("next_gen_hints", []),
        "report": str(rp.relative_to(REPO)),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", help="JSON file with [{map, edge}, ...]; "
                                    "omit for the curated default list")
    ap.add_argument("--no-capture", action="store_true",
                    help="Reuse existing capture shots; skip the Godot render")
    ap.add_argument("--skip-existing", action="store_true",
                    help="Skip jobs whose plate_critique_<map>_<edge>.json already exists")
    args = ap.parse_args()

    if args.jobs:
        jobs = json.loads(Path(args.jobs).read_text(encoding="utf-8"))
    else:
        jobs = DEFAULT_JOBS

    REPORTS.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []
    for job in jobs:
        rp = report_path(job["map"], job["edge"])
        if args.skip_existing and rp.exists():
            print(f"  skip {job['map']} / {job['edge']} (cached)")
            data = json.loads(rp.read_text(encoding="utf-8"))
            crit = data.get("result", {}).get("critique", {})
            rows.append({
                "map": job["map"], "edge": job["edge"],
                "score": crit.get("score"), "verdict": crit.get("verdict"),
                "cached": True,
                "report": str(rp.relative_to(REPO)),
            })
            continue
        rows.append(run_one(job["map"], job["edge"], args.no_capture))

    # Summary file.
    summary = {"jobs": rows}
    SUMMARY_PATH.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    # Scoreboard.
    print("\n" + "═" * 78)
    print(" PLATE CRITIQUE SCOREBOARD")
    print("═" * 78)
    print(f" {'edge':<5} {'map':<42} {'score':<7} {'verdict'}")
    print(" " + "─" * 76)
    avg_count = 0
    avg_total = 0
    for r in rows:
        score = r.get("score")
        if isinstance(score, int):
            avg_total += score
            avg_count += 1
            score_str = f"{score}/5"
        else:
            score_str = "ERR" if r.get("error") else "?"
        verdict = (r.get("verdict") or r.get("error") or "")[:30]
        print(f" {r['edge']:<5} {r['map'][:42]:<42} {score_str:<7} {verdict}")
    if avg_count > 0:
        print(" " + "─" * 76)
        print(f" mean score: {avg_total / avg_count:.2f} across {avg_count}")
    print("═" * 78)
    print(f" summary: {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
