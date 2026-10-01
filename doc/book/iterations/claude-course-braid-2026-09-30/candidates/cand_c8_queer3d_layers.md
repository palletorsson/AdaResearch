# Three Layers: bodies in the lab, bodies in debt, bodies out of bounds

Candidate `c8_queer3d_layers`, braid auto-research, 2026-10-01. Grown from one reference: Palle Torsson's Queer 3D World course (Konstfack, three weeks, 2024 intro): the three layers of Ada Research, FOUNDATION (the lab), THE UNCANNY AND ALGORITHMIC DEBT, and ONTOLOGY (hybrid and impossible space), used as the macro-structure; scanned and sculpted bodies from week 1; AI-assisted code as practice; a mini project shown to the class.

Marks: [V] checked this session against a file (the braid folder, the 2024 course text, spine.json, maps/ada.json, maps/lineage.json, survey_bundle.json, the kit folders under doc/book/studies/); [V via research_*] checked by the sweep agents and taken from their files; [mem] from memory, not checked. Nothing in the repo was edited, staged or committed.

## For the student: why this order

This course is built like the Queer 3D World course: three layers, like an onion. Part I is the lab. You build bodies that hold still (a point, a line, a grid, a surface, a family of colours, a body type) and learn how each one is made. Part II is the uncanny. The same bodies start to move, fall, hang, sound, scatter and grow, and every one of those motions is an approximation that owes something: time chopped into frames, forces added up step by step, solvers that stop at 'good enough', chance that is only pseudo, noise that makes everything look like a blob, recursion that must be stopped, surfaces looked up in a table, models that learn their data's bias. Part III leaves the lab: your bodies are lost in generated worlds, go soft, grow skins, get cut and joined, swarm, become impossible from all but one eye, drift from order to entropy, and finally leave the computer as a build other people can walk into. Every chapter still passes through all three layers on a small scale: make the body, read its debt, give it a place. Your own scanned or sculpted body arrives on day one and comes back in every part, so the course is one body picking up a year of procedures. The order follows the Ada spine where the spine's order is the order your hands need, and says so where it does not: chance appears early as a value and returns later as debt, isosurfaces and machine learning close the debt part, and graphs follow the maze that needs them.

## Parts

**I. Foundation: the lab** (chapters 1-15). You can build a still body in code (points, lines, grids, surfaces, colours, patterns, classes), give it a boundary and a place, turn it into a family with @export, and argue one axis with a predicted comparison sheet. Your scanned body stands among them.

**II. The uncanny and algorithmic debt** (chapters 16-28). You can make bodies move, hang, sound, scatter and grow, and for each procedure you can say what its approximation owes or hides (frames, integration, relaxation, sampling, pseudo-randomness, the blob, the pixel, the rule, the stopped recursion, the lookup table, the bias) and show it in one still.

**III. Ontology: out of bounds** (chapters 29-37). Your bodies leave the lab: generated worlds you can get lost in, soft and patterned skins, collages, swarms, impossible viewpoints and order-to-entropy, ending in a build other people can walk, carry or become.

The macro-structure is the Queer 3D intro's onion [V: QUEER3D.md, QUEER3D_2024.txt]. The same three layers repeat inside every chapter: FOUNDATION is the chapter's making, DEBT is its `debt` field, ONTOLOGY is its `place` field. So each part stresses one layer and every chapter still passes through all three, which makes the course self-similar.

## Tracks

### Queer 3D World in three weeks (short, 3 weeks (15 days: taught sessions plus own work, as in the 2024 course))

Chapters: 1 Bring a body: a scan meets a point, 2 The engine calls you: a point that lives, 3 Solid or ghost: what you see and what stops you, 4 Where is a body? Coordinates, frames and the hand, 7 Many bodies: the grid as an instruction, 11 Colour as a family: the first @export, 15 Synthesis I: the specimen sheet, 21 Noise: chance with memory, and the blob, 22 Shaders: the pixel computes, the collider stays, 33 Cut and join: collage bodies, 37 Leaving the lab: the show

'The body the scanner could not see': a hybrid body, your scan or sculpt collaged with ONE procedural family, standing in a small room where a visitor can meet it (stand on it, walk through it, carry it or become it). Shown to the class as a desktop build (and on the headset if it holds frame rate), with a 3-5 variant comparison sheet, a prediction written before the render, a one-sentence claim, and one debt comment in the code saying what the approximation owes. Designed first: every short-track chapter ends in a step of it. Week 1 FOUNDATION: Mon c01 scan day; Tue c02 + c03; Wed c04 headset day; Thu c07 grid + AI protocol; Fri own work (plinth). Week 2 DEBT: Mon c11 family; Tue c21 noise on your scan; Wed c22 shader skin; Thu c15 specimen sheet and the brief (pivot); Fri own work. Week 3 ONTOLOGY: Mon c33 collage; Tue-Wed own work and a guest; Thu c37 build; Fri the show. Supplied and named (the prerequisites the short track skips): the Day Zero base scene; the first-person walker and XR rig (vr_staging.tscn, XR Tools pickup), used before they are opened in c17; segment.gd show_between(); errors are met as the daily planted bug instead of c05; arrays, conditions and input stay inside the supplied walker and grid kit (c06); random values and seeds come as the FastNoiseLite seed property (c08, c20); areas and signals come in the supplied comment box and teleporter (c09); a MeshDataTool helper that displaces a scan along its normals replaces the mesh chapters (c13); a shader template with a named amplitude uniform; the sheet camera script; a CSG kit; export presets. Classes (c12) are skipped: @export works on a plain script.

### Three Layers: the year (long, about one academic year (about 36 teaching weeks: Part I autumn, Part II winter, Part III spring, with a pause week after each synthesis))

Chapters: 1 Bring a body: a scan meets a point, 2 The engine calls you: a point that lives, 3 Solid or ghost: what you see and what stops you, 4 Where is a body? Coordinates, frames and the hand, 5 Two points make a relation: the line, 6 Klee's walk: the trace, 7 Many bodies: the grid as an instruction, 8 Chance as a value: Schotter, 9 A body that notices: the floor that answers, 10 A body of parts: pivots and frames, 11 Colour as a family: the first @export, 12 A body type: the class that crosses a category, 13 Surfaces from vertices: can you stand on it?, 14 The tile and its repeats, 15 Synthesis I: the specimen sheet, 16 Time in slices: the staircase under the curve, 17 The integrator owes: forces, and the walker opened, 18 Good enough: form found by relaxation, 19 Pendulum, circle, spiral: sampled waves and sound, 20 Pseudo: the seed returns, 21 Noise: chance with memory, and the blob, 22 Shaders: the pixel computes, the collider stays, 23 Rules and their edge: cellular automata, 24 Recursion must be stopped: fractal bodies, 25 Grammar: the turtle, its stack, and the building, 26 Implicit bodies: the lookup table and the neck, 27 Bias: the model is a picture of its data, 28 Synthesis II: the debt audit, 29 A generated world you can get lost in, 30 Graphs: the world as a network, 31 Soft: polycount against deformation, 32 Morphogenesis: Turing's pattern on your skin, 33 Cut and join: collage bodies, 34 Many bodies choose: swarms, 35 Impossible space: the camera decides, 36 Order to entropy: the body between states, 37 Leaving the lab: the show

The short track's mini project, extended into the capstone: the same body carried through the year (after Learning Processing's Zoog and The Nature of Code's Ecosystem Project), now a room of hybrid bodies in your hall of the endless museum that is also a small complete game: player, input, camera, UI, save/load, audio and a build. Milestones: c15 first sheet and brief; c28 debt audit, recipe saved as .tres, mid-year review; c33 published JSON remix; c35 capstone proposal (two units before the end, after Aesthetic Programming ch9); c37 show and hand-over. Pause weeks with no new code idea come after c15 and c28 (after Aesthetic Programming) and give the declared returns their place.

## The chapters at a glance

