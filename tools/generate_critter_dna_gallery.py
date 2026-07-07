"""
generate_critter_dna_gallery.py

60-variant DNA gallery for the Creature kingdom — body+limb critters
via CreatureMorphology, parallel to the tree / flower / fungus
galleries. Each variant is a flat CritterDNA dict the lab loads
through CritterDNA.from_dict() and feeds to CreatureMorphology.build.

Five archetype clusters, 12 variants each. The clusters double as
the LIFECYCLE STAGES the critter system is designed around (the
DNA can transform between them at runtime, but for a static gallery
we just sample one stage per variant):

  - bug_beetle     : short body (3-4 segs), 6 legs, low mobility, hard
                     scales — Coleoptera read.
  - larva_worm     : long body (8-12 segs), few/no limbs, soft, curved.
  - walker_quad    : 4 prominent limbs, balanced symmetry, dog/lizard.
  - flier_wing     : compact body, mobility>0.7, big symmetric appendages
                     (rendered as wings via splay angle).
  - alien_crab     : extreme parameters — many limbs, off-palette, weird.

Run:
    python tools/generate_critter_dna_gallery.py

Output:
    ada_encyclopedia/public/critter-dna-gallery/
        manifest.json
        cd_<cluster>_<NN>.json   (60 files)
"""

from __future__ import annotations

import json
import random
from pathlib import Path

GALLERY_DIR = Path(
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\critter-dna-gallery"
)


