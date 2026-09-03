#!/usr/bin/env python3
"""map_plan.py — the map as a drawing, not a photograph.

2026-09-03, Palle, looking at an iso capture: "what is the best way to represent
position, can you make the grid or the museum an alternative map where you have
the right kind of abstraction to see how things are placed, remove the biome
around the grid, make the walls more clear".

A render shows a world. To judge PLACEMENT you want a plan: no biome, no sky, no
grass, no lighting, walls as walls, and every object drawn at its MEASURED size
rather than as whatever the camera happened to catch. This draws that, straight
from map_data.json and the measured footprints in doc/shelf.json, with no Godot
and no server, so it can run on every room in the corpus in a second.

It shows five things a photograph cannot:

  * an object's real footprint, to scale, against the cells it was given
  * an OVERRUN, in red, where that footprint leaves the room
  * an UNMEASURED object, hatched, because an unmeasured artifact is an
    unbounded one and half of some rooms have no measurement at all
  * a floating or buried object, from its y offset, called out in the margin
  * the void cells, the spawn and the exit, which decide whether any of it is
    reachable

    python tools/map_plan.py Symmetry_Seventeen
    python tools/map_plan.py --seq=formfinding --out=doc/plans
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL = 26          # px per grid cell
PAD = 130          # px margin for the legend

WALL = "#2b3038"
FLOOR = "#eceff4"
FLOOR2 = "#dfe4ec"
VOID = "#ffffff"
INK = "#141820"
RED = "#d1344b"
AMBER = "#c07a12"
BLUE = "#2f6bd8"
GREEN = "#2e7d4f"


def esc(s: str) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def load_shelf() -> dict:
    p = os.path.join(ROOT, "doc", "shelf.json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}


def plan(map_name: str, shelf: dict) -> tuple[str, list[str]]:
    p = os.path.join(ROOT, "commons", "maps", map_name, "map_data.json")
    layers = json.load(open(p, encoding="utf-8"))["layers"]
    st = layers["structure"]
    it = layers.get("interactables", [])
    ut = layers.get("utilities", [])
    H, W = len(st), len(st[0])
    ox, oy = PAD, 60
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W * CELL + PAD * 2}" '
        f'height="{H * CELL + oy + 150}" font-family="IBM Plex Mono, Consolas, monospace">',
        f'<rect width="100%" height="100%" fill="#f7f7f4"/>',
        f'<text x="{ox}" y="30" font-size="17" fill="{INK}" font-weight="bold">{esc(map_name)}</text>',
        f'<text x="{ox}" y="48" font-size="11" fill="#666">{W} x {H} cells = {W}.0 x {H}.0 m'
        f'   ·   plan, not a render: every body drawn at its measured size</text>',
        '<defs><pattern id="hatch" width="6" height="6" patternTransform="rotate(45)" '
        'patternUnits="userSpaceOnUse"><line x1="0" y1="0" x2="0" y2="6" '
        f'stroke="{AMBER}" stroke-width="2"/></pattern></defs>',
    ]

    # ---- the fabric: floor, wall, void -------------------------------------
    for r in range(H):
        for c in range(W):
            v = str(st[r][c]).strip()
            x, y = ox + c * CELL, oy + r * CELL
            if v == "0" or v == "":
                out.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                           f'fill="{VOID}" stroke="#d8d8d4" stroke-dasharray="2 2"/>')
            elif v == "1":
                out.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                           f'fill="{FLOOR}" stroke="#d3d8e0"/>')
            else:
                # a wall or a raised column: solid, and its height printed
                out.append(f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" fill="{WALL}"/>')
                out.append(f'<text x="{x + CELL / 2}" y="{y + CELL / 2 + 3}" font-size="8" '
                           f'fill="#8b93a1" text-anchor="middle">{esc(v)}</text>')

    # ---- utilities ---------------------------------------------------------
    for r in range(min(H, len(ut))):
        for c in range(min(W, len(ut[r]))):
            v = str(ut[r][c]).strip()
            if not v or v == "-":
                continue
            code = v.split(":")[0]
            x, y = ox + c * CELL + CELL / 2, oy + r * CELL + CELL / 2
            col = {"s": GREEN, "t": BLUE}.get(code, "#8a8f98")
            out.append(f'<circle cx="{x}" cy="{y}" r="7" fill="none" stroke="{col}" stroke-width="2"/>')
            out.append(f'<text x="{x}" y="{y + 3}" font-size="8" fill="{col}" '
                       f'text-anchor="middle">{esc(code)}</text>')

    # ---- the bodies, at measured size --------------------------------------
    notes: list[str] = []
    over = unmeasured = 0
    for r in range(min(H, len(it))):
        for c in range(min(W, len(it[r]))):
            raw = str(it[r][c]).strip()
            if not raw or raw == "-":
                continue
            tok = raw.split(":")[0].split("#")[0]
            parts = raw.split("#")[0].split(":")
            y_off = None
            if len(parts) >= 3:
                try:
                    y_off = float(parts[2])
                except ValueError:
                    y_off = None
            e = shelf.get(tok, {})
            aabb = e.get("aabb")
            cx, cy = ox + c * CELL + CELL / 2, oy + r * CELL + CELL / 2

            if aabb and (aabb[0] or aabb[2]):
                w_m, d_m = float(aabb[0]), float(aabb[2])
                w, d = w_m * CELL, d_m * CELL
                x0, y0 = cx - w / 2, cy - d / 2
                leaves = (x0 < ox or y0 < oy or x0 + w > ox + W * CELL or y0 + d > oy + H * CELL)
                col = RED if leaves else BLUE
                if leaves:
                    over += 1
                    notes.append(f"OVERRUN  {tok}: {w_m:.1f} x {d_m:.1f} m at r{r} c{c} leaves the room")
                out.append(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{w:.1f}" height="{d:.1f}" '
                           f'fill="{col}" fill-opacity="0.13" stroke="{col}" stroke-width="1.4"/>')
            else:
                unmeasured += 1
                notes.append(f"UNMEASURED  {tok} at r{r} c{c} — no aabb, so no guard on its size")
                out.append(f'<rect x="{cx - CELL / 2:.1f}" y="{cy - CELL / 2:.1f}" width="{CELL}" '
                           f'height="{CELL}" fill="url(#hatch)" stroke="{AMBER}" stroke-width="1.4"/>')

            out.append(f'<circle cx="{cx}" cy="{cy}" r="2.4" fill="{INK}"/>')
            out.append(f'<text x="{cx + 5}" y="{cy - 4}" font-size="8" fill="{INK}">{esc(tok)}</text>')

            under = str(st[r][c]).strip() if r < H and c < W else ""
            if under in ("0", ""):
                notes.append(f"OVER VOID  {tok} at r{r} c{c} stands on a cell with no floor")
            elif under != "1":
                # IN A WALL. 2026-09-03, Palle reading the Symmetry_Seventeen plan:
                # "we have to change the wall around the artifacts... they have to be
                # stamped into the floor to remove the wall?" Yes, for most of them.
                # The registry already knows which: spatial_needs.wall_backing says
                # whether a body WANTS a wall behind it. Corpus-wide, 150 artifacts
                # stand on a wall cell and 123 of them declare wall_backing false --
                # embedded against their own declaration. The other 21 belong there.
                wb = e.get("wall_backing")
                if wb is True:
                    notes.append(f"IN WALL    {tok} at r{r} c{c} — declares wall_backing, so this is by design")
                else:
                    notes.append(f"IN WALL    {tok} at r{r} c{c} on structure '{under}' — "
                                 f"declares no wall backing; carve the cell to floor")
                out.append(f'<rect x="{cx - CELL / 2:.1f}" y="{cy - CELL / 2:.1f}" width="{CELL}" '
                           f'height="{CELL}" fill="none" stroke="{RED}" stroke-width="2.4" '
                           f'stroke-dasharray="3 2"/>')
            if y_off is not None and abs(y_off) > 0.01:
                notes.append(f"Y OFFSET   {tok} at r{r} c{c} is {y_off:+.2f} m — auto-grounding is cancelled")

    # ---- legend ------------------------------------------------------------
    ly = oy + H * CELL + 22
    out.append(f'<text x="{ox}" y="{ly}" font-size="10" fill="#555">'
               f'walls solid · void dashed · body drawn at measured footprint · '
               f'<tspan fill="{RED}">red = leaves the room</tspan> · '
               f'<tspan fill="{AMBER}">hatched = unmeasured</tspan> · '
               f'<tspan fill="{GREEN}">s spawn</tspan> · <tspan fill="{BLUE}">t exit</tspan></text>')
    for i, n in enumerate(notes[:9]):
        col = RED if n.startswith(("OVERRUN", "OVER VOID")) else AMBER
        out.append(f'<text x="{ox}" y="{ly + 16 + i * 13}" font-size="10" fill="{col}">{esc(n)}</text>')
    if len(notes) > 9:
        out.append(f'<text x="{ox}" y="{ly + 16 + 9 * 13}" font-size="10" fill="#666">'
                   f'… and {len(notes) - 9} more</text>')
    out.append("</svg>")
    return "\n".join(out), notes


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("maps", nargs="*")
    ap.add_argument("--seq", default="")
    ap.add_argument("--out", default=os.path.join(ROOT, "doc", "plans"))
    args = ap.parse_args()

    names = list(args.maps)
    if args.seq:
        p = os.path.join(ROOT, "commons", "maps", "sequences", args.seq + ".json")
        d = json.load(open(p, encoding="utf-8"))
        s = d["sequences"][args.seq] if "sequences" in d else d
        names += s.get("maps", [])
    if not names:
        ap.print_help()
        return 1

    shelf = load_shelf()
    os.makedirs(args.out, exist_ok=True)
    tot_over = tot_unmeas = 0
    for m in names:
        if not os.path.exists(os.path.join(ROOT, "commons", "maps", m, "map_data.json")):
            print(f"  {m}: no map_data.json")
            continue
        svg, notes = plan(m, shelf)
        dest = os.path.join(args.out, m + ".svg")
        open(dest, "w", encoding="utf-8").write(svg)
        o = sum(1 for n in notes if n.startswith("OVERRUN"))
        u = sum(1 for n in notes if n.startswith("UNMEASURED"))
        v = sum(1 for n in notes if n.startswith("OVER VOID"))
        tot_over += o
        tot_unmeas += u
        print(f"  {m:38s} -> {os.path.relpath(dest, ROOT)}   "
              f"overrun {o}  unmeasured {u}  over-void {v}")
    print(f"\n{len(names)} plan(s); {tot_over} overrun(s), {tot_unmeas} unmeasured body/ies")
    return 0


if __name__ == "__main__":
    sys.exit(main())
