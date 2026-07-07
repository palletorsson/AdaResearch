"""
generate_softbody_fungus_gallery.py

Sister gallery to fungus-dna: same FungusMorphology base, but each
variant gets a soft-body deformation pose applied AFTER the rigid
mushroom is built. The deformation is a per-node transform (squash,
tilt, bulge) on Cap / Stem / Gills. Reads as a soft-body mushroom
caught mid-frame even though no physics ran — a static gallery
captures one pose per variant.

Five deformation archetypes, 12 variants each:
  - gravity_droop  : cap squashed and edges sagging downward
  - squash_settle  : whole mushroom compressed vertically
  - wind_lean      : stem leaning, cap follows
  - inflate_bloat  : cap puffed, stem swollen
  - wilt_collapse  : cap drooping to one side, stem buckling

Each variant config = base CritterDNA + a "deformation" block that the
lab reads to pose the mesh nodes after FungusMorphology.build runs.

Run:
    python tools/generate_softbody_fungus_gallery.py

Output:
    ada_encyclopedia/public/softbody-fungus-gallery/
        manifest.json
        sf_<archetype>_<NN>.json   (60 files)
"""

from __future__ import annotations

import json
import random
from pathlib import Path

GALLERY_DIR = Path(
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\softbody-fungus-gallery"
)


# Each archetype defines:
#   base_dna        : CritterDNA gene ranges (similar to button_dome /
#                     parasol_tall — we want a recognisable mushroom
#                     before deformation)
#   deformation     : pose ranges per node:
#                       cap_scale   = (sx, sy, sz)
#                       cap_tilt    = (deg_x, deg_z)
#                       stem_scale  = (sx, sy, sz)
#                       stem_tilt   = (deg_x, deg_z)
#                       cap_offset  = (x, y, z) — slide cap relative
#                                     to stem top
#   palette         : (cap, stem, gill) RGB triples

