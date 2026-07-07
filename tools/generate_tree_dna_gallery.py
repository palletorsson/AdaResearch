"""
generate_tree_dna_gallery.py

Generate a 60-variant DNA gallery for the Tree kingdom. Mirrors
generate_botanical_flower_gallery.py: per-archetype deterministic
sampling, JSON configs written next to the encyclopedia public folder
where commons/testing/tree_dna_gallery_lab.gd will pick them up and
render PNGs.

Five archetype clusters, 12 variants each:
  - conical_fir   : tall, narrow, deep recursion (spruce / pine read)
  - broad_oak     : wide canopy, moderate decay (oak / maple read)
  - bushy_shrub   : low scale, high branching (juniper / hazel read)
  - willow_droop  : tall, droopy branches (willow / birch read)
  - alien_grove   : extreme parameters, off-palette (Q-FEP read)

Each config is a flat dict that CritterDNA.from_dict() can load.
Colors are stored as RGB triples (0..1) — the lab converts to Color.
The dispatcher's _spawn_tree gives the canonical parameter pattern;
this generator amplifies that into a parameter SPACE for browsing.

Run:
    python tools/generate_tree_dna_gallery.py

Output:
    ada_encyclopedia/public/tree-dna-gallery/
        manifest.json
        td_<cluster>_<NN>.json   (60 files)
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

# Path to the encyclopedia public folder — same convention as
# the BotanicalFlower gallery. If you move the encyclopedia repo,
# edit this constant.
GALLERY_DIR = Path(
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\tree-dna-gallery"
)

# Per-cluster configuration. Each entry defines the parameter ranges
# for that archetype. The generator samples uniformly within each
# range (with a seeded RNG per cluster for reproducibility) to produce
# 12 variants. CritterDNA gene names match algorithms/nature_system/
# dna/critter_dna.gd; keep this file in sync if you add genes there.

CLUSTERS = {
    "conical_fir": {
        "label": "Conical Fir",
        "notes": "Tall narrow conifer — small branch_angle, high decay, dense leaves",
        "ranges": {
            "segments":      (4.5, 7.0),     # Deep L-system recursion
            "scale":         (0.9, 1.4),     # Tall
            "symmetry":      (3.0, 4.0),
            "branch_angle":  (15.0, 28.0),   # Narrow — pine silhouette
            "branch_decay":  (0.72, 0.85),   # Strong taper top
            "leaf_density":  (0.65, 0.90),   # Needle-dense
            "part_length":   (0.6, 0.95),
            "part_width":    (0.18, 0.28),
            "part_curve":    (0.1, 0.25),    # Branches stay rigid
            "part_taper":    (0.7, 0.95),
            "phyllotaxis":   (0.0, 0.3),     # Spiral
            "inflorescence": (0.0, 0.15),
            "root_type":     (0.6, 0.9),     # Deep tap roots
            "form_process":  (0.0, 0.15),    # Grown
            "skeleton_complexity": (0.7, 0.95),
            "recursion_depth":     (0.5, 0.8),
            "roughness":     (0.7, 0.9),
        },
        "palette": [
            # primary (fruit/accent), secondary (BARK — used by trunk
            # shader), tertiary (LEAF — used by foliage shader).
            # Verified against tree_morphology.gd: trunk pulls
            # secondary_color, leaves pull tertiary_color.
            ([0.18, 0.55, 0.20], [0.30, 0.18, 0.10], [0.10, 0.40, 0.18]),
            ([0.15, 0.50, 0.18], [0.25, 0.16, 0.09], [0.08, 0.35, 0.15]),
            ([0.20, 0.48, 0.15], [0.35, 0.22, 0.13], [0.12, 0.38, 0.13]),
            ([0.13, 0.45, 0.25], [0.28, 0.20, 0.12], [0.07, 0.32, 0.20]),
        ],
    },

    "broad_oak": {
        "label": "Broad Oak",
        "notes": "Wide canopy — moderate angle, low decay, broad leaves",
        "ranges": {
            "segments":      (3.5, 5.5),
            "scale":         (1.0, 1.6),
            "symmetry":      (3.0, 5.0),
            "branch_angle":  (28.0, 45.0),
            "branch_decay":  (0.55, 0.70),   # Slow taper — branches stay thick
            "leaf_density":  (0.55, 0.85),
            "part_length":   (0.55, 0.85),
            "part_width":    (0.25, 0.40),
            "part_curve":    (0.2, 0.45),
            "part_taper":    (0.55, 0.80),
            "phyllotaxis":   (0.2, 0.7),
            "inflorescence": (0.0, 0.25),
            "root_type":     (0.5, 0.85),
            "form_process":  (0.0, 0.20),
            "skeleton_complexity": (0.6, 0.9),
            "recursion_depth":     (0.4, 0.7),
            "roughness":     (0.6, 0.85),
        },
        "palette": [
            # (fruit_accent, bark, leaf) — see conical_fir note above.
            ([0.25, 0.55, 0.18], [0.32, 0.22, 0.13], [0.18, 0.42, 0.14]),
            ([0.30, 0.62, 0.22], [0.40, 0.28, 0.18], [0.20, 0.48, 0.18]),
            ([0.22, 0.58, 0.20], [0.28, 0.18, 0.10], [0.16, 0.45, 0.16]),
            ([0.32, 0.65, 0.25], [0.36, 0.25, 0.15], [0.22, 0.52, 0.20]),
        ],
    },

    "bushy_shrub": {
        "label": "Bushy Shrub",
        "notes": "Low compact — wide angles, shallow segments, tight crown",
        "ranges": {
            "segments":      (2.5, 4.0),     # Shallow recursion
            "scale":         (0.5, 0.9),     # Small
            "symmetry":      (4.0, 6.0),     # Many forks per node
            "branch_angle":  (40.0, 65.0),   # Wide
            "branch_decay":  (0.60, 0.78),
            "leaf_density":  (0.70, 0.95),
            "part_length":   (0.35, 0.55),   # Short branches
            "part_width":    (0.20, 0.32),
            "part_curve":    (0.30, 0.55),
            "part_taper":    (0.60, 0.85),
            "phyllotaxis":   (0.4, 0.9),
            "inflorescence": (0.0, 0.40),
            "root_type":     (0.3, 0.7),
            "form_process":  (0.05, 0.20),
            "skeleton_complexity": (0.55, 0.85),
            "recursion_depth":     (0.3, 0.6),
            "roughness":     (0.65, 0.88),
        },
        "palette": [
            # (fruit_accent, bark, leaf)
            ([0.28, 0.62, 0.25], [0.30, 0.22, 0.15], [0.18, 0.48, 0.20]),
            ([0.32, 0.65, 0.28], [0.35, 0.26, 0.18], [0.22, 0.52, 0.22]),
            ([0.22, 0.55, 0.18], [0.25, 0.18, 0.12], [0.16, 0.45, 0.16]),
            ([0.30, 0.60, 0.22], [0.32, 0.24, 0.16], [0.20, 0.50, 0.18]),
        ],
    },

    "willow_droop": {
        "label": "Willow Droop",
        "notes": "Tall droopy — high part_curve gives weeping silhouette",
        "ranges": {
            "segments":      (4.0, 6.0),
            "scale":         (1.0, 1.5),
            "symmetry":      (3.0, 4.0),
            "branch_angle":  (22.0, 38.0),
            "branch_decay":  (0.62, 0.75),
            "leaf_density":  (0.50, 0.80),
            "part_length":   (0.7, 1.1),     # Long pendant branches
            "part_width":    (0.15, 0.25),
            "part_curve":    (0.55, 0.90),   # KEY — droopy
            "part_taper":    (0.70, 0.90),
            "part_tilt":     (20.0, 40.0),   # Gravity sag
            "phyllotaxis":   (0.0, 0.4),
            "inflorescence": (0.0, 0.20),
            "root_type":     (0.4, 0.7),
            "form_process":  (0.0, 0.15),
            "skeleton_complexity": (0.65, 0.90),
            "recursion_depth":     (0.45, 0.75),
            "roughness":     (0.55, 0.78),
        },
        "palette": [
            # (fruit_accent, bark, leaf)
            ([0.35, 0.68, 0.28], [0.38, 0.32, 0.22], [0.25, 0.55, 0.22]),
            ([0.32, 0.65, 0.25], [0.32, 0.28, 0.20], [0.22, 0.50, 0.20]),
            ([0.30, 0.62, 0.28], [0.30, 0.26, 0.18], [0.20, 0.48, 0.22]),
            ([0.38, 0.70, 0.32], [0.42, 0.36, 0.26], [0.28, 0.58, 0.25]),
        ],
    },

    "alien_grove": {
        "label": "Alien Grove",
        "notes": "Off-palette parameters — Q-FEP read of tree-as-form",
        "ranges": {
            "segments":      (3.0, 7.0),     # Anywhere
            "scale":         (0.6, 1.6),
            "symmetry":      (2.0, 7.0),
            "branch_angle":  (50.0, 88.0),   # Splayed
            "branch_decay":  (0.50, 0.85),
            "leaf_density":  (0.20, 0.95),
            "part_length":   (0.3, 1.1),
            "part_width":    (0.10, 0.45),
            "part_curve":    (0.0, 0.95),
            "part_taper":    (0.30, 0.95),
            "part_twist":    (-30.0, 30.0),
            "phyllotaxis":   (0.0, 1.0),
            "inflorescence": (0.0, 0.80),
            "root_type":     (0.0, 0.95),
            "form_process":  (0.0, 0.45),
            "skeleton_complexity": (0.40, 0.95),
            "recursion_depth":     (0.30, 0.90),
            "roughness":     (0.20, 0.95),
            "iridescence":   (0.0, 0.5),
            "transparency":  (0.0, 0.3),
        },
        "palette": [
            # Off-palette — purples, cyans, oranges
            ([0.35, 0.18, 0.42], [0.20, 0.65, 0.55], [0.85, 0.55, 0.92]),
            ([0.55, 0.20, 0.18], [0.10, 0.55, 0.62], [0.95, 0.85, 0.30]),
            ([0.20, 0.22, 0.45], [0.55, 0.80, 0.30], [0.92, 0.40, 0.55]),
            ([0.45, 0.30, 0.15], [0.85, 0.60, 0.25], [0.30, 0.85, 0.95]),
            ([0.25, 0.45, 0.50], [0.92, 0.30, 0.55], [0.95, 0.92, 0.40]),
        ],
    },
}


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def sample_cluster(name: str, spec: dict, n: int) -> list[dict]:
    """Sample n variants for a cluster. Deterministic per-cluster seed."""
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    palette = spec["palette"]
    out: list[dict] = []
    for i in range(n):
        cfg: dict = {}
        # Sample numeric ranges
        for key, (lo, hi) in spec["ranges"].items():
            cfg[key] = lo + rng.random() * (hi - lo)
        # Discrete-ish: integer-like genes get rounded
        cfg["segments"] = round(cfg["segments"], 2)
        cfg["symmetry"] = round(cfg["symmetry"], 2)
        # Pick a palette triple
        pri, sec, ter = rng.choice(palette)
        # Slight per-variant tint
        tint = lambda c, k: max(0.0, min(1.0, c + rng.uniform(-0.06, 0.06) * k))
        cfg["primary_color"]   = [round(tint(pri[j], 1.0), 4) for j in range(3)]
        cfg["secondary_color"] = [round(tint(sec[j], 1.0), 4) for j in range(3)]
        cfg["tertiary_color"]  = [round(tint(ter[j], 1.0), 4) for j in range(3)]

        # Always tree
        cfg["body_type"] = 0.0

        # Round all floats to 4 dp for compact JSON.
        for k, v in cfg.items():
            if isinstance(v, float):
                cfg[k] = round(v, 4)

        # Identity / cluster tag (tolerated by from_dict because it
        # filters unknown keys via set() — but we'll keep them under
        # an underscore prefix so the lab can read them back).
        cfg["_cluster"] = name
        cfg["_id"] = f"td_{name}_{i + 1:02d}"
        cfg["seed"] = rng.randint(0, 99999)
        out.append(cfg)
    return out


def main() -> None:
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)

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
                "image":  f"/tree-dna-gallery/{v['_id']}.png",
                "config": f"/tree-dna-gallery/{v['_id']}.json",
            })
            total += 1

    manifest = {
        "version": 1,
        "description":
            "Tree-DNA gallery — 60 CritterDNA configs sampled across 5 "
            "tree archetype clusters. Render via "
            "commons/testing/tree_dna_gallery_lab.gd; configs are flat "
            "dicts compatible with CritterDNA.from_dict().",
        "entries": entries,
    }
    with (GALLERY_DIR / "manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Wrote {total} configs across {len(CLUSTERS)} clusters to {GALLERY_DIR}")


if __name__ == "__main__":
    main()
