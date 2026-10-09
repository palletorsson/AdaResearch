# Patterns and shaders: what a rule lets happen

> Current requirements and teaching order: [Patterns: the room wears what we make](patterns-room-body-shaders-2026-09-10.md). The source audit below remains useful; the newer plan requires hall controls, deliberate hand input, multiple carrier forms and a closing shader/fabric studio.

Planning draft · 9 September 2026 · grounded in the current project sources

Companion proposal: [The pattern machine dresses the body and the room](patterns-dream-dressing-2026-09-09.md), connecting dream DNA sculptures, interior surfaces, automatic scores and controlled material experiments with drag, fetish and desire.

## The argument

**A pattern makes some differences repeatable. A shader gives us another way to construct, inspect and disturb that repetition.** The sequence should let the visitor discover what the rule preserves, what it changes, and what it cannot carry.

Colour has made appearance relational. Transformation has shown that changing position, orientation or scale changes what a body can do. Patterns bring a further question: **what happens when a transformation becomes a rule for many places?** Shaders then let us ask where that rule operates: on objects, on coordinates, on the appearance of a surface, on vertices, or on a state carried from one moment to the next.

The red thread is:

> Make a difference → repeat it → find its address → shape a boundary → transform the address → classify what survives → encounter the sampling limit → author another possibility.

The visitor carries one small, asymmetric motif through this route. An off-centre mark makes a reflection or rotation visible; a centred circle often conceals the operation. The motif is a companion whose changing conditions can be compared. It is not an original whose later encodings are necessarily losses.

The critical question stays close to each experiment: **which differences does this operation preserve, erase, or make newly possible—and for whom?** Unexpected arrangements can support orientation, shelter, visibility or play. Irregularity is not automatically freedom, symmetry is not automatically oppression, and an extravagant material is not queer simply because it is pink or shiny.

## What we actually have

The active `tiling` sequence contains four authored rooms and three recently consolidated ribbon collections. The separate `patterngeneration` sequence has 25 map files and is outside the live spine. Twelve shader lesson scenes and their scripts exist; all twelve currently have `map_ready: false` in the registry. These are substantial source material, but not twelve verified museum lessons.

| Material | What can carry the plan | What needs care |
|---|---|---|
| `Tutorial_Pattern`, `Array_Patterns`, `Pattern_Foundry` | Editable motifs, repeated tiles, pattern machines and a working CPU/GPU tiling choice | Overlapping collections need distinct questions and selected primary configurations |
| `Symmetry_Seventeen` | Wallpaper editors, looms, mills and galleries | Begin with operations on a motif; reveal the classification afterward |
| `pattern_maker_station` | Paint a small grid, choose a palette, rotate/flip, select wallpaper groups, repeat on a floor | Its CPU fallback makes a texture on the same plane; it is not a physical tile array |
| Shader lessons 01–05 | Coordinates/colour, thresholds, distance shapes, coordinate transforms and repetition | Adapt gallery rows into focused experiments; check controls and safe parameter ranges |
| Shader lessons 06–09 | Randomness, noise, nearest-cell fields and layered noise | Better as later returns with explicit prerequisites |
| Shader lesson 10 | A reaction-diffusion shader and a branching visual shader | The host does not establish the persistent feedback needed for reaction-diffusion; branching appearance is not particle aggregation |
| Shader lessons 11–12 | A rich stock of material appearances and animated specimens | Current showcases need learner controls and comparisons; advanced ingredients cannot silently become beginner prerequisites |
| `Ribbon_Patterns_01…03` | Repeated structures, sampling comparisons, signals and glitches | Treat as optional collections, not three completed compulsory lessons |

Three specific claims must be repaired before they teach: the Penrose-named map currently places `koch_curve`; the Wang map places `env_one`; and `patterns_wang.gdshader` hashes each tile's edges independently, so neighbouring edge agreement is not guaranteed. Even a corrected matching rule would not by itself prove aperiodicity. Several other legacy galleries use `floor_plan_space` placeholders.

Keep the existing sequence keys for now. This proposal is a **teaching route of twelve encounters**, not an instruction to add twelve rooms to the museum or activate all legacy shader maps. Use existing rooms wherever they can hold the argument. Decide the final sequence boundary after the first pilot.

