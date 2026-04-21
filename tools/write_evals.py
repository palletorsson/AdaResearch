#!/usr/bin/env python
"""
write_evals.py — Persist session evaluations to gallery manifests.

Reads an in-file dict of evaluations (my running ratings across the
session) and writes one evals.json per gallery under
ada_encyclopedia/public/<gallery>/evals.json.

Each gallery's evals.json is a dict keyed by artefact id:
  { "<id>": {
      "stars": 1-5,
      "verdict": "crown_jewel|winner|strong|working|broken|boring",
      "notes": "...",
      "next_gen_hints": ["..."],
      "evaluated_by": "claude",
      "date": "YYYY-MM-DD"
  }, ... }

Gallery pages fetch evals.json at load time and overlay star badges +
notes on tiles that have an eval. Tiles without an eval render unadorned.

Re-run any time new evals are written. Idempotent.
"""
from __future__ import annotations
import json
import os
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"

TODAY = "2026-04-21"
AUTHOR = "claude"


def E(stars, verdict, notes, hints=None):
    return {
        "stars": stars,
        "verdict": verdict,
        "notes": notes,
        "next_gen_hints": hints or [],
        "evaluated_by": AUTHOR,
        "date": TODAY,
    }


# ─── Graph grammar evals (the most evaluated gallery this session) ──

GRAPH_EVALS = {
    # gen00 — original branches and space colonization
    "gg00_tree_classic":         E(4, "working",    "Iterative branching, 4 generations, produces a clean skeletal tree. Baseline for the grammar."),
    "gg00_tree_narrow":          E(3, "working",    "Narrow conifer — less splay. Reads as pine."),
    "gg00_tree_wide":            E(3, "working",    "Wide oak — 4 children per node. Works."),
    "gg00_rhizome_horizontal":   E(3, "working",    "Sideways rhizome via high spread. Low detail but recognisable."),
    "gg00_colonize_ellipsoid":   E(5, "winner",     "Stunning real-tree silhouette. Space colonisation with ellipsoidal attractor cloud produces a canopy that looks like a real plant. Best gen00 result."),
    "gg00_colonize_cone":        E(4, "strong",     "Tall cypress/grass silhouette from conical attractor cloud."),
    "gg00_colonize_torus":       E(1, "broken",     "Empty frame. Attractors out of reach for root. Config needed tighter cloud_center — fixed in gg01.", ["reduce cloud_size_y", "move cloud_center closer to root"]),
    "gg00_compound_spawn_colonize": E(3, "working", "Two spawn levels then colonise — denser canopy."),
    "gg00_tree_with_segments":   E(3, "working",    "Subdivide_edge after spawn gives visible kinks."),
    "gg00_dense_branching":      E(4, "strong",     "Dense 5-child branching bush."),

    # gen01 — shaders + leaf_tuft added
    "gg01_tree_shaded":          E(4, "strong",     "Tree_classic with bark + plant shaders. First shader demo."),
    "gg01_tree_with_tufts":      E(4, "strong",     "Bush silhouette with plant-shader foliage."),
    "gg01_conifer":              E(5, "winner",     "Reads as a living juniper. Dense green foliage with visible bark. Shaders transform the output completely."),
    "gg01_autumn_tree":          E(4, "strong",     "Red-orange foliage reads as fall maple."),
    "gg01_colonize_tree_shaded": E(2, "working",    "Compact sphere cluster instead of tree — Runions went too tight. Rendered but aesthetic miss.", ["increase cloud_size", "reduce attractor_count"]),
    "gg01_coral_red":            E(4, "strong",     "Dense red branching. Flesh shader reads as living coral."),
    "gg01_fern_spread":          E(4, "strong",     "Wide low spread with green tufts."),
    "gg01_dense_foliage":        E(4, "strong",     "Grass-like dense tufts everywhere."),
    "gg01_colonize_torus_fixed": E(3, "working",    "Retried torus with tighter cloud — torus ring visible."),
    "gg01_bristle_ball":         E(5, "winner",     "Elegant rosette of bright capsules. Like a succulent or sea urchin. Pure leaf_tuft on root."),

    # gen02 — metaball rendering
    "gg02_urchin_metaball_soft": E(3, "working",    "Soft fusion at roots, bristles remain distinct. Works as the red urchin metaball."),
    "gg02_urchin_metaball_heavy": E(2, "working",   "Over-smoothed — bristles erased into a near-smooth ball. Failure mode worth naming: over-smoothing erases topology.", ["reduce smoothness", "keep bristle count below 100"]),
    "gg02_tree_metaball":        E(4, "strong",     "Branches fuse at forks like molten metal. First metaball tree."),
    "gg02_coral_metaball":       E(5, "crown_jewel","User's favourite of the session. Cluster of organic red forms — fused extremities reading as a single organism with many reaching parts. Low-poly marching cubes becomes aesthetic feature."),

    # gen03 — noise modulator
    "gg03_tree_noise_light":     E(3, "working",    "Subtle organic wobble. Noise modulator proof-of-concept."),
    "gg03_tree_noise_heavy":     E(4, "strong",     "Wind-beaten bonsai silhouette, branches bent irregularly."),
    "gg03_tree_knotty":          E(4, "strong",     "Noise-modulated radii produce knotty bark thickness variation."),
    "gg03_tree_both":            E(4, "strong",     "Position + radius noise combined. Full organic character."),
    "gg03_rhizome_noise":        E(4, "strong",     "Horizontal rhizome + XZ-only displacement — wild meander along ground."),
    "gg03_canopy_windblown":     E(3, "working",    "Space-colonised canopy with horizontal bias. Subtle."),
    "gg03_bristle_knotty":       E(3, "working",    "Bristle ball with radius noise — varied thickness."),
    "gg03_dense_chaos":          E(4, "strong",     "Red bramble ball. Heavy noise + dense branching + red foliage."),

    # gen04 — coral family (metaball + multi-root + variants)
    "gg04_coral_tangled":        E(4, "strong",     "High jitter turned limbs into a knot of reaching arms."),
    "gg04_coral_chubby":         E(4, "strong",     "Rounded doubled spheres with stubby appendages — reads as cute alien."),
    "gg04_coral_fungal":         E(5, "winner",     "Ochre + softer smoothing. Unexpectedly reads as figures running or dancing. Pareidolia is strong — anthropomorphic silhouettes."),
    "gg04_coral_bone":           E(4, "strong",     "Ivory faceted — low-poly becomes decorative rather than approximate."),
    "gg04_coral_paired":         E(5, "crown_jewel","Two seeds offset 0.8m apart — two creatures fused at the hip. Entangled symbiosis aesthetic. Multi-root seeder debut."),
    "gg04_coral_trinity":        E(5, "winner",     "Three seeds in equilateral triangle. Dense anemone cluster."),

    # gen05 — sine modulator
    "gg05_bamboo":               E(5, "winner",     "Sine radii along depth produces clean bead-segments. The single most recognisable silhouette in the gallery."),
    "gg05_serpentine_trunk":     E(4, "strong",     "Sine displacement along Y drives X-axis wiggle. Reads as alien root."),
    "gg05_pulsing_tree":         E(3, "working",    "Pulse-wave radii on tree. Subtle but adds knuckled thickness."),

    # gen06 — RD-as-modulator (required stability fix)
    "gg06_rd_spots":             E(4, "strong",     "Bushy canopy with RD-spots pattern pushing leaf nodes. Reads as wind-patterned hedge."),
    "gg06_rd_stripes":           E(3, "working",    "Stripes displacement — ridged foliage."),
    "gg06_rd_mazes_canopy":      E(3, "working",    "Space-colonized + RD mazes. Organic labyrinth."),

    # gen07 — Poisson scatter seeder
    "gg07_scatter_forest":       E(5, "winner",     "12 seeds scattered on a disk, each grows a small tree. Forest patch from one config — the payoff of the seeder role."),
    "gg07_scatter_corals":       E(5, "winner",     "8 coral roots + metaball = long reef/colony of fused creatures."),
    "gg07_scatter_grove_rd":     E(3, "working",    "Scatter + RD displacement produces dappled bush cluster."),

    # gen08 — parametric curves (first 6)
    "gg08_helix_vine":           E(3, "working",    "Polygonal coil, benefits from more depth iterations."),
    "gg08_trefoil_vine":         E(2, "working",    "Wireframe loop visible on close inspection but too thin against background.", ["thicker capsules", "switch to metaball", "dark background"]),
    "gg08_lissajous_branches":   E(4, "strong",     "Fan-shaped radial spread with green tips. Tropical rosette reading."),
    "gg08_rose_canopy":          E(5, "crown_jewel","Accidental cherry blossom. Rose curve + leaf_tuft + plant_red → flowering tree the author did not design."),
    "gg08_spiral_tower":         E(3, "working",    "Archimedean spiral trace. Clean, pedagogically useful."),
    "gg08_butterfly_bush":       E(4, "strong",     "Dense green topiary ball. Butterfly curve tangled the bristles."),

    # gen09 — parametric curves (library expansion)
    "gg09_figure_eight_vine":    E(3, "working",    "Figure-eight knot visible but thin."),
    "gg09_torus_knot":           E(3, "working",    "Knot outline visible, faint against background.", ["metaball render", "thicker capsules"]),
    "gg09_rose_5_bush":          E(4, "strong",     "Dense red pentagonal bush with visible 5-petal clustering."),
    "gg09_seashell_vine":        E(2, "working",    "Logarithmic spiral but too thin — needs metaball render."),
    "gg09_wave_torus_canopy":    E(4, "strong",     "Dense green topiary with 8-fold radial pattern."),
    "gg09_enneper_cluster":      E(5, "crown_jewel","Multi-armed reaching creature. Enneper curve × coral recipe × metaball. Second accidental category of the session."),
    "gg09_helicoid_growth":      E(3, "working",    "Radius-growing helix tower. Readable but not striking."),
    "gg09_breather_tree":        E(3, "working",    "Breather curve produces amplitude pulses. Subtle."),

    # gen10 — symmetry
    "gg10_mandala_4fold":        E(4, "strong",     "4-fold topiary sphere. Symmetry filled all space."),
    "gg10_mandala_6fold":        E(4, "strong",     "Hexagonal mandala — dense spherical."),
    "gg10_mandala_creature":     E(5, "winner",     "Pentagonal starfish/sea-star from 5-fold symmetry + coral + metaball. Symmetry op gives whole categories of radial creatures."),

    # gen11 — CA prune selector
    "gg11_ca_conway":            E(5, "winner",     "Scattered forest pruned by Conway's Game of Life. Trees only in CA-alive cells — patchy ecological pattern with rhythm in gaps. The CA-as-selector idea works."),
    "gg11_ca_seeds":             E(4, "strong",     "B2/S rule forest — explosive Seeds CA creates rhythmic bands."),
    "gg11_ca_day_night":         E(4, "strong",     "Day-and-Night CA produces large stable continental islands."),

    # gen12 — convex hull finishing
    "gg12_organism_in_cage":     E(3, "working",    "Coral inside wireframe hull cage. Concept visible."),
    "gg12_tree_in_hull":         E(3, "working",    "Tree + tight hull — branches pressing against skin."),
    "gg12_hull_metaball":        E(5, "winner",     "Organism + hull + metaball = reaching creature where shell and skeleton fuse. Rediscovers the enneper_cluster aesthetic via different path."),

    # gen13 — CA seeder mode (new role)
    "gg13_ca_seeder_conway":     E(5, "winner",     "Conway CA directly seeds the forest. Ecology is the CA pattern. Proves CA-as-seeder is conceptually distinct from CA-as-pruner."),
    "gg13_ca_seeder_highlife":   E(4, "strong",     "HighLife CA produces moving gliders — seeds form migrating patterns."),
    "gg13_ca_seeder_day_night":  E(4, "strong",     "Day-and-Night CA — large stable continents of growth."),
    "gg13_ca_seeder_seeds":      E(4, "strong",     "Seeds CA (B2/S) — oscillating explosive patterns."),
    "gg13_ca_seeder_life_without_death": E(5, "winner", "Life-without-Death fills everything. Geological overgrowth — forest as terrain/mountainside."),
    "gg13_ca_conway_dense":      E(4, "strong",     "Conway + higher density = tighter ecological patches."),
    "gg13_ca_coral_seeder":      E(4, "strong",     "CA-seeded coral forest + metaball — colonies in CA patterns fuse smoothly. Reef."),
    "gg13_ca_seeder_autumn_forest": E(5, "crown_jewel", "Three distinct red-foliage forest patches following Conway's pattern. Reads as landscape seen from above — islands of autumn trees separated by ground. Geographic structure from discrete rules."),

    # gen14 — escape-time fractals
    "gg14_mandelbrot_forest":    E(5, "crown_jewel","You can see the Mandelbrot set shape in the forest: main body + satellite buds. Fractal boundary as ecology."),
    "gg14_julia_forest":         E(4, "strong",     "Julia set c=-0.7+0.27i produces closed oval with dragon boundaries. Reads as island."),
    "gg14_julia_forest_2":       E(4, "strong",     "Different Julia c — different shape, autumn color. Douady rabbit constant."),
    "gg14_burning_ship_forest":  E(4, "strong",     "Flattened oval with angular antenna protrusions — Burning Ship character."),
    "gg14_koch_branches":        E(3, "working",    "Tree with Koch'd branches. Capsules too thin.", ["metaball render", "thicker base radius"]),
    "gg14_koch_lightning":       E(5, "winner",     "Vertical chain + Koch depth-3. The straight line became a branching lightning bolt. Self-similar zigzag at three scales."),

    # gen15 — Modulor fold (after fractals)
    "gg15_modulor_library":      E(4, "strong",     "Room + 2 tables + 6 books + pen. Ontology reads at a glance. Bird's-eye camera needed."),
    "gg15_modulor_workshop":     E(4, "strong",     "Room with multiple tables holding cups and books."),
    "gg15_modulor_body":         E(5, "crown_jewel","Anatomical skeleton: torso → 2 arms → forearms → hands → 4 fingers. PURE proof that Modulor fold works for bodies. Same op as library."),
    "gg15_modulor_kitchen":      E(4, "strong",     "Floor + tables + many cups. Reads as kitchen counter."),
    "gg15_modulor_nested_rooms": E(5, "winner",     "Four Modulor rungs visible simultaneously: floor → tables → shelves → books. Ontology IS geometry."),

    # gen16 — chandelier render mode (Adelman-family lighting)
    "gg16_chandelier_adelman_3bulb": E(4, "strong",  "3-bulb Branching Bubble Chandelier form. Dark metal rods + frosted glass bulbs. Clean Adelman reference.", ["try hanging orientation (negate trunk pitch)", "add slight noise to bulb surface for hand-blown look"]),
    "gg16_chandelier_5bulb":         E(4, "strong",  "5-bulb fan variant. Reads as floor lamp. Different count, same grammar."),
    "gg16_chandelier_2gen":          E(5, "winner",  "Two branching generations = 6 bulbs, richer tree. Strongest chandelier of the batch. Reads most clearly as Adelman's catalog pieces.", ["try 3-gen with 8+ bulbs", "add slight glass-surface noise"]),
    "gg16_chandelier_brass_7bulb":   E(4, "strong",  "Warm brass rods + smaller bulbs + joint beads. Ornate variant. Shows show_joints option works."),
    "gg16_molecule_colored":         E(4, "strong",  "SAME GRAMMAR reused as molecule diagram. Cyan atoms + grey bonds. Proves the chandelier renderer is also a ball-and-stick renderer — one substrate, two domains. Pedagogical gold."),
}


