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
     "blurb": "Three substrates ship, and none is the default — the map picks. `ca` is a 3D cellular automaton frozen at its spreading front: a voxel network, visibly computed. `mycelium` is space-colonised filaments: tapering hyphae, visibly grown. `dna` is the real mushroom — FungusMorphology cap+stem+gills fed by 60 curated presets in five families; fd= picks the family, the cell seed the variant.",
     "algos": [
         {"algo": "ca", "renders": "MoldNetwork CA, gen-frozen as a spreading voxel network", "token": "fungus:ca:seed:t=5"},
         {"algo": "ca (tuned)", "renders": "same CA, per-cell rule and freeze generation", "token": "fungus:ca:seed:rule=4-6/5-7/10/M:gen=16"},
         {"algo": "mycelium", "renders": "space-colonised filaments — tapering hyphae, trunks thickening inward, tips hair-thin (the taper a voxel grid cannot hold)", "token": "fungus:mycelium:seed:t=5:d=1.0"},
         {"algo": "mycelium (sparse)", "renders": "same web, thinned — d= sets how densely the mat fills its disc", "token": "fungus:mycelium:seed:t=5:d=0.3"},
         {"algo": "dna", "renders": "a real mushroom — cap, stem, gills, spores from a curated DNA preset (fd= family, seed-picked variant)", "token": "fungus:dna:seed:fd=fairy_ring:t=3"},
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
    {"mod": "fd=", "what": "fungus:dna only — the curated mushroom family: alien_lumen, button_dome, fairy_ring, parasol_tall, shelf_bracket (12 variants each, cell-seed picked)"},
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

# The principals: every distinct thing the layer can grow, one token each,
# each shot alone on the scratch stage (tools/capture_biome_principals.py).
# group: substrate (seeds), halo (the rim spill per kingdom), vacuum.
EXAMPLES = [
    {"slug": "flora_tree", "group": "substrate", "token": "flora:lsystem:seed:t=4",
     "caption": "the tree — DNA-driven L-system morphology"},
    {"slug": "flora_flower", "group": "substrate", "token": "flora:scatter:seed:t=3",
     "caption": "the flower — botanical preset by tier"},
    {"slug": "fungus_ca", "group": "substrate", "token": "fungus:ca:seed:t=5",
     "caption": "the voxel network — CA frozen at its spreading front"},
    {"slug": "fungus_ca_tuned", "group": "substrate", "token": "fungus:ca:seed:rule=4-6/5-7/10/M:gen=16",
     "caption": "the same CA, per-cell rule= and gen= — visibly computed"},
    {"slug": "fungus_mycelium", "group": "substrate", "token": "fungus:mycelium:seed:t=5:d=1.0",
     "caption": "the mycelium web — space-colonised tapering filaments"},
    {"slug": "fungus_mycelium_sparse", "group": "substrate", "token": "fungus:mycelium:seed:t=5:d=0.3",
     "caption": "the same web, thinned by d="},
    {"slug": "fungus_dna", "group": "substrate", "token": "fungus:dna:seed:fd=fairy_ring:t=3",
     "caption": "the real mushroom — FungusMorphology cap+stem+gills from a curated preset"},
    {"slug": "fauna_grub", "group": "substrate", "token": "fauna:dna:seed:t=4",
     "caption": "the creature — a cell-sized DNA grub"},
    {"slug": "mineral_crystal", "group": "substrate", "token": "mineral:vein:seed:t=4",
     "caption": "the crystal cluster — faceted prisms, inner light"},
    {"slug": "water_pool", "group": "substrate", "token": "water:pool:seed:t=4",
     "caption": "the pool — reflective disc, ripple rings, reeds"},
    {"slug": "meta_glyph", "group": "substrate", "token": "meta:glyph:seed:t=4",
     "caption": "the glyph — a hovering rune of light, not alive"},
    {"slug": "halo_flora", "group": "halo", "token": "flora:scatter:halo:d=0.8",
     "caption": "flora spills off the rim — grass and blooms into the dark"},
    {"slug": "halo_fungus", "group": "halo", "token": "fungus:scatter:halo:d=0.8",
     "caption": "fungus rim — mushroom caps thinning outward"},
    {"slug": "halo_fauna", "group": "halo", "token": "fauna:scatter:halo:d=0.8",
     "caption": "fauna rim — earthy mounds at the edge"},
    {"slug": "halo_mineral", "group": "halo", "token": "mineral:scatter:halo:d=0.8",
     "caption": "mineral rim — scattered stones"},
    {"slug": "halo_water", "group": "halo", "token": "water:scatter:halo:d=0.8",
     "caption": "water rim — reeds at the shore"},
    {"slug": "halo_meta", "group": "halo", "token": "meta:scatter:halo:d=0.8",
     "caption": "meta rim — small lights past the edge"},
    {"slug": "mute", "group": "vacuum", "token": "::mute",
     "caption": "the declared vacuum — nothing grows here on purpose; a reaction can open it"},
]

# The tier ladders (ruled next-step 2026-07-21): for the substrates where t=
# matters most, five seeds stand in a row at t=1..5 on one wide stage — the
# whole ladder reads in a single shot (ex/ladder_<slug>.png).
LADDERS = [
    {"slug": "tree", "token_fmt": "flora:lsystem:seed:t={t}",
     "caption": "tree depth — segments, scale and leaf density climb with t="},
    {"slug": "flower", "token_fmt": "flora:scatter:seed:t={t}",
     "caption": "flower presets — the tier picks the species and the scale (bluebell → orchid → daisy)"},
    {"slug": "ca", "token_fmt": "fungus:ca:seed:t={t}",
     "caption": "CA size — the voxel network's grid dimension grows with t="},
]

# The flora & fauna DETAIL CATALOG (asked 2026-07-21): the species level.
# Where the principals show WHAT a token grows, the details show the RANGE
# within it — flower species, position-seeded tree and grub individuals,
# and the five curated mushroom families. cell = where the seed stands on
# the stage (position IS the DNA seed for tree/fauna, so moving the cell
# is how you meet a different individual).
DETAILS = [
    {"slug": "flower_bluebell", "kingdom": "flora", "token": "flora:scatter:seed:t=1",
     "caption": "bluebell — the tier-1 species"},
    {"slug": "flower_orchid", "kingdom": "flora", "token": "flora:scatter:seed:t=3",
     "caption": "orchid — the tier-3 species"},
    {"slug": "flower_daisy", "kingdom": "flora", "token": "flora:scatter:seed:t=5",
     "caption": "daisy — the tier-5 species"},
    {"slug": "tree_a", "kingdom": "flora", "token": "flora:lsystem:seed:t=4", "cell": [1, 1],
     "caption": "tree individual A — DNA seeded by its cell"},
    {"slug": "tree_b", "kingdom": "flora", "token": "flora:lsystem:seed:t=4", "cell": [3, 2],
     "caption": "tree individual B — same token, different cell, different tree"},
    {"slug": "tree_c", "kingdom": "flora", "token": "flora:lsystem:seed:t=4", "cell": [2, 3],
     "caption": "tree individual C — the grammar varies, the species holds"},
    {"slug": "fd_alien_lumen", "kingdom": "fungus", "token": "fungus:dna:seed:fd=alien_lumen:t=3",
     "caption": "alien lumen — bioluminescent caps (12 curated variants)"},
    {"slug": "fd_button_dome", "kingdom": "fungus", "token": "fungus:dna:seed:fd=button_dome:t=3",
     "caption": "button dome — low round caps (12 curated variants)"},
    {"slug": "fd_fairy_ring", "kingdom": "fungus", "token": "fungus:dna:seed:fd=fairy_ring:t=3",
     "caption": "fairy ring — colony in a circle (12 curated variants)"},
    {"slug": "fd_parasol_tall", "kingdom": "fungus", "token": "fungus:dna:seed:fd=parasol_tall:t=3",
     "caption": "tall parasol — high stem, wide cap (12 curated variants)"},
    {"slug": "fd_shelf_bracket", "kingdom": "fungus", "token": "fungus:dna:seed:fd=shelf_bracket:t=3",
     "caption": "shelf bracket — stacked ledges (12 curated variants)"},
    {"slug": "grub_a", "kingdom": "fauna", "token": "fauna:dna:seed:t=4", "cell": [1, 1],
     "caption": "grub individual A — DNA seeded by its cell"},
    {"slug": "grub_b", "kingdom": "fauna", "token": "fauna:dna:seed:t=4", "cell": [3, 2],
     "caption": "grub individual B — same species logic as the trees"},
    {"slug": "grub_c", "kingdom": "fauna", "token": "fauna:dna:seed:t=4", "cell": [2, 3],
     "caption": "grub individual C"},
]

META = [
    {"key": "presence", "what": "the ground stain — every active unmuted cell stamps a breathing kingdom-tinted stain into the floor (radial falloff, spreads with claims, muted cells stay dry). true by default; false switches it off"},
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
    for e in EXAMPLES:
        img = os.path.join(IMG_DIR, "ex", f"{e['slug']}.png")
        e["image"] = f"/biome-gallery/ex/{e['slug']}.png" if os.path.exists(img) else None
    for l in LADDERS:
        img = os.path.join(IMG_DIR, "ex", f"ladder_{l['slug']}.png")
        l["image"] = f"/biome-gallery/ex/ladder_{l['slug']}.png" if os.path.exists(img) else None
        l["tokens"] = [l["token_fmt"].format(t=t) for t in range(1, 6)]
    for d in DETAILS:
        img = os.path.join(IMG_DIR, "ex", f"detail_{d['slug']}.png")
        d["image"] = f"/biome-gallery/ex/detail_{d['slug']}.png" if os.path.exists(img) else None
    data = {
        "title": "The biome",
        "subtitle": "Everything the living layer can grow. Each kingdom shot from its own gallery map: every algo at tiers 1, 3 and 5, a halo edge behind, a mute cell in front.",
        "grammar": "kingdom:algo:role[:mod=val…][:on=trigger:response[/response…]]",
        "kingdoms": KINGDOMS, "examples": EXAMPLES, "ladders": LADDERS,
        "details": DETAILS, "roles": ROLES, "mods": MODS,
        "triggers": TRIGGERS, "responses": RESPONSES, "meta": META,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    shot = sum(1 for k in KINGDOMS if k["image"])
    ex_shot = sum(1 for e in EXAMPLES if e["image"])
    print(f"biome_gallery.json: {len(KINGDOMS)} kingdoms ({shot} captured), "
          f"{len(EXAMPLES)} principals ({ex_shot} captured), "
          f"{len(ROLES)} roles, {len(TRIGGERS)} triggers -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
