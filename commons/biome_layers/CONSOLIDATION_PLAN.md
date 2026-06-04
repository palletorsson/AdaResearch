# Biome Consolidation Plan — one populator, one spawn path

> Authored 2026-06-02 from a four-agent research pass (prior-art, code-feasibility,
> VR-performance, curriculum-honesty). This is the PRECONDITION for the schema-v2
> affordances refactor and the curriculum-honesty reorder. Do this first; nothing
> downstream is safe until the world has a single source of truth and rides the
> existing LOD/merge machinery.

## The problem (verified in code, 2026-06-02)

`GridSystem._handle_biome_ring()` (`commons/grid/GridSystem.gd:636-766`) runs **three
independent populators** on every map, none aware of the others:

1. **`BiomeAccrualManager.apply()`** (`:677`) — the 19-layer accrual stack from
   `biome_contributions.json`. Runs at ANY density (even 0). Its flora/critter layers
   (`lsystem_trees.gd`, `dna_creatures.gd`) spawn LOOSE geometry — they do NOT route
   through ChunkManager, so they never get `merge_mesh_children` or visibility-range culling.
2. **`GroundLayerComponent.apply()`** (`:716`) — ground tiles via MultiMesh.
3. **`BiomeRingComponent.generate()`** (`:756`) — runs when density ≥ 0.05. Has its OWN
   foliage MultiMeshes PLUS `_spawn_dna_trees` (`:497`) PLUS `_spawn_dna_creatures` (`:570`)
   PLUS a `ChunkManager` of up to 40 more DNA organisms (`_spawn_dna_organisms :627`).

### Consequences

- **Visible doubling, live today.** A seq-11 density map renders ~8 trees from
  `lsystem_trees.gd` AND ~6–14 from `BiomeRingComponent._spawn_dna_trees` — two flavors of
  tree, two placement schemes, side by side. Creatures come from THREE sources
  (`dna_creatures` ≤20, ring creatures ≤18, ChunkManager ≤40).
- **Triple spawn code.** `lsystem_trees.gd:74` and `BiomeRingComponent.gd:559` call the
  identical `TreeMorphologyClass.build(dna, root, mapper, 1)`. The dispatcher
  (`biome_paint_dispatcher._spawn_tree/_creature`) is a third copy. Each has subtly
  different DNA tuning + placement, driven by different config (`biome_contributions.json`
  vs `soft_stages.json`).
- **Perf cliff.** The merge/LOD fix (`VisibilityRangeHelper.merge_mesh_children`,
  proven to take 30 organisms from 5,261 → 207 draw calls) only governs the ring's
  ChunkManager. The accrual layers bypass it entirely. At seq 19, with all layers
  accreted, the unmerged accrual trees + creatures + `ca_surface`'s 450–800 loose
  MeshInstances blow past the VR <1,000-draw-call ceiling before fill-rate is counted.

## Target architecture

```
GridSystem._handle_biome_ring()
   └─ BiomeAccrualManager.apply(ctx)          ← THE ONLY populator
        ├─ floating_primitives / animated / tint / wave / …   (abstract layers, unchanged)
        ├─ ground_substrate   (absorbs GroundLayerComponent + ring's surrounding ground+fog)
        ├─ flora_spawn   ─┐
        ├─ critter_spawn ─┤──── all delegate to ────►  SpawnService
        └─ biome_paint_dispatcher ┘                       └─ routes every organism through
                                                             ChunkManager (LOD) + merge_mesh_children
```

- **One populator** — GridSystem calls only `BiomeAccrualManager.apply()`.
- **One spawn path** — `SpawnService` is the single home for "build a DNA tree / creature /
  flower / mushroom and register it with ChunkManager for LOD + merge." `flora_spawn`,
  `critter_spawn`, and `biome_paint_dispatcher` all call it.
- **`BiomeRingComponent` retired** — its valuable parts (surrounding ground ring + fog fade,
  and the ChunkManager LOD discipline) are absorbed; its spawn duplication is deleted.

## Phases — each independently shippable + verified by capture

Every phase ends with: capture the same representative maps, compare draw-calls + visuals
against the Phase-0 baseline. The PERF logger (`Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`,
already wired in ChunkManager `_log_performance`) is the regression oracle.

### Phase 0 — Baseline safety net (no code change)
- Pick representative maps across the spine: one abstract (seq 1, e.g. `Point_One`), one
  mid (seq ~9 CA, the draw-call bomb), one flora (seq ~11 L-systems), one late
  (seq ~15+ if a walkable one exists).
- Capture each via `capture_multi_angle.gd --mode=map`. Record draw calls / object counts
  from the PERF line.
- This is the regression oracle for every later phase. **Commit the baseline captures.**

