"""Render the tile palette as an SVG so the 10 tiles are visible at a glance.

Output: doc/placement_research/tile_palette.svg
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
PAL = ROOT / "commons" / "maps" / "tile_palette" / "palette.json"
OUT = ROOT / "doc" / "placement_research" / "tile_palette.svg"

STRUCT_COLOR = {
    "0": "#0A0A0E",   # void
    " ": "#0A0A0E",
    "1": "#2A3346",
    "2": "#3A4A6A",   # floor
    "3": "#D86B9E",   # table/raised
}
EDGE_COLOR = {
    "spawn":   "#7DFFA8",
    "exit":    "#FF8080",
    "open":    "#888888",
    "wall_l":  "#F4A261",
    "wall_r":  "#F4A261",
    "cluster": "#9B5DE5",
    "array":   "#FBE38A",
    "break":   "#4D4D5A",
    "display": "#A5C8FF",
}
SLOT_COLOR = {
    "centerpiece":     "#E63946",
    "wall_backing":    "#F4A261",
    "cluster_anchor":  "#9B5DE5",
    "cluster_member":  "#B68FE0",
    "small":           "#A5C8FF",
}


def render() -> str:
    with open(PAL, "r", encoding="utf-8") as f:
        palette = json.load(f)
    tiles = palette["tiles"]
    cell = 36
    pad = 14
    title_h = 60
    label_h = 38
    tile_w = 3 * cell + pad * 2
    tile_h = 3 * cell + pad * 2 + label_h

    cols = 5
    rows = (len(tiles) + cols - 1) // cols
    canvas_w = pad + cols * (tile_w + pad)
    canvas_h = title_h + rows * (tile_h + pad) + 200

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace" font-size="20" '
                 f'font-weight="700" fill="#FFFFFF">Tile palette — 10 templates × 3×3</text>')
    parts.append(f'<text x="20" y="56" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">edge codes: green=spawn · red=exit · grey=open · '
                 f'orange=wall · purple=cluster · yellow=array · dark=break · blue=display</text>')

    for i, tile in enumerate(tiles):
        col = i % cols
        row = i // cols
        x0 = pad + col * (tile_w + pad)
        y0 = title_h + row * (tile_h + pad)

        parts.append(f'<rect x="{x0}" y="{y0}" width="{tile_w}" height="{tile_h}" '
                     f'fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')
        parts.append(f'<text x="{x0 + pad}" y="{y0 + 16}" font-family="ui-monospace" '
                     f'font-size="11" font-weight="700" fill="#E8E8EE">{tile["id"]}</text>')
        parts.append(f'<text x="{x0 + pad}" y="{y0 + 30}" font-family="ui-monospace" '
                     f'font-size="9" fill="#9090A0">role: {tile.get("role", "")}</text>')

        # Grid
        gx = x0 + pad
        gy = y0 + label_h
        for r in range(3):
            for c in range(3):
                ch = tile["structure"][r][c]
                fill = STRUCT_COLOR.get(ch, "#3A4A6A")
                parts.append(f'<rect x="{gx + c * cell}" y="{gy + r * cell}" '
                             f'width="{cell}" height="{cell}" '
                             f'fill="{fill}" stroke="#1F1F26" stroke-width="0.5"/>')

        # Utilities (sp/t)
        for r in range(3):
            for c in range(3):
                u = tile["utilities"][r][c]
                if isinstance(u, str) and u.strip():
                    cx = gx + c * cell + cell / 2
                    cy = gy + r * cell + cell / 2
                    if u == "sp":
                        parts.append(f'<circle cx="{cx}" cy="{cy}" r="10" '
                                     f'fill="#80FF80" stroke="#0A0A0E" stroke-width="1"/>')
                        parts.append(f'<text x="{cx}" y="{cy + 5}" font-family="ui-monospace" '
                                     f'font-size="12" font-weight="700" fill="#0A0A0E" '
                                     f'text-anchor="middle">S</text>')
                    elif u == "t":
                        parts.append(f'<circle cx="{cx}" cy="{cy}" r="10" '
                                     f'fill="#FF8080" stroke="#0A0A0E" stroke-width="1"/>')
                        parts.append(f'<text x="{cx}" y="{cy + 5}" font-family="ui-monospace" '
                                     f'font-size="12" font-weight="700" fill="#0A0A0E" '
                                     f'text-anchor="middle">T</text>')

        # Slots — coloured dot per type
        for slot in tile.get("slots", []):
            cx = gx + slot["c"] * cell + cell / 2
            cy = gy + slot["r"] * cell + cell / 2
            col_v = SLOT_COLOR.get(slot["type"], "#888888")
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="9" fill="{col_v}" '
                         f'stroke="#FFFFFF" stroke-width="1.5"/>')
            # Letter
            letter = slot["type"][0].upper()
            parts.append(f'<text x="{cx}" y="{cy + 4}" font-family="ui-monospace" '
                         f'font-size="11" font-weight="700" fill="#FFFFFF" '
                         f'text-anchor="middle">{letter}</text>')

        # Edge labels around the perimeter
        edges = tile.get("edges", {})
        edge_label_size = 9
        # N (top)
        parts.append(f'<rect x="{gx}" y="{gy - 3}" width="{3 * cell}" height="3" '
                     f'fill="{EDGE_COLOR.get(edges.get("N", "open"), "#888")}"/>')
        # S (bottom)
        parts.append(f'<rect x="{gx}" y="{gy + 3 * cell}" width="{3 * cell}" height="3" '
                     f'fill="{EDGE_COLOR.get(edges.get("S", "open"), "#888")}"/>')
        # W (left)
        parts.append(f'<rect x="{gx - 3}" y="{gy}" width="3" height="{3 * cell}" '
                     f'fill="{EDGE_COLOR.get(edges.get("W", "open"), "#888")}"/>')
        # E (right)
        parts.append(f'<rect x="{gx + 3 * cell}" y="{gy}" width="3" height="{3 * cell}" '
                     f'fill="{EDGE_COLOR.get(edges.get("E", "open"), "#888")}"/>')

    # Adjacency table at bottom
    leg_y = title_h + rows * (tile_h + pad) + 24
    parts.append(f'<text x="20" y="{leg_y}" font-family="ui-monospace" font-size="13" '
                 f'font-weight="700" fill="#E8E8EE">edge compatibility (selected)</text>')
    compat = palette.get("_meta", {}).get("compat", {})
    keys = ["spawn", "exit", "open", "wall_l", "wall_r", "cluster", "array", "break", "display"]
    cell_w = 60
    for i, k in enumerate(keys):
        x = 30 + i * cell_w + 80
        parts.append(f'<text x="{x}" y="{leg_y + 24}" font-family="ui-monospace" '
                     f'font-size="9" fill="#9090A0" text-anchor="middle">{k}</text>')
    parts.append(f'<text x="20" y="{leg_y + 24}" font-family="ui-monospace" '
                 f'font-size="9" fill="#9090A0">from \\ to</text>')
    for j, kj in enumerate(keys):
        y = leg_y + 44 + j * 16
        parts.append(f'<text x="20" y="{y}" font-family="ui-monospace" '
                     f'font-size="9" fill="#E8E8EE">{kj}</text>')
        allowed = compat.get(kj, [])
        for i, ki in enumerate(keys):
            x = 30 + i * cell_w + 80 - 6
            ok = ki in allowed
            parts.append(f'<rect x="{x}" y="{y - 9}" width="12" height="12" '
                         f'fill="{EDGE_COLOR.get(kj, "#888") if ok else "#1A1A1F"}" '
                         f'fill-opacity="{0.85 if ok else 0.25}" '
                         f'stroke="#3A3A45" stroke-width="0.5"/>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">{"".join(parts)}</svg>')


def main():
    OUT.write_text(render(), encoding="utf-8")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
