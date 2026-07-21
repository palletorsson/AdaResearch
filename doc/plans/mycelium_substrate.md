# The L-system / space-colonization mycelium substrate

> Scoped 2026-07-19 out of the biome visual loop. The biome's `fungus:ca`
> substrate (a 3D cellular automaton, MoldNetwork) was pushed to its ceiling
> in the rule-search: it renders a spreading voxel *network* when frozen at the
> right generation, but it fundamentally **fills or dies** — it cannot hold
> hair-thin branching filaments. True mycelium — hyphae thinning to their tips,
> an irregular web across the ground — needs a **curve renderer**, not a voxel
> grid. This is that substrate, as its own thread.

## The form we're after

Mycelium is not a mushroom (that is the fruiting body) and not a blob. It is a
**branching filament network**: a colony spreading flat from a seed point,
hyphae dividing and dividing, each strand tapering toward its growing tip, the
whole thing an open irregular web with the density highest near the origin and
thinning outward. Occasional fruiting bodies (mushrooms) rise where the web is
dense.

## What already exists (reuse, don't rebuild)

- **`MorphoSweep`** (`algorithms/nature_system/morphology/morpho_sweep.gd`) —
  a generalized sweep: any cross-section along any path with variable radius and
  twist. A tapering circle swept along a branch **is a hypha**. This is the
  render primitive; it exists.
- **`Turtle` + `LSystem`** (`algorithms/machinelearning/thegame_a/`) and
  **`tree_walker.gd`** — turtle-graphics branch generation from an L-system
  string. A filament grammar drives them.
- **`grammar_seed`** (the seams artifact) — a working turtle L-system fern; the
  branching-walk pattern in miniature.
- **`fungus_morphology.gd`** — a *mushroom* builder (cap/stem/gills). NOT the
  web — but the optional fruiting bodies at dense nodes could reuse it.
- **biome-6 batching** in `GridBiomeComponent` — filaments are many thin tube
  segments; they MUST batch into MultiMesh under the per-map budget, exactly the
  existing halo/marker path.

## Two generators (prototype order)

1. **L-system turtle filaments** (fast prototype). A filament grammar
   (`F → FF[+F][-F]` style with low angles and stochastic drop) walked by the
   turtle; each `F` becomes a `MorphoSweep` tube whose radius shrinks with depth.
   Machinery exists; validates the render pipeline in a day. Reads *regular*,
   which mycelium is not — so it is the scaffold, not the destination.
2. **Space colonization** (the target). Scatter attractor points on the ground
   disc; grow hyphae from the seed toward nearby attractors, killing an attractor
   when a tip reaches it; the emergent branching is the organic irregular web
   real mycelium has. New code (~150 LOC, standard algorithm), but the correct
   look. Renders through the same `MorphoSweep` + batch path as (1).

## Where it plugs in

- **Grammar:** a new fungus algo — `fungus:mycelium:seed`. The parser already
  keeps `algo` verbatim; no grammar change beyond documenting the value.
- **Dispatch:** `biome_paint_dispatcher._spawn_fungus` **branches on the algo**:
  `ca` keeps the gen-frozen voxel network (unchanged — additive discipline),
  `mycelium` routes to the new filament builder. Maps using `fungus:ca` render
  byte-identical.
- **Mods reused:** `t=` tier → colony radius / branch depth; `d=` density →
  attractor count (web fill); `gen=` → growth iterations (already added). Per-cell
  deterministic seed + jitter, as the CA freeze does.
- **Ground-hugging:** flat spread (Y ≈ 0, low arcs), like the flattened CA, so it
  reads as a mat not a bush.

## Milestones (the thread's open items)

1. Filament render spike: one L-system branch string → `MorphoSweep` tapering
   tubes → capture on a probe map. Proves the pipeline.
2. Space-colonization generator: attractors on a ground disc, grow-to-attractor,
   branching web; capture; compare to (1) — pick the generator.
3. Batch the tube segments into MultiMesh under the biome-6 budget; verify
   O(kingdoms) nodes and a negative budget-clamp test.
4. Wire into `_spawn_fungus` as the `fungus:mycelium` algo branch; additive
   (probe that `fungus:ca` maps are byte-identical); tier/density/gen mods.
5. Tune the mycelial read at biome scale (min radius so it survives VR distance,
   emission for the bioluminescent look, per-cell variation); before/after vs the
   CA network on `Biome_VisualBench`.
