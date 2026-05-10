"""grammar_dna.py — auto-research compositional grammar variants.

Where primitive_dna.py sweeps one primitive's parameter space, this tool
generates *compositions* that demonstrate categories of the compositional
grammar. Each category has its own variant generator that emits compose
JSON specs, which the existing primitive_dna.py compose mode renders
into .tscn scenes.

First three categories shipped (of the eight named):
  A. cube_to_pyramid    — single CylinderMesh(4) with top_radius sweep
  B. solomonic_stack    — N CylinderMesh stacked with rotation offset Δθ
  C. tessellation_field — N×M grid of CylinderMesh(K) tiles

Storage convention mirrors the others:
  ada_encyclopedia/public/grammar-runs/<category>/<variant_id>/{front,...}.png
  ada_encyclopedia/public/grammar-runs/manifest.json
"""

from __future__ import annotations

import argparse
import datetime
import json
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
ENCY = REPO.parent / "ada_encyclopedia"
GRAMMAR_RUNS = ENCY / "public" / "grammar-runs"
PROMOTED_DIR = REPO / "commons" / "primitives" / "promoted"
SPECS_DIR = PROMOTED_DIR / "_specs"
GODOT_EXE = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
CAPTURE_SCRIPT = "res://commons/testing/capture_multi_angle.gd"


# ── Category A: cube → pyramid morph ────────────────────────────────
# CylinderMesh(radial_segments=4) with sweep on top_radius / bottom_radius
# at fixed bottom_radius. r = top/bottom is the single shape parameter.
# r=0 → pyramid, r=1 → cube, r>1 → mushroom cap.

def gen_cube_to_pyramid() -> list[dict]:
    """8 variants showing the pyramid → cube → mushroom morph."""
    variants = []
    bottom_r = 0.40
    height = 0.40
    ratios = [0.0, 0.10, 0.25, 0.50, 0.75, 1.00, 1.40, 2.00]
    for r in ratios:
        top_r = bottom_r * r
        spec = {
            "_comment": f"cube↔pyramid morph: top/bottom = {r:.2f}",
            "primitive": "Composition",
            "shader": "flat",
            "color": [0.62, 0.65, 0.74],
            "components": [
                {
                    "primitive": "CylinderMesh",
                    "params": {
                        "top_radius": round(top_r, 4),
                        "bottom_radius": bottom_r,
                        "height": height,
                        "radial_segments": 4,
                    },
                    "transform": {"position": [0, height * 0.5, 0]},
                }
            ],
        }
        variants.append({
            "id": f"r{int(r*100):03d}",
            "spec": spec,
            "params": {"top_bottom_ratio": r, "shape": _label_shape(r)},
        })
    return variants


def _label_shape(r: float) -> str:
    if r < 0.05: return "pyramid"
    if r < 0.40: return "tapered_frustum"
    if r < 0.85: return "frustum"
    if r < 1.15: return "cube"
    if r < 1.60: return "inverted_frustum"
    return "mushroom_cap"


# ── Category A.5: totem poles — edge-continuous + per-segment colors
# A vertical column of N segments, each segment a frustum (or cube
# section) where each top_radius MATCHES the next segment's bottom_radius
# (the 180-flip continuity principle). Each segment is also a different
# COLOR drawn from a named palette — like Color_Pillar's pillarcolorcollection
# but stacking colors VERTICALLY within a single column instead of one
# color per pillar. Concrete proof: edge-continuous shape changes + colour
# rhythm = a totem pole.

# Palettes from algorithms/color/color_palettes.tres
PALETTES: dict[str, list[list[float]]] = {
    "rainbow": [
        [0.95, 0.20, 0.25], [0.98, 0.55, 0.15], [1.00, 0.85, 0.20],
        [0.30, 0.80, 0.30], [0.20, 0.65, 0.95], [0.40, 0.30, 0.85],
        [0.62, 0.20, 0.85], [0.95, 0.30, 0.65],
    ],
    "bauhaus": [
        [0.86, 0.08, 0.23], [0.00, 0.45, 0.70], [1.00, 0.84, 0.00],
        [0.10, 0.10, 0.10], [0.95, 0.95, 0.95], [0.50, 0.50, 0.50],
    ],
    "mondrian": [
        [0.95, 0.95, 0.95], [0.90, 0.10, 0.16], [0.05, 0.05, 0.05],
        [0.00, 0.41, 0.78], [1.00, 0.86, 0.00], [0.05, 0.05, 0.05],
    ],
    "memphis": [
        [1.00, 0.08, 0.58], [0.00, 0.98, 0.60], [0.00, 0.75, 0.99],
        [1.00, 0.65, 0.00], [0.63, 0.13, 0.94], [0.20, 0.80, 0.20],
        [1.00, 0.41, 0.71],
    ],
    "autumn": [
        [0.72, 0.45, 0.20], [0.55, 0.27, 0.08], [0.80, 0.50, 0.20],
        [0.86, 0.08, 0.23], [0.94, 0.90, 0.55], [0.50, 0.10, 0.10],
        [0.18, 0.31, 0.31], [0.72, 0.53, 0.04],
    ],
    "hokusai": [
        [0.06, 0.13, 0.31], [0.19, 0.27, 0.47], [0.38, 0.46, 0.65],
        [0.57, 0.68, 0.85], [0.95, 0.95, 0.95], [0.78, 0.86, 0.93],
        [0.15, 0.23, 0.37],
    ],
}


