#!/usr/bin/env python3
"""Generate default dressing rooms for every artifact that doesn't have one.

Default = "on a pillar" — a 3x3 walkable floor with a plinth (tile value 3)
at the centre anchor. The artifact sits on the plinth.

Scans:  commons/artifacts/registry/*.json
Writes: commons/artifacts/dressing_rooms/<lookup_name>.json (only if missing)

Usage:
    python tools/generate_default_dressing_rooms.py            # dry-run, lists what would be written
    python tools/generate_default_dressing_rooms.py --write    # actually write the files
    python tools/generate_default_dressing_rooms.py --write --only=arrays,grid2d   # filter
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"


def default_room(lookup_name: str) -> dict:
    return {
        "lookup_name": lookup_name,
        "footprint": [1, 1, 1],
        "rotations": ["0", "90", "180", "270"],
        "approach": "south",
        "exit": "north",
        "footing": {
            "anchor": [1, 1],
            "tiles": [
                [1, 1, 1],
                [1, 3, 1],
                [1, 1, 1],
            ],
        },
        "extras": [],
        "artifact_offset": [0.0, 0.0, 0.0],
        "clearance": [3, 3, 3],
    }


def collect_registry_lookups(only: set[str] | None) -> list[tuple[str, str]]:
    """Returns list of (lookup_name, source_registry_filename)."""
    out: list[tuple[str, str]] = []
    for reg in sorted(REGISTRY_DIR.glob("*.json")):
        if only and reg.stem not in only:
            continue
        try:
            data = json.loads(reg.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! could not parse {reg.name}: {e}")
            continue
        artifacts = data.get("artifacts", data) if isinstance(data, dict) else {}
        if not isinstance(artifacts, dict):
            continue
        for key, entry in artifacts.items():
            if not isinstance(entry, dict):
                continue
            lookup = entry.get("lookup_name") or key
            if not isinstance(lookup, str) or not lookup:
                continue
            out.append((lookup, reg.name))
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--write", action="store_true", help="actually write files (default is dry-run)")
    p.add_argument("--only", type=str, default="", help="comma-separated registry stems to limit to")
    args = p.parse_args()

    only = {s.strip() for s in args.only.split(",") if s.strip()} or None

    if not ROOMS_DIR.exists():
        ROOMS_DIR.mkdir(parents=True, exist_ok=True)

    existing = {p.stem for p in ROOMS_DIR.glob("*.json")}
    print(f"Existing dressing rooms: {len(existing)}")

    lookups = collect_registry_lookups(only)
    print(f"Total artifact entries scanned: {len(lookups)}")

    seen: set[str] = set()
    to_write: list[tuple[str, str]] = []
    duplicates = 0
    for lookup, source in lookups:
        if lookup in seen:
            duplicates += 1
            continue
        seen.add(lookup)
        if lookup in existing:
            continue
        to_write.append((lookup, source))

    print(f"Unique artifacts: {len(seen)}  (duplicates skipped: {duplicates})")
    print(f"Already covered:  {len(seen & existing)}")
    print(f"Will create:      {len(to_write)}")

    if not args.write:
        print("\n[dry-run]  pass --write to create files. First 30 candidates:")
        for lookup, src in to_write[:30]:
            print(f"  + {lookup:<40s}  <- {src}")
        if len(to_write) > 30:
            print(f"  ... and {len(to_write) - 30} more")
        return 0

    written = 0
    for lookup, _src in to_write:
        path = ROOMS_DIR / f"{lookup}.json"
        path.write_text(json.dumps(default_room(lookup), indent=2), encoding="utf-8")
        written += 1
    print(f"\nWrote {written} default dressing rooms to {ROOMS_DIR.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
