#!/usr/bin/env python3
"""Prefab-sculpture auto-research generator.

Six families, one per sculptural lineage, each a `mode` of prefab_sculpture.gd:
  cast (Whiteread) · twist (Sosnowska) · accumulation (Donovan) ·
  web (Saraceno) · assemblage (Genzken/Hirschhorn) · bio (Yi/Huyghe).
Generates scored DNA specimens (varied by seed + colour register), keeps the
best few per family, writes them + a GalleryView manifest into the encyclopedia
sculpture-gallery.
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\sculpture-gallery"
SCENE = "res://commons/artifacts/prefab_sculpture/prefab_sculpture.tscn"

# palette triads: (color_a primary, color_b secondary, accent)
CONCRETE = [("0.82,0.82,0.80", "0.60,0.60,0.58", "0.42,0.42,0.40"),
            ("0.70,0.69,0.66", "0.50,0.50,0.48", "0.34,0.33,0.31")]
STEEL = [("0.60,0.62,0.66", "0.44,0.46,0.50", "0.88,0.40,0.12"),
         ("0.52,0.54,0.58", "0.38,0.40,0.44", "0.92,0.86,0.20")]
PEARL = [("0.93,0.93,0.96", "0.80,0.82,0.88", "0.72,0.86,1.00"),
         ("0.96,0.90,0.92", "0.86,0.80,0.85", "0.92,0.72,0.86")]
COSMOS = [("0.10,0.11,0.16", "0.08,0.09,0.13", "0.42,0.72,1.00"),
          ("0.12,0.10,0.17", "0.09,0.08,0.12", "0.80,0.50,1.00")]
POP = [("0.95,0.30,0.20", "0.20,0.50,0.95", "0.98,0.82,0.12"),
       ("0.92,0.22,0.60", "0.20,0.80,0.52", "0.98,0.62,0.12")]
BIO = [("0.55,0.85,0.60", "0.40,0.70,0.55", "0.62,1.00,0.72"),
       ("0.86,0.60,0.70", "0.60,0.42,0.55", "1.00,0.72,0.86"),
       ("0.40,0.70,0.75", "0.30,0.55,0.60", "0.52,0.95,0.95")]
# contradiction modes: (core, secondary, accent/glow). chrome+glass are fixed
# archetypes in the artifact — these tint the heavy core + the emissive/glass.
APPARATUS_PAL = [("0.55,0.55,0.53", "0.80,0.82,0.85", "0.40,0.80,1.00"),
                 ("0.48,0.47,0.46", "0.78,0.80,0.84", "0.95,0.55,0.15"),
                 ("0.52,0.50,0.54", "0.80,0.82,0.85", "0.75,0.45,1.00")]
ORGAN_PAL = [("0.85,0.62,0.66", "0.80,0.82,0.85", "1.00,0.50,0.55"),
             ("0.55,0.82,0.72", "0.80,0.82,0.85", "0.40,1.00,0.80"),
             ("0.80,0.80,0.86", "0.78,0.80,0.84", "0.60,0.80,1.00")]
# reference-mix wave 2: (primary, secondary, accent)
BOTANICAL_PAL = [("0.93,0.93,0.91", "0.55,0.42,0.22", "0.95,0.85,0.30"),
                 ("0.85,0.15,0.15", "0.50,0.40,0.22", "0.90,0.70,0.20"),
                 ("0.85,0.35,0.55", "0.52,0.42,0.24", "0.95,0.80,0.40")]
DRAPE_PAL = [("0.86,0.84,0.80", "0.20,0.50,0.95", "0.95,0.20,0.20"),
             ("0.84,0.82,0.78", "0.95,0.20,0.60", "0.20,0.90,0.40")]
TOTEM_PAL = [("0.90,0.20,0.30", "0.20,0.55,0.90", "0.95,0.80,0.20"),
             ("0.30,0.80,0.55", "0.85,0.30,0.70", "0.95,0.85,0.25")]
JUDD_PAL = [("0.90,0.20,0.20", "0.20,0.50,0.90", "0.95,0.80,0.10")]
# reference-mix wave 3: nature-under-glass, monumental object, machine ecology
VITRINE_PAL = [("0.34,0.62,0.30", "0.55,0.55,0.53", "0.90,0.95,1.00"),
               ("0.40,0.68,0.34", "0.50,0.50,0.48", "0.85,0.92,1.00"),
               ("0.30,0.58,0.28", "0.60,0.60,0.58", "0.95,0.97,1.00")]
MESH_PAL = [("0.80,0.88,0.70", "0.55,0.45,0.30", "0.70,0.90,0.60"),
            ("0.86,0.84,0.74", "0.50,0.42,0.30", "0.80,0.85,0.70"),
            ("0.78,0.86,0.82", "0.52,0.44,0.32", "0.72,0.92,0.80")]
EARTHWORK_PAL = [("0.45,0.32,0.20", "0.40,0.36,0.30", "0.55,0.45,0.35"),
                 ("0.50,0.36,0.22", "0.42,0.38,0.32", "0.60,0.50,0.38"),
                 ("0.38,0.28,0.18", "0.38,0.34,0.28", "0.58,0.48,0.36")]
VESSEL_PAL = [("0.90,0.88,0.82", "0.85,0.83,0.78", "0.95,0.85,0.60"),
              ("0.88,0.86,0.84", "0.82,0.80,0.78", "0.80,0.90,1.00"),
              ("0.92,0.90,0.86", "0.86,0.84,0.80", "1.00,0.78,0.62")]
COLUMN_PAL = [("0.90,0.90,0.88", "0.30,0.31,0.34", "0.75,0.75,0.78"),
              ("0.92,0.91,0.86", "0.26,0.27,0.30", "0.70,0.72,0.78"),
              ("0.88,0.88,0.90", "0.34,0.34,0.36", "0.78,0.78,0.80")]
LUMEN_PAL = [("0.08,0.08,0.10", "0.06,0.06,0.07", "1.00,0.98,0.92"),
             ("0.09,0.09,0.11", "0.06,0.06,0.08", "0.70,0.85,1.00"),
             ("0.10,0.09,0.12", "0.07,0.06,0.08", "1.00,0.75,0.40")]
THREAD_PAL = [("0.85,0.12,0.12", "0.16,0.12,0.10", "0.95,0.20,0.20"),
              ("0.80,0.10,0.14", "0.14,0.11,0.10", "0.90,0.18,0.22"),
              ("0.88,0.16,0.16", "0.18,0.13,0.11", "1.00,0.25,0.25")]
GLOW_PAL = [("0.95,0.25,0.30", "0.20,0.14,0.12", "1.00,0.40,0.50"),
            ("0.90,0.20,0.45", "0.18,0.12,0.14", "1.00,0.35,0.65"),
            ("0.98,0.30,0.22", "0.20,0.14,0.10", "1.00,0.50,0.30")]
BLOCK_PAL = [("0.92,0.92,0.94", "0.05,0.05,0.06", "0.55,0.80,1.00"),
             ("0.90,0.90,0.92", "0.06,0.06,0.07", "0.95,0.85,0.50"),
             ("0.94,0.94,0.96", "0.05,0.05,0.07", "0.70,1.00,0.80")]
# reference-mix wave 4: filigree shadow, spiral shards, gradient-on-lava, radial burst
LATTICE_PAL = [("0.18,0.18,0.20", "0.14,0.14,0.16", "0.80,0.80,0.85"),
               ("0.20,0.16,0.14", "0.16,0.13,0.12", "0.90,0.70,0.45"),
               ("0.16,0.18,0.22", "0.12,0.14,0.17", "0.60,0.80,1.00")]
SPIRAL_PAL = [("0.62,0.34,0.18", "0.20,0.18,0.16", "0.85,0.55,0.30"),
              ("0.55,0.30,0.16", "0.18,0.16,0.15", "0.80,0.48,0.26"),
              ("0.50,0.40,0.30", "0.16,0.15,0.14", "0.75,0.60,0.40")]
GRADIENT_PAL = [("0.90,0.50,0.70", "0.05,0.05,0.06", "0.60,0.90,1.00"),
                ("0.60,0.85,0.90", "0.06,0.05,0.05", "0.95,0.60,0.85"),
                ("0.95,0.80,0.30", "0.05,0.06,0.05", "0.55,0.75,1.00")]
BURST_PAL = [("0.95,0.95,0.95", "0.85,0.85,0.88", "0.70,0.85,1.00"),
             ("0.96,0.94,0.90", "0.84,0.84,0.86", "1.00,0.80,0.40"),
             ("0.92,0.94,0.97", "0.82,0.84,0.88", "0.60,1.00,0.85")]
# wave 5: glowing canopy, algae bioreactor, draped net-cave
LUMICANOPY_PAL = [("0.72,0.42,0.50", "0.45,0.32,0.45", "0.20,0.95,0.90"),
                  ("0.78,0.45,0.55", "0.48,0.34,0.48", "0.95,0.25,0.85"),
                  ("0.70,0.40,0.52", "0.42,0.30,0.44", "0.30,0.70,1.00")]
BIOREACTOR_PAL = [("0.93,0.95,0.96", "0.45,0.85,0.35", "0.45,1.00,0.40"),
                  ("0.90,0.94,0.95", "0.50,0.88,0.40", "0.55,1.00,0.50")]
NETCAVE_PAL = [("0.95,0.45,0.20", "0.10,0.09,0.08", "0.30,0.85,0.40"),
               ("0.92,0.30,0.22", "0.10,0.08,0.08", "0.90,0.70,0.20")]
# wave 6: pigment mound, colour field, reed bed, dotted gourd, strut field, horn garden
PIGMENT_PAL = [("0.78,0.10,0.08", "0.50,0.06,0.05", "0.95,0.30,0.20"),
               ("0.10,0.18,0.62", "0.07,0.12,0.45", "0.30,0.45,0.95"),
               ("0.92,0.72,0.08", "0.65,0.50,0.05", "1.00,0.85,0.20")]
COLORFIELD_PAL = [("0.95,0.30,0.30", "0.20,0.50,0.95", "0.95,0.85,0.20"),
                  ("0.30,0.85,0.55", "0.85,0.30,0.70", "0.20,0.70,1.00")]
REEDBED_PAL = [("0.80,0.66,0.34", "0.30,0.55,0.22", "0.90,0.80,0.40"),
               ("0.76,0.62,0.32", "0.34,0.58,0.26", "0.85,0.78,0.42")]
DOTGOURD_PAL = [("0.96,0.78,0.10", "0.06,0.06,0.06", "0.95,0.85,0.20"),
                ("0.95,0.45,0.10", "0.06,0.06,0.06", "0.98,0.70,0.15")]
STRUT_PAL = [("0.82,0.66,0.42", "0.12,0.12,0.13", "0.70,0.55,0.35"),
             ("0.78,0.62,0.40", "0.14,0.13,0.12", "0.66,0.52,0.34")]
HORN_PAL = [("0.90,0.20,0.20", "0.12,0.12,0.13", "0.30,0.90,1.00"),
            ("0.20,0.55,0.90", "0.12,0.12,0.13", "1.00,0.85,0.20")]
# wave 7 (4-agent synthesis): Do Ho Suh translucent fabric architecture
FABRICARCH_PAL = [("0.98,0.55,0.45", "0.40,0.85,0.70", "0.95,0.30,0.65"),
                  ("0.95,0.45,0.55", "0.55,0.80,0.95", "0.98,0.70,0.30"),
                  ("0.60,0.85,0.92", "0.98,0.60,0.40", "0.85,0.40,0.90")]
# wave 8 (4-agent synthesis): Takuro Kuwata encrusted ceramic — glaze/gold/bead triad
ENCRUSTED_PAL = [("0.93,0.28,0.55", "0.85,0.66,0.22", "0.30,0.70,0.95"),
                 ("0.25,0.62,0.95", "0.85,0.68,0.25", "0.95,0.82,0.30"),
                 ("0.45,0.82,0.45", "0.82,0.64,0.24", "0.95,0.35,0.60")]
# wave 9 (4-agent synthesis): Cornelia Parker exploded-shed debris cloud
EXPLODEDSHED_PAL = [("0.16,0.11,0.07", "0.45,0.47,0.50", "1.00,0.85,0.55"),
                    ("0.12,0.10,0.09", "0.40,0.42,0.46", "1.00,0.95,0.80"),
                    ("0.20,0.13,0.08", "0.50,0.45,0.40", "1.00,0.70,0.40")]
# wave 10 (4-agent synthesis): Louise Bourgeois "Maman" — bronze spider + marble eggs
SPIDER_PAL = [("0.18,0.16,0.14", "0.90,0.88,0.83", "0.45,0.40,0.34"),
              ("0.14,0.15,0.17", "0.92,0.92,0.94", "0.40,0.44,0.48"),
              ("0.22,0.17,0.12", "0.88,0.84,0.76", "0.55,0.42,0.28")]
# wave 11 (4-agent synthesis): Jeff Koons mirror-chrome balloon dog
BALLOONDOG_PAL = [("0.95,0.10,0.55", "0.78,0.08,0.45", "1.00,0.45,0.75"),
                  ("0.15,0.45,0.95", "0.12,0.38,0.82", "0.45,0.70,1.00"),
                  ("0.98,0.50,0.08", "0.86,0.42,0.06", "1.00,0.72,0.30"),
                  ("0.90,0.80,0.10", "0.80,0.70,0.08", "1.00,0.95,0.40")]
# wave 12 (4-agent synthesis): Alexander Calder large hanging mobile — primary-colour plates
MOBILE_PAL = [("0.88,0.13,0.10", "0.95,0.82,0.08", "0.12,0.32,0.80"),
              ("0.10,0.10,0.10", "0.93,0.93,0.90", "0.88,0.15,0.12"),
              ("0.95,0.80,0.08", "0.12,0.35,0.82", "0.10,0.10,0.10")]
# wave 13 (4-agent synthesis): Barbara Hepworth pierced-and-strung carved form (CSG-bored)
PIERCED_PAL = [("0.62,0.42,0.22", "0.62,0.76,0.90", "0.95,0.93,0.85"),
               ("0.90,0.88,0.83", "0.66,0.80,0.92", "0.96,0.96,0.92"),
               ("0.42,0.52,0.42", "0.85,0.90,0.92", "0.92,0.90,0.82")]
# wave 14 (4-agent synthesis): Claes Oldenburg monumental pop lipstick on caterpillar tracks
LIPSTICK_PAL = [("0.85,0.10,0.15", "0.85,0.66,0.22", "0.26,0.30,0.20"),
                ("0.90,0.15,0.42", "0.82,0.82,0.86", "0.20,0.22,0.24"),
                ("0.78,0.06,0.10", "0.86,0.68,0.25", "0.24,0.28,0.20")]
# wave 15 (4-agent synthesis): Dan Flavin fluorescent-tube light composition
FLAVIN_PAL = [("0.95,0.15,0.25", "0.20,0.45,0.95", "0.95,0.85,0.20"),
              ("0.95,0.30,0.65", "0.30,0.90,0.45", "0.65,0.30,0.95"),
              ("0.40,0.85,0.95", "0.95,0.55,0.15", "0.90,0.55,0.85")]
# wave 16 (4-agent synthesis): Robert Smithson "Spiral Jetty" land-art earthwork
SPIRALJETTY_PAL = [("0.10,0.10,0.11", "0.80,0.26,0.28", "0.90,0.88,0.82"),
                   ("0.13,0.12,0.11", "0.86,0.34,0.32", "0.86,0.82,0.76"),
                   ("0.08,0.09,0.11", "0.74,0.20,0.26", "0.92,0.90,0.85")]
# wave 17 (4-agent synthesis): Sol LeWitt modular open-cube structure (white edge-lattice)
LEWITT_PAL = [("0.93,0.93,0.91", "0.84,0.85,0.87", "0.72,0.74,0.78"),
              ("0.95,0.95,0.96", "0.82,0.83,0.85", "0.65,0.67,0.72"),
              ("0.91,0.91,0.89", "0.85,0.84,0.82", "0.76,0.74,0.71")]


def j(v):
    return round(v, 3)


def base(rng, mode, pal):
    a, b, c = rng.choice(pal)
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_cast(rng):
    d = base(rng, "cast", CONCRETE)
    d.update({"sculpt_height": j(rng.uniform(1.3, 1.9)), "sculpt_width": j(rng.uniform(0.7, 1.1)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.0, "rough_amt": 0.92, "emissive": False})
    return d, "Cast — negative space", "Whiteread: the solidified gaps between absent furniture, stacked as matte plaster blocks."


def fam_twist(rng):
    d = base(rng, "twist", STEEL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(0.6, 0.95)),
              "complexity": rng.randint(5, 8), "metallic_amt": 0.7, "rough_amt": 0.35, "emissive": False})
    return d, "Twisted frame", "Sosnowska: a galvanized box-frame tower warped and leaned as it rises."


def fam_accum(rng):
    d = base(rng, "accumulation", PEARL)
    d.update({"sculpt_height": j(rng.uniform(0.8, 1.3)), "sculpt_width": j(rng.uniform(1.0, 1.5)),
              "unit_count": rng.randint(160, 320), "metallic_amt": 0.1, "rough_amt": 0.4, "emissive": False})
    return d, "Accumulation landscape", "Donovan: one found unit, multiplied into a teeming pearly landscape."


def fam_web(rng):
    d = base(rng, "web", COSMOS)
    d.update({"sculpt_height": j(rng.uniform(1.4, 1.9)), "sculpt_width": j(rng.uniform(1.2, 1.6)),
              "unit_count": rng.randint(120, 220), "metallic_amt": 0.2, "rough_amt": 0.4, "emissive": True})
    return d, "Tensile web", "Saraceno: glowing nodes linked into an airborne cosmic network."


def fam_assemblage(rng):
    d = base(rng, "assemblage", POP)
    d.update({"sculpt_height": j(rng.uniform(1.2, 1.8)), "sculpt_width": j(rng.uniform(0.8, 1.2)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.3, "rough_amt": 0.6, "emissive": False})
    return d, "Pop assemblage", "Genzken / Hirschhorn: a precarious vernacular stack in clashing pop colour."


def fam_bio(rng):
    d = base(rng, "bio", BIO)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.5)), "sculpt_width": j(rng.uniform(0.8, 1.2)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.0, "rough_amt": 0.25, "emissive": True})
    return d, "Bio-growth", "Anicka Yi / Huyghe: a wet translucent membrane cluster — a machine ecology."


def fam_apparatus(rng):
    d = base(rng, "apparatus", APPARATUS_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.2, 1.7)), "sculpt_width": j(rng.uniform(0.8, 1.2)),
              "complexity": rng.randint(3, 5), "metallic_amt": 0.4, "rough_amt": 0.7, "emissive": True})
    return d, "Apparatus — contradiction", "A concrete mass pierced by a chrome rod, a glass/emissive core seated in a socket, and abstract pseudo-controls: three contradictory materials interpenetrating, function only implied."


def fam_organ(rng):
    d = base(rng, "organ", ORGAN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.5)), "sculpt_width": j(rng.uniform(0.8, 1.2)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.2, "rough_amt": 0.3, "emissive": True})
    return d, "Organ — contradiction", "A warm wax membrane run through by cold chrome, an emissive nodule and a glass bead embedded, with pseudo-valves: a bio-machine of fused contradictory matter."


def fam_botanical(rng):
    d = base(rng, "botanical", BOTANICAL_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.6)), "sculpt_width": j(rng.uniform(0.7, 1.1)),
              "complexity": rng.randint(4, 8), "metallic_amt": 0.6, "rough_amt": 0.4, "emissive": False})
    return d, "Botanical bronze", "Kiwanga / Quinn: a giant flower cast in bronze — soft organic form rendered in hard metal."


def fam_drape(rng):
    d = base(rng, "drape", DRAPE_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.4)), "sculpt_width": j(rng.uniform(1.0, 1.5)),
              "complexity": rng.randint(3, 6), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Draped assemblage", "Kelley / Hutchins: slumped cast cloth over furniture legs, studded with R/G/B lights and a flag scrap."


def fam_totem(rng):
    d = base(rng, "totem", TOTEM_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.4)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(5, 9), "unit_count": rng.randint(240, 420),
              "metallic_amt": 0.2, "rough_amt": 0.5, "emissive": False})
    return d, "Beaded totem", "Jeffrey Gibson: a symmetric ceremonial totem of beads, radiating fans, and cascading rainbow fringe."


def fam_judd(rng):
    d = base(rng, "judd", JUDD_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 2.0)), "sculpt_width": j(rng.uniform(0.8, 1.2)),
              "complexity": rng.randint(4, 8), "metallic_amt": 0.2, "rough_amt": 0.3, "emissive": False})
    return d, "Judd stack", "Donald Judd: a clean modular stack of evenly-spaced lacquer-colour boxes — minimalism as counterpoint."


def fam_vitrine(rng):
    d = base(rng, "vitrine", VITRINE_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.5)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 6), "unit_count": rng.randint(60, 120),
              "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": False})
    return d, "Vitrine — nature under glass", "A glass greenhouse on a concrete plinth sealing a live grass patch: hard architecture preserving soft nature behind glass."


def fam_mesh(rng):
    d = base(rng, "mesh", MESH_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 2.0)), "sculpt_width": j(rng.uniform(0.9, 1.3)),
              "complexity": rng.randint(4, 6), "unit_count": rng.randint(300, 600),
              "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": False})
    return d, "Knit mesh membrane", "Ernesto Neto: an open knitted-net tower of soft stitches, drooping and biomorphic, on splayed roots."


def fam_earthwork(rng):
    d = base(rng, "earthwork", EARTHWORK_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.3, 1.8)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.0, "rough_amt": 0.95, "emissive": False})
    return d, "Earthwork creature", "An earthen fiber mass grazing on twig legs over a dark soil mound, a hard mirror disc set in the earth."


def fam_vessel(rng):
    d = base(rng, "vessel", VESSEL_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 2.2)), "sculpt_width": j(rng.uniform(0.7, 1.1)),
              "complexity": rng.randint(3, 5), "metallic_amt": 0.0, "rough_amt": 0.3,
              "emissive": rng.random() < 0.5})
    return d, "Monumental vessel", "A humble household vessel — bottle, amphora or funnel — rendered monumental in translucent alabaster."


def fam_column(rng):
    d = base(rng, "column", COLUMN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.4)), "sculpt_width": j(rng.uniform(0.9, 1.4)),
              "complexity": rng.randint(1, 3), "metallic_amt": 0.2, "rough_amt": 0.5, "emissive": False})
    return d, "Broken columns", "Diana Al-Hadid: broken classical marble columns on machined finned-metal bases — antiquity set on a heat-sink."


def fam_lumenarch(rng):
    d = base(rng, "lumenarch", LUMEN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.4)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(3, 6), "metallic_amt": 0.3, "rough_amt": 0.6, "emissive": True})
    return d, "Luminous arch", "A matte-black portal arch studded with glowing blocks: heavy dark mass riddled with brilliant light."


def fam_threadfield(rng):
    d = base(rng, "threadfield", THREAD_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 2.0)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "unit_count": rng.randint(300, 600), "complexity": rng.randint(3, 5),
              "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": False})
    return d, "Thread field", "Chiharu Shiota: a dense web of red threads raining from above onto a dark hull, dark keys suspended in the weave."


def fam_glowmound(rng):
    d = base(rng, "glowmound", GLOW_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.6)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(8, 16), "metallic_amt": 0.0, "rough_amt": 0.35, "emissive": True})
    return d, "Glow mound", "Pierre Huyghe: a bioluminescent translucent mound glowing from within, a dark turned-spiral pendant hung above it."


def fam_blockfield(rng):
    d = base(rng, "blockfield", BLOCK_PAL)
    d.update({"sculpt_height": j(rng.uniform(0.8, 1.4)), "sculpt_width": j(rng.uniform(1.3, 1.8)),
              "unit_count": rng.randint(120, 300), "complexity": rng.randint(5, 7),
              "metallic_amt": 0.1, "rough_amt": 0.5, "emissive": False})
    return d, "Block field", "A topographic grid of white cubes rising into a model-city heightfield on a black reflective plinth."


def fam_lattice(rng):
    d = base(rng, "lattice", LATTICE_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.5)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.7, "rough_amt": 0.4, "emissive": False})
    return d, "Filigree cube", "Anila Quayyum Agha: a laser-cut lace cube balanced on a vertex over a dark mirror floor, all openwork shadow."


def fam_spiralstack(rng):
    d = base(rng, "spiralstack", SPIRAL_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(0.7, 1.1)),
              "complexity": rng.randint(5, 10), "metallic_amt": 0.5, "rough_amt": 0.5, "emissive": False})
    return d, "Spiral-tile column", "Curved rusty tiles threaded up a thin rod in a golden-angle helix — a vertebral stack of shards."


def fam_gradientpillar(rng):
    d = base(rng, "gradientpillar", GRADIENT_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(0.6, 0.95)),
              "complexity": rng.randint(8, 14), "metallic_amt": 0.1, "rough_amt": 0.15,
              "emissive": rng.random() < 0.4})
    return d, "Gradient pillar on lava", "A glossy candy-rainbow tube rising from a rough black lava base — slick gradient against craggy dark rock."


def fam_burst(rng):
    d = base(rng, "burst", BURST_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.2, 1.8)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "unit_count": rng.randint(400, 900), "complexity": rng.randint(3, 5),
              "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": rng.random() < 0.5})
    return d, "Radial burst", "Thousands of fine spikes radiating from a centre into a soft supernova halo — a toothpick sunburst."


def fam_lumicanopy(rng):
    d = base(rng, "lumicanopy", LUMICANOPY_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(1.6, 2.4)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Lumicanopy", "A giant glowing mushroom canopy on a soft knit stem, emissive light-strands radiating across its underside."


def fam_bioreactor(rng):
    d = base(rng, "bioreactor", BIOREACTOR_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.4)), "sculpt_width": j(rng.uniform(0.9, 1.4)),
              "complexity": rng.randint(6, 12), "unit_count": rng.randint(200, 500),
              "metallic_amt": 0.0, "rough_amt": 0.4, "emissive": True})
    return d, "Algae bioreactor", "The Living / EcoLogicStudio: a white triangulated lattice column with living green algae growing in its cells."


def fam_netcave(rng):
    d = base(rng, "netcave", NETCAVE_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(1.6, 2.4)),
              "unit_count": rng.randint(300, 600), "complexity": rng.randint(3, 6),
              "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": False})
    return d, "Net-cave canopy", "Ernesto Neto: a warm draped crochet net sagging overhead, anchored by tendrils to dark fibrous floor clumps."


def fam_pigment(rng):
    d = base(rng, "pigment", PIGMENT_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.6)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(1, 3), "metallic_amt": 0.0, "rough_amt": 1.0, "emissive": False})
    return d, "Pigment mound", "Anish Kapoor / Wolfgang Laib: a pure cone of saturated matte pigment spilling onto the floor."


def fam_colorfield(rng):
    d = base(rng, "colorfield", COLORFIELD_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 2.0)), "sculpt_width": j(rng.uniform(1.4, 2.0)),
              "unit_count": rng.randint(300, 700), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": False})
    return d, "Colour field", "Emmanuelle Moureaux: a floating volume of small cubes graded through the full spectrum."


def fam_reedbed(rng):
    d = base(rng, "reedbed", REEDBED_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "unit_count": rng.randint(40, 90), "metallic_amt": 0.0, "rough_amt": 0.55, "emissive": False})
    return d, "Reed bed", "A thicket of tall bamboo poles rising from a low grass patch — a vertical reed-stand."


def fam_dotgourd(rng):
    d = base(rng, "dotgourd", DOTGOURD_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.4)), "sculpt_width": j(rng.uniform(1.2, 1.6)),
              "complexity": rng.randint(8, 12), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": False})
    return d, "Dotted gourd", "Yayoi Kusama: a ribbed gourd in saturated yellow swarmed with black polka dots."


def fam_strutfield(rng):
    d = base(rng, "strutfield", STRUT_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.0, 1.5)), "sculpt_width": j(rng.uniform(1.4, 1.8)),
              "complexity": rng.randint(6, 12), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": False})
    return d, "Strut field", "A field of crossing pine struts on dark bases — a chaotic constructive timber lattice."


def fam_horngarden(rng):
    d = base(rng, "horngarden", HORN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.2, 1.8)), "sculpt_width": j(rng.uniform(1.2, 1.8)),
              "complexity": rng.randint(4, 8), "metallic_amt": 0.1, "rough_amt": 0.4,
              "emissive": rng.random() < 0.6})
    return d, "Horn garden", "A cluster of bright pop megaphone horns on thin stems, glowing at the mouth — a playful sound-garden."


def fam_fabricarch(rng):
    d = base(rng, "fabricarch", FABRICARCH_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 2.2)), "sculpt_width": j(rng.uniform(1.4, 2.0)),
              "complexity": rng.randint(3, 6), "metallic_amt": 0.0, "rough_amt": 0.5,
              "emissive": rng.random() < 0.7})
    return d, "Fabric architecture", "Do Ho Suh: a translucent sheer-fabric ghost-house over a steel armature — clustered coloured rooms you see straight through."


def fam_encrusted(rng):
    d = base(rng, "encrusted", ENCRUSTED_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.5, 2.0)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(6, 12), "unit_count": rng.randint(120, 260),
              "metallic_amt": 0.0, "rough_amt": 0.1, "emissive": rng.random() < 0.5})
    return d, "Encrusted ceramic", "Takuro Kuwata: a tea-jar drowned in thick candy glaze, kairagi beading and gold leaf — precious meets grotesque."


def fam_explodedshed(rng):
    d = base(rng, "explodedshed", EXPLODEDSHED_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.4)), "sculpt_width": j(rng.uniform(1.8, 2.4)),
              "complexity": rng.randint(5, 10), "unit_count": rng.randint(90, 170),
              "metallic_amt": 0.0, "rough_amt": 0.9, "emissive": rng.random() < 0.7})
    return d, "Exploded shed", "Cornelia Parker 'Cold Dark Matter': a garden shed's charred fragments frozen mid-explosion around a single glowing bulb."


def fam_spider(rng):
    d = base(rng, "spider", SPIDER_PAL)
    d.update({"sculpt_height": j(rng.uniform(2.2, 2.8)), "sculpt_width": j(rng.uniform(2.0, 2.6)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.7, "rough_amt": 0.5,
              "emissive": rng.random() < 0.6})
    return d, "Maman spider", "Louise Bourgeois: a monumental bronze spider arched high on spindly legs, a marble egg sac slung beneath its abdomen."


def fam_balloondog(rng):
    d = base(rng, "balloondog", BALLOONDOG_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.4, 1.9)), "sculpt_width": j(rng.uniform(1.6, 2.2)),
              "complexity": rng.randint(4, 7), "metallic_amt": 1.0, "rough_amt": 0.05,
              "emissive": rng.random() < 0.5})
    return d, "Balloon dog", "Jeff Koons: a child's twisted party-balloon dog blown up monumental in mirror-polished saturated chrome."


def fam_mobile(rng):
    d = base(rng, "mobile", MOBILE_PAL)
    d.update({"sculpt_height": j(rng.uniform(2.9, 3.4)), "sculpt_width": j(rng.uniform(2.6, 3.1)),
              "complexity": rng.randint(5, 8), "metallic_amt": 0.05, "rough_amt": 0.72, "emissive": False})
    return d, "Calder mobile", "Alexander Calder: a large hanging mobile — a cascade of balanced wire arms suspending flat biomorphic plates in primary colours."


def fam_pierced(rng):
    d = base(rng, "pierced", PIERCED_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.7, 2.2)), "sculpt_width": j(rng.uniform(1.0, 1.5)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.15, "rough_amt": 0.45,
              "emissive": rng.random() < 0.4})
    return d, "Hepworth pierced form", "Barbara Hepworth: a smooth carved mass pierced clean through (CSG-bored), its hollow painted pale, with taut strings stretched across the opening like a harp."


def fam_lipstick(rng):
    d = base(rng, "lipstick", LIPSTICK_PAL)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.6)), "sculpt_width": j(rng.uniform(1.4, 2.0)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.5, "rough_amt": 0.4,
              "emissive": rng.random() < 0.6})
    return d, "Oldenburg lipstick", "Claes Oldenburg: a monumental red lipstick ascending from a gold tube, perched on military caterpillar tracks — glamour on a war machine."


def fam_flavin(rng):
    d = base(rng, "flavin", FLAVIN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.6)), "sculpt_width": j(rng.uniform(1.8, 2.8)),
              "complexity": rng.randint(5, 9), "metallic_amt": 0.0, "rough_amt": 0.6,
              "emissive": rng.random() < 0.6})
    return d, "Flavin fluorescent", "Dan Flavin: a monument-to-Tatlin skyline of commercial fluorescent tubes glowing in a corner, washing the walls with coloured light."


def fam_spiraljetty(rng):
    d = base(rng, "spiraljetty", SPIRALJETTY_PAL)
    d.update({"sculpt_height": j(rng.uniform(0.45, 0.75)), "sculpt_width": j(rng.uniform(3.0, 3.8)),
              "complexity": rng.randint(4, 6), "unit_count": rng.randint(120, 210),
              "metallic_amt": 0.0, "rough_amt": 0.9, "emissive": rng.random() < 0.3})
    return d, "Spiral Jetty", "Robert Smithson: a counterclockwise coil of black basalt rock and earth spiralling out into the rose-red water of the Great Salt Lake — land art read from above."


def fam_lewitt(rng):
    d = base(rng, "lewitt", LEWITT_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.7, 2.3)), "sculpt_width": j(rng.uniform(1.8, 2.6)),
              "complexity": rng.randint(2, 4), "metallic_amt": 0.0, "rough_amt": 0.8,
              "emissive": False})
    return d, "LeWitt open cubes", "Sol LeWitt: a modular white lattice of open cubes defined only by their edges — a full grid, floor grid, stepped stack, or 'incomplete open cube', the serial system made visible."


FAMILIES = {"cast": fam_cast, "twist": fam_twist, "accumulation": fam_accum,
            "web": fam_web, "assemblage": fam_assemblage, "bio": fam_bio,
            "apparatus": fam_apparatus, "organ": fam_organ,
            "botanical": fam_botanical, "drape": fam_drape, "totem": fam_totem, "judd": fam_judd,
            "vitrine": fam_vitrine, "mesh": fam_mesh, "earthwork": fam_earthwork,
            "vessel": fam_vessel, "column": fam_column, "lumenarch": fam_lumenarch,
            "threadfield": fam_threadfield, "glowmound": fam_glowmound, "blockfield": fam_blockfield,
            "lattice": fam_lattice, "spiralstack": fam_spiralstack,
            "gradientpillar": fam_gradientpillar, "burst": fam_burst,
            "lumicanopy": fam_lumicanopy, "bioreactor": fam_bioreactor, "netcave": fam_netcave,
            "pigment": fam_pigment, "colorfield": fam_colorfield, "reedbed": fam_reedbed,
            "dotgourd": fam_dotgourd, "strutfield": fam_strutfield, "horngarden": fam_horngarden,
            "fabricarch": fam_fabricarch, "encrusted": fam_encrusted,
            "explodedshed": fam_explodedshed, "spider": fam_spider,
            "balloondog": fam_balloondog, "mobile": fam_mobile,
            "pierced": fam_pierced, "lipstick": fam_lipstick,
            "flavin": fam_flavin, "spiraljetty": fam_spiraljetty,
            "lewitt": fam_lewitt}


def score(d):
    s = 100.0
    s += float(d.get("sculpt_height", 1.5))           # taller reads bolder
    if d.get("emissive"):
        s += 1.5
    s += d.get("complexity", 0) * 0.2
    s += min(d.get("unit_count", 0), 300) * 0.005
    return s


def main():
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(31173)
    entries, render = [], []
    for fam, builder in FAMILIES.items():
        cands = []
        for _ in range(8):
            d, name, desc = builder(rng)
            cands.append((score(d), d, name, desc))
        cands.sort(key=lambda c: c[0], reverse=True)
        for rank, (sc, d, name, desc) in enumerate(cands[:3], 1):
            cid = "sculpt_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/sculpture-gallery/%s.png" % cid,
                            "config": "/sculpture-gallery/%s.json" % cid, "notes": "%s — %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Prefab sculpture auto-research — generative specimens across forty-five contemporary-sculpture lineages.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d sculpture specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])


if __name__ == "__main__":
    sys.exit(main())
