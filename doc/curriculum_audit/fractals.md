# Fractals — Curriculum Audit

**Sequence ID:** `fractals`
**Spine order:** 10 (lambda_edge phase)
**Maps:** 11 (10 thematic + 1 chamber)
**Truth:** `D = log(N) / log(S)` — infinite complexity from finite rules, dimensions between integers
**QFEP term:** `E(S) + F` — deterministic rule F plus stochastic variation lambda·E(S)
**Prereqs:** primitives, transformation · **Unlocks:** proceduralgeneration, lsystems
**Evolutions written:** 0 (intent.md exists for all thematic maps; chamber is thin)

## 1. Core Concept

Fractals teach that complexity is **generated, not designed**. A five-line function whose output becomes its own input produces structures no human can draw by hand: infinite perimeter in finite area, non-integer dimension, self-similar copies at every scale. This is the `lambda_edge` thesis made concrete — the most interesting structure in any system lives at its phase transitions, and fractals are the geometry of those transitions. The sequence walks the learner through four operations that all produce fractality — **subdivision, deletion, addition, iteration** — and shows the same governing law (`D = log(N)/log(S)`) measuring all of them. By the end, fractals are no longer a curiosity file but the ordinary geometry of coastlines, trees, lungs, romanesco, and the Mandelbrot boundary itself.

## 2. The Red Thread

1. **Recursion** (Fractal_Recursion)
   - A function that calls itself with a reduced argument and a base case
   - Captures: self-reference as generative mechanism, depth as exponent of complexity, subdivision
   - Leaks: why some recursions converge and others diverge; dimension; measurement

2. **Branching / Organic Recursion** (Fractal_RecursiveTrees)
   - Recursion given two (or more) children per call — the tree grammar
   - Captures: L-system branching, stochastic perturbation (noise inside the rule), growth without blueprints
   - Leaks: formal dimension measurement; non-branching fractals; topology of the resulting set

3. **Deletion** (Fractal_CantorSet)
   - A fractal defined by what is removed — middle-third, iterated
   - Captures: non-integer dimension made explicit (D = log 2 / log 3 ≈ 0.631), existence-by-absence, the first computable D
   - Leaks: how deletion generalizes to 2D/3D; additive fractals; complex-plane fractals

4. **Addition / Replacement** (Fractal_KochSierpinski)
   - Koch curve: replace each segment with a spiked quadruple (D ≈ 1.262). Sierpinski: remove/replace in 2D (D ≈ 1.585)
   - Captures: the dual of deletion — growth by replacement, infinite perimeter in finite area, the paradox of Richardson's coastline
   - Leaks: why this is "pathological" language is wrong; the 3D case

5. **Dimensional Ladder** (Fractal_MengerSponge)
   - Deletion extended to 3D: D ≈ 2.727, infinite surface / zero volume, a walkable fractal
   - Captures: the universal curve property (all 1D compact curves embed in it), completion of the deletion arc (Cantor → Sierpinski → Menger), embodied scale
   - Leaks: organic fractals, iteration-based (non-constructive) fractals

6. **Golden Growth** (Fractal_GoldenSpiral)
   - Fibonacci recurrence F(n) = F(n-1) + F(n-2); golden ratio φ; 137.5° phyllotaxis; romanesco
   - Captures: additive self-similarity in biological form, irrationality as optimal packing, the empirical fractal
   - Leaks: why nature chose φ specifically; the jump from real to complex iteration

7. **Complex Iteration** (Fractal_JuliaSet)
   - z_{n+1} = z_n² + c on the complex plane — the fractal emerges from dynamics, not construction
   - Captures: iteration as source of form, connected vs. Cantor-dust Julia sets, parameter-space thinking
   - Leaks: which c-values give connected sets; an atlas of Julia sets

8. **The Master Fractal** (Fractal_MandelbrotSet)
   - M = {c : orbit of 0 under z²+c is bounded}. The atlas of all Julia sets
   - Captures: infinite zoom, self-similarity as literal nesting (mini-Mandelbrots), boundary Hausdorff dimension = 2 (Shishikura) — "the edge is as rich as the whole"
   - Leaks: 3D analogs (Mandelbulb); what to do with all this structure; how fractals interact with randomness and selection

9. **Synthesis** (Fractal_Synthesis)
   - Gallery of the whole arc with D values on a common number-line
   - Captures: the four operations (subdivide/delete/add/iterate) measured by one formula; QFEP as unified theory of edge-of-chaos geometry
   - Leaks: agency — fractals so far have been observed, not acted upon