def gen_totem_pole() -> list[dict]:
    """6 totem poles — all edge-continuous, each with a different palette
    and a different segment-shape sequence."""
    variants = []

    def make_totem(variant_id: str, palette_name: str, shape_program: str,
                   layers: list[tuple]) -> dict:
        """layers: list of (bottom_r, top_r, height) tuples, each top_r
        equal to next bottom_r (edge continuity required)."""
        palette = PALETTES[palette_name]
        components = []
        y = 0.0
        for i, (bot, top, h) in enumerate(layers):
            color = palette[i % len(palette)]
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(top, 4),
                    "bottom_radius": round(bot, 4),
                    "height": round(h, 4),
                    "radial_segments": 4,
                },
                "transform": {"position": [0, round(y + h * 0.5, 5), 0]},
                "color": color,
            })
            y += h
        return {
            "id": variant_id,
            "spec": {
                "_comment": f"totem pole: {palette_name} palette, {shape_program} shape program",
                "primitive": "Composition", "shader": "flat",
                "color": [0.5, 0.5, 0.5],  # ignored — per-component colors win
                "components": components,
            },
            "params": {
                "palette": palette_name, "shape_program": shape_program,
                "n_layers": len(layers), "edge_continuous": True,
            },
        }

    R = 0.30
    h = 0.16

    # 1. Rainbow tapered totem: 8 segments, each a frustum tapering inward
    layers = []
    radii = [R * (1.0 - 0.08 * i) for i in range(9)]
    for i in range(8):
        layers.append((radii[i], radii[i + 1], h))
    variants.append(make_totem(
        "rainbow_taper", "rainbow", "tapering frusta (linear)", layers
    ))

    # 2. Bauhaus pinched totem: 6 segments alternating thin/wide pinches
    layers = []
    rs = [R, R * 0.35, R * 0.85, R * 0.40, R * 0.90, R * 0.45, R * 0.20]
    for i in range(6):
        layers.append((rs[i], rs[i + 1], h * 1.1))
    variants.append(make_totem(
        "bauhaus_pinch", "bauhaus", "alternating wide/narrow pinches", layers
    ))

    # 3. Mondrian cube totem: 6 cube segments (constant radius)
    layers = [(R, R, h * 1.4) for _ in range(6)]
    variants.append(make_totem(
        "mondrian_cubes", "mondrian", "constant-radius cube stack", layers
    ))

    # 4. Memphis bulge totem: 7 segments with bulging in/out radius schedule
    layers = []
    rs = [R * 0.4, R * 1.0, R * 0.6, R * 1.1, R * 0.5, R * 0.95, R * 0.3, R * 0.5]
    for i in range(7):
        layers.append((rs[i], rs[i + 1], h * 0.95))
    variants.append(make_totem(
        "memphis_bulge", "memphis", "bulging radius schedule", layers
    ))

    # 5. Autumn diminish totem: 8 sections shrinking exponentially,
    # ending in a pyramid finial
    layers = []
    rs = [R * math.pow(0.85, i) for i in range(8)]
    rs.append(0.0)  # pyramid tip
    for i in range(8):
        layers.append((rs[i], rs[i + 1], h * 1.05))
    variants.append(make_totem(
        "autumn_diminish", "autumn", "exponential taper to a pyramid finial", layers
    ))

    # 6. Hokusai wave totem: 7 segments with sinusoidal radius (wave)
    layers = []
    n = 7
    rs = [R * (0.55 + 0.40 * math.sin(2.0 * math.pi * (i / float(n - 1)))) for i in range(n + 1)]
    for i in range(n):
        layers.append((rs[i], rs[i + 1], h * 0.90))
    variants.append(make_totem(
        "hokusai_wave", "hokusai", "sinusoidal (wave) radius schedule", layers
    ))

    return variants


# ── Category B: solomonic stack — rotation chirality ────────────────
# N CylinderMesh(4) stacked with progressive rotation Δθ between each.

def gen_solomonic_stack() -> list[dict]:
    """5 variants — straight column, slight twist, full helix."""
    variants = []
    n_layers = 12
    layer_h = 0.10
    radius = 0.18
    deltas_deg = [0.0, 5.0, 15.0, 30.0, 45.0]
    for dtheta in deltas_deg:
        components = []
        for i in range(n_layers):
            angle_rad = math.radians(dtheta * i)
            # Use a square cross-section CylinderMesh and fake rotation by
            # stacking with positions only — but the "rotation" still won't
            # render without per-component rotation. So we use radial_segments
            # high enough that rotation is moot and rely on stacked square
            # frusta whose corners cycle visually.
            # Actually for Solomonic effect we need the corners to rotate.
            # Compose mode currently only handles position offsets, not
            # rotation. So this helix is degraded — it shows as a stack
            # of identical pieces. We'll render anyway for the gallery.
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": radius,
                    "bottom_radius": radius,
                    "height": layer_h,
                    "radial_segments": 4,
                },
                "transform": {
                    "position": [0, layer_h * 0.5 + i * layer_h, 0],
                    "rotation_degrees": [0, dtheta * i, 0],
                },
            })
        spec = {
            "_comment": f"solomonic stack: {n_layers} layers, Δθ={dtheta}°",
            "primitive": "Composition",
            "shader": "flat",
            "color": [0.78, 0.42, 0.18],
            "components": components,
        }
        variants.append({
            "id": f"helix_d{int(dtheta):02d}",
            "spec": spec,
            "params": {"n_layers": n_layers, "delta_theta_deg": dtheta},
        })
    return variants


# ── Category C: tessellation field — planar grammar ─────────────────
# N×N grid of CylinderMesh(K) prisms tiling the plane.

