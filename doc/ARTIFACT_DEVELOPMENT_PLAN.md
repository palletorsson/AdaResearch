# Artifact Development Plan

> Bridging Theory → QFEP → VR Deliverables

**Created:** 2026-02-03  
**Status:** Active  
**Tracks:** Grant WP alignment, QFEP coverage, ContentValidator completeness

---

## Overview

This plan maps the original grant vision (VR_VR_PT_2023.md) through the QFEP framework to concrete artifact deliverables. Each artifact is an interactive VR object that teaches an algorithm while embodying QFEP principles.

**Goal:** Complete artifact coverage for all 18 spine sequences, enabling critical.md writing.

---

## Phase 1: Foundation Solidification (F_order)
*WP1: Basic Elements — Weeks 1-2*

### Status: ✅ Strong base, needs polish

**Sequences:** `primitives`, `transformations`

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `vector_addition_demo` | 🔨 Build | HIGH | Two arrows → resultant, grabbable |
| `dot_product_projector` | 🔨 Build | HIGH | Show projection visually |
| `cross_product_demo` | 🔨 Build | HIGH | Normal vector from two inputs |
| `transform_matrix_cube` | 🔨 Build | MED | 3x3 matrix → cube deformation |
| `basis_vectors_rig` | 🔨 Build | MED | i,j,k as grabbable axes |

**Existing to integrate:**
- `vector_translation_demo` ✅
- 250+ primitives ✅

**Deliverable:** Interactive vector math toolkit

---

## Phase 2: Oscillation Layer (F ↔ E)
*WP1: Basic Elements — Weeks 3-4*

### Status: ✅ Strong, minor gaps

**Sequences:** `wavefunctions`, `forces`

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `coupled_pendulums` | 🔨 Build | HIGH | Energy transfer visualization |
| `wave_interference_tank` | 🔨 Build | HIGH | Two sources, interference pattern |
| `resonance_bridge` | 🔨 Build | MED | Tacoma Narrows reference |
| `force_field_visualizer` | 🔨 Build | MED | Arrow field for gravity/charge |
| `orbital_mechanics_demo` | 🔨 Build | LOW | Planet + satellite |

**Existing (complete):**
- `oscilloscope` ✅
- `harmonic_motion_demo` ✅
- `spring_demo` ✅
- `additive_wave_demo` ✅
- `chladni_plate` ✅
- `dna_specimen` ✅
- `petri_dish_worms` ✅

**Deliverable:** Complete oscillation/forces artifact set

---

## Phase 3: Entropy Unleashed (E_entropy)
*WP2: Advanced Elements — Weeks 5-8*

### Status: ⚠️ Registered but needs interactive wrappers

**Sequences:** `randomness`, `noise`, `cellularautomata`

### 3A: Randomness (Week 5)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `distribution_sampler` | 🔨 Build | HIGH | Gaussian, uniform, Poisson - grabbable |
| `random_walk_terrarium` | 🔨 Build | HIGH | 2D/3D walks in glass case |
| `entropy_source` | 🔨 Build | HIGH | Visual true randomness vs pseudo |
| `monte_carlo_estimator` | 🔨 Build | MED | Pi estimation with darts |
| `brownian_motion_tank` | 🔨 Build | MED | Particles in fluid |

### 3B: Noise (Week 6)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `perlin_terrain_sculptor` | 🔨 Build | HIGH | Sliders for octaves, persistence |
| `flow_field_painter` | 🔨 Build | HIGH | Draw particles following noise |
| `noise_comparison_panel` | 🔨 Build | MED | Value vs Perlin vs Simplex |
| `curl_noise_vortex` | 🔨 Build | MED | Divergence-free flow |
| `fractal_brownian_landscape` | 🔨 Build | LOW | fBm terrain generation |

### 3C: Cellular Automata (Weeks 7-8)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `ca_rule_explorer` | ✅ Done | HIGH | **2026-02-03** — 64×50 board, rules 0-255, keyboard control |
| `game_of_life_petri` | 🔨 Build | HIGH | Classic GoL, drawable |
| `ca_3d_cube` | 🔨 Build | MED | 3D cellular automata |
| `langtons_ant_habitat` | 🔨 Build | MED | Emergent highway |
| `wireworld_circuit` | 🔨 Build | LOW | Logic with CA |

**Deliverable:** Full entropy toolkit — randomness→noise→CA progression

---

## Phase 4: Edge of Chaos (lambda_edge)
*WP2: Advanced Elements — Weeks 9-12*

### Status: ⚠️ Core thesis territory, needs focus

**Sequences:** `fractals`, `lsystems`, `proceduralgeneration`

### 4A: Fractals (Weeks 9-10)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `mandelbrot_dive` | ✅ Done | HIGH | **2026-02-03** — GPU shader, 5 palettes, auto-dive |
| `julia_set_explorer` | 🔨 Build | HIGH | c-parameter slider |
| `sierpinski_builder` | 🔨 Build | HIGH | Step-by-step construction |
| `koch_snowflake_grower` | 🔨 Build | MED | Iteration control |
| `dragon_curve_unfolder` | 🔨 Build | MED | Paper folding visualization |
| `fractal_dimension_measurer` | 🔨 Build | LOW | Box-counting demo |

