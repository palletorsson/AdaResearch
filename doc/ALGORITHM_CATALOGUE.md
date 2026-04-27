# Algorithm Catalogue

> The substrate's vocabulary. Around eighty algorithms across thirteen families,
> annotated with the channels they write to, the compute cost they ask for,
> the spine sequences they fit, and what they pair well with. Living document —
> add rows when new algorithms appear, edit rows as understanding shifts.

This catalogue is the registry the **map recipe language** queries. A recipe like
*"give me a folding-family algorithm for the floor at compute-budget level 2,
paired with a body-channel grammar dress"* must resolve to specific rows here.

Companion docs:
- `doc/EDGES_OF_ALGORITHM.md` — the thirteen edges the late spine teaches
- `doc/EDGES_OF_ALGORITHM_VISUAL_SEEDS.md` — moodboards per edge (to be written)

---

## Schema

Each row carries:

| Column | Meaning |
|---|---|
| `name` | canonical snake_case identifier |
| `channels` | substrate channels written to: `color` / `visibility` / `transform` / `glyph` (subdivision) / `part` (role-tag) / `mechanism` / `particle` / `body` |
| `cost` | 1–5 estimate. 1 = trivial constant per cube. 5 = continuous simulation |
| `status` | `shipped` (in `commons/grid/mutators/`) / `scoped` (designed, not implemented) / `aspirational` (needs design) |
| `seq` | spine sequences this naturally fits (CSV abbreviated) |
| `pairs` | algorithms it composes well with |
| `notes` | one-sentence summary or reference |

---

## The foundational eight

Eight roots that, when combined, produce most of the eighty variants. Build
these first; everything else is mostly cousin/pairing/compose.

| name | family | why foundational |
|---|---|---|
| `l_system` | 1 spatial | every branching morphology fits in this; flowers, plants, corals, mineral dendrites, blood vessels |
| `voronoi` | 1 spatial | every cellular packing reduces to this; brain coral, soap bubbles, shattered glass, floor mosaic |
| `reaction_diffusion` | 1 spatial | the only known model of biological pattern emergence (Turing); brain coral folds, animal coats, fingerprints |
| `wave_function_collapse` | 2 path | the only general-purpose constraint-respecting layout algorithm we have; produces most labyrinths, towns, brick walls |
| `folding` | 5 fold | the project's deepest verb (the F edge); everything else is a special case |
| `mechanism` | 7 mech | wheels, axles, pulleys — without these, the maps are static; with them, machines |
| `body_wearable` | 10 body | the parallel substrate — the avatar as second-site for algorithmic dressing |
| `decay` | 9 time | every other algorithm needs to know how to age; without decay, nothing has history |

These eight cover the catalogue's structural / topological / temporal /
embodied / mechanical axes. **Implement the eight first, then add cousins on
demand.**

---

## Family 1 — Spatial structure (make-the-shape)