def gen_tessellation_field() -> list[dict]:
    """Alhambra grammar — plane-filling tessellations + cylinder/torus
    wall combinators.

    First three are pure tilings (K=4 squares, K=6 honeycomb,
    K=3+K=6 trihexagonal). The next three are Alhambra-style wall
    combinators: cylinders + tori arranged to form interlaced
    geometric patterns reminiscent of Islamic architectural ornament.
    """
    variants = []
    height = 0.4
    color = [0.40, 0.60, 0.45]

    # ── K=4: square tiling ─────────────────────────────────────────
    # CylinderMesh(4) without rotation has corners at distance R from
    # the axis at angles 0,90,180,270 — that's a diamond. Rotate 45°
    # to get an axis-aligned square with side L = R*sqrt(2). Spacing
    # between centers = L for edge-to-edge tiling.
    grid_n = 5
    R = 0.22
    L = R * math.sqrt(2.0)  # side length, also the spacing
    components = []
    for i in range(grid_n):
        for j in range(grid_n):
            x = (i - (grid_n - 1) * 0.5) * L
            z = (j - (grid_n - 1) * 0.5) * L
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(R, 4),
                    "bottom_radius": round(R, 4),
                    "height": height,
                    "radial_segments": 4,
                },
                "transform": {
                    "position": [round(x, 5), height * 0.5, round(z, 5)],
                    "rotation_degrees": [0, 45, 0],  # axis-align the square
                },
            })
    variants.append({
        "id": "k04_squares",
        "spec": {
            "_comment": f"{grid_n}x{grid_n} square tiling (K=4, axis-aligned)",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": components,
        },
        "params": {"radial_segments": 4, "tiling": "square",
                   "side_length": round(L, 4), "grid_size": grid_n},
    })

    # ── K=6: hexagonal honeycomb tiling ───────────────────────────
    # CylinderMesh(6) without rotation has vertex at angle 0 (in +X
    # direction). With rotation_degrees=[0, 30, 0] we get a "pointy-Z"
    # hexagon (vertex pointing along +Z). Honeycomb math:
    #   - vertices at distance R from center, side length L = R
    #   - row spacing in Z (along pointy axis): 1.5 * R
    #   - column spacing in X (perpendicular): R * sqrt(3)
    #   - alternate rows offset by half a column in X
    R = 0.18
    rows, cols = 5, 5
    row_dz = 1.5 * R
    col_dx = R * math.sqrt(3.0)
    components = []
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * col_dx
            if r % 2 == 1:
                x += col_dx * 0.5
            z = (r - (rows - 1) * 0.5) * row_dz
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(R, 4),
                    "bottom_radius": round(R, 4),
                    "height": height,
                    "radial_segments": 6,
                },
                "transform": {
                    "position": [round(x, 5), height * 0.5, round(z, 5)],
                    "rotation_degrees": [0, 30, 0],
                },
            })
    variants.append({
        "id": "k06_honeycomb",
        "spec": {
            "_comment": f"{rows}x{cols} hexagonal honeycomb tiling (K=6)",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": components,
        },
        "params": {"radial_segments": 6, "tiling": "honeycomb",
                   "side_length": round(R, 4), "grid": [rows, cols]},
    })

    # ── K=3 + K=6: trihexagonal tiling ────────────────────────────
    # Triangles alone don't tile cleanly with our prim setup, but
    # combined with hexagons in the trihexagonal pattern (3.6.3.6)
    # they fill space perfectly. Each hexagon sits in a honeycomb
    # lattice; six triangles fill the gaps between three hexagons.
    # We render a small patch.
    Rh = 0.16          # hexagon circumradius (vertex distance)
    side = Rh          # for K=6 the side length equals the radius
    Rt = side / math.sqrt(3.0)  # triangle circumradius for the same edge
    rows, cols = 4, 4
    row_dz = 1.5 * Rh
    col_dx = Rh * math.sqrt(3.0)
    components = []
    # Hexagons at honeycomb lattice
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * col_dx
            if r % 2 == 1:
                x += col_dx * 0.5
            z = (r - (rows - 1) * 0.5) * row_dz
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(Rh, 4),
                    "bottom_radius": round(Rh, 4),
                    "height": height,
                    "radial_segments": 6,
                },
                "transform": {
                    "position": [round(x, 5), height * 0.5, round(z, 5)],
                    "rotation_degrees": [0, 30, 0],
                },
            })
    # Triangles in the gaps. In trihexagonal tiling, each hex has
    # 6 triangle neighbours, but each triangle is shared between
    # 3 hexes. For a finite patch we place pairs (up + down) at the
    # "joints" between adjacent hexes within rows.
    for r in range(rows):
        for c in range(cols - 1):
            x_left = (c - (cols - 1) * 0.5) * col_dx
            if r % 2 == 1:
                x_left += col_dx * 0.5
            x_mid = x_left + col_dx * 0.5
            z = (r - (rows - 1) * 0.5) * row_dz
            # Up-pointing triangle (vertex toward +Z)
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(Rt, 4),
                    "bottom_radius": round(Rt, 4),
                    "height": height,
                    "radial_segments": 3,
                },
                "transform": {
                    "position": [round(x_mid, 5), height * 0.5,
                                 round(z + Rh * 0.5, 5)],
                    "rotation_degrees": [0, 90, 0],
                },
            })
            # Down-pointing triangle (vertex toward -Z), rotated 180°
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(Rt, 4),
                    "bottom_radius": round(Rt, 4),
                    "height": height,
                    "radial_segments": 3,
                },
                "transform": {
                    "position": [round(x_mid, 5), height * 0.5,
                                 round(z - Rh * 0.5, 5)],
                    "rotation_degrees": [0, -90, 0],
                },
            })
    variants.append({
        "id": "k36_trihexagonal",
        "spec": {
            "_comment": "trihexagonal tiling: hexagons + triangles fill plane",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": components,
        },
        "params": {"tiling": "trihexagonal", "K": [3, 6]},
    })

    # ── Alhambra grammar: cylinder + torus wall combinators ──────
    # The Islamic geometric tradition combined filled circles
    # (cylinders, from above) with rings (tori) to create patterns
    # where solid centres alternate with open rings, sometimes
    # interlaced. With our two primitives we can render four
    # archetypal patterns.
    plate_h = 0.06   # all elements very thin to read as a wall panel
    panel_color = [0.86, 0.78, 0.62]  # warm sandstone / Alhambra cream
    accent_color = [0.42, 0.58, 0.50]  # Alhambra zellige green-blue
    deep_color = [0.32, 0.20, 0.18]    # carved-shadow brown

    # ── Alhambra 1: rosette field — every honeycomb cell holds a
    # filled cylinder surrounded by a torus ring. Adjacent rings touch.
    rows, cols = 4, 5
    Rh = 0.18  # honeycomb circumradius
    row_dz = 1.5 * Rh
    col_dx = Rh * math.sqrt(3.0)
    cyl_R = Rh * 0.30
    torus_inner = Rh * 0.55
    torus_outer = Rh * 0.95
    components = []
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * col_dx
            if r % 2 == 1:
                x += col_dx * 0.5
            z = (r - (rows - 1) * 0.5) * row_dz
            # Inner filled disc
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(cyl_R, 4),
                    "bottom_radius": round(cyl_R, 4),
                    "height": plate_h,
                    "radial_segments": 24,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": deep_color,
            })
            # Surrounding ring
            components.append({
                "primitive": "TorusMesh",
                "params": {
                    "inner_radius": round(torus_inner, 4),
                    "outer_radius": round(torus_outer, 4),
                    "ring_segments": 32,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": accent_color,
            })
    variants.append({
        "id": "alhambra_rosette_field",
        "spec": {
            "_comment": "Alhambra rosette field: filled disc + torus ring per honeycomb cell",
            "primitive": "Composition", "shader": "flat",
            "color": panel_color, "components": components,
        },
        "params": {"tiling": "rosette", "lattice": "honeycomb",
                   "elements": ["cylinder_inner", "torus_ring"]},
    })

    # ── Alhambra 2: interlace lattice — rows of tori with cylinders
    # at every junction; the cylinders tie the rings together.
    rows, cols = 5, 6
    spacing = 0.32
    torus_inner = spacing * 0.42
    torus_outer = spacing * 0.55
    cyl_R = spacing * 0.16
    components = []
    # Lay tori on a square grid
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * spacing
            z = (r - (rows - 1) * 0.5) * spacing
            components.append({
                "primitive": "TorusMesh",
                "params": {
                    "inner_radius": round(torus_inner, 4),
                    "outer_radius": round(torus_outer, 4),
                    "ring_segments": 24,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": accent_color,
            })
    # Cylinders at the JUNCTIONS between tori (row + col offset by half)
    for r in range(rows - 1):
        for c in range(cols - 1):
            x = (c - (cols - 1) * 0.5 + 0.5) * spacing
            z = (r - (rows - 1) * 0.5 + 0.5) * spacing
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(cyl_R, 4),
                    "bottom_radius": round(cyl_R, 4),
                    "height": plate_h,
                    "radial_segments": 16,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": deep_color,
            })
    variants.append({
        "id": "alhambra_interlace_lattice",
        "spec": {
            "_comment": "Alhambra interlace: torus grid with cylinder studs at junctions",
            "primitive": "Composition", "shader": "flat",
            "color": panel_color, "components": components,
        },
        "params": {"tiling": "interlace", "lattice": "square",
                   "elements": ["torus_grid", "cylinder_junctions"]},
    })

    # ── Alhambra 3: nested concentric — a single cell with a cylinder
    # at centre and three tori at increasing radii, repeated as a field.
    rows, cols = 3, 4
    spacing = 0.50
    cyl_R = spacing * 0.10
    ring_widths = [(0.16, 0.20), (0.26, 0.30), (0.36, 0.40)]  # (inner, outer) as fraction of spacing
    components = []
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * spacing
            z = (r - (rows - 1) * 0.5) * spacing
            # Centre disc
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(cyl_R, 4),
                    "bottom_radius": round(cyl_R, 4),
                    "height": plate_h,
                    "radial_segments": 24,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": deep_color,
            })
            # Three concentric rings
            for ri, (inner_f, outer_f) in enumerate(ring_widths):
                ring_color = accent_color if ri % 2 == 0 else panel_color
                components.append({
                    "primitive": "TorusMesh",
                    "params": {
                        "inner_radius": round(spacing * inner_f, 4),
                        "outer_radius": round(spacing * outer_f, 4),
                        "ring_segments": 32,
                    },
                    "transform": {"position": [round(x, 5), plate_h * 0.5 + ri * 0.001,
                                                round(z, 5)]},
                    "color": ring_color,
                })
    variants.append({
        "id": "alhambra_nested_concentric",
        "spec": {
            "_comment": "Alhambra nested concentric: cylinder + 3 tori per cell, square lattice",
            "primitive": "Composition", "shader": "flat",
            "color": panel_color, "components": components,
        },
        "params": {"tiling": "nested", "rings_per_cell": 3,
                   "elements": ["cylinder_centre", "torus_x3"]},
    })

    # ── Alhambra 4: star-and-cross — 12-pointed star approximation
    # using overlapping torus rings at three rotations + central
    # cylinder, on a triangular lattice.
    rows, cols = 3, 4
    spacing = 0.42
    cyl_R = spacing * 0.10
    star_inner = spacing * 0.32
    star_outer = spacing * 0.36
    components = []
    for r in range(rows):
        for c in range(cols):
            x = (c - (cols - 1) * 0.5) * spacing
            if r % 2 == 1:
                x += spacing * 0.5
            z = (r - (rows - 1) * 0.5) * spacing * 0.866  # √3/2 for equilateral
            # Centre disc
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(cyl_R, 4),
                    "bottom_radius": round(cyl_R, 4),
                    "height": plate_h,
                    "radial_segments": 12,
                },
                "transform": {"position": [round(x, 5), plate_h * 0.5, round(z, 5)]},
                "color": deep_color,
            })
            # Three rotated tori (creating 6-fold star approximation)
            for k in range(3):
                rot_y = k * 60.0
                components.append({
                    "primitive": "TorusMesh",
                    "params": {
                        "inner_radius": round(star_inner, 4),
                        "outer_radius": round(star_outer, 4),
                        "ring_segments": 6,  # hex-shaped torus → star points
                    },
                    "transform": {
                        "position": [round(x, 5), plate_h * 0.5 + k * 0.001,
                                      round(z, 5)],
                        "rotation_degrees": [0, rot_y, 0],
                    },
                    "color": accent_color if k == 0 else panel_color,
                })
    variants.append({
        "id": "alhambra_star_and_cross",
        "spec": {
            "_comment": "Alhambra star-and-cross: 6-segment tori rotated 0/60/120deg → 6-pointed star",
            "primitive": "Composition", "shader": "flat",
            "color": panel_color, "components": components,
        },
        "params": {"tiling": "star_and_cross", "lattice": "triangular",
                   "elements": ["cylinder_centre", "torus_x3_rotated"]},
    })

    return variants


