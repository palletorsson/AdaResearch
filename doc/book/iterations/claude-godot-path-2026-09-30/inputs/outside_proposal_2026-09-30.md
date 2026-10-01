# Ada Research — a cumulative path through Godot

**Curriculum proposal · 30 September 2026**

**Repository baseline:** `palletorsson/AdaResearch`, branch `palm-scanner-door-entry`, commit `5a74c6e3064362e4a2882bfe4b6bd79a1e6b0c0a`.

**Status:** A proposed teaching architecture, not a description of a completed course. No repository files have been modified. No runtime, export, headset or learner testing has been performed for this proposal. Existing project commitments, proposed teaching additions and external Godot references are distinguished below.

## 1. What the project already gives us

The explicit sequence spine is in `commons/maps/curriculum_spine.json`; map membership is defined under `commons/maps/sequences/`. Its ordered spine currently contains:

1. primitives
2. transformation
3. array_tutorial
4. color
5. tiling
6. change
7. forces
8. formfinding
9. wavefunctions
10. randomness
11. noise
12. shaders
13. cellularautomata
14. fractals
15. lsystems
16. proceduralgeneration
17. softbodies
18. isosurfaces
19. boolean_surfaces
20. swarmintelligence
21. machinelearning
22. graphtheory
23. foundationscrisis
24. qfeplaboratory
25. postfoundationscrisis

The spine also describes a Lab hub and branches. This is a documented navigation design, not a fresh verification of runtime unlocking or return behaviour.

The teaching documents are not fully aligned. `doc/book/ARC.md` is an older 24-chapter arc, including a separate symmetry sequence and a different position for isosurfaces. The committed `primitives.json` still begins with Point_One, although the Point_Zero teaching agreement and the 30 September reading proof establish the newer Point Zero → Point One → Point Coordinates opening. `doc/book/STUDENT_TOOLBOX.md` is referenced by the Point Zero intent but was not retrievable at the pinned commit; it may exist in a working copy.

These differences should be reconciled before generating a course automatically. They are not reasons to abandon the opening already developed with the author. Old metadata descriptions are not taken here as verified mathematical, theoretical or runtime claims.

The new `Point_Lines/tutorial.md` provides an especially useful teaching precedent. It explicitly carries forward the earlier markers and callbacks, supplies a complete small script, introduces subtraction and length, uses the Remote inspector as a temporary moving hand, and names `show_between()` as a borrowed drawing helper. It distinguishes the desktop study from the museum's XR interactions.

## 2. The central proposal

**The tutorial should accumulate the learner's capacity to make, not accumulate explanations of every object encountered.**

Ada Research is the field. The museum, the encounter manuscript, the critical writing and the tutorial offer different routes through it. None needs to contain everything available in the others.

The course should lead towards this capability:

> I can construct a small world, make something happen in it, follow why it happens, change its terms, and give another person a reliable way to encounter it.

This is broader than reproducing an exhibit and narrower than mastering every Godot API.

The course has three complementary activities:

- **Encounter:** meet an object, a situation or a question in Ada.
- **Make:** construct or alter a small working example whose important parts can be understood.
- **Compose:** return to a personal project and use the operation for another purpose.

These are curriculum roles, not compulsory headings or a fixed literary pattern for every lesson. Some halls can remain contemplative visits. Others can become substantial studios spanning several sessions.

### The learner's continuing project

Start with the small Day Zero environment, not a complete clone of the museum as the novice's development assignment. Gradually turn it into an independently authored place: a small museum, garden, instrument, exploratory game, workshop or other world.

Keep earlier creations reusable as scenes, data and tools. New work should occasionally change an old object rather than always add another room. A controller can acquire a new input; a remembered line can become a path; a pattern can become a garment; a creature can receive an altered environment.

Use the Lab idea as a return to composition: after a sequence, bring something back and decide what to do with it. This learner workshop is a proposed teaching use of the hub idea, not a claim that the current Lab automatically imports students' work.

Do not require every learner to build the same museum or keep every previous experiment active in one enormous scene. The continuity belongs to capabilities and reusable work, not compulsory architectural expansion.

### Borrowing has a record

For each significant dependency, distinguish:

1. What the learner can currently operate.
2. What they have opened and understood.
3. What they can independently change or replace.

