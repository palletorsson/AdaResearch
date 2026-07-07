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
import math
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


# ── wave ─────────────────────────────────────────────────────────
# Diagonal traveling sine wave. Bands of brightness sweep across
# (x + y) over time. We render an init frame (t = 0) with a single
# hue and value swept from sin((x + y) / WAVELEN).

_WAVE_HUE = 0.58
_WAVE_SAT = 0.55
_WAVE_VAL_MIN = 0.18
_WAVE_VAL_MAX = 1.0
_WAVE_LEN = 16.0  # cells per spatial period


def _wave_color(amp: float) -> tuple[int, int, int]:
    t = (amp + 1.0) * 0.5  # → [0, 1]
    v = _WAVE_VAL_MIN + (_WAVE_VAL_MAX - _WAVE_VAL_MIN) * t
    return hsv_to_rgb(_WAVE_HUE, _WAVE_SAT, v)


def render_wave_init() -> list[list[tuple[int, int, int]]]:
    rows = []
    for y in range(GRID):
        row = []
        for x in range(GRID):
            amp = math.sin(math.tau * (x + y) / _WAVE_LEN)
            row.append(_wave_color(amp))
        rows.append(row)
    return rows


# ── count ────────────────────────────────────────────────────────
# Each cell shows its row-major index mod STATES — first row 0..7,
# next row continues with width offset, etc. With GRID=64 and
# STATES=8, every row is the same identical 0..7 sweep. To make the
# enumeration legible, we use a SMALL block grid (16x16 logical cells
# upscaled to 64x64 pixels) and let index = y*16 + x, so successive
# rows visibly continue the count rather than restarting.

_COUNT_BLOCK = 4              # 4 px per logical cell → 16 cells wide
_COUNT_LOGICAL = GRID // _COUNT_BLOCK   # = 16


def _count_color(state: int) -> tuple[int, int, int]:
    return hsv_to_rgb(state / STATES, 0.75, 0.95)


def render_count_init() -> list[list[tuple[int, int, int]]]:
    # Pre-compute logical cell colors.
    logical = [[_count_color((ly * _COUNT_LOGICAL + lx) % STATES)
                for lx in range(_COUNT_LOGICAL)]
               for ly in range(_COUNT_LOGICAL)]
    rows = []
    for y in range(GRID):
        ly = y // _COUNT_BLOCK
        row = []
        for x in range(GRID):
            lx = x // _COUNT_BLOCK
            row.append(logical[ly][lx])
        rows.append(row)
    return rows


# ── sieve ────────────────────────────────────────────────────────
# Sieve of Eratosthenes laid into a 16x16 logical grid (so primes are
# visible as discrete dots). Index = ly * 16 + lx. Prime cells light
# up; composite cells stay dim.

_SIEVE_BLOCK = 4
_SIEVE_LOGICAL = GRID // _SIEVE_BLOCK   # = 16
_SIEVE_PRIME = hsv_to_rgb(0.62, 0.55, 0.85)
_SIEVE_FRESH = hsv_to_rgb(0.12, 0.85, 1.0)
_SIEVE_DEAD = (13, 13, 18)


def _is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n < 4:
        return True
    if n % 2 == 0:
        return False
    i = 3
    while i * i <= n:
        if n % i == 0:
            return False
        i += 2
    return True


def render_sieve_init() -> list[list[tuple[int, int, int]]]:
    # Highlight every prime; show the most recent in FRESH yellow so
    # the gallery thumbnail conveys "discovery in progress."
    n_logical = _SIEVE_LOGICAL * _SIEVE_LOGICAL
    primes = [i for i in range(n_logical) if _is_prime(i)]
    fresh = set(primes[-3:]) if len(primes) >= 3 else set(primes)
    logical = []
    for ly in range(_SIEVE_LOGICAL):
        row = []
        for lx in range(_SIEVE_LOGICAL):
            idx = ly * _SIEVE_LOGICAL + lx
            if idx in fresh:
                row.append(_SIEVE_FRESH)
            elif _is_prime(idx):
                row.append(_SIEVE_PRIME)
            else:
                row.append(_SIEVE_DEAD)
        logical.append(row)
    rows = []
    for y in range(GRID):
        ly = y // _SIEVE_BLOCK
        row = []
        for x in range(GRID):
            lx = x // _SIEVE_BLOCK
            row.append(logical[ly][lx])
        rows.append(row)
    return rows


# ── fibonacci ────────────────────────────────────────────────────
# fib(index) mod K laid into a 16x16 logical grid. Pisano period for
# K=8 is 12, so bands repeat every 12 indices — visible as a
# non-trivial but clearly periodic stripe pattern.

_FIB_BLOCK = 4
_FIB_LOGICAL = GRID // _FIB_BLOCK   # = 16
_FIB_K = STATES                     # = 8


