# Evolving Tools — Reusable Artifacts That Grow Through the Curriculum

> Build once. Extend through progression. The same object means more as you learn more.

## The Pattern

Ada Research has three independent systems that share one architecture: a **fixed physical object** whose behavior evolves through the curriculum without changing the object's code.

| System | Fixed part | Evolving part | Mechanism |
|--------|-----------|--------------|-----------|
| **Substrates** | Renderer (MultiMesh, ImmediateMesh, texture) | Algorithm cartridge | Registry swap |
| **Catalyst** | Crystal pickup + projectile system | Active mode | `sequence_completed` signal |
| **draw_dot** | ImmediateMesh trail recorder | How coordinates map to meaning | Class inheritance |

These are the **instruments** of Ada Research — the things the player picks up, stands next to, or holds while learning. They don't change code between sequences. They accumulate meaning through capability unlocks, new cartridges, and ecosystem shifts.

## Why This Matters

A Grid2D petri dish in `cellularautomata` (sequence 9) runs Game of Life. The same petri dish in `softbodies` (sequence 13) sits in a forest with deformable terrain, surrounded by creatures that have shifted from foes to curious. The substrate is identical. The world around it changed. The player's hands can do more. Same object, radically different experience.

This is the pedagogical core: **you revisit the same tools with deeper understanding**.

---

## System 1: Substrates

### Architecture
```
substrate_<type>.tscn       — Scene: physical shell (base plate, rim, touch area)
<type>_renderer.gd          — MultiMesh/ImmediateMesh/Image rendering
<type>_cartridge.gd         — Base class: initialize(), step(), get_color()
cartridges/cartridge_*.gd   — Algorithm implementations
<type>.json                 — Registry: lookup_name → scene + config
```

### Dimension Ladder
```
Bar → Profile → BarArray → Grid2D → Grid3D
 0D      1D        1D        2D        3D
                                  + WalkSurface (continuous 2D)
                                  + MeshArtifact (deformable 3D)
```

### Built Substrates (6 of 7)

| Substrate | Cartridges | Primary sequences | Status |
|-----------|-----------|-------------------|--------|
| Living Paper | 35 | randomness, CA, fractals, L-systems, noise, search | Built |
| Grid2D | 8 | cellularautomata, patterngeneration, searchpathfinding | Built |
| BarArray | 9 | array_tutorial, sorting, statistics | Built |
| Grid3D | 8 | graphtheory, randomness, entropy | Built |
| Profile | 16 | wavefunctions, noise, statistics, physics | Built |
| WalkSurface | 6 | wavefunctions, noise, fractals | Built |
| **MeshArtifact** | — | lsystems, softbodies, fractals | **Not built** |

### MeshArtifact = mesh_grammar

The 7th substrate slot maps directly to the existing `commons/mesh_grammar/` system:

- 18 operations (extrude, inset, split, tube_branch, lsystem_branch, cellular_surface, ...)
- Composable selectors (by_index, by_normal, by_random, by_material)
- Generation history tracking
- Facade grammar specialization already exists

**To build:** Wrap mesh_grammar in the cartridge pattern. Each grammar rule-set becomes a `MeshArtifactCartridge`. Operations map to sequences:

| Operation | Unlocks at sequence | Why |
|-----------|-------------------|-----|
| extrude, inset, scale | primitives | Basic shape manipulation |
| rotate, split | transformation | Spatial operations |
| noise_displace | noise | Stochastic deformation |
| cellular_surface | cellularautomata | Rule-based surface |
| lsystem_branch, profile_extrude | lsystems | Grammar-driven growth |
| tube_branch, petal_splay | proceduralgeneration | Full generative vocabulary |
| bulge, scallop | softbodies | Deformable surfaces |

### Substrate Placement Across Sequences

Each substrate appears in **multiple sequences**, but with different cartridges:

```
primitives:           grid2d_blank        living_paper_random_walk
transformation:       grid2d_transforms
color:                grid2d_color
wavefunctions:        profile_sine        walk_surface_sine
randomness:           living_paper_levy   living_paper_brownian
noise:                grid2d_perlin       walk_surface_noise
cellularautomata:     grid2d_life         living_paper_rule30
fractals:             living_paper_mandel grid3d_entropy
lsystems:             living_paper_fern   [mesh_artifact_tree]
proceduralgeneration: [mesh_artifact_facade]
softbodies:           [mesh_artifact_cloth]
swarmintelligence:    grid3d_force_directed
graphtheory:          grid3d_bfs          grid3d_kruskal
```

---

## System 2: draw_dot

### Current State

Two variants exist:

| Variant | Script | What it does |
|---------|--------|-------------|
| `draw_dot` | `commons/primitives/point/draw_dot.gd` | Records hand position as ImmediateMesh line strip in 3D space |
| `draw_dot_time_domain` | `commons/primitives/point/draw_dot_time_domain.gd` | Extends base, adds Z-axis as time. Existing points advance along +Z. XY movement becomes oscilloscope trace |

### Evolution Pattern

draw_dot_time_domain doesn't rewrite the tracer — it **inherits and reconfigures** the coordinate mapping. Same recording mechanism, different interpretation. This is the pattern for all future variants.

### Proposed Ladder

| Sequence | Variant | What changes | Extends |
|----------|---------|-------------|---------|
| primitives | `draw_dot` | Spatial trace — record hand position as line strip | base |
| wavefunctions | `draw_dot_time_domain` | Time axis — XY + Z=time, oscilloscope trace | draw_dot |
| noise | `draw_dot_noise` | Perlin displacement on trail points — hand draws through turbulence | draw_dot |
| cellularautomata | `draw_dot_cellular` | Trail points are cells, neighbors influence color/brightness | draw_dot |
| fractals | `draw_dot_fractal` | Trail branches at configurable depth — hand draws a tree | draw_dot |
| lsystems | `draw_dot_lsystem` | Hand motion interpreted as turtle commands (F=forward, +=turn) | draw_dot |
| softbodies | `draw_dot_spring` | Trail points connected by spring forces — elastic drawing | draw_dot |
| swarmintelligence | `draw_dot_swarm` | Trail spawns followers that flock around the drawn path | draw_dot |