A supplied player can be operated before it is explained. The camera can be inspected before a full controller is built. The ray-picking helper can remain borrowed while coordinate relations are taught. Later lessons revisit selected dependencies when a practical question makes them worth opening.

Some dependencies remain deliberately outside the course: nobody must implement an operating system or rasterizer to understand a Godot scene. Name those boundaries rather than promising to remove all borrowing eventually.

## 3. The opening: a detailed cumulative route

The following is a proposed making progression using the revised opening agreed in the manuscript, not a claim that all its study packages are already complete.

| Stop | What the learner makes or changes | Godot/programming capability | What carries forward |
|---|---|---|---|
| **Day Zero** | Open the supplied project, change its greeting, save, run, stop and recover the original. | Project versus scene; `project.godot`; Scene tree; Inspector; FileSystem; Output; main/current scene; versioned starter and recovery copy. | A dependable place to work. |
| **Point Zero** | Set a greeting once, run a counter repeatedly, move counting into readiness, change the increment. | `extends`, `func`, indentation, variables, integers, strings, property assignment, `_ready()`, `_process()`, unused `delta`. | State and two different occasions for instructions. |
| **Point One** | Keep a position; give it a marker; vary visibility and the collision boundary separately. | `Node3D`, `MeshInstance3D`, a mesh resource, material properties and the distinct collision-body/shape arrangement. | A small reusable object with separately inspectable representations. |
| **Point Coordinates** | Move the marker, read its components, compare local and world readings, test proximity to a target. | `Vector3`, member access, node references, local/global position, a Boolean condition, a simple named input action. | A point whose position other objects can use. |
| **Point Lines** | Connect two markers, calculate distance and keep the readout current as an endpoint changes. | Function calls and arguments, vector subtraction, `.length()`, formatting; inspect the supplied segment helper's contract. | A usable relation between positions. |
| **Point Trace** | Retain successive positions and draw segments between them; limit the record. | A small array, `append`, index access, iteration, a sampling condition, separating stored data from its display. | A path the learner made. |
| **Point Line Grid** | Give retained positions grid addresses and compare the original with a quantised copy. | Integer/float distinction, rounding, index-to-position conversion, pure transformation functions, copying rather than silently mutating the source. | An addressable drawing or layout. |
| **Point Triangle Context** | Submit one triangle from three positions, toggle the fill, then assemble two triangles. | A small `SurfaceTool` or `ArrayMesh` construction; vertex order, normals and material visibility at the scale needed for this example. | A first authored surface. |
| **Primitives Polythedra** | Combine faces; compare the drawn opening with the chosen collider; save the object as a scene. | Scene composition, body/shape separation, reusable geometry and collision arrangements. | A small construction kit. |
| **Point Animatedcube** | Store corners and triangle indices; change a corner; replay the reveal separately from restoring the data. | Indexed structures, reusable update functions, snapshot/reset state, scene instances. | An editable object with an understood reset. |
| **Primitives Ignorance** | Expose mesh resolution and size settings; compare two configurations. | `@export`, Inspector-driven parameters, generated mesh resources; a first measured cost comparison. | A configurable artifact rather than a hard-coded specimen. |
| **Primitives Portals** | Generate a bounded family; select a member, reverse its displayed order, advance a small staged process. | Loops, parameters, `Button`/`Timer` signals, explicit state and finite stopping. | A repeatable comparison instrument. |
| **Primitives Melencolia** | Compose a small arrangement from earlier parts; add one personally chosen object, view and light; export it. | Scene organisation, elementary camera/light editing, an initial asset-import encounter, first distribution checkpoint. | A small finished composition another person can open. |

The table indicates first introductions and deliberate returns; it is not a requirement to teach every named concept completely at its first appearance.

### Two necessary accommodations

**Lists before the Array sequence.** Trace and triangle construction need small lists. Introduce only enough to keep ordered positions and submit vertices. The later Array sequence can develop multidimensional indexing, population construction, occupancy and data ownership. A topic's major chapter need not be its first syntactic appearance.

**Contact before a complete player.** A fixed-camera Point One study needs a supplied probe or another visible contact test. An invisible collider without a way to encounter it does not teach the distinction. This is a study-design requirement, not a reason to move the entire character-controller curriculum into Point One.

### What not to require here

Do not require the learner to implement XR tracking, general polygon triangulation, a production line renderer, full save migration, or the museum loader before leaving Primitives. A small explicit helper is acceptable when its input, output and limits are named.