10. **Cross-Sequence** (Fractal_CrossSequence)
    - Stochastic trees + cellular automata (Rule 90 → Sierpinski) + evolutionary algorithms on fractal fitness landscapes
    - Captures: fractals as substrate for computation and evolution, not just a topic among topics
    - Leaks: L-systems as a language (next sequence), procedural generation as a practice (next sequence)

11. **Chamber** (Chamber_Fractals)
    - Catalyst mode `fractal` + creature `fractal_hydra` — self-similarity across the player/creature boundary
    - Captures: narrative closure, QFEP embodiment, transition to procgen + L-systems
    - Leaks: the catalyst mode itself is under-documented in-world

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact(s) | Status |
|-------|-----|---------|--------------------|--------|
| 1 | Fractal_Recursion | Recursion (subdivide) | cube_subdivision, cube_staircase, recursive_chair, fibonacci_pagoda | intent ✓, evolution missing |
| 2 | Fractal_RecursiveTrees | Branching / stochastic | recursive_tree, recursive_tree_2, inverted_tree_cloud, mobius_world | intent ✓, evolution missing |
| 3 | Fractal_CantorSet | Deletion (1D, D=0.631) | cantor_set, example_8_4_cantor_pagoda_vr, example_8_4_cantor_set_vr | intent ✓, evolution missing |
| 4 | Fractal_KochSierpinski | Addition/replace (D=1.26, 1.58) | fractal_koch_curve, koch_curve_3d, sierpinski_triangle, sierpinski_pyramid | intent ✓, evolution missing |
| 5 | Fractal_MengerSponge | Deletion in 3D (D=2.727) | menger_sponge | intent ✓, evolution missing |
| 6 | Fractal_GoldenSpiral | Organic / φ / phyllotaxis | fibonacci_sequences, golden_rectangle, romanesco, fibonacci_terrain | intent ✓, evolution missing |
| 7 | Fractal_JuliaSet | Complex iteration | julia_set, julia_set_explorer | intent ✓, evolution missing |
| 8 | Fractal_MandelbrotSet | Master fractal / atlas | mandelbrot_set, mandelbrot_dive | intent ✓, evolution missing |
| 9 | Fractal_Synthesis | Unified D-spectrum | cantor_set, koch_curve, sierpinski_triangle, recursive_tree, romanesco, fibonacci_sequences | intent ✓, evolution missing |
| 10 | Fractal_CrossSequence | Fractal × CA × evolution | fractal_stochastic_tree, cellular_automata_3d_stacked, evolutionary_algorithms | intent ✓, evolution missing |
| 11 | Chamber_Fractals | Catalyst + creature | becoming_catalyst (mode: fractal), fractal_hydra | intent thin (4 lines), evolution missing |

**Ordering observation:** The sequence as written is pedagogically well-ordered (see §7). One visible friction point: the dimension formula `D = log(N)/log(S)` is **invoked** in Map 3 (Cantor) but not **introduced** by its own artifact until Map 9 (Synthesis). Learners meet dimension as a result before they meet it as a tool.

## 4. Artifact Inventory

