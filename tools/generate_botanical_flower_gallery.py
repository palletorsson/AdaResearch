#!/usr/bin/env python3
"""
Generate botanical-flower-gallery DNA configs.

Mirrors the /dna substrate-gallery pattern (one config JSON + one PNG
per variant, manifest aggregating). Five archetype clusters × ~12
variants each = ~60 BotanicalFlower variants, deterministically seeded.

Pipeline:
  1. This script writes ada_encyclopedia/public/botanical-flower-gallery/
     bf_*.json (per-variant configs) + manifest.json
  2. commons/testing/botanical_flower_gallery_lab.gd reads each config,
     spawns BotanicalFlower with it, captures bf_*.png
  3. /dna picks up the new gallery once we add it to GALLERIES

Run: python tools/generate_botanical_flower_gallery.py
"""

from __future__ import annotations

import json
import math
import os
import random
import sys
from pathlib import Path

# Output dir (encyclopedia public so the gallery is web-served).
ENCYCLOPEDIA = Path(os.environ.get(
    "ADA_ENCYCLOPEDIA_PATH",
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia",
))
OUT_DIR = ENCYCLOPEDIA / "public" / "botanical-flower-gallery"


# Enums (mirror commons/flora/botanical_flower.gd).
PHYLLOTAXIS = {"ALTERNATE": 0, "OPPOSITE": 1, "WHORLED": 2, "ROSETTE": 3, "SPIRAL": 4}
LEAF_SHAPE = {"LINEAR": 0, "LANCEOLATE": 1, "ELLIPTIC": 2, "OVATE": 3,
              "OBOVATE": 4, "CORDATE": 5, "SPATULATE": 6, "RENIFORM": 7}
FLOWER_FORM = {"OPEN": 0, "BELL": 1, "TUBULAR": 2, "FUNNEL": 3,
               "BOWL": 4, "COMPOSITE": 5}
INFLORESCENCE = {"SINGLE": 0, "RACEME": 1, "SPIKE": 2, "UMBEL": 3,
                 "HEAD": 4, "CYME": 5, "PANICLE": 6}


