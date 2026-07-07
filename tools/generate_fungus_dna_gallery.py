"""
generate_fungus_dna_gallery.py

Generate a 60-variant DNA gallery for the Fungus kingdom — REAL
mushrooms (cap + stem + gills + colonies) via FungusMorphology, NOT
voxel CA. Mirrors generate_tree_dna_gallery.py: per-archetype
deterministic sampling, JSON configs written next to the encyclopedia
public folder where commons/testing/fungus_dna_gallery_lab.gd will
pick them up and render PNGs.

FungusMorphology gene mapping (algorithms/nature_system/morphology/
fungus_morphology.gd):
  part_curve     0.0=flat   0.3=dome     0.6=conical   1.0=funnel
  part_width     cap diameter
  part_length    stem height
  part_taper     <0.5 = bulbous stem,  >0.5 = classic top-narrow
  part_tilt      cap tilt angle (degrees)
  symmetry       gill / pore count
  segments       shelf / bracket count for bracket fungi
  edge_type      >0.5 = stem ring (annulus); also wavy edge
  leaf_density   spore cloud density (>0.4 enables spores)
  transparency   cap translucency (bioluminescent species)
  iridescence    bioluminescent emission
  sociality      >0.5 + inflorescence>0.2 = colony, else single
  inflorescence  <0.4 fairy ring, <0.7 shelf bracket, else dense cluster
  primary_color  CAP color
  secondary_color STEM color
  tertiary_color GILL / spore color

Five archetype clusters, 12 variants each:
  - button_dome     : single, classic dome cap (Agaricus / Amanita)
  - parasol_tall    : single, flat cap on tall stem with ring (Macrolepiota)
  - shelf_bracket   : colony, shelf fungi on imaginary tree (Ganoderma)
  - fairy_ring      : colony, ring of small caps (Marasmius)
  - alien_lumen     : bioluminescent, funnel cap, exotic palette

Run:
    python tools/generate_fungus_dna_gallery.py

Output:
    ada_encyclopedia/public/fungus-dna-gallery/
        manifest.json
        fd_<cluster>_<NN>.json   (60 files)
"""

from __future__ import annotations

import json
import random
from pathlib import Path

GALLERY_DIR = Path(
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\fungus-dna-gallery"
)


