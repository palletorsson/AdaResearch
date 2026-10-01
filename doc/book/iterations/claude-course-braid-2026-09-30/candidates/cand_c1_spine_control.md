# The Spine as It Stands: a braided course in the museum's order (control)

Candidate id `c1_spine_control`. Auto-research run 2026-09-30/10-01. Written to the contract in `CONTRACT.md`; the JSON twin is `cand_c1_spine_control.json` (same folder).

**Anchor.** Ada's spine as it stands (commons/maps/curriculum_spine.json v1.5: 25 sequences, 204 working-tree halls), which follows introductory Processing (spine 1-5) and The Nature of Code (spine 6-21) with Ada-only blocks (formfinding, shaders, isosurfaces, boolean, graphs) and the crisis arc (23-25). The braid is applied chapter by chapter; no chapter is moved out of spine order.

**What a control is for.** This candidate changes nothing about the order. It lays the braid (CODE, BODY, ARGUMENT, PLACE; FOUNDATION, DEBT, ONTOLOGY) over the 25 sequences exactly as `commons/maps/curriculum_spine.json` has them. Where a hall uses an idea before the spine teaches it, the control **supplies** the idea (named, opened later) instead of moving the hall. Every other candidate can be read against it: what does moving a chapter buy, and what does it cost?

Legend: **[V]** verified in a file this run (named); **[mem]** recalled, not checked; **[P]** a prediction written before any render, falsifiable by design.

## For the student: why this order

You will learn to program by walking Ada's museum in the order it is built. It opens as Paul Klee's point going for a walk and as the first semester every creative-coding course teaches: one body, a variable, a boundary, a frame, a measured relation, a recorded walk, a loop, a surface, a class, a pattern. Each idea makes a body you can stand on, walk through, carry or become. It continues as The Nature of Code: bodies that change, are thrown, balance, swing, happen by chance, fill space as noise, grow by rules, go soft, blur into fields, flock and learn. It ends where no coding course goes: graphs, the foundations crisis, the QFEP laboratory and the world outside the lab. Every chapter asks the same things. Build a body in code. Turn it into a family with one axis. Write down which two members will look most alike before you render them, then make the comparison image and one sentence it supports. Put the body where a body meets it. Then say what the approximation owes. This order is one choice among several: chance, noise and sound arrive late here, where The Nature of Code and Aesthetic Programming put chance early. The course keeps the museum's order so every hall you visit is the one you are learning in, and so you can see what the other orders would change.

## Shape at a glance

| | |
|---|---|
| Chapters | 39 in 6 parts |
| Order agreement with the spine | 1.0 by construction: every chapter's sequence is in spine order. This sits deliberately **outside** the 0.6-0.95 band the contract rewards; the control is the baseline, not a bid. |
| Departures | none. Returns are declared inside the chapters (list below). |
| Spine coverage | 25 / 25 sequences; 140 distinct halls used, all present in `spine.json` [V] |
| Load | no chapter introduces more than 3 code ideas; chapter 33 introduces none (a pause week) |
| Code vocabulary | all 83 contract ids introduced, plus 4 `other:` ideas (pins_joints, bit_ops, three_valued_logic, metrics_log); ladder check passed (no idea returns before its chapter) [V build.py] |
| Small complete game | player, camera (12), input (6), ui (24), save_load (16), audio (14), export_build (10), physics_bodies (18), instancing (13), signals (10) |
| xr / import_assets / ai_assist | chapter 4 / chapter 12 / chapter 10 |

## Parts

**I. The point goes for a walk (spine 1: primitives)**: chapters 1-10. You make one body from code, give it a boundary, place it in a frame, measure it against another, record its walk, repeat it on a grid, build a surface from vertices and pay for smoothness, and ship a first build.

**II. Frame, many, colour, pattern (spine 2-5)**: chapters 11-16. You pose bodies in time, walk in a body of your own (scanned or built), make many from one scene, colour them by a rule written in a class, and read one pattern source under several laws, saved to disk.

**III. Change, force, balance, wave (spine 6-9)**: chapters 17-22. You let bodies change: a curve becomes steps, forces throw and hold bodies, stacks stand or fall, a pendulum becomes a circle, a spiral stair and a sound.

**IV. Chance, field, pixel (spine 10-12)**: chapters 23-26. You make chance repeatable, give it a distribution and a round of play, turn it into a walkable field, and move a rule into the GPU, saying each time what the approximation owes.

**V. Rules that grow, bodies without edges (spine 13-19)**: chapters 27-33. You write rules that grow bodies (neighbour rules, recursion, grammars, generators) and bodies without fixed edges (soft, implicit, carved), and keep each one stopped, budgeted and walkable.

**VI. Bodies that choose, and the crisis (spine 20-25)**: chapters 34-39. You build bodies that choose (flocks, learners, routes), stage what mathematics cannot close, measure your own predictions, and leave the lab with a finished hall.

## Tracks

### Three weeks: a body family in your own hall (`short`)

