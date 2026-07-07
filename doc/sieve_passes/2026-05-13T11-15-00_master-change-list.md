# Master change list — 2026-05-13 sieve cycle

_Recorded 2026-05-13T11:15:00_

The session's structural changes, in one place, for sign-off and follow-up build work.

## 1. JSON edits applied (done this session)

### 1a. curriculum_spine.json

**Sequence-level edits (10):**
- `cellularautomata`: phase E_entropy → λ_edge (order 9 unchanged)
- `isosurfaces`: phase λ_edge → F_order, order 12.5 → 4.6
- `boolean_surfaces`: phase λ_edge → F_order, order 12.7 → 4.7
- `swarmintelligence`: phase integration → λ_edge, order 14 → 13
- `softbodies`: order 13 → 14 (phase integration unchanged)
- `graphtheory`: phase integration → relation, order 19 → 16
- `foundationscrisis`: order 16 → 17 (phase synthesis unchanged)
- `qfeplaboratory`: order 17 → 18 (phase synthesis unchanged)
- `postfoundationscrisis`: order 18 → 19 (phase synthesis unchanged)
- New phase `relation` added to phases block

**Phase truth statements added (7):** F_order, oscillation, E_entropy, λ_edge, integration, relation, synthesis.

### 1b. soft_stages.json

**Order updates (9):** cellularautomata, fractals, lsystems, procgen, swarm, soft, ML, graph, crisis, lab, post — aligned with new spine order. Also fixed v1.3 drift: array_tutorial 5→3, color 3→4, forces 4→5.

**catalyst_affordances filled (15):** forces, wavefunctions, randomness, noise, cellularautomata, fractals, lsystems, proceduralgeneration, swarmintelligence, softbodies, machinelearning, graphtheory, foundationscrisis, qfeplaboratory, postfoundationscrisis.

**New stages added (2):** isosurfaces (order 4.6), boolean_surfaces (order 4.7).

### 1c. Sequence file edits

- `cellularautomata.json` → `qfep_term: λ`, `layer: lambda_edge`
- `swarmintelligence.json` → `layer: lambda_edge`
- `isosurfaces.json` → `layer: F_order`
- `boolean_surfaces.json` → `qfep_term: F`, `layer: F_order`, updated qfep_connection
- `graphtheory.json` → `layer: relation`
- `qfeplaboratory.json` → `unlocks` adds `postfoundationscrisis`
- `postfoundationscrisis.json` → `unlocks: []` (terminal)
- `softbodies.json` → `unlocks: ["machinelearning", "morphogenesis"]` (was `swarmintelligence`)
- `array_tutorial.json` → added `layer: F_order`
- `randomness.json` → added `layer: E_entropy`
- Layer field normalized in: primitives, transformation, color, change, forces, wavefunctions, noise, fractals, foundationscrisis, qfeplaboratory, postfoundationscrisis

## 2. New artifacts to build (the queue)

### 2a. F_order tail — change sequence (scaffolded in JSON, need .gd/.tscn)

From prior session, registered in `commons/maps/sequences/change.json`:

| token | role | catalyst affordance |
|---|---|---|
| `slope_tangent_demo` | derivative as instantaneous rate | — |
| `derivative_pair` | function and its derivative side-by-side | — |
| `velocity_arrow` | velocity as derivative of position | — |
| `partial_derivative_terrain` | ∂f/∂x and ∂f/∂y on a surface | — |
| `riemann_pump` | Riemann sum as left/right/midpoint accumulation | — |
| `integral_area` | area under curve as integration | — |
| `vector_field_grid` | a 2D/3D vector field of arrows | — |
| `particle_flow_swarm` | particles following the field | — |
| `ftc_bridge` | fundamental theorem of calculus bridge | — |
| `catalyst_sustain_demo` | sustain affordance demo | `sustain` |

10 artifacts total. Already in JSON; need .gd and .tscn files.

### 2b. F_order geometry tail — boolean_surfaces fill (NEW)

The sequence is in the spine but has 0 artifacts. Minimum viable build:

| token | role |
|---|---|
| `csg_union_demo` | A ∪ B — two solids merging |
| `csg_intersection_demo` | A ∩ B — only overlap survives |
| `csg_difference_demo` | A − B — subtraction |
| `csg_compose_workbench` | place primitives, compose with operators (catalyst affordance: `csg-compose`) |
| `csg_architecture_cavity` | the cavity-in-wall as A − B (real-world example) |

5 artifacts. Need sequence map structure + .gd/.tscn files.

### 2c. λ_edge — new affordance demos (NEW)

The macro sieve names five affordances at λ_edge. Most have existing sequence artifacts that *are* the affordance (CA artifacts demonstrate evolve, fractal artifacts demonstrate split). One needs a dedicated demo:

| token | role | sequence |
|---|---|---|
| `seed_orb` | the player throws a seed; world generates around landing point | proceduralgeneration |

