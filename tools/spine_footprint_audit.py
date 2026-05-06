#!/usr/bin/env python
"""
spine_footprint_audit.py — audit spine maps against the 8x16 runner footprint.

The SpineRunner expects every corridor map to be shaped:
  - 16 rows deep (z-axis)
  - 8  cols wide (x-axis)
  - spawn at row ~1, teleporter at row ~14-15 (both near col 3-4)

This script walks the curriculum spine, loads each map's JSON, and reports
which maps already conform and which need resizing or spawn/teleporter
relocation.

Usage:
    python tools/spine_footprint_audit.py
    python tools/spine_footprint_audit.py --sequence primitives
    python tools/spine_footprint_audit.py --json  # machine-readable output
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SPINE_JSON = REPO / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"

TARGET_ROWS = 16   # z
TARGET_COLS = 8    # x
SPAWN_ROW_MAX = 3          # spawn must be in first 3 rows (south edge)
TELE_ROW_MIN = TARGET_ROWS - 3   # teleporter must be in last 3 rows (north edge)


def load_spine_queue() -> list[tuple[str, str]]:
    """Return list of (sequence_name, map_name) in spine order."""
    spine = json.loads(SPINE_JSON.read_text(encoding="utf-8"))
    seqs = sorted(
        spine.get("spine", {}).get("sequences", []),
        key=lambda s: int(s.get("order", 999)),
    )
    out: list[tuple[str, str]] = []
    for seq in seqs:
        name = seq.get("name", "")
        if not name:
            continue
        sp = SEQ_DIR / f"{name}.json"
        if not sp.exists():
            continue
        data = json.loads(sp.read_text(encoding="utf-8"))
        entry = data.get("sequences", {}).get(name, {})
        for m in entry.get("maps", []):
            out.append((name, str(m)))
    return out


def audit_map(map_name: str) -> dict:
    """Return audit dict for one map."""
    path = MAPS_DIR / map_name / "map_data.json"
    if not path.exists():
        return {"map": map_name, "status": "MISSING", "reasons": ["map_data.json not found"]}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return {"map": map_name, "status": "INVALID_JSON", "reasons": [str(e)]}

    layers = data.get("layers", {})
    structure = layers.get("structure", [])
    utilities = layers.get("utilities", [])
    rows = len(structure)
    cols = len(structure[0]) if rows > 0 and isinstance(structure[0], list) else 0

    reasons: list[str] = []

    # Footprint check
    footprint_ok = rows == TARGET_ROWS and cols == TARGET_COLS
    if not footprint_ok:
        reasons.append(f"footprint {rows}x{cols} (want {TARGET_ROWS}x{TARGET_COLS})")

    # Spawn + teleporter check (scan utilities layer)
    spawn_pos: tuple[int, int] | None = None
    tele_pos: tuple[int, int] | None = None
    for r, row in enumerate(utilities):
        if not isinstance(row, list):
            continue
        for c, cell in enumerate(row):
            token = str(cell).strip()
            if not token:
                continue
            head = token.split(":", 1)[0]
            if head == "sp" and spawn_pos is None:
                spawn_pos = (r, c)
            elif head == "t" and tele_pos is None:
                tele_pos = (r, c)

    if spawn_pos is None:
        reasons.append("no spawn (sp) in utilities")
    elif spawn_pos[0] > SPAWN_ROW_MAX:
        reasons.append(f"spawn at row {spawn_pos[0]} (want <= {SPAWN_ROW_MAX})")

    if tele_pos is None:
        reasons.append("no teleporter (t) in utilities")
    elif tele_pos[0] < TELE_ROW_MIN:
        reasons.append(f"teleporter at row {tele_pos[0]} (want >= {TELE_ROW_MIN})")

    status = "OK" if not reasons else ("RESIZE" if not footprint_ok else "RELOCATE")
    return {
        "map": map_name,
        "status": status,
        "rows": rows,
        "cols": cols,
        "spawn": list(spawn_pos) if spawn_pos else None,
        "teleporter": list(tele_pos) if tele_pos else None,
        "reasons": reasons,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", help="audit one sequence only")
    ap.add_argument("--json", action="store_true", help="machine-readable JSON output")
    ap.add_argument("--only-bad", action="store_true", help="skip OK maps in text output")
    args = ap.parse_args()

    queue = load_spine_queue()
    if args.sequence:
        queue = [(s, m) for (s, m) in queue if s == args.sequence]
        if not queue:
            print(f"no maps found for sequence '{args.sequence}'", file=sys.stderr)
            return 1

    reports: list[dict] = []
    for seq, m in queue:
        r = audit_map(m)
        r["sequence"] = seq
        reports.append(r)

    if args.json:
        print(json.dumps({"target": [TARGET_ROWS, TARGET_COLS], "reports": reports}, indent=2))
        return 0

    # Text mode
    buckets = {"OK": 0, "RESIZE": 0, "RELOCATE": 0, "MISSING": 0, "INVALID_JSON": 0}
    print(f"Spine footprint audit -- target {TARGET_ROWS}x{TARGET_COLS} (rows x cols)")
    print(f"Spawn must be row <= {SPAWN_ROW_MAX}, teleporter row >= {TELE_ROW_MIN}")
    print("-" * 72)
    current_seq = ""
    for r in reports:
        buckets[r["status"]] = buckets.get(r["status"], 0) + 1
        if args.only_bad and r["status"] == "OK":
            continue
        if r["sequence"] != current_seq:
            current_seq = r["sequence"]
            print(f"\n-- {current_seq} --")
        tag = {"OK": "OK", "RESIZE": "RZ", "RELOCATE": "MV", "MISSING": "??", "INVALID_JSON": "!!"}.get(r["status"], "..")
        size = f"{r.get('rows', '?')}x{r.get('cols', '?')}"
        reasons = "; ".join(r["reasons"]) if r["reasons"] else ""
        print(f"  [{tag}] {r['map']:<40s} {size:>8s}  {reasons}")

    print("\n" + "-" * 72)
    total = len(reports)
    print(f"Total: {total}   OK: {buckets['OK']}   RESIZE: {buckets['RESIZE']}   RELOCATE: {buckets['RELOCATE']}   MISSING: {buckets['MISSING']}   INVALID: {buckets['INVALID_JSON']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