Produce a single object from a rule.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `radial_symmetry` | visibility, transform | 1 | shipped (rings) | symmetry, fractals, mosaicanalysis | `tessellation_hex` | n-fold rotation around a vertical axis |
| `log_spiral` | transform, visibility | 2 | aspirational | mosaicanalysis, biological_growth | `radial_symmetry`, `fibonacci_swirl` | ammonites, sunflower seed heads |
| `l_system` | visibility, transform | 3 | aspirational | lsystems, biological_growth, fractals | `voronoi`, `reaction_diffusion` | F1 root |
| `l_system_branching` | visibility | 3 | aspirational | lsystems, fractals | `l_system` | branching subset of L-systems with named axiom + replacement rules |
| `rhizome` | visibility | 3 | aspirational | biological_growth, criticalalgorithms | `l_system_branching`, `seeking_self_branching` | non-rooted distributed branching; Deleuze-Guattari resonance |
| `double_branches` | visibility | 2 | aspirational | fractals, lsystems | `l_system_branching` | dichotomous branching (Y-shape recursion) |
| `seeking_self_branching` | visibility, part | 3 | aspirational | criticalalgorithms, biological_growth | `rhizome` | self-modifying branching that responds to its own state |
| `voronoi_round` | visibility, color | 3 | aspirational | mosaicanalysis, patterngeneration | `voronoi_straight`, `reaction_diffusion` | smooth Lloyd-relaxed voronoi (brain coral) |
| `voronoi_straight` | visibility, color | 2 | aspirational | mosaicanalysis, patterngeneration | `voronoi_round` | classical straight-edge voronoi (cracked tile) |
| `tessellation_hex` | visibility | 1 | aspirational | mosaicanalysis, symmetry | `radial_symmetry` | regular hexagonal tiling |
| `tessellation_tri` | visibility | 1 | aspirational | mosaicanalysis, symmetry | — | triangular tiling |
| `reaction_diffusion` | visibility, color | 4 | aspirational | morphogenesis, biological_growth | `voronoi_round` | F1 root; Turing 1952; brain coral, animal stripes |
| `crystallisation` | visibility, transform | 3 | aspirational | morphogenesis, isosurfaces | `reaction_diffusion` | dendritic snowflake / mineral growth |
| `radiolaria` | visibility, transform | 3 | aspirational | mosaicanalysis, fractals | `tessellation_hex`, `radial_symmetry` | geodesic micro-skeletons (Haeckel signature) |
| `sphere_variants` | visibility | 1 | aspirational | primitives | — | UV-sphere, ico-sphere, fibonacci-sphere variants |
| `ca_shells` | visibility | 2 | shipped (rule_30) | cellularautomata | `tessellation_hex` | 1D and 2D CA evolved on a cylindrical/spherical surface |
| `knot_theory` | visibility, transform | 3 | aspirational | higher_dimensions, fold_system | `folding` | trefoils, Möbius, prime knots up to 8 crossings |
| `fibonacci_swirl` | transform | 2 | aspirational | mosaicanalysis, biological_growth | `log_spiral`, `radial_symmetry` | phyllotaxis (137.5° rotation per element) |
| `sine_form` | transform | 1 | aspirational | forces, particles | `snake_sine_fold` | simple sinusoid driving any axis |
| `snake_sine_fold` | transform, visibility | 2 | aspirational | forces, fold_system | `sine_form`, `folding` | meandering sinusoid with amplitude variation |

---

## Family 2 — Path & topology (make-the-route)

Produce a route through a thing.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `labyrinth_making` | visibility, part | 3 | aspirational | searchpathfinding, criticalalgorithms | `wave_function_collapse` | recursive backtracker / Prim / Eller |
| `pathfinding_bfs` | visibility | 2 | shipped (bfs_frontier) | searchpathfinding | `pathfinding_astar` | breadth-first, frontier-by-step |
| `pathfinding_astar` | visibility | 3 | aspirational | searchpathfinding | `pathfinding_bfs` | heuristic-guided shortest path |
| `pathfinding_dijkstra` | visibility, color | 3 | aspirational | searchpathfinding, graphtheory | `pathfinding_astar` | weighted shortest path; colours by distance |
| `wave_function_collapse` | visibility, part | 4 | aspirational | proceduralgeneration, patterngeneration | `labyrinth_making`, `tessellation_hex` | F2 root; constraint-respecting tile layout |
| `ascending_stairs` | visibility, transform | 2 | aspirational | bodyprogression | `descending_stairs` | algorithm that places stair geometry up to a height target |
| `descending_stairs` | visibility, transform | 2 | aspirational | bodyprogression | `ascending_stairs` | mirror of above |
| `stairs_platforms` | visibility | 2 | aspirational | bodyprogression | `ascending_stairs` | platform-and-rise grammar (vertical maze) |
| `ant_nest_caves` | visibility, particle | 4 | aspirational | swarmintelligence, biological_growth | `wave_function_collapse` | erosion-style cavity-grower |

---

## Family 3 — Noise / randomness / scatter (make-the-distribution)