# ─── Mesh grammar evals ─────────────────────────────────────────

MESH_EVALS = {
    # gen00 — first pass, some broken by wrong tag name
    "gen00_tower_plain":      E(3, "working",    "Recognisable staircase tower from inset+extrude."),
    "gen00_tower_taper":      E(3, "working",    "Works, silhouette very similar to plain. Scale factor needs more aggression."),
    "gen00_coral_random":     E(1, "broken",     "Plain sphere — 'tag:inset_inner' didn't match; InsetFaceOp emits 'inset'. Fixed in gen01.", ["use tag:inset"]),
    "gen00_spikes_iso":       E(4, "strong",     "Striking spiky organism, reads as clear form."),
    "gen00_mushroom":         E(4, "strong",     "Clean mushroom silhouette from 3-step cascade."),
    "gen00_bulge_sphere":     E(4, "strong",     "Sphere with elegant spike protrusions — unexpected aesthetic."),
    "gen00_noise_sphere":     E(3, "working",    "Subtle bumpy sphere."),
    "gen00_petals":           E(5, "winner",     "Beautiful cactus/agave form. petal_splay on up-faces is the strongest primitive in the library."),
    "gen00_cellular":         E(1, "broken",     "Cube unchanged — op produced no visible effect. Params unknown.", ["investigate cellular_surface_op params"]),
    "gen00_scale_alt":        E(2, "broken",     "Nested cube frames — tag chain not working.", ["use tag:inset"]),
    "gen00_tube_branches":    E(4, "strong",     "Tube branches on icosphere look like limbs."),
    "gen00_hybrid":           E(2, "broken",     "Tag bug as scale_alt and coral_random.", ["use tag:inset"]),

    # gen01 — tag bug fixed + winners established
    "gen01_petals_wide":      E(4, "strong",     "Fat agave/succulent from wider splay."),
    "gen01_petals_long":      E(4, "strong",     "Long petals — grass tuft."),
    "gen01_petals_all":       E(5, "crown_jewel","THE BEST shape in the whole gallery. Sea urchin/thistle explosion from petal_splay on ALL faces of an icosphere."),
    "gen01_mushroom_tall":    E(4, "strong",     "Clean mushroom with long stem — classic silhouette."),
    "gen01_mushroom_cluster": E(4, "strong",     "Stacked mushroom caps — 4-step cascade."),
    "gen01_spikes_dense":     E(4, "strong",     "Crystal/shard cluster from stacked random extrude."),
    "gen01_spikes_sphere":    E(3, "working",    "Sphere-based spikes — less dramatic than icosphere."),
    "gen01_bulge_big":        E(3, "working",    "Lumpier with bigger bulge."),
    "gen01_bulge_all":        E(3, "working",    "Lumpy stone — bulge on every face."),
    "gen01_tube_branches_dense": E(3, "working", "Coral-like with many tube branches."),
    "gen01_tube_sphere":      E(3, "working",    "Tubes from sphere seed — soft branching creature."),
    "gen01_tower_aggressive": E(4, "strong",     "Tower with aggressive taper — pyramid silhouette."),
    "gen01_coral_fixed":      E(4, "strong",     "Now actually shows coral bumps (tag fix)."),
    "gen01_hybrid_fixed":     E(4, "strong",     "Inset+extrude+noise working with correct tag."),
    "gen01_compound_petals":  E(5, "crown_jewel","Spiked-then-petaled MONSTER. Reads like dragon or deep-sea creature. COMPOUND RECIPE PROVEN."),
    "gen01_compound_mushroom_bulge": E(4, "strong", "Mushroom with bulged cap — compound chain."),

    # gen02 — compound recipe exploration
    "gen02_petals_layered":   E(5, "winner",     "Peach blossom / fractal thistle. Dense petals with inner petals."),
    "gen02_petals_sphere":    E(4, "strong",     "Petals on sphere base — smoother than icosphere."),
    "gen02_petals_tall":      E(4, "strong",     "Long thin petals — grass burst."),
    "gen02_petals_short_fat": E(4, "strong",     "Short fat petals — scales/armor."),
    "gen02_petals_on_bulge":  E(5, "crown_jewel","Perfect 'fantastic creature' look. Organic sea-creature vibe — pincushion organism."),
    "gen02_petals_on_spikes": E(4, "strong",     "Spikes first then petals on up-faces — dragon aesthetic."),
    "gen02_coral_deep":       E(4, "strong",     "Deep inset + tall extrude — visible coral bumps."),
    "gen02_coral_polyps":     E(4, "strong",     "Inset + extrude + bulge — lumpy coral polyps."),
    "gen02_spikes_layered":   E(4, "strong",     "Crystal cluster — spikes then spikes on tips."),
    "gen02_spikes_tower":     E(5, "crown_jewel","Fantasy castle with spiked crown. Tower + petals = castle."),
    "gen02_mushroom_forest":  E(4, "strong",     "Multi-cap mushroom from 5-step cascade."),
    "gen02_mushroom_petaled": E(5, "crown_jewel","PALM TREE with crown fronds and roots. Mushroom + petals on down-faces."),
    "mg_op11_twist_spire_cone": E(3, "working",   "Transform-stack test is visible now: a stepped twisted turret rather than a clean spire. Valuable because it shows rotate/scale working, but the geometry still kinks instead of flowing."),
    "mg_op12_cylinder_split_crown": E(4, "strong","Split used as a true faceting operator. The crystal becomes a fractured pyramid with a believable carved-core reading."),
    "mg_op13_arch_scalloped_gate": E(4, "strong", "Best recovery of the retune pass. Edge-decorate finally reads: the arch turns into a dense block-built portal or voxel shrine."),
    "mg_op14_torus_riveted_halo": E(4, "strong",  "Beaded torus ring works as a halo or mechanical gasket. Good proof that edge_decorate can ornament closed meshes if boundary-only is disabled."),
    "mg_op15_icosa_scale_pod": E(3, "working",    "ScaleTileOp definitely fires, but the result is still sparse. More pod than pinecone. Useful operator proof, weaker silhouette."),
    "mg_op16_sphere_barnacle_field": E(4, "strong","Scatter produces a convincing barnacle/urchin crust without relying on extrusion. One of the clearer new surface-texture recipes."),
    "mg_op17_capsule_blossom_bonsai": E(4, "strong","Branch operator made legible by the pedestal base. Reads as a tiny altar bonsai with blossom clusters instead of a random spray of branches."),
    "mg_op18_cellular_perforated_shell": E(4, "strong","CA + delete + edge decor works. The shell becomes a punctured dome with beaded hole boundaries, which is conceptually richer than a plain perforation."),
    "mg_op19_daynight_ziggurat": E(5, "winner",   "Strongest architecture of the batch. Day-and-Night CA seed plus stepped inset/extrude yields a readable citadel or ruin cluster."),
    "mg_op20_delta_bead_sheet": E(4, "strong",    "RD ornament finally reads after the retune. The delta sheet becomes a studded relief panel rather than staying a flat terrain sample."),
}


