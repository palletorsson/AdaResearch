#!/usr/bin/env python3
"""Import auto-research gallery entries into the spine as playable maps.

Each gallery — pattern, facade, soft-body — is already an auto-research
output but lives outside the spine. This tool wraps each entry as a
real `commons/maps/<id>/map_data.json` so the encyclopedia can play it
through `/map-3d/<id>` and the variant pipeline can pull it like any
other base map.

The three galleries map to spine sequences as agreed:
    pattern-gallery   → array_tutorial   (plane composition)
    facade-gallery    → array_tutorial   (architectural composition)
    soft-body-gallery → softbodies       (creature/body composition)

Usage:
    python tools/import_gallery.py pattern
    python tools/import_gallery.py facade --force
    python tools/import_gallery.py soft-body
    python tools/import_gallery.py all

Each imported map gets:
    - structure: floor (h=1) with optional back wall (h=2 or h=3)
    - spawn at (1, 1)
    - teleporter at the far side
    - one central interactable slot the gallery's source token can occupy
    - metadata.imported_from = gallery id, links back to the gallery
      manifest entry so the encyclopedia can render a "imported from
      pattern-gallery" chip on the card.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from iso_voxel_render import render_iso        # noqa: E402

ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"

GALLERIES = {
    "pattern": {
        "manifest_dir":  ENCYCLOPEDIA / "public" / "pattern-gallery",
        "sequence":      "array_tutorial",
        "name_prefix":   "Pattern",
        "rows": 10, "cols": 10,
        "back_wall":     False,    # patterns are read on the floor
        "blurb":         "Plane-composition study sourced from the pattern gallery. The wallpaper-group repetition is the lesson.",
    },
    "facade": {
        "manifest_dir":  ENCYCLOPEDIA / "public" / "facade-gallery",
        "sequence":      "array_tutorial",
        "name_prefix":   "Facade",
        "rows": 12, "cols": 14,
        "back_wall":     True,     # facade reads as a wall
        "blurb":         "Architectural-composition study sourced from the facade gallery. Bays × stories as composed parts.",
    },
    "soft-body": {
        "manifest_dir":  ENCYCLOPEDIA / "public" / "soft-body-gallery",
        "sequence":      "softbodies",
        "name_prefix":   "SoftBody",
        "rows": 12, "cols": 12,
        "back_wall":     False,    # body sits in an open arena
        "blurb":         "Soft-body study sourced from the DNA soft-body gallery. The creature is the artifact.",
    },
}


def _safe_name(s: str) -> str:
    """Sanitize an arbitrary id into a folder/lookup name."""
    out = []
    for ch in s:
        if ch.isalnum() or ch in ("_", "-"):
            out.append(ch)
        else:
            out.append("_")
    return "".join(out).strip("_")


def _make_map_data(gallery_id: str, entry: dict, cfg: dict) -> tuple[str, dict]:
    """Wrap a single gallery entry as a map_data.json. Returns
    (map_name, map_data_dict)."""
    rows = cfg["rows"]
    cols = cfg["cols"]
    back_wall = cfg["back_wall"]
    name_prefix = cfg["name_prefix"]
    sequence = cfg["sequence"]
    eid = _safe_name(entry.get("id", "unknown"))
    map_name = f"{name_prefix}_{eid}"

    # Structure: 1-thick wall border, h=1 floor inside.
    struct = [["0"] * cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            on_edge = (r == 0 or r == rows - 1 or c == 0 or c == cols - 1)
            if on_edge:
                struct[r][c] = "0"
            else:
                struct[r][c] = "1"
    # Optional back wall: facade lives on the far side as a tall wall.
    if back_wall:
        for c in range(1, cols - 1):
            struct[1][c] = "3"        # 3-tall back wall

    # Utilities: spawn at (1,1), teleport opposite corner on the floor.
    utils = [[" "] * cols for _ in range(rows)]
    utils[1][1] = "sp"
    # If back-wall row took (1, 1..cols-1), put spawn at (rows-2, 1) instead.
    if back_wall:
        utils[1][1] = " "
        struct[rows - 2][1] = "1"
        utils[rows - 2][1] = "sp"
        utils[rows - 2][cols - 2] = "t"
    else:
        utils[rows - 2][cols - 2] = "t"

    # Interactables: place the gallery's source token at the central
    # cell. We don't have a single "this is the gallery viewer" artifact,
    # so use a sentinel that the encyclopedia map-3d viewer can render
    # generically (a blue ball) — and put the gallery image link in
    # metadata so the player can open the source.
    interact = [[" "] * cols for _ in range(rows)]
    cr = (rows // 2) + (1 if back_wall else 0)
    cc = cols // 2
    if back_wall: cr = max(3, rows // 2)   # under the back wall
    interact[cr][cc] = f"gallery_marker_{gallery_id}:0:0.5"

    map_data = {
        "map_info": {
            "name":         map_name.replace("_", " "),
            "lookup_name":  map_name,
            "title":        entry.get("notes", "") or map_name.replace("_", " "),
            "description":  cfg["blurb"] + (" — " + entry.get("notes", "") if entry.get("notes") else ""),
            "format":       "json",
            "version":      "1.0",
            "dimensions":   {"depth": rows, "width": cols, "max_height": 3 if back_wall else 1},
            "metadata": {
                "category":          "imported_gallery",
                "spine_research":    True,
                "imported_from":     gallery_id,
                "source_entry_id":   entry.get("id"),
                "source_image":      entry.get("image"),
                "source_config":     entry.get("config"),
                "sequence":          sequence,
                "saved_at":          datetime.utcnow().isoformat() + "Z",
            },
        },
        "layers": {
            "structure":     struct,
            "utilities":     utils,
            "interactables": interact,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.10, 0.10, 0.20]},
        },
        "lighting": {
            "ambient_color": [0.45, 0.50, 0.65],
            "ambient_energy": 0.6,
            "directional_light": {
                "enabled": True, "color": [1.0, 0.92, 0.78],
                "direction": [-0.5, -0.8, -0.4], "energy": 1.3,
            },
        },
        "utility_definitions": {
            "sp": {"description": "Player spawn", "type": "spawn"},
            "t":  {"description": "Teleport — next map in sequence",
                   "type": "teleporter",
                   "properties": {"action": "next_in_sequence"}},
        },
    }
    return map_name, map_data


def _heights_grid(struct: list[list[str]]) -> list[list[int]]:
    return [[int(c) for c in row] for row in struct]


def import_one(gallery_id: str, force: bool) -> dict:
    cfg = GALLERIES[gallery_id]
    manifest_path = cfg["manifest_dir"] / "manifest.json"
    if not manifest_path.exists():
        return {"gallery": gallery_id, "error": f"missing {manifest_path}"}
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])
    written = []
    skipped = 0
    map_names: list[str] = []
    for entry in entries:
        map_name, map_data = _make_map_data(gallery_id, entry, cfg)
        out_dir = MAPS_DIR / map_name
        out_path = out_dir / "map_data.json"
        if out_path.exists() and not force:
            skipped += 1
            map_names.append(map_name)
            continue
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(map_data, indent=2), encoding="utf-8")
        # Iso thumbnail.
        try:
            render_iso(_heights_grid(map_data["layers"]["structure"]),
                       out_dir / "map_iso.png", cell_px=12,
                       utilities=map_data["layers"]["utilities"],
                       interactables=map_data["layers"]["interactables"])
        except Exception as ex:
            print(f"  ! render failed for {map_name}: {ex}")
        written.append(map_name)
        map_names.append(map_name)
        print(f"  + {map_name}")

    # Splice imported map names into the sequence file's maps[].
    seq_path = SEQ_DIR / f"{cfg['sequence']}.json"
    if seq_path.exists() and map_names:
        try:
            sd = json.loads(seq_path.read_text(encoding="utf-8"))
            seqs = sd.get("sequences", {})
            first_key = next(iter(seqs.keys()), None)
            if first_key:
                seq = seqs[first_key]
                cur = seq.get("maps") or []
                added = 0
                for n in map_names:
                    if n not in cur:
                        cur.append(n); added += 1
                seq["maps"] = cur
                if added:
                    seq.setdefault("notes", "")
                    seq["last_imported_from"] = {
                        "gallery": gallery_id,
                        "n_added": added,
                        "at": datetime.utcnow().isoformat() + "Z",
                    }
                    seq_path.write_text(json.dumps(sd, indent="\t") + "\n",
                                        encoding="utf-8")
                    print(f"    sequence {cfg['sequence']}: +{added} new maps")
        except Exception as ex:
            print(f"  ! could not splice into {seq_path.name}: {ex}")

    return {
        "gallery": gallery_id,
        "written": len(written),
        "skipped": skipped,
        "total_in_gallery": len(entries),
        "sequence": cfg["sequence"],
    }


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("gallery", choices=["pattern", "facade", "soft-body", "all"],
                   help="which gallery to import (or 'all')")
    p.add_argument("--force", action="store_true",
                   help="overwrite existing imported maps")
    args = p.parse_args()
    targets = ["pattern", "facade", "soft-body"] if args.gallery == "all" else [args.gallery]
    summary = []
    for g in targets:
        print(f"\n=== importing {g} ===")
        summary.append(import_one(g, args.force))
    print()
    print(f"=== summary ===")
    for s in summary:
        if "error" in s:
            print(f"  {s['gallery']:12s} ERROR: {s['error']}")
        else:
            print(f"  {s['gallery']:12s} -> {s['sequence']:16s} "
                  f"written:{s['written']:3d} skipped:{s['skipped']:3d} "
                  f"total:{s['total_in_gallery']:3d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
