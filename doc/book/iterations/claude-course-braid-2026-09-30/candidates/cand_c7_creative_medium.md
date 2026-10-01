# Assignments with a Lineage: what bodies are possible in code

Candidate `c7_creative_medium`, grown from one reference: **Golan Levin and Tega Brain, Code as Creative Medium: A Handbook for Computational Art and Design (MIT Press, 2021): assignment-driven chapters, each an open brief with historical precedents from computational and conceptual art, kept apart from short closed exercises; Part Two's exercise order (Computing without a Computer, Graphic Elements, Iteration, Color, Conditional Testing, Unpredictability, Arrays, Time and Interactivity, Typography, Curves, Shapes, Geometry, Image, Visualization, Text and Language, Simulation, Machine Learning, Sound, Games) sets the code ladder.**

Written 2026-10-01 for the braid auto-research run. Nothing in either repo was edited, staged or committed. Sources are tagged [V] (checked this session or in the research sweeps' verified sources) or [mem] (from memory, not checked).

## For the student: why this order

This course is built like Golan Levin and Tega Brain's Code as Creative Medium: every chapter is an assignment with a lineage, a brief, one or two works from computational and conceptual art that answered it before you, a short closed exercise that trains one programming idea, and an open making step. What changes is the medium and the question. The medium is Godot and VR, and the question under every brief is Ada's: what bodies are possible? So each assignment asks you to build a body in code, turn it into a family along one axis, write down before you render which two members will look most alike and why, say in one sentence what the comparison image shows, write what the approximation owes or hides, and put the body where a person meets it: stand on it, walk through it, carry it, become it. The order follows the book's exercise ladder (graphic elements, iteration, colour, conditions, unpredictability, time, curves, simulation, learning, games), and it follows the Ada spine where the spine argues better: a Godot node is already a transform, forces come before waves, and the late crisis halls are critique beside code. Where the two disagree, the chapter says so. Chance and noise come early, straight after the tiling rule they disturb, because you need a regular pattern to see randomness, and they come back later as debt. The family (@export) comes early because every argument in the course sweeps one. Levin and Brain end their assignments with bodies (personal prosthetic, parametric object, public sculpture, extrapolated body); here you start with them.

## How a chapter runs

Levin and Brain split their book into open **assignments** (a brief, learning objectives, variations by skill level, and an annotated gallery of historical and contemporary precedents) and short closed **exercises** that train one skill. Every chapter here has both halves, braided with Ada's four strands and three layers:

1. **Brief and lineage.** The assignment title (a Levin and Brain brief or exercise group, translated to a body in 3D) and one or two precedent works (`lineage.reference`).
2. **Walk the hall and predict** (PRIMM Predict). The carrier hall is visited first, in the headset or on desktop; the student guesses how its work is built.
3. **The exercise** (CODE strand; PRIMM Run, Investigate, Modify). One to three code ideas from the vocabulary, first met here; one planted bug whose message the student reads.
4. **Make the body** (BODY). Built in code, in `_ready()` until c03 opens time.
5. **The family and the prediction** (ARGUMENT). One axis, 3-5 values, a written prediction of the closest pair and why, *before* rendering; then one comparison sheet and a one-sentence claim. This is the falsifiable replacement for Aesthetic Programming's open ReadMe.
6. **The debt** (DEBT layer). What the approximation owes or hides, written as a *debt comment* inside the student's own code (after Marino's Climategate reading), and discussed as a code-critique thread on Ada's forum shape: snippet, context, one question.
7. **The place** (PLACE / ONTOLOGY). Where a body meets it: stand on it, walk through it, carry it, become it; on desktop first, and the headset route reachable from c04 (XR Tools rig) and c07 (a Quest export).
8. **Variations at two depths.** The short track does steps 1-5 and a one-line debt; the long track does all eight and the chapter's `project_step`.

## Parts

| Part | Title | Chapters | Promise |
|---|---|---|---|
| p1 | Computing without a computer: one body | c01-c07 (7) | You can write an instruction for a body, build one body in code, give it time, carry it, connect it, record its walk, and direct and check code a machine writes for you. |
| p2 | Iterative pattern: a rule makes a family | c08-c12 (5) | You can make many bodies by a rule, assemble a body from parts (and a scan), turn it into a family with @export, and colour and tile it by rules you can read back from the image. |
| p3 | Unpredictability: chance, noise, skin and appearance | c13-c16 (4) | You can replace a rule with a seeded draw, give a body noise to stand on, build its skin from vertices, and give it an appearance that lies about its shape, and you can say what each approximation hides. |
| p4 | Machines and creatures: bodies in time and force | c17-c24 (8) | Your bodies flow, fall, hang, reach, draw, sound and play: particles, forces, your own integrator, rays and signals, sines and audio, the seed as key, and one small complete game. |
| p5 | Rules that grow: bodies and worlds that make themselves | c25-c29 (5) | Bodies generated by neighbour rules, recursion, grammars and breeding, and a generated world navigated as a graph: procedures you can stop, save, reload and argue with. |
| p6 | Leaving the lab: extrapolated bodies | c30-c35 (6) | Bodies that deform, fuse, flock, learn and close from only one standpoint, ending in a public body that other people can revise. |

Each part ends, in the long track, with a **Synthesis week** (no new code idea: returns, a checkpoint, the mini-project step) and one Levin and Brain interview theme as a discussion (The First Day; The Bimodal Classroom; Encouraging a Point of View; When Things Go Wrong; Favorite Assignment; Advice). The parts line up loosely with the 2023 application's arc: I-II are the pre-WP foundation (Klee in drag), III-IV take WP1 (randomness, noise, sine, sound, particles), V takes WP2-WP3 (CA, fractals, L-systems, evolution, graphs), VI takes WP2's soft bodies and WP4 (swarm, AI, non-euclidean) and ends in the application's commoning.

## Tracks

### Three weeks: a body family in your own hall (`short`)

- **Length:** 3 weeks in the Queer 3D format: 10 teaching days (one chapter a day), then a mini-project week with a guest session, shown to the class on the last day
- **Chapters:** c01, c02, c03, c04, c07, c08, c09, c10, c13, c14
- **Project:** Pick one Levin and Brain brief translated to a body (Virtual Creature, Parametric Object, Face Generator, Generative Landscape or Extrapolated Body) and answer it with a family: one body built in code with one @export axis of 3-5 values, optionally collaged with one scanned or Tilt Brush body, placed in your own hall where a visitor can stand on, walk through, carry or become it, on desktop and once on the headset. Show the comparison sheet with your written prediction (which two members look most alike, and why) and one-sentence claim, plus one debt comment in your code. Brief chosen by the first day of week 3. Supplied and named: the first-person walker and the XR Tools rig (from Day Zero), the segment helper (c05), the trace recorder (c06), the seed-replay grid (random-definition kit), and one-line asides for what the short track skips: conditions (if randf() < p), arrays (a list of bodies) and booleans.

### One year: from an instruction to a public body (`long`)