# ── Category D: forced-perspective stacks ───────────────────────────
# Stack of frusta with progressively shrinking radii — the eye reads
# fake depth where there is none. Compare linear / exponential /
# anti-perspective tapers.

def gen_forced_perspective() -> list[dict]:
    """5 variants of stacked frusta playing tricks with the eye."""
    variants = []
    n_layers = 8
    layer_h = 0.12
    base_r = 0.35

    schedules = [
        # (id, label, taper_function)
        ("linear", "linear taper",
         lambda i, n: 1.0 - (i / float(n))),
        ("exp_strong", "exponential taper (forced perspective)",
         lambda i, n: math.pow(0.62, i)),
        ("exp_weak", "weak exponential",
         lambda i, n: math.pow(0.85, i)),
        ("inverted", "anti-perspective (top-heavy)",
         lambda i, n: 0.2 + 0.9 * (i / float(n))),
        ("zigzag", "zigzag depth-illusion",
         lambda i, n: 1.0 - 0.7 * (i / float(n)) + 0.18 * math.sin(i * 1.4)),
    ]

    for sched_id, label, taper in schedules:
        components = []
        y_cursor = 0.0
        for i in range(n_layers):
            r_top = base_r * taper(i + 1, n_layers)
            r_bot = base_r * taper(i, n_layers)
            r_top = max(r_top, 0.01)
            r_bot = max(r_bot, 0.01)
            components.append({
                "primitive": "CylinderMesh",
                "params": {
                    "top_radius": round(r_top, 4),
                    "bottom_radius": round(r_bot, 4),
                    "height": layer_h,
                    "radial_segments": 4,
                },
                "transform": {"position": [0, y_cursor + layer_h * 0.5, 0]},
            })
            y_cursor += layer_h
        spec = {
            "_comment": f"forced-perspective stack: {label}",
            "primitive": "Composition",
            "shader": "flat",
            "color": [0.55, 0.50, 0.62],
            "components": components,
        }
        variants.append({
            "id": f"persp_{sched_id}",
            "spec": spec,
            "params": {"n_layers": n_layers, "schedule": sched_id, "label": label},
        })
    return variants