(`evolve_demo`, `split_demo`, `grow_demo`, `flock_demo` are arguably the existing sequence artifacts and don't need new builds. Optionally a `chamber`-style affordance demo per λ_edge sequence.)

### 2d. integration — new affordance demos (NEW)

| token | role | sequence |
|---|---|---|
| `flex_cloth_pad` or `drape_target` | player throws cloth; it drapes to a target | softbodies |
| `learn_input_pair_stand` | place input-output pairs; bracelet learns the mapping | machinelearning |

2 artifacts.

### 2e. relation — graphtheory recognition (REFRAME, no new)

graphtheory has existing artifacts (force_directed_layout, KonigsbergBridge, etc.). The reorder repositions the sequence but doesn't require new artifacts. **Optional:** a `connect` affordance demo at GT_Foundations that lets the player place edges between nodes.

### 2f. synthesis fill — postfoundationscrisis (NEW, the largest debt)

5 maps in postfoundationscrisis are SCAFFOLD-only. From synthesis sieve 6d:

| map | new artifacts |
|---|---|
| CriticalAlgorithms_Applied_Ethics | `ethical_design_clipboard`, `excluded_class_visualizer`, `room_shape_demonstrator` |
| SpeculativeComputation_Paraconsistent_Engineering | `merge_conflict_visualizer`, `cap_theorem_walk`, `florensky_in_production` |
| SpeculativeComputation_Situated_Computation | `situated_sensor`, `locatable_knowledge_station` |
| SpeculativeComputation_Collective_Knowledge | `wiki_fragment_station`, `peer_edit_ledger`, `citation_graph_node` |
| PostCrisis_Synthesis | `edge_as_ground_capstone` (7-station ring) |

12 new artifacts.

### 2g. synthesis — retroactive recognition (NEW, 1 artifact)

| token | role | sequence |
|---|---|---|
| `qfep_term_compass` | each formula term lights up and shows its origin sequence | qfeplaboratory (QFEP_Sandbox or QFEP_Synthesis) |

1 artifact.

## 3. Build queue totals

| group | count | priority |
|---|---|---|
| change sequence fill | 10 | high (sequence is already in spine, needs scaffolds) |
| boolean_surfaces fill | 5 | medium-high (sequence has 0/0 artifacts) |
| λ_edge `seed_orb` | 1 | medium |
| integration affordances | 2 | medium |
| postfoundationscrisis fill | 12 | high (thesis-landing depends on this) |
| qfep_term_compass | 1 | medium-high (closes the loop) |
| **Total new artifacts** | **31** | |

## 4. Schema and bug fixes (separate work)

### 4a. machinelearning.json schema duplication

Nested `artifact_groups` arrays are empty; root-level arrays are populated. Two truth sources. Action:
- Delete the nested empty `artifact_groups` (lines 114-171 of machinelearning.json)
- Keep root-level `artifact_groups` (lines 174-260) as the single truth source

Out of scope for this session; flagged for one-off cleanup.

### 4b. Recommendations not applied this session

From earlier phase sieves, items deferred:

- **oscillation sieve 1** — split wavefunctions if VR walk confirms 82-artifact bloat. Deferred until headset walk.
- **oscillation sieve 2/3** — foreground resonance, surface chaos. Authoring choice for next-pass.
- **synthesis sieve 6a** — phase rename `synthesis → thesis_arc`. Decided against; lighter touch is the new phase truth (done).
- **macro sieve dark spot** — pedagogical hard step at 4.6/4.7 (isosurfaces/boolean before forces). Mitigation: vectors already named in transformation. Accept as is.

## 5. Documents produced this cycle

```
doc/sieve_passes/
  2026-05-13T09-15-00_math-density.md          (prior)
  2026-05-13T09-45-00_catalyst-arsenal-mapping.md (prior)
  2026-05-13T10-30-00_phase-oscillation.md
  2026-05-13T10-35-00_phase-e-entropy.md
  2026-05-13T10-40-00_phase-lambda-edge.md
  2026-05-13T10-45-00_phase-integration.md
  2026-05-13T10-50-00_phase-synthesis.md
  2026-05-13T10-55-00_macro-qfep-arc.md
  2026-05-13T11-05-00_verification-pass.md
  2026-05-13T11-15-00_master-change-list.md    (this file)
```

Plus the change sequence proposal at `doc/sequence_proposals/2026-05-13_change-sequence.md` (prior session).

## 6. Verdict

**Reorder applied. Structure verified.** All four invariants hold (0 layer mismatches, 0 order mismatches, 0 missing affordances, 0 backward unlocks).

**31 artifacts queued** to build, distributed across 6 sequences. The largest debt is postfoundationscrisis (12 artifacts, the thesis-landing). Next-priority debt is change sequence fill (10 artifacts, already in JSON), then boolean_surfaces (5, now mis-aligned without artifacts).

The spine now reads as one argument from primitive form to applied thesis. The bracelet at synthesis holds 33 affordances. Phase truths are stated. The reorder is verified internally consistent.

Next step is **build queue execution** — scaffolding the new artifact files. See section 7 of macro sieve for the verb-set per phase.

Load-bearing rule out:

> **Reorder before build.** Building 31 artifacts under the *old* spine ordering would have placed them in wrong phases, generated wrong affordances, and embedded the v1.3 drift deeper. Doing the structural moves *first* — and verifying consistency — means the build queue lands artifacts where they belong on the first pass. Sieve before scaffold.
