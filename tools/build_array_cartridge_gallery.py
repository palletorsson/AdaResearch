#!/usr/bin/env python3
"""
build_array_cartridge_gallery.py
=================================

Creates `public/array-cartridge-gallery/` populated with one entry per
grid2d cartridge in the array_tutorial sequence (disco, slow, random
to start; expandable). Each entry has:

    <id>.json    — config: name, parameters (states, interval defaults), notes
    <id>.png     — placeholder PNG drawn from the cartridge's init state
                   (real captures come later from Godot running
                   grid2d_substrate with each cartridge)

Plus a `manifest.json` aggregator and `evals.json` shell ready for
DNA-page curation.

Why hand-rolled PNG instead of PIL: this repo's Python tooling is
stdlib-only by convention. We build a 64x64 RGB image from scratch
using struct + zlib. Tiny but honest visualization of each cartridge's
initial state, sufficient for the gallery thumbnail until Godot has
captured a real shot.

Run:
    python tools/build_array_cartridge_gallery.py

Output:
    ada_encyclopedia/public/array-cartridge-gallery/
        manifest.json
        evals.json
        disco.json   disco.png
        slow.json    slow.png
        random.png   random.png
"""

from __future__ import annotations
import argparse
import colorsys
import json
import random
import struct
import zlib
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GALLERY_DIR = REPO.parent / "ada_encyclopedia" / "public" / "array-cartridge-gallery"

GRID = 64                  # PNG canvas (also the visual init grid)
STATES = 8


def hsv_to_rgb(h: float, s: float, v: float) -> tuple[int, int, int]:
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return int(r * 255), int(g * 255), int(b * 255)