- **Length:** 3 weeks full time (15 days). Week 1: chapters 1+2 (day 1), 3, 4, 5+6, 7. Week 2: chapters 10, 12, 15, 23, 25. Week 3: mini project from day 11, with guest and critique sessions (Code Societies' rhythm) and the showing on day 15. SUPPLIED AND NAMED, because the track skips the chapter that teaches them: defining functions (ch. 8) - met first by reading the AI-written check_magic() in ch. 10; delta (ch. 11) - read inside the supplied walker in ch. 12; MultiMesh (ch. 14) - the 10 PRINT walls in ch. 23 come from a supplied wall-emitter helper; PackedVector3Array and SurfaceTool (ch. 8, 14) - the terrain in ch. 25 is emitted by a supplied terrain_mesh(points) helper whose inputs and output are stated; surfaces from vertices and smooth normals (ch. 8-9) - bodies are built from primitive meshes and SphereMesh resolution instead; rotation order (ch. 11) - Inspector rotation only; scene instancing (ch. 13) - duplicated nodes; the RigidBody drop in ch. 3 and the XR staging scene - supplied throughout.
- **Chapters:** 1, 2, 3, 4, 5, 6, 7, 10, 12, 15, 23, 25
- **Project:** Extrapolated body (after Code as Creative Medium): one body built in code (primitives in loops, a noise field, or around your imported scan), exposed as a family with one @export axis of 3-5 values; the closest pair predicted in writing before rendering; one comparison image and a one-sentence claim; one debt comment in the code saying what the approximation owes; placed in your hall where a visitor stands on, walks through, carries or becomes it; shown on desktop, and on the headset if the route works. Optional variant after Blas' Facial Weaponization Suite: aggregate the class's scans into one collective body, axis = number of scans (consent first; matched topology is needed).

### One year: the museum in order, and a hall of your own (`long`)

- **Length:** About a year: two semesters, 39 chapters at roughly one a week, with checkpoints CP1 (ch. 10), CP2 (ch. 16), a midterm simulation project (ch. 22), CP4 (ch. 26), a pause week (ch. 33), the final project planned at ch. 36 and shown at ch. 39.
- **Chapters:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39
- **Project:** Final project: a finished hall in the endless museum with at least three body families, each with prediction, comparison image, claim and a debt comment in the code; walked by classmates on desktop and headset; exported.

## Chapter map

| n | chapter | spine (order) | carrier hall | code_new | argument axis | place | track |
|---|---|---|---|---|---|---|---|
| 1 | Day Zero: a world that runs, and breaks | primitives (1) | Point_Zero | statements, output, errors | camera standpoint on the same scene (Inspector values only) | Run it on the desktop | S+L |
| 2 | Point Zero: the engine calls you | primitives (1) | Point_Zero | variables, lifecycle, properties | where and how the height is written | Stand next to the column | S+L |
| 3 | Point One: one body from code, and its boundary | primitives (1) | Point_One | calling, meshes, collision | collider radius relative to the visible radius | Walk into it with the supplied desktop walker | S+L |
| 4 | Point Coordinates: position and frame | primitives (1) | Point_Coordinates | vectors, transforms, xr | the parent's transform, child position fixed at (0.5, 0, 0) | Carry it | S+L |
| 5 | Point Lines: distance belongs to the line | primitives (1) | Point_Lines | expressions, methods, types | the measure the connector follows | Two people each hold one end in the headset (or two keys ... | S+L |
| 6 | Point Trace: a point goes for a walk | primitives (1) | Point_Trace | arrays, conditions, input | gate distance | Walk with it (desktop walker or headset) | S+L |
| 7 | Many bodies: loops, and a first family | primitives (1) | Point_Line_Grid | loops, nested_loops, export | spacing relative to cube size | Stand on it | S+L |
| 8 | Surfaces from vertices: the triangle | primitives (1) | Point_Triangle_Context | functions, parameters, surface_tool | one corner walked toward collinearity | Walk behind the triangle and it disappears | L |
| 9 | Budget of smoothness: from pyramid to sphere | primitives (1) | Primitives_Ignorance | return, trig, normals | sphere tessellation | In the headset, stand in a ring of spheres | L |
| 10 | Melencolia: primitives synthesis and a first build | primitives (1) | Primitives_Melencolia | signals, export_build, ai_assist | pyramid apex | Assemble the puzzle by hand (desktop drag or headset grab) | S+L |
| 11 | Pose in time: move, turn, scale | transformation (2) | Trans_Rotation | delta, basis, interpolation | order of two 90-degree turns applied to one plank lying along x (global axes) | Ride it | L |
| 12 | The body you walk in | transformation (2) | Trans_Scale | player, camera, import_assets | what is scaled, seen from the walker's camera | Become it | S+L |
| 13 | Many bodies with addresses | array_tutorial (3) | Array | instancing, lifetime, areas | what collecting does to the address | Walk the floor and collect | L |
| 14 | A floor that keeps time: MultiMesh and sound | array_tutorial (3) | Tutorial_Disco | multimesh, audio, packed_arrays | step rule over (x, z, phase) | Dance on it | L |
| 15 | Colour by a rule: describe a body in a single class | color (4) | Color_Context_Placed | classes, materials, dictionaries | colour rule | Walk round the stack with a coloured flashlight | S+L |
| 16 | Pattern: one source, many laws | tiling (5) | Symmetry_Seventeen | uv, json, save_load | wallpaper rule over the same 4 x 4 source | Wear it | L |
| 17 | Change: a curve and its steps | change (6) | Change_Intro | integration, debugging | step size h (bar width) | Climb it | L |
| 18 | Forces I: vectors act | forces (7) | VFM_05_Launch | forces, physics_bodies | launch angle at fixed speed | Throw it | L |
| 19 | Forces II: force as place, and sight | forces (7) | Vectors_Act5_ForceAsPlace | raycasts, inheritance, groups | law inside the zone | Bridge a chasm by walking into a zone whose law carries you | L |
| 20 | Formfinding: standing although it could fall | formfinding (8) | FormFinding_Forge | booleans, timers, await | overhang of each block over the one below (fraction of block length) | Stack it by hand in the headset | L |
| 21 | Pendulum, circle, spiral | wavefunctions (9) | Wavefunctions_Sky_Stairs | tool_scripts, setters | radius change per turn | Climb the stair with the walker, then in the headset with... | L |
| 22 | Sound bodies: a sum of circles | wavefunctions (9) | WaveFunctions_Synthesis_Lab | threads | number of odd harmonics (1/n) toward a square wave | Strike it | L |
| 23 | Chance I: a pattern that returns | randomness (10) | Random_Definition | random, seeds | seed | Walk the maze (10 PRINT's 'Maze Walker') | S+L |
| 24 | Chance II: distributions and a round of play | randomness (10) | Random_Game | state_machines, particles, ui | placement law | Play a round | L |
| 25 | Noise: fields and the blob | noise (11) | Noise_Space_10 | noise, profiling | generator | Walk the terrain | S+L |
| 26 | One rule per pixel: shaders | shaders (12) | Shader_09_FBM | shaders, uniforms | fBm octaves (uniform int) | Walk on the glass over the moving water | L |
| 27 | Neighbours: cellular automata | cellularautomata (13) | CA_GameOfLife | buffers, testing | rule | Walk the bridge | L |
| 28 | Recursion must be stopped: fractals | fractals (14) | Fractal_MengerSponge | recursion, composition | depth | Fly through the sponge in the headset (merged collider) | L |
| 29 | Grammar and the turtle: L-systems | lsystems (15) | LSystems_Architecture | strings, stacks | turn angle for the same rule and depth | Walk the corridors the grammar drew | L |
| 30 | Navigate a generated world | proceduralgeneration (16) | PG_Caves_Mazes | navigation, resources | maze hand | Walk it | L |
| 31 | Soft bodies: stretchability | softbodies (17) | SoftBodies_Soft_Body_Deformation | other:pins_joints | mesh subdivision of the same soft body | Carry it in the headset | L |
| 32 | Implicit bodies: a threshold in a field | isosurfaces (18) | ISO_Metaballs | other:bit_ops | blend radius | Can a player-sized body pass? cast_motion() with a Capsul... | L |
| 33 | Union and difference (pause week) | boolean_surfaces (19) | Boolean_Works | (pause) | operation on the same box and sphere, half overlapping | Walk into the burrow | L |
| 34 | Many that choose: agents and flocks | swarmintelligence (20) | SwarmIntelligence_Boids_Algorithm | queues | which rule leads (separation / alignment / cohesion weights) | Stand in the flock in the headset | L |
| 35 | Bodies that learn | machinelearning (21) | ML_Neural_Networks | sorting | hidden-layer topology | Walk through the network in the headset | L |
| 36 | Nodes and edges: routes | graphtheory (22) | GT_Pathfinding | graphs, search | layout seed for the same cube graph (force_directed_layout) | Walk the graph as rooms | L |
| 37 | Impossible bodies: the foundations crisis | foundationscrisis (23) | Escher_Impossible | other:three_valued_logic | seam disclosure | Stand at the one point where the staircase closes | L |
| 38 | Order toward entropy: the QFEP laboratory | qfeplaboratory (24) | QFEP_F_Term | other:metrics_log | lambda, order to entropy (lambda_hall) | Become the slider | L |
| 39 | Leaving the lab: situated computation and your hall | postfoundationscrisis (25) | CriticalAlgorithms_Applied_Ethics | files | seating plan | The final hall | L |

## Chapters

Rhythm in every chapter: **predict, run, investigate, modify, make** (PRIMM), plus the written prediction of the closest pair, the comparison image, and one planted bug whose message the student reads. FOUNDATION is the chapter itself; DEBT and PLACE/ONTOLOGY are filled for every chapter.

### I. The point goes for a walk (spine 1: primitives)

#### 1. Day Zero: a world that runs, and breaks

- **Spine:** primitives. **Halls:** Point_Zero (encounter) [V spine.json]
- **CODE:** new statements, output, errors; returns -
- **BODY:** The supplied base scene (floor, sun, camera, WorldEnvironment, a Label3D) opened, run and stopped. The student's first body is the greeting that stands in the room: its text set by one statement, printed to Output. Then one planted typo, and Godot's exact message read aloud. Supplied: base.tscn and the XR staging scene (named, opened later).
- **ARGUMENT:** axis *camera standpoint on the same scene (Inspector values only)*; values front, eye height / from above / floor level / behind the label.
  - Prediction: Front and floor level look most alike: both see the label's face over the floor. From above the label is a thin sliver; from behind the text reads mirrored (Label3D is double-sided by default [mem]). [P]
  - Claim: *A scene is not a picture: the same bodies give different stills, and one standpoint can nearly hide a body.*
- **DEBT:** The default scene is a set of decisions nobody in the room made: a sun, a floor at y = 0, a camera at standing eye height, English keywords (FLOW-MATIC's default, Marino ch. 5). Montfort's 'Critique My Starter Programs' turned on the starter scene: which body does it assume? Errors are help: 'valid and intentional are different' (Montfort ch. 4).
- **PLACE / ONTOLOGY:** Run it on the desktop; then follow the written headset route with the supplied XR staging scene and stand in the room you just changed.
- **Godot:** Project Manager; Run Project F5 / Run Current Scene F6; Node3D, Label3D, Camera3D, DirectionalLight3D, WorldEnvironment; print(), Output panel; Debugger > Errors
- **Lineage:** Processing: LP ch. 2 (run, errors); Processing Handbook 'Structure 1: Code Elements'. NoC: below NoC's entry level (NoC assumes a semester of this). 2023 application: pre-WP: the application's basic elements assume a working world. Klee: none directly; the Vorkurs starts with the body (Itten's warm-up) [V research_bauhaus]. Reference: /course Day Zero kit, doc/book/studies/day-zero [V ada.json]; W01 'break it on purpose' pulled forward as the planted bug.
- **Departure:** none (spine order)
- **Project step:** Open the course log (a ReadMe beside the code, in Git). Write the prediction before moving the camera; paste the four stills and the claim.
- **Tracks:** short, long

#### 2. Point Zero: the engine calls you

- **Spine:** primitives. **Halls:** Point_Zero (carrier) [V spine.json]
- **CODE:** new variables, lifecycle, properties; returns statements, output, errors
- **BODY:** A column that grows: a box in the scene whose height is a variable, set once in _ready() and changed in _process(); a Label3D prints the count beside the supplied frame_counter_display.
- **ARGUMENT:** axis *where and how the height is written*; values set once in _ready / _process: h = 1.0 every frame / _process: h += 0.01 / _process: h += 0.001.
  - Prediction: The first two are identical in every still, although one runs once and the other 60-90 times a second; the two accumulating columns differ tenfold after the same time. [P]
  - Claim: *A picture cannot show code that runs without changing anything; only accumulation makes time visible.*
- **DEBT:** Growth counted in frames belongs to the machine: at 90 Hz in the headset the += column grows 1.5 times faster than at 60 Hz on a laptop. The repair (delta) is held back to chapter 11, and the log should say so. Frames and seconds diverge on frame_counter_display.
- **PLACE / ONTOLOGY:** Stand next to the column; note when it passes your head height on the desktop and again in the headset, and compare the two times.
- **Godot:** extends Node3D; _ready(); _process(delta); var count := 0; Label3D.text, str(); Node3D.scale
- **Lineage:** Processing: LP ch. 3 setup()/draw(), ch. 4 variables; Handbook 'Structure 2: Continuous'. NoC: NoC's draw() loop, assumed. 2023 application: pre-WP. Klee: I.1 the point sets off: motion needs an active agent [V lineage.json]. Reference: /course Point_Zero kit point-zero/hello_world.tscn [V]; GDQuest delays _process to lesson 10 [V research_engine], the spine does not; Fuller's Lexicon 'Variable' as the reading.
- **Departure:** none (spine order)
- **Project step:** Log: the four stills after 5 s at 60 Hz, plus one measured headset time.
- **Tracks:** short, long

#### 3. Point One: one body from code, and its boundary

- **Spine:** primitives. **Halls:** Point_One (carrier) [V spine.json]
- **CODE:** new calling, meshes, collision; returns variables, properties, lifecycle, errors
- **BODY:** A point built entirely in code: MeshInstance3D.new(), SphereMesh.new() (a resource, not a node), add_child(); a StaticBody3D with a CollisionShape3D whose radius is set apart from the visible radius. Supplied: a ball that drops (opened in chapter 18).
- **ARGUMENT:** axis *collider radius relative to the visible radius*; values 0.5x / 1x / 2x / no collider.
  - Prediction: Without the dropped ball all four look identical. With it, 0.5x and 'no collider' look most alike: in both the ball sinks into the visible body; only 1x shows touching, and 2x makes the ball float. [P]
  - Claim: *What a body is to others (its collider) is set apart from what it looks like; touch is a third thing, made only where the two agree.*
- **DEBT:** Colliders are approximations chosen for speed: sphere, box, convex hull, trimesh; the walker itself is a capsule. Where look and boundary disagree, bodies pass into each other (in this project the walk map cannot see CSG collision [mem project note]). Gaboury's Utah teapot: which primitives are the default bodies, and who standardised them.
- **PLACE / ONTOLOGY:** Walk into it with the supplied desktop walker: you stop at the collider, not at the surface you see. In the headset, put your hand into the 'no collider' point.
- **Godot:** MeshInstance3D + SphereMesh; StaticBody3D, CollisionShape3D, SphereShape3D; .new(), add_child(); Debug > Visible Collision Shapes
- **Lineage:** Processing: LP ch. 1 a creature from primitives (Zoog); LP ch. 8 objects as a user. NoC: none. 2023 application: pre-WP. Klee: I.1 the point. Reference: /course Point_One kit; STUDENT_TOOLBOX learner room 'three points with one name and different boundaries' [V ada.json]; Code as Creative Medium 'Graphic Elements'.
- **Departure:** none (spine order)
- **Project step:** Your hall starts: three points with one name and different boundaries, placed in your own room.
- **Tracks:** short, long

#### 4. Point Coordinates: position and frame

- **Spine:** primitives. **Halls:** Point_Coordinates (carrier) [V spine.json]
- **CODE:** new vectors, transforms, xr; returns properties, calling, variables
- **BODY:** A point with a parent: its Vector3 position set in code, the parent moved, turned and scaled; position and global_position shown on a label. On the XR route the student makes their own point holdable (no single grab() call, per the ruling).
- **ARGUMENT:** axis *the parent's transform, child position fixed at (0.5, 0, 0)*; values identity / moved +1 m in x / turned 90 degrees about y / scaled 2x.
  - Prediction: Identity and moved look most alike in a still framed on the pair (same shape, same child-parent distance); turned and scaled put the same three numbers somewhere else. [P]
  - Claim: *Position is always relative: the same three numbers make a different place under a different parent.*
- **DEBT:** The origin and the axes are decisions (y up, metres, a world 0,0,0). Far from the origin floats jitter. global_position is a calculation that looks like a fact. Pickup belongs here (ruling), so 'carrying' starts as a change of parent.
- **PLACE / ONTOLOGY:** Carry it: desktop drag with the supplied tool; in the headset hold it with XR Tools and watch position and global_position part.
- **Godot:** Vector3; position vs global_position; Node3D parent/child; Transform3D; XROrigin3D / XRCamera3D (supplied staging), XR Tools pickable
- **Lineage:** Processing: processing.org 'Coordinate System and Shapes'; P3D '3D Shapes'. NoC: NoC 1.1 'The Point of Vectors'. 2023 application: WP1 in spirit: 'vectors and dimensionality' named as basic concepts. Klee: II.14 the three dimensions [V lineage.json]. Reference: /course Point_Coordinates kit (desktop + xr) [V ada.json].
- **Departure:** none (spine order)
- **Project step:** Your point becomes holdable in your hall; log the four parent stills.
- **Tracks:** short, long

#### 5. Point Lines: distance belongs to the line

- **Spine:** primitives. **Halls:** Point_Lines (carrier) [V spine.json]
- **CODE:** new expressions, methods, types; returns vectors, variables, lifecycle, output
- **BODY:** A segment between two carried points: d = b - a, d.length(), a label with the number; the connector placed by the supplied show_between() in segment.gd (named, opened in chapter 8).
- **ARGUMENT:** axis *the measure the connector follows*; values Euclidean (straight) / horizontal only (floor projection) / Manhattan (three-leg path) / vertical only.
  - Prediction: Euclidean and horizontal look most alike while both points share a height; lift one end and they part. [P]
  - Claim: *Distance is a chosen measure, and the measure draws a different connector between the same two points.*
- **DEBT:** length() hides a geometry: Euclid by default. b - a is a Vector3 (a direction with a size); length() returns a float that forgets the direction (types). The norm returns in NonEuclidean_Spaces (chapter 37).
- **PLACE / ONTOLOGY:** Two people each hold one end in the headset (or two keys on desktop): the number is a relation between two bodies.
- **Godot:** Vector3 arithmetic; length(), distance_to(); float vs Vector3; typed var; '%.2f' % d; supplied segment.gd show_between()
- **Lineage:** Processing: LP ch. 7 functions (dist); Handbook 'Math 1'. NoC: NoC 1.1-1.5 subtraction and magnitude. 2023 application: WP1 in spirit ('vectors'). Klee: I.1-I.2 a line limited by fixed points. Reference: /course Point_Lines kit; ruling 'distance belongs to the line' (TUTORIAL_LINEAGE.md) [V].
- **Departure:** none (spine order)
- **Project step:** A measured relation in your hall: two holdable points and the distance between them.
- **Tracks:** short, long

#### 6. Point Trace: a point goes for a walk

- **Spine:** primitives. **Halls:** Point_Trace (carrier) [V spine.json]
- **CODE:** new arrays, conditions, input; returns vectors, methods, types, expressions, lifecycle
- **BODY:** A recorder: a typed Array[Vector3] of kept positions (the list before append), a condition that keeps a position only past a gate distance (the condition before the threshold), a cap, named input actions for pause and clear; the kept positions drawn as dots.
- **ARGUMENT:** axis *gate distance*; values 0 (every frame) / 0.02 m / 0.1 m / 0.5 m.
  - Prediction: 0 and 0.02 m look most alike (a dense line either way; the count differs, the picture barely); 0.5 m reads as a dotted polygon. [P]
  - Claim: *A record is a body shaped by what it refuses to keep.*
- **DEBT:** Every record forgets: the gate and the cap decide which walks survive, and rounding tidies a trembling hand into a line (draw_dot's retention family: none, trace, lattice, archive, wax [V ada.json]).
- **PLACE / ONTOLOGY:** Walk with it (desktop walker or headset): your own route becomes a body you can turn round and look at.
- **Godot:** Array[Vector3]; append(), size(), pop_front(); if; distance_to() threshold; Project Settings > Input Map; Input.is_action_just_pressed()
- **Lineage:** Processing: LP ch. 5 conditionals, ch. 9 arrays (mouse history). NoC: none. 2023 application: pre-WP. Klee: I.1 'an active line on a walk' [V research_bauhaus]. Reference: /course Point_Trace kit, 47 checks passed [V ada.json]; rulings: list before append, condition before a distance threshold; Fuller's Lexicon 'Lists'.
- **Departure:** none (spine order)
- **Project step:** Your walk through your hall, recorded and left standing as a body.
- **Tracks:** short, long

#### 7. Many bodies: loops, and a first family

- **Spine:** primitives. **Halls:** Point_Line_Grid (carrier) [V spine.json]
- **CODE:** new loops, nested_loops, export; returns calling, meshes, properties, conditions
- **BODY:** A 5 x 5 lattice of cubes from two nested for-loops; spacing and cube size exposed with @export, so the Inspector turns one grid into a family.
- **ARGUMENT:** axis *spacing relative to cube size*; values 0.7 (overlap) / 1.0 (touching) / 1.5 (gaps) / 3.0 (scatter).
  - Prediction: Overlap and touching look most alike: both read as one slab, and only gaps make the count visible. [P]
  - Claim: *At or below touching, many bodies read as one: a grid's number is only visible through its gaps.*
- **DEBT:** The Cartesian lattice is the default order of 3D space ('purely repetitive and therefore structural', Klee I.6). Twenty-five colliders cost more than one. The grid is not a prerequisite for the first line (ruling), yet it becomes everyone's floor.
- **PLACE / ONTOLOGY:** Stand on it: overlap and touching carry the walker, gaps drop it between cubes, scatter is a field of stepping stones.
- **Godot:** for i in range(n); nested loops; @export var spacing: float; the Inspector as the family's control panel
- **Lineage:** Processing: LP ch. 6 loops and the nested-loop grid; Design By Numbers 'Line' then 'Lines' [V research_creative]. NoC: none. 2023 application: pre-WP. Klee: I.5-I.6 structural rhythm and the chessboard [V lineage.json]. Reference: Generative Design numbered variants; Form+Code 'Repeat'; Fuller's Lexicon 'Loop'.
- **Departure:** none (spine order)
- **Project step:** A floor family in your hall: pick the spacing a visitor can walk on and say why.
- **Tracks:** short, long

#### 8. Surfaces from vertices: the triangle

- **Spine:** primitives. **Halls:** Point_Triangle_Context (carrier); Primitives_Polythedra (field trip); Point_Lines (field trip) [V spine.json]
- **CODE:** new functions, parameters, surface_tool; returns vectors, loops, arrays, meshes, types
- **BODY:** make_face(a, b, c): three Vector3s submitted to an ImmediateMesh, then to SurfaceTool; a fan loop makes a polygon; Polythedra's open trihedron closed by a convex hull from the same points. The supplied show_between() from chapter 5 is opened and rewritten as the student's own function.
- **ARGUMENT:** axis *one corner walked toward collinearity*; values equilateral / obtuse (120 degrees) / needle (170 degrees) / collinear (180 degrees).
  - Prediction: Needle and collinear look most alike from the front: both read as a line, although one still has area. [P]
  - Claim: *A surface is three points that disagree; when they agree, the face vanishes.*
- **DEBT:** A face has one side: Godot winds front faces clockwise and culls the back (Gaboury, 'Culling Vision' [V research_engine]). The triangle is the only polygon the GPU believes; every curved body is owed to it.
- **PLACE / ONTOLOGY:** Walk behind the triangle and it disappears; give the polyhedron a ConvexPolygonShape3D and stand on it.
- **Godot:** func make_face(a: Vector3, b: Vector3, c: Vector3); ImmediateMesh PRIMITIVE_TRIANGLES; SurfaceTool begin / add_vertex / commit; ConvexPolygonShape3D
- **Lineage:** Processing: LP ch. 14 vertex shapes; processing.org PShape. NoC: none. 2023 application: pre-WP. Klee: I.3 medial lines close into planes [V lineage.json]. Reference: Godot docs 'Procedural geometry' (ImmediateMesh vs SurfaceTool) [V research_engine]; Fuller's Lexicon 'Function'.
- **Departure:** none (spine order)
- **Project step:** Add one authored surface to your hall, and one you can stand on.
- **Tracks:** long

#### 9. Budget of smoothness: from pyramid to sphere

- **Spine:** primitives. **Halls:** Primitives_Ignorance (carrier); Primitives_Portals (field trip) [V spine.json]
- **CODE:** new return, trig, normals; returns functions, parameters, loops, surface_tool, export
- **BODY:** build_ring(n) returns n points on a circle from sin and cos; a pyramid on that ring with @export base_sides; the same builder stacked into a sphere of rings and segments; flat against smooth normals with SurfaceTool.generate_normals().
- **ARGUMENT:** axis *sphere tessellation (declared on sphere_high: coarse, low, high, ultra) [V ada.json]*; values coarse / low / high / ultra.
  - Prediction: High and ultra look most alike at arm's length: past a few hundred triangles the eye stops counting while the count keeps multiplying. [P]
  - Claim: *Smoothness is bought with triangles, and past a point the price keeps rising while the picture stops changing.*
- **DEBT:** Polycount against smooth deformation, the 2023 application's own question (l. 89). A smooth-looking sphere is a polyhedron whose normals lie about its facets. Counting triangles is not measuring frame time (measured in chapter 25). Primitives_Portals: the gap to the true circle never reaches zero.
- **PLACE / ONTOLOGY:** In the headset, stand in a ring of spheres: too many 'ultra' bodies make the room stutter at 72-90 Hz, and comfort is part of the budget.
- **Godot:** func build_ring(n: int) -> Array[Vector3]; sin(), cos(), TAU; SurfaceTool.generate_normals(), set_smooth_group(); SphereMesh.radial_segments / rings
- **Lineage:** Processing: Handbook 'Math 3: Trigonometry'; P3D sphereDetail. NoC: NoC 3.5 polar to Cartesian (early use). 2023 application: application l. 89: polycount vs smooth deformation [V lineage.json]. Klee: I.7 proportion. Reference: Catlike Coding's five spheres: construction as an axis [V research_engine].
- **Departure:** none (spine order)
- **Project step:** A body family in your hall that argues smoothness: three resolutions and one sentence on what each costs.
- **Tracks:** long

#### 10. Melencolia: primitives synthesis and a first build

- **Spine:** primitives. **Halls:** Primitives_Melencolia (carrier); Point_Animatedcube (field trip) [V spine.json]
- **CODE:** new signals, export_build, ai_assist; returns functions, arrays, loops, conditions, input, collision
- **BODY:** Duerer's truncated pyramid assembled from snap_pyramid_puzzle's parts; check_magic(NUMBERS) over rows, columns and diagonals; a custom signal emitted when an arrangement completes and heard by the room. check_magic() is first written with an AI assistant under stated constraints, then checked.
- **ARGUMENT:** axis *pyramid apex (declared on snap_pyramid_puzzle: tall, regular, flat, spire, inverted) [V ada.json]*; values flat / regular / tall / spire / inverted.
  - Prediction: Tall and spire look most alike (both read as needles); inverted is the outlier because its silhouette and shadow flip. [P]
  - Claim: *One base and one apex make a family whose members read as different kinds of object: roof, tent, spire, funnel.*
- **DEBT:** ai_assist as debt: before accepting the generated code, write what should change, what must not, and what observation would show it is wrong; code you did not write is a black box you now own. Melencolia's solid has been argued over for 500 years: a body can be exact and still undecided.
- **PLACE / ONTOLOGY:** Assemble the puzzle by hand (desktop drag or headset grab); the room answers the completion signal. Export a desktop build and try the Quest (Android, OpenXR) route.
- **Godot:** signal completed; completed.emit(); connect(); Project > Export: Windows desktop; Android with OpenXR
- **Lineage:** Processing: Handbook 'Synthesis 1: Form and Code'; LP ch. 10 algorithms. NoC: none. 2023 application: pre-WP; Freire and Illich: learners open, repair and change the tools. Klee: end of Part I: the work as genesis, stone laid on stone. Reference: /course CP1 checkpoint [V ada.json]; Aesthetic Programming RunMe/ReadMe [V research_ccs]; Queer 3D: 'use ChatGPT to write simpler programs' [V QUEER3D.md].
- **Departure:** none (spine order)
- **Project step:** CP1: your room exported and shown; the log holds predictions, comparison images and claims for chapters 1-10.
- **Tracks:** short, long

### II. Frame, many, colour, pattern (spine 2-5)

#### 11. Pose in time: move, turn, scale

- **Spine:** transformation. **Halls:** Trans_Rotation (carrier); Trans_Pre (field trip); Trans_Translation (field trip); Trans_Introduction (encounter) [V spine.json]
- **CODE:** new delta, basis, interpolation; returns lifecycle, transforms, vectors, export, trig
- **BODY:** A jointed body of pivots: each plank a child Node3D turned by a Basis about its own pivot, moved by lerp on a delta-accumulated clock (the Trans_Pre pickup's bob and spin). Chapter 2's column is repaired with += rate * delta.
- **ARGUMENT:** axis *order of two 90-degree turns applied to one plank lying along x (global axes)*; values x then y / y then x / x only / y only.
  - Prediction: 'x then y' and 'y only' look most alike: the x turn spins the plank about its own length, so both end up along z (one on edge, one flat); 'y then x' stands the plank upright. [P]
  - Claim: *Rotation does not commute: the same two turns in another order make another pose.*
- **DEBT:** One turn, three encodings (Euler angles, Basis, quaternion) and gimbal lock; a pose is nine numbers that mean nothing alone. delta repairs frame dependence, but the physics tick still quantises time.
- **PLACE / ONTOLOGY:** Ride it: an AnimatableBody3D plank turns about a pivot you choose while the walker stands on it.
- **Godot:** _process(delta); Basis, rotate() vs rotate_object_local(); lerp(), Tween; AnimatableBody3D
- **Lineage:** Processing: LP ch. 14 'Translation and Rotation (in 3D!)'; processing.org 2D Transformations: order matters. NoC: NoC 3.1-3.2 angles and angular motion. 2023 application: pre-WP. Klee: I.9 a muscle brings two bones into a new angle; II frames of reference [V lineage.json]. Reference: Transform early is right in Godot, where a node is a transform [V research_creative]; Form+Code 'Transform'.
- **Departure:** none (spine order)
- **Project step:** A body in your hall that moves on its own clock, frame-rate independent.
- **Tracks:** long

#### 12. The body you walk in

- **Spine:** transformation. **Halls:** Trans_Scale (carrier); Trans_Body (field trip); Trans_Introduction (field trip); Trans_Pit (encounter) [V spine.json]
- **CODE:** new player, camera, import_assets; returns input, transforms, collision, delta, vectors, xr
- **BODY:** The supplied walker opened: a CharacterBody3D with move_and_slide() and a Camera3D at its eye. Its skin is replaced by the student's own imported body (a phone 3D scan, a Tilt Brush sculpture or a Blender model as glTF), with the capsule collider kept.
- **ARGUMENT:** axis *what is scaled, seen from the walker's camera*; values nothing / room x4 / body x0.25 / room and body both x4.
  - Prediction: Room x4 and body x0.25 give nearly identical stills from the walker's eye; only the doorways the small body now fits through tell them apart. 'Both x4' looks like 'nothing'. [P]
  - Claim: *Scale is relative: from inside, a bigger room and a smaller you make the same picture, and only collision tells them apart.*
- **DEBT:** The capsule is the engine's default body (about 1.8 m, upright; in VR two hands); the scan is heavy (often 100k+ triangles) and its skin does not collide; the camera height encodes a body. 'Critique My Starter Programs' again: which body does the starter assume?
- **PLACE / ONTOLOGY:** Become it: walk as your scanned body. In the headset the desktop walker is swapped for the XR body; the skin stays a child of the controller (skin vs controller, GDQuest 3D module 7 [V research_engine]).
- **Godot:** CharacterBody3D, move_and_slide(), floor_snap_length; Camera3D.current; XRCamera3D; Import dock: .glb/.gltf, scale, mesh LOD; CapsuleShape3D
- **Lineage:** Processing: LP ch. 14 3D camera. NoC: none. 2023 application: Queer 3D week 1: 3D scanning, Tilt Brush, Blender [V QUEER3D.md]. Klee: II.21 the tightrope walker who 'is the scale' [V research_bauhaus]. Reference: Squash the Creeps parts 2-3 (player, input) [V research_engine]; Code as Creative Medium 'Extrapolated Body'; Fuller's Lexicon 'Import/Export'.
- **Departure:** none (spine order)
- **Project step:** Your own body enters your hall as the one who walks it.
- **Tracks:** short, long

#### 13. Many bodies with addresses

- **Spine:** array_tutorial. **Halls:** Array (carrier); Tutorial_3D (field trip); Tutorial_Tiling_Floor (field trip); Tutorial_Tiling_Walls (encounter) [V spine.json]
- **CODE:** new instancing, lifetime, areas; returns nested_loops, arrays, signals, conditions, player
- **BODY:** The Trans_Pre pickup saved as a scene and instanced from a 2D array by nested loops; each pickup an Area3D; collecting writes 0 into its slot. molnar_cube_study is visited with its disorder supplied (random is met in chapter 23).
- **ARGUMENT:** axis *what collecting does to the address*; values keep the slot (write 0) / erase and shift / hide (visible = false) / queue_free().
  - Prediction: Keep, hide and queue_free are indistinguishable in a still (gaps where collected); erase-and-shift rebuilds the row with the gaps closed. [P]
  - Claim: *A picture cannot tell an empty address from a hidden body; only the data, and what a body can still touch, can.*
- **DEBT:** Hiding is not deleting: a hidden Area3D still reports and still costs. The address outlives the occupant (the sequence's own question: does removing an occupant erase its address or change what a body can stand on? [V ada.json]). Point_Trace introduced lists, so Array is a return, not a first meeting (ruling).
- **PLACE / ONTOLOGY:** Walk the floor and collect; in the 'hide' version the invisible pickups still catch you.
- **Godot:** PackedScene, instantiate(); add_child(), queue_free(), visible; Area3D.body_entered; Array of Arrays
- **Lineage:** Processing: LP ch. 9 arrays, ch. 13 2D arrays; processing.org 'Two-Dimensional Arrays'. NoC: none (assumed). 2023 application: pre-WP. Klee: I.5-I.6 structure: an address and its occupant [V lineage.json]. Reference: Molnar's (Des)Ordres cited in commons/maps/Array/final.md [V research_bauhaus].
- **Departure:** none (spine order)
- **Project step:** A collectable field in your hall: decide what an empty place means.
- **Tracks:** long

#### 14. A floor that keeps time: MultiMesh and sound

- **Spine:** array_tutorial. **Halls:** Tutorial_Disco (carrier); Tutorial_Tiling_Floor (field trip) [V spine.json]
- **CODE:** new multimesh, audio, packed_arrays; returns loops, nested_loops, delta, arrays, instancing
- **BODY:** A 16 x 16 MultiMesh floor, monochrome (coloured Disco returns after Color, per the array_tutorial ruling), stepped by a delta clock; each step plays a tone generated into an AudioStreamWAV from a PackedByteArray.
- **ARGUMENT:** axis *step rule over (x, z, phase)*; values (x + z + phase) % 2 / (x + phase) % 2 / (x * z + phase) % 3 / phase % 2 for every cell.
  - Prediction: Checker and stripes look most alike in any one still (half the cells lit, regular); 'every cell' is the outlier, all or nothing. [P]
  - Claim: *One clock and four index rules: the floor's pattern is arithmetic on an address, and time only shifts it.*
- **DEBT:** A MultiMesh draws 256 instances in one call, but they are not nodes: no collider, no signal each (a crowd without individuals). A generated tone is a list of numbers the speaker must trust.
- **PLACE / ONTOLOGY:** Dance on it: an Area3D under the walker shifts the phase when you step.
- **Godot:** MultiMeshInstance3D; set_instance_transform / set_instance_color; PackedFloat32Array, PackedByteArray; AudioStreamWAV, AudioStreamPlayer3D
- **Lineage:** Processing: processing.org Sound; LP ch. 20. NoC: none. 2023 application: WP1 'Sound experiments', its first echo in the spine [V lineage.json]. Klee: Part I measures line rhythm like a musical score. Reference: Tutorial_Disco step_sequencer [V ada.json].
- **Departure:** none (spine order)
- **Project step:** A floor in your hall that answers footsteps with sound.
- **Tracks:** long

#### 15. Colour by a rule: describe a body in a single class

- **Spine:** color. **Halls:** Color_Context_Placed (carrier); Color_Flashlight (field trip); Color_Walls (field trip); Color_Rainbow (encounter); Color_Grid_Pallet (encounter) [V spine.json]
- **CODE:** new classes, materials, dictionaries; returns export, loops, meshes, calling
- **BODY:** chroma_stack rebuilt as the student's own class_name: a const Dictionary of stacks, an @export_enum rule, a loop that turns the recipe into PrimitiveMesh parts, each given a StandardMaterial3D coloured by the rule. The prompt is CCSWG's 'describe a body in a single class'.
- **ARGUMENT:** axis *colour rule (declared on chroma_stack: one, by_shape, by_height, by_neighbour, composed) [V ada.json]*; values one / by_shape / by_height / by_neighbour.
  - Prediction: by_shape and by_height look most alike on the bauhaus stack, because its shapes are stacked in height order and both rules paint the same parts; 'one' is the outlier. [P]
  - Claim: *A colour rule reads a body's structure back to you, or hides it when two structures coincide.*
- **DEBT:** Colour is relative (Albers): one material reads differently under coloured light (Color_Flashlight). StandardMaterial3D's default albedo is the default body of surfaces; sRGB against linear and the headset's display shift colour without an error. Which properties get a place in the class is the modelling choice, and the critique.
- **PLACE / ONTOLOGY:** Walk round the stack with a coloured flashlight: colour belongs to the meeting of light, surface and eye.
- **Godot:** class_name; @export_enum; const Dictionary; StandardMaterial3D.albedo_color; Color.from_hsv(); SpotLight3D
- **Lineage:** Processing: processing.org Color (HSB); LP ch. 8 objects (write your own class). NoC: NoC 4.9 textures and blending, its only colour moment. 2023 application: WP2 'queer meshes and textures' sits next to it. Klee: IV.39-43 chromatic energy: Klee ends in colour; here colour is appearance, and colour as energy returns in chapter 26 (declared return) [V research_bauhaus]. Reference: Albers' 'make two colours look alike' is the argument strand's ancestor [V research_bauhaus]; CCSWG 2024 'describe X in a single class' [V research_ccs]; Fuller's Lexicon 'Object Orientation'.
- **Departure:** none (spine order)
- **Project step:** A class of your own in your hall: one body type, its colour rule in the Inspector.
- **Tracks:** short, long

#### 16. Pattern: one source, many laws

- **Spine:** tiling. **Halls:** Symmetry_Seventeen (carrier); Pattern_Foundry (field trip); Tutorial_Pattern (field trip); Ribbon_Patterns_03 (field trip); Pattern_Disco (encounter) [V spine.json]
- **CODE:** new uv, json, save_load; returns arrays, nested_loops, functions, dictionaries, materials
- **BODY:** A 4 x 4 palette-index source read by get_color(x, y) under a wallpaper rule, baked into an Image and ImageTexture and laid on a floor, a wall and a garment mesh by UV; the source saved and restored as versioned JSON in user://. Tutorial_Pattern's shader version is visited as supplied (shaders are met in chapter 26).
- **ARGUMENT:** axis *wallpaper rule over the same 4 x 4 source*; values p1 (wrap) / pm (mirror odd blocks) / pg (glide) / p4 (quarter turns).
  - Prediction: pm and pg look most alike (both mirror; pg only shifts the mirrored rows by half a block); p1 is the outlier for a motif with a strong direction. [P]
  - Claim: *One motif under four laws gives four patterns: the pattern is the rule, not the tile.*
- **DEBT:** The symmetry census claims completeness (17 groups) where Klee argues for non-symmetrical balance (II.23). A texture is a skin with no thickness and no collision; UV seams show where a curved body was cut to lie flat. The spine keeps regularity here and randomness five sequences later, though 10 PRINT argues you need the grid to see chance.
- **PLACE / ONTOLOGY:** Wear it: the same texture on the floor you stand on and on a garment you put on.
- **Godot:** Image.create(), set_pixel(), ImageTexture; UV on QuadMesh; SurfaceTool.set_uv(); JSON.stringify(), JSON.parse_string(); FileAccess user://
- **Lineage:** Processing: processing.org Images and Pixels; LP ch. 15 pixels, ch. 18 data (JSON). NoC: none. 2023 application: WP3 'Pattern and World Building' in name; the 2022 prototype's meander patterns [V lineage.json]. Klee: I.5-I.6 repetition; II.23 non-symmetrical balance as the counter-position. Reference: 10 PRINT 'Regularity' [V research_ccs]; Book of Shaders 'Patterns' as the later return.
- **Departure:** none (spine order)
- **Project step:** CP2: your hall holds your walking body, a coloured class family and a patterned surface restored from JSON.
- **Tracks:** long

### III. Change, force, balance, wave (spine 6-9)

#### 17. Change: a curve and its steps

- **Spine:** change. **Halls:** Change_Intro (carrier); Flow_Field (field trip) [V spine.json]
- **CODE:** new integration, debugging; returns functions, loops, export, surface_tool, collision, player
- **BODY:** f(x) plotted as a line strip; a secant from two samples with @export h; a Riemann sum accumulated in a for loop and built as bars you can stand on. The loop is stepped through in the debugger. Flow_Field is visited with its noise sampler supplied and named (noise is met in chapter 25).
- **ARGUMENT:** axis *step size h (bar width)*; values 1.0 / 0.5 / 0.1 / 0.01.
  - Prediction: 0.1 and 0.01 look most alike: below about a tenth the staircase reads as a ramp while the sum still changes in the third decimal. [P]
  - Claim: *A smooth curve on a computer is a staircase you stopped seeing.*
- **DEBT:** Everything continuous here is steps: frames (chapter 2), facets (chapter 9), samples. The debugger shows the loop one step at a time, and the error the picture cannot show.
- **PLACE / ONTOLOGY:** Climb it: h = 1.0 is a stair the walker climbs step by step, h = 0.01 is a ramp, and the walker's step height decides where one becomes the other.
- **Godot:** ImmediateMesh PRIMITIVE_LINE_STRIP; static func f(x: float) -> float; accumulation; Debugger: breakpoints, step over, watched variables
- **Lineage:** Processing: LP ch. 5 hand-rolled gravity (first accumulation); Handbook 'Development 2: Iteration, Debugging'. NoC: NoC 1.7-1.8 Motion 101 (rate of change). 2023 application: WP2 'flow fields' (Flow_Field, sampler supplied). Klee: III water and air as transitional regions (weak) [V lineage.json]. Reference: The Handbook gives debugging a chapter mid-book [V research_creative].
- **Departure:** none (spine order)
- **Project step:** A stair or ramp in your hall made from a function and a step size.
- **Tracks:** long

#### 18. Forces I: vectors act

- **Spine:** forces. **Halls:** VFM_05_Launch (carrier); VFM_03_Motion (field trip); Vectors_Act1_WhatAVectorIs (field trip); Vectors_Act3_FieldsAndMotion (field trip) [V spine.json]
- **CODE:** new forces, physics_bodies; returns vectors, delta, integration, export, input, xr
- **BODY:** A thrown body twice: first a predicted arc from @export angle and speed as 64 time samples (own integration, no physics engine), then a RigidBody3D launched with the same numbers; both trails side by side.
- **ARGUMENT:** axis *launch angle at fixed speed*; values 15 degrees / 30 degrees / 45 degrees / 60 degrees / 75 degrees.
  - Prediction: 30 and 60 degrees land at the same distance (complementary angles, no drag), so their landing stills match while the arcs differ in height; 45 lands farthest. [mem, physics]
  - Claim: *Two throws can share a landing and still be different bodies in the air: the endpoint forgets the path.*
- **DEBT:** Two integrators disagree: my Euler step against the engine's solver. Drag and the physics tick (60 or 90 Hz) move the landing. 'Realistic' is a choice of error.
- **PLACE / ONTOLOGY:** Throw it: in the headset by hand (XR Tools release velocity), on desktop with a key; then walk to where it lands.
- **Godot:** RigidBody3D; apply_central_impulse(), apply_central_force(); _physics_process(delta); mass, linear_damp; own step: v += a * dt; p += v * dt
- **Lineage:** Processing: processing.org PVector; LP ch. 5 bouncing ball. NoC: NoC 1 Vectors, 2 Forces, and the physics library (NoC 6). 2023 application: WP1 in spirit ('noise and vectors'). Klee: III a bullet fired steeply rises and falls [V lineage.json]. Reference: NoC Motion 101.
- **Departure:** none (spine order)
- **Project step:** A thrown-body family in your hall with its predicted and simulated arcs.
- **Tracks:** long

#### 19. Forces II: force as place, and sight

- **Spine:** forces. **Halls:** Vectors_Act5_ForceAsPlace (carrier); VFM_08_Arena (field trip); VFM_07_Gravity (field trip); Vectors_Act4b_Oscillation (encounter); VFM_09_Legs (encounter) [V spine.json]
- **CODE:** new raycasts, inheritance, groups; returns areas, physics_bodies, forces, vectors, classes, signals
- **BODY:** force_field_zone: an Area3D that replaces gravity with an @export law for every body inside; a VFM_08 creature that extends a supplied creature script, overrides only _find_target(), looks with intersect_ray() and scopes its candidates with a group.
- **ARGUMENT:** axis *law inside the zone (declared on force_field_zone: gravity, lift, crossing, weightless) [V ada.json]*; values gravity / lift / crossing / weightless.
  - Prediction: Weightless and lift look most alike a second after release (bodies hover near where they were let go); crossing is the outlier, sweeping bodies sideways. [P]
  - Claim: *A force is a place a body enters, not a thing a body carries.*
- **DEBT:** The creature 'sees' along one ray, and a thin screen defeats it: sight is a line test. Inheritance lets you change one behaviour and keep everything you never read; the base class is a borrowed body.
- **PLACE / ONTOLOGY:** Bridge a chasm by walking into a zone whose law carries you: the walker's own gravity is replaced.
- **Godot:** Area3D gravity_space_override, gravity_direction; extends; super(); overriding a method; PhysicsDirectSpaceState3D.intersect_ray(); add_to_group(); get_tree().get_nodes_in_group()
- **Lineage:** Processing: none. NoC: NoC 2 gravitational attraction; NoC 4.6 inheritance and polymorphism; NoC 5 seeking. 2023 application: WP1 in spirit. Klee: III.30-32 the falling stone and the meteor [V lineage.json]. Reference: VFM_08's crab [V survey_bundle].
- **Departure:** none (spine order)
- **Project step:** A zone in your hall where the law changes, and one body that looks for you.
- **Tracks:** long

#### 20. Formfinding: standing although it could fall

- **Spine:** formfinding. **Halls:** FormFinding_Forge (carrier); FormFinding_Equilibrium (field trip); FormFinding_Relaxation (field trip); FormFinding_Catenary (encounter); FormFinding_Descent (encounter) [V spine.json]
- **CODE:** new booleans, timers, await; returns physics_bodies, signals, conditions, xr, interpolation
- **BODY:** A stack of grabbed RigidBody3D blocks; a settle test (every body asleep and none below the table) that must hold for 2 s on a Timer; then await the reward tween. Equilibrium's recursive mobile is visited with its recursion supplied and named (recursion is met in chapter 28).
- **ARGUMENT:** axis *overhang of each block over the one below (fraction of block length)*; values 0 / 1/4 / 1/2 / 3/4.
  - Prediction: 0 and 1/4 look most alike (both stand); 1/2 sits at the tipping edge and may go either way depending on the solver; 3/4 falls. [P]
  - Claim: *A body stands while its centre of mass falls inside its support; the rest is the solver's opinion.*
- **DEBT:** 'Stable' is a fact about the engine: sleep thresholds, solver iterations and the tick rate decide the verdict (in this project a die read 15/16 at 90 Hz and 2/16 at 60 Hz [mem project note]).
- **PLACE / ONTOLOGY:** Stack it by hand in the headset; the stack is a place your body can knock over.
- **Godot:** RigidBody3D sleeping; and / or / not; Timer, timeout; await get_tree().create_timer(2.0).timeout; Tween
- **Lineage:** Processing: none. NoC: NoC 6.10-6.11 Verlet and constraints (Relaxation). 2023 application: WP2 soft body and cloth overlap (Relaxation). Klee: II.22-25 the scale, non-symmetrical balance, the tower of stones; III 'to stand despite all possibilities to fall' [V research_bauhaus]. Reference: Moholy-Nagy's balance studies [V research_bauhaus]; FormFinding_Forge as the spine's first complete game loop [V survey_bundle].
- **Departure:** none (spine order)
- **Project step:** A balance puzzle in your hall with a win condition.
- **Tracks:** long

#### 21. Pendulum, circle, spiral

- **Spine:** wavefunctions. **Halls:** Wavefunctions_Sky_Stairs (carrier); WaveFunctions_Pendulum (field trip); WaveFunctions_Unit_Circle (field trip); WaveFunctions_Sine_Space (field trip); Wavefunctions_Bernini (encounter) [V spine.json]
- **CODE:** new tool_scripts, setters; returns trig, surface_tool, collision, export, player, xr
- **BODY:** Klee's derivation first: a pendulum, the pendulum freed into a circle, the circle with a growing radius into a spiral. Then a helical stair from a function (angle, radius, height per step), ArrayMesh treads and matching colliders, under @tool with setters so it rebuilds in the editor as a parameter changes.
- **ARGUMENT:** axis *radius change per turn*; values -0.3 m (contracting) / 0 (helix) / +0.3 m / +0.8 m (expanding).
  - Prediction: 0 and +0.3 look most alike from above at two turns; -0.3 is the outlier because it closes on the axis. [P]
  - Claim: *The circle is the pendulum freed; the spiral is the circle with a growing or shrinking memory.*
- **DEBT:** sin and cos are computed approximations. A vertex-shader wave moves the picture and not the collider, so Sine_Space rebuilds its heightfield collider from the same function on purpose. Spiral stairs test VR comfort (vection).
- **PLACE / ONTOLOGY:** Climb the stair with the walker, then in the headset with a comfort check (snap turn, vignette).
- **Godot:** @tool; var radius: float: set(v): radius = v; _rebuild(); ArrayMesh; ConcavePolygonShape3D; sin/cos per step
- **Lineage:** Processing: LP ch. 13 polar/Cartesian, oscillation. NoC: NoC 3 Oscillation: pendulum, polar coordinates, waves. 2023 application: WP1 'sine curves'. Klee: IV.33-36 top, pendulum, circle ('purest of mobile forms'), spiral (life or death) [V research_bauhaus]. Reference: Catlike Coding's graph-to-surface ladder [V research_engine].
- **Departure:** none (spine order)
- **Project step:** A stair family in your hall, rebuilt in the editor, climbed in the headset.
- **Tracks:** long

#### 22. Sound bodies: a sum of circles

- **Spine:** wavefunctions. **Halls:** WaveFunctions_Synthesis_Lab (carrier); WaveFunctions_AirMusic (field trip); WaveFunctions_Effect_Sound (field trip); WaveFunctions_John_Cage (encounter) [V spine.json]
- **CODE:** new threads; returns trig, arrays, audio, packed_arrays, areas, xr
- **BODY:** An additive instrument: a typed Array[float] of harmonic amplitudes summed into a waveform, drawn as a ribbon body and rendered into an AudioStreamWAV on a worker thread; struck with a held stick (AirMusic).
- **ARGUMENT:** axis *number of odd harmonics (1/n) toward a square wave*; values 1 (sine) / 3 / 7 / 31.
  - Prediction: 7 and 31 look most alike at ribbon scale: both read as a square with ripples at the corners, and the ripple never vanishes (Gibbs overshoot, about 9%). [mem, maths]
  - Claim: *Every periodic body of sound is a sum of circles, and the sharp corner is the one it never quite reaches.*
- **DEBT:** Fourier (WP2) is practised here without its name appearing in any hall [V lineage.json]. The overshoot is an approximation debt that does not shrink. A worker thread may not touch the scene: the main thread keeps the world.
- **PLACE / ONTOLOGY:** Strike it: an Area3D contact plays the note at the body's position; walk round it and hear it pan.
- **Godot:** Thread / WorkerThreadPool; wait_to_finish(); AudioStreamWAV from PackedByteArray; AudioStreamPlayer3D; Array[float]
- **Lineage:** Processing: LP ch. 20 sound (oscillators). NoC: NoC 3 waves. 2023 application: WP1 'resonance frequencies, sound experiments'; WP2 'Fourier transforms' [V APPLICATION.md]. Klee: Part I line rhythm as a score. Reference: WaveFunctions_John_Cage as precedent.
- **Departure:** none (spine order)
- **Project step:** Midterm (after NoC's simulation project): a moving or sounding body family in your hall, with its claim and one planted-bug note.
- **Tracks:** long

### IV. Chance, field, pixel (spine 10-12)

#### 23. Chance I: a pattern that returns

- **Spine:** randomness. **Halls:** Random_Definition (carrier); Randomness_10_PRINT_Algorithm (field trip); Random_Entropy (field trip); Random_Remove (encounter); Random_Cubes (encounter) [V spine.json]
- **CODE:** new random, seeds; returns multimesh, collision, nested_loops, player, arrays
- **BODY:** The runnable random-definition kit first (seed replay), then a walkable 10 PRINT maze: a RandomNumberGenerator with a seed picks one of two rotations per cell; walls as one MultiMesh plus colliders. Every earlier use of chance (Coordinates, Trans_Body, Array's disorder, Flow_Field) was supplied; it is opened here.
- **ARGUMENT:** axis *seed*; values seed 1 / seed 1 again / seed 2 / seeded from the clock.
  - Prediction: 'seed 1' and 'seed 1 again' are identical to the pixel (difference 0); seed 2 and the clock seed differ everywhere yet look alike as texture. [P]
  - Claim: *Pseudo-random is a pattern that returns: a seed is the name of one body in the family.*
- **DEBT:** Pseudo-randomness is Queer 3D's first debt: the generator is a deterministic function. A code-critique station (Kittler model, Marino ch. 6): read and annotate 20-40 lines of the RNG behind Random_Definition. The spine meets random here, later than NoC (chapter 0), Aesthetic Programming (chapter 5 of 10), Nake 1965 and the 2023 application's WP1.
- **PLACE / ONTOLOGY:** Walk the maze (10 PRINT's 'Maze Walker'); give a classmate your seed and walk the same maze.
- **Godot:** RandomNumberGenerator: seed, state, randi_range(), randf(); MultiMesh + StaticBody3D walls
- **Lineage:** Processing: LP ch. 4 random() as a value (met far later here); LP ch. 13 probability. NoC: NoC 0 Randomness, the book's opening. 2023 application: WP1 'Randomness', its first item [V APPLICATION.md]. Klee: none: randomness is absent from the Bauhaus; Nake's Hommage a Paul Klee (1965) adds it [V research_bauhaus]. Reference: 10 PRINT chapters 'Randomness' and 'Maze Walker' [V research_ccs].
- **Departure:** none (spine order)
- **Project step:** A seeded body in your hall whose seed you publish in the log.
- **Tracks:** short, long

#### 24. Chance II: distributions and a round of play

- **Spine:** randomness. **Halls:** Random_Game (carrier); Random_Gaussian (field trip); Random_Mushrooms (field trip); Random_Walk (field trip); Random_Pheromone (encounter) [V spine.json]
- **CODE:** new state_machines, particles, ui; returns random, seeds, conditions, signals, instancing, lifetime, timers
- **BODY:** A scatter of mushroom bodies placed by a distribution (distribution_sampler); then Random_Game's round: stones in an enum state machine (STAND, WARN, SINK) on seeded waits, a GPUParticles3D burst when one sinks, a score and a replay on a UI panel.
- **ARGUMENT:** axis *placement law (declared on distribution_sampler: uniform, gaussian, poisson, exponential) [V ada.json]*; values uniform / gaussian / poisson / exponential.
  - Prediction: Gaussian and exponential look most alike from above (both crowd one place); uniform is the outlier, an even carpet. [P]
  - Claim: *A distribution is a shape of expectation: the same number of bodies makes a different body of bodies.*
- **DEBT:** 'Normal' is a statistical word for the average body (Quetelet's average man) that turns into a norm. Seeded waits read as fair while they are designed. Particles are cheap bodies without collision: spectacle has a debt too.
- **PLACE / ONTOLOGY:** Play a round: stand on stones that sink on seeded waits; score and replay live on a panel (screen on desktop, world-space panel in the headset).
- **Godot:** enum State; match; GPUParticles3D, ParticleProcessMaterial, one_shot; Control, Label, Button, CanvasLayer; SubViewport for a world-space panel; randfn()
- **Lineage:** Processing: LP ch. 13 probability; Handbook 'Math 4: Random'. NoC: NoC 0 distributions; NoC 4 particle systems (after oscillation, as in the 2024 NoC order). 2023 application: WP1 'particle systems', which has no other home in the spine [V lineage.json]. Klee: I.1 the line walking freely (Random_Walk) [V lineage.json]. Reference: Squash the Creeps part 8 score and replay [V research_engine]; Code as Creative Medium 'One-Button Game'.
- **Departure:** none (spine order)
- **Project step:** A playable round in your hall: a start, a score, an end and a replay.
- **Tracks:** long

#### 25. Noise: fields and the blob

- **Spine:** noise. **Halls:** Noise_Space_10 (carrier); Noise_Perlin_Simplex (field trip); Noise_Columns (field trip); Noise_Voxel (field trip); Lab_Path (encounter) [V spine.json]
- **CODE:** new noise, profiling; returns nested_loops, packed_arrays, collision, player, export, surface_tool
- **BODY:** A walkable terrain: FastNoiseLite sampled on a grid, multiplied by an edge envelope, emitted as an ArrayMesh and a ConcavePolygonShape3D from the same vertex list; rebuilds refused while a body stands on it; the rebuild cost measured in the Profiler.
- **ARGUMENT:** axis *generator (declared on noise_space: simplex, perlin, value, cellular) [V ada.json]*; values simplex / perlin / value / cellular.
  - Prediction: Simplex and perlin look most alike (smooth hills; perlin may show faint grid alignment); cellular is the outlier, cells and ridges. [P]
  - Claim: *Each noise type has a signature blob: the terrain shows the algorithm's handwriting, not nature's.*
- **DEBT:** The blob aesthetic (Queer 3D): noise makes everything organic in the same way. Queer 3D's overflow rates (Perlin 45, random 635, Voronoi 0, sine space 3284) as a number to compare. Octaves cost time you can now measure: chapter 9's counting becomes measuring. Code-critique station: the FastNoiseLite call and what its defaults decide.
- **PLACE / ONTOLOGY:** Walk the terrain; in the headset a rebuild under your feet is refused, because a body standing on it changes what may change.
- **Godot:** FastNoiseLite: noise_type, frequency, fractal_octaves, seed; ArrayMesh + ConcavePolygonShape3D from one PackedVector3Array; Profiler; Time.get_ticks_usec()
- **Lineage:** Processing: LP ch. 13 noise. NoC: NoC 0.6 Perlin noise. 2023 application: WP1 'Perlin noise' (Voronoi as the cellular type). Klee: none. Reference: Catlike Coding 'Pseudorandom Noise': the stripes of a weak hash [V research_engine]; Fuller's Lexicon 'Glitch'.
- **Departure:** none (spine order)
- **Project step:** A terrain in your hall that holds a walker, with its measured cost.
- **Tracks:** short, long

#### 26. One rule per pixel: shaders

- **Spine:** shaders. **Halls:** Shader_09_FBM (carrier); Shader_01_Shaping (field trip); Shader_05_Patterns (field trip); Shader_11_QueerRubber (field trip); Shader_10_ReactionDiffusion (encounter); Tutorial_Pattern (field trip) [V spine.json]
- **CODE:** new shaders, uniforms; returns noise, uv, export, collision, materials, trig
- **BODY:** Noise_6_Wall's fBm loop moved into a vertex shader on a subdivided PlaneMesh (the basin water), octaves as a uniform int set from GDScript; a glass StaticBody3D slab laid over it. Chapter 16's tiling redone as fract(UV * n) (declared return), and chapter 15's colour returns as light and energy (QueerRubber's fresnel).
- **ARGUMENT:** axis *fBm octaves (uniform int)*; values 1 / 2 / 4 / 6.
  - Prediction: 4 and 6 look most alike at walking distance: the extra octaves fall below the mesh's vertex spacing and the eye's resolution. [P]
  - Claim: *Detail is layered chance; past the mesh's resolution extra octaves cost and show nothing.*
- **DEBT:** A vertex shader moves the picture, not the body: collision stays flat (visibility against materiality). The GPU is 'procedure crystallized' (Gaboury ch. 5). On the Quest renderer several looks drop out with no error [V survey_bundle godot notes].
- **PLACE / ONTOLOGY:** Walk on the glass over the moving water: your feet meet a flat collider under a surface that looks alive.
- **Godot:** ShaderMaterial; shader_type spatial; uniform int octaves : hint_range(1, 8); vertex(): VERTEX += NORMAL * h; TIME; set_shader_parameter()
- **Lineage:** Processing: none (Handbook 'Render Techniques' is nearest). NoC: none. 2023 application: WP3 'shading algorithms'; WP2 'queer meshes and textures' (QueerRubber). Klee: IV chromatic energy: colour's late return (declared return of chapter 15). Reference: Book of Shaders chapters 5-13 map one to one onto Ada's Shader halls [V research_engine]; Fuller's Lexicon 'Pixel'.
- **Departure:** none (spine order)
- **Project step:** CP4: one body family in your hall moved to the GPU, with a note on what its collider does not know.
- **Tracks:** long

### V. Rules that grow, bodies without edges (spine 13-19)

#### 27. Neighbours: cellular automata

- **Spine:** cellularautomata. **Halls:** CA_GameOfLife (carrier); CA_Introduction (field trip); CA_EdgeOfChaos (field trip); CA_SoftRules (encounter); CA_BeyondBinary (encounter) [V spine.json]
- **CODE:** new buffers, testing; returns arrays, conditions, loops, multimesh, collision, player, seeds
- **BODY:** A 1D elementary CA history (typed Array[bool] rows, wrap by modulo, rule bits, a new-row buffer and a swap) turned into a collidable bridge; a headless check asserts that rule 90 reproduces Sierpinski rows; CA_EdgeOfChaos's A/B lockstep harness as the experiment form.
- **ARGUMENT:** axis *rule (declared on ca_bridge: 30, 90, 110, 250) [V ada.json]*; values 30 / 90 / 110 / 250.
  - Prediction: 30 and 110 look most alike (both irregular, 'complex'); 250 is the outlier, nearly solid. [P]
  - Claim: *Eight bits decide whether a bridge holds: the rule number is the body's genome.*
- **DEBT:** Synchronous update is an idealisation: in-place scanning makes another body (CA_ExpandingSpace). Wrap-around hides a torus. The CA hall names do not match their contents [V lineage.json].
- **PLACE / ONTOLOGY:** Walk the bridge: rule 90's gaps drop the walker, rule 250 carries it.
- **Godot:** Array[bool]; two buffers and a swap; (rule >> n) & 1; assert(); a headless check with godot --headless --script; StaticBody3D per live cell, or a MultiMesh
- **Lineage:** Processing: processing.org 2D arrays, pixel neighbours. NoC: NoC 7 Cellular Automata. 2023 application: WP2 'cellular automata'; WP4 'chaos theory' (EdgeOfChaos). Klee: I.6 the chessboard (weak). Reference: Wolfram's classes via NoC 7 [mem].
- **Departure:** none (spine order)
- **Project step:** A rule-grown bridge or floor in your hall, with a check that proves the rule.
- **Tracks:** long

#### 28. Recursion must be stopped: fractals

- **Spine:** fractals. **Halls:** Fractal_MengerSponge (carrier); Fractal_Recursion (field trip); Fractal_RecursiveTrees (field trip); Fractal_Synthesis (field trip); Fractal_GoldenSpiral (encounter) [V spine.json]
- **CODE:** new recursion, composition; returns functions, return, multimesh, collision, classes, profiling, xr
- **BODY:** A recursive generator with an explicit base case: Menger's 20-of-27 rule to depth 0-3 emitted into one MultiMesh plus a merged collider; a recursive tree; both composed behind one generate(depth) -> Array interface in the synthesis room. Equilibrium's supplied recursion (chapter 20) is opened (declared return).
- **ARGUMENT:** axis *depth (declared on fractal_recursion_2: 1, 2, 4, 6, 7) [V ada.json]*; values 1 / 2 / 4 / 6 / 7.
  - Prediction: 6 and 7 look most alike: the new parts fall below a pixel while the part count multiplies again. [P]
  - Claim: *Past a depth the body stops changing for the eye but not for the machine.*
- **DEBT:** 'Recursion must always be controlled' (Queer 3D): a depth budget, stack overflow, 20^n cubes. Munari's 'mad branch' is the exception every family has, a queer reading of the rule.
- **PLACE / ONTOLOGY:** Fly through the sponge in the headset (merged collider); removed cubes as gone, ghost or scar (menger_sponge removal axis).
- **Godot:** func build(depth): if depth == 0: return; MultiMesh + merged ConcavePolygonShape3D; class_name Generator; a composed child node; Time.get_ticks_usec()
- **Lineage:** Processing: LP ch. 13 recursion. NoC: NoC 8 Fractals. 2023 application: WP2 'fractal subdivision'; WP1 'Fibonacci' (GoldenSpiral). Klee: I.7 the golden section; IV.36 the spiral; the subtractive making that ends Part I [V lineage.json]. Reference: Munari, Drawing a Tree [V research_bauhaus]; Kawaguchi's fractal bodies (Queer 3D lineage); Fuller's Lexicon 'Elegance'.
- **Departure:** none (spine order)
- **Project step:** A recursive body in your hall with its depth budget written in the code.
- **Tracks:** long

#### 29. Grammar and the turtle: L-systems

- **Spine:** lsystems. **Halls:** LSystems_Architecture (carrier); LSystems_Grammar_Lab (field trip); LSystems_Growth (field trip); Point_Trace (field trip); Assemblage_Same_Desire (encounter) [V spine.json]
- **CODE:** new strings, stacks; returns dictionaries, loops, arrays, recursion, collision, player
- **BODY:** expand_once(s): for c in s: out += rules.get(c, c), under a symbol budget; a turtle reads F + - [ ] with an Array stack of {pos, dir}; its centrelines become corridors with walls.
- **ARGUMENT:** axis *turn angle for the same rule and depth*; values 20 degrees / 25.7 degrees / 60 degrees / 90 degrees.
  - Prediction: 20 and 25.7 look most alike (both read as plants); 90 turns the same sentence into a building plan. [P]
  - Claim: *One sentence gives many bodies: the interpreter's angle is half the grammar.*
- **DEBT:** A generated instruction is not the conditions that let a body use it: corridors must clear a 0.6 m capsule (LSystems_Architecture). The turtle is Logo, and Logo is Klee's walking point (declared return of chapter 6).
- **PLACE / ONTOLOGY:** Walk the corridors the grammar drew; test the clear width with the real walker.
- **Godot:** String; for c in s; +=; Dictionary.get(c, c); Array push_back() / pop_back() as a stack; BoxMesh walls + StaticBody3D
- **Lineage:** Processing: LP ch. 17 strings; LP ch. 14 push/pop. NoC: NoC 8.5 L-systems. 2023 application: WP2 'L-systems'. Klee: I.1 the walking point, returned as the turtle. Reference: GDQuest's supplied turtle is Logo [V research_engine].
- **Departure:** none (spine order)
- **Project step:** A grammar-drawn plan in your hall that a body can walk.
- **Tracks:** long

#### 30. Navigate a generated world

- **Spine:** proceduralgeneration. **Halls:** PG_Caves_Mazes (carrier); PG_Genetic_Evolution (field trip); PG_Sculpted_Forms (field trip); PG_Space_Colonization (encounter) [V spine.json]
- **CODE:** new navigation, resources; returns random, seeds, collision, player, classes, export, stacks
- **BODY:** A maze carved by a chosen algorithm, walls with colliders; a NavigationMesh baked over it; a NavigationAgent3D with the player's radius sent through; the maze recipe saved as a custom Resource (.tres), as PG_Genetic_Evolution saves its genome.
- **ARGUMENT:** axis *maze hand (declared on maze_generation: backtracker, prim, binary_tree, sidewinder, labyrinth) [V ada.json]*; values backtracker / prim / binary_tree / sidewinder.
  - Prediction: binary_tree and sidewinder look most alike (long open corridors along edges, a visible bias); backtracker is the outlier, long winding corridors and few dead ends. [P]
  - Claim: *Every maze algorithm leaves a handwriting you can read from above.*
- **DEBT:** WP3 asks 'how do we navigate an auto-generated world?': the route in the array is not the route for a body (clearance). A genome saved as a Resource is a body as a file: Ada's DNA families as data.
- **PLACE / ONTOLOGY:** Walk it; send an agent through; block a corridor and watch it re-plan.
- **Godot:** NavigationRegion3D; bake_navigation_mesh(); NavigationAgent3D: target_position, radius; class_name MazeRecipe extends Resource; ResourceSaver.save()
- **Lineage:** Processing: none (LP ch. 10 algorithms is nearest). NoC: NoC 9 evolutionary computing (PG_Genetic_Evolution). 2023 application: WP3 'procedural generation', 'evolutionary algorithms' and its navigation question [V APPLICATION.md]. Klee: Part I's additive and subtractive making. Reference: 10 PRINT 'Maze Walker'; maze algorithm names after common usage [mem].
- **Departure:** none (spine order)
- **Project step:** A generated passage in your hall that an agent and a visitor can both cross.
- **Tracks:** long

#### 31. Soft bodies: stretchability

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); Topology_Entropy_Morphogenesis (field trip); SoftBodies_Cloth_Physics (field trip); SoftBodies_Carusell (encounter); ProceduralGeneration_Reaction_Diffusion_Systems (encounter) [V spine.json]
- **CODE:** new other:pins_joints; returns import_assets, physics_bodies, export, setters, xr
- **BODY:** The scanned body from chapter 12, decimated, or a subdivided box, made a SoftBody3D: stiffness, damping and pressure as @export sliders; two points pinned by index; hung from a PinJoint3D ring (Carusell).
- **ARGUMENT:** axis *mesh subdivision of the same soft body*; values 2 / 4 / 8 / 16.
  - Prediction: 8 and 16 look most alike at rest; pinned, 16 sags and wrinkles more finely, and 2 deforms as a few rigid facets. [P]
  - Claim: *A body can only bend where it has vertices: smooth deformation is paid for in polygons.*
- **DEBT:** Polycount against smooth deformation (application l. 89) made physical. A scan is too heavy to be a soft body until it is decimated. Turing's 1952 morphogenesis is visited in the reaction-diffusion hall: order from order (Chun, Programmed Visions ch. 3).
- **PLACE / ONTOLOGY:** Carry it in the headset: grab a soft body and watch it hang and swing; walk through the cloth curtain.
- **Godot:** SoftBody3D: simulation_precision, linear_stiffness, pressure_coefficient; set_point_pinned(); PinJoint3D; decimation on import or in Blender
- **Lineage:** Processing: none. NoC: NoC 3.9 springs; NoC 6.11 soft bodies from Verlet springs. 2023 application: WP2 'soft body simulation (cloth, liquids, rubber)'; WP3 reaction-diffusion; Turing 1952. Klee: I.9 bone, ligament, tendon [V research_bauhaus]. Reference: Queer 3D lineage: Bellmer, Satterwhite (hybrid form) [V QUEER3D.md].
- **Departure:** none (spine order)
- **Project step:** Your body, softened, in your hall: a pin, a slider and a claim about polycount.
- **Tracks:** long

#### 32. Implicit bodies: a threshold in a field

- **Spine:** isosurfaces. **Halls:** ISO_Metaballs (carrier); ISO_ImplicitModeling (field trip); ISO_LookupTable (field trip); ISO_TorusGyroid (field trip); ISO_Introduction (encounter) [V spine.json]
- **CODE:** new other:bit_ops; returns functions, nested_loops, surface_tool, normals, noise, collision, raycasts, player
- **BODY:** density(p) as a sum of metaball fields (or SDF primitives joined by smooth-min); a triple loop turns eight corner samples into an 8-bit index; the supplied 256-entry marching-cubes table turns the index into triangles through SurfaceTool.generate_normals().
- **ARGUMENT:** axis *blend radius (declared as fusion on implicit_surface_modeling: distinct, necked, lobed, single) [V ada.json]*; values distinct / necked / lobed / single.
  - Prediction: Lobed and single look most alike from a distance (one mass); necked is the most telling, the moment two become one. [P]
  - Claim: *Smooth-min is where the blob comes from: one number decides when two bodies become one.*
- **DEBT:** The blob aesthetic has an address: smooth minimum (Quilez) and the isosurface threshold. The marching-cubes table is supplied: a code-critique station reads 40 lines of it (Kittler model). Grid resolution against detail is polycount again.
- **PLACE / ONTOLOGY:** Can a player-sized body pass? cast_motion() with a CapsuleShape3D through the gyroid; then walk into the cave interior.
- **Godot:** func density(p: Vector3) -> float; bit operations: |, <<; supplied TRI_TABLE; SurfaceTool.generate_normals(); create_trimesh_shape(); PhysicsDirectSpaceState3D.cast_motion()
- **Lineage:** Processing: none. NoC: none. 2023 application: none by list; the application names Lague's coding adventures (Marching Cubes). Klee: Part I additive making (deposit). Reference: Lague's Marching Cubes and a Godot-Marching-Cubes repo [V research_engine]; Quilez's smooth minimum [V research_engine].
- **Departure:** none (spine order)
- **Project step:** A blob body in your hall whose fusion you can set, and a passage tested for a body.
- **Tracks:** long

#### 33. Union and difference (pause week)

- **Spine:** boolean_surfaces. **Halls:** Boolean_Works (carrier); Boolean_Verbs (field trip); Boolean_Gallery (field trip) [V spine.json]
- **CODE:** new none (pause week); returns meshes, collision, export, player, profiling
- **BODY:** No new code. Carve an inhabitable burrow with CSGCombiner3D children (union, intersection, subtraction) and use_collision; then bake it to a static mesh with a trimesh collider and compare the frame cost.
- **ARGUMENT:** axis *operation on the same box and sphere, half overlapping*; values union / intersection / box minus sphere / sphere minus box.
  - Prediction: Union and 'box minus sphere' share the box's outline from the front; 'box minus sphere' and 'sphere minus box' are the most different pair, because subtraction does not commute. [P]
  - Claim: *The order of a cut decides which body survives.*
- **DEBT:** CSG is expensive and was never meant to ship, so bake it. Coincident faces z-fight: two bodies claiming one place. This project's walk map cannot see CSG collision [mem project note].
- **PLACE / ONTOLOGY:** Walk into the burrow: collision decides whether a hollow is an opening or a sealed cavity.
- **Godot:** CSGCombiner3D, CSGBox3D, CSGSphere3D; operation; use_collision; bake CSG to MeshInstance3D
- **Lineage:** Processing: none (Processing has no CSG). NoC: none. 2023 application: none. Klee: Part I ends on genesis: building up and chipping away are Klee's two productive acts [V lineage.json]. Reference: Aesthetic Programming's pause weeks with no new syntax [V research_ccs]; TUTORIAL_LINEAGE 'reflect halls need no compulsory code'.
- **Departure:** none (spine order)
- **Project step:** Pause: fold earlier families into your hall and write the log's DEBT section across chapters 23-32.
- **Tracks:** long

### VI. Bodies that choose, and the crisis (spine 20-25)

#### 34. Many that choose: agents and flocks

- **Spine:** swarmintelligence. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_FlowFields (field trip); SwarmIntelligence_Agent_Based_Modeling_ABM (field trip); SwarmIntelligence_PhysarumColony (encounter) [V spine.json]
- **CODE:** new queues; returns classes, export, multimesh, dictionaries, vectors, profiling, groups
- **BODY:** Boids as a small class with position and velocity; separation, alignment and cohesion weights as @export; one node per boid first, then one MultiMesh with a spatial hash; FlowFields' breadth-first distance field from a goal, computed with a queue.
- **ARGUMENT:** axis *which rule leads (separation / alignment / cohesion weights)*; values separation only / alignment only / cohesion only / balanced 1.5 / 1 / 1.
  - Prediction: Alignment-only and balanced look most alike in a still (a coherent stream); cohesion-only collapses into a ball and separation-only spreads into a lattice. [P]
  - Claim: *A flock is three local rules; no bird holds the shape.*
- **DEBT:** Emergence is not innocent: 'self-organisation' is also the language of markets and management. O(N^2) neighbour search eats the frame budget. Calling Physarum 'intelligent' is a metaphor with a politics.
- **PLACE / ONTOLOGY:** Stand in the flock in the headset: your body is a neighbour they avoid.
- **Godot:** class Boid (RefCounted); Array as a queue: push_back() / pop_front() for BFS; MultiMesh transforms per frame; a spatial hash in a Dictionary
- **Lineage:** Processing: none. NoC: NoC 5 Autonomous Agents (steering, flocking, flow fields). 2023 application: WP4 'swarm intelligence'; WP2 'flow fields' returns. Klee: none. Reference: Reynolds' boids (1987) [mem].
- **Departure:** none (spine order)
- **Project step:** A crowd in your hall that notices the visitor.
- **Tracks:** long

#### 35. Bodies that learn

- **Spine:** machinelearning. **Halls:** ML_Neural_Networks (carrier); ML_Perception (field trip); ML_Evolution (field trip); ML_Gradient_Landscape (field trip); ML_Classification (encounter) [V spine.json]
- **CODE:** new sorting; returns arrays, nested_loops, timers, await, testing, ai_assist, classes
- **BODY:** A tiny network trained in Timer-driven batches so the frame never stalls, each weight shown as a cylinder's thickness and colour; ML_Evolution's population ranked with sort_custom() (a tournament); the perceptron trained as a headless check that converges on AND and fails on XOR.
- **ARGUMENT:** axis *hidden-layer topology (declared on neural_network_visualization: graded, flat, deep, widened, pinched) [V ada.json]*; values flat / graded / deep / widened / pinched.
  - Prediction: Graded and deep look most alike (both taper); widened is the outlier, a bulging middle. [P]
  - Claim: *A network is a body of weights; its shape sets what it can learn before it has seen any data.*
- **DEBT:** Models are always biased (Queer 3D). XOR is the classic failure. The assistant you have used since chapter 10 is a scaled-up version of these weighted sums (ai_assist returns: what does the model not know about your scene?). Turing's B-type unorganised machine is the application's precedent.
- **PLACE / ONTOLOGY:** Walk through the network in the headset; touch an input node and watch the activation travel.
- **Godot:** Array of Arrays (weights), nested loops; sort_custom(func(a, b): return a.fitness > b.fitness); Timer-driven batches with await; assert-based headless check
- **Lineage:** Processing: none. NoC: NoC 9 GA, NoC 10 neural networks, NoC 11 neuroevolution. 2023 application: WP3 'neural networks', 'evolutionary algorithms'; WP4 'AI'; the Turing test [V APPLICATION.md]. Klee: none. Reference: Aesthetic Programming ch. 10 'Machine unlearning' [V research_ccs]; Chun, Discriminating Data (homophily) [mem].
- **Departure:** none (spine order)
- **Project step:** A learner in your hall whose weights a visitor can see change.
- **Tracks:** long

#### 36. Nodes and edges: routes

- **Spine:** graphtheory. **Halls:** GT_Pathfinding (carrier); GT_Layout (field trip); GT_Spanning_Trees (field trip); GT_Foundations (encounter); GT_Network_Analysis (encounter) [V spine.json]
- **CODE:** new graphs, search; returns classes, dictionaries, queues, stacks, navigation, signals, timers
- **BODY:** A RefCounted Graph (a vertex array and an adjacency Dictionary of Arrays) kept apart from its Node3D renderer; BFS and DFS replayed as timed light; an AStar3D walker that re-plans when a pressed button disables a point; a force-directed layout that gives the graph a body.
- **ARGUMENT:** axis *layout seed for the same cube graph (force_directed_layout)*; values seed 0 / seed 1 / seed 2 / seed 3.
  - Prediction: All four converge to congruent shapes, rotated or mirrored, so any two look alike; that is the argument. An irregular graph would separate them more. [P]
  - Claim: *A graph has no body until a layout gives it one; the same relations wear different bodies.*
- **DEBT:** Centrality turns into importance and the shortest path into the only value; recommendation by similarity (homophily) closes neighbourhoods (Chun [mem]). The application puts graphs with world building (WP3); the spine puts them six sequences after procedural generation.
- **PLACE / ONTOLOGY:** Walk the graph as rooms; block a door and watch the walker re-route.
- **Godot:** class Graph extends RefCounted; Dictionary of Arrays; BFS with a queue, DFS with a stack; AStar3D: add_point(), connect_points(), get_point_path(), set_point_disabled()
- **Lineage:** Processing: none. NoC: none (NoC 2 and 3.9 springs in the layout). 2023 application: WP3 'Graph Theory' and its navigation question [V APPLICATION.md]. Klee: none. Reference: Euler's Koenigsberg (GT_Foundations).
- **Departure:** none (spine order)
- **Project step:** Plan the final project now, two units before the end (Aesthetic Programming): flowchart your hall, name its families, predictions and debts.
- **Tracks:** long

#### 37. Impossible bodies: the foundations crisis

- **Spine:** foundationscrisis. **Halls:** Escher_Impossible (carrier); NonEuclidean_Spaces (field trip); Brouwer_Intuitionism (field trip); Florensky_Paraconsistent (field trip); Godel_Incompleteness (encounter); Euclid_Parallel (encounter) [V spine.json]
- **CODE:** new other:three_valued_logic; returns camera, signals, resources, classes, shaders, uniforms
- **BODY:** escher_staircase, a body correct from one viewpoint only: the active Camera3D is read each frame and viewpoint_locked is emitted when the viewer aligns. Brouwer's propositions get a third value, 'not yet constructed', as a custom Resource with an enum instead of a bool.
- **ARGUMENT:** axis *seam disclosure (declared on escher_staircase: none, hairline, gap, scaffold, field) [V ada.json]*; values none / hairline / gap / scaffold / field.
  - Prediction: From the locked viewpoint, none and hairline look most alike (the seam invisible or nearly); scaffold is the outlier; from any other standpoint all five separate. [P]
  - Claim: *An impossible body is possible from one standpoint: the camera, not the geometry, closes the loop.*
- **DEBT:** Goedel and the halting problem: 'not found within budget' is not 'unprovable' (Godel_Incompleteness). A bool is a two-valued decision; a third value is a political choice (non-binary logic in code). Non-Euclidean space in a Euclidean engine is always a trick, a shader warp the collider does not follow (return of chapter 5's norm).
- **PLACE / ONTOLOGY:** Stand at the one point where the staircase closes; step off it and watch it break.
- **Godot:** get_viewport().get_camera_3d(); dot with -basis.z; enum Truth {TRUE, FALSE, NOT_YET}; class_name Proposition extends Resource; signal viewpoint_locked
- **Lineage:** Processing: none. NoC: none. 2023 application: WP4 'non-euclidean spaces'; the decision problem and the paradoxes of infinity that ended the 2022 prototype [V APPLICATION.md]. Klee: II a picture can be logically right and psychologically wrong (weak) [V lineage.json]. Reference: Escher, Reutersvard, Penrose (Queer 3D lineage); QueerOS 'Warning' [V research_queer].
- **Departure:** none (spine order)
- **Project step:** A body in your hall that only exists from one place, and your note on where that place is.
- **Tracks:** long

#### 38. Order toward entropy: the QFEP laboratory

- **Spine:** qfeplaboratory. **Halls:** QFEP_F_Term (carrier); QFEP_E_Term (field trip); QFEP_Lambda_Spectrum (field trip); QFEP_Synthesis (field trip); QFEP_Edge_Of_Chaos (encounter) [V spine.json]
- **CODE:** new other:metrics_log; returns packed_arrays, random, multimesh, player, vectors, physics_bodies
- **BODY:** The student's own course log as data: each chapter's predicted closest pair against the measured one, logged into a PackedFloat32Array and drawn as a line chart (F = |prediction - observation|, as QFEP_F_Term does); E as the spread (RMS) of a Brownian population; lambda from the visitor's position along a track driving a MultiMesh field.
- **ARGUMENT:** axis *lambda, order to entropy (lambda_hall)*; values 0.0 / 0.35 / 0.7 / 1.0.
  - Prediction: 0.7 and 1.0 look most alike: disorder saturates, and past a point more entropy adds no visible difference; 0.35 is where structure and noise are both legible. [P]
  - Claim: *Entropy saturates: the step from order to some disorder is visible, the step from much to more is not.*
- **DEBT:** A metric is a body too: F measures my prediction error, not the world. QFEP is a framework, not a law (the Sieve's third question: what lives in the dark spot?). Entropy as resistance (Haraway and Ahmed via Queer 3D).
- **PLACE / ONTOLOGY:** Become the slider: walk along the lambda track; your position sets the room's order.
- **Godot:** PackedFloat32Array log; ImmediateMesh line chart; RMS spread from global_position; the visitor's position projected on a track (dot)
- **Lineage:** Processing: none. NoC: none (NoC 0's random walk returns as Brownian kicks). 2023 application: the application's Theory: complexity and entropy; QFEP postdates the application [V lineage.json]. Klee: none: Klee's arc ends in energy and colour. Reference: Nees' Schotter as the order-to-entropy arc in one image [V research_bauhaus].
- **Departure:** none (spine order)
- **Project step:** Your log's predictions plotted as F; add an entropy axis to one body family in your hall.
- **Tracks:** long

#### 39. Leaving the lab: situated computation and your hall

- **Spine:** postfoundationscrisis. **Halls:** CriticalAlgorithms_Applied_Ethics (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (field trip); SpeculativeComputation_Rhizome_Network (field trip); PostCrisis_Synthesis (field trip); SpeculativeComputation_Collective_Knowledge (encounter) [V spine.json]
- **CODE:** new files; returns loops, raycasts, save_load, json, export_build, xr
- **BODY:** room_shape_demonstrator: seating generated by loops under a plan, checked by a raycast sightline from every seat to one point; the final hall reads back a record another hall wrote (a user:// file, written atomically), so state survives scenes and restarts.
- **ARGUMENT:** axis *seating plan (declared on room_shape_demonstrator: pair, head, circle, panopticon, vacant) [V ada.json]*; values pair / head / circle / panopticon / vacant.
  - Prediction: Head and panopticon look most alike from above (every chair faces one point); circle is the plan where the sightline check passes for every seat. [P]
  - Claim: *Equal spacing is not equal standing: a plan decides who sees whom.*
- **DEBT:** Algorithmic bias (Buolamwini's Coded Gaze, in the application). Accessibility as a check the code can run but not decide. The course's own dark spot: 'revealing the black box' can hide as much as it shows (Chun's 'sourcery', Programmed Visions ch. 1).
- **PLACE / ONTOLOGY:** The final hall: your room in the endless museum, walked by classmates on desktop and headset; export a Quest build.
- **Godot:** FileAccess user://; write to .tmp then rename; raycast sightlines; export presets: Windows and Android/Quest
- **Lineage:** Processing: LP ch. 21 exporting. NoC: none. 2023 application: the application's Critical Technology field (Coded Gaze); Illich, Freire and Federici on commoning; Deleuze and Guattari's rhizome [V lineage.json]. Klee: none. Reference: Code Societies 'Software as Ideology' and 'Critical Simulation' [V research_creative]; the Aesthetic Programming final project with a ReadMe [V research_ccs].
- **Departure:** none (spine order)
- **Project step:** Final project: a finished hall with at least three body families, each with its prediction, comparison image, claim and a debt comment in the code; shown, walked and exported.
- **Tracks:** long

## Returns and supplies, declared

The control never moves a hall, so where the spine's own halls use an idea early it has two tools: a **supply** (the idea is given, named, and opened in a later chapter) and a **return** (a later chapter goes back to an earlier body or idea and says so).

Supplies (the spine uses the idea before it teaches it) [V lineage.json notes, survey_bundle.json hooks]:
- **Chance** in Point_Coordinates, Trans_Body, Array's molnar_cube_study and Flow_Field is supplied until **chapter 23** (spine 10).
- **Noise** in Flow_Field (spine 6) and Wavefunctions_Bernini (9) is supplied until **chapter 25** (spine 11).
- **Recursion** in FormFinding_Equilibrium (spine 8) is supplied until **chapter 28** (spine 14).
- **A first shader** in Tutorial_Pattern (spine 5) and Noise_6_Wall (11) is supplied until **chapter 26** (spine 12).
- **The segment helper** (show_between, chapter 5) is opened in chapter 8; **the walker** (chapters 3-11) is opened in chapter 12; **the XR staging scene** runs throughout.
- **Inheritance** in VFM_08_Arena (spine 7) is *taught* there (chapter 19), because class authorship was already given its own chapter at colour (chapter 15). That is a placement of a code idea, not a move of a hall.

Declared returns:
- Chapter 2's frame-counted column is repaired with delta in **chapter 11**.
- Chapter 5's Euclidean norm returns as non-Euclidean space in **chapter 37**.
- Chapter 6's walking point returns as the L-system turtle in **chapter 29** (Logo is Klee's walk).
- Chapter 9's triangle counting becomes measuring with the Profiler in **chapter 25**.
- Chapter 12's scanned body returns, decimated, as a soft body in **chapter 31** (polycount against deformation made physical).
- Chapter 15's colour as appearance returns as colour as light and energy with shaders in **chapter 26** (Klee ends in colour).
- Chapter 16's CPU tiling returns as `fract(UV * n)` in **chapter 26**.
- Chapter 20's supplied recursion is opened in **chapter 28**.
- ai_assist (chapter 10) returns critically in **chapter 35**, where the student sees what an assistant is made of.

## What the control shows (for scoring the other candidates)

These are measurements of this candidate, so they are also measurements of the spine as it stands.

1. **The spine is front-loaded with elements.** Spine 1-5 takes 16 of 39 chapters (41%) for 5 of 25 sequences, and primitives alone takes 10. This is the creative-coding intro semester (Processing Handbook, Learning Processing, ICM) laid out in 3D. It is logical for the ladder, because the fundamentals must come somewhere, but it pushes everything the 2023 application calls 'basic' (WP1) past the middle.
2. **Chance arrives at chapter 23 of 39 (59% of the way), noise at 25.** The comparable courses meet chance much earlier: NoC chapter 0, Aesthetic Programming 5 of 10, Code as Creative Medium 6 of 19, Nake 1965 in the Klee lineage, Palle's 2023 WP1, and Queer 3D's Foundation list, which *starts* with randomness and simplex noise [V research files, QUEER3D.md]. The control has to supply chance four times before it may teach it. That is the strongest single argument a candidate can make for a departure.
3. **Sound and particles.** WP1 names both. In the control sound is first heard at chapter 14 (Tutorial_Disco) and taught properly at 22; particles have no hall of their own and sit in Random_Game at chapter 24, the only place the spine offers.
4. **Graphs at 36.** The application puts graph theory with world building (WP3, 'how do we navigate an auto-generated world?'); the spine puts it six sequences after procedural generation. The control has to teach navigation (chapter 30) before graphs (chapter 36), so pathfinding is used before it is understood.
5. **Regularity and randomness are five sequences apart** (tiling 5, randomness 10). 10 PRINT argues you need the regular grid to see chance [V research_ccs]; the control can only point back from chapter 23 to chapter 16.
6. **The short track has to skip 27 chapters** and jump from colour (chapter 15) to chance (23). Four idea gaps are bridged by supplied helpers (functions, delta, MultiMesh, PackedVector3Array/SurfaceTool). The three-week course works, but only by treating the spine as a menu, so the control's short track is already 'not forced by the spine' out of necessity.
7. **Where the spine is right and the tradition is wrong.** Transformation at spine 2 is 12 Learning Processing chapters early, and correct in Godot, where a node is a transform [V research_creative]. Colour early (spine 4, as processing.org has it) is also defensible if its late return (Klee IV, shaders) is declared, as here.
8. **Where the braid strains.** Formfinding, isosurfaces, boolean, graphs and the crisis arc have no Processing or NoC counterpart, so the lineage fields thin out from chapter 20 on. Chapter 33 (boolean) carries no new code at all, and chapters 31, 32, 37 and 38 need `other:` ideas because the spine's late halls are about bodies and arguments, not new syntax. That supports the ruling that reflect halls need no compulsory code, and suggests a candidate may merge late sequences into fewer chapters.
9. **The late spine is critique-shaped.** Chapters 37-39 read best as Code Societies-style critique sessions set beside code (a guest, a reading, a small score) rather than as more code [V research_creative].

## Are there comparable courses with this scope? (short answer)

Not with this whole scope. The research sweeps (research_ccs, research_creative, research_engine, research_bauhaus, research_queer) found critical-code courses with a braid of theory and syntax (Aesthetic Programming, Marino's and Douglass' CCS courses, CCS 382), creative-coding courses whose order matches spine 1-21 (Processing Handbook, Learning Processing, ICM, NoC, Generative Design, Code as Creative Medium), engine curricula without a critical layer (Catlike Coding, GDQuest, Book of Shaders, Lague), and one close art-school precedent for a Bauhaus basic course redone in 3D (Claudia Hart's Experimental 3D at SAIC). None teaches procedural 3D or VR bodies to beginners with a queer or critical lens, and none asks for a falsifiable prediction per chapter. What each lends this control is listed next.

## What this candidate learned from comparable courses

- Processing Handbook, Learning Processing, NYU ICM [V research_creative]: spine 1-5 already is creative coding's 27-year intro order (draw, variables, conditions, loops, functions, objects, arrays). The control keeps it and borrows ICM's double titles (effect, then idea: 'Many bodies: loops, and a first family').
- The Nature of Code [V research_creative]: spine 6-21 is NoC reordered; the control keeps its inanimate-to-living-to-intelligence drift, its cumulative chapter-end project (the Ecosystem exhibit becomes 'your hall in the endless museum') and the ITP course's midterm simulation project (after chapter 22).
- Aesthetic Programming [V research_ccs]: RunMe/ReadMe becomes BODY plus ARGUMENT, with Ada's falsifiable prediction replacing the open ReadMe questions; the ReadMe lives beside the code in Git; peer feedback on each chapter; a pause week with no new syntax (chapter 33); the final project planned two units before the end (chapter 36).
- Critical Code Studies (Marino) [V research_ccs]: code-critique stations at the DEBT step, on Ada's own approximating code (the RNG in chapter 23, the FastNoiseLite call in 25, the marching-cubes table in 32), after the Kittler raytracer chapter; the Climategate 'confessing comment' becomes a debt comment in the student's own code (detail [mem]).
- CCSWG 2024 [V research_ccs]: 'describe a body in a single class' as the classes chapter's prompt (chapter 15); write first, critique second inside every chapter.
- Montfort, Exploratory Programming [V research_ccs]: errors in week one as a positive topic ('valid and intentional are different', chapter 1's planted bug); 'Critique My Starter Programs' turned on Godot's default scene (chapter 1) and capsule player (chapter 12).
- 10 PRINT [V research_ccs]: 'Maze Walker' as the first seeded body (chapter 23); 'Regularity before Randomness' is quoted against the control itself, which keeps the grid (5) and chance (10) five sequences apart and says so.
- Fuller's Software Studies: A Lexicon [V research_ccs]: one reading per code idea, pulled in by the code rather than pushed by a theory sequence (Variable ch. 2, Lists ch. 6, Loop ch. 7, Function ch. 8, Import/Export ch. 12, Object Orientation ch. 15, Glitch ch. 25, Pixel ch. 26, Elegance ch. 28).
- Albers, Interaction of Color [V research_bauhaus]: the argument strand's ancestor ('make two colours look alike' becomes 'predict which two bodies look alike'); a constrained material (one body with one or two exposed axes) keeps comparisons honest.
- Klee, Pedagogical Sketchbook, corrected order [V research_bauhaus, lineage.json]: Part I (line, structure, body) is spine 1; the pendulum, circle and spiral open Part IV and land in chapter 21; Klee ends in colour, so colour is taught as appearance at spine 4 and returns as energy with shaders (declared return, chapter 26).
- Gaboury, Image Objects [V research_engine]: one technical object per chapter as a critique at chapter grain: culling (ch. 8), the default primitives / Utah teapot (ch. 3, 12), object orientation (ch. 15), frame buffer and GPU (ch. 16, 26).
- Code as Creative Medium [V research_creative]: body-named assignments give the short track's mini project ('Extrapolated Body'); short exercises (PRIMM) against open assignments (Make); 'The Bimodal Classroom' for mixed groups at Konstfack.
- SFPC Code Societies (3 weeks, a teacher per session) [V research_creative]: the short track's shape, with guest and critique sessions in week 3; it also shows how the late spine can be taught as critique beside code.
- Queer Game Studies and CCS 382 [V research_queer]: failure before futures; the control's close runs crisis (37) to QFEP (38) to leaving the lab (39).
- GDQuest Learn GDScript / 3D [V research_engine]: use before make (supplied walker, segment helper, XR staging, named and opened later); skin versus controller for swapping the desktop body for the XR body (chapter 12). The control does not take GDQuest's late _process: the spine teaches it at Point Zero.
- Book of Shaders [V research_engine]: Ada's Shader halls follow its chapters 5-13 and the spine keeps its drawing-before-generative order; the control keeps shaders as one block at spine 12 and makes tiling-to-shader a declared return rather than a braided strand.
- What no comparable course has, and the control keeps [V research_ccs, research_creative]: bodies built in 3D code, a falsifiable prediction per chapter, and the DEBT layer on geometry (polycount against deformation, the blob, stopped recursion). The canon's queer work is linguistic or data-centred; Ada's geometric queering is a gap the course should name, not borrow authority for.

## Verification notes

- [V] Halls: every hall in every chapter was checked against `spine.json` by `c1/build.py` (140 halls, 0 missing). The ladder, the load limit, the vocabulary and spine coverage were checked by the same script.
- [V] Declared DNA axes (sphere_high tessellation, snap_pyramid_puzzle apex, chroma_stack rule, force_field_zone law, distribution_sampler law, noise_space generator, ca_bridge rule, fractal_recursion_2 depth, maze_generation hand, implicit_surface_modeling fusion, neural_network_visualization topology, escher_staircase seam, room_shape_demonstrator plan) were taken from `maps/ada.json`, which read them from the registries; I did not open the registries myself.
- [V] Hall hooks and tutorial forms come from `doc/book/iterations/claude-godot-path-2026-09-30/survey_bundle.json`; lineage (Processing, NoC, Klee sections, WP mapping) from `maps/lineage.json`; course comparisons from the five `research_*.md` files.
- [V] `maps/ada.json` and `maps/lineage.json` were absent when this run started and appeared about two minutes later; both were used.
- [mem] Physics and maths facts inside predictions: complementary launch angles share a range without drag; Gibbs overshoot is about 9%. Label3D is double-sided by default. Reynolds' boids date from 1987. Wolfram's classes via NoC 7. Maze-algorithm biases (binary tree's diagonal bias). Quetelet's 'average man'. Chun's Discriminating Data (homophily).
- [mem] Two facts are from this project's own memory notes, not re-measured: the settle test that read 15/16 at 90 Hz and 2/16 at 60 Hz, and 'the walk map cannot see CSG collision'.
- [P] Every closest-pair prediction is a prediction. Several may be wrong, and a wrong one is worth more than a right one: it is the lower bound that catches a broken render (CLAUDE.md, DNA programme).
- Nothing in the Ada repo was edited, staged or committed.
