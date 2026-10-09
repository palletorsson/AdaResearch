# Foundations before Randomness

2026-10-04. **Proposed foundation plan; no lessons or runtime changed.**

Establish the programming fundamentals by the end of Colour. Reuse them through Tiling, Change, Forces, Form Finding and Waves before the deep study of Randomness.

Planning only. This document adds a proposed foundation layer to the current hall summaries. It does not approve proposals, rewrite tutorials, change code, or move maps.

Use the existing Endless Museum. Select a small operation from its artifacts, explain its supplied surroundings, then let the student vary and reuse it. The tutorial, reflective writing and museum remain overlapping sets.

## Target

The Nature of Code assumes variables, conditionals, loops, functions, objects and arrays, with familiarity with object-oriented programming. Ada must teach these before treating them as prerequisites. The target is usable foundations, not all of computer science.

[The Nature of Code prerequisites](https://natureofcode.com/introduction/#what-do-you-need-to-know).

Use the existing hall order. First exposure, practice and independent use are different stages. A supplied callback or renderer may be used before its implementation is taught. All checks below are proposed learner actions, not results already observed.

## 1. Primitives — Name, connect, keep and generate.

**Leave able to:** Use named positions, a short list, a condition, a loop and a returning function to make a small geometric arrangement. Explain which values describe it and which objects display it.

| Hall | Role and selected learning | Practice / carry | Independent variation | Supplied |
| --- | --- | --- | --- | --- |
| Point_Zero | **Introduce.** Initialization and repeated execution; read a call and its argument. | Compare one reading with repeated readings in the existing counter. A frame callback and a list loop are different forms of repetition. | Predict which instruction runs once and which runs again. | Existing counter, display, player, camera and room. |
| Point_One | **Introduce.** Named values, assignment, basic types, arithmetic; resource and node references. | Separate the variable holding a position from the sphere displaying it. Read .new(), property assignment and add_child in the existing construction; give var and const distinct meanings. | Change radius once and predict which visible and physical parts use it. | Existing corridor conditions; collision construction can be read before it is authored. |
| Point_Coordinates | **Reuse.** A changing property in one reference frame; persistent script state versus a local temporary. | Read the held point's X, Y and Z. Keep the object reference available to the callback that needs it; explain scope when the code crosses callbacks. | Move along one named axis and explain the changed value. | Hold connection, input and coordinate readout. |
| Point_Lines | **Introduce.** Expressions and returned values: subtract positions, then obtain length. | Reuse variables and method calls. Distinguish position, displacement and scalar distance before normalizing anything. | Choose two other endpoints with the same separation in another direction. | Existing segment renderer and endpoint input. |
| Point_Trace | **Introduce in three beats.** A one-dimensional list, first comparison/if, then indexed for traversal. | Beat 1: append and read a position. Beat 2: keep a sample only when distance reaches spacing. Beat 3: join neighbours. Explain true/false, indentation, zero-based indices and range bounds beside their first use. | Predict the retained points for stop–move–return, then the number and order of joined segments. | Pen/point input, segment renderer and session record. Align the eventual lesson with the museum, not the older starter host. |
| Point_Line_Grid | **Reuse.** List order versus spatial address; original data versus a derived display. | Follow the museum's fit-then-round operation in three dimensions. Read/traverse known data; preserve its source. | Find two recorded visits that occupy one displayed address and show that the original remains distinct. | Existing session transfer and grid receiver; no promise of persistence after restart. |
| Point_Triangle_Context | **Introduce.** A face as three ordered positions. | Reuse a short position list and a supplied face submission call. Inspect winding without rebuilding the renderer. | Make another non-collinear triangle; reverse its order and predict the visible side. | Mesh submission/display support. |
| Primitives_Polythedra | **Introduce.** Indices refer to shared positions; a face list describes connectivity. | Close a tetrahedron using a small known vertex list. Reuse index reading and traversal. | Alter one corner and identify every face that refers to it. | Mesh assembler; no long factory data dump. |
| Point_Animatedcube | **Reuse.** Shared corners, face connectivity and a diagonal. | Reuse position and face lists. Separate editing their data from moving the whole node. | Change the diagonal while retaining the same outer corners. | Existing cube comparison and display. |
| Primitives_Ignorance | **Introduce.** Author a small function: parameters, local values and a return. | Turn a repeated geometric construction into a reusable position generator. Distinguish defining a function from calling it. Use a small subset of the existing forms. | Call the same generator twice with different inputs and explain the two returned results. | Display/mesh assembly and any not-yet-taught formula. |
| Primitives_Godot | **Reuse.** Engine class, instance, resource and scene have different roles. | Relate the resource instances already met in Point One to one documented parameter. Authoring a new class comes later. | Make two resources with different settings; identify which object an edit affects. | Museum presentation and collision support. |
| Primitives_Columns | **Reuse.** Functions plus nested repetition generate a family. | Vary profile, height and radial count separately. Explain each loop's job; this is construction using known pieces. | Use the same rule for another column and compare resolution at fixed shape. | Mesh stitching/receiver where not already understood. |
| Primitives_Profiles | **Selected exploration.** Source outline versus construction along a route. | Change one disclosed recipe input. Reuse functions/lists without requiring font extraction, triangulation and sweeping at once. | Predict which feature follows the outline and which follows the route. | Font outlines, hole processing and sweep construction. |
| Primitives_Portals | **Reuse.** A running total and a stopping comparison express a chosen tolerance. | Reuse neighbour traversal, arithmetic and a returning function. Explain any accumulation before using it as a result. | Choose a different tolerance and justify a finite resolution. | Comparison display; no proof that more segments make better art. |
| Primitives_Melencolia | **Compose / reflect.** No required new syntax. | Arrange a small family made with known values, lists, loops and generators. Preserve the reflective question about geometry and desire. | Make and explain one arrangement without copying the previous example exactly. | Museum staging; unfamiliar scale controls remain supplied until Transformation. |

## 2. Transformation — Make a rule run, decide and remember.

**Leave able to:** Write a timed or input-responsive rule with a branch and retained state. Reset it deliberately; explain whether the state is recomputed or remembered.

| Hall | Role and selected learning | Practice / carry | Independent variation | Supplied |
| --- | --- | --- | --- | --- |
| Trans_Pre | **Develop.** delta, elapsed time, comparisons and if/else. | Begin with one familiar cube moving or holding at a duration boundary. Reuse Trace's first if. Size, turns and a supplied sine call become separate variations after this works. | Change duration and endpoints; predict start, middle and finish. | Museum collection and readout; circular derivation of sine waits for Waves. |
| Trans_Introduction | **Develop.** An event invokes a handler; a reset assigns known starting state. | A supplied connection calls the learner's reset function. Reuse timing on one deck with declared input/output. | Restart twice and account for what returns to its start. | Event wiring, collision, physical deck and rider transport. |
| Trans_Translation | **Reuse.** Guard an invalid operation; keep a waypoint index. | Read a short route. Check length before division, then advance the index at the end of a leg. Contrast per-frame stepping with traversing the whole list in one call. | Include a repeated waypoint and explain how the rule handles a zero-length leg. | Preview marker; use carrying only after its deck contract is settled. |
| Trans_Rotation | **Reuse.** Pivot and order of operations. | Reuse a returning position function, known offsets and timed angles. | Reverse two turns and predict when their results differ. | Ride physics and readouts. |
| Trans_Scale | **Reuse.** Parent-child transform ownership. | Use direct references to a small group. Scaling its parent changes placement and size relative to a fixed comparison. | Predict which child distances change and which outside object stays fixed. | Museum room, bottle and relocation. |
| Trans_Body | **Develop.** A current boolean versus a retained flag; combine simple conditions. | Compute proximity afresh, then compare it with a remembered visit. Introduce and/not only where the chosen rule needs them. | Walk away and predict reversible response versus remembered change. | Visitor-position query, collision update and carving infrastructure. |
| Trans_Pit | **Compose.** No required new syntax. | Compose two leaves from one opening fraction using known functions, timing and an occupancy input. | Choose an opening/reset rule, predict an intermediate pose and test it. | Airlock frame, event/input binding and physical leaf wrapper. |

## 3. Arrays — Organize many things without losing one.

**Leave able to:** Read and change one entry in a collection, distinguish a value from an object reference, and write a repeatable spatial or timed rule over the collection.

| Hall | Role and selected learning | Practice / carry | Independent variation | Supplied |
| --- | --- | --- | --- | --- |
| Array | **Develop in two beats.** Independent objects, stored references and indexed writes; then nested traversal. | Start with a short row made through a named creation function. Compare two references to one object with references to separate objects. Keep occupancy records distinct from display references; extend to a plane only afterwards. | Change one object and one occupancy entry; predict their separate effects while addresses stay fixed. | Creation/display adapter and collection event. The full tutorial is currently missing. |
| Tutorial_3D | **Reuse.** An extra index and explicit storage order. | Use distinct rows/layers. Explain conversion from the earlier [x][z] plane to the installed values[y][z][x] representation. | Write/read one slot with unequal x, y, z; preserve its neighbours. | Flight, selection and collection; no matrix-algebra detour. |
| Tutorial_Tiling_Floor | **Develop.** Remainder gives a repeating address-to-turn rule. | Reuse nested traversal, a function and a conditional exception; zero now means orientation, not vacancy. | Predict a 4×4 sample, then expand the same rule and preserve one chosen exception. | Asymmetric motif and raster-image renderer. |
| Tutorial_Tiling_Walls | **Reuse / reflect.** No required new syntax. | Use the same image on another supplied receiver. Compare image rotation with movement of the wall. | Explain what changes in appearance and what changes in passage. | Upright receiver, hinge and collision. |
| Tutorial_Disco | **Compose.** Read a boolean record through time. | Start with one short score. Reuse elapsed time, retained index and remainder; a true entry triggers a supplied sound operation. | Move an event while holding tempo fixed, then change tempo while preserving the score. | Sound and display; robust catch-up scheduling remains supplied. |

## 4. Colour — Calculate a value, assign it, give it state.

**Leave able to:** Use a returning function and a small authored class. Create two instances with independent state, apply results to known receivers, and use the foundation concepts together.

| Hall | Role and selected learning | Practice / carry | Independent variation | Supplied |
| --- | --- | --- | --- | --- |
| Color_Context_Placed | **Reuse.** Palette lookup and assignment. | Apply known loops and indices to existing parts while retaining geometry. Avoid introducing dictionaries here. | Regroup separated parts by colour without moving them; inspect the selected index. | Direct part/material references and optional numeric categories. |
| Color_Flashlight | **Reuse / reflect.** An object's property and its receiver are distinct. | Change the existing light's colour, then its aim with colour held fixed. | Explain why an equal numeric colour need not look equal on different surfaces. | Light reference, grabbing and renderer. |
| Color_Nails | **Develop.** A complete position-to-Color function with a stated contract. | Reuse functions authored in Primitives. Name positive box dimensions, parameters, locals, clamping and return. Separate calculation from assigning albedo. | Check origin, opposite corner and an outside point; change one coordinate and predict one channel. | Input/hand support and one explicitly bound preview receiver; full function binding is proposed. |
| Color_Rainbow | **Optional / reflect.** No required new syntax. | Reuse a hand-picked palette if desired. Keep the celebration independent of completing an exercise. | Optionally vary palette length at fixed total width. | Arch construction and accessible route; automatic colour transfer is not assumed. |
| Color_Pillar | **Reuse.** Same function contract, another coordinate-to-colour rule. | Return Color from HSV-based inputs; caller/receiver can stay the same. Explain the hand-height adapter. | Vary value alone, then diagnose a wrong coordinate frame separately from a wrong formula. | HSV conversion and explicit height adapter. |
| Color_Grid_Pallet | **Introduce a small class.** One class defines state and methods; separate instances keep separate current indices. | Propose Palette with a colour list and index, current_colour() and next_colour(). Start with a nonempty palette; create two instances and advance one. Reuse known modulo/functions and send the result through the existing floor receiver. | Predict both instances after separate advances, then store and revisit a colour at an address. | Class shell and address-to-MultiMesh receiver. This learner class and binding are proposed; there is no material/node per cell. |
| Color_Paint | **Reuse / reflect.** Known time, functions and bounded surface coordinates. | Change one existing automatic path rate/amplitude; compare its calls with the manual cans' shared paint operation. | Predict narrow/wide or slow/fast path changes without confusing the evolving image with a retained gesture list. | UV-to-hit conversion, spraying and feedback shader. |
| Color_Walls | **Compose / reflect.** Combine known palettes, instances, functions and assignments. | Use a small existing part list or pane arrangement to make an independent variation. Keep transparency and lighting implementation supplied. | Use a different palette length, a returning function and a bounded condition; explain which objects share values and which keep state. | Pane receiver, collision and rendering; preserve privacy/authority inquiry. |

## Coverage register

| Subject | First explicit encounter | Practise | Demonstrate | Observable capacity |
| --- | --- | --- | --- | --- |
| Execution and calls | Point_Zero | Point_Trace, Trans_Pre | Trans_Pit | Distinguish initialization, repeated frames, a list traversal and an invoked handler. |
| Variables, assignment and basic types | Point_One | Point_Coordinates, Point_Trace | Primitives_Melencolia | Name and change a value; distinguish a number, bool, position, list and object reference. |
| Arithmetic, expressions and returned values | Point_One, Point_Lines | Primitives_Portals, Trans_Translation | Color_Nails | Follow inputs through a calculation and predict its returned type and value. |
| Comparisons and conditions | Point_Trace | Trans_Pre, Trans_Translation, Trans_Body | Tutorial_Tiling_Floor, Trans_Pit | Write if/else, explain the bool, and handle a relevant boundary or invalid input. |
| Lists and indexed data | Point_Trace | Point_Line_Grid, Array | Tutorial_Disco | Read, append and change entries while keeping order and bounds explicit. |
| Loops and accumulation | Point_Trace | Primitives_Columns, Primitives_Portals, Array | Tutorial_Tiling_Floor | Predict iteration bounds; traverse neighbours, a row and a small nested collection. |
| Functions: parameters, locals and return | Primitives_Ignorance | Primitives_Columns, Trans_Rotation, Color_Nails | Color_Pillar, Color_Walls | Write a small function, call it with other inputs and reuse its contract. |
| Scope and retained state | Point_Coordinates | Trans_Pre, Trans_Body | Tutorial_Disco, Color_Grid_Pallet | Explain what survives a callback and what is recomputed; reset deliberately. |
| Objects, properties and references | Point_One | Primitives_Godot, Trans_Scale, Array | Color_Grid_Pallet | Distinguish class/resource/node/value; predict shared references versus independent instances. |
| An authored class with state and methods | Color_Grid_Pallet | Color_Walls | Color_Walls | Make two instances, invoke their methods and explain their independent state. |
| Events and input | Point_Coordinates | Trans_Introduction | Tutorial_Disco | Explain supplied input and handler calls without rebuilding XR or signal infrastructure. |
| Observation and debugging | Point_Zero, Point_One | Point_Trace, Trans_Translation, Color_Nails | Color_Walls | Predict, inspect a value, isolate one change, identify a mismatch and check the correction. |

## Rehearse between Colour and Randomness

### Tiling

Return to palette instances, addressed reads, copies and references. Let the same record acquire another reader.

Supply serialization and complex rendering; do not add a language prerequisite merely because it appears in the artifact.

### Change

Use known functions, loops and running totals for a finite difference and finite sum. Keep a position through repeated field steps.

The mathematical relationship is new; programming basics should be familiar. Choose exact learner edit bindings before writing.

### Forces

Keep position and velocity as separate state; update several independent bodies using the same small rule.

Make state-plus-update reusable for particles and agents. Engine physics and the learner's explicit update remain different operations.

### Form Finding

Reuse conditions, functions, state and repeated updates to search or satisfy a constraint.

Annealing needs a local bounded-random-draw introduction: range, when a draw occurs and one acceptance comparison. Do not pretend Arrays already taught it.

### Waves

Reuse elapsed time, the short sine preview, lists, functions and independent state. Return to traces through sampling.

Give new signal/coupling concepts room. Event selection may reuse the bounded draw; distributions and seeds wait for Randomness.

## Readiness, observed through making

Given the working museum, named input/display interfaces and a changed requirement, make a small study with several independently stored bodies or marks. Use a list, a loop, a returning function, a condition and two class instances. Add a reset, predict an outcome, inspect values and explain a correction. Then replace one deterministic choice with a supplied bounded random draw and state what remains unchanged.

Passing this practical review would support foundation readiness; appearing in code, a summary or a completed reading does not. The task can build on the student's existing work and need not become another museum artifact.

Return to the named first lesson or practice hall for the missing operation; do not solve a language difficulty by adding another algorithm.

Deferred until useful:

- Inheritance hierarchies or polymorphism
- Dictionaries before a lesson needs them
- General matrix algebra
- Manual memory management or asynchronous programming
- Implementing the renderer, XR player, physics engine or shader system
- A full theory of probability before Randomness

## One tutorial at a time

1. Review these placements as a proposed foundation layer; retain current accepted summaries until a deliberate revision is agreed.
2. For the next hall, write its short storyboard with: brings, first new operation, practice, supplied interface and one independent variation.
3. Check the existing artifact and identify the exact learner edit location before expanding that single tutorial.
4. Read the next two halls to ensure they reuse the result rather than silently adding prerequisites. Update both full and compact summaries when a choice is adopted.
5. After each sequence, assess the small independent work. Record observed difficulty and adjust the next introduction; no invented time estimate or mastery score.
6. At Colour, check the six NOC fundamentals together. Practise them further in the intervening sequences before the Randomness checkpoint.

## Decisions still open

- Point Trace's current companion uses a starter scene and persisted TraceMemory, while the museum notes describe the existing pen and session transfer. Preserve the museum's source record and fit-then-round Grid behavior; reconcile the teaching host before promoting the lesson.
- The current Point One source edit starts with a constant. Make the intended variable/assignment learning explicit without falsely presenting the corridor as a live draggable point.
- Array's reduced creation/display binding and Tutorial_3D's storage conversion need concrete lesson contracts. A visible collection alone does not teach independent object ownership.
- Nails' complete authored function, Grid's proposed Palette class and custom colour receiver are not delivered learner exercises yet.
- The older subject register still assigns first conditions to Translation and a random draw to Array. Reconcile it only when these proposed teaching placements are adopted.
- Core by Colour is a curriculum target, not evidence of a tested beginner course or a claim that all 35 full tutorials already meet it.

## Evidence and maintenance

Current summaries and selected source/companion texts informed this plan. Source reading is not learner testing. The older subject register is a comparison, not the authority when it conflicts with museum summaries.

Edit `doc/book/iterations/2026-10-04-foundations-before-randomness/plan.json`, then run its `build.py`. This rebuilds this guide, the review page and a source manifest; it never promotes teaching decisions.

- `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`
- `doc/book/course/storyboards/BRIEF.md`
- `doc/book/course/storyboards/LINES-TRACE-GRID.md`
- `doc/book/course/sketch/subject_lineage.json`
- `commons/maps/Point_One/tutorial.md`
- `commons/maps/Point_Trace/tutorial.md`
- `algorithms/color/gridcolorizer/address_lesson.gd`
- `algorithms/color/pillarcolorcollection/field_sampler.gd`
- `commons/maps/Color_Nails/tutorial.md`