Fill space with stochastic placements.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `box_noise` | color, visibility | 1 | aspirational | noise, randomness | `threshold_boolean_cuts` | uniform integer noise per cube |
| `threshold_boolean_cuts` | visibility | 1 | aspirational | noise | `box_noise` | noise > threshold → visible; otherwise hidden |
| `crackle` | visibility, color | 2 | aspirational | noise, criticalalgorithms | `voronoi_straight` | high-frequency fracture noise (cellular noise variant) |
| `randomness_string` | glyph, color | 2 | aspirational | randomness | `string_combinations` | random-walk string of cubes |
| `string_combinations` | visibility, transform | 2 | aspirational | randomness, lsystems | `randomness_string` | combinatorial generation of short cube-strings |
| `scatter` | visibility, particle | 1 | aspirational | randomness | `feather_overlay_arrays` | poisson-disk or uniform random placement |
| `feather_overlay_arrays` | color, glyph | 2 | aspirational | mosaicanalysis | `scatter` | layered scatter at multiple scales (feather barbs) |
| `random_walk_dispersion` | particle, transform | 2 | aspirational | randomness, particles | `scatter` | the ladybugs on the Codex cover; brownian-style scatter from a centre |

---

## Family 4 — Boolean / CSG / combinatorial (combine-shapes)

Operate on existing shapes to make new ones.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `boolean_arch` | visibility | 2 | aspirational | computationalgeometry | `boolean_cuts` | curved-boundary boolean operations |
| `boolean_cuts` | visibility | 2 | aspirational | computationalgeometry | `threshold_boolean_cuts` | planar / cylindrical / spherical cut |
| `boolean_arrays` | visibility | 2 | aspirational | computationalgeometry, mosaicanalysis | `element_repeat` | array of boolean operations along an axis |
| `primitive_combinations` | visibility | 2 | shipped (composition) | primitives | `combination_form` | union / intersection / difference of substrate primitives |
| `combination_form` | visibility, transform | 2 | aspirational | primitives | `primitive_combinations` | hand-crafted form composed of named primitives |
| `enkla_maskiner` | mechanism | 2 | aspirational | forces, primitives | `single_axis_rotation` | Swedish "simple machines": lever / pulley / wedge / inclined plane / screw / wheel-axle |
| `illustrated_graphs` | visibility, color | 2 | aspirational | graphtheory | `pathfinding_dijkstra` | nodes-and-edges drawn as substrate primitives |
| `first_principal_examples` | visibility | 1 | aspirational | primitives | — | a tiny "Hello World" instance of any algorithm; pedagogical exemplar |

---

## Family 5 — Folding / morphing (change-the-shape)

Transform an existing shape over time.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `folding` | transform, visibility | 3 | aspirational | fold_system, qfeplaboratory | `sharp_fold`, `smooth_fold` | F5 root; the F edge; abstract recursive transformation |
| `sharp_fold` | transform | 2 | aspirational | fold_system | `folding` | crease-based folding (origami) |
| `smooth_fold` | transform | 3 | aspirational | fold_system, biological_growth | `folding` | continuous-curvature folding (cloth, leaves) |
| `morph` | transform, visibility | 3 | aspirational | morphogenesis, fold_system | `merge` | A → B interpolation over time |
| `merge` | visibility, part | 2 | aspirational | morphogenesis | `morph` | two regions becoming one part |
| `bulge` | transform | 1 | aspirational | particles, softbodies | `twist` | local radial expansion |
| `twist` | transform | 1 | aspirational | forces | `bulge` | rotation along an axis with displacement |
| `drip` | particle, decay | 3 | aspirational | particles, decay | `softbody` | gravity-driven viscous extension downward |
| `mould_fill` | visibility, decay | 3 | aspirational | biological_growth, decay | `drip` | spreading-fungal-fill over surface |
| `gradient_filter_morph` | visibility, color | 2 | aspirational | morphogenesis | `morph` | apply a gradient-based filter to a shape's surface |

---

## Family 6 — Repeats / arrays / fields (make-density)