# ── Category E: recursive primitives — branching trees ──────────────
# A trunk + N branches angled outward; each branch is itself a smaller
# trunk + branches. Depth controls compounding complexity.

def gen_recursive_branching() -> list[dict]:
    """4 variants showing depth=1..4 branching."""
    variants = []
    branches_per_node = 3
    branch_angle_deg = 30.0  # tilt each child relative to its parent's axis
    shrink = 0.62
    base_h = 0.45
    base_r = 0.06

    def rot_axis_angle(axis: list[float], angle: float) -> list[list[float]]:
        """3x3 rotation matrix (Rodrigues) around unit axis by angle radians."""
        x, y, z = axis
        c, s = math.cos(angle), math.sin(angle)
        C = 1 - c
        return [
            [c + x*x*C,    x*y*C - z*s, x*z*C + y*s],
            [y*x*C + z*s,  c + y*y*C,   y*z*C - x*s],
            [z*x*C - y*s,  z*y*C + x*s, c + z*z*C],
        ]

    def matvec(M: list[list[float]], v: list[float]) -> list[float]:
        return [sum(M[i][j] * v[j] for j in range(3)) for i in range(3)]

    def vlen(v: list[float]) -> float:
        return math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])

    def normalize(v: list[float]) -> list[float]:
        n = vlen(v) or 1.0
        return [v[0]/n, v[1]/n, v[2]/n]

    def cross(a: list[float], b: list[float]) -> list[float]:
        return [
            a[1]*b[2] - a[2]*b[1],
            a[2]*b[0] - a[0]*b[2],
            a[0]*b[1] - a[1]*b[0],
        ]

    def perp_axis(d: list[float]) -> list[float]:
        """Return a unit vector perpendicular to d."""
        ref = [0.0, 1.0, 0.0] if abs(d[1]) < 0.95 else [1.0, 0.0, 0.0]
        return normalize(cross(d, ref))

    def dir_to_euler_yxz(d: list[float]) -> list[float]:
        """Euler angles (deg, YXZ order matching primitive_dna's matrix) so
        that local +Y maps to direction d. We solve for yaw (Y) and pitch
        (X) — roll (Z) stays 0."""
        d = normalize(d)
        # The matrix R = Ry(yaw) * Rx(pitch) * Rz(0) maps local +Y to:
        #   (sin(yaw)*sin(pitch), cos(pitch), cos(yaw)*sin(pitch))
        # Solve for pitch and yaw given d = (dx, dy, dz):
        #   cos(pitch) = dy
        #   sin(pitch) = sqrt(1 - dy*dy)
        # Wait, this is wrong because the matrix in primitive_dna uses
        # YXZ multiplication (Ry * Rx * Rz). Let me derive what +Y maps to.
        # Local +Y = (0, 1, 0). Apply Rz first (no-op), then Rx, then Ry.
        # After Rx(pitch): (0, cos(pitch), sin(pitch))
        # After Ry(yaw):   (sin(yaw)*sin(pitch), cos(pitch), cos(yaw)*sin(pitch))
        # So: dy = cos(pitch); dx = sin(yaw) * sin(pitch); dz = cos(yaw) * sin(pitch)
        dx, dy, dz = d
        pitch = math.acos(max(-1.0, min(1.0, dy)))
        sp = math.sin(pitch)
        if abs(sp) < 1e-6:
            yaw = 0.0
        else:
            yaw = math.atan2(dx, dz)
        # Note: primitive_dna's _format_transform3d takes [rx, ry, rz] in
        # degrees and rotates Ry*Rx*Rz. So we return [pitch_deg, yaw_deg, 0].
        return [math.degrees(pitch), math.degrees(yaw), 0.0]

    def grow(parent_top: list[float], parent_dir: list[float],
             length: float, bottom_r: float, depth: int,
             out: list, is_root: bool = False):
        """Append a cylinder from parent_top going in parent_dir.

        Face-meeting principle (the L-system trick):
        - Each segment's bottom_radius is set by the JOINT it attaches to
        - Each segment's top_radius tapers by `taper_ratio`
        - At every joint we place a SphereMesh with radius = joint radius;
          this hides the angular discontinuity between segments meeting at
          different angles. Without the sphere, the segments' flat
          end-faces would intersect at non-perpendicular angles and leave
          a visible gap. With it, each segment plunges into a sphere that
          absorbs both, producing a clean L-system-style joint.
        """
        taper_ratio = 0.78  # top_r / bottom_r within a single segment
        top_r = bottom_r * taper_ratio
        end = [parent_top[i] + parent_dir[i] * length for i in range(3)]
        mid = [parent_top[i] + parent_dir[i] * length * 0.5 for i in range(3)]
        rot = dir_to_euler_yxz(parent_dir)

        # Joint sphere at the BASE of this segment (only when we're a child
        # of a previous segment — root has no joint below it). Sphere
        # radius matches the bottom of this segment so it absorbs the
        # cylinder's bottom face cleanly even when the cylinder is tilted.
        if not is_root:
            out.append({
                "primitive": "SphereMesh",
                "params": {
                    "radius": round(bottom_r * 1.02, 4),
                    "height": round(bottom_r * 2.04, 4),
                    "radial_segments": 12,
                    "rings": 6,
                },
                "transform": {
                    "position": [round(p, 5) for p in parent_top],
                },
            })

        # The cylinder segment itself
        out.append({
            "primitive": "CylinderMesh",
            "params": {
                "top_radius": round(top_r, 4),
                "bottom_radius": round(bottom_r, 4),
                "height": round(length, 4),
                "radial_segments": 8,
            },
            "transform": {
                "position": [round(m, 5) for m in mid],
                "rotation_degrees": [round(r, 4) for r in rot],
            },
        })

        if depth <= 0:
            # Cap the tip with a small sphere so terminals don't show flat circles
            out.append({
                "primitive": "SphereMesh",
                "params": {
                    "radius": round(top_r * 1.02, 4),
                    "height": round(top_r * 2.04, 4),
                    "radial_segments": 10,
                    "rings": 5,
                },
                "transform": {
                    "position": [round(e, 5) for e in end],
                },
            })
            return

        # Children: bottom_r equals THIS segment's top_r → face continuity
        child_bottom_r = top_r
        perp = perp_axis(parent_dir)
        tilt_R = rot_axis_angle(perp, math.radians(branch_angle_deg))
        tilted = matvec(tilt_R, parent_dir)
        for k in range(branches_per_node):
            spread_R = rot_axis_angle(
                normalize(parent_dir),
                k * (2.0 * math.pi / branches_per_node)
            )
            child_dir = normalize(matvec(spread_R, tilted))
            grow(end, child_dir,
                 length * shrink, child_bottom_r, depth - 1, out,
                 is_root=False)

    for max_depth in [1, 2, 3, 4]:
        components: list = []
        # Trunk goes straight up
        grow([0, 0, 0], parent_dir=[0.0, 1.0, 0.0],
             length=base_h, bottom_r=base_r,
             depth=max_depth, out=components, is_root=True)
        spec = {
            "_comment": f"recursive branching tree, depth={max_depth}",
            "primitive": "Composition",
            "shader": "flat",
            "color": [0.42, 0.30, 0.18],
            "components": components,
        }
        variants.append({
            "id": f"tree_d{max_depth}",
            "spec": spec,
            "params": {"depth": max_depth, "branches": branches_per_node,
                       "shrink": shrink, "n_components": len(components)},
        })
    return variants