### Phase 1 — Extract `SpawnService` (pure refactor, zero behaviour change)
- New `commons/biome_layers/spawn_service.gd` (or `algorithms/nature_system/systems/`).
  Hoist the duplicated DNA build code: `build_tree(dna, parent, lod)`,
  `build_creature(dna, parent, lod)`, `build_flower(cfg)`, `build_mushroom(cfg)`.
- Each builder registers its result with the shared LOD path: `ChunkManager` enrolment +
  `VisibilityRangeHelper.merge_mesh_children` + `apply_lod_tier_ranges`.
- Point the THREE existing call sites at it: `lsystem_trees.gd:74`,
  `BiomeRingComponent.gd:559/_spawn_dna_creatures`, `biome_paint_dispatcher._spawn_tree/_creature`.
- **Risk: low.** Pure hoist. Intended output: identical visuals, draw calls equal-or-lower
  (because the accrual trees now get merged). Verify captures match Phase 0 within noise.

### Phase 2 — Route accrual flora/critters through ChunkManager
- The win lands here: `lsystem_trees` / `dna_creatures` previously spawned loose; now via
  `SpawnService` they get merge + visibility-range culling.
- **Risk: low–medium.** Verify: seq-11 map draw calls DROP markedly (the trees collapse from
  ~80 draw-calls-each to ~1 each). Visual: trees should look the same, just culled at distance.

### Phase 3 — Fix `ca_surface.gd` (the draw-call bomb)
- Convert `ca_surface.gd:49-63` from one `MeshInstance3D` + unique `StandardMaterial3D` per
  live cell to ONE `MultiMeshInstance3D` + one shared material, instance-transform per cell.
- **Risk: low.** Self-contained. Verify: seq-9 CA map draw calls collapse from hundreds to ~1–2.

### Phase 4 — Retire `BiomeRingComponent` (the structural change)
Split into two independently-shippable halves; 4a (low risk) lands first.

#### Phase 4a — Retire the ring's DNA *population* ✅ DONE + VERIFIED (2026-06-04)
- Removed the ring's DNA tree/creature spawn diversion in `_place_foliage` (now bare
  `types.erase("tree")`/`types.erase("creature")`) and commented out the `_spawn_dna_organisms`
  call in `generate()`. **The ring keeps `_build_ring_ground` (landscape + fog) — it still runs
  via the live `generate()` call.** Only the *duplicated DNA organisms* are gone.
- `_spawn_dna_trees` / `_spawn_dna_creatures` / `_spawn_dna_organisms` left on disk as dead code
  (unreferenced) for one commit cycle, per the plan's revert-safety spirit.
- **This removes the live doubling** — DNA trees/creatures now come *only* from the accrual stack.
- **KEY FINDING — no regression, and here's why:** the ring's foliage already passed through
  `GrammarOperationsManager.filter_foliage_types` (the grammar gate: `tree→growth@seq11`,
  `creature→swarm@seq13`). So the ring's *effective* schedule was already tree@11 / creature@13.
  The accrual schedule is `lsystem_trees@11`, `dna_creatures@12` — i.e. **at or earlier than** the
  gated ring. Accrual fully covers what the ring used to spawn; no sequence loses trees or creatures.
  The static soft_stages "tree@3 / creature@11" kingdom timing never actually fired earlier because
  the grammar gate suppressed it at runtime. (The static-file disagreement is the honesty-reorder
  epic — harmless at runtime.)
- **Verification (clean `ecosystem_progression.json` — see gotcha below):**
  - `LSystems_Growth` (order 11): accrual applied `lsystem_trees`; ring generated ground@0.70;
    no tree doubling; teaching artifacts visible; `map_pathfinder.py check` → OK.
  - `SwarmIntelligence_PhysarumColony` (order 13): accrual applied `dna_creatures`; ring log
    `Grammar gated foliage — dropped: ["creature"]` (ring spawns no creatures → no doubling);
    ground+fog preserved; `map_pathfinder.py check` → OK.
  - No GDScript parse/runtime errors in either capture log.
- **GOTCHA discovered:** `EcosystemManager` persists `user://ecosystem_progression.json` and
  `force_advance_to` is **monotonic** (`_current_stage_order = max(order over all completed seqs)`).
  A stale save with `biome_lab` (order 99) completed pins every map to stage 99 → lab-only mode
  → only the painted dispatcher applies. Delete the save (`%APPDATA%/Godot/app_userdata/Ada
  Research Zero One/ecosystem_progression.json`) before capture-verifying real-map staging.

