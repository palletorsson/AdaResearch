"""tools/grow_scene.py — grow a BEAD: an artifact's footprint stage, nothing else.

A bead is the atomic unit of the artifact-first map pipeline: the object plus
exactly the cells its stage rule mandates. No spawn, no teleporter, no
background, no context — the footprint makes us zoom in. Beads are placed
later to compose maps (the necklace); the map supplies the thread.

Stage rules (derived from registry spatial_needs, never hand-tagged):
  table   platform table/pedestal   -> cube under (h2) + ONE ring around (h1), y_offset 1.0
  space   explicit --space override -> solid floor (h1), artifact hangs above it (y 1.6)
  large   footprint_cells >= 4      -> its own base footprint at h1, no ring
  wall    platform wall             -> footprint + back row raised to h3
  sunken  platform sunken           -> v0: floor (true pocket needs grid_y care)
  floor   everything else           -> footprint at h1

A 1-cell table artifact therefore yields a 3x3 bead — "three by three cubes,
depending on the footprint." Groups lay plots adjacent in the given order.

Usage:
  python tools/grow_scene.py --artifacts=spring_demo --name=Spring
  python tools/grow_scene.py --artifacts=point --name=Point --space=point

Output: commons/maps/MiniScene_<Name>/map_data.json (settings.disable_biome
= true so captures stay context-free). Beads are stamps, not walkable maps —
no pathfinder check. Editable in GridEditorDesktop3D / the web editor like
any map.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
REG_DIR = ROOT / "commons" / "artifacts" / "registry"
MAPS_DIR = ROOT / "commons" / "maps"

RING = 1          # clearance ring around every stage
SPACE_Y = 1.6     # hanging height for space-staged artifacts
TABLE_Y = 0.0     # artifact sits ON its cube (find_highest_y already lifts it) — y0, no float


def load_registry_entry(token: str) -> dict | None:
    for f in sorted(REG_DIR.glob("*.json")):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts")
        if isinstance(arts, dict) and token in arts and isinstance(arts[token], dict):
            return arts[token]
    return None


def footprint_cells(entry: dict) -> int:
    sn = entry.get("spatial_needs") or {}
    cells = sn.get("footprint_cells")
    if isinstance(cells, (int, float)) and cells > 0:
        return int(cells)
    fp = entry.get("footprint") or (entry.get("parameters") or {}).get("footprint")
    if isinstance(fp, list) and len(fp) == 3:
        return max(1, int(fp[0]) * int(fp[2]))
    return 1


def classify_stage(entry: dict, override: str | None, catalog: bool = False) -> str:
    if override:
        return override
    sn = entry.get("spatial_needs") or {}
    platform = str(sn.get("platform", "none")).lower()
    if platform in ("table", "pedestal"):
        return "table"
    if platform == "wall":
        return "wall"
    if platform == "sunken":
        return "sunken"   # v0 renders as floor; true pocket later
    if footprint_cells(entry) >= 4:
        return "large"
    # catalog mode: present a lone small object on a flat footprint + 1-cell ring,
    # the artifact sitting AT y0 on the cube (no raised plinth, no float).
    if catalog:
        return "pad"
    return "floor"


def grow(name: str, tokens: list[str], overrides: dict[str, str],
         catalog: bool = False) -> Path:
    plots = []   # (token, stage, side, plot_w)
    for token in tokens:
        entry = load_registry_entry(token)
        if entry is None:
            print(f"  ! {token}: not in any registry — staging as floor/1-cell")
            entry = {}
        stage = classify_stage(entry, overrides.get(token), catalog)
        side = max(1, math.ceil(math.sqrt(footprint_cells(entry))))
        # table / space / pad add one ring of cells around the object; the rest
        # are just the footprint itself. A 1-cell pad -> 3x3 flat bead.
        pw = side + 2 * RING if stage in ("table", "space", "pad") else side
        plots.append((token, stage, side, pw))
        print(f"  {token}: stage={stage} footprint_side={side} bead_w={pw}")

    # Beads sit flush against each other, no corridor, no margin — the grid IS
    # the union of footprints, nothing more.
    width = sum(pw for *_, pw in plots)
    depth = max(pw for *_, pw in plots)

    structure = [["0"] * width for _ in range(depth)]   # void by default
    utilities = [[" "] * width for _ in range(depth)]
    interactables = [[" "] * width for _ in range(depth)]

    x = 0
    for token, stage, side, pw in plots:
        ring = RING if stage in ("table", "space", "pad") else 0
        top = (depth - pw) // 2          # centre the bead vertically
        # stamp the bead's cells
        for r in range(pw):
            for c in range(pw):
                rr, cc = top + r, x + c
                inner = ring <= r < ring + side and ring <= c < ring + side
                if stage == "table":
                    structure[rr][cc] = "2" if inner else "1"
                else:  # space, wall, large, floor, pad — solid flat footprint
                    structure[rr][cc] = "1"   # artifact sits ON this at y0 (space hangs via y_offset)
        if stage == "wall":
            for c in range(pw):
                structure[top][x + c] = "3"   # back wall of the bead
        y_off = {"table": TABLE_Y, "space": SPACE_Y, "pad": 0.0}.get(stage, 0.0)
        cr = top + ring + side // 2
        cc = x + ring + side // 2
        # rotation 0 faces the iso capture camera (NE); 180 shows the back of
        # text panels mirrored. Beads are catalog cutouts — face front.
        interactables[cr][cc] = f"{token}:0:{y_off}"
        x += pw

    map_name = f"MiniScene_{name}"
    folder = MAPS_DIR / map_name
    folder.mkdir(parents=True, exist_ok=True)
    data = {
        "map_info": {
            "name": map_name,
            "lookup_name": map_name,
            "title": f"Mini scene: {name.replace('_', ' ')}",
            "description": (
                f"A mini scene grown by tools/grow_scene.py — "
                f"{', '.join(tokens)} staged by footprint rule "
                f"({', '.join(stage for _, stage, _, _ in plots)}). One concept, one bead; "
                f"maps are necklaces of these."
            ),
            "version": "0.1-grow-scene",
            "format": "json",
            "created_from": "tools/grow_scene.py",
            "dimensions": {"width": width, "depth": depth, "max_height": 3},
            "metadata": {"category": "bead", "estimated_time": "0 minutes"},
        },
        "utility_definitions": {},
        "settings": {"floor_tile_size": 1.0, "disable_biome": True},
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
    }
    (folder / "map_data.json").write_text(
        json.dumps(data, indent=2) + "\n", encoding="utf-8")
    (folder / "blurb.md").write_text(
        f"A bead: {', '.join(tokens)} on its footprint, nothing else. "
        f"Placed later to make maps.\n", encoding="utf-8")
    print(f"  -> {folder / 'map_data.json'}  ({width}x{depth} — bead, not a map)")
    return folder


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--artifacts", required=True, help="comma-separated tokens, tutorial order")
    ap.add_argument("--name", required=True)
    ap.add_argument("--space", default="", help="tokens to stage as hanging-in-space")
    ap.add_argument("--stage", default="", help="explicit overrides token:stage,...")
    ap.add_argument("--catalog", action="store_true",
                    help="present lone small objects on a plinth (floor->table)")
    args = ap.parse_args()

    tokens = [t.strip() for t in args.artifacts.split(",") if t.strip()]
    overrides: dict[str, str] = {t.strip(): "space" for t in args.space.split(",") if t.strip()}
    for pair in args.stage.split(","):
        if ":" in pair:
            tok, st = pair.split(":", 1)
            overrides[tok.strip()] = st.strip()

    print(f"grow_scene: {args.name} <- {tokens}")
    grow(args.name, tokens, overrides, catalog=args.catalog)


if __name__ == "__main__":
    main()
