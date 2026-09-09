#!/usr/bin/env python
"""
build_shelf_index.py — one row per artifact that has been PHOTOGRAPHED, joining
what it is, where it stands, and whether it stands anywhere at all.

2026-09-09, Palle: "make a gallery where I can see the individual artifact not
in their maps."

There was no such view. /artifact-gallery is a curated seventeen-prop showcase,
/artifacts renders "0 registries, 0 artifacts", and /artifact/<token> shows one
artifact at a time and only if you already know its name. Meanwhile
sync_artifact_captures.py had put 1,932 tokens' worth of angles on disk and
nothing browsed them.

THE COLUMN THAT MATTERS IS `placements`. Five artifacts were built, compiled,
captured and registered with map_ready: true on 2026-09-09, and a regex over all
2,799 maps found them in ZERO of them — map_ready is a claim, not a fact. The
same sweep found 59 artifacts that read other artifacts' source code and stand
in no room. An artifact nobody can walk up to is a file, and the only way to see
how many of those there are is to put the number beside the picture.

  python tools/build_shelf_index.py
  -> <encyclopedia>/public/artifact-gallery/shelf.json

Re-run after any capture sync or any placement. It reads only; it writes one
file, into the web app's public directory, never into the repo's data.
"""
from __future__ import annotations

import io
import json
import os
import re
import sys
import time
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

REPO = Path(__file__).resolve().parent.parent
ENCY = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", REPO.parent / "ada_encyclopedia"))
MANIFEST = ENCY / "public" / "artifact-gallery" / "captures" / "manifest.json"
OUT = ENCY / "public" / "artifact-gallery" / "shelf.json"

MAPS = REPO / "commons" / "maps"
REGISTRY = REPO / "commons" / "artifacts" / "registry"

# A placement cell is "<token>" or "<token>:<rot>[:y[:scale]]" with an optional
# "#key:value" tail. Everything before the first colon or hash is the token.
CELL = re.compile(r"^([A-Za-z0-9_]+)")


def read_json(p: Path, default=None):
    try:
        return json.loads(io.open(p, encoding="utf-8").read())
    except Exception:
        return default


def registry_rows() -> dict:
    """token -> the fields the shelf shows. Registry files are token-keyed dicts,
    sometimes wrapped in an "artifacts" key and sometimes not."""
    out: dict = {}
    for p in sorted(REGISTRY.glob("*.json")):
        d = read_json(p)
        if not isinstance(d, dict):
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        for token, v in arts.items():
            if not isinstance(v, dict) or "lookup_name" not in v and "scene" not in v:
                continue
            seq = v.get("sequence") or ""
            if not seq:
                ms = v.get("map_sequences")
                if isinstance(ms, list) and ms:
                    seq = str(ms[0])
            out[token] = {
                "name": str(v.get("name") or token),
                "sequence": str(seq),
                "category": str(v.get("category") or ""),
                "description": str(v.get("description") or "")[:400],
                "scene": str(v.get("scene") or ""),
                "registry": p.name,
                # a family declares axes; a singleton does not
                "promoted": bool(isinstance(v.get("dna"), dict) and v["dna"].get("axes")),
            }
    return out


def placement_counts() -> tuple[dict, int]:
    """token -> number of DISTINCT maps placing it. Distinct maps, not cells: a
    room that stands the same piece three times has still met it once."""
    counts: dict = {}
    n_maps = 0
    for md in MAPS.glob("*/map_data.json"):
        d = read_json(md)
        if not isinstance(d, dict):
            continue
        layers = d.get("layers", d)
        rows = layers.get("interactables") if isinstance(layers, dict) else None
        if not isinstance(rows, list):
            continue
        n_maps += 1
        here = set()
        for row in rows:
            if not isinstance(row, list):
                continue
            for cell in row:
                s = str(cell).strip()
                if not s:
                    continue
                m = CELL.match(s)
                if m:
                    here.add(m.group(1))
        for t in here:
            counts[t] = counts.get(t, 0) + 1
    return counts, n_maps


def main() -> int:
    man = read_json(MANIFEST)
    if not man or not isinstance(man.get("captures"), dict):
        print("no capture manifest at %s — run tools/sync_artifact_captures.py first" % MANIFEST)
        return 1
    caps = man["captures"]
    reg = registry_rows()
    placed, n_maps = placement_counts()

    rows = []
    for token, entry in sorted(caps.items()):
        angles = entry.get("angles") or []
        if not angles:
            continue
        r = reg.get(token, {})
        rows.append({
            "token": token,
            "name": r.get("name", token),
            "sequence": r.get("sequence", ""),
            "category": r.get("category", ""),
            "description": r.get("description", ""),
            "promoted": r.get("promoted", False),
            "in_registry": token in reg,
            "placements": placed.get(token, 0),
            "angles": angles,
            # the tile image; front if we have it, else whatever came back
            "tile": "front" if "front" in angles else angles[0],
        })

    unplaced = sum(1 for r in rows if r["placements"] == 0)
    orphan = sum(1 for r in rows if not r["in_registry"])
    doc = {
        "_doc": ("Generated by tools/build_shelf_index.py. One row per captured artifact, "
                 "joining the capture manifest, the registry and a placement count over every "
                 "map. Images are served at /artifact-gallery/captures/<token>/<angle>.png."),
        "generated_at": int(time.time()),
        "maps_scanned": n_maps,
        "count": len(rows),
        "unplaced": unplaced,
        "not_in_registry": orphan,
        "rows": rows,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    io.open(OUT, "w", encoding="utf-8", newline="").write(json.dumps(doc, ensure_ascii=False) + "\n")
    print("%d captured artifact(s) across %d maps" % (len(rows), n_maps))
    print("  %d stand in no map at all" % unplaced)
    print("  %d are not in any registry (a capture with no entry behind it)" % orphan)
    print("  -> %s" % OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