| n | part | chapter | spine (order) | new code | argument axis | departure |
|---|---|---|---|---|---|---|
| 1 | foundation | Bring a body: a scan meets a point (S) | primitives (1) | statements, output, import_assets | triangles in the scan (set with Blender's Decimate modifier before export) | yes |
| 2 | foundation | The engine calls you: a point that lives (S) | primitives (1) | variables, lifecycle, properties | point radius (m) |  |
| 3 | foundation | Solid or ghost: what you see and what stops you (S) | primitives (1) | calling, physics_bodies, collision | collider radius as a fraction of the visible radius (Debug > Visible Collision Shapes on) |  |
| 4 | foundation | Where is a body? Coordinates, frames and the hand (S) | primitives (1), transformation (2) | vectors, transforms, xr | the parent's scale |  |
| 5 | foundation | Two points make a relation: the line | primitives (1), forces (7) | expressions, methods, errors | line thickness as a fraction of its length |  |
| 6 | foundation | Klee's walk: the trace | primitives (1) | arrays, conditions, input | gate distance (m) before a new position is kept |  |
| 7 | foundation | Many bodies: the grid as an instruction (S) | primitives (1), array_tutorial (3) | loops, nested_loops, ai_assist | gap between cells as a fraction of the cell size |  |
| 8 | foundation | Chance as a value: Schotter | array_tutorial (3), randomness (10) | random, interpolation, booleans | maximum disorder at the last row (radians) | yes |
| 9 | foundation | A body that notices: the floor that answers | randomness (10), primitives (1) | areas, signals, lifetime | fraction of stepped-on slabs that vanish | yes |
| 10 | foundation | A body of parts: pivots and frames | transformation (2) | composition, basis | pivot position along each segment (0 = base, 1 = tip) | yes |
| 11 | foundation | Colour as a family: the first @export (S) | color (4) | materials, export, functions | number of bands N |  |
| 12 | foundation | A body type: the class that crosses a category | primitives (1) | classes, types, trig | base_sides | yes |
| 13 | foundation | Surfaces from vertices: can you stand on it? | primitives (1), wavefunctions (9) | meshes, surface_tool, normals | grid resolution n | yes |
| 14 | foundation | The tile and its repeats | tiling (5) | uv, parameters, return | repeat rule |  |
| 15 | foundation | Synthesis I: the specimen sheet (S) | color (4), primitives (1) | instancing, groups, files | share of the body that is procedural | yes |
| 16 | debt | Time in slices: the staircase under the curve | change (6) | delta, setters, tool_scripts | number of slices n |  |
| 17 | debt | The integrator owes: forces, and the walker opened | forces (7) | forces, integration, player | time step (s) |  |
| 18 | debt | Good enough: form found by relaxation | formfinding (8) | packed_arrays, profiling | constraint iterations per frame |  |
| 19 | debt | Pendulum, circle, spiral: sampled waves and sound | wavefunctions (9) | audio, timers, await | radius growth per turn |  |
| 20 | debt | Pseudo: the seed returns | randomness (10) | seeds, save_load | seed | yes |
| 21 | debt | Noise: chance with memory, and the blob (S) | noise (11) | noise, multimesh | noise type |  |
| 22 | debt | Shaders: the pixel computes, the collider stays (S) | shaders (12) | shaders, uniforms | displacement amplitude (m) |  |
| 23 | debt | Rules and their edge: cellular automata | cellularautomata (13) | buffers, debugging | rule number |  |
| 24 | debt | Recursion must be stopped: fractal bodies | fractals (14) | recursion | recursion depth |  |
| 25 | debt | Grammar: the turtle, its stack, and the building | lsystems (15) | strings, dictionaries, stacks | turn angle, same grammar |  |
| 26 | debt | Implicit bodies: the lookup table and the neck | isosurfaces (18) | testing | smooth-minimum blend radius k (m), sources 0.5 m apart | yes |
| 27 | debt | Bias: the model is a picture of its data | machinelearning (21), postfoundationscrisis (25) | ui, sorting | share of training bodies from the majority class | yes |
| 28 | debt | Synthesis II: the debt audit | noise (11), primitives (1) | resources | one quality @export that scales every budget at once (triangles, octaves, iterations, depth) | yes |
| 29 | ontology | A generated world you can get lost in | proceduralgeneration (16) | navigation, queues | corridor width relative to the walker's diameter |  |
| 30 | ontology | Graphs: the world as a network | graphtheory (22) | graphs, search | search algorithm | yes |
| 31 | ontology | Soft: polycount against deformation | softbodies (17) | raycasts, particles | triangles in the scan used as a soft body |  |
| 32 | ontology | Morphogenesis: Turing's pattern on your skin | softbodies (17), shaders (12) | threads | feed/kill regime | yes |
| 33 | ontology | Cut and join: collage bodies (S) | boolean_surfaces (19) | json | operation |  |
| 34 | ontology | Many bodies choose: swarms | swarmintelligence (20) | inheritance | separation weight |  |
| 35 | ontology | Impossible space: the camera decides | foundationscrisis (23) | camera | camera offset from the designed standpoint (degrees) |  |
| 36 | ontology | Order to entropy: the body between states | qfeplaboratory (24) | state_machines | λ |  |
| 37 | ontology | Leaving the lab: the show (S) | postfoundationscrisis (25) | export_build | platform |  |

(S) = in the short track. Every chapter has a hall carrier or field trip that exists in spine.json [V], a debt and a place.

## Chapters

### I. Foundation: the lab

#### 1. Bring a body: a scan meets a point

- **Spine:** primitives. **Halls:** Point_Zero (encounter); Primitives_Ignorance (field trip)
- **Code:** new statements, output, import_assets
- **Body:** Your own body, or an object you own, scanned with a phone photogrammetry app or drawn in Tilt Brush / Open Brush, exported as .glb and dropped at 1:1 into the Day Zero base scene next to one point; a one-line script prints a greeting and the body's name to the Output panel.
- **Argument:** axis triangles in the scan (set with Blender's Decimate modifier before export), values 100000 / 10000 / 1000 / 200. *Predict:* 100k and 10k will look most alike from 2 m: the body covers fewer screen pixels than 10k triangles have faces. The break comes between 1k and 200, where the silhouette turns into facets. *Claim:* Below about a thousand triangles a scanned body stops reading as a person and starts reading as a polyhedron; above about ten thousand the extra triangles are invisible from where a visitor stands.
- **Debt:** A scan is a reconstruction, not a recording: holes where the camera did not look, light baked into the texture, the back you never captured, surfaces averaged from many photos. Photogrammetry fails on dark, shiny, hairy and moving surfaces [mem], so who and what scans well is not neutral. This is the course description's own triad: stretchability, topology, bias ('töjbarhet, topologier, bias' [V]).
- **Place:** Stand beside your double at 1:1 in a room it never stood in; walk around it and find the side the scanner missed. XR route (supplied rig): see it at your own eye height.
- **Godot:** Import dock: .glb/.gltf scenes; Node3D, MeshInstance3D; print(); Output panel; Debugger > Monitors (primitives drawn); doc/book/studies/day-zero/base.tscn (supplied)
- **Lineage:** Processing: LP ch1-2 (pixels; running a sketch); Handbook Structure 1 (code elements). NoC: below NoC's entry level. Application: polycount against smooth deformation (application l.89) met on day one. Klee: before I.1: the body as given, before the point sets off. Reference: Queer 3D World week 1 (3D scanning, Tilt Brush, export to Blender) [V]; UCSC AGPM 129 'make before the tool'; Anthropy's Twine book shares a work in chapter 1.
- **Departure:** Adds a strand the spine does not have: bringing in a scanned or sculpted body, the Queer 3D course's first day. Primitives_Ignorance (the tenth primitives hall) is visited on day one as a field trip because it asks the same polycount question of a sphere.
- **Project step:** Mini project, day 1: choose the body you will carry all course (scan, sculpt or found model) and keep its four decimation levels.

#### 2. The engine calls you: a point that lives

- **Spine:** primitives. **Halls:** Point_Zero (carrier); Point_One (field trip)
- **Code:** new variables, lifecycle, properties; returns statements, output
- **Body:** A point: a supplied MeshInstance3D with a SphereMesh whose radius and position your script sets in _ready(); a counter raised in _process() shows on a Label3D (the point-zero kit).
- **Argument:** axis point radius (m), values 0.005 / 0.02 / 0.1 / 0.5. *Predict:* 0.005 and 0.02 will look most alike from 2 m, both a dot; 0.1 already reads as a ball and 0.5 as a body you could bump into. *Claim:* A mathematical point has no size but a drawn one must: at arm's length the dot turns into a ball somewhere between 2 and 10 cm.
- **Debt:** The engine cannot draw nothing: the 'point' is a sphere of 32 x 16 segments, about a thousand triangles standing in for zero size. And the counter counts frames, not seconds; on a faster screen it runs faster. That debt is repaid with delta in chapter 16.
- **Place:** Walk to the point and through it: it has no boundary yet, so your walker passes through it like a ghost.
- **Godot:** _ready(), _process(); var; SphereMesh.radius; Node3D.position; Label3D.text; doc/book/studies/point-zero/hello_world.tscn
- **Lineage:** Processing: LP ch3-4 (setup/draw = _ready/_process; variables); Handbook Data 1. NoC: below entry. Application: not listed (a basic element no work package names). Klee: I.1 the dot before its walk. Reference: Queer 3D Foundation layer, 'a typical science lab' [V]; Learn GDScript From Zero lessons 1-10 (statements before the game loop).
- **Project step:** Put a point at a landmark on your scanned body (the nose, a knuckle) from code; its radius is your first variable.

#### 3. Solid or ghost: what you see and what stops you

- **Spine:** primitives. **Halls:** Point_One (carrier); Primitives_Polythedra (encounter)
- **Code:** new calling, physics_bodies, collision; returns variables, properties, lifecycle
- **Body:** Three points built entirely in code (SphereMesh.new(), MeshInstance3D.new(), StaticBody3D + CollisionShape3D + SphereShape3D, add_child), one visible radius and a different boundary each.
- **Argument:** axis collider radius as a fraction of the visible radius (Debug > Visible Collision Shapes on), values none / 0.5x / 1x / 2x. *Predict:* 'none', '0.5x' and '1x' will look identical in a still without the debug overlay; with it, 1x and 0.5x are the closest pair. The boundary is invisible to the camera. *Claim:* What you see and what stops you are two different bodies; a still shows the second only when a debug overlay draws it.
- **Debt:** The collider is a second, simpler body the eye never sees. Every game body is a pair, a picture and a boundary, and they are allowed to disagree. First critique of a starter (after Montfort's 'Critique My Starter Programs'): which bodies does Godot give you by default (the capsule, the cube) and who are they for?
- **Place:** Walk into each point: pass through the ghost, stop at the solid, and be stopped early by the 2x boundary, an invisible wall around a body larger than it looks.
- **Godot:** SphereMesh.new(), MeshInstance3D; StaticBody3D, CollisionShape3D, SphereShape3D; add_child(); Debug > Visible Collision Shapes; doc/book/studies/point-one/study.tscn
- **Lineage:** Processing: LP ch8 as a user (objects you call but did not write); Handbook Shape 1. NoC: NoC 6 physics libraries, named only. Application: not listed. Klee: I.2-I.4 active, medial and passive: the point that acts and the point acted upon. Reference: Point One's solid/ghost distinction; Gaboury, Image Objects ch3 (the Utah teapot: which bodies are default); Queer 3D: the lab 'also has something uncanny' [V].
- **Project step:** Give your scanned body a boundary two ways (the automatic convex shape, a hand-sized box); walk into both and note where picture and boundary disagree.

#### 4. Where is a body? Coordinates, frames and the hand

- **Spine:** primitives, transformation. **Halls:** Point_Coordinates (carrier); Trans_Introduction (field trip); Trans_Scale (encounter)
- **Code:** new vectors, transforms, xr; returns properties, variables, physics_bodies, collision
- **Body:** A constellation of points as children of one parent Node3D; you move, rotate and scale the parent and watch position (local) and global_position (world) disagree.
- **Argument:** axis the parent's scale, values 0.25 / 1 / 2 / 4. *Predict:* 1 and 2 will look most alike in a framed still (same shape, the camera reframes); at 0.25 the constellation is a jewel, at 4 it is a room you stand inside. *Claim:* A body's numbers are relative to its parent: the same local coordinates make a jewel or a room depending on one frame above them.
- **Debt:** 'Where' always means 'where relative to what'. The world origin is a convention, and far from it float precision starts to jitter [mem]. A carried object is re-parented to the hand: a second frame the code must know about.
- **Place:** Carry it. On the XR route pick up a point with the supplied XR Tools pickup (ruling: pickup belongs to Point Coordinates); on desktop, the supplied crosshair carry. Scale the parent to 4 and stand inside your own constellation.
- **Godot:** Vector3; position vs global_position; Transform3D, to_global(), to_local(); XRToolsPickable (supplied); commons/scenes/vr_staging.tscn (supplied XR rig); doc/book/studies/point-coordinates/coordinates.tscn
- **Lineage:** Processing: LP ch14 transformations, met ten chapters early because a Godot node IS a transform. NoC: NoC 1.1 'the point of vectors'. Application: 'noise and vectors' as basic concepts (application l.9). Klee: II.14-II.17 dimension; the viewer's shifting axis. Reference: Queer 3D week 2 'VR in Unity' [V] moved to week 1; research_creative: transform early is where agreeing with the spine is right.
- **Project step:** Parent your scan and your points to one Node3D; keep stills at scale 0.25 and 4.

#### 5. Two points make a relation: the line

- **Spine:** primitives, forces. **Halls:** Point_Lines (carrier); Vectors_Act1_WhatAVectorIs (field trip)
- **Code:** new expressions, methods, errors; returns vectors, variables, lifecycle, properties
- **Body:** A line body: a thin box stretched between two carried points by the supplied show_between() (segment.gd), with b - a and its length printed while either end moves.
- **Argument:** axis line thickness as a fraction of its length, values 0.002 / 0.01 / 0.05 / 0.25. *Predict:* 0.002 and 0.01 will look most alike (both a drawn mark); at 0.25 the 'line' is a beam you could stand on. *Claim:* A line in 3D is a stretched body: its thickness decides whether it reads as a mark, a rod or a beam.
- **Debt:** Break it on purpose (the W01 workshop): predict each error before running (a typo, a null node, a method that does not exist), then read Godot's exact message and the class reference. 'Valid and intentional are different' (Montfort). The line is a box pretending to have one dimension.
- **Place:** Carry the two ends apart until the line crosses the room; walk under the beam version.
- **Godot:** b - a, length(), distance_to(), normalized(); segment.gd show_between() (supplied); Debugger error messages; class reference (F1); doc/book/studies/point-lines/line.tscn
- **Lineage:** Processing: LP ch2 errors, ch5 expressions; Handbook Math 1. NoC: NoC 1.1-1.5 (b - a, magnitude). Application: vectors (application l.9). Klee: I.2 a line limited by two fixed points. Reference: Montfort, Exploratory Programming ch4; GDQuest's lesson 2 'your first error'; ruling: distance belongs to Point Lines.
- **Project step:** Draw three lines from code between landmarks on your scanned body, a skeleton of distances, and print their lengths.

#### 6. Klee's walk: the trace

- **Spine:** primitives. **Halls:** Point_Trace (carrier); Random_Walk (encounter)
- **Code:** new arrays, conditions, input; returns vectors, methods, expressions, errors
- **Body:** A recorder: while a named input action is held, the carried point appends its position to an Array[Vector3] only if it has moved more than a gate distance; each kept position becomes a small sphere (the point-trace kit).
- **Argument:** axis gate distance (m) before a new position is kept, values 0.005 / 0.02 / 0.1 / 0.4. *Predict:* 0.005 and 0.02 will look most alike, both a continuous line; at 0.4 the trace becomes separate stepping stones. *Claim:* A trace is a sampling: the gate decides whether a walk is kept as a line or as a row of stones.
- **Debt:** The walk is continuous and the list is not: everything between two kept samples is lost, and a capped list forgets its own beginning (pop_front). The condition is taught before the distance threshold (standing ruling).
- **Place:** Walk while holding the action: your own route becomes a line you can later walk back along.
- **Godot:** Array[Vector3]: append(), size(), pop_front(); if / elif / else; InputMap actions, Input.is_action_pressed(); doc/book/studies/point-trace/trace.tscn
- **Lineage:** Processing: LP ch5 conditionals, ch9 arrays (mouse history); Handbook Control 1, Data 4. NoC: NoC 0 walker's trail, named. Application: not listed. Klee: I.1 'an active line on a walk'. Reference: Queer 3D Foundation question 'how do points, lines and the grid work' [V]; rulings: list before append, condition before a distance threshold.
- **Project step:** Walk around your scanned body holding the action: the first thing in your hall made by your own movement.

#### 7. Many bodies: the grid as an instruction

- **Spine:** primitives, array_tutorial. **Halls:** Point_Line_Grid (carrier); Array (field trip); Tutorial_Tiling_Floor (encounter)
- **Code:** new loops, nested_loops, ai_assist; returns arrays, conditions, calling, physics_bodies, collision, vectors
- **Body:** A floor of cubes built by two nested for-loops, each cube with a collider: first written as a LeWitt-style instruction in plain words, then generated by an AI assistant, then read, run and corrected by you.
- **Argument:** axis gap between cells as a fraction of the cell size, values 0 / 0.05 / 0.3 / 1.0. *Predict:* 0 and 0.05 will look most alike from standing height (a floor with seams); the break is between 0.3 and 1.0, where the floor turns into stepping stones. *Claim:* Repetition becomes structure when the gap is smaller than the foot: one loop makes a floor or a set of stones.
- **Debt:** The AI protocol, after LeWitt's instruction-as-work: write the instruction, predict the grid, ask the AI, run it, and mark every place the AI had to guess (cell size? corner or centre origin? which axis is up?). The guesses are the debt. Write down what must not change and which observation would prove the code wrong.
- **Place:** Stand on it, then cross it at each gap: at which gap does your walker fall through?
- **Godot:** for i in range(n); nested for; BoxMesh + BoxShape3D per cell; any AI assistant, with the instruction kept as a comment above the code
- **Lineage:** Processing: LP ch6 loops (nested grid); DBN 'Line' then 'Lines'; Handbook Control 2. NoC: below entry. Application: not listed. Klee: I.5-I.6 'purely repetitive and therefore structural'; the chessboard. Reference: Queer 3D course description: 'use ChatGPT to write simpler programs that can activate and generate 3D' [V]; LeWitt; research_bauhaus's ai_assist protocol; ruling: grids are not prerequisites for the first line.
- **Project step:** Build a plinth or floor for your body out of a loop and decide its gap.

#### 8. Chance as a value: Schotter

- **Spine:** array_tutorial, randomness. **Halls:** Array (carrier); Randomness_10_PRINT_Algorithm (field trip); Random_Rotate_Random_XYZ (encounter)
- **Code:** new random, interpolation, booleans; returns loops, nested_loops, transforms, collision
- **Body:** Nees's Schotter as a walkable floor: a grid of slabs whose random rotation and offset grow row by row (lerp from 0 to a maximum), plus a 10 PRINT row where randf() < 0.5 chooses one of two diagonals (Array's molnar_cube_study carries the same disorder on a lattice).
- **Argument:** axis maximum disorder at the last row (radians), values 0 / 0.2 / 0.6 / 1.5. *Predict:* 0 and 0.2 will look most alike: a little disorder still reads as a grid. The grid 'breaks' somewhere past 0.6. *Claim:* Randomness needs a regular grid to be seen: the row where the grid stops reading as a grid is where chance becomes the subject.
- **Debt:** Unseeded randf() gives a new floor every run, so no still can be repeated; that debt is repaid in chapter 20. Nake's Hommage à Paul Klee (1965) asks whether a random number can stand in for intuition.
- **Place:** Walk down the Schotter floor: at which row does the disorder make it unwalkable?
- **Godot:** randf(), randf_range(); lerp(); Node3D.rotate_y(); randf() < 0.5 as a bool
- **Lineage:** Processing: LP ch4 random() as a value; Handbook Math 4 Random. NoC: NoC 0 met as a value only. Application: WP1 Basic Elements begins with randomness. Klee: Klee has no chance; Nake adds it to Klee's 'Hauptweg und Nebenwege'. Reference: Queer 3D Foundation's first question: 'what is randomness and how can it be visualised?' [V]; 10 PRINT's 'Regularity' before 'Randomness'; Recreating the Past week 1 (Molnar).
- **Departure:** Randomness (spine 10) is met early, at array_tutorial's place (3), as a VALUE disturbing a grid already built: the Queer 3D course asks it first, the application puts it in WP1, and every creative-coding tradition meets random() early. Randomness as a TOPIC keeps its spine place in chapter 20, as a declared return.
- **Project step:** Scatter ten copies of a small primitive around your scan with a disorder ramp; note which amount still reads as arranged.

#### 9. A body that notices: the floor that answers

- **Spine:** randomness, primitives. **Halls:** Random_Remove (carrier); Point_One (field trip); Point_Lines (encounter)
- **Code:** new areas, signals, lifetime; returns nested_loops, random, booleans, conditions, collision
- **Body:** The Schotter floor again, now with an Area3D over each slab: when your walker enters, the slab emits a signal, lights up, and a moment later is freed.
- **Argument:** axis fraction of stepped-on slabs that vanish, values 0 / 0.1 / 0.3 / 0.7. *Predict:* 0 and 0.1 will look most alike in a still taken after a walk (a floor with a few holes); at 0.7 your path is printed as an absence. *Claim:* A floor that answers keeps a negative trace: after the walk, the holes are a picture of where a body went.
- **Debt:** A signal is only as wide as its area: a body moving far enough between two physics frames can skip it. A freed node is gone; nothing remembers it unless you record it.
- **Place:** Walk it: the floor disappears behind you, Klee's walk inverted into a missing floor.
- **Godot:** Area3D.body_entered; signal, connect(), emit(); queue_free(); point_sun_switch (Point_One) as the model
- **Lineage:** Processing: LP ch3 interaction (events); Handbook Input 1-2. NoC: below entry. Application: not listed. Klee: I.1 the walk, as removal. Reference: Squash the Creeps parts 6-7 (areas, signals) as the game kit's first event; Queer 3D: the uncanny inside the lab.
- **Departure:** Random_Remove (spine 10) carries a Part I chapter because the first event a body meets should be a floor responding to it; its seeded draw waits for chapter 20.
- **Project step:** Give your hall one thing that notices the visitor near your body (light now, sound in chapter 19).

#### 10. A body of parts: pivots and frames

- **Spine:** transformation. **Halls:** Trans_Rotation (carrier); Trans_Body (carrier); Trans_Pit (encounter)
- **Code:** new composition, basis; returns transforms, vectors, loops, physics_bodies
- **Body:** A limb of three segments, each a child of the one before (bone, tendon, muscle after Klee I.9), posed by setting each joint's Basis from an angle.
- **Argument:** axis pivot position along each segment (0 = base, 1 = tip), values 0 / 0.5 / 1.0 / 1.5. *Predict:* 0 and 0.5 will look most alike at small angles; at 1.5 the pivot sits outside the segment and the limb swings like a door instead of bending. *Claim:* A body of parts is a tree of frames: where the pivot sits decides whether it bends like a limb or swings like a door.
- **Debt:** A Basis mixes rotation and scale: scale a parent unevenly and every child shears. Euler angles hide gimbal lock (Random_Rotate_Random_XYZ). A hierarchy always has a parent. Klee's own passage maps active/passive organs onto male/female: name that as the dark spot of the source this course 'puts in drag'.
- **Place:** Ride it: stand on the carousel (Trans_Rotation) or pass the slatted wall that opens as you approach (Trans_Body). Pose a limb from your scan's shoulder.
- **Godot:** child Node3D as composition; Basis(axis, angle), Basis.from_euler(); a pivot as an offset child; look_at()
- **Lineage:** Processing: LP ch14 push/pop, rotate about a pivot; Handbook Transform 1-2. NoC: NoC 3 angular motion (static here). Application: not listed. Klee: I.9-I.10 bone, ligament, tendon, muscle as active, medial and passive organs. Reference: Queer 3D lineage: Bellmer's jointed doll, collage and hybrid form [V]; Form+Code puts Repeat before Transform.
- **Departure:** Transformation (spine 2) comes after array_tutorial (3): a body of parts needs many parts first (Form+Code's Repeat before Transform), and position and frame were met in chapter 4.
- **Project step:** Attach a jointed appendage built from primitives to your scan (Code as Creative Medium's 'Personal Prosthetic').

#### 11. Colour as a family: the first @export

- **Spine:** color. **Halls:** Color_Rainbow (carrier); Color_Context_Placed (field trip); Color_Walls (encounter); Color_Flashlight (encounter)
- **Code:** new materials, export, functions; returns loops, calling, interpolation
- **Body:** An arch of N bands, each a primitive with its own StandardMaterial3D coloured by Color.from_hsv(i / N, s, v); N is an @export, so the Inspector turns one script into a family, and make_band(i) is your first own function.
- **Argument:** axis number of bands N, values 3 / 7 / 12 / 48. *Predict:* 12 and 48 will look most alike: above about twelve the eye stops counting bands and sees a gradient. *Claim:* Quantity turns into continuity: above about twelve bands the arch stops being a sequence of colours and becomes one gradient.
- **Debt:** HSV is a model, not the eye: equal hue steps are not equal perceived steps (the yellow band looks brighter), and the material colour is not the screen colour (light, tonemapping, sRGB). Albers: a colour has many faces.
- **Place:** Walk through the arch; change its light (Color_Flashlight) and watch the family change with no change to the code.
- **Godot:** StandardMaterial3D.new(), albedo_color; Color.from_hsv(); @export var n: int; func make_band(i)
- **Lineage:** Processing: LP ch1 RGB, ch7 functions; Handbook Color 1. NoC: below entry. Application: not listed (shading is WP3). Klee: IV.43 the colour circle, met here as appearance; its energy returns in chapter 22. Reference: Albers, Interaction of Color ('make two colours look alike'); Aesthetic Programming ch2; ICM's double titles ('A family: @export').
- **Project step:** Expose one @export on your body's material (hue, saturation or banding) and render three values side by side.

#### 12. A body type: the class that crosses a category

- **Spine:** primitives. **Halls:** Primitives_Melencolia (carrier); Primitives_Portals (field trip); Primitives_Polythedra (encounter)
- **Code:** new classes, types, trig; returns export, functions, loops, vectors, methods
- **Body:** 'Describe a body in a single class': class_name Pyramid with typed @exports base_sides: int and height: float; the base ring is placed with cos/sin in a loop and joined to the apex with the line helper from chapter 5 (a wireframe body; faces come in chapter 13).
- **Argument:** axis base_sides, values 3 / 4 / 6 / 12 / 48. *Predict:* 12 and 48 will look most alike, both a cone. 3 and 4 differ most in name (tetrahedron, pyramid) and least in number. *Claim:* With enough sides a pyramid is a cone: one integer parameter crosses a named category, and nothing in the class marks where.
- **Debt:** The circle is never drawn, only approximated by n sides (Primitives_Portals: circular approximation and limits). The class decides which properties a body has, so it decides what can vary: the modelling choice is the critique.
- **Place:** Carry the pieces of Melencolia's snap pyramid and assemble a body you then stand inside at 1:1.
- **Godot:** class_name; typed vars, @export_range; cos(), sin(), TAU; an instance per body type
- **Lineage:** Processing: LP ch8 objects (Zoog as a class), ch13 trig; Handbook Shape 3 Parameters. NoC: NoC 3 angles and trig, named. Application: polycount (application l.89). Klee: I.7 proportion (2:3:5, the golden section). Reference: CCSWG 2024 'describe war in a single class', turned to bodies; Queer 3D debt: algorithms taken for granted are simplifications [V].
- **Departure:** Returns to primitives halls (Melencolia, Portals) after colour: the class and the circle's approximation need @export and functions first.
- **Project step:** Wrap your body's procedural part in a class with two typed @exports.

#### 13. Surfaces from vertices: can you stand on it?

- **Spine:** primitives, wavefunctions. **Halls:** Point_Triangle_Context (carrier); WaveFunctions_Sine_Space (field trip); Point_Animatedcube (encounter)
- **Code:** new meshes, surface_tool, normals; returns nested_loops, trig, functions, collision, classes
- **Body:** A triangle from three Vector3s, then a heightfield y = sin(x) cos(z) built with SurfaceTool on an n x n grid, generate_normals(), and a trimesh collider made from the same vertices.
- **Argument:** axis grid resolution n, values 2 / 4 / 8 / 32. *Predict:* 8 and 32 will look most alike from standing height with smooth normals; 2 is a folded plane, not a wave. *Claim:* The surface you walk on and the surface you see are one list of vertices: at low resolution you walk on a polyhedron, not on the wave.
- **Debt:** Smooth normals lie about the shape: they make 8 look like 32 while the collider keeps 8's facets (roll a ball and it bumps). Winding order decides which side exists: Godot winds front faces clockwise.
- **Place:** Stand on it; drop spheres and watch them roll over facets you cannot see.
- **Godot:** ImmediateMesh; SurfaceTool begin / add_vertex / generate_normals / commit; ArrayMesh; create_trimesh_shape(), ConcavePolygonShape3D
- **Lineage:** Processing: LP ch14 vertex shapes; Handbook Shape 2 Vertices; PShape. NoC: below entry. Application: 'queer meshes and textures' (WP2); polycount (l.89). Klee: I.3-I.4 medial lines whose figures read as planes. Reference: Catlike Coding Basics 2-3 (a graph becomes a surface); Moholy-Nagy material, then volume; Queer 3D debt 'deformation and polygon count' [V].
- **Departure:** WaveFunctions_Sine_Space (spine 9) is visited early as 'the graph', following the engine tradition's graph-to-surface ladder; the wave sequence keeps its place in chapter 19.
- **Project step:** Build your hall's floor from a function and check that your scan's feet meet it.

#### 14. The tile and its repeats

- **Spine:** tiling. **Halls:** Symmetry_Seventeen (carrier); Pattern_Foundry (field trip); Tutorial_Pattern (encounter); Ribbon_Patterns_02 (encounter)
- **Code:** new uv, parameters, return; returns nested_loops, arrays, conditions, materials, functions
- **Body:** A 4 x 4 motif and a function get_color(x, y) -> Color that returns it under a repeat rule, baked into an Image and wrapped as a texture on a floor and on your chapter-13 surface.
- **Argument:** axis repeat rule, values p1 (translate) / pm (mirror) / pg (glide) / p4m (mirror and quarter turns). *Predict:* pm and pg will look most alike if the motif is itself mirror-symmetric: on a symmetric tile the glide is invisible. *Claim:* Two symmetry rules can make the same floor: the group you see depends on the motif as much as on the rule.
- **Debt:** Texture filtering: nearest against linear blurs the seams, mipmaps turn a fine pattern grey from standing height, and UVs stretch on a curved surface (the Ribbon halls).
- **Place:** Walk on the patterned floor; lay the pattern on your wave surface and find where it stretches.
- **Godot:** Image.create(), set_pixel(); ImageTexture; UV, texture repeat, filter; func get_color(x: int, y: int) -> Color
- **Lineage:** Processing: LP ch15 images and pixels; Handbook Image 1. NoC: below entry. Application: WP3 pattern and world building, named early. Klee: I.6 the chessboard: structure as repetition. Reference: Book of Shaders ch9 Patterns; Queer 3D lineage: Escher's Metamorphosis [V]; Albers's 'two different colours look alike' turned into a symmetry problem.
- **Project step:** Give your body a patterned skin or plinth with one repeat rule.

#### 15. Synthesis I: the specimen sheet

- **Spine:** color, primitives. **Halls:** Color_Context_Placed (carrier); Primitives_Ignorance (field trip); Tutorial_3D (encounter)
- **Code:** new instancing, groups, files; returns classes, export, loops, import_assets
- **Body:** Your hybrid so far (the scan plus one procedural family) saved as a PackedScene, instanced four times at four values of one @export, lined up, put in a group, and photographed by a supplied sheet camera into one PNG in user://.
- **Argument:** axis share of the body that is procedural, values scan only / scan + one procedural part / scan + three procedural parts / procedural only. *Predict:* 'scan only' and 'scan + one part' will look most alike: a small procedural part reads as an accessory until it changes the silhouette. *Claim:* A hybrid reads as a new body only once the procedural part changes the silhouette; before that it reads as a costume.
- **Debt:** The sheet shows one standpoint, and a family that changes on a face the camera does not see will look inert (Ada's own measurement: five of seven 'dead' DNA verdicts were false). Write the ReadMe beside the code and one debt comment inside it.
- **Place:** Your hall: the four instances stand in a row in your room of the endless museum; walk the row at visitor height.
- **Godot:** PackedScene.instantiate(); add_to_group(), get_nodes_in_group(); get_viewport().get_texture().get_image().save_png('user://...'); supplied sheet camera script
- **Lineage:** Processing: Handbook Synthesis 1 (form and code); LP lesson-end projects. NoC: NoC's Ecosystem Project step (a creature for a museum). Application: each package's workshop-test-document cycle. Klee: the part-end key sentence. Reference: Queer 3D mini project shown to the class [V]; Generative Design's numbered variants; Ada's DNA sheets and dna.predicted_degeneracy; Aesthetic Programming RunMe/ReadMe.
- **Departure:** A synthesis chapter: it returns to colour (spine 4) and primitives (1) halls after tiling (5) because it gathers Part I, not because a hall needs it here.
- **Project step:** SHORT TRACK PIVOT (end of week 2): write the mini-project brief (body, axis, prediction, place) and render the first sheet.

### II. The uncanny and algorithmic debt

#### 16. Time in slices: the staircase under the curve

- **Spine:** change. **Halls:** Change_Intro (carrier); Flow_Field (encounter); Point_Zero (encounter)
- **Code:** new delta, setters, tool_scripts; returns export, loops, functions, instancing, collision, lifecycle
- **Body:** A Riemann staircase: n pillars under a curve, rebuilt live in the editor by an @tool script whenever n's setter runs; then the curve set moving with delta so it keeps one speed on any screen.
- **Argument:** axis number of slices n, values 2 / 4 / 8 / 64. *Predict:* 8 and 64 will look most alike from across the hall; up close 64 is a ramp and 8 is still a stair. *Claim:* The staircase approaches the curve and never becomes it: the approximation's debt shrinks with n and never reaches zero.
- **Debt:** The frame is the computer's slice of time. _process runs once per frame, so chapter 2's counter counted frames; delta pays that back. The integral is a sum and the curve on screen is a polyline. Part I's bodies held still; from here everything moves, and every motion is sampled.
- **Place:** Walk up the staircase at each n. With the capsule walker, at which step height does the stair stop being climbable? [mem: CharacterBody3D has no automatic step-up; the capsule's round foot climbs only small steps. Test it.]
- **Godot:** _process(delta); @tool; var n: int: set(v): n = v; rebuild(); @export_range
- **Lineage:** Processing: Handbook Structure 2 Continuous (the draw loop opens part 2). NoC: NoC 1 motion 101 (velocity per frame). Application: not listed. Klee: II.14 dimension: a stair between two planes. Reference: Queer 3D debt: algorithms as 'negotiations with what mathematics cannot answer' [V]; the Processing Handbook's static before continuous.
- **Project step:** Make one property of your body live: a setter plus @tool, so dragging it in the Inspector rebuilds the body in the editor.

#### 17. The integrator owes: forces, and the walker opened

- **Spine:** forces. **Halls:** Vectors_Act3_FieldsAndMotion (carrier); VFM_05_Launch (carrier); Vectors_Act5_ForceAsPlace (field trip); VFM_03_Motion (encounter)
- **Code:** new forces, integration, player; returns vectors, delta, areas, signals, physics_bodies, arrays
- **Body:** A thrown body integrated three ways (your Euler step, your semi-implicit step, Godot's RigidBody3D), drawn as three trails beside the exact parabola; then the supplied first-person walker is opened, and its gravity turns out to be an integrator too.
- **Argument:** axis time step (s), values 0.1 / 0.033 / 0.0167 / 0.004. *Predict:* 0.0167 and 0.004 will look most alike: over a short throw Euler's drift at 60 Hz is under a centimetre; at 0.1 the arc visibly overshoots. *Claim:* Physics in a game is a chosen error: Euler's arc drifts from the true parabola by an amount that grows with the step.
- **Debt:** Integration error, energy from nowhere, results that depend on the physics rate (Ada measured one settling die at 15/16 at 90 Hz and 2/16 at 60 Hz [V memory file]). Critique the starter body: the walker is a 1.8 m capsule. Which body does the engine assume a player is?
- **Place:** Enter the force-as-place zone (Vectors_Act5): gravity is replaced for your walker inside it; throw parts of your body across its edge.
- **Godot:** velocity += a * delta; position += velocity * delta; _physics_process(); RigidBody3D.apply_central_force(); CharacterBody3D.velocity, move_and_slide(), is_on_floor(); Area3D gravity override
- **Lineage:** Processing: LP ch5 hand-rolled gravity; Handbook Motion 1-2. NoC: NoC 1-2 vectors and forces. Application: not listed (NoC lineage). Klee: III.26-III.32 the gravitational curve: falling stone, bullet, 'to stand despite all possibilities to fall'. Reference: GDQuest 3D module 7 (skin vs controller: the walker's body can be swapped for the XR body); Lague shows the failed attempt first.
- **Project step:** Make part of your body fall, be thrown or resist: one part as a RigidBody3D, one moved by an integrator you wrote.

#### 18. Good enough: form found by relaxation

- **Spine:** formfinding. **Halls:** FormFinding_Relaxation (carrier); FormFinding_Catenary (field trip); FormFinding_Equilibrium (encounter); FormFinding_Forge (encounter)
- **Code:** new packed_arrays, profiling; returns classes, integration, loops, arrays, delta
- **Body:** A hanging net of Verlet points in a PackedVector3Array with distance constraints, relaxed a set number of iterations per frame between two anchors you can grab.
- **Argument:** axis constraint iterations per frame, values 1 / 3 / 10 / 50. *Predict:* 10 and 50 will look most alike (the net has reached its catenary); at 1 it sags like rubber. *Claim:* The solver stops when the error is invisible, not when it is zero, and the frame budget decides where that is.
- **Debt:** 'Good enough' is a decision: iterations cost milliseconds (read them in the Profiler), and stiffness here is a side effect of the iteration count, not a material. Von Neumann, quoted in the Queer 3D intro: truth is too complicated for anything but approximations [V].
- **Place:** Grab an anchor and walk; the net follows. Walk under the catenary arch (FormFinding_Catenary).
- **Godot:** PackedVector3Array; a RefCounted solver class; Debugger > Profiler, Performance.get_monitor(); Time.get_ticks_usec()
- **Lineage:** Processing: Handbook Simulate 2 Physics. NoC: NoC 6 constraints and springs. Application: WP2 soft body simulation (cloth), named early. Klee: II.20-II.25 balance disturbed and corrected. Reference: Queer 3D debt: speed against quality [V]; Moholy-Nagy's balance studies.
- **Project step:** Hang something from your body (a cloth, a chain, a net) and set its iteration count by the frame budget.

#### 19. Pendulum, circle, spiral: sampled waves and sound

- **Spine:** wavefunctions. **Halls:** WaveFunctions_Pendulum (carrier); WaveFunctions_Unit_Circle (carrier); Wavefunctions_Sky_Stairs (field trip); WaveFunctions_Effect_Sound (field trip); WaveFunctions_Synthesis_Lab (encounter); WaveFunctions_John_Cage (encounter)
- **Code:** new audio, timers, await; returns trig, delta, surface_tool, collision, loops, packed_arrays, export
- **Body:** Klee's derivation in code: a pendulum's swing, the same motion as a point going round a circle, and a spiral whose radius grows every turn, swept into a walkable staircase; each crossing plays a tone rendered sample by sample.
- **Argument:** axis radius growth per turn, values -0.2 / 0 / 0.2 / 0.6. *Predict:* 0 (a circle) and 0.2 will look most alike near the start, seen from above; -0.2 closes toward a point and 0.6 flings outward. *Claim:* One parameter turns the circle into Klee's two spirals: negative growth contracts toward a point, positive growth expands without end.
- **Debt:** Sound is a list of samples: 44,100 numbers a second stand in for a continuous wave, and with too few, high frequencies fold back as false tones (aliasing). The spiral is a polyline, the pendulum an integrator (chapter 17), and a Timer fires on the first frame after it is due, not at the moment.
- **Place:** Climb the spiral staircase (Sky_Stairs); stand at the pendulum's crossing and hear it.
- **Godot:** AudioStreamWAV from a PackedByteArray, AudioStreamPlayer3D; Timer.timeout; await get_tree().create_timer(t).timeout; sin(TAU * f * t)
- **Lineage:** Processing: Handbook Math 3 trigonometry; LP ch13. NoC: NoC 3 oscillation. Application: WP1 sine curves and resonance, sound experiments; WP2 Fourier (additive synthesis, encounter). Klee: IV.33-IV.38 spinning top, pendulum, circle ('purest of mobile forms'), expanding or contracting spiral. Reference: research_bauhaus's correction of the Klee order [V]; Recreating the Past (John Whitney); Queer 3D ontology's 'sine-curve space' [V].
- **Project step:** Give your body a sound: a tone derived from its own dimensions (height becomes pitch), played when a visitor comes close.

#### 20. Pseudo: the seed returns

- **Spine:** randomness. **Halls:** Random_Definition (carrier); Random_Cubes (field trip); Random_Entropy (encounter); Random_Gaussian (encounter)
- **Code:** new seeds, save_load; returns random, loops, instancing, physics_bodies, forces, files, conditions
- **Body:** Chapter 8's Schotter floor rebuilt with a RandomNumberGenerator whose seed you choose, save to user:// and load after a restart, so the same 'random' floor comes back.
- **Argument:** axis seed, values 1959 / 1960 / 1959 after a restart / randomize(). *Predict:* '1959' and '1959 after a restart' will be identical pixel for pixel; 1959 and 1960 are as different as any two random floors. *Claim:* Chance under a seed is a pattern that returns: two runs with one seed are one picture.
- **Debt:** Code-critique station (after Critical Code Studies' Kittler chapter): read and annotate about 20 lines of seed_replay_demo and write what 'random' means there. Pseudo-randomness is a deterministic function; a die thrown with a seeded velocity can still land differently at another physics rate. Chun's 'sourcery': reading the script does not show the generator inside the engine.
- **Place:** Throw the seeded die (Random_Cubes) and predict its face; walk the floor that returns.
- **Godot:** RandomNumberGenerator: seed, randf(), randomize(); FileAccess or ConfigFile in user://; OS.get_user_data_dir(); doc/book/studies/random-definition/study.tscn (runnable kit)
- **Lineage:** Processing: LP ch4 random() (a return); Handbook Math 4. NoC: NoC 0 randomness as the topic (Gaussian, walks as encounters). Application: WP1 randomness. Klee: none (Nees, Schotter, 1968). Reference: Queer 3D debt: 'computer randomness is only pseudo-random' [V]; 10 PRINT ch40; the CCS code critique.
- **Departure:** A deliberate return: chance was met as a value in chapter 8; randomness keeps its spine place (10) as a debt topic.
- **Project step:** Seed every random choice in your body and save the seed with it, so the version you show is the version you made.

#### 21. Noise: chance with memory, and the blob

- **Spine:** noise. **Halls:** Noise_Perlin_Simplex (carrier); Noise_Space_10 (carrier); Random_Noise_Types (field trip); Noise_Voxel (encounter)
- **Code:** new noise, multimesh; returns seeds, surface_tool, normals, collision, nested_loops, import_assets, export
- **Body:** Your scan's vertices pushed along their normals by FastNoiseLite (a supplied MeshDataTool helper in the short track), and a noise field of 10,000 cubes drawn as one MultiMesh.
- **Argument:** axis noise type, values simplex / perlin / value / cellular. *Predict:* simplex and perlin will look most alike: both are gradient noises with the rounded 'blob' look; cellular breaks it with ridges and cells. *Claim:* The 'blob aesthetic' belongs to gradient noise, not to noise as such: change the generator and the body stops looking melted.
- **Debt:** The Queer 3D intro names it: noise algorithms produced a 'blob aesthetic' [V]. Noise is smoothed pseudo-randomness under a seed (chapter 20), and octaves finer than a pixel are paid for and never seen (Noise_Space_10's own source comment explains why its ladder stops at four [V via maps/ada.json]).
- **Place:** Walk the noise terrain (Noise_Space_10); stand next to your blobbed double.
- **Godot:** FastNoiseLite: noise_type, seed, frequency, fractal_octaves; MeshDataTool (supplied helper); MultiMeshInstance3D, set_instance_transform()
- **Lineage:** Processing: LP ch13 noise(); Handbook 2nd ed. Random. NoC: NoC 0 Perlin noise. Application: WP1 Perlin noise; Voronoi via TYPE_CELLULAR. Klee: none. Reference: Queer 3D Foundation question 'what is simplex noise, what can we learn from it' and its ontology comparison of noise types by 'overflow rate' [V]; Fuller's Lexicon 'Glitch'.
- **Project step:** Put noise on your scan and decide, from a sheet, which generator your body argues in.

#### 22. Shaders: the pixel computes, the collider stays

- **Spine:** shaders. **Halls:** Shader_09_FBM (carrier); Shader_11_QueerRubber (carrier); Shader_01_Shaping (field trip); Shader_12_PinkExtravaganza (encounter)
- **Code:** new shaders, uniforms; returns materials, uv, noise, collision, export, trig
- **Body:** A rubber skin for your body: a spatial shader that displaces vertices by a wave or fBm in vertex() and draws a fresnel rim in fragment(), its amplitude a uniform set from GDScript.
- **Argument:** axis displacement amplitude (m), values 0 / 0.02 / 0.1 / 0.4. *Predict:* 0 and 0.02 will look most alike in a still; at 0.4 the picture has left the collider 40 cm behind. *Claim:* A shader can move a body's picture as far as it likes while the collider stays where the CPU put it: what you see and what stops you split again.
- **Debt:** The GPU computes every pixel and the CPU never sees the result: chapter 3's solid and ghost at a new scale (Shader_09's hook: visible deformation, unchanged collision). Colour returns as energy (Klee IV). Steyerl's poor image: resolution and compression are political.
- **Place:** Walk into the displaced wall: you collide with the undeformed one.
- **Godot:** ShaderMaterial, .gdshader; shader_type spatial; vertex(), fragment(); uniform float amplitude : hint_range(0.0, 1.0); set_shader_parameter(); TIME, UV, NORMAL, VIEW
- **Lineage:** Processing: Handbook 2nd ed. Render Techniques; PShader named. NoC: not in NoC. Application: WP3 shading algorithms, met here. Klee: IV.39-IV.43 chromatic energy and the colour circle. Reference: Book of Shaders ch5-13; Queer 3D debt 'visibility and invisibility' [V]; Gaboury, Image Objects ch5 'procedure crystallized'.
- **Project step:** Choose chapter 21 (noise on the vertices, CPU) or 22 (displacement in the shader, GPU) for your body, and write what each one owes.

#### 23. Rules and their edge: cellular automata

- **Spine:** cellularautomata. **Halls:** CA_Introduction (carrier); CA_GameOfLife (carrier); CA_EdgeOfChaos (field trip)
- **Code:** new buffers, debugging; returns arrays, booleans, conditions, multimesh, collision, loops, seeds
- **Body:** A bridge grown from an elementary cellular automaton: each generation one row, each live cell a collidable block, computed with a current and a next buffer.
- **Argument:** axis rule number, values 30 / 90 / 110 / 184. *Predict:* 30 and 110 will look most alike from a distance (irregular, full of triangles); 90 is a clean Sierpinski lattice and 184 settles into diagonal traffic. *Claim:* Four rules on one neighbourhood: some grow a bridge you can cross, some a sieve you fall through. The rule number decides walkability.
- **Debt:** Step one generation in the debugger (a breakpoint, the remote scene tree): the second buffer is what stops a rule from reading its own half-written answer. At the edge of chaos one flipped cell (CA_EdgeOfChaos) spreads or dies, and you cannot know which without running it.
- **Place:** Walk the CA bridge; where the rule leaves gaps, you fall.
- **Godot:** two Array[bool] buffers and a swap; (rule >> neighbourhood) & 1; breakpoints, step, Remote scene tree; MultiMesh display + BoxShape3D per live cell
- **Lineage:** Processing: Handbook Simulate 1 (Life). NoC: NoC 7 cellular automata. Application: WP2 cellular automata; WP4 chaos. Klee: I.5 divisional articulation (rhythm). Reference: Queer 3D debt: Turing and entropy, 'which morphology, noise or disturbance is possible in a system' [V].
- **Project step:** Grow one part of your hall (a path, a wall, a skin) from a rule and check it one generation at a time in the debugger.

#### 24. Recursion must be stopped: fractal bodies

- **Spine:** fractals. **Halls:** Fractal_RecursiveTrees (carrier); Fractal_Recursion (carrier); Fractal_MengerSponge (field trip); Fractal_GoldenSpiral (encounter)
- **Code:** new recursion; returns functions, parameters, return, conditions, multimesh, profiling, basis, random, seeds
- **Body:** Munari's tree: one rule (each branch splits in two, each thinner than the one before) as a recursive function with an explicit depth limit and one seeded 'mad branch'.
- **Argument:** axis recursion depth, values 2 / 4 / 6 / 9. *Predict:* 6 and 9 will look most alike from standing height (the new twigs are smaller than a pixel), while 9 has eight times the branches. *Claim:* Recursion's debt is paid in invisible work: past depth 6 the tree costs more and looks the same.
- **Debt:** 'Recursion must always be controlled' (the Queer 3D intro [V]): plant the missing base case and read the stack-overflow message. Munari's mad branch as a queer reading of recursion: the family still reads through the exception.
- **Place:** Stand under the tree; fly through the Menger sponge (merged collision) at depth 2 and 3.
- **Godot:** func branch(p, dir, length, depth); base case: if depth == 0: return; stack overflow message; MultiMesh for branches
- **Lineage:** Processing: LP ch13 recursion; Handbook Shape 3 Recursion. NoC: NoC 8 fractals. Application: WP2 fractal subdivision; WP1 Fibonacci (GoldenSpiral encounter). Klee: I.11 propagation. Reference: Queer 3D lineage: Kawaguchi's fractal bodies [V]; Munari, Drawing a Tree.
- **Project step:** Grow a recursive part on your body and set its depth from a sheet, not by taste.

#### 25. Grammar: the turtle, its stack, and the building

- **Spine:** lsystems. **Halls:** LSystems_Grammar_Lab (carrier); LSystems_Architecture (carrier); LSystems_Growth (field trip); Assemblage_Same_Desire (encounter)
- **Code:** new strings, dictionaries, stacks; returns loops, recursion, vectors, basis, meshes, collision
- **Body:** An L-system: an axiom string rewritten by a Dictionary of rules, read by a turtle (Klee's walking point as Logo) that pushes and pops its state on a stack, drawn as lines and built as walkable corridors.
- **Argument:** axis turn angle, same grammar, values 18 / 25.7 / 60 / 90. *Predict:* 18 and 25.7 will look most alike (both plants); 90 turns the same grammar into a floor plan. *Claim:* One grammar is a plant at 25 degrees and a building at 90: the interpretation, not the rule, decides the category.
- **Debt:** Strings grow exponentially, so a symbol budget has to stop the rewriting (the grammar's debt). The turtle's stack is a memory of where it was, and a pop throws it away.
- **Place:** Walk the grammar's corridors (LSystems_Architecture): a building that is also a plant.
- **Godot:** String, for c in s; Dictionary, rules.get(c, c); Array as a stack: push_back(), pop_back(); ImmediateMesh lines; BoxMesh walls with colliders
- **Lineage:** Processing: LP ch17 text; Handbook Typography (strings). NoC: NoC 8 L-systems. Application: WP2 L-systems. Klee: I.1 the walk again: the turtle is Klee's point with a memory. Reference: Queer 3D lineage: Superstudio, Borromini [V]; GDQuest's turtle.
- **Project step:** Write one grammar that grows a part of your hybrid and show it at two angles.

#### 26. Implicit bodies: the lookup table and the neck

- **Spine:** isosurfaces. **Halls:** ISO_Metaballs (carrier); ISO_LookupTable (carrier); ISO_Introduction (field trip); ISO_Caves (encounter)
- **Code:** new testing; returns noise, surface_tool, normals, arrays, functions, collision, profiling, dictionaries
- **Body:** A body with no vertices of its own: a density field from two to five sources joined by a smooth minimum, meshed by marching cubes with the case table supplied, then tested for holes.
- **Argument:** axis smooth-minimum blend radius k (m), sources 0.5 m apart, values 0 / 0.1 / 0.3 / 0.8. *Predict:* 0 and 0.1 will look most alike (two separate bodies); a neck appears near 0.3 and at 0.8 they are one blob. *Claim:* The blob is a parameter: once k exceeds the gap between sources, two bodies become one.
- **Debt:** Code-critique station: read the supplied case table, a finite negotiation with a continuous surface in which ambiguous cases are settled by convention. A test that every edge is shared by exactly two triangles shows where the table leaves holes. Quilez's smooth minimum is where the blob aesthetic comes from.
- **Place:** Walk into the cave (ISO_Caves); stand in the neck between two sources.
- **Godot:** func density(p: Vector3) -> float; supplied marching-cubes table; SurfaceTool + generate_normals(); assert() and a headless test scene
- **Lineage:** Processing: none (the Lague lineage). NoC: not in NoC. Application: 'queer meshes' (WP2); blob architecture in the lineage. Klee: II.14 dimension: a body from a field, not from lines. Reference: Queer 3D lineage: blob architecture (Gehry, Hadid) [V]; Critical Code Studies ch6 (Kittler's raytracer) as the model for reading 3D code.
- **Departure:** Isosurfaces (spine 18) come before procedural generation (16) and soft bodies (17): the lookup table belongs to the debt of approximation (Part II), while generated worlds and soft bodies are where bodies leave the lab (Part III).
- **Project step:** Rebuild one part of your body as a density field and test it for holes.

#### 27. Bias: the model is a picture of its data

- **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Classification (carrier); ML_Gradient_Landscape (field trip); CriticalAlgorithms_Algorithmic_Bias_Visualization (field trip); ML_Neural_Networks (encounter)
- **Code:** new ui, sorting; returns arrays, vectors, loops, dictionaries, materials, uv, input, ai_assist
- **Body:** A k-nearest-neighbour classifier painted on the floor: labelled bodies you made stand on it, every floor pixel takes the label of its k nearest bodies (sorted by distance), and a Button steps the training.
- **Argument:** axis share of training bodies from the majority class, values 50/50 / 70/30 / 90/10 / 99/1. *Predict:* 90/10 and 99/1 will look most alike: the minority's region has already shrunk to islands around its few examples. *Claim:* The boundary follows the majority: a classifier is a map of its data's proportions, not of the bodies.
- **Debt:** 'Machine-learning models are always biased' (Queer 3D intro [V]). Turn it on the course itself: the AI assistant used since chapter 7 is a model trained on a corpus. Ask it for 'a human body' in code and record what it assumes (height, symmetry, two arms). Collect and label your own small data set first (Feminist Data Set).
- **Place:** Stand in the field: which class claims your position? Move until it changes.
- **Godot:** Button.pressed, Control nodes / world-space Label3D; Array.sort_custom(); Image painted per pixel
- **Lineage:** Processing: LP ch10 algorithms (a small program taken apart). NoC: NoC 10 neural networks (encounter). Application: WP3 neural networks. Klee: none. Reference: Queer 3D Foundation question on LLM layers and debt 'always biased' [V]; Chun, Discriminating Data (homophily) [mem]; Aesthetic Programming ch10.
- **Departure:** Machine learning (spine 21) closes Part II, before procedural generation (16), soft bodies (17), boolean surfaces (19) and swarms (20): in the Queer 3D intro bias is the last and largest debt, and it turns the course's own AI assistant into the thing studied.
- **Project step:** Ask your AI assistant for a body and add its answer to your sheet as a fifth, unrequested variant: what did it assume?

#### 28. Synthesis II: the debt audit

- **Spine:** noise, primitives. **Halls:** Noise_Space_10 (carrier); Primitives_Ignorance (field trip); Random_Definition (encounter)
- **Code:** new resources; returns export, seeds, files, profiling, testing, ai_assist, instancing
- **Body:** Your hybrid saved as a custom Resource (.tres) holding the scan path, family values, seed and budget: a body as a recipe others can open, repair and change.
- **Argument:** axis one quality @export that scales every budget at once (triangles, octaves, iterations, depth), values full / half / quarter / headset budget. *Predict:* full and half will look most alike from visitor height; the headset budget is the first to show. *Claim:* Most of a body's cost is invisible from where a visitor stands; the debt shows only at the budget the headset forces.
- **Debt:** Write debt comments into your own code, after the Climategate chapter of Critical Code Studies: each approximation, what it owes, what it hides. Post one snippet with its context and one question to the critique thread (the project forum). Chun's sourcery, and the Sieve's third question: what does seeing your code still hide?
- **Place:** Your hall in the endless museum: walk around the body at visitor height at each budget.
- **Godot:** class_name BodyRecipe extends Resource; @export fields; ResourceSaver.save(), load(); duplicate(true)
- **Lineage:** Processing: Handbook Synthesis 2-3. NoC: Ecosystem Project step. Application: hacker ethics: Illich's transparency and repairability, commoning. Klee: none. Reference: Aesthetic Programming's ReadMe; the CCSWG code-critique thread; Queer 3D debt: 'the consequences and limits of relying on algorithms' [V].
- **Departure:** A synthesis chapter: it returns to noise (spine 11) and primitives (1) halls after machine learning (21) because it audits all of Part II on the student's own body.
- **Project step:** LONG TRACK mid-year review: the debt audit of your hybrid, its recipe as .tres, and the audited sheet.

### III. Ontology: out of bounds

#### 29. A generated world you can get lost in

- **Spine:** proceduralgeneration. **Halls:** PG_Caves_Mazes (carrier); Randomness_10_PRINT_Algorithm (field trip); PG_Sculpted_Forms (encounter); PG_Genetic_Evolution (encounter)
- **Code:** new navigation, queues; returns random, seeds, stacks, arrays, nested_loops, collision, player
- **Body:** A maze carved from a seed by a depth-first walk (a stack), checked by a flood fill (a queue), then given a navigation mesh so an agent with your walker's radius can find its way through.
- **Argument:** axis corridor width relative to the walker's diameter, values 0.8 / 1.0 / 1.5 / 3.0. *Predict:* 0.8 and 1.0 will look almost identical in plan view, yet only 1.0 is solvable for the body; 1.5 and 3.0 both read as clear mazes. *Claim:* A maze solvable in the array can be unsolvable for a body: the route belongs to the corridor's width, not to the grid.
- **Debt:** The array's route and the body's route differ: the navigation mesh erodes every wall by the agent's radius. The application's WP3 question: how do we navigate an auto-generated world?
- **Place:** Walk it; release one navigation agent the size of your walker and one the size of your scanned body.
- **Godot:** NavigationRegion3D, bake_navigation_mesh(); NavigationAgent3D: target_position, get_next_path_position(); Array as a queue: push_back(), pop_front()
- **Lineage:** Processing: LP ch10 algorithms. NoC: NoC 5 path following, named. Application: WP3 procedural generation and 'how do we navigate an auto-generated world?'. Klee: II.18 the tightrope walker 'is the scale'. Reference: Queer 3D ontology: processes become rooms outside the lab [V]; 10 PRINT's 'Maze Walker'; Montfort's 'Navigable Generated Landscape'.
- **Project step:** Generate the approach to your body: a maze or cave the visitor must walk to reach it.

#### 30. Graphs: the world as a network

- **Spine:** graphtheory. **Halls:** GT_Pathfinding (carrier); GT_Spanning_Trees (field trip); GT_Foundations (encounter)
- **Code:** new graphs, search; returns queues, stacks, dictionaries, signals, navigation, await, input
- **Body:** Your maze from chapter 29 turned into a graph (cells as nodes, openings as edges); BFS, DFS and A* replayed as light moving through the corridors; closing a door re-plans the route.
- **Argument:** axis search algorithm, values BFS / DFS / A* / greedy best-first. *Predict:* BFS and A* will light the same final path (both shortest), but A* lights far fewer cells; DFS's path is the longest. *Claim:* Search algorithms leave different traces in one maze: the path can be the same while what was visited differs.
- **Debt:** A graph keeps only what someone chose to connect; the rest of the world disappears from it. A* needs a heuristic, an assumption about distance that can be wrong.
- **Place:** Walk the lit path; press the button that closes a corridor and watch the route re-plan around you.
- **Godot:** AStar3D: add_point, connect_points, get_point_path, set_point_disabled; Dictionary adjacency lists; await for a step-by-step replay
- **Lineage:** Processing: none (outside the creative-coding canon). NoC: NoC 5 steering along paths. Application: WP3 graph theory. Klee: none. Reference: Queer 3D ontology [V]; Code Societies (Networked Terraforming); the graph halls as field trips.
- **Departure:** Graph theory (spine 22) follows procedural generation (16) directly, ahead of soft bodies (17), boolean surfaces (19) and swarms (20): the maze needs search as soon as it exists, and the application groups graphs with world building (WP3).
- **Project step:** Make your hall's maze a graph and let one door change the visitor's route to your body.

#### 31. Soft: polycount against deformation

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); SoftBodies_Cloth_Physics (field trip); SoftBodies_Affect_Theory_Visualization (field trip); SoftBodies_Playground_of_Joy (encounter)
- **Code:** new raycasts, particles; returns physics_bodies, import_assets, export, profiling, signals, integration
- **Body:** Your scan as a SoftBody3D at several decimation levels, poked by a ray from your hand or crosshair: where it is hit it dents and throws a burst of particles.
- **Argument:** axis triangles in the scan used as a soft body, values 200 / 800 / 3000 / 12000. *Predict:* 3000 and 12000 will look most alike at rest, but 12000 will not hold the frame budget (or goes unstable); 200 dents in facets. *Claim:* A soft body can bend only where it has vertices, and every vertex costs: smooth deformation and smooth surface pull against each other.
- **Debt:** The application's own question: the trade-off between polycount and deforming a body smoothly (l.89). The course description's 'stretchability' as ideology [V]: which bodies does the engine let bend, and at what price?
- **Place:** Poke it, push it, lean on it; pin it at one point and walk around it.
- **Godot:** SoftBody3D: simulation_precision, linear_stiffness, set_point_pinned(); PhysicsRayQueryParameters3D, intersect_ray(); GPUParticles3D, ParticleProcessMaterial, one_shot
- **Lineage:** Processing: Handbook Simulate 2 (springs). NoC: NoC 6: soft bodies are a course week, not a book chapter. Application: WP2 soft bodies (cloth, liquids, rubber); WP1 particle systems. Klee: II.20 balance disturbed. Reference: Queer 3D course description: 'how 3D reflects ideological ideas about stretchability, topologies, bias' [V].
- **Project step:** Make your hybrid answer touch (soft, dented, or bursting into particles) at the polycount the headset allows.

#### 32. Morphogenesis: Turing's pattern on your skin

- **Spine:** softbodies, shaders. **Halls:** ProceduralGeneration_Reaction_Diffusion_Systems (carrier); Topology_Entropy_Morphogenesis (carrier); Shader_10_ReactionDiffusion (field trip); CA_SoftRules (encounter)
- **Code:** new threads; returns buffers, packed_arrays, shaders, uniforms, uv, profiling, setters
- **Body:** A Gray-Scott reaction-diffusion field on two buffers (first on a worker thread on the CPU, then as a ping-pong shader), used as the skin and displacement of your hybrid.
- **Argument:** axis feed/kill regime, values spots / stripes / labyrinth / waves. *Predict:* stripes and labyrinth will look most alike (both line-like); spots differ most. *Claim:* The same two chemicals make spots or stripes from two rates alone: in Turing's model a pattern is a rate, not a blueprint.
- **Debt:** The model is a 1952 simplification that biology partly confirmed and partly refused [mem]. The CPU version stalls the frame unless it moves to a thread (and a worker task must be waited on to be released); the GPU version is fast and unreadable from GDScript.
- **Place:** Stand in a room whose walls grow the pattern (a bio-cyborg room); touch the skin to seed a new spot.
- **Godot:** WorkerThreadPool.add_task(), wait_for_task_completion(); Thread, named; SubViewport ping-pong with ViewportTexture; Image.set_pixel() against a shader
- **Lineage:** Processing: none. NoC: NoC 7 continuous CA, named. Application: WP3 reaction-diffusion; Turing's 1952 morphology (application l.73). Klee: I.11-I.12 propagation, heart and blood: growth by flow. Reference: Queer 3D: morphogenesis, 'can twisted rooms transcend power and challenge normative structures?', and bio-cyborg rooms [V]; Chun 'Order from Order'; Gaboury's queer history of computing (Turing).
- **Departure:** Reaction-diffusion lives in the soft-bodies (17) and shader (12) sequences; it is taught after graphs (22) because it needs threads and the shader chapter, and because the Queer 3D intro places morphogenesis where bodies leave the lab.
- **Project step:** Grow a Turing skin on your hybrid.

#### 33. Cut and join: collage bodies

- **Spine:** boolean_surfaces. **Halls:** Boolean_Verbs (carrier); Boolean_Works (carrier); Boolean_Gallery (encounter)
- **Code:** new json; returns import_assets, collision, meshes, resources, dictionaries, files, random, seeds
- **Body:** A collage body after Höch and Bellmer: your scan combined with procedural parts by union, intersection and difference; the recipe (operands, order, operation) stored as JSON so a classmate can remix it.
- **Argument:** axis operation, values A ∪ B / A ∩ B / A − B / B − A. *Predict:* A ∪ B and A − B will look most alike from the front if B sits mostly behind A; A − B and B − A are never alike. *Claim:* Order is part of a collage: A − B and B − A are two different bodies made from the same parts.
- **Debt:** CSG on a scanned mesh is fragile: non-manifold scans fail or take seconds. Coincident faces z-fight, and baking to a static mesh freezes the collage. JSON keeps the recipe but not the reasons.
- **Place:** Carve a burrow into your body and walk in (use_collision).
- **Godot:** CSGCombiner3D, CSGMesh3D, CSGSphere3D, operation; use_collision; bake to MeshInstance3D + trimesh; JSON.stringify(), JSON.parse_string()
- **Lineage:** Processing: none. NoC: not in NoC. Application: WP2 'the algorithmic topology of desire and the creation of queer meshes'. Klee: I.12 'stone upon stone': building against carving. Reference: Queer 3D lineage: collage and cut-up (Höch, Bellmer, Bourgeois), hybrid form (Satterwhite, Perry) [V]; Critical Code Studies ch7 (Taroko Gorge remixes).
- **Project step:** Collage your body; publish its JSON recipe so a classmate can remix it and defend the remix with a claim.

#### 34. Many bodies choose: swarms

- **Spine:** swarmintelligence. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_PhysarumColony (field trip); SwarmIntelligence_FlowFields (encounter); SwarmIntelligence_Agent_Based_Modeling_ABM (encounter); ML_Evolution (encounter)
- **Code:** new inheritance; returns classes, vectors, groups, multimesh, profiling, forces, search, areas
- **Body:** A flock of small bodies derived from your hybrid: a base Agent class that Boid, Ant and Slime extend, steering by separation, alignment and cohesion, with the visitor as an obstacle.
- **Argument:** axis separation weight, values 0 / 0.5 / 1.5 / 5. *Predict:* 0 and 0.5 will look most alike (a clump); at 5 the flock dissolves into evenly spaced individuals. *Claim:* One weight decides whether many bodies read as one body or as a crowd of individuals.
- **Debt:** All-pairs neighbour search costs n squared, so the frame budget caps the flock (a spatial hash lifts the cap). Each agent sees only what its rule lets it see. Emergence is a reading, not a property.
- **Place:** Stand in the flock: it parts around you. XR route: become one of them (the camera rides a boid).
- **Godot:** class_name Agent; extends Agent; super(), overriding a method; MultiMesh transforms per frame; a spatial hash in a Dictionary
- **Lineage:** Processing: Handbook Motion 2 (machine and organism). NoC: NoC 5 autonomous agents (flocking). Application: WP4 swarm intelligence; WP3 evolutionary (encounter); WP2 flow fields (encounter). Klee: none. Reference: Queer 3D lineage: emergence; ontology's bio-cyborg rooms [V].
- **Project step:** Release a swarm of small versions of your body into your hall.

#### 35. Impossible space: the camera decides

- **Spine:** foundationscrisis. **Halls:** Escher_Impossible (carrier); NonEuclidean_Spaces (field trip); Godel_Incompleteness (encounter)
- **Code:** new camera; returns vectors, transforms, signals, shaders, uniforms, search, xr
- **Body:** A Penrose triangle of three straight bars that closes from exactly one camera position; a signal fires when the visitor's eye reaches it.
- **Argument:** axis camera offset from the designed standpoint (degrees), values 0 / 5 / 20 / 90. *Predict:* 0 and 5 will look most alike (the triangle still reads as closed); by 20 the bars visibly miss each other. *Claim:* An impossible body is possible from exactly one eye: impossibility is a fact about a camera, not about the geometry.
- **Debt:** Every still in this course was shot from one standpoint, and a family that bites on an unseen face looks dead (Ada's anamorphic lesson): the camera is the course's own dark spot. Gödel and the halting problem: a search that may never end needs a budget (Godel_Incompleteness).
- **Place:** Walk to the standpoint, on desktop or in the headset, and watch the triangle close; walk the Escher stair.
- **Godot:** Camera3D, get_viewport().get_camera_3d(); -global_transform.basis.z as the view direction; a dot-product alignment test; XRCamera3D (the headset's eye)
- **Lineage:** Processing: LP ch14 3D (camera named); Handbook 3D extension. NoC: not in NoC. Application: WP4 non-euclidean spaces. Klee: II.15-II.17 perspective as optical illusion, horizon and eye level. Reference: Queer 3D ontology: 'impossible possible space'; lineage Escher, Reutersvärd, Penrose [V]; Gaboury, Image Objects ch1 'culling vision'.
- **Project step:** Find the one standpoint from which your hybrid is 'right' and make the visitor search for it.

#### 36. Order to entropy: the body between states

- **Spine:** qfeplaboratory. **Halls:** QFEP_Lambda_Spectrum (carrier); QFEP_Synthesis (carrier); QFEP_E_Term (encounter); QFEP_F_Term (encounter)
- **Code:** new state_machines; returns interpolation, export, setters, multimesh, vectors, random, seeds
- **Body:** Your hybrid given one λ from order (0) to entropy (1) that disorders all its families at once, and an enum state machine (jarred, released, dissolving) that tries to name what λ does.
- **Argument:** axis λ, values 0 / 0.25 / 0.5 / 0.75 / 1.0. *Predict:* 0 and 0.25 will look most alike (order is robust); the body 'flips' between 0.5 and 0.75. *Claim:* The body keeps its category until λ crosses a threshold and then changes all at once: the edge of chaos is where a category decides.
- **Debt:** A state machine is a list of allowed identities; λ is what the enum cannot hold. The QFEP F-to-E arc is the course's own arc: the application's 'as we step towards more entropy... difference and diversity increase'.
- **Place:** Walk the λ hall (your position is λ) and stand where your body changes state.
- **Godot:** enum State { JARRED, RELEASED, DISSOLVING }; match state:; the player's position projected onto a track with dot(); one @export lambda with a setter
- **Lineage:** Processing: none. NoC: none. Application: entropy as the cross-connection; WP4 chaos theory. Klee: IV.38 the spiral: life or death. Reference: Queer 3D debt: entropy through Haraway and Ahmed 'can be a resistance' [V]; Glitch Feminism 'Glitch Is Anti-Body'.
- **Project step:** Give your hybrid a λ; the show will let visitors walk it from order to entropy.

#### 37. Leaving the lab: the show

- **Spine:** postfoundationscrisis. **Halls:** PostCrisis_Synthesis (carrier); SpeculativeComputation_Collective_Knowledge (field trip); SpeculativeComputation_Situated_Computation (encounter)
- **Code:** new export_build; returns save_load, files, profiling, xr, import_assets, ui, audio, input, resources, camera
- **Body:** Your hybrid in its room, exported as a build other people can run: a desktop build, and a Quest build if the room holds the headset's frame rate.
- **Argument:** axis platform, values editor run / desktop export / Quest export at the headset budget. *Predict:* the editor run and the desktop export will look identical; the Quest build is the first to show the decimation. *Claim:* Shipping is a decimation: the headset shows the body its frame budget allows, not the one you made.
- **Debt:** A build freezes res:// (read-only inside the .pck), so visitor comments must go to user://. In VR, comfort and frame rate are not polish. Who can run the build (hardware, access) is part of the work.
- **Place:** The show: visitors walk, carry or become the body; a comment box records what they say, and PostCrisis_Synthesis's read-back brings it into your next session.
- **Godot:** Project > Export, presets for Windows and Android/Quest; OpenXR export settings; user:// against res://; on-device Performance monitors
- **Lineage:** Processing: LP ch21 exporting; Handbook Output. NoC: the Ecosystem Project as an exhibit. Application: the final package: optimisation and publication; open-source release. Klee: the concluding note: a teacher's programme. Reference: Queer 3D: 'the course ends with a mini project shown to the class' [V]; Code Societies' scores and sketch pieces; the Pixelles showcase.
- **Project step:** SHORT: show the mini project. LONG: the capstone, a room of hybrid bodies that is a small complete game (player, input, camera, UI, save, audio, build), shown and handed on as a recipe.

## Relation to the spine

Order agreement, computed here from each chapter's first spine sequence: 0.946 of chapter pairs are in spine order (0.932 using each chapter's earliest sequence). Every inversion has a declared departure on at least one side (script check). All 25 sequences are touched.

Why so close to the spine, for a course that set out to be 'related, not forced'? **Finding: the spine is already, roughly, the three layers.** Spine 1-5 (primitives, transformation, array, colour, tiling) is the lab of still bodies; 6-18 (change, forces, form-finding, waves, randomness, noise, shaders, CA, fractals, L-systems, isosurfaces) are procedures whose approximations owe something; 16-25 (generation, soft bodies, boolean, swarm, graphs, crisis, QFEP, post-crisis) are where bodies leave the lab. Using the Queer 3D layers as the macro-structure GROUPS the spine far more than it REORDERS it. The departures that remain are the ones the layers argue for:

- **1. Bring a body: a scan meets a point:** Adds a strand the spine does not have: bringing in a scanned or sculpted body, the Queer 3D course's first day. Primitives_Ignorance (the tenth primitives hall) is visited on day one as a field trip because it asks the same polycount question of a sphere.
- **8. Chance as a value: Schotter:** Randomness (spine 10) is met early, at array_tutorial's place (3), as a VALUE disturbing a grid already built: the Queer 3D course asks it first, the application puts it in WP1, and every creative-coding tradition meets random() early. Randomness as a TOPIC keeps its spine place in chapter 20, as a declared return.
- **9. A body that notices: the floor that answers:** Random_Remove (spine 10) carries a Part I chapter because the first event a body meets should be a floor responding to it; its seeded draw waits for chapter 20.
- **10. A body of parts: pivots and frames:** Transformation (spine 2) comes after array_tutorial (3): a body of parts needs many parts first (Form+Code's Repeat before Transform), and position and frame were met in chapter 4.
- **12. A body type: the class that crosses a category:** Returns to primitives halls (Melencolia, Portals) after colour: the class and the circle's approximation need @export and functions first.
- **13. Surfaces from vertices: can you stand on it?:** WaveFunctions_Sine_Space (spine 9) is visited early as 'the graph', following the engine tradition's graph-to-surface ladder; the wave sequence keeps its place in chapter 19.
- **15. Synthesis I: the specimen sheet:** A synthesis chapter: it returns to colour (spine 4) and primitives (1) halls after tiling (5) because it gathers Part I, not because a hall needs it here.
- **20. Pseudo: the seed returns:** A deliberate return: chance was met as a value in chapter 8; randomness keeps its spine place (10) as a debt topic.
- **26. Implicit bodies: the lookup table and the neck:** Isosurfaces (spine 18) come before procedural generation (16) and soft bodies (17): the lookup table belongs to the debt of approximation (Part II), while generated worlds and soft bodies are where bodies leave the lab (Part III).
- **27. Bias: the model is a picture of its data:** Machine learning (spine 21) closes Part II, before procedural generation (16), soft bodies (17), boolean surfaces (19) and swarms (20): in the Queer 3D intro bias is the last and largest debt, and it turns the course's own AI assistant into the thing studied.
- **28. Synthesis II: the debt audit:** A synthesis chapter: it returns to noise (spine 11) and primitives (1) halls after machine learning (21) because it audits all of Part II on the student's own body.
- **30. Graphs: the world as a network:** Graph theory (spine 22) follows procedural generation (16) directly, ahead of soft bodies (17), boolean surfaces (19) and swarms (20): the maze needs search as soon as it exists, and the application groups graphs with world building (WP3).
- **32. Morphogenesis: Turing's pattern on your skin:** Reaction-diffusion lives in the soft-bodies (17) and shader (12) sequences; it is taught after graphs (22) because it needs threads and the shader chapter, and because the Queer 3D intro places morphogenesis where bodies leave the lab.

What this candidate does NOT move, and why: randomness keeps its spine place as a DEBT topic (chapter 20); it is only MET earlier, as a value (chapter 8). Colour stays early (chapter 11) and returns as energy with the shaders (chapter 22), because Klee ends in colour [V via research_bauhaus]. Transformation stays early because a Godot node is a transform (research_creative).

Coverage checks (script): no ladder violation, no unknown id, no chapter with more than 3 new ideas, all 83 vocabulary ids used once as new. Game kit: player 17, input 6, camera 35, ui 27, save_load 20, audio 19, export_build 37, physics 3, instancing 15, signals 9. xr 4, import_assets 1, ai_assist 7. Application WP1 (randomness 8/20, Fibonacci 24, Perlin 21, Voronoi as cellular 21, sine and sound 19, particles 31), WP2 (fractals 24, flow fields 16/34 as encounters, Fourier 19 as encounter, L-systems 25, CA 23, soft 31, queer meshes 13/26/33), WP3 (reaction-diffusion 32, graphs 30, generation 29, neural networks 27, shading 22, evolution 29/34 as encounters), WP4 (swarm 34, chaos 23/36, AI 27, non-euclidean 35).

## What it learned from comparable courses

- Queer 3D World (Palle, 2024) [V]: the three layers become the three parts, and every chapter repeats all three on a small scale (make it, read its debt, place it); scanning on day one; 'use ChatGPT to write simpler programs' becomes a taught protocol (c07) and later an object of critique (c27); a mini project shown to the class ends both tracks.
- Aesthetic Programming (Soon and Cox): a critical theme tied to each piece of syntax rather than a separate theory track; the RunMe/ReadMe pair, with Ada's falsifiable PREDICTION + CLAIM in place of open ReadMe questions; pause weeks; the final project planned two units before the end.
- Critical Code Studies (Marino) and the CCSWG: code-critique stations placed at the DEBT step and never at the opening (the RNG in c20, the marching-cubes table in c26, the student's own code in c28); the confessing comment (Climategate) becomes the 'debt comment'; 'describe X in a single class' becomes c12; the critique thread maps onto Ada's forum; Taroko Gorge remixes become the JSON collage remix (c33).
- Montfort, Exploratory Programming: modify before write (the runnable kits); errors taught as a positive topic ('valid and intentional are different', c05); 'Critique My Starter Programs' turned on Godot's default capsule and cube (c03, c17).
- 10 PRINT: 'Regularity' before 'Randomness', which is why chance first appears as disorder on a grid already built (c08, Schotter) and returns as seeds (c20); its Maze Walker becomes the walkable maze (c29).
- Nake, Nees and Molnar (research_bauhaus): randomness enters the Klee lineage in 1965-68 as disturbance of an order, so it can come early without skipping the grid.
- Klee's Pedagogical Sketchbook, with the corrected section order [V via research_bauhaus / maps/lineage.json]: the line on a walk (c06), repetition as structure (c07), the body of bones and tendons (c10), balance and gravity (c17-c18), pendulum then circle then spiral (c19), colour as energy at the end (c22). The active/passive = male/female passage is named as a dark spot (c10).
- Albers, Interaction of Color: a stated perceptual target with one constrained material is the ancestor of the ARGUMENT strand; 'make two different bodies look alike' is the prediction turned into an assignment (c11, c14).
- LeWitt: the instruction as the work gives the AI-assisted protocol (write the instruction, predict, generate, check, mark where the AI had to guess) in c07.
- Code as Creative Medium (Levin and Brain): body-named assignments (Personal Prosthetic in c10; the mini project is a Virtual Creature / Extrapolated Body in 3D) and variations at two depths for two tracks.
- Processing Handbook: static before continuous (Part I builds in _ready; delta opens Part II in c16), a synthesis at the end of each part (c15, c28, c37).
- The Nature of Code: the cumulative project is a museum exhibit of creatures; Ada's project_step puts each chapter's body into the student's hall of the endless museum.
- Catlike Coding and the Book of Shaders: graph before surface (c13 visits WaveFunctions_Sine_Space early); construction as an axis; the shader as a single editable line (c22).
- Gaboury, Image Objects: one technical object per chapter as a critical lens (the default body in c03, culling and the camera in c35, the GPU in c22).
- SFPC Code Societies: a three-week critical format with a guest per session and small 'score' outcomes, the model for the short track's week 3.
- UCSC AGPM 129 and Anthropy: make before the tool (the scan before any GDScript) and share a first work in week 1.
- Gap named rather than borrowed [V via research_ccs]: none of these courses critiques geometry, bodies or VR; Ada's polycount-against-deformation, the blob, stretchability and impossible space are its own contribution.

## Weak spots, stated

- Camera is formally opened only at chapter 35. Until then it is part of the supplied walker and the sheet camera. That serves the critique (the camera as the course's dark spot) but is late for a game course.
- Part III is short (9 chapters) against Part I (15). The ontology chapters lean on returns, and chapters 32-36 have a single new idea each; a teacher could merge 32 into 31.
- Scanning raises consent and data questions (biometric scans of classmates); the course uses the student's own body or an owned object, and should say so on day one.
- The short track has 11 chapters in 15 days. It works only because the walker, the grid kit, a MeshDataTool helper, a shader template, the sheet camera and a CSG kit are supplied and named.
- Several claims are predictions a sheet may falsify (for example, which spiral pair looks alike, or the step height a capsule climbs [mem]). That is the point of the format, but the numbers are untested.