The first endpoint coincidence is a useful debugging case. The first missing node reference is a useful editor lesson. Debugging should enter through actual small constructions, not wait for a final technical appendix.

## 4. Continue through the 25-sequence spine

All assignments and engine-feature placements in this section are proposals. The sequence names and order come from the repository; the detailed Godot teaching allocation expands beyond the current manuscript.

### Sequences 2–5: make a place someone can use

| Sequence | Godot teaching focus | Return to the learner's project |
|---|---|---|
| **2. Transformation** | Position, rotation, scale, hierarchy and pivots; useful interpolation; `delta`; `Tween` and `AnimationPlayer`; basic `InputMap`, `Camera3D` and `CharacterBody3D`; collision masks; signals; simple states; scene transition. | Build a navigable room with an animated pickup, a moving obstacle or platform, a dependable return, and pause/retry. |
| **3. Arrays** | `for` loops, arrays and dictionaries; nested indexing; `PackedScene.instantiate()`; separate data from nodes; spawn/remove/update; identifiers and occupancy. | Replace hand-placed repetitions with an editable grid. Connect selection to a readout. Compare a small custom grid with Godot's `GridMap`/`MeshLibrary` as a separate implementation option. |
| **4. Color** | `StandardMaterial3D`; shared versus unique resources; RGB/HSV; lighting and normals; Control-based sliders, buttons, containers and signals. | Build a palette/material instrument, a readable interface and a persistent chosen appearance. |
| **5. Tiling / Patterns** | Images and textures; UVs; source/receiver separation; resource-based recipes; basic file persistence; live versus held copies; imported surfaces and materials. | Make a mark, keep it, apply it to more than one surface and recover it after restarting. |

Transformation needs a compact player workshop beside its existing route. Borrow movement while examining the early objects, then open the borrowed controller in a separate study: input direction, velocity, floor contact, camera control and a reset. Keep a single movement scheme initially; alternative and remappable input should grow from that foundation.

The formal treatment of forces comes later, but a walking controller already needs a minimal explanation of its physics update. Teach what is required for this controller now; return to the fuller dynamics later.

The first complete playable work should exist by the end of Transformation. Arrays, Color and Patterns then give it new authoring possibilities. Do not postpone pause, retry, a visible instruction or a playable export until the final chapter.

### Sequences 6–12: make the world change, sound and vary

| Sequence | Godot teaching focus | Return to the learner's project |
|---|---|---|
| **6. Change** | Rates, accumulated state, `_process()` versus `_physics_process()`, step size, timers, local/global pause and plotted readouts. | Make movement whose rate is explicit; add a diagnostic view that can hold one process without freezing everything. |
| **7. Forces** | `RigidBody3D`, `CharacterBody3D`, `AnimatableBody3D`, areas, collision layers/masks, queries, forces/impulses, joints and surface response; compare engine simulation with a small custom integrator. | Give an existing object weight or a response; build a reliable carrier or reactive region; inspect what the actual controller receives. |
| **8. Form Finding** | A simulation independent of its presentation; step/run/reset; stopping conditions and budgets; coroutines or work spread over frames; assertions and repeatable small tests. | Add an object that develops under a rule and can be stopped, compared and kept. |
| **9. Wavefunctions** | Phase, frequency and amplitude; coordinated animation; sample playback with `AudioStreamPlayer3D`; buses/effects/volume; optional procedural audio generation. | Make a playable sound-and-motion instrument. Retain a chosen preset and allow silence. |
| **10. Randomness** | Local `RandomNumberGenerator`; seed, state and draw order; weighted choices; selection with/without replacement; reusable spawning and reset conditions. | Generate a recoverable arrangement. Change its vocabulary or assignment, not only its seed. |
| **11. Noise** | `FastNoiseLite`; sampling coordinates; mesh construction and normals; terrain collision; initial chunking and rebuild budgets. | Turn a generated field into a place to traverse, inspect or shelter in. |
| **12. Shaders** | `ShaderMaterial`; uniforms; vertex/fragment operations; UV/world/view spaces; texture sampling; CPU/GPU responsibility; first render-target or feedback study if its supporting implementation is supplied. | Give existing objects another response to position, time or viewpoint without confusing visible deformation with changed collision. |

Audio should not be silent until Wavefunctions. Earlier pickups and controls may use supplied samples. The wave sequence is where the learner opens their timing, synthesis or mixing in depth.