Each variant is a single GDScript file that `extends` draw_dot and overrides the coordinate/point behavior. No changes to the base class.

### Unlock Mechanism

draw_dot already has a tag-trigger system:
```gdscript
@export var trigger_tag: String = ""
@export var trigger_action: String = ""
@export var movement_threshold: float = 0.5
```

When the player moves enough distance, it calls `TagSystem.trigger_tag_action()`. This is the progression gate — each variant requires different movement thresholds and triggers different tags. The variant availability should be gated by `soft_stages.json` capability unlocks.

---

## System 3: Catalyst

### Current State

10 modes, unlocked per sequence:

| Mode | Sequence | Order | Projectile behavior |
|------|----------|-------|-------------------|
| primitives | primitives | 1 | Geometry/shapes |
| transformation | transformation | 2 | Rotations |
| chromatic | color | 3 | Color projectiles |
| forces | forces | 4 | Physics |
| waveform | wavefunctions | 6 | Sinusoidal |
| chaos | randomness | 7 | Entropy |
| cellular | cellularautomata | 9 | CA patterns |
| fractal | fractals | 10 | Self-similar |
| branching | lsystems | 11 | Branching growth |
| swarm | swarmintelligence | 14 | Collective |

### Connection to draw_dot

Both are **held tools that grow**:
- Catalyst: picked up crystal, fires projectiles, modes unlock
- draw_dot: picked up tracer, records motion, variants unlock

The catalyst transforms *other things* (artifacts, hazards). draw_dot transforms *the trace itself* (the player's own movement becomes data). They complement — catalyst acts outward, draw_dot records inward.

### Connection to substrates

Catalyst projectiles **interact with substrates**:
- Chromatic mode hitting a grid2d → colors cells
- Chaos mode hitting a bar_array → randomizes bars
- Cellular mode hitting a grid2d → seeds life patterns

These interactions are the capability layer — `hand_verbs` from `soft_stages.json` determine what the catalyst can do to which substrate.

---

## The Unified Instrument Track

All three systems should be tracked as a single progression in the roadmap: the **instruments** track.

### Per-sequence instrument state

| Sequence | Substrates available | draw_dot variant | Catalyst mode | Key verb |
|----------|---------------------|-----------------|---------------|----------|
| primitives | grid2d, living_paper | spatial trace | primitives | grab, snap |
| transformation | + (same) | — | transformation | rotate, translate |
| color | + (same) | — | chromatic | paint, shoot_color |
| forces | + bar_array | — | forces | push, pull |
| array_tutorial | + (same) | — | — | snap_place, reorder |
| wavefunctions | + profile, walk_surface | time_domain | waveform | oscillate, tune |
| randomness | + (same) | — | chaos | randomize |
| noise | + (same) | noise_trace | — | sculpt_terrain |
| cellularautomata | + (same) | cellular_trace | cellular | seed_life, edit_rules |
| fractals | + (same) | fractal_trace | fractal | zoom, iterate |
| lsystems | + (same) | lsystem_trace | branching | write_rule, branch_grow |
| proceduralgeneration | + mesh_artifact | — | — | generate_world |
| softbodies | + (same) | spring_trace | — | deform, tune_lambda |
| swarmintelligence | + (same) | swarm_trace | swarm | swarm_command, embody |
| machinelearning | + (same) | — | — | train, evolve |
| foundationscrisis | + (same) | — | — | hold_paradox |
| qfeplaboratory | + (same) | — | — | full_parameter_control |
| graphtheory | + (same) | — | — | connect, traverse |

### What doesn't change

- Substrate renderers stay the same
- draw_dot base class stays the same
- Catalyst crystal pickup stays the same
- Scene trees stay the same

### What changes per sequence

- Which cartridges are available (registry + allow_flags)
- Which draw_dot variant is active (gated by capability)
- Which catalyst mode is unlocked (signal-driven)
- Which hand_verbs work (CatalystCapabilityManager)
- What the world looks like around the tool (EcosystemManager)

---

## Implementation Priorities

### 1. MeshArtifact substrate (HIGH)
- Wrap mesh_grammar in cartridge pattern
- Create `MeshArtifactCartridge` base class
- Register in `mesh_artifact.json`
- First cartridge: facade grammar (already exists)

### 2. draw_dot evolution ladder (MEDIUM)
- Design 3-4 variants (time_domain exists, add noise, fractal, spring)
- Each is a single .gd file extending draw_dot
- Gate availability through soft_stages capability

### 3. Instruments track in roadmap (LOW)
- Add `instruments` track definition to `roadmap_tracks.json`
- Add per-sequence instrument beats
- Surface in encyclopedia roadmap view

### 4. Catalyst-substrate interactions (MEDIUM)
- Define which catalyst modes affect which substrates
- Wire through hand_verbs → substrate.on_catalyst_hit()

---

## Design Principles

1. **Extend, don't rewrite** — new variants inherit from base. draw_dot_time_domain proves this works.
2. **Cumulative, not replacive** — you never lose tools. Unlocks only add.
3. **Same object, different context** — the substrate is identical. The world around it changed.
4. **Code doesn't change, meaning does** — Grid2D in cellularautomata and Grid2D in softbodies run the same renderer. The ecosystem, hazards, and player capability make them feel completely different.
5. **Honest about gaps** — not every sequence needs every tool. The table above has blanks. That's fine.
