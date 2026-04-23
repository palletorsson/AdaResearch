# Procedural Generation — Curriculum Audit

**Sequence ID:** `proceduralgeneration`
**QFEP term:** Lambda_Edge — rules (F) constrained by randomness (E) produce emergent worlds
**Maps:** 8 (7 content + 1 chamber)
**Prerequisites:** noise, cellularautomata
**World phase:** organic
**Evolutions written:** 0

## 1. Core Concept

A world does not need an author. Rules + randomness + a seed is enough. This sequence teaches generative systems as the algorithmic answer to the question "where does content come from?" — the body learns that determinism and surprise are not opposites but dance partners, that a handful of local rules produces infinite macroscopic variety, and that every generator sits on the Lambda edge where too much order collapses to repetition and too much randomness collapses to noise. The interesting zone is the threshold itself: percolation's critical density, mutation rate's edge of chaos, carving vs constructing. The sequence is a taxonomy of *how* rules build worlds — noise-fields, growth-agents, cellular states, constraint-propagation, physics-then-freeze — and the player walks through each strategy as a physical space.

## 2. The Red Thread

1. **Evolution** (PG_Genetic_Evolution)
   - Fitness pressure + mutation + crossover breeds form without a designer
   - Captures: selection without selector, convergence from random starts, "mutation_rate 0.3 = edge of chaos"
   - Leaks: what the fitness *function* represents; evolution needs a judge

2. **Agent-guided growth** (PG_Space_Colonization)
   - Branches reach toward scattered attractors, consuming them on contact
   - Captures: competition-for-resources shaping structure, vascular/root emergence, kill_distance as tuning knob
   - Leaks: the attractor cloud itself is designed; real growth finds its own nutrients

3. **Phase transition** (PG_Percolation_Network)
   - At p ≈ p_c the random lattice goes from fragmented to connected; a fractal cluster threads through
   - Captures: criticality, emergent connectivity, the discrete/continuous boundary
   - Leaks: percolation assumes a grid; real phase transitions live in continuous fields

4. **Rules vs fields** (PG_Branching_Growth)
   - Explicit branching (agents) placed beside noise-driven terrain (fields) — two grammars for "organic"
   - Captures: the algorithmic dichotomy (imperative vs implicit), rules-that-move vs rules-that-evaluate
   - Leaks: hybrid systems combine both; the dichotomy is pedagogical scaffolding

5. **Carving vs constructing** (PG_Caves_Mazes)
   - Subtractive (random walk carves air from stone) vs additive (recursive backtracking builds corridors)
   - Captures: negative space as content, ordered vs organic exploration topology
   - Leaks: why is one "cave-like" and the other "maze-like" at a perceptual level — that is an art question

6. **Accumulation** (PG_Sculpted_Forms)
   - Pile cubes, subdivide icosahedra, stack membranes — sculpture from layered rules
   - Captures: geometry as process, stacking as a form of time, physics-then-freeze (cube_mound)
   - Leaks: what stops the accumulation; every generator needs a termination condition

7. **Symmetry and rhizome** (PG_Mirrored_Patterns)
   - Mirrored CA makes kaleidoscopes; rhizomatic mazes make non-hierarchical branching networks
   - Captures: pattern = rule + mirror, Deleuze's rhizome as architecture
   - Leaks: symmetry is a constraint on generation, not a generator itself — this belongs as much in transformation

