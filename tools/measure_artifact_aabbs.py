#!/usr/bin/env python3
"""Run the Godot AABB measurement and merge results into the artifact registry.

Pipeline:
    1. (optional) Boot Godot headless and run
       commons/testing/measure_artifacts.gd which writes
       ada_run/artifact_measurements.json — one record per artifact.
    2. Parse that report.
    3. For each artifact, find its registry file under
       commons/artifacts/registry/*.json and merge the measured
       fields back onto the entry (aabb_size, aabb_center, grid_cells,
       max_dimension_m, measured_at).
    4. Save each registry, preserving the project's tab-indented JSON.

This is the loop that turns hand-edited footprint into measured AABB so the
auto-research artifact placer has a number it can trust.

Usage:
    python tools/measure_artifact_aabbs.py
    python tools/measure_artifact_aabbs.py --no-run        # use existing report
    python tools/measure_artifact_aabbs.py --dry-run       # show diffs only
    python tools/measure_artifact_aabbs.py --registry transforms
    python tools/measure_artifact_aabbs.py --force         # remeasure even if up-to-date
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GD_SCRIPT = REPO / "commons" / "testing" / "measure_artifacts.gd"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
REPORT_PATH = REPO / "ada_run" / "artifact_measurements.json"

# Default Godot binary; can be overridden with GODOT_EXE env var.
def _find_godot() -> str:
    """Look in a few likely places for the Godot 4 binary on Windows."""
    if os.name != "nt":
        return "godot"
    candidates = [
        r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe",
        r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
        r"C:/Users/palle/Desktop/godot.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return candidates[0]   # let it fail loudly with a clear message


DEFAULT_GODOT = _find_godot()


# ── 1. Run Godot ───────────────────────────────────────────────────
PROGRESS_PATH   = REPO / "ada_run" / "artifact_measurements.progress.txt"
CHECKPOINT_PATH = REPO / "ada_run" / "artifact_measurements.checkpoint.json"
SKIP_LIST_PATH  = REPO / "ada_run" / "artifact_measurements.skip_list.txt"


def _auto_skip_crasher() -> str:
    """If the last progress marker isn't in the checkpoint, that artifact
    crashed Godot. Append it to the skip list and return its name."""
    if not PROGRESS_PATH.exists():
        return ""
    lines = PROGRESS_PATH.read_text(encoding="utf-8").splitlines()
    if not lines:
        return ""
    last = lines[0].strip()
    if not last:
        return ""
    done: set[str] = set()
    if CHECKPOINT_PATH.exists():
        try:
            cp = json.loads(CHECKPOINT_PATH.read_text(encoding="utf-8"))
            for a in cp.get("artifacts", []):
                if isinstance(a, dict) and "lookup_name" in a:
                    done.add(a["lookup_name"])
        except Exception:
            pass
    if last in done:
        return ""
    # Not in the checkpoint = it crashed. Append to skip list (idempotent).
    SKIP_LIST_PATH.parent.mkdir(parents=True, exist_ok=True)
    existing: set[str] = set()
    if SKIP_LIST_PATH.exists():
        existing = {l.strip() for l in SKIP_LIST_PATH.read_text(
            encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")}
    if last not in existing:
        with SKIP_LIST_PATH.open("a", encoding="utf-8") as f:
            f.write(f"{last}\n")
    return last


def run_godot_measurement(registry_filter: str = "") -> int:
    """Spawn Godot headless to run measure_artifacts.gd. Returns exit code."""
    godot = os.environ.get("GODOT_EXE", DEFAULT_GODOT)
    if not Path(godot).exists() and os.name == "nt":
        sys.exit(f"godot not found at {godot}; set GODOT_EXE")
    cmd = [
        godot,
        "--path", str(REPO),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/measure_artifacts.gd",
        "--",
        "--outdir=res://ada_run",
    ]
    if registry_filter:
        cmd.append(f"--registry={registry_filter}")
    print(f"  godot> {' '.join(cmd[:5])} … {' '.join(cmd[-3:])}")
    proc = subprocess.run(cmd, cwd=str(REPO))
    return proc.returncode


# ── 2. Parse report ────────────────────────────────────────────────
def load_report() -> dict:
    if not REPORT_PATH.exists():
        sys.exit(f"no measurement report at {REPORT_PATH} — "
                 f"run without --no-run first")
    return json.loads(REPORT_PATH.read_text(encoding="utf-8"))


# ── 3. Index registries ────────────────────────────────────────────
def index_registry() -> dict[str, tuple[Path, str]]:
    """Map lookup_name → (registry_path, registry_key) for every artifact."""
    out: dict[str, tuple[Path, str]] = {}
    for reg_path in sorted(REGISTRY_DIR.glob("*.json")):
        try:
            data = json.loads(reg_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! skip {reg_path.name}: {e}")
            continue
        arts = data.get("artifacts")
        if not arts:
            continue
        if isinstance(arts, dict):
            for key, entry in arts.items():
                if not isinstance(entry, dict):
                    continue
                lname = entry.get("lookup_name") or key
                out[lname] = (reg_path, key)
        elif isinstance(arts, list):
            for entry in arts:
                if isinstance(entry, dict):
                    lname = entry.get("lookup_name", "")
                    if lname:
                        out[lname] = (reg_path, lname)
    return out


# ── 4. Merge into registry entries ─────────────────────────────────
def merge_aabbs(report: dict, force: bool, dry_run: bool) -> dict:
    index = index_registry()
    updates: dict[Path, dict] = {}     # registry_path → loaded data (cached writes)
    stats = {"updated": 0, "skipped_unchanged": 0, "missing_in_registry": 0,
             "errors_in_report": 0}
    diffs: list[str] = []

    now = datetime.utcnow().isoformat() + "Z"

    for record in report.get("artifacts", []):
        lname = record.get("lookup_name")
        if not lname:
            continue
        if record.get("error"):
            stats["errors_in_report"] += 1
            continue
        loc = index.get(lname)
        if not loc:
            stats["missing_in_registry"] += 1
            continue
        reg_path, key = loc
        if reg_path not in updates:
            updates[reg_path] = json.loads(reg_path.read_text(encoding="utf-8"))
        data = updates[reg_path]
        arts = data.get("artifacts")
        entry = arts[key] if isinstance(arts, dict) else None
        if entry is None and isinstance(arts, list):
            for a in arts:
                if a.get("lookup_name") == lname:
                    entry = a; break
        if entry is None:
            stats["missing_in_registry"] += 1
            continue

        new_payload = {
            "aabb_size":      record.get("aabb_size"),
            "aabb_center":    record.get("aabb_center"),
            "grid_cells":     record.get("grid_cells"),
            "max_dimension_m": record.get("max_dimension_m"),
            "measured_at":    now,
        }
        prior = entry.get("measurements") or {}
        # Skip when the numeric measurements haven't changed and not forced.
        same = all(prior.get(k) == new_payload[k]
                   for k in ("aabb_size", "aabb_center", "grid_cells",
                             "max_dimension_m"))
        if same and not force:
            stats["skipped_unchanged"] += 1
            continue
        diffs.append(
            f"  {lname:40s} {prior.get('grid_cells')!s:>10s} -> "
            f"{new_payload['grid_cells']!s:>10s}  "
            f"max={new_payload['max_dimension_m']}m"
        )
        entry["measurements"] = new_payload
        # Mirror grid_cells onto the top-level footprint hint when there is
        # NO manual footprint set, so the placer has a default. Manual
        # footprints (set in the dressing-room editor) are never overwritten.
        if "footprint" not in entry and new_payload.get("grid_cells"):
            gc = new_payload["grid_cells"]
            # Godot reports [w, d]; pad to [w, h, d] for the registry shape.
            if len(gc) == 2:
                entry["footprint_measured"] = [gc[0], 1, gc[1]]
            elif len(gc) == 3:
                entry["footprint_measured"] = list(gc)
        stats["updated"] += 1

    if not dry_run:
        for reg_path, data in updates.items():
            backup = reg_path.with_suffix(reg_path.suffix + ".bak")
            shutil.copy2(reg_path, backup)
            reg_path.write_text(
                json.dumps(data, indent="\t") + "\n", encoding="utf-8")

    return {"stats": stats, "diffs": diffs, "files": list(updates.keys())}


# ── 5. CLI ─────────────────────────────────────────────────────────
def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--no-run", action="store_true",
                   help="skip Godot, just merge an existing measurement report")
    p.add_argument("--registry", default="",
                   help="limit measurement to one registry file prefix")
    p.add_argument("--dry-run", action="store_true",
                   help="print diffs without writing the registry")
    p.add_argument("--force", action="store_true",
                   help="rewrite registry entries even when measurements match")
    args = p.parse_args()

    if not args.no_run:
        if not GD_SCRIPT.exists():
            sys.exit(f"missing {GD_SCRIPT}")
        # Auto-recovery loop: every Godot crash adds the offending artifact
        # to the skip list and we re-launch from the checkpoint. Cap the
        # number of retries so we don't loop forever on a deep bug.
        MAX_RETRIES = 20
        for attempt in range(MAX_RETRIES):
            rc = run_godot_measurement(args.registry)
            if rc == 0:
                break
            crasher = _auto_skip_crasher()
            if not crasher:
                sys.exit(f"godot exited with {rc} but no crasher detected — bailing")
            print(f"  ! godot crashed on '{crasher}' (rc={rc}); "
                  f"added to skip list, resuming…")
        else:
            sys.exit(f"giving up after {MAX_RETRIES} crashes")
        # Promote checkpoint to final report on success.
        if CHECKPOINT_PATH.exists() and not REPORT_PATH.exists():
            shutil.copy2(CHECKPOINT_PATH, REPORT_PATH)
        elif CHECKPOINT_PATH.exists():
            # Final write happens in the GD script; if it didn't (e.g.
            # premature quit), use the checkpoint instead.
            if REPORT_PATH.stat().st_size < CHECKPOINT_PATH.stat().st_size:
                shutil.copy2(CHECKPOINT_PATH, REPORT_PATH)

    report = load_report()
    print(f"  report: {report.get('measured', '?')} measured, "
          f"{report.get('errors', '?')} errors, "
          f"{report.get('skipped', '?')} skipped")

    result = merge_aabbs(report, force=args.force, dry_run=args.dry_run)
    s = result["stats"]
    print()
    if result["diffs"]:
        print("changes:")
        for d in result["diffs"][:30]:
            print(d)
        if len(result["diffs"]) > 30:
            print(f"  … (+{len(result['diffs']) - 30} more)")
    print()
    print(f"=== merge ===  updated: {s['updated']}  "
          f"unchanged: {s['skipped_unchanged']}  "
          f"missing-in-registry: {s['missing_in_registry']}  "
          f"errors-in-report: {s['errors_in_report']}")
    if args.dry_run:
        print("(dry run — no files written)")
    else:
        print(f"wrote {len(result['files'])} registry file(s); "
              f"backups created with .bak suffix")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