Fill space with smart copies. *This is the glyph channel's home territory.*

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `element_repeat` | glyph, visibility | 1 | scoped | mosaicanalysis, patterngeneration | `pip_system` | strict periodic repetition |
| `pip_system` | glyph, color | 1 | scoped | patterngeneration | `element_repeat` | small repeated marks (dots, dashes, glyph-pips) |
| `space_filling` | glyph, visibility | 2 | scoped | patterngeneration, fractals | `pip_system` | density-target placement (Hilbert / Peano curve cousins) |
| `overlay_pattern` | color, glyph | 2 | scoped | mosaicanalysis | `feather_overlay_arrays` | composited pattern layers at varying alpha |
| `expanding_water_edges` | visibility, decay | 2 | aspirational | particles, decay | `mould_fill` | progressive growth from a contour outward |
| `pattern_from_base_rule` | glyph, visibility | 2 | scoped | patterngeneration | `combination_of_themes` | recipe-like: pattern emerges from one or two base rules + a transform |

---

## Family 7 — Mechanisms / machines (make-it-move)

Animate structure as machine. **New channel: `mechanism`.**

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `single_axis_rotation` | mechanism, transform | 2 | scoped | forces, primitives | `complex_rotation` | F7 root; constant-speed rotation around one axis |
| `complex_rotation` | mechanism, transform | 3 | scoped | forces | `single_axis_rotation` | gimbal / nutation / multi-axis combined |
| `wheel_machine` | mechanism, transform | 3 | scoped | forces | `single_axis_rotation` | wheel + axle + ground contact; rolls |
| `enkla_maskiner_combo` | mechanism | 3 | scoped | forces, primitives | `enkla_maskiner` | named compositions of simple machines (block-and-tackle, etc.) |
| `sweet_violence_machine` | mechanism, particle | 4 | aspirational | criticalalgorithms | `enkla_maskiner_combo` | Bataille-cousin: a machine whose product is *violence delivered tenderly*; teaching object for L (failure) and J (training-fossil) |
| `glassware_mechanism` | mechanism, visibility | 3 | aspirational | criticalalgorithms | `wheel_machine` | Glashauseffekte — fragile transparent machinery, the lab object |

---

## Family 8 — Particle / physics / soft (make-it-act)

Continuous-time simulation off the cube grid. **New channel: `particle`.**

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `particle_system` | particle | 3 | scoped | particles | `flocking` | base particle emitter + integrator |
| `water_simulation` | particle, visibility | 5 | aspirational | physicssimulation | `softbody` | SPH or grid-based fluid |
| `softbody` | particle, transform | 4 | scoped | softbodies | `water_simulation` | mass-spring or PBD soft body |
| `flocking` | particle | 3 | aspirational | swarmintelligence | `particle_system` | Reynolds boids (separation / alignment / cohesion) |
| `physical_process` | particle, mechanism | 3 | aspirational | physicssimulation | `softbody` | generic rigid-body integrator |
| `lift_and_decay` | particle, decay | 2 | aspirational | particles, decay | `decay_uniform` | rise + fade-out per particle |
| `rolling_physics` | particle, mechanism | 3 | aspirational | forces | `wheel_machine` | sphere/cube rolling under gravity on a surface |
| `explosion` | particle, mechanism | 3 | aspirational | particles | `rolling_physics` | impulse-emission radial scatter with secondary particles |

---

## Family 9 — Decay / time (let-it-go) — *modifier, not standalone*

Decay is a temporal modifier applied to expressions in any other family. The
"channel" it modifies is *whatever* channel the host expression writes to,
attenuated over time.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `decay_uniform` | (any) | 1 | scoped | decay (all) | — | global multiplier on a channel's intensity decreasing over t |
| `drip_decay` | (any) | 2 | aspirational | decay | `drip` | downward-biased decay (gravity stains) |
| `pixel_eating_decay` | visibility, color | 2 | aspirational | decay, criticalalgorithms | `crackle` | edge-eroding decay (8-bit aesthetic for cultural commentary) |
| `water_edge_expansion_decay` | visibility | 2 | aspirational | decay | `mould_fill` | wet-edge / coffee-stain advancing front |
| `mould_decay` | visibility, color | 3 | aspirational | decay, biological_growth | `mould_fill` | fractal spread at a slow rate |

---

## Family 10 — Body wearables (algorithms-on-bodies)