CLUSTERS = {
    "button_dome": {
        "label": "Button Dome",
        "notes":
            "Single dome-cap mushroom — Agaricus / Amanita read. "
            "Classic dome (part_curve ~0.3) on a top-tapered stem.",
        "ranges": {
            "scale":         (0.8, 1.4),
            "part_curve":    (0.20, 0.42),    # dome
            "part_width":    (0.60, 1.00),
            "part_length":   (0.80, 1.40),    # stem height factor
            "part_taper":    (0.55, 0.80),    # classic top-narrow
            "part_tilt":     (0.0, 12.0),
            "symmetry":      (4.0, 8.0),       # gill density
            "edge_type":     (0.0, 0.45),     # mostly no skirt
            "leaf_density":  (0.30, 0.60),
            "sociality":     (0.0, 0.40),     # single
            "inflorescence": (0.0, 0.30),
            "transparency":  (0.0, 0.10),
            "iridescence":   (0.0, 0.05),
            "roughness":     (0.55, 0.80),
            "pattern_type":  (0.0, 0.5),
            "pattern_density":(0.0, 0.4),
        },
        "palette": [
            # cap (primary), stem (secondary), gills (tertiary)
            ([0.78, 0.22, 0.18], [0.92, 0.92, 0.85], [0.95, 0.92, 0.78]),  # red fly-agaric
            ([0.55, 0.32, 0.18], [0.85, 0.78, 0.65], [0.92, 0.85, 0.55]),  # boletus
            ([0.45, 0.22, 0.12], [0.88, 0.82, 0.70], [0.85, 0.75, 0.45]),  # porcini
            ([0.75, 0.55, 0.25], [0.92, 0.88, 0.78], [0.95, 0.88, 0.70]),  # honey
            ([0.85, 0.62, 0.45], [0.88, 0.85, 0.78], [0.78, 0.65, 0.45]),  # cinnamon
        ],
    },

    "parasol_tall": {
        "label": "Parasol Tall",
        "notes":
            "Flat cap on tall slim stem, with ring (Macrolepiota / "
            "Coprinus). edge_type > 0.5 enables stem skirt.",
        "ranges": {
            "scale":         (1.0, 1.6),
            "part_curve":    (0.05, 0.25),    # nearly flat
            "part_width":    (0.80, 1.30),
            "part_length":   (1.40, 2.20),    # very tall
            "part_taper":    (0.65, 0.85),
            "part_tilt":     (0.0, 6.0),
            "symmetry":      (5.0, 8.0),
            "edge_type":     (0.55, 0.95),    # skirt ring
            "leaf_density":  (0.30, 0.50),
            "sociality":     (0.0, 0.40),     # single (occasional pair)
            "inflorescence": (0.0, 0.30),
            "transparency":  (0.0, 0.15),
            "iridescence":   (0.0, 0.08),
            "roughness":     (0.50, 0.75),
            "pattern_type":  (0.3, 0.8),       # scaled / spotted caps
            "pattern_density":(0.3, 0.7),
        },
        "palette": [
            # earthy parasols
            ([0.78, 0.72, 0.55], [0.92, 0.90, 0.82], [0.95, 0.92, 0.78]),  # cream parasol
            ([0.65, 0.45, 0.30], [0.88, 0.80, 0.65], [0.88, 0.78, 0.50]),  # tan
            ([0.85, 0.78, 0.62], [0.95, 0.92, 0.85], [0.92, 0.88, 0.65]),  # pale
            ([0.55, 0.35, 0.20], [0.78, 0.70, 0.55], [0.85, 0.78, 0.45]),  # toasted
        ],
    },

    "shelf_bracket": {
        "label": "Shelf Bracket",
        "notes":
            "Stacked shelf fungi (Ganoderma / Trametes). Set "
            "inflorescence ∈ [0.4, 0.7] + sociality > 0.5 to trigger "
            "the bracket colony layout.",
        "ranges": {
            "scale":         (0.7, 1.3),
            "part_curve":    (0.15, 0.40),    # gentle dome to flat
            "part_width":    (0.90, 1.50),
            "part_length":   (0.30, 0.60),    # short / no stem
            "part_taper":    (0.40, 0.65),
            "part_tilt":     (10.0, 30.0),    # tilts outward
            "symmetry":      (5.0, 8.0),
            "segments":      (3.0, 6.0),       # bracket count
            "edge_type":     (0.0, 0.55),
            "leaf_density":  (0.20, 0.50),
            "sociality":     (0.65, 0.95),     # colony triggered
            "inflorescence": (0.45, 0.68),     # SHELF range
            "transparency":  (0.0, 0.10),
            "iridescence":   (0.0, 0.10),
            "roughness":     (0.65, 0.92),
            "pattern_type":  (0.4, 0.9),       # zoned / banded
            "pattern_density":(0.5, 0.9),
        },
        "palette": [
            # hardwood / oxidised metal palette
            ([0.55, 0.30, 0.15], [0.78, 0.55, 0.35], [0.92, 0.78, 0.50]),  # bracket brown
            ([0.42, 0.22, 0.12], [0.65, 0.45, 0.25], [0.88, 0.72, 0.40]),  # dark bracket
            ([0.35, 0.25, 0.18], [0.55, 0.40, 0.25], [0.78, 0.62, 0.32]),  # blackened
            ([0.62, 0.40, 0.20], [0.85, 0.62, 0.35], [0.95, 0.85, 0.55]),  # honey shelf
            ([0.30, 0.45, 0.25], [0.55, 0.65, 0.40], [0.78, 0.85, 0.55]),  # mossy turkey-tail
        ],
    },

    "fairy_ring": {
        "label": "Fairy Ring",
        "notes":
            "Ring of small caps (Marasmius / Mycena). Set inflorescence "
            "< 0.4 + sociality > 0.5 to trigger the fairy-ring layout.",
        "ranges": {
            "scale":         (0.5, 1.0),       # small mushrooms
            "part_curve":    (0.30, 0.65),    # dome → conical
            "part_width":    (0.40, 0.75),
            "part_length":   (0.80, 1.40),
            "part_taper":    (0.55, 0.85),
            "part_tilt":     (0.0, 8.0),
            "symmetry":      (4.0, 7.0),
            "edge_type":     (0.0, 0.4),
            "leaf_density":  (0.30, 0.70),
            "sociality":     (0.65, 0.95),     # colony triggered
            "inflorescence": (0.0, 0.38),      # FAIRY RING range
            "transparency":  (0.0, 0.20),
            "iridescence":   (0.0, 0.20),
            "roughness":     (0.50, 0.78),
            "pattern_type":  (0.0, 0.5),
            "pattern_density":(0.0, 0.5),
        },
        "palette": [
            # forest-floor palette
            ([0.62, 0.38, 0.22], [0.85, 0.78, 0.65], [0.92, 0.85, 0.65]),  # tan mycena
            ([0.45, 0.30, 0.20], [0.78, 0.72, 0.62], [0.88, 0.82, 0.55]),  # soft brown
            ([0.85, 0.55, 0.32], [0.92, 0.88, 0.75], [0.95, 0.88, 0.62]),  # apricot
            ([0.78, 0.78, 0.75], [0.92, 0.92, 0.88], [0.85, 0.85, 0.78]),  # white pioneer
        ],
    },

    "alien_lumen": {
        "label": "Alien Lumen",
        "notes":
            "Bioluminescent / funnel-cap variants — high iridescence, "
            "transparency, exotic palette. Q-FEP read of fungus.",
        "ranges": {
            "scale":         (0.6, 1.4),
            "part_curve":    (0.55, 1.00),    # conical → funnel (chanterelle / weird)
            "part_width":    (0.50, 1.20),
            "part_length":   (0.70, 1.80),
            "part_taper":    (0.20, 0.85),    # full range, can be bulbous
            "part_tilt":     (0.0, 25.0),
            "symmetry":      (3.0, 8.0),
            "edge_type":     (0.30, 0.95),
            "leaf_density":  (0.40, 0.85),
            "sociality":     (0.0, 0.85),     # mix
            "inflorescence": (0.0, 0.85),     # mix
            "transparency":  (0.30, 0.70),    # KEY — translucent caps
            "iridescence":   (0.45, 0.95),    # KEY — emission
            "roughness":     (0.20, 0.55),    # smoother (jelly-like)
            "pattern_type":  (0.4, 1.0),
            "pattern_density":(0.4, 1.0),
        },
        "palette": [
            # off-palette: glow blues, magentas, electric greens
            ([0.92, 0.30, 0.65], [0.45, 0.20, 0.55], [0.85, 0.95, 1.00]),  # magenta+navy
            ([0.20, 0.85, 0.95], [0.18, 0.30, 0.55], [0.92, 0.95, 0.40]),  # cyan+yellow
            ([0.85, 0.95, 0.30], [0.32, 0.55, 0.20], [0.95, 0.85, 0.55]),  # acid green
            ([0.65, 0.30, 0.95], [0.22, 0.18, 0.45], [0.95, 0.65, 0.95]),  # purple glow
            ([0.95, 0.55, 0.20], [0.35, 0.22, 0.18], [0.95, 0.92, 0.62]),  # ember
        ],
    },
}