8. **Chamber** (Chamber_ProcGen)
   - "The golem rebuilds from whatever is nearby. You cannot destroy it. Every piece you knock off becomes material."
   - Captures: procgen as irreducible — the system survives because it is not a thing but a rule
   - Leaks: the chamber is narrative closure, not a final concept — it points at regrowth / autopoiesis

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Compute | Status |
|-------|-----|---------|-----------------|---------|--------|
| 1 | PG_Genetic_Evolution | Evolution | GeneticProgramming | HEAVY solo | Map built, no evolution |
| 2 | PG_Space_Colonization | Agent-guided growth | space_colonization_algorithm | HEAVY solo | Map built, no evolution |
| 3 | PG_Percolation_Network | Phase transition | percolationnetwork_ca (+dark_sphere) | HEAVY solo | Map built, no evolution |
| 4 | PG_Branching_Growth | Rules vs fields | branching_growth_algorithm + organic_space | MEDIUM | Map built, no evolution |
| 5 | PG_Caves_Mazes | Carving vs constructing | caverandomwalk + maze_generation | MEDIUM | Map built, no evolution |
| 6 | PG_Sculpted_Forms | Accumulation | cube_mound_scene + dome + layered_membrane | LIGHT+MED | Map built, no evolution |
| 7 | PG_Mirrored_Patterns | Symmetry / rhizome | mirror_cellular_texture_for_3d + rhizomatic_maze_space | LIGHT | Map built, no evolution |
| 8 | Chamber_ProcGen | Synthesis (bricoleur golem) | proximity_spawner(bricoleur_golem) + catalyst_target×4 | — | Chamber built, minimal |

Ordering note: the sequence starts with the heaviest / most dramatic artifact (genetic evolution) rather than the simplest concept. This is a deliberate "drop them into awe" opener rather than a simple-to-complex build. Consider if that is right — see Proposed Ordering.

## 4. Artifact Inventory

| Concept | Artifact | File | @identity | Status |
|---------|----------|------|-----------|--------|
| Evolution | GeneticProgramming | algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.gd | yes | ✓ has auto-evolve, fitness labels; **missing** VR selection-pressure picker |
| Agent growth | space_colonization_algorithm | algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.gd | yes | ✓ works; **missing** VR attractor placement |
| Phase transition | percolationnetwork_ca | algorithms/proceduralgeneration/growth_systems/percolationnetwork_ca/percolationnetwork_ca.gd | yes | ✓ walkable flow; **missing** VR threshold slider, Label3D |
| Phase transition (visual anchor) | dark_sphere | (registry: lsystems.json — odd home) | unknown | ✓ placed but registry location is misleading |
| Branching (explicit) | branching_growth_algorithm | algorithms/proceduralgeneration/growth_systems/branchinggrowthalgorithm/branching_growth_algorithm.gd | yes | ✓ jitter parameter is the star; **missing** slider, button, Label3D |
| Noise field | organic_space | algorithms/alternativegeometries/organicspace/organic_space.gd | yes | ✓ CSG + noise cave |
| Cave (carving) | caverandomwalk | algorithms/proceduralgeneration/growth_systems/caverandomwalk/caverandomwalk.gd | yes | ✓ walkers carve voxels; **missing** seed slider |
| Maze (constructing) | maze_generation | algorithms/proceduralgeneration/procedural_logic/mazegeneration/maze_generator.gd | yes | ✓ recursive backtracking, red cursor visible |
| Accumulation (physics) | cube_mound_scene | algorithms/proceduralgeneration/hybrid_complex/cubemound/cube_mound.gd | yes | ✓ drop-settle-freeze |
| Accumulation (subdivision) | dome | (registry: primitives.json — classification issue) | unknown | ✓ icosphere subdivision |
| Accumulation (layering) | layered_membrane | algorithms/proceduralgeneration/hybrid_complex/layeredmembrane/layered_membrane.gd | yes | ✓ concentric translucent cylinders |
| Mirrored CA | mirror_cellular_texture_for_3d | algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd | yes | ✓ kaleidoscopes; **missing** VR symmetry selector, probability sliders |
| Rhizome | rhizomatic_maze_space | algorithms/alternativegeometries/rhizomaticmazespace/RhizomaticMazeSpace.gd | yes | ✓ Deleuze-named, path network + organic mesh |
| Chamber creature | bricoleur_golem | (via proximity_spawner) | unknown | ✓ referenced but identity file not located in quick scan |

### Coverage of red thread

Every concept-atom in the red thread has at least one anchor artifact on disk with a working _ready(). All eight core PG artifacts carry @identity blocks. The `needs:` field of most identities declares **missing VR controls** (sliders, buttons, Label3D) — the artifacts compute correctly but do not let the player *tune* the rule. This is the sequence's single biggest quality gap.

