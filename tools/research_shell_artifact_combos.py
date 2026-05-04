#!/usr/bin/env python3
"""
research_shell_artifact_combos.py
==================================

Auto-research that combines map-grammar shells with artifact-layer
cartridges. The shell is the substrate; the artifact layer is the
cartridge. Each combination is one map_data.json + one gallery entry.

Inputs:
    SHELLS    — names of map-grammar-gallery entries (e.g. mg_soane_collection)
                whose structure layer becomes the substrate.
    LAYOUTS   — algorithmic rules that decide WHICH cells get artifacts.
    PALETTES  — sets of artifact lookup names that fill those cells.

Combinations:
    len(SHELLS) × len(LAYOUTS) × len(PALETTES) maps generated, one per
    (shell, layout, palette) triple. Each gets:

    commons/maps/shell_<shell>_<layout>_<palette>/map_data.json
    public/shell-cartridge-gallery/<id>.json     ← shell+cartridge config
    public/shell-cartridge-gallery/<id>.png      ← top-down preview

The gallery's manifest.json lists them all; /dna curates them; best-of
items can be promoted to canonical sequence maps (array_tutorial first).

This is the OUTER substrate the user described: a reusable map shell
running an artifact-layer cartridge. The inner substrate (grid2d_substrate
running disco/slow/random) is exactly the same pattern at a smaller
scale — cells instead of cubes, color cartridges instead of artifact ones.

Run:
    python tools/research_shell_artifact_combos.py
    python tools/research_shell_artifact_combos.py --dry
"""

from __future__ import annotations
import argparse
import colorsys
import json
import struct
import zlib
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC_PUBLIC = REPO.parent / "ada_encyclopedia" / "public"
SHELL_SOURCE = ENC_PUBLIC / "map-grammar-gallery"
GALLERY = ENC_PUBLIC / "shell-cartridge-gallery"
MAPS = REPO / "commons" / "maps"

# ── Substrate (shells) ───────────────────────────────────────
# Names match map-grammar-gallery entries. We read their map_data.json
# from commons/maps/<id>/ and reuse the structure layer.
SHELLS = [
    "mg_room_walled",          # 12x12 walled room — basic
    "mg_soane_collection",     # 16x22 plinth field — the shell that started this
    "mg_drunkard_plinths",     # 18x18 organic with plinths — dense
]

# ── Cartridges (artifact-layer layout rules) ─────────────────
# Each rule is a function that takes the structure grid and returns a
# list of (r, c) cells where artifacts should be placed.
def layout_filled_floor(structure: list[list[int]]) -> list[tuple[int, int]]:
    """Every walkable (h=1) cell gets an artifact."""
    return [(r, c) for r, row in enumerate(structure)
                   for c, h in enumerate(row) if h == 1]


def layout_diagonal_array(structure: list[list[int]]) -> list[tuple[int, int]]:
    """(r + c) % 4 == 0 — sparse diagonal grid."""
    return [(r, c) for r, row in enumerate(structure)
                   for c, h in enumerate(row) if h == 1 and (r + c) % 4 == 0]


def layout_perimeter(structure: list[list[int]]) -> list[tuple[int, int]]:
    """Cells one step inside the outer boundary."""
    rows = len(structure)
    cols = len(structure[0]) if rows else 0
    out = []
    for r in range(1, rows - 1):
        for c in range(1, cols - 1):
            if structure[r][c] != 1:
                continue
            on_edge = (r == 1 or r == rows - 2 or c == 1 or c == cols - 2)
            if on_edge:
                out.append((r, c))
    return out


def layout_atop_plinths(structure: list[list[int]]) -> list[tuple[int, int]]:
    """Place artifact on top of every h>=2 plinth (the columnar variant)."""
    return [(r, c) for r, row in enumerate(structure)
                   for c, h in enumerate(row) if h >= 2]


def layout_checker(structure: list[list[int]]) -> list[tuple[int, int]]:
    """Every other walkable cell."""
    return [(r, c) for r, row in enumerate(structure)
                   for c, h in enumerate(row) if h == 1 and (r + c) % 2 == 0]


LAYOUTS = {
    "filled":    layout_filled_floor,
    "diagonal":  layout_diagonal_array,
    "perimeter": layout_perimeter,
    "atop":      layout_atop_plinths,
    "checker":   layout_checker,
}

# ── Palettes (artifact lookup names) ─────────────────────────
# Each palette is a list of registered artifact lookup names. The layout
# function says WHERE; the palette says WHAT — cycled by index.
PALETTES = {
    "buren": [f"buren_col_{r:02d}_{c:02d}"
              for r in (1, 4, 7, 10) for c in (1, 4, 7, 10)],
    "array_substrates": ["array_disco_substrate", "array_slow_substrate",
                         "array_random_substrate"],
    "mixed": ["array_disco_substrate", "buren_col_01_04",
              "array_slow_substrate", "buren_col_04_04",
              "array_random_substrate", "buren_col_07_04"],
}