Mounted on the player's avatar, not in the room. **New channel: `body`.** This
family needs its own *body-substrate* — same shape as the floor-substrate
(GridMutatorBase) but rigged to the avatar.

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `body_gadget` | body | 2 | aspirational | bodyprogression, joints | — | small wearable artifact mounted to a named body part |
| `queer_dress` | body, glyph | 3 | aspirational | criticalalgorithms, qfeplaboratory | `morphology_dress` | wearable that *refuses* the body's authorised silhouette; G (opacity refusal) made literal |
| `morphology_dress` | body, transform | 3 | aspirational | morphogenesis, fold_system | `grammar_dress` | reshapes the avatar's outline using `morph` / `bulge` |
| `grammar_dress` | body, glyph | 3 | aspirational | grammar_systems, qfeplaboratory | `morphology_dress` | generates ornament from a grammatical rule (L-system on the body) |
| `scaling_binding` | body, transform | 2 | aspirational | bodyprogression | — | how a wearable scales with avatar size; technique not algorithm |
| `vr_hand_extension` | body, mechanism | 3 | aspirational | bodyprogression | `body_gadget` | hand becomes claw / pen / shears / tentacle |
| `waged_body_extension` | body, glyph | 3 | aspirational | criticalalgorithms, postfoundationscrisis | `queer_dress` | "waged" = labour-marked; visualises the labour the body has performed |
| `half_body_morph` | body, transform | 3 | aspirational | morphogenesis | `morphology_dress` | bilateral asymmetry as wearable |

---

## Family 11 — Visual filters (output-treatment)

Operate after rendering, on the image / material. **Lives at the shader layer.**

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `visual_spectrum_filter` | (shader) | 1 | aspirational | color | — | constrain output to a palette range |
| `flow_icon_render` | (shader) | 2 | aspirational | proceduralaudio, particles | — | render flow direction as small arrow icons on surfaces |
| `outline_silhouette` | (shader) | 1 | aspirational | gallery, criticalalgorithms | — | edge-detection rim on objects (Codex-cousin line work) |
| `gradient_on_mesh` | (shader) | 1 | shipped (color gradients) | color | — | gradient applied across mesh UVs |
| `crackling_filter` | (shader) | 2 | aspirational | decay, criticalalgorithms | `crackle` | crinkled-paper post-process |
| `pixel_decay_filter` | (shader) | 2 | aspirational | decay | `pixel_eating_decay` | low-res pixelation increasing over time |

---

## Family 12 — Composition / staging (arrange-everything)

The map-recipe layer. *Not a channel — a grammar that arranges all the others.*

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `compassion_staging` | (composition) | — | aspirational | postfoundationscrisis | — | choreographed scenes of care / refusal / repair |
| `combination_of_themes` | (composition) | — | aspirational | gallery, qfeplaboratory | — | a recipe drawing from multiple sequence vocabularies |
| `playground_grammar` | (composition) | — | aspirational | bodyprogression | — | rule for arranging interactive structures (climb / hide / reveal) |
| `divide_and_conquer_space` | (composition) | — | aspirational | computationalgeometry | — | binary-space-partition layout for maps |
| `temporal_to_spatial_circle` | (composition) | — | aspirational | qfeplaboratory, fold_system | — | carousel layout — cyclic time as place |
| `temporal_to_spatial_strip` | (composition) | — | aspirational | sequence_index, gallery | — | linear time as horizontal strip of panels |
| `temporal_to_spatial_spiral` | (composition) | — | aspirational | mosaicanalysis | — | logarithmic time as spiral |
| `centerpiece_flank_layout` | (composition) | — | aspirational | (all) | — | the Haeckel composition: big specimen middle, smaller flanking |
| `frame_in_frame_layout` | (composition) | — | aspirational | gallery, qfeplaboratory | — | nested panels (Codex pages-within-pages) |
| `plate_taxonomy_layout` | (composition) | — | aspirational | mosaicanalysis, biological_growth | — | 3×3 or 4×3 grid of pedestals on a backing wall |

---

## Family 13 — Part-grammar (name-the-parts)

Produce *positions with names*. Every cube knows what it is. **New channel: `part`.**

