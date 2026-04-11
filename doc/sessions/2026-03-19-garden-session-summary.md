# Garden Session — 2026-03-19

## Overview

Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.

## Phase 1: Horizontal Audit (Sequence Compression)

Processed 38 of 42 sequences. Added titles to 313 maps. Merged 13 maps. Fixed artifact-map mismatches across 6 sequences.

### Sequences deeply restructured:
- **cellularautomata**: 12→8 maps (merged totalistic+multistate, neighborhoods+3D, stochastic+continuous, ant+wireworld)
- **fractals**: 14→10 maps (merged recursive trees, Koch+Sierpinski, duplicate Mandelbrot)
- **joints**: 7→6 maps (merged articulated+IK, reassigned all artifacts to correct maps)
- **particles**: 5→5 maps (fixed 3 title/content mismatches, removed misplaced artifacts)
- **isosurfaces**: 16→12 maps (merged torus+gyroid, metaballs; dropped 2 redundant)
- **forces**: 9→9 maps (rebalanced vector/force split, repurposed VectorWorkbench→ForcesComposition)
- **physicssimulation**: 21→21 maps (fixed 3 wrong artifacts, added simulation_instability)

### All remaining sequences: titled + progression checked

## Phase 2: Vertical Audit (20 Artifact Deep Dive)

Audited 20 key artifacts on 7 layers: essence, code, expression, interaction, feedback, edge cases, performance.

### Findings:
- 5 world-class (game_of_life_petri, mandelbrot_dive, force_field_visualizer, fluid_simulation, single_particle_vr)
- 10 correct but passive (no VR interaction)
- 5 broken or inert

### Rebuilt:
- **verlet_integration**: SoftBody3D cloth wrapper → Euler vs Verlet orbital comparison with energy readouts
- **SliderPress**: inert code → motor-driven piston with VR speed/force sliders
- **ClothSimulation**: 900 CSG nodes → MultiMesh + ImmediateMesh with VR wind/stiffness sliders

## Phase 3: The @identity System

Defined 8-field identity format embedded in .gd code comments:
- essence, desire, critical_parameter, triggers, emerges, needs, relationships, truth

Added @identity blocks to 363 artifacts across all spine + non-spine sequences.

### Key insight: The `needs` field marks VR controls as [has] or [missing], creating a distributed improvement roadmap in the code itself.

## Phase 4: Garden Listener

Built `tools/garden_listener.py` — diagnoses project health:

```
976 artifacts total
452 have voices (46%)
163 have full bodies
288 are reaching (389 phantom limbs)
524 are silent
```

Health states: DORMANT → SCATTERED → REACHING → GROWING → LIVING

## New Artifacts Built (8)

1. **IKArm** — FABRIK inverse kinematics, 4-segment arm tracking orbiting target
2. **lifetime_curves** — 3 emitters with color/size/opacity curves (quick flash, slow fade, pulse)
3. **sub_emitters** — firework mortar with burst particles on death
4. **particle_campfire** — synthesis: fire + embers + smoke
5. **box_counting_dimension** — Sierpinski with progressive grid overlay, log-log plot, D≈1.585
6. **momentum_collision** — elastic/inelastic on a rail with conservation readouts
7. **simulation_instability** — spring system with dt ramp: stable → drifting → EXPLODED
8. **verlet_integration** — rebuilt: side-by-side Euler vs Verlet with ghost line

## Tools Created (5)

1. `tools/verify_sequence.py` — post-audit verification (titles, content arrays, blurbs)
2. `tools/extract_identities.py` — parse @identity blocks from .gd files
3. `tools/query_identities.py` — search, filter, explore (truths, desires, needs-missing, relationships)
4. `tools/garden_listener.py` — project-wide health diagnosis with growth prescriptions
5. `tools/add_map_titles.py` — batch title generation from blurbs

## Blog Posts (8)

1. Sequence Compression (CA proof of concept)
2. Three More Sequences Named (fractals, joints, particles)
3. Filling the Gaps (artifact mismatches, 5 new builds)
4. The Sequence Audit Playbook (methodology for other AIs)
5. From Name to Flower (the vertical deep dive problem)
6. Artifacts That Speak (301 identities, the capstone)
7. The Garden Report (session closing, full numbers)
8. Sequence Audit Playbook update (added Step 6: blurb verification)

## Documentation

- `doc/INTENT_WRITING_GUIDE.md` — format spec for intent.md files, for ada writer
- 50 missing blurb.md files written from garden context
- All 184 existing intent.md files completed (57 gaps added, 13 rewritten)
- 1 new intent.md (Escher_Impossible)

## Encyclopedia Updates

- Garden API: `/api/garden` with modes: health, identity, search, reaching, truths, state, field
- Maps API: now returns title, blurb, and artifactIdentities
- `src/lib/ada-repo/identities.ts` — identity parser module

## Ada Writer Updates

- Identity module wired into maps API (`src/lib/ada-repo/identities.ts`)
- MapInfo interface updated with title field
- Running on port 3002, reads repo via ADA_RESEARCH_PATH

## GDScript Fixes

- Renamed inner class `Particle` to `LifetimeParticle`/`CampfireParticle`/`BurstParticle` (global name collision)
- Added explicit `float()` casts for Dictionary value access in simulation_instability
- Added explicit type annotations for Godot 4.6 strict mode

## What Remains

- 188 non-spine maps missing intent.md
- 524 voiceless artifacts (mostly scene-only, no .gd)
- 389 phantom limbs (agency question: not all need sliders)
- The deeper agency question: algorithms reaching other algorithms

## Key Commits

```
fa08f0ea fix: resolve GDScript parse errors in new artifacts
b7810da9 docs: complete all intent.md files
5080550b docs: write 50 missing blurb.md files
6d2f0442 docs: write Escher_Impossible intent.md + intent writing guide
3d6a6e8d feat: title + voice all non-spine sequences
2a741e6c feat: title all 10 remaining spine sequences
b2acc194 feat: garden_listener.py
063ab981 feat: add @identity blocks batch 5
430e4038 feat: add @identity blocks batch 4
671fe200 feat: add @identity blocks batch 3
0ecb36e3 feat: add @identity blocks batch 2
3d9b91b7 feat: add @identity blocks batch 1
6fc84ed9 feat: query_identities.py
b68589d5 feat: add @identity blocks to 13 artifacts
07706be5 feat: rebuild SliderPress and cloth_simulation
619d3dfc docs: update .md files for rebuilt verlet and instability
ac573ed4 feat: rebuild verlet_integration
3b2859c8 feat: audit physicssimulation
27363886 feat: restructure forces sequence
5f2cd488 feat: rename, merge, and audit 6 sequences
```