# ─── Form gallery evals (SDF body recipes) ──────────────────────

FORM_EVALS = {
    "flower_classic":          E(4, "strong",     "Classic flower from kingdom DNA. Baseline."),
    "flower_3petal":           E(3, "working",    "Minimal 3-petal variant."),
    "flower_7petal":           E(4, "strong",     "Dense 7-petal flower."),
    "flower_compact":          E(3, "working",    "Compact 8-petal symmetry."),
    "fungus_cap":              E(3, "working",    "Mushroom cap from fungus body."),
    "fungus_tall":             E(3, "working",    "Tall fungus variant."),
    "walker_biped":            E(3, "working",    "Biped walker baseline."),
    "walker_quad":             E(3, "working",    "4-limb walker — more creature-like."),
    "tree_classic":            E(4, "strong",     "Canonical tree body."),
    "tree_gnarled":            E(4, "strong",     "More iterations = gnarled trunk."),
    "modulor_rung0":           E(3, "working",    "Walker at Modulor rung 0."),
    "modulor_rung2":           E(3, "working",    "Walker at rung 2 — smaller."),
    "modulor_rung4":           E(3, "working",    "Walker at rung 4 — tiny."),
    "column_doric":            E(4, "strong",     "Classical Doric column. Clean stone render."),
    "column_tall":             E(3, "working",    "Tall variant column."),
    "pedestal_square":         E(3, "working",    "Classical pedestal."),
    "pedestal_tall":           E(3, "working",    "Tall pedestal variant."),
    "amphora_classic":         E(4, "strong",     "Classical amphora — clean terracotta."),
    "amphora_squat":           E(3, "working",    "Squat variant."),
    "ruin_wall_low":           E(3, "working",    "Ruin wall segment."),
    "graph_tree_classic":      E(4, "strong",     "Clean skeletal tree from graph_tree_body. Port of Blender bone_skin prototype."),
    "graph_tree_sparse":       E(3, "working",    "2-branch narrow variant."),
    "graph_tree_coral":        E(3, "working",    "5-branch coral-like variant."),
    "graph_tree_fan":          E(3, "working",    "4-branch with deep recursion — fan-shaped."),
    "graph_tree_dense":        E(3, "working",    "Dense 3-branch, depth 5."),
}


# ─── Primitive stack evals ──────────────────────────────────────

PRIMITIVE_STACK_EVALS = {
    "ps01_bauhaus_totem_green":  E(4, "strong", "Green-sphere Bauspiel totem — sphere on cube on stepped base. Recognisable Siedhoff-Buscher."),
    "ps01_bauhaus_totem_red":    E(5, "winner", "Full 6-piece red Bauhaus Bauspiel totem: cylinder → disc → cube → sphere → hemisphere → small sphere. Unmistakable Siedhoff-Buscher silhouette."),
    "ps01_random_totem_bauhaus": E(4, "strong", "Pure DNA exploration — seed=11 produced a handsome dark totem with red disc. Proves random DNA generates credible totems without curation.", ["try more seeds", "vary scale_variation"]),
    "ps02_coco_pendant":         E(3, "working", "Beaded pendant with glowing bulb — renders correctly but camera frames it narrow. Reads as Coco Reynolds pendant when zoomed.", ["adjust camera to fit vertical composition", "increase bead size variation"]),
    "ps02_pendant_bauhaus_beads": E(3, "working", "Pendant grammar with Bauhaus palette. Different character — reads as a bead curtain fragment."),
    "ps03_vignelli_metafora":    E(3, "working", "Four Euclidean legs under glass plate. Plate renders subtly — could be more visible.", ["lighter plate alpha", "camera pitch higher"]),
    "ps03_metafora_bauhaus":     E(3, "working", "3-leg Bauhaus variant. Plate not visible in frame — camera framing issue.", ["camera pitch > 0.3"]),
    "ps04_utensilo_mono":        E(5, "winner", "6×5 wall grid of monochrome primitives — the Dorothee Becker Uten.Silo aesthetic from one config + seed. Reads as a modernist wall organizer."),
    "ps04_utensilo_pastel":      E(4, "strong", "Same wall-grid grammar with pastel palette — warmer character."),
    "ps05_lady_lamp":            E(4, "strong", "Tall black pyramid + glass sphere at apex. Grammar handles Lady Lamp form via 2-item vertical stack with extreme scale contrast."),
    "ps05_lady_lamp_tall":       E(3, "working", "Taller, narrower variant. Same grammar, different proportion."),
    "ps06_grawunder_xxx_warm":   E(5, "winner",  "Johanna Grawunder XXX Table (2001) — two translucent orange/pink panels crossing, orange disc top. Subtractive darkening visible at panel overlap. Accurate reference match.", ["try 4-panel radial version", "add glass refraction"]),
    "ps06_grawunder_xxx_cool":   E(4, "strong",  "Cool blue/magenta variant. Subtractive mix darkens to purple at overlap. Same grammar, different hue."),
    "ps06_grawunder_cmy":        E(5, "winner",  "CMY 3-panel stack — cyan + magenta + yellow. Maximum subtractive darkening where all three overlap. Genuinely teaches subtractive color mixing as structure."),
    "ps07_kras_slon_round":      E(5, "winner",  "Ana Kraš Slon Round Table (2015) — maple wood top on striped cylindrical pedestal. Very close to reference image. Stripe-pedestal grammar proven."),
    "ps07_kras_red_cream":       E(4, "strong",  "Red-and-cream stripes + lighter top. Same grammar, recolored — reads as a warm-toned Kraš variant."),
    "ps07_kras_rainbow":         E(4, "strong",  "6-color rotating stripe palette on Kraš pedestal. Kinetic-op-art character — stripe palette as expressive DNA."),
}


