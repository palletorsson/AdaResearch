# Forces (Vectors & Forces) — Curriculum Audit

**Sequence ID:** `forces`
**Source file:** `commons/maps/sequences/forces.json`
**Spine position:** Behaviors layer, after `primitives` and `transformation`
**Merged from:** `vectors.json` (merged 2026-02-20)
**Maps:** 10 (`VectorFoundations`, `VectorOperations`, `VectorApplied`, `VectorAdvanced`, `ForcesFoundations`, `ForcesComposition`, `ForcesSystems`, `ForcesChaos`, `ForcesArena`, `Chamber_Forces`)
**Evolutions written:** 0 formal evolution files — but strong `@identity` coverage on 17 vector artifacts and 1 forces artifact.
**QFEP term:** `dynamics` — vectors define system state S; forces drive φΔE(S, t).

## 1. Core Concept

The sequence teaches **how direction and magnitude become motion**. Vectors give space a grammar — every point can carry both "where" and "how much." Forces take that grammar and run it in time: F = ma is the hinge that converts a static vector (a push) into a moving vector (an acceleration, then a velocity, then a trajectory). The arc is pure math → operated math → applied math → embodied math → Newton → composition → systems → chaos → arena. The truth statement in the sequence file nails it: *"Direction + magnitude = vector. F = ma. Acceleration is the only thing you feel. Position and velocity are states; force is what changes them."* This is the pivot map of the curriculum — before it, space is geometry; after it, space has dynamics.

## 2. The Red Thread

1. **Coordinate Frame** (VectorFoundations — Island A entry)
   - Three mutually perpendicular directions with an agreed origin
   - Captures: embodiment inside a basis, orientation as felt direction, right-hand convention
   - Leaks: the arbitrariness of the choice (right vs left-handed, Y-up vs Z-up are decisions, not truths)

2. **Vector as Magnitude × Direction** (VectorFoundations)
   - `v = |v| * v-hat`. Three floats become one arrow.
   - Captures: decomposition into components, the spring-scale feel of magnitude, unit vectors as "direction without size"
   - Leaks: vectors aren't points and aren't numbers — they're displacements, which the still geometry of Primitives couldn't hold

3. **Addition and Subtraction** (VectorFoundations)
   - Head-to-tail, parallelogram law; `b - a` = relative position
   - Captures: resultant, displacement, relative frames
   - Leaks: what if the vectors live on a curved manifold? (parallel transport → higher dimensions / foundations crisis)

4. **Dot Product — Alignment** (VectorOperations)
   - `a · b = |a||b|cos θ`. Projection, work, "how parallel?"
   - Captures: angle measurement without arccos, the gate from geometry to energy
   - Leaks: dot product only measures "how much in the same direction" — says nothing about rotation

5. **Cross Product — Perpendicularity** (VectorOperations)
   - `a × b` produces a new vector perpendicular to both, magnitude `|a||b|sin θ`
   - Captures: torque seed, normals, handedness made visible
   - Leaks: cross product is a 3D-only accident — in 2D you get scalars, in 4D+ you need wedge products (forward-leak to higher_dimensions / alternative geometries)

6. **Projection & Reflection** (VectorOperations)
   - Decomposing a vector into parallel + perpendicular components onto a surface
   - Captures: normal force, bounce, mirror symmetry, the "split one force into two" move
   - Leaks: reflection assumes hard surfaces — soft deformation requires soft_bodies

7. **Vector Field** (VectorApplied)
   - Every point in space gets a vector; particle reads the local instruction
   - Captures: flow, advection, swirl vs radial composition
   - Leaks: the particle has no memory or goal — memoryful agents require swarmintelligence; fields over time require wavefunctions

8. **Targeting / Steering** (VectorApplied)
   - Subtract positions to get a "desire vector" → normalize → scale by max speed → follow
   - Captures: AI-as-vector-math, the seed of boids/reynolds behaviors
   - Leaks: single-target greedy — group dynamics leak forward to swarms

