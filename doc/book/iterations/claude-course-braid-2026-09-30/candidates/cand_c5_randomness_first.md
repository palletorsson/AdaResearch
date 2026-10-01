# A Number Nobody Chose: bodies from chance, fields and rules

Candidate `c5_randomness_first` for the 2026-09-30 auto-research braid. Anchor: Randomness and noise first: The Nature of Code (ch 0 Randomness, then vectors, forces, oscillation, particles, agents, physics, CA, fractals, evolution, neural networks), Palle's first-principles order in Queer 3D World (randomness, simplex noise, loops and recursion, vectors and dimensionality, points, lines and grid, ML) and the 2023 application's WP1; opened by the runnable Random_Definition kit.

Marks: **[V]** verified this session (in spine.json, the survey bundle, maps/ada.json, maps/lineage.json, the random-definition kit, the research sweeps, or Palle's own texts); **[mem]** recalled, not checked this session. Nothing in the Ada repo was edited, staged or committed.

## For the student: why this order

We start where the machine is least like you: with a number nobody chose. The first thing you type draws a random value and gives it to a cube; the second makes that value return, because computer chance is a pattern that repeats under a seed. Chance comes first because Palle's Queer 3D World, Ada's 2023 application and The Nature of Code all begin there, and because it hands your first body a debt you can see at once: the chance is computed. Chance is only visible against order, so the grid arrives in the same week (10 PRINT's 'regularity before randomness'), and noise follows as chance that remembers its neighbour: the field you will stand on. Only then do we go back to where Ada's spine starts, the point, the line, the face and the frame, because by then you have a crowd of bodies and a reason to ask where one of them is. From there the course runs close to the spine: forces, balance and waves (Klee's falling, standing and spiral), rules that grow (shaders, cellular automata, recursion, grammars, mazes), bodies that give, fuse, flock and learn, and the limits: impossible space, and entropy, where the first week's chance returns as a measure. In every chapter you build one body in code, make it a family, predict which two members will look most alike before you render them, say what the approximation owes, and put the body somewhere a body meets it.

## For the teacher: what this candidate argues

- **Chance first, but never chance alone.** The anchor puts randomness at chapter 0 (NoC, Queer 3D World, WP1). The research sweeps show every other tradition putting it later (Aesthetic Programming 5 of 10, Levin and Brain 6 of 19, the spine 10 of 25) [V research_ccs.md, research_creative.md]. This candidate keeps the anchor's opening and answers the objection inside Part I: the grid arrives in the same week (c03, c05) because 10 PRINT shows chance is only visible against regularity [V research_ccs.md], and the student's own body arrives by c04, so chance always has something to act on.
- **Supplied, then opened.** c02-c03 run on the Random_Definition kit's display.gd [V kit README]; the walker, the SKETCH/segment helper, face_up() and the XR rig are supplied and each is opened later (c04, c13, c18, c23), as GDQuest does with its turtle [V research_engine.md].
- **The return to the spine's start is the pivot.** Part III (c15-c20) goes back to spine 1-5: points, frames, faces, joints, colour, symmetry. After two parts of scattering and growing bodies, 'where is a body?' becomes a question the student already has.
- **From Part IV on the course follows the spine** (forces, formfinding, waves, shaders, CA, fractals, L-systems, PG, soft bodies, isosurfaces and boolean, swarm, ML, crisis, QFEP, post-crisis), with three declared moves: particles added (WP1, no spine hall [V maps/lineage.json]), shaders after forces (WP3 groups shading with world building), graph theory pulled into procedural generation (WP3's 'navigate an auto-generated world').
- **The course closes where it opened.** c36 brings the first week's chance back as entropy inside QFEP (the application's arc toward entropy [V APPLICATION.md]), and c37 turns the hall into a game whose fairness is a distribution.

Measured on this JSON by c5_build.py (my own approximation of the scorer):

| check | result |
|---|---|
| chapters | 37 in 6 parts |
| spine-order agreement (pairs, first-listed sequence, ties counted as in order / strict) | 0.785 / 0.725 |
| same, using each chapter's lowest-numbered sequence | 0.754 / 0.682 |
| spine coverage | 25/25 |
| ladder violations, unknown ids, halls not in spine.json | 0 |
| chapters with more than 3 new code ideas | 0 |
| code-vocabulary ids never introduced | 0 (all used) |
| backward moves without a departure note | 0 |
| short track's own ladder (returns only from earlier short-track chapters) | 0 gaps; 32 code ideas in three weeks |
| halls used | 119 distinct of 204; 68 carrier, 29 field-trip and 41 encounter uses |
| small-complete-game kit (first met) | player c23, input c16, camera c23, ui c37, save_load c14, audio c25, export_build c08, physics_bodies c07, instancing c22, signals c16 |

## Parts

| part | title | chapters | promise |
|---|---|---|---|
| p1 | Chance: a number nobody chose | c01-c08 | You make bodies from values you did not choose, learn to make them return with a seed, build the body chance needs, and see why chance needs a grid to be seen. Ends with a collage you share (WP1; NoC 0; Queer 3D first principle 1). |
| p2 | Fields: chance with a neighbour | c09-c14 | Noise becomes columns, a floor you stand on, a threshold body you walk through, a family of fields and a flow that moves a crowd; the blob look gets its name. Ends with a recipe that returns (WP1-2; NoC 0.6; Queer 3D first principle 2). |
| p3 | Dimension: where a body is | c15-c20 | Back to the spine's opening with a crowd of bodies in hand: frames, lines, faces, joints, colour and symmetry (Queer 3D first principles 3-4; NoC 1; Klee I-II). |
| p4 | Force: falling, standing, swinging | c21-c25 | Your own integrator, particles, the player's body opened, balance proved by a test, and Klee's pendulum turned into a spiral stair that sounds (NoC 1-4; Klee II-IV; WP1 sound). |
| p5 | Growth: rules that grow | c26-c30 | Rules make bodies per pixel, per neighbour, per call and per symbol, and a carved world must be navigated (WP2-3; NoC 7-8; Book of Shaders). |
| p6 | Worlds and the crisis | c31-c37 | Bodies that give, fuse, flock and learn, then the limits: impossible space, entropy as the return of chance, and the game as a situated round (WP3-4; NoC 5, 9-10; Ada's crisis, QFEP and post-crisis). |

## Tracks

### Three weeks: a chance body in a place (`short`)

- Length: 3 weeks (15 days): week 1 c01-c05 + c08; week 2 c09-c12 + c15; week 3 mini project from day 1
- Chapters: c01, c02, c03, c04, c05, c08, c09, c10, c11, c12, c15
- Mini project: A chance body in a place: one seeded body family (procedural, scanned, or both collaged) with one @export axis; a comparison sheet of 3-5 members with the prediction written before rendering and one claim; placed on a walkable noise field in your hall; carried or stood on in VR if the headset route works; shown to the class with its debt said aloud. Supplied and named: display.gd (c02-c03), the desktop walker and XR staging rig (vr_staging.tscn, XR Tools), the SKETCH/segment helper, the MultiMesh collider helper (c11), export presets, the phone-scan and Blender import recipe.

### One year: your hall in the endless museum (`long`)

- Length: about 36 teaching weeks over two semesters, one chapter a week, a pause week with no new code after each synthesis (c08, c14, c20, c25, c30), final project planned at c34 and shown at c37
- Chapters: c01, c02, c03, c04, c05, c06, c07, c08, c09, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30, c31, c32, c33, c34, c35, c36, c37
- Final project: Final project: your hall as a playable round in the endless museum (c37), built from the bodies of every part, with each chapter's argument sheet and a ReadMe in Git beside the code.

Short-track day plan (15 days): D1 c01 + c02, D2 c03, D3 c04, D4 c05, D5 c08 (checkpoint 1, share a build); D6 c09, D7 c10, D8 c11, D9 c12, D10 c15 (the headset route: carry it); D11-D15 mini project, with one guest seminar on the DEBT layer (Queer 3D World's rhythm) and the showing on D15. The mini project starts on the first day of week 3, as the research on Aesthetic Programming and Code Societies advises [V research_ccs.md, research_creative.md].

## Two indexes (after the Processing Handbook's two tables of contents)

The reading order is the chapter list below. The same chapters by spine sequence, so a teacher can see which sequences are met early, returned to, or left as encounters:

| spine | sequence | chapters (first-listed sequence in **bold**) |
|---|---|---|
| 1 | primitives | **c01**, **c04**, c06, c10, **c15**, **c16**, **c17** |
| 2 | transformation | c15, **c18** |
| 3 | array_tutorial | c03, c05, c20 |
| 4 | color | **c19**, c22 |
| 5 | tiling | c05, c14, **c20** |
| 6 | change | **c13**, c21 |
| 7 | forces | c06, c16, **c21**, **c22**, **c23**, c24 |
| 8 | formfinding | **c24**, c28, c31 |
| 9 | wavefunctions | c09, **c25** |
| 10 | randomness | **c02**, **c03**, c04, **c05**, **c06**, **c07**, **c08**, **c14**, c18, c22, c33, c36, c37 |
| 11 | noise | **c09**, **c10**, **c11**, **c12**, c26, c37 |
| 12 | shaders | **c26**, c27 |
| 13 | cellularautomata | **c27** |
| 14 | fractals | c25, **c28** |
| 15 | lsystems | c05, c14, **c29** |
| 16 | proceduralgeneration | c11, **c30**, c34 |
| 17 | softbodies | c27, **c31** |
| 18 | isosurfaces | c11, **c32** |
| 19 | boolean_surfaces | c32 |
| 20 | swarmintelligence | c13, **c33** |
| 21 | machinelearning | **c34** |
| 22 | graphtheory | c30 |
| 23 | foundationscrisis | **c35** |
| 24 | qfeplaboratory | **c36** |
| 25 | postfoundationscrisis | c34, **c37** |

## Chapters

### Part 1: Chance: a number nobody chose

#### c01. Day Zero: the room answers

*Spine:* primitives (1). *Halls:* Point_Zero (carrier). *Tracks:* short, long.

- **CODE** new: statements, output, errors
- **BODY** The supplied room (Day Zero's floor, camera, light) and two things your script makes: Point Zero's greeting, a Label3D whose text you set, and one cube whose colour you type as three numbers, Color(0.9, 0.3, 0.6). A chosen value, so that the next chapter's unchosen one has something to differ from.
- **ARGUMENT** axis: red channel of the typed colour (green 0.3 and blue 0.6 fixed); values: 0.0 / 0.33 / 0.66 / 1.0.
  - Predict first: 0.66 and 1.0 will look most alike: the room's light and the renderer's tonemapping compress the top of the range, so equal steps in the number are not equal steps on screen.
  - Claim: A typed number is not yet a colour: light, tonemapper and screen stand between the code and the picture.
- **DEBT** Critique the starter, after Montfort's 'Critique My Starter Programs': what body does Godot's template assume (a unit cube at the origin, a capsule player, English keywords, which is FLOW-MATIC's default of US English for Swedish-speaking students)? Name every supplied part (base.tscn, the desktop walker, the XR staging scene): nothing in the room was made by you yet.
- **PLACE** Stand beside the cube in the supplied room (desktop walker, F5). Headset route: Day Zero's written XR route through commons/scenes/vr_staging.tscn, named, not required.
- **Planted bug** print("hello" with the bracket missing: read the parse error, its line number, and what it does not tell you.
- **Godot** Node3D; Label3D.text; print(); _ready() as a supplied slot (opened in c06); StandardMaterial3D.albedo_color (typed, explained in c04 and c19); Output panel and Debugger > Errors
- **Lineage** Processing: Learning Processing ch 1-2 (pixels, the editor, errors); Processing Handbook 'Structure 1: Code Elements'. NoC: none (NoC assumes a semester of this). Application: before WP1: the lab opens. Klee: I.1 the dot, before it walks. Reference: Montfort, Exploratory Programming ch 3-4 ('valid and intentional are different') and ch 7 'Critique My Starter Programs'; GDQuest Learn GDScript lesson 2 'Your first error'; Coding Train 'Errors & Console'.
- **Project step** Open your own hall (an empty room scene named after you) and put the talking cube in it. It receives one body per chapter, as The Nature of Code's Ecosystem Project fills a museum exhibit.

#### c02. A value nobody chose

*Spine:* randomness (10). *Halls:* Random_Definition (carrier), Randomness_Examples_of_Randomness (field trip). *Tracks:* short, long.

- **CODE** new: variables, calling, random; returns: statements, output, errors
- **BODY** One cube coloured by three calls to a local RandomNumberGenerator, Color(a, b, c). The supplied display.gd builds the cube (named as supplied); the lesson owns the generator, the draws and what the draws become. Kit: doc/book/studies/random-definition, step 1, then step 6's channel roles.
- **ARGUMENT** axis: channel roles: what the same three draws become; values: Color(a, b, c) / Color(c, b, a) / Color(a, b, 0) / Color(a, a, a).
  - Predict first: Color(a, b, c) and Color(c, b, a) look most alike: the same three numbers with red and blue exchanged keep green and roughly the lightness; Color(a, a, a) is grey on every seed, the odd one out.
  - Claim: What a draw becomes decides more of the look than which number was drawn.
- **DEBT** randf() is borrowed. Godot documents reproducible seeded sequences but treats the algorithm as an implementation detail (kit README); the chance is fully computed. Nake's Hommage a Paul Klee (1965) used random numbers as a stand-in for the artist's intuition: can a number nobody chose stand in for a choice, and who chose the generator?
- **PLACE** Field trip to Random_Definition (desktop or headset): press REPLAY on seed_replay_demo and watch the museum's 8 x 8 grids do what your one cube does.
- **Planted bug** var rng: RandomNumberGenerator declared without .new(): read the error about calling randf on a null (Nil) value, and the line it points to.
- **Godot** RandomNumberGenerator.new(); randf(); var; Color(r, g, b); material_override; display.gd (supplied)
- **Lineage** Processing: Learning Processing ch 4 Variables (random() as a value, example_04_07_randompainting). NoC: NoC 0 Randomness (random()). Application: WP1 randomness. Klee: none: Klee has no chance; Nake adds it in 1965. Reference: Queer 3D World first principle 1 ('what is randomness, and how can it be visualised?'); Recreating the Past week 1 (Molnar, Chaos and Order); Aesthetic Programming ch 5 (random as control and care).
- **Departure** Earlier than the spine (randomness is spine 10). The course opens with chance because Queer 3D World, the 2023 application's WP1 and The Nature of Code all start there, and because a drawn value gives the first body a debt you can see: the chance is computed. The points, transforms and arrays the spine teaches first are supplied here by display.gd and come back in Part III.
- **Project step** Hang the unchosen cube beside c01's chosen one, its channel role on a label.

#### c03. A pattern that returns

*Spine:* randomness (10), array_tutorial (3). *Halls:* Random_Definition (carrier), Randomness_10_PRINT_Algorithm (encounter), Array (encounter). *Tracks:* short, long.

- **CODE** new: seeds, loops, functions; returns: variables, calling, random
- **BODY** A 4 x 4 grid of cubes, then a pair of grids, coloured from one seed by your function colour_grid(cubes), which loops over the display's supplied array: forty-eight draws receive a place. Kit steps 2-4; step 5 (the unused draw, an if) waits for c05, where conditions are named.
- **ARGUMENT** axis: where the seed is reset; values: never / once per replay / before each grid / before each cube.
  - Predict first: 'once per replay' and 'never' look most alike as single stills (thirty-two unrelated colours each); only a second REPLAY tells them apart. 'before each cube' is the odd one: every cube the same colour.
  - Claim: A seed is not a picture: where the reset sits in the code decides whether the pattern returns, repeats or dissolves.
- **DEBT** Pseudo-randomness is a pattern that returns: under a seed the generator is repetition you cannot see (Queer 3D: 'computer randomness is only pseudo-random'). 10 PRINT's 'Regularity before Randomness': the ordered grid is what lets chance be seen at all.
- **PLACE** Write your seed on your hall's wall label: anyone who types it gets your grid. Encounter Randomness_10_PRINT_Algorithm, a maze you walk, which c05 builds.
- **Planted bug** the seed reset moved inside the loop: every cube one colour, no error message, only a wrong picture.
- **Godot** rng.seed; for cube in cubes; func colour_grid(cubes); steps/ recovery files
- **Lineage** Processing: Learning Processing ch 6 Loops, ch 7 Functions; Handbook 'Math 4: Random'. NoC: NoC 0 (randomSeed). Application: WP1 randomness. Klee: I.5-I.6 'purely repetitive and therefore structural' (the grid). Reference: 10 PRINT ch 30 Regularity and ch 40 Randomness; the Random_Definition kit (verify passes).
- **Departure** Randomness (spine 10) before arrays (spine 3): the loop walks a supplied array here; index, length and append arrive in c06-c07, so the ruling 'list before append' holds.
- **Project step** Save the seed you like: your hall's floor takes your 4 x 4 grid's colours.

#### c04. The body chance needs

*Spine:* primitives (1), randomness (10). *Halls:* Point_One (carrier), Random_Cubes (encounter). *Tracks:* short, long.

- **CODE** new: properties, meshes, collision; returns: variables, calling, random, seeds, functions
- **BODY** Your own body replaces display.gd's cube: a MeshInstance3D given a BoxMesh or SphereMesh resource in code, plus a StaticBody3D and a CollisionShape3D sized apart from what you see. make_body(size) builds it; a seeded draw sets the size. From here make_body() carries every chapter, as Learning Processing's Zoog does.
- **ARGUMENT** axis: collider size relative to the visible mesh (a supplied ball dropped on each); values: 0 (none) / 0.5 / 1.0 / 1.5.
  - Predict first: 1.0 and 1.5 look most alike: in both the ball rests on top and only its height differs by a quarter of the body. 0 and 0.5 are the telling pair: through the body, or sunk inside one that looks solid.
  - Claim: What you see and what holds you are two bodies, and a still shows the second only when another body meets it.
- **DEBT** The collider approximates the visible body (a box for a sphere, later a hull for a scan): physics runs on a simpler body than the one you see. Point One's line between solid and ghost is a decision, not a fact of the mesh.
- **PLACE** Stand on it: which of your four bodies holds you? (desktop walker; headset through Point_One.)
- **Planted bug** the mesh is made but never added to the tree (no add_child): no error and nothing in the room; the Remote scene tree shows it missing.
- **Godot** MeshInstance3D.new(); BoxMesh / SphereMesh; StaticBody3D; CollisionShape3D + BoxShape3D; add_child(); Debug > Visible Collision Shapes
- **Lineage** Processing: Learning Processing ch 1 (Zoog from primitives), ch 8 objects used before written. NoC: none. Application: polycount against smooth deformation first met (SphereMesh rings). Klee: I.1 the dot becomes a body (Klee never builds a solid). Reference: Levin and Brain, Code as Creative Medium 'Parametric Object'; Learning Processing's Zoog; the point-one kit.
- **Departure** Spine 1 after spine 10: the point the spine opens with arrives as the body chance needs. c02-c03 used supplied cubes, named as supplied.
- **Project step** Replace every supplied cube in your hall with make_body(); keep the seed.

#### c05. 10 PRINT in space

*Spine:* randomness (10), array_tutorial (3), lsystems (15), tiling (5). *Halls:* Randomness_10_PRINT_Algorithm (carrier), Array (carrier), Assemblage_Same_Desire (field trip), Tutorial_Tiling_Floor (encounter). *Tracks:* short, long.

- **CODE** new: nested_loops, conditions, vectors; returns: loops, functions, random, seeds, properties, meshes, collision
- **BODY** A floor of your own bodies built by a nested loop, each cell placed at a Vector3 (a position is three numbers held as one value): at each cell one draw decides, by an if, whether a wall slab leans left or right (make_cell(x, z, lean)). Then Schotter's version: the same grid with a disorder ramp, the draw scaled by the row.
- **ARGUMENT** axis: odds of the left lean; values: 0.0 / 0.25 / 0.5 / 0.75 / 1.0.
  - Predict first: 0.0 and 1.0 look most alike: both are regular stripes, mirror images; the maze appears only near 0.5. (ten_print_textile already declares this odds axis.)
  - Claim: Chance is only visible against the regular grid that frames it: at either end of the odds the maze turns back into a pattern.
- **DEBT** The maze was never designed and still reads as a maze: the grid does the designing. Nees's Schotter (1968) ramps disorder down a grid: at which row does it stop reading as a grid? One line of BASIC hides a platform; one call to randf hides an engine.
- **PLACE** Walk the maze: the slabs have colliders. At which odds does it trap you? Randomness_10_PRINT_Algorithm is the same maze at room scale.
- **Planted bug** the inner loop reuses x instead of z: a diagonal of slabs; read the picture, there is no error.
- **Godot** for x in range(n): for z in range(n); Vector3(x * s, 0, z * s); if rng.randf() < odds; rotation_degrees.y; func make_cell(x, z, lean)
- **Lineage** Processing: Learning Processing ch 5 Conditionals, ch 6 nested-loop grid (exercise_06_08). NoC: NoC 0 (probability). Application: WP1 randomness. Klee: I.5-I.6 the chessboard: repetition as structure. Reference: 10 PRINT (Montfort et al. 2012) incl. 'Maze Walker'; Nees, Schotter (1968); Molnar (Des)Ordres; Aesthetic Programming ch 5 (a generative program with two rules).
- **Departure** Randomness (10) with array_tutorial (3) and tiling (5): the grid enters as the frame chance needs, well before tiling's own chapter (c20, a deliberate return). Ruling kept: this first condition tests a draw, not a distance.
- **Project step** Floor your hall with your maze at the odds you argued for.

#### c06. A walk that remembers

*Spine:* randomness (10), primitives (1), forces (7). *Halls:* Random_Walk (carrier), Point_Trace (encounter), Vectors_Act1_WhatAVectorIs (encounter). *Tracks:* long.

- **CODE** new: lifecycle, delta, arrays; returns: vectors, random, seeds, conditions, meshes, functions
- **BODY** A walker: a body whose position gets a random Vector3 step every fixed interval (a delta accumulator in _process), leaving a trail kept in an Array of Vector3: first a fixed list of the four step directions read by index, then append for the trail, capped (the ruling: the list before append) and drawn by the supplied SKETCH/segment helper. No distance gate: every step is kept.
- **ARGUMENT** axis: step law; values: four directions (+-x, +-z) / eight directions / any direction, unit length / gaussian step / Levy flight (rare long jumps).
  - Predict first: 'any direction' and 'gaussian' look most alike: both are isotropic clouds of short steps. The four-direction walk shows its grid; the Levy walk makes islands joined by long lines.
  - Claim: The step's law, not the chance, sets the shape of the walk.
- **DEBT** The walker never chooses, yet its trail has a memory (the Array) the walker lacks. A walk on a lattice shows the lattice. The engine calls _process at the frame rate, so a walk without delta runs faster on a faster machine: the body's speed belonged to the hardware.
- **PLACE** Become the walker: the supplied desktop walker's position receives your step, so you are walked and read the trail from inside it.
- **Planted bug** the step added every frame without delta: the walk goes twice as far at 120 fps; read the FPS monitor.
- **Godot** _process(delta); accumulator; Vector3; position +=; Array[Vector3].append(), pop_front() cap; segment helper (supplied SKETCH, opened in c13)
- **Lineage** Processing: Learning Processing ch 3 (setup/draw: the engine calls you), ch 9 (mouse history). NoC: NoC 0.1 Random Walks (the Walker), NoC 1 Vectors. Application: WP1 randomness. Klee: I.1 'an active line on a walk', handed to chance. Reference: Levin and Brain 'drunk walk'; GDQuest delays the game loop to lesson 10; the point-trace kit (47 checks).
- **Departure** The frame loop (_process, delta) arrives here, later than Point Zero in the spine, because nothing moved before. Klee's walking line is handed to chance before the student draws a line by choice (c16).
- **Project step** Let a walker cross your hall and leave its trail on the floor.

#### c07. Counting chance: dice and distributions

*Spine:* randomness (10). *Halls:* Random_Cubes (carrier), Random_Gaussian (carrier), Random_Entropy (encounter). *Tracks:* long.

- **CODE** new: physics_bodies, expressions, types; returns: arrays, loops, conditions, random, seeds, meshes, collision, functions, vectors
- **BODY** A histogram built from bodies: an Array of six counts indexed by the result (counts[face] += 1; int counts from randi_range against float draws from randf, and / against integer division), turned into a row of make_body() columns whose heights are the counts. Then a real die: a RigidBody3D thrown with a seeded velocity, its face read by a supplied face_up() when it sleeps.
- **ARGUMENT** axis: law (1000 draws each); values: uniform: randi_range(1, 6) / sum of two dice / randfn gaussian / the physical die.
  - Predict first: 'sum of two dice' and 'gaussian' look most alike: adding chances makes a centre, and a triangle already bends toward the bell. The uniform and the physical die should match; if they do not, the die is not fair.
  - Claim: A distribution is a shape you can build, and adding chances builds a centre.
- **DEBT** The physical die is not fair: in Ada a settling die read 15 of 16 at a 90 Hz physics rate and 2 of 16 at 60 Hz. The engine's physics is a second generator with its own bias. Counting keeps the totals and throws away the arrangement; Random_Entropy asks what remains.
- **PLACE** Throw the die in your hall and watch its column grow.
- **Planted bug** counts indexed by face 1-6 in an array of size 6: read the out-of-bounds error for index 6.
- **Godot** Array; counts[i] += 1; randi_range; randfn; RigidBody3D; linear_velocity; face_up() (supplied, opened with basis in c18)
- **Lineage** Processing: Learning Processing ch 9 Arrays, ch 13 (random distribution, probability). NoC: NoC 0.2-0.4 (distributions, probability, the normal distribution). Application: WP1 randomness. Klee: none. Reference: Levin and Brain, exercises 'Unpredictability' (coin toss); distribution_sampler's declared law axis.
- **Departure** Randomness (10) before forces (7): the die is the student's first physics body, met as a generator. Forces and integration come back in c21.
- **Project step** Stand a histogram of 1000 throws of your die in your hall.

#### c08. Synthesis I: a chance collage you can share

*Spine:* randomness (10). *Halls:* Random_Mushrooms (field trip), Random_Remove (encounter), Random_Space_Geometry (encounter). *Tracks:* short, long.

- **CODE** new: import_assets, export_build, ai_assist; returns: random, seeds, loops, nested_loops, meshes, collision, functions
- **BODY** A collage body: a scanned or Tilt Brush body imported as .glb, scattered with your make_body() bodies by one seed over your maze floor, the imported body given a collider made from its mesh.
- **ARGUMENT** axis: the scan's polycount after decimation in Blender; values: 1.0 / 0.25 / 0.05 / 0.01.
  - Predict first: 1.0 and 0.25 look most alike at room distance: the scan carries far more triangles than the eye can use there; 0.01 is a different body, faceted like c04's coarse sphere.
  - Claim: A scan brings more body than the room can see, and the excess is paid in frame time.
- **DEBT** Collage meets debt: phone photogrammetry loses what it cannot see well (hair, dark or shiny surfaces in poor light, transparency) and carries excess triangles. The AI-written part owes a check: ask an AI to add random rotation to your scatter, say what must not change (the seed's return), and name the observation that would prove it wrong (two runs with one seed differ).
- **PLACE** Share it: export a desktop build (and, on the headset route, an Android/Quest build from the supplied presets) and let a classmate walk your collage on their machine.
- **Planted bug** the AI's version calls rng.randomize(): the seed no longer returns, and the replay test catches it.
- **Godot** import .glb (Scene import dock); instantiate an imported scene; create_trimesh_shape(); Project > Export, export templates; supplied export presets
- **Lineage** Processing: Processing Handbook 'Synthesis 1: Form and Code'. NoC: Ecosystem Project, step 0. Application: WP1 close; Freire and Illich (open, repair, share). Klee: I.11 additive building, stone on stone. Reference: Queer 3D World week 1 (scanning, Tilt Brush, export to Blender); Anthropy, Make Your Own Twine Games (share the first work in chapter 1); Hoch and Bellmer (collage).
- **Departure** A synthesis with no spine home: scanning and a shared build come in week 1 because Queer 3D World starts there and because sharing early keeps the work public.
- **Project step** Checkpoint 1 (short track, end of week 1): your hall holds a seeded collage, and the build runs on a classmate's machine.

### Part 2: Fields: chance with a neighbour

#### c09. Noise: chance with a neighbour

*Spine:* noise (11), wavefunctions (9). *Halls:* Noise_Columns (carrier), Random_Noise_Types (encounter), WaveFunctions_Sine_Space (encounter). *Tracks:* short, long.

- **CODE** new: noise, return, parameters; returns: functions, loops, nested_loops, random, seeds, meshes, properties
- **BODY** A row of 24 make_body() columns whose heights come from one function height(i: int) -> float that takes a position and returns a value from one of several sources: a ramp (i * 0.05, the regular reference), randf(), or FastNoiseLite of several types.
- **ARGUMENT** axis: source; values: ramp / randf / value noise / perlin / simplex.
  - Predict first: perlin and simplex look most alike: smooth hills of about the same width. Value noise shows flat-topped steps, randf a jagged skyline, and the ramp is the regular reference that makes the other four readable.
  - Claim: Noise is chance that remembers its neighbour: its smoothness is designed, not found.
- **DEBT** The blob aesthetic starts here: noise looks 'natural' because the algorithm forces neighbours to agree (Perlin made it for film textures in the early 1980s). Queer 3D World's overflow comparison (Perlin 45, random 635, Voronoi 0, sine-curve space 3284) shows how differently four 'natural' sources behave.
- **PLACE** Walk the columns as stepping stones: which source makes a stair you can climb? randf's is not climbable.
- **Planted bug** height() returns on one branch only: 'Not all code paths return a value'.
- **Godot** FastNoiseLite; noise_type; get_noise_1d; func height(i: int) -> float; return
- **Lineage** Processing: Learning Processing ch 13 (Perlin noise, oscillation). NoC: NoC 0.6 Perlin Noise. Application: WP1 Perlin noise. Klee: none. Reference: Queer 3D World first principle 2 ('what is simplex noise, and what can we learn from it?'); Book of Shaders ch 11; Catlike Coding 'Building a Graph' and 'Pseudorandom Noise'.
- **Departure** Noise (spine 11) straight after chance, as NoC 0.6 and Queer 3D World's second first principle place it. The sine hall is only an encounter here (another smooth source, seen in the room); cos and sin are written in c13, and the wave sequence keeps its own place in c25.
- **Project step** A row of noise columns along one wall of your hall, labelled with its source.

#### c10. A floor you can stand on

*Spine:* noise (11), primitives (1). *Halls:* Noise_Space_10 (carrier), Noise_One (carrier), Point_Triangle_Context (encounter). *Tracks:* short, long.

- **CODE** new: surface_tool, normals; returns: noise, nested_loops, vectors, return, collision, meshes
- **BODY** A heightfield terrain: a nested loop samples noise into Vector3 vertices, two triangles per cell go into SurfaceTool, generate_normals() shades it, and a collider is made from the mesh.
- **ARGUMENT** axis: octaves; values: 1 / 2 / 4 / 6.
  - Predict first: 4 and 6 look most alike: the extra octaves add detail finer than the grid spacing, which the mesh cannot show.
  - Claim: Detail below the vertex spacing is invisible: the mesh, not the noise, sets the limit of the body.
- **DEBT** The application's polycount against smooth deformation in one still: more octaves cost nothing visible until the grid is refined, and refining costs frame time. The same vertices with flat or smooth normals read as crystal or as skin.
- **PLACE** Stand on it and walk it: the collider comes from the mesh, so what you see is what holds you (compare c04).
- **Planted bug** triangles wound counter-clockwise: the terrain is invisible from above and visible from below.
- **Godot** SurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES); add_vertex; generate_normals(); commit(); create_trimesh_shape(); front faces wind clockwise in Godot
- **Lineage** Processing: Processing Handbook 'Shape 2: Vertices'; P3D beginShape/vertex. NoC: NoC 0.6 2D noise (terrain). Application: WP1 Perlin noise. Klee: II.14 three dimensions. Reference: Catlike Coding Basics 2-3 (graph, grid, surface); Montfort 'Navigable Generated Landscape'; Levin and Brain 'Generative Landscape'.
- **Departure** The triangle (Point_Triangle_Context, spine 1) is met inside a terrain rather than before it; Part III returns to the single face and the closed polyhedron (c17).
- **Project step** Your hall gets a noise floor with the octaves you argued for.

#### c11. Threshold: the field becomes a body

*Spine:* noise (11), isosurfaces (18), proceduralgeneration (16). *Halls:* Noise_Voxel (carrier), ISO_Introduction (encounter), PG_Percolation_Network (field trip). *Tracks:* short, long.

- **CODE** new: multimesh, booleans, debugging; returns: noise, nested_loops, conditions, vectors, return, collision
- **BODY** 3D noise sampled on a 24^3 grid; a boolean is_solid(p) decides each cell; solid cells become instances of one MultiMesh, thousands of your bodies in one draw call (colliders from a supplied helper: a MultiMesh draws, it does not hold).
- **ARGUMENT** axis: threshold (voxelnoise's declared axis); values: massif / sponge / archipelago / wisp.
  - Predict first: massif and sponge look most alike from outside: the outer shell is full in both; only a cut or a walk inside shows the sponge's tunnels.
  - Claim: A threshold turns a field into a body, and near the middle the body and its negative are the same kind of thing.
- **DEBT** One number decides what counts as matter: the cut is binary and the field is not, so whoever sets the threshold writes inside and outside with a >. FastNoiseLite returns about -1 to 1, so a 0.5 threshold chosen for 0 to 1 leaves almost nothing, which you find only by printing the range.
- **PLACE** Walk through it: the sponge is walkable inside and out; the archipelago is islands you jump between.
- **Planted bug** threshold 0.5 on values in -1..1: a nearly empty room; print the min and max to find out why.
- **Godot** MultiMesh; MultiMeshInstance3D; set_instance_transform; get_noise_3d; print() of min and max; breakpoints and the Remote scene tree
- **Lineage** Processing: Handbook 'Development 2: Iteration, Debugging' (debugging mid-course). NoC: NoC 0.6 3D noise. Application: WP1 Perlin noise. Klee: I.11-I.12 additive building against subtractive cutting. Reference: Queer 3D World ontology layer (hybrid, impossible space); Montfort (errors as a topic, not an appendix).
- **Departure** The field-to-body cut (noise, 11) with a first look at isosurfaces (18, an encounter only): the smooth surface through the same field comes back in c32.
- **Project step** A threshold body stands in the middle of your hall.

#### c12. A family of fields

*Spine:* noise (11). *Halls:* Noise_Perlin_Simplex (carrier), Noise_Space_10 (carrier), Noise_Inside_Noise (field trip). *Tracks:* short, long.

- **CODE** new: classes, export, tool_scripts; returns: noise, surface_tool, normals, functions, parameters, collision, ai_assist
- **BODY** Your c10 terrain becomes a body type: class_name NoiseBody with @export generator, frequency, octaves and seed, rebuilt in the editor by @tool. One class, many bodies: a family.
- **ARGUMENT** axis: generator (declared on noise_space and perlin_noise); values: simplex / perlin / value / cellular.
  - Predict first: simplex and perlin look most alike: round blobs of one size. Value noise shows its grid in squarish steps; cellular is another kind of body, cells with ridges (Voronoi).
  - Claim: The generator names a geometry: three of four make blobs, and only cellular cuts the ground into cells.
- **DEBT** The blob aesthetic named: three of four default generators give the same rounded body. A family is also a fence: the @export list decides which bodies the class allows ('describe a body in a single class', after CCSWG 2024). Derive, never transcribe: Ada's science_screen once declared axis values its code did not have, and a sweep published sixteen identical frames with no error.
- **PLACE** Lay the four family members as four floor tiles in one line and walk across them: the generator under your feet.
- **Planted bug** a @tool script that rebuilds on every property change without clearing the old children: copies pile up in the editor viewport; read the scene tree.
- **Godot** class_name; @export, @export_enum, @export_range; @tool; Engine.is_editor_hint(); Inspector
- **Lineage** Processing: Learning Processing ch 8 Objects (class, constructor). NoC: NoC 0 (the Walker class) and NoC 4 (a class for many). Application: WP1 Perlin noise, Voronoi diagrams. Klee: none. Reference: Form+Code 'Parameterize'; Generative Design numbered variants; CCSWG 2024 ('describe war in a single class'); Aesthetic Programming ch 6 Object abstraction; Fuller's Lexicon 'Object Orientation'.
- **Departure** Class authorship with @export (a body type = a family) comes far earlier than the spine's first authored class (spine 7/20), because Ada's bodies are measured to be families (74% of scripts use @export) and every later argument sweeps one.
- **Project step** Your hall's floor becomes an instance of your NoiseBody class; three family members stand as a triptych.

#### c13. Flow: a field that moves bodies

*Spine:* change (6), swarmintelligence (20). *Halls:* Flow_Field (carrier), SwarmIntelligence_FlowFields (field trip), Change_Intro (encounter). *Tracks:* long.

- **CODE** new: packed_arrays, trig; returns: noise, types, vectors, delta, lifecycle, arrays, classes, export
- **BODY** A fibre body: 300 particles advected through a noise angle field (angle -> Vector3(cos a, 0, sin a)), each trail a bounded, typed PackedVector3Array drawn as a line strip. The trails are the body: hair, current, grain. The SKETCH helper is opened here.
- **ARGUMENT** axis: field frequency; values: 0.005 / 0.02 / 0.08 / 0.3.
  - Predict first: 0.005 and 0.02 look most alike: both laminar streams. At 0.3 the field changes within one step and the trails turn back into random walks (c06).
  - Claim: A field's scale decides whether a crowd flows or wanders: at high frequency, noise becomes chance again.
- **DEBT** Each step is an Euler step, so the trail approximates the field and its error grows with the step (Change_Intro's secant). A flow field is also control: who draws the field that moves the crowd? Types: Godot refuses a wrongly typed value set through set() in silence; in Ada a sweep once published ten identical tiles because of it.
- **PLACE** Stand in the flow: the supplied walker is pushed by the field where you stand; walk against it.
- **Planted bug** the angle in degrees passed to cos(): trails curl in tight knots; print the numbers.
- **Godot** PackedVector3Array; typed Array[Vector3]; ImmediateMesh line strip; get_noise_2d; cos / sin
- **Lineage** Processing: Learning Processing ch 13 (polar and Cartesian). NoC: NoC 5 (2024) flow-field following; NoC 1 Vectors. Application: WP2 flow fields; WP1 sine curves (as direction). Klee: III the path of a body through air strata. Reference: Generative Design M.1; Aesthetic Programming ch 5 ('at least two rules').
- **Departure** Change (spine 6) after noise (11): the field has to exist before it can move anything; NoC and the application (WP2) both put flow fields after noise. The derivative returns as motion in c21.
- **Project step** A flow body drifts across your hall's air.

#### c14. Synthesis II: a recipe that returns

*Spine:* randomness (10), tiling (5), lsystems (15). *Halls:* Random_Definition (carrier), Pattern_Foundry (encounter), LSystems_Living (field trip). *Tracks:* long.

- **CODE** new: resources, save_load, files; returns: classes, export, seeds, noise, import_assets, export_build
- **BODY** A body as a recipe: your NoiseBody's parameters (seed, generator, octaves, threshold) kept in a custom Resource, saved as .tres to user://, loaded in a fresh run and rebuilt; the scan's import settings kept beside it.
- **ARGUMENT** axis: what the recipe keeps; values: everything / seed missing / generator missing / only the seed.
  - Predict first: 'everything' and 'generator missing' look most alike if your generator happens to be the class default (simplex): a missing value is invisible exactly when it equals the default, and that is the danger.
  - Claim: A saved body is only the part of it the recipe names; what the recipe leaves out returns as the default.
- **DEBT** A recipe is a compression (Steyerl's poor image: what survives transfer). Defaults are invisible. Illich's repairability in practice: a .tres is readable text a classmate can open, understand and change.
- **PLACE** Carry a recipe to another hall: load a classmate's .tres into your hall and stand in their body.
- **Planted bug** saving to res:// in an exported build: works in the editor, fails in the export, because res:// is read-only in a .pck.
- **Godot** extends Resource + class_name; ResourceSaver.save(); load() / ResourceLoader; user://; FileAccess (read the .tres as text)
- **Lineage** Processing: Learning Processing ch 18 Data. NoC: none. Application: Illich (transparency, repairability); commoning. Klee: none. Reference: Processing Handbook 'Synthesis 2'; Aesthetic Programming's ReadMe stored beside the code in Git; the Brief's 'a recipe saved as .tres = DNA families as files'.
- **Departure** Saving (no spine home; data.save is on the survey's never-taught list) enters here because a seeded family is only a family if it can return in another run and in another's hands.
- **Project step** Checkpoint 2: your hall rebuilds from files, and a classmate can open your recipe.

### Part 3: Dimension: where a body is

#### c15. Where is a body? Coordinates and frames

*Spine:* primitives (1), transformation (2). *Halls:* Point_Coordinates (carrier), Trans_Introduction (encounter), Trans_Pre (field trip). *Tracks:* short, long.

- **CODE** new: transforms, composition, xr; returns: vectors, properties, meshes, collision, classes
- **BODY** Your walker body from c06 parented under moving frames: position (local) against global_position, a child that rides its parent. On the headset route, hold your point and make a second one holdable (the pickup belongs here).
- **ARGUMENT** axis: parent frame for the same local position (1, 0, 0), shown as a long exposure; values: world / a spinning table / a room scaled x2 / the walker's head.
  - Predict first: 'world' and 'room scaled x2' look most alike: both leave a single point, at different distances. The spinning table draws a circle, the head a copy of your own path.
  - Claim: A position means nothing without its frame: the same (1, 0, 0) is a point, a circle or a copy of you.
- **DEBT** Coordinates are a convention: Y up, metres, an origin nobody stands at, and float jitter far from it (the Critical Engineering 'exploit'). The headset adds a frame you do not control, your own head (Bagnall on normativity in hardware: default height, two hands).
- **PLACE** Carry it: pick the point up (headset route through Point_Coordinates; the desktop carry is supplied).
- **Planted bug** after reparenting under the spinning table, position is set where global_position was meant: the point jumps by the table's offset; print both.
- **Godot** Node3D.position vs global_position; to_global(); reparent(); XRToolsPickable on the object side (rig supplied); commons/scenes/vr_staging.tscn
- **Lineage** Processing: Learning Processing ch 14 (translate, pushMatrix). NoC: NoC 1 Vectors. Application: the headset route. Klee: II.14 three dimensions; II.16 the axis that shifts with the viewer. Reference: Queer 3D World first principles 3-4 (vectors and dimensionality; points, lines and grid); GDQuest 3D 'skin vs controller'.
- **Departure** A deliberate return to the spine's opening (primitives 1, transformation 2) after chance and fields: the student has scattered and grown many bodies and now asks where one of them is. Pickup ruling kept: the XR scene is supplied and only the object side is taught.
- **Project step** Your hall gets a holdable point: a visitor can carry one of your bodies.

#### c16. A line between two chances

*Spine:* primitives (1), forces (7). *Halls:* Point_Lines (carrier), Point_Trace (carrier), Vectors_Act1_WhatAVectorIs (field trip). *Tracks:* long.

- **CODE** new: input, signals, methods; returns: vectors, arrays, conditions, transforms, random, seeds, lifecycle
- **BODY** Twelve seeded points and a rule that connects them. Each segment is an object with a method show_between(a, b); distance (b - a).length() is measured here, and a signal fires when two ends come within reach. Named input actions add and remove points (Point Trace).
- **ARGUMENT** axis: connection rule; values: all pairs / nearest neighbour / within distance d / in drawing order.
  - Predict first: 'nearest neighbour' and 'within distance d' (small d) look most alike: both link only near points and leave far ones alone. 'all pairs' is a hairball, 'in drawing order' a walk.
  - Claim: The points are the same in every still: the rule of connection is the body.
- **DEBT** Distance as the only relation: Euclidean nearness taken for similarity (homophily, Chun's Discriminating Data). A line has no thickness, so to be seen it must be faked as a thin box or strip.
- **PLACE** Walk the lines: give each segment a thin collider and cross your hall on the network as a bridge.
- **Planted bug** a one-argument signal connected to a zero-argument method: the button is dead, and the error appears in the debugger at each emit, not where you connected (Ada memory: 'a 1-arg signal on a 0-arg method is a dead button').
- **Godot** InputMap actions; Input.is_action_just_pressed; signal / emit / connect; func show_between(a, b); distance_to(), length()
- **Lineage** Processing: Learning Processing ch 3 (mouse and key events), ch 7 Functions. NoC: NoC 1.1-1.5 (the point of vectors, magnitude). Application: none. Klee: I.1-I.4 the line limited by fixed points; medial lines. Reference: Kandinsky, Point and Line to Plane; LeWitt's wall drawings (connect corners and midpoints); the point-lines and point-trace kits.
- **Departure** Distance belongs to Point Lines (ruling): it is measured here, after chance has placed the points. The signal is the student's first own event.
- **Project step** A line network joins the bodies in your hall.

#### c17. Faces, and the faces you cannot see

*Spine:* primitives (1). *Halls:* Primitives_Polythedra (carrier), Primitives_Ignorance (carrier), Primitives_Melencolia (field trip), Primitives_Portals (encounter). *Tracks:* long.

- **CODE** new: profiling; returns: meshes, surface_tool, normals, packed_arrays, loops, export
- **BODY** A polyhedron built from a vertex list and index triples (ArrayMesh), then a family of spheres: the same sphere at four tessellations, with triangles counted and frame time read.
- **ARGUMENT** axis: tessellation (sphere_high's declared axis); values: coarse / low / high / ultra.
  - Predict first: 'high' and 'ultra' look most alike at arm's length: past a certain count the silhouette stops changing and only the cost grows.
  - Claim: Smoothness is bought with triangles, and past the eye's limit the body only costs.
- **DEBT** Polycount against smooth deformation (the application): a coarse body cannot bend smoothly, a fine one spends frame time the headset lacks at 72/90 fps. Which bodies are default (Gaboury on the Utah teapot: BoxMesh, SphereMesh, the capsule)? Back faces are culled: a body has faces you cannot see from where you stand.
- **PLACE** Walk around and into your polyhedron: from inside, the culled faces vanish. Which faces does the body owe you?
- **Planted bug** one face wound the wrong way: a hole that exists only from outside.
- **Godot** ArrayMesh.add_surface_from_arrays; PackedVector3Array + PackedInt32Array; SphereMesh.radial_segments / rings; Performance monitors, Profiler
- **Lineage** Processing: Learning Processing ch 14 vertex shapes (pyramid, cube). NoC: none. Application: polycount against smooth deformation. Klee: I.4 medial lines close into planes (Klee never builds a solid). Reference: Gaboury, Image Objects ch 1 (culling) and ch 3 (the teapot); Catlike Coding 'Procedural Meshes' (construction as an axis).
- **Departure** Primitives (1) after fields: the student has used SurfaceTool on a terrain (c10) and now closes a body by hand, which the spine does first.
- **Project step** A hand-built polyhedron joins your hall, with its triangle count on the label.

#### c18. A body of parts: joints and pivots

*Spine:* transformation (2), randomness (10). *Halls:* Trans_Body (carrier), Trans_Rotation (carrier), Trans_Scale (encounter), Random_Rotate_Random_XYZ (field trip). *Tracks:* long.

- **CODE** new: basis, interpolation; returns: transforms, composition, meshes, classes, export, delta
- **BODY** Klee's body book in code: a limb of bones as nested Node3Ds, each turning about its own joint by a Basis, moved between two poses by lerp and Tween; face_up() from c07 is opened (the die's up vector is a basis column).
- **ARGUMENT** axis: joints in one limb, each bent by the same total angle; values: 1 / 2 / 4 / 8.
  - Predict first: 4 and 8 look most alike: both read as a curve; 1 is a stick and 2 an elbow.
  - Claim: A curve can be made from enough straight bones: bending is a count of joints.
- **DEBT** Bending by joints is another polycount: few joints look broken, many cost. Euler angles lie: random Euler angles are not uniformly random orientations (Random_Rotate_Random_XYZ shows the clumping at the poles).
- **PLACE** Become it: the limb is attached to your walker and follows you; Trans_Body's approach wall opens as you arrive.
- **Planted bug** the rotation applied to the parent instead of the part: the whole body turns; read the tree.
- **Godot** Basis(axis, angle); Transform3D; rotate_object_local; lerp; Tween; a pivot as a parent offset
- **Lineage** Processing: Learning Processing ch 14 (rotate, push/pop). NoC: NoC 3.1-3.2 (angles, angular motion). Application: topology and deformation. Klee: I.9 bone, ligament, tendon, muscle. Reference: Bellmer's dolls (the jointed body as a proposition); Kandinsky's analytical drawing (reduce a body to its skeleton).
- **Departure** Transformation (2) after the point chapters, as in the spine, but after chance: the student already has bodies to joint.
- **Project step** A jointed body (or your scan with pivots) moves between two poses in your hall.

#### c19. Colour as a rule

*Spine:* color (4). *Halls:* Color_Context_Placed (carrier), Color_Rainbow (carrier), Color_Grid_Pallet (field trip), Color_Walls (encounter). *Tracks:* long.

- **CODE** new: materials, dictionaries; returns: loops, interpolation, export, classes, random, arrays
- **BODY** A stack of bodies coloured by a rule: a const Dictionary of palettes and an @export_enum rule, each part given its own StandardMaterial3D with Color.from_hsv from code.
- **ARGUMENT** axis: rule (chroma_stack's declared axis); values: one / by_shape / by_height / by_neighbour / composed.
  - Predict first: 'by_height' and 'composed' look most alike on a tall stack: height dominates a composed rule once parts are stacked. 'one' is the reference.
  - Claim: Colour is a rule over positions before it is a pigment: the same stack under five rules is five bodies.
- **DEBT** lerp in RGB passes through grey; HSV is also a model with its own lie (perceived lightness is not V). Albers: a colour has many faces, and 'by_neighbour' makes that a rule.
- **PLACE** Walk around the stack under the room's light: which rule survives the shade?
- **Planted bug** one material shared by all parts: colouring one colours all.
- **Godot** StandardMaterial3D.new(); Color.from_hsv; const Dictionary; @export_enum; material.duplicate() against a shared material
- **Lineage** Processing: Learning Processing ch 1 (RGB); Handbook 'Color 1'. NoC: none. Application: none (colour is Klee's end). Klee: IV.39-43 chromatic energy (first visit; energy returns with shaders). Reference: Albers, Interaction of Color ('make two colours look alike' is the prediction as assignment); Levin and Brain exercise 'Color'.
- **Departure** Colour (spine 4) after transformation as in the spine, but after chance: c01-c03 already used colour as a value. Klee's colour as energy returns with shaders (c26).
- **Project step** Your hall's bodies take colour from a rule you can name.

#### c20. Repetition is structure: tiling and symmetry

*Spine:* tiling (5), array_tutorial (3). *Halls:* Symmetry_Seventeen (carrier), Pattern_Foundry (carrier), Tutorial_Tiling_Floor (encounter), Ribbon_Patterns_03 (field trip). *Tracks:* long.

- **CODE** new: uv, json; returns: arrays, nested_loops, materials, dictionaries, save_load, files, random, seeds
- **BODY** A seeded random 4 x 4 source written into an Image pixel by pixel and repeated across a floor by UV; get_color(x, y) rules (wrap, mirror, glide, quarter-turn) make symmetry groups from one source; the recipe saved as JSON.
- **ARGUMENT** axis: symmetry rule applied to one random tile; values: p1 (wrap) / pm (mirror) / pg (glide) / p4 (quarter-turn).
  - Predict first: pm and pg look most alike: both reflect, and the glide only shifts every other reflected row by half a tile. p1 shows the tile's randomness unframed.
  - Claim: A symmetry rule turns chance into ornament: the same random tile is disorder under wrap and pattern under mirror.
- **DEBT** The seventeen wallpaper groups are a complete classification, a closed list: what does a complete list leave out (the exception, the mad branch)? Texture filtering (nearest or linear) decides whether the tile's pixels stay pixels. UV is a second coordinate system the body carries.
- **PLACE** Stand on your pattern: floor your hall with it, then walk Symmetry_Seventeen's census room.
- **Planted bug** the mirror rule uses x % 4 on negative coordinates: a seam at the origin.
- **Godot** Image.create + set_pixel; ImageTexture.create_from_image; uv1_scale; texture_filter; JSON.stringify / JSON.parse_string; FileAccess
- **Lineage** Processing: Processing Handbook 'Image 1'. NoC: none. Application: WP3 'pattern' (in name). Klee: I.5-I.7 structure as repetition; proportion. Reference: 10 PRINT ch 30 Regularity; Book of Shaders ch 9 Patterns; Recreating the Past, Pattern (Riley, Albers).
- **Departure** Tiling (5) as a deliberate return to regularity: in c03-c05 the grid framed chance; here symmetry frames it. The spine has it earlier; the course needs chance first to show what symmetry does to it.
- **Project step** Part III close: your hall's floor is your own tile under a rule, its recipe JSON beside the code.

### Part 4: Force: falling, standing, swinging

#### c21. Motion: your own integrator

*Spine:* forces (7), change (6). *Halls:* Vectors_Act3_FieldsAndMotion (carrier), VFM_05_Launch (carrier), VFM_03_Motion (encounter), Change_Intro (encounter). *Tracks:* long.

- **CODE** new: integration, forces; returns: vectors, delta, physics_bodies, lifecycle, arrays, packed_arrays
- **BODY** A thrown body moved by your own Euler integrator (velocity += acceleration * dt; position += velocity * dt) in a fixed-step _physics_process, its arc drawn, beside a RigidBody3D given the same start.
- **ARGUMENT** axis: timestep; values: 1/10 s / 1/30 s / 1/60 s / 1/120 s.
  - Predict first: 1/60 and 1/120 look most alike: the arcs overlap within a line width; 1/10 lands visibly off.
  - Claim: An integrator is an approximation whose error you can see as a drift from the true arc.
- **DEBT** The physics tick is a choice with consequences: the same stack settles differently at 60 and 90 Hz (Ada measured it). The engine's RigidBody is another integrator you do not see.
- **PLACE** Be thrown: VFM_05_Launch puts you on the arc (desktop, with a comfort setting).
- **Planted bug** position updated with the old velocity and velocity never updated: a straight line; compare with the RigidBody.
- **Godot** _physics_process; fixed-step accumulator; apply_central_force; RigidBody3D.gravity_scale; physics/common/physics_ticks_per_second
- **Lineage** Processing: Learning Processing ch 5 (gravity by hand, example_05_09). NoC: NoC 1.7-1.10 (motion 101) and NoC 2 Forces. Application: vectors (the application's arc text). Klee: III.28-30 the bullet fired steeply rises and falls. Reference: Sebastian Lague's failure-first narration; Catlike Coding 'Measuring Performance'.
- **Departure** Forces (spine 7) after chance and noise (10-11): those moved earlier (c02-c14), so Part IV sits later than the spine's middle. Inside Part IV the spine's order holds (forces, formfinding, waves).
- **Project step** A thrown body arcs across your hall on your own integrator.

#### c22. Bodies born and dying: particles

*Spine:* forces (7), color (4), randomness (10). *Halls:* Vectors_Act3_FieldsAndMotion (carrier), Color_Rainbow (field trip), Random_Game (encounter). *Tracks:* long.

- **CODE** new: particles, instancing, lifetime; returns: integration, forces, random, seeds, arrays, classes, export
- **BODY** A fountain of your own bodies: a PackedScene instanced by an emitter, each copy with a lifespan, moved by c21's integrator and freed when it dies (iterate backwards); then the same fountain as a GPUParticles3D.
- **ARGUMENT** axis: spread of the initial direction; values: 0 deg / 5 deg / 20 deg / 45 deg / 90 deg.
  - Predict first: 0 and 5 degrees look most alike: both read as one jet; 45 and 90 read as a spray and a burst.
  - Claim: A fountain's body is its spread: the particles are the same, and the chance in their start decides the shape.
- **DEBT** Particles are the 'juice' of games: bodies made to die. Dead nodes must be freed or they cost; the GPU version is faster and cannot be touched one by one. WP1 names particle systems and the spine has no hall for them.
- **PLACE** Stand in the fountain; on the headset, hold the emitter (the pickup from c15).
- **Planted bug** removing dead particles while iterating forward: every other one survives.
- **Godot** PackedScene.instantiate(); add_child; queue_free(); lifespan counter; GPUParticles3D; ParticleProcessMaterial
- **Lineage** Processing: Processing Handbook 'Motion 2: Machine, Organism'. NoC: NoC 4 Particle Systems. Application: WP1 particle systems. Klee: IV.37-38 the arrow (the wish to extend one's reach). Reference: NoC 4 (emitter, lifespan, isDead); Levin and Brain 'Virtual Creature'.
- **Departure** An addition with no spine hall: WP1 lists particle systems and the spine has none. It sits after motion, as NoC puts it after forces.
- **Project step** A fountain of your bodies in your hall.

#### c23. Force as a place: open the walker

*Spine:* forces (7). *Halls:* Vectors_Act5_ForceAsPlace (carrier), Vectors_Act4a_KineticForces (carrier), VFM_08_Arena (field trip). *Tracks:* long.

- **CODE** new: player, areas, camera; returns: forces, integration, physics_bodies, collision, signals, composition, xr, input
- **BODY** The supplied walker opened: a CharacterBody3D (the controller), its skin (a body you made) and its head (a Camera3D), composed as three nodes. An Area3D replaces gravity with an @export acceleration for any body inside it, you included.
- **ARGUMENT** axis: law (force_field_zone's declared axis); values: gravity / lift / crossing / weightless.
  - Predict first: 'lift' and 'weightless' look most alike in a still of dropped bodies: both hold bodies up, and only a second still two seconds later tells floating from rising.
  - Claim: A force can be a place: the same body falls, floats or crosses depending on the room it stands in.
- **DEBT** The player body is a capsule, the default body of games: who is 1.8 m tall and without a shape? Skin against controller: what you look like is not what collides. Chun's 'sourcery': opening the walker's source does not reveal everything, the engine's C++ stays below.
- **PLACE** Walk into the zone and become the body its law acts on; on the headset the XR body replaces the desktop capsule (skin kept, controller swapped).
- **Planted bug** the Area3D's collision mask misses the player's layer: the zone ignores you; read the layers.
- **Godot** CharacterBody3D.move_and_slide(); velocity; Camera3D; Area3D body_entered / body_exited; gravity_space_override; XROrigin3D (supplied)
- **Lineage** Processing: Learning Processing ch 3 Interaction. NoC: NoC 2 (forces as environment: the Liquid). Application: the VR body. Klee: II.21 the tightrope walker is the scale. Reference: GDQuest 3D module 7 'skin vs controller'; Godot 'Your first 3D game' parts 2-3; Bagnall in Queer Game Studies (hardware normativity).
- **Departure** The player, supplied since c01, is opened here at forces, as the Brief proposes: one body among others, its parts named and swappable.
- **Project step** Your hall gets a room with its own law, and your own skin walks it.

#### c24. Standing despite falling: balance

*Spine:* formfinding (8), forces (7). *Halls:* FormFinding_Equilibrium (carrier), FormFinding_Forge (carrier), VFM_09_Legs (field trip), FormFinding_Relaxation (encounter). *Tracks:* long.

- **CODE** new: testing; returns: physics_bodies, forces, integration, classes, export, signals
- **BODY** A stack or mobile of your bodies with moved centres of mass; before each run the student writes 'tip' or 'hold', and a headless check proves it at two physics rates.
- **ARGUMENT** axis: centre-of-mass offset, as a share of the base's half-width; values: 0 / 0.25 / 0.5 / 0.75.
  - Predict first: 0 and 0.25 look most alike after three seconds: both stand. 0.75 has fallen; 0.5 is the edge where the physics rate decides.
  - Claim: To stand despite every possibility of falling is a margin: past half the base, the body's fate belongs to the solver.
- **DEBT** A settle test depends on the physics rate (a die read 15/16 at 90 Hz and 2/16 at 60 Hz in Ada): 'it stands' is a fact about a solver as much as a body. Symmetric balance is one kind; Klee's key word is non-symmetrical balance.
- **PLACE** Stand on it: FormFinding_Forge's stacking puzzle, a tower you can climb.
- **Planted bug** the check reads the result before the bodies sleep: it always says 'stands'.
- **Godot** RigidBody3D.center_of_mass_mode / center_of_mass; sleeping; a headless SceneTree script; assert(); physics_ticks_per_second at 60 and 90
- **Lineage** Processing: none. NoC: NoC 6 Physics Libraries (2012 ch 5). Application: formfinding (no work package). Klee: II.23-25 non-symmetrical balance; III 'to stand despite all possibilities to fall'. Reference: Moholy-Nagy's balance studies (Vorkurs); Montfort's Essential Concepts as checks.
- **Departure** Formfinding (8) in its spine place inside Part IV, later in absolute terms because chance and noise moved ahead. Klee's order agrees: balance (II) comes before the pendulum (IV), which is c25.
- **Project step** A balanced (or deliberately falling) body in your hall, with its test beside it.

#### c25. Pendulum, circle, spiral, note

*Spine:* wavefunctions (9), fractals (14). *Halls:* WaveFunctions_Pendulum (carrier), WaveFunctions_Unit_Circle (carrier), Wavefunctions_Sky_Stairs (carrier), WaveFunctions_Effect_Sound (carrier), WaveFunctions_John_Cage (field trip), Fractal_GoldenSpiral (encounter). *Tracks:* long.

- **CODE** new: audio, timers; returns: trig, delta, integration, packed_arrays, random, surface_tool, collision
- **BODY** Klee's derivation in code: a pendulum (oscillation) freed from gravity into a circle (sin and cos over a full turn) whose radius grows into a spiral staircase you can climb; the angle sounds as a note rendered sample by sample.
- **ARGUMENT** axis: radius growth per turn; values: -0.2 / 0.0 / 0.1 / 0.3.
  - Predict first: 0.0 and 0.1 look most alike from above: a slow spiral reads as a circle until you count the turns. -0.2 closes to the centre (Klee: death), 0.3 opens (life).
  - Claim: A circle is a spiral that stopped growing: one number turns a closed form into a stair up or down.
- **DEBT** Sampling: a sine at 44.1 kHz is a list of numbers, and a frequency above half of that folds back (aliasing). John Cage's chance operations bring chance back as a way of composing, not a lack of choice.
- **PLACE** Climb the spiral stair (Wavefunctions_Sky_Stairs) and hear the pitch rise with the radius.
- **Planted bug** the audio buffer filled once in _ready: the note plays once and stops, because the generator needs feeding.
- **Godot** sin / cos; AudioStreamWAV + PackedByteArray.encode_s16; AudioStreamGenerator; AudioStreamPlayer3D; Timer.timeout
- **Lineage** Processing: Learning Processing ch 13 (oscillation, wave). NoC: NoC 3 Oscillation (amplitude, period, the pendulum). Application: WP1 sine curves, resonance, sound; WP2 Fourier (WaveFunctions_Synthesis_Lab). Klee: IV.33-36 top, pendulum, circle, spiral (life or death), in the verified order. Reference: Klee, Pedagogical Sketchbook IV; Cage; Levin and Brain 'Synesthetic Instrument'.
- **Departure** Wavefunctions (9) keep their spine place after formfinding; cos and sin were met in c13 as direction, so this is their full return as oscillation, with sound (WP1) and Klee IV's derivation.
- **Project step** Part IV close: your hall has a sounding stair a visitor can climb.

### Part 5: Growth: rules that grow

#### c26. A rule for every pixel: shaders

*Spine:* shaders (12), noise (11). *Halls:* Shader_01_Shaping (carrier), Shader_05_Patterns (carrier), Shader_09_FBM (carrier), Shader_11_QueerRubber (field trip), Noise_Inside_Noise (encounter). *Tracks:* long.

- **CODE** new: shaders, uniforms; returns: noise, uv, materials, export, trig, ai_assist
- **BODY** Your noise floor moved to the GPU: a spatial shader whose vertex() displaces a subdivided plane by fBm and whose fragment() colours it by height, with uniforms set from GDScript.
- **ARGUMENT** axis: domain-warp amount (noise fed by noise); values: 0 / 0.5 / 1 / 2.
  - Predict first: 0 and 0.5 look most alike: a small warp bends the blobs without changing their kind. At 2 the field folds into marbled streaks.
  - Claim: Warping noise by noise keeps the generator and changes the body's kind.
- **DEBT** The shader moves what you see, not what holds you: a StaticBody laid over the displaced plane stays flat (c04 again). Every pixel runs one program at once and cannot ask its neighbour: a shader is fast because it forgets. For AI-written shaders, say what must not change (uniform names and ranges) and test at both ends of each range.
- **PLACE** Walk on the GPU floor and find where your feet and the surface disagree.
- **Planted bug** the uniform set from GDScript under a misspelled name: nothing changes and nothing complains.
- **Godot** ShaderMaterial; shader_type spatial; vertex() / fragment(); uniform float ... : hint_range; set_shader_parameter(); TIME
- **Lineage** Processing: Processing Handbook 'Render Techniques'. NoC: none. Application: WP3 shading algorithms. Klee: IV.39-43 chromatic energy (colour as energy, the return). Reference: Book of Shaders ch 5-13 (Ada's Shader halls map onto them); Inigo Quilez on fBm and domain warping.
- **Departure** Shaders (spine 12) after the forces part: the GPU's model (every pixel at once) is easiest after the same noise has run on the CPU (c09-c12), and the application groups shading with world building (WP3).
- **Project step** Your hall's floor or a wall runs on a shader of your own.

#### c27. Rules over neighbours: cellular automata

*Spine:* cellularautomata (13), softbodies (17), shaders (12). *Halls:* CA_Introduction (carrier), CA_GameOfLife (carrier), CA_SoftRules (field trip), ProceduralGeneration_Reaction_Diffusion_Systems (encounter), Shader_10_ReactionDiffusion (encounter). *Tracks:* long.

- **CODE** new: buffers; returns: arrays, booleans, conditions, nested_loops, multimesh, collision, packed_arrays, debugging
- **BODY** A 1D rule applied row after row, each row read from the old buffer into a new one and swapped. Each live cell of the history becomes collidable floor, so the rule's gaps are holes you fall through.
- **ARGUMENT** axis: rule (ca_bridge's declared axis); values: 30 / 90 / 110 / 250.
  - Predict first: 30 and 110 look most alike at a glance: both irregular textures. They part under a walk: 110 carries travelling structures, 30 stays chaotic. 90 is Sierpinski, 250 a regular checker.
  - Claim: Four eight-bit rules make four kinds of floor: order, fractal, chaos and something that carries structure.
- **DEBT** Writing into the buffer you are reading is the classic bug: the rule sees its own future. Wolfram's classes and the 'edge of chaos' are a classification that makes some behaviour 'interesting'. Turing's 1952 morphogenesis (reaction-diffusion, visited in CA_SoftRules) as a continuous rule over neighbours: the leopard's spots, and Turing's own body as the history the project carries.
- **PLACE** Walk the bridge: is rule 110's floor crossable end to end? (CA_GameOfLife)
- **Planted bug** one buffer updated in place: rule 90 drifts to one side.
- **Godot** PackedByteArray; two buffers and a swap; (rule >> n) & 1; MultiMesh; StaticBody3D per cell or one merged shape
- **Lineage** Processing: Learning Processing ch 13 (grid of cells). NoC: NoC 7 Cellular Automata. Application: WP2 cellular automata; WP3 reaction-diffusion. Klee: none. Reference: Langton's ant in Aesthetic Programming ch 5; Book of Shaders' planned 'Simulation' chapter.
- **Project step** A CA floor or wall grows through your hall.

#### c28. Rules that call themselves: recursion

*Spine:* fractals (14), formfinding (8). *Halls:* Fractal_Recursion (carrier), Fractal_RecursiveTrees (carrier), Fractal_MengerSponge (field trip), Fractal_CantorSet (encounter), FormFinding_Equilibrium (encounter). *Tracks:* long.

- **CODE** new: recursion, queues; returns: functions, parameters, return, transforms, basis, random, seeds, multimesh
- **BODY** A tree grown by a function that calls itself, branch(pos, dir, length, depth), with a base case; the same tree grown breadth-first from a queue of tips; one seeded 'mad branch' (Munari) breaks the rule.
- **ARGUMENT** axis: depth (fractal_recursion_2's declared axis); values: 1 / 2 / 4 / 6 / 7.
  - Predict first: 6 and 7 look most alike: the new branches at depth 7 are shorter than the room can show, the same limit as c10's octaves.
  - Claim: Recursion must be stopped, and past a few levels the stop is set by the eye, not by the rule.
- **DEBT** 'Recursion must always be controlled' (Queer 3D): without a base case the program never returns. The mad branch is the exception every family has (Munari); a rule that allows no exception is a norm.
- **PLACE** Stand under your tree; walk into the Menger sponge's holes (Fractal_MengerSponge).
- **Planted bug** the depth decrement is missing: 'Stack overflow (stack size: 1024)'.
- **Godot** a recursive func with a depth guard; Array as a queue (push_back / pop_front); MultiMesh for branches
- **Lineage** Processing: Processing Handbook 'Shape 3: Parameters, Recursion'. NoC: NoC 8 Fractals. Application: WP2 fractal subdivision; WP1 Fibonacci (visited in c25). Klee: I.7 proportion (2:3:5, the golden section). Reference: Munari, Drawing a Tree (1978); Kawaguchi's growth bodies (Queer 3D lineage).
- **Project step** A recursive body grows in your hall, one mad branch included.

#### c29. Grammars: a string grows a body

*Spine:* lsystems (15). *Halls:* LSystems_Grammar_Lab (carrier), LSystems_Growth (carrier), LSystems_Architecture (carrier), Assemblage_Same_Desire (field trip). *Tracks:* long.

- **CODE** new: strings, stacks; returns: recursion, dictionaries, loops, vectors, basis, collision
- **BODY** A string rewritten by rules (a Dictionary from symbol to replacement) and read by a turtle that draws; [ and ] push and pop the turtle's state on a stack; the same string read as corridors you can walk.
- **ARGUMENT** axis: grammar at depth 4 (lsystem_editor's declared axis); values: koch / dragon / plant / binary_tree / cantor.
  - Predict first: plant and binary_tree look most alike: both branch through [ and ]; koch and dragon are single lines that never branch.
  - Claim: A grammar is a body's genotype, and branching comes from one pair of symbols, [ and ].
- **DEBT** The string grows exponentially, so a symbol budget is the grammar's control (recursion by another name). The turtle is Logo, Papert's teaching body, and Klee's walking point again: whose walk does the grammar write?
- **PLACE** Walk the grammar: LSystems_Architecture turns turtle centrelines into corridors. Is your plant a place?
- **Planted bug** the string expanded in place while it is being read: the loop never ends; cap it with a budget.
- **Godot** String; for c in s; Dictionary.get(c, c); Array as a stack (push_back / pop_back); ImmediateMesh
- **Lineage** Processing: none. NoC: NoC 8.6 L-systems. Application: WP2 L-systems. Klee: I.1 the walking point, handed to a grammar. Reference: Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants; GDQuest's turtle, declared a teaching tool.
- **Project step** A grammar body or corridor in your hall.

#### c30. Navigate a generated world: a maze is a graph

*Spine:* proceduralgeneration (16), graphtheory (22). *Halls:* PG_Caves_Mazes (carrier), GT_Pathfinding (carrier), GT_Spanning_Trees (field trip), GT_Foundations (encounter). *Tracks:* long.

- **CODE** new: graphs, search, navigation; returns: queues, stacks, recursion, random, seeds, nested_loops, dictionaries, collision, player
- **BODY** A maze carved from a grid graph by a seeded algorithm, then searched: breadth-first from a queue shows the shortest route; a NavigationMesh baked over it sends an agent with your player's radius through.
- **ARGUMENT** axis: carving hand (maze_generation's declared axis); values: backtracker / prim / binary_tree / sidewinder.
  - Predict first: binary_tree and sidewinder look most alike: both leave long straight corridors along the edges they favour. The backtracker makes long winding passages, prim many short dead ends.
  - Claim: Every maze algorithm has a hand you can see: a 'random' maze is biased by how it is carved.
- **DEBT** A route in the array is not a route for a body: the graph ignores width (the survey hook for PG_Caves_Mazes). WP3 asks 'How do we navigate an auto-generated world?': who is the world generated for, and whose body fits its corridors?
- **PLACE** Walk the maze and race the agent to the exit.
- **Planted bug** cells marked visited when popped instead of when pushed: the search floods the maze.
- **Godot** adjacency in a Dictionary; BFS with a queue; AStar3D; NavigationRegion3D + NavigationMesh bake; NavigationAgent3D
- **Lineage** Processing: Learning Processing ch 10 Algorithms. NoC: NoC 5 (path following). Application: WP3 graph theory, procedural generation. Klee: II.15 railroad tracks (the path cut for the eye). Reference: 10 PRINT 'Maze Walker'; Montfort 'Navigable Generated Landscape'; Lague 'Procedural Cave Generation'.
- **Departure** Graph theory (spine 22) pulled forward into procedural generation (16): the maze is a graph the student already made, and the application asks its navigation question in WP3 together with procedural generation.
- **Project step** Part V close: a generated maze wing in your hall with a route the check guarantees.

### Part 6: Worlds and the crisis

#### c31. The body that gives: soft bodies

*Spine:* softbodies (17), formfinding (8). *Halls:* SoftBodies_Soft_Body_Deformation (carrier), SoftBodies_Obsticals (carrier), Topology_Entropy_Morphogenesis (carrier), FormFinding_Relaxation (field trip), SoftBodies_Playground_of_Joy (encounter). *Tracks:* long.

- **CODE** new: setters; returns: physics_bodies, export, classes, integration, import_assets, profiling, interpolation
- **BODY** A soft body from a subdivided mesh (SoftBody3D), pinned at two points, with one @export softness whose setter moves stiffness, damping and pressure together; then your scan from c08 made soft.
- **ARGUMENT** axis: subdivisions of the soft mesh; values: 2 / 4 / 8 / 16.
  - Predict first: 8 and 16 look most alike at rest; they part only when pressed (16 dents locally, 8 bends as a whole). 2 folds like a box.
  - Claim: A soft body can only bend where it has vertices: deformation is paid in polycount.
- **DEBT** The application's trade-off in its plainest form: a scanned body of thousands of triangles makes the solver crawl, and decimated it bends like a sack. Softness as affect (SoftBodies_Affect_Theory_Visualization): what does a body that yields teach against the rigid default?
- **PLACE** Squeeze through: SoftBodies_Obsticals' breathing room narrows below your width.
- **Planted bug** the setter rebuilds before the node is ready: an error on a null instance when the value is set from the Inspector.
- **Godot** SoftBody3D; simulation_precision; set_point_pinned; pressure_coefficient, damping_coefficient; @export var softness: float: set = _set_softness
- **Lineage** Processing: none. NoC: NoC course week on soft-body physics (S23 syllabus). Application: WP2 soft body simulation (cloth, liquids, rubber); 'the algorithmic topology of desire'. Klee: I.9 ligament and muscle. Reference: Queer 3D World on deformation and polygon count; Satterwhite and Perry (hybrid form).
- **Project step** A soft body (perhaps your scan) in your hall that visitors can press.

#### c32. Fusion: joining bodies by field and by verb

*Spine:* isosurfaces (18), boolean_surfaces (19). *Halls:* ISO_ImplicitModeling (carrier), ISO_LookupTable (carrier), Boolean_Verbs (carrier), Boolean_Works (field trip), ISO_TorusGyroid (encounter), ISO_Metaballs (encounter). *Tracks:* long.

- **CODE** new: raycasts; returns: noise, booleans, multimesh, surface_tool, normals, collision, player, import_assets
- **BODY** Two ways to join: metaballs meshed by marching cubes (the 256-case table supplied and read, not written) and the same bodies joined by CSG union; a shape cast tests whether a player-sized body can pass the neck.
- **ARGUMENT** axis: fusion (declared on both implicit_surface_modeling and csg_union_demo); values: distinct / necked / lobed / single.
  - Predict first: In the field version 'lobed' and 'single' look most alike, because the smooth join hides the seam; in the CSG version 'necked' and 'lobed' look most alike, because a union only seams and never blends.
  - Claim: A field blends where a verb seams: the blob look belongs to the method, not to the bodies.
- **DEBT** The smooth minimum is where the blob aesthetic comes from (Quilez): the 'organic' look of blob architecture is an operator. Code-critique station, after Marino's reading of Kittler's raytracer: read and annotate 30 lines of the supplied marching-cubes table. Who wrote it, what does it assume, what does it approximate? Klee's additive and subtractive making returns as union and difference.
- **PLACE** Walk through the neck if the cast says you fit; carve a burrow you can enter (Boolean_Works).
- **Planted bug** a CSG child animated every frame: the shape rebuilds each frame and frame time collapses; profile it.
- **Godot** PhysicsDirectSpaceState3D.intersect_ray / cast_motion; ShapeCast3D; CSGCombiner3D, CSGSphere3D, CSGMesh3D (your scan); use_collision
- **Lineage** Processing: none. NoC: none. Application: queer meshes; topology. Klee: I.11-I.12 additive building against subtractive cutting. Reference: Marino, Critical Code Studies ch 6 (Kittler's code); Gehry and Hadid (blob architecture, Queer 3D lineage); Lague 'Marching Cubes'.
- **Project step** A fused body in your hall, with a passage you can prove you fit through.

#### c33. Many that move as one: agents and swarms

*Spine:* swarmintelligence (20), randomness (10). *Halls:* SwarmIntelligence_Boids_Algorithm (carrier), SwarmIntelligence_PhysarumColony (carrier), Random_Pheromone (field trip), SwarmIntelligence_Swarm_Intelligence_Algorithms (encounter). *Tracks:* long.

- **CODE** new: inheritance, groups; returns: vectors, forces, multimesh, profiling, classes, random, buffers
- **BODY** A flock of your bodies: an Agent base class with steer(), subclasses Boid and Ant overriding it; separation, alignment and cohesion summed as forces; neighbours found by group.
- **ARGUMENT** axis: weights of the three rules; values: cohesion only / alignment only / separation only / all three equal / all three, alignment doubled.
  - Predict first: 'alignment only' and 'all three, alignment doubled' look most alike: both a stream of parallel bodies. Cohesion only is a clump, separation only an even scatter.
  - Claim: A flock's shape is a ratio of three rules, and no bird knows the shape.
- **DEBT** Emergence as an alibi: a crowd with no leader still has a designer (the weights). The all-pairs neighbour search is n squared (profile it at 50 and 500). Physarum is praised as 'intelligent' by the same metaphor that calls a carved maze 'random'.
- **PLACE** Stand in the flock: the boids avoid your body, and you become the obstacle they separate from.
- **Planted bug** the subclass's _ready overrides the parent's without super(): the agent never joins its group.
- **Godot** extends + super(); class_name base class; add_to_group / get_nodes_in_group; MultiMesh; Profiler
- **Lineage** Processing: Learning Processing ch 22 Advanced OOP (inheritance). NoC: NoC 5 Autonomous Agents (steering, flocking). Application: WP4 swarm intelligence, algorithmic life. Klee: none. Reference: Reynolds, Boids (1987); Lague 'Boids' and 'Slime Simulation'; NoC's Ecosystem Project.
- **Project step** A swarm lives in your hall, and a visitor is one of its obstacles.

#### c34. Bodies that learn: fitting, selection, bias

*Spine:* machinelearning (21), proceduralgeneration (16), postfoundationscrisis (25). *Halls:* ML_Neural_Networks (carrier), ML_Evolution (carrier), ML_Classification (field trip), PG_Genetic_Evolution (encounter), CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter). *Tracks:* long.

- **CODE** new: await; returns: classes, export, arrays, packed_arrays, random, seeds, resources, timers, ai_assist
- **BODY** A tiny network trained in batches spread over frames (await), each weight shown as a cylinder's thickness and colour; beside it a population of your bodies selected over generations, genomes saved as .tres recipes (c14).
- **ARGUMENT** axis: topology (neural_network_visualization's declared axis); values: graded / flat / deep / widened / pinched.
  - Predict first: 'deep' and 'graded' look most alike as bodies: both long chains of layers. 'pinched' is the telling one: a bottleneck every signal must pass.
  - Claim: A network's shape is an argument about what it must forget: the pinch decides what passes.
- **DEBT** Models are always biased (Queer 3D): the data sets what the model can see; after Sinders' Feminist Data Set, collect and label a tiny set of bodies before training anything. The LLM behind your AI assistant is a network of this kind at vast scale: which layers activate when you ask it for a 'body'?
- **PLACE** Walk through the network: layers are rooms, weights are bridges as wide as the weight.
- **Planted bug** training in one loop in _ready: the window freezes for seconds; spread it with await.
- **Godot** await get_tree().process_frame; Timer; PackedFloat32Array; a genome Resource
- **Lineage** Processing: none. NoC: NoC 9 Evolutionary Computing, NoC 10 Neural Networks. Application: WP3 neural networks, evolutionary algorithms; WP4 AI; Turing's B-type machines. Klee: none. Reference: Queer 3D World first principle 4 (ML models, how their layers are activated); Aesthetic Programming ch 10 Machine unlearning; Chun, Discriminating Data.
- **Project step** Checkpoint 3 (long track): plan the final project now, two units before the end, with a written plan and a flowchart of your hall.

#### c35. Impossible space: when the frame lies

*Spine:* foundationscrisis (23). *Halls:* Escher_Impossible (carrier), NonEuclidean_Spaces (carrier), Euclid_Parallel (field trip), Godel_Incompleteness (encounter). *Tracks:* long.

- **CODE** new: threads; returns: camera, shaders, uniforms, signals, transforms, await, search
- **BODY** An impossible body, an Escher stair or Penrose triangle that closes only from one standpoint (the camera's), and a curved room whose warp is a vertex-shader uniform; a proof search run on a worker thread with a budget and a cancel.
- **ARGUMENT** axis: seam (escher_staircase's declared axis); values: none / hairline / gap / scaffold / field.
  - Predict first: 'none' and 'hairline' look most alike from the locked standpoint: the seam shows only when you step aside.
  - Claim: An impossible body is a possible body seen from one place: the seam is the price of the illusion, and hiding it is a decision.
- **DEBT** Anamorphic bodies: a body argued from one standpoint is half blind (Ada found five of seven 'dead' axes alive from another angle). Godel and the halting problem: some searches cannot be known to end; a thread can be waited on, cancelled or budgeted, never predicted.
- **PLACE** Walk the impossible stair until the seam shows; enter the curved room.
- **Planted bug** a worker task never waited on: its resources are never released (Ada memory: 'a worker task must be WAITED to be released').
- **Godot** WorkerThreadPool.add_task / wait_for_task_completion; Thread; Camera3D.global_transform; a curvature uniform in vertex(); signal viewpoint_locked
- **Lineage** Processing: none. NoC: none. Application: WP4 non-euclidean spaces; the paradoxes (infinity). Klee: II.16-20 perspective as optical illusion ('logically right but psychologically wrong'). Reference: Escher, Reutersvard, Penrose (Queer 3D lineage); Gaboury on queer computing history and Turing.
- **Project step** One impossible element in your hall, with its standpoint marked on the floor.

#### c36. Entropy: chance returns as a measure

*Spine:* qfeplaboratory (24), randomness (10). *Halls:* QFEP_E_Term (carrier), QFEP_F_Term (carrier), Random_Entropy (carrier), QFEP_Edge_Of_Chaos (field trip), QFEP_Lambda_Spectrum (encounter). *Tracks:* long.

- **CODE** new: sorting; returns: random, seeds, arrays, dictionaries, multimesh, interpolation, buffers, noise
- **BODY** 200 seeded symbols as bodies, sorted in place by a tween (order out of disorder), with Shannon entropy computed from their counts before and after; the same measure applied to the bodies of Part I (the c03 grid, the c05 maze, the c11 threshold body).
- **ARGUMENT** axis: share of the sorted row shuffled back; values: 0% (sorted) / 10% / 50% / 100% (as drawn).
  - Predict first: 50% and 100% look most alike: after half the swaps a sorted row already reads as disorder. The entropy of the counts is the same in all four stills.
  - Claim: Sorting changes the arrangement and leaves the entropy of the counts untouched: the disorder you see is not the disorder the measure counts.
- **DEBT** QFEP's F to E is the project's own arc, and the measure is a model too: Shannon's entropy does not see the arrangement. Turing, Enigma and entropy; with Haraway and Ahmed, entropy can be read as resistance to an imposed order (Queer 3D).
- **PLACE** Walk the sorted row from order into the drawn end (QFEP_E_Term's fan).
- **Planted bug** log(0) for an empty bin: the entropy comes out nan; guard the zero count.
- **Godot** Array.sort / sort_custom; a Tween per instance; log(); Dictionary counts
- **Lineage** Processing: none. NoC: NoC 0 returns (distribution). Application: the arc toward entropy; Turing (Enigma). Klee: IV.43 the close: back to the dot of page one. Reference: QFEP (Ada's F to E); the Random_Definition kit's closing line (Random Entropy asks what remains when we count the values).
- **Departure** A deliberate return to Part I: randomness (spine 10) closes the course inside QFEP (24), so the first week's chance becomes the last month's measure.
- **Project step** Every body in your hall gets its entropy on its label.

#### c37. A round: the small complete game

*Spine:* postfoundationscrisis (25), randomness (10), noise (11). *Halls:* Random_Game (carrier), PostCrisis_Synthesis (carrier), CriticalAlgorithms_Applied_Ethics (field trip), SpeculativeComputation_Situated_Computation (encounter), Lab_Path (encounter). *Tracks:* long.

- **CODE** new: state_machines, ui; returns: player, input, camera, signals, instancing, physics_bodies, audio, save_load, export_build, xr, random, seeds, testing
- **BODY** Your hall becomes a round: start, play, win or lose, replay. A state machine of seeded stones that stand or sink (Random_Game), a HUD, a save that survives restarts, and a build shared on desktop and, by the headset route, on the Quest.
- **ARGUMENT** axis: how long a stone waits before sinking (same mean, 2 s); values: fixed 2 s / uniform 0.5-3.5 s / gaussian around 2 s / shorter each round.
  - Predict first: 'fixed' and 'gaussian' look most alike on a plotted timeline of one round: the bell keeps most waits near 2 s. The uniform range is the one players call unfair.
  - Claim: Fairness is a distribution: the same mean wait feels fair or cruel depending on its spread.
- **DEBT** Situated computation: whose body is this game for? (CriticalAlgorithms_Applied_Ethics' seating plans include the panopticon.) The win condition is a norm, and the seed decides who had an easy round. After the Critical Engineering Manifesto, find where your own game shows its seams.
- **PLACE** Play it, then let a classmate play it on their machine or the headset: the final showing.
- **Planted bug** the state set inside _process without a guard: 'lose' is entered every frame and its sound stutters.
- **Godot** enum + match (state machine); CanvasLayer, Control, Label, Button; ConfigFile or FileAccess save; change_scene_to_file; export presets (desktop, Android/Quest)
- **Lineage** Processing: Learning Processing ch 10 Algorithms (a game from parts). NoC: NoC Ecosystem Project (the exhibit). Application: hacker ethics: share, open, repair; Freire. Klee: none. Reference: Godot 'Your first 3D game' part 8 (score and replay); GDQuest 'The Final Challenge'; SFPC Code Societies (small scores as outcomes); Pixelles (a fixed public showing).
- **Project step** Final showing: your hall is a playable round in the endless museum, its argument sheets and ReadMe beside it.

## What this candidate learned from comparable courses

- The Nature of Code: randomness as chapter 0, then vectors, forces, oscillation, particles, agents, CA, fractals, evolution and networks. This course keeps that order for its first two parts and for Part IV, supplies the 'one semester of creative coding' NoC assumes inside the braid (c01-c08), and borrows the cumulative Ecosystem Project as 'your hall in the endless museum'.
- Queer 3D World (Palle, 2024): the first-principles order (randomness, simplex noise, loops and recursion, vectors and dimensionality, points, lines and grid, ML) sets Parts I-III; the three weeks, the scanning and Tilt Brush of week 1 and the closing mini project set the short track.
- The 2023 application: WP1 (randomness, Perlin, Voronoi, sine, sound, particles) is taught first and whole (c02-c13, c22, c25); the arc toward entropy closes the course (c36).
- 10 PRINT: 'Regularity before Randomness' is why the grid comes in the same week as chance (c03, c05) rather than after it; its Maze Walker is c05's place.
- Levin and Brain, Code as Creative Medium: their exercises put Unpredictability right after conditionals and before arrays, and c02-c05 follow that (arrays arrive in c06); the named body prompts (Parametric Object, Virtual Creature, Generative Landscape) name c04, c22 and c10.
- Aesthetic Programming: randomness at chapter 5 of 10, after loops and transforms, is the order this candidate deliberately rejects (it opens with chance). Kept: RunMe and ReadMe as body and argument, pause weeks, and a final project planned two units before the end (c34).
- Montfort, Exploratory Programming: errors in week one ('valid and intentional are different', c01-c03's planted bugs); 'Critique My Starter Programs' turned on Godot's template and capsule player as the first DEBT (c01).
- GDQuest, Learn GDScript From Zero: use before make (display.gd, face_up, the walker, all supplied and later opened), the first error as a lesson, and the game loop held back until the first body moves (c06).
- Processing Handbook: a synthesis closes each part (c08, c14, and the checkpoint steps of c20, c25, c30, c34); debugging gets a mid-course chapter, not an appendix (c11).
- Learning Processing's Zoog: one student body (make_body() from c04) rebuilt as each idea arrives.
- Catlike Coding: graph, then grid, then surface (c09 a row of columns plotting one function, c10 the grid, c12 a family of surfaces); hashing before noise is the model for c02-c03's seeded draws before c09's noise.
- Critical Code Studies: a code-critique station on Ada's own approximating code at the DEBT step, never at the opening (the marching-cubes table in c32, after Marino's reading of Kittler's raytracer). CCSWG 2024's 'describe X in a single class' becomes 'describe a body in a single class' (c12).
- Recreating the Past and the computer-art lineage (Molnar, Nake, Nees): the opening recreates the moment chance entered the Klee lineage, Nake's Hommage a Paul Klee (c02) and Nees's Schotter (c05).
- Klee's Pedagogical Sketchbook, in the verified order where it shapes the body: balance (II, c24) before pendulum, circle and spiral as one derivation (IV, c25), and colour last as energy (c26). The gravitational curve (III) opens Part IV as the thrown body (c21), where NoC's motion-first order is followed instead of Klee's.
- Albers: 'make two colours look alike' is the ancestor of the prediction; Munari's mad branch is c28's exception; Gaboury's Image Objects supplies the culling and default-body debts (c17).
- Anthropy and the queer game courses: share a build in week 1 (c08), and make before the tool (the scan is imported before the student has written a mesh by hand).
- What only Ada adds, and the course says so: no course found teaches geometry, the body and VR together with a critical layer, and none uses a falsifiable prediction plus a one-sentence claim as its critique format.

## Verified and recalled

[V] this session:
- Every hall named exists in spine.json (checked by c5_build.py); hall hooks and features from doc/book/iterations/claude-godot-path-2026-09-30/survey_bundle.json.
- Declared DNA axes used as arguments, from maps/ada.json carriers: voxelnoise threshold, noise_space and perlin_noise generator, simplex_noise octaves, sphere_high tessellation, chroma_stack rule, pattern_tile_4x4 motif, force_field_zone law, ca_bridge rule, fractal_recursion_2 depth, lsystem_editor grammar, maze_generation hand, implicit_surface_modeling and csg_union_demo fusion, neural_network_visualization topology, escher_staircase seam, distribution_sampler law, ten_print_textile odds.
- The Random_Definition kit's steps (seed, grid, pair, unused draw, channel roles), its supplied display.gd, and its note that Godot treats the generator's algorithm as an implementation detail (doc/book/studies/random-definition/README.md, TUTORIAL.md).
- Klee's section order (balance II, gravitational curve III, pendulum/circle/spiral IV, colour at the end), from maps/lineage.json and research_bauhaus.md.
- WP1 contents and the absence of a particle-system hall (maps/lineage.json application_packages); @export in 74% of Ada scripts (BRIEF.md); Queer 3D World's overflow table (QUEER3D_2024.txt l.1502-1504).
- Ada memory entries quoted in DEBT steps (from the auto-memory index): the die that read 15/16 at 90 Hz and 2/16 at 60 Hz; a typed set() refused in silence; a 1-arg signal on a 0-arg method is a dead button; a worker task must be waited to be released; Godot winds front faces clockwise; five of seven dead verdicts were anamorphic (CLAUDE.md).

[mem] recalled, not checked:
- That Godot's RandomNumberGenerator is PCG32 internally, and that a new generator starts from a time-based seed.
- That set_shader_parameter() with a misspelled name fails silently (c26's planted bug; test it before teaching).
- Perlin's noise dates (early 1980s, film textures); Reynolds 1987; Prusinkiewicz and Lindenmayer; Chun's Discriminating Data on homophily; photogrammetry's known blind spots (hair, dark or shiny surfaces, transparency).
- Predictions about existing works (chroma_stack 'by_height' vs 'composed', ca_bridge 30 vs 110, maze_generation's biases) are written as predictions to be proven wrong, not as facts about those works.

## What this order forecloses, and the dark spot

- **Foreclosed:** the student meets rng.randf() before they have built a body or a loop, so c02-c03 lean on a supplied display.gd; a teacher who dislikes supplied parts will find the first week heavier than the spine's Point Zero opening. Colour appears as a value in c01-c03 long before its chapter (c19). Forces and waves (spine 7-9) arrive about a third of the way into the year rather than in the first quarter.
- **Gained:** the first DEBT (computed chance) is visible on day two, the first test for AI-written code (c08: does the seed still return?) comes free with seeds, and entropy at the end closes a loop the student opened.
- **Dark spot:** 'chance first' can read as 'nature first', letting noise's blob look pass as the natural default before the student has the vocabulary to question it. c09-c12 name the blob aesthetic explicitly for that reason; whether naming is enough is untested. No chapter has been tried with a learner or on a headset.
