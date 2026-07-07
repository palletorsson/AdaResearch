"""Abstract views of placement. Six families of slice, each revealing
something the others hide.

The point: placement is a RELATION, not a position. Each view foregrounds
one relation:
  - orthographic (x,y,z slices)     — geometry from three angles
  - constraint pressure fields      — what the room wants per artifact
  - walking sequence ribbon         — temporal POV
  - constraint radar per artifact   — 10-metric profile
  - strategy manifold (2D MDS)      — placements as points in quality-space
  - differential field              — strategy A minus strategy B

Run:
  python tools/placement_abstractions.py

Outputs to doc/placement_research/:
  pressure_fields.svg
  orthographic_3view.svg
  walking_ribbon.svg
  constraint_radar.svg
  strategy_manifold.svg
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "doc" / "placement_research" / "results.json"
OUT_DIR = ROOT / "doc" / "placement_research"

CELL = 28
PAD = 14
LABEL_H = 28
GAP = 18

ARTIFACT_COLORS = ["#E63946", "#457B9D", "#F4A261", "#2A9D8F", "#E9C46A", "#9B5DE5"]


def load() -> dict:
    with open(RESULTS, "r", encoding="utf-8") as f:
        return json.load(f)


# ─────────────────────────────────────────────────────────────────────
# View 1: CONSTRAINT PRESSURE FIELDS
# For each artifact, render the cell-by-cell "this artifact would be
# happy here" map. Then overlay where each strategy placed it.
# ─────────────────────────────────────────────────────────────────────

def pressure_for_artifact(artifact: dict, room: dict, partners: list[dict]) -> list[list[float]]:
    """Compute pressure[r][c] = how well cell (r,c) satisfies this artifact's
    constraints, ignoring other artifacts (pure 'where does the room want it')."""
    depth = room["depth"]
    width = room["width"]
    sp_r = room["spawn_row"]; sp_c = room["spawn_col"]
    te_r = room["teleporter_row"]; te_c = room["teleporter_col"]
    footprint = artifact["footprint_cells"]
    fp_dim = max(1, int(round(math.sqrt(footprint))))
    pref_zone = artifact.get("preferred_zone", "any")
    wall_back = artifact.get("wall_backing", False)
    cluster_with = artifact.get("cluster_with", []) or []

    field = [[0.0 for _ in range(width)] for _ in range(depth)]
    for r in range(depth):
        for c in range(width):
            score = 1.0
            # Footprint must fit
            if r + fp_dim > depth or c + fp_dim > width:
                score -= 2.0
            # Don't overlap spawn/teleporter
            for di in range(fp_dim):
                for dj in range(fp_dim):
                    if (r + di, c + dj) == (sp_r, sp_c):
                        score -= 5.0
                    if (r + di, c + dj) == (te_r, te_c):
                        score -= 5.0
            # Wall backing
            cells = [(r + di, c + dj) for di in range(fp_dim) for dj in range(fp_dim)]
            on_wall = any(rr == 0 or rr == depth - 1 or cc == 0 or cc == width - 1
                          for (rr, cc) in cells)
            if wall_back and on_wall:
                score += 1.5
            elif wall_back and not on_wall:
                score -= 1.5
            # Zone match
            zone_r = r + fp_dim // 2
            if zone_r >= 2 * depth // 3:
                zone = "entry"
            elif zone_r <= depth // 3:
                zone = "back"
            else:
                zone = "center"
            if pref_zone == "any":
                pass
            elif zone == pref_zone:
                score += 1.0
            else:
                score -= 0.5
            # Cluster — pull toward partner positions (use spawn-proximity as proxy)
            if cluster_with:
                d_spawn = abs(r - sp_r) + abs(c - sp_c)
                score += max(0, 1.0 - d_spawn / 6.0)
            field[r][c] = score
    return field


def render_pressure_field_svg(data: dict) -> str:
    artifacts = data["artifacts"]
    room = data["room"]
    placements_by_strategy = data["best_placements"]
    strategies_ranked = sorted(data["summary"].items(), key=lambda kv: -kv[1]["mean"])

    # Layout: rows = strategies (top 4), cols = artifacts
    top_strats = [s for s, _ in strategies_ranked[:4]]
    width = room["width"]
    depth = room["depth"]
    panel_w = width * CELL + PAD * 2
    panel_h = depth * CELL + PAD * 2 + LABEL_H + 14

    cols = len(artifacts)
    rows = len(top_strats)
    title_h = 80
    total_w = GAP + cols * (panel_w + GAP)
    total_h = title_h + rows * (panel_h + GAP) + GAP + 60  # space for strategy labels

    parts = [f'<rect width="{total_w}" height="{total_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="{GAP}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Constraint pressure fields — what the room WANTS</text>')
    parts.append(f'<text x="{GAP}" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'Brightness = how much cell satisfies the artifact\'s constraints '
                 f'(walls, isolation, zone, footprint). Dot = where the strategy placed it. '
                 f'Distance between bright spot and dot = placement error.</text>')

    # Pre-compute pressure fields per artifact (room-only, partner-independent)
    pressure_per_artifact = []
    for a in artifacts:
        f = pressure_for_artifact(a, room, [])
        flat = [v for row in f for v in row]
        lo = min(flat); hi = max(flat)
        # normalise to [0,1]
        rng = max(0.001, hi - lo)
        norm = [[(v - lo) / rng for v in row] for row in f]
        pressure_per_artifact.append(norm)

    for ri, strategy in enumerate(top_strats):
        # Strategy label on left
        y_lbl = title_h + ri * (panel_h + GAP) + panel_h / 2 + 8
        score = strategies_ranked[ri][1]["mean"]
        parts.append(f'<g transform="translate(0,0)">')
        # No room for left labels — put in panel title
        parts.append('</g>')
        bp = placements_by_strategy[strategy]
        place_by_name = {p["artifact"]: (p["row"], p["col"]) for p in bp["placements"]}

        for ci, a in enumerate(artifacts):
            x = GAP + ci * (panel_w + GAP)
            y = title_h + ri * (panel_h + GAP)
            field = pressure_per_artifact[ci]

            parts.append(f'<g transform="translate({x},{y})">')
            parts.append(f'<rect width="{panel_w}" height="{panel_h}" '
                         f'fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')

            # Title: artifact + strategy
            if ci == 0:
                parts.append(f'<text x="{PAD}" y="20" font-family="ui-monospace,monospace" '
                             f'font-size="11" font-weight="600" fill="{ARTIFACT_COLORS[ri]}">'
                             f'{strategy}</text>')
                parts.append(f'<text x="{panel_w - PAD}" y="20" font-family="ui-monospace,monospace" '
                             f'font-size="10" fill="#8888A0" text-anchor="end">'
                             f'μ={score:.3f}</text>')
            else:
                parts.append(f'<text x="{PAD}" y="20" font-family="ui-monospace,monospace" '
                             f'font-size="10" fill="#9090A0">'
                             f'#{ci+1} {a["lookup_name"][:20]}</text>')
            # If first row, also show the artifact name on top
            if ri == 0 and ci > 0:
                pass  # placeholder

            # Cells with pressure
            for r in range(depth):
                for c in range(width):
                    p = field[r][c]
                    # Map [0,1] to color from #1F1F26 to #FBE38A (warm)
                    if p < 0:
                        col = "#2A1B1B"
                    else:
                        # bilinear interpolation black -> warm yellow
                        rr = int(0x1F + (0xFB - 0x1F) * p)
                        gg = int(0x1F + (0xE3 - 0x1F) * p)
                        bb = int(0x26 + (0x8A - 0x26) * p)
                        col = f"#{rr:02X}{gg:02X}{bb:02X}"
                    parts.append(f'<rect x="{PAD + c * CELL}" y="{LABEL_H + r * CELL}" '
                                 f'width="{CELL}" height="{CELL}" fill="{col}"/>')

            # Spawn / teleporter markers
            parts.append(f'<text x="{PAD + room["spawn_col"] * CELL + CELL/2}" '
                         f'y="{LABEL_H + room["spawn_row"] * CELL + CELL/2 + 4}" '
                         f'font-family="ui-monospace,monospace" font-size="11" '
                         f'font-weight="700" fill="#80FF80" text-anchor="middle">S</text>')
            parts.append(f'<text x="{PAD + room["teleporter_col"] * CELL + CELL/2}" '
                         f'y="{LABEL_H + room["teleporter_row"] * CELL + CELL/2 + 4}" '
                         f'font-family="ui-monospace,monospace" font-size="11" '
                         f'font-weight="700" fill="#FF8080" text-anchor="middle">T</text>')

            # Strategy's placement of THIS artifact
            if a["lookup_name"] in place_by_name:
                pr, pc = place_by_name[a["lookup_name"]]
                fp = max(1, int(round(math.sqrt(a["footprint_cells"]))))
                # box around placement
                bx = PAD + pc * CELL
                by = LABEL_H + pr * CELL
                parts.append(f'<rect x="{bx}" y="{by}" width="{fp * CELL}" '
                             f'height="{fp * CELL}" fill="none" '
                             f'stroke="{ARTIFACT_COLORS[ci]}" stroke-width="3"/>')
                # dot at center
                cx = bx + fp * CELL / 2
                cy = by + fp * CELL / 2
                parts.append(f'<circle cx="{cx}" cy="{cy}" r="5" '
                             f'fill="{ARTIFACT_COLORS[ci]}" stroke="#0A0A0E" stroke-width="2"/>')

            # Outline
            parts.append(f'<rect x="{PAD}" y="{LABEL_H}" width="{width * CELL}" '
                         f'height="{depth * CELL}" fill="none" stroke="#3A3A45"/>')

            parts.append('</g>')

    # Artifact key at bottom
    key_y = title_h + rows * (panel_h + GAP) + 10
    parts.append(f'<text x="{GAP}" y="{key_y + 20}" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'Pressure colour: dark = unwanted · warm = ideal. '
                 f'Box+dot = where the strategy placed the artifact.</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{total_w}" height="{total_h}" '
            f'viewBox="0 0 {total_w} {total_h}">'
            + "".join(parts) + '</svg>')


# ─────────────────────────────────────────────────────────────────────
# View 2: ORTHOGRAPHIC 3-VIEW (top + front + side)
# Engineering drawing — three orthogonal projections of the same map.
# Top (x,z), Front (x,y), Side (z,y).
# ─────────────────────────────────────────────────────────────────────

def render_orthographic_svg(data: dict, strategy: str = "simulated_annealing") -> str:
    room = data["room"]
    bp = data["best_placements"][strategy]
    artifacts = data["artifacts"]
    name_to_art = {a["lookup_name"]: a for a in artifacts}

    width = room["width"]; depth = room["depth"]
    # Use approximate height = footprint_cells (taller = bigger artifact)
    def height_of(name: str) -> int:
        a = name_to_art.get(name, {})
        return max(1, min(3, a.get("footprint_cells", 1)))

    max_h = 3
    cell = 32
    pad = 16

    # Three panels: top (x,z = width × depth), front (x,y = width × max_h), side (z,y = depth × max_h)
    top_w = width * cell + pad * 2
    top_h = depth * cell + pad * 2 + LABEL_H
    front_h_total = max_h * cell + pad * 2 + LABEL_H
    side_w = depth * cell + pad * 2

    # Layout: top | side
    #          front
    layout_w = pad + top_w + GAP + side_w + pad
    layout_h = 90 + top_h + GAP + front_h_total + pad

    parts = [f'<rect width="{layout_w}" height="{layout_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="{pad}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Orthographic 3-view — {strategy} placement, score {bp["score"]:.3f}</text>')
    parts.append(f'<text x="{pad}" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'Top (x,z) · Side (z,y) · Front (x,y). '
                 f'Artifact heights proxied from footprint_cells.</text>')

    place_data = []   # (artifact, row, col, fp_dim, h, color)
    for i, p in enumerate(bp["placements"]):
        a = name_to_art[p["artifact"]]
        fp = max(1, int(round(math.sqrt(a["footprint_cells"]))))
        h = height_of(p["artifact"])
        color = ARTIFACT_COLORS[i % len(ARTIFACT_COLORS)]
        place_data.append((p["artifact"], p["row"], p["col"], fp, h, color))

    # TOP VIEW (x = col, z = row, viewed from above)
    top_x = pad
    top_y = 90
    parts.append(f'<g transform="translate({top_x},{top_y})">')
    parts.append(f'<rect width="{top_w}" height="{top_h}" fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')
    parts.append(f'<text x="{pad}" y="20" font-family="ui-monospace,monospace" '
                 f'font-size="12" fill="#E8E8EE" font-weight="600">TOP (x,z)</text>')
    # grid
    for r in range(depth):
        for c in range(width):
            parts.append(f'<rect x="{pad + c * cell}" y="{LABEL_H + r * cell}" '
                         f'width="{cell}" height="{cell}" '
                         f'fill="#0E0E12" stroke="#1F1F26" stroke-width="0.5"/>')
    # spawn/teleporter
    sx = pad + room["spawn_col"] * cell + cell / 2
    sy = LABEL_H + room["spawn_row"] * cell + cell / 2
    parts.append(f'<circle cx="{sx}" cy="{sy}" r="6" fill="#4D7C0F"/>')
    parts.append(f'<text x="{sx}" y="{sy + 4}" font-family="ui-monospace,monospace" '
                 f'font-size="10" fill="#FFF" text-anchor="middle">S</text>')
    tx = pad + room["teleporter_col"] * cell + cell / 2
    ty = LABEL_H + room["teleporter_row"] * cell + cell / 2
    parts.append(f'<circle cx="{tx}" cy="{ty}" r="6" fill="#7C2D12"/>')
    parts.append(f'<text x="{tx}" y="{ty + 4}" font-family="ui-monospace,monospace" '
                 f'font-size="10" fill="#FFF" text-anchor="middle">T</text>')
    # placements
    for (name, row, col, fp, h, color) in place_data:
        parts.append(f'<rect x="{pad + col * cell}" y="{LABEL_H + row * cell}" '
                     f'width="{fp * cell}" height="{fp * cell}" '
                     f'fill="{color}" fill-opacity="0.7" stroke="{color}" stroke-width="2"/>')
        cx = pad + col * cell + fp * cell / 2
        cy = LABEL_H + row * cell + fp * cell / 2
        parts.append(f'<text x="{cx}" y="{cy + 4}" font-family="ui-monospace,monospace" '
                     f'font-size="9" fill="#FFF" text-anchor="middle" font-weight="700">'
                     f'{name[:8]}</text>')
    # axis labels
    parts.append(f'<text x="{pad}" y="{LABEL_H + depth * cell + 12}" '
                 f'font-family="ui-monospace,monospace" font-size="9" fill="#606070">'
                 f'← back wall (row 0)    →    spawn (row {depth-1})</text>')
    parts.append('</g>')

    # SIDE VIEW (z = row, y = height, viewed from right)
    side_x = top_x + top_w + GAP
    side_y = top_y
    parts.append(f'<g transform="translate({side_x},{side_y})">')
    side_h = max_h * cell + pad * 2 + LABEL_H + 24
    parts.append(f'<rect width="{side_w}" height="{top_h}" fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')
    parts.append(f'<text x="{pad}" y="20" font-family="ui-monospace,monospace" '
                 f'font-size="12" fill="#E8E8EE" font-weight="600">SIDE (z,y)</text>')
    # grid: z (row) on x-axis, y (height) on y-axis
    floor_y = top_h - pad - cell  # floor line
    for r in range(depth):
        for h_level in range(max_h):
            yy = floor_y - h_level * cell
            parts.append(f'<rect x="{pad + r * cell}" y="{yy}" width="{cell}" '
                         f'height="{cell}" fill="#0E0E12" stroke="#1F1F26" stroke-width="0.5"/>')
    # spawn marker at row, height=0
    parts.append(f'<circle cx="{pad + room["spawn_row"] * cell + cell/2}" cy="{floor_y + cell/2}" '
                 f'r="4" fill="#4D7C0F"/>')
    parts.append(f'<circle cx="{pad + room["teleporter_row"] * cell + cell/2}" cy="{floor_y + cell/2}" '
                 f'r="4" fill="#7C2D12"/>')
    # artifacts: width along z (row+fp), height = h
    for (name, row, col, fp, h, color) in place_data:
        # The artifact spans rows [row, row+fp-1] at heights [0, h-1]
        for r_off in range(fp):
            for h_level in range(h):
                rr = row + r_off
                xx = pad + rr * cell
                yy = floor_y - h_level * cell
                parts.append(f'<rect x="{xx}" y="{yy}" width="{cell}" height="{cell}" '
                             f'fill="{color}" fill-opacity="0.6" stroke="{color}" stroke-width="1"/>')
    parts.append('</g>')

    # FRONT VIEW (x = col, y = height, viewed from front)
    front_x = top_x
    front_y = top_y + top_h + GAP
    parts.append(f'<g transform="translate({front_x},{front_y})">')
    parts.append(f'<rect width="{top_w}" height="{front_h_total}" fill="#1A1A1F" stroke="#2A2A33" rx="6"/>')
    parts.append(f'<text x="{pad}" y="20" font-family="ui-monospace,monospace" '
                 f'font-size="12" fill="#E8E8EE" font-weight="600">FRONT (x,y) — what player sees</text>')
    floor_y = front_h_total - pad - cell
    for c in range(width):
        for h_level in range(max_h):
            yy = floor_y - h_level * cell
            parts.append(f'<rect x="{pad + c * cell}" y="{yy}" width="{cell}" height="{cell}" '
                         f'fill="#0E0E12" stroke="#1F1F26" stroke-width="0.5"/>')
    parts.append(f'<circle cx="{pad + room["spawn_col"] * cell + cell/2}" cy="{floor_y + cell/2}" '
                 f'r="4" fill="#4D7C0F"/>')
    parts.append(f'<circle cx="{pad + room["teleporter_col"] * cell + cell/2}" cy="{floor_y + cell/2}" '
                 f'r="4" fill="#7C2D12"/>')
    for (name, row, col, fp, h, color) in place_data:
        for c_off in range(fp):
            for h_level in range(h):
                cc = col + c_off
                xx = pad + cc * cell
                yy = floor_y - h_level * cell
                parts.append(f'<rect x="{xx}" y="{yy}" width="{cell}" height="{cell}" '
                             f'fill="{color}" fill-opacity="0.5" stroke="{color}" stroke-width="1"/>')
    parts.append('</g>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{layout_w}" height="{layout_h}" '
            f'viewBox="0 0 {layout_w} {layout_h}">'
            + "".join(parts) + '</svg>')


# ─────────────────────────────────────────────────────────────────────
# View 3: WALKING SEQUENCE RIBBON
# Reduce the 2D floor to a 1D ribbon: what does the player encounter
# at each step along the walk from spawn to teleporter?
# ─────────────────────────────────────────────────────────────────────

def render_walking_ribbon_svg(data: dict) -> str:
    room = data["room"]
    artifacts = data["artifacts"]
    name_to_art = {a["lookup_name"]: a for a in artifacts}
    strategies_ranked = sorted(data["summary"].items(), key=lambda kv: -kv[1]["mean"])
    strategies = [s for s, _ in strategies_ranked]

    sp_r, sp_c = room["spawn_row"], room["spawn_col"]
    te_r, te_c = room["teleporter_row"], room["teleporter_col"]
    width = room["width"]; depth = room["depth"]

    # Each strategy: compute a straight-line walk from spawn to teleporter,
    # sample N=8 points, find nearest artifact to each, score visibility
    N = 8
    samples = []
    for t in range(N + 1):
        a = t / N
        r = sp_r + (te_r - sp_r) * a
        c = sp_c + (te_c - sp_c) * a
        samples.append((r, c))

    ribbon_h = 60
    margin = 100
    canvas_w = 1100
    canvas_h = 80 + len(strategies) * (ribbon_h + 12) + 40

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Walking sequence — what player encounters spawn → teleporter</text>')
    parts.append(f'<text x="20" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'Each strategy reduced to a 1D ribbon. '
                 f'For each step along the walk, the closest artifact is named. '
                 f'Reveals: does the player encounter artifacts in sensible order?</text>')

    for si, strategy in enumerate(strategies):
        bp = data["best_placements"][strategy]
        place_data = {p["artifact"]: (p["row"], p["col"]) for p in bp["placements"]}
        y = 80 + si * (ribbon_h + 12)

        # Label
        parts.append(f'<text x="20" y="{y + ribbon_h/2 + 5}" font-family="ui-monospace,monospace" '
                     f'font-size="12" fill="#E8E8EE" font-weight="600">{strategy}</text>')
        parts.append(f'<text x="20" y="{y + ribbon_h/2 + 22}" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#8888A0">μ={data["summary"][strategy]["mean"]:.3f}</text>')

        # Ribbon (gradient from S to T)
        rx = margin
        rw = canvas_w - margin - 20
        # background bar
        parts.append(f'<defs><linearGradient id="grad{si}" x1="0" y1="0" x2="1" y2="0">'
                     f'<stop offset="0" stop-color="#1F2E12"/>'
                     f'<stop offset="1" stop-color="#2E1212"/>'
                     f'</linearGradient></defs>')
        parts.append(f'<rect x="{rx}" y="{y}" width="{rw}" height="{ribbon_h}" '
                     f'fill="url(#grad{si})" stroke="#2A2A33" rx="4"/>')
        # S and T markers
        parts.append(f'<text x="{rx + 6}" y="{y + 18}" font-family="ui-monospace,monospace" '
                     f'font-size="12" font-weight="700" fill="#80FF80">S</text>')
        parts.append(f'<text x="{rx + rw - 14}" y="{y + 18}" font-family="ui-monospace,monospace" '
                     f'font-size="12" font-weight="700" fill="#FF8080">T</text>')

        # For each sample point, find nearest artifact and tick
        for ti, (sr, sc) in enumerate(samples):
            x_pos = rx + (rw * ti / N)
            best_name = None
            best_d = 1e9
            for name, (pr, pc) in place_data.items():
                a = name_to_art[name]
                fp = max(1, int(round(math.sqrt(a["footprint_cells"]))))
                ccx = pc + fp / 2
                ccy = pr + fp / 2
                d = math.hypot(sr - ccy, sc - ccx)
                if d < best_d:
                    best_d = d; best_name = name
            color = ARTIFACT_COLORS[list(place_data.keys()).index(best_name) % 6] if best_name else "#555"
            # vertical tick
            parts.append(f'<line x1="{x_pos}" y1="{y + 22}" x2="{x_pos}" y2="{y + ribbon_h - 6}" '
                         f'stroke="{color}" stroke-width="3"/>')
            # artifact label (small)
            short = best_name[:10] if best_name else "—"
            parts.append(f'<text x="{x_pos}" y="{y + ribbon_h - 2}" '
                         f'font-family="ui-monospace,monospace" font-size="8" '
                         f'fill="{color}" text-anchor="middle">{short}</text>')
            # distance dot
            r_size = max(2, 8 - best_d)
            parts.append(f'<circle cx="{x_pos}" cy="{y + 30}" r="{r_size}" fill="{color}" '
                         f'fill-opacity="0.7"/>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">'
            + "".join(parts) + '</svg>')


# ─────────────────────────────────────────────────────────────────────
# View 4: STRATEGY MANIFOLD — placements as points in quality space
# ─────────────────────────────────────────────────────────────────────

def render_manifold_svg(data: dict) -> str:
    """2D projection of the 10-metric profile per strategy.
    Simple MDS via PCA-like: project onto first two principal axes
    (computed approximately, no numpy)."""
    strategies = list(data["summary"].keys())
    metric_keys = list(data["summary"][strategies[0]]["per_metric"].keys())
    vectors = []
    for s in strategies:
        v = [data["summary"][s]["per_metric"][k] for k in metric_keys]
        vectors.append(v)

    # Centre
    n = len(strategies); m = len(metric_keys)
    means = [sum(v[k] for v in vectors) / n for k in range(m)]
    centred = [[v[k] - means[k] for k in range(m)] for v in vectors]

    # Compute axes manually via projection on two manually-chosen contrast vectors:
    # axis1 = "geometric vs frequency" — isolation/clearance/wall vs cluster/zone
    # axis2 = "deterministic vs noisy" — score std (proxy via worst)
    iso_idx = metric_keys.index("isolation_satisfied")
    clr_idx = metric_keys.index("clearance_satisfied")
    wall_idx = metric_keys.index("wall_backing_satisfied")
    clst_idx = metric_keys.index("cluster_satisfied")
    zone_idx = metric_keys.index("preferred_zone_match")
    reach_idx = metric_keys.index("reachability")

    def axis1(v): return v[iso_idx] + v[clr_idx] + v[wall_idx] - v[clst_idx] - v[zone_idx]
    def axis2(v): return v[reach_idx] + v[clst_idx] + v[zone_idx]

    xs = [axis1(v) for v in centred]
    ys = [axis2(v) for v in centred]

    # Layout
    canvas_w = 900; canvas_h = 600
    margin_l = 110; margin_b = 90; margin_t = 80; margin_r = 40
    plot_w = canvas_w - margin_l - margin_r
    plot_h = canvas_h - margin_t - margin_b

    xlo, xhi = min(xs) - 0.1, max(xs) + 0.1
    ylo, yhi = min(ys) - 0.1, max(ys) + 0.1
    if xhi == xlo: xhi = xlo + 1
    if yhi == ylo: yhi = ylo + 1

    def px(x): return margin_l + (x - xlo) / (xhi - xlo) * plot_w
    def py(y): return margin_t + plot_h - (y - ylo) / (yhi - ylo) * plot_h

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Strategy manifold — placements as points in quality space</text>')
    parts.append(f'<text x="20" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'X = geometry-vs-relation balance · Y = walkability + relational success</text>')

    # Axes
    parts.append(f'<line x1="{margin_l}" y1="{margin_t + plot_h}" '
                 f'x2="{margin_l + plot_w}" y2="{margin_t + plot_h}" stroke="#3A3A45"/>')
    parts.append(f'<line x1="{margin_l}" y1="{margin_t}" '
                 f'x2="{margin_l}" y2="{margin_t + plot_h}" stroke="#3A3A45"/>')

    # Axis labels
    parts.append(f'<text x="{margin_l + plot_w/2}" y="{margin_t + plot_h + 32}" '
                 f'font-family="ui-monospace,monospace" font-size="11" '
                 f'fill="#9090A0" text-anchor="middle">'
                 f'geometric (iso+clr+wall) ← → relational (cluster+zone)</text>')
    parts.append(f'<text x="40" y="{margin_t + plot_h/2}" '
                 f'font-family="ui-monospace,monospace" font-size="11" '
                 f'fill="#9090A0" text-anchor="middle" '
                 f'transform="rotate(-90, 40, {margin_t + plot_h/2})">'
                 f'walkability + relational</text>')

    # Points
    for i, s in enumerate(strategies):
        x = px(xs[i]); y = py(ys[i])
        mean = data["summary"][s]["mean"]
        radius = 6 + (mean - 0.78) * 60
        color = ARTIFACT_COLORS[i % len(ARTIFACT_COLORS)]
        parts.append(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="{color}" '
                     f'fill-opacity="0.45" stroke="{color}" stroke-width="2"/>')
        parts.append(f'<text x="{x}" y="{y + radius + 14}" font-family="ui-monospace,monospace" '
                     f'font-size="11" font-weight="600" fill="#E8E8EE" text-anchor="middle">'
                     f'{s}</text>')
        parts.append(f'<text x="{x}" y="{y + radius + 28}" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#8888A0" text-anchor="middle">'
                     f'μ={mean:.3f}</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">'
            + "".join(parts) + '</svg>')


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

def main():
    data = load()

    outputs = [
        ("pressure_fields.svg",      render_pressure_field_svg(data)),
        ("orthographic_3view.svg",   render_orthographic_svg(data, "simulated_annealing")),
        ("walking_ribbon.svg",       render_walking_ribbon_svg(data)),
        ("strategy_manifold.svg",    render_manifold_svg(data)),
    ]
    for name, svg in outputs:
        path = OUT_DIR / name
        with open(path, "w", encoding="utf-8") as f:
            f.write(svg)
        print(f"wrote {path}")
    print("\nopen any in a browser:")
    for name, _ in outputs:
        print(f"  doc/placement_research/{name}")


if __name__ == "__main__":
    main()