def png_write(path: Path, pixels: list[list[tuple[int, int, int]]]) -> None:
    """Write an RGB PNG. pixels is a list of rows, each row a list of (r,g,b)."""
    h = len(pixels)
    w = len(pixels[0]) if h else 0
    raw = bytearray()
    for row in pixels:
        raw.append(0)  # filter byte = none
        for r, g, b in row:
            raw.extend((r, g, b))
    def chunk(tag: bytes, data: bytes) -> bytes:
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)  # 8-bit RGB
    idat = zlib.compress(bytes(raw), 9)
    iend = b""
    path.write_bytes(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", iend))


# ── Per-cartridge init renderers ──────────────────────────────────

def _disco_color(state: int) -> tuple[int, int, int]:
    return hsv_to_rgb(state / STATES, 0.85, 1.0)


def _slow_color(state: int) -> tuple[int, int, int]:
    return hsv_to_rgb(state / STATES, 0.40, 0.70)


def _random_color(state: int) -> tuple[int, int, int]:
    return hsv_to_rgb(state / STATES, 0.70, 0.95)


def render_disco_init() -> list[list[tuple[int, int, int]]]:
    return [[_disco_color((x + y) % STATES) for x in range(GRID)] for y in range(GRID)]


def render_slow_init() -> list[list[tuple[int, int, int]]]:
    return [[_slow_color((x + y) % STATES) for x in range(GRID)] for y in range(GRID)]


def render_random_init() -> list[list[tuple[int, int, int]]]:
    rng = random.Random(42)
    return [[_random_color(rng.randint(0, STATES - 1)) for x in range(GRID)] for y in range(GRID)]


# ── Per-cartridge config blocks ───────────────────────────────────

CARTRIDGES = [
    {
        "id": "disco",
        "title": "Disco",
        "renderer": render_disco_init,
        "config": {
            "id": "disco",
            "cartridge": "disco",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.08,
            "init_pattern": "diagonal_rainbow",
            "step_rule": "all_cells_advance_one_state",
            "palette": {"sat": 0.85, "val": 1.0},
            "qfep": "F_order",
            "notes": (
                "Pure rhythm. Every cell carries one of 8 states arranged as "
                "(x + y) mod 8; each step advances every cell together. The "
                "array's index space made visible as a sweeping rainbow."
            ),
        },
    },
    {
        "id": "slow",
        "title": "Slow",
        "renderer": render_slow_init,
        "config": {
            "id": "slow",
            "cartridge": "slow",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.6,
            "init_pattern": "diagonal_rainbow",
            "step_rule": "all_cells_advance_one_state",
            "palette": {"sat": 0.40, "val": 0.70},
            "qfep": "F_order",
            "notes": (
                "Same rule as disco. Different tempo and a desaturated palette. "
                "Demonstrates that cadence is parameter, not law — the array "
                "reads as different by feel, not by structure."
            ),
        },
    },
    {
        "id": "random",
        "title": "Random",
        "renderer": render_random_init,
        "config": {
            "id": "random",
            "cartridge": "random",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.2,
            "init_pattern": "uniform_random",
            "step_rule": "every_cell_rerolls_each_step",
            "palette": {"sat": 0.70, "val": 0.95},
            "qfep": "E_entropy",
            "notes": (
                "Same hardware, no memory. The array's structure persists "
                "but values are sampled fresh each step. F_order substrate, "
                "E_entropy cartridge — the substrate / cartridge factoring "
                "made unmistakable."
            ),
        },
    },
]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true",
                    help="Print plan; don't write files.")
    args = ap.parse_args()

    print(f"Gallery: {GALLERY_DIR}")
    print(f"Cartridges: {len(CARTRIDGES)}")
    for c in CARTRIDGES:
        print(f"  - {c['id']:8s} {c['title']:8s} qfep={c['config']['qfep']}")

    if args.dry:
        print("\n[dry run]")
        return

    GALLERY_DIR.mkdir(parents=True, exist_ok=True)

    entries = []
    for c in CARTRIDGES:
        cid = c["id"]
        # config json
        (GALLERY_DIR / f"{cid}.json").write_text(
            json.dumps(c["config"], indent=2) + "\n", encoding="utf-8")
        # placeholder PNG (init state)
        png_write(GALLERY_DIR / f"{cid}.png", c["renderer"]())
        # manifest entry
        entries.append({
            "id": cid,
            "notes": c["config"]["notes"],
            "title": c["title"],
            "image": f"/array-cartridge-gallery/{cid}.png",
            "config": f"/array-cartridge-gallery/{cid}.json",
            "qfep": c["config"]["qfep"],
            "substrate": c["config"]["substrate"],
            "step_rule": c["config"]["step_rule"],
        })

    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": (
            "Array cartridge gallery — grid2d substrate cartridges for the "
            "array_tutorial sequence. Each entry IS a real Grid2DCartridge "
            "subclass at commons/substrates/grid2d/cartridges/. Configs "
            "shown here become parameters for grid2d_substrate placements "
            "in array maps. Same hardware (the array), many cartridges "
            "(the cadences and rules running on it). Future entries: wave, "
            "count, sieve, fibonacci, sliding-window."
        ),
        "entries": entries,
    }
    (GALLERY_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    evals_path = GALLERY_DIR / "evals.json"
    if not evals_path.exists():
        evals_path.write_text(json.dumps({}, indent=2) + "\n", encoding="utf-8")

    print(f"\nWrote:")
    print(f"  {GALLERY_DIR}/manifest.json   ({len(entries)} entries)")
    for c in CARTRIDGES:
        print(f"  {GALLERY_DIR}/{c['id']}.json  +  {c['id']}.png")
    print(f"  {GALLERY_DIR}/evals.json")
    print()
    print("View at:")
    print(f"  http://localhost:3003/array-cartridge-gallery/manifest.json")
    print(f"  http://localhost:3003/array-cartridge-gallery/disco.png")
    print()
    print("Next:")
    print("  1) Add gallery slug to /dna page GALLERIES list")
    print("  2) Capture real screenshots via Godot when Array_Soane_Plaza loads")


if __name__ == "__main__":
    main()
