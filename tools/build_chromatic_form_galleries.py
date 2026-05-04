#!/usr/bin/env python3
"""
build_chromatic_form_galleries.py
==================================

Auto-research output for res://algorithms/color/gradient_interpolator/ +
res://algorithms/color/color_mixing/.

The two algorithms together give us:
  - per-step color interpolation in RGB or HSV (gradient_interpolator)
  - subtractive (CMY) and additive (RGB) overlap palettes (color_mixing)

This builder pipes those palette generators into THREE non-cubic forms
inspired by modernist contemporary art / architecture / design:

  chromatic-fins-gallery       — Cruz-Diez wall: row of vertical fins,
                                 one color per fin, slight Z stagger.
  gradient-corridor-gallery    — Walk-through corridor; floor + 4 walls
                                 + ceiling stripes, gradient pull from
                                 entry to exit (yellow tunnel etc.).
  chromatic-panel-field-gallery — Suspended translucent panels around a
                                  wood floor (Cruz-Diez/Houseago hybrid).

Each form is rendered by commons/testing/render_chromatic_form.gd; this
script generates the JSON configs (computing the gradient strip) and
calls Godot once per entry. Output PNGs live alongside JSONs in the
gallery folder, and each entry is also appended to the master
/primitive-stack-gallery so the same searchable surface carries them.

Run:
    python tools/build_chromatic_form_galleries.py
    python tools/build_chromatic_form_galleries.py --dry
    python tools/build_chromatic_form_galleries.py --gallery chromatic-fins-gallery
"""

from __future__ import annotations
import argparse
import colorsys
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
PS_GALLERY = "primitive-stack-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"
RENDER_GD = "res://commons/testing/render_chromatic_form.gd"


# ── Palette generators (mirroring gradient_interpolator.gd) ──────

def _hex_to_rgb(h: str) -> tuple[float, float, float]:
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)


def _rgb_to_hex(r: float, g: float, b: float) -> str:
    return "#%02x%02x%02x" % (
        max(0, min(255, int(r * 255))),
        max(0, min(255, int(g * 255))),
        max(0, min(255, int(b * 255))),
    )


def lerp_rgb(a: str, b: str, n: int) -> list[str]:
    """Straight RGB interpolation — matches Color.lerp() in Godot."""
    ar, ag, ab = _hex_to_rgb(a)
    br, bg, bb = _hex_to_rgb(b)
    out = []
    for i in range(n):
        t = i / max(n - 1, 1)
        out.append(_rgb_to_hex(
            ar + (br - ar) * t,
            ag + (bg - ag) * t,
            ab + (bb - ab) * t,
        ))
    return out


def lerp_hsv(a: str, b: str, n: int) -> list[str]:
    """HSV interpolation — matches gradient_interpolator._lerp_hsv,
    walks the shorter arc around the hue wheel."""
    ar, ag, ab = _hex_to_rgb(a)
    br, bg, bb = _hex_to_rgb(b)
    ah, as_, av = colorsys.rgb_to_hsv(ar, ag, ab)
    bh, bs, bv = colorsys.rgb_to_hsv(br, bg, bb)
    dh = bh - ah
    if dh > 0.5: dh -= 1.0
    elif dh < -0.5: dh += 1.0
    out = []
    for i in range(n):
        t = i / max(n - 1, 1)
        h = (ah + dh * t) % 1.0
        s = as_ + (bs - as_) * t
        v = av + (bv - av) * t
        r, g, bl = colorsys.hsv_to_rgb(h, s, v)
        out.append(_rgb_to_hex(r, g, bl))
    return out


def cmy_palette() -> list[str]:
    """Subtractive CMY trio with their pairwise mixes (paint logic)."""
    # C, M, Y, C+M=Blue, M+Y=Red, Y+C=Green, all=Black, white=substrate
    return ["#00bfbf", "#bf00bf", "#bfbf00", "#0000a0", "#a00000", "#00a000", "#202020", "#f8f8f8"]


def rgb_additive_palette() -> list[str]:
    """Additive RGB trio + pairwise mixes (light logic)."""
    return ["#ff2020", "#20ff20", "#2030ff", "#ffff20", "#ff20ff", "#20ffff", "#ffffff", "#101010"]


# ── Form catalogs ────────────────────────────────────────────────

def fin_entries() -> list[dict]:
    """12 fin-walls, each playing a different gradient logic."""
    n = 16
    out = [
        # 4 from gradient_interpolator: same endpoints, RGB vs HSV
        {"id": "fins_red_cyan_rgb",  "form": "fin_wall", "n": n,
         "colors": lerp_rgb("#ff0000", "#00ffff", n),
         "notes": "Red→cyan, RGB lerp. Mid passes through muddy gray (the straight line in the cube)."},
        {"id": "fins_red_cyan_hsv",  "form": "fin_wall", "n": n,
         "colors": lerp_hsv("#ff0000", "#00ffff", n),
         "notes": "Red→cyan, HSV lerp. Same endpoints; the wheel arc carries us through orange/yellow/green."},
        {"id": "fins_yellow_violet_hsv", "form": "fin_wall", "n": n,
         "colors": lerp_hsv("#f0d020", "#6a30a0", n),
         "notes": "Yellow→violet, HSV. Itten's strongest value contrast traversed via the warm side."},
        {"id": "fins_blue_orange_hsv",   "form": "fin_wall", "n": n,
         "colors": lerp_hsv("#1844a0", "#e87018", n),
         "notes": "Blue→orange complementary, HSV — the cool/warm temperature axis."},
        # Modernist canon palettes pinned across n fins
        {"id": "fins_mondrian",   "form": "fin_wall", "n": 14,
         "colors": ["#cc1f1f", "#0a0a0a", "#f4f2ec", "#1f4ecc", "#0a0a0a", "#f4f2ec", "#f0c020",
                    "#0a0a0a", "#f4f2ec", "#1f4ecc", "#cc1f1f", "#0a0a0a", "#f0c020", "#f4f2ec"],
         "notes": "De Stijl chord turned into a Cruz-Diez wall — primary triad + grid bars + white."},
        {"id": "fins_klein_value", "form": "fin_wall", "n": 12,
         "colors": lerp_hsv("#0a1860", "#80b0e0", 12),
         "notes": "International Klein Blue, value scale. Single hue traversed via brightness."},
        {"id": "fins_rothko", "form": "fin_wall", "n": 12,
         "colors": lerp_rgb("#3a0808", "#e08840", 12),
         "notes": "Rothko atmospheric warm field — burgundy through ember to ochre, RGB straight."},
        {"id": "fins_bauhaus_triad", "form": "fin_wall", "n": 12,
         "colors": ["#cc1f1f", "#f0c020", "#1f4ecc"] * 4,
         "notes": "Bauhaus primary triad repeated — Kandinsky's questionnaire as a wall."},
        # Color-mixing seeded
        {"id": "fins_cmy_subtractive", "form": "fin_wall", "n": 8,
         "colors": cmy_palette(),
         "notes": "Subtractive (CMY) palette: cyan/magenta/yellow + their mixes. Paint logic across a wall."},
        {"id": "fins_rgb_additive", "form": "fin_wall", "n": 8,
         "colors": rgb_additive_palette(),
         "notes": "Additive (RGB) palette: light primaries + their mixes."},
        # Riley Op-art binary on fins
        {"id": "fins_riley_alternation", "form": "fin_wall", "n": 16,
         "colors": ["#0a0a0a", "#f4f2ec"] * 8,
         "notes": "Bridget Riley alternation — fin parallax compounds Op-art flicker."},
        # Cruz-Diez chromatic saturation full HSV
        {"id": "fins_cruz_diez_full_hsv", "form": "fin_wall", "n": 24,
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 24.0, 0.85, 0.95)) for i in range(24)],
         "notes": "Full chromatic circle, 24 fins. The Cruz-Diez 'saturated' room."},
    ]
    for e in out:
        e["params"] = {
            "fin_width": 0.10,
            "fin_height": 1.6,
            "fin_thickness": 0.022,
            "gap": 0.055,
            "transparent": True,
            "alpha": 0.78,
            "stagger_z": 0.10,
        }
    return out


