"""Render a grown map's structure layer as an SVG.

Reads commons/maps/Grown_<Name>/map_data.json and emits an SVG showing:
  - laid floor cells (light, height-1)
  - table cells (darker, height-2)
  - void cells (background)
  - spawn + teleporter
  - artifact positions (numbered in placement order)

Output: doc/placement_research/grown_<name>_structure.svg

Run:
  python tools/render_grown_structure.py --name=PointTestsClone
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"


def render_svg(map_name: str, out_path: Path) -> None:
    src = MAPS_DIR / f"Grown_{map_name}" / "map_data.json"
    with open(src, "r", encoding="utf-8") as f:
        m = json.load(f)

    width = m["map_info"]["dimensions"]["width"]
    depth = m["map_info"]["dimensions"]["depth"]
    structure = m["layers"]["structure"]
    utilities = m["layers"]["utilities"]
    interactables = m["layers"]["interactables"]

    CELL = 38
    PAD = 24
    TITLE_H = 80
    LEGEND_H = 80

    canvas_w = PAD * 2 + width * CELL
    canvas_h = TITLE_H + PAD + depth * CELL + LEGEND_H

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']

    # Title
    placed = m["map_info"]["metadata"]["artifacts_placed"]
    laid_n = m["map_info"]["metadata"]["laid_floor_cells"]
    table_n = m["map_info"]["metadata"]["table_cells"]
    parts.append(f'<text x="{PAD}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Grown_{map_name} — structure layer</text>')
    parts.append(f'<text x="{PAD}" y="62" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'{width}×{depth} bounding box · '
                 f'{laid_n} laid floor cells · {table_n} table cell(s) · '
                 f'{len(placed)} artifact(s) placed</text>')

    # Grid
    gx = PAD; gy = TITLE_H
    artifact_idx = 0
    placement_positions: list[tuple[int, int, str, int]] = []  # (r, c, name, index)
    for ri, row in enumerate(interactables):
        for ci, tok in enumerate(row):
            if isinstance(tok, str) and tok.strip():
                artifact_idx += 1
                name = tok.split(":")[0].split("#")[0]
                placement_positions.append((ri, ci, name, artifact_idx))

    for r in range(depth):
        for c in range(width):
            cell_code = structure[r][c] if r < len(structure) and c < len(structure[r]) else "0"
            x = gx + c * CELL
            y = gy + r * CELL
            if cell_code == "0" or cell_code.strip() == "":
                # Void — dark transparent
                parts.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                             f'fill="#0A0A0E" stroke="#16161E" stroke-width="0.5"/>')
            elif cell_code == "3":
                # Table cell — pink/raised
                parts.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                             f'fill="#D86B9E" stroke="#FBE38A" stroke-width="2"/>')
                # Inner highlight to show "raised"
                parts.append(f'<rect x="{x + 4}" y="{y + 4}" width="{CELL - 8}" '
                             f'height="{CELL - 8}" fill="none" stroke="#FFFFFF" stroke-width="1" '
                             f'stroke-dasharray="2,2" opacity="0.6"/>')
            else:
                # Floor cell — laid by walker
                parts.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                             f'fill="#3A4A6A" stroke="#5A6A8A" stroke-width="0.7" '
                             f'fill-opacity="0.85"/>')

    # Spawn + teleporter
    for r in range(depth):
        for c in range(width):
            if c >= len(utilities[r]): continue
            u = utilities[r][c]
            if not isinstance(u, str): continue
            cx = gx + c * CELL + CELL / 2
            cy = gy + r * CELL + CELL / 2
            if u.startswith("sp"):
                parts.append(f'<circle cx="{cx}" cy="{cy}" r="14" '
                             f'fill="#80FF80" stroke="#0A0A0E" stroke-width="2"/>')
                parts.append(f'<text x="{cx}" y="{cy + 5}" '
                             f'font-family="ui-monospace,monospace" font-size="13" '
                             f'font-weight="700" fill="#0A0A0E" text-anchor="middle">S</text>')
            elif u == "t":
                parts.append(f'<circle cx="{cx}" cy="{cy}" r="14" '
                             f'fill="#FF8080" stroke="#0A0A0E" stroke-width="2"/>')
                parts.append(f'<text x="{cx}" y="{cy + 5}" '
                             f'font-family="ui-monospace,monospace" font-size="13" '
                             f'font-weight="700" fill="#0A0A0E" text-anchor="middle">T</text>')

    # Artifacts
    art_colors = ["#E63946", "#457B9D", "#F4A261", "#2A9D8F", "#E9C46A",
                  "#9B5DE5", "#FF6B9D", "#06D6A0", "#118AB2", "#FFD166"]
    for (r, c, name, idx) in placement_positions:
        cx = gx + c * CELL + CELL / 2
        cy = gy + r * CELL + CELL / 2
        col = art_colors[(idx - 1) % len(art_colors)]
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="11" fill="{col}" '
                     f'stroke="#FFFFFF" stroke-width="2"/>')
        parts.append(f'<text x="{cx}" y="{cy + 4}" font-family="ui-monospace,monospace" '
                     f'font-size="11" font-weight="700" fill="#FFFFFF" text-anchor="middle">'
                     f'{idx}</text>')

    # Legend at bottom
    legend_y = gy + depth * CELL + 20
    items = [
        ("#3A4A6A", "laid floor (height 1)"),
        ("#D86B9E", "table (height 2)"),
        ("#0A0A0E", "void (walker never went)"),
        ("#80FF80", "S = spawn"),
        ("#FF8080", "T = teleporter"),
    ]
    lx = PAD
    for color, label in items:
        parts.append(f'<rect x="{lx}" y="{legend_y}" width="14" height="14" '
                     f'fill="{color}" stroke="#3A3A45"/>')
        parts.append(f'<text x="{lx + 20}" y="{legend_y + 12}" '
                     f'font-family="ui-monospace,monospace" font-size="11" '
                     f'fill="#E8E8EE">{label}</text>')
        lx += 200

    # Artifact list
    legend_y += 28
    parts.append(f'<text x="{PAD}" y="{legend_y + 4}" font-family="ui-monospace,monospace" '
                 f'font-size="11" font-weight="600" fill="#E8E8EE">placed:</text>')
    lx = PAD + 80
    for (r, c, name, idx) in placement_positions:
        col = art_colors[(idx - 1) % len(art_colors)]
        parts.append(f'<circle cx="{lx + 7}" cy="{legend_y}" r="6" fill="{col}"/>')
        parts.append(f'<text x="{lx + 18}" y="{legend_y + 4}" '
                     f'font-family="ui-monospace,monospace" font-size="10" '
                     f'fill="#E8E8EE">{idx}. {name[:18]}</text>')
        lx += 180

    out_path.write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
        f'viewBox="0 0 {canvas_w} {canvas_h}">{"".join(parts)}</svg>',
        encoding="utf-8"
    )


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--name", type=str, required=True)
    p.add_argument("--out", type=str, default=None)
    args = p.parse_args()

    if args.out:
        out = Path(args.out)
    else:
        out = ROOT / "doc" / "placement_research" / f"grown_{args.name}_structure.svg"
    render_svg(args.name, out)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
