#!/usr/bin/env python3
"""The first vertical slice — three artifacts through the whole pipeline.

    artifact -> measurements -> spatial contract -> exhibition brief
             -> museum bay -> negotiation -> floor diagnostic
             -> wall diagnostic -> map_data.json -> traversal validation

Three artifacts chosen because they are genuinely different spatial cases, not
three versions of the same one:

    bias_visualizer                a freestanding object, orbitable
    science_screen                 a wall-oriented panel, painting-like
    neural_network_visualization   a large interactive piece, 10 cells wide

Nothing here contains artifact-specific placement code. Swap the three names
and the same pipeline runs.

Usage:
    python tools/spatial_slice.py
    python tools/spatial_slice.py --artifacts=a,b,c --map=My_Map
    python tools/spatial_slice.py --no-map          # diagnostics only
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from spatial_contract import ascii_masks, masks, rotate_offset
from emit_dressing_room import staged_contract
from spatial_floorplan import FloorPlan, WallSurface, build_enfilade, from_museum
from spatial_negotiation import Occupancy, Placement, run

DEFAULT_ARTIFACTS = ["bias_visualizer", "science_screen",
                     "neural_network_visualization"]
DEFAULT_MAP = "Museum_Spatial_Slice"
OUT_DIR = REPO / "ada_run" / "spatial_slice"

#: Cell roles come from the encyclopedia's own ROLES table — the one
#: /template-pattern-editor, /template-gallery, /template-maps and
#: /template-lab all read. The overlay hues come from
#: doc/PLACEMENT_NEGOTIATION.md. Neither is chosen here: a diagnostic that
#: invents its own colours makes one room look like two rooms depending on
#: which tool drew it, which is this project's recurring fault in pixels.
from spatial_palette import (ACCENT, BODY, CIRCULATION, DOOR, GROUND, INK,
                             INK_DIM, PRESENTATION, ROUTE, SIGHT, cell_colour)

CSS_COLOURS = {
    "wall": cell_colour("4"), "floor": cell_colour("1"), "void": GROUND,
    "route": ROUTE, "body": BODY, "circ": CIRCULATION,
    "pres": PRESENTATION, "slot": cell_colour("1s"), "text": INK,
}


# ── Exhibition brief ────────────────────────────────────────────────

def exhibition_brief(names: list[str]) -> list[dict[str, Any]]:
    """Order and semantic role only — never coordinates.

    Reuses the project's canonical 1D order (commons/data/spine_artifact_order
    .json) for sequencing, and each artifact's own contract for its role.
    """
    order_path = REPO / "commons" / "data" / "spine_artifact_order.json"
    rank: dict[str, int] = {}
    if order_path.exists():
        try:
            rows = json.loads(order_path.read_text(encoding="utf-8")).get("order", [])
            for i, row in enumerate(rows):
                rank.setdefault(str(row.get("lookup")), i)
        except Exception:
            pass
    brief = []
    for name in names:
        c = staged_contract(name)
        brief.append({
            "lookup_name": name,
            "role": c.importance,
            "spine_rank": rank.get(name),
            "sequence_known": name in rank,
        })
    brief.sort(key=lambda b: (b["spine_rank"] is None, b["spine_rank"] or 0))
    return brief


# ── Diagnostics ─────────────────────────────────────────────────────

def floor_diagnostic_svg(plan: FloorPlan, placements: list[Placement],
                         occ: Occupancy, cell: int = 22) -> str:
    """Top-down 1 m grid: structure, corridor, and each artifact's three
    envelopes drawn as distinct layers rather than one blended blob."""
    w, h = plan.width * cell, plan.depth * cell
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h + 90}" '
             f'viewBox="0 0 {w} {h + 90}">',
             f'<rect width="{w}" height="{h + 90}" fill="{GROUND}"/>']

    for z in range(plan.depth):
        for x in range(plan.width):
            c = plan.grid[z][x]
            # A slot keeps its own role colour, so a podium reads as a podium
            # here exactly as it does in the pattern editor.
            fill = (ROUTE if (x, z) in plan.route and c not in ("4", "")
                    else cell_colour(c))
            parts.append(f'<rect x="{x * cell}" y="{z * cell}" width="{cell}" '
                         f'height="{cell}" fill="{fill}" stroke="{GROUND}" '
                         f'stroke-width="0.5"/>')

    def paint(cells, colour, opacity):
        for (x, z) in sorted(cells):
            parts.append(f'<rect x="{x * cell}" y="{z * cell}" width="{cell}" '
                         f'height="{cell}" fill="{colour}" opacity="{opacity}"/>')

    for p in placements:
        if p.result != "ACCEPT" or not p.masks:
            continue
        ax, az = p.anchor
        paint({(c[0] + ax, c[1] + az) for c in p.masks.presentation}, CSS_COLOURS["pres"], 0.75)
    for p in placements:
        if p.result != "ACCEPT" or not p.masks:
            continue
        ax, az = p.anchor
        paint({(c[0] + ax, c[1] + az) for c in p.masks.circulation}, CSS_COLOURS["circ"], 0.65)
    for p in placements:
        if p.result != "ACCEPT" or not p.masks:
            continue
        ax, az = p.anchor
        paint({(c[0] + ax, c[1] + az) for c in p.masks.physical}, CSS_COLOURS["body"], 0.92)
        parts.append(
            f'<text x="{ax * cell + cell / 2}" y="{az * cell + cell / 2 + 4}" '
            f'font-family="monospace" font-size="10" fill="#ffffff" '
            f'text-anchor="middle">{p.artifact[:3]}</text>')

    for s in plan.slots:
        x, z = s.cell
        parts.append(f'<circle cx="{x * cell + cell / 2}" cy="{z * cell + cell / 2}" r="3" '
                     f'fill="none" stroke="{CSS_COLOURS["slot"]}" stroke-width="1.5"/>')
    for label, (x, z) in (("S", plan.spawn), ("T", plan.exit)):
        parts.append(f'<text x="{x * cell + cell / 2}" y="{z * cell + cell / 2 + 5}" '
                     f'font-family="monospace" font-size="13" font-weight="bold" '
                     f'text-anchor="middle" fill="{INK}">{label}</text>')

    legend = [("physical", CSS_COLOURS["body"]), ("circulation", CSS_COLOURS["circ"]),
              ("presentation", CSS_COLOURS["pres"]), ("route", CSS_COLOURS["route"]),
              ("slot", CSS_COLOURS["slot"])]
    for i, (name, colour) in enumerate(legend):
        x = 8 + i * 118
        parts.append(f'<rect x="{x}" y="{h + 22}" width="14" height="14" fill="{colour}"/>')
        parts.append(f'<text x="{x + 20}" y="{h + 33}" font-family="sans-serif" '
                     f'font-size="11" fill="{INK}">{name}</text>')
    parts.append(f'<text x="8" y="{h + 62}" font-family="sans-serif" font-size="11" '
                 f'fill="{INK_DIM}">{plan.width} x {plan.depth} m'
                 + (f' — {"; ".join(plan.expansions)}' if plan.expansions else '')
                 + '</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def wall_diagnostic_svg(wall: WallSurface, scale: int = 60) -> str:
    """Wall elevation: bounds, openings, feature zone, mounting heights and
    every occupying rectangle in (u, v)."""
    w = int(wall.length_m * scale) + 80
    h = int(wall.height_m * scale) + 90

    def X(u: float) -> float: return 40 + u * scale
    def Y(v: float) -> float: return 30 + (wall.height_m - v) * scale

    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
             f'viewBox="0 0 {w} {h}">',
             f'<rect width="{w}" height="{h}" fill="{GROUND}"/>',
             f'<rect x="{X(0)}" y="{Y(wall.height_m)}" width="{wall.length_m * scale}" '
             f'height="{wall.height_m * scale}" fill="{cell_colour("4")}" '
             f'stroke="{cell_colour("2")}" stroke-width="2"/>']

    fz = wall.feature_zone
    parts.append(f'<rect x="{X(fz[0])}" y="{Y(fz[3])}" width="{(fz[2] - fz[0]) * scale}" '
                 f'height="{(fz[3] - fz[1]) * scale}" fill="none" stroke="{ACCENT}" '
                 f'stroke-width="1.5" stroke-dasharray="6 4"/>')
    parts.append(f'<text x="{X((fz[0] + fz[2]) / 2)}" y="{Y(fz[3]) - 6}" '
                 f'font-family="sans-serif" font-size="11" fill="{ACCENT}" '
                 f'text-anchor="middle">feature zone</text>')

    for band, label in ((1.55, "eye 1.55 m"), (0.75, "reach 0.75"), (1.35, "reach 1.35")):
        band_ink = cell_colour("1")
        parts.append(f'<line x1="{X(0)}" y1="{Y(band)}" x2="{X(wall.length_m)}" '
                     f'y2="{Y(band)}" stroke="{band_ink}" stroke-width="1" '
                     f'stroke-dasharray="3 5"/>')
        parts.append(f'<text x="4" y="{Y(band) + 4}" font-family="monospace" '
                     f'font-size="9" fill="{INK_DIM}">{label.split()[0]}</text>')

    for op in wall.openings:
        parts.append(f'<rect x="{X(op[0])}" y="{Y(op[3])}" width="{(op[2] - op[0]) * scale}" '
                     f'height="{(op[3] - op[1]) * scale}" fill="{GROUND}" stroke="{cell_colour("2")}" '
                     f'stroke-width="1.5"/>')

    for item in wall.occupied:
        r = item["rect"]
        colour = (BODY if item.get("role") in ("feature", "dna_variant")
                  else CIRCULATION)
        parts.append(f'<rect x="{X(r[0])}" y="{Y(r[3])}" width="{(r[2] - r[0]) * scale}" '
                     f'height="{(r[3] - r[1]) * scale}" fill="{colour}" opacity="0.85" '
                     f'stroke="{GROUND}" stroke-width="1"/>')
        parts.append(f'<text x="{X((r[0] + r[2]) / 2)}" y="{Y((r[1] + r[3]) / 2)}" '
                     f'font-family="monospace" font-size="10" fill="#fff" '
                     f'text-anchor="middle">{item["token"]}</text>')

    parts.append(f'<text x="40" y="{h - 30}" font-family="sans-serif" font-size="12" '
                 f'fill="{INK}">wall {wall.id} — {wall.side}, '
                 f'{wall.length_m:g} x {wall.height_m:g} m, '
                 f'{len(wall.occupied)} occupant(s)</text>')
    parts.append(f'<text x="40" y="{h - 12}" font-family="monospace" font-size="10" '
                 f'fill="{INK_DIM}">u runs along the wall, v floor-to-ceiling</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def explain(p: Placement) -> str:
    """The brief's per-artifact diagnostic block."""
    c = p.contract
    lines = [f"ARTIFACT: {p.artifact}",
             f"placement_mode: {p.mode}",
             f"rotation: {p.rotation}",
             f"slot: {p.slot}    anchor_cell: {list(p.anchor)}"]
    if c:
        lines += ["body:",
                  f"  {c.footprint_cells[0]} x {c.footprint_cells[1]} cells "
                  f"({c.body_m[0]:.2f} x {c.body_m[1]:.2f} x {c.body_m[2]:.2f} m)",
                  "clearance:"]
        lines += [f"  {s}: {c.clearance.get(s, 0)}" for s in ("front", "back", "left", "right")]
        lines.append(f"wall:\n  {p.wall or 'none'}")
        lines.append("required_access:")
        for s in c.required_sides:
            got = next((t for t in p.traces if t.rule == f"required_access.{s}"), None)
            lines.append(f"  {s} = {(got.status.upper() if got else 'N/A')}")
    for rule in ("physical_overlap", "circulation_overlap", "route_preserved", "presentation"):
        t = next((t for t in p.traces if t.rule == rule), None)
        if t:
            lines.append(f"{rule}:\n  {t.status.upper()}")
    if p.wall_rect:
        lines.append(f"wall_rect_uv:\n  {[round(v, 2) for v in p.wall_rect]}")
    lines.append("exceptions:")
    lines += [f"  {e}" for e in p.exceptions] or ["  none"]
    esc = [t for t in p.traces if t.rule == "escalation"]
    if esc:
        lines.append("escalation:")
        lines += [f"  {t.detail}" for t in esc]
    lines.append(f"score:\n  {p.score:.2f}")
    lines.append(f"result:\n  {p.result}")
    return "\n".join(lines)


