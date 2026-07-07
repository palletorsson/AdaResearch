#!/usr/bin/env python3
"""build_dressing_map_menu.py — a by-map menu for the dressing-room browsers.

Lets the Godot DressingRoomCatalog3D viewer and the web /dressing-rooms page
organise / filter rooms BY MAP (the way /book is organised by chapter): pick a
sequence -> a map -> see only the artifacts (rooms) that map actually places.

Keyed by DIRECTORY name (the stable id that matches the sequence files), with
the display name carried alongside for the UI. (The existing
doc/artifact_to_maps.json keys by map_info.name, which collides and can't group
by sequence — this is a separate, self-consistent index for the browsers.)

Out (both, so Godot and the web each read a local copy):
  commons/data/artifact_maps.json                # Godot: res://commons/data/...
  ada_encyclopedia/public/artifact-maps.json     # web:  /artifact-maps.json

Shape:
  {
    "artifact_maps": {"<artifact>": ["<mapDir>", ...]},
    "maps":  {"<mapDir>": {"name": "<display>", "seq": "<seqId|'' >", "n": <count>}},
    "sequences": [{"seq": "<id>", "name": "<title>", "maps": ["<mapDir>", ...]}],
    "counts": {"maps": N, "artifacts": N}
  }
"""
from __future__ import annotations
import json, os, glob, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS = os.path.join(ROOT, "commons", "maps")
SEQS = os.path.join(ROOT, "commons", "maps", "sequences")
OUT_ADA = os.path.join(ROOT, "commons", "data", "artifact_maps.json")
OUT_WEB = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia", "public", "artifact-maps.json")

SKIP_TOKENS = {"s", "sp", "t", "origin", "", " "}


def main() -> int:
    art2maps: dict[str, set] = collections.defaultdict(set)
    map_display: dict[str, str] = {}
    map_nart: dict[str, int] = {}

    for md in sorted(glob.glob(os.path.join(MAPS, "*", "map_data.json"))):
        mapdir = os.path.basename(os.path.dirname(md))
        try:
            d = json.load(open(md, encoding="utf-8"))
        except Exception:
            continue
        map_display[mapdir] = str(d.get("map_info", {}).get("name", mapdir))
        here: set = set()
        for row in d.get("layers", {}).get("interactables", []):
            if not isinstance(row, list):
                continue
            for cell in row:
                if not isinstance(cell, str) or not cell.strip():
                    continue
                lk = cell.strip().lstrip("#").split("#", 1)[0].split(":", 1)[0]
                if lk and lk not in SKIP_TOKENS:
                    art2maps[lk].add(mapdir)
                    here.add(lk)
        if here:
            map_nart[mapdir] = len(here)

    # map -> sequence (authoritative, from sequence files; dir names match)
    seq_maps: dict[str, list] = {}
    seq_name: dict[str, str] = {}
    map_seq: dict[str, str] = {}
    for sf in sorted(glob.glob(os.path.join(SEQS, "*.json"))):
        try:
            sd = json.load(open(sf, encoding="utf-8"))
        except Exception:
            continue
        seqs = sd.get("sequences", {})
        if not isinstance(seqs, dict):
            continue
        for sid, s in seqs.items():
            if not isinstance(s, dict):
                continue
            ms = [m for m in (s.get("maps", []) or []) if isinstance(m, str)]
            if not ms:
                continue
            seq_name[sid] = str(s.get("name", sid))
            bucket = seq_maps.setdefault(sid, [])
            for m in ms:
                if m not in bucket:
                    bucket.append(m)
                map_seq.setdefault(m, sid)

    # maps that carry artifacts but sit in no sequence
    placed = set(map_nart.keys())
    unseq = sorted(m for m in placed if m not in map_seq)

    maps_out = {}
    for m in sorted(placed):
        maps_out[m] = {"name": map_display.get(m, m), "seq": map_seq.get(m, ""), "n": map_nart.get(m, 0)}

    sequences = []
    for sid in sorted(seq_maps, key=lambda s: seq_name.get(s, s).lower()):
        # only maps that actually place artifacts, keep sequence order
        ms = [m for m in seq_maps[sid] if m in placed]
        if ms:
            sequences.append({"seq": sid, "name": seq_name.get(sid, sid), "maps": ms})
    if unseq:
        sequences.append({"seq": "(unsequenced)", "name": "Unsequenced", "maps": unseq})

    out = {
        "artifact_maps": {a: sorted(ms) for a, ms in sorted(art2maps.items())},
        "maps": maps_out,
        "sequences": sequences,
        "counts": {"maps": len(placed), "artifacts": len(art2maps)},
    }
    for path in (OUT_ADA, OUT_WEB):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        json.dump(out, open(path, "w", encoding="utf-8"), separators=(",", ":"))
        print("wrote %s  (%d KB)" % (os.path.relpath(path, os.path.dirname(ROOT)), os.path.getsize(path) // 1024))
    print("artifacts=%d  maps=%d  sequences=%d (+unsequenced)" % (len(art2maps), len(placed), len(sequences)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