#### Phase 4b — Fold the ring into the accrual stack ✅ DONE + VERIFIED (2026-06-04)
**Deviation from the original plan, deliberately:** the plan said "delete `BiomeRingComponent.gd`."
On inspection the ring owns TWO spatially-distinct contributions, not one — `_build_ring_ground`
(landscape + fog + **the walkable ground collider players stand on**) AND `_place_foliage` (the
ring-*zone* MultiMesh ground-cover annulus). The accrual organism layers operate on/near the grid;
neither covers the annulus. So rather than reimplement collision + foliage code (high risk for the
one biome piece that affects locomotion), the ring is now **wrapped** as a `ground_ring` accrual
layer that invokes the existing, tested `BiomeRingComponent.generate()` byte-for-byte. Same output,
different invocation site. This still achieves the plan's intent — **one populator** (everything
flows through `BiomeAccrualManager`); GridSystem no longer special-cases the ring; the ring inherits
per-map `biome_overrides` for free.
- `commons/biome_layers/ground_ring.gd` (new): `apply(ctx)` reads density/grid_dims/cube_size/
  terrain_mode/kingdoms from ctx, density-gates barren maps (< 0.05), instantiates
  `BiomeRingComponent` and calls `generate(...)`.
- `biome_contributions.json`: `ground_ring` entry at order 1 with `"always": true`.
- `BiomeAccrualManager`: lab-mode skip now respects `"always": true` (so `ground_ring` applies even
  in `biome_lab` mode, matching the old unconditional GridSystem call).
- `GridSystem._handle_biome_ring()`: threads density/terrain_mode/kingdoms into the accrual ctx;
  the ring instantiation + density gate + `generate()` call are **removed** (only comments remain).
- **Verification (clean ecosystem state):**
  - `LSystems_Growth` (order 11): `applied=["ground_ring", …]`; `[ground_ring] accrual layer → ring
    generated`; ground+fog landscape visually identical to pre-4b; pathfinder OK.
  - `Biome_Spine` (biome_lab, stage 99, lab-only): `applied=["ground_ring", "biome_paint_dispatcher"]`
    — the `always` flag let `ground_ring` through while all 19 spine layers stayed skipped; ground+fog
    preserved; dispatcher intact; pathfinder OK.
  - No `GridSystem: 🌿 Biome ring generated` line (old special-case gone); no parse/runtime errors.
- **Leftover (tiny follow-up):** the dead `_spawn_dna_trees/_creatures/_organisms` inside
  `BiomeRingComponent.gd` (retired in Phase 4a) are still on disk, now confirmed unreferenced. A
  cleanup pass can delete them and decide whether to fully absorb the component into `ground_ring.gd`
  vs keep the wrapper. Not blocking.

### Phase 5 — Single resolver owns the running total (bridge to schema-v2)
- With one populator, add a `budget_scale` float to the accrual `ctx`. Even a stub that
  always returns 1.0 establishes the hook. Each `*_spawn` layer multiplies its target count by it.
- This is the seam the schema-v2 `performance_budget` work plugs into. NOT the full budget
  system (that's the next epic) — just the single chokepoint that makes a budget possible.

## Config reconciliation (do alongside Phase 4)

Three files disagree on WHEN life appears. Resolve which drives what:
- `biome_contributions.json` — WHICH layers exist per sequence (drives the accrual stack). **Canonical for layer presence.**
- `soft_stages.json` — density + kingdoms + terrain_mode (drives the resolver's scaling). **Canonical for density.**
- `biome_config.json` — kingdom `unlock_order` + colors + intensity scaling. **Canonical for unlock gating + render params.**
- Today `biome_contributions.json` (flowers@13) contradicts `biome_config.json` (flower unlock 4) and `soft_stages.json` (flower kingdom @ color). The curriculum-honesty reorder (next epic) makes `biome_contributions.json` agree with the unlock_order table.
- ACTION in this plan: just document the role split above in each file's header. The value
  reconciliation is the honesty-reorder epic, not this one.

## What this plan deliberately does NOT do (next epics)
- Schema-v2 `affordances[]` — trivial (~15 lines) ONCE there's one populator. Separate commit.
- Curriculum-honesty reorder (flowers@3, mushrooms@6, two-faces constrained renders). Separate epic.
- Full `performance_budget` (fill-rate governor, active-agent governor, proximity weighting).
  Phase 5 only installs the hook.

## Verification checklist (every phase)
- [ ] Representative maps captured, draw calls compared to Phase-0 baseline.
- [ ] `map_pathfinder.py check <Map>` passes (teaching artifact still reachable).
- [ ] `biome_lab` maps (`Biome_Spine`, `Biome_Zoo`) still render.
- [ ] No GDScript parse/runtime errors in the export/capture log.
- [ ] `git` diff scoped to the phase (no accidental cross-phase churn).

## Single biggest risk
Phase 4. Retiring `BiomeRingComponent` removes a populator that produces a distinct visual
(the world-extends-into-mist landscape) AND the only ChunkManager currently in the pipeline.
Phases 1–3 must land the merge/LOD discipline into `SpawnService` FIRST, so that when the ring
is removed in Phase 4 the accrual layers already ride the performant path. Do not reorder.