def _fib_mod(n: int, k: int) -> int:
    if n == 0:
        return 0
    a, b = 0, 1
    for _ in range(n - 1):
        a, b = b, (a + b) % k
    return b


def _fib_color(state: int) -> tuple[int, int, int]:
    return hsv_to_rgb(state / STATES, 0.7, 0.92)


def render_fibonacci_init() -> list[list[tuple[int, int, int]]]:
    logical = [[_fib_color(_fib_mod(ly * _FIB_LOGICAL + lx, _FIB_K))
                for lx in range(_FIB_LOGICAL)]
               for ly in range(_FIB_LOGICAL)]
    rows = []
    for y in range(GRID):
        ly = y // _FIB_BLOCK
        row = []
        for x in range(GRID):
            lx = x // _FIB_BLOCK
            row.append(logical[ly][lx])
        rows.append(row)
    return rows


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
    {
        "id": "wave",
        "title": "Wave",
        "renderer": render_wave_init,
        "config": {
            "id": "wave",
            "cartridge": "wave",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.1,
            "init_pattern": "diagonal_sine",
            "step_rule": "phase_advance_per_step",
            "palette": {"hue": 0.58, "sat": 0.55, "val_min": 0.18, "val_max": 1.0},
            "wavelength_cells": _WAVE_LEN,
            "qfep": "F_order",
            "notes": (
                "A diagonal traveling wave swept across the array. Each "
                "cell's value is sin(2π·(i+j)/N + t), quantized to bands. "
                "Bright and dark fronts move uniformly across the index "
                "space — the array becomes a medium, the values flow, "
                "the cells stay put."
            ),
        },
    },
    {
        "id": "count",
        "title": "Count",
        "renderer": render_count_init,
        "config": {
            "id": "count",
            "cartridge": "count",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.25,
            "init_pattern": "row_major_index_mod",
            "step_rule": "uniform_increment_per_step",
            "palette": {"sat": 0.75, "val": 0.95},
            "logical_grid": _COUNT_LOGICAL,
            "qfep": "F_order",
            "notes": (
                "Each cell shows its own row-major index — first row 0,1,2,..., "
                "next row picks up where the first ended. The DNA of the "
                "array, its enumeration, laid bare. After playing with count, "
                "the player has felt what 'linear memory laid out in 2D' "
                "really means."
            ),
        },
    },
    {
        "id": "sieve",
        "title": "Sieve",
        "renderer": render_sieve_init,
        "config": {
            "id": "sieve",
            "cartridge": "sieve",
            "substrate": "grid2d",
            "states": 3,
            "interval_default": 0.2,
            "init_pattern": "primality_of_index",
            "step_rule": "scanning_reveal_pass",
            "palette": {
                "prime_hue": 0.62,
                "prime_sat": 0.55,
                "prime_val": 0.85,
                "fresh_hue": 0.12,
                "fresh_sat": 0.85,
                "fresh_val": 1.0,
            },
            "logical_grid": _SIEVE_LOGICAL,
            "qfep": "F_order",
            "notes": (
                "Sieve of Eratosthenes laid into the array — a cell lights "
                "if its index is prime, stays dark otherwise. Disco/wave/count "
                "put structure ONTO the array; sieve reads structure OUT of "
                "the index. Sparse, irregular, self-similar — the opposite "
                "of disco's rhythm."
            ),
        },
    },
    {
        "id": "fibonacci",
        "title": "Fibonacci",
        "renderer": render_fibonacci_init,
        "config": {
            "id": "fibonacci",
            "cartridge": "fibonacci",
            "substrate": "grid2d",
            "states": STATES,
            "interval_default": 0.2,
            "init_pattern": "fib_mod_k_of_index",
            "step_rule": "offset_drift_per_step",
            "palette": {"sat": 0.7, "val": 0.92},
            "K": _FIB_K,
            "pisano_period_k8": 12,
            "logical_grid": _FIB_LOGICAL,
            "qfep": "F_order",
            "notes": (
                "fib(index) mod K — Fibonacci numbers laid along the array, "
                "quantized. Because Fibonacci mod K is eventually periodic "
                "(Pisano period π(K) = 12 for K=8), bands repeat in a "
                "non-trivial cadence. Structure exists, but the period isn't "
                "obvious from the rule. A wink at number theory inside an "
                "array tutorial."
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
        "version": 2,
        "description": (
            "Array cartridge gallery — grid2d substrate cartridges for the "
            "array_tutorial sequence. Each entry IS a real Grid2DCartridge "
            "subclass at commons/substrates/grid2d/cartridges/. Configs "
            "shown here become parameters for grid2d_substrate placements "
            "in array maps. Same hardware (the array), many cartridges "
            "(the cadences and rules running on it). Seven entries — "
            "disco/slow (rhythm), random (entropy on the same lattice), "
            "wave (oscillation), count (index laid bare), sieve (primality "
            "of index), fibonacci (Pisano-period bands)."
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