def corridor_entries() -> list[dict]:
    """8 corridors — gradient interiors."""
    n = 14
    out = [
        {"id": "corridor_yellow_immersive", "form": "gradient_corridor", "n": n,
         "colors": lerp_hsv("#f8e060", "#a86010", n),
         "notes": "Yellow corridor (image ref 2): warm yellow at entry deepening to ochre."},
        {"id": "corridor_yellow_to_blue_hsv", "form": "gradient_corridor", "n": n,
         "colors": lerp_hsv("#f0d020", "#1844a0", n),
         "notes": "Yellow→blue HSV walk (image ref 4). Tunnel passes through green and cyan."},
        {"id": "corridor_yellow_to_violet_hsv", "form": "gradient_corridor", "n": n,
         "colors": lerp_hsv("#f0d030", "#6a30a0", n),
         "notes": "Yellow→violet HSV. Strongest value contrast; passes through ember + magenta."},
        {"id": "corridor_klein_blue_dive", "form": "gradient_corridor", "n": 12,
         "colors": lerp_rgb("#80b0e0", "#0a1860", 12),
         "notes": "Klein-blue dive: pale to ultramarine, value-only journey."},
        {"id": "corridor_warm_dusk_rgb", "form": "gradient_corridor", "n": n,
         "colors": lerp_rgb("#f8d8b8", "#3a1808", n),
         "notes": "Warm dusk RGB lerp — sun-warmed walls fading to night."},
        {"id": "corridor_rothko_chromatic", "form": "gradient_corridor", "n": 10,
         "colors": ["#3a0808", "#5a0c08", "#882010", "#a83018", "#c84818",
                    "#e08840", "#a86018", "#7a3818", "#5a1810", "#3a0808"],
         "notes": "Rothko chromatic field stretched along Z — warmth blooms then recedes."},
        {"id": "corridor_riley_alternation", "form": "gradient_corridor", "n": 16,
         "colors": ["#0a0a0a", "#f4f2ec"] * 8,
         "notes": "Riley alternation along the corridor — black/white pulse with depth."},
        {"id": "corridor_bauhaus_walk", "form": "gradient_corridor", "n": 12,
         "colors": ["#cc1f1f", "#f0c020", "#1f4ecc"] * 4,
         "notes": "Bauhaus triad walked end-to-end — primary chord as architecture."},
    ]
    for e in out:
        e["params"] = {
            "ring_depth": 0.45,
            "ring_width": 1.7,
            "ring_height": 1.9,
            "wall_thickness": 0.05,
        }
    return out


def panel_entries() -> list[dict]:
    """8 suspended panel fields."""
    n = 12
    out = [
        {"id": "panels_holographic_full_hsv", "form": "chromatic_panel_field", "n": n,
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / n, 0.85, 0.95)) for i in range(n)],
         "notes": "Holographic gallery (image ref 3): full HSV chromatic field on translucent panels."},
        {"id": "panels_red_cyan_complement", "form": "chromatic_panel_field", "n": n,
         "colors": lerp_hsv("#ff2848", "#28e8d8", n),
         "notes": "Red↔cyan complementary HSV walk on hanging glass."},
        {"id": "panels_yellow_violet_split", "form": "chromatic_panel_field", "n": n,
         "colors": lerp_hsv("#f0d020", "#6a30a0", n),
         "notes": "Yellow/violet panels — value-extreme complement, hue-arc journey."},
        {"id": "panels_klein_value", "form": "chromatic_panel_field", "n": 10,
         "colors": lerp_rgb("#0a1860", "#80b0e0", 10),
         "notes": "Klein-blue value field — ten translucent panels of the same hue at different brightness."},
        {"id": "panels_rgb_additive_overlap", "form": "chromatic_panel_field", "n": 8,
         "colors": rgb_additive_palette(),
         "notes": "Additive primaries + mixes on translucent panels — overlapping reads as light."},
        {"id": "panels_cmy_subtractive_overlap", "form": "chromatic_panel_field", "n": 8,
         "colors": cmy_palette(),
         "notes": "Subtractive CMY + mixes — paint logic in suspension."},
        {"id": "panels_rothko_field", "form": "chromatic_panel_field", "n": 9,
         "colors": ["#3a0808", "#5a0c08", "#882010", "#a83018", "#c84818",
                    "#e08840", "#a86018", "#7a3818", "#5a1810"],
         "notes": "Rothko atmospheric field as nine hanging color zones."},
        {"id": "panels_bauhaus_chord", "form": "chromatic_panel_field", "n": 9,
         "colors": ["#cc1f1f", "#f0c020", "#1f4ecc"] * 3,
         "notes": "Bauhaus primary triad triple-cycled on hanging panels."},
    ]
    for i, e in enumerate(out):
        e["params"] = {
            "panel_width": 0.6,
            "panel_height": 1.6,
            "panel_thickness": 0.02,
            "spread": 2.4,
            "alpha": 0.55,
            "seed": 42 + i * 7,
        }
    return out


def panel_grid_3x3_entries() -> list[dict]:
    """3×3 plan grid of orthogonal translucent panels (rotated 0° / 90°).
    Each entry combines a palette generator with a rotation mode, so the
    9 cells of the grid play different overlap behaviors.
    """
    # Build a 9-step gradient for each chromatic palette so each cell of
    # the 3×3 plan grid takes one slot.
    out = [
        {"id": "grid_3x3_hsv_full_checker",
         "form": "panel_grid_3x3",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 9.0, 0.85, 0.95)) for i in range(9)],
         "notes": "Full HSV chromatic circle on a 9-cell grid; checker rotation alternates panel orientation (NS/EW), so adjacent cells cross orthogonally and overlap-mix.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_hsv_full_rows",
         "form": "panel_grid_3x3",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 9.0, 0.85, 0.95)) for i in range(9)],
         "notes": "Same hue circle, but rotation alternates per row — top/bottom rows run E-W, middle row runs N-S. Walks pass through three color tunnels.",
         "params": {"rotation_mode": "rows"}},
        {"id": "grid_3x3_hsv_spiral",
         "form": "panel_grid_3x3",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 9.0, 0.85, 0.95)) for i in range(9)],
         "notes": "Per-row 90° rotation step (0°, 90°, 180°) — the grid spirals through orientations, building a Sol LeWitt-style combinatoric variant.",
         "params": {"rotation_mode": "spiral"}},
        {"id": "grid_3x3_red_cyan_hsv",
         "form": "panel_grid_3x3",
         "colors": lerp_hsv("#ff2030", "#20e8e8", 9),
         "notes": "Red→cyan HSV interpolation across 9 cells. Checker rotation; green/yellow midpoints overlap with red/cyan endpoints.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_yellow_violet_hsv",
         "form": "panel_grid_3x3",
         "colors": lerp_hsv("#f0d020", "#6a30a0", 9),
         "notes": "Yellow→violet, strongest value contrast. Each cell takes one step, panels cross at right angles for perceptual layering.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_cmy_subtractive",
         "form": "panel_grid_3x3",
         "colors": cmy_palette() + ["#888888"],   # pad to 9
         "notes": "Subtractive CMY trio + their pairwise mixes + neutral. Where CMY panels overlap, mixed hues are visible against the gray cell.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_rgb_additive",
         "form": "panel_grid_3x3",
         "colors": rgb_additive_palette() + ["#404040"],
         "notes": "Additive RGB primaries + mixes. Light-logic: panel overlap brightens toward white at the cross-cells.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_mondrian",
         "form": "panel_grid_3x3",
         "colors": ["#cc1f1f", "#f4f2ec", "#1f4ecc",
                    "#0a0a0a", "#f0c020", "#0a0a0a",
                    "#1f4ecc", "#f4f2ec", "#cc1f1f"],
         "notes": "Mondrian primary triad + black/white grid as a 3×3 plan. The De Stijl chord made walkable.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_klein_value",
         "form": "panel_grid_3x3",
         "colors": lerp_rgb("#0a1860", "#80b0e0", 9),
         "notes": "Klein-blue value scale across nine cells. One hue, nine brightnesses, two orientations — Yves Klein meets Sol LeWitt.",
         "params": {"rotation_mode": "checker"}},
        {"id": "grid_3x3_bauhaus_triad",
         "form": "panel_grid_3x3",
         "colors": ["#cc1f1f", "#f0c020", "#1f4ecc"] * 3,
         "notes": "Bauhaus triad triple-cycled. Repetition + orthogonal rotation makes the same chord read differently per cell.",
         "params": {"rotation_mode": "spiral"}},
    ]
    # Default common geometry params on each entry.
    for e in out:
        p = e.setdefault("params", {})
        p.setdefault("spacing", 0.55)
        p.setdefault("panel_w", 0.50)
        p.setdefault("panel_h", 1.60)
        p.setdefault("panel_t", 0.022)
        p.setdefault("alpha", 0.62)
    return out


def truchet_entries() -> list[dict]:
    """Smith-Truchet tile fields: random rotation per cell, 2-color motif.
    Curves emerge from a square grid — the canonical "rule generates form"
    procedural pattern."""
    out = [
        {"id": "truchet_black_white",
         "form": "truchet_grid",
         "colors": ["#0a0a0a", "#f4f2ec"],
         "notes": "Classic Smith-Truchet: black-on-white, 16×16 random rotations. Curves flow through the square grid.",
         "params": {"grid_n": 16, "tile": 0.18, "seed": 1}},
        {"id": "truchet_klein_blue",
         "form": "truchet_grid",
         "colors": ["#0a1860", "#cce8f4"],
         "notes": "Klein-blue tiles on pale ground. Single-hue Truchet — value contrast carries the curves.",
         "params": {"grid_n": 16, "tile": 0.18, "seed": 4}},
        {"id": "truchet_red_terracotta",
         "form": "truchet_grid",
         "colors": ["#a02020", "#e8c890"],
         "notes": "Pompeii-floor palette: oxide red on bone. Roman mosaic colors in a Smith-Truchet grid.",
         "params": {"grid_n": 18, "tile": 0.16, "seed": 11}},
        {"id": "truchet_mondrian_red_blue",
         "form": "truchet_grid",
         "colors": ["#cc1f1f", "#1f4ecc"],
         "notes": "Mondrian primaries — Truchet curves where De Stijl right angles would normally rule.",
         "params": {"grid_n": 14, "tile": 0.20, "seed": 3}},
        {"id": "truchet_rothko_warm",
         "form": "truchet_grid",
         "colors": ["#3a0808", "#e08840"],
         "notes": "Rothko warm-field palette in Truchet. The atmospheric chord made graphic.",
         "params": {"grid_n": 16, "tile": 0.18, "seed": 7}},
        {"id": "truchet_dense_30",
         "form": "truchet_grid",
         "colors": ["#0a0a0a", "#f4f2ec"],
         "notes": "30×30 dense field — at this resolution Truchet reads as continuous flow, not tile.",
         "params": {"grid_n": 30, "tile": 0.10, "seed": 2}},
    ]
    return out