Likewise, do not teach every terrain algorithm before making one modest terrain. Separate the field, the sampler, the mesh and the collider so later substitutions have identifiable consequences.

**Composition checkpoint:** make a compact audiovisual place with input, a saved configuration and one meaningful variation. A second person should be able to enter, act, restart and recover something they made.

### Sequences 13–19: construct rules that build and reshape worlds

| Sequence | Godot teaching focus | Return to the learner's project |
|---|---|---|
| **13. Cellular Automata** | Current/next buffers, neighbourhoods, fixed simulation ticks, packed data, boundary conditions, visualisation decoupled from state, instancing. | Add a writable field whose history has a consequence. |
| **14. Fractals** | Recursion, base cases, explicit work stacks, generation budgets, progress/cancellation and safe editor previews. | Build a reusable generator with a chosen stopping point. |
| **15. L-Systems** | Strings, parsing, dictionaries, state stacks, custom recipe Resources, validation; curves and path-following where appropriate. | Turn a small editable language into a branching object or arrangement. |
| **16. Procedural Generation** | Combine generators; seeded layouts; spawn and exit constraints; navigation meshes/agents or a small A* route; loading/generated chunks; inspectable failure states. | Build a small generated level that a particular controller can actually use. |
| **17. Soft Bodies** | `SoftBody3D`, pins, joints, mesh preparation, rigid/soft interaction; an accompanying asset/character studio for import, skeletal animation and `AnimationTree`. | Give one authored body deformation or movement it can retain, and compare it with prescribed animation. |
| **18. Isosurfaces** | Scalar fields, local extraction, interpolation, `SurfaceTool`/`ArrayMesh`, normals, collision rebuilding, dirty chunks, data generation versus scene mutation. | Build a small editable volume or cave and profile its update. |
| **19. Boolean Surfaces** | CSG trees, editor composition, operand order, prototype-to-mesh workflow, collider choice and geometric validation. | Compose an inhabitable cut or shelter from earlier geometry. |

The full marching-cubes table, every fractal and every grammar need not become compulsory reimplementations. The core route can construct one meaningful case, use a supplied full implementation with an explicit interface, and offer deeper algorithm work as a branch.

Do not equate an attractive generated scene with a finished level. Add a spawn check, an exit, a reset, a controller-specific clearance test and a documented failure response. There can also be legitimate studies whose purpose is looking rather than traversing; label their purpose rather than declaring all of them failed levels.

Introduce advanced optimisation only against an observed problem. A many-instance comparison can motivate MultiMesh. A stalled rebuild can motivate chunking and work scheduling. Threads require a separate explanation of data ownership and the main-thread scene boundary; they are not a universal speed switch.

**Composition checkpoint:** make a generator with a reproducible recipe, an inspectable result, one editable constraint and a route back from a failed generation.

### Sequences 20–25: make systems inspectable, revisable and shareable

| Sequence | Godot teaching focus | Return to the learner's project |
|---|---|---|
| **20. Swarm Intelligence** | Agent state, sensing, steering, local/shared memory, spatial indexing and performance-aware representation. | Add a population that responds to an environment the learner can change. |
| **21. Machine Learning** | Data collection, explicit inputs and targets, a small genuine adaptive update, training versus inference, model state, logging and evaluation. | Compare a fixed behaviour with one that changes from feedback. Larger external ML integration remains optional. |
| **22. Graph Theory** | Adjacency, traversal, costs, A*, queues/stacks, path visualisation, dependency graphs and navigation debugging. | Open the route machinery used earlier; make a changed connection alter an actual route. |
| **23. Foundations Crisis** | Stated assumptions, validation, counterexamples, unsupported inputs, timeouts/budgets, reversible configuration and communicating uncertainty. | Test the limits of the learner's own tools without turning every theorem into another API lesson. |
| **24. QFEP Laboratory** | Parameter-to-receiver wiring, comparison instruments, recorded configurations, custom inspectors and model-time comparisons. | Build an instrument that reveals what its controls actually change. QFEP remains a project research framework, not a universal game-quality score. |
| **25. Post-Foundations Crisis** | Stable IDs, save schema versions, undo/redo, provenance, authored editing tools, packaging, accessibility, credits and a tested release. | Let someone else alter the world, keep or undo a change, and return to it. |