# ─── Soft body evals ───────────────────────────────────────────

SOFT_BODY_EVALS = {
    # ── Verlet track (research DNA — deterministic headless) ──
    "sb01_cloth_drape_corners":  E(3, "working", "Two-corner pinned drape — reads as a hanging tarp. Slight catenary curl at pinned corners, otherwise too flat.", ["reduce stiffness to 0.6", "add subtle wind force", "longer sim steps for fuller sag"]),
    "sb02_cloth_drape_top_row":  E(2, "boring",  "Flat rectangle — full-top-row pin + high stiffness = rigid plane, no character.", ["much lower stiffness 0.3-0.5", "more rows for vertical sag", "break pin pattern (pin alternating columns)"]),
    "sb03_cloth_flag_sideways":  E(4, "winner",  "Billowed into a candle-flame cone from diagonal wind — unexpectedly striking sculptural shape. Directed gravity as wind force proves its DNA expressiveness.", ["vary wind direction for different cones", "try with top-row pin + sideways wind", "this is the grammar for 'flame' or 'flag' forms"]),
    "sb04_cloth_tablecloth":     E(2, "boring",  "Four-corner pinned square — rendered as near-flat sheet. Scalloped edges between pins not visible at this camera angle.", ["lower stiffness so belly sags", "camera from below to see belly", "add center-weight particle to pull middle down"]),
    "sb05_jelly_box_bounce":     E(3, "working", "28-spring skeleton readable as a wireframe tent shape — particle spheres not clearly visible in output, only wires.", ["bigger particle radius 0.18+", "start closer to floor", "lower stiffness so deformation more visible"]),
    "sb06_jelly_grid_settle":    E(4, "strong",  "5x5x5 lattice mid-collapse — reads like brutalist architecture mid-demolition. The Verlet settle has structural beauty.", ["capture at multiple timesteps", "vary aspect ratios", "this is the 'collapsing scaffold' grammar"]),
    "sb07_jelly_grid_tall_stiff": E(3, "working", "Tall column with interior collapse — outer shell stable but inside buckles.", ["denser grid cells", "add outer shell material", "try with pinned top row (hanging column)"]),
    "sb08_jelly_grid_floppy":    E(4, "strong",  "Wide floppy lattice spread on ground — low stiffness + wide grid produces a convincing pancake with ruffled edges.", ["vary damping for more wobble", "this is the grammar for 'bread dough' or 'fallen tent' forms"]),

    # ── Native track — captures of existing SoftBody3D artifacts ──
    "sbX01_jelly_cube":          E(3, "working", "Capture shows the VR control panel (STIFF/DAMP/PRESS sliders) partially occluding the cube behind. Good for the control interface but misleading thumbnail.", ["add no-UI capture angle", "rotate camera to foreground the cube"]),
    "sbX02_flagdancer":          E(2, "broken",  "Tiny square mid-frame — flag either unrendered or physics hadn't animated at capture time. Needs longer pre-capture settle.", ["increase capture wait_seconds", "force wind to be active at t=0"]),
    "sbX03_cloth_simulation":    E(3, "working", "Native Godot cloth artifact — scene loaded. Compare geometry against Verlet sb01-sb04."),
    "sbX04_squishy_ball_pit":    E(3, "working", "Glowing squishy spheres in glass container — the pressure-inflated DNA in production form."),
    "sbX05_soft_trampoline":     E(3, "working", "Edge-pinned bouncy sheet — the shipping version of what Verlet sb04 reaches for."),
    "sbX06_breathing_room":      E(3, "working", "Corridor with breathing walls — time-varying pressure as DNA, distinct from static-settle poses."),
    "sbX07_soft_mushrooms":      E(5, "crown_jewel", "Polka-dot soft mushrooms — shader-based soft look (not actual SoftBody3D physics but reads as soft). Crown jewel of the existing softbody sequence.", ["this is the grammar for 'forest creature' or 'fungal crystal' forms"]),
    "sbX08_cloth_straps":        E(3, "working", "Hanging cloth straps — walkthrough-interactive. Proximity-reactive drape."),
    "sbX09_revolving_joy_ride":  E(3, "working", "Rotating ride with hanging softbodies. Kinetic variant."),
    "sbX10_pendulum_slap":       E(3, "working", "Double pendulum slaps softbody — energy transfer demo."),
    "sbX11_rounded_softbody_test": E(4, "strong", "VR squeeze-interactive strain-energy heatmap + force arrows + volume preservation chart. The most pedagogically rich native softbody artifact.", ["this doubles as a physics-teaching instrument"]),
    "sbX12_softbody3d":          E(3, "working", "Core Godot SoftBody3D node reference demo."),
    "sbX13_gallery_part1":       E(4, "winner",  "The 36-config softbody test grid mid-simulation — spheres, cubes, pyramids, cylinders arrayed with labels. Genuinely the DNA overview I tried to reinvent.", ["this IS the existing DNA system", "labels visible in capture — worth framing the whole grid"]),
    "sbX14_gallery_part2":       E(3, "working", "Part 2 of the test grid — pressure/deflation/drag/mass variants."),
    "sbX15_gallery_part3":       E(3, "working", "Part 3 — caving, collapse, stability edge cases."),
}


# ─── L-system evals + cross-gallery DNA bridges ───────────────