def hsv_to_rgb(h: float, s: float, v: float) -> list[float]:
    """HSV (0..1, 0..1, 0..1) → [r, g, b] floats. Godot reads list."""
    h = h % 1.0
    i = int(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    i = i % 6
    if i == 0: r, g, b = v, t, p
    elif i == 1: r, g, b = q, v, p
    elif i == 2: r, g, b = p, v, t
    elif i == 3: r, g, b = p, q, v
    elif i == 4: r, g, b = t, p, v
    else: r, g, b = v, p, q
    return [round(r, 4), round(g, 4), round(b, 4)]


# ── Archetypes ───────────────────────────────────────────────────────

def cluster_tiny_meadow(rng: random.Random, idx: int) -> dict:
    """Short-stem wildflowers, single small flower, varied warm/cool hues."""
    hue = rng.uniform(0.0, 1.0)  # any color
    sat = rng.uniform(0.5, 0.95)
    return {
        "stem_height": rng.uniform(0.06, 0.18),
        "stem_radius": 0.003,
        "stem_curve": rng.uniform(0.0, 0.3),
        "pendant": False,
        "leaf_count": rng.randint(2, 5),
        "leaf_shape": rng.choice([LEAF_SHAPE["LINEAR"], LEAF_SHAPE["LANCEOLATE"], LEAF_SHAPE["OVATE"]]),
        "phyllotaxis": rng.choice([PHYLLOTAXIS["ROSETTE"], PHYLLOTAXIS["OPPOSITE"]]),
        "leaf_length": rng.uniform(0.04, 0.10),
        "leaf_width": rng.uniform(0.015, 0.04),
        "flower_form": rng.choice([FLOWER_FORM["OPEN"], FLOWER_FORM["BOWL"]]),
        "petal_count": rng.choice([4, 5, 5, 6]),
        "petal_length": rng.uniform(0.025, 0.05),
        "petal_width": rng.uniform(0.012, 0.025),
        "petal_color": hsv_to_rgb(hue, sat, rng.uniform(0.7, 0.95)),
        "petal_opening": rng.uniform(45.0, 75.0),
        "petal_curve": rng.uniform(0.05, 0.3),
        "stamen_count": rng.choice([3, 5, 8]),
        "stamen_color": hsv_to_rgb((hue + 0.1) % 1.0, 0.7, 0.95),
        "inflorescence": INFLORESCENCE["SINGLE"],
        "flower_count": 1,
        "overall_scale": rng.uniform(1.4, 1.8),
        "lod": 2,
        "seed": idx * 31 + 1,
    }


def cluster_pendant_bell(rng: random.Random, idx: int) -> dict:
    """Bluebell-family — pendant flower heads, bell or tubular, dramatic stem curve."""
    hue = rng.choice([0.65, 0.62, 0.7, 0.85, 0.92, 0.0])  # blues + magentas + reds
    return {
        "stem_height": rng.uniform(0.18, 0.32),
        "stem_curve": rng.uniform(0.4, 0.85),
        "stem_radius": rng.uniform(0.003, 0.006),
        "pendant": True,
        "leaf_count": rng.randint(2, 4),
        "leaf_shape": rng.choice([LEAF_SHAPE["LINEAR"], LEAF_SHAPE["LANCEOLATE"]]),
        "phyllotaxis": PHYLLOTAXIS["ROSETTE"],
        "leaf_length": rng.uniform(0.10, 0.18),
        "leaf_width": rng.uniform(0.01, 0.022),
        "flower_form": rng.choice([FLOWER_FORM["BELL"], FLOWER_FORM["TUBULAR"], FLOWER_FORM["BELL"]]),
        "petal_count": rng.choice([5, 6, 6, 8]),
        "petal_length": rng.uniform(0.03, 0.06),
        "petal_width": rng.uniform(0.014, 0.022),
        "petal_color": hsv_to_rgb(hue, rng.uniform(0.55, 0.85), rng.uniform(0.55, 0.85)),
        "petal_opening": rng.uniform(10.0, 30.0),
        "petal_curve": rng.uniform(0.4, 0.8),
        "inflorescence": rng.choice([INFLORESCENCE["RACEME"], INFLORESCENCE["UMBEL"], INFLORESCENCE["SINGLE"]]),
        "flower_count": rng.randint(1, 7),
        "flower_spacing": rng.uniform(0.025, 0.05),
        "overall_scale": rng.uniform(1.4, 2.0),
        "lod": 2,
        "seed": idx * 37 + 7,
    }


def cluster_composite_disk(rng: random.Random, idx: int) -> dict:
    """Daisy / sunflower — composite head, lots of ray petals, central disk."""
    hue = rng.choice([0.13, 0.10, 0.08, 0.0, 0.92, 0.55, 0.7])  # yellows, oranges, whites, lavenders
    sat = rng.uniform(0.4, 0.95)
    return {
        "stem_height": rng.uniform(0.15, 0.35),
        "stem_curve": rng.uniform(0.0, 0.15),
        "stem_radius": rng.uniform(0.005, 0.01),
        "pendant": False,
        "leaf_count": rng.randint(3, 7),
        "leaf_shape": rng.choice([LEAF_SHAPE["LANCEOLATE"], LEAF_SHAPE["OVATE"], LEAF_SHAPE["SPATULATE"]]),
        "phyllotaxis": rng.choice([PHYLLOTAXIS["ALTERNATE"], PHYLLOTAXIS["OPPOSITE"]]),
        "leaf_length": rng.uniform(0.06, 0.14),
        "leaf_width": rng.uniform(0.025, 0.06),
        "flower_form": FLOWER_FORM["COMPOSITE"],
        "petal_count": rng.choice([8, 12, 15, 21, 24]),
        "petal_length": rng.uniform(0.04, 0.08),
        "petal_width": rng.uniform(0.012, 0.02),
        "petal_color": hsv_to_rgb(hue, sat, rng.uniform(0.85, 0.99)),
        "petal_opening": rng.uniform(70.0, 90.0),
        "petal_curve": rng.uniform(0.05, 0.25),
        "stamen_count": rng.randint(20, 50),
        "stamen_color": hsv_to_rgb(0.10, 0.9, 0.6),  # disk = brown/yellow
        "inflorescence": INFLORESCENCE["SINGLE"],
        "flower_count": 1,
        "overall_scale": rng.uniform(1.5, 2.3),
        "lod": 2,
        "seed": idx * 41 + 11,
    }


def cluster_tropical_spire(rng: random.Random, idx: int) -> dict:
    """Tall raceme/panicle/spike — many small flowers up a single tall stem."""
    hue = rng.choice([0.92, 0.85, 0.7, 0.55, 0.13, 0.0, 0.25])
    return {
        "stem_height": rng.uniform(0.45, 0.95),
        "stem_curve": rng.uniform(0.0, 0.15),
        "stem_radius": rng.uniform(0.008, 0.014),
        "pendant": False,
        "leaf_count": rng.randint(4, 8),
        "leaf_shape": rng.choice([LEAF_SHAPE["LANCEOLATE"], LEAF_SHAPE["LINEAR"]]),
        "phyllotaxis": rng.choice([PHYLLOTAXIS["ALTERNATE"], PHYLLOTAXIS["SPIRAL"]]),
        "leaf_length": rng.uniform(0.10, 0.20),
        "leaf_width": rng.uniform(0.02, 0.05),
        "flower_form": rng.choice([FLOWER_FORM["OPEN"], FLOWER_FORM["BELL"], FLOWER_FORM["BOWL"]]),
        "petal_count": rng.choice([4, 5, 6]),
        "petal_length": rng.uniform(0.018, 0.04),
        "petal_width": rng.uniform(0.008, 0.018),
        "petal_color": hsv_to_rgb(hue, rng.uniform(0.55, 0.9), rng.uniform(0.7, 0.95)),
        "petal_opening": rng.uniform(40.0, 75.0),
        "petal_curve": rng.uniform(0.1, 0.5),
        "inflorescence": rng.choice([INFLORESCENCE["RACEME"], INFLORESCENCE["SPIKE"], INFLORESCENCE["PANICLE"]]),
        "flower_count": rng.randint(8, 22),
        "flower_spacing": rng.uniform(0.025, 0.05),
        "overall_scale": rng.uniform(1.3, 1.8),
        "lod": 2,
        "seed": idx * 43 + 17,
    }


def cluster_alien_strange(rng: random.Random, idx: int) -> dict:
    """Extreme params — flowers that don't quite resemble anything earthly."""
    hue1 = rng.uniform(0.0, 1.0)
    hue2 = (hue1 + rng.uniform(0.3, 0.6)) % 1.0
    return {
        "stem_height": rng.uniform(0.05, 0.5),
        "stem_curve": rng.uniform(0.0, 1.0),
        "stem_radius": rng.uniform(0.002, 0.025),
        "pendant": rng.choice([True, False]),
        "leaf_count": rng.randint(0, 12),
        "leaf_shape": rng.randint(0, 7),
        "phyllotaxis": rng.choice([PHYLLOTAXIS["WHORLED"], PHYLLOTAXIS["SPIRAL"], PHYLLOTAXIS["ROSETTE"]]),
        "leaf_length": rng.uniform(0.03, 0.25),
        "leaf_width": rng.uniform(0.005, 0.08),
        "leaf_color": hsv_to_rgb(rng.uniform(0.25, 0.45), rng.uniform(0.3, 0.95), rng.uniform(0.3, 0.7)),
        "leaf_angle": rng.uniform(10.0, 80.0),
        "flower_form": rng.randint(0, 5),
        "petal_count": rng.choice([3, 7, 11, 13, 17, 24, 30]),
        "petal_length": rng.uniform(0.02, 0.12),
        "petal_width": rng.uniform(0.005, 0.05),
        "petal_color": hsv_to_rgb(hue1, rng.uniform(0.7, 1.0), rng.uniform(0.7, 1.0)),
        "petal_opening": rng.uniform(0.0, 90.0),
        "petal_curve": rng.uniform(0.0, 1.0),
        "stamen_count": rng.randint(3, 30),
        "stamen_color": hsv_to_rgb(hue2, 0.85, 0.95),
        "pistil_color": hsv_to_rgb(hue2, 0.7, 0.7),
        "inflorescence": rng.randint(0, 6),
        "flower_count": rng.randint(1, 18),
        "flower_spacing": rng.uniform(0.02, 0.07),
        "overall_scale": rng.uniform(1.5, 2.4),
        "lod": 2,
        "seed": idx * 47 + 23,
    }


CLUSTERS = [
    ("tiny_meadow",     "Tiny meadow — short stem, single small flower, wildflower colors", cluster_tiny_meadow,    12),
    ("pendant_bell",    "Pendant bell — bluebell-family, drooping heads, blue/violet hues",   cluster_pendant_bell,   12),
    ("composite_disk",  "Composite disk — daisy/sunflower, ray petals around dense disk",     cluster_composite_disk, 12),
    ("tropical_spire",  "Tropical spire — tall raceme/panicle/spike with many small flowers", cluster_tropical_spire, 12),
    ("alien_strange",   "Alien strange — extreme params, recognisable but not earthly",       cluster_alien_strange,  12),
]


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Generating BotanicalFlower DNA configs into {OUT_DIR}")

    entries: list[dict] = []
    for cluster_name, cluster_desc, generator, count in CLUSTERS:
        # Deterministic per-cluster RNG so re-runs are reproducible.
        rng = random.Random(hash(cluster_name) & 0xFFFFFFFF)
        for i in range(count):
            cfg_id = f"bf_{cluster_name}_{i + 1:02d}"
            cfg = generator(rng, i + 1)
            cfg["_cluster"] = cluster_name
            cfg["_id"] = cfg_id
            (OUT_DIR / f"{cfg_id}.json").write_text(
                json.dumps(cfg, indent=2),
                encoding="utf-8",
            )
            entries.append({
                "id": cfg_id,
                "notes": cluster_desc,
                "layout": cluster_name,
                "interpretation": "botanical_flower",
                "image": f"/botanical-flower-gallery/{cfg_id}.png",
                "config": f"/botanical-flower-gallery/{cfg_id}.json",
            })
        print(f"  {cluster_name:18s}: {count} variants")

    manifest = {
        "version": 1,
        "description": (
            "BotanicalFlower DNA — anatomically-correct Swedish-plant generator "
            "(commons/flora/BotanicalFlower) with five archetype clusters explored "
            "via parameter sampling. Each variant is a configure() dict that reproduces "
            "the same flower whenever loaded. Crown jewels feed back into the biome "
            "paint dispatcher for the flower kingdom (commons/biome_layers/biome_paint_dispatcher.gd)."
        ),
        "entries": entries,
    }
    (OUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )
    print(f"\nWrote {len(entries)} entries + manifest.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
