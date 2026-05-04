# Biome Layer Design — multi-scale, seed-driven, algorithm-composed

> Authored 2026-05-04 from a one-hour conversation closing the day's biome
> work. This doc captures the framework that connects what we already
> built to what we still need to build. Future sessions: read this first.

## The unifying insight

**The biome is a fractal in space.** Same architectural pattern as the
fractal database (`/fractal` in encyclopedia), applied to scale instead
of meaning. Painted cells in a `biome_paint` layer are not render units
— they are **seeds**. The renderer at each scale reads the seed map and
produces something *different* from the seed.

Once you see this, the design questions ("how do we make it organic?",
"how do biome types overlap?", "how do we keep it flexible?") all
collapse to the same answer: *layer algorithms over a seed grid, at
multiple scales, each scale a different fold of the seed.*

## Scale ladder

```
scale 0 — cell        seed token (e.g. "f3")              — paint
scale 1 — patch       ~3×3 cells of related paint         — kingdom claim
scale 2 — zone        4×6 cells (one zoo strategy)        — transition pattern
scale 3 — region      many zones                          — biome arc segment
scale 4 — corridor    Biome_Spine end-to-end              — curriculum walk
scale 5 — world       all maps with biome layer           — project ecosystem
```

Each scale **consumes the scale below**. At cell scale, the renderer
spawns one substrate per paint token. At patch scale, painted cells
become anchors for territorial regions. At zone scale, dominant kingdom
sets terrain mode + ambient. At region scale, kingdom transitions become
paths and gradients. Same paint, five readings.

Implementation rule: **every scale has its own fold function**. Same
`FoldFn` signature as the encyclopedia's fractal database. Adding scale
N+1 = adding a fold function. Existing scales keep working.

## Seed vs render — the bedrock distinction

The painted cell specifies *intent*: "this is a flower zone, intensity
3." It does NOT specify *render*. Between paint and pixel sits the
**substrate dispatcher**, the **PresenceGrid diffusion**, and the
**rendering ladder** (per-kingdom × per-sequence tier list).

```
biome_paint layer  →  BiomePaintTokens.parse()  →  deposits
                                                       ↓
                                                  PresenceGrid
                                                       ↓
                                                  KingdomDispatcher
                                                       ↓
                                                  substrate.build(cfg)
                                                       ↓
                                                  Node3D in scene
```

`PresenceGrid` already exists in
`algorithms/nature_system/systems/presence_grid.gd` but is gated off via
`NatureRenderer.gd:296` (`_activate_living_ground`). Re-enabling it is
prerequisite for any work above scale 0.

## Algorithm palette — one row per design question

The biome's distribution questions all map to algorithms the curriculum
already teaches. Each algorithm is a unit you compose.

| Question | Algorithm | Sequence | Existing? |
|---|---|---|---|
| Who owns this point? | Voronoi / nearest-neighbor | computationalgeometry | yes |
| How does presence spread? | Reaction-Diffusion (Gray-Scott) | randomness / cellular | yes (`rd-gallery`) |
| Where do clusters form? | L-system, Poisson disk | lsystems / probability | yes (`lsystem-gallery`) |
| How do I jitter naturally? | Perlin / Simplex noise | noise (seq 8 unlock) | yes |
| Where do creatures aggregate? | Boids / flocking | swarmintelligence | yes (`boid_manager`) |
| What's alive next tick? | Cellular automata | cellularautomata | yes (`CA3D_Flexible`) |
| How do paths connect biomes? | Force fields / least-cost | forces / graph | yes |
| Where do roots branch? | Recursive subdivision | fractals | yes |

The biome stops being "render flowers" and becomes "**compose algorithms
into a flower-rendering pipeline**." Each algorithm answers one question.

## Per-question recipes

### "How do I make it look organic?"

Layered jitter, applied after seq 8 (when noise becomes
curriculum-honest):

- **Position**: each rendered piece offsets by `noise(x,z) × cell_size × 0.4`
- **Rotation**: random or aligned to flow (force fields, L-system tropism)
- **Scale**: Gaussian around the kingdom's mean, weighted by intensity
- **Density**: Poisson-disk sampling, λ = `intensity × kingdom_density`
- **Footprint extension**: each substrate's bounds extend beyond its cell
  so adjacent cells overlap visually — organic blending instead of grid

For zones < seq 8, deterministic jitter only (hash-based, predictable).

### "How do biome types overlap?"

`PresenceGrid` handles this for free once enabled. Each painted cell
deposits into one or more kingdom channels. The grid stores per-kingdom
presence as continuous fields. The renderer reads the channel with
strongest local presence; where two kingdoms overlap (typical at zone
boundaries), it either picks dominant or **blends** — tree-flower hybrid,
fungus-moss layer.

Token grammar already supports overlap: `m` and `x` tokens expand to
multi-kingdom deposits in `biome_paint_tokens.gd:75-84`. The dispatcher
runs once per emitted deposit.

### "How do tiles seed a world?"

Three nesting strategies:

1. **Voronoi territory** (cell → patch): each painted cell claims a
   territorial region, decided by nearest-neighbor or Voronoi. Empty
   cells inherit from their nearest seed.

2. **Diffusion gradient** (patch → zone): `PresenceGrid` runs N
   diffusion ticks; cells stop being discrete and become a continuous
   field. The gradient is what's rendered.

3. **L-system distribution** (zone → region): a patch becomes the
   axiom; an L-system grows clusters/paths through neighboring zones.
   Output is a placement map for substrate spawns.

Same painted layer, three rendering interpretations. Pick the right
strategy for the right scale.

### "How do we keep the system flexible?"

Same pattern as the fractal fold strategies: **configure by data, not by
code**. Every layer is small named composable units.

