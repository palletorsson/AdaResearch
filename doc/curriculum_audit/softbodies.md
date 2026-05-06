# Soft Bodies & Morphogenesis — Curriculum Audit

**Sequence ID:** `softbodies`
**Spine name:** Soft Bodies & Morphogenesis: Matter That Finds Its Shape
**Layer:** integration
**QFEP term:** Integration
**Maps:** 10 (9 in `maps[]`, plus `Chamber_SoftBodies` listed without artifact_group)
**Prerequisites:** forces, cellularautomata
**Unlocks:** swarmintelligence, morphogenesis
**Truth:** "Form is not imposed — it emerges from the material's own dynamics."

## 1. Core Concept

Matter that finds its own shape. This sequence teaches that form is not imposed from outside but negotiated from within — through springs resisting stretch, constraints holding edges together, pressure inflating volumes, and reactions that produce pattern from uniformity. It begins tactile (a jelly cube you can poke) and ends theoretical (Turing's reaction-diffusion, entropy as morphogenetic pressure). The through-line is F=E oscillation made physical: elastic restoring force (F) against deformation (E), activator against inhibitor, order against disorder. Softness is reframed as capacity to be affected — not weakness but a queer physics where identity persists through transformation rather than in spite of it.

## 2. The Red Thread

1. **Deformation** (`SoftBodies_Soft_Body_Deformation`)
   - A single point-mass lattice yielding to contact and recovering
   - Captures: stiffness/damping/pressure as the three axes of soft behavior; jiggle
   - Leaks: how the lattice is built, why springs not rigid joints

2. **Spring-Mass Dialogue** (`SoftBodies_Carusell`)
   - Compliance negotiating with motion — centripetal force against elastic recovery
   - Captures: dynamic deformation, collision response, hanging constraint
   - Leaks: the mesh as a mesh (you feel the blob, you don't see the springs)

3. **Compliance vs. Obstacle** (`SoftBodies_Obsticals`, `..._Part2`)
   - Yielding matter pressed against unyielding structure — walls breathe, flags dance
   - Captures: soft bodies as pressure systems; contact as continuous negotiation
   - Leaks: internal strain field — where the stress actually lives

4. **Cloth — Constrained Surface** (`SoftBodies_Cloth_Physics`)
   - 2D lattice of masses connected by structural/shear/bend springs, hung under gravity
   - Captures: cloth thinks with its whole body; constraints solve collective equilibrium
   - Leaks: tearing (constraint breaking), self-collision, wind field modeling

5. **Strain Energy & Volume** (`SoftBodies_Playground_of_Joy` → `rounded_softbody_test`)
   - Per-vertex E = ½·k·displacement², volume preservation, collision-force overlays
   - Captures: the invisible stress field rendered; conservation as emergent constraint
   - Leaks: why this shape and not another — what selects between possible equilibria

6. **Softness as Affect** (`SoftBodies_Affect_Theory_Visualization` → `radiolaria`)
   - Biological form (silica skeleton) as the outcome of surface tension and constraint, not design
   - Captures: softness as *capacity to be affected*; affect theory bridged to physics
   - Leaks: process — we see the result, not the becoming

7. **Reaction-Diffusion — Pattern From Process** (`ProceduralGeneration_Reaction_Diffusion_Systems`)
   - Gray-Scott: dA/dt = D_a·∇²A − A·B² + f·(1−A); dB/dt = D_b·∇²B + A·B² − (k+f)·B
   - Captures: pattern from uniformity; activator/inhibitor F=E at chemical scale
   - Leaks: the 2D field stays flat — how does pattern become geometry?

8. **Entropy Becoming Morphology** (`Topology_Entropy_Morphogenesis`)
   - Single entropy parameter S ∈ [0,1] sweeps a gyroid field through smooth→crumpled
   - Captures: morphogenesis as a function of one number; disorder finding structure
   - Leaks: time — this is parameter sweep, not developmental history

9. **Synthesis (Chamber)** (`Chamber_SoftBodies`)
   - Hopper chamber: "everything gives when you push it." Intended catalyst integration.
   - Captures: sequence close-out, return to Lab
   - Leaks: *currently empty* — chamber has no catalyst, no signature artifacts, no creatures

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | SoftBodies_Soft_Body_Deformation | Deformation (tactile first contact) | jelly_cube + softmill | ✓ works |
| 2 | SoftBodies_Carusell | Spring-mass dialogue | revolving_joy_ride, cloth_straps, soft_mushroom | ✓ works |
| 3 | SoftBodies_Obsticals | Compliance vs. obstacle | breathing_room, flagdancer | ✓ works |
| 4 | SoftBodies_Obsticals_Part2 | Extended obstacle gallery | softbody_gallery_part2 | ✓ thin |
| 5 | SoftBodies_Cloth_Physics | Cloth — constrained surface | softstopscene | ⚠ under-specified |
| 6 | SoftBodies_Playground_of_Joy | Strain energy / volume / free play | rounded_softbody_test, branching_growth_algorithm, gridagent | ✓ strongest teaching artifact |
| 7 | SoftBodies_Affect_Theory_Visualization | Softness as affect | radiolaria | ✓ (bridges to theory) |
| 8 | ProceduralGeneration_Reaction_Diffusion_Systems | Turing patterns | reaction_diffusion, turing_pattern_generator | ✓ (absorbed from morphogenesis) |
| 9 | Topology_Entropy_Morphogenesis | Entropy → morphology | entropy_morphogenesis | ✓ (absorbed from morphogenesis) |
| 10 | Chamber_SoftBodies | Chamber / synthesis | *none — only science_screen* | ✗ empty |

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Deformation (jelly) | jelly_cube | `commons/artifacts/jelly_cube/jelly_cube.gd` | ✓ @identity complete; sliders+buttons |
| Deformation (rotational) | softmill | `algorithms/physicssimulation/softbodies/softmill/` | ✓ works; rotating_arm has @identity |
| Hanging cloth | cloth_straps | `algorithms/softbodies/cloth_straps/cloth_straps.gd` | ✓ @identity complete |
| Rotational soft | revolving_joy_ride | `algorithms/softbodies/joyride/revolving_joy_ride.gd` | ✓ @identity complete |
| Soft organisms | soft_mushrooms / soft_mushroom | `algorithms/softbodies/mushrooms/` | ✓ @identity complete |
| Breathing walls | breathing_room | `algorithms/softbodies/advanced_concepts/breathing_room.gd` | ✓ @identity complete |
| Flag (skeleton-cloth) | flagdancer | `algorithms/physicssimulation/softbodies/flagdancer/` | ✓ @identity complete (note: bone-wave not true soft body) |
| Extended gallery | softbody_gallery_part1/2/3 | `algorithms/softbodies/` | ✓ exists, identity unclear |
| Cloth chamber | softstopscene | `algorithms/physicssimulation/softbodies/softbodystop/stopscene.tscn` | ⚠ category "unknown", description stub |
| Strain energy viewer | rounded_softbody_test | `algorithms/softbodies/rounded_softbody.tscn` | ✓ best teaching artifact; VR grip, 3 modes |
| Pendulum slap | pendulum_slap | `algorithms/softbodies/slap_test/` | ✓ exists but unused by sequence |
| Trampoline | soft_trampoline | `algorithms/softbodies/advanced_concepts/` | ✓ exists but unused |
| Ball pit | squishy_ball_pit | `algorithms/softbodies/advanced_concepts/` | ✓ exists but unused |
| Radiolaria | radiolaria | `algorithms/computationalbiology/radiolaria/radiolaria.gd` | ✓ @identity complete (CSG, not sim) |
| Reaction-diffusion | reaction_diffusion, turing_pattern_generator | `algorithms/proceduralgeneration/growth_systems/reactiondiffusion/` | ✓ @identity complete (GPU ping-pong) |
| Entropy morphogenesis | entropy_morphogenesis | `algorithms/spacetopology/entropy_morphogenesis/` | ✓ @identity complete (gyroid + marching cubes) |
| Growth coupling | branching_growth_algorithm | `algorithms/proceduralgeneration/growth_systems/branchinggrowthalgorithm/` | ✓ reused from procgen |
| Grid agent | gridagent | — | ⚠ reused; not audited here |
| Chamber catalyst | — | — | ✗ **MISSING** |

## 5. Gap Analysis

### Chamber is empty
`Chamber_SoftBodies/map_data.json` has only a `science_screen` — no `becoming_catalyst`, no signature soft-body artifact, no creatures. For a sequence tagged as an Integration chamber that "returns to lab," this is the biggest hole. By the catalyst chamber design (memory `project_catalyst_chambers`), this should be a **Nature Act** chamber (sequence ~6–11) with catalyst pickup, befriended creatures, library rack, and teleporter. None of that is present. Also: `Chamber_SoftBodies` is absent from the sequence's `artifact_groups[]` — it's listed in `maps[]` but not wired for placement.

### Cloth map is thin
`SoftBodies_Cloth_Physics` depends on a single artifact `softstopscene` whose registry entry is stubbed (`category: "unknown"`, `description: "Deformable soft body physics simulation"`). The map's concept (draping, tearing, wind) is the canonical cloth-physics demonstration; it deserves a dedicated, @identity-documented cloth sim with explicit structural/shear/bend spring visualization.

### Unused assets
`pendulum_slap`, `soft_trampoline`, `squishy_ball_pit`, `softbody_gallery_part1`, `softbody_gallery_part3` all exist and are registered but are not placed in any softbodies map. Either absorb them into existing maps (Obsticals_Part2 gallery is a natural home) or de-register.

### flagdancer is not actually a soft body
Its @identity says "Skeleton3D with per-bone sine wave displacement" — it is bone-animated, not a spring-mass system. It looks right but teaches the wrong thing in this sequence. Either relabel as "wave-driven surface" (wavefunctions) or upgrade to a real cloth simulation.

### radiolaria is not a soft body either
CSG union/subtraction on spheres/cylinders — a morphology showcase, not a simulation. Narratively it works (bridge to affect theory); pedagogically it doesn't teach the sequence's physics. The @identity is honest about this; the sequence framing should be honest too — call it a **specimen cabinet**, not a simulation.

### Missing transitions
- **Mass-spring → Cloth** is a real conceptual jump (0D → 1D → 2D lattice). No bridge map explains why cloth needs *three* spring families (structural, shear, bend) where jelly got away with one.
- **Soft bodies → Reaction-diffusion** is tagged as "absorbed morphogenesis" — but the absorption is labelled, not taught. No bridge from mechanical F=E (springs) to chemical F=E (activator/inhibitor). The connection is stated in the sequence JSON qfep_connection but never inhabited by a map.
- **RD → entropy morphogenesis** both live in "synthesis" but share no artifact.

### Ordering: Affect before or after Turing?
`SoftBodies_Affect_Theory_Visualization` currently sits between the play maps and the morphogenesis pair. The affect-theory turn is pointed outward — it recontextualizes what you just felt. Placing it AFTER Turing/entropy could land harder: *first* you see pattern emerge, *then* you reflect on softness as capacity to be affected. Current order is defensible (radiolaria is a preview of morphogenesis) but not obvious.

### Redundancies
- `SoftBodies_Obsticals` and `SoftBodies_Obsticals_Part2` share `pick_up_cube`, `grab_long_stick`. Part2 is described as "twelve test scenarios" but only places `softbody_gallery_part2`. Either merge or give Part2 a distinct concept (e.g. self-collision, tearing).
- Three gallery parts exist; only part2 is used. Consolidate.

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:
- **Collective motion from simple rules** → Swarm Intelligence (next sequence)
- **Developmental history, not just parameter sweep** → Biological Growth / Morphogenesis (unlock)
- **Learning the right stiffness from data** → Machine Learning
- **Identity preserved through transformation** → QFEP Laboratory (the F=E formula stated here, proved there)
- **Tearing, fracture, material failure** → unaddressed; could go to Meshes
- **Self-collision, knot theory** → Graph theory / Computational Geometry
- **Fluid as the limit of very-soft body** → Procedural Audio wavefunctions, or a future fluids sequence
- **Why this shape and not another (shape selection)** → Isosurfaces, Constraint Solvers
- **Skeleton + cloth hybrids (real creature bodies)** → Fold System, Pokemon Studio
- **Continuum mechanics (stress tensors, FEM)** → forward leak, currently not anywhere

## 7. Proposed Ordering

### Current (9 + chamber)
```
1. Soft_Body_Deformation
2. Carusell
3. Obsticals
4. Obsticals_Part2
5. Cloth_Physics
6. Playground_of_Joy
7. Affect_Theory_Visualization
8. Reaction_Diffusion_Systems
9. Entropy_Morphogenesis
10. Chamber_SoftBodies  (in maps[], absent from artifact_groups[])
```

### Proposed
```
1. Soft_Body_Deformation          — jelly_cube + softmill  (tactile hello)
2. Carusell                       — joy_ride + cloth_straps + mushroom  (motion)
3. Obsticals                      — breathing_room + flagdancer  (resistance)
4. Cloth_Physics                  — [rebuild artifact] (dedicated 2D lattice, tear/wind)
5. Obsticals_Part2                — [rethink: self-collision gallery, absorb trampoline / ball_pit / pendulum_slap] 
6. Playground_of_Joy              — rounded_softbody_test (strain/volume, THE teaching artifact) + growth
7. Reaction_Diffusion_Systems     — [bridge map: chemical F=E after you've felt mechanical F=E]
8. Entropy_Morphogenesis          — single-parameter morphogenesis
9. Affect_Theory_Visualization    — radiolaria as *reflection* on what you just saw, not preview
10. Chamber_SoftBodies            — [BUILD: becoming_catalyst + one signature soft creature + library rack]
```

Two structural moves:
- **Cloth up (4), galleries down (5)**: teach the canonical cloth sim before the gallery, so the gallery has vocabulary to extend. Currently galleries come before the explanation.
- **Affect after Turing, before Chamber**: the affect-theory turn lands harder when it can reframe both the mechanical and the chemical. It becomes the reflection phase of the chamber's larger arc.

## Summary

Soft Bodies is the sequence where Ada's F=E gets physical. The mid-game is the strongest: `rounded_softbody_test` with per-vertex strain energy is a model teaching artifact, @identity blocks across the soft body artifacts are unusually thorough, and the QFEP framing is already written into the sequence JSON. The main weaknesses are at the two ends: the cloth map depends on a stubbed artifact, and the chamber is empty — no catalyst, no creatures, no synthesis. Two artifacts (`flagdancer`, `radiolaria`) present themselves as soft-body simulations but are actually bone-animation and CSG — honest in their own @identity, under-framed in the sequence narrative. And the absorption of morphogenesis (reaction-diffusion + entropy) is declared but not bridged: no map teaches that the mechanical F=E of springs is the same move as the chemical F=E of activator/inhibitor. That bridge is the one thing that would make this sequence click as an Integration layer.