# ── Map compile + validation ────────────────────────────────────────

def token_cell(p: Placement) -> tuple[int, int]:
    """The cell a map_data interactables token must name so that the artifact's
    BODY lands on the cells the negotiator reserved."""
    ax, az = p.anchor
    c = p.contract
    if c is None:
        return ax, az
    ox = int(round(c.centre_offset_m[0]))
    oz = int(round(c.centre_offset_m[1]))
    if not ox and not oz:
        return ax, az
    rx, rz = rotate_offset(ox, oz, p.rotation)
    return ax - rx, az - rz


def _published(p: Placement) -> dict[str, Any]:
    """A placement as the 3D-correspondence gate needs to read it."""
    row = p.as_dict()
    if p.masks and p.result == "ACCEPT":
        ax, az = p.anchor
        row["expected_cells"] = sorted([c[0] + ax, c[1] + az] for c in p.masks.physical)
        row["token_cell"] = list(token_cell(p))
    if p.contract is not None:
        # The tallest the artifact may stand: its own height, lifted onto
        # whatever surface it was given.
        row["expected_height_m"] = round(
            p.contract.body_m[2]
            + (p.wall_rect[1] if p.wall_rect else p.support_height_m), 3)
    return row


def token_for(p: Placement) -> str:
    """The interactables token for a placement.

    `name:rot` leaves the grid's auto-grounding in charge, which is the
    project's stated convention. A THIRD field is a manual y and switches
    auto-grounding off (GridInteractablesComponent.gd:1253) — so `:0.0` is not
    a harmless default, it silently un-grounds the artifact. Only a wall
    mounting height, which the wall diagnostic actually computed, earns it.
    """
    if p.wall_rect and p.contract is not None:
        y = round(p.wall_rect[1] - p.contract.base_y_m, 3)
        if abs(y) >= 0.01:
            return f"{p.artifact}:{p.rotation}:{y}"
    return f"{p.artifact}:{p.rotation}"


