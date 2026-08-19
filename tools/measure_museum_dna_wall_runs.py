#!/usr/bin/env python3
"""Measure configured DNA wall variants and publish compact planning envelopes.

This is a preflight, not a registry writer.  It reads accepted wall-series
instructions from ``ada_run/em_plan.json``, configures those exact variants in
Godot 4.6, and writes the maximum family envelope consumed by the spatial
negotiator.  A crash is isolated to one ``anchor|axis|value`` and recorded as
an explicit skipped value instead of making the whole corpus unknowable.

Usage:
  python tools/measure_museum_dna_wall_runs.py
  python tools/measure_museum_dna_wall_runs.py --sequence=primitives
  python tools/measure_museum_dna_wall_runs.py --prepare-only
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import math
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
PLAN = REPO / "ada_run" / "em_plan.json"
SPEC = REPO / "ada_run" / "museum_dna_wall_measure_spec.json"
RAW = REPO / "ada_run" / "museum_dna_wall_measurements.json"
PROGRESS = REPO / "ada_run" / "museum_dna_wall_measurements.progress.txt"
ENVELOPES = REPO / "commons" / "data" / "museum_dna_wall_envelopes.json"
REGISTRY = REPO / "commons" / "artifacts" / "registry"
GODOT = Path(os.environ.get(
    "GODOT_EXE", r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe"))
MEASURER = "res://commons/testing/measure_museum_dna_wall_runs.gd"


def _read(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _write(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # One-space indentation is the project's compact-readable convention for
    # generated corpora: reviewable diffs without the 4x expansion of indent=4.
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n",
                    encoding="utf-8")


def _registry() -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for raw in sorted(glob.glob(str(REGISTRY / "*.json"))):
        for token, entry in (_read(Path(raw)).get("artifacts") or {}).items():
            if isinstance(entry, dict):
                out[str(token)] = entry
    return out


def _plan_rows(plan: dict[str, Any], sequence: str) -> list[dict[str, Any]]:
    if isinstance(plan.get("plans"), list):
        rows = [r for r in plan["plans"] if isinstance(r, dict)]
    else:
        rows = [r for r in (plan.get("museums") or {}).values()
                if isinstance(r, dict)]
    if sequence:
        rows = [r for r in rows if str(r.get("sequence", "")) == sequence]
    return rows


def build_spec(sequence: str = "") -> dict[str, Any]:
    plan = _read(PLAN)
    registry = _registry()
    families: dict[tuple[str, str], dict[str, Any]] = {}
    for museum in _plan_rows(plan, sequence):
        for run in museum.get("wall_runs", []):
            if not isinstance(run, dict) or not run.get("housed") \
                    or not run.get("assemble"):
                continue
            anchor, axis = str(run.get("anchor", "")), str(run.get("axis", ""))
            scene = str((registry.get(anchor) or {}).get("scene", ""))
            if not anchor or not axis or not scene:
                continue
            family = families.setdefault((anchor, axis), {
                "anchor": anchor, "axis": axis, "scene": scene,
                "variants": {}, "uses": 0,
            })
            family["uses"] += 1
            rects = run.get("rects_uv") or []
            for index, value_v in enumerate(run.get("values") or []):
                value = str(value_v)
                rect = rects[index] if index < len(rects) else []
                width = round(float(rect[2]) - float(rect[0]), 3) \
                    if isinstance(rect, list) and len(rect) >= 4 else 0.0
                height = round(float(rect[3]) - float(rect[1]), 3) \
                    if isinstance(rect, list) and len(rect) >= 4 else 0.0
                old = family["variants"].get(value)
                # Minimum received rectangle is the honest fit gate when one
                # lineage is used in several buildings.
                if old:
                    old["allowed_wh"] = [min(old["allowed_wh"][0], width),
                                         min(old["allowed_wh"][1], height)]
                else:
                    family["variants"][value] = {
                        "value": value, "allowed_wh": [width, height],
                    }
    serial: list[dict[str, Any]] = []
    for family in sorted(families.values(), key=lambda r: (r["anchor"], r["axis"])):
        family = dict(family)
        family["variants"] = list(family["variants"].values())
        serial.append(family)
    measurer_source = REPO / "commons" / "testing" / "measure_museum_dna_wall_runs.gd"
    source_hash = hashlib.sha256(measurer_source.read_bytes()).hexdigest()
    identity = json.dumps({"families": serial, "measurer": source_hash},
                          sort_keys=True, separators=(",", ":"))
    run_id = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:16]
    return {
        "schema": "adaresearch.museum_dna_wall_measure_spec.v1",
        "run_id": run_id,
        "measurer_sha256": source_hash,
        "source": "ada_run/em_plan.json accepted wall_runs",
        "sequence": sequence,
        "families": serial,
        "skip": [],
    }


def _progress_key() -> str:
    try:
        return PROGRESS.read_text(encoding="utf-8").strip().splitlines()[0]
    except (OSError, IndexError):
        return ""


def run_godot(spec: dict[str, Any], max_restarts: int) -> int:
    skip: set[str] = set(str(v) for v in spec.get("skip", []))
    for attempt in range(max_restarts + 1):
        spec["skip"] = sorted(skip)
        _write(SPEC, spec)
        cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
               f"--expect={RAW}", "--grace=60", "--stall=45", "--",
               str(GODOT), "--path", str(REPO), "--xr-mode", "off",
               "--no-window", "--script", MEASURER, "--",
               f"--spec={SPEC}", f"--out={RAW}", f"--progress={PROGRESS}"]
        result = subprocess.run(cmd, cwd=str(REPO))
        if result.returncode == 0:
            return 0
        culprit = _progress_key()
        if not culprit or culprit == "complete" or culprit in skip \
                or attempt >= max_restarts:
            return result.returncode
        skip.add(culprit)
        print(f"measurement restart {attempt + 1}: isolating {culprit}", flush=True)
    return 1


def publish(spec: dict[str, Any]) -> dict[str, Any]:
    raw = _read(RAW)
    measured = {f"{r.get('anchor')}|{r.get('axis')}|{r.get('value')}": r
                for r in raw.get("measurements", []) if isinstance(r, dict)}
    skipped = {f"{r.get('anchor')}|{r.get('axis')}|{r.get('value')}": r
               for r in raw.get("skipped", []) if isinstance(r, dict)}
    families: dict[str, Any] = {}
    for family in spec.get("families", []):
        anchor, axis = family["anchor"], family["axis"]
        variants: dict[str, list[float]] = {}
        missing: list[str] = []
        invalid: list[str] = []
        for variant in family["variants"]:
            value = variant["value"]
            key = f"{anchor}|{axis}|{value}"
            row = measured.get(key)
            if row and row.get("ok") and row.get("portable", True) \
                    and len(row.get("size_wdh") or []) == 3:
                variants[value] = [round(float(v), 3) for v in row["size_wdh"]]
            elif row and row.get("ok") and not row.get("portable", True):
                invalid.append(value)
            elif key in skipped:
                missing.append(value)
            else:
                invalid.append(value)
        envelope = [max((v[i] for v in variants.values()), default=0.0)
                    for i in range(3)]
        complete = len(variants) == len(family["variants"])
        families[f"{anchor}|{axis}"] = {
            "anchor": anchor, "axis": axis, "scene": family["scene"],
            "values": variants,
            "envelope_wdh": [round(v, 3) for v in envelope],
            "complete": complete,
            **({"missing": missing} if missing else {}),
            **({"invalid": invalid} if invalid else {}),
        }
    report = {
        "schema": "adaresearch.museum_dna_wall_envelopes.v1",
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "method": ("Godot 4.6; config before _ready; immediate merged "
                   "MeshInstance3D + CollisionShape3D AABB; [width,depth,height] m"),
        "run_id": spec["run_id"],
        "families": families,
        "summary": {
            "families": len(families),
            "complete": sum(1 for f in families.values() if f["complete"]),
            "variants": sum(len(f["values"]) for f in families.values()),
            "skipped_or_invalid": sum(len(f.get("missing", [])) +
                                      len(f.get("invalid", []))
                                      for f in families.values()),
            "wall_depth_ok": sum(1 for f in families.values()
                                 if f["complete"] and
                                 f["envelope_wdh"][1] <= 0.7),
        },
    }
    _write(ENVELOPES, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sequence", default="")
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--publish-only", action="store_true")
    parser.add_argument("--max-restarts", type=int, default=12)
    args = parser.parse_args()

    spec = build_spec(args.sequence)
    if not spec["families"]:
        print("no accepted DNA wall variants in the selected plan", file=sys.stderr)
        return 2
    _write(SPEC, spec)
    variants = sum(len(f["variants"]) for f in spec["families"])
    print(f"prepared {len(spec['families'])} families / {variants} variants -> {SPEC}")
    if args.prepare_only:
        return 0
    if not args.publish_only:
        # A changed spec must not resume an unrelated raw report.  The GDScript
        # also checks run_id; removing it here keeps watchdog progress honest.
        prior = _read(RAW)
        if prior.get("run_id") != spec["run_id"] and RAW.exists():
            RAW.unlink()
        code = run_godot(spec, max(0, args.max_restarts))
        if code != 0:
            print(f"Godot measurement failed with exit {code}", file=sys.stderr)
            return code
    report = publish(spec)
    summary = report["summary"]
    print("published {complete}/{families} complete families, {variants} variants, "
          "{skipped_or_invalid} skipped/invalid -> {path}".format(
              path=ENVELOPES, **summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