LSYSTEM_EVALS = {
    "ls01_algae":                    E(2, "broken",   "Lindenmayer's original algae (A->AB, B->A) — but primitive_shape=cube with step_len=0.05 and no rotations leaves the turtle in one spot. Renders empty.", ["use interpretation='text' or render string directly", "algae is a string-DNA pattern, not a spatial one"]),
    "ls02_koch_curve":               E(3, "working",  "Koch island curve from above — 90° angles produce the self-similar coastline. Camera pitch too extreme, shape floats in corner.", ["camera pitch 0.9 not 1.4", "more iterations for finer detail"]),
    "ls03_classic_tree":             E(5, "crown_jewel", "Lindenmayer's canonical plant F->F[+F]F[-F]F at 25.7°, rendered as brown-to-green tapered tubes. The textbook tree made visible. Perfect DNA demonstration."),
    "ls03b_denser_angle":            E(4, "winner",   "Denser canopy at 22.5° (Prusinkiewicz value). Same F->F[+F]F[-F]F rule as ls03 but with a closer branching angle — reads as cypress vs pine."),
    "ls04_classic_tree_as_graph":    E(2, "broken",   "Same plant DNA with graph interpretation — nodes too tiny (radius 0.015) against large AABB, rendered near-invisible.", ["bigger node radius 0.04+", "or render in graph-grammar-gallery via seed:{lsystem:...}"]),
    "ls05_classic_tree_as_softbody": E(2, "broken",   "Same plant DNA as softbody — camera AABB uses pre-sim walk segments, not post-sim positions. Tree falls out of frame.", ["compute AABB from sim.positions post-step", "or use sb_ls01 in soft-body-gallery instead"]),
    "ls06_bush_stochastic":          E(4, "winner",   "Stochastic production — three alt rules at weighted probabilities. Same seed = same bush. Handsome tube-rendered plant."),
    "ls07_dragon_curve":             E(4, "winner",   "Heighway dragon curve — two non-terminals X/Y encode the folding. 12 iterations = full dragon, rendered in pink against neutral bg."),
    "ls08_hilbert_3d":               E(2, "broken",   "3D Hilbert curve — the turtle alphabet with 4 non-terminals (A/B/C/D) produces spike artifacts. Either rule is miscoded or turtle needs more operators.", ["audit Hilbert 3D rules character-by-character", "verify & ^ / \\ all dispatch correctly"]),
    "ls09_fractal_plant_3d":         E(5, "crown_jewel", "Dense fractal plant — two sub-branches per F at 22.5°. Lush cypress-like green crown. The gallery's prettiest tree."),
    "ls10_sympodial_tree_3d":        E(4, "winner",   "Prusinkiewicz sympodial branching — 3 branches per node with rolls between. Reads as a palm tree or agave.", ["slightly larger step_len for proportion"]),
    "ls11_wiki_fractal_plant":       E(4, "winner",   "Canonical fractal plant from the L-system literature: F doubles into FF while X only steers branching. Nested bracket fans produce a delicate fern-like crown with visible recursive tiers.", ["try iteration 6 for denser foliage", "try graph interpretation to bridge this DNA into graph-grammar"]),
    "ls12_koch_snowflake_classic":  E(4, "winner",   "Classic Koch snowflake at 60?. Triangular axiom plus F->F-F++F-F produces a crisp crystalline coastline.", ["try iteration 5 for finer lace", "try tubes to thicken the snowflake into a coral loop"]),
    "ls13_dragon_cpfg_leftfold":    E(4, "winner",   "CPFG-style dragon curve using non-drawing L/R steering symbols. Tight paper-fold path with clear recursive elbows.", ["try mirrored axiom to compare handedness", "try a warmer palette to emphasize folding rhythm"]),
    "ls14_levy_c_curve":            E(4, "strong",   "Levy C curve at 45?. Repeated +F--F+ replacement creates a dense lightning-fold ribbon.", ["try iteration 12 for fuller fill", "try graph interpretation for a node-edge reading"]),
    "ls15_quadratic_island":        E(4, "strong",   "Quadratic island style curve with right-angle bays and nested inlets. Reads as a blocky shoreline or circuit trace.", ["try one extra iteration if framing holds", "try starting from a single segment for a less enclosed form"]),
    "ls16_koch_square_dense":       E(3, "working",  "Dense right-angle Koch variant. Familiar square-wave DNA pushed one generation deeper into woven lattice territory.", ["compare against ls02 for density", "try a slightly larger step length if the frame feels too tight"]),
    "ls17_binary_tree_grogra":      E(4, "winner",   "Simple binary tree from the classic X->F[+X][-X] family. Clean bifurcating scaffold with readable recursive tiers.", ["try graph interpretation for pruning experiments", "raise angle slightly for a broader crown"]),
    "ls18_two_dimensional_plant_grogra": E(4, "winner", "Grogra's two-dimensional plant grammar. Alternating trunk continuation and side branches create a convincing botanical silhouette from very little DNA.", ["try one more iteration", "compare 20? versus 25? branching angle"]),
    "ls19_cpfg_fan_plant":          E(4, "strong",   "Fan-like plant from the CPFG example family. The extra [F] branch fills the crown and makes the rule read less like a tree and more like a frond.", ["try greener tip gradient", "bridge this into mesh-grammar for leaf-pocket extrusion"]),
    "ls20_cpfg_bushy_fx":           E(4, "winner",   "Bushy X-driven plant with repeated side branching and trunk continuation. Reads as a compact shrub rather than a single-stem tree.", ["increase iterations to 6 for saturation", "test stochastic alternatives on X for species variation"]),
    "ls21_cpfg_weeping_plant":      E(5, "crown_jewel", "Nested-canopy plant from the well-known X->F-[[X]+X]+F[+FX]-X grammar. Delicate, fern-like tiers with clear recursive depth.", ["make a graph twin", "try a denser 6th iteration if framing stays readable"]),
    "ls22_stochastic_balanced_seed13": E(4, "winner", "Balanced stochastic tree using equal-probability branching choices. One plausible specimen of the CPFG stochastic family.", ["render more seeds from the same grammar", "compare with ls23 to study specimen variance"]),
    "ls23_stochastic_balanced_seed77": E(4, "winner", "Same stochastic grammar as ls22 with a different seed. The species identity holds while the local branching decisions change.", ["pick the stronger specimen for walkable promotion", "try graph conversion to inspect topology differences"]),
    "ls24_stochastic_left_heavy":   E(4, "strong",   "Left-heavy stochastic plant. Probability mass shifted toward + branches produces a noticeable directional lean.", ["weaken the bias for subtler asymmetry", "pair with a mirrored right-heavy twin for pedagogy"]),
    "ls25_stochastic_right_heavy":  E(4, "strong",   "Right-heavy stochastic plant. A good control image against ls24: same family, opposite directional bias.", ["compare both in a two-up gallery card", "try slightly lower angle for willow-like droop"]),
    "ls26_stochastic_sparse_retention": E(3, "working", "Sparse stochastic plant with an identity option that leaves some segments unbranched. Opens negative space through the crown.", ["reduce the retention weight if it feels too bare", "try one extra iteration to re-densify while keeping gaps"]),
    "ls27_tripod_crown_3d":         E(4, "winner",   "Three-way radial 3D crown using pitch plus repeated roll. Reads as a tripod sapling or chandelier skeleton.", ["try graph interpretation to inspect the radial topology", "increase angle slightly for a wider crown"]),
    "ls28_candelabra_3d":           E(4, "strong",   "3D candelabra with branches distributed across pitch-up, pitch-down, and roll. Good evidence that the local frame is behaving volumetrically.", ["try a darker trunk material", "increase step length for a taller candelabrum"]),
    "ls29_spiral_pine_3d":          E(4, "winner",   "Spiral conifer built from alternating roll-left and roll-right branches. The trunk continues while the crown wraps around it.", ["one more iteration for denser spiral", "try a colder evergreen palette"]),
    "ls30_pitchfork_canopy_3d":     E(4, "strong",   "Mixed 3D/planar canopy combining pitched and yawed branches. Reads as a pragmatic test of hybrid crown construction.", ["increase pitch angle for more vertical spread", "compare against ls27 to isolate the effect of yaw branches"]),
    "ls31_radial_quadbush_3d":      E(4, "winner",   "Four-way radial bush created by rolling the same pitched branch around the trunk. Symmetry reads clearly without collapsing to a flat silhouette.", ["try five-way radial spacing", "bridge this DNA into graph-grammar for chandelier conversion"]),
}

# Cross-gallery DNA bridges — L-system feeding into other substrates
GRAPH_LSYSTEM_BRIDGE_EVALS = {
    "gg_ls01_plant_chandelier":          E(4, "winner", "DNA BRIDGE: L-system plant as Adelman chandelier via graph_grammar. Glowing white-pearl branches against green. Same DNA as ls03 tube-tree, now Adelman chandelier."),
    "gg_ls02_plant_modulor_folded":      E(5, "crown_jewel", "DNA BRIDGE: L-system plant + modulor_fold on leaves. Dense cypress-like column — fold added visible foliage substance to every tip. Proof that two grammars compose."),
    "gg_ls03_plant_koch_subdivided":     E(3, "working", "DNA BRIDGE: L-system plant + koch_edge subdivision. Thin zigzagging tree. CA-prune originally tried here but L-system trees are narrow in XZ and all project to same cells.", ["try heavier koch amplitude", "or fractal_prune with bigger bailout"]),
    # Triple bridge — L-system → soft-body sim → graph chandelier
    "gg_ls04_fallen_tree_chandelier":    E(4, "winner", "TRIPLE DNA BRIDGE: L-system plant → soft-body sim (wind + gentle gravity) → graph chandelier. Crumpled glowing pearl cluster on the ground. DNA travelled across THREE substrates: grammar → physics → rendering."),
    "gg_ls05_standing_tree_chandelier":  E(5, "crown_jewel", "TRIPLE DNA BRIDGE: Same L-system plant, stiff + gentle gravity. Pearl-cluster chandelier standing upright — grapes of light. The reverse bridge (post-sim pose → graph) makes DNA survive physics."),
    # Noise-as-universal-post-op
    "gg_noise01_plant_perturbed": E(4, "winner", "POST-OP BRIDGE: L-system plant + simplex-noise displacement. Every pearl jitters along a 3D noise vector. Straight chandelier becomes organically wobbly — same DNA plus modifier."),
    "gg_noise02_plant_cellular":  E(4, "winner", "POST-OP BRIDGE: Same L-system plant, but noise_type=cellular (Worley). Branches get crystalline encrusted bumps — reads as a coral twig. Noise-type as expressive DNA axis."),
    # Stacked bridges — DNA flowing through ≥4 substrates
    "gg_quad01_ca_tapestry_chandelier": E(5, "crown_jewel", "QUADRUPLE DNA BRIDGE: Life-without-Death CA → soft-body cloth (pinned corners, wind) → graph from post-sim pose → chandelier. Pearl-lamps hang from a V-shaped sagging tapestry like rigging for an installation. Four substrates, one config."),
    "gg_quint01_ca_sb_noise":           E(3, "working",     "QUINTUPLE DNA BRIDGE: CA → softbody → graph → noise-post-op → chandelier. All three bridge shapes (seeder, reverse-pose, post-op) stacked in one config. Proof-of-concept works but sparse CA + wind collapsed most nodes off-frame.", ["denser CA density 0.5+", "weaker wind or fewer steps"]),
    # RD seeder bridges
    "gg_rd01_coral_chandelier":    E(4, "winner",     "DNA BRIDGE: Gray-Scott coral → graph → chandelier. Pearl-lamps embedded in a coral topology against dark platform. Reads as star-cluster seascape."),
    "gg_rd02_stripes_capsule":     E(4, "winner",     "DNA BRIDGE: Gray-Scott stripes → graph → capsule. Beige capsule-pasta fragments traced along the Turing ridges. Archaeological aesthetic."),
}