### 4B: L-Systems (Week 11)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `lsystem_editor` | 🔨 Build | HIGH | Live axiom/rules editing |
| `tree_grower` | 🔨 Build | HIGH | Botanical L-system |
| `branching_coral` | 🔨 Build | MED | Underwater aesthetic |
| `city_generator` | 🔨 Build | MED | Urban L-system |
| `grammar_visualizer` | 🔨 Build | LOW | Show rewrite steps |

### 4C: Procedural Generation (Week 12)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `wfc_tile_generator` | 🔨 Build | HIGH | Wave Function Collapse live |
| `markov_chain_writer` | 🔨 Build | MED | Text generation visible |
| `dungeon_generator` | 🔨 Build | MED | Room placement algorithm |
| `texture_synthesizer` | 🔨 Build | LOW | Exemplar-based |

**Deliverable:** Edge-of-chaos toolkit — self-similarity, grammars, emergence

---

## Phase 5: Integration & Emergence
*WP3: Pattern and World Building — Weeks 13-18*

### Status: 🔴 Major gap — grant's "advanced" territory

**Sequences:** `morphogenesis`, `swarmintelligence`, `softbodies`, `machinelearning`

### 5A: Morphogenesis (Weeks 13-14)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `turing_pattern_generator` | 🔨 Build | HIGH | Reaction-diffusion, spots/stripes |
| `leopard_spots_demo` | 🔨 Build | HIGH | Turing's actual problem |
| `gray_scott_reactor` | 🔨 Build | MED | Parameter exploration |
| `diffusion_limited_aggregation` | 🔨 Build | MED | Crystal growth |
| `belousov_zhabotinsky` | 🔨 Build | LOW | Chemical oscillation |

### 5B: Swarm Intelligence (Weeks 15-16)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `boids_aquarium` | ✅ Done | HIGH | **2026-02-03** — 1m glass cube, 30 boids |
| `ant_colony_farm` | 🔨 Build | HIGH | Pheromone trails visible |
| `swarm_conductor` | 🔨 Build | HIGH | Player influences swarm |
| `particle_swarm_optimizer` | 🔨 Build | MED | PSO finding minima |
| `stigmergy_sandbox` | 🔨 Build | MED | Indirect coordination |

### 5C: Soft Bodies (Week 17)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `jelly_cube` | ✅ Done | HIGH | **2026-02-03** — 5 variants: jelly, bouncy, water, slime, queer |
| `cloth_simulator` | 🔨 Build | HIGH | Fabric physics |
| `fluid_tank` | 🔨 Build | HIGH | SPH or grid fluid |
| `slime_mold` | 🔨 Build | MED | Physarum simulation |
| `queer_morphology_specimen` | 🔨 Build | HIGH | **Grant thesis artifact** |

### 5D: Machine Learning (Week 18)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `neural_network_visualizer` | 🔨 Build | HIGH | Weights as connections |
| `perceptron_trainer` | 🔨 Build | HIGH | Single neuron learning |
| `backprop_flow` | 🔨 Build | MED | Gradient visualization |
| `evolution_terrarium` | 🔨 Build | MED | Genetic algorithm creatures |
| `deep_dream_portal` | 🔨 Build | LOW | Style transfer reference |

**Deliverable:** Emergence toolkit — morphogenesis, swarms, soft bodies, learning

---

## Phase 6: Synthesis & Critique
*WP4: Advanced Techniques — Weeks 19-24*

### Status: 🔴 Theory-heavy, needs embodiment

**Sequences:** `foundationscrisis`, `qfeplaboratory`, `speculativecomputation`, `criticalalgorithms`

### 6A: Foundations Crisis (Week 19) ✅ MOSTLY COMPLETE

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `godel_statement_plaque` | ✅ Done | — | Self-reference cascade |
| `russell_set_box` | ✅ Done | — | Infinite regress |
| `magritte_pipe` | ✅ Done | — | Representation gap |
| `escher_staircase` | ✅ Done | — | Local vs global consistency |
| `florensky_sphere` | ✅ Done | — | Non-Euclidean theology |
| `bifurcation_diagram` | ✅ Done | — | Route to chaos |
| `halting_problem_machine` | 🔨 Build | MED | Turing's undecidability |
| `cantor_diagonal` | 🔨 Build | LOW | Uncountability proof |

### 6B: QFEP Laboratory (Weeks 20-21) ✅ STRONG

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `lambda_slider` | ✅ Done | — | Entropy drive control |
| `phi_slider` | ✅ Done | — | Rate sensitivity (queer term) |
| `qfep_reactor` | ✅ Done | — | Central visualization |
| `phase_cube` | ✅ Done | — | Solid→complex→gas |
| `entropy_meter` | ✅ Done | — | E(S) gauge |
| `edge_detector` | ✅ Done | — | λ≈0.4 finder |
| `reactive_particle_field` | ✅ Done | — | Formula made physical |
| `bifurcation_walkway` | ✅ Done | HIGH | **2026-02-03** — 10m walkway, r=2.5→4.0, λ made physical |
| `qfep_sandbox_console` | 🔨 Build | HIGH | Full control panel |
| `edge_of_chaos_orb` | 🔨 Build | MED | State indicator |