ARCHETYPES = {
    "gravity_droop": {
        "label": "Gravity Droop",
        "notes":
            "Cap squashed flat and bulging outward, like a soft cap "
            "sagging under its own weight after rain.",
        "base_dna": {
            "scale": (0.9, 1.4),
            "part_curve":  (0.25, 0.42),    # dome to start with
            "part_width":  (0.7, 1.1),
            "part_length": (1.0, 1.6),
            "part_taper":  (0.55, 0.78),
            "symmetry":    (4.0, 7.0),
            "edge_type":   (0.0, 0.30),
            "leaf_density":(0.30, 0.55),
            "sociality":   (0.0, 0.40),
            "inflorescence":(0.0, 0.30),
            "transparency":(0.0, 0.10),
            "iridescence": (0.0, 0.05),
            "roughness":   (0.5, 0.75),
        },
        "deformation": {
            "cap_scale_x":  (1.30, 1.65),    # bulge horizontally
            "cap_scale_y":  (0.30, 0.55),    # squash vertically (heavy)
            "cap_scale_z":  (1.30, 1.65),
            "cap_tilt_x":   (-3.0, 3.0),
            "cap_tilt_z":   (-3.0, 3.0),
            "stem_scale_x": (1.0, 1.10),
            "stem_scale_y": (0.85, 1.0),     # slight stem compression
            "stem_scale_z": (1.0, 1.10),
            "stem_tilt_x":  (-2.0, 2.0),
            "stem_tilt_z":  (-2.0, 2.0),
            "cap_offset_y": (-0.02, 0.0),
        },
        "palette": [
            ([0.78, 0.22, 0.18], [0.92, 0.92, 0.85], [0.95, 0.92, 0.78]),
            ([0.55, 0.32, 0.18], [0.85, 0.78, 0.65], [0.92, 0.85, 0.55]),
            ([0.85, 0.62, 0.45], [0.88, 0.85, 0.78], [0.78, 0.65, 0.45]),
            ([0.62, 0.42, 0.55], [0.85, 0.80, 0.78], [0.78, 0.72, 0.62]),
        ],
    },

    "squash_settle": {
        "label": "Squash Settle",
        "notes":
            "Whole mushroom compressed vertically — the cap and stem "
            "both shrink in y, expand in xz. Reads as 'just landed'.",
        "base_dna": {
            "scale": (1.0, 1.5),
            "part_curve":  (0.25, 0.55),
            "part_width":  (0.7, 1.2),
            "part_length": (1.0, 1.6),
            "part_taper":  (0.45, 0.75),
            "symmetry":    (4.0, 8.0),
            "edge_type":   (0.0, 0.40),
            "leaf_density":(0.25, 0.55),
            "sociality":   (0.0, 0.40),
            "inflorescence":(0.0, 0.30),
            "transparency":(0.0, 0.15),
            "iridescence": (0.0, 0.10),
            "roughness":   (0.55, 0.78),
        },
        "deformation": {
            "cap_scale_x":  (1.20, 1.45),
            "cap_scale_y":  (0.55, 0.75),
            "cap_scale_z":  (1.20, 1.45),
            "cap_tilt_x":   (-2.0, 2.0),
            "cap_tilt_z":   (-2.0, 2.0),
            "stem_scale_x": (1.20, 1.45),    # stem squashes too
            "stem_scale_y": (0.40, 0.65),
            "stem_scale_z": (1.20, 1.45),
            "stem_tilt_x":  (-2.0, 2.0),
            "stem_tilt_z":  (-2.0, 2.0),
            "cap_offset_y": (-0.10, -0.02),  # cap drops with stem
        },
        "palette": [
            ([0.85, 0.55, 0.30], [0.92, 0.85, 0.70], [0.95, 0.88, 0.65]),
            ([0.45, 0.30, 0.20], [0.78, 0.72, 0.55], [0.85, 0.78, 0.50]),
            ([0.65, 0.35, 0.32], [0.85, 0.72, 0.62], [0.92, 0.82, 0.55]),
            ([0.78, 0.78, 0.55], [0.92, 0.92, 0.78], [0.95, 0.92, 0.62]),
        ],
    },

    "wind_lean": {
        "label": "Wind Lean",
        "notes":
            "Whole stem tilted by wind / weight; cap follows the lean. "
            "Subtle s-curve from the stem-tilt + counter-tilt on cap.",
        "base_dna": {
            "scale": (0.9, 1.5),
            "part_curve":  (0.20, 0.50),
            "part_width":  (0.6, 1.0),
            "part_length": (1.2, 1.9),         # tall — shows lean better
            "part_taper":  (0.55, 0.80),
            "symmetry":    (4.0, 7.0),
            "edge_type":   (0.0, 0.55),
            "leaf_density":(0.25, 0.50),
            "sociality":   (0.0, 0.35),
            "inflorescence":(0.0, 0.25),
            "transparency":(0.0, 0.15),
            "iridescence": (0.0, 0.10),
            "roughness":   (0.50, 0.75),
        },
        "deformation": {
            "cap_scale_x":  (0.95, 1.10),
            "cap_scale_y":  (0.85, 1.05),
            "cap_scale_z":  (0.95, 1.10),
            "cap_tilt_x":   (-12.0, -4.0),    # cap tilts back to stay level
            "cap_tilt_z":   (-12.0, -4.0),
            "stem_scale_x": (1.0, 1.10),
            "stem_scale_y": (1.0, 1.10),
            "stem_scale_z": (1.0, 1.10),
            "stem_tilt_x":  (8.0, 22.0),      # KEY — strong stem lean
            "stem_tilt_z":  (8.0, 22.0),
            "cap_offset_y": (0.0, 0.04),
        },
        "palette": [
            ([0.78, 0.72, 0.55], [0.92, 0.90, 0.82], [0.95, 0.92, 0.78]),
            ([0.65, 0.45, 0.30], [0.88, 0.80, 0.65], [0.88, 0.78, 0.50]),
            ([0.55, 0.35, 0.20], [0.78, 0.70, 0.55], [0.85, 0.78, 0.45]),
            ([0.40, 0.25, 0.18], [0.72, 0.65, 0.50], [0.82, 0.72, 0.42]),
        ],
    },

    "inflate_bloat": {
        "label": "Inflate Bloat",
        "notes":
            "Cap puffed up like a balloon, stem swollen (puffball / "
            "Lycoperdon read). Both directions enlarged from base form.",
        "base_dna": {
            "scale": (0.9, 1.4),
            "part_curve":  (0.30, 0.60),       # rounder caps preferred
            "part_width":  (0.7, 1.1),
            "part_length": (0.6, 1.1),         # shorter — puffballs aren't tall
            "part_taper":  (0.30, 0.55),       # bulbous stem base
            "symmetry":    (4.0, 7.0),
            "edge_type":   (0.0, 0.30),
            "leaf_density":(0.40, 0.70),
            "sociality":   (0.0, 0.40),
            "inflorescence":(0.0, 0.30),
            "transparency":(0.0, 0.20),
            "iridescence": (0.0, 0.12),
            "roughness":   (0.45, 0.70),
        },
        "deformation": {
            "cap_scale_x":  (1.35, 1.70),       # KEY — big puff
            "cap_scale_y":  (1.40, 1.85),
            "cap_scale_z":  (1.35, 1.70),
            "cap_tilt_x":   (-2.0, 2.0),
            "cap_tilt_z":   (-2.0, 2.0),
            "stem_scale_x": (1.35, 1.65),       # KEY — swollen stem
            "stem_scale_y": (0.95, 1.20),
            "stem_scale_z": (1.35, 1.65),
            "stem_tilt_x":  (-2.0, 2.0),
            "stem_tilt_z":  (-2.0, 2.0),
            "cap_offset_y": (0.0, 0.05),
        },
        "palette": [
            ([0.92, 0.88, 0.75], [0.95, 0.92, 0.82], [0.95, 0.90, 0.65]),
            ([0.85, 0.62, 0.55], [0.92, 0.82, 0.75], [0.92, 0.85, 0.55]),
            ([0.78, 0.85, 0.78], [0.92, 0.95, 0.88], [0.85, 0.92, 0.55]),
            ([0.95, 0.62, 0.30], [0.92, 0.82, 0.62], [0.95, 0.85, 0.55]),
        ],
    },

    "wilt_collapse": {
        "label": "Wilt Collapse",
        "notes":
            "Cap drooping heavily to one side, stem buckling. Asymmetric "
            "wilt — what an aged mushroom looks like just before falling.",
        "base_dna": {
            "scale": (0.9, 1.4),
            "part_curve":  (0.20, 0.60),
            "part_width":  (0.6, 1.1),
            "part_length": (1.0, 1.6),
            "part_taper":  (0.60, 0.85),
            "symmetry":    (4.0, 7.0),
            "edge_type":   (0.30, 0.85),       # ring / wavy edge
            "leaf_density":(0.30, 0.60),
            "sociality":   (0.0, 0.40),
            "inflorescence":(0.0, 0.30),
            "transparency":(0.0, 0.25),
            "iridescence": (0.0, 0.15),
            "roughness":   (0.55, 0.85),
        },
        "deformation": {
            "cap_scale_x":  (1.20, 1.50),
            "cap_scale_y":  (0.40, 0.65),       # heavy droop
            "cap_scale_z":  (1.20, 1.50),
            "cap_tilt_x":   (15.0, 35.0),       # KEY — strong asymmetric tilt
            "cap_tilt_z":   (-25.0, -10.0),
            "stem_scale_x": (1.0, 1.15),
            "stem_scale_y": (0.75, 0.95),
            "stem_scale_z": (1.0, 1.15),
            "stem_tilt_x":  (5.0, 18.0),         # stem bends with cap weight
            "stem_tilt_z":  (-15.0, -3.0),
            "cap_offset_y": (-0.04, 0.0),
        },
        "palette": [
            ([0.55, 0.30, 0.18], [0.78, 0.65, 0.45], [0.85, 0.72, 0.42]),
            ([0.42, 0.32, 0.22], [0.65, 0.55, 0.42], [0.72, 0.62, 0.38]),
            ([0.65, 0.45, 0.30], [0.85, 0.72, 0.55], [0.92, 0.82, 0.55]),
            ([0.35, 0.22, 0.15], [0.55, 0.45, 0.32], [0.72, 0.55, 0.30]),
        ],
    },
}