## The foundation route

The first three encounters are a pilot. The remaining encounters extend the same motif and controls. Each has at most two primary artifacts or proposed artifact configurations; secondary exhibits remain available when they add something specific.

| # | Encounter and candidate room | Primary material | What the visitor discovers |
|---|---|---|---|
| 1 | **One mark, many consequences** · `Tutorial_Pattern` | `pattern_maker_station`, initially restricted to translation | Editing one source cell changes a field of occurrences |
| 2 | **What counts as the same?** · `Array_Patterns` | `pattern_tile_4x4` and `pattern_tile_mirror`, adapted to compare the same motif | Translation preserves handedness; reflection changes it |
| 3 | **The floor has more than one construction** · `Pattern_Foundry` | `pattern_maker_station` + proposed physical-tile comparator | Repeated objects and a patterned surface can resemble each other while behaving differently |
| 4 | **Where does the colour come from?** · `Shader_02_Colors` | Selected gradient demo + proposed sample probe | A surface address becomes an input to a colour rule |
| 5 | **How wide is an edge?** · `Shader_01_Shaping` | Selected step/smoothstep comparison | A boundary is a decision whose threshold and transition width can be changed |
| 6 | **A circle that is not a hole** · `Shader_03_Shapes` | Selected circle-distance demo + proposed physical aperture comparison | A shape in a fragment shader does not automatically change collision |
| 7 | **Move the question** · `Shader_04_Matrices` | Selected translation/rotation comparison | Transforming sample coordinates moves the pattern without moving the supporting object |
| 8 | **The address starts again** · `Shader_05_Patterns` | Selected classic repetition demo | `fract` repeats local coordinates; `floor` retains which cell we are in |
| 9 | **What survives the move?** · `Symmetry_Seventeen` | `vr_tile_editor` + `wall_pattern_gallery`, curated configurations | A symmetry is an operation that leaves the complete pattern unchanged |
| 10 | **The pattern outruns the image** · candidate `Shader_Arch_Gallery`, or a new small encounter | Proposed sampling/seam rig | The rule, surface mapping and displayed samples have different limits |
| 11 | **Looks soft, stands firm** · `Shader_11_QueerRubber` | Adapted material/body comparison | Shading, visible deformation and bodily support are separate operations |
| 12 | **Make a rule hospitable to something else** · `Shader_12_PinkExtravaganza` | Proposed editable recipe station using studied ingredients | Changing a convention can enable one use while making another harder |

### 1–3. Start with a pattern the visitor made

In `Tutorial_Pattern`, begin with a four-by-four source cell and an off-centre mark. Let the visitor change it before explaining the representation. Ask them to predict where the next change will appear. Show one source-cell boundary, then offer the full lattice. Keep the editor's other wallpaper groups available later; the opening argument needs only translation.

In `Array_Patterns`, put two versions of that motif alongside one another. Change only the placement operation. A hand, hook or letter-like mark lets reflection become unmistakable. The source cell and the rendered occurrences must be distinguishable: changing the shared source is different from giving one occurrence a local exception. That exception control is proposed work, not a capability to promise in prose yet.

In `Pattern_Foundry`, place the same motif in discrete tiles and on a shader floor. Let a visitor inspect the edge and try a supported physical interaction with the tiles. The existing CPU texture path can be a third, secondary comparison. Keep the viewpoint, motif and scale comparable. The lesson is not that one is real and the others fake: **each construction offers a different set of operations**. The physical comparator must be built or adapted and tested before this becomes a book claim.

**Pilot acceptance:** a new visitor can change the motif, distinguish translation from reflection, and describe one observable difference between the physical arrangement and the shader surface. The same saved motif survives all three encounters.

### 4–6. Coordinates, decisions and surfaces

Carry the colour sequence forward through a single gradient, rather than another RGB catalogue. A probe identifies the surface coordinate being sampled. Compare the same material on a plane and a bent or differently mapped surface only after the plane is understood. Introduce UV as a surface address; do not equate it with world position.

Now move a threshold through that gradient. Begin with `step`; introduce a transition width with `smoothstep`. The visitor should see the difference before being given the function names. Zero-width and inverted-edge controls need defined behavior; do not expose accidental undefined results as a mathematical discovery. Later, inspect what a softened edge preserves and conceals.