SB_RD_BRIDGE_EVALS = {
    "sb_rd01_coral_cloth":  E(3, "working", "DNA BRIDGE: Gray-Scott coral → soft-body cloth. Coral cells become particles pinned at top corners. Hangs as a tattered coral-lace banner.", ["longer steps for full settle", "bigger particle_radius for visibility"]),
    "sb_rd02_stripes_flag": E(2, "broken", "DNA BRIDGE: Gray-Scott stripes → soft-body flag. Flag pinned top-row, side wind — but rendered near-empty. Camera AABB missed the fluttering banner.", ["lower stiffness", "reduce wind strength", "fix AABB to use sim.positions post-sim"]),
    # FROZEN PROCESSED FORM — glass vessel
    "gl01_classic_bulb":   E(5, "crown_jewel", "Drooping amphora teardrop. Sphere under gravity + small top pin + moderate pressure + 200 steps = a fully-formed vessel that no one designed. Wireframe visible, silhouette reads unmistakably as hand-blown glass. The canonical frozen-processed-form artifact."),
    "gl02_long_bottle":    E(5, "crown_jewel", "Elongated olive-green bottle pod. Low stiffness + stronger gravity + 380 steps = vertical stretch. The longer you simulate, the longer the neck. Duration as design parameter made literal."),
    "gl03_wide_bowl":      E(4, "winner",      "Rounded orange urn/egg. Wide top-pin ring (28%) + high pre-inflation + weak gravity = pressure dominates, gravity mild. Shows that force balance determines vessel proportions."),
    "gl04_lopsided_vase":  E(5, "crown_jewel", "Magenta vessel slumped off-axis. Non-axial gravity (sideways + down) produces a lopsided hand-crafted look — as if the glass sagged sideways while cooling. Gravity direction as aesthetic choice."),
    "gl05_collapsed_sag":  E(4, "winner",      "Over-cooked tall brown collapse. Very low stiffness + strong gravity + 500 steps = vessel fails into a long teardrop. Documents what breaks the vessel pattern; the failure state is itself a legible form."),
    # GLASS MEETS MOULD — industrial glass-blowing process rendered
    "gm01_bottle_in_cylinder_mould": E(4, "winner",      "Glass pre-inflated 70%, pressed into a cylinder mould radius 0.55. The expanding sphere hits the cylinder walls and takes its uniform-radius shape. Elongated bottle with visibly vertical sides — the mould imprinted on the vessel."),
    "gm02_vase_in_tapered_mould":    E(3, "working",     "Glass in a tapered mould (narrow top, wide bottom). Amphora-like silhouette but taper is subtler than intended; the mould effect is there but not dramatic at these mould radii. Increase the taper ratio or use higher preinflate for stronger mould contact.", ["taper radii 0.2→0.8 not 0.25→0.7", "higher preinflate (1.2+) to force glass into mould contours"]),
    "gm03_box_in_cube_mould":        E(5, "crown_jewel", "Sphere glass pressed into a box mould 0.9×1.4×0.9. Clearly RECTANGULAR silhouette — the round glass became a square bottle. Flat faces visible where expansion was stopped by box walls. The clearest 'mould imprinted on vessel' render in the batch."),
    "gm04_pressed_onto_sphere":      E(3, "working",     "External mould (exclude mode): glass drapes over a solid sphere obstruction mid-vessel. The vessel shape shows the obstacle's influence — subtle bulge around y=0.9 where the sphere sits. Would read more dramatically with a larger/more asymmetric external form."),
}

PS_RD_BRIDGE_EVALS = {
    "ps_rd01_coral_garden":  E(5, "crown_jewel", "DNA BRIDGE: Gray-Scott coral → wood-cylinder garden. The coral pattern materialized as a beige cylinder forest — reads as an archaeological excavation of reef columns. One of the session's best crossovers."),
    "ps_rd02_mitosis_cells": E(4, "winner",      "DNA BRIDGE: Gray-Scott mitosis → pastel sphere colonies. Self-replicating RD dots rendered as pastel-cream sphere patches — reads as biology in a petri dish."),
}

# Noise bridges living in soft-body + primitive-stack galleries
SB_NOISE_BRIDGE_EVALS = {
    "sb_noise01_jelly_crystal": E(4, "winner", "POST-OP BRIDGE: Jelly grid + cellular noise post-op. Settled lattice gets Voronoi-crystal displacement. Reads as a fractured gemstone scaffold."),
}

PS_NOISE_BRIDGE_EVALS = {
    "ps_noise01_jiggled_city": E(5, "crown_jewel", "POST-OP BRIDGE: Conway CA city + simplex-noise jiggle. Every cube offset by a small 3D noise — the grid-city becomes leaning/drunk modernist. Universal post-op proved: any substrate's positions can take the same noise_displace block."),
}

# ─── Reaction-Diffusion (Gray-Scott) — new substrate ─────────

MESH_RD_BRIDGE_EVALS = {
    "mg_rd01_coral_extruded":   E(3, "working", "DNA BRIDGE: Gray-Scott coral heightmap as mesh-grammar seed, then extrude-up. Coral ridges slightly raised; mesh-ops fired but subtly. Proof of the bridge — RD field as starting topology for face rewriting.", ["higher height_amp", "more generations", "add bevel after extrude"]),
    "mg_rd02_stripes_insetting":E(3, "working", "DNA BRIDGE: Gray-Scott stripes heightmap + inset + extrude. Low-relief terrain with subtle tile-scale operations. Reads smooth; ops barely visible at this scale.", ["larger inset amount", "3+ generations", "use scale_face op after"]),
    "mg_rd03_mitosis_bulged":   E(5, "crown_jewel", "DNA BRIDGE: Gray-Scott mitosis + bulge op on up-facing faces. RD dots become puffy blister bumps — reads as a literal tissue sample. The clearest cross-substrate win: RD provides the pattern, mesh-grammar provides the volume."),
    # L-system → mesh-grammar
    "mg_ls01_tree_extruded":    E(3, "working", "DNA BRIDGE: L-system plant as box-prism mesh seed; each turtle segment becomes a thin oriented box, then extrude-up. Skeletal tree — bridge fires but extrusion amount is small relative to box size.", ["larger extrude distance", "smaller base_width so extrusion shows"]),
    "mg_ls02_tree_bulged":      E(4, "winner", "DNA BRIDGE: Same L-system plant with bulge op. Branches puff into triangular leaf-pockets — the mesh-grammar op reads the L-system tree's segment-boxes as foliage waiting to be inflated. Novel biology."),
    # CA → mesh-grammar
    "mg_ca01_conway_city_meshed":          E(5, "crown_jewel", "DNA BRIDGE: Conway Life as extruded-box mesh seed + inset + extrude on up-faces. Reads as architectural concept models — stepped buildings with skylight-well tops. Conway's city becomes Brutalist maquette."),
    "mg_ca02_life_without_death_meshed":   E(4, "winner", "DNA BRIDGE: Life-without-Death as dense mesh seed + subtle bulge. Cross-hatched mineral crust, low-relief accumulation. The rule's memory (cells that lived stay alive) materialized as encrusted terrain."),
    # Primitive-as-seed — any Ada primitive or Godot built-in becomes mesh-grammar starting geometry
    "mg_prim01_dodecahedron_extruded":    E(5, "crown_jewel", "PRIMITIVE-AS-SEED: Dodecahedron from Ada primitive library + extrude-all. Twelve pentagonal faces each grow outward — reads as blooming crystal flower. First proof that scene-path seeds unlock the full primitives library."),
    "mg_prim02_octahedron_inset":         E(4, "winner",      "PRIMITIVE-AS-SEED: Octahedron + inset + extrude. Triangular faces recess then project — origami-paper sculpture aesthetic."),
    "mg_prim03_torus_bulged":             E(4, "winner",      "PRIMITIVE-AS-SEED: Godot TorusMesh + bulge. Donut surface bumps outward, tri-tiling visible on the ring."),
    "mg_prim04_cylinder_split":           E(4, "winner",      "PRIMITIVE-AS-SEED: Cylinder + split on caps + extrude. Clean drum with radially-split top — subdivide-op operating on a non-seed primitive."),
    "mg_prim05_tetrahedron_scallop":      E(3, "working",     "PRIMITIVE-AS-SEED: Tetrahedron + bulge. Simplest polyhedron becomes rounded — minimal DNA producing elaboration."),
    "mg_prim06_bipyramid_bulged":         E(3, "working",     "PRIMITIVE-AS-SEED: Bipyramid + bulge. Two-pointed seed bulges into a lozenge/gem shape."),
    "mg_prim07_crystal_extruded":         E(4, "winner",      "PRIMITIVE-AS-SEED: Ada crystal primitive + extrude. Gem seed becomes an exploded crystal cluster with inner reflections visible through the extruded shell."),
    "mg_prim08_diamond_inset":            E(3, "working",     "PRIMITIVE-AS-SEED: Diamond + inset + bulge. Jeweled seed gets recessed facets — reads as cut gem with texture treatment."),
    "mg_prim09_capsule_scalloped":        E(3, "working",     "PRIMITIVE-AS-SEED: Godot CapsuleMesh + noise-displace. Pill shape with organic surface perturbation — the noise post-op pattern reaching mesh-grammar."),
    "mg_prim10_arch_subdivided":          E(5, "crown_jewel", "PRIMITIVE-AS-SEED: Ada architectural arch + extrude. The semicircle-arch primitive becomes a ribbed archway with tessellated mesh visible on every face. First piece of Ada 'building primitives' library routed through mesh-grammar."),
}

