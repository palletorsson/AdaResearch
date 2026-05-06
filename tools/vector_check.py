#!/usr/bin/env python3
"""
vector_check.py
===============

Measure whether Ada is staying on its vector (Truth ↔ Seam ↔ Being).

Reports the metrics defined in doc/VECTOR.md. Doesn't fail; surfaces.
Humans decide what to do.

Run from repo root:
    python tools/vector_check.py
    python tools/vector_check.py --json    # machine-readable
"""

from __future__ import annotations
import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
SEQ_DIR = MAPS / "sequences"
REG_DIR = REPO / "commons" / "artifacts" / "registry"
ADA_RUN = REPO / "ada_run"

# Variant suffix pattern: foo_v3_corridor, foo_v7_curve, etc.
VARIANT_RE = re.compile(r"_v\d+_[a-z_]+$")


def _read_json(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


# ---------------------------------------------------------------- maps ratio

def map_ratios() -> dict:
    """authored vs procedural-variant maps. Heuristic — variant suffix."""
    if not MAPS.exists(): return {"error": "no maps dir"}
    total = 0; variants = 0; authored = 0
    for d in MAPS.iterdir():
        if not d.is_dir(): continue
        if not (d / "map_data.json").exists(): continue
        total += 1
        if VARIANT_RE.search(d.name):
            variants += 1
        else:
            authored += 1
    ratio = authored / total if total else 0.0
    return {
        "total_maps": total,
        "authored_maps": authored,
        "variant_maps": variants,
        "authored_ratio": round(ratio, 3),
        "healthy_range": [0.10, 0.30],
        "verdict": _verdict(ratio, 0.10, 0.30),
    }


# ------------------------------------------------------------- QFEP coverage

def qfep_coverage() -> dict:
    """Artifacts with a `qfep_connection` field (prose linking to the framework).
    Sequences with a `qfep_term` field (one of: S, F, E, λ, integration, synthesis)."""
    art_total = 0; art_tagged = 0
    if REG_DIR.exists():
        for f in REG_DIR.glob("*.json"):
            d = _read_json(f); arts = (d or {}).get("artifacts", {})
            if not isinstance(arts, dict): continue
            for a in arts.values():
                art_total += 1
                if isinstance(a, dict):
                    qc = a.get("qfep_connection") or a.get("qfep_term") or a.get("qfep")
                    if qc and str(qc).strip(): art_tagged += 1
    seq_total = 0; seq_tagged = 0
    if SEQ_DIR.exists():
        for f in SEQ_DIR.glob("*.json"):
            if f.name == "grow_map_sandbox.json": continue
            d = _read_json(f); seqs = (d or {}).get("sequences", {})
            if not isinstance(seqs, dict): continue
            for s in seqs.values():
                seq_total += 1
                if isinstance(s, dict):
                    if (s.get("qfep_term") or s.get("qfep_connection")):
                        seq_tagged += 1
    art_pct = art_tagged / art_total if art_total else 0.0
    seq_pct = seq_tagged / seq_total if seq_total else 0.0
    overall = (art_pct + seq_pct) / 2 if seq_total and art_total else max(art_pct, seq_pct)
    return {
        "artifact_coverage": round(art_pct, 3),
        "artifacts_tagged": f"{art_tagged}/{art_total}",
        "sequence_coverage": round(seq_pct, 3),
        "sequences_tagged": f"{seq_tagged}/{seq_total}",
        "overall": round(overall, 3),
        "healthy_min": 0.85,
        "verdict": "ok" if overall >= 0.85 else "low" if overall >= 0.6 else "alarm",
    }


# ----------------------------------------------------------- spec coverage

def spec_coverage() -> dict:
    """How many artifacts have a portable spec_url? (Empty today; that's the point.)"""
    if not REG_DIR.exists(): return {"error": "no registry dir"}
    total = 0; with_spec = 0
    for f in REG_DIR.glob("*.json"):
        d = _read_json(f); arts = (d or {}).get("artifacts", {})
        if not isinstance(arts, dict): continue
        for a in arts.values():
            total += 1
            if isinstance(a, dict) and a.get("spec_url"):
                with_spec += 1
    pct = with_spec / total if total else 0.0
    return {
        "total_artifacts": total,
        "with_spec": with_spec,
        "spec_coverage": round(pct, 4),
        "doc": "Should grow MoM as we migrate artifacts to portable specs.",
    }


# ---------------------------------------------------------------- VR walks

def vr_walks() -> dict:
    md = ADA_RUN / "desktop_feedback.md"
    js = ADA_RUN / "desktop_feedback.json"
    last = None; mtime = None
    for p in (md, js):
        if p.exists():
            t = p.stat().st_mtime
            if mtime is None or t > mtime: mtime = t; last = p
    if mtime is None:
        return {"days_since_last_vr_walk": None, "verdict": "unknown",
                "note": "no ada_run/desktop_feedback.md or .json"}
    age = (time.time() - mtime) / 86400
    # Count lines added in last 30d (rough: file size in lines is fine for now)
    line_count = 0
    if md.exists():
        line_count = sum(1 for _ in md.open("r", encoding="utf-8", errors="ignore"))
    return {
        "last_walk_file": str(last.relative_to(REPO)),
        "days_since_last_vr_walk": round(age, 1),
        "feedback_line_count": line_count,
        "healthy_max_days": 7,
        "verdict": "ok" if age < 7 else "drift" if age < 21 else "alarm",
    }


# --------------------------------------------------- spines with both kinds

def hybrid_sequences() -> dict:
    """For each sequence's authored maps, does the corpus contain `<name>_v*_*`
    variants on disk? A sequence is hybrid when ≥1 authored map has variants."""
    if not SEQ_DIR.exists(): return {"error": "no sequences dir"}
    # Index variants on disk by stem.
    variant_stems: dict[str, int] = {}
    for d in MAPS.iterdir():
        if not d.is_dir(): continue
        name = d.name
        m = re.match(r"^(.+?)_v\d+_[a-z_]+$", name)
        if m:
            variant_stems[m.group(1)] = variant_stems.get(m.group(1), 0) + 1
    seqs = 0; with_both = 0; only_authored = 0; spine_authored = 0
    issues = []
    for f in SEQ_DIR.glob("*.json"):
        if f.name == "grow_map_sandbox.json": continue
        d = _read_json(f); s = (d or {}).get("sequences", {})
        if not isinstance(s, dict): continue
        for sid, sdef in s.items():
            seqs += 1
            maps = (sdef or {}).get("maps", []) or []
            has_authored = bool(maps)
            has_variants = any(m in variant_stems for m in maps)
            if has_authored and has_variants: with_both += 1
            elif has_authored: only_authored += 1; issues.append(f"{sid}:authored-only({len(maps)})")
            else: spine_authored += 1
    return {
        "sequences_total": seqs,
        "with_both_kinds": with_both,
        "only_authored_no_variants": only_authored,
        "empty_or_no_authored": spine_authored,
        "sample_issues": issues[:6],
        "verdict": "ok" if with_both >= seqs * 0.7 else "drift",
        "note": "hybrid = authored spine maps PLUS at least one auto-research variant on disk",
    }


# ----------------------------------------------- engine-specific code creep

def engine_creep() -> dict:
    """Files that should be portable shouldn't reference Godot APIs.
    Scans tools/map_grammar/ for `extends`, `Vector3`, `Node`, etc."""
    targets = REPO / "tools" / "map_grammar"
    godot_signals = ("Vector3", "Vector2", " extends ", "@export", "@onready",
                     "preload(", "load(\"res://", "Node3D", "MeshInstance3D")
    if not targets.exists():
        return {"error": "no tools/map_grammar"}
    total_lines = 0; godot_lines = 0
    for p in targets.rglob("*.py"):
        for line in p.open("r", encoding="utf-8", errors="ignore"):
            total_lines += 1
            if any(g in line for g in godot_signals): godot_lines += 1
    pct = godot_lines / total_lines if total_lines else 0.0
    return {
        "scanned_dir": str(targets.relative_to(REPO)),
        "total_lines": total_lines,
        "godot_referencing_lines": godot_lines,
        "engine_creep": round(pct, 4),
        "verdict": "ok" if pct < 0.005 else "watch" if pct < 0.02 else "alarm",
    }


# --------------------------------------------- variant-to-spine production

def production_ratio(window_days: int = 90) -> dict:
    """Look at file mtimes inside maps. Variants written vs authored within window."""
    cutoff = time.time() - window_days * 86400
    v_recent = 0; a_recent = 0
    for d in MAPS.iterdir():
        if not d.is_dir(): continue
        md = d / "map_data.json"
        if not md.exists(): continue
        if md.stat().st_mtime < cutoff: continue
        if VARIANT_RE.search(d.name): v_recent += 1
        else: a_recent += 1
    ratio = (v_recent / a_recent) if a_recent else (float("inf") if v_recent else 0.0)
    if a_recent == 0 and v_recent == 0:
        verdict = "quiet"
    elif a_recent == 0:
        verdict = "alarm"  # all variants no spines
    elif ratio < 3:
        verdict = "low-procedural"
    elif ratio > 12:
        verdict = "drift"
    else:
        verdict = "ok"
    return {
        "window_days": window_days,
        "variants_modified": v_recent,
        "authored_modified": a_recent,
        "ratio_v_per_a": (round(ratio, 1) if ratio != float("inf") else "inf"),
        "healthy_range": [3, 12],
        "verdict": verdict,
    }


# ------------------------------------------------------------ helpers

def _verdict(value, lo, hi):
    if value < lo: return "low (museum drift)"
    if value > hi: return "high (procedural bias)"
    return "ok"


def _color(verdict: str) -> str:
    if verdict in ("ok", "quiet"): return "\033[92m"   # green
    if verdict in ("watch", "drift", "low (museum drift)", "high (procedural bias)", "low", "low-procedural"):
        return "\033[93m"  # yellow
    return "\033[91m"      # red (alarm/unknown/error)


# ------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "metrics": {
            "map_ratios":        map_ratios(),
            "qfep_coverage":     qfep_coverage(),
            "spec_coverage":     spec_coverage(),
            "vr_walks":          vr_walks(),
            "hybrid_sequences":  hybrid_sequences(),
            "engine_creep":      engine_creep(),
            "production_ratio":  production_ratio(),
        },
    }

    if args.json:
        print(json.dumps(report, indent=2))
        return

    R = "\033[0m"
    BOLD = "\033[1m"
    print()
    print(f"{BOLD}Ada Vector Check  ·  {report['generated_at']}{R}")
    print("=" * 60)
    print()
    for name, m in report["metrics"].items():
        verdict = m.get("verdict", "—")
        col = _color(verdict)
        print(f"{BOLD}{name}{R}  {col}{verdict}{R}")
        for k, v in m.items():
            if k == "verdict": continue
            if isinstance(v, list):
                v = ", ".join(str(x) for x in v) or "—"
            print(f"  {k:30}  {v}")
        print()
    print("=" * 60)
    print("doc/VECTOR.md explains each metric and what 'drift' means.")
    print("Re-run on the first of the month. Pick one corrective action per drift.")
    print()


if __name__ == "__main__":
    main()