def sample_archetype(name: str, spec: dict, n: int) -> list[dict]:
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    out: list[dict] = []
    for i in range(n):
        cfg: dict = {}

        # Base DNA — sample within ranges.
        for key, (lo, hi) in spec["base_dna"].items():
            cfg[key] = round(lo + rng.random() * (hi - lo), 4)
        cfg["body_type"] = 3.0
        cfg.setdefault("segments", 4.0)
        cfg.setdefault("part_tilt", 0.0)

        pri, sec, ter = rng.choice(spec["palette"])
        tint = lambda c: max(0.0, min(1.0, c + rng.uniform(-0.05, 0.05)))
        cfg["primary_color"]   = [round(tint(pri[j]), 4) for j in range(3)]
        cfg["secondary_color"] = [round(tint(sec[j]), 4) for j in range(3)]
        cfg["tertiary_color"]  = [round(tint(ter[j]), 4) for j in range(3)]

        # Deformation block — the lab reads this and applies it post-build.
        deform: dict = {}
        for key, (lo, hi) in spec["deformation"].items():
            deform[key] = round(lo + rng.random() * (hi - lo), 4)
        cfg["_deform"] = deform

        cfg["_cluster"] = name
        cfg["_id"] = f"sf_{name}_{i + 1:02d}"
        cfg["seed"] = rng.randint(0, 99999)
        out.append(cfg)
    return out


def main() -> None:
    GALLERY_DIR.mkdir(parents=True, exist_ok=True)

    # Wipe stale outputs so reruns are clean.
    for old in GALLERY_DIR.glob("sf_*.json"):
        old.unlink()
    for old in GALLERY_DIR.glob("sf_*.png"):
        old.unlink()

    entries: list[dict] = []
    total = 0
    for arch_name, spec in ARCHETYPES.items():
        variants = sample_archetype(arch_name, spec, n=12)
        for v in variants:
            cfg_path = GALLERY_DIR / f"{v['_id']}.json"
            with cfg_path.open("w", encoding="utf-8") as f:
                json.dump(v, f, indent=2)
            entries.append({
                "id":   v["_id"],
                "notes": spec["notes"],
                "layout": arch_name,
                "interpretation": spec["label"],
                "image":  f"/softbody-fungus-gallery/{v['_id']}.png",
                "config": f"/softbody-fungus-gallery/{v['_id']}.json",
            })
            total += 1

    manifest = {
        "version": 1,
        "description":
            "Soft-body fungus gallery — 60 FungusMorphology mushrooms "
            "with 5 deformation poses (gravity droop / squash settle / "
            "wind lean / inflate bloat / wilt collapse) applied as "
            "per-node geometric transforms after FungusMorphology builds. "
            "Each pose reads as a soft-body mushroom captured mid-frame.",
        "entries": entries,
    }
    with (GALLERY_DIR / "manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Wrote {total} configs across {len(ARCHETYPES)} archetypes to {GALLERY_DIR}")


if __name__ == "__main__":
    main()