| Adding | Cost |
|---|---|
| New biome scale | one fold function (same FoldFn signature) |
| New kingdom | one row in `KINGDOM_KEYWORDS` + dispatch table |
| New substrate | one row in `KINGDOM_SUBSTRATE` + gallery entry |
| New rendering tier | one row in tier ladder + scene file |
| New algorithm | one row in algorithm palette + GDScript wrapper |

No layer requires touching another. The architecture stays open.

## Build path — smallest first

In dependency order. Each step is roughly an hour. Each lands a
visible upgrade. Do them in order; they compound.

1. **Re-enable `PresenceGrid` in `NatureRenderer`.** Flip the gate at
   `NatureRenderer.gd:296`. Painted cells start depositing. Nothing
   visible yet, but the infrastructure activates.

2. **Add `Biome_Spine` to a sequence file.** Without sequence
   membership, `EcosystemManager.sync_to_map` returns early. One JSON
   edit. The progression engages.

3. **Build `biome_paint_dispatcher.gd`** in `commons/biome_layers/`.
   Reads painted cells via `BiomePaintTokens.iter_painted_cells()`.
   For each deposit, calls `KingdomFactory.spawn(kingdom, intensity,
   stage_order)`. Factory dispatches to the substrate from the
   per-kingdom tier list.

4. **Wrap `tree_morphology.build()` into the tier-4 tree path.** This
   is the highest-leverage one-hour change. `lsystem_trees.gd` (82 LOC,
   placeholder) becomes a thin wrapper around `TreeMorphology.build()`
   (753 LOC, production). Sequence-11+ trees jump from primitive
   cylinders to full DNA-driven L-system trees.

5. **Wrap `CellularAutomata3D_Flexible` into fungus tier-4 mycelium.**
   Same pattern: existing `ca_surface.gd` calls into the production CA
   class with a fungus-flavoured config. One hour.

6. **Add jitter post-op via Perlin.** Position + rotation +
   scale displacement, gated to seq 8+. One pass over spawned
   children, applied uniformly. Organic look unlocks.

7. **Voronoi territory layer.** New scale-1 fold. Painted cells claim
   patches; empty cells render as nearest-neighbor's kingdom at low
   density. Soft edges replace grid edges.

8. **Multi-kingdom blending.** Where two kingdoms claim adjacent
   territories, render hybrid scenes. Cross-kingdom (`x`) tokens already
   declare blend intent.

9. **L-system distribution for clusters.** Painted patches become
   axioms for in-zone scatter. Trees cluster into groves; flowers form
   meandering lines along force fields.

10. **Walking-creature path generation.** Force fields + boids decide
    where creatures move. Path-finding through painted cells produces
    realistic herding/wandering.

The first four steps take a focused day. After step 4, `Biome_Spine` in
VR is materially better than the pink boxes we have today.

## What's already in the project

From the audits done 2026-05-04 (see blog posts
*The twenty-third substrate*, *The view from above*, *The loop closed*):

- **Seed parsing**: `BiomePaintTokens.parse()` ✓
- **Diffusion model**: `PresenceGrid.deposit()` ✓ (gated off)
- **Token grammar**: `f1-5 / t1-5 / u1-5 / c1-5 / m1-5 / x1-5 / -` ✓
- **Per-sequence dispatcher**: `BiomeAccrualManager` ✓
- **Production builders**: `tree_morphology.gd`, `flower_morphology.gd`,
  `fungus_morphology.gd`, `creature_morphology.gd` (all
  `algorithms/nature_system/morphology/`) ✓
- **DNA-driven critters**: `CritterEntity`, `CritterDNA`,
  `MorphologyRouter`, `CritterSpawner` ✓
- **Standalone flora**: `commons/flora/botanical_flower.gd` ✓
- **Foliage batching**: `commons/foliage/billboard_collector.gd` ✓
- **Algorithm libraries**: lsystem-gallery, rd-gallery, mesh-grammar,
  graph-grammar, soft-body, pattern, form/SDF, primitive-stack — all
  galleried with rated configs ✓
- **Fractal database**: 7 fold strategies, including `biome` and
  `temporal`, querying the whole tree ✓

## What's missing

- **Wiring**: nothing reads painted cells to spawn flora today.
  `_activate_living_ground` is gated false.
- **Dispatcher**: the `(kingdom, sequence) → substrate` table
  specified in earlier audits but not built.
- **Tier wrappers**: 5 thin wrappers calling `*_morphology.build()` from
  the existing biome layer files.
- **Voronoi/diffusion overlays**: not applied to the rendered output.
  PresenceGrid exists but doesn't drive rendering yet.

## Cross-references

- Audit: `algorithms/nature_system/systems/biome_paint_tokens.gd`
- Audit: `commons/managers/BiomeAccrualManager.gd`
- Audit: `algorithms/nature_system/morphology/tree_morphology.gd`
- Blog: *The twenty-third substrate* (2026-05-04)
- Blog: *The view from above* (2026-05-04)
- Encyclopedia: `/dna` — substrate gallery index
- Encyclopedia: `/biome-spine`, `/biome-zoo`, `/biome-poster` — current
  visualization surfaces
- Fractal database: `GET /api/fractal?strategy=biome` — every entity
  asked "how would you render as biome?"

## Principle

**The biome system makes the curriculum's algorithms physical.** Walking
the spine left to right, you see each algorithm become rendering as it
unlocks. Color → flower palette. Forces → swaying. L-systems → real
trees. Cellular automata → mycelial fungus. Soft bodies → creatures.
QFEP → cross-kingdom hybrid. The biome is the curriculum, embodied.

When you add a new algorithm to the curriculum, the biome inherits it
automatically — one new dispatch row, one new substrate wrapper. No
parallel rendering pipeline, no separate authorial pass. The biome
grows because the project grows.
