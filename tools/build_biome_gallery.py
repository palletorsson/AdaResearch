#!/usr/bin/env python3
"""build_biome_gallery.py — the biome's own catalogue.

Everything the living layer (`layers.biome`) can grow, in one place: the six
kingdoms and what each algo actually renders, the role vocabulary, the per-cell
mods, and the reaction grammar. Each kingdom card carries a real Godot capture
of `Biome_Gallery_<Kingdom>` (that kingdom's algos at tiers 1/3/5, a halo edge,
a mute cell).

Emits ada_encyclopedia/public/biome_gallery.json for the /biome-gallery page.

  python tools/build_biome_gallery.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia"))
IMG_DIR = os.path.join(ENC, "public", "biome-gallery")
OUT = os.path.join(ENC, "public", "biome_gallery.json")

KINGDOMS = [
    {"id": "flora", "name": "Flora", "color": "#59bf59",
     "blurb": "Plants. The algo splits the kingdom: woody algos grow real DNA-driven trees, everything else opens a botanical flower on a tier ladder (bluebell → orchid → daisy).",
     "algos": [
         {"algo": "lsystem", "renders": "tree morphology (DNA-driven L-system tree)", "token": "flora:lsystem:seed:t=4"},
         {"algo": "scatter", "renders": "botanical flower, preset by tier", "token": "flora:scatter:seed:t=3"},
     ]},
    {"id": "fungus", "name": "Fungus", "color": "#a674cc",
     "blurb": "Two substrates ship, and neither is the default (ruled 2026-07-21) — the map picks. `ca` is a 3D cellular automaton frozen at its spreading front: a voxel network, visibly computed. `mycelium` is space-colonised filaments: tapering hyphae, trunks thickening inward, tips hair-thin, visibly grown.",
     "algos": [
         {"algo": "ca", "renders": "MoldNetwork CA, gen-frozen as a spreading voxel network", "token": "fungus:ca:seed:t=5"},
         {"algo": "ca (tuned)", "renders": "same CA, per-cell rule and freeze generation", "token": "fungus:ca:seed:rule=4-6/5-7/10/M:gen=16"},
         {"algo": "mycelium", "renders": "space-colonised filaments — tapering hyphae, trunks thickening inward, tips hair-thin (the taper a voxel grid cannot hold)", "token": "fungus:mycelium:seed:t=5:d=1.0"},
         {"algo": "mycelium (sparse)", "renders": "same web, thinned — d= sets how densely the mat fills its disc", "token": "fungus:mycelium:seed:t=5:d=0.3"},
     ]},
    {"id": "fauna", "name": "Fauna", "color": "#e5994d",
     "blurb": "Creatures. A DNA-driven CritterEntity built from the shared morphology, with biome-compact geometry so a cell's creature is a grub that fits its cell rather than a fifteen-metre thread.",
     "algos": [
         {"algo": "dna", "renders": "CritterEntity — segmented body, legs, head", "token": "fauna:dna:seed:t=4"},
     ]},
    {"id": "mineral", "name": "Mineral", "color": "#99a3bf",
     "blurb": "Stone. No dispatcher substrate, so the layer grows its own specimen: a faceted crystal cluster of prism shards, metallic with a faint inner light.",
     "algos": [
         {"algo": "vein", "renders": "crystal cluster specimen", "token": "mineral:vein:seed:t=4"},
     ]},
    {"id": "water", "name": "Water", "color": "#5a8cd9",
     "blurb": "Still water. A reflective disc with two ripple rings and reeds at the rim — the quiet counterpart to the growing kingdoms.",
     "algos": [
         {"algo": "pool", "renders": "reflective pool + ripple rings + reeds", "token": "water:pool:seed:t=4"},
     ]},
    {"id": "meta", "name": "Meta", "color": "#e6e6e6",
     "blurb": "The kingdom that is not alive. A hovering emissive glyph — a ring crossed by two strokes, unshaded so it reads as a rune of light rather than an object.",
     "algos": [
         {"algo": "glyph", "renders": "hovering emissive glyph", "token": "meta:glyph:seed:t=4"},
     ]},
]

ROLES = [
    {"role": "seed", "what": "grows now — the cell stages its substrate at load"},
    {"role": "field", "what": "dormant, claimable — nothing until a reaction claims it"},
    {"role": "edge", "what": "declared boundary of a colony"},
    {"role": "halo", "what": "spills wilderness OUTWARD past the grid edge — a ground strip plus kingdom cover, thinning into the dark"},
    {"role": "mute", "what": "a declared vacuum. Nothing grows here on purpose — and a reaction can open it"},
]

MODS = [
    {"mod": "d=", "what": "density 0–1 — how full the cell packs"},
    {"mod": "t=", "what": "tier 1–5 — the intensity ladder (size, preset, colony radius)"},
    {"mod": "p=", "what": "palette"},
    {"mod": "clk=", "what": "clock: static | dwell | walk"},
    {"mod": "rule=", "what": "fungus only — override the CA rule string"},
    {"mod": "gen=", "what": "fungus only — the generation the CA freezes at (its thin spreading front)"},
]

TRIGGERS = [
    {"trigger": "catalyst", "what": "any catalyst mode hits this cell"},
    {"trigger": "catalyst.<mode>", "what": "one typed mode — chromatic, fractal, branching, cellular, swarm…"},
    {"trigger": "friend", "what": "any settled FRIEND creature enters the cell"},
    {"trigger": "friend.<power>", "what": "one lineage's power — neutralizer, bridger, escort, replicator…"},
    {"trigger": "touch", "what": "the player's body enters the cell"},
    {"trigger": "dwell", "what": "the player stays — attention, once per visit"},
    {"trigger": "tick", "what": "time, every tick_seconds"},
]

RESPONSES = [
    {"response": "seed", "what": "activate and STAGE this cell — an unmuted vacuum visibly opens"},
    {"response": "step", "what": "advance the local algorithm one generation"},
    {"response": "claim", "what": "expand into adjacent field cells, staging them"},
    {"response": "mute", "what": "silence the cell"},
    {"response": "unmute", "what": "lift the silence"},
    {"response": "mutate.<channel>", "what": "route into the mutator stack — colour, visibility, transform, glyph, part. NOTE the dot: ':' is the token separator"},
]

META = [
    {"key": "budget_instances", "what": "cap on batched instances; over budget the layer thins by even stride and says so"},
    {"key": "visibility_range", "what": "GPU culling distance for every batch"},
    {"key": "tick_seconds", "what": "how often `tick` fires (default 5)"},
    {"key": "dwell_seconds", "what": "how long counts as dwelling (default 2.5)"},
]


def main() -> int:
    for k in KINGDOMS:
        img = os.path.join(IMG_DIR, f"{k['id']}.png")
        k["image"] = f"/biome-gallery/{k['id']}.png" if os.path.exists(img) else None
        k["map"] = f"Biome_Gallery_{k['id'].capitalize()}"
    data = {
        "title": "The biome",
        "subtitle": "Everything the living layer can grow. Each kingdom shot from its own gallery map: every algo at tiers 1, 3 and 5, a halo edge behind, a mute cell in front.",
        "grammar": "kingdom:algo:role[:mod=val…][:on=trigger:response[/response…]]",
        "kingdoms": KINGDOMS, "roles": ROLES, "mods": MODS,
        "triggers": TRIGGERS, "responses": RESPONSES, "meta": META,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    shot = sum(1 for k in KINGDOMS if k["image"])
    print(f"biome_gallery.json: {len(KINGDOMS)} kingdoms ({shot} captured), "
          f"{len(ROLES)} roles, {len(TRIGGERS)} triggers -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