CLUSTERS = {
    "bug_beetle": {
        "label": "Bug · Beetle",
        "notes":
            "Short hard-shelled critter — 3-4 body segments, 6 legs, "
            "low mobility, scales surface. The classic insect read.",
        "ranges": {
            "scale":         (0.6, 1.1),
            "segments":      (3.0, 5.0),
            "symmetry":      (3.0, 4.0),       # 3-4 leg pairs
            "mobility":      (0.10, 0.40),
            "aggression":    (0.10, 0.40),
            "branch_angle":  (35.0, 60.0),
            "branch_decay":  (0.55, 0.78),
            "part_length":   (0.5, 0.9),       # short legs
            "part_width":    (0.6, 1.0),
            "part_curve":    (0.05, 0.20),     # straight body
            "part_taper":    (0.45, 0.70),
            "part_twist":    (-3.0, 3.0),
            "part_tilt":     (15.0, 35.0),
            "phyllotaxis":   (0.0, 0.4),
            "edge_type":     (0.0, 0.4),
            "pattern_type":  (0.3, 0.7),
            "pattern_density":(0.4, 0.8),
            "roughness":     (0.55, 0.85),
        },
        "palette": [
            # body, limbs, eyes/accent
            ([0.32, 0.18, 0.10], [0.45, 0.28, 0.15], [0.85, 0.72, 0.20]),  # bronze
            ([0.18, 0.12, 0.08], [0.30, 0.22, 0.15], [0.75, 0.85, 0.30]),  # black-yellow
            ([0.45, 0.22, 0.18], [0.62, 0.32, 0.22], [0.95, 0.85, 0.40]),  # red-orange
            ([0.20, 0.32, 0.18], [0.32, 0.45, 0.22], [0.85, 0.92, 0.45]),  # forest green
            ([0.42, 0.32, 0.15], [0.55, 0.40, 0.20], [0.92, 0.78, 0.35]),  # amber
        ],
    },

    "larva_worm": {
        "label": "Larva · Worm",
        "notes":
            "Long soft-body critter — 8-12 segments, almost no limbs, "
            "high body curvature. Soft scales, organic palette.",
        "ranges": {
            "scale":         (0.5, 1.0),
            "segments":      (8.0, 12.0),
            "symmetry":      (1.0, 2.0),       # very few/no limb pairs
            "mobility":      (0.05, 0.25),
            "aggression":    (0.0, 0.20),
            "branch_angle":  (60.0, 90.0),     # if there are bristles, splayed
            "branch_decay":  (0.65, 0.85),
            "part_length":   (0.15, 0.40),     # tiny stubs at most
            "part_width":    (0.4, 0.8),
            "part_curve":    (0.40, 0.85),     # KEY — curvy body
            "part_taper":    (0.55, 0.80),
            "part_twist":    (-15.0, 15.0),
            "part_tilt":     (20.0, 45.0),
            "phyllotaxis":   (0.4, 1.0),
            "edge_type":     (0.0, 0.35),
            "pattern_type":  (0.1, 0.5),
            "pattern_density":(0.3, 0.7),
            "roughness":     (0.40, 0.65),     # softer
        },
        "palette": [
            # soft / wet larva tones
            ([0.85, 0.78, 0.65], [0.65, 0.55, 0.40], [0.55, 0.42, 0.32]),  # cream
            ([0.92, 0.65, 0.55], [0.78, 0.45, 0.35], [0.42, 0.22, 0.18]),  # pink
            ([0.65, 0.78, 0.55], [0.45, 0.62, 0.35], [0.30, 0.45, 0.22]),  # green
            ([0.95, 0.92, 0.85], [0.78, 0.72, 0.62], [0.55, 0.42, 0.32]),  # pale
        ],
    },

    "walker_quad": {
        "label": "Walker · Quad",
        "notes":
            "Quadruped form — balanced 4-limb symmetry, mid mobility, "
            "dog / lizard read. Limbs are prominent and load-bearing.",
        "ranges": {
            "scale":         (0.8, 1.4),
            "segments":      (4.0, 6.0),
            "symmetry":      (2.0, 3.0),       # 2 leg pairs (front + back)
            "mobility":      (0.45, 0.75),
            "aggression":    (0.15, 0.55),
            "branch_angle":  (20.0, 38.0),     # limbs more vertical
            "branch_decay":  (0.65, 0.78),
            "part_length":   (0.85, 1.40),     # longer legs
            "part_width":    (0.7, 1.10),
            "part_curve":    (0.05, 0.25),
            "part_taper":    (0.45, 0.70),
            "part_twist":    (-3.0, 3.0),
            "part_tilt":     (8.0, 22.0),
            "phyllotaxis":   (0.0, 0.4),       # alternating legs
            "edge_type":     (0.20, 0.55),
            "pattern_type":  (0.2, 0.6),
            "pattern_density":(0.2, 0.6),
            "roughness":     (0.50, 0.78),
            "curiosity":     (0.45, 0.85),
        },
        "palette": [
            ([0.45, 0.32, 0.22], [0.55, 0.40, 0.28], [0.85, 0.65, 0.30]),
            ([0.32, 0.28, 0.22], [0.42, 0.38, 0.30], [0.95, 0.92, 0.55]),
            ([0.62, 0.45, 0.30], [0.72, 0.55, 0.38], [0.30, 0.45, 0.92]),  # blue eyes
            ([0.55, 0.42, 0.35], [0.65, 0.50, 0.42], [0.92, 0.85, 0.65]),
            ([0.28, 0.32, 0.42], [0.38, 0.42, 0.52], [0.95, 0.78, 0.30]),  # bluish
        ],
    },

    "flier_wing": {
        "label": "Flier · Wing",
        "notes":
            "Aerial form — compact body, high mobility, large "
            "symmetric splayed appendages reading as wings. "
            "Aggression mid (predatory raptor) or low (butterfly).",
        "ranges": {
            "scale":         (0.5, 1.0),       # smaller bodies fly better
            "segments":      (3.0, 5.0),
            "symmetry":      (2.0, 3.0),       # paired wings
            "mobility":      (0.70, 0.95),     # KEY — fast
            "aggression":    (0.10, 0.65),
            "branch_angle":  (75.0, 90.0),     # appendages spread wide (wings)
            "branch_decay":  (0.55, 0.72),
            "part_length":   (1.30, 2.00),     # KEY — long "wings"
            "part_width":    (0.5, 0.85),
            "part_curve":    (0.05, 0.25),
            "part_taper":    (0.55, 0.80),
            "part_twist":    (-8.0, 8.0),
            "part_tilt":     (-12.0, 8.0),     # wings tilt up
            "phyllotaxis":   (0.0, 0.3),
            "edge_type":     (0.40, 0.85),     # wing edges
            "pattern_type":  (0.4, 0.9),       # patterned wings
            "pattern_density":(0.5, 0.95),
            "roughness":     (0.30, 0.60),
            "iridescence":   (0.05, 0.45),     # shimmer
            "curiosity":     (0.55, 0.95),
        },
        "palette": [
            ([0.62, 0.32, 0.18], [0.92, 0.78, 0.30], [0.20, 0.10, 0.05]),  # monarch
            ([0.18, 0.22, 0.45], [0.42, 0.55, 0.85], [0.95, 0.92, 0.55]),  # blue morpho
            ([0.85, 0.78, 0.30], [0.95, 0.92, 0.65], [0.32, 0.18, 0.10]),  # yellow swallowtail
            ([0.42, 0.18, 0.32], [0.78, 0.45, 0.62], [0.92, 0.85, 0.55]),  # purple
            ([0.85, 0.85, 0.85], [0.95, 0.95, 0.95], [0.40, 0.30, 0.18]),  # white moth
        ],
    },

    "alien_crab": {
        "label": "Alien · Crab",
        "notes":
            "Extreme variants — many limbs, off-palette, asymmetric "
            "or twisted. Q-FEP read of creature-form.",
        "ranges": {
            "scale":         (0.6, 1.4),
            "segments":      (2.0, 8.0),
            "symmetry":      (3.0, 5.0),       # many limb pairs
            "mobility":      (0.20, 0.85),
            "aggression":    (0.30, 0.85),     # spiky / threatening
            "branch_angle":  (40.0, 88.0),
            "branch_decay":  (0.50, 0.85),
            "part_length":   (0.6, 1.6),
            "part_width":    (0.4, 1.10),
            "part_curve":    (0.10, 0.55),
            "part_taper":    (0.30, 0.85),
            "part_twist":    (-25.0, 25.0),    # KEY — twisty
            "part_tilt":     (-25.0, 35.0),
            "phyllotaxis":   (0.0, 1.0),
            "edge_type":     (0.40, 0.95),
            "pattern_type":  (0.5, 1.0),
            "pattern_density":(0.5, 1.0),
            "roughness":     (0.20, 0.85),
            "iridescence":   (0.20, 0.65),
            "transparency":  (0.0, 0.25),
            "curiosity":     (0.40, 0.95),
        },
        "palette": [
            # off-palette
            ([0.32, 0.20, 0.55], [0.62, 0.40, 0.92], [0.95, 0.85, 0.30]),  # purple
            ([0.20, 0.55, 0.62], [0.40, 0.85, 0.92], [0.95, 0.30, 0.55]),  # cyan
            ([0.92, 0.30, 0.20], [0.95, 0.55, 0.30], [0.20, 0.30, 0.85]),  # orange/blue
            ([0.55, 0.78, 0.30], [0.85, 0.92, 0.40], [0.65, 0.20, 0.55]),  # acid green/magenta
            ([0.85, 0.55, 0.92], [0.95, 0.78, 0.95], [0.20, 0.85, 0.65]),  # lavender/teal
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

        # Round count-like genes for cleaner DNA reads.
        cfg["segments"] = round(cfg["segments"], 2)
        cfg["symmetry"] = round(cfg["symmetry"], 2)

        pri, sec, ter = rng.choice(spec["palette"])
        tint = lambda c: max(0.0, min(1.0, c + rng.uniform(-0.05, 0.05)))
        cfg["primary_color"]   = [round(tint(pri[j]), 4) for j in range(3)]
        cfg["secondary_color"] = [round(tint(sec[j]), 4) for j in range(3)]
        cfg["tertiary_color"]  = [round(tint(ter[j]), 4) for j in range(3)]

        cfg["body_type"] = 1.0  # creature

        cfg["_cluster"] = name
        cfg["_id"] = f"cd_{name}_{i + 1:02d}"
        cfg["seed"] = rng.randint(0, 99999)
        out.append(cfg)
    return out


def main() -> None:
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)

    for old in GALLERY_DIR.glob("cd_*.json"):
        old.unlink()
    for old in GALLERY_DIR.glob("cd_*.png"):
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
                "image":  f"/critter-dna-gallery/{v['_id']}.png",
                "config": f"/critter-dna-gallery/{v['_id']}.json",
            })
            total += 1

    manifest = {
        "version": 1,
        "description":
            "Critter-DNA gallery — 60 CritterDNA configs sampled across "
            "5 lifecycle archetype clusters and rendered via "
            "CreatureMorphology (segmented body + limbs + head + tail). "
            "Static T-pose builds — animation deliberately disabled, "
            "since we only need the silhouette for VR / gallery review.",
        "entries": entries,
    }
    with (GALLERY_DIR / "manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Wrote {total} configs across {len(CLUSTERS)} clusters to {GALLERY_DIR}")


if __name__ == "__main__":
    main()
