"""Render the best placement from each strategy as an SVG grid.

Auto-research produced numbers; this turns the numbers into visible rooms
so the placement can be eye-checked.

Run:
  python tools/placement_visualize.py

Output: doc/placement_research/best_placements.svg
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "doc" / "placement_research" / "results.json"
OUT = ROOT / "doc" / "placement_research" / "best_placements.svg"

CELL = 32           # px per grid cell
PAD = 14            # padding inside each room panel
LABEL_H = 36        # height of title label above each room
GAP = 24            # gap between panels
COLS = 2            # panels per row in the output grid

# Artifact colours (1..N) — distinct, high-contrast
ARTIFACT_COLORS = [
    "#E63946",   # red
    "#457B9D",   # blue
    "#F4A261",   # orange
    "#2A9D8F",   # teal
    "#E9C46A",   # yellow
    "#9B5DE5",   # purple
]


def render_room_svg(strategy: str, score: float, ascii_grid: list[str],
                    placements: list[dict], artifacts: list[dict],
                    x_off: int, y_off: int) -> tuple[str, int, int]:
    """Render one room. Returns (svg fragment, total_w, total_h) for the panel."""
    depth = len(ascii_grid)
    width = len(ascii_grid[0]) if depth > 0 else 0

    room_w = width * CELL
    room_h = depth * CELL
    panel_w = room_w + PAD * 2
    panel_h = room_h + PAD * 2 + LABEL_H

    parts = []
    # Panel background
    parts.append(f'<g transform="translate({x_off},{y_off})">')
    parts.append(f'<rect width="{panel_w}" height="{panel_h}" fill="#1A1A1F" '
                 f'stroke="#2A2A33" stroke-width="1" rx="6" />')

    # Title
    parts.append(f'<text x="{PAD}" y="22" font-family="ui-monospace,monospace" '
                 f'font-size="14" font-weight="600" fill="#E8E8EE">{strategy}</text>')
    parts.append(f'<text x="{panel_w - PAD}" y="22" font-family="ui-monospace,monospace" '
                 f'font-size="14" fill="#9090A0" text-anchor="end">score {score:.3f}</text>')

    # Room background (cells)
    room_x = PAD
    room_y = LABEL_H
    for r in range(depth):
        for c in range(width):
            ch = ascii_grid[r][c]
            x = room_x + c * CELL
            y = room_y + r * CELL
            fill = "#0E0E12"  # empty cell
            if ch == 'S':
                fill = "#4D7C0F"
            elif ch == 'T':
                fill = "#7C2D12"
            elif ch.isdigit():
                idx = int(ch) - 1
                if 0 <= idx < len(ARTIFACT_COLORS):
                    fill = ARTIFACT_COLORS[idx]
            parts.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                         f'fill="{fill}" stroke="#1F1F26" stroke-width="0.5" />')

            # Cell text (S/T)
            if ch in ('S', 'T'):
                parts.append(f'<text x="{x + CELL/2}" y="{y + CELL/2 + 5}" '
                             f'font-family="ui-monospace,monospace" font-size="13" '
                             f'font-weight="700" fill="#FAFAFC" text-anchor="middle">{ch}</text>')

    # Outline
    parts.append(f'<rect x="{room_x}" y="{room_y}" width="{room_w}" height="{room_h}" '
                 f'fill="none" stroke="#3A3A45" stroke-width="2" />')

    # Compass: N (back wall = row 0), S (spawn side = row depth-1)
    parts.append(f'<text x="{room_x + room_w/2}" y="{room_y - 4}" '
                 f'font-family="ui-monospace,monospace" font-size="10" fill="#606070" '
                 f'text-anchor="middle">▲ back wall (row 0)</text>')

    parts.append('</g>')
    return "".join(parts), panel_w, panel_h


def render_legend(artifacts: list[dict], x_off: int, y_off: int) -> tuple[str, int, int]:
    """Compact legend explaining which colour = which artifact."""
    parts = []
    w = 380
    h = 24 + 18 * (len(artifacts) + 1)
    parts.append(f'<g transform="translate({x_off},{y_off})">')
    parts.append(f'<rect width="{w}" height="{h}" fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')
    parts.append(f'<text x="12" y="20" font-family="ui-monospace,monospace" '
                 f'font-size="13" fill="#E8E8EE" font-weight="600">artifact key</text>')
    y = 36
    for i, a in enumerate(artifacts):
        c = ARTIFACT_COLORS[i % len(ARTIFACT_COLORS)]
        parts.append(f'<rect x="12" y="{y}" width="16" height="16" fill="{c}" '
                     f'stroke="#1F1F26"/>')
        flags = []
        if a.get("wall_backing"):
            flags.append("wall_backing")
        if a.get("isolation", 0) > 0:
            flags.append(f"isolation={a['isolation']}")
        if a.get("cluster_with"):
            flags.append("cluster")
        if a.get("preferred_zone") and a["preferred_zone"] != "any":
            flags.append(f"zone={a['preferred_zone']}")
        flagstr = " · ".join(flags) if flags else "—"
        parts.append(f'<text x="36" y="{y + 12}" font-family="ui-monospace,monospace" '
                     f'font-size="11" fill="#E8E8EE">{a["lookup_name"]}</text>')
        parts.append(f'<text x="36" y="{y + 26}" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#8888A0">footprint={a["footprint_cells"]} · {flagstr}</text>')
        y += 38
    parts.append('</g>')
    return "".join(parts), w, h


def main():
    with open(RESULTS, "r", encoding="utf-8") as f:
        data = json.load(f)

    artifacts = data["artifacts"]
    # Sort strategies by mean score for the layout
    ranked = sorted(data["summary"].items(), key=lambda kv: -kv[1]["mean"])

    # Compute panel size from the first one
    first_strat = ranked[0][0]
    first_bp = data["best_placements"][first_strat]
    sample_grid = first_bp["ascii"]
    depth = len(sample_grid)
    width = len(sample_grid[0])
    panel_w = width * CELL + PAD * 2
    panel_h = depth * CELL + PAD * 2 + LABEL_H

    total_w = COLS * panel_w + (COLS + 1) * GAP
    rows = (len(ranked) + COLS - 1) // COLS
    total_h = 80 + rows * (panel_h + GAP) + 200   # extra for header + legend

    body = []
    # Header
    body.append(f'<rect width="{total_w}" height="{total_h}" fill="#0A0A0E"/>')
    body.append(f'<text x="{GAP}" y="36" font-family="ui-monospace,monospace" '
                f'font-size="20" fill="#FFFFFF" font-weight="700">'
                f'Placement auto-research — best placement per strategy</text>')
    body.append(f'<text x="{GAP}" y="60" font-family="ui-monospace,monospace" '
                f'font-size="12" fill="#9090A0">'
                f'{data["seeds_per_strategy"]} seeds × {len(ranked)} strategies '
                f'· 10 constraint metrics · 10×6 room, spawn back-centre, teleporter front-centre</text>')

    y = 80
    for i, (strategy, stats) in enumerate(ranked):
        col = i % COLS
        row = i // COLS
        x = GAP + col * (panel_w + GAP)
        y_pos = 80 + row * (panel_h + GAP)
        bp = data["best_placements"][strategy]
        frag, _, _ = render_room_svg(
            strategy=strategy, score=bp["score"],
            ascii_grid=bp["ascii"], placements=bp["placements"],
            artifacts=artifacts, x_off=x, y_off=y_pos,
        )
        body.append(frag)

    # Legend at bottom
    legend_y = 80 + rows * (panel_h + GAP)
    legend_frag, lw, lh = render_legend(artifacts, GAP, legend_y)
    body.append(legend_frag)

    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{total_w}" height="{legend_y + lh + GAP}" '
        f'viewBox="0 0 {total_w} {legend_y + lh + GAP}">'
        + "".join(body)
        + '</svg>'
    )

    with open(OUT, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"wrote {OUT}")
    print(f"  open with any browser or vector editor")


if __name__ == "__main__":
    main()