9. **Torque** (VectorAdvanced)
   - `τ = r × F`. The cross product made physical. Lever arm turns linear force into spin.
   - Captures: rotational dynamics, "zero torque through the center," embodied wrench
   - Leaks: rigid-body rotations want quaternions (forward-leak to transformation's deeper layer)

10. **Throwing / Projectile** (VectorAdvanced)
    - `p(t) = p0 + v0·t + 0.5·g·t²`. Initial conditions write the whole parabola.
    - Captures: release as commitment, trajectory prediction, VR hand velocity as input
    - Leaks: after release, no control — the question of corrective forces opens Forces proper

11. **Newton's Laws — F = ma** (ForcesFoundations)
    - The axiom. Force changes velocity; mass resists change.
    - Captures: the central equation of the sequence, embodied mass variation (light ball vs heavy ball)
    - Leaks: Newton assumes inertial frames — non-inertial frames open relativistic questions (forward-leak to foundationscrisis)

12. **Gravity & Friction & Drag** (ForcesFoundations)
    - Constant down-pull; velocity-opposing resistance; `F_drag = -C|v|²v-hat`
    - Captures: terminal velocity, the fluid's "memory of your velocity," mass as privilege in a medium
    - Leaks: real fluids have turbulence, pressure, viscosity gradients (forward-leak to fluid_simulation)

13. **Superposition** (ForcesComposition)
    - `F_net = ΣF_i`. Every force acts simultaneously; the body feels only the sum.
    - Captures: force composition as vector addition applied, "nature doesn't apply forces one at a time"
    - Leaks: non-linear force fields (e.g., self-interacting) break clean superposition — hints at chaos ahead

14. **Work & Energy** (ForcesComposition)
    - `W = F · d`. Dot product returns as energy transfer. Momentum conservation in collisions.
    - Captures: energy as the accounting layer under forces
    - Leaks: conservation laws → Lagrangian mechanics (not covered), heat → thermodynamics (not covered)

15. **Attractors & Springs** (ForcesSystems)
    - Inverse-square attraction, Hooke's law `F = -kx`
    - Captures: oscillation, orbit, potential wells, the two canonical force laws of classical physics
    - Leaks: damping brings friction back; coupled oscillators open wavefunctions

16. **Force Fields & Particle Systems** (ForcesSystems)
    - Many bodies under spatial force functions; statistical emergence
    - Captures: the leap from "a ball" to "a cloud"
    - Leaks: particle interaction → swarm, softbodies, fluid

17. **N-Body / Chaos** (ForcesChaos)
    - Three bodies with gravity; strange attractors; force-directed graph layout
    - Captures: deterministic rules → unpredictable dynamics, sensitivity to initial conditions
    - Leaks: chaos is where Newton's promise of prediction breaks — the bridge to foundationscrisis and cellularautomata

18. **Arena — Applied Synthesis** (ForcesArena)
    - Drone combat, physics destruction, exhibition gallery
    - Captures: force knowledge as game-loop grammar; everything deployed in one world
    - Leaks: destructible meshes point at procedural geometry / voronoi (forward-leak to computationalgeometry)

19. **Chamber** (Chamber_Forces)
    - Catalyst chamber — physics as gentleness, the kresling slowed by calming mortar
    - Captures: synthesis, catalyst pickup that carries forward, narrative closure
    - Leaks: transition into physicssimulation / swarmintelligence / softbodies (the declared unlocks)

## 3. Map-to-Concept Mapping

| Order | Map | Concept(s) | Anchor Artifact(s) | Grammar | Status |
|-------|-----|------------|--------------------|---------|--------|
| 1 | VectorFoundations | Frame + magnitude + add/subtract | `VectorBasics`, `basis_vectors_rig`, `vector_addition_demo`, `vector_subtraction_demo`, `coordinate_system_switcher`, `ForceMagnitudeDemo` | linear (3 islands) | ✓ built |
| 2 | VectorOperations | Dot + cross + projection | `dot_product_projector`, `vector_projection_demo`, `normal_force_demo` | linear (3 islands) | ✓ built |
| 3 | VectorApplied | Fields + targeting + weather | `VectorFieldFlow`, `force_field_visualizer`, `hl_turret_vectors`, `weather_vector_field` | florence (3 islands) | ✓ built |
| 4 | VectorAdvanced | Torque + throwing + steering | `torque_demo`, `VectorThrowing`, `exercise_1_3_solution_3_d_bouncing_ball_vr`, `exercise_1_8_solution_attraction_magnitude_vr` | florence (4 islands) | ✓ built |
| 5 | ForcesFoundations | Newton + friction + drag | `example_2_5_fluid_resistance_vr` | zelda (3 islands) | ⚠ under-populated — only 2 interactables listed |
| 6 | ForcesComposition | Superposition + work-energy + momentum | `combined_forces_demo`, `work_energy_demo`, `momentum_collision` | zelda (diamond) | ✓ built |
| 7 | ForcesSystems | Attractors + fields + springs + particles | `mass_spring_damper`, `spring_system`, `particle_systems`, `force_fields`, `vector_fields`, `firework_launcher`, `example_3_2...`, `example_3_3...` | zelda (4 islands) | ✓ dense |
| 8 | ForcesChaos | N-body + chaos + force-directed | `three_body_problem`, `nbody_simulation`, `chaos_attractor`, `forcedirected3d` | zelda | ✓ built |
| 9 | ForcesArena | Combat + destruction + gallery | `gravity_gun_test_scene`, `vector_drone`, `destructibles_test_scene`, `VectorThrowing`, `sphere_splitting_showcase` | vatican (world-scale) | ✓ built |
| 10 | Chamber_Forces | Synthesis + catalyst | `becoming_catalyst` (implicit — chamber pattern) | chamber | ✓ small (11×7) |

The ordering is coherent: pure-math vectors → applied vectors → Newton → composition → systems → chaos → arena → chamber. `ForcesComposition` is correctly placed after `ForcesFoundations` (even though the sequence's `artifact_groups` list orders `ForcesComposition` before `ForcesFoundations` in the JSON — the `maps` array has Foundations first, which is correct).

**Note on the JSON inconsistency:** In `forces.json`, the `maps` array (line 71-82) lists `ForcesFoundations` before `ForcesComposition`, but the `artifact_groups` blocks list `ForcesComposition` (line 161) *before* `ForcesFoundations` (line 176). The content list (line 35-45) also matches `maps`: Foundations then Composition. This ordering conflict should be resolved — see Gap Analysis.

## 4. Artifact Inventory

### Core Vector Atoms
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Coordinate frame | CoordinateSystem3M | `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd` | vectors.json | ✓ @identity |
| Magnitude × direction | VectorBasics | `algorithms/vectors/01_vector_basics/VectorBasics.gd` | vectors.json | ✓ @identity, strong |
| Force magnitude | ForceMagnitudeDemo | `algorithms/vectors/01_vector_basics/ForceMagnitudeDemo.gd` | vectors.json | ✓ @identity |
| Addition | VectorAddition | `algorithms/vectors/02_vector_addition/VectorAddition.gd` | vectors.json | ✓ |
| Addition (demo) | vector_addition_demo | (in registry vectors.json @ 3793) | vectors.json | ✓ |
| Subtraction | VectorSubtraction | `algorithms/vectors/04_vector_subtraction/VectorSubtraction.gd` | vectors.json | ✓ |
| Subtraction (demo) | vector_subtraction_demo | (registry @ 4534) | vectors.json | ✓ |
| Basis rig | basis_vectors_rig | (registry @ 1385) | vectors.json | ✓ repeat anchor across maps |
| Coordinate switcher | coordinate_system_switcher | (registry @ 1480) | vectors.json | ✓ |

### Operations
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Dot product | VectorDotProduct | `algorithms/vectors/03_dot_product/VectorDotProduct.gd` | vectors.json | ✓ |
| Dot product (projector) | dot_product_projector | (registry @ 1893) | vectors.json | ✓ |
| Cross product | VectorCrossProduct | `algorithms/vectors/06_vector_cross_product/VectorCrossProduct.gd` | vectors.json | ✓ |
| Torque | VectorTorque + TorqueDemo | `09_vector_torque/VectorTorque.gd`, `06_vector_cross_product/TorqueDemo.gd` | vectors.json, vectors_demos.json | ✓ @identity on TorqueDemo |
| Projection/reflection | VectorProjectionReflection, vector_reflection_demo | `07_vector_projection_reflection/`, `vector_reflection/` | vectors.json, vectors_demos.json | ✓ @identity |
| Normal force | NormalForceDemo | `07_vector_projection_reflection/NormalForceDemo.gd` | vectors_demos.json | ✓ @identity |

### Applied / Field
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Vector field | VectorFieldFlow | `algorithms/vectors/10_vector_field_flow/VectorFieldFlow.gd` | vectors.json | ✓ @identity |
| Force field visualizer | force_field_visualizer | (commons_artifacts.json @ 3278) | commons_artifacts | ✓ |
| Weather field | weather_vector_field | `algorithms/vectors/weather_vector_field/` | vectors_demos.json | ✓ @identity |
| Turret targeting | hl_turret_vectors, TurretTargeting | `algorithms/vectors/11_turret_targeting/`, `vectors.json` | vectors.json, vectors_demos.json | ✓ |
| Throwing | VectorThrowing | `algorithms/vectors/08_vector_throwing/VectorThrowing.gd` | vectors.json | ✓ @identity, strong |
| Drone | vector_drone | `08_vector_throwing/vector_drone.gd` | vectors.json | ✓ @identity |

### Forces — Newton, Friction, Drag
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| F = ma (mass variation) | example_2_2_forces_mass_variation_vr | `algorithms/forces/example_2_2_...gd` | physics_simulation.json | ✓ present, no @identity |
| Gravity scaled by mass | example_2_3_gravity_scaled_by_mass_vr | `algorithms/forces/example_2_3_...gd` | physics_simulation.json | ✓ no @identity |
| Friction | example_2_4_friction_vr | `algorithms/forces/example_2_4_friction_vr.gd` | physics_simulation.json | ✓ no @identity |
| Fluid resistance / drag | example_2_5_fluid_resistance_vr | `algorithms/forces/example_2_5_...gd` | physics_simulation.json | ✓ @identity (ONLY forces artifact with it) |
| Forces intro | example_2_1_forces_vr | `algorithms/forces/example_2_1_forces_vr.gd` | physics_simulation.json | ✓ no @identity |
| Generic Newton | newtons_laws | (physics_simulation @ 5797) | physics_simulation | ✓ |

### Forces — Composition
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Superposition | combined_forces_demo | `algorithms/vectors/02_vector_addition/CombinedForcesDemo.gd` | vectors_demos.json | ✓ @identity, strong |
| Work-energy | work_energy_demo | `algorithms/vectors/03_dot_product/WorkEnergyDemo.gd` | vectors_demos.json | ✓ @identity |
| Momentum/collision | momentum_collision | (physics_simulation @ 5562) | physics_simulation | ✓ |

### Forces — Systems
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Single attractor | example_2_6_single_attractor_vr | `algorithms/forces/...` | physics_simulation | ✓ no @identity |
| Multiple attractors | example_2_7_multiple_attractors_vr | `algorithms/forces/...` | physics_simulation | ✓ |
| Two-body attraction | example_2_8_two_body_attraction_vr | `algorithms/forces/...` | physics_simulation | ✓ |
| Spring (Hooke) | example_3_11_a_spring_connection_vr, spring_system | `algorithms/forces/`, physics_simulation | physics_simulation | ✓ |
| Spring-mass-damper | mass_spring_damper | (physics_simulation @ 5474) | physics_simulation | ✓ |
| Particle systems | particle_systems, example_4_*_vr (6 particle examples) | physics_simulation | physics_simulation | ✓ rich |
| Force fields | force_fields, vector_fields | physics_simulation | physics_simulation | ✓ |
| Firework | firework_launcher | physics_simulation @ 4870 | physics_simulation | ✓ |

### Forces — Chaos
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Three-body | three_body_problem | physics_simulation @ 6988 | physics_simulation | ✓ |
| N-body | nbody_simulation, example_2_9_n_body_attraction_vr | physics_simulation, `algorithms/forces/` | physics_simulation | ✓ |
| Chaos attractor | chaos_attractor | primitives.json @ 1447 (oddly registered here) | primitives | ⚠ categorization drift |
| Force-directed graph | forcedirected3d | algorithms_misc.json @ 2522 | algorithms_misc | ⚠ categorization drift |

### Arena
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Gravity gun | gravity_gun_test_scene | `algorithms/vectors/08_vector_throwing/destructibles/` | vectors.json @ 3044 | ✓ |
| Destructibles | destructibles_test_scene | `08_vector_throwing/destructibles_test_scene.gd` | vectors.json | ✓ @identity |
| Sphere splitting | sphere_splitting_showcase | `08_vector_throwing/sphere_splitting_showcase.gd` | vectors.json | ✓ @identity |
| Catalyst target | catalyst_target | hazards.json @ 897 | hazards | ✓ |

### Chamber
| Concept | Artifact | File | Registry | Status |
|---------|----------|------|----------|--------|
| Catalyst | becoming_catalyst (implicit) | `commons/hazards/becoming_catalyst/` | hazards | ✓ shared across chambers |

## 5. Gap Analysis

### Missing or Weak
1. **ForcesFoundations is underpopulated.** The map's `artifacts` list in the sequence JSON contains only `dark_sphere` and `example_2_5_fluid_resistance_vr`. Newton's core examples (`example_2_1_forces_vr`, `example_2_2_forces_mass_variation_vr`, `example_2_3_gravity_scaled_by_mass_vr`, `example_2_4_friction_vr`) exist in `algorithms/forces/` and are in `physics_simulation.json` registry — but are not placed on this map. This is the most important gap: **the map titled "Newton's Laws" lists no Newton artifact.**

2. **No @identity on any `algorithms/forces/*.gd` except `example_2_5_fluid_resistance_vr`.** 16 forces examples lack identity blocks. Contrast: 17 vector artifacts have them. The forces half of the sequence is documentation-starved.

3. **No dedicated `forces.json` registry.** Forces artifacts are scattered across `physics_simulation.json` (F=ma examples, springs, particles, attractors, nbody), `vectors_demos.json` (composition demos), `primitives.json` (chaos_attractor — odd), `algorithms_misc.json` (forcedirected3d — odd), `commons_artifacts.json` (force_field_visualizer). Categorization drift makes artifact discovery harder. A `forces.json` registry or clearer categorization would help.

4. **No evolution files.** Primitives has 3 evolutions; forces has 0. The sequence is one of the most important (direct prerequisite for physicssimulation, swarmintelligence, softbodies) and yet has no long-form narrative evolutions.

5. **No standalone "Hooke's law" anchor demo with @identity.** Springs exist (`spring_system`, `mass_spring_damper`, `example_3_5_simple_harmonic_motion_vr`, `example_3_11_a_spring_connection_vr`) but none has a clean `F = -kx` identity — whereas dot/cross/torque each have crisp identity anchors.

6. **No standalone gravity-well pedagogy anchor.** `gravity_well` exists in physics_simulation @ 5256 but isn't placed on any forces sequence map and has no @identity.

7. **Chamber_Forces has no listed artifacts** in `forces.json` artifact_groups. The map file exists but sits orphaned from the group metadata.

### Ordering Issues
- **`artifact_groups` array order in `forces.json`** lists ForcesComposition *before* ForcesFoundations (lines 161, 176), contradicting the `maps` and `content` arrays. Resolve: move ForcesComposition block after ForcesFoundations block to match playable order.
- **Redundant anchor artifacts repeated across maps**: `VectorBasics`, `basis_vectors_rig`, `dark_sphere` appear in VectorFoundations, VectorOperations, VectorApplied, and ForcesComposition. This is probably intentional (repeated anchor = visual callback) but risks staleness. Consider: keep basis_vectors_rig as the spine-motif, but retire `VectorBasics` after VectorFoundations.

### Missing Transitions
- **VectorAdvanced → ForcesFoundations**: the bridge "projectile as initial condition" to "projectile as differential equation" is weak. A small bridge artifact showing `v0` branching into "integrate forward" vs "apply new forces" would link the two halves.
- **ForcesComposition → ForcesSystems**: the leap from "two forces sum" to "a field of forces everywhere" is currently a teleporter, not a pedagogy. A field-superposition demo (same composition principle, distributed over space) would bridge.
- **ForcesChaos → ForcesArena**: chaos ends abstract, arena begins with drones — missing transition is "chaos is what makes arena feel alive."

### Redundancies
- Multiple turret artifacts (`hl_turret_vectors`, `laser_turret`, `sentry_turret`, `TurretTargeting`, `ball_dropper`) all teach subtract-normalize-scale targeting. Could consolidate to one "canonical turret" plus variants.
- Multiple particle examples (`example_4_1` through `example_4_6`, plus `particle_systems`) overlap with ForcesSystems content.

## 6. Forward Leaks

Questions this sequence raises but cannot hold:

- **Self-interacting fields / coupled oscillators** → `wavefunctions` (waves as oscillators with memory)
- **Turbulence, pressure, viscosity gradients** → `physicssimulation` proper / fluid sim (declared unlock)
- **Deformable bodies, internal stress** → `softbodies` (declared unlock — springs between particles is the bridge)
- **Many agents with memory + goals** → `swarmintelligence` (declared unlock — steering lives here, swarming generalizes it)
- **Rigid body rotation with quaternions** → `transformation` deeper layer
- **Constraints and joints** → `joints`, `constraint_solvers`
- **Integration stability, Verlet vs Euler** → covered technically (verlet_integration, numerical_integration exist) but not pedagogically surfaced in the sequence
- **Gradient descent as force** → `machinelearning` (ML treats loss-gradient as a force on parameters; hinted by `forcedirected3d` which is graph-layout-as-physics)
- **Non-inertial frames, relativity, Lagrangian mechanics** → `foundationscrisis` (where Newton breaks)
- **N-body chaos → cellular emergent systems** → `cellularautomata`
- **Destruction → procedural voronoi geometry** → `computationalgeometry`
- **Forces as metaphor for social/political dynamics** → `criticalalgorithms` / QFEP integration

The declared `unlocks` (`physicssimulation`, `swarmintelligence`, `softbodies`) correctly capture the three main exits. Missing explicit link to `machinelearning` (gradient = force) and `wavefunctions` (spring coupling = wave equation).

## 7. Proposed Ordering

Current order is mostly correct. Proposed minor adjustments:

```
1.  VectorFoundations     — frame + magnitude + add/subtract         [keep]
2.  VectorOperations      — dot + cross + projection                 [keep]
3.  VectorApplied         — fields + targeting + weather             [keep]
4.  VectorAdvanced        — torque + throwing + steering             [keep]
    --- PIVOT: from geometry-of-motion to physics-of-motion ---
5.  ForcesFoundations     — F=ma, gravity, friction, drag            [keep, BUT populate with Newton artifacts]
6.  ForcesComposition     — superposition, work-energy, momentum     [keep]
7.  ForcesSystems         — attractors, fields, springs, particles   [keep]
8.  ForcesChaos           — n-body, strange attractors               [keep]
9.  ForcesArena           — combat, destruction, gallery             [keep]
10. Chamber_Forces        — synthesis, catalyst pickup               [keep]
```

**Required fixes (not ordering, but blocking):**

1. In `forces.json`, reorder the `artifact_groups` array to put `ForcesFoundations` block (line 176-186) before `ForcesComposition` block (line 161-175), matching the `maps` array.
2. Add Newton artifacts to `ForcesFoundations` interactables: at minimum `example_2_1_forces_vr`, `example_2_2_forces_mass_variation_vr`, `example_2_4_friction_vr` alongside the existing `example_2_5_fluid_resistance_vr`.
3. Add an `artifact_groups` entry for `Chamber_Forces` (currently absent).
4. Consider creating a `commons/artifacts/registry/forces.json` and migrating scattered forces artifacts (`mass_spring_damper`, `nbody_simulation`, `three_body_problem`, `spring_system`, `particle_systems`, `force_fields`, `firework_launcher`, `newtons_laws`, `gravity_well`, `momentum_collision`, `example_2_*_vr`, `example_3_*_spring/harmonic/pendulum`, `example_4_*_particle`) into it. Currently `physics_simulation.json` is a dumping ground that mixes this sequence with the next one (physicssimulation).

## Summary

The forces sequence is the spine's pivot from static geometry to dynamics. It has strong bones — 10 well-named maps, ~75 anchor artifacts, coherent progression from pure vectors through Newton, composition, systems, chaos, to arena. The vector half (maps 1-4) is mature: 17 artifacts carry @identity blocks with sharp pedagogical framing (e.g., VectorBasics' "a vector is not a number and not a point — it is a displacement"; VectorThrowing's "a throw is an initial condition — after release, physics decides"). The forces half (maps 5-8) is structurally complete but documentation-starved: only `example_2_5_fluid_resistance_vr` has an @identity; the other 15 forces artifacts lack identity blocks, and the key "Newton's Laws" map lists only 2 interactables. The sequence has zero evolution files despite being a critical unlock gate for three downstream sequences (physicssimulation, swarmintelligence, softbodies).

**Highest-value next actions:**
1. Populate `ForcesFoundations.interactables` with Newton examples (2_1, 2_2, 2_4) — the map currently fails to deliver on its own title.
2. Write @identity blocks for the 16 forces artifacts in `algorithms/forces/`, matching the quality of the vectors half.
3. Write one evolution for the pivot map (`ForcesFoundations`) — the geometry→dynamics hinge deserves narrative.
4. Resolve the `artifact_groups` ordering inconsistency in `forces.json`.
5. Create `commons/artifacts/registry/forces.json` to consolidate scattered forces artifacts and reduce cross-sequence categorization drift.
