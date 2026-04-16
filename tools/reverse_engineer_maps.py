#!/usr/bin/env python3
"""
Reverse-engineer existing maps into spacer configs.

For each map, analyzes the structure layer and infers:
  - Which topology mode would reproduce it (corridor/room/ring/open)
  - Where A anchors should go (artifact positions + key walkway junctions)
  - Optimal padding and corridor width
  - A spacer config block to add to map_data.json

Also writes A anchors into the utilities layer so generate_structure.py
can regenerate the map from anchors alone.

Usage:
  python tools/reverse_engineer_maps.py --map Random_Definition
  python tools/reverse_engineer_maps.py --sequence randomness
  python tools/reverse_engineer_maps.py --all --dry-run
  python tools/reverse_engineer_maps.py --all --write-anchors    # write A codes to utilities
"""

import argparse
import json
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import (
    ROOT,
    MAPS_DIR,
    load_json,
    parse_interactable_cell,
    scan_all_sequences,
)


def analyze_map(map_data: dict) -> dict:
    """Analyze a map's structure and infer spacer configuration."""
    layers = map_data.get("layers", {})
    structure = layers.get("structure", [])
    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])

    if not structure:
        return {"error": "no structure layer"}

    rows = len(structure)
    cols = len(structure[0]) if structure else 0
    total = rows * cols

    # ── Cell counting ──────────────────────────────────────────
    floor_cells = []
    wall_cells = []
    void_cells = []
    for r in range(rows):
        for c in range(cols):
            v = int(structure[r][c]) if str(structure[r][c]).isdigit() else 0
            if v == 0:
                void_cells.append((r, c))
            elif v == 1:
                floor_cells.append((r, c))
            else:
                wall_cells.append((r, c))

    floor_pct = len(floor_cells) / total * 100 if total else 0
    wall_pct = len(wall_cells) / total * 100 if total else 0

    # ── Find spawn, teleporter, artifacts ──────────────────────
    spawn = None
    teleporter = None
    anchors_explicit = []
    artifacts = []

    for r in range(len(utilities)):
        for c in range(len(utilities[r])):
            cell = str(utilities[r][c]).strip()
            if not cell or cell == " ":
                continue
            code = cell.split(":")[0].lower()
            if code in ("sp", "s"):
                spawn = (r, c)
            elif code == "t":
                teleporter = (r, c)
            elif code == "a":
                anchors_explicit.append((r, c))

    for r in range(len(interactables)):
        for c in range(len(interactables[r])):
            cell = str(interactables[r][c]).strip()
            if cell and cell != " ":
                name, config = parse_interactable_cell(cell)
                if name and len(name) > 1:
                    artifacts.append((r, c, name))

    # ── Infer topology mode ────────────────────────────────────

    # Detect if structure is mostly open
    if floor_pct > 75:
        mode = "open"
    elif floor_pct > 55:
        mode = "room"
    else:
        # Check corridor characteristics: is the floor a narrow connected path?
        # Measure average floor "width" by checking neighbors
        narrow_count = 0
        for r, c in floor_cells:
            neighbors_floor = 0
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    v = int(structure[nr][nc]) if str(structure[nr][nc]).isdigit() else 0
                    if v > 0:
                        neighbors_floor += 1
            if neighbors_floor <= 2:
                narrow_count += 1

        narrow_pct = narrow_count / max(len(floor_cells), 1) * 100

        if narrow_pct > 40:
            mode = "corridor"
        else:
            mode = "room"

    # ── Check if structure looks like a ring (loop) ────────────
    # A ring has most floor cells with exactly 2 floor neighbors
    if mode == "corridor":
        two_neighbor_count = 0
        for r, c in floor_cells:
            n = 0
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    v = int(structure[nr][nc]) if str(structure[nr][nc]).isdigit() else 0
                    if v > 0:
                        n += 1
            if n == 2:
                two_neighbor_count += 1
        if two_neighbor_count / max(len(floor_cells), 1) > 0.5:
            # Check if there's a loop (BFS, detect cycle)
            mode = "ring"

    # ── Infer padding ──────────────────────────────────────────
    # Check average distance from artifact to nearest wall
    padding = 1
    if artifacts:
        wall_set = set(wall_cells) | set(void_cells)
        total_dist = 0
        for r, c, _ in artifacts:
            min_dist = rows + cols
            for wr, wc in wall_set:
                d = abs(r - wr) + abs(c - wc)
                if d < min_dist:
                    min_dist = d
                    if min_dist <= 1:
                        break
            total_dist += min_dist
        avg_dist = total_dist / len(artifacts)
        if avg_dist > 3:
            padding = 2
        elif avg_dist > 1.5:
            padding = 1
        else:
            padding = 0

    # ── Infer corridor width ───────────────────────────────────
    corridor_width = 2
    if mode in ("corridor", "ring"):
        # Sample corridor widths at several points
        widths = []
        for r, c in floor_cells[::max(1, len(floor_cells) // 20)]:
            # Measure horizontal width
            hw = 1
            for dc in range(1, 5):
                nc = c + dc
                if nc < cols:
                    v = int(structure[r][nc]) if str(structure[r][nc]).isdigit() else 0
                    if v > 0:
                        hw += 1
                    else:
                        break
                else:
                    break
            # Measure vertical width
            vw = 1
            for dr in range(1, 5):
                nr = r + dr
                if nr < rows:
                    v = int(structure[nr][c]) if str(structure[nr][c]).isdigit() else 0
                    if v > 0:
                        vw += 1
                    else:
                        break
                else:
                    break
            widths.append(min(hw, vw))
        if widths:
            corridor_width = max(1, min(4, round(sum(widths) / len(widths))))

    # ── Infer wall height ──────────────────────────────────────
    wall_height = 2
    if wall_cells:
        heights = [int(structure[r][c]) for r, c in wall_cells if str(structure[r][c]).isdigit()]
        if heights:
            wall_height = max(set(heights), key=heights.count)  # mode

    # ── Determine optimal A anchor positions ───────────────────
    # Key positions: artifacts + spawn + teleporter + corridor junctions
    inferred_anchors = []
    if spawn:
        inferred_anchors.append({"pos": spawn, "type": "spawn"})
    if teleporter:
        inferred_anchors.append({"pos": teleporter, "type": "teleporter"})
    for r, c, name in artifacts:
        inferred_anchors.append({"pos": (r, c), "type": "artifact", "name": name})

    # Find junction points (floor cells with 3+ floor neighbors)
    junctions = []
    for r, c in floor_cells:
        n = 0
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols:
                v = int(structure[nr][nc]) if str(structure[nr][nc]).isdigit() else 0
                if v > 0:
                    n += 1
        if n >= 3:
            junctions.append((r, c))

    # Add junctions that aren't near existing anchors
    existing_positions = set(a["pos"] for a in inferred_anchors)
    for jr, jc in junctions:
        too_close = False
        for pos in existing_positions:
            if abs(jr - pos[0]) + abs(jc - pos[1]) <= 2:
                too_close = True
                break
        if not too_close:
            inferred_anchors.append({"pos": (jr, jc), "type": "junction"})
            existing_positions.add((jr, jc))

    # ── Build spacer config ────────────────────────────────────
    spacer_config = {
        "mode": mode,
        "padding": padding,
        "wall_height": wall_height,
        "corridor_width": corridor_width,
    }

    return {
        "dimensions": f"{rows}x{cols}",
        "floor_count": len(floor_cells),
        "wall_count": len(wall_cells),
        "void_count": len(void_cells),
        "floor_pct": round(floor_pct, 1),
        "wall_pct": round(wall_pct, 1),
        "artifact_count": len(artifacts),
        "inferred_mode": mode,
        "inferred_padding": padding,
        "inferred_corridor_width": corridor_width,
        "inferred_wall_height": wall_height,
        "spacer_config": spacer_config,
        "anchor_count": len(inferred_anchors),
        "anchors": inferred_anchors,
    }


def write_anchors_to_map(map_data: dict, analysis: dict) -> bool:
    """Write inferred A anchors into the utilities layer."""
    utils = map_data.get("layers", {}).get("utilities", [])
    if not utils:
        return False

    written = 0
    for anchor in analysis["anchors"]:
        if anchor["type"] == "junction":
            r, c = anchor["pos"]
            if 0 <= r < len(utils) and 0 <= c < len(utils[r]):
                current = str(utils[r][c]).strip()
                if not current or current == " ":
                    utils[r][c] = "A"
                    written += 1

    # Add spacer config to map_data
    map_data["spacer"] = analysis["spacer_config"]

    return written > 0


def main():
    parser = argparse.ArgumentParser(description="Reverse-engineer maps into spacer configs")
    parser.add_argument("--map", help="Single map name")
    parser.add_argument("--sequence", help="All maps in a sequence")
    parser.add_argument("--all", action="store_true", help="All maps")
    parser.add_argument("--dry-run", action="store_true", help="Analyze only, don't write")
    parser.add_argument("--write-anchors", action="store_true", help="Write A anchors to utilities layer")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    # Collect targets
    targets = []
    if args.map:
        targets = [args.map]
    elif args.sequence:
        sequences = scan_all_sequences()
        for sid, seq in sequences.items():
            if sid.lower() == args.sequence.lower():
                for m in seq.get("maps", []):
                    name = m if isinstance(m, str) else m.get("name", "")
                    if name:
                        targets.append(name)
                break
    elif args.all:
        targets = sorted([
            d.name for d in MAPS_DIR.iterdir()
            if d.is_dir() and (d / "map_data.json").is_file()
        ])
    else:
        print("Specify --map, --sequence, or --all")
        return

    results = {}
    mode_counts = {}

    for map_name in targets:
        map_file = MAPS_DIR / map_name / "map_data.json"
        if not map_file.is_file():
            continue

        map_data = load_json(map_file)
        if not map_data:
            continue

        analysis = analyze_map(map_data)
        results[map_name] = analysis

        mode = analysis.get("inferred_mode", "unknown")
        mode_counts[mode] = mode_counts.get(mode, 0) + 1

        if not args.json:
            print(f"  {map_name}: {analysis['dimensions']} | "
                  f"floor={analysis['floor_pct']}% wall={analysis['wall_pct']}% | "
                  f"mode={mode} pad={analysis['inferred_padding']} "
                  f"cw={analysis['inferred_corridor_width']} wh={analysis['inferred_wall_height']} | "
                  f"{analysis['artifact_count']} artifacts, {analysis['anchor_count']} anchors")

        if args.write_anchors and not args.dry_run:
            if write_anchors_to_map(map_data, analysis):
                with open(map_file, "w", encoding="utf-8") as f:
                    json.dump(map_data, f, indent=2, ensure_ascii=False)

    if args.json:
        print(json.dumps(results, indent=2, default=str))
    else:
        print(f"\n{'='*50}")
        print(f"Total: {len(results)} maps analyzed")
        print(f"Mode distribution:")
        for mode, count in sorted(mode_counts.items(), key=lambda x: -x[1]):
            print(f"  {mode}: {count} ({count/len(results)*100:.0f}%)")


if __name__ == "__main__":
    main()
