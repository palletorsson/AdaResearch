# Handover: the Godot course, written in functional text

## Current working anchor

- **Capacity tree reviewed from its files — 19 October 2026:** [CAPACITY_TREE_REVIEW.md](CAPACITY_TREE_REVIEW.md). `python tools/capacity_progress.py` gives one evidence rung per hall across the ladder, lineage, plan, memory and ghost-state layers (today: 10 none · 122 written · 69 focused · 5 runs · 0 learner over 206 live halls) and reports drift: 76 tutorials and 242 protected sources changed since the 5 October fingerprints, Pattern_Temple unknown to every layer, two Forces halls still in the layers, and `plan.json`, `memory/state.json` and the early/growth/later storyboards absent from git. Fingerprints are compared raw, CRLF and LF; a raw comparison over-reports drift by 101 files on an LF clone. Proposals for the page are in the review; nothing in the course data was changed.

- **Project memory is live — 4 October 2026:** [Open the workspace](http://localhost:3003/project-memory). It reads the 25 sequences and 204 hall storyboards and saves working notes, reasons, questions and source-linked findings in `doc/book/memory/state.json`, with prior revisions in `history/`. Start AI work from [memory/AI.md](../memory/AI.md); use the project packet, then descend to a sequence or hall. Source fingerprints flag changed evidence; acceptance is a separate editorial decision. The workspace supports parallel readers through revision-checked integration; it does not dispatch them automatically. The earlier pilot remains bounded evidence, not a whole-museum audit. Implementation of this memory tool is authorized; the current writing restriction remains summaries only, with no museum logic/order or full-lesson changes. [Usage and verification](../memory/README.md).

- **Bounded memory test — 4 October 2026:** [Report](../iterations/2026-10-04-context-roundtrip-test/index.html). Thirteen frozen inputs source-checked; a fresh reader retained 8/8 predeclared distinctions from a 402-word packet. Grid fits before rounding; its lossy mapping is not inverted by later Array position generation. Pen records can span pickups; session retention does not establish restart persistence. These known-case checks support the handoff method, not whole-course quality or runtime behavior. Summaries only; no museum code/order edits. Register conflicts remain to reconcile. Related systems: GraphRAG, RAPTOR, Letta, Skyframe and PROV; borrow patterns before adding infrastructure.

- **Global ↔ local orientation — 4 October 2026:** start with [storyboards/CONTEXT.md](storyboards/CONTEXT.md), then the generated [25-sequence overview](storyboards/SEQUENCES.md). Palle wants movement between whole project, sequences, maps and evidence without losing purpose. The compact method retains the question while descending and returns findings plus affected dependencies upward. A bounded document audit found thin sequence-level decision memory and unreconciled subject-register wording (existing counter; Grid's lossy mapping). These are recorded questions, not a completed all-map audit or permission to change runtime/order. Next proposed review: Primitives → Transformation.
- **Why compact memory — 4 October 2026:** Palle's aim is fast global decisions and an evolving curriculum, not merely shorter reading. Keep decisions, proposals, reasons, dependencies and open questions distinguishable so specific corrections survive context loss. The blog [A memory we can change](../iterations/2026-10-04-memory-that-can-change/index.html) develops this method. Palle clarified “GPU” as parallel processing: the proposed next layer is independent, version-bound evidence checks, not a new renderer or permission to change code. This evidence process is proposed, not implemented.
- **Full + short alternatives — 4 October 2026:** Palle requested compact AI versions as alternatives to all summaries. Day Zero and all 204 halls now pair `storyboard` (full prose) with `storyboard_short` (compact instructions). The review has a Full / Short AI switch. [TUTORIAL_STORYBOARDS_SHORT.md](TUTORIAL_STORYBOARDS_SHORT.md) exports the compact set with shared constraints once. The 192 later full paragraphs are unchanged; Primitives has full prose counterparts to the previous short trial. Maintain the same teaching choices in both versions. This remains summary work, not permission to edit runtime logic or expand tutorials.
- **Scope correction — 4 October 2026:** Palle: “do not change the logic of the code” and “we are just making summaries.” This pass is restricted to the short tutorial storyboards. Use source inspection to describe the existing behavior; do not implement new connections, change artifact logic or placement, or expand full tutorials. The attempted Trace-to-Grid runtime changes from this pass were withdrawn. [Lines → Trace → Grid notes](storyboards/LINES-TRACE-GRID.md) record the existing behavior and proposed teaching selection. Any future implementation task must be separately requested.
- **Withdrawn experiment output:** automatic approval review blocked removing the three `ada_run/encounter_pilot/*_tutorial_handoff/` folders. Their manifests and `WITHDRAWN.md` mark them as withdrawn; the collector will not use their images. Their results do not describe current code. The added production helpers and probe scripts were removed, production changes undone, and map hashes checked against the pre-pass inventory.

- **Current task and writing gate — 4 October 2026:** Palle requested the storyboards through the whole museum and confirmed a route with museum images and paragraphs. [TUTORIAL_STORYBOARDS.md](TUTORIAL_STORYBOARDS.md) now collects Day Zero and all 204 halls in 25 sequences. The [visual museum route](../iterations/2026-10-04-museum-tutorial-storyboards/index.html) places each proposal beside attributed museum images, its prior/new/supplied capabilities and artifact links. The authored sources and rebuild instructions are in [storyboards/README.md](storyboards/README.md). Correct the proposed teaching choices before full drafting; do not continue full lessons automatically. Existing critical texts, tutorials and map arrangements are not replaced by this proposal.
- **Main project:** the existing Endless Museum in AdaResearch_46. Use its actual hall, artifacts, player and lighting as the tutorial context.
- **Begin with the artifact already there.** Point Zero already has its frame counter. Palle rejected the added Hello-world teaching display; that addition has been removed. Select the useful operation from the existing material. This does not make a production-script maintenance exercise the default tutorial: the student needs a coherent, understandable operation or construction they can reuse. Any learner-made version and its relation to the existing artifact belong in the storyboard first.
- **Reader's starting agreement:** Point Zero opens by distinguishing the tutorial track, accompanying reflective texts and the wider field of museum artifacts. These sets overlap. An artifact need not appear in either text to belong in the museum.
- **Latest full draft, not an approved teaching model:** Point_Coordinates follows three production scripts and centres its edits on starting height and decimal formatting. Source accuracy was checked, but Palle's correction calls for agreement on what the student should learn before this is expanded or repeated. Its storyboard now proposes a movable point whose position the student can read and use; the exact taught grab connection and extent of local/world comparison need correction first.
- **Existing verification record:** 32 native checks passed for the Coordinates draft at `../iterations/2026-10-03-coordinates-existing-point/index.html`. This establishes the checked behaviours, not the suitability of the curriculum. Prior drafts are at `../iterations/2026-10-03-point-one-existing-points/index.html` and `../iterations/2026-10-03-point-zero-in-the-museum/index.html`. Physical headset use and beginner comprehension remain untested.
- **Work one tutorial at a time, after its storyboard is corrected:** name the encounter, prior capability, student action, new concept, supplied parts and reusable outcome. Then select and verify the code. Keep direct references to code-created objects; no hidden scene lookups in learner code. Do not choose a teaching subject merely because it is easy to patch and test.
- **Keep writing tracks distinct:** `tutorial.md` teaches selected operations; `final.md` carries its own critical and poetic inquiry. Do not rewrite either to account for every object.
- **Remaining environment alignment:** other pilots and Day Zero's detailed setup still describe the separate starter. Adapt their host instructions individually; do not claim museum integration from starter tests. The starter remains a test companion, not the main project.

## Environment correction: Endless Museum — 3 October 2026

Palle explicitly means the existing **Endless Museum** as the tutorial environment. Do not propose another museum or make the plain studio the default teaching destination. Reuse the actual halls, player, lighting and spine. The existing museum script exposes `start_chapter` and `start_map`; its shipped menu route is `commons/scenes/endless_museum_staged.tscn`. Self-contained lesson code still creates its own objects and keeps direct references. The starter remains a portable test environment. `COURSE_WORLD.md` now records this decision. Existing tutorial pilots, including Trans_Pre, are still implemented and tested only in the starter; no museum integration is claimed by this correction. Next practical work is to connect Trans_Pre's reduced code to the actual Endless Museum hall and verify it there before proceeding to another tutorial.

## Trans_Pre tutorial — 3 October 2026

The canonical Trans_Pre tutorial now continues from placing bodies to animating one code-created cube in the shared starter's `trans_pre.tscn`. Stage 0 keeps the cube still while elapsed time runs; 1 adds linear rise/fall; 2 adds rotation; 3 adds uniform scaling. The student owns delta/time, interval mapping, rate and extent. The mesh, orientation mark and readout are named supplied helpers with source, without scene lookups. The old tutorial is preserved exactly as `tutorial-museum.md`. A separate `tutorial-sine.md` implements the planned early usable sine comparison at the same endpoints and period; the museum retains its linear motion. Review, complete code, teaching contract, native room images and an eight-second film are in `../iterations/2026-10-03-transformation-a-running-body/`. 61 native checks passed on a cold extracted starter, including actual printed edits. Physical headset use remains untested. No critical text or museum placement changed. Continue with Trans_Introduction after author review: distinguish visible animation from a surface that supports a body. Coordinates' earlier starter pass remains pending, and the old numeric taxonomy is not certified by this local pilot.

## Closing tutorials made — 3 October 2026

Following Palle's clarification about ideal form, finite construction and geometric desire, the practical closing route now has two executable studies. Ignorance's existing function lesson links to `tutorial-column.md`: seven radii, equally spaced heights, a supplied circle sampler and a learner-owned position loop. Straight profile intervals are explicitly distinguished from the curved colonnade. Melencolia's canonical tutorial now composes three identical code-built pyramids by changing their placement list. The old implementation notes are preserved in `tutorial-museum.md`. Portals' existing tolerance lesson is unchanged. Both scenes are in the updated shared starter; review, paired native images, complete code, local teaching contracts and cold-package checks are under `../iterations/2026-10-03-primitives-closing-tutorials/`. No final.md or museum placement changed. The first new lesson to read is One Column, then use Portals before the composition lesson. After author review, continue into Transformation; Coordinates' earlier starter pass remains pending. Do not promote the old numeric taxonomy as validated by these local examples.

## Closing Primitives: form and desire — 3 October 2026

Palle's Gamwell reading clarifies the end of the sequence: constructing a form, deciding when a model is sufficient, and asking what we want making it to mean. A small pass is promoted to the three `final.md` files for Ignorance, Portals and Melencolia; the review and exact diffs are in `../iterations/2026-10-03-primitives-form-and-desire/`. Read `PRIMITIVES-CLOSING-LINEAGE.md` for the separate tutorial, critical and spatial responsibilities. The proposed single-column tutorial is not implemented yet, and Rings of Ash remains standalone rather than inserted into the spine. Its new prose is held separately pending placement. Existing tutorials remain as shipped. Next making work: one column from a profile, with the builder supplied and one parameter varied at a time; then Melencolia's composition exercise. Coordinates' earlier starter pass remains pending. Do not treat aesthetic value, a numerical tolerance and a historical claim as interchangeable evidence.

## Rings of Ash gallery — 3 October 2026

Palle asked for a transcendental gallery of totem/Pompeii columns at resolutions 4, 6, 8, 12 and 16. Built a walkable 5×5 gallery: columns vary radial sides across and curved-profile subdivisions along the room. Palle then requested varied outlines and heights: the default gallery now combines Vessel, Reed, Bell, Spindle and Cairn profiles at 2.87–6.17 m overall height. Setting `varied_forms = false` restores the original controlled comparison (one profile, 4.89 m overall). Plinth labels distinguish profile, mesh height and the two sampling counts. The new source assets and independent registry are under `commons/artifacts/resolution_colonnade/` and `commons/artifacts/registry/resolution_colonnade.json`. The shared starter exposes `resolution_colonnade.tscn` as an optional gallery with the existing desktop/XR input rigs. Source files are copied by the starter builder. Native review: `../iterations/2026-10-03-resolution-colonnade/`. This is a spatial companion to the Primitives/Portals resolution studies, not an additional mandatory lesson or an applied spine placement. The single column is available for placement; the full gallery needs its own footprint. Resume the tutorial chain at Melencolia after author review. Coordinates' earlier starter pass is still pending.

## Portals pilot — 3 October 2026

`Primitives_Portals/tutorial.md` now runs in `primitive_portals.tscn`. It is a short application of ordered points, distances, traversal and the preceding function lesson: `polygon_perimeter` takes a list and returns its closed boundary length. A supplied circle sampler and display keep trigonometric derivation outside this lesson. Six, twelve, twenty-four and forty-eight sides share a one-metre radius; an explicit absolute tolerance distinguishes a useful approximation from exactness. The grey guide always has 256 segments, while the circumference number uses TAU × radius. No new pickup or UI system is introduced. The former tutorial is archived as `tutorial-previous.md`, including its extra portal-velocity example; that example must not be presented as implemented by the hall's rings. The critical chapter and live map are unchanged. Review: `../iterations/2026-10-03-portals-a-useful-limit/`. Melencolia is next after author review, as an arrangement exercise and reflective return. Coordinates still needs its earlier shared-starter pass; continue one tutorial at a time without certifying the old numeric taxonomy.

## Primitives Ignorance pilot — 3 October 2026

`Primitives_Ignorance/tutorial.md` now runs in `primitive_rules.tscn`. A first explicit function, `octahedron_positions(radius: float) -> Array[Vector3]`, produces opposite points on three axes. Eight face rows remain supplied separately. `_ready()` calls the generator once; `_process()` permits later handle edits without restoring symmetry. A short SphereMesh return changes radial segments and rings separately at fixed dimensions; a named MeshEdges helper exposes the actual triangle edges. Both lesson scripts create their objects in code with direct refs. The old museum tutorial is retained as `tutorial-museum.md`; the critical chapter and live hall are unchanged. Review: `../iterations/2026-10-03-primitives-a-rule-for-positions/`. 33 native checks passed, including printed edits, desktop and synthetic XR movement. Physical headset use remains untested. Primitives_Portals is next after author review. Coordinates still needs its earlier starter pass; continue one tutorial at a time without certifying the old numeric taxonomy.

## Cube pilot — 3 October 2026

`Point_Animatedcube/tutorial.md` now continues in `point_cube.tscn`. The learner reuses Polyhedra's position/face lists and nested submission loop with eight explicit cube coordinates; this lesson does not derive a cube from a gesture or touch Trace's saved file. It follows the front pair `[4,5,7]`, `[5,6,7]`: moving 6 tilts only the second front triangle. A repeatable `corner_shift` parameter and the alternate pair `[4,5,6]`, `[4,6,7]` expose how triangulation changes a non-planar surface while its four corners stay fixed. Supplied pink/white materials and an amber diagonal make the comparison legible. Twelve triangle patches are distinguished from six geometric square faces; there is no surface collider. The full museum walkthrough, replay, nets and prefab collection are preserved in `tutorial-museum.md`; final.md and the hall are unchanged. Review: `../iterations/2026-10-03-cube-a-shared-diagonal/`. Primitives_Ignorance is next after author review, with a small rule generating positions. Coordinates still needs its earlier starter pass. Continue one tutorial at a time; the numeric taxonomy is not certified by these pilots.

## Polyhedra pilot — 3 October 2026

`Primitives_Polythedra/tutorial.md` continues in `point_polyhedra.tscn`. It reads the same original three Trace selections as Triangle (not temporary edits to that scene), adds a fourth point at their centre plus a declared negative-Z offset, and separates a position array from face-index rows. A nested loop submits each row's three positions to ImmediateMesh. The learner adds `[1, 3, 2]` to the three-face open corner to close a tetrahedron; four non-coplanar positions are required for volume. The two-sided unshaded materials, pickup and transport are reused. The study adds no collider around the surface. The richer museum collision, barrier and slope comparisons remain in `tutorial-museum.md`, final.md and technical.md. Review: `../iterations/2026-10-03-polyhedra-a-face-list/`. Cube is next after author review; Coordinates still needs its earlier shared-starter pass. Continue one lesson at a time; this local contract does not promote the old numeric taxonomy.

## Triangle pilot — 3 October 2026

`Point_Triangle_Context/tutorial.md` now continues the shared starter in `point_triangle.tscn`. Read the same saved Trace record that Grid reads; select entries 0, n/3 and 2*(n/3), using integer division. These are list positions, not detected corners or equal arc distances. Copy them into three movable PointHandles in the same local frame; join three Segments; explicitly submit three vertices to an ImmediateMesh. No automatic projection, snapping, fitting, saved-record edit or general polygon fill. A supplied two-sided, unshaded material separates the geometry comparison from normals/culling. The learner adds the face in code and can independently change viewpoint, corner position and visibility. The earlier museum walkthrough and concave-fan investigation are preserved in `tutorial-museum.md`; `final.md` and live hall are unchanged. Review and local contract: `../iterations/2026-10-03-triangle-three-corners/`. Polyhedra is next after author review; Coordinates still needs its earlier shared-starter revision. This does not certify the older numeric taxonomy or the whole course.

## Correction: reuse the learner's trace in Grid — 3 October 2026

Palle's correction is essential: Grid must receive the trace already made with the desktop mouse or VR hand. The previous live-point Grid pilot missed this continuity. The current `point_trace.tscn` saves a snapshot on release through the supplied TraceMemory helper. `point_grid.tscn` reads that same record, preserves `source_points`, and rounds each entry into a separate `grid_points` list. Changing spacing rereads the saved source. It never starts a replacement gesture or uses a synthetic fallback. The two displayed views share a source-based fit and differ by a layout translation. Review: `../iterations/2026-10-03-trace-return-to-grid/`. File storage, release signals and comparison layout stay supplied; the visible lesson owns the value-to-value mapping. The earlier Grid pilot is a historical comparison, superseded by this correction.

## Point Grid pilot — 3 October 2026

The next pilot is `commons/maps/Point_Line_Grid/tutorial.md`, with `point_grid.tscn` and `studies/point_grid/grid.gd` in the shared starter. Review and local contract: `../iterations/2026-10-03-point-grid-an-address/`. The learner divides by spacing, uses `roundi()` and Vector3i to name an address, then converts back to Vector3/metres. Separate input and output markers show that computing an address does not move the hand. Trace's list and loop now retain changes of address, including returns. A grid address names a place; an array index identifies a visit. The finite XY ruling is supplied and labelled as a section of the 3D calculation. Floor-plan loops, release alignment and whole-drawing replay are deferred. Triangle is next; Coordinates still needs its earlier shared-starter rewrite. Continue one tutorial at a time.

## Point Trace pilot — 3 October 2026

Trace now continues the same starter in `point_trace.tscn`, with `studies/point_trace/trace.gd` and canonical `commons/maps/Point_Trace/tutorial.md`. It teaches an ordered `Array[Vector3]`, append/index/size, a distance-based admission condition, traversal of adjacent pairs with `for`, and finite capacity through `pop_front()`. The local contract and reading copy are in `../iterations/2026-10-03-point-trace-positions-kept/`. This is a continuous centre-position record; the museum pens' snapping and separate strokes are not claimed. The named TraceDrawing helper supplies rendering, while the learner owns the list and traversal. A small `if` comparison is now explained in Trace; the later Transformation chapter can deepen conditions. Whole-array copying remains future work. The old numeric taxonomy and proposed subject register are not certified by this pilot. Continue one tutorial at a time after Palle reads it.

## Point Lines pilot — 3 October 2026

At Palle's request, Lines now has a shared-starter pilot: `point_lines.tscn`, `studies/point_lines/line.gd`, and the canonical `commons/maps/Point_Lines/tutorial.md`. It constructs its handles, segment and readouts in code; subtraction and length are the new operations. The supplied pickup and cylinder renderer have named interfaces and included source. Review: `../iterations/2026-10-03-point-lines-two-ends/index.html`. Coordinates remains before Lines in the spine; its older tutorial still needs the new shared-starter pass. Do not treat this preview as completion of that intervening lesson or silently alter the order.

## Point One in the prepared world — 3 October 2026

The revised `commons/maps/Point_One/tutorial.md` follows three stations in the Day Zero starter: stored position, visible surface, separate collision. Open `point_one.tscn` with Run Current Scene; the complete learner scripts are under `studies/point_one/`. The review and local teaching contract are in `../iterations/2026-10-03-point-one-a-body/`. The reader can change radius and collision independently. Grabbing and reference frames remain for Coordinates. The earlier fixed-camera download is an older companion, not the current lesson route. Keep `final.md` separate and continue one tutorial at a time after Palle reads this pilot.

## One prepared XR world, portable studies — 3 October 2026

[COURSE_WORLD.md](COURSE_WORLD.md) defines the shared environment and the role of separate study downloads. Day Zero owns editor setup, the chosen XR Tools version, player and input configuration, and headset deployment. Tutorials create portable lesson objects and declare their environment or interaction dependencies. The older Day Zero/Point Zero ZIPs remain desktop studies. The new [Ada XR starter](../studies/ada-xr-starter/README.md) includes the room, desktop/XR players, pickup and bundled XR Tools 4.5.1. It has desktop and simulated-controller checks; physical headset and Quest deployment verification remain pending. Keep that distinction explicit. A desktop camera test must not instruct students to override a tracked XR camera. Continue one tutorial at a time.

## Self-contained lesson objects, 3 October 2026

Palle's latest correction: examples must not use dollar references to nodes in a scene file. Create each lesson's objects in code and keep direct variable references; do not substitute get_node() or another path lookup for $. Day Zero may supply the camera, room, lighting and player context. Name that context explicitly. Point Zero now creates its own Label3D and runs on an empty Node3D; its first small use of a variable, new() and add_child() is explained. Point One develops those operations through a visible point. Revise one tutorial at a time; do not bulk-rewrite the remaining chapters. This supersedes earlier permission to fetch prepared teaching displays or meshes by scene path.

## Subject introductions and returns, 3 October 2026

[sketch/SUBJECT_REGISTER.md](sketch/SUBJECT_REGISTER.md) adds a detailed proposed teaching register through Randomness. Its authored decisions are in `sketch/subject_lineage.json`; `sketch/taxonomy_use_index.json` separately indexes current tutorial-code occurrences and all existing taxonomy entries. Introduce a usable sine operation in Trans_Pre and bounded random variation with a repeatable seed in Array. Waves and Randomness deepen those beginnings. Keep the current sequence order for the first writing trial; Unit Circle need not move merely to make sine available.

Separate encountered, supplied, introduced, reused and deepened. A first introduction states what the learner can deliberately change; a deeper return states the additional capability. A code-token occurrence is not proof of teaching. The existing numeric `introduced_at` values and checker still describe the old functional draft. Revise a lesson, its declarations and its executable example together before promoting its new locations. Continue one tutorial at a time; this register is a plan, not a bulk rewrite.

## Curriculum through Randomness, 3 October 2026

[sketch/CURRICULUM_TO_RANDOMNESS.md](sketch/CURRICULUM_TO_RANDOMNESS.md) records a proposed learning route through all 87 maps in the first ten sequences. Keep the sequence order. A tutorial may teach one operation inside an artifact; final.md is not responsible for everything left over, and museum objects may belong to neither text. Distinguish a technical prerequisite from a critical question carried between halls. The small Platonic generator introduces a function returning positions in Primitives; Colour develops functions later. Unit Circle before Sine Space is a proposed tutorial trial, not an applied spine change. Missing and mismatched tutorials are listed with evidence. Continue one lesson at a time; this outline does not certify the present lessons or their code.

## Encounter-led progression, 3 October 2026

Teach a programming concept when the current encounter gives the learner a reason to use it. Point introduces variables through a position; Trace introduces an ordered one-dimensional list of positions and a for loop over that list. Later arrays and tiling chapters develop those skills rather than introduce them from nothing. Use Learning Processing and The Nature of Code as teaching references, with the Ada spine as the route.

tutorial.md teaches how to construct, change and inspect the encounter. final.md follows its critical, poetic and associative questions. They share artifacts and accurate claims, but need not carry the same explanations, pace or code. Adding a programming concept to a tutorial does not require adding it to final.md.

This supersedes the 2 October suggestion to leave Trace’s list entirely supplied, and the fixed allocation “loops first in Array, arrays first in Tiling.” Keep the movement and drawing infrastructure supplied; teach the short ordered list and its `for` traversal in Trace itself. Point Zero attends to ready/process; Point explains variables in a concrete construction. An early counter can preview a variable without carrying the full explanation.

Continue one tutorial at a time. The sketch and scaffold record this new progression; the written functional draft, its type declarations and runnable studies must be updated together when each lesson is rewritten. Do not silently change final.md to carry tutorial explanations.


## Spine-first correction, 2 October 2026

Use the current spine and each map’s tutorial.md as the scaffold. Programming prerequisites guide the size of each step, not a competing route. Record local exceptions: introduce one essential operation earlier, borrow an explicit component, or return to its implementation later. A reflective hall need not introduce a new coding feature.

The canonical source index and the first chapter's map-by-map decisions are in [sketch/SPINE_SCAFFOLD.md](sketch/SPINE_SCAFFOLD.md). All twelve Primitives tutorials exist. The 25 chapter order already matches the spine; the current chapter-internal draft does not yet. Start the next prose pilot with Point Zero (`_ready`, `_process`, counter), then Point One (code-created visible and solid marker), then Coordinates. Do not treat the earlier sphere-first draft as the final route or rewrite every lesson at once.


Written 2026-10-02, 21:30, by the session that did this work (Claude, session d4723a07), for the next model; checked by hand against the files and git at 21:50 (every link, path and commit exists; the counts re-measured).
Palle is switching models because this session kept re-writing his text in its own words. Read section 1 before you touch anything.

Paths are relative to `C:/Users/palle/Documents/GitHub/AdaResearch_46/`.
`ada_encyclopedia/` means `C:/Users/palle/Documents/GitHub/ada_encyclopedia/` (branch `spatial-iterations-gallery`).
The Ada repo's trunk is `palm-scanner-door-entry` (`main` is stale).

---

## 1. The one thing that went wrong, and how to avoid it

Palle gives short, exact corrections. The agents (and this session) answered each correction by re-writing whole chapters in their own voice, so every fix brought new drift, and he had to catch it again. His words, at the end: "you're not letting me win. please make it work."

What the drift looked like, all found by Palle, all fixed in `3083866fe`:

| what the agents wrote | what Palle wanted | why |
|---|---|---|
| "`StandardMaterial3D` is a class: Godot wrote it." | "`StandardMaterial3D` is a Godot built-in class." | the documentation's term, said simply |
| "Alpha is how much a colour covers." | the standard definition: alpha is the colour's opacity, 0 fully transparent, 1 fully opaque | use the technical term and its standard definition |
| "A function answers." | "A function returns a value." | the code says `return`; "answer" turns a function into a speaker in a dialogue and hides that control and a value go back to the caller |

**How to work with Palle on this text:**
1. Do exactly what he asks. Change only the lines his request needs. Every other line stays byte-identical.
2. Show him the before/after of the exact lines (a small table), then commit.
3. Use established terms with standard definitions, close to the Godot documentation (docs.godotengine.org class reference and GDScript reference). Never paraphrase a term that has a standard name.
4. For a change of style across chapters, do one chapter, show him, and roll out only after his yes.
5. Work by hand. Palle asked, at the end of this session: "do this by hand not by multi agents". Many agents meant many voices, and each correction met new drift. If an agent is ever unavoidable, brief it for minimal change and ask for a table of every changed line (old, new, why), and check the diff against that table yourself.
6. Turn each correction into a checker rule where you can (a forbidden synonym in `taxonomy.json`, a test), so it cannot come back.

**The reference for the voice:** [test_tutorial.md](test_tutorial.md), "A sphere in code": the simple test tutorial Palle asked for, written by hand at the end of this session, its code run in Godot 4.6. Palle has not reviewed it yet. Start by showing it to him.

**The research frame:** Palle's preface (his Google Doc, https://docs.google.com/document/d/1z3Sk3YY3VYiNUau5F0IhxHQxusAG-e2sRmDvt3CQn7M/edit) explains why the text is compressed: Dichtung, intelligence as compression and unfolding, the subtle vectors (direction, force, connection), cribs and Good–Turing, entropy as situated and layered. Read it to understand what the course text is for.

---

## 1b. The two anchors (added at the end of the session, after the mistakes above were traced)

Every drift today came from structure or words invented by a model and then copied. Two things outside the model now fix both:

- **Structure: the scaffold, read from the spine.** [scaffold/SCAFFOLD.md](scaffold/SCAFFOLD.md) (data: `scaffold/scaffold.json`, regenerate with `python doc/book/course/scaffold/build_scaffold.py`, dev server needed). One chapter per spine sequence, one hall per map in the sequence's order, and in each hall the works in Palle's own arrangement: his primary works, his named boxes with their works, his notes. 25 chapters, 204 halls, 419 primary works. Palle: "we should have used scaffold from the spine sequence." A chapter is written hall by hall from this, and each primary work is something the student builds, in code. The sketch (`sketch/sketch.json`) did not do this: it took the Learning Processing ladder as its skeleton and pulled works from across halls; treat the sketch as background, the scaffold as the skeleton. The ladder still decides which programming idea arrives when a work first needs it.
- **Words: Godot's own documentation and editor labels.** The 4.6-stable class reference and the 4.6 editor UI strings are downloaded (with Palle's permission) at `C:/Users/palle/Documents/GitHub/godot_reference_4.6/` (outside the repo). A derived vocabulary (classes, member names, 5,485 UI strings) is `godot_vocabulary_4.6.json` there. Not yet wired into the checker: that is the next mechanical job (every Godot name and every quoted editor label must exist there; Godot entries' definitions derived from the docs).
- **Bodies are made in code**, from chapter 1 (Palle: "it is all wrong to use the dollar mesh tscn approach"). The `$Name` pattern came from an agent-written chapter-1 seed and the checker's `nodes=` runner, not from Palle or the sketch.

## 2. What the project is

A Godot 4 course for first-time programmers, inside Ada Research (the VR museum of algorithms). One chapter per spine sequence: 25 chapters. Part I follows the Learning Processing ladder; The Nature of Code follows; case studies (Haeckel's radiolaria and others) come later as extensions.

The text is written in **functional text**:
- **short-speak**: lines, not paragraphs; one claim per line, about seven words; do / see / why.
- **type safety**: every term the course uses is an entry in one hard taxonomy; a term is used only after the section that introduces it; synonyms are forbidden; names from the code appear exactly as the code spells them.
- **verified as code**: a checker reads the chapters like a compiler and runs every code block in Godot 4.6.

---

## 3. Palle's rules, in his words, and where each one lives

| date (2026-10-02) | Palle | became | lives in |
|---|---|---|---|
| morning | "The text is too verbose, there are not enough images ... the language should be like The Nature of Code. You must lead the student with as little text as possible but still enough to understand. Intelligence is compression." | short-speak | [SHORT_SPEAK.md](SHORT_SPEAK.md) |
| morning | "Before we commit to writing ... sketch the whole sequence ... one image per tutorial. Chapters: one chapter per spine sequence. Part I: the Learning Processing is the right ladder. Case studies: later." | the sketch | [sketch/sketch.json](sketch/sketch.json), [sketch/SKETCH.md](sketch/SKETCH.md) |
| midday | "Type safe means that we are not using unintroduced elements (hard taxonomy) and that the text is verified as code. Maybe we can call it Functional text." | taxonomy + checker | [taxonomy.json](taxonomy.json), [functional_text/FUNCTIONAL_TEXT.md](functional_text/FUNCTIONAL_TEXT.md), [functional_text/check.py](functional_text/check.py) |
| afternoon | "the decompressor should not be forced to recreate the original but to understand the content of the tutorial" | the compression test measures understanding | [functional_text/round_trip/REPORT.md](functional_text/round_trip/REPORT.md) |
| afternoon | "how to run the project can be described once. after that we can just say run the project" + "not everything should be linked back, not the teaching of that tutorial but admin" | admin procedures: defined once, then called by name and linked; teaching is never linked | SHORT_SPEAK "Admin is said once", FUNCTIONAL_TEXT 2a, kind `admin` in the taxonomy |
| evening | "make images later" | images deferred; figure lines stay | — |
| evening | "can we make it even more readable by indented point list that we can group related hierarchical meaning?" | lines in a tree: numbered steps for doing, a bullet tree for understanding, plain lead and point | SHORT_SPEAK "Lines in a tree", FUNCTIONAL_TEXT 2b |
| evening | "highlight the word type like in code?" | NOT BUILT yet (see 6.2) | — |
| evening | "the usual word is return ... explain the concept of function returning a var ... use illustration whenever you can along the code" | return, not answer; 4.2 explains the return value and `void`; one diagram figure line so far | ch04 4.2; `answer` is a forbidden synonym of `return` |
| evening | "`StandardMaterial3D` is a godot basic class ... use the technical term the standard definition ... stay close to the documentation and opt for clarity ... these seem to be unnecessary rewrites" | standard words, standard definitions; built-in class explained in 1.1 | ch01 1.1, ch04 4.7 and 4.8 |

---

## 4. The files

### The course text (Ada repo, `doc/book/course/`)

| file | what it is | state |
|---|---|---|
| [SHORT_SPEAK.md](SHORT_SPEAK.md) | the voice: short-speak, type-safe text, admin said once, what compression keeps, lines in a tree | committed |
| [functional_text/FUNCTIONAL_TEXT.md](functional_text/FUNCTIONAL_TEXT.md) | the form: taxonomy, sections as functions (needs / gives / admin / borrows), the page's devices (2b), the chapter file format, what the checker verifies and cannot see | committed |
| [taxonomy.json](taxonomy.json) | the hard taxonomy: 631 entries (concept 201, godot 157, maths 106, gdscript 69, supplied 43, name 30, plain 18, admin 7), each with forms, def, introduced_at, synonyms, depends_on | committed |
| [functional/ch01.md](functional/ch01.md) | 1 Points Build Bodies | written, 0 errors |
| [functional/ch02.md](functional/ch02.md) | 2 Bodies That Change | written, 0 errors |
| [functional/ch03.md](functional/ch03.md) | 3 Many From One | written, 0 errors |
| [functional/ch04.md](functional/ch04.md) | 4 Colour by Function | written, 0 errors |
| [functional/ch05.md](functional/ch05.md) | 5 A Source, Many Repeats | written, 0 errors |
| [functional/ch18.md](functional/ch18.md) | 18 Bodies From Fields (written early as the hard case) | written, 0 errors |
| [functional/patches/](functional/patches/) | the taxonomy changes each chapter writer proposed, kept as the record | committed |
| [functional_text/check.py](functional_text/check.py) | the checker (standard library only) | committed |
| [functional_text/test_check.py](functional_text/test_check.py) | 207 tests, each rule with a passing case and a planted fault | committed |
| [functional_text/sketch_report.md](functional_text/sketch_report.md) | the order check of the whole sketch: 34 errors, 641 warnings | committed |
| [sketch/sketch.json](sketch/sketch.json) | 25 chapters, 197 sections, each with idea, picture, hall, code; 13 open questions | committed |
| [functional_text/round_trip/REPORT.md](functional_text/round_trip/REPORT.md) | the compression research, rounds one and two | committed |
| [site/](site/) | a MkDocs Material docs site (Read the Docs ready); it builds the OLD kit lessons, not the functional chapters yet | committed |

Chapters 6 to 17 and 19 to 25 are not written. Each exists only as its sketch entry.

### The pages (`ada_encyclopedia/`, dev server `npm run dev`, port 3003)

| URL | source |
|---|---|
| http://localhost:3003/course/sketch | `src/app/course/sketch/page.tsx` |
| http://localhost:3003/course/sketch/1 (and /2 /3 /4 /5 /18) | `src/app/course/sketch/[chapter]/page.tsx`, `functional-text.css`, `src/lib/course-sketch.ts` |
| http://localhost:3003/course/sketch/order | `src/app/course/sketch/order/page.tsx` |

The chapter page hides the signature comments, keeps one source line per page line, renders numbered steps and the bullet tree, shows the Types box as a card, and links every admin call to its first instance. A new `chNN.md` appears on its own.

### Memory (for Claude sessions)
`~/.claude/projects/C--Users-palle-Documents-GitHub-AdaResearch-46/memory/feedback_course_text_compression.md` (the whole day's decisions) and `feedback_minimal_change_pilot_first.md` (section 1 of this file).

---

## 5. How it works, and the commands

### A chapter file
Each section starts with a signature in an HTML comment, then plain Markdown:

```markdown
<!-- section 2.1
needs: extends, Node3D, func, _process, var, :=, +=, $, position, y, frame, MeshInstance3D, BoxMesh, Inspector, metre, base_scene, add_a_node, run_the_project, new, add_child, Vector3, _ready, mesh, root_node, script, =, function, scene, node, supplied, editor
gives: *, delta, frame_rate
admin: delete_a_node
-->
## 2.1 A little every frame

*[the cube in three stills a second apart, each half a metre higher than the last]*

**Delete a node**: select it, then press Delete.
If you added supplied nodes, delete those from the editor.
Keep the base room, camera and lighting.

Replace the root node's script with this example.
Code creates the cube each time you run.

**Example 2.1: a rising cube**

(gdscript block: create cube with MeshInstance3D.new(), assign BoxMesh.new(), add_child(cube), then move cube.position in _process)

Run the project: the cube rises.

- `cube` is declared outside the functions.
  - `_ready` creates its mesh and adds it to the scene.
  - `_process` uses the same node every frame.
- `delta` is the seconds since the last frame.
  - It has no underscore here: the code uses it.
- `*` multiplies.
- `speed * delta` is the frame's share of `speed`.
  - After one second, the cube stands 0.5 higher.
- The frame rate: how many frames Godot draws a second.
  - A fast machine draws more frames, each a shorter `delta`.
- Change `speed * delta` to `speed`: the cube shoots away.
  - It adds 0.5 every frame, not every second.
  - Restore: `speed * delta`.

Times `delta`: per second, at any frame rate.
```

- `needs`: entries the section uses (all introduced earlier). `gives`: entries it introduces (each needs a defining line in the text). `admin`: admin procedures it defines. `borrows`: supplied parts it hands out.
- The form: plain lead line, numbered steps (doing), code, a bullet tree (understanding: a child explains, qualifies, follows from or restores its parent; at most two levels), plain point line.
- The page's devices are listed in FUNCTIONAL_TEXT 2b. Nothing else (no arrows, no `enters:`, no `from:`, no provenance tags: the checker refuses them).
- Every chapter script `extends Node3D` and sits on the root node of the base scene (the checker's `top` rule).

### Commands (run from `doc/book/course/`)

```bash
python functional_text/check.py --taxonomy taxonomy.json --godot functional/ch04.md
```
Checks one chapter, runs its code in Godot. The exit code is the number of errors. Without `--godot` it is fast and skips Godot. `--quiet-warnings` hides warnings.

```bash
python functional_text/test_check.py
```
All 207 tests, about 100 s; some run Godot.

```bash
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json --report functional_text/sketch_report.md
```
The order check of the whole course sketch.

Godot is `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe`; the checker finds it itself.

### State at handover (measured 21:20)
- ch01, ch02, ch03, ch04, ch05, ch18: 0 errors with `--godot`.
- 207 tests: OK.
- Sketch order check: 34 errors, 641 warnings. The 7 real order breaks: wallpaper group, rate, Mover (in 8.x), damping, reaction-diffusion, genome, queue. The other errors are terms the sketch never teaches.
- Uncommitted in `doc/book/course/`: only `kits_checked.json`, which is not part of this work (leave it).

---

## 6. What is open, in order

### 6.1 Decision: create the teaching objects in code

Update, 2 October 2026: Palle asked to remove all dollar-sign mesh references and simplify the opening. Direct editor-created teaching nodes in the six written chapters have been replaced: Point, Cube, the primitive court, the nested room, wall holder, lamps, swatch and pane backdrop now originate in code. No `nodes=...MeshInstance3D` fixture supplies those objects in the checks. `$Supplied`, `$Walker` and `$Counter` still refer to explicitly supplied services or non-mesh nodes.

Section 1.1 is the language pilot: one sphere, four actions (create, give a mesh, place, add), an already attached root script, and the supplied room/camera/light. The minimal download is `doc/book/course/pilots/2026-10-02-first-sphere/`, published at `/course/sketch/first-sphere.zip`. The lesson is `/course/sketch/1`. Section 1.2 creates its own sphere too, so it no longer fails on a missing `$Point`.

The six-part, 25-chapter order is in `sketch/sketch.json` and `sketch/SKETCH.md`, visible at `/course/sketch`. It matches Palle's table. Part I remains: shapes/coordinates/callbacks/mouse/variables → conditionals → loops → functions and a class → arrays. `new`, `var` and `add_child` begin in 1.1; coordinate names in 1.2; supplied-node lookup in 1.5. Functions as reusable rules and user-defined classes stay in chapter 4.

The broader changes are construction fixes, not approval to rewrite every lesson's voice. Keep reviewing the language one lesson at a time. Do not ask code-versus-editor again.

Named supplied parts still need a separate delivery pass. Chapter 3 currently instantiates the explicitly supplied pickup cube and patterned tiles from scene files; these are not hidden dollar-sign dependencies. Do not silently replace their pickup/material behaviour with a bare mesh. The first-sphere download contains the opening only, not the later feeler, walker, tile or paint services. Runtime checks of later supplied services use stubs and do not prove those teaching kits are delivered or visually complete.

### 6.2 Type highlighting (asked, not built)
"highlight the word type like in code?" Plan, already agreed in principle:
- The checker, as it checks a chapter, writes a sidecar `functional/chNN.types.json` with every prose use of a taxonomy term it resolved (line, span, entry id, kind, declaring or not, def, introduced_at, a hash of the chapter text). One implementation: spans come from the checker's own matching, never from a second matcher in TypeScript.
- The chapter page colours those spans by kind (concept, maths; code names keep their code style), the declaring use in bold, with a tooltip "N.M · def". A tooltip, not a link: Palle's rule is that teaching is never linked back.

### 6.3 Illustrations beside the code
"use illustration whenever you can along the code". Every section has a figure line `*[...]*` saying what its picture shows; only one diagram line exists so far (ch04 4.2: `*[diagram: ...]*`, the flow of a return value). Add a figure line beside each code block where a picture helps. The images themselves come later ("make images later"): renders from each example's own code for bodies, drawn diagrams for ideas. Note: the checker does not yet know the `diagram:` prefix as a kind; it reads it as an ordinary figure line, which works.

### 6.4 Standard vocabulary, the rest of it
The three words Palle named are fixed. Other homemade definitions are likely still in the chapters and in `taxonomy.json` defs. Do this as a list for Palle first, not as a rewrite: for each term, the current def, the Godot documentation's wording (URL), a proposed short def. Change only what he approves. Course-coined terms that he agreed (mesh = what is seen, shape = what is touched) stay.

### 6.5 Part II, chapters 6 to 9 (Motion: change, forces, formfinding, wavefunctions)
Write them the way chapters 2 to 5 were written, but with the method of section 1: one chapter first, show Palle, then the rest. Each writer proposes taxonomy changes in a patch file (`functional/chNN.taxonomy_patch.json`, a list of `{op, id, fields, why}`) instead of editing `taxonomy.json`, because parallel writers overwrite each other; one agent merges the patches in chapter order. A student reading of each chapter, with the earlier chapters in hand, found the real stalls last time.

### 6.6 Smaller open points
- Two editor procedures are not confirmed in a live Godot editor (the checker cannot click): "Make a new script" (Script, File, New Script, name, Create) and dropping a `.gd` or `.tscn` from the FileSystem onto a node to attach it.
- Two choices for Palle from the order check: may an exercise explain a term in passing (accept-reject, Huber, topological sort)? Is "evolution" taught or an everyday word?
- "basic class" (Palle's word) against "built-in class" (the Godot documentation's word): the text uses "built-in class". Ask if he prefers his.

---

## 7. The compression research (background for Palle's research method)

Palle's method: compress, unfold, compare, and let what fails to return change the next version. He wants to study the "subtle vectors" lost in compression: the direction of a thought, the force of a claim, the connection between a shortcut and the system it enters.

- Round one (rebuild the lesson): of claims kept in the compressed text, 480 of 484 returned; of claims cut, 2 of 117. Force was lost first, connection next.
- Round two (understand the lesson, with the earlier chapters available, open book, two blind judges): every one of 336 scores was full, for the original and for texts at 54% (Point One) and 33% (cellular) of its prose. This is a ceiling: agent readers already know Godot. The eleven extra devices round one proposed cost 11 to 36% more words and moved no score, so they were dropped. The only misunderstanding came from a paragraph of the original.
- A sharper round three would need a reader without Godot knowledge and an exam with headroom. A draft plan exists: [functional_text/round_trip/T1_PLAN_DRAFT.md](functional_text/round_trip/T1_PLAN_DRAFT.md) (not approved by Palle).
- All sheets: `functional_text/round_trip/round2/results.json`.

---

## 8. Traps that cost time today

- **Stale `.git/index.lock`.** A crashed git left an empty lock five times today. If git refuses and no `git.exe` is running (`tasklist | grep -i git`), delete `.git/index.lock`.
- **Shared tree.** Other sessions edit this repo. Commit by explicit paths only (`git add -- <paths>`), never `git add -A`, never `git stash`. `doc/book/course/kits_checked.json` and the encyclopedia's `src/app/globals.css` belong to others.
- **Agents commit if they see "commit" in Palle's messages**, even when the brief says not to. Say it explicitly in every brief, and check `git log` after a run.
- **Workflow resume re-runs work.** A resumed workflow reused results only while its calls came in the same order; after the crash it re-ran a 27-minute compression. Keep expensive outputs as files.
- **Windows file locks.** A write to `taxonomy.json` once failed with `OSError: [Errno 22]` while another process read it; retry after a second.
- **Python on Windows writes CRLF** in text mode unless you pass `newline="\n"`; a workflow script with CR characters is refused.
- **The shell's working directory** follows your last `cd`; a folder you `cd` into cannot be deleted until you leave it.
- **A twin session.** After the computer crashed, session 0f212078 received the same messages as this one; it wrote an earlier version of this file. Forum thread `261002-xga26` claims these paths (`python tools/forum.py read 261002-xga26`).
- **`godot --doctool`** dumps only the API skeleton, without descriptions. For definitions, read docs.godotengine.org.

---

## 9. Today's commits

Ada repo (`palm-scanner-door-entry`):

| commit | what |
|---|---|
| `243394c16` | the course sketch, 25 chapters |
| `faeac2b6d` | functional text: spec, taxonomy, checker, tests, chapters 1 and 18, admin |
| `5dcdc23de` | compression rounds one and two; the first handover |
| `2161e5ab7` | the docs site |
| `9f7cddf35` | cellular kit: the edge walker hangs on row 9's edge, it does not stand on row 8 at 1.46 m |
| `05f13cf7e` | specs amended from round two |
| `ee8602cb1` | one convention for scripts (root node, extends Node3D); admin "make a new script", "put a script on a node"; the device rule |
| `9099afac2` | chapters 2 to 5 written, their taxonomy patches merged |
| `720bbf194` | chapters 2 to 5 fixed after four student readings |
| `6b5b6f6d1` | lines in a tree |
| `3083866fe` | Palle's words: return, not answer; built-in class; alpha is opacity |

Encyclopedia (`spatial-iterations-gallery`): `af36b31f` the /course/sketch pages, `70791229` two blog posts (2026-10-02 "The Field Was Too Wide", "Text That Compiles"), `297d942c` the tree styling.

Nothing is pushed.

---

## 10. Do not

- Do not re-write a chapter to fix one line.
- Do not paraphrase a standard term.
- Do not relaunch the old kit build (`doc/book/studies/`, `KITS_BRIEF_LONG.md`): Palle stopped it for being too verbose.
- Do not link teaching back; only admin calls link.
- Do not change the bodies-in-code question (6.1) without Palle's answer.
- Do not push.