# ── Category F: meeting-face rules ──────────────────────────────────
# A host primitive (cube) + a guest primitive attached at different
# locations. Some meetings are "clean" (face-to-face, axis-aligned);
# others are "broken" (face-to-edge, face-to-vertex, off-axis).

def gen_meeting_faces() -> list[dict]:
    """6 variants showing valid vs broken primitive meetings."""
    variants = []
    host_size = 0.4  # cube edge length
    guest_size = 0.22

    def host_component() -> dict:
        return {
            "primitive": "BoxMesh",
            "params": {"size": [host_size, host_size, host_size]},
            "transform": {"position": [0, host_size * 0.5, 0]},
        }

    cases = [
        # (id, label, guest_position_offset, guest_rot_deg, is_clean)
        ("clean_top", "face-to-face (top, axis-aligned)",
         [0, host_size + guest_size * 0.5, 0],
         [0, 0, 0], True),
        ("clean_side", "face-to-face (side, axis-aligned)",
         [host_size * 0.5 + guest_size * 0.5, host_size * 0.5, 0],
         [0, 0, 0], True),
        ("face_off_center", "face-to-face but off-center",
         [host_size * 0.25, host_size + guest_size * 0.5, host_size * 0.2],
         [0, 0, 0], False),
        ("edge_meeting", "face-to-edge (broken)",
         [host_size * 0.5 + guest_size * 0.4, host_size + guest_size * 0.3, 0],
         [0, 0, 0], False),
        ("vertex_meeting", "face-to-vertex (very broken)",
         [host_size * 0.5 + guest_size * 0.4,
          host_size + guest_size * 0.4,
          host_size * 0.5 + guest_size * 0.4],
         [0, 0, 0], False),
        ("rotated_45", "face-to-face but rotated 45° (broken silhouette)",
         [0, host_size + guest_size * 0.5, 0],
         [0, 45, 0], False),
    ]

    for cid, label, gpos, grot, clean in cases:
        components = [
            host_component(),
            {
                "primitive": "BoxMesh",
                "params": {"size": [guest_size, guest_size, guest_size]},
                "transform": {
                    "position": gpos,
                    "rotation_degrees": grot,
                },
            },
        ]
        spec = {
            "_comment": f"meeting-faces: {label} ({'clean' if clean else 'broken'})",
            "primitive": "Composition",
            "shader": "flat",
            "color": [0.70, 0.60, 0.42] if clean else [0.74, 0.40, 0.36],
            "components": components,
        }
        variants.append({
            "id": cid,
            "spec": spec,
            "params": {"label": label, "is_clean": clean},
        })
    return variants


# ── Category G: negative-space pairings ─────────────────────────────
# Arrangements where the EMPTY SPACE between primitives is the
# intended shape. Without CSG we can't carve voids out of solids,
# but we can frame voids by surrounding them.