RD_EVALS = {
    "rd01_spots_heightmap":    E(4, "winner",     "Classic Gray-Scott spots (F=0.037, K=0.06). Heightmap produces a field of dome-islands — atoll aesthetic."),
    "rd02_stripes_heightmap":  E(5, "crown_jewel","Stripes pattern (F=0.022, K=0.051). Green-teal brain/fingerprint ridges — one of the canonical Gray-Scott outputs made tangible as terrain."),
    "rd03_mazes_heightmap":    E(4, "winner",     "Maze pattern (F=0.029, K=0.057). Interconnected channels — coral labyrinth."),
    "rd04_coral_heightmap":    E(5, "crown_jewel","Coral pattern (F=0.062, K=0.061). Bronzed coral-brain terrain with branching ridges and cavities. Stunning organic texture from two constants."),
    "rd05_mitosis_heightmap":  E(4, "winner",     "Mitosis pattern (F=0.0367, K=0.0649). Teal dome-cells self-replicate. Biology from two numbers."),
    "rd06_coral_pillars":      E(5, "crown_jewel","Coral pattern rendered as beige polyp-pillar forest. 3D forest of thousands of stubs following the RD ridges. Most architectural RD render."),
    "rd07_stripes_plate":      E(4, "winner",     "High-res stripes rendered as a flat textured plate viewed top-down. Pure pattern — brain fingerprint as image, no geometry. The RD DNA at full resolution."),
    "rd08_chaos_heightmap":    E(3, "working",    "Chaotic (F, K) never equilibrates — 5000 iterations produces a perpetually-morphing ridge landscape. Parameters that don't settle."),
    "rd09_delta_turing_plate": E(4, "strong",     "δ-class Turing-like negatons rendered top-down. Clear hex-lattice intent and a good demonstration that Gray-Scott can stabilize into grain-bounded cellular order."),
    "rd10_theta_ring_heightmap": E(4, "strong",   "θ-class ring growth translated into terrain. Reads as a looping ridge network rather than simple stripes."),
    "rd11_iota_negaton_plate": E(3, "working",    "ι-class molecule-like clustering. More diagrammatic than lush, but valuable because it shows the negaton regime rather than the usual positive ridges."),
    "rd12_kappa_hedgerow_pillars": E(4, "strong", "κ-class hedgerow rendered as pillars. Architectural, hedge-maze reading comes through well in 3D."),
    "rd13_lambda_hex_heightmap": E(5, "winner",   "λ-class mitosis field settling toward hex packing. One of the clearest demonstrations of self-replication becoming spatial order."),
    "rd14_epsilon_overcrowd_plate": E(4, "strong","ε-class overcrowding rendered top-down. More turbulent than λ: spot mitosis, die-out, and rapid refilling all stay visible in one image."),
    "rd15_mu_worm_heightmap":  E(4, "strong",     "μ-class worm lanes. Distinct from κ because the channels stay more separated and directional."),
    "rd16_zeta_stable_heightmap": E(4, "strong",  "ζ-class stable-spot terrain. Calmer and more symmetric than ε, while still avoiding the static regularity of λ."),
    "rd17_eta_spotworm_heightmap": E(4, "strong", "η-class mix of spots and short worms. Nicely occupies the in-between regime rather than collapsing to pure ridges or pure cells."),
    "rd18_gamma_branch_heightmap": E(4, "strong", "γ-class unstable stripe terrain. Branching ridges and local breakdown events make it a stronger dynamic counterpoint than the flatter void-field attempt."),
}

# ─── Wallpaper patterns — 17 mathematical tilings ─────────────

PATTERN_EVALS = {
    "pt01_p1_bauhaus":    E(3, "working",     "p1 — translation only. Simplest group. Bauhaus palette reveals the raw motif tiling without symmetry ornament."),
    "pt02_p2_escher":     E(3, "working",     "p2 — 180° rotation. Monochrome palette emphasizes figure-ground flipping between tile halves."),
    "pt03_p4m_alhambra":  E(4, "winner",      "p4m with dot-motif and Alhambra palette. 90° rotation + reflections produce ceramic-tile aesthetic. The most common Alhambra group."),
    "pt04_p6m_persian":   E(5, "crown_jewel", "p6m — hexagonal rotation + reflections, the richest of all 17 groups. Persian palette turns the dot motif into carpet medallions. Textbook output of wallpaper mathematics."),
    "pt05_p3_memphis":    E(3, "working",     "p3 — 120° rotation only, no reflection. Triangular chirality. Memphis palette reads as confetti-scale postmodern textile."),
    "pt06_pmm_tatami":    E(4, "winner",      "pmm — two perpendicular reflections on a rectangular lattice. Tatami palette turns the weave into literal straw matting."),
    "pt07_p4g_pastel":    E(3, "working",     "p4g — 90° rotation + reflections NOT through centers. Pastel palette softens the chirality distinction from p4m."),
    "pt08_p6_monochrome": E(3, "working",     "p6 — 60° rotation only, no reflection. Hexagonal chirality. Monochrome reduces to pure geometry."),
    "pt09_pgg_bauhaus":   E(3, "working",     "pgg — two perpendicular glides, no reflection. Chiral zig-zag. Bauhaus palette."),
    "pt10_p3m1_alhambra": E(4, "winner",      "p3m1 — 120° rotation + reflection through rotation centers. Classic Moorish tessellation emerges from Alhambra palette + dot motif."),
}

# ─── Facade presets — 9th substrate ───────────────────────────
# Each preset IS the DNA; notes describe what the rendered image shows,
# not what the style "should" be.

FACADE_EVALS = {
    "classical":                  E(5, "crown_jewel", "Symmetric 5-bay with dentil cornice, arched piano-nobile windows, columns flanking the base, portholes and checkerboard rustication. Textbook classical composition — the reference all others are measured against."),
    "baroque":                    E(5, "crown_jewel", "Solomonic (twisted) columns + broken pediments + arched windows with ornamental keystone + checkerboard base. Reads unmistakably 17th-century Italian."),
    "gothic_portal":              E(4, "winner",      "Pointed arches, tracery window, vertical emphasis. Reads as cathedral-front."),
    "capri_whitewash":            E(3, "working",     "Mediterranean vernacular — small windows, flat roof, white stucco. Minimal but recognizably Capri."),
    "florence_marble":            E(4, "winner",      "Polychrome marble facade with alternating stone bands. Florentine 14th-15th century."),
    "florentine_polychrome":      E(4, "winner",      "Giotto-tradition polychrome: alternating marble courses + arched openings."),
    "bernini_colonnade":          E(4, "winner",      "Curved colonnade, piazza-embracing form. The Bernini Vatican gesture compressed into a facade."),
    "galleria_vittorio_emanuele": E(3, "working",     "Iron-and-glass arcade silhouette. Reads as 19th-century Milan shopping gallery."),
    "continuous_monument":        E(3, "working",     "Superstudio-style rationalist grid — endless gridded surface. Cold by design."),
    "decon_fragment":             E(3, "working",     "Deconstructivist tilted planes. Intentional dissonance; abstract."),
    "memphis_totem":              E(4, "winner",      "Sottsass 1980s postmodernism — scattered geometric shapes, pastel accents, graphic irregular composition."),
    "naples_diamond_rustication": E(4, "winner",      "Diamond-point rusticated stone base — distinctive Neapolitan palazzo vocabulary."),
    "nyc_tenement":               E(3, "working",     "19th-century walk-up tenement with regular fenestration. Reads as NYC Lower East Side."),
    "painted_vault":              E(3, "working",     "Pompeii-style trompe-l'oeil painted architectural framing."),
    "pompeii_black_room":         E(3, "working",     "Pompeii Fourth Style black ground with classical architectural motifs."),
    "pompeii_ceiling_coffers":    E(3, "working",     "Deep-relief coffered ceiling composition."),
    "pompeii_ceiling_medallion":  E(3, "working",     "Central medallion with radiating panels — classical ceiling."),
    "pompeii_fourth_style":       E(3, "working",     "Theatrical fantasy architecture — Pompeii's final wall style."),
    "pompeii_red_room":           E(4, "winner",      "Rich Pompeii red ground with classical architectural framing. The canonical Pompeii color."),
    "pompeii_second_style":       E(3, "working",     "Illusionistic architecture opening flat walls into depicted depth. Second-Style perspective trick."),
    "superstudio_grid":           E(3, "working",     "Superstudio's rationalist grid. Modernist critique in facade form."),
    "venetian_gothic":            E(4, "winner",      "Venetian Gothic with bifora (two-arched) windows and Moorish arch forms. Reads as Ca' d'Oro descendant."),
    "villa_boscoreale":           E(3, "working",     "Pompeii-adjacent Roman villa — Boscoreale wall paintings compositional framing."),
    "villa_mysteries":            E(3, "working",     "Villa of the Mysteries reference — Dionysian frieze composition."),
    "villa_san_michele":          E(3, "working",     "Axel Munthe's Capri villa reference. Mediterranean classical."),
    "villa_san_michele_exact":    E(3, "working",     "More literal Villa San Michele reconstruction. Same source, tighter fit."),
}

# ─── Trajectory (force → form) — 10th substrate ───────────────
# The time axis used as a spatial axis. Circle becomes spiral, Lorenz
# becomes butterfly, double pendulum becomes chaotic ribbon.