### 6C: Speculative Computation (Weeks 22-23)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `quantum_superposition_box` | 🔨 Build | HIGH | Schrödinger's state |
| `hypercomputation_horizon` | 🔨 Build | MED | Beyond Turing |
| `non_euclidean_room` | 🔨 Build | MED | Hyperbolic/spherical space |
| `time_crystal` | 🔨 Build | LOW | Temporal patterns |
| `posthuman_interface` | 🔨 Build | LOW | Cyborg speculation |

### 6D: Critical Algorithms (Week 24)

| Artifact | Status | Priority | Notes |
|----------|--------|----------|-------|
| `bias_visualizer` | 🔨 Build | **CRITICAL** | Joy Buolamwini reference |
| `filter_bubble_terrarium` | 🔨 Build | HIGH | Recommendation isolation |
| `surveillance_panopticon` | 🔨 Build | HIGH | Farocki reference |
| `data_extractivism_map` | 🔨 Build | MED | Kate Crawford reference |
| `algorithmic_redlining` | 🔨 Build | MED | Safiya Noble reference |
| `poor_image_degrader` | 🔨 Build | MED | Steyerl reference |

**Deliverable:** Complete synthesis layer — theory embodied, critique enabled

---

## Summary: Artifact Count by Phase

| Phase | QFEP | Existing | To Build | Total |
|-------|------|----------|----------|-------|
| 1. Foundation | F_order | 250+ | 5 | ~255 |
| 2. Oscillation | oscillation | 11 | 5 | 16 |
| 3. Entropy | E_entropy | ~20 | 15 | ~35 |
| 4. Edge | lambda_edge | ~15 | 15 | ~30 |
| 5. Integration | integration | ~10 | 20 | ~30 |
| 6. Synthesis | synthesis | 27 | 15 | ~42 |
| **TOTAL** | | ~333 | **75** | ~408 |

---

## Development Workflow

### For each artifact:

1. **Build scene** → `res://commons/artifacts/{name}/{name}.tscn`
2. **Register** → Add to appropriate `registry/*.json`
3. **Test in map** → Place in sequence map via `map_data.json`
4. **Document** → Update artifact description, params, interactions
5. **Enable critique** → Now `critical.md` can be written

### File structure per artifact:
```
commons/artifacts/{artifact_name}/
├── {artifact_name}.tscn       # Main scene
├── {artifact_name}.gd         # Script
├── {artifact_name}.tres       # Resources (optional)
└── README.md                  # Dev notes (optional)
```

---

## Priority Queue (Next 10 Artifacts)

Building order optimized for grant alignment + QFEP coverage:

| # | Artifact | Sequence | Why |
|---|----------|----------|-----|
| 1 | `bias_visualizer` | criticalalgorithms | **Grant thesis** - coded gaze |
| 2 | ✅ `boids_aquarium` | swarmintelligence | WP3 emergence showcase — **DONE 2026-02-03** |
| 3 | `turing_pattern_generator` | morphogenesis | Turing's leopard spots |
| 4 | ✅ `ca_rule_explorer` | cellularautomata | Wolfram rules interactive — **DONE 2026-02-03** |
| 5 | `lsystem_editor` | lsystems | Grammar as generative tool |
| 6 | ✅ `jelly_cube` | softbodies | Queer morphology precursor — **DONE 2026-02-03** |
| 7 | `perlin_terrain_sculptor` | noise | Core noise interaction |
| 8 | ✅ `mandelbrot_dive` | fractals | Infinite detail — **DONE 2026-02-03** |
| 9 | ✅ `bifurcation_walkway` | qfeplaboratory | Walkable phase transition — **DONE 2026-02-03** |
| 10 | `queer_morphology_specimen` | softbodies | **Grant thesis** - fluid form |

---

## Milestones

- [ ] **M1 (Week 4):** Phases 1-2 complete — F_order + oscillation solid
- [ ] **M2 (Week 8):** Phase 3 complete — E_entropy toolkit
- [ ] **M3 (Week 12):** Phase 4 complete — lambda_edge (fractals, L-systems)
- [ ] **M4 (Week 18):** Phase 5 complete — Integration (swarms, soft bodies)
- [ ] **M5 (Week 24):** Phase 6 complete — Synthesis (critique enabled)
- [ ] **M6 (Week 26):** critical.md writing begins for all spine sequences

---

## Tracking

Update this file as artifacts are completed:
- Change `🔨 Build` → `✅ Done`
- Add completion date
- Note any scope changes

**Last updated:** 2026-02-03 (5 artifacts done: boids, jelly, CA, mandelbrot, bifurcation)

---

*This plan aligns with VR_VR_PT_2023.md grant vision, QFEP framework, and ContentValidator requirements.*