def gen_negative_space() -> list[dict]:
    """6 variants where the void between primitives is the artifact."""
    variants = []
    color = [0.55, 0.58, 0.66]

    def box(size_xyz: list[float], pos: list[float]) -> dict:
        return {
            "primitive": "BoxMesh",
            "params": {"size": size_xyz},
            "transform": {"position": pos},
        }

    def cyl(r: float, h: float, pos: list[float], segs: int = 12) -> dict:
        return {
            "primitive": "CylinderMesh",
            "params": {
                "top_radius": r, "bottom_radius": r, "height": h,
                "radial_segments": segs,
            },
            "transform": {"position": pos},
        }

    # 1. Corner pillars — 4 vertical cylinders frame an empty cube of air
    pillars: list = []
    pad = 0.32
    h = 0.5
    r = 0.06
    for sx in (-1, 1):
        for sz in (-1, 1):
            pillars.append(cyl(r, h, [sx * pad, h * 0.5, sz * pad]))
    variants.append({
        "id": "corner_pillars",
        "spec": {
            "_comment": "4 corner pillars frame an empty volume",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": pillars,
        },
        "params": {"void_shape": "cubical", "n_pillars": 4},
    })

    # 2. Square frame — 4 thin boxes arranged as a ring; the center hole
    # is the artifact. Lying flat so the void reads from top.
    frame: list = []
    side = 0.8
    bar_w = 0.08
    bar_t = 0.08
    # top bar (along X, at +Z)
    frame.append(box([side, bar_t, bar_w], [0, bar_t * 0.5, side * 0.5 - bar_w * 0.5]))
    # bottom bar
    frame.append(box([side, bar_t, bar_w], [0, bar_t * 0.5, -side * 0.5 + bar_w * 0.5]))
    # left bar (along Z, at -X)
    frame.append(box([bar_w, bar_t, side - 2 * bar_w], [-side * 0.5 + bar_w * 0.5, bar_t * 0.5, 0]))
    # right bar
    frame.append(box([bar_w, bar_t, side - 2 * bar_w], [side * 0.5 - bar_w * 0.5, bar_t * 0.5, 0]))
    variants.append({
        "id": "square_frame",
        "spec": {
            "_comment": "square ring of boxes; center hole is the artifact",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": frame,
        },
        "params": {"void_shape": "square", "side": side},
    })

    # 3. Aperture — ring of small cylinders forming a circle; center
    # void reads as a circular opening.
    aperture: list = []
    n_cyls = 12
    ring_r = 0.32
    for i in range(n_cyls):
        ang = 2.0 * math.pi * i / n_cyls
        x = ring_r * math.cos(ang)
        z = ring_r * math.sin(ang)
        aperture.append(cyl(0.05, 0.4, [x, 0.2, z]))
    variants.append({
        "id": "aperture",
        "spec": {
            "_comment": f"{n_cyls} cylinders form a circle around a void",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": aperture,
        },
        "params": {"void_shape": "circular", "n_cylinders": n_cyls},
    })

    # 4. Bracket pair — two L-shapes facing each other; gap between is
    # the slot/void.
    brackets: list = []
    arm_long = 0.4
    arm_short = 0.18
    arm_t = 0.06
    gap = 0.18
    for sx in (-1, 1):
        # Vertical arm
        brackets.append(box(
            [arm_t, arm_long, arm_t],
            [sx * (gap * 0.5 + arm_t * 0.5), arm_long * 0.5, 0]
        ))
        # Horizontal arm at top, pointing inward
        brackets.append(box(
            [arm_short, arm_t, arm_t],
            [sx * (gap * 0.5 + arm_t + arm_short * 0.5 - arm_t * 0.5),
             arm_long - arm_t * 0.5, 0]
        ))
    variants.append({
        "id": "bracket_pair",
        "spec": {
            "_comment": "two L-brackets framing a vertical slot",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": brackets,
        },
        "params": {"void_shape": "slot", "gap": gap},
    })

    # 5. Niche — row of pillars with the center two omitted; the gap
    # in the middle is the niche.
    niche: list = []
    n_pillars = 7
    pillar_h = 0.55
    pillar_r = 0.05
    spacing = 0.13
    omit = {3}  # center
    for i in range(n_pillars):
        if i in omit:
            continue
        x = (i - (n_pillars - 1) * 0.5) * spacing
        niche.append(cyl(pillar_r, pillar_h, [x, pillar_h * 0.5, 0]))
    variants.append({
        "id": "niche_in_row",
        "spec": {
            "_comment": f"row of {n_pillars} pillars with center omitted — niche",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": niche,
        },
        "params": {"void_shape": "niche", "omitted": sorted(omit)},
    })

    # 6. Tower interior — 4 walls of a small tower; viewed from above
    # the empty interior is the void.
    tower: list = []
    inner = 0.45
    wall_t = 0.06
    wall_h = 0.5
    # +X and -X walls (front/back)
    tower.append(box([wall_t, wall_h, inner + 2 * wall_t],
                     [inner * 0.5 + wall_t * 0.5, wall_h * 0.5, 0]))
    tower.append(box([wall_t, wall_h, inner + 2 * wall_t],
                     [-inner * 0.5 - wall_t * 0.5, wall_h * 0.5, 0]))
    # +Z and -Z walls (sides), shorter to leave wall gap visible
    tower.append(box([inner, wall_h, wall_t],
                     [0, wall_h * 0.5, inner * 0.5 + wall_t * 0.5]))
    tower.append(box([inner, wall_h, wall_t],
                     [0, wall_h * 0.5, -inner * 0.5 - wall_t * 0.5]))
    variants.append({
        "id": "tower_interior",
        "spec": {
            "_comment": "4 walls frame an interior void; top view shows the room",
            "primitive": "Composition", "shader": "flat",
            "color": color, "components": tower,
        },
        "params": {"void_shape": "room", "inner_size": inner},
    })

    return variants


# ── Generator dispatch ───────────────────────────────────────────────

CATEGORIES: dict[str, dict[str, Any]] = {
    "cube_to_pyramid": {
        "title": "Cube ↔ Pyramid morph",
        "essence": "single float controls a 1-parameter family of shapes — pyramid, frustum, cube, mushroom cap",
        "primary_axis": "top_bottom_ratio",
        "generator": gen_cube_to_pyramid,
    },
    "totem_pole": {
        "title": "Totem poles (edge-continuous + per-segment colour)",
        "essence": "vertical multi-segment columns where every joint has matching radii (180-flip continuity) and each segment is a different palette colour — the principle from Color_Pillar's pillarcolorcollection but stacking colours within one column",
        "primary_axis": "palette",
        "generator": gen_totem_pole,
    },
    "solomonic_stack": {
        "title": "Solomonic stacks",
        "essence": "N primitives stacked with progressive rotation Δθ between layers — straight pillar at 0°, helical at 30°+",
        "primary_axis": "delta_theta_deg",
        "generator": gen_solomonic_stack,
    },
    "tessellation_field": {
        "title": "Tessellation fields & Alhambra grammar",
        "essence": "first 3 are pure tilings (square, honeycomb, trihexagonal); next 4 are Alhambra wall combinators of cylinder + torus — rosettes, interlace, nested concentric rings, star-and-cross",
        "primary_axis": "tiling",
        "generator": gen_tessellation_field,
    },
    "forced_perspective": {
        "title": "Forced-perspective stacks",
        "essence": "stacks of frusta with engineered taper schedules — eye reads fake depth where none exists",
        "primary_axis": "schedule",
        "generator": gen_forced_perspective,
    },
    "recursive_branching": {
        "title": "Recursive primitives",
        "essence": "trees where each branch is itself a smaller tree — depth controls compounding complexity",
        "primary_axis": "depth",
        "generator": gen_recursive_branching,
    },
    "meeting_faces": {
        "title": "Meeting-face rules",
        "essence": "which face of A meets which face of B — face-to-face is clean, face-to-edge or rotated breaks the silhouette",
        "primary_axis": "label",
        "generator": gen_meeting_faces,
    },
    "negative_space": {
        "title": "Negative-space pairings",
        "essence": "compositions where the empty space between primitives is the artifact — frames, brackets, apertures, niches",
        "primary_axis": "void_shape",
        "generator": gen_negative_space,
    },
}