def wolfram_entries() -> list[dict]:
    """Wolfram elementary cellular automata. Single rule number, single
    seed cell, N steps of evolution → 2D pattern wall. Each entry picks a
    well-known rule and a palette."""
    n_grad = 16
    out = [
        {"id": "wolfram_rule_30_warm",
         "form": "wolfram_ca_wall",
         "colors": lerp_hsv("#f0c020", "#cc1f1f", n_grad),
         "notes": "Rule 30 — chaotic; used by Wolfram for his random-number generator. Yellow→red row gradient.",
         "params": {"rule": 30, "width": 51, "steps": 32, "tile": 0.06}},
        {"id": "wolfram_rule_90_klein",
         "form": "wolfram_ca_wall",
         "colors": lerp_rgb("#0a1860", "#80b0e0", n_grad),
         "notes": "Rule 90 — Sierpiński triangle. Klein-blue value gradient down the wall.",
         "params": {"rule": 90, "width": 51, "steps": 32, "tile": 0.06}},
        {"id": "wolfram_rule_110_full_hsv",
         "form": "wolfram_ca_wall",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / n_grad, 0.85, 0.95)) for i in range(n_grad)],
         "notes": "Rule 110 — Turing-complete; the structure-on-edge-of-chaos. Full HSV down the rows.",
         "params": {"rule": 110, "width": 51, "steps": 32, "tile": 0.06}},
        {"id": "wolfram_rule_184_traffic",
         "form": "wolfram_ca_wall",
         "colors": ["#1a1a1a", "#f0c020"],
         "notes": "Rule 184 — traffic-flow CA, a classic minimal-pair model. Black/yellow.",
         "params": {"rule": 184, "width": 51, "steps": 32, "tile": 0.06}},
        {"id": "wolfram_rule_150_xor",
         "form": "wolfram_ca_wall",
         "colors": lerp_hsv("#cc1f1f", "#1f4ecc", n_grad),
         "notes": "Rule 150 — XOR of three neighbors; nested fractal. Red→blue row gradient.",
         "params": {"rule": 150, "width": 51, "steps": 32, "tile": 0.06}},
        {"id": "wolfram_rule_22_nested",
         "form": "wolfram_ca_wall",
         "colors": lerp_hsv("#1a8848", "#f4f2ec", n_grad),
         "notes": "Rule 22 — nested triangular structure; Wolfram class-2-going-class-3.",
         "params": {"rule": 22, "width": 51, "steps": 32, "tile": 0.06}},
    ]
    return out


def voronoi_entries() -> list[dict]:
    """Voronoi tessellations: K seeds, nearest-color rasterization on a
    grid. Mondrian without right angles."""
    out = [
        {"id": "voronoi_8_full_hsv",
         "form": "voronoi_field",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 8.0, 0.85, 0.95)) for i in range(8)],
         "notes": "8 seeds, full chromatic palette. Cellular partition reads as rough Mondrian on circles.",
         "params": {"grid_n": 32, "tile": 0.10, "seeds": 8, "seed_rng": 1}},
        {"id": "voronoi_5_bauhaus",
         "form": "voronoi_field",
         "colors": ["#cc1f1f", "#f0c020", "#1f4ecc", "#0a0a0a", "#f4f2ec"],
         "notes": "5 seeds, Bauhaus chord. Voronoi turns the primary triad into irregular continents.",
         "params": {"grid_n": 28, "tile": 0.10, "seeds": 5, "seed_rng": 3}},
        {"id": "voronoi_12_rainbow",
         "form": "voronoi_field",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 12.0, 0.85, 0.95)) for i in range(12)],
         "notes": "12 seeds, full HSV. More seeds → smaller cells → finer Mondrian-of-circles.",
         "params": {"grid_n": 36, "tile": 0.09, "seeds": 12, "seed_rng": 5}},
        {"id": "voronoi_4_mondrian",
         "form": "voronoi_field",
         "colors": ["#cc1f1f", "#1f4ecc", "#f0c020", "#f4f2ec"],
         "notes": "4 seeds, De Stijl palette. Smallest possible canon — four large irregular cells.",
         "params": {"grid_n": 24, "tile": 0.12, "seeds": 4, "seed_rng": 9}},
        {"id": "voronoi_10_rothko",
         "form": "voronoi_field",
         "colors": ["#3a0808", "#5a0c08", "#882010", "#a83018", "#c84818",
                    "#e08840", "#a86018", "#7a3818", "#5a1810", "#3a0808"],
         "notes": "10 seeds, Rothko atmospheric warm field. Cells blur into chromatic regions.",
         "params": {"grid_n": 32, "tile": 0.10, "seeds": 10, "seed_rng": 13}},
        {"id": "voronoi_20_klein_value",
         "form": "voronoi_field",
         "colors": lerp_rgb("#0a1860", "#80b0e0", 8),
         "notes": "20 seeds, Klein-blue value strip — close-packed cells, single-hue tonal map.",
         "params": {"grid_n": 36, "tile": 0.09, "seeds": 20, "seed_rng": 17}},
    ]
    return out


