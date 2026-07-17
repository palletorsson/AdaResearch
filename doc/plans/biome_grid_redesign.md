# Biome Grid Redesign — the living layer as part of the grid

> Palle, 2026-07-16 (verbatim): "The biome should be part of the grid (is that a
> good idea). I guess it makes it easier to manage. So there is the current
> artifact domain of the grid, but then the biome means different algorithms
> apply to the grid where the grid points activate different algorithms and
> produce the biome as a living layer on top of the grid cells. Different grid
> points have different layers, modifiers and roles."
>
> CORE GRID work — this document is the deep-consideration step required before
> any code. Verdict first, grammar second, migration third, tests last.

## Verdict: yes — and the codebase was already leaning here

Evidence on disk:
- `commons/biome_layers/biome_paint_dispatcher.gd` (2026-05-05, "foundation
  alive"): painted cells are SEEDS, dispatched to substrates by
  (kingdom, stage_order), curriculum-honesty guarded, primitive fallback.
  A `biome_paint` layer concept already exists.
- `commons/biome_layers/CONSOLIDATION_PLAN.md` (2026-06-02, four-agent pass):
  GridSystem `_handle_biome_ring()` runs THREE independent populators
  (BiomeAccrualManager + GroundLayerComponent + BiomeRingComponent) — visible
  doubling live today, loose geometry that bypasses ChunkManager/LOD.
  "Nothing downstream is safe until the world has a single source of truth."
- The walls layer precedent (`layers.walls` + GridWallSegmentsComponent) set
  the discipline: additive layer, gated by data presence, pathfinder-aware,
  negative-tested.

What the grid-native move buys (the P-8 'world' intent, made manageable):
- **Per-map authorship**: biome versioned in map_data.json like everything
  else, not smeared from a global soft_stages config. Paintable in the same
  editors as structure (template painter, map-simulator, the catalyst brush
  that already does runtime repaint_biome()).
- **Engine-neutral data**: the living layer survives an engine swap like every
  other layer. The seam legible: biome is DECLARED, not a side effect.
- **The vacuum protected**: soul maps (P-8) can declare `mute` cells — the
  biome cannot flood Point_One's arrival void again (the Grown_Point_One
  failure, and curriculum honesty, both fixed at the data level).
- **One populator** (fulfilling the consolidation plan): the dispatcher
  becomes THE spawn path, riding ChunkManager/MultiMesh.

What it must NOT do:
- Biome stays a LAYER on cells, never structure: no walkability changes, the
  pathfinder untouched (non-blocking flora only; blocking life is a hazard,
  a different layer).
- The outside is not sealed: today's ring (wilderness beyond the grid) becomes
  a ROLE (`halo`) on edge cells, not a deleted feature — the dark spot stays
  generative (sieve Q3).

## The grammar: layers.biome

Same grid shape as structure. Cell token:

    <kingdom>:<algo>:<role>[:<mod>=<val>...]     or "" (none)

- **kingdoms** (existing six): flora, fungus, fauna, mineral, water, meta
- **algo** (dispatch key into the substrate ladder — the 22 kingdom×tier
  scripts + crown jewels): scatter, lsystem, ca, dna, fog, tint, particles...
- **roles** (the new piece — what the grid POINT does):
  - `seed`  — the algorithm runs outward from this cell into its field
  - `field` — claimable by an adjacent seed's algorithm (no own algorithm)
  - `edge`  — transition band; algorithms fade/blend here
  - `halo`  — edge-of-grid cell that spills wilderness OUTWARD (the old ring)
  - `mute`  — biome forbidden; the declared vacuum (soul maps, heroes' voids)
- **modifiers**: `d=` density 0..1, `t=` tier 1..5 (the rendering ladder),
  `p=` palette, `clk=` clock (static | dwell | walk — the living layer may
  grow with the desire timeline: life that responds to attention)

Examples:
    flora:lsystem:seed:d=0.6:t=3     one tree cluster seeding its field
    fungus:ca:field                   claimable by a neighboring CA seed
    water:fog:edge:d=0.2              a fading fog band
    flora:scatter:halo:d=0.8          wilderness spilling off this rim cell
    ::mute                            nothing may live here

Curriculum honesty stays as the DISPATCH GUARD (unchanged): the dispatcher
checks (kingdom, stage_order) exactly as today; soft_stages.json remains the
per-sequence law; the map's biome layer is the per-cell request, honesty is
the filter. A map cannot paint itself trees in sequence 2.

## Architecture (the consolidation, completed by this redesign)

    map_data.json layers.biome
        → GridBiomeComponent (NEW, additive, gated on layer presence)
            → BiomePaintDispatcher (EXISTS — becomes the only populator)
                → substrate ladder (22 scripts, kingdom × tier)
                → ChunkManager / MultiMesh (LOD, merge, culling — mandatory)
    BiomeRingComponent      → RETIRED into role `halo`
    BiomeAccrualManager     → RETIRED into per-map default biome rows
                              (a map WITHOUT layers.biome gets the sequence
                              accrual default compiled in — byte-compatible
                              behavior, but now inspectable as data)
    GroundLayerComponent    → stays (ground tiles are structure-adjacent),
                              reads `p=` palette modifiers

## Migration steps (grid discipline, in order)

1. **Schema + parser**: BiomePaintTokens extended to the grammar above;
   negative test: a map with no `layers.biome` loads byte-identically.
2. **GridBiomeComponent**: reads the layer, feeds the dispatcher; headless
   compile-check + live map-load test on a sibling test map (Biome_GridTest).
3. **Dispatcher completes TODOs 3.b–3.f** (substrate lookup per kingdom) —
   was already "next session" in its own header, 10 weeks ago.
4. **Halo role** replaces BiomeRingComponent on one map; visual A/B capture;
   then retire the component behind a feature flag.
5. **Accrual compile-in**: tool writes each sequence's accrual default as
   explicit biome rows into maps that opt in (sibling-first, like everything).
6. **Authoring**: 4th paint mode in /template-maps (kingdom palette) + the
   pattern editor gains biome role codes; the catalyst brush keeps working
   (it already writes the runtime layer).
7. **Perf gate**: every spawn path through ChunkManager; the scrubber
   (BiomeScrubberDesktop3D) is the profiling harness; budget per map stated
   in the layer's _meta.

## The sieve (core grid obligation)

- **Thicken?** Yes: per-cell life gives relational handles (paint, mute,
  seed/field), makes the world thinkable per map, and finally makes the
  biome honest — declared where it lives.
- **Foreclosed?** Emergence untied to cells (a flock that ignores the grid);
  wilderness as OTHER than the map. Mitigation: halo keeps the outside; the
  clock modifier keeps time-based life; nothing forbids a substrate from
  wandering off its seed cell — the cell is the activation point, not a cage.
- **Dark spot?** The water between the islands (Palle's reference image): the
  un-celled space. Kept unclaimed on purpose — halo spills into it but no
  grammar governs it. If it ever needs law, that is a new ruling, not a
  default.

## Status

- 2026-07-16: design written, awaiting Palle's go for step 1–2 (schema +
  component + negative test). Tracked as thread `biome-grid`.