The final sequences should not compensate for missing basic software engineering. Persistence, testing, UI and distribution must already have appeared. These chapters revisit them under stronger questions: whose change survives, what a log records, what reset erases, and how someone can challenge the tool's choices.

A native GDScript adaptive example can make learning concrete without requiring a large external ML toolchain. A neural-network picture, an animation of training and a working update must be identified separately. Learners can then decide whether deeper ML or external integration belongs in their project.

**Final work:** an independently authored, small but complete game or exploratory world, plus the source, a reproducible build route and an account of one important decision revised after another person's encounter.

## 5. The engine curriculum must cross the artistic sequence

The sequence titles are not a complete index to game-development skills. Add short, explicitly labelled **Godot workshops** at points where an actual need develops.

### Project/editor fluency

Day Zero introduces import, save, run and recovery. Early scripts add breakpoints, error messages, Remote inspector and documentation lookup. By the first composition checkpoint, introduce version-control basics: a known working revision, a readable change and a way back. Keep implementation and teaching examples aligned to one tested Godot version for a course cohort.

### Scenes, resources and software structure

Point One separates a node from the mesh or material it uses. Cube/Arrays introduce instances. Color exposes shared resources. Patterns introduces named reusable recipes. Later, refactor repeated behaviours into small components or classes because duplication has become visible—not because novices must learn a grand architecture first.

Avoid an all-purpose autoload for every interaction. Start with explicit node references and direct signals; add a persistent session owner when information genuinely crosses scene lifetimes.

### UI and interaction

A supplied control can be used before its UI construction is taught. Build one ordinary screen-space button and one slider early, then inspect containers, anchors, keyboard focus, labels and input ownership in Color. Later world-space panels can reuse the same underlying commands.

A function such as `set_seed(value)` should not depend on whether a value came from a mouse, a controller, the Inspector or an automated test. That is a proposed interface design, not a requirement that every existing artifact already works that way.

### Player and camera

Borrow first, inspect next, construct a modest player in Transformation. Revisit camera frames, movement and collision in Forces and Noise. Keep actual player behaviour distinct from direct manipulation of a marker and from a displayed model of another body.

### Asset and character production

Add a small import workshop at a first composition milestone: one mesh or image, scale, origin, material, licence and reimport. Add animation blending and skeletal import later beside bodies and creatures. Procedural geometry alone does not teach the whole asset workflow.

### Saving and history

Start with saving the project in Day Zero. Hold a copy of data in Primitives. Keep a simple player configuration or palette by Color/Patterns. Save a generated recipe in Randomness. Later add stable IDs, loading errors, schema changes, undo and provenance.

“Reset,” “replay,” “restore,” “reload” and “undo” should not become interchangeable labels. Their differences can remain concrete parts of the course's artistic research.

### Debugging, testing and performance

Every studio should include a small check whose outcome can be described in advance. Suitable examples include a zero-length segment, a missing selection, an empty collection, a shared material changed accidentally, or a scene re-entered after a saved edit.

Use source inspection, numerical tests and embodied walkthroughs for different claims. A compile check does not prove a button can be reached. A screenshot does not prove collision. A seed does not establish bit-identical physical outcomes across versions and devices.

Measure before refactoring for speed. Revisit memory, number of scene nodes, draw calls, texture sizes, physics cost and rebuild work as the project grows. Keep frame time distinct from frame count.

### Distribution and access

Export a small composition early. Repeat the process as dependencies grow. Later builds include explicit asset/data filters, saved-file locations, settings, credits and instructions for a reader or player outside the developer's machine.

Teach readable controls, more than one input route where relevant, adjustable movement/timing, mute/volume and recovery alongside the features that need them. They should not first appear as a final ethical appendix.

## 6. XR, 2D and other branches

### XR: an overlapping route, not an entrance examination

The first making route remains possible on an ordinary desktop. The museum can still provide XR encounters from the beginning through a supplied tested setup.

A proposed XR progression:

1. **Preparation:** get a known scene running; test tracked view and input on the actual device.
2. **Coordinates/Transformation:** inspect origin, camera and controller frames; distinguish a real hand movement from artificial locomotion.
3. **Interaction:** connect an abstract selection/grab command to XR Tools or another named supplied interaction layer.
4. **Bodies/Forces:** inspect what collision can move, what is directly tracked, and how reach and comfort change the encounter.
5. **Rendering/release:** test stereo materials, UI legibility, performance and export on the target headset.