def sample_cluster(name: str, spec: dict, n: int) -> list[dict]:
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    out: list[dict] = []
    for i in range(n):
        cfg: dict = {}
        for key, (lo, hi) in spec["ranges"].items():
            cfg[key] = round(lo + rng.random() * (hi - lo), 4)

        pri, sec, ter = rng.choice(spec["palette"])
        tint = lambda c: max(0.0, min(1.0, c + rng.uniform(-0.05, 0.05)))
        cfg["primary_color"]   = [round(tint(pri[j]), 4) for j in range(3)]
        cfg["secondary_color"] = [round(tint(sec[j]), 4) for j in range(3)]
        cfg["tertiary_color"]  = [round(tint(ter[j]), 4) for j in range(3)]

        # Always tree/fungus body type — FungusMorphology doesn't gate
        # on body_type but we set it consistently for downstream tools.
        cfg["body_type"] = 3.0  # 0=tree 1=walker 2=flower 3=fungus

        # Default `segments` if not in ranges (shelf_bracket sets it,
        # other clusters don't need it but FungusMorphology reads it).
        cfg.setdefault("segments", 4.0)

        cfg["_cluster"] = name
        cfg["_id"] = f"fd_{name}_{i + 1:02d}"
        cfg["seed"] = rng.randint(0, 99999)
        out.append(cfg)
    return out


def main() -> None:
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)

    # Wipe stale CA-era PNGs/JSONs so the re-render is clean.
    for old in GALLERY_DIR.glob("fd_*.json"):
        old.unlink()
    for old in GALLERY_DIR.glob("fd_*.png"):
        old.unlink()

    entries: list[dict] = []
    total = 0
    for cluster_name, spec in CLUSTERS.items():
        variants = sample_cluster(cluster_name, spec, n=12)
        for v in variants:
            cfg_path = GALLERY_DIR / f"{v['_id']}.json"
            with cfg_path.open("w", encoding="utf-8") as f:
                json.dump(v, f, indent=2)
            entries.append({
                "id":   v["_id"],
                "notes": spec["notes"],
                "layout": cluster_name,
                "interpretation": spec["label"],
                "image":  f"/fungus-dna-gallery/{v['_id']}.png",
                "config": f"/fungus-dna-gallery/{v['_id']}.json",
            })
            total += 1

    manifest = {
        "version": 2,
        "description":
            "Fungus-DNA gallery — 60 CritterDNA configs sampled across "
            "5 mushroom archetype clusters and rendered via "
            "FungusMorphology (cap + stem + gills + colonies). v2 "
            "replaces the v1 voxel-CA gallery.",
        "entries": entries,
    }
    with (GALLERY_DIR / "manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Wrote {total} configs across {len(CLUSTERS)} clusters to {GALLERY_DIR}")


if __name__ == "__main__":
    main()