### Existing artifacts (grouped by concept-atom)

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Recursion — subdivision | cube_subdivision | `algorithms/fractals/cubesubdivision/cube_subdivision.gd` | ✓ |
| Recursion — stair | cube_staircase | `algorithms/fractals/cubesubdivision/cube_staircase.gd` | ✓ |
| Recursion — CSG | recursive_boolean_cube | `algorithms/fractals/recursive_boolean_cube.gd` | ✓ |
| Recursion — furniture | recursive_chair, recursive_table, cube_desk, cube_bookshelf, cube_cabin | `algorithms/fractals/cubesubdivision/*.gd` | ✓ (six variants — possible redundancy) |
| Recursion — radial (VR) | example_8_3_recursion_circles_vr | `algorithms/fractals/example_8_3_recursion_circles_vr.gd` | ✓ |
| Recursion — Fibonacci bridge | fibonacci_pagoda | `algorithms/fractals/pillar/fibonacci_pagoda.gd` | ✓ |
| Recursion — template | fractal_recursion_2 | (registry: commons_artifacts.json) | ✓ (fractal_recursion_1 used in Synthesis) |
| Branching — deterministic | recursive_tree, recursive_tree_2 | `algorithms/fractals/recursivetree/recursive_tree.gd`, `algorithms/fractals/recursive_tree/recursive_tree.gd` | ✓ (two implementations — consolidation candidate) |
| Branching — inverted | inverted_tree_cloud | `algorithms/fractals/recursive_tree/inverted_tree_cloud.gd` | ✓ |
| Branching — topological | mobius_world | (registry) | ✓ |
| Branching — stochastic (VR) | example_8_7_stochastic_tree_vr, example_8_7_stochastic_tree_separated_vr | `algorithms/fractals/*.gd` | ✓ |
| Branching — scene | fractal_scene | (registry) | ✓ |
| Branching — conceptual | living_paper | `commons/artifacts/registry/living_paper.json` | ✓ |
| Branching — subdivision link | small_subdivision_cube | (registry) | ✓ |
| Deletion (1D) | cantor_set | `algorithms/fractals/cantorset/cantor_set.gd` | ✓ |
| Deletion — architectural | example_8_4_cantor_pagoda_vr | `algorithms/fractals/example_8_4_cantor_pagoda_vr.gd` | ✓ |
| Deletion — radial | example_8_4_cantor_set_vr | `algorithms/fractals/example_8_4_cantor_set_vr.gd` | ✓ |
| Addition — Koch 2D | fractal_koch_curve, koch_curve | `algorithms/fractals/koch_curve/KochCurve.gd`, `algorithms/fractals/koch_curve_1/KochCurve.gd` | ✓ (two implementations — consolidation candidate) |
| Addition — Koch 3D | koch_curve_3d | `algorithms/fractals/koshcurve/KochCurve3D.gd` | ✓ |
| Addition — Sierpinski 2D | sierpinski_triangle | `algorithms/fractals/sierpinskitriangle/sierpinski_triangle.gd` | ✓ |
| Addition — Sierpinski 3D | sierpinski_pyramid | `algorithms/fractals/sierpinski_pyramid/SierpinskiPyramid.gd` | ✓ |
| Dimensional ladder | menger_sponge | `algorithms/fractals/mengersponge/menger_sponge.gd` | ✓ |
| Organic — Fibonacci | fibonacci_sequences | `algorithms/fractals/fibonacci_sequences/FibonacciSequences.gd` | ✓ |
| Organic — terrain | fibonacci_terrain | `algorithms/fractals/fibonacci_terrain/fibonacci_terrain.gd` | ✓ |
| Organic — golden rect | golden_rectangle | `algorithms/fractals/golden_rectangle/golden_rectangle.gd` | ✓ |
| Organic — empirical | romanesco | `algorithms/fractals/romanesco/romanesco.gd` | ✓ |
| Complex iteration | julia_set | `algorithms/fractals/julia_set/JuliaSet.gd` | ✓ |
| Complex iteration — interactive | julia_set_explorer | (registry) | ✓ |
| Master fractal | mandelbrot_set | `algorithms/fractals/mandelbrot_set/MandelbrotSet.gd` | ✓ |
| Master — infinite zoom | mandelbrot_dive | (registry) | ✓ |
| Cross-sequence — CA stack | cellular_automata_3d_stacked | (registry, from CA sequence) | ✓ borrowed |
| Cross-sequence — GA | evolutionary_algorithms | (registry, from optimization) | ✓ borrowed |
| Cross-sequence — stochastic | fractal_stochastic_tree | (registry) | ✓ |
| Anchor (shared) | dark_sphere | (registry) | ✓ present in every map |

### Non-listed algorithms present in `algorithms/fractals/`
(Files that exist in the folder but are not placed in any current map. Latent assets.)

- `box_counting_dimension/box_counting_dimension.gd` — computes D via box counting. **This is the missing dimension-calculator artifact.**
- `fractal_clouds/fractal_clouds.gd` — Brownian / mid-point displacement clouds. Natural leak target.
- `lsystem_dungeon/lsystem_dungeon.gd` — L-system-generated dungeon. Belongs in lsystems sequence but is a clear bridge asset.
- `example_8_8_lsystem_string_only_vr.gd`, `example_8_9_lsystem_tree_vr.gd` — L-system VR demos, forward leak.
- `meshfractal/fractal.gd` — generic mesh fractal, could substitute for/augment `fractal_recursion_2`.

## 5. Gap Analysis

### Concepts well-covered
- Subdivision recursion (Fractal_Recursion has 9 artifacts — arguably too many)
- Deletion arc: Cantor → Sierpinski → Menger is clean and complete
- Complex dynamics: Julia → Mandelbrot is the canonical path, well-served

### Missing concepts / artifacts (gap-by-gap)

**High priority**