def compile_map(plan: FloorPlan, placements: list[Placement],
                map_name: str) -> dict[str, Any]:
    """Emit the project's 3-layer map_data.json. The assembler stays dumb: it
    receives resolved cells, not a placement problem."""
    W, D = plan.width, plan.depth
    structure = [["1" for _ in range(W)] for _ in range(D)]
    utilities = [["" for _ in range(W)] for _ in range(D)]
    interactables = [["" for _ in range(W)] for _ in range(D)]

    # A structure cell's value IS its height in cubes (GridSystem.cube_size is
    # 1.0), so the wall the negotiator reasoned about and the wall the grid
    # builds are the same wall only if this number follows plan.wall_height_m.
    wall_code = str(max(1, int(round(plan.wall_height_m))))
    for z in range(D):
        for x in range(W):
            structure[z][x] = wall_code if plan.grid[z][x] == "4" else "1"

    sx, sz = plan.spawn
    ex, ez = plan.exit
    utilities[sz][sx] = "s"
    utilities[ez][ex] = "t"
    # Pathfinder rule 5: a teleport stands in a void cell, not on a floor block.
    structure[ez][ex] = "0"

    for p in placements:
        if p.result != "ACCEPT":
            continue
        # The negotiator placed a BODY at p.anchor. A map token places the
        # scene's NODE. For an artifact whose geometry is built off its origin
        # those are different cells, and writing the body cell straight into
        # the token is how a plan that validated in 2D lands somewhere else in
        # 3D — measured on neural_network_visualization, 4.5 m east.
        x, z = token_cell(p)
        if 0 <= x < W and 0 <= z < D:
            interactables[z][x] = token_for(p)

    return {
        "map_info": {
            "name": "Spatial Slice — three contracts, one negotiator",
            "lookup_name": map_name,
            "description": ("A museum bay compiled from resolved spatial contracts. "
                            "Every placement here was negotiated, not authored."),
            "version": "1.0.0",
            "format": "json",
            "dimensions": {"width": W, "depth": D,
                           "max_height": max(4, int(round(plan.wall_height_m)))},
            "metadata": {
                "category": "spatial-pipeline",
                "generator": "tools/spatial_slice.py",
                "expansions": plan.expansions,
                # Each placement publishes the cells it was actually GIVEN, so
                # commons/testing/verify_placement.gd can diff the built museum
                # against the approved plan without re-deriving the contract in
                # a second language (and drifting from it).
                "placements": [_published(p) for p in placements],
            },
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
    }


def kit_buildable(plan: FloorPlan) -> tuple[bool, str]:
    """Can the certified module kit actually build this room?

    `commons/data/museum_module_kit.json` certifies wall pieces at 1–4 m widths
    and a single 4 m height. A negotiator that raises a wall to 9 m has solved
    the artifact's problem by inventing architecture nobody has tested — which
    is exactly the failure mode the kit exists to prevent, so it is reported
    rather than quietly compiled.
    """
    kit = REPO / "commons" / "data" / "museum_module_kit.json"
    piece = REPO.parent / "ada_encyclopedia" / "public" / "museum-wall-kit" / "solid_4m.json"
    height = 4.0
    for path, key in ((piece, "height_m"),):
        if path.exists():
            try:
                height = float(json.loads(path.read_text(encoding="utf-8"))[key])
            except Exception:
                pass
    if not kit.exists():
        return True, "no module kit on disk; nothing to check against"
    if plan.wall_height_m > height + 0.01:
        return False, (f"walls are {plan.wall_height_m:g} m but the kit certifies "
                       f"{height:g} m pieces — this room cannot be built from "
                       f"tested modules")
    return True, f"walls at {plan.wall_height_m:g} m are within the certified {height:g} m"


def traversal_ok(plan: FloorPlan, placements: list[Placement],
                 occ: Occupancy) -> tuple[bool, str]:
    """Spawn must still reach the exit with every body and clearance in place."""
    blocked = set(occ.physical)
    start, goal = plan.spawn, plan.exit
    if start in blocked or goal in blocked:
        return False, "spawn or exit is inside an artifact body"
    seen = {start}
    queue = [start]
    while queue:
        x, z = queue.pop()
        if (x, z) == goal:
            return True, f"spawn {list(start)} reaches exit {list(goal)}"
        for nx, nz in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if (nx, nz) in seen or (nx, nz) in blocked:
                continue
            if not plan.walkable(nx, nz):
                continue
            seen.add((nx, nz))
            queue.append((nx, nz))
    return False, f"exit {list(goal)} unreachable from spawn ({len(seen)} cells visited)"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--artifacts", default=",".join(DEFAULT_ARTIFACTS))
    ap.add_argument("--map", default=DEFAULT_MAP)
    ap.add_argument("--bays", type=int, default=3)
    ap.add_argument("--museum", default="",
                    help="place into one of the 30 authored museum templates "
                         "instead of the parametric enfilade scaffold")
    ap.add_argument("--no-map", action="store_true", help="diagnostics only")
    args = ap.parse_args()

    names = [a.strip() for a in args.artifacts.split(",") if a.strip()]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 66)
    print("EXHIBITION BRIEF  (order and role only — no coordinates)")
    print("=" * 66)
    brief = exhibition_brief(names)
    for b in brief:
        rank = b["spine_rank"]
        print(f"  {b['lookup_name']:32s} {b['role']:11s} "
              f"spine_rank={rank if rank is not None else '-'}")

    print()
    print("=" * 66)
    print("CONTRACTS")
    print("=" * 66)
    for b in brief:
        c = staged_contract(b["lookup_name"])
        print(f"\n  {c.lookup}")
        print(f"    body      {c.body_m[0]:.2f} x {c.body_m[1]:.2f} x {c.body_m[2]:.2f} m "
              f"= {c.footprint_cells[0]} x {c.footprint_cells[1]} cells "
              f"[{c.provenance.get('body.footprint_cells', '?')}]")
        print(f"    modes     {c.modes}  preferred={c.preferred_mode}")
        print(f"    clearance {c.clearance}  [{c.provenance.get('clearance', '?')}]")
        print(f"    access    required={c.required_sides}")
        print(f"    wall      allowed={c.wall_allowed}  flush={c.wall_flush_m} m")
        for cf in c.conflicts:
            print(f"    CONFLICT  {cf}")

    order = [b["lookup_name"] for b in brief]
    base_plan = from_museum(args.museum) if args.museum else None
    plan, placements, occ = run(order, plan=base_plan, bays=args.bays)

    print()
    print("=" * 66)
    print("NEGOTIATION")
    print("=" * 66)
    for p in placements:
        print()
        print(explain(p))

    print()
    print("=" * 66)
    print("MASKS  (O body / c circulation / p presentation)")
    print("=" * 66)
    for p in placements:
        if p.masks:
            print(f"\n  {p.artifact}  mode={p.mode} rotation={p.rotation}")
            for line in ascii_masks(p.masks).splitlines():
                print(f"    {line}")

    # Diagnostics
    (OUT_DIR / "floor_diagnostic.svg").write_text(
        floor_diagnostic_svg(plan, placements, occ), encoding="utf-8")
    wall_files: list[str] = []
    for wall in plan.walls:
        if wall.occupied:
            path = OUT_DIR / f"wall_{wall.id}.svg"
            path.write_text(wall_diagnostic_svg(wall), encoding="utf-8")
            wall_files.append(path.name)

    ok, why = traversal_ok(plan, placements, occ)
    kit_ok, kit_why = kit_buildable(plan)

    report = {
        "schema": "adaresearch.spatial_slice.v1",
        "brief": brief,
        "plan": {"width": plan.width, "depth": plan.depth,
                 "spawn": list(plan.spawn), "exit": list(plan.exit),
                 "expansions": plan.expansions},
        "placements": [p.as_dict() for p in placements],
        "traversal": {"ok": ok, "detail": why},
        "module_kit": {"buildable": kit_ok, "detail": kit_why},
        "diagnostics": {"floor": "floor_diagnostic.svg", "walls": wall_files},
    }
    (OUT_DIR / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    if not args.no_map:
        map_dir = REPO / "commons" / "maps" / args.map
        map_dir.mkdir(parents=True, exist_ok=True)
        (map_dir / "map_data.json").write_text(
            json.dumps(compile_map(plan, placements, args.map), indent=1),
            encoding="utf-8")

    accepted = sum(p.result == "ACCEPT" for p in placements)
    print()
    print("=" * 66)
    print("RESULT")
    print("=" * 66)
    print(f"  placed          {accepted}/{len(placements)}")
    print(f"  room            {plan.width} x {plan.depth} m"
          + (f"   ({'; '.join(plan.expansions)})" if plan.expansions else ""))
    print(f"  traversal       {'PASS' if ok else 'FAIL'} — {why}")
    print(f"  module kit      {'PASS' if kit_ok else 'WARN'} — {kit_why}")
    print(f"  floor diagram   {OUT_DIR / 'floor_diagnostic.svg'}")
    for f in wall_files:
        print(f"  wall diagram    {OUT_DIR / f}")
    if not args.no_map:
        print(f"  map             commons/maps/{args.map}/map_data.json")
    return 0 if (accepted == len(placements) and ok) else 1


if __name__ == "__main__":
    raise SystemExit(main())


def threshold_diagnostic_svg(plan: FloorPlan, placement: Placement,
                             th: Any, cell: int = 12) -> str:
    """Top-down proof of a threshold: the building, the precinct work outside
    it, the door, and the line of sight from a standing point through to it.

    Drawn because a sightline is exactly the kind of claim that reads as true
    in a trace and is false on the floor.
    """
    w, h = plan.width * cell, plan.depth * cell
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h + 54}" '
         f'viewBox="0 0 {w} {h + 54}">',
         f'<rect width="{w}" height="{h + 54}" fill="{GROUND}"/>']
    for z in range(plan.depth):
        for x in range(plan.width):
            c = plan.grid[z][x]
            fill = (ROUTE if (x, z) in plan.route and c not in ("4", "")
                    else cell_colour(c))
            p.append(f'<rect x="{x*cell}" y="{z*cell}" width="{cell}" height="{cell}" '
                     f'fill="{fill}"/>')
    if placement.masks:
        ax, az = placement.anchor
        for c in placement.masks.physical:
            p.append(f'<rect x="{(c[0]+ax)*cell}" y="{(c[1]+az)*cell}" width="{cell}" '
                     f'height="{cell}" fill="{BODY}" opacity="0.9"/>')
    for c in getattr(th, "sight_cells", []):
        p.append(f'<rect x="{c[0]*cell}" y="{c[1]*cell}" width="{cell}" '
                 f'height="{cell}" fill="{SIGHT}" opacity="0.45"/>')
    if getattr(th, "door_cell", None):
        dx, dz = th.door_cell
        p.append(f'<rect x="{dx*cell}" y="{dz*cell}" width="{cell}" height="{cell}" '
                 f'fill="{DOOR}" stroke="{GROUND}" stroke-width="2"/>')
    if getattr(th, "stand_cell", None):
        sx, sz = th.stand_cell
        p.append(f'<circle cx="{sx*cell+cell/2}" cy="{sz*cell+cell/2}" r="{cell*0.35}" '
                 f'fill="none" stroke="{INK}" stroke-width="2"/>')
    legend = [("work", BODY), ("sightline", SIGHT),
              ("door", DOOR), ("route", ROUTE)]
    for i, (name, colour) in enumerate(legend):
        x = 8 + i * 96
        p.append(f'<rect x="{x}" y="{h+16}" width="12" height="12" fill="{colour}"/>')
        p.append(f'<text x="{x+18}" y="{h+26}" font-family="sans-serif" '
                 f'font-size="11" fill="{INK}">{name}</text>')
    p.append(f'<text x="8" y="{h+46}" font-family="sans-serif" font-size="11" '
             f'fill="{INK_DIM}">{placement.artifact} — precinct in the '
             f'{placement.venue}, {th.door_width_m} m portal on the '
             f'{th.door_side} wall</text>')
    p.append("</svg>")
    return "\n".join(p)