The circle encounter asks a more bodily question. A distance-based coloured circle can look like an opening, but it remains on its supporting geometry. Compare it with an actual opening. If an alpha cutout or discarded fragment is introduced, test collision separately. Provide a safe way to probe the distinction with a held object or pointer before inviting bodily passage.

**Acceptance:** the visitor can locate a sample, change a boundary intentionally, and predict which apparent opening supports passage. A code excerpt describes the implemented operation, not an imagined interaction.

### 7–9. Transform the address, then recognize the rule

Reconnect directly to the transformation halls. Move a panel in world space; then leave it still and change where its material samples the motif. For the current translation shader, subtracting an offset from the query coordinates shifts the displayed feature toward that offset. Let the visitor establish the direction experimentally. Then compare rotation around different centres and the effect of operation order.

Repetition becomes a small piece of readable code. The following is a proposed teaching fragment, not a claim that the entire experiment is already implemented:

```glsl
vec2 address = UV * repeats;
vec2 cell = floor(address);
vec2 local = fract(address);
```

At an integer boundary, the local address returns to zero while the cell address advances. The student can use `local` to repeat a motif and `cell` to make an exception. First move a phase control by hand; later let a local elapsed-time parameter drive it. Reset that experiment's phase, not the global game clock. Arrival is already partway through the running museum.

Only now ask what leaves the whole pattern unchanged. Use an asymmetric motif and compare translation, reflection, rotation and glide reflection. Three or four clear comparisons can lead into the atlas. Seventeen is the classification of periodic plane symmetry groups under the relevant Euclidean assumptions; it is not a census of every possible pattern or difference. A finite framed sample also has edges that the ideal infinite pattern does not.

**Acceptance:** a visitor can predict a coordinate transformation, explain the difference between cell identity and local address, and test one proposed symmetry on an unfamiliar motif.

### 10–12. Find a remainder and work with it

Build one controlled sampling experiment. Increase repetition, change viewing distance and inspect a magnified portion of the rendered result. Introduce a UV seam separately from insufficient image sampling: they have different causes. Compare a hard boundary with a footprint-aware transition after the artifact makes that distinction visible. A local low-resolution display or a deliberately slower local update can make the budget inspectable without slowing XR tracking or the whole museum.

The material comparison then separates a soft-looking highlight, an actual change in visible geometry, and a change in collision or physical response. Use the same specimen and lighting for the first comparison. Existing latex, leather and other shaders provide appearances; they do not establish softness to the hand. Vertex displacement can change the visible surface without updating its collision representation. Make each enabled channel explicit in the experiment.

End with an authored use, not a demand for maximum distortion. For example: make a repeated surface that helps a visitor find an entrance but gives someone resting nearby visual shelter; or create one persistent exception that lets a person orient within a repeated field. Compare before and after. Preserve one practical requirement while changing another convention. Let the visitor save the recipe, its code and one unresolved consequence. The existing extravagant gallery becomes a secondary invitation to later techniques, not a requirement to understand noise, optics and feedback all at once.

**Acceptance:** the visitor can identify a sampling or representation limit, deliberately change a rule, and explain both a new possibility and a consequence for another use. Success can include a productive unresolved result.

## Later returns: uncertainty, neighbours and memory

The current legacy prerequisite of `randomness` is too broad for introductory coordinates and thresholds. Keep advanced topics in return paths, entered when their actual prerequisites have been encountered.

| Return | Existing source | Prerequisites and experiment | Condition before teaching |
|---|---|---|---|
| Seeded difference | `Shader_06_Random` | Cell identity and functions; compare a fixed seed with a changing input | Reproduce a saved pattern; distinguish deterministic pseudorandom output from a changing time input |
| Neighbouring differences | `Shader_07_Noise` | Randomness and interpolation; compare independent samples with correlated variation | One controlled comparison, not a gallery of names; retain the same range and scale |
| Territory | `Shader_08_CellularNoise` | Distance and nearest neighbours; move sites and watch ownership change | Name the metric and tie behavior; do not label every nearest-distance difference an exact distance to an edge |
| Many scales | `Shader_09_FBM` | Noise, frequency, amplitude and sampling; add one octave at a time | Describe the finite layered construction and measure its cost; avoid claims of infinite detail |
| A pattern with a past | `Shader_10_ReactionDiffusion` | Arrays, neighbours and numerical time steps | Initialize state; implement distinct read/write buffers, reset and stable updates; separate simulation data from display colour |
| Similar growth, different process | `dla_visual.gdshader` plus a verified aggregation implementation | Stochastic motion, contact and accumulated state | Label the existing shader as a branching appearance; compare with actual walkers and sticking only after that simulation exists |
| Local rules and nonperiodic order | Wang/Penrose material | Tiling constraints and periodicity | Replace wrong/placeholder artifacts; demonstrate shared-edge compatibility separately from aperiodicity |