OpenXR is not the same layer as a pickup toolkit. Retain a desktop implementation of the underlying operation when practical, without claiming desktop and headset encounters are identical.

### 2D: a parallel application of the same ideas

A learner should be able to take a branch into `Node2D`, `Camera2D`, `CharacterBody2D`, lines/polygons, sprites and tile-based layouts. Trace, grid, random walk and cellular automata supply good translations between 2D and 3D. A native 2D lesson should teach its own APIs rather than imply that a 3D course already covered them.

### Specialist development branches

Multiplayer, remote services, native extensions, compute work, complex character rigs and editor plug-ins can each support substantial additional courses. Connect them to a demonstrated need rather than making them all mandatory for the main route.

For example, shared editing after Post-Crisis can motivate authority, message validation, disconnects and conflict handling. A two-person networked room would be a new tested deliverable, not a feature implied by the word “commons.”

The goal is broad practical 3D Godot competence and a way into further subsystems—not a defensible percentage of “all Godot.”

## 7. What each tutorial needs to carry

Use a compact editorial contract, preferably outside the main literary flow:

| Field | Purpose |
|---|---|
| **Begins with** | Exact starter/checkpoint and required prior capabilities. |
| **Makes possible** | A concrete act the learner can perform afterwards. |
| **New work** | The small set of concepts actually introduced in this lesson. |
| **Reuses** | Named prior functions, scenes, data or practices. |
| **Borrows** | Supplied helpers and what they receive/return; planned revisit or deliberate boundary. |
| **Check** | An observable result and one useful contrasting case. |
| **Carry forward** | A reusable artifact or capability and its next use. |
| **Further paths** | Optional developments with their prerequisites, not an unranked list of everything nearby. |

For Trace, for example:

- Begins with two endpoints, the supplied segment renderer, function calls and a changing position.
- New work is retaining ordered positions and deciding when to append.
- Borrows input-to-position conversion and cylinder orientation.
- Check: pausing below the movement gate does not add another stored position; reducing capacity removes the oldest samples as new ones arrive.
- Carries an ordered path into Grid; later uses include `Curve3D`, motion recording, drawing, fields and save data.

The actual lesson still needs a complete starting script, clear editing instructions, an expected observation, a way back and room for an individually chosen change. The contract should not turn every paragraph into a checklist.

### Three documents should remain distinct

- `final.md`: the authored encounter, its critical and poetic movement, and its invitation to continue.
- `tutorial.md`: the selected making path with prerequisites and runnable stages.
- `technical.md` or an existing equivalent: the installed artifact's wider machinery, exact source, implementation history and further dependencies.

This is a proposed division of responsibility to align with the current project. Do not rename existing files wholesale without checking the book's linking and publishing system.

## 8. A course should accumulate independence, not require 204 compulsory lessons

Use the current spine as a sequence of studios. Within each, choose a small main exercise, a return to earlier work and a composition task. An encounter can be visited without becoming an assessed making lesson. A difficult making lesson can span more than one session.

Three useful course exits are:

1. **Foundations and composition:** Day Zero through the early world-building studios. A small navigable composition with interactions, a readable interface, recovery and a shareable build.
2. **Generative game development:** continue through dynamics, sound, randomness, fields and chosen generation studios. A reusable generator and a tested procedural place.
3. **Systems and artistic research:** continue through populations, learning, graphs and the closing investigations. A revisable world whose important assumptions and histories can be examined by another person.

These are proposed course configurations, not time estimates. Trial lessons should determine workload before advertising a semester schedule. A shorter selection needs a prerequisite-checked route or a supplied checkpoint, not a silent jump over missing skills.

An independent change is stronger evidence of learning than reproducing a screenshot. Ask a learner to use a known operation for another purpose: make a target ring instead of reward, give a held trace another scale, restore a different subset of state, or let a previous input affect the next event. The desired result need not match the author's preferred aesthetic.

## 9. A practical implementation order