# ── PNG helpers (stdlib-only) ─────────────────────────────────
def _png(path: Path, pixels: list[list[tuple[int, int, int]]]) -> None:
    h = len(pixels); w = len(pixels[0]) if h else 0
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b in row: raw.extend((r, g, b))
    def chunk(tag: bytes, data: bytes) -> bytes:
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 9)
    path.write_bytes(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b""))


def render_preview(structure: list[list[int]],
                    artifact_cells: list[tuple[int, int]],
                    palette_idx_for: dict[tuple[int, int], int],
                    palette_size: int,
                    cell_px: int = 8) -> list[list[tuple[int, int, int]]]:
    rows = len(structure)
    cols = len(structure[0]) if rows else 0
    H = rows * cell_px
    W = cols * cell_px
    img = [[(20, 22, 28) for _ in range(W)] for _ in range(H)]
    # Draw structure
    for r in range(rows):
        for c in range(cols):
            h = structure[r][c]
            if h <= 0: continue
            shade = 60 + min(h, 5) * 28
            color = (shade, shade, shade + 4)
            for dy in range(cell_px - 1):
                for dx in range(cell_px - 1):
                    img[r * cell_px + dy][c * cell_px + dx] = color
    # Overlay artifact dots — rainbow by palette index
    for (r, c) in artifact_cells:
        idx = palette_idx_for[(r, c)]
        hue = (idx % palette_size) / max(1, palette_size)
        rr, gg, bb = colorsys.hsv_to_rgb(hue, 0.85, 1.0)
        col = (int(rr * 255), int(gg * 255), int(bb * 255))
        cy = r * cell_px + cell_px // 2
        cx = c * cell_px + cell_px // 2
        radius = max(2, cell_px // 3)
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx * dx + dy * dy <= radius * radius:
                    py, px = cy + dy, cx + dx
                    if 0 <= py < H and 0 <= px < W:
                        img[py][px] = col
    return img


# ── Combo execution ──────────────────────────────────────────
def load_shell(shell_id: str) -> dict:
    p = MAPS / shell_id / "map_data.json"
    if not p.exists():
        raise FileNotFoundError(f"Shell map not found: {p}")
    return json.loads(p.read_text(encoding="utf-8"))


def parse_height(v) -> int:
    if isinstance(v, int): return v
    try: return int(str(v).strip() or 0)
    except: return 0


def emit_combo(shell_id: str, layout_name: str, palette_name: str,
                dry: bool = False) -> dict:
    shell = load_shell(shell_id)
    structure_raw = shell["layers"]["structure"]
    rows = len(structure_raw)
    cols = len(structure_raw[0]) if rows else 0
    structure_h = [[parse_height(structure_raw[r][c]) for c in range(cols)]
                    for r in range(rows)]
    layout_fn = LAYOUTS[layout_name]
    palette = PALETTES[palette_name]

    cells = layout_fn(structure_h)
    palette_idx_for = {cell: i for i, cell in enumerate(cells)}

    # Build new map_data: keep shell's structure, replace utilities + interactables
    new_struct = [[str(v) for v in row] for row in structure_h]
    new_util = [[" " for _ in range(cols)] for _ in range(rows)]
    new_inter = [[" " for _ in range(cols)] for _ in range(rows)]

    # Spawn at top-left walkable cell, teleport at bottom-right walkable cell
    spawn = next(((r, c) for r in range(rows) for c in range(cols)
                  if structure_h[r][c] == 1), (0, 0))
    tele = next(((r, c) for r in range(rows - 1, -1, -1) for c in range(cols - 1, -1, -1)
                 if structure_h[r][c] == 1), (rows - 1, cols - 1))
    new_util[spawn[0]][spawn[1]] = "sp"
    new_util[tele[0]][tele[1]] = "t"

    # Place artifacts (skip spawn/tele cells)
    placed = []
    for i, (r, c) in enumerate(cells):
        if (r, c) in (spawn, tele): continue
        lookup = palette[i % len(palette)]
        new_inter[r][c] = f"{lookup}:0:0"
        placed.append((r, c, lookup))

    combo_id = f"shell_{shell_id.replace('mg_','')}_{layout_name}_{palette_name}"
    map_name = combo_id

    map_data = {
        "map_info": {
            "name": map_name, "lookup_name": map_name,
            "description": (
                f"Shell-cartridge combo: shell={shell_id}, "
                f"layout={layout_name}, palette={palette_name}. "
                f"{len(placed)} artifacts on top of the shell structure. "
                f"Auto-generated for shell-cartridge-gallery curation."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": cols, "depth": rows,
                            "max_height": max((max(row) for row in structure_h), default=1)},
            "metadata": {
                "source": "research_shell_artifact_combos.py",
                "shell": shell_id,
                "layout": layout_name,
                "palette": palette_name,
                "n_placed": len(placed),
            },
        },
        "layers": {
            "structure":     new_struct,
            "utilities":     new_util,
            "interactables": new_inter,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.07, 0.08, 0.12]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "hidden_except_corners",
        },
        "utility_definitions": {"sp": {"type": "spawn"}, "t": {"type": "teleporter"}},
    }

    config = {
        "id": combo_id,
        "shell": shell_id,
        "layout": layout_name,
        "palette": palette_name,
        "n_placed": len(placed),
        "spawn": list(spawn),
        "teleport": list(tele),
        "qfep": "F_order",
        "notes": (
            f"Shell={shell_id} ({rows}x{cols}). Layout '{layout_name}' "
            f"selected {len(cells)} cells; palette '{palette_name}' filled "
            f"them with {len(placed)} artifacts. The shell is the reusable "
            f"substrate; the (layout, palette) pair is the cartridge."
        ),
    }

    preview = render_preview(structure_h, [(r, c) for r, c, _ in placed],
                              palette_idx_for, len(palette))

    if dry:
        return {"id": combo_id, "placed": len(placed), "rows": rows, "cols": cols}

    map_dir = MAPS / map_name
    map_dir.mkdir(parents=True, exist_ok=True)
    (map_dir / "map_data.json").write_text(
        json.dumps(map_data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")

    GALLERY.mkdir(parents=True, exist_ok=True)
    (GALLERY / f"{combo_id}.json").write_text(
        json.dumps(config, indent=2) + "\n", encoding="utf-8")
    _png(GALLERY / f"{combo_id}.png", preview)

    return {
        "id": combo_id,
        "title": combo_id.replace("_", " "),
        "image": f"/shell-cartridge-gallery/{combo_id}.png",
        "config": f"/shell-cartridge-gallery/{combo_id}.json",
        "shell": shell_id,
        "layout": layout_name,
        "palette": palette_name,
        "n_placed": len(placed),
        "map_route": f"/map-3d/{map_name}",
        "notes": config["notes"],
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true",
                    help="Print plan; don't write maps or PNGs.")
    args = ap.parse_args()

    print(f"Shells:    {len(SHELLS)}    {SHELLS}")
    print(f"Layouts:   {len(LAYOUTS)}   {list(LAYOUTS.keys())}")
    print(f"Palettes:  {len(PALETTES)}  {list(PALETTES.keys())}")
    total = len(SHELLS) * len(LAYOUTS) * len(PALETTES)
    print(f"Combos:    {total}")
    print()

    if args.dry:
        for s in SHELLS:
            for L in LAYOUTS:
                for P in PALETTES:
                    info = emit_combo(s, L, P, dry=True)
                    print(f"  {info['id']:60s} placed={info['placed']}")
        return

    GALLERY.mkdir(parents=True, exist_ok=True)
    entries = []
    for s in SHELLS:
        for L in LAYOUTS:
            for P in PALETTES:
                try:
                    e = emit_combo(s, L, P)
                    entries.append(e)
                    print(f"  OK{e['id']:60s} placed={e['n_placed']}")
                except Exception as err:
                    print(f"  --shell={s} layout={L} palette={P} — {err}")

    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": (
            "Shell + cartridge auto-research. The shell is a map-grammar "
            "structure (mg_*); the cartridge is an artifact-layout rule + "
            "palette. Same shell, many cartridges = same substrate, many "
            "tracks. Curate stars≥4 entries here; promote winners to "
            "array_tutorial / color sequences via the bake pipeline."
        ),
        "entries": entries,
    }
    (GALLERY / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    evals_path = GALLERY / "evals.json"
    if not evals_path.exists():
        evals_path.write_text("{}\n", encoding="utf-8")

    print()
    print(f"Wrote {len(entries)} combos -> {GALLERY}")
    print(f"  manifest.json + {len(entries)} (.json + .png) pairs")
    print(f"  + {len(entries)} real maps in commons/maps/")
    print()
    print("View at:")
    print("  http://localhost:3003/dna  (after registering 'shell-cartridge-gallery')")
    print(f"  http://localhost:3003/shell-cartridge-gallery/manifest.json")
    if entries:
        print(f"  http://localhost:3003{entries[0]['map_route']}")


if __name__ == "__main__":
    main()