| name | channels | cost | status | seq | pairs | notes |
|---|---|---|---|---|---|---|
| `flower_grammar` | part, visibility | 2 | aspirational | flowers, biological_growth | `l_system_branching` | sepals (protective outer) / petals (attract pollinators) / stamens (pollen) / pistil (ovules) |
| `insect_grammar` | part, transform | 2 | aspirational | biological_growth, joints | `flower_grammar` | head (sense + feed) / thorax (locomotion) / abdomen (digest + reproduce) |
| `bird_grammar` | part, transform | 3 | aspirational | biological_growth | `insect_grammar` | 23-region taxonomy: Beak, Iris, Pupil, Mantle, Lesser coverts, Scapulars, Coverts, Tertials, Rump, Primaries, Vent, Thigh, Tibio-tarsal articulation, Tarsus, Feet, Tibia, Belly, Flanks, Breast, Throat, Wattle, Eyestripe, Head |
| `human_grammar` | part, body | 3 | aspirational | bodyprogression, joints | `bird_grammar` | head / torso / limbs / joints / digits with nested sub-parts |
| `molecular_grammar` | part, visibility | 3 | aspirational | higher_dimensions | — | residues / side-chains / backbones (proteins, polymers) |
| `tooled_object_grammar` | part, mechanism | 2 | aspirational | primitives, forces | `enkla_maskiner` | handle / ferrule / blade / tang (anatomical decomposition of made things) |

Distinguishing feature: once a cube carries a role tag, *every other channel*
can read it. Color paints by role. Visibility hides by role. Labels follow a
named region across morphs. Subdivision intensifies per role. Decay acts
per role. **The part channel is what connects the substrate to the Codex
Seraphinianus's labelled-diagram tradition.**

---

## Channel coverage summary

| Channel | Status | Algorithms writing to it (at full build) |
|---|---|---|
| `color` | shipped | ~15 |
| `visibility` | shipped | ~40 |
| `transform` | shipped | ~25 |
| `glyph` (subdivision) | scoped | ~10 |
| `part` (role-tag) | scoped | ~6 |
| `mechanism` | scoped | ~10 |
| `particle` | scoped | ~10 |
| `body` | scoped | ~8 |

---

## Status overview

| status | count | meaning |
|---|---|---|
| `shipped` | ~6 | already in `commons/grid/mutators/` |
| `scoped` | ~25 | channels designed, expressions queued |
| `aspirational` | ~50 | needs design + implementation |

---

## How to use this catalogue

### As a query target

The recipe language (still to be written) compiles map recipes by querying
this catalogue:

```
SELECT name, channels, cost
FROM catalogue
WHERE family = 'spatial_structure'
  AND cost <= 2
  AND seq CONTAINS 'mosaicanalysis'
  AND status IN ('shipped', 'scoped')
```

### As a design checklist

When designing a late-spine map, walk the families top to bottom and ask
*does this map want one of these?* The answer is usually yes for 4–6 families
and no for the rest. The yeses become the recipe.

### As a coverage report

Each spine sequence has a known set of expected algorithms. We can audit
which sequences are over- or under-served by the catalogue. Auditing is
out of scope for this initial doc; a future `tools/catalogue_audit.py`
will produce coverage reports.

---

## Compute-budget heuristics

Per-map cap should hold:

- ≤ 1500 cubes total at level-0 (12×8×12 = 1152 + headroom)
- subdivisions add ≤ 4× over base (so ≤ 6000 cubes effective)
- one mechanism + one particle channel maximum per map
- decay modifier is free (it's a multiplier on existing channels)

If a recipe exceeds budget, the recipe compiler swaps heavy algorithms for
lighter cousins from the same family. `voronoi_round` (cost 3) → `voronoi_straight`
(cost 2). `water_simulation` (cost 5) → `lift_and_decay` (cost 2).

---

## Status as of 2026-04-27

- ~6 shipped, ~25 scoped, ~50 aspirational
- 4 channels live, 4 channels scoped
- The foundational eight are roots; build them next

This document is the spine of the recipe language. Edit freely as understanding shifts.

*Started 2026-04-27. Companion to `doc/EDGES_OF_ALGORITHM.md` and
`doc/EDGES_OF_ALGORITHM_VISUAL_SEEDS.md` (forthcoming).*