- **Length:** about 41 weeks at one session a week: 35 chapters plus 6 part syntheses (pause weeks with no new code idea, as in Aesthetic Programming), midterm game at c24, final brief chosen at the start of Part VI
- **Chapters:** c01, c02, c03, c04, c05, c06, c07, c08, c09, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30, c31, c32, c33, c34, c35
- **Project:** Midterm: the One-Button Game (c24) built from your own bodies. Final: planned at the start of Part VI, two units of work before the end (after Aesthetic Programming's chapter 9): your family placed in the class's collective museum hall (c35) with prediction, claim, debt comment, edit rule and a headset build. Each part closes with a Synthesis week (the Processing Handbook's rhythm) and a Levin and Brain interview theme as discussion (The First Day, The Bimodal Classroom, Encouraging a Point of View, When Things Go Wrong).

Short-track day plan: week 1 = c01, c02, c03, c04, c07 (instruction, body, time, hands and the headset, the machine drafter and the export); week 2 = c08, c09, c10, c13, c14 (many, parts and scan, family, chance, ground); week 3 = own work on the mini project, a guest, the showing. The short track skips c05, c06, c11, c12: their ideas are supplied and named (see the mini-project text), which is the honest cost of three weeks.

## The two indexes (after the Processing Handbook)

The Handbook prints two tables of contents: a reading order, and the same chapters by category. This course does the same: the reading order is the course; the by-spine index shows which spine sequence each chapter draws on, so a departure shows as a jump.

### Reading order

| n | id | Chapter | Part | Spine (order) | New code ideas | Carrier (or first) hall | Departure note |
|---|---|---|---|---|---|---|---|
| 1 | c01 | Computing Without a Computer: an instruction for a body | p1 | primitives (1) | statements, output, errors | Point_Zero |  |
| 2 | c02 | Graphic Elements: one body, solid or ghost | p1 | primitives (1) | variables, calling, properties | Point_One | yes |
| 3 | c03 | Clock: the engine calls you | p1 | primitives (1) | lifecycle, delta, types | Point_Zero |  |
| 4 | c04 | The Carried Point: name its reference | p1 | primitives (1) | vectors, transforms, xr | Point_Coordinates |  |
| 5 | c05 | Line: connect and measure | p1 | primitives (1) | expressions, methods, strings | Point_Lines |  |
| 6 | c06 | Drawing Machine I: the walk that remains | p1 | primitives (1) | arrays, conditions, input | Point_Trace | yes |
| 7 | c07 | When Things Go Wrong: the drafter is a machine | p1 | primitives (1), postfoundationscrisis (25) | ai_assist, debugging, export_build | Primitives_Melencolia | yes |
| 8 | c08 | Iterative Pattern: purely repetitive and therefore structural | p2 | array_tutorial (3), primitives (1) | loops, nested_loops, functions | Array | yes |
| 9 | c09 | Face Generator: a body of parts, and a scanned one | p2 | transformation (2) | parameters, return, import_assets | Trans_Body | yes |
| 10 | c10 | Parametric Object: a body is a family | p2 | primitives (1), color (4) | classes, export, setters | Primitives_Ignorance | yes |
| 11 | c11 | Custom Pixel: colour is a rule | p2 | color (4) | materials, interpolation, dictionaries | Color_Grid_Pallet |  |
| 12 | c12 | Modular Alphabet: tiles and their rule | p2 | tiling (5) | booleans, uv | Pattern_Foundry |  |
| 13 | c13 | Unpredictability: Ten Print, and the seed that returns | p3 | randomness (10) | random, seeds | Randomness_10_PRINT_Algorithm | yes |
| 14 | c14 | Generative Landscape: noise you can stand on | p3 | noise (11) | noise, instancing | Noise_Perlin_Simplex | yes |
| 15 | c15 | A Skin to Stand On: surfaces from vertices | p3 | noise (11), primitives (1) | meshes, surface_tool, normals | Noise_Space_10 | yes |
| 16 | c16 | Augmented Projection: an appearance the body does not have | p3 | shaders (12), color (4) | shaders, uniforms | Shader_09_FBM | yes |
| 17 | c17 | Flow Field: a weather of bodies | p4 | change (6) | packed_arrays, particles, lifetime | Flow_Field | yes |
| 18 | c18 | Virtual Creature: to stand although it could fall | p4 | forces (7) | physics_bodies, collision, forces | VFM_09_Legs | yes |
| 19 | c19 | Hanging Sculpture: a form that finds itself | p4 | formfinding (8) | integration, profiling | FormFinding_Relaxation | yes |
| 20 | c20 | Personal Prosthetic: the arrow extends your reach | p4 | forces (7), color (4) | raycasts, areas, signals | Vectors_Act5_ForceAsPlace | yes |
| 21 | c21 | Drawing Machine II: the harmonograph | p4 | wavefunctions (9) | trig, basis, multimesh | WaveFunctions_Pendulum | yes |
| 22 | c22 | Synesthetic Instrument: a body you can hear | p4 | wavefunctions (9) | audio, ui, timers | WaveFunctions_AirMusic | yes |
| 23 | c23 | Creative Cryptography: the seed as key (randomness returns) | p4 | randomness (10) | sorting, await | Random_Entropy | yes |
| 24 | c24 | One-Button Game: stand or sink | p4 | randomness (10), formfinding (8) | player, state_machines | Random_Game | yes |
| 25 | c25 | Life: a rule for neighbours | p5 | cellularautomata (13) | buffers | CA_Introduction |  |
| 26 | c26 | Recursive Tree: the rule that must be stopped | p5 | fractals (14) | recursion, stacks, queues | Fractal_RecursiveTrees |  |
| 27 | c27 | Modular Alphabet II: a grammar that grows | p5 | lsystems (15) | resources | LSystems_Grammar_Lab | yes |
| 28 | c28 | Virtual Creature II: bred, not designed | p5 | proceduralgeneration (16), machinelearning (21) | files, json, save_load | PG_Genetic_Evolution |  |
| 29 | c29 | Maze Walker: navigate an auto-generated world | p5 | graphtheory (22), proceduralgeneration (16) | graphs, search, navigation | GT_Pathfinding | yes |
| 30 | c30 | Extrapolated Body: soft, pinned, deforming | p6 | softbodies (17) | composition, tool_scripts | SoftBodies_Soft_Body_Deformation | yes |
| 31 | c31 | Implicit Body: a field decides where the skin is | p6 | isosurfaces (18), boolean_surfaces (19) | threads | ISO_Metaballs | yes |
| 32 | c32 | Bot: many bodies, local rules | p6 | swarmintelligence (20) | inheritance, groups | SwarmIntelligence_Boids_Algorithm | yes |
| 33 | c33 | Data Self-Portrait: whose data trains the body | p6 | machinelearning (21) | testing | ML_Classification | yes |
| 34 | c34 | Impossible Figure: what a model lets you claim | p6 | foundationscrisis (23), qfeplaboratory (24) | camera | Escher_Impossible |  |
| 35 | c35 | Virtual Public Sculpture: a body in the collective museum | p6 | postfoundationscrisis (25) | other:undo_redo | SpeculativeComputation_Collective_Knowledge |  |

### By spine sequence

| Spine | Sequence | Chapters (reading-order number) |
|---|---|---|
| 1 | primitives | 1 Computing Without a Computer; 2 Graphic Elements; 3 Clock; 4 The Carried Point; 5 Line; 6 Drawing Machine I; 7 When Things Go Wrong; 8 Iterative Pattern; 10 Parametric Object; 15 A Skin to Stand On |
| 2 | transformation | 9 Face Generator |
| 3 | array_tutorial | 8 Iterative Pattern |
| 4 | color | 10 Parametric Object; 11 Custom Pixel; 16 Augmented Projection; 20 Personal Prosthetic |
| 5 | tiling | 12 Modular Alphabet |
| 6 | change | 17 Flow Field |
| 7 | forces | 18 Virtual Creature; 20 Personal Prosthetic |
| 8 | formfinding | 19 Hanging Sculpture; 24 One-Button Game |
| 9 | wavefunctions | 21 Drawing Machine II; 22 Synesthetic Instrument |
| 10 | randomness | 13 Unpredictability; 23 Creative Cryptography; 24 One-Button Game |
| 11 | noise | 14 Generative Landscape; 15 A Skin to Stand On |
| 12 | shaders | 16 Augmented Projection |
| 13 | cellularautomata | 25 Life |
| 14 | fractals | 26 Recursive Tree |
| 15 | lsystems | 27 Modular Alphabet II |
| 16 | proceduralgeneration | 28 Virtual Creature II; 29 Maze Walker |
| 17 | softbodies | 30 Extrapolated Body |
| 18 | isosurfaces | 31 Implicit Body |
| 19 | boolean_surfaces | 31 Implicit Body |
| 20 | swarmintelligence | 32 Bot |
| 21 | machinelearning | 28 Virtual Creature II; 33 Data Self-Portrait |
| 22 | graphtheory | 29 Maze Walker |
| 23 | foundationscrisis | 34 Impossible Figure |
| 24 | qfeplaboratory | 34 Impossible Figure |
| 25 | postfoundationscrisis | 7 When Things Go Wrong; 35 Virtual Public Sculpture |

## The departures, in one place

The spine is followed where it argues better than the reference (a node is already a transform; forces before waves; the late crisis halls as critique beside code). It is left where the reference and the application agree against it:

- **Repeat before Transform** (c08 before c09): Levin and Brain's first two assignments are Iterative Pattern, then Face Generator; Form+Code also puts Repeat first. Position and parenting are already at c04.
- **Parametric Object early** (c10): the book puts it 20th; Ada's bodies are 74% @export families, and every argument sweeps one.
- **Chance and noise early** (c13-c14, spine 10-11 after spine 5): Unpredictability is the book's fifth exercise group, after Conditional Testing, before Arrays; WP1 in the application; 10 PRINT's regularity before randomness keeps the Modular Alphabet directly before Ten Print. It also repairs the spine's own ladder break (Flow_Field uses noise at spine 6).
- **Surfaces and shaders early** (c15-c16, spine 11-12 before spine 6): the skin you stand on follows the noise ground; Augmented Projection is the book's tenth assignment, and the argument (normals mislead a little, a vertex shader a lot, the collider tells the truth) is one continuous thought.
- **Randomness returns** (c23 at spine place 10): the seed as key, distributions, entropy: the debt half of chance, where the spine puts it.
- **Graph theory early** (c29, spine 22 after spine 16): the application's WP3 puts graph theory beside procedural generation to answer 'how do we navigate an auto-generated world?'; 10 PRINT's Maze Walker opens it.
- **Numbered returns**, not departures: Drawing Machine I and II (c06, c21), Modular Alphabet I and II (c12, c27), Virtual Creature I and II (c18, c28), colour as appearance and as energy (c11, c16).

Measured on this JSON (first-named spine sequence per chapter): order agreement **0.936** of chapter pairs in spine order (0.948 using each chapter's earliest sequence); spine coverage 25/25; 96 distinct halls named, all present in spine.json; no ladder violations; no chapter over 3 new ideas; all 88 vocabulary ids used, plus one `other:undo_redo`; every backstep carries a departure note.

## Chapters

### Part 1: Computing without a computer: one body

*You can write an instruction for a body, build one body in code, give it time, carry it, connect it, record its walk, and direct and check code a machine writes for you.*

#### 1. Computing Without a Computer: an instruction for a body (`c01`, tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Zero (field trip)
- **Code, new:** statements, output, errors. **Returns:** (none)
- **Body:** An instruction body: a six-line rule for a figure of tape on the floor (after LeWitt), carried out by two partners who have not seen your intention; then the same rule typed as print() lines in the supplied Day Zero scene, with one planted typo whose message you read in the Output and Debugger panels.
- **Argument:** axis *how much the instruction fixes*: vague / counted / measured / located. **Prediction:** Measured and located will look most alike: once lengths are fixed the drafters differ only in where they start, and the room's corners pull everyone to the same start. Vague and counted will differ most. **Claim:** The spread between two drafters' bodies is a picture of what the text left open.
- **Debt:** The drafter is someone else's labour (LeWitt's assistants) and the language is English: GDScript's keywords are English words a Swedish class reads as foreign (FLOW-MATIC, Marino ch. 5). The error message is Godot deciding what counts as a valid instruction; 'valid and intentional are different' (Montfort ch. 4).
- **Place:** Stand on your partner's tape body in the classroom; then walk the Point_Zero hall before any code and guess how its works are built (PRIMM predict). Day Zero opens the headset route once, described but not yet required.
- **Godot:** Project Manager and first import; Run Project (F5) and Run Current Scene (F6), stop; print() and the Output panel; Debugger panel: read one error message; Inspector: change the Welcome Label3D text
- **Lineage:** Levin and Brain / precedents: CaCM Exercises, first group 'Computing without a Computer' [V ToC]; LeWitt, 'Paragraphs on Conceptual Art' (1967) and the wall drawings [V research_bauhaus]; Molnar's machine imaginaire [V research_bauhaus]. Processing: LP ch. 2 (editor, running a sketch, errors); Processing Handbook 'Structure 1: Code Elements'. NoC: none (The Nature of Code assumes this semester). Application: before WP1: Freire's reflection and action, the application's hacker ethics. Klee: I.1: the point sets off on a walk; an instruction for a line.
- **Project step:** Write, in six lines, an instruction for a body you want to exist. Keep it: every later chapter can answer it, and the mini project does.

#### 2. Graphic Elements: one body, solid or ghost (`c02`, tracks: short, long)

- **Spine:** primitives. **Halls:** Point_One (carrier); Primitives_Polythedra (encounter)
- **Code, new:** variables, calling, properties. **Returns:** statements, output, errors
- **Body:** A point that is a body: MeshInstance3D.new() given a SphereMesh resource, sized and placed by properties; a supplied StaticBody3D with a CollisionShape3D gives it a collider whose size you set apart from what you see (point-one kit: solid.gd, visible.gd).
- **Argument:** axis *collider radius against visible radius*: none / half / equal / double. **Prediction:** With a ball dropped on each, equal and double will look most alike: a ball resting a few centimetres above a surface is hard to see at hall distance, while none (it falls through) and half (it sinks in) are obvious. **Claim:** What you see and what holds you are two properties of one body; a body can look solid and be a ghost.
- **Debt:** The collider is a second, simpler body standing in for the first: physics approximates your sphere by another sphere or a box. Which bodies may be passed through is decided by one number, not by the mesh.
- **Place:** Walk into the solid one and through the ghost (Point_One's distinction); the desktop walker and the headset player both meet the collider, never the mesh.
- **Godot:** MeshInstance3D; SphereMesh and BoxMesh (PrimitiveMesh resources); add_child(); position and scale properties; StaticBody3D + CollisionShape3D (supplied, opened at c18)
- **Lineage:** Levin and Brain / precedents: CaCM Exercises 'Graphic Elements' (first group in the solutions repo, after the unplugged group in the book) [V github.com/golanlevin/exercises]. Processing: LP ch. 1 Pixels (shapes, Zoog from primitives) and ch. 4 Variables; Handbook 'Shape 1' and 'Data 1'. NoC: none. Application: pre-WP (the F term before entropy, primitives.json). Klee: I.1-4: the point before it moves; the passive point is placed.
- **Departure:** Point_One before Point_Zero: the /course opening starts with Point_Zero (begin once, continue). Here a still body comes first because CaCM opens with Graphic Elements and the Processing Handbook keeps its whole first part static ('static before continuous'). The Point_Zero kit is used unchanged in the next chapter.
- **Project step:** Build the first body your instruction names from a primitive, and decide with one number whether a visitor can pass through it.

#### 3. Clock: the engine calls you (`c03`, tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Zero (carrier); WaveFunctions_Pendulum (encounter)
- **Code, new:** lifecycle, delta, types. **Returns:** variables, properties, calling
- **Body:** A clock built from primitives: a disc and two BoxMesh hands on pivot nodes whose rotation is set every frame from seconds accumulated with delta; an int counts frames and a float counts seconds on the same Label3D (point-zero kit: _ready once, _process every frame).
- **Argument:** axis *what drives the hand*: frame count / delta seconds / physics ticks / system clock. **Prediction:** After 60 s at a steady 60 fps all four agree. Run the same scene at 30 fps or on a 90 Hz headset: delta seconds and system clock stay together and look most alike; frame count runs slow or fast. **Claim:** A frame is not a unit of time; only a hand driven by delta or the clock keeps the same angle on every machine.
- **Debt:** Engine time is sampled: _process runs when the engine decides, and a headset changes what a frame is. Ada measured it: a swing damped per tick keeps 0.451 of its amplitude at 60 Hz and 0.294 at 90 Hz (doc/book/iterations/claude-noc-vs-lineage-2026-09-29). The clock also names whose time counts: the GPU's frames or the calendar's seconds.
- **Place:** Stand under a wall-sized clock in your room; on the headset route the frame-driven hand visibly runs away from the delta-driven one.
- **Godot:** _ready() and _process(delta); int and float; rotation property on a pivot node; Label3D text; Time.get_ticks_msec(); Engine.physics_ticks_per_second
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 3 'Clock' [V ToC]; Catlike Coding's Godot 4 introduction begins by making a clock [V research_engine]; Marclay, The Clock (2010) [mem]. Processing: setup() and draw() (LP ch. 3); Handbook 'Structure 2: Continuous' opens its Part 2. NoC: none. Application: pre-WP. Klee: IV.33-36: the circle as the pendulum freed from gravity; here only its turning, the sine waits for c21.
- **Project step:** Give your body a time: one property that changes with delta, and one sentence on what must not change with frame rate.

#### 4. The Carried Point: name its reference (`c04`, tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Coordinates (carrier); Trans_Introduction (encounter)
- **Code, new:** vectors, transforms, xr. **Returns:** properties, variables, lifecycle
- **Body:** Two points, one the child of a moving parent: set X, Y and Z as a Vector3, move the parent, compare position with global_position; on the XR route hold the point with XR Tools and make a second one holdable yourself (point-coordinates kit). Pickup belongs here, as the ruling says.
- **Argument:** axis *which node the point is a child of*: world / table / your hand / moving platform. **Prediction:** After you walk two metres and turn, world and table children have not moved and look most alike (a still parent is invisible); hand and platform children have gone with their parents. **Claim:** A position is only a number until you name its parent; carrying is re-parenting.
- **Debt:** The frame is a default nobody chose: Y is up, the unit is the metre, the origin is where the scene began. The supplied XR rig expects a standing adult height and two hands (Bagnall's hardware chapter in Queer Game Studies): the body the rig expects is a norm, not a fact.
- **Place:** Carry it: hold the point in your hand on the headset route, or pick it up with the desktop walker's crosshair; put it on the platform and watch the parent take over.
- **Godot:** Vector3; position vs global_position; reparent() and the scene tree; Node3D as a transform; XRToolsPickable (supplied rig); desktop pickup fallback
- **Lineage:** Levin and Brain / precedents: CaCM's 'Geometry' exercises come late (group 11 in the repo) [V]; in 3D and VR a frame must come before a shape, so coordinates enter with Graphic Elements. Processing: LP ch. 14 Transformations and 3D, twelve LP chapters early, because a Godot node is a transform. NoC: ch. 1 Vectors (position only). Application: the application's 'noise and vectors' as basic concepts. Klee: II.14: three dimensions (left/right, top/bottom, front/back).
- **Project step:** Decide what your body is attached to: the world, a table, a hand or another body.

#### 5. Line: connect and measure (`c05`, tracks: long)

- **Spine:** primitives. **Halls:** Point_Lines (carrier); Vectors_Act1_WhatAVectorIs (encounter)
- **Code, new:** expressions, methods, strings. **Returns:** vectors, properties, lifecycle
- **Body:** A segment between two carried points, redrawn every frame by the supplied segment helper (segment.gd show_between(), opened at c15), with b - a, its length() and a Label3D showing the distance as text (point-lines kit). Distance belongs to the line, as the ruling says.
- **Argument:** axis *line thickness*: 2 mm / 1 cm / 5 cm / 20 cm. **Prediction:** At three metres 2 mm and 1 cm look most alike (both read as a line); 20 cm reads as a beam, an object. **Claim:** A line in 3D is always a thin body; its thickness decides whether we read a relation or a thing.
- **Debt:** There is no line in a 3D engine: the helper builds a thin box and turns it with look_at, so every line is a body with a polycount. Distance is Euclidean by default; the crisis chapter (c34) will question the straight line.
- **Place:** Walk between the two points and stretch the line with your hands; the distance text follows you.
- **Godot:** Vector3 subtraction; length() and distance_to(); str() and String formatting; Label3D; supplied segment helper
- **Lineage:** Levin and Brain / precedents: CaCM 'Graphic Elements' (lines) [V repo]; Kandinsky, Point and Line to Plane (1926) [V research_bauhaus]. Processing: line(); LP ch. 3's continuous line from pmouse. NoC: ch. 1 Vectors: magnitude. Application: pre-WP. Klee: I.1-2: the active line, a line limited by fixed points.
- **Project step:** Join two parts of your body with a line, and say whether it is a relation or a limb.

#### 6. Drawing Machine I: the walk that remains (`c06`, tracks: long)

- **Spine:** primitives. **Halls:** Point_Trace (carrier)
- **Code, new:** arrays, conditions, input. **Returns:** vectors, expressions, methods, lifecycle
- **Body:** A recorder: named input actions move a point, its positions are kept in a typed Array[Vector3] (the list first, append after), a condition gates recording until the point has moved far enough (the line's distance), with a capacity and a pause (point-trace kit).
- **Argument:** axis *minimum distance between kept points*: 0 (every frame) / 2 cm / 10 cm / 50 cm. **Prediction:** 0 and 2 cm will look most alike (a smooth ribbon); 50 cm becomes a polyline with visible corners. **Claim:** A trace is not the walk; it is the walk filtered by a rule, and the rule shows as corners.
- **Debt:** The list forgets: at capacity the oldest point is dropped. A rule decides what counts as having moved; standing still leaves no mark. Every recorded walk is a sampled walk.
- **Place:** Walk your own trace: on the headset route your hand or head is the pen, and Klee's walking point becomes your walk.
- **Godot:** Input Map and named actions; Input.is_action_pressed(); Array[Vector3], append(), size(), pop_front(); if / elif / else
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 7 'Drawing Machine', first of two visits [V ToC]; Molnar's machine imaginaire [V research_bauhaus]. Processing: LP ch. 9 Arrays (mouse history) and ch. 5 Conditionals. NoC: none. Application: pre-WP. Klee: I.1: 'an active line on a walk, moving freely' [V klee_sections].
- **Departure:** Drawing Machine is CaCM's seventh assignment; it is met early because Ada's ruled opening ends in Point_Trace (list before append, condition before a distance threshold). It returns as Drawing Machine II (c21, the harmonograph).
- **Project step:** Record one walk around the place your body will stand; keep the points for later (c33 uses them).

#### 7. When Things Go Wrong: the drafter is a machine (`c07`, tracks: short, long)

- **Spine:** primitives, postfoundationscrisis. **Halls:** Primitives_Melencolia (field trip); CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter)
- **Code, new:** ai_assist, debugging, export_build. **Returns:** errors, statements, variables, properties, conditions
- **Body:** The c01 instruction body drafted by an AI assistant as GDScript: you write what should change, what must not change, and one observation that would prove the code wrong; you run it, break it on purpose (the W01 study), step through it with breakpoints, and export a build to the headset or a classmate's laptop.
- **Argument:** axis *how much the prompt fixes (c01's axis, returned)*: vague / counted / measured / located. **Prediction:** The generated bodies converge faster than the human drafters did: vague and counted both come back as a default cube or capsule at the origin, so they will look most alike. **Claim:** Where the prompt is open, the model fills in its defaults; the generated body shows the model's idea of a body, not yours.
- **Debt:** Algorithmic enclosure and the default body: the assistant learned from other people's code and repeats its norms (the capsule player, the cube at the origin). Chun's 'sourcery': seeing generated source is not knowing what it does. A build is a second machine with its own errors (read-only res://, another refresh rate).
- **Place:** Run the build on the headset (the headset is an export) or on a classmate's machine and stand in it: the first time your body exists outside your editor.
- **Godot:** breakpoints, step, the Debugger's stack and variables; the remote scene tree; Project > Export: desktop preset and Android/Quest preset with templates; push_error() and assert()
- **Lineage:** Levin and Brain / precedents: CaCM interview themes 'When Things Go Wrong' and 'The First Day' [V ToC]; LeWitt's drafters as the model for directing a machine drafter [V research_bauhaus]; Queer 3D 2024: 'use ChatGPT to write simpler programs' [V QUEER3D.md]. Processing: Processing Handbook 'Development 1: Sketching' and 'Development 2: Iteration, Debugging'. NoC: none. Application: the application's hacker ethics: Illich's transparency and repairability. Klee: none.
- **Departure:** Ada has no sequence for directing generated code. It closes the opening because the short track needs it in week one (Queer 3D practice) and every later planted bug assumes the debugger. The bias hall (spine 25) is visited as an encounter, not taught.
- **Project step:** Have your instruction body built once by an assistant and once by yourself; keep both and the prompt.

### Part 2: Iterative pattern: a rule makes a family

*You can make many bodies by a rule, assemble a body from parts (and a scan), turn it into a family with @export, and colour and tile it by rules you can read back from the image.*

#### 8. Iterative Pattern: purely repetitive and therefore structural (`c08`, tracks: short, long)

- **Spine:** array_tutorial, primitives. **Halls:** Array (carrier); Point_Line_Grid (field trip); Tutorial_3D (encounter)
- **Code, new:** loops, nested_loops, functions. **Returns:** variables, calling, properties, vectors
- **Body:** A lattice body: a make_box() function called from nested for loops places n x n x n boxes at (i, j, k) * spacing, the Array hall's Molnar lattice before its disorder.
- **Argument:** axis *gap between bodies, as a fraction of their size*: 0 / 0.25 / 1 / 3. **Prediction:** 0 and 0.25 look most alike from the hall door: at a quarter gap the eye still fuses the lattice into one block. 3 reads as scattered bodies. **Claim:** Repetition is structure only while the gap is visible; close the gap and many bodies become one.
- **Debt:** The lattice takes the Cartesian grid as the natural order of things; the grid is 3D's most repeated default (the pixel, Kittler's raytracer). Each box is a node: 20 cubed is 8000 nodes, and the cost comes back at density (c21, MultiMesh).
- **Place:** Walk through it: Tutorial_3D is the same body at room scale; at gap 0.25 you cannot pass, at 1 you can.
- **Godot:** for i in range(n); nested loops; func make_box(); add_child() in a loop; node count in the remote tree
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 1 'Iterative Pattern' and Exercise group 'Iteration' (16 exercises) [V ToC, V repo]; Molnar, (Des)Ordres (1974) [V research_bauhaus; cited in commons/maps/Array/final.md]; Form+Code 'Repeat' [V research_creative]. Processing: LP ch. 6 Loops; Handbook 'Control 2: Repetition'. NoC: none. Application: pre-WP. Klee: I.5-6: structure; the chessboard; 'purely repetitive and therefore structural' [V klee_sections].
- **Departure:** array_tutorial (3) before transformation (2): Repeat comes before Transform in CaCM (Iterative Pattern is assignment 1, Face Generator 2, Iteration the second exercise group) and in Form+Code. Position and parenting were met at c04; what waits is the composite body with pivots (c09).
- **Project step:** Make your body many: a row, a ring or a lattice, and choose the gap.

#### 9. Face Generator: a body of parts, and a scanned one (`c09`, tracks: short, long)

- **Spine:** transformation. **Halls:** Trans_Body (carrier); Trans_Rotation (field trip); Trans_Scale (encounter)
- **Code, new:** parameters, return, import_assets. **Returns:** functions, transforms, properties, vectors
- **Body:** A face or figure assembled from primitives by make_part(mesh, pos, rot, scl) -> MeshInstance3D, every part a child of one parent pivot so the whole turns together; beside it one scanned face or Tilt Brush sculpture imported as .glb and placed with the same function.
- **Argument:** axis *how the second eye is made from the first*: translated / mirrored (scale.x = -1) / rotated 180 degrees / scaled 0.5. **Prediction:** With sphere eyes, translated, mirrored and rotated look identical and only scaled differs. Give the eye one asymmetric feature (a lid) and the closest pair becomes mirrored and rotated. **Claim:** A symmetric part hides which transform made its twin; only an asymmetric feature makes the transform visible.
- **Debt:** The face as a norm: Chernoff (1973) mapped data onto faces because we read faces too readily, and face recognition presumes a canonical face (Blas, Facial Weaponization Suite). scale.x = -1 flips the winding (Godot winds front faces clockwise), so a mirrored mesh can render inside out: symmetry that costs something. The scan brings its own debt: holes, baked light, a polycount you did not choose.
- **Place:** Become it: on the headset route parent the face to your head and meet yourself in a supplied mirror camera; on desktop stand face to face at eye height with the scanned and the generated face side by side.
- **Godot:** func with parameters and a return value; a parent Node3D as pivot; rotation and scale properties; Import dock: .glb/.obj; instantiate an imported scene
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 2 'Face Generator' [V ToC]; Chernoff faces (1973) [V Wikipedia, via search]; Blas, Facial Weaponization Suite (2011-14) [V research_queer]; Aesthetic Programming's 'Geometric emoji' [V research_ccs]; Hannah Hoch's collage (Queer 3D lineage) [V QUEER3D.md]. Processing: LP ch. 7 Functions (Zoog assembled from functions); pushMatrix/popMatrix (ch. 14). NoC: none. Application: pre-WP. Klee: I.9: bone, tendon, muscle as nested parts.
- **Departure:** Back to spine 2 after spine 3 (declared at c08). Importing has no spine sequence: it is the Queer 3D course's day-one practice (3D scanning, Tilt Brush), placed here so a scanned body and a procedural body meet as collage.
- **Project step:** Build your body from named parts with one function; add one imported part if you have a scan.

#### 10. Parametric Object: a body is a family (`c10`, tracks: short, long)

- **Spine:** primitives, color. **Halls:** Primitives_Ignorance (carrier); Color_Context_Placed (field trip); Topology_Entropy_Morphogenesis (encounter)
- **Code, new:** classes, export, setters. **Returns:** functions, parameters, loops, properties
- **Body:** class_name Pod extends Node3D: a body type with @export segments, radius and profile, rebuilt by a setter whenever a value changes, so the Inspector, or a sweep script, is the family's control (Primitives_Ignorance's sphere_high counts triangles the same way).
- **Argument:** axis *segments of a round body*: 4 / 8 / 16 / 64. **Prediction:** 16 and 64 will look most alike at two metres: past about 16 segments the silhouette reads round, and the extra triangles show only in the triangle counter. **Claim:** Roundness is a claim made by the distance you stand at; past a budget, more polygons buy nothing you can see.
- **Debt:** Polycount against smooth deformation (the 2023 application): a smooth body is always a polygon, and a UV sphere bunches its vertices at the poles. The family also hides what it cannot say: an @export range is a fence around the possible bodies.
- **Place:** Carry the family: on the headset route hold the 4-segment and the 64-segment body up to your eye; at ten centimetres the round one is faceted too.
- **Godot:** class_name; @export, @export_range, @export_enum; a setter: var segments := 16: set(v); the Inspector as control; Performance monitor: triangle count
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 20 'Parametric Object' [V ToC]; Form+Code 'Parameterize' (Chair, Wave) [V research_creative]; Molnar's series as the unit of work [V research_bauhaus]; the CCSWG prompt 'describe war in a single class', here 'describe a body in a single class' [V research_ccs]. Processing: LP ch. 8 Objects (Zoog as a class), before arrays of objects. NoC: Introduction's prerequisites: classes. Application: WP2 'queer meshes'; topology and polycount. Klee: I.7: proportion (2:3:5, the golden section) as a parameter.
- **Departure:** Parametric Object is CaCM's 20th assignment and Parameterize has no spine sequence; it comes this early because 74% of Ada's scripts are families built on @export and every later argument sweeps an exported axis. It returns to primitives (Primitives_Ignorance) and visits a colour hall early as a field trip.
- **Project step:** Turn your body into a class with one @export axis of 3-5 values: that axis is your mini project's argument.

#### 11. Custom Pixel: colour is a rule (`c11`, tracks: long)

- **Spine:** color. **Halls:** Color_Grid_Pallet (carrier); Color_Walls (field trip); Color_Rainbow (encounter); Color_Flashlight (encounter)
- **Code, new:** materials, interpolation, dictionaries. **Returns:** loops, nested_loops, classes, export
- **Body:** A floor of pixel bodies you stand on: each tile a box with its own StandardMaterial3D whose albedo is computed from its index by a rule; a Dictionary keyed by Vector2i finds the tile under your feet and recolours it.
- **Argument:** axis *the space a nine-tile gradient walks through*: RGB lerp / HSV short way / HSV long way / HSV stepped in 4. **Prediction:** HSV short way and HSV stepped look most alike (stepping only quantises the same path); RGB passes through grey in the middle and stands apart. **Claim:** The midpoint of two colours is not in the colours but in the space you choose to walk between them.
- **Debt:** Colour on screen is a gamut and a lighting model, not a property of the body: the same albedo reads differently under the flashlight (Color_Flashlight). Knowlton and Harmon turned a nude into symbols (1966) and film stock was calibrated to one skin tone (the Shirley card) [mem]: the pixel has a politics.
- **Place:** Stand on it: walk across the floor and the tile under your feet changes by the rule; hold the flashlight and see the surface change while the material does not.
- **Godot:** StandardMaterial3D.new(), albedo_color, material_override; Color.from_hsv() and Color.lerp(); Dictionary with Vector2i keys
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 6 'Custom Pixel' and Exercise group 'Color' (12 exercises) [V ToC, V repo]; Albers, Interaction of Color (1963) [V research_bauhaus]; Knowlton and Harmon, Studies in Perception I (1966) [mem]; Rozin, Wooden Mirror (1999) [mem]. Processing: Handbook 'Color 1'; LP ch. 1 (RGB). NoC: none. Application: WP3 shading (here as appearance; it returns as energy at c16). Klee: IV.39-43: chromatic energy and the colour circle, an early visit to Klee's last part.
- **Project step:** Give your body family a colour rule computed from its index, not picked by hand.

#### 12. Modular Alphabet: tiles and their rule (`c12`, tracks: long)

- **Spine:** tiling. **Halls:** Pattern_Foundry (carrier); Symmetry_Seventeen (field trip); Tutorial_Tiling_Floor (encounter)
- **Code, new:** booleans, uv. **Returns:** nested_loops, conditions, dictionaries, materials, expressions
- **Body:** A Truchet alphabet in 3D: two module bodies (a quarter-arc tile and its turned twin) placed on a grid by a boolean rule of the cell index; then the same rule baked into an Image and repeated across one plane by UV scale, as the flat port.
- **Argument:** axis *the rule that decides which module goes where*: all the same / checker (i + j) % 2 / row parity i % 2 / diagonal i == j / xor of both parities. **Prediction:** Checker and xor will look most alike: the xor of the two parities is the checker written another way. All the same stands apart as long waves. **Claim:** Two rules that read differently can be one rule; the pattern shows the rule's truth table, not its wording.
- **Debt:** Regularity is the baseline chance needs ('Regularity before Randomness', 10 PRINT). The seventeen wallpaper groups are a closed list; a pattern the list does not name is still a pattern (tiling's ruling: cumulative encounters, not a derivation). A texture is a promise: the UV plane looks tiled but is flat to the feet (Tutorial_Tiling_Walls).
- **Place:** Walk the floor of module bodies; then step onto the flat textured port and feel no arcs underfoot.
- **Godot:** bool, and / or / not; % modulo; Image.create() and set_pixel(); ImageTexture; uv1_scale on StandardMaterial3D; rotation in 90-degree steps
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 8 'Modular Alphabet' and Exercise group 'Conditional Testing' [V ToC, V repo]; Truchet (1704) [mem]; 10 PRINT ch. 30 'Regularity' [V research_ccs]; Crouwel, New Alphabet (1967) [mem]. Processing: LP ch. 5 Conditionals (else, and, or); Handbook 'Control 1: Decisions'. NoC: none. Application: WP3 'unique and dynamic patterns'. Klee: I.5-6: the chessboard, quantitative structure in two dimensions.
- **Project step:** Design two modules of your body and a rule that places them; keep the rule, because chance will replace it.

### Part 3: Unpredictability: chance, noise, skin and appearance

*You can replace a rule with a seeded draw, give a body noise to stand on, build its skin from vertices, and give it an appearance that lies about its shape, and you can say what each approximation hides.*

#### 13. Unpredictability: Ten Print, and the seed that returns (`c13`, tracks: short, long)

- **Spine:** randomness. **Halls:** Randomness_10_PRINT_Algorithm (carrier); Random_Definition (field trip); Random_Cubes (encounter)
- **Code, new:** random, seeds. **Returns:** nested_loops, conditions, booleans, loops
- **Body:** The c12 alphabet with its rule replaced by chance: rng.randf() < p chooses the module in each cell; rng.seed is printed on a label, so the same seed returns the same maze (the runnable random-definition kit).
- **Argument:** axis *probability of the first module (p)*: 0.0 / 0.25 / 0.5 / 0.75 / 1.0. **Prediction:** 0.25 and 0.75 will look most alike: they are mirror twins with the same amount of order in opposite directions; 0.5 is the most maze-like, and 0 and 1 return to c12's 'all the same'. **Claim:** Chance has a dial: p sets how ordered the pattern is, and the seed only picks one member of that family.
- **Debt:** Pseudo-randomness: the numbers are a pattern that returns (Random_Definition). A seed makes chance repeatable, which is what lets you argue with it and what makes it a key (c23). Nake and Nees used random as a stand-in for intuition: can a pseudo-random number stand in for a choice?
- **Place:** Walk the maze at human scale (Randomness_10_PRINT_Algorithm): at p = 0.5 you can get lost; change the seed and it is another room with the same character.
- **Godot:** RandomNumberGenerator; randf(), randi_range(); rng.seed and printing it; randomize() against a fixed seed
- **Lineage:** Levin and Brain / precedents: CaCM Exercise group 'Unpredictability' (coin toss, drunk walk, Ten Print, noise mountains), fifth in the repo, after Conditional Testing and before Arrays [V repo order; contents V research_ccs]; 10 PRINT CHR$(205.5+RND(1)) (2012) ch. 40 'Randomness' [V]; Nees, Schotter (1968) [V research_bauhaus]. Processing: LP ch. 4 random(); Handbook 'Math 4: Random'. NoC: ch. 0 Randomness. Application: WP1 randomness. Klee: none: randomness is absent from the Bauhaus; it enters Klee's lineage with Nake's Hommage a Paul Klee (1965) and Nees's Schotter (1968) [V research_bauhaus].
- **Departure:** randomness (10) moves to right after tiling (5), ahead of change, forces, formfinding and wavefunctions. CaCM puts Unpredictability right after Conditional Testing, Aesthetic Programming at chapter 5 of 10, the 2023 application in WP1; 10 PRINT argues regularity before randomness, so it follows the c12 alphabet directly. Randomness returns at its spine place as debt (c23).
- **Project step:** Replace one decision in your body family with a seeded draw, and print the seed on the label.

#### 14. Generative Landscape: noise you can stand on (`c14`, tracks: short, long)

- **Spine:** noise. **Halls:** Noise_Perlin_Simplex (carrier); Random_Noise_Types (field trip); Noise_Voxel (encounter)
- **Code, new:** noise, instancing. **Returns:** random, seeds, nested_loops, export, classes
- **Body:** A landscape of column bodies: a column PackedScene (mesh and collider) instanced on a grid, its height FastNoiseLite.get_noise_2d(x, z) times an amplitude; beside it the same grid with heights from randf(), so chance and noise stand side by side; the noise type can be simplex, Perlin, value or cellular (Voronoi).
- **Argument:** axis *octaves (fractal layers of the noise)*: 1 / 2 / 4 / 8. **Prediction:** 4 and 8 will look most alike: each octave halves the amplitude, so after four the added detail is smaller than one column. 1 is the smooth blob landscape. **Claim:** Noise is chance that remembers its neighbours; octaves add detail only down to the size of the bodies that show it.
- **Debt:** The blob aesthetic (Queer 3D intro): Perlin and simplex noise made a whole era of 3D look alike, soft hills and organic blobs. Noise is 'nature' chosen for being cheap and smooth; Palle's overflow comparison (Perlin 45, random 635, Voronoi 0, sine space 3284) shows how differently the families behave.
- **Place:** Stand on it: walk the columns; at eight octaves your feet catch on the fine steps, at one you stroll.
- **Godot:** FastNoiseLite (noise_type incl. TYPE_CELLULAR, frequency, fractal_octaves, seed); PackedScene and instantiate(); add_child() in a nested loop
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 4 'Generative Landscape' and 'noise mountains' in the Unpredictability exercises [V ToC; V research_ccs]; Montfort's free project 'Create a Navigable Generated Landscape' [V research_ccs]; Perlin (1985) [mem]. Processing: noise() (LP ch. 13); Handbook 'Math 4'. NoC: ch. 0 'Perlin Noise (a Smoother Approach)'. Application: WP1 Perlin noise and Voronoi diagrams. Klee: none.
- **Departure:** noise (11) moves early with randomness: CaCM has noise inside Unpredictability and Generative Landscape as its fourth assignment, the application puts Perlin noise in WP1, and it repairs a ladder break (spine 6 Flow_Field already uses FastNoiseLite five sequences before spine 11 teaches it).
- **Project step:** Give your body a ground: a noise field it stands on, with a seed you can print.

#### 15. A Skin to Stand On: surfaces from vertices (`c15`, tracks: long)

- **Spine:** noise, primitives. **Halls:** Noise_Space_10 (carrier); Point_Triangle_Context (field trip); Noise_One (encounter)
- **Code, new:** meshes, surface_tool, normals. **Returns:** noise, nested_loops, vectors, functions, return
- **Body:** The c14 landscape as one continuous skin: a function that returns an ArrayMesh built with SurfaceTool from an n x n grid of vertices (two triangles per cell), generate_normals(), and create_trimesh_shape() for a collider you walk on. It starts from one triangle of three Vector3s (Point_Triangle_Context), and it opens the c05 segment helper.
- **Argument:** axis *grid resolution of the skin*: 4 / 8 / 32 / 128. **Prediction:** 32 and 128 will look most alike, until you walk on them; 4 is a faceted crystal. With flat against smooth normals the same 8-grid looks like two different bodies. **Claim:** The surface you see is a story told by normals; the surface you walk on is the triangles.
- **Debt:** Polycount against smooth deformation, now in your own vertices: the collider follows the triangles, the shading follows the normals, and they can disagree (Noise_One: vertex relief without collision). Godot's front faces wind clockwise; a flipped triangle vanishes from one side.
- **Place:** Walk on it: the trimesh collider carries the desktop walker and the headset player; drop supplied RigidBody3D balls and watch them gather in the valleys.
- **Godot:** SurfaceTool: begin, add_vertex, index, generate_normals, commit; ArrayMesh; ImmediateMesh for the first triangle; create_trimesh_shape(); flat vs smooth shading
- **Lineage:** Levin and Brain / precedents: CaCM Exercise groups 'Shapes' and 'Geometry' (later in the book, pulled forward) [V repo]; Catlike Coding's graph-to-surface ladder [V research_engine]; Godot docs 'Using the SurfaceTool' [V research_engine]. Processing: beginShape() and vertex() (Handbook 'Shape 2: Vertices'; LP ch. 14). NoC: none. Application: WP2 'queer meshes and textures'. Klee: I.3-4: medial lines whose figures read as planes.
- **Departure:** Still inside the early noise block (declared at c14). It also returns to primitives' Point_Triangle_Context, where Ada's first authored surface lives. CaCM's Shapes and Geometry come after Curves; surfaces come first here because Ada's bodies must be stood on, not only seen.
- **Project step:** Give your body a skin built from vertices, with a collider that matches it.

#### 16. Augmented Projection: an appearance the body does not have (`c16`, tracks: long)

- **Spine:** shaders, color. **Halls:** Shader_09_FBM (carrier); Shader_01_Shaping (field trip); Shader_11_QueerRubber (encounter)
- **Code, new:** shaders, uniforms. **Returns:** uv, noise, materials, normals, vectors, export, setters
- **Body:** The c15 skin with a ShaderMaterial: vertex() displaces it by fBm and fragment() paints a fresnel rim from dot(NORMAL, VIEW); the uniforms are bound to @export setters so the family is swept from GDScript, while the collider stays the undeformed skin (Shader_09_FBM's glass slab over a moving floor).
- **Argument:** axis *vertex displacement amplitude*: 0 / 0.05 / 0.2 / 0.6. **Prediction:** 0 and 0.05 look most alike in a still (the rim light carries both); 0.6 reads as another body. Walked, all four are the same body. **Claim:** A shader changes what a body promises, never what it is: four bodies to the eye, one to the feet.
- **Debt:** What can an appearance promise that the body of the room does not provide? (the shaders sequence's question). The GPU is 'procedure crystallized' (Gaboury): code run millions of times, invisible in the scene tree. Queer rubber: the shader is where Ada's pink, glossy, impossible surfaces live, and where they spend the frame.
- **Place:** Walk on it: the floor heaves at 0.6 while your feet stay on the flat collider; stand in the gap between image and body.
- **Godot:** ShaderMaterial and a .gdshader (shader_type spatial; vertex(); fragment()); uniform with hint_range; set_shader_parameter(); TIME, NORMAL, VIEW
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 10 'Augmented Projection' [V ToC]; The Book of Shaders ch. 5-13, which the Shader_01..09 halls follow one to one [V research_engine]; Valbuena, Augmented Sculpture (2007) [mem]; Gaboury, Image Objects ch. 5 'Procedure Crystallized' [V research_engine]. Processing: PShader (Handbook 2nd ed. 'Render Techniques') [mem]. NoC: none. Application: WP3 shading algorithms; WP2 queer textures. Klee: IV.39-43: colour as energy (Klee ends in colour; here it comes before force, declared).
- **Departure:** shaders (12) move ahead of change (6) to wavefunctions (9). CaCM's Augmented Projection is assignment 10 of 23, and the Book of Shaders' drawing chapters sit beside colour and pattern. It follows the skin directly because the argument is the same one made bigger: normals mislead a little, a vertex shader a lot, the collider tells the truth. Klee's order (colour last) is not followed.
- **Project step:** Give your body an appearance that lies about its shape, and write down where the lie is.

### Part 4: Machines and creatures: bodies in time and force

*Your bodies flow, fall, hang, reach, draw, sound and play: particles, forces, your own integrator, rays and signals, sines and audio, the seed as key, and one small complete game.*

#### 17. Flow Field: a weather of bodies (`c17`, tracks: long)

- **Spine:** change. **Halls:** Flow_Field (carrier); Change_Intro (field trip); SwarmIntelligence_FlowFields (encounter)
- **Code, new:** packed_arrays, particles, lifetime. **Returns:** noise, lifecycle, delta, vectors, arrays, meshes
- **Body:** A particle system of your own: positions in a PackedVector3Array advected through a FastNoiseLite angle field in _process, each particle reborn at the edge when its lifetime runs out, trails drawn from a bounded buffer; then the same field driving a GPUParticles3D emitter, to compare.
- **Argument:** axis *field frequency*: 0.01 / 0.03 / 0.1 / 0.3. **Prediction:** 0.1 and 0.3 will look most alike: above some frequency the trails turn into hair or fur, a texture rather than currents. 0.01 reads as one wind. **Claim:** Below a frequency a flow field is a place you could be carried through; above it, it is a texture on the air.
- **Debt:** The field is noise again (the blob returns as wind), and particles exist only as long as a number you chose (lifetime) and the frame budget allow. A bounded trail forgets. Rate and accumulation (Change_Intro): a trail is an integral you draw.
- **Place:** Stand in the flow: particles stream around you; on the XR route the field itself carries the player slowly, with no rotation, and you learn why VR comfort is not polish.
- **Godot:** PackedVector3Array; GPUParticles3D and ParticleProcessMaterial; lifetime and one_shot; ImmediateMesh line strips; queue_free() for node particles
- **Lineage:** Levin and Brain / precedents: CaCM Exercise group 'Simulation' (flow field) [V research_ccs]; flow-field essays by Tyler Hobbs [mem]. Processing: Handbook 'Motion 1-2'. NoC: ch. 4 Particle Systems; flow fields in ch. 5. Application: WP1 particle systems; WP2 flow fields. Klee: III.27: water and air as transitional regions; the swimmer.
- **Departure:** change (6) comes after the early chance, noise and shader block (c13-c16): the field is noise, so the ladder puts it after noise, as The Nature of Code places flow fields [V lineage notes]. From here to c22 the spine order holds.
- **Project step:** Put your body in a weather: a field that moves particles, or copies of your body, around it.

#### 18. Virtual Creature: to stand although it could fall (`c18`, tracks: long)

- **Spine:** forces. **Halls:** VFM_09_Legs (carrier); VFM_03_Motion (field trip); Vectors_Act4a_KineticForces (encounter)
- **Code, new:** physics_bodies, collision, forces. **Returns:** classes, export, vectors, instancing, delta
- **Body:** A creature of RigidBody3D parts: a body plate on N legs with its centre of mass shifted by an export, pushed by apply_central_force so that it walks, stumbles or falls; the StaticBody3D and CollisionShape3D supplied since c02 are opened.
- **Argument:** axis *number of legs*: 2 / 3 / 4 / 6. **Prediction:** 4 and 6 look most alike (both standing); 2 falls; 3 stands only if the shifted centre of mass stays inside its triangle. **Claim:** A creature stands when its centre of mass lies over the hull of its feet; beyond three legs, more legs buy margin, not standing.
- **Debt:** Engine physics is a fixed-step approximation: XR Tools sets the physics rate to the headset's refresh, and Ada measured the same body behaving differently at 60 and 90 Hz. Physics also defaults to one gravity, one friction and rigid parts: a norm of what a body is made of.
- **Place:** Carry it and let go: pick the creature up on the headset route, or push it with the walker, and set it on the c15 skin; it stands or falls under your hands.
- **Godot:** RigidBody3D; CollisionShape3D, collision layers and masks; apply_central_force(); center_of_mass_mode; _physics_process()
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 5 'Virtual Creature' [V ToC]; Sims, Evolved Virtual Creatures (1994) [mem]; Jansen's Strandbeest (Queer 3D lineage) [V QUEER3D.md]. Processing: none (Processing has no engine physics; Handbook 'Simulate 2: Physics'). NoC: ch. 2 Forces; ch. 6 Physics Libraries (2024 order). Application: WP4 'algorithmic life' (an early touch). Klee: II.21-25: the tightrope walker, non-symmetrical balance; III: to stand although every possibility of falling remains [V klee_sections].
- **Departure:** No move of its own: in spine order after c17, and after the forward-moved chance, noise and shader block (c13-c16, declared there).
- **Project step:** Give your body weight and a way to fall; decide what keeps it standing.

#### 19. Hanging Sculpture: a form that finds itself (`c19`, tracks: long)

- **Spine:** formfinding. **Halls:** FormFinding_Relaxation (carrier); FormFinding_Catenary (field trip); FormFinding_Equilibrium (encounter)
- **Code, new:** integration, profiling. **Returns:** packed_arrays, classes, physics_bodies, forces, delta, surface_tool
- **Body:** A hanging net integrated by your own Verlet step: points in PackedVector3Arrays, constraints relaxed each fixed step, drawn as a SurfaceTool mesh and pinned at anchors you can grab; timed in the Profiler stepped live against pre-baked in _ready, then set beside Godot's SoftBody3D.
- **Argument:** axis *number of pinned anchors*: 2 / 3 / 4 / 6. **Prediction:** 4 and 6 will look most alike (a sagging canopy); 2 hangs as a catenary hammock, 3 as a sail. **Claim:** The form is not drawn; it is what remains when the forces agree, and where you pin decides which agreement.
- **Debt:** Who chose the criterion under which this form appears to have found its place? (formfinding's question). Your integrator is a fixed-step approximation that can explode; the pre-baked form is cheap but frozen. Profiling makes the frame budget a material: 72-90 Hz leaves about 11-14 ms.
- **Place:** Walk under it and grab an anchor: drag a pin and the canopy finds its form again above your head.
- **Godot:** fixed step with an accumulator in _physics_process(); Verlet position integration; RefCounted class; Profiler and Performance monitors; grabbable anchors
- **Lineage:** Levin and Brain / precedents: Ada addition: CaCM has no form-finding chapter. Gaudi's hanging chain models [mem]; Frei Otto [mem]; Catlike Coding 'Measuring Performance' [V research_engine]. Processing: Handbook 'Simulate 2: Physics' (springs). NoC: ch. 2-3 springs; Verlet constraints in the physics-library chapter [mem]. Application: WP2 soft bodies (cloth). Klee: III.26: the plummet; I.9: the ligament as a fibrous web.
- **Departure:** No move of its own: in spine order after c17, and after the forward-moved chance, noise and shader block (c13-c16, declared there).
- **Project step:** Hang or pin your body and let a force decide one of its dimensions.

#### 20. Personal Prosthetic: the arrow extends your reach (`c20`, tracks: long)

- **Spine:** forces, color. **Halls:** Vectors_Act5_ForceAsPlace (carrier); Color_Paint (field trip); Color_Flashlight (encounter)
- **Code, new:** raycasts, areas, signals. **Returns:** xr, physics_bodies, forces, export, materials
- **Body:** A tool worn on the hand: a held node casts a RayCast3D (Klee's arrow); where it hits, it paints, pulls, drops an Area3D gravity zone or unmakes a collider, and it emits its own signal hit(body) that another node listens to.
- **Argument:** axis *what the ray does at its point*: marks (paint) / pulls (force) / lifts (gravity zone) / removes (collider off). **Prediction:** After thirty seconds of use, pulls and lifts look most alike (bodies gathered near where the ray landed); marks leaves every body in place and only changes surfaces. **Claim:** A prosthetic is defined by what its point does; the same ray is a brush, a hand or a law depending on one function.
- **Debt:** Whose hand is extended, and which bodies can the ray reach? Collision layers decide what exists for it. The controller assumes two hands and a trigger finger (Bagnall). Klee calls the arrow born of the wish to extend one's reach: reach is power.
- **Place:** Become it: wear it on the XR hand, or on the desktop crosshair, and change the room from a distance.
- **Godot:** RayCast3D and intersect_ray(); Area3D with a gravity override; body_entered; signal hit(body), emit(), connect(); a node attached to XRController3D
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 19 'Personal Prosthetic' [V ToC]; Rebecca Horn, Finger Gloves (1972) [mem]; Stelarc, Third Hand [mem]; GDQuest's skin vs controller [V research_engine]. Processing: none (mouse picking is 2D). NoC: ch. 2 forces applied by the user. Application: WP4 (early): algorithmic life acting on the player. Klee: IV.37-38: the arrow (shaft, point, rudder), born of the wish to extend one's reach [V klee_sections].
- **Departure:** Visits a colour hall (Color_Paint, spine 4) long after colour, as a field trip: the painting ray needs raycasts, and raycasts need the physics of c18. A declared return.
- **Project step:** Give the visitor a prosthetic for your body: a way to reach, paint, push or unmake it.

#### 21. Drawing Machine II: the harmonograph (`c21`, tracks: long)

- **Spine:** wavefunctions. **Halls:** WaveFunctions_Pendulum (carrier); WaveFunctions_Unit_Circle (field trip); WaveFunctions_Intro (encounter)
- **Code, new:** trig, basis, multimesh. **Returns:** delta, lifecycle, arrays, export, packed_arrays
- **Body:** A harmonograph: two damped pendulums written as sin and cos of time, with phase and decay per second, drive a pen point; its marks are instances of one MultiMesh; the same angle builds a Basis that turns the drawing table.
- **Argument:** axis *frequency ratio of the two pendulums*: 1:1 / 1:2 / 2:3 / 3:4 / 1:1.01. **Prediction:** In the still at 60 s, 2:3 and 3:4 look most alike (both knotted, 3:4 denser); 1:1 is an ellipse and 1:1.01 slowly precesses into a rosette. **Claim:** Small whole-number ratios close their figure; a ratio one percent off never returns, and the drift is the drawing.
- **Debt:** Damping written per frame breaks at 90 Hz (Ada's measurement): write decay per second. The circle is Klee's pendulum freed from gravity, and a MultiMesh makes ten thousand marks one draw call: the frame budget decides how long a drawing may remember.
- **Place:** Walk around the drawing as it grows in the air; on the headset route one pendulum follows your hand's swing.
- **Godot:** sin(), cos(), TAU; Basis(axis, angle); MultiMeshInstance3D, set_instance_transform(), instance_count
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 7 'Drawing Machine' (second visit) and Exercise group 'Curves' [V ToC, V repo]; the harmonograph [mem]; Tinguely's Meta-Matics (1959) [mem]; John Whitney in Recreating the Past [V research_creative]. Processing: sin() and cos() (Handbook 'Math 3: Trigonometry'; LP ch. 13). NoC: ch. 3 Oscillation. Application: WP1 sine curves and resonance. Klee: IV.33-36: top, pendulum, circle (the pendulum freed from gravity), spiral [V klee_sections].
- **Departure:** No move of its own: in spine order after c17, and after the forward-moved chance, noise and shader block (c13-c16, declared there).
- **Project step:** Give your body a rhythm: one property driven by a sine with phase and decay per second.

#### 22. Synesthetic Instrument: a body you can hear (`c22`, tracks: long)

- **Spine:** wavefunctions. **Halls:** WaveFunctions_AirMusic (carrier); WaveFunctions_Effect_Sound (field trip); Tutorial_Disco (encounter); WaveFunctions_Synthesis_Lab (encounter)
- **Code, new:** audio, ui, timers. **Returns:** trig, areas, signals, packed_arrays, export
- **Body:** An instrument of bars: each bar's length sets the pitch of a tone rendered sample by sample into an AudioStreamWAV as a sum of sines (additive synthesis, Fourier named); struck by hand through an Area3D, played by a Timer-driven step sequencer, controlled from a small world-space panel of sliders (Controls in a SubViewport on a quad).
- **Argument:** axis *tuning of the row of bars*: equal temperament / just intonation / octave doubling / random. **Prediction:** Equal temperament and just intonation will look most alike (their bar lengths differ by under 1%); octave doubling is a steep curve, random a skyline. **Claim:** An instrument's shape is its tuning written in space: pitch is one over length, so a scale is a curve you can walk along.
- **Debt:** Equal temperament is a compromise that makes every interval slightly out of tune, chosen by one musical culture; the sine is the 'pure' tone because Fourier made it the unit. Audio runs on its own clock: a Timer on the frame clock drifts against the audio buffer.
- **Place:** Play it: strike the bars with your hands on the headset route, or with the c20 prosthetic ray; the sound comes from where the bar is.
- **Godot:** AudioStreamWAV from a PackedByteArray; AudioStreamPlayer3D; AudioStreamGenerator (optional); Timer and timeout; Control nodes (HSlider, Label) in a SubViewport on a quad
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 23 'Synesthetic Instrument' (the book's last) and Exercise group 'Sound' [V ToC, V repo]; Fischinger's Lumigraph [mem]; Levin, Audiovisual Environment Suite (2000) [mem]; John Cage (the WaveFunctions_John_Cage hall). Processing: the Sound library (Handbook extension 'Sound'). NoC: ch. 3 Oscillation (waves). Application: WP1 sound experiments and resonance frequencies; WP2 Fourier transforms (named). Klee: IV: kinetic energy.
- **Departure:** No move of its own: in spine order after c17, and after the forward-moved chance, noise and shader block (c13-c16, declared there).
- **Project step:** Make your body audible: one sound whose pitch, volume or timing comes from its geometry.

#### 23. Creative Cryptography: the seed as key (randomness returns) (`c23`, tracks: long)

- **Spine:** randomness. **Halls:** Random_Entropy (carrier); Random_Walk (field trip); Random_Gaussian (encounter)
- **Code, new:** sorting, await. **Returns:** random, seeds, multimesh, arrays, dictionaries, loops
- **Body:** A wall of 200 seeded symbol bodies that hides a message: the seed is the key. Sort them, awaiting one step at a time, and the disorder becomes a readable order; a random walk and a Gaussian scatter drawn from the same seed show the same numbers as other bodies.
- **Argument:** axis *how the same 200 draws are interpreted*: uniform scatter / gaussian scatter / random walk / sorted. **Prediction:** Uniform and gaussian scatter look most alike from afar (both clouds; gaussian is denser at the centre); the random walk is a single thread and sorted a staircase. **Claim:** The same numbers make different bodies; chance is in the draws, form is in the interpretation.
- **Debt:** Entropy: sorting lowers it and costs work; a seed is order dressed as disorder, and Enigma fell because its key space was smaller than it looked (the application's Turing throughline). Who chooses the set within which chance is allowed to operate? (randomness's question). Shannon entropy over 200 symbols is a proxy; the QFEP drift ruling says never to pass it off as more.
- **Place:** Walk along the wall while it sorts itself around you; give your seed to a classmate and their room builds your wall.
- **Godot:** Array.sort() and sort_custom(); await get_tree().create_timer(t).timeout; await a signal; randfn() for a Gaussian
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 16 'Creative Cryptography' [V ToC]; Turing and Enigma in the 2023 application [V APPLICATION.md]; 10 PRINT on pseudo-randomness [V research_ccs]. Processing: LP ch. 10 Algorithms (sorting). NoC: ch. 0 random walks and the normal distribution. Application: WP1 randomness; the entropy throughline (Turing, Enigma). Klee: none.
- **Departure:** Deliberate return: randomness was met at c13 as a value and a seed; here, at its spine place (10, after wavefunctions 9), it returns as debt (distributions, walks, entropy, the seed as key). The creative-coding traditions meet random() early; the spine keeps the deeper treatment where it is.
- **Project step:** Publish your body as a seed: a classmate should rebuild exactly your family member from one number.

#### 24. One-Button Game: stand or sink (`c24`, tracks: long)

- **Spine:** randomness, formfinding. **Halls:** Random_Game (carrier); FormFinding_Forge (field trip); Trans_Pit (encounter)
- **Code, new:** player, state_machines. **Returns:** signals, timers, await, input, ui, physics_bodies, areas, seeds, audio
- **Body:** A round of play made of your bodies: the supplied first-person walker opened (CharacterBody3D, move_and_slide), stones whose states IDLE, WARN, SINKING and GONE are switched by seeded awaited waits, one button (jump, or grab on the headset), a score and restart on a world-space panel, and a sound for each state.
- **Argument:** axis *warning time before a stone sinks*: 0 s / 0.5 s / 1 s / 2 s. **Prediction:** In a mid-round still, 1 s and 2 s look most alike (many stones wear warning rings and the player stands on a safe one); at 0 s no ring is ever visible. **Claim:** Fairness is visible: a warning is a ring in space before it is a rule in time.
- **Debt:** The player body is the most default body in 3D: a capsule (Squash the Creeps, every course). Opening it shows that a CharacterBody3D is a collider with a velocity, not a body with weight, joints or feeling (Montfort's 'Critique My Starter Programs', turned on the capsule). A state machine tidies behaviour into named boxes: what does not fit a state?
- **Place:** Play it: stand on the stones on desktop or headset; the XR body can replace the walker (skin vs controller) without the stones changing.
- **Godot:** CharacterBody3D, velocity, move_and_slide(); enum and match; restart by resetting state, not reloading the scene; input map for one button across desktop and XR
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 11 'One-Button Game' and Exercise group 'Games' [V ToC, V repo]; Godot's 'Your first 3D game' parts 2-3 and 8 as the minimum kit [V research_engine]; Montfort, 'Critique My Starter Programs' [V research_ccs]. Processing: LP ch. 10 Algorithms (a small game taken apart). NoC: the course's midterm Simulation Project, as a checkpoint [V research_creative]. Application: WP3 'How do we navigate an auto-generated world?' (a first answer). Klee: III: to stand despite every possibility of falling, as a rule of play.
- **Departure:** Returns to randomness (10) and formfinding (8) after wavefunctions (9): the game is the synthesis of Part IV and waits until audio, timers, signals and await exist. It is the long track's midterm.
- **Project step:** Midterm: turn your hall into a round with a start, one way to fail, a score and a restart.

### Part 5: Rules that grow: bodies and worlds that make themselves

*Bodies generated by neighbour rules, recursion, grammars and breeding, and a generated world navigated as a graph: procedures you can stop, save, reload and argue with.*

#### 25. Life: a rule for neighbours (`c25`, tracks: long)

- **Spine:** cellularautomata. **Halls:** CA_Introduction (carrier); CA_GameOfLife (field trip); CA_BeyondBinary (encounter); Shader_10_ReactionDiffusion (encounter)
- **Code, new:** buffers. **Returns:** arrays, booleans, nested_loops, multimesh, signals, physics_bodies
- **Body:** A tower grown from a one-dimensional automaton: each generation a row of boxes computed from the row below by a rule number read as bits, with two buffers (current, next) swapped each step; stacked upward, the history is a body you can climb. Reaction-diffusion (Shader_10) is shown as the same double buffer with continuous values: Turing's 1952 spots.
- **Argument:** axis *rule number*: 30 / 90 / 110 / 184. **Prediction:** 30 and 110 will look most alike from a distance (both irregular); 90 is a clean Sierpinski triangle and 184 a traffic of diagonals. **Claim:** One byte of rule decides a whole body; neighbours make a form that no single cell contains.
- **Debt:** The edge: the row wraps with (i + n) % n, a torus nobody sees. Without a second buffer, cells read neighbours already updated, an order-of-evaluation bug that looks like a new rule. Rule 30 is chaos from order; Wolfram's classes are a taxonomy, not a law, and Life is not alive.
- **Place:** Climb it: live cells are StaticBody3D steps (CA_GameOfLife's floor), and the rule's gaps are where you fall.
- **Godot:** Array[bool] or PackedByteArray double buffer and swap; bit operations (rule >> k) & 1; MultiMesh history; a merged collider for live cells
- **Lineage:** Levin and Brain / precedents: CaCM Exercise group 'Simulation' (Life) [V research_ccs]; Wolfram's elementary automata [mem]; Turing, 'The Chemical Basis of Morphogenesis' (1952), the application's throughline [V APPLICATION.md]. Processing: Handbook 'Simulate 1: Biology'. NoC: ch. 7 Cellular Automata. Application: WP2 cellular automata; WP3 reaction-diffusion; WP4 chaos. Klee: I.5: divisional articulation, rhythm by rule.
- **Project step:** Grow one part of your body by a neighbour rule, one generation per step.

#### 26. Recursive Tree: the rule that must be stopped (`c26`, tracks: long)

- **Spine:** fractals. **Halls:** Fractal_RecursiveTrees (carrier); Fractal_Recursion (field trip); Fractal_MengerSponge (encounter); Fractal_GoldenSpiral (encounter)
- **Code, new:** recursion, stacks, queues. **Returns:** functions, parameters, return, basis, multimesh, seeds, profiling
- **Body:** A tree after Munari's rule: branch(pos, basis, length, depth) calls itself twice with a thinner, shorter child until depth reaches 0; then the same tree grown with an explicit stack (depth first) and a queue (breadth first), one generation per step. The Fibonacci spiral hall is visited as the proportion version.
- **Argument:** axis *recursion depth*: 2 / 4 / 6 / 8. **Prediction:** 6 and 8 look most alike: each generation halves the branch, so depth 8's twigs are finer than the silhouette can show, at four times the nodes of depth 6. **Claim:** An apparent infinity is a finite budget: past the depth the eye can resolve, recursion only spends.
- **Debt:** 'Recursion must always be controlled' (Queer 3D intro): with no base case there is no tree, only a stack overflow. Which finite budget gives this apparent infinity its body? (fractals' question). Munari's 'mad branches' turn up in nearly every family: the exception as the queer reading of the rule.
- **Place:** Walk under the canopy and look up; on the headset route stand inside the Menger sponge's hollow at depth 3.
- **Godot:** a recursive function with a base case; Array as stack (push_back/pop_back); Array as queue (push_back/pop_front); the stack overflow error; node count or MultiMesh
- **Lineage:** Levin and Brain / precedents: CaCM Exercise group 'Simulation' (recursive tree) [V research_ccs]; Munari, Drawing a Tree (1978) [V research_bauhaus]; Kawaguchi's growth-model bodies (Queer 3D lineage) [V QUEER3D.md]. Processing: Handbook 'Shape 3: Parameters, Recursion'. NoC: ch. 8 Fractals. Application: WP2 fractal subdivision; WP1 Fibonacci (Fractal_GoldenSpiral). Klee: I.7: proportion and the golden section; I.12: additive building, stone upon stone.
- **Project step:** Let one part of your body contain smaller copies of itself, and choose where it stops.

#### 27. Modular Alphabet II: a grammar that grows (`c27`, tracks: long)

- **Spine:** lsystems. **Halls:** LSystems_Grammar_Lab (carrier); LSystems_Living (field trip); LSystems_Architecture (encounter)
- **Code, new:** resources. **Returns:** strings, dictionaries, stacks, recursion, export, classes, meshes
- **Body:** A plant or a building from words: an axiom and a Dictionary of rules rewrite a String n times under a symbol budget; the supplied turtle (opened) reads F + - [ ] into branch bodies; the grammar is a custom Resource with @export fields saved as .tres, so a family of plants is a folder of files.
- **Argument:** axis *branching angle in the grammar*: 15 / 25.7 / 45 / 90. **Prediction:** 15 and 25.7 look most alike (both tall and plant-like); at 90 the same grammar becomes a rectilinear building (LSystems_Architecture). **Claim:** The rule says what grows; the interpreter decides what it becomes: one grammar is a weed at 25 degrees and a city block at 90.
- **Debt:** What does a rule say, and what does its interpreter allow it to become? (lsystems' question). The string grows exponentially, so a symbol budget is a grammar's base case. Lindenmayer's plants are idealised: botany as a formal language.
- **Place:** Walk through the grammar at 90 degrees: LSystems_Architecture turns the turtle's centrelines into corridors with colliders.
- **Godot:** building a String; a Dictionary of rules; class_name X extends Resource with @export; ResourceSaver.save() and load(); the supplied turtle, opened
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 8 'Modular Alphabet' (second visit) and Exercise group 'Text and Language' [V ToC, V repo]; Lindenmayer (1968) [mem]; Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants (1990) [mem]. Processing: Handbook 'Typography' as strings [mem]. NoC: ch. 8, the L-systems section. Application: WP2 L-systems. Klee: I.1: the line on a walk; the turtle is Logo, Klee's walking point with a grammar.
- **Departure:** Returns to Modular Alphabet (c12) as a numbered visit: modules become symbols, and placement becomes a grammar.
- **Project step:** Save your body family as Resource files, one member per file.

#### 28. Virtual Creature II: bred, not designed (`c28`, tracks: long)

- **Spine:** proceduralgeneration, machinelearning. **Halls:** PG_Genetic_Evolution (carrier); ML_Evolution (field trip); PG_Space_Colonization (encounter)
- **Code, new:** files, json, save_load. **Returns:** resources, sorting, random, seeds, classes, export, physics_bodies
- **Body:** A population of c18 creatures whose genomes (leg count, lengths, centre of mass) are custom Resources, mutated and crossed; the fittest by a criterion you write are sorted, kept and saved as JSON in user://, so evolution continues after you quit.
- **Argument:** axis *fitness criterion*: distance walked / height reached / time upright / nearness to the player. **Prediction:** After twenty generations distance walked and time upright look most alike (both breed low, wide, many-legged bodies); height reached breeds towers that fall. **Claim:** The evolved body is a portrait of its fitness function: change the criterion and a different creature wins.
- **Debt:** What counts as a desirable body? (procedural generation's question). Fitness is a norm written as one number, and selection is a judgement you handed over. Evolved creatures are known to exploit physics bugs to win [mem]: evolution finds the engine's debts before you do.
- **Place:** The elite creature is released into your hall; with 'nearness to the player' it walks toward you on the headset route.
- **Godot:** FileAccess; JSON.stringify() and JSON.parse_string(); user:// paths; saving and loading a population; Resource.duplicate(true)
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 5 'Virtual Creature' (second visit) [V ToC]; Sims, Evolved Virtual Creatures (1994) [mem]; Latham and Todd, Mutator [mem]. Processing: LP ch. 18 Data (JSON). NoC: ch. 9 Evolutionary Computing; ch. 11 Neuroevolution (named). Application: WP3 evolutionary algorithms and procedural generation. Klee: I.10: propagation (the plant, the watermill).
- **Project step:** Let the visitor's choice breed your body, and save and reload the population between sessions.

#### 29. Maze Walker: navigate an auto-generated world (`c29`, tracks: long)

- **Spine:** graphtheory, proceduralgeneration. **Halls:** GT_Pathfinding (carrier); PG_Caves_Mazes (field trip); GT_Spanning_Trees (encounter)
- **Code, new:** graphs, search, navigation. **Returns:** queues, stacks, dictionaries, random, seeds, player, signals
- **Body:** A generated maze read as a graph: cells are nodes, open walls are edges in a Dictionary of neighbour lists; breadth-first search finds the route and lays a line of lights; then a NavigationAgent3D with the player's radius walks it, and a button closes an edge and forces a re-plan (GT_Pathfinding).
- **Argument:** axis *probability that a wall between two cells is open*: 0.3 / 0.45 / 0.5 / 0.6 / 0.8. **Prediction:** 0.6 and 0.8 look most alike (a route exists and the lights reach the exit); at 0.3 and 0.45 the lights stop short. The switch lies near 0.5, the bond percolation threshold of a square grid. **Claim:** Connectedness is not proportional to openness: near one probability a world snaps from islands to a continent.
- **Debt:** What counts as a connected, usable route? The navmesh is baked for one body radius: a wheelchair, a crawling body or a flying one gets another world. Which relation survives when the picture is rearranged? (graph theory's question). Homophily in network models (Chun, Discriminating Data) [mem].
- **Place:** Walk the maze by the lights; on the headset route close an edge with your hand and watch the route re-plan around you.
- **Godot:** Dictionary adjacency lists; breadth-first search with a queue; AStar3D / AStarGrid2D; NavigationRegion3D and baking; NavigationAgent3D (radius)
- **Lineage:** Levin and Brain / precedents: 10 PRINT ch. 65 'Maze Walker in BASIC' [V research_ccs]; Montfort's 'Navigable Generated Landscape' [V research_ccs]; CaCM Exercise group 'Games' [V repo]. Processing: none. NoC: ch. 5 path following [mem]. Application: WP3 graph theory and 'How do we navigate an auto-generated world?' [V APPLICATION.md]. Klee: II.15: railroad tracks as the measure of a path.
- **Departure:** graphtheory (22) moves ahead of softbodies (17), isosurfaces (18), swarm (20) and machine learning (21), straight after procedural generation (16): the 2023 application puts graph theory in WP3 beside procedural generation to answer 'how do we navigate an auto-generated world?', and PG_Caves_Mazes already needs the graph (lineage note e).
- **Project step:** Make your hall navigable by a body other than yours: bake it for another radius and see what changes.

### Part 6: Leaving the lab: extrapolated bodies

*Bodies that deform, fuse, flock, learn and close from only one standpoint, ending in a public body that other people can revise.*

#### 30. Extrapolated Body: soft, pinned, deforming (`c30`, tracks: long)

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); SoftBodies_Carusell (field trip); Topology_Entropy_Morphogenesis (encounter); SoftBodies_Affect_Theory_Visualization (encounter)
- **Code, new:** composition, tool_scripts. **Returns:** physics_bodies, export, setters, meshes, surface_tool, profiling, particles
- **Body:** A body that extends past its skeleton: a SoftBody3D skin over a RigidBody3D core, composed as child scenes (skin and controller), pinned at chosen points; an @tool script bakes a settled soft pose into a static ArrayMesh with a trimesh collider you can lean on.
- **Argument:** axis *subdivisions of the soft mesh*: 1 / 2 / 4 / 8. **Prediction:** Settled and sagging, 4 and 8 look most alike; 1 folds like card, 2 dents in a few facets. **Claim:** A body can only deform where it has vertices: smooth movement is paid for in polygons.
- **Debt:** Polycount against smooth deformation (the 2023 application) in its plainest form: the solver moves vertices, so a low-poly body is a stiff body. What holds a deforming body together, and which attachments are allowed to change? (softbodies' question). Bellmer, Kawaguchi and Satterwhite: the extrapolated body is where the queer lens looks hardest at the norm of an intact figure.
- **Place:** Become it: on the headset route the soft skin hangs from your hands and deforms as you move; on desktop, lean the walker against the baked pose.
- **Godot:** SoftBody3D (simulation_precision, pressure_coefficient, pinned points); PinJoint3D; a scene instanced as a component; an @tool script run in the editor; baking to ArrayMesh with create_trimesh_shape()
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 22 'Extrapolated Body' [V ToC]; Stelarc [mem]; Bellmer, Kawaguchi, Satterwhite (Queer 3D lineage) [V QUEER3D.md]. Processing: none. NoC: soft-body springs in the physics-library chapter [mem]. Application: WP2 soft bodies (cloth, liquids, rubber) and 'the algorithmic topology of desire'. Klee: I.9: bone, ligament, tendon, muscle as passive, medial and active.
- **Departure:** No move of its own: in spine order, after graph theory, which was moved ahead of it at c29 (declared there).
- **Project step:** Give your body a part that deforms, and choose its polygon budget knowingly.

#### 31. Implicit Body: a field decides where the skin is (`c31`, tracks: long)

- **Spine:** isosurfaces, boolean_surfaces. **Halls:** ISO_Metaballs (carrier); ISO_LookupTable (field trip); Boolean_Verbs (encounter)
- **Code, new:** threads. **Returns:** noise, surface_tool, normals, tool_scripts, profiling, shaders, uniforms, packed_arrays
- **Body:** Metaball bodies: a density field summed from spheres, sampled on a grid and meshed by marching cubes with a supplied case table on a worker thread, re-meshed when a ball moves; beside it the same union built with CSG, to set a field's fusion against a Boolean's seam.
- **Argument:** axis *fusion of two sources (Ada's shared ISO and Boolean vocabulary)*: distinct / necked / lobed / single. **Prediction:** Lobed and single look most alike from the field side; the CSG union shows a crease wherever the field shows a neck. **Claim:** A field fuses bodies with smooth necks and a Boolean joins them with a seam: fusion belongs to the method, not to the shapes.
- **Debt:** The engine of the blob aesthetic (Gehry and Hadid in the Queer 3D lineage): the neck between sources is where metaballs look 'organic'. The marching-cubes table is a supplied black box of 256 cases; read twenty lines of it as a code-critique station (after Marino's reading of Kittler's raytracer). Which samples and threshold are enough to declare a boundary? (isosurfaces' question).
- **Place:** Walk through the neck between two sources: the extracted mesh has a trimesh collider, and a CSG subtraction carves a burrow you can enter (Boolean_Verbs).
- **Godot:** Thread and WorkerThreadPool (wait to release); marching cubes into an ArrayMesh; a supplied lookup table; CSGCombiner3D and use_collision; Profiler comparison with a raymarched shader
- **Lineage:** Levin and Brain / precedents: Ada addition (no CaCM chapter): Lague, Marching Cubes and Godot-Marching-Cubes [V research_engine]; Quilez, smooth minimum [V research_engine]; Marino, Critical Code Studies ch. 6 'Kittler's Code' [V research_ccs]. Processing: none. NoC: none (Lague's Coding Adventures: Marching Cubes) [V research_engine]. Application: WP2 queer meshes; topology and polycount. Klee: I.12: additive making (stone on stone) and subtractive making (chipping away).
- **Departure:** No move of its own: in spine order, after graph theory, which was moved ahead of it at c29 (declared there).
- **Project step:** Make two of your bodies fuse, by field or by Boolean, and choose which seam you want.

#### 32. Bot: many bodies, local rules (`c32`, tracks: long)

- **Spine:** swarmintelligence. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_Swarm_Intelligence_Algorithms (field trip); SwarmIntelligence_PhysarumColony (encounter)
- **Code, new:** inheritance, groups. **Returns:** multimesh, vectors, forces, profiling, areas, signals, state_machines
- **Body:** A flock of your bodies: a base class Agent whose steer() is overridden by Boid, Follower and Shy subclasses; neighbours found through a group or an Area3D sensor; drawn as one MultiMesh once the node count gets expensive.
- **Argument:** axis *separation weight*: 0 / 0.5 / 1.5 / 4. **Prediction:** 1.5 and 4 look most alike in a still (an evenly spaced flock); 0 collapses into a clump and 0.5 into tight strings. **Claim:** A flock's shape is three weights; the collective decision is a spacing rule that nobody holds.
- **Debt:** Whose local information contributes to the apparent collective decision? (swarm's question). Inheritance freezes a taxonomy of bodies (Agent above Boid), and a group call reaches every hall (Ada's call_group lesson).
- **Place:** Stand in the flock: the boids avoid your head and hands (an Area3D on the XR rig or the walker).
- **Godot:** extends a custom class, super(), overriding; add_to_group() and get_nodes_in_group(); Area3D as a sensor; one node per agent against one MultiMesh
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 12 'Bot' (a bot as an autonomous agent) [V ToC]; Reynolds, Boids (1987) [mem]; Lague, Boids [V research_engine]. Processing: LP ch. 22 Advanced OOP (inheritance). NoC: ch. 5 Autonomous Agents (steering, flocking). Application: WP4 swarm intelligence. Klee: none.
- **Departure:** No move of its own: in spine order, after graph theory, which was moved ahead of it at c29 (declared there).
- **Project step:** Make your body a species: a base class and two behaviours that inherit from it.

#### 33. Data Self-Portrait: whose data trains the body (`c33`, tracks: long)

- **Spine:** machinelearning. **Halls:** ML_Classification (carrier); ML_Perception (field trip); CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter)
- **Code, new:** testing. **Returns:** arrays, dictionaries, json, save_load, loops, uv, materials, packed_arrays
- **Body:** A self-portrait as a classifier: your c06 walk traces, and classmates' with consent, become labelled points; k-means or a perceptron paints its decision field onto the floor you stand on; a headless test asserts that it learns what it should and fails where it must (XOR).
- **Argument:** axis *who labelled the training data*: you / the class / a default dataset / random labels. **Prediction:** The class and the default dataset look most alike (smooth, confident regions); random labels give a speckled field; your own labels draw the most particular map. **Claim:** The decision field is a map of who labelled the data; the machine's confidence is borrowed from its labellers.
- **Debt:** What has been named a feature, a label or an improvement? (machine learning's question). Models are always biased (Queer 3D intro); the Feminist Data Set labels slowly and in public. A test proves only what you thought to ask.
- **Place:** Stand on your own portrait: the field under your feet says which class your position belongs to; walk across the boundary the data drew.
- **Godot:** assert(); a headless test scene run from the command line; a small supplied test runner; updating an Image field each step
- **Lineage:** Levin and Brain / precedents: CaCM Assignment 9 'Data Self-Portrait' and Exercise group 'Machine Learning' [V ToC, V repo]; Aesthetic Programming ch. 10 'Machine unlearning' [V research_ccs]; Feminist Data Set [V research_queer]. Processing: none. NoC: ch. 10 Neural Networks (the perceptron). Application: WP3 neural networks; WP4 AI; Turing's B-type machine. Klee: none.
- **Departure:** No move of its own: in spine order, after graph theory, which was moved ahead of it at c29 (declared there).
- **Project step:** Train something on data about your visitors or yourself, and write the test that would catch it lying.

#### 34. Impossible Figure: what a model lets you claim (`c34`, tracks: long)

- **Spine:** foundationscrisis, qfeplaboratory. **Halls:** Escher_Impossible (carrier); NonEuclidean_Spaces (field trip); QFEP_E_Term (encounter)
- **Code, new:** camera. **Returns:** shaders, uniforms, signals, vectors, testing, packed_arrays
- **Body:** An anamorphic body: three disconnected beams that close into a Penrose triangle from one standpoint only; a script reads the active Camera3D's position and forward vector and emits viewpoint_locked when the visitor stands there; beside it a triangle whose angle sum changes with a curvature uniform (NonEuclidean_Spaces).
- **Argument:** axis *where the camera stands*: the locked point / 0.5 m off / 2 m off / from above. **Prediction:** 0.5 m off and 2 m off look most alike (both plainly broken); only the locked point closes the figure; from above shows three separate beams. **Claim:** An impossible body is possible from exactly one place; like a proof, it holds only where it is made to be seen.
- **Debt:** What does this model let us claim, and what cannot follow from this demonstration? (the crisis question), and what exactly does the instrument measure? (the QFEP question: never call spread Shannon entropy). Every Ada DNA tile was shot from one camera standpoint, and five of seven 'inert' verdicts turned out false from another angle.
- **Place:** Find the one spot: walk until the triangle closes; on the headset route your head is the camera, so it closes for your eyes only.
- **Godot:** Camera3D and get_viewport().get_camera_3d(); forward as -global_transform.basis.z; near, far and culling; a SubViewport camera
- **Lineage:** Levin and Brain / precedents: Ada addition (no CaCM chapter); Code Societies' 'Critical Simulation' session as the model of critique beside code [V research_creative]; Reutersvard and Penrose (Queer 3D lineage) [V QUEER3D.md]; Gaboury, 'Culling Vision' [V research_engine]. Processing: camera() and perspective() (LP ch. 14). NoC: none. Application: WP4 non-euclidean spaces; the application's paradoxes of infinity and entropy. Klee: II.15-20: perspective as optical illusion; a wall 'logically right but psychologically wrong'.
- **Project step:** Place one work in your hall that only closes from one standpoint, and mark the spot, or refuse to.

#### 35. Virtual Public Sculpture: a body in the collective museum (`c35`, tracks: long)

- **Spine:** postfoundationscrisis. **Halls:** SpeculativeComputation_Collective_Knowledge (carrier); PostCrisis_Synthesis (field trip); SpeculativeComputation_Rhizome_Network (encounter)
- **Code, new:** other:undo_redo. **Returns:** export_build, xr, save_load, json, resources, signals, instancing, testing, ai_assist, import_assets
- **Body:** Your family placed as a public work in a shared hall: each visitor's change is kept as a provenance record with an undo history (UndoRedo), the hall reads records written in other halls (PostCrisis_Synthesis), and the build ships to the headset and to the class's shared museum.
- **Argument:** axis *who may change the sculpture*: only the author / anyone, last write wins / anyone, with kept history / no one (sealed). **Prediction:** Only the author and sealed look most alike to a visitor at any moment (unchanging); last write wins drifts toward the latest visitor, and kept history grows layers. **Claim:** A public body is its edit rule: who may revise it, and whether revisions are kept, shows in its shape over a week.
- **Debt:** Can the work keep its conditions, exclusions and possible revisions available to others? (the post-crisis question). Illich's repairability and the application's commoning: a sculpture that can be opened and changed. Collective memory is also surveillance: the provenance log records its visitors.
- **Place:** Show it: it stands in the shared museum hall, where classmates walk, carry, revise or become it, on desktop and headset.
- **Godot:** UndoRedo; Dictionary provenance records; a shared user:// file or a supplied sync; export presets (desktop and Quest); the final build checklist
- **Lineage:** Levin and Brain / precedents: CaCM Assignments 21 'Virtual Public Sculpture' and 13 'Collective Memory' [V ToC]; the Nature of Code Ecosystem Project [V research_creative]; Code Societies 'Distributed Web of Care' [V research_creative]. Processing: Handbook 'Synthesis 4' and 'Output 2'. NoC: the Ecosystem Project, a museum exhibit of creatures [V research_creative]. Application: the application's hacker ethics (Freire, Illich, commoning) and its final year of publication. Klee: IV.43: the close, where the line returns to the dot of page one.
- **Project step:** Final project: place your family in the collective museum with its prediction, claim, debt comment and edit rule.

## What this candidate learned from comparable courses

- Code as Creative Medium [V ToC, V exercise repo]: the two-kind unit. A short closed exercise trains one code idea (the CODE strand, PRIMM drills); an open assignment asks for a work with a point of view (BODY, ARGUMENT, PLACE). Every chapter here is named after one of its assignments or exercise groups.
- Code as Creative Medium: each assignment carries annotated historical precedents, so each chapter's lineage.reference names one or two works that answered the brief before, tagged [V] or [mem].
- Code as Creative Medium: Computing without a Computer comes first (Day Zero becomes an unplugged LeWitt exercise), and Unpredictability comes fifth, right after Conditional Testing and before Arrays; this candidate moves chance and noise forward from spine 10-11 to just after tiling on that evidence.
- Code as Creative Medium: Variations for different skill levels (from summaries [agg]) become the two tracks sharing one chapter at two depths, and the 'Bimodal Classroom' interview names Konstfack's mixed groups.
- Code as Creative Medium, against the grain: the book's last assignments are body briefs (Personal Prosthetic, Parametric Object, Virtual Public Sculpture, Extrapolated Body); Ada pulls Parametric Object to chapter 10 and makes the body the subject from chapter 2. Screen- and web-bound briefs (Browser Extension, Experimental Chat, Voice Machine) are dropped.
- Code as Creative Medium, what it lacks: its stance is point of view, not debt, and it is 2D and web-first. The DEBT layer comes from critical code studies (Marino's code critique, Chun's sourcery, a debt comment in the student's own code), and the 3D engine demands (the engine calls you, the tree, no immediate drawing) from Godot's own courses.
- Processing Handbook [V]: numbered returns (Drawing Machine I and II, Virtual Creature I and II, Modular Alphabet I and II), a Synthesis that closes each part, static bodies before the draw loop, and debugging as a chapter (c07), not an appendix.
- 10 PRINT [V]: regularity before randomness (the Modular Alphabet directly precedes Ten Print), the maze as a walkable place, and the Maze Walker as the graph chapter's opening.
- Aesthetic Programming [V]: the RunMe/ReadMe pair becomes body plus falsifiable prediction and claim; pause weeks with no new syntax become the long track's six Synthesis weeks; the final project is chosen two units before the end.
- Recreating the Past (SFPC) [V]: recreate a precedent (Molnar's lattice, 10 PRINT, the harmonograph) and write the difference between original and recreation as debt; its course also ends in Body and Glitch/Deformation, as Part VI does.
- Code Societies (SFPC, 3 weeks) [V]: a three-week critical course with a guest per session, the model for the short track's third week, and for teaching the crisis, QFEP and post-crisis halls as critique beside code (c34, c35) rather than as more code.
- The Nature of Code [V]: particles, forces, oscillation, CA, fractals, evolution, agents and networks as the Part IV-VI ladder, and the Ecosystem Project, a museum exhibit of creatures, as the model for placing each body in your own hall of the museum.
- Klee, Pedagogical Sketchbook [V via lineage map]: the corrected order (pendulum and top in Part IV, the arrow as the wish to extend one's reach, the book ends in colour) gives lineage anchors for the clock, the creature's balance, the prosthetic and the harmonograph; the course names where it does not follow Klee (colour before force).
- Critical code studies (Marino, CCSWG, Montfort) [V]: write first, read after, so every chapter makes the body before the debt step; 'Critique My Starter Programs' is turned on Godot's capsule player (c24); the marching-cubes table is read as a Kittler-style code-critique station (c31).
- Queer and feminist teaching (CCS 382, Queer Game Studies, Feminist Data Set, Blas) [V]: failure before futures (debt before ontology), a scanned body in week one (c09), consent and slow labelling for the data chapter (c33).
- GDQuest and Godot's 'Your first 3D game' [V]: use before make, with supplied parts openly declared and opened later (the segment helper at c15, the collider at c18, the walker at c24, the turtle at c27); the minimum game kit (player, input, score, restart) for the One-Button Game.

## Sieve pass (Palle's three questions)

1. **Does it thicken the cognitive water?** Each chapter gives three handles at once: a named brief with an art-historical lineage (a way into the problem that is not the syntax), a body you can stand in, and a prediction that can be wrong. The numbered returns (I and II) give a student a way to move back through the course rather than only forward.
2. **What is foreclosed?** Levin and Brain's order is a creative-coding order, so it pulls toward 'make something expressive' rather than 'what does this approximation owe'; the debt steps have to push against the reference's cheerfulness every chapter. The early chance/noise block also delays forces, so a student who came for physics waits until chapter 18. And the brief-per-chapter format risks pastiche of the precedent (Recreating the Past's own caution): the body should leave its precedent, not copy it.
3. **What lives in the dark spot?** The precedents are almost all canonical, mostly Western, mostly male computational art (Molnar and Albers are the exceptions the canon already admits); the queer lineage Palle teaches (Hoch, Bellmer, Satterwhite, Perry, Kawaguchi, Blas) enters at the debt and place steps, not as the brief. Whether that is a habitat or a seal is the course's open question: a teacher could swap the precedent of any chapter for one from the Queer 3D list without changing its code ladder, and that swap is where the course should be argued.

## Verification notes

- [V] Code as Creative Medium: Part One assignment list and Part Two exercise list from the Penguin Random House education page (fetched this session); the order of the 18 coded exercise groups (Graphic Elements, Iteration, Color, Conditional Testing, Unpredictability, Arrays, Time and Interactivity, Typography, Curves, Shapes, Geometry, Image, Visualization, Text and Language, Simulation, Machine Learning, Sound, Games) from github.com/golanlevin/exercises (fetched this session). The contents of Unpredictability and Simulation (Ten Print, noise mountains, recursive tree, flow field, Life) are from research_ccs.md.
- [agg] The assignment format (Brief, Learning Objectives, Variations) and the grouping of assignments by concern are from search summaries, not the book's pages.
- [mem] The specific precedents named per assignment (Tinguely, Rozin, Horn, Stelarc, Sims, Crouwel, Truchet, Fischinger, Valbuena, Perlin, Marclay, Gaudi, Otto) are my own choices from memory, not Levin and Brain's gallery for that assignment; Chernoff (1973) was confirmed through a search result only.
- [V] Hall names, carriers and hooks: spine.json, survey_bundle.json (teachable_hook, artifact_features), maps/ada.json (carriers, DNA axes, sequence questions, rulings) and maps/lineage.json (Klee sections, WP placement, ladder breaks). The maps were present when checked; no wait was needed.
- [V] Measurements quoted from the repo: 74% @export (BRIEF.md); the 60/90 Hz amplitude figures (doc/book/iterations/claude-noc-vs-lineage-2026-09-29 via maps/ada.json); the 'five of seven inert verdicts false' figure (CLAUDE.md).
- Not checked: whether each hall's installed work actually supports the body described in its chapter; the chapter bodies are designs built from the survey hooks, not tested lessons.
