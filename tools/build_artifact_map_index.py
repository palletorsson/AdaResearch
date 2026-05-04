#!/usr/bin/env python3
"""
build_artifact_map_index.py
============================

For every artifact, find the maps it actually appears in. Walks every
commons/maps/<MapName>/map_data.json, parses the interactables layer,
and indexes which artifact tokens occur where.

Result: doc/artifact_to_maps.json — `{artifact_lookup: [{map: "X",
cells: [[x, z], ...], sequence: "Y"}]}` — used by /api/research-loop
to pick a "native" target map for in-context captures.

Run:
    python tools/build_artifact_map_index.py
"""

from __future__ import annotations
import json
import re
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS_DIR = REPO / "commons" / "maps"
DOC_OUT = REPO / "doc"
WEB_OUT = REPO.parent / "ada_encyclopedia" / "public" / "research-map"

# Token format: lookup_name[:rotation[:y_offset]][#param:value...]
TOKEN_RE = re.compile(r"^([a-zA-Z][a-zA-Z0-9_]*)")


def extract_lookup(token: str) -> str | None:
    s = token.strip()
    if not s or s in {" ", "  ", "0", "1", "2", "3", "4", "5"}:
        return None
    m = TOKEN_RE.match(s)
    return m.group(1) if m else None


def main():
    if not MAPS_DIR.exists():
        print(f"No maps dir at {MAPS_DIR}")
        return

    artifact_to_maps: dict[str, list[dict]] = defaultdict(list)
    map_count = 0
    artifact_hit_count = 0

    for map_dir in sorted(MAPS_DIR.iterdir()):
        if not map_dir.is_dir():
            continue
        md = map_dir / "map_data.json"
        if not md.exists():
            continue
        try:
            data = json.loads(md.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        map_count += 1

        info = data.get("map_info", {})
        map_name = info.get("name", map_dir.name)
        sequence = info.get("sequence_name") or info.get("sequence") or ""

        layers = data.get("layers", {})
        inter = layers.get("interactables", [])

        # Track per-(map, artifact) cells
        cells_by_lookup: dict[str, list[list[int]]] = defaultdict(list)

        for z, row in enumerate(inter):
            if not isinstance(row, list):
                continue
            for x, cell in enumerate(row):
                if not isinstance(cell, str):
                    continue
                lookup = extract_lookup(cell)
                if not lookup:
                    continue
                cells_by_lookup[lookup].append([x, z])

        for lookup, cells in cells_by_lookup.items():
            artifact_to_maps[lookup].append({
                "map": map_name,
                "cells": cells,
                "sequence": sequence,
                "n_occurrences": len(cells),
            })
            artifact_hit_count += 1

    # Sort each artifact's map list: real curricular maps first (deprioritize
    # AutoGen / Test scaffolding), then by n_occurrences descending, then name.
    def _is_scaffold(name: str) -> bool:
        n = (name or "").lower()
        return ("autogen" in n or n.startswith("test") or "_test" in n
                or n.startswith("ecology_autogen"))
    for lookup in artifact_to_maps:
        artifact_to_maps[lookup].sort(
            key=lambda m: (1 if _is_scaffold(m["map"]) else 0,
                           -m["n_occurrences"], m["map"]))

    out = {
        "schema_version": 1,
        "totals": {
            "maps_scanned": map_count,
            "artifacts_indexed": len(artifact_to_maps),
            "artifact_placements": artifact_hit_count,
        },
        "artifact_to_maps": dict(sorted(artifact_to_maps.items())),
    }

    DOC_OUT.mkdir(parents=True, exist_ok=True)
    out_path = DOC_OUT / "artifact_to_maps.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Also feed the encyclopedia.
    WEB_OUT.mkdir(parents=True, exist_ok=True)
    (WEB_OUT / "artifact_to_maps.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    print(f"Scanned {map_count} maps")
    print(f"Indexed {len(artifact_to_maps)} unique artifact lookups across {artifact_hit_count} placements")
    print(f"Wrote: doc/artifact_to_maps.json")
    print(f"       ada_encyclopedia/public/research-map/artifact_to_maps.json")
    print()
    print("Top artifacts by map count:")
    by_map_count = sorted(artifact_to_maps.items(), key=lambda x: -len(x[1]))
    for lookup, maps in by_map_count[:10]:
        print(f"  {lookup:30s}  {len(maps):3d} maps  e.g. {maps[0]['map']}")


if __name__ == "__main__":
    main()
