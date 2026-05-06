#!/usr/bin/env python3
"""Derive a spatial profile for every artifact from its measured AABB.

For each registry entry that already has `measurements.aabb_size` (from
tools/measure_artifact_aabbs.py), this writes a `spatial_profile` block:

    spatial_profile: {
        dir_group:       omni | panel | plane | floor | ceiling | corner
        range:           1–100 (cells of effect / claim radius)
        density:         high | medium | low | field
        min_clearance:   0–3 (empty cells the placer should leave)
        stack_priority:  0.0–1.0 (who wins overlap; 1 = dominant)
        approach_dir:    "front" | "any"
        derived_at:      timestamp
        derived_from:    "aabb_size + category"  (or "manual" if user edits)
    }

Existing `spatial_profile.derived_from == "manual"` entries are NEVER
overwritten. The auto-detection only fills slots that don't have a hand
edit. This is the same contract as measurements vs footprint.

Heuristics (paraphrased):
    nearly cubic, max_dim < 0.5m              → omni, range=1, density=high
    one face thin (panel),    h > 0.5m         → panel, range=2, density=high
    short and wide flat,      h < 0.3 of dims  → plane / field, range from area
    man-tall, mixed dims                       → floor, range scales with width
    huge >= 4m max_dim                         → landscape, density=high

Usage:
    python tools/derive_spatial_profile.py
    python tools/derive_spatial_profile.py --dry-run
    python tools/derive_spatial_profile.py --registry transforms
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REG_DIR = REPO / "commons" / "artifacts" / "registry"


# ── Auto-detection ──────────────────────────────────────────────────
def detect_dir_group(aabb: list[float], max_dim: float) -> str:
    """Pick orientation class from the bounding box shape."""
    if not aabb or len(aabb) != 3 or max_dim <= 0:
        return "omni"
    w, h, d = aabb
    horiz_max = max(w, d)
    if max_dim < 0.4:
        return "omni"                                   # tiny, places anywhere
    if h < 0.30 * horiz_max and horiz_max > 0.5:
        return "plane"                                  # short and wide, sits on top
    if min(w, d) < 0.25 * horiz_max and h > 0.5:
        return "panel"                                  # one face thin → wall
    cube_like = (
        abs(w - h) / max_dim < 0.20 and
        abs(d - h) / max_dim < 0.20 and
        max_dim < 1.5
    )
    if cube_like:
        return "omni"
    return "floor"                                       # gravity-anchored default


def detect_range(max_dim_m: float) -> int:
    """Map physical max-dim to a cell-count radius. Capped at 100.
    Most teaching artifacts are 1–5; fields/floors 6–15;
    landscapes 16–100."""
    if max_dim_m <= 0:
        return 1
    if max_dim_m <= 0.4: return 1
    if max_dim_m <= 1.0: return 2
    if max_dim_m <= 2.0: return 4
    if max_dim_m <= 3.0: return 6
    if max_dim_m <= 5.0: return 10
    if max_dim_m <= 10.0: return 18
    if max_dim_m <= 20.0: return 35
    if max_dim_m <= 40.0: return 60
    return min(100, int(max_dim_m * 1.5))


# Category-based density priors. Tunable; manual override beats this.
DENSITY_BY_CATEGORY = {
    "carpet":        "field",
    "mosaic":        "field",
    "floor":         "field",
    "biome":         "field",
    "ring":          "field",
    "rug":           "field",
    "wall":          "high",
    "panel":         "high",
    "screen":        "high",
    "plinth":        "high",
    "pillar":        "high",
    "pedestal":      "high",
    "tutorial":      "medium",
    "reading":       "medium",
    "label":         "low",
    "particle":      "low",
    "ambient":       "low",
    "sound":         "low",
}


def detect_density(entry: dict, dir_group: str, max_dim_m: float) -> str:
    """Pick density bucket from category + tags + size."""
    # Build a token set rather than a blob substring search — substring
    # search is too loose (e.g., "string_search" contains "ring", which
    # would falsely match the "ring → field" rule).
    import re
    parts = [
        str(entry.get("category", "")),
        *(entry.get("tags") or []),
        *(entry.get("dev_themes") or []),
        str(entry.get("name", "")),
        str(entry.get("lookup_name", "")),
    ]
    tokens: set[str] = set()
    for p in parts:
        for t in re.split(r"[\s_\-/]+", str(p).lower()):
            if t: tokens.add(t)
    for key, dens in DENSITY_BY_CATEGORY.items():
        if key in tokens:
            return dens
    # Fall back on shape:
    if dir_group == "plane" and max_dim_m >= 1.5:
        return "field"             # broad-and-flat → atmospheric carpet
    if dir_group in ("panel", "pedestal"):
        return "high"
    if max_dim_m >= 4.0:
        return "high"              # large landscapes claim their cells
    return "medium"


def detect_clearance(dir_group: str, density: str, max_dim_m: float) -> int:
    if density == "field": return 0      # fields invite overlap
    if density == "low": return 0
    if dir_group == "panel": return 1
    if max_dim_m >= 3.0: return 2
    return 1


def detect_stack_priority(dir_group: str, density: str) -> float:
    """1.0 = dominant (others move out of the way), 0.0 = submissive."""
    if density == "high":
        return 0.85 if dir_group in ("panel", "floor", "omni") else 0.7
    if density == "field":
        return 0.30                       # fields yield to focus
    if density == "low":
        return 0.10
    return 0.50


def detect_approach_dir(dir_group: str) -> str:
    return "front" if dir_group == "panel" else "any"


# ── Profile build ──────────────────────────────────────────────────
def build_profile(entry: dict) -> dict | None:
    """Derive a spatial_profile from the entry's measurements + category.
    Returns None if no measurements exist (skip)."""
    measurements = entry.get("measurements") or {}
    aabb = measurements.get("aabb_size")
    max_dim = measurements.get("max_dimension_m") or 0.0
    if not aabb or max_dim <= 0:
        return None
    dir_group = detect_dir_group(aabb, max_dim)
    rng = detect_range(max_dim)
    dens = detect_density(entry, dir_group, max_dim)
    clear = detect_clearance(dir_group, dens, max_dim)
    prio = detect_stack_priority(dir_group, dens)
    return {
        "dir_group":      dir_group,
        "range":          rng,
        "density":        dens,
        "min_clearance":  clear,
        "stack_priority": round(prio, 2),
        "approach_dir":   detect_approach_dir(dir_group),
        "derived_at":     datetime.utcnow().isoformat() + "Z",
        "derived_from":   "aabb_size + category",
    }


# ── Walk the registry ──────────────────────────────────────────────
def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true",
                   help="report changes without writing")
    p.add_argument("--registry", default="",
                   help="limit to one registry file (substring match)")
    args = p.parse_args()

    files = sorted(REG_DIR.glob("*.json"))
    if args.registry:
        files = [f for f in files if args.registry in f.name]
    if not files:
        print("no registry files found"); return 1

    stats = {"updated": 0, "manual_kept": 0, "no_measurements": 0,
             "files_written": 0}
    by_dir_group: dict[str, int] = {}
    by_density: dict[str, int] = {}
    samples: list[str] = []

    for reg_path in files:
        try:
            data = json.loads(reg_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! skip {reg_path.name}: {e}"); continue
        arts = data.get("artifacts")
        if not isinstance(arts, dict):
            continue
        touched = False
        for key, entry in arts.items():
            if not isinstance(entry, dict): continue
            existing = entry.get("spatial_profile") or {}
            if existing.get("derived_from") == "manual":
                stats["manual_kept"] += 1
                continue
            new_profile = build_profile(entry)
            if not new_profile:
                stats["no_measurements"] += 1
                continue
            if not args.dry_run:
                entry["spatial_profile"] = new_profile
                touched = True
            stats["updated"] += 1
            by_dir_group[new_profile["dir_group"]] = by_dir_group.get(new_profile["dir_group"], 0) + 1
            by_density[new_profile["density"]] = by_density.get(new_profile["density"], 0) + 1
            if len(samples) < 18:
                lname = entry.get("lookup_name") or key
                samples.append(
                    f"  {lname:38s} dir={new_profile['dir_group']:6s} "
                    f"range={new_profile['range']:3d} "
                    f"density={new_profile['density']:6s} "
                    f"clear={new_profile['min_clearance']} "
                    f"prio={new_profile['stack_priority']}"
                )
        if touched and not args.dry_run:
            shutil.copy2(reg_path, reg_path.with_suffix(reg_path.suffix + ".bak"))
            reg_path.write_text(json.dumps(data, indent="\t") + "\n",
                                encoding="utf-8")
            stats["files_written"] += 1

    print()
    print("=== samples ===")
    for s in samples: print(s)

    print()
    print("=== by dir_group ===")
    for k, v in sorted(by_dir_group.items(), key=lambda x: -x[1]):
        print(f"  {k:8s} {v}")
    print()
    print("=== by density ===")
    for k, v in sorted(by_density.items(), key=lambda x: -x[1]):
        print(f"  {k:8s} {v}")
    print()
    print(f"=== summary ===")
    print(f"  updated:          {stats['updated']}")
    print(f"  manual kept:      {stats['manual_kept']}")
    print(f"  no measurements:  {stats['no_measurements']}")
    print(f"  files written:    {stats['files_written']}")
    if args.dry_run:
        print("(dry run — no writes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