def radiolaria_entries() -> list[dict]:
    """Haeckel-style biological specimens via CSG. Six types from
    algorithms/computationalbiology/radiolaria, each rendered with a
    curated palette."""
    out = [
        {"id": "radio_basic_cream",   "form": "radiolaria_specimen",
         "colors": ["#e8d8b8", "#a83820"],
         "notes": "Basic radiolarian — cream sphere studded with random bumps; unions only.",
         "params": {"type": "basic", "seed": 1}},
        {"id": "radio_basic_pollen_blue",  "form": "radiolaria_specimen",
         "colors": ["#cce0e8", "#1f4ecc"],
         "notes": "Basic form, cool-water palette. Pale blue substrate, ultramarine accents.",
         "params": {"type": "basic", "seed": 7}},
        {"id": "radio_spiky_icosa_red",   "form": "radiolaria_specimen",
         "colors": ["#f0e0c0", "#cc1f1f"],
         "notes": "Spiky radiolarian — 12 icosahedral spikes (perfect 5-fold symmetry). Cream base, red spikes.",
         "params": {"type": "spiky", "seed": 11, "max_spike_length": 1.1}},
        {"id": "radio_spiky_icosa_yellow", "form": "radiolaria_specimen",
         "colors": ["#e8e0c0", "#f0c020"],
         "notes": "Spiky form with golden spikes — Haeckel's chromolithograph palette.",
         "params": {"type": "spiky", "seed": 17, "max_spike_length": 0.95}},
        {"id": "radio_polyhedral_cut",    "form": "radiolaria_specimen",
         "colors": ["#d8d8d8", "#3aa060"],
         "notes": "Polyhedral specimen — sphere carved by box subtractions at icosahedral vertices, plus ornament spheres.",
         "params": {"type": "polyhedral", "seed": 3}},
        {"id": "radio_polyhedral_warm",   "form": "radiolaria_specimen",
         "colors": ["#e8c890", "#a86028"],
         "notes": "Polyhedral with warm wood/brass palette — terra-cotta substrate.",
         "params": {"type": "polyhedral", "seed": 23}},
        {"id": "radio_lattice_3axis",     "form": "radiolaria_specimen",
         "colors": ["#f4f2ec", "#1f4ecc"],
         "notes": "Lattice sphere — 3 perpendicular ring axes, surface nodes scattered on the sphere. Architectural.",
         "params": {"type": "lattice", "seed": 5}},
        {"id": "radio_lattice_warm",      "form": "radiolaria_specimen",
         "colors": ["#e8d8b8", "#cc4020"],
         "notes": "Same lattice rule, warm palette — cream rings on a cream sphere with ember nodes.",
         "params": {"type": "lattice", "seed": 31}},
        {"id": "radio_ringed_concentric", "form": "radiolaria_specimen",
         "colors": ["#e0d8c0", "#3a2818"],
         "notes": "Ringed form — small core with 1-3 concentric tori, randomly oriented. Saturn-like.",
         "params": {"type": "ringed", "seed": 9}},
        {"id": "radio_pollen_bumps",      "form": "radiolaria_specimen",
         "colors": ["#f0c870", "#a85020"],
         "notes": "Pollen — substrate sphere covered in surface bumps, with 1-3 germ pores subtracted on the equator.",
         "params": {"type": "pollen", "seed": 13}},
        {"id": "radio_pollen_violet",     "form": "radiolaria_specimen",
         "colors": ["#c8b8d8", "#6a30a0"],
         "notes": "Pollen with violet palette — pale lavender + deep purple accents.",
         "params": {"type": "pollen", "seed": 41}},

        # ── Extra basic / spiky / polyhedral palettes ────────────────
        {"id": "radio_basic_fossilized",      "form": "radiolaria_specimen",
         "colors": ["#a89070", "#3a1810"],
         "notes": "Basic specimen, fossilized palette — preserved silica plus iron oxidation pockets.",
         "params": {"type": "basic", "seed": 23}},
        {"id": "radio_basic_glass",           "form": "radiolaria_specimen",
         "colors": ["#e8f0f8", "#88c0d8"],
         "notes": "Glass radiolarian — pale silica with cool aqua highlights. Living-microscope view.",
         "params": {"type": "basic", "seed": 47}},
        {"id": "radio_spiky_random_brass",    "form": "radiolaria_specimen",
         "colors": ["#e8c870", "#a86028"],
         "notes": "Spiky form, brass palette — Haeckel chromolithograph reissued in foundry colors.",
         "params": {"type": "spiky", "seed": 53, "max_spike_length": 1.3}},
        {"id": "radio_spiky_violet_short",    "form": "radiolaria_specimen",
         "colors": ["#e0d8e8", "#3818a0"],
         "notes": "Spiky form with stubby violet spikes — pollen-like density with icosahedral symmetry.",
         "params": {"type": "spiky", "seed": 59, "max_spike_length": 0.55}},
        {"id": "radio_polyhedral_klein",      "form": "radiolaria_specimen",
         "colors": ["#aac0d8", "#0a1860"],
         "notes": "Polyhedral form, Klein-blue palette — silica skeleton tinted ultramarine.",
         "params": {"type": "polyhedral", "seed": 61}},

        # ── Lattice / ringed extras ───────────────────────────────────
        {"id": "radio_lattice_rose",          "form": "radiolaria_specimen",
         "colors": ["#f0d8d0", "#a83820"],
         "notes": "Lattice with rose palette — pale pink rings with deep coral nodes.",
         "params": {"type": "lattice", "seed": 67}},
        {"id": "radio_ringed_saturn",         "form": "radiolaria_specimen",
         "colors": ["#e8d8a8", "#88582a"],
         "notes": "Ringed form, Saturn palette — ochre rings around a tan core.",
         "params": {"type": "ringed", "seed": 71}},

        # ── Pollen extras ─────────────────────────────────────────────
        {"id": "radio_pollen_blackcurrant",   "form": "radiolaria_specimen",
         "colors": ["#3818a0", "#88a830"],
         "notes": "Pollen, blackcurrant palette — purple grain with pollen-yellow surface bumps.",
         "params": {"type": "pollen", "seed": 73}},
        {"id": "radio_pollen_alabaster",      "form": "radiolaria_specimen",
         "colors": ["#f8f0e8", "#3a3028"],
         "notes": "Pollen, alabaster carving — bone-white substrate with charcoal accents.",
         "params": {"type": "pollen", "seed": 79}},

        # ── Diatoms (NEW form) ────────────────────────────────────────
        {"id": "radio_diatom_white",          "form": "radiolaria_specimen",
         "colors": ["#f0f0e0", "#88a8c0"],
         "notes": "Diatom — flat disc with radial rim spines and a central pore. The sand-dollar of the microscopic world.",
         "params": {"type": "diatom", "seed": 1}},
        {"id": "radio_diatom_amber",          "form": "radiolaria_specimen",
         "colors": ["#e8c878", "#3a1808"],
         "notes": "Amber diatom — fossilized substrate with deep brown spines.",
         "params": {"type": "diatom", "seed": 5}},
        {"id": "radio_diatom_violet",         "form": "radiolaria_specimen",
         "colors": ["#d8c0d8", "#6a2880"],
         "notes": "Violet diatom — pale lavender disc, deep magenta rim spines.",
         "params": {"type": "diatom", "seed": 11}},

        # ── Molecular chains (path-following CSG growth) ──────────────
        # Atoms walk a path, close-pack against neighbors, occasionally
        # branch like substituents on an organic molecule. Topology
        # parameter switches between growth (branching tree), chain
        # (worm), helix (DNA-like), and ring (cyclic).
        {"id": "radio_globular_cream",        "form": "radiolaria_specimen",
         "colors": ["#f0e0c0", "#a87838"],
         "notes": "Molecular growth — atoms walk an organic path, close-packed, occasionally branching like substituents on a polymer backbone.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 14, "atom_radius": 0.10, "pack": 0.72, "drift": 0.55, "branch_probability": 0.18, "seed": 3}},
        {"id": "radio_globular_marine",       "form": "radiolaria_specimen",
         "colors": ["#88b0c8", "#3060a0"],
         "notes": "Marine molecular chain — long worm-form, low branching probability. Ocean palette.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 18, "atom_radius": 0.09, "pack": 0.70, "drift": 0.45, "branch_probability": 0.05, "seed": 17}},
        {"id": "radio_globular_red",          "form": "radiolaria_specimen",
         "colors": ["#e88060", "#5a1810"],
         "notes": "Molecular growth, red — atoms expand along a curving path, close-packed CSG UNION. Two end caps in deep red read as accent groups.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 16, "atom_radius": 0.10, "pack": 0.72, "drift": 0.55, "branch_probability": 0.20, "seed": 29}},
        {"id": "radio_helix_dna",             "form": "radiolaria_specimen",
         "colors": ["#a8c8e8", "#1f4ecc"],
         "notes": "DNA helix — atoms walk a smooth helical path, every 3rd atom in deep blue. The double-helix backbone in CSG form (one strand).",
         "params": {"type": "globular_cluster", "topology": "helix", "atoms": 18, "atom_radius": 0.09, "seed": 7}},
        {"id": "radio_ring_benzene",          "form": "radiolaria_specimen",
         "colors": ["#e8d8a8", "#3a2818"],
         "notes": "Benzene ring — 6 carbons in a hexagonal cycle, alternating bond color. Pack=1.6 separates atoms slightly so each reads as its own carbon (space-filling model).",
         "params": {"type": "globular_cluster", "topology": "ring", "atoms": 6, "atom_radius": 0.18, "pack": 1.6, "seed": 1}},
        {"id": "radio_ring_cyclo10",          "form": "radiolaria_specimen",
         "colors": ["#d8e0c0", "#5a8038"],
         "notes": "Cyclodecane — 10-atom macrocycle. Smaller atoms, closer pack — reads as a fused ring backbone.",
         "params": {"type": "globular_cluster", "topology": "ring", "atoms": 10, "atom_radius": 0.13, "pack": 1.4, "seed": 1}},
        {"id": "radio_chain_branched",        "form": "radiolaria_specimen",
         "colors": ["#e8c890", "#a83820"],
         "notes": "Highly-branched molecular chain — branch probability bumped to 35%, atoms multiply tree-style.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 22, "atom_radius": 0.09, "pack": 0.70, "drift": 0.65, "branch_probability": 0.35, "seed": 53}},

        # ── Stretch-test series ────────────────────────────────────
        # The "stretched ring" effect comes from CSG UNION fusing the
        # accent atom into a chain of larger-color spheres on both sides.
        # Lower pack → atoms more buried → ring thinner / more stretched.
        # Higher accent_period → fewer accents → each band more isolated.

        {"id": "radio_stretch_pack_070",      "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "Stretch-test pack=0.70 — 24 atoms, low drift, accent every 6th. Reference: rings clearly visible, atoms still distinguishable.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 24, "atom_radius": 0.10, "pack": 0.70, "drift": 0.20, "branch_probability": 0.0, "accent_period": 6, "seed": 1}},
        {"id": "radio_stretch_pack_055",      "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "Stretch-test pack=0.55 — same chain, atoms more overlapped. Accent rings get THINNER & MORE STRETCHED. The sweet spot.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 24, "atom_radius": 0.10, "pack": 0.55, "drift": 0.20, "branch_probability": 0.0, "accent_period": 6, "seed": 1}},
        {"id": "radio_stretch_pack_045",      "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "Stretch-test pack=0.45 — heavy overlap. Rings now read as thin slits. Chain becomes a smooth tube with red bands.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 24, "atom_radius": 0.10, "pack": 0.45, "drift": 0.20, "branch_probability": 0.0, "accent_period": 6, "seed": 1}},
        {"id": "radio_stretch_pack_035",      "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "Stretch-test pack=0.35 — extreme overlap. Accent atom barely peeks through. Edge of legibility.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 24, "atom_radius": 0.10, "pack": 0.35, "drift": 0.20, "branch_probability": 0.0, "accent_period": 6, "seed": 1}},

        # ── Long-chain series — same pack, chain expands ──────────
        {"id": "radio_chain_long_30",         "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "30-atom polymer at pack=0.55. Chain length scales linearly; the stretched-ring effect repeats every 6 atoms.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 30, "atom_radius": 0.08, "pack": 0.55, "drift": 0.18, "branch_probability": 0.0, "accent_period": 6, "seed": 1}},
        {"id": "radio_chain_long_45",         "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "45-atom polymer — same recipe stretched longer. Several ring-bands fit in one frame.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 45, "atom_radius": 0.07, "pack": 0.55, "drift": 0.15, "branch_probability": 0.0, "accent_period": 7, "seed": 1}},
        {"id": "radio_chain_long_60",         "form": "radiolaria_specimen",
         "colors": ["#f0e0c8", "#cc1f1f"],
         "notes": "60-atom polymer — extreme length. Chain coils through the camera frame; ring effect persists at the same micro-scale.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 60, "atom_radius": 0.06, "pack": 0.55, "drift": 0.13, "branch_probability": 0.0, "accent_period": 8, "seed": 1}},

        # ── The signature: long + thin + stretched ────────────────
        {"id": "radio_chain_signature_red",   "form": "radiolaria_specimen",
         "colors": ["#f8e0c0", "#cc2018"],
         "notes": "Signature stretched chain — 36 atoms, pack=0.50, accent every 5th. Chain reads as a worm with periodic red rings.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 36, "atom_radius": 0.08, "pack": 0.50, "drift": 0.18, "branch_probability": 0.0, "accent_period": 5, "seed": 11}},
        {"id": "radio_chain_signature_klein", "form": "radiolaria_specimen",
         "colors": ["#a8c8e8", "#0a1860"],
         "notes": "Signature chain in Klein blue — same recipe, ultramarine accents on pale aqua tube.",
         "params": {"type": "globular_cluster", "topology": "growth", "atoms": 36, "atom_radius": 0.08, "pack": 0.50, "drift": 0.18, "branch_probability": 0.0, "accent_period": 5, "seed": 11}},

        # ── Tentacle creatures: center bulge + N radiating chains ──────
        # Bulge + tentacles topology = jellyfish, octopus, anemone, sun.
        # Each tentacle tapers toward the tip and carries the same red-ring
        # CSG fusion artifacts as the linear chain.
        {"id": "radio_tentacles_2",           "form": "radiolaria_specimen",
         "colors": ["#f0d8c0", "#c83838"],
         "notes": "2-tentacle creature — center bulge with two opposing arms. The simplest creature topology: dumbbell / barbell.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 2, "tentacle_atoms": 12, "atom_radius": 0.12, "bulge_factor": 3.5, "pack": 0.55, "tentacle_drift": 0.20, "accent_period": 5, "seed": 1}},
        {"id": "radio_tentacles_3",           "form": "radiolaria_specimen",
         "colors": ["#e0d0b8", "#a8281a"],
         "notes": "3-tentacle creature — Fibonacci-spiral distribution. Triskelion in Boolean form.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 3, "tentacle_atoms": 10, "atom_radius": 0.11, "bulge_factor": 3.5, "pack": 0.55, "tentacle_drift": 0.18, "accent_period": 5, "seed": 3}},
        {"id": "radio_tentacles_4",           "form": "radiolaria_specimen",
         "colors": ["#e8d8b0", "#3818a0"],
         "notes": "4-tentacle creature — quadrupedal. Fibonacci distribution gives slight asymmetry.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 4, "tentacle_atoms": 9, "atom_radius": 0.10, "bulge_factor": 3.2, "pack": 0.55, "tentacle_drift": 0.20, "accent_period": 4, "seed": 7}},
        {"id": "radio_tentacles_6_octopus",   "form": "radiolaria_specimen",
         "colors": ["#d8a878", "#cc1f1f"],
         "notes": "6-tentacle octopus-like — small bulge with six radiating arms. Each arm tapers and curls slightly.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 6, "tentacle_atoms": 11, "atom_radius": 0.10, "bulge_factor": 2.8, "pack": 0.50, "tentacle_drift": 0.30, "accent_period": 5, "seed": 11}},
        {"id": "radio_tentacles_8_anemone",   "form": "radiolaria_specimen",
         "colors": ["#f0c0a8", "#a83820"],
         "notes": "8-tentacle anemone — dense radiating arms. Fibonacci spiral gives pseudo-random arrangement that reads as living.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 8, "tentacle_atoms": 8, "atom_radius": 0.09, "bulge_factor": 2.6, "pack": 0.50, "tentacle_drift": 0.35, "accent_period": 4, "seed": 17}},
        {"id": "radio_tentacles_12_sun",      "form": "radiolaria_specimen",
         "colors": ["#f8d030", "#a83820"],
         "notes": "12-tentacle sun creature — golden palette, short straight arms. The classic radial sea-creature read in Haeckel's plates.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 12, "tentacle_atoms": 6, "atom_radius": 0.11, "bulge_factor": 2.4, "pack": 0.55, "tentacle_drift": 0.10, "accent_period": 3, "seed": 23}},
        {"id": "radio_tentacles_klein_jellyfish","form": "radiolaria_specimen",
         "colors": ["#a8c8e8", "#0a1860"],
         "notes": "Klein-blue jellyfish — large bulge + 5 long curling tentacles. Body and trailing limbs.",
         "params": {"type": "globular_cluster", "topology": "tentacles", "tentacles": 5, "tentacle_atoms": 14, "atom_radius": 0.10, "bulge_factor": 4.0, "pack": 0.55, "tentacle_drift": 0.40, "accent_period": 6, "seed": 29}},

        # ── Headcrabs: bulge + 4 jointed legs + underside beak ─────────
        # Half-Life headcrab anatomy as Boolean specimen. Body sphere has
        # its bottom carved off (flatter silhouette), legs come out of the
        # equator with an upward shoulder before bending sharply DOWN at
        # the knee, ending near floor level. Beak protrudes from underside.
        {"id": "radio_headcrab_classic",      "form": "radiolaria_specimen",
         "colors": ["#d8a878", "#5a1810"],
         "notes": "Classic headcrab — 4 curved legs with knee bend, brown body, dark accent beak underneath. Half-Life silhouette.",
         "params": {"type": "globular_cluster", "topology": "headcrab", "legs": 4, "leg_atoms": 9, "atom_radius": 0.10, "bulge_factor": 3.5, "pack": 0.55, "knee_at": 0.45, "initial_lift": 0.5, "post_knee_drop": 1.6, "accent_period": 5, "seed": 1}},
        {"id": "radio_headcrab_fast",         "form": "radiolaria_specimen",
         "colors": ["#a83820", "#1a0a08"],
         "notes": "Fast headcrab — longer thinner legs, more pronounced knee, blood-red body. Half-Life 2 spider variant.",
         "params": {"type": "globular_cluster", "topology": "headcrab", "legs": 4, "leg_atoms": 11, "atom_radius": 0.08, "bulge_factor": 3.0, "pack": 0.55, "knee_at": 0.40, "initial_lift": 0.7, "post_knee_drop": 2.0, "accent_period": 4, "seed": 7}},
        {"id": "radio_headcrab_six_legs",     "form": "radiolaria_specimen",
         "colors": ["#88a878", "#3a1810"],
         "notes": "Six-legged headcrab — extra pair of legs, denser radial coverage. Spider-headcrab hybrid.",
         "params": {"type": "globular_cluster", "topology": "headcrab", "legs": 6, "leg_atoms": 8, "atom_radius": 0.09, "bulge_factor": 3.2, "pack": 0.55, "knee_at": 0.45, "initial_lift": 0.5, "post_knee_drop": 1.6, "accent_period": 4, "seed": 13}},
        {"id": "radio_headcrab_klein",        "form": "radiolaria_specimen",
         "colors": ["#a8c8e8", "#0a1860"],
         "notes": "Klein-blue headcrab — pale aqua body, ultramarine bands and beak. Marine creature.",
         "params": {"type": "globular_cluster", "topology": "headcrab", "legs": 4, "leg_atoms": 10, "atom_radius": 0.10, "bulge_factor": 3.5, "pack": 0.55, "knee_at": 0.50, "initial_lift": 0.4, "post_knee_drop": 1.5, "accent_period": 4, "seed": 19}},
        {"id": "radio_headcrab_eight_legged", "form": "radiolaria_specimen",
         "colors": ["#3a3028", "#cc1f1f"],
         "notes": "Eight-legged headcrab — full-spider mode. Charcoal body with red bands, dense leg cluster.",
         "params": {"type": "globular_cluster", "topology": "headcrab", "legs": 8, "leg_atoms": 7, "atom_radius": 0.08, "bulge_factor": 3.0, "pack": 0.55, "knee_at": 0.45, "initial_lift": 0.55, "post_knee_drop": 1.5, "accent_period": 3, "seed": 23}},

        # ── Spiral horns / Foram (NEW form) ───────────────────────────
        {"id": "radio_spiral_horn_pearl",     "form": "radiolaria_specimen",
         "colors": ["#f0e8d8", "#a87060"],
         "notes": "Spiral horn — Foraminifera-style tapering bead spiral. Pearl + rose. Two full turns.",
         "params": {"type": "spiral_horn", "seed": 37}},
        {"id": "radio_spiral_horn_klein",     "form": "radiolaria_specimen",
         "colors": ["#a8c8e8", "#1f4ecc"],
         "notes": "Spiral horn, Klein-blue palette — twisting chambered tower.",
         "params": {"type": "spiral_horn", "seed": 41}},
        {"id": "radio_spiral_horn_amber",     "form": "radiolaria_specimen",
         "colors": ["#e8c870", "#3a1810"],
         "notes": "Amber spiral horn — golden bead tower fossilized in resin tones.",
         "params": {"type": "spiral_horn", "seed": 43}},

        # ── Axopods (NEW form) ────────────────────────────────────────
        {"id": "radio_axopod_white",          "form": "radiolaria_specimen",
         "colors": ["#f0f0f0", "#1a1a1a"],
         "notes": "Axopod — Acantharea-style: tiny core with 12 long thin axial spikes. Black-on-white precision drawing.",
         "params": {"type": "axopod", "seed": 13}},
        {"id": "radio_axopod_warm",           "form": "radiolaria_specimen",
         "colors": ["#e8d0a0", "#a83820"],
         "notes": "Axopod, warm palette — cream core with rust-red needles.",
         "params": {"type": "axopod", "seed": 19}},
        {"id": "radio_axopod_klein",          "form": "radiolaria_specimen",
         "colors": ["#cce8f0", "#0a1860"],
         "notes": "Klein-blue axopod — pale aqua core, ultramarine spines.",
         "params": {"type": "axopod", "seed": 23}},

        # ── Comb jellies (NEW form) ───────────────────────────────────
        {"id": "radio_comb_jelly_pearl",      "form": "radiolaria_specimen",
         "colors": ["#f0e8e0", "#88a8c0"],
         "notes": "Comb jelly — 8 vertical bump rows pole-to-pole, accent every 3 bumps. Pearlescent.",
         "params": {"type": "comb_jelly", "seed": 31}},
        {"id": "radio_comb_jelly_iridescent", "form": "radiolaria_specimen",
         "colors": ["#a0e0c8", "#a040c8"],
         "notes": "Iridescent comb jelly — pale sea-green with magenta cilia rows.",
         "params": {"type": "comb_jelly", "seed": 37}},
    ]
    return out


def boolean_corridor_entries() -> list[dict]:
    """Architectural CSG corridors: long box minus aperture pattern.
    Walks down one axis; aperture mode determines the architecture's vocabulary."""
    out = [
        {"id": "corridor_arches_warm",  "form": "boolean_corridor",
         "colors": ["#e8d0a0", "#3088c8", "#3a2810"],
         "notes": "Romanesque arches — sphere subtractions in the side walls. Warm stone, cool sky.",
         "params": {"length": 9.0, "width": 2.6, "height": 2.8, "aperture": "arches", "n_apertures": 5}},
        {"id": "corridor_slots_klein",  "form": "boolean_corridor",
         "colors": ["#0a1860", "#f8d8b8", "#1a1a1a"],
         "notes": "Modernist slot windows — rectangular subtractions. Klein-blue corridor, warm sky.",
         "params": {"length": 9.0, "width": 2.4, "height": 2.6, "aperture": "slots", "n_apertures": 5}},
        {"id": "corridor_vault_terracotta", "form": "boolean_corridor",
         "colors": ["#c8704a", "#88c0e8", "#3a1810"],
         "notes": "Vaulted corridor — sphere subtractions through the ceiling. Terra-cotta walls.",
         "params": {"length": 9.0, "width": 2.6, "height": 2.6, "aperture": "vault", "n_apertures": 4}},
        {"id": "corridor_skylights_concrete", "form": "boolean_corridor",
         "colors": ["#b0b0b0", "#f0c020", "#3a3a3a"],
         "notes": "Concrete corridor with rectangular skylights overhead. Sun pools march down the axis.",
         "params": {"length": 10.0, "width": 2.4, "height": 2.8, "aperture": "skylights", "n_apertures": 5}},
        {"id": "corridor_pillared_marble", "form": "boolean_corridor",
         "colors": ["#f0e8d8", "#3088c8", "#5a4838"],
         "notes": "Pillared niches — wall pockets carved out, leaving column-like sections between.",
         "params": {"length": 9.0, "width": 3.0, "height": 2.8, "aperture": "pillared", "n_apertures": 4}},
        {"id": "corridor_arches_sunset", "form": "boolean_corridor",
         "colors": ["#a82018", "#f8d030", "#3a0808"],
         "notes": "Arches with sunset palette — deep red wall, golden sky framing each opening.",
         "params": {"length": 8.0, "width": 2.4, "height": 2.6, "aperture": "arches", "n_apertures": 4}},
    ]
    return out


def boolean_space_entries() -> list[dict]:
    """Procedural architectural CSG rooms — light wells, grottos, atria,
    apses, inverse cubes. The signature carved feature defines the space."""
    out = [
        {"id": "space_atrium_warm",     "form": "boolean_procedural_space",
         "colors": ["#f0e0c8", "#a86028", "#3a2810"],
         "notes": "Atrium with a circular oculus through the ceiling and a single column under it. Roman house DNA.",
         "params": {"size": 4.5, "space_type": "atrium", "seed": 1}},
        {"id": "space_grotto_cool",     "form": "boolean_procedural_space",
         "colors": ["#5878a0", "#80b0e0", "#1a2840"],
         "notes": "Grotto — six overlapping sphere subtractions hollow out a cave-like void. Pool at floor center.",
         "params": {"size": 4.8, "space_type": "grotto", "seed": 5}},
        {"id": "space_light_well_klein", "form": "boolean_procedural_space",
         "colors": ["#e0d8c0", "#1f4ecc", "#3a2818"],
         "notes": "Light well — tall vertical cylinder cut through ceiling and floor. Column of Klein-blue light.",
         "params": {"size": 4.5, "space_type": "light_well", "seed": 9}},
        {"id": "space_apse_red",        "form": "boolean_procedural_space",
         "colors": ["#d04830", "#f8d030", "#3a1810"],
         "notes": "Apse — half-sphere niche carved into the back wall, golden back-plate inside. Sacred geometry.",
         "params": {"size": 4.5, "space_type": "apse", "seed": 3}},
        {"id": "space_inverse_cube",    "form": "boolean_procedural_space",
         "colors": ["#c8c0b0", "#5a3818", "#3a3028"],
         "notes": "Cube minus alcoves — four wall-niches + ceiling oculus carved out of a solid block.",
         "params": {"size": 4.6, "space_type": "inverse_cube", "seed": 11}},
        {"id": "space_grotto_warm",     "form": "boolean_procedural_space",
         "colors": ["#a87838", "#f0a040", "#3a1810"],
         "notes": "Grotto with warm palette — golden bubble cave, ember pool. Pompeii catacomb feel.",
         "params": {"size": 4.8, "space_type": "grotto", "seed": 19}},
    ]
    return out


def fantastic_form_entries() -> list[dict]:
    """Six exotic CSG forms: Menger sponge (recursive fractal), gyroid
    pillar (TPMS analog), trabecular bone (random sphere subtractions),
    Schwarz lattice (cubic vertex voids), hyperbolic vault (Gaudí/Catalan
    rib ceiling), sponge skeleton (axis channels).

    These were never well-served by primitive_stack — they need real
    Boolean composition. Now they have a home."""
    out = [
        # ── Menger sponges ────────────────────────────────────────────
        {"id": "menger_sponge_d2_warm",
         "form": "menger_sponge",
         "colors": ["#e8c890", "#a86028"],
         "notes": "Menger sponge depth 2 — 400 unit cubes after subtraction. Sandstone palette.",
         "params": {"depth": 2, "size": 1.6}},
        {"id": "menger_sponge_d2_klein",
         "form": "menger_sponge",
         "colors": ["#1f4ecc", "#80b0e0"],
         "notes": "Menger sponge in Klein blue — the fractal whose dimension is log(20)/log(3) ≈ 2.726.",
         "params": {"depth": 2, "size": 1.6}},
        {"id": "menger_sponge_d1_red",
         "form": "menger_sponge",
         "colors": ["#cc1f1f", "#3a0808"],
         "notes": "Menger depth 1 — only 20 cubes; the simplest sponge before recursion explodes.",
         "params": {"depth": 1, "size": 1.6}},

        # ── Gyroid pillars ────────────────────────────────────────────
        {"id": "gyroid_pillar_klein",
         "form": "gyroid_pillar",
         "colors": ["#a8c8e8", "#1f4ecc"],
         "notes": "Schoen Gyroid analog — interlinked torus stack approximating the famous triply-periodic minimal surface. Klein-blue chord.",
         "params": {"layers": 14, "twist": 0.6}},
        {"id": "gyroid_pillar_brass",
         "form": "gyroid_pillar",
         "colors": ["#e8c870", "#a86028"],
         "notes": "Brass-and-amber gyroid pillar — what a Schoen Gyroid would look like cast in foundry metal.",
         "params": {"layers": 14, "twist": 0.7}},

        # ── Trabecular bone ───────────────────────────────────────────
        {"id": "trabecular_skeleton_bone",
         "form": "trabecular_skeleton",
         "colors": ["#f0e0c8", "#a87838"],
         "notes": "Bone trabeculae — sphere with 60 random spherical voids carved out, leaving the strut network. Cream marrow palette.",
         "params": {"voids": 60, "seed": 1}},
        {"id": "trabecular_skeleton_dense",
         "form": "trabecular_skeleton",
         "colors": ["#d8d8c8", "#3a2818"],
         "notes": "Dense trabecular bone — 90 voids creates a very airy strut network, almost foam-like.",
         "params": {"voids": 90, "min_void_r": 0.10, "max_void_r": 0.18, "seed": 11}},

        # ── Schwarz lattices ──────────────────────────────────────────
        {"id": "schwarz_lattice_white",
         "form": "schwarz_lattice",
         "colors": ["#f0f0f0", "#3a3a3a"],
         "notes": "Schwarz P-surface analog: cube minus spheres at all 27 vertices of a 3×3×3 lattice. Architectural foam.",
         "params": {"grid": 3, "void_r": 0.40, "size": 1.5}},
        {"id": "schwarz_lattice_dense",
         "form": "schwarz_lattice",
         "colors": ["#a8b0c0", "#0a0a0a"],
         "notes": "Denser Schwarz lattice on a 4×4×4 grid (64 voids). Reads as a delicate strut framework.",
         "params": {"grid": 4, "void_r": 0.28, "size": 1.5}},

        # ── Hyperbolic vault ──────────────────────────────────────────
        {"id": "hyperbolic_vault_gaudi",
         "form": "hyperbolic_vault",
         "colors": ["#e8d0a0", "#c8704a"],
         "notes": "Gaudí Sagrada Família-style vault — twisting cylinders carved through the ceiling form rib pattern. Sandstone + ember.",
         "params": {"ribs": 12, "rib_thickness": 0.10}},
        {"id": "hyperbolic_vault_violet",
         "form": "hyperbolic_vault",
         "colors": ["#a878a0", "#3818a0"],
         "notes": "Hyperbolic vault, dusk palette — Gaudí dreams in violet.",
         "params": {"ribs": 14, "rib_thickness": 0.08}},

        # ── Voronoi meteorites ────────────────────────────────────────
        {"id": "voronoi_meteorite_iron",
         "form": "voronoi_meteorite",
         "colors": ["#a89878", "#3a2818"],
         "notes": "Iron-nickel meteorite — sphere with 24 spherical craters in Voronoi-like distribution. Asteroid surface from CSG SUBTRACTION alone.",
         "params": {"radius": 0.7, "seeds": 24, "crater_min": 0.10, "crater_max": 0.30, "seed": 1}},
        {"id": "voronoi_meteorite_dense",
         "form": "voronoi_meteorite",
         "colors": ["#888080", "#1a1010"],
         "notes": "Dense crater field — 50 craters of varied size. Reads as a beat-up asteroid or ancient skull-stone.",
         "params": {"radius": 0.7, "seeds": 50, "crater_min": 0.06, "crater_max": 0.20, "seed": 7}},
        {"id": "voronoi_meteorite_klein",
         "form": "voronoi_meteorite",
         "colors": ["#88a8c8", "#0a1860"],
         "notes": "Klein-blue cratered moon — pale aqua surface with deep impact pockets.",
         "params": {"radius": 0.7, "seeds": 32, "crater_min": 0.08, "crater_max": 0.25, "seed": 13}},

        # ── Sponge skeletons ──────────────────────────────────────────
        {"id": "sponge_skeleton_pompeii",
         "form": "sponge_skeleton",
         "colors": ["#e8c890", "#a83820"],
         "notes": "Sponge skeleton: cube with cylindrical channels punched along all three axes. Pompeii-floor palette.",
         "params": {"grid": 4, "hole_radius": 0.18, "size": 1.5}},
        {"id": "sponge_skeleton_marble",
         "form": "sponge_skeleton",
         "colors": ["#f0f0e8", "#3a3028"],
         "notes": "Marble sponge skeleton — coarser 3×3 channel grid leaves more material between holes.",
         "params": {"grid": 3, "hole_radius": 0.22, "size": 1.5}},

        # ── Boolean cathedrals (recursive nested CSG) ────────────────
        {"id": "boolean_cathedral_classic",
         "form": "boolean_cathedral",
         "colors": ["#e8d8b8", "#f0c020", "#3a2818"],
         "notes": "Cathedral nave with arched windows + apse hemisphere at the far end + 5 niches with golden ornaments. Four nested CSG levels: nave → arches → apse → niches → ornaments.",
         "params": {"nave_length": 7.0, "nave_width": 3.6, "nave_height": 4.0, "arches": 4, "niches": 5}},
        {"id": "boolean_cathedral_violet",
         "form": "boolean_cathedral",
         "colors": ["#e8d8e0", "#a040c8", "#3a1840"],
         "notes": "Violet cathedral — pale-mauve walls, magenta apertures. Bardo / Turrell-cathedral hybrid.",
         "params": {"nave_length": 7.0, "nave_width": 3.6, "nave_height": 4.0, "arches": 5, "niches": 7}},
        {"id": "boolean_cathedral_gothic",
         "form": "boolean_cathedral",
         "colors": ["#a87838", "#f8e030", "#1a0a08"],
         "notes": "Gothic cathedral — terra-cotta walls, golden apse, dense niches. Sagrada Família palette.",
         "params": {"nave_length": 8.0, "nave_width": 3.6, "nave_height": 4.5, "arches": 6, "niches": 9}},
    ]
    return out


def turrell_entries() -> list[dict]:
    """James Turrell-inspired Boolean architectural color spaces.
    Four forms × multiple palettes — the color IS the architecture."""
    out = [
        # ── Skyspaces (ceiling aperture) ────────────────────────────
        {"id": "skyspace_meeting_orange_sky",
         "form": "turrell_skyspace",
         "colors": ["#e88828", "#3088c8"],
         "notes": "Live Oak Friends 'Meeting' (1996) — warm orange room, cool aperture revealing blue sky. Image ref 4.",
         "params": {"room_size": 5.0, "room_height": 3.4, "aperture_w": 1.6, "aperture_d": 1.6}},
        {"id": "skyspace_violet_sky",
         "form": "turrell_skyspace",
         "colors": ["#d04898", "#4a2890"],
         "notes": "Magenta room with deep-violet aperture — saturation contrast at the sky.",
         "params": {"room_size": 5.0, "room_height": 3.4, "aperture_w": 1.4, "aperture_d": 1.4}},
        {"id": "skyspace_amber_dusk",
         "form": "turrell_skyspace",
         "colors": ["#d8a040", "#783090"],
         "notes": "Amber/violet — the Turrell signature dusk pairing; warm room cooled by aperture.",
         "params": {"room_size": 5.0, "room_height": 3.4, "aperture_w": 1.5, "aperture_d": 1.5}},
        {"id": "skyspace_klein_blue_pierced",
         "form": "turrell_skyspace",
         "colors": ["#0a1860", "#f8d8b8"],
         "notes": "Klein-blue interior pierced by warm pale sky — Klein meets Turrell.",
         "params": {"room_size": 5.0, "room_height": 3.4, "aperture_w": 1.4, "aperture_d": 1.4}},

        # ── Afrum corners (projected solid of light) ────────────────
        {"id": "afrum_blue_corner",
         "form": "turrell_afrum_corner",
         "colors": ["#08081a", "#28a8ff"],
         "notes": "Afrum (Blue), 1968 — saturated blue cube floats in the corner; the original Turrell illusion. Image ref 1.",
         "params": {}},
        {"id": "afrum_pink_corner",
         "form": "turrell_afrum_corner",
         "colors": ["#0a0816", "#ff60b0"],
         "notes": "Afrum (Pink) — Memphis pink cube glowing in a near-black room.",
         "params": {}},
        {"id": "afrum_yellow_corner",
         "form": "turrell_afrum_corner",
         "colors": ["#080808", "#f8d030"],
         "notes": "Afrum (Yellow) — the warmest variant; cube reads almost like a window.",
         "params": {}},

        # ── Chromatic chambers (back-wall aperture + steps) ─────────
        {"id": "chamber_red_yellow",
         "form": "turrell_chromatic_chamber",
         "colors": ["#c83030", "#f8c020"],
         "notes": "Red chamber, yellow aperture — 'Bridget's Bardo' palette. Image ref 3.",
         "params": {}},
        {"id": "chamber_purple_violet",
         "form": "turrell_chromatic_chamber",
         "colors": ["#a04098", "#3818a0"],
         "notes": "Magenta chamber, deep-violet aperture — Bardo / staircase ascension. Image ref 2 echo.",
         "params": {}},
        {"id": "chamber_orange_blue",
         "form": "turrell_chromatic_chamber",
         "colors": ["#d86028", "#28a8d0"],
         "notes": "Warm orange chamber with cool blue aperture — full complementary contrast.",
         "params": {}},

        # ── Aten Reign (concentric rings overhead) ──────────────────
        {"id": "aten_reign_violet_dusk",
         "form": "turrell_aten_reign",
         "colors": lerp_hsv("#a040c8", "#3030a8", 6),
         "notes": "Aten Reign (Guggenheim, 2013): magenta→violet vortex overhead. Image ref 5.",
         "params": {"rings": 6}},
        {"id": "aten_reign_full_hsv",
         "form": "turrell_aten_reign",
         "colors": [_rgb_to_hex(*colorsys.hsv_to_rgb(i / 6.0, 0.85, 0.95)) for i in range(6)],
         "notes": "Full HSV chromatic vortex — the rotunda walks the wheel from outer to inner.",
         "params": {"rings": 6}},
        {"id": "aten_reign_yellow_blue",
         "form": "turrell_aten_reign",
         "colors": lerp_hsv("#f0c020", "#1840a0", 6),
         "notes": "Yellow→blue HSV walk overhead — passes through green/cyan en route.",
         "params": {"rings": 6}},
        {"id": "aten_reign_warm_ember",
         "form": "turrell_aten_reign",
         "colors": lerp_rgb("#3a0808", "#f8c878", 6),
         "notes": "Ember rotunda — Rothko warm-field walked vertically.",
         "params": {"rings": 6}},
    ]
    return out


GALLERIES = {
    "chromatic-fins-gallery":         (fin_entries,      "Cruz-Diez chromatic fin walls — vertical translucent fins, one hue per fin, parallax stagger. Built from gradient_interpolator (RGB vs HSV) and color_mixing palettes."),
    "gradient-corridor-gallery":      (corridor_entries, "Walk-through gradient corridors — floor + walls + ceiling stripe per ring. Inspired by Olafur Eliasson chromatic interiors and the yellow-tunnel reference."),
    "chromatic-panel-field-gallery":  (panel_entries,    "Suspended translucent chromatic panels arranged on a wood-floor disk. The hanging-gallery reference rendered through gradient_interpolator and color_mixing logic."),
    "chromatic-grid-3x3-gallery":     (panel_grid_3x3_entries, "3×3 plan grid of vertical translucent panels rotated at 90° intervals. Adjacent panels cross orthogonally — overlap-mix where they meet. Sol LeWitt grid combinatorics × Cruz-Diez chromatic acrylic × color_mixing.gd's overlap logic."),
    "truchet-grid-gallery":           (truchet_entries,  "Smith-Truchet tile fields. Each cell is a square split along one diagonal, randomly rotated. Curves emerge from the square grid — the canonical 'rule generates form' procedural pattern. Sébastien Truchet 1704; revived by Cyril Stanley Smith 1987."),
    "wolfram-ca-wall-gallery":        (wolfram_entries,  "Wolfram elementary 1D cellular automata. One rule (0–255), one seed cell, N generations → 2D pattern. The minimal recipe for emergent complexity. Rule 30 chaos, rule 90 Sierpiński, rule 110 Turing-complete."),
    "voronoi-field-gallery":          (voronoi_entries,  "Voronoi tessellations. K seeds, nearest-color rasterization on a grid. Mondrian without right angles. Each seed colors its territory; territory shape emerges from seed positions alone."),
    "turrell-spaces-gallery":         (turrell_entries,  "James Turrell-inspired Boolean architectural color spaces. Four forms: skyspaces (ceiling aperture revealing sky), Afrums (saturated cubes of light projected into room corners), chromatic chambers (Live Oak Friends Meeting / Bridget's Bardo), and Aten Reign (concentric oval rings stacked overhead in the Guggenheim rotunda). Color is the architecture."),
    "radiolaria-csg-gallery":         (radiolaria_entries, "Ernst Haeckel-style biological specimens via Godot's CSG (Constructive Solid Geometry) — basic / spiky / polyhedral / lattice / ringed / pollen forms. Each is a Boolean tree of CSGSphere/Cylinder/Torus with UNION + SUBTRACTION operations. Sister to algorithms/computationalbiology/radiolaria, presented as a curatable gallery."),
    "boolean-corridor-gallery":       (boolean_corridor_entries, "Architectural CSG corridors. Each is a long box with apertures subtracted from its walls/ceiling: arched windows (sphere SUBTRACTION), slot windows (box SUBTRACTION), vault hollows (hemisphere through ceiling), skylights (slot in ceiling), or pillared niches (wall pockets). Romanesque, modernist, brutalist, classical — all from the same Boolean recipe."),
    "boolean-space-gallery":          (boolean_space_entries, "Procedural architectural CSG rooms. Each room shell is a hollowed box, with a signature carved feature defining the space: central oculus (atrium), overlapping spherical voids (grotto), vertical cylinder light well, half-sphere apse niche, or alcove-carved inverse cube. The feature IS the architecture."),
    "fantastic-csg-gallery":          (fantastic_form_entries, "Six exotic CSG forms that primitive_stack could never carry: Menger sponge (recursive fractal cube), Schoen Gyroid pillar (TPMS analog), trabecular bone (random spherical voids in a sphere), Schwarz lattice (cubic vertex voids), Gaudí hyperbolic vault (twisting rib ceiling), and sponge skeleton (cylindrical channel grid). Mathematical, biological, architectural — all from the same Boolean recipe."),
}


# ── Render execution ─────────────────────────────────────────────

def render_one(godot: str, gallery_slug: str, entry: dict, force: bool) -> bool:
    cid = entry["id"]
    out_dir = ENC / "public" / gallery_slug
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{cid}.png"
    out_cfg = out_dir / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"    skip   {cid}")
        return True

    # The gallery's <id>.json is the human-readable record — full entry incl. notes.
    out_cfg.write_text(json.dumps(entry, indent=2) + "\n", encoding="utf-8")

    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    cfg_for_render = {
        "id": cid,
        "form": entry["form"],
        "colors": entry["colors"],
        "params": entry.get("params", {}),
    }
    cfg_staging = STAGING_DIR / f"{cid}.json"
    cfg_staging.write_text(json.dumps(cfg_for_render, indent=2), encoding="utf-8")

    user_out = f"user://chromatic_gallery/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off",
        "--script", "res://commons/testing/render_chromatic_form.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=800", "--wait=2.5",
    ]
    print(f"    render {cid:42s} ", end="", flush=True)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
    except subprocess.TimeoutExpired:
        print("TIMEOUT"); return False
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr:
            print(f"      stderr: {proc.stderr[-300:]}")
        return False

    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        print("no APPDATA"); return False
    ud = Path(appdata) / "Godot" / "app_userdata"
    src = None
    if ud.exists():
        for d in ud.iterdir():
            cand = d / "chromatic_gallery" / f"{cid}.png"
            if cand.exists():
                src = cand; break
    if src is None:
        print("no PNG produced"); return False
    shutil.copy2(src, out_png)
    print(f"OK ({src.stat().st_size // 1024} KB)")
    return True


def write_manifest(slug: str, entries: list[dict], description: str) -> None:
    out_dir = ENC / "public" / slug
    rows = []
    for e in entries:
        rows.append({
            "id": e["id"],
            "form": e.get("form", ""),
            "n_colors": len(e.get("colors", [])),
            "notes": e.get("notes", ""),
            "image": f"/{slug}/{e['id']}.png",
            "config": f"/{slug}/{e['id']}.json",
        })
    manifest = {
        "schema_version": 1, "version": 1,
        "description": description,
        "entries": rows,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def merge_into_master(slug: str, entries: list[dict]) -> None:
    src = ENC / "public" / slug
    dst = ENC / "public" / PS_GALLERY
    if not (dst / "manifest.json").exists(): return
    for e in entries:
        for ext in (".png", ".json"):
            sp = src / (e["id"] + ext)
            if sp.exists(): shutil.copy2(sp, dst / (e["id"] + ext))
    m = json.loads((dst / "manifest.json").read_text(encoding="utf-8"))
    existing = {x["id"] for x in m["entries"]}
    added = 0
    for e in entries:
        if e["id"] in existing: continue
        m["entries"].append({
            "id": e["id"],
            "notes": f"[{slug.replace('-gallery','').replace('-',' ')}] {e.get('notes', '')}",
            "layout": e["form"],
            "image": f"/{PS_GALLERY}/{e['id']}.png",
            "config": f"/{PS_GALLERY}/{e['id']}.json",
        })
        added += 1
    (dst / "manifest.json").write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  merged into /{PS_GALLERY}/: +{added} entries (total {len(m['entries'])})")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--gallery", help="Build only this slug")
    ap.add_argument("--no-merge", action="store_true")
    args = ap.parse_args()

    plan = {k: v for k, v in GALLERIES.items() if not args.gallery or k == args.gallery}
    print(f"Galleries: {list(plan.keys())}")
    total = 0
    for slug, (gen, _desc) in plan.items():
        entries = gen()
        total += len(entries)
        print(f"  {slug}: {len(entries)} entries")
        for e in entries:
            print(f"    - {e['id']:40s} form={e['form']:25s} n={len(e['colors'])}")
    print(f"  total: {total} entries\n")

    if args.dry: return

    godot = _find_godot()
    if not godot:
        print("No Godot. Set GODOT_EXE."); sys.exit(1)

    for slug, (gen, desc) in plan.items():
        entries = gen()
        print(f"  {slug}:")
        for e in entries:
            render_one(godot, slug, e, args.force)
        write_manifest(slug, entries, desc)
        if not args.no_merge:
            merge_into_master(slug, entries)
        print()


if __name__ == "__main__":
    main()