1. **Dimension calculator** — The governing law `D = log(N)/log(S)` is the sequence's truth-statement but has no interactive artifact. `algorithms/fractals/box_counting_dimension/box_counting_dimension.gd` **already exists** and is not placed on any map. Place it in Fractal_CantorSet (where D is first invoked) and/or Fractal_Synthesis (gap noted in that intent.md explicitly).
2. **Depth comparator** (noted in Fractal_Recursion intent gap) — side-by-side render of the same recursive rule at depths 1–6. No such artifact exists.
3. **Mandelbrot–Julia bridge** (noted in Fractal_MandelbrotSet intent gap) — a moveable cursor on M rendering the corresponding Julia set live. The two concepts are topologically linked but visually disjoint.
4. **Stochastic-tree parameter explorer** (noted in Fractal_RecursiveTrees intent gap) — sliders for angle variance / length variance / depth. The stochastic_tree_separated artifact exists as a static demo but not as a parameterized instrument.

**Medium priority**

5. **Fractal dimension wall** (noted in Fractal_Synthesis intent gap) — a 0–3 number line with all fractals in the sequence placed at their D. Would be the single most unifying artifact in the sequence.
6. **Koch coastline ruler** (noted in Fractal_KochSierpinski intent gap) — demonstrates Richardson's empirical observation that coastline length depends on ruler scale.
7. **Menger cross-section slicer** (noted in Fractal_MengerSponge intent gap) — shows Sierpinski / Cantor patterns as embedded sub-fractals.
8. **Phyllotaxis slider** (noted in Fractal_GoldenSpiral intent gap) — divergence-angle slider demonstrating why 137.5° is unique.
9. **Connected ↔ Cantor-dust Julia demo** (noted in Fractal_JuliaSet intent gap) — shatter animation as c crosses the Mandelbrot boundary.
10. **QFEP dashboard** (noted in Fractal_CrossSequence intent gap) — four simultaneous views of one stochastic tree (quantum / fractal / emergent / edge-poised).

**Low priority (nice-to-have)**

11. **Richardson plot** — log-log plot of length vs. ruler size, producing D as the slope. Companion to #6.
12. **Hilbert / Peano space-filling curve** — dimension-2 curve, fills the gap between the deletion arc and Menger sponge conceptually.
13. **Romanesco field / gallery instance** — current romanesco is a single model; a field of varying parameters would show that nature computes a family, not a fixed output.
14. **Mandelbulb / 3D Julia** — referenced as a leak but no artifact. Would also forward-seed procgen.

### Redundancies

- **Cube-furniture family in Fractal_Recursion** — `cube_desk`, `cube_bookshelf`, `cube_cabin`, `recursive_chair`, `recursive_table`, plus `cube_subdivision` and `cube_staircase`. Seven artifacts making the same pedagogical point. Consolidation candidate: keep `cube_subdivision` (primitive) + `recursive_chair` (familiar object made strange) + `cube_staircase` (visible depth) and move the other four to a gallery / recursion_furniture_showcase map or demote them to atmosphere.
- **Duplicate recursive_tree implementations** — `algorithms/fractals/recursivetree/recursive_tree.gd` and `algorithms/fractals/recursive_tree/recursive_tree.gd` both exist. Same for `koch_curve/KochCurve.gd` and `koch_curve_1/KochCurve.gd`. Likely historical drift; one of each should be canonical, the other deprecated.
- **fractal_recursion_1 vs fractal_recursion_2** — both appear in the registries and in map artifact_groups. Need an explicit naming convention (e.g., `_1` = 2D demo, `_2` = 3D demo) or consolidation.
- **fibonacci_terrain appears in both Fractal_GoldenSpiral and Fractal_JuliaSet** — intentional bridge per the intent.md, but worth flagging: the same artifact carrying two pedagogical jobs (organic growth, then bridge) risks muddying both.

### Missing transitions

- **Map 2 → Map 3** (RecursiveTrees → CantorSet) is conceptually the biggest jump in the sequence: organic branching to formal deletion with computable dimension. The `stochastic_tree_separated` in Map 3 is the only bridge and it carries a lot of weight. A transition map or a dimension-introduction artifact placed between them would smooth this.
- **Map 6 → Map 7** (GoldenSpiral → JuliaSet) is the other large leap: real-number recurrence to complex-plane iteration. Currently unbridged. A "complex numbers for biologists" artifact or a `complex_plane_walkabout` before Julia would help.
- **Map 10 → Chamber** (CrossSequence → Chamber_Fractals) — the chamber intent.md is only four lines; the transition is architecturally there but narratively thin.

### Chamber under-developed