def cmd_sweep(args) -> int:
    if not Path(GODOT_EXE).exists():
        print(f"  !! Godot exe not found: {GODOT_EXE}", file=sys.stderr)
        return 1

    GRAMMAR_RUNS.mkdir(parents=True, exist_ok=True)
    SPECS_DIR.mkdir(parents=True, exist_ok=True)

    cat_filter = args.category
    selected = (
        [(k, v) for k, v in CATEGORIES.items() if k == cat_filter]
        if cat_filter else list(CATEGORIES.items())
    )

    if not selected:
        print(f"  !! unknown category '{cat_filter}'", file=sys.stderr)
        print(f"     known: {', '.join(CATEGORIES.keys())}", file=sys.stderr)
        return 1

    # Start from existing manifest if present so a filtered sweep
    # only updates the swept category and preserves the others.
    existing_manifest_path = GRAMMAR_RUNS / "manifest.json"
    if existing_manifest_path.exists():
        try:
            existing = json.loads(existing_manifest_path.read_text(encoding="utf-8"))
            manifest_categories = dict(existing.get("categories", {}))
        except Exception:
            manifest_categories = {}
    else:
        manifest_categories = {}

    for cat_id, cat in selected:
        print(f"\n=== {cat_id} ===")
        variants = cat["generator"]()
        manifest_variants = []

        cat_dir = GRAMMAR_RUNS / cat_id
        cat_dir.mkdir(parents=True, exist_ok=True)

        for v in variants:
            vid = v["id"]
            promote_token = f"grammar_{cat_id}_{vid}"
            spec_path = SPECS_DIR / f"{promote_token}.compose.json"
            spec_path.write_text(json.dumps(v["spec"], indent=2), encoding="utf-8")

            # Promote via primitive_dna.py compose mode
            cmd = [
                sys.executable, str(REPO / "tools/primitive_dna.py"),
                "promote",
                "--as", promote_token,
                "--compose", str(spec_path.relative_to(REPO)).replace("\\", "/"),
                "--force",
            ]
            r = subprocess.run(cmd, capture_output=True, text=True,
                               cwd=str(REPO))
            if r.returncode != 0:
                print(f"    XX {vid} promote failed: {r.stderr[-300:]}",
                      file=sys.stderr)
                continue

            # Capture (multi-angle, artifact mode)
            cap_cmd = [
                GODOT_EXE,
                "--path", str(REPO),
                "--xr-mode", "off",
                "--no-window",
                "--script", CAPTURE_SCRIPT, "--",
                "--mode=artifact", f"--target={promote_token}",
            ]
            cap = subprocess.run(cap_cmd, capture_output=True, text=True,
                                 cwd=str(REPO), timeout=120)

            # Copy from godot user_data → grammar-runs/<cat>/<vid>/
            user_data = (
                Path(os.environ.get("APPDATA", ""))
                / "Godot/app_userdata/Ada Research Zero One/multi_shots"
                / promote_token
            )
            v_dir = cat_dir / vid
            v_dir.mkdir(parents=True, exist_ok=True)
            n_copied = 0
            for angle in ("front", "left", "right", "top"):
                src = user_data / f"{angle}.png"
                if src.exists():
                    shutil.copy(str(src), str(v_dir / f"{angle}.png"))
                    n_copied += 1
            if n_copied > 0:
                print(f"    OK {vid} ({n_copied} angles)")
                manifest_variants.append({
                    "id": vid,
                    "params": v["params"],
                    "n_components": len(v["spec"]["components"]),
                    "captures": [a for a in ("front","left","right","top")
                                 if (v_dir / f"{a}.png").exists()],
                })
            else:
                print(f"    XX {vid} no captures saved")

        manifest_categories[cat_id] = {
            "title": cat["title"],
            "essence": cat["essence"],
            "primary_axis": cat["primary_axis"],
            "variants": manifest_variants,
        }

    # Write manifest — re-order categories to match CATEGORIES dict
    # so the gallery flows in canonical (simple-to-complex) order
    # regardless of which categories were swept last.
    ordered = {cid: manifest_categories[cid]
               for cid in CATEGORIES.keys()
               if cid in manifest_categories}
    # Keep any unknown legacy categories at the end (defensive).
    for cid in manifest_categories:
        if cid not in ordered:
            ordered[cid] = manifest_categories[cid]
    manifest = {
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "categories": ordered,
    }
    manifest_path = GRAMMAR_RUNS / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    total = sum(len(c["variants"]) for c in manifest_categories.values())
    print(f"\n  manifest: {manifest_path}")
    print(f"  total variants captured: {total}")
    print(f"  view: http://localhost:3003/grammar-dna")
    return 0


def cmd_list(args) -> int:
    print(f"  {'category':25s}  {'title':35s}  {'variants'}")
    for cat_id, cat in CATEGORIES.items():
        n = len(cat["generator"]())
        print(f"  {cat_id:25s}  {cat['title']:35s}  {n}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="grammar_dna")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_sweep = sub.add_parser("sweep", help="generate + capture grammar variants")
    p_sweep.add_argument("category", nargs="?", default=None,
                         help=f"optional category filter ({', '.join(CATEGORIES.keys())})")
    p_sweep.set_defaults(func=cmd_sweep)
    p_list = sub.add_parser("list", help="list known categories")
    p_list.set_defaults(func=cmd_list)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