1. **Align the navigation sources.** Preserve the 25-sequence ordering, document the intended split opening, update the relevant map list and resolve the referenced toolbox document. Keep historical descriptions from silently overriding current numerical order.
2. **Publish a small curriculum manifest.** Map selected lessons to prerequisites, introduced skills, borrowed helpers, starter/completed checkpoints and future reuse. A proposed location is `doc/book/tutorial_path.json`; this file has not been created in the repository by this review.
3. **Prove one vertical chain.** Day Zero → Point Zero → Point One → Coordinates → Lines → Trace → Grid, ending in the learner's own small changed construction. Read, run and teach that chain before expanding the whole course.
4. **Add a composition checkpoint.** Make the route produce a finished small work that can be given to someone else. Record novice confusions and actual elapsed work rather than infer learnability from source accuracy.
5. **Extend by sequence-sized increments.** Keep a stable course release while the research branch continues changing. Upgrade the teaching version deliberately, with a migration note and tested checkpoints.

The curriculum manifest should describe learning dependencies, not rank the artistic worth of the field. It must not become another one-artifact rule or a demand to delete everything not on the main path.

## 10. The principle to carry forward

The pupil first borrows a world they cannot yet construct. Their learning should gradually make parts of that world available for alteration. Eventually they should be able to change not just what appears inside a room, but how it is addressed, how it responds, what it remembers, how it is shared and who can use it.

The path succeeds when a learner can leave it deliberately and continue working elsewhere in the field.

---

## Sources and scope

### Project sources inspected for this proposal

- `commons/maps/curriculum_spine.json` at `5a74c6e3064362e4a2882bfe4b6bd79a1e6b0c0a`: ordered 25-sequence spine, hub/branch design and legacy metadata.
- `commons/maps/sequences/primitives.json` at the same commit: committed map membership, currently preceding reconciliation with the split opening.
- `doc/book/ARC.md` at the same commit: older 24-chapter pedagogical arc.
- `commons/maps/Point_Zero/intent.md` at the same commit: borrowing agreement, callbacks/count lesson, distinction between encounter and making, intended Point One/Coordinates progression.
- `commons/maps/Point_Lines/tutorial.md` at the same commit: complete small study, explicit inherited skills, borrowed segment renderer and transfer into Trace.
- `tools/sequence_pipeline_scorer.py` at the same commit: confirms the spine and sequence source paths.
- `CLAUDE.md` at the same commit: project layout and Sieve; its counts explicitly require remeasurement.
- *AdaResearch_Reading_Proof_2026-09-30.pdf*: supplied first proof, 25 sequences/204 halls; explicitly excludes the separate, still-developing full making course. Used for the agreed opening and encountered materials, not proof of current runtime behaviour.
- *Ways through the halls*: supplied private editorial proposals, not runtime acceptance.

### External references used to check Godot teaching coverage

These are reference sources for the proposed engine curriculum, not evidence that the corresponding Ada lessons have been implemented.

- Godot 4.6, Step by step: https://docs.godotengine.org/en/4.6/getting_started/step_by_step/
- Godot 4.6, Your first 3D game: https://docs.godotengine.org/en/4.6/getting_started/first_3d_game/index.html
- Godot 4.6, Using signals: https://docs.godotengine.org/en/4.6/getting_started/step_by_step/signals.html
- Godot 4.6, GDScript reference: https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/gdscript_basics.html
- Godot 4.6, Resources: https://docs.godotengine.org/en/4.6/tutorials/scripting/resources.html
- Godot 4.6, Using Containers: https://docs.godotengine.org/en/4.6/tutorials/ui/gui_containers.html
- Godot 4.6, Saving games: https://docs.godotengine.org/en/4.6/tutorials/io/saving_games.html
- Godot 4.6, Procedural geometry: https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/index.html
- Godot 4.6, Introduction to shaders: https://docs.godotengine.org/en/4.6/tutorials/shaders/introduction_to_shaders.html
- Godot 4.6, AnimationTree: https://docs.godotengine.org/en/4.6/tutorials/animation/animation_tree.html
- Godot 4.6, Importing 3D scenes: https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/index.html
- Godot 4.6, Audio: https://docs.godotengine.org/en/4.6/tutorials/audio/
- Godot 4.6, Navigation: https://docs.godotengine.org/en/4.6/tutorials/navigation/
- Godot 4.6, Thread-safe APIs: https://docs.godotengine.org/en/4.6/tutorials/performance/thread_safe_apis.html
- Godot 4.6, Setting up XR: https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html
- Godot 4.6, Exporting projects: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html
- Godot 4.6, List of features: https://docs.godotengine.org/en/4.6/about/list_of_features.html
- Daniel Shiffman, The Nature of Code, Randomness: https://natureofcode.com/random/