TRAJECTORY_EVALS = {
    "tr01_unit_circle_spiral":      E(5, "crown_jewel", "The canonical example. Unit circle (cos t, sin t) + constant rise → clean tubular helix, blue-to-tan gradient showing time progression. The question 'can we save the time domain in the spatial domain?' rendered directly."),
    "tr02_lissajous_knot_3d":       E(5, "crown_jewel", "3D Lissajous with 3:2:5 frequency ratios — closed interlocking curve rendered as pink/purple tubes. Three orthogonal sine waves conspire into a knot. Signal-processing math as sculpture."),
    "tr03_pendulum_extruded":       E(4, "winner",      "1D damped pendulum extruded along Z. Sine-like oscillation visibly decays along the time axis — damping made spatially legible."),
    "tr04_double_pendulum_chaos":   E(3, "working",     "Double pendulum tip trajectory — tangled chaos. Camera frames it tight; the chaotic ribbon is there but reads as knotted mass rather than legible fractal. Needs bigger camera pull-back."),
    "tr05_lorenz_butterfly":        E(5, "crown_jewel", "Lorenz attractor at canonical (σ=10, ρ=28, β=8/3). Two orbit wings visible, blue-pink gradient tracing time. The iconic strange-attractor butterfly made into a standalone sculptural object."),
    "tr06_kepler_precessing_orbit": E(4, "winner",      "Keplerian orbit with precession — rosette pattern from top-down. Orbital mechanics + slow rotation → apsidal-precession flower."),
    "tr07_magnetic_helix":          E(5, "crown_jewel", "Charged particle in uniform B-field along Y. Cyclotron motion + vertical velocity → gorgeous tapering tornado helix, tan-to-teal gradient. Reads as a literal tornado or slinky."),
    "tr08_damped_spiral":           E(4, "winner",      "2D damped oscillator extruded along Z. Spirals inward as amplitude decays — the time axis makes the decay visible."),
    "tr09_lissajous_fan":           E(3, "working",     "Fan of 12 parallel circular spirals with phase-spread π — tight stacked composition, reads as a woven ring. Camera too close."),
    "tr10_lorenz_fan":              E(4, "winner",      "Six Lorenz attractors from initial conditions differing by 0.002. Chaos amplifies the gap — six butterflies diverge into distinct silhouettes. Sensitivity to initial conditions made spatial."),
    # FROZEN PROCESSED FORM — bouncing ball with walls + plates
    "br01_ball_in_box":              E(5, "crown_jewel", "Ball bouncing in rectangular box. 16 seconds of gravity + wall reflections traced as gradient parabolas — large blue arcs on the left decay to small tan arcs on the right. The whole life of one bouncing ball as a single drawing. The clearest 'frozen processed form' in the gallery."),
    "br02_galton_board":             E(3, "working",     "Angled-peg zigzag. Ball hooks off one diagonal peg then curves down. Only 1-2 collisions register reliably — peg density + ball size balance isn't finding the full cascading-scatter behavior.", ["tighter peg spacing", "larger initial horizontal velocity", "peg as crossing-X (two segments) instead of single-angle"]),
    "br03_pinball_triangle":         E(4, "winner",      "Closed triangle of three plates, ball bouncing inside at high restitution. Chaotic scribble fills the triangular boundary — reads as purple pinball pocket. The energy preservation is visible; this is an almost-elastic-limit render."),
    "br04_stepped_cascade":          E(4, "winner",      "Six tilted plates in staircase. Ball enters top-left, cascades diagonally along each step, decays into a rest at the bottom. Clean waterfall-down-stairs read — the force sequence IS the choreography."),
    "br05_curved_funnel":            E(2, "broken",      "V-funnel + catch bowl. Ball escaped the plate field or Z-extrusion moved it off-camera — output empty. Illustrates that plate layouts with gaps fail closed-system tests.", ["remove extrude_rate for first iteration", "widen funnel arms to prevent escape", "add containment floor wall"]),
    "br06_pattern_writer_s_curve":   E(2, "broken",      "Attempt at reverse-engineering an S-curve via 8 hand-placed plates. Only 2 trail fragments visible — ball escaped. Honest proof that hand-tuned reverse engineering is actually hard; this is Tier 3 (optimization) in disguise, not Tier 1 (hand-tune).", ["this confirms reverse-engineering needs a genetic algorithm or differentiable simulator, not hand placement"]),
    # FROZEN POINTS — sampling pattern + mould collision
    "fz01_circle_beat_dodecagon":      E(5, "crown_jewel", "Unit circle strobed 12 times at integer beats = dodecagon vertices with blue-to-tan color gradient marking time. Same motion as tr01 spiral, different sampling → polygon. The sampling pattern IS the form."),
    "fz02_circle_golden_constellation":E(4, "winner",      "Rising spiral sampled at 60 golden-ratio intervals. Low-discrepancy phyllotactic distribution — 'sunflower seed' arrangement floating in air. Same rising motion, irregular but balanced sampling."),
    "fz03_lorenz_curvature_scatter":   E(4, "winner",      "Lorenz attractor sampled where curvature is highest. Points cluster at wing-switch transitions — the chaotic 'events' get more weight. Y-silhouette reveals where dynamics become interesting. Sampling bias as a lens on dynamics."),
    "fz04_spiral_meets_sphere":        E(5, "crown_jewel", "Rising spiral of radius 2.5 pressed into a containing sphere of radius 1.5. The spiral cannot escape; it clamps to the sphere's surface. The frozen form is part free helix, part surface-tracing hemisphere. Glass pressed into a mould — literally rendered."),
    "fz05_lissajous_meets_cylinder":   E(5, "crown_jewel", "3D Lissajous knot pressed into cylinder mould radius 1.0. Horizontal oscillation clamped, vertical stays free. Reads as label printed on a can or calligraphic drum inscription. Different mould geometry = different frozen pattern from same motion."),
    "fz06_bouncing_against_dome":      E(3, "working",     "Bouncing ball + sphere-exclude mould. Trajectory can't pass through the dome region — gets snapped to its surface. Visible as skim-arc pattern across horizon. Subtle at this scale.", ["larger relative dome radius", "try contain mode to make it a ceiling"]),
}

SB_LSYSTEM_BRIDGE_EVALS = {
    "sb_ls01_plant_skeleton":       E(4, "winner", "DNA BRIDGE: L-system plant as spring-mass skeleton. Upper tree stands, lower portion collapsed to floor. Visible L-system branching structure with physics consequence."),
    "sb_ls02_plant_wind_collapse":  E(5, "crown_jewel", "DNA BRIDGE: Same L-system plant, low stiffness + diagonal wind + 140 steps. Tree bent sideways almost to ground. 'Fallen tree after storm' from pure DNA + force."),
    # CA-as-universal-seeder bridges
    "sb_ca01_conway_cloth":              E(3, "working", "DNA BRIDGE: Conway Life 8-step pattern as a hanging cloth. Sparse — islands of alive cells hang as fragments. Conway dies off too fast for full tapestry.", ["higher density 0.65+", "more iterations with Day-and-Night instead"]),
    "sb_ca02_life_without_death_cloth":  E(5, "crown_jewel", "DNA BRIDGE: Life-without-Death as a woven tapestry hung from two corners. 12 CA steps fill the grid (cells never die); result drapes as a dense lattice with slight wind. Genuinely beautiful — CA rule becomes textile."),
}

PS_LSYSTEM_BRIDGE_EVALS = {
    "ps_ls01_bauhaus_tree": E(3, "working", "DNA BRIDGE: L-system plant as Bauhaus primitive sculpture. Cubes on branches, spheres at nodes, bipyramid tips — traces the tree but reads as dots.", ["larger primitive_size 0.08+", "or denser sample-per-segment"]),
    "ps_ls02_wood_tree":    E(3, "working", "Same L-system DNA, wood palette. Reads as totem-pole variant — palette changes character but structure is identical.", ["larger primitives", "try size_by_depth: false for chunkier feel"]),
    # CA-as-universal-seeder bridges
    "ps_ca01_conway_city":     E(5, "crown_jewel", "DNA BRIDGE: Conway Life as monochrome skyline. Cubes at alive cells, height scaled by live-neighbor count — clusters become towers, isolated cells squat blocks. Emergent modernist city from one rule."),
    "ps_ca02_highlife_bauhaus":E(3, "working", "DNA BRIDGE: HighLife + Bauhaus palette = scattered primary-color beads on the CA pattern. Pretty but less architectural than the Conway city. The rule's sparse alive-count favors flat layouts.", ["try life_without_death for denser bead field", "or use cube shape for tighter clustering"]),
}


def write_gallery_evals(name: str, evals: dict) -> None:
    out_dir = ENCYCLOPEDIA_DIR / "public" / name
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "evals.json"
    payload = {
        "evaluated_by": AUTHOR,
        "date": TODAY,
        "schema_version": 1,
        "evals": evals,
    }
    out_path.write_text(json.dumps(payload, indent=2))
    print(f"  wrote {out_path.relative_to(REPO_ROOT.parent)}  ({len(evals)} evals)")


def main() -> int:
    print(f"Writing evals (date={TODAY}, author={AUTHOR})")
    # Merge cross-gallery L-system bridge evals into each host gallery
    graph_full = {**GRAPH_EVALS, **GRAPH_LSYSTEM_BRIDGE_EVALS}
    sb_full    = {**SOFT_BODY_EVALS, **SB_LSYSTEM_BRIDGE_EVALS, **SB_NOISE_BRIDGE_EVALS, **SB_RD_BRIDGE_EVALS}
    ps_full    = {**PRIMITIVE_STACK_EVALS, **PS_LSYSTEM_BRIDGE_EVALS, **PS_NOISE_BRIDGE_EVALS, **PS_RD_BRIDGE_EVALS}
    write_gallery_evals("graph-grammar-gallery",   graph_full)
    write_gallery_evals("mesh-grammar-gallery",    {**MESH_EVALS, **MESH_RD_BRIDGE_EVALS})
    write_gallery_evals("form-gallery",            FORM_EVALS)
    write_gallery_evals("primitive-stack-gallery", ps_full)
    write_gallery_evals("soft-body-gallery",       sb_full)
    write_gallery_evals("lsystem-gallery",         LSYSTEM_EVALS)
    write_gallery_evals("rd-gallery",              RD_EVALS)
    write_gallery_evals("pattern-gallery",         PATTERN_EVALS)
    write_gallery_evals("facade-gallery",          FACADE_EVALS)
    write_gallery_evals("trajectory-gallery",      TRAJECTORY_EVALS)
    total = (len(graph_full) + len(MESH_EVALS) + len(FORM_EVALS)
             + len(ps_full) + len(sb_full) + len(LSYSTEM_EVALS)
             + len(RD_EVALS) + len(PATTERN_EVALS) + len(FACADE_EVALS)
             + len(TRAJECTORY_EVALS))
    print(f"Total: {total} evals across 10 galleries")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