Do not treat visually complicated output as evidence of higher formal entropy. A later QFEP connection must name the relevant state, probability model or distribution, observation scale and measure. Here we can establish the questions and collect cases without pre-empting that work.

Narrative generation, typography and general pixel-art collections remain elective or belong elsewhere. They can return when their actual algorithms advance the argument.

## Space, roles, text and shared tools

Use a legible demonstration bay inside the museum: a margin at the same level as the experiment, a clear entrance and exit, a place for a group to stand, and a side-mounted control/probe display. Reserve pits for an argument that needs a gap. A shader floor should not acquire a dangerous spatial claim just because the museum has a standard pit layout.

The three ribbon halls remain owned by patterns. Use their stock selectively: structure from 01, colour/sample comparisons from 02, signal and glitch examples from 03. Retain deliberate recurrence when the configuration and question change. Remove duplicates only after comparing those roles. Existing strong text and useful secondary artifacts are assets to preserve.

Build four reusable capabilities rather than a different interface for every lesson:

1. **A saved motif and recipe.** A small palette-index grid, palette, symmetry, phase and coordinate policy, with a version and source reference. Keep baseline and visitor variant. A room must be able to reconstruct the recipe without a hidden dependency on the previous room's scene tree.
2. **A specimen comparison.** Apply the same recipe to physical tiles, a baked texture and a shader where meaningful. Match scale and viewing conditions; explicitly record where equivalence ends. The CPU image fallback already exists, the geometric comparison does not.
3. **A sample probe.** Show surface address, local/cell address and the relevant computed value in a small casing beside the work. If values are recomputed on the CPU, label them as function values, not measured final framebuffer colours. Avoid continuous GPU readback just to populate a label.
4. **A common experiment panel.** Extend `ShaderRackPanel` and the canonical `ControlPanel`: selected parameters, baseline reset, comparison toggle and delayed source reveal. Existing shader galleries show snippets immediately; discovery-first presentation needs an actual control change. Make the same operations usable with VR and desktop input.

For each encounter, one record should connect the exact primary placement/configuration to its question, observable action, source excerpt, limitation and `final.md` passage. Artifact registry membership alone cannot establish that connection. The necklace's primary filter and the book must resolve to those same placements.

Write final prose after the experiment has produced evidence. Use the existing technical and critical writing as sources; preserve its good passages. Each section should move between a specific observation and its mechanism, then reopen the question. A proposed voice test, to validate against the repeat/probe experiment:

> The mark returns before we reach the far wall. Move one square in the small panel. All its distant occurrences change with it. Which of them did we touch?
>
> The floor asks the same question at another address. `fract` keeps the part after the whole number; at each whole number, the local address begins again. Beside it, `floor` still knows which cell we crossed. We can make one cell answer differently. Repetition has not exhausted what the address can do.

## Ten tasks, in order