## 5. Gap Analysis

### Missing evolutions (high priority — all 8 maps)
Nothing in `ada_run/narrations/proceduralgeneration/` (checked via sequence state: evolutions written = 0). Primitives and fractals have worked examples — procgen has none. This sequence is heavy with concept density and would benefit enormously from narrative scaffolding.

### Missing interaction (high priority)
Nearly every @identity block lists `needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]`. Artifacts render but the player cannot turn the generator knob. For procgen specifically this is the core pedagogy loss — the entire point is to feel the phase boundary when you move mutation_rate from 0.29 to 0.31, or watch percolation fail at p=0.3 and succeed at p=0.5. Without sliders the artifacts are dioramas, not instruments.

Artifacts requiring VR controls added:
- GeneticProgramming — selection-pressure picker, mutation-rate slider
- percolationnetwork_ca — threshold slider (the critical parameter!), Label3D for p_c
- branching_growth_algorithm — jitter slider, push_button
- caverandomwalk — seed slider
- mirror_cellular_texture_for_3d — symmetry selector, birth/death probability sliders
- reaction_diffusion_vr (not in sequence but in growth_systems) — parameter sliders
- turing_pattern — parameter sliders

### Registry misplacement
- `dome` lives in `primitives.json` but is used here as a PG accumulation artifact. Either add a registry reference or move/duplicate into procgen_extra.
- `dark_sphere` lives in `lsystems.json` — if it is a generic dark-orb visual anchor it should move to commons.
- `rhizomatic_maze_space` and `organic_space` live in `alternative_geometries.json` — reasonable (they straddle), but the sequence JSON's `algorithm_sources` block explicitly maps them here, so a cross-reference would prevent future confusion.

### Missing transitions / bridges
- PG_Genetic_Evolution → PG_Space_Colonization: both are growth, but one is evolutionary (fitness-selected) and one is developmental (attractor-seeking). The shift is subtle. A text bridge should name it.
- PG_Percolation_Network → PG_Branching_Growth: percolation is *all* randomness, branching is *all* rules. The branching map then puts rules *against* noise. Order this so the player feels "pure random → rules versus random."
- PG_Caves_Mazes → PG_Sculpted_Forms: subtractive/additive in 2D (caves/mazes) generalizes to additive accumulation in 3D (mounds/domes). This is a beautiful progression but not narrated.
- Chamber_ProcGen → ? The chamber is a bricoleur_golem encounter but the sequence's `unlocks` array is empty. What comes next in the curriculum? The sequence completes but does not hand off.

### Redundancies
- Two noise-field artifacts (organic_space + layered_membrane) in consecutive maps. Both are "noise sculpts form" but at different frequencies. Could pair them in one map as a noise-families showcase.
- Mirrored CA + rhizomatic maze share a map but do not speak to each other — symmetry and rhizome are arguably *opposing* patterns of organization. The map design treats them as parallel exhibits; they could instead be staged as a dialectic.

### Deferred / redistributed content
The sequence JSON lists 9 deferred maps and a large `redistributed_artifacts` block pushing content to fractals, lsystems, cellularautomata, spatial_partitioning, constraint_solvers, higher_dimensions. This reorganization is documented in `doc/PROCEDURAL_GENERATION_REORGANIZATION.md` and appears intentional — but the **sub_sequences** block mentions grammar_systems, spatial_partitioning, constraint_solvers, isosurfaces, higher_dimensions as "focused sub-sequences in branch tracks." If those tracks exist as separate sequence JSONs (they do — verified via glob), then procgen is correctly functioning as a **hub** rather than a trunk. That is a design choice that should be named explicitly in doc.

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:

