"""Render the humanoid_walker's trajectory as an SVG.

Runs strategy_humanoid_walker with trace=enabled, captures every
(look / place / tweak / move / salvage) event, draws:
  - the room grid
  - the walk path as a connected line
  - placement events as boxes with timestamps
  - decision annotations along the path

Output: doc/placement_research/humanoid_walker_trajectory.svg

Run:
  python tools/placement_trajectory.py
  python tools/placement_trajectory.py --map=Point_Tests
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import io
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "doc" / "placement_research"

sys.path.insert(0, str(ROOT / "tools"))
from placement_research import (
    Room, Artifact, Placement, strategy_humanoid_walker, score_placement,
    TEST_ARTIFACTS,
)
# Reuse the registry-loading from place_artifacts.py
from place_artifacts import existing_placements, room_from_map, load_registry


CELL = 44
PAD = 24
TOP_PAD = 110
RIGHT_PAD = 280   # log column
ART_COLORS = ["#E63946", "#457B9D", "#F4A261", "#2A9D8F", "#E9C46A", "#9B5DE5",
              "#FF6B9D", "#06D6A0", "#118AB2", "#FFD166"]


def render_trajectory_svg(room: Room, artifacts: list[Artifact],
                           seed: int = 0) -> str:
    trace: list = []
    rng = random.Random(seed)
    placements = strategy_humanoid_walker(room, list(artifacts), rng, trace=trace)
    final_score = score_placement(room, placements)

    grid_w = room.width * CELL
    grid_h = room.depth * CELL
    canvas_w = PAD + grid_w + RIGHT_PAD + PAD
    canvas_h = TOP_PAD + grid_h + PAD + 100

    name_to_color = {a.lookup_name: ART_COLORS[i % len(ART_COLORS)]
                     for i, a in enumerate(artifacts)}

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']

    # Title
    parts.append(f'<text x="{PAD}" y="38" font-family="ui-monospace,monospace" '
                 f'font-size="22" font-weight="700" fill="#FFFFFF">'
                 f'Humanoid walker — embodied placement trajectory</text>')
    parts.append(f'<text x="{PAD}" y="62" font-family="ui-monospace,monospace" '
                 f'font-size="12" fill="#9090A0">'
                 f'Worker enters at S, looks → places → tweaks → moves toward T. '
                 f'Score: {final_score["total"]:.3f}</text>')
    parts.append(f'<text x="{PAD}" y="82" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#7070A0">'
                 f'{len(trace)} decisions  ·  '
                 f'{sum(1 for e in trace if e[0] == "place")} placements  ·  '
                 f'{sum(1 for e in trace if e[0] == "tweak")} tweaks  ·  '
                 f'{sum(1 for e in trace if e[0] == "move")} moves  ·  '
                 f'{sum(1 for e in trace if e[0] == "salvage")} salvage</text>')

    # Grid
    gx = PAD; gy = TOP_PAD
    for r in range(room.depth):
        for c in range(room.width):
            parts.append(f'<rect x="{gx + c * CELL}" y="{gy + r * CELL}" '
                         f'width="{CELL}" height="{CELL}" '
                         f'fill="#101015" stroke="#1F1F26" stroke-width="0.5"/>')

    # Final placements (boxes)
    for p in placements:
        color = name_to_color.get(p.artifact.lookup_name, "#888")
        w, d = p.artifact.footprint_dim()
        x = gx + p.col * CELL
        y = gy + p.row * CELL
        parts.append(f'<rect x="{x}" y="{y}" width="{w * CELL}" height="{d * CELL}" '
                     f'fill="{color}" fill-opacity="0.4" stroke="{color}" stroke-width="2"/>')
        # Label
        cx = x + w * CELL / 2; cy = y + d * CELL / 2
        parts.append(f'<text x="{cx}" y="{cy + 4}" font-family="ui-monospace,monospace" '
                     f'font-size="9" font-weight="700" fill="#FFFFFF" text-anchor="middle">'
                     f'{p.artifact.lookup_name[:10]}</text>')

    # Walk path — connect successive `move` and start positions
    move_path: list[tuple[int, int]] = []
    for e in trace:
        kind, pos, _, _ = e
        if kind in ("start", "move"):
            move_path.append(pos)
    if len(move_path) >= 2:
        # Smooth polyline from cell centers
        pts = " ".join(f"{gx + c * CELL + CELL/2},{gy + r * CELL + CELL/2}"
                       for (r, c) in move_path)
        parts.append(f'<polyline points="{pts}" fill="none" stroke="#7DFFA8" '
                     f'stroke-width="3" stroke-opacity="0.55" '
                     f'stroke-linejoin="round" stroke-linecap="round"/>')
        # Step numbers along the path
        for i, (r, c) in enumerate(move_path):
            if i % 2 == 1 and i > 0:    # sparse labels
                parts.append(f'<text x="{gx + c * CELL + CELL/2}" y="{gy + r * CELL + CELL/2 - 12}" '
                             f'font-family="ui-monospace,monospace" font-size="9" '
                             f'fill="#7DFFA8" text-anchor="middle">{i}</text>')

    # Place/tweak markers (overlays)
    place_idx = 0
    for e in trace:
        kind, pos, name, score = e
        r, c = pos
        cx = gx + c * CELL + CELL / 2; cy = gy + r * CELL + CELL / 2
        if kind == "place":
            place_idx += 1
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="14" '
                         f'fill="none" stroke="#FFD700" stroke-width="3" stroke-dasharray="3,2"/>')
            parts.append(f'<text x="{cx + 16}" y="{cy + 4}" font-family="ui-monospace,monospace" '
                         f'font-size="11" font-weight="700" fill="#FFD700">{place_idx}</text>')
        elif kind == "tweak":
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="8" fill="#FF6B9D" '
                         f'stroke="#0A0A0E" stroke-width="2"/>')
        elif kind == "salvage":
            parts.append(f'<rect x="{cx-8}" y="{cy-8}" width="16" height="16" '
                         f'fill="none" stroke="#FF6B6B" stroke-width="2" stroke-dasharray="2,2"/>')

    # Spawn + teleporter
    sx = gx + room.spawn_col * CELL + CELL/2
    sy = gy + room.spawn_row * CELL + CELL/2
    parts.append(f'<circle cx="{sx}" cy="{sy}" r="12" fill="#80FF80" stroke="#0A0A0E" stroke-width="2"/>')
    parts.append(f'<text x="{sx}" y="{sy + 5}" font-family="ui-monospace,monospace" '
                 f'font-size="13" font-weight="700" fill="#0A0A0E" text-anchor="middle">S</text>')
    tx = gx + room.teleporter_col * CELL + CELL/2
    ty = gy + room.teleporter_row * CELL + CELL/2
    parts.append(f'<circle cx="{tx}" cy="{ty}" r="12" fill="#FF8080" stroke="#0A0A0E" stroke-width="2"/>')
    parts.append(f'<text x="{tx}" y="{ty + 5}" font-family="ui-monospace,monospace" '
                 f'font-size="13" font-weight="700" fill="#0A0A0E" text-anchor="middle">T</text>')

    # Decision log on the right
    log_x = PAD + grid_w + 20
    log_y = TOP_PAD
    parts.append(f'<text x="{log_x}" y="{log_y - 8}" font-family="ui-monospace,monospace" '
                 f'font-size="12" font-weight="700" fill="#E8E8EE">decision log</text>')
    # Filter trace for display — show only place/tweak/salvage (skip look/move noise)
    display_trace = [e for e in trace if e[0] in ("place", "tweak", "salvage", "start")]
    line_y = log_y + 4
    icon_for = {"start": "→", "place": "●", "tweak": "↻", "salvage": "✕"}
    color_for = {"start": "#7DFFA8", "place": "#FFD700", "tweak": "#FF6B9D", "salvage": "#FF6B6B"}
    for e in display_trace[:28]:
        kind, pos, name, score = e
        icon = icon_for.get(kind, "·")
        color = color_for.get(kind, "#888")
        text = f"{icon} {kind:8} ({pos[0]:2},{pos[1]:2})"
        if name: text += f" {name[:14]}"
        if score is not None and score != 0.0: text += f" s={score:.2f}"
        parts.append(f'<text x="{log_x}" y="{line_y + 14}" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="{color}">{text}</text>')
        line_y += 16

    # Legend at bottom
    leg_y = TOP_PAD + grid_h + 24
    parts.append(f'<text x="{PAD}" y="{leg_y}" font-family="ui-monospace,monospace" '
                 f'font-size="11" font-weight="600" fill="#E8E8EE">artifacts:</text>')
    lx = PAD + 90
    for i, a in enumerate(artifacts):
        color = name_to_color[a.lookup_name]
        parts.append(f'<rect x="{lx}" y="{leg_y - 12}" width="14" height="14" fill="{color}"/>')
        parts.append(f'<text x="{lx + 20}" y="{leg_y}" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#E8E8EE">{a.lookup_name[:18]}</text>')
        lx += 190
    parts.append(f'<text x="{PAD}" y="{leg_y + 24}" font-family="ui-monospace,monospace" '
                 f'font-size="10" fill="#9090A0">'
                 f'GREEN path = walk · GOLD ring = place · PINK dot = tweak · '
                 f'RED dashed box = salvage (placed after walk ended)</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">'
            + "".join(parts) + '</svg>')


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", type=str, help="run on existing map (default: TEST_ARTIFACTS)")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--out", type=str, default="humanoid_walker_trajectory.svg")
    args = p.parse_args()

    if args.map:
        # Load real map
        src = ROOT / "commons" / "maps" / args.map / "map_data.json"
        with open(src, "r", encoding="utf-8") as f:
            map_data = json.load(f)
        room, _, _ = room_from_map(map_data)
        old_placements = existing_placements(map_data, room)
        artifacts = [p.artifact for p in old_placements]
        if not artifacts:
            print(f"No artifacts found in {args.map}")
            return
    else:
        room = Room()
        artifacts = list(TEST_ARTIFACTS)

    svg = render_trajectory_svg(room, artifacts, seed=args.seed)
    out_path = OUT_DIR / args.out
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"wrote {out_path}")
    print(f"  open in browser to see the walker's trajectory + decisions")


if __name__ == "__main__":
    main()