6. Ruling: does `fungus:mycelium` become the default fungus look, or do both ship
   (`ca` = voxel network, `mycelium` = filaments) as an authoring choice? Optional
   fruiting bodies (`fungus_morphology`) at dense nodes.

## Ruling: the generator is space colonization (2026-07-21, milestone 2)

Both generators now exist and capture side by side — `mycelium_spike` (L-system
turtle) and `mycelium_colony` (space colonization). **The substrate takes space
colonization.** The L-system stays as what it was scoped to be: the scaffold that
proved the render path, not the destination.

The difference is not tuning. The L-system branches on *schedule* — every `F` at
a given depth splits the same way, so the fan is symmetric and reads as a
decoration of a rule. The colony branches because *food nearby runs out* and a
tip has to go somewhere else; the irregularity is inherited from the scatter, not
sprinkled on afterwards. That is the mycelial read.

Two things came out of building it that the plan did not anticipate:

- **Thickness should come from subtree weight, not branch depth.** The spike
  thinned by depth, which puts a thick strand anywhere shallow and a thin one
  anywhere deep regardless of what the strand carries. A mat is a *flow network*:
  everything a tip absorbs travels home through its parent. Weighting each node
  by its downstream segment count gives trunks that thicken inward and tips that
  all end hair-thin — the taper a voxel grid cannot hold at all, and the reason
  this substrate exists.
- **The spatial hash is load-bearing, not an optimisation.** The naive nearest-node
  search is O(steps x attractors x nodes); at the densities a mat actually needs it
  is hundreds of millions of distance checks and the generator stops being
  runnable. Bucketing nodes by influence-radius cells took 900 attractors /
  2600 nodes to the same 12s headless run as the 260/900 first pass.

**The gap this opens (not closable by tuning):** the colony is a *tree* — one
seed, strictly radial, no cycles. Real mycelium **anastomoses**: hyphae that meet
fuse, so the network has loops, and the mat reads as a *web* rather than a
starburst. Space colonization cannot produce a loop; it only ever attaches a new
node to one parent. Closing this needs an explicit fusion pass (join tips that
pass within some radius, and let the thickness solver run on a graph rather than
a tree). Folded into milestone 5 as its own item rather than left implicit.

## Ruling: both substrates ship (2026-07-21, milestone 6)

**Palle, verbatim: "both should ship as an authoring choice."**

Milestone 6 asked whether `fungus:mycelium` replaces the fungus look or joins it.
It joins it. The kingdom carries **two substrates and no default**:

- `fungus:ca` — the MoldNetwork cellular automaton, gen-frozen at its spreading
  front: a voxel network, blocky, algorithmic, visibly *computed*.
- `fungus:mycelium` — space-colonised filaments: tapering hyphae, trunks
  thickening inward, tips hair-thin, visibly *grown*.

They are not better and worse versions of one thing; they are two different
readings of fungus, and the map picks. That makes the choice an authoring act,
so it has to exist where authoring happens — the `/template-maps` kingdom palette
now carries `fungus · mycelium web` and `fungus · mycelium (sparse)` brushes
beside the CA ones, `/biome-gallery` lists all four fungus tokens, and the token
grammar header documents the algo as the chooser.

One honest asymmetry the ruling leaves standing: a cell that declares **no** algo
keeps the CA. That is not a default in disguise — it is the painted biome layer,
which has no algo field at all, and changing its substrate silently would break
maps that never asked. Grid cells always declare.

## Risks / gotchas

- **Perf** — many thin segments; batching is mandatory, not optional. A colony is
  hundreds of tube segments; without MultiMesh it dies the frame budget.
- **VR legibility** — hair-thin filaments vanish at distance; needs a minimum
  radius and probably emission, tuned against a walked capture (THE EDGE:
  language + desktop observation, not "walk it to find out").
- **Determinism** — seed per cell; space colonization's attractor scatter must be
  seeded or neighbours won't match run-to-run.
- **Don't confuse the two fungus forms** — `fungus_morphology` = mushrooms
  (fruiting body), this substrate = the mycelial web. They compose; they are not
  the same thing.
- **Additive** — the CA path stays as `fungus:ca`; this is a *new* algo, gated,
  negative-tested (grid-guard discipline).

## Done criteria

`fungus:mycelium:seed` renders a hair-thin branching filament web that reads as
mycelium at biome scale, batched within the per-map budget, additive (the
`fungus:ca` path byte-identical), captured before/after against the CA network.
Related: [biome_grid_redesign.md](biome_grid_redesign.md) (the layer), the
rule-search in the biome visual loop (why the CA can't do this).