- **Constraint propagation (WFC)** → constraint_solvers sequence (wave function collapse already lives there)
- **Grammar-driven generation** → grammar_systems (Markov, N-gram, voxel grammar) and lsystems (rewriting rules for branching structures — lsystem_tree was moved out)
- **Spatial decomposition** → spatial_partitioning (Voronoi, Delaunay, BSP, Poisson — all originally here, now separated)
- **Isosurfaces** → isosurfaces sequence (marching cubes, cave terrain)
- **Higher-dimensional projection** → higher_dimensions sequence (tesseract, 16-cell)
- **Soft-body dynamics** → softbodies — cube_mound is physics-then-freeze; softbodies keeps the physics live
- **Learned generation (VAE/GAN)** → machinelearning — procgen is rule-authored, ML is data-authored; the contrast is crucial
- **Agent intelligence with goals** → swarmintelligence — space colonization has proto-agents; swarm gives them local perception and emergent collective behavior
- **Living regrowth / autopoiesis** → biological_growth, morphogenesis, ecology progression — the bricoleur_golem chamber hints at this but does not formalize it
- **Generation over time (narrative)** → speculativecomputation — procgen generates *once*; speculative computation generates *histories*
- **The politics of generation** → criticalalgorithms — who decides the fitness function, who chooses the seed, who gets percolated through

## 7. Proposed Ordering

The current sequence ordering leads with the most impressive artifact (genetic evolution) rather than the simplest concept. Two orderings are defensible:

### Option A — Current "drop-into-awe" order (keep)
1. PG_Genetic_Evolution — evolution as dramatic opener
2. PG_Space_Colonization — growth toward attractors
3. PG_Percolation_Network — criticality
4. PG_Branching_Growth — rules vs fields
5. PG_Caves_Mazes — subtractive vs additive
6. PG_Sculpted_Forms — accumulation in 3D
7. PG_Mirrored_Patterns — symmetry and rhizome
8. Chamber_ProcGen — bricoleur

Good if the teaching frame is *pedagogy-by-spectacle*. Works because heavy compute maps are solo and the player leaves them with a visceral "a world without a designer" feeling.

### Option B — "Simple rules outward" order (pedagogically cleaner)
1. **PG_Caves_Mazes** — simplest: random walk + recursive backtracking
2. **PG_Branching_Growth** — add agents reaching toward targets + noise fields
3. **PG_Sculpted_Forms** — accumulate in 3D
4. **PG_Mirrored_Patterns** — add symmetry constraints
5. **PG_Percolation_Network** — the phase transition itself
6. **PG_Space_Colonization** — full vascular growth
7. **PG_Genetic_Evolution** — the apex: selection without a selector
8. **Chamber_ProcGen** — synthesis

This climbs the complexity ladder. "I walked a maze → I saw branches find attractors → I felt a phase transition → I watched selection without a selector" is a story.

**Recommendation:** Option A for public player-facing flow (current state is fine); Option B for teaching contexts. Note the decision in the sequence JSON design_notes so future maintainers do not reorder it by accident.

### Also required regardless of order
1. Write evolutions for at least PG_Genetic_Evolution, PG_Percolation_Network, and Chamber_ProcGen (three tentpoles)
2. Add VR sliders/buttons to the six artifacts whose @identity declares `needs: [missing]`
3. Add a Label3D or science_screen explainer to each heavy-compute solo map so the player knows what they are watching
4. Resolve the registry-home confusion for dome / dark_sphere
5. Populate the sequence's `unlocks` array — what is next? swarmintelligence? softbodies? ML?

## Summary

Procedural generation is **structurally complete** — all 8 maps exist, all core artifacts exist with @identity blocks, the red thread from evolution → growth → phase transition → rules/fields → carving/constructing → accumulation → symmetry/rhizome → chamber is coherent. It is **pedagogically under-developed** — zero evolutions written, nearly every artifact missing the VR controls that would let the player *tune* the generator and feel the phase boundary (which is the whole point). The sequence also functions as a **hub**: it deliberately sheds constraint-solvers, grammars, spatial-partitioning, isosurfaces, and higher-dimensions to sibling sequences rather than teaching them here. That is a sound design choice but the `unlocks` field is empty, leaving the curriculum tree's branch-point undeclared. The fix is clear: add sliders, write evolutions, declare unlocks.