| Priority | Action | Depends on | Reviewable result / done when |
|---|---|---|---|
| 1 | Record the four authored pattern rooms' exact primary candidates, configurations and current behavior | — | Inventory links each claim to a placed artifact and source; no book promise relies on an untested control |
| 2 | Make a focused translation-only `pattern_maker_station` configuration and a saved motif recipe | 1 | Edit/save/reload restores the same source cell, palette and repeat settings |
| 3 | Adapt the array comparison to use that motif for translation and reflection | 2 | An asymmetric mark makes the difference observable with one controlled operation |
| 4 | Build the physical-tile versus shader-floor comparison | 2 | Same recipe and scale; physical and surface behavior can be tested safely; CPU texture available as secondary |
| 5 | Pilot encounters 1–3 and write their evidence-based `final.md` passages | 3, 4 | A solo visitor and a teacher-led group can perform the stated discoveries; book and primary placements agree |
| 6 | Add selected-demo, reset and delayed-code controls to the shared shader panel | 1 | One existing shader lesson can run with a small chosen comparison and consistent desktop/VR controls |
| 7 | Assemble the coordinate → threshold → distance → transform → repeat route | 2, 6 | Uniforms/defaults work; parameter limits are defined; each experiment passes a prediction-and-transfer check |
| 8 | Curate the symmetry room and build the sampling/seam comparison | 7 | A visitor distinguishes symmetry, a mapping seam and undersampling; later code explains each separately |
| 9 | Build the material/body comparison and one editable final recipe; complete foundation prose | 5, 8 | Appearance, geometry and collision are distinguished; a visitor can save an intentional alternative and its consequence |
| 10 | Repair or explicitly defer legacy simulation and aperiodic claims | Inventory findings; before activating affected rooms | RD has verified persistent state or remains deferred; DLA visual is labelled accurately; Wang/Penrose have correct implementations before their claims enter the book |

Task 10's inaccurate descriptions can be corrected early; implementing the advanced simulations need not delay the foundation. Tasks 2–4 are the most useful immediate build. They establish a shared object and a real comparison before committing to the entire shader route.

### Release gates

- **Pilot:** three working encounters, one carried motif, matched primary roles and text, observed solo/group use.
- **Foundation:** all twelve encounters, or an intentionally merged equivalent, with selected shaders compiling on the actual target renderer and device; no placeholder lessons. Track CPU/GPU frame time under relevant viewing conditions. Derive the frame budget from the chosen device refresh rate rather than assuming a universal number.
- **Book completion:** every required encounter has an evidenced `final.md`; transitions carry the learner's prior discoveries forward; proposed actions are not narrated as existing ones.
- **Advanced returns:** prerequisites and simulation state are verified before adding these rooms to the required spine. Keep appearance experiments available under accurate names.

No live sequence order, registry readiness flags or museum placements are changed by this planning document.

## Evidence and technical references

Local implementation anchors, relative to the repository root:

- `commons/maps/sequences/tiling.json` and `commons/maps/sequences/patterngeneration.json`: current ownership and curriculum lists. The tiling note claiming shader work does not exist is contradicted by the actual shader directories and should be refreshed during implementation.
- `commons/artifacts/pattern_maker_station/pattern_maker_station.gd`: editor, boundary choices, CPU image and GPU tiling paths.
- `commons/resourses/shaders/wallpaper_tile.gdshader` and `commons/primitives/arrays/wallpaper_groups.gd`: current tiling implementations.
- `algorithms/shaders/book_of_shaders/`: lesson hosts and shader implementations, including `patterns_wang.gdshader` and `dla_visual.gdshader`.
- `algorithms/shaders/shader_rack_panel.gd` and `commons/ui/control_panel.gd`: reusable control infrastructure.
- `commons/resourses/shaders/reaction_diffusion.gdshader`: feedback-dependent update shader; its existence alone does not establish a running feedback simulation.
- `commons/artifacts/registry/commons_artifacts.json`: artifact definitions and readiness flags.

The Book of Shaders provides useful coordinate/repetition and noise progressions, which this plan adapts into embodied comparisons: [Patterns](https://thebookofshaders.com/09/), [Noise](https://thebookofshaders.com/11/), [Fractal Brownian Motion](https://thebookofshaders.com/13/).

Implementation should follow the project's Godot version: [Godot 4.6 spatial shader stages and outputs](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html), [shader functions](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shader_functions.html), and [GPU performance considerations](https://docs.godotengine.org/en/4.6/tutorials/performance/gpu_optimization.html). Shader evaluation is not universally “once per pixel,” and not every shader is simply a stateless coordinate-to-colour function.

For the scope of the symmetry classification, use the [IUCr's seventeen plane-group diagrams](https://www.iucr.org/news/newsletter/volume-30/number-4/symmetry-diagrams-for-the-17-plane-groups-now-freely-available). If named historical tileworks enter the prose, identify particular works and their provenance; mathematical comparison should not turn distinct artistic practices into an inevitable march toward computation.