`Chamber_Fractals/intent.md` is four lines. For context, `Fractal_CrossSequence/intent.md` is a full six-section document. The chamber is where the sequence's QFEP meaning lands and it needs the same treatment. Also needs `technical.md` and `critical.md` to exist (they don't — only `blurb.md` and `intent.md`).

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:

- **L-systems as a formal grammar** → `lsystems` sequence (direct unlock). The stochastic-tree artifact is already an implicit L-system; it needs the explicit language.
- **Procedural generation as practice** → `proceduralgeneration` sequence (direct unlock). Fractals give the *what*; procgen gives the *how to author systems that produce them*.
- **Noise and Brownian motion** → `noise` / wavefunctions. `fractal_clouds` exists but is latent — it would be a natural bridge.
- **Cellular automata as computational fractals** → `cellularautomata`. Rule 90 = Sierpinski is the iconic bridge, already alluded to in CrossSequence.
- **Evolutionary algorithms and fitness landscapes** → `optimization` / evolutionary-ecology sequences. CrossSequence points the door; the full treatment lives elsewhere.
- **Topology (manifolds, Möbius, Klein)** → foundations / topology. `mobius_world` is a hint at a whole sequence.
- **3D fractals beyond Menger (Mandelbulb, quaternion Julia)** → advanced / research. Open leak with no home yet.
- **Measurement theory / Hausdorff dimension formally** → foundations. The sequence uses the word "dimension" looser than a mathematician would; foundations would sharpen it.
- **Self-reference outside geometry (Gödel, Y-combinator, strange loops)** → computation / lambda / foundations. Recursion here is geometric; recursion as Hofstadterian loop is a different sequence.
- **Why coastlines are fractal (physics of erosion / growth)** → forces / noise / ecology. Empirical-fractal question that Romanesco only gestures at.
- **Agency over fractals (authoring, not observing)** → proceduralgeneration chamber. Learner is a viewer here; in procgen they become an author.

## 7. Proposed Ordering

The current order is **essentially correct** and reflects careful pedagogical thinking. The four operations (subdivide / delete / add / iterate) are sequenced with the dimensional ladder embedded in the middle and organic fractals providing the pivot from geometric to dynamical. Proposed refinements:

```
1. Fractal_Recursion         — subdivision, self-reference as mechanism
2. Fractal_RecursiveTrees    — branching, stochasticity, organic recursion
   ↳ [+ transition artifact: dimension_introduction or box_counting_dimension placed at end of Map 2]
3. Fractal_CantorSet         — deletion in 1D, first computable D
4. Fractal_KochSierpinski    — addition/replacement in 1D and 2D
5. Fractal_MengerSponge      — deletion ladder completes at 3D
6. Fractal_GoldenSpiral      — organic / φ / romanesco
   ↳ [+ transition artifact: complex_plane_walkabout]
7. Fractal_JuliaSet          — complex iteration
8. Fractal_MandelbrotSet     — master fractal, atlas of Julia
9. Fractal_Synthesis         — D-spectrum, four operations unified
10. Fractal_CrossSequence    — fractals × CA × evolution
11. Chamber_Fractals         — catalyst + fractal_hydra (needs fuller intent/technical/critical)
```

Two surgical insertions (dimension introduction between 2–3, complex-plane preparation between 6–7) would smooth the two largest conceptual leaps in the sequence without disturbing the overall shape.

## Summary

Fractals is a **structurally mature sequence with a thin instrumentation layer**. Every map has an intent.md, the four-operation scaffolding (subdivide / delete / add / iterate) is rigorous, and the artifact count is high (50+ placements). But the sequence is still largely a **gallery**: the learner walks past fractals rather than operating on them. The highest-leverage work is instrumenting the existing concepts:

1. **Place `box_counting_dimension`** (already built, sitting idle) in Fractal_CantorSet and Fractal_Synthesis — this single move turns the governing formula from an assertion into a tool.
2. **Build the three named bridge artifacts** — Mandelbrot-Julia cursor, depth comparator, stochastic-tree slider panel — each already called for in the map intent.md gap lines.
3. **Thicken Chamber_Fractals** — the current 4-line intent.md is the weakest point in an otherwise strong sequence.
4. **Consolidate the cube-furniture family** in Fractal_Recursion — seven artifacts carry the weight of three; the rest should move to atmosphere or a side gallery.
5. **Resolve duplicate implementations** — `recursive_tree` / `KochCurve` both have two copies in different folders.

No maps need to be built. No concepts are missing. The skeleton is complete; the sequence needs instruments, not bones.
