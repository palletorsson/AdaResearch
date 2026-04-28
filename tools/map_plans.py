#!/usr/bin/env python
"""map_plans.py — orthographic plan, section, and elevation drawings of any map.

Reads commons/maps/<MapName>/map_data.json + the artifact registry, produces
four SVGs per map:
  plan.svg         top-down (the floor plan — layout, density, footprints, path)
  section_x.svg    cut at central column, looking west (y-axis usage)
  section_z.svg    cut at central row, looking south (elevation along walking path)
  elevation.svg    front-on facade (silhouette)

Cheap, fast, no Godot. Direct SVG generation. ~1 second per map.

Output:
  doc/plans/<MapName>/plan.svg
  doc/plans/<MapName>/section_x.svg
  doc/plans/<MapName>/section_z.svg
  doc/plans/<MapName>/elevation.svg
  doc/plans/<MapName>/plans.json   (raw layout for atlas / encyclopedia consumption)

Usage:
  python tools/map_plans.py --map=QFEP_Synthesis
  python tools/map_plans.py --map=QFEP_Synthesis --out-dir=public/plans
  python tools/map_plans.py --batch foundationscrisis qfeplaboratory
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
OUT_DIR_DEFAULT = REPO / "doc" / "plans"

CELL = 22         # px per grid cell
FONT_SMALL = 9
FONT_MED = 11

# Family → colour. Falls back to hash for unknowns.
FAMILY_COLORS = {
    "qfep":                  "#d23b6e",
    "color":                 "#d8a04b",
    "cellular_automata":     "#3da3a3",
    "fractals":              "#7148a8",
    "lsystems":              "#5fa14a",
    "randomness":            "#b94a4a",
    "machinelearning":       "#3b6cb0",
    "physics_simulation":    "#9b6f3a",
    "wavefunctions":         "#c557a3",
    "primitives":            "#7a7a7a",
    "foundations":           "#2b6788",
    "hazards":               "#d65a3a",
    "computational_biology": "#4ba17b",
    "nature_system":         "#3da353",
    "mesh_grammar":          "#cc5040",
    "commons_artifacts":     "#666666",
    "isosurfaces":           "#cf8a3d",
    "alternative_geometries":"#43678f",
    "neuroscience":          "#7c3aa1",
    "lab":                   "#90786b",
    "living_paper":          "#83b54d",
    "datastructures":        "#9b9032",
    "topology":              "#5a8a52",
    "transforms":            "#aa6a3b",
    "shaders":               "#6b8a4a",
    "parametric":            "#a04a87",
    "grammar_systems":       "#3aa180",
    "procgen_extra":         "#8a5a3a",
    "algorithms_misc":       "#7d7d7d",
    "arrays":                "#5b8089",
    "bar_array":             "#5b8089",
    "chaos":                 "#a83a3a",
    "furniture":             "#856b48",
}


def family_color(family: str) -> str:
    if family in FAMILY_COLORS:
        return FAMILY_COLORS[family]
    h = hash(family) & 0xFFFFFF
    return f"#{h:06x}"


# ───────────────────────────────────────────────────────────────────────
# Artifact registry → footprint + family lookup
# ───────────────────────────────────────────────────────────────────────

def load_artifact_index() -> dict[str, dict]:
    """{lookup_name: {family, footprint:(w,d,h)}}"""
    index: dict[str, dict] = {}
    for json_path in sorted(REGISTRY_DIR.glob("*.json")):
        family = json_path.stem
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if isinstance(data, dict) and "artifacts" in data and isinstance(data["artifacts"], dict):
            entries = data["artifacts"]
        elif isinstance(data, dict):
            metadata_keys = {"registry_info", "registry_name", "description",
                             "_comment", "_note", "sequence_mapping"}
            entries = {k: v for k, v in data.items()
                       if k not in metadata_keys and isinstance(v, dict)}
        elif isinstance(data, list):
            entries = {it.get("lookup_name", f"{family}_{i}"): it
                       for i, it in enumerate(data) if isinstance(it, dict)}
        else:
            continue
        for name, entry in entries.items():
            if not isinstance(entry, dict):
                continue
            fp = entry.get("footprint", [1.0, 1.0, 1.0])
            try:
                fw = float(fp[0]) if len(fp) >= 1 else 1.0
                fd = float(fp[1]) if len(fp) >= 2 else 1.0
                fh = float(fp[2]) if len(fp) >= 3 else 1.0
            except Exception:
                fw, fd, fh = 1.0, 1.0, 1.0
            index[name] = {"family": family, "footprint": (fw, fd, fh)}
    return index


# ───────────────────────────────────────────────────────────────────────
# Map parsing
# ───────────────────────────────────────────────────────────────────────

def parse_map(map_name: str) -> dict | None:
    p = MAPS_DIR / map_name / "map_data.json"
    if not p.exists():
        return None
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None
    info = d.get("map_info", {})
    layers = d.get("layers", {})
    structure = layers.get("structure", []) or []
    utilities = layers.get("utilities", []) or []
    interactables = layers.get("interactables", []) or []
    if not structure:
        return None

    rows = len(structure)
    cols = len(structure[0]) if structure else 0

    # Heights as floats; structure values are sometimes strings.
    heights: list[list[float]] = []
    for r in range(rows):
        h_row = []
        row = structure[r] if r < len(structure) else []
        for c in range(cols):
            v = row[c] if c < len(row) else 0
            try:
                h_row.append(float(v))
            except Exception:
                h_row.append(0.0)
        heights.append(h_row)

    # Spawn + teleporter from utilities (cells starting with 's' or 't').
    spawn = None
    teleport = None
    labels: list[tuple[int, int, str]] = []
    for r in range(min(rows, len(utilities))):
        u_row = utilities[r] if isinstance(utilities[r], list) else []
        for c in range(min(cols, len(u_row))):
            cell = u_row[c]
            if not isinstance(cell, str):
                continue
            cell = cell.strip()
            if not cell or cell == " ":
                continue
            head = cell.split(":")[0]
            if head == "s" or head == "sp":
                spawn = (r, c)
            elif head == "t":
                teleport = (r, c)
            elif head == "3t" and ":" in cell:
                labels.append((r, c, cell.split(":", 1)[1]))

    # Artifacts from interactables.
    artifacts: list[dict] = []
    for r in range(min(rows, len(interactables))):
        i_row = interactables[r] if isinstance(interactables[r], list) else []
        for c in range(min(cols, len(i_row))):
            cell = i_row[c]
            if not isinstance(cell, str):
                continue
            cell = cell.strip()
            if not cell or cell == " ":
                continue
            base = cell.split(":")[0]
            # Skip util-shaped tokens that occasionally land in interactables.
            if base in {"s", "sp", "t"}:
                continue
            artifacts.append({"row": r, "col": c, "name": base, "raw": cell})

    return {
        "name": map_name,
        "title": info.get("title", map_name),
        "description": info.get("description", ""),
        "rows": rows,
        "cols": cols,
        "heights": heights,
        "spawn": spawn,
        "teleport": teleport,
        "labels": labels,
        "artifacts": artifacts,
    }


# ───────────────────────────────────────────────────────────────────────
# SVG primitives
# ───────────────────────────────────────────────────────────────────────

def height_color(h: float) -> str:
    """Greyscale by height; 0 = void, 1 = floor, 2 = wall, 3+ = plinth."""
    if h <= 0:
        return "#101015"
    if h <= 1:
        return "#4a4a52"
    if h <= 2:
        return "#3a3a42"
    return "#2a2a32"


def svg_open(width: int, height: int, title: str, subtitle: str = "") -> list[str]:
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" font-family="ui-sans-serif,system-ui,-apple-system,sans-serif">',
        '<style>',
        '.title{font-size:14px;font-weight:bold;fill:#eee}',
        '.subtitle{font-size:10px;fill:#888}',
        '.label{font-size:9px;fill:#bbb;text-anchor:middle;pointer-events:none}',
        '.legend{font-size:9px;fill:#888}',
        '</style>',
        f'<rect width="{width}" height="{height}" fill="#1a1a1f"/>',
        f'<text class="title" x="14" y="20">{title}</text>',
    ]
    if subtitle:
        parts.append(f'<text class="subtitle" x="14" y="36">{subtitle}</text>')
    return parts


def svg_close() -> str:
    return "</svg>"


# ───────────────────────────────────────────────────────────────────────
# Plan view (top-down)
# ───────────────────────────────────────────────────────────────────────

def render_plan(m: dict, art_index: dict[str, dict]) -> str:
    rows = m["rows"]
    cols = m["cols"]
    margin = 50
    width = margin * 2 + cols * CELL
    height = margin * 2 + rows * CELL + 80  # extra for legend

    parts = svg_open(width, height,
                     f"{m['title']} — plan (top-down)",
                     f"{cols}×{rows} grid, looking down −Y")

    # Cell heights as floor tiles.
    for r in range(rows):
        for c in range(cols):
            x = margin + c * CELL
            y = margin + r * CELL
            h = m["heights"][r][c]
            parts.append(
                f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                f'fill="{height_color(h)}" stroke="#0d0d12" stroke-width="0.4"/>'
            )

    # Path: spawn → teleport (dashed line).
    if m["spawn"] and m["teleport"]:
        sr, sc = m["spawn"]
        tr, tc = m["teleport"]
        parts.append(
            f'<line x1="{margin + sc * CELL + CELL/2}" y1="{margin + sr * CELL + CELL/2}" '
            f'x2="{margin + tc * CELL + CELL/2}" y2="{margin + tr * CELL + CELL/2}" '
            f'stroke="#6b6" stroke-width="1.3" stroke-dasharray="4 3" opacity="0.55"/>'
        )

    # Spawn + teleport markers.
    if m["spawn"]:
        sr, sc = m["spawn"]
        cx = margin + sc * CELL + CELL / 2
        cy = margin + sr * CELL + CELL / 2
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="6" fill="#4ade80" stroke="#0d0d12" stroke-width="1"/>')
        parts.append(f'<text x="{cx + 9}" y="{cy + 3}" font-size="9" fill="#4ade80">spawn</text>')
    if m["teleport"]:
        tr, tc = m["teleport"]
        cx = margin + tc * CELL + CELL / 2
        cy = margin + tr * CELL + CELL / 2
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="6" fill="#f87171" stroke="#0d0d12" stroke-width="1"/>')
        parts.append(f'<text x="{cx + 9}" y="{cy + 3}" font-size="9" fill="#f87171">teleport</text>')

    # Artifacts: footprint-sized rectangles.
    families_used: set[str] = set()
    for a in m["artifacts"]:
        info = art_index.get(a["name"], {})
        family = info.get("family", "unknown")
        families_used.add(family)
        fp = info.get("footprint", (1.0, 1.0, 1.0))
        # footprint = (width, depth, height); use width × depth on plan.
        fw = max(0.5, min(fp[0], 4.0))
        fd = max(0.5, min(fp[1], 4.0))
        col = family_color(family)
        cx = margin + a["col"] * CELL + CELL / 2
        cy = margin + a["row"] * CELL + CELL / 2
        rw = fw * CELL * 0.78
        rd = fd * CELL * 0.78
        parts.append(
            f'<rect x="{cx - rw/2:.1f}" y="{cy - rd/2:.1f}" width="{rw:.1f}" height="{rd:.1f}" '
            f'fill="{col}" stroke="#fff" stroke-width="0.6" opacity="0.92" rx="1.5">'
            f'<title>{a["name"]}\nfamily: {family}\nfootprint: {fp}</title></rect>'
        )
        # Tiny label below the rect.
        if rw >= 14:
            parts.append(
                f'<text x="{cx:.1f}" y="{cy + rd/2 + 9:.1f}" class="label">{a["name"][:18]}</text>'
            )

    # 3D-text labels (utility 3t cells) shown as small italic text.
    for r, c, txt in m["labels"]:
        cx = margin + c * CELL + CELL / 2
        cy = margin + r * CELL + CELL / 2
        snippet = txt.split(":")[0][:24]
        parts.append(
            f'<text x="{cx:.1f}" y="{cy + 3:.1f}" font-size="7" fill="#aaa" '
            f'text-anchor="middle" font-style="italic" pointer-events="none">{snippet}</text>'
        )

    # Legend.
    legend_y = margin + rows * CELL + 16
    parts.append(f'<text class="subtitle" x="14" y="{legend_y}">legend:</text>')
    legend_x = 64
    for fam in sorted(families_used):
        col = family_color(fam)
        parts.append(
            f'<rect x="{legend_x}" y="{legend_y - 9}" width="11" height="11" fill="{col}" stroke="#111" stroke-width="0.4"/>'
        )
        parts.append(f'<text x="{legend_x + 14}" y="{legend_y}" class="legend">{fam}</text>')
        legend_x += len(fam) * 6 + 28

    parts.append(svg_close())
    return "\n".join(parts)


# ───────────────────────────────────────────────────────────────────────
# Section views (cross-sections)
# ───────────────────────────────────────────────────────────────────────

def render_section(m: dict, art_index: dict[str, dict], axis: str) -> str:
    """axis='x' = cut at central column (looking west, see YZ plane);
       axis='z' = cut at central row (looking south, see YX plane)."""
    rows, cols = m["rows"], m["cols"]
    if axis == "x":
        slice_idx = cols // 2
        depth = rows
        ax_label = f"cut at column {slice_idx}, looking west — Y vs Z"
        get_h = lambda i: m["heights"][i][slice_idx]
        cell_arts = [a for a in m["artifacts"] if a["col"] == slice_idx]
        get_pos = lambda a: a["row"]
    else:
        slice_idx = rows // 2
        depth = cols
        ax_label = f"cut at row {slice_idx}, looking south — Y vs X"
        get_h = lambda i: m["heights"][slice_idx][i]
        cell_arts = [a for a in m["artifacts"] if a["row"] == slice_idx]
        get_pos = lambda a: a["col"]

    margin = 50
    max_h = max(int(get_h(i)) for i in range(depth)) if depth else 1
    max_h = max(max_h, 4)
    width = margin * 2 + depth * CELL
    height = margin * 2 + max_h * CELL + 30

    parts = svg_open(width, height,
                     f"{m['title']} — section {axis.upper()}",
                     ax_label)

    base_y = margin + max_h * CELL  # bottom row of cells
    for i in range(depth):
        h = get_h(i)
        h_int = max(1, int(round(h)))
        x = margin + i * CELL
        # Draw stacked rectangles bottom-up.
        for level in range(h_int):
            y = base_y - (level + 1) * CELL
            col = height_color(level + 1)
            parts.append(
                f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                f'fill="{col}" stroke="#0d0d12" stroke-width="0.4"/>'
            )

    # Artifacts in this slice — silhouette at their position.
    for a in cell_arts:
        info = art_index.get(a["name"], {})
        family = info.get("family", "unknown")
        fp = info.get("footprint", (1.0, 1.0, 1.0))
        fh = max(0.4, min(fp[2], 4.0))
        # parse y_offset from raw token (artifact:rotation:y_offset:scale).
        y_off = 0.0
        try:
            parts_tok = a["raw"].split(":")
            if len(parts_tok) >= 3:
                y_off = float(parts_tok[2])
        except Exception:
            pass
        col = family_color(family)
        i = get_pos(a)
        cx = margin + i * CELL + CELL / 2
        floor_h = max(1, int(round(get_h(i))))
        floor_y = base_y - floor_h * CELL
        rect_h = fh * CELL * 0.85
        rect_y = floor_y - rect_h - y_off * CELL
        parts.append(
            f'<rect x="{cx - CELL*0.35:.1f}" y="{rect_y:.1f}" '
            f'width="{CELL*0.7:.1f}" height="{rect_h:.1f}" '
            f'fill="{col}" stroke="#fff" stroke-width="0.6" opacity="0.9" rx="1.5">'
            f'<title>{a["name"]}\nfamily: {family}\ny_offset: {y_off}</title></rect>'
        )

    # Spawn + teleport markers in slice.
    for marker, color, label in [(m["spawn"], "#4ade80", "spawn"), (m["teleport"], "#f87171", "tele")]:
        if not marker:
            continue
        mr, mc = marker
        in_slice = (axis == "x" and mc == slice_idx) or (axis == "z" and mr == slice_idx)
        if not in_slice:
            continue
        i = get_pos({"row": mr, "col": mc})
        cx = margin + i * CELL + CELL / 2
        floor_h = max(1, int(round(get_h(i))))
        cy = base_y - floor_h * CELL - 4
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="5" fill="{color}" stroke="#0d0d12" stroke-width="1"/>')
        parts.append(f'<text x="{cx + 8}" y="{cy + 3}" font-size="9" fill="{color}">{label}</text>')

    parts.append(svg_close())
    return "\n".join(parts)


# ───────────────────────────────────────────────────────────────────────
# Elevation: combine all rows into one facade silhouette
# ───────────────────────────────────────────────────────────────────────

def render_elevation(m: dict, art_index: dict[str, dict]) -> str:
    """Looking south at the whole map. Each column = max-height across all rows."""
    rows, cols = m["rows"], m["cols"]
    # Per-column max heights.
    col_max = [max(int(round(m["heights"][r][c])) for r in range(rows)) for c in range(cols)]
    overall_max = max(col_max + [4])
    margin = 50
    width = margin * 2 + cols * CELL
    height = margin * 2 + overall_max * CELL + 30
    parts = svg_open(width, height, f"{m['title']} — elevation",
                     "front-on facade — silhouette as seen from south")

    base_y = margin + overall_max * CELL
    # Stacked silhouette per column.
    for c in range(cols):
        h = col_max[c]
        x = margin + c * CELL
        for level in range(h):
            y = base_y - (level + 1) * CELL
            col = height_color(level + 1)
            parts.append(
                f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" '
                f'fill="{col}" stroke="#0d0d12" stroke-width="0.4"/>'
            )

    # Artifacts as pins on the columns they live in (one per col, take topmost).
    by_col: dict[int, dict] = {}
    for a in m["artifacts"]:
        cur = by_col.get(a["col"])
        if cur is None or a["row"] < cur["row"]:
            by_col[a["col"]] = a
    for c, a in by_col.items():
        info = art_index.get(a["name"], {})
        family = info.get("family", "unknown")
        fp = info.get("footprint", (1.0, 1.0, 1.0))
        fh = max(0.4, min(fp[2], 4.0))
        y_off = 0.0
        try:
            parts_tok = a["raw"].split(":")
            if len(parts_tok) >= 3:
                y_off = float(parts_tok[2])
        except Exception:
            pass
        col_color = family_color(family)
        cx = margin + c * CELL + CELL / 2
        col_h = col_max[c]
        col_top_y = base_y - col_h * CELL
        rect_h = fh * CELL * 0.85
        rect_y = col_top_y - rect_h - y_off * CELL
        parts.append(
            f'<rect x="{cx - CELL*0.32:.1f}" y="{rect_y:.1f}" '
            f'width="{CELL*0.64:.1f}" height="{rect_h:.1f}" '
            f'fill="{col_color}" stroke="#fff" stroke-width="0.6" opacity="0.9" rx="1.5">'
            f'<title>{a["name"]}\nfamily: {family}</title></rect>'
        )

    parts.append(svg_close())
    return "\n".join(parts)


# ───────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────

def render_one(map_name: str, art_index: dict[str, dict],
               out_root: Path) -> bool:
    m = parse_map(map_name)
    if m is None:
        print(f"  ! could not parse {map_name}")
        return False
    out_dir = out_root / map_name
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "plan.svg").write_text(render_plan(m, art_index), encoding="utf-8")
    (out_dir / "section_x.svg").write_text(render_section(m, art_index, "x"), encoding="utf-8")
    (out_dir / "section_z.svg").write_text(render_section(m, art_index, "z"), encoding="utf-8")
    (out_dir / "elevation.svg").write_text(render_elevation(m, art_index), encoding="utf-8")
    summary = {
        "name": map_name,
        "title": m["title"],
        "description": m["description"],
        "dimensions": {"rows": m["rows"], "cols": m["cols"]},
        "n_artifacts": len(m["artifacts"]),
        "spawn": m["spawn"],
        "teleport": m["teleport"],
        "artifacts": [
            {
                "name": a["name"],
                "row": a["row"],
                "col": a["col"],
                "family": art_index.get(a["name"], {}).get("family", "unknown"),
            }
            for a in m["artifacts"]
        ],
    }
    (out_dir / "plans.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"  ✓ {map_name}: {m['rows']}×{m['cols']}, {len(m['artifacts'])} artifacts")
    return True


def list_sequence_maps(seq_name: str) -> list[str]:
    p = SEQUENCES_DIR / f"{seq_name}.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return []
    seqs = d.get("sequences")
    if not isinstance(seqs, dict):
        seqs = {seq_name: d}
    sd = seqs.get(seq_name) or next(iter(seqs.values()), {})
    if not isinstance(sd, dict):
        return []
    maps = sd.get("maps", []) or sd.get("map_order", [])
    return [m if isinstance(m, str) else m.get("lookup_name", m.get("name", "")) for m in maps if m]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="single map name")
    ap.add_argument("--batch", nargs="+", help="one or more sequence names; render all their maps")
    ap.add_argument("--out-dir", type=Path, default=OUT_DIR_DEFAULT)
    args = ap.parse_args()

    if not args.map and not args.batch:
        print("specify --map=<name> or --batch <seq1> <seq2> ...")
        sys.exit(2)

    print("[plans] loading artifact registry...")
    art_index = load_artifact_index()
    print(f"[plans] indexed {len(art_index)} artifacts")

    targets: list[str] = []
    if args.map:
        targets.append(args.map)
    if args.batch:
        for seq in args.batch:
            ms = list_sequence_maps(seq)
            print(f"[plans] {seq}: {len(ms)} maps")
            targets.extend(ms)

    out_root = Path(args.out_dir)
    print(f"[plans] writing to {out_root}")
    ok = 0
    for map_name in targets:
        if render_one(map_name, art_index, out_root):
            ok += 1
    print(f"[plans] {ok}/{len(targets)} maps drawn")


if __name__ == "__main__":
    main()
