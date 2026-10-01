# Candidate c3: Form+Code for Bodies

*Course candidate `c3_form_code`, grown from one reference: Casey Reas, Chandler McWilliams and LUST, **Form+Code in Design, Art, and Architecture** (Princeton Architectural Press, 2010 [mem]; 176 pp. [V]). Written 2026-10-01 for the braid auto-research. JSON: `cand_c3_form_code.json` (same folder). Marks: [V] = checked today against a source; [mem] = from memory; [our placement] = a mapping this candidate makes that the anchor does not.*

## What the anchor is, and what it is not [V/mem]

Form+Code is a survey, not a course. Its body is five themes, each an essay, a gallery of works and two downloadable code examples [V formandcode.com, fetched 2026-10-01]:

| Theme | Code examples [V] | Here |
|---|---|---|
| (What is Code? / Form and Computers) [mem] | none | Part 1, Code and Form |
| Repeat | Embedded Iteration, Recursive Tree | Part 2 |
| Transform | Transcoded Landscape, Slit-Scan | Part 3 |
| Parameterize | Chair, Wave | Part 4 (no spine sequence; declared addition) |
| Visualize | Displaying Data, Superformula | Part 5 |
| Simulate | Particles, Diffusion-Limited Aggregation | Part 6 |

What the course takes from it is the **order of verbs**: what code does to a form, from making one, to repeating it, turning it, making it a family, making the invisible visible, to letting a process make it. The anchor has no exercises, no skill ladder and no critical layer, so those come from the comparable courses below and from Ada itself (the four strands, the three layers, the prediction). Where the anchor's verbs overlap (a recursive tree is Repeat *and* Simulate), the course follows the anchor's own filing and names the return.

## For the student: why this order

This course is ordered by what code does to form, not by the order of Ada's halls. First you learn what code is and make single bodies: a point, a line, a room you can stand in with the headset on. Then you REPEAT a body (a trace, a grid, a tile, disorder in the grid, a tree that repeats inside itself), TRANSFORM it (a pivot, a scale, an easing, time laid into space, a function turned into ground), PARAMETERIZE it (a class, a family in the Inspector, a budget you measure, genes saved as files), VISUALIZE what cannot be seen (a value as colour, a noise field, a shader, an implicit surface, a graph, a judgment), and finally SIMULATE it (forces, aggregation, balance, rules, soft bodies, swarms, navigation, learning) until the model meets what it cannot hold. Each verb needs the ones before it: disorder is invisible without a grid, a transform means most when there are many bodies, an argument about a family needs a class, and a simulation needs all of these. The Ada halls carry each step or are visited as field trips. Where this order leaves the spine's order the chapter says why, and where a topic comes back (chance, colour, recursion, graphs) it is a named return. In every chapter you build a body in code, vary it along one axis, write down before rendering which two variants will look most alike, and defend one sentence with the picture. Then you ask what the approximation owes or hides, and you take the body out of the lab into a place where a body meets it.

## Parts

**Code and Form (What is code? Form and computers)** (ch 1-6). You can make a single body in code, give it a collider that is a separate decision, place it by coordinates, relate two bodies with a function, bring in a scanned body, and stand among them in the headset from a build you exported.

**Repeat** (ch 7-12). You can make many bodies from one: a kept walk, a lattice, an authored surface, a tiled floor, a seeded disorder and a recursive tree, and you know that each repetition is decided by a gap, a rule, a seed or a stop.

**Transform** (ch 13-17). You can turn a body (pivots, scale, easing) and transcode one thing into another (time into space, a function into ground), and you have opened the player body itself as one transform among others.

**Parameterize (an addition to the spine, declared)** (ch 18-21). You can write a body as a class whose exported fields make a family, sweep one axis into a comparison sheet, measure what each value costs, test a claim, and save a body as a file that returns.

**Visualize** (ch 22-27). You can make an invisible value visible (colour, a noise field, a per-pixel shader, an implicit surface, a graph, a classifier) and say what each picture hides.

**Simulate** (ch 28-37). You can let bodies be made by processes (forces, aggregation, balance, rules, soft deformation, collectives, navigation, learning), assemble a small complete game, and end with a hall that argues and knows the limits of its own model.

## Tracks

### Three weeks: one family of bodies (Queer 3D World format)

- **Length:** 3 weeks, 15 days; week 1 Code and Form in the headset (ch 1, 3, 4, 5, 6); week 2 Repeat, Transform and Parameterize (ch 8, 11, 13, 18, 19, 23); week 3 from day 11 is the mini project, with ch36 as a guest critique session on day 13 and the showing on day 15
- **Chapters:** 1, 3, 4, 5, 6, 8, 11, 13, 18, 19, 23, 36
- **Project:** A PARAMETRIC BODY (prompts from Levin & Brain: Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic). One class with one exported axis and 3-5 values; a prediction written before rendering of which two will look most alike; the comparison still; one claim sentence; a debt comment in the code; the body placed in the class's shared hall where a visitor can stand on it, walk through it, carry it or become it; shown in the headset on the last day. Supplied and named because the short track skips their chapters: the base room with the desktop walker and the XR rig (commons/scenes/vr_staging.tscn); the Point Zero kit's _ready/_process template (ch2); the SKETCH helper point(p), line(a, b), box(p, size) and a Trace recorder (ch7); make_fan() returning an ArrayMesh (ch9); a MultiMesh floor builder (ch10); a heightfield-to-mesh-and-collider builder for the noise terrain (ch17); an Area3D trigger with its signal wired (ch15); a sweep_sheet scene that lays out five instances with labels [to be written for the course; Ada's build_dna_gallery.py is the adult version]; a scan-to-glb route (phone photogrammetry or Tilt Brush, then Blender). In the short track ch36 is a guest critique session, so its code (files, shaders, raycasts) is shown, not written.

### One year: the whole ladder (Palle's one-year course for professional artists)

- **Length:** About two terms of 15-16 weeks. Term 1: parts 1-4 (ch 1-21), with a pause week after each part and the midterm family sheet at ch21. Term 2: parts 5-6 (ch 22-37), with the final project planned at ch35 and shown at ch37.
- **Chapters:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
- **Project:** Midterm at ch21: the hall's family saved as files and shown as a sheet that a classmate can load and breed. Final at ch37: the student's hall in the class's endless museum (a family, its prediction, its comparison sheet, its claim, a debt comment in the code, a final.md), walked in the headset from an exported build.

Short track, day by day (a proposal): D1 Day Zero (ch1, unplugged LeWitt plus the base room); D2 Point One (ch3); D3 Coordinates (ch4); D4 Lines (ch5); D5 the collage room in the headset, exported and swapped with a classmate (ch6). D6 many bodies (ch8); D7 chance in the grid (ch11) plus the AI protocol; D8 a body of joints (ch13); D9 a body in a single class plus @export (ch18-19, the family sheet); D10 noise (ch23). D11-15 mini project, with D13 as ch36 given as a guest critique session (Code Societies' 'Critical Simulation' format) and D15 the showing in the headset. The pivot into the mini project happens at the start of week 3, as the research found every comparable short course does.

## The reading order (table of contents 1)

| n | Chapter | Part | Spine (order) | Code new | Argument axis | Departure | Tracks |
|---|---|---|---|---|---|---|---|
| 1 | What is code? An instruction someone else performs (Day Zero) | code_form | primitives (1) | statements, output, errors | how precise the written instruction is | - | short/long |
| 2 | Point Zero: the engine calls you | code_form | primitives (1) | variables, lifecycle, delta | frame rate the scene runs at (--fixed-fps) | - | long |
| 3 | Point One: a body is a node plus a mesh, and a collider that is not the mesh | code_form | primitives (1) | calling, meshes, collision | collider radius as a fraction of the visible radius (still taken with Debug > Visible Collision Shapes on and the supplied walker standing on top) | - | short/long |
| 4 | Point Coordinates: where is a body? Position, parent, pickup | code_form | primitives (1) | vectors, properties, transforms | parent offset, with the child's local position fixed (still over the floor grid) | - | short/long |
| 5 | Point Lines: a relation between two bodies | code_form | primitives (1) | expressions, functions, parameters | exponent p in thickness = 0.05 * length^p (three lines of 0.5, 1 and 2 m in each variant) | - | short/long |
| 6 | Synthesis 1: a collage room, where a scanned body meets coded bodies, in the headset | code_form | primitives (1) | import_assets, xr, export_build | decimation of the scanned mesh (share of triangles kept) | - | short/long |
| 7 | Point Trace: repeat in time, the walk kept | repeat | primitives (1) | arrays, conditions, booleans | distance gate for taking a sample (the same recorded walk replayed) | - | long |
| 8 | Embedded iteration: many bodies in a row, a grid, a lattice | repeat | primitives (1), array_tutorial (3) | loops, nested_loops, materials | gap between cells as a fraction of the cell size | declared | short/long |
| 9 | A triangle is a list: the first authored surface | repeat | primitives (1) | surface_tool, normals, return | how the normals are made (an 8-sided fan, same vertices) | - | long |
| 10 | Tiling: the tile and its rule (regularity) | repeat | array_tutorial (3), tiling (5) | uv, multimesh, audio | repeat rule (wallpaper operation) applied to the same 4x4 tile | declared | long |
| 11 | Chance 1: disorder in the grid | repeat | randomness (10), array_tutorial (3) | random, seeds, ai_assist | disorder amount (molnar_cube_study's 'amount') | declared | short/long |
| 12 | Recursive tree: repeat inside itself | repeat | fractals (14) | recursion, debugging | depth limit | declared | long |
| 13 | Pivot and order: a body of joints | transform | transformation (2) | basis, composition, instancing | pivot position along each limb segment (same joint angles) | declared | short/long |
| 14 | Scale: the room or the body? | transform | transformation (2) | player, input, camera | room scale with the body fixed (still: the capsule in front of the same door) | declared | long |
| 15 | Easing: between two states | transform | transformation (2) | interpolation, areas, signals | easing curve over the same two positions (a multiple-exposure still at 10 equal time steps) | declared | long |
| 16 | Slit-scan: the pendulum's time laid into space (pendulum, circle, spiral) | transform | wavefunctions (9) | trig, queues | radius growth per turn | declared | long |
| 17 | Transcoded landscape: a function becomes ground | transform | change (6), wavefunctions (9) | packed_arrays, physics_bodies | grid resolution (samples per metre) over the same function | declared | long |
| 18 | Describe a body in a single class | parameterize | primitives (1) | classes, methods, types | base_sides | declared | short/long |
| 19 | @export: the family in the Inspector | parameterize | primitives (1), color (4), softbodies (17), isosurfaces (18) | export, setters, tool_scripts | apex offset as a fraction of the base radius (Ada's apex_stance axis) | declared | short/long |
| 20 | The budget: polycount measured, a claim tested | parameterize | primitives (1), formfinding (8) | testing, profiling | u_steps of the catenoid | declared | long |
| 21 | Genes as files: a family saved, a body recalled | parameterize | proceduralgeneration (16), randomness (10), tiling (5) | dictionaries, resources, save_load | the limb_count gene | declared | long |
| 22 | Value to colour: the chroma stack | visualize | color (4) | ui, strings | ground colour behind one fixed grey block (Albers) | declared | long |
| 23 | Noise: a field you cannot see | visualize | noise (11), change (6), randomness (10) | noise | noise generator (same seed, frequency and octaves) | declared | short/long |
| 24 | A shader draws every pixel at once | visualize | shaders (12), tiling (5) | shaders, uniforms | fBm octaves (uniform int layers) | declared | long |
| 25 | Implicit bodies: the hidden field as a surface | visualize | isosurfaces (18), boolean_surfaces (19) | raycasts | fusion: the distance between two sources (the shared ISO/Boolean vocabulary) | declared | long |
| 26 | Visualize a relation: a graph laid out and searched | visualize | graphtheory (22) | graphs, search, await | layout rule for the same graph | declared | long |
| 27 | Visualize a judgment: classification and its bias | visualize | machinelearning (21), postfoundationscrisis (25) | sorting, json | k (neighbours consulted) | declared | long |
| 28 | Forces: your own integrator | simulate | forces (7) | forces, integration | integration step on a damped spring (trail still) | declared | long |
| 29 | Particles and aggregation: many short lives build one body | simulate | randomness (10), proceduralgeneration (16), softbodies (17) | particles, lifetime | stickiness (probability of freezing on contact) | declared | long |
| 30 | Balance: form found by force, and a first complete game | simulate | formfinding (8) | state_machines, groups | top stone's centre-of-mass offset as a fraction of its half-width (still after 3 s) | declared | long |
| 31 | Rules that grow: automata and grammars | simulate | cellularautomata (13), lsystems (15), fractals (14) | buffers, stacks | elementary rule number | declared | long |
| 32 | Soft bodies: polycount against deformation | simulate | softbodies (17) | timers | subdivisions of the jelly (still taken while it is struck) | declared | long |
| 33 | Collective bodies: flocks and swarms | simulate | swarmintelligence (20) | inheritance | separation weight | declared | long |
| 34 | Navigate a generated world | simulate | proceduralgeneration (16), graphtheory (22), lsystems (15) | navigation | maze algorithm on the same grid | declared | long |
| 35 | Bodies that learn | simulate | machinelearning (21) | threads | selection pressure | declared | long |
| 36 | Critical simulation: what the model cannot hold | simulate | foundationscrisis (23), qfeplaboratory (24), postfoundationscrisis (25) | files | curvature of the triangle's space | - | short/long |
| 37 | Synthesis: your hall in the endless museum | simulate | qfeplaboratory (24), postfoundationscrisis (25) | (none: synthesis) | the student's own family axis (one exported field of their hall's main body) | - | long |

## The spine index (table of contents 2, after the Processing Handbook's two TOCs)

Each spine sequence, and the chapters that draw on it. A jump in the numbers is a departure, and every one is explained in its chapter.

| Spine | Sequence | Chapters | Halls used |
|---|---|---|---|
| 1 | primitives | 1, 2, 3, 4, 5, 6, 7, 8, 9, 18, 19, 20 | 12 of 12: Point_Animatedcube, Point_Coordinates, Point_Line_Grid, Point_Lines, Point_One, Point_Trace, Point_Triangle_Context, Point_Zero, Primitives_Ignorance, Primitives_Melencolia, Primitives_Polythedra, Primitives_Portals |
| 2 | transformation | 13, 14, 15 | 6 of 7: Trans_Body, Trans_Introduction, Trans_Pit, Trans_Pre, Trans_Rotation, Trans_Scale |
| 3 | array_tutorial | 8, 10, 11 | 4 of 5: Array, Tutorial_3D, Tutorial_Disco, Tutorial_Tiling_Floor |
| 4 | color | 19, 22 | 5 of 8: Color_Context_Placed, Color_Nails, Color_Pillar, Color_Rainbow, Color_Walls |
| 5 | tiling | 10, 21, 24 | 3 of 8: Pattern_Foundry, Symmetry_Seventeen, Tutorial_Pattern |
| 6 | change | 17, 23 | 2 of 2: Change_Intro, Flow_Field |
| 7 | forces | 28 | 7 of 13: VFM_03_Motion, VFM_05_Launch, VFM_09_Legs, Vectors_Act1_WhatAVectorIs, Vectors_Act3_FieldsAndMotion, Vectors_Act4b_Oscillation, Vectors_Act5_ForceAsPlace |
| 8 | formfinding | 20, 30 | 4 of 6: FormFinding_Catenary, FormFinding_Equilibrium, FormFinding_Forge, FormFinding_Relaxation |
| 9 | wavefunctions | 16, 17 | 7 of 12: WaveFunctions_Effect_Sound, WaveFunctions_Pendulum, WaveFunctions_Sine_Space, WaveFunctions_Synthesis_Lab, WaveFunctions_Unit_Circle, Wavefunctions_Bernini, Wavefunctions_Sky_Stairs |
| 10 | randomness | 11, 21, 23, 29 | 8 of 14: Random_Definition, Random_Game, Random_Gaussian, Random_Pheromone, Random_Remove, Random_Space_Geometry, Random_Walk, Randomness_10_PRINT_Algorithm |
| 11 | noise | 23 | 3 of 9: Noise_Columns, Noise_Perlin_Simplex, Noise_Space_10 |
| 12 | shaders | 24 | 5 of 6: Shader_01_Shaping, Shader_05_Patterns, Shader_09_FBM, Shader_10_ReactionDiffusion, Shader_11_QueerRubber |
| 13 | cellularautomata | 31 | 3 of 8: CA_AgentsCircuits, CA_GameOfLife, CA_Introduction |
| 14 | fractals | 12, 31 | 4 of 7: Fractal_GoldenSpiral, Fractal_KochSierpinski, Fractal_Recursion, Fractal_RecursiveTrees |
| 15 | lsystems | 31, 34 | 4 of 8: LSystems_Architecture, LSystems_Grammar_Lab, LSystems_Growth, LSystems_Living |
| 16 | proceduralgeneration | 21, 29, 34 | 3 of 7: PG_Caves_Mazes, PG_Genetic_Evolution, PG_Sculpted_Forms |
| 17 | softbodies | 19, 29, 32 | 6 of 9: ProceduralGeneration_Reaction_Diffusion_Systems, SoftBodies_Affect_Theory_Visualization, SoftBodies_Cloth_Physics, SoftBodies_Playground_of_Joy, SoftBodies_Soft_Body_Deformation, Topology_Entropy_Morphogenesis |
| 18 | isosurfaces | 19, 25 | 4 of 13: ISO_Introduction, ISO_LookupTable, ISO_Metaballs, ISO_TorusGyroid |
| 19 | boolean_surfaces | 25 | 1 of 3: Boolean_Verbs |
| 20 | swarmintelligence | 33 | 3 of 7: SwarmIntelligence_Boids_Algorithm, SwarmIntelligence_PhysarumColony, SwarmIntelligence_Swarm_Intelligence_Algorithms |
| 21 | machinelearning | 27, 35 | 5 of 8: ML_Classification, ML_Evolution, ML_Gradient_Landscape, ML_Neural_Networks, ML_Perception |
| 22 | graphtheory | 26, 34 | 5 of 8: GT_Foundations, GT_Layout, GT_Network_Analysis, GT_Pathfinding, GT_Spanning_Trees |
| 23 | foundationscrisis | 36 | 4 of 8: Crisis_Synthesis, Escher_Impossible, Godel_Incompleteness, NonEuclidean_Spaces |
| 24 | qfeplaboratory | 36, 37 | 3 of 8: QFEP_Edge_Of_Chaos, QFEP_Sandbox, QFEP_Synthesis |
| 25 | postfoundationscrisis | 27, 36, 37 | 4 of 8: CriticalAlgorithms_Algorithmic_Bias_Visualization, CriticalAlgorithms_Applied_Ethics, PostCrisis_Synthesis, SpeculativeComputation_Rhizome_Network |

## Chapters

### Code and Form (What is code? Form and computers)

#### 1. What is code? An instruction someone else performs (Day Zero)

- **Spine:** primitives. **Halls:** Point_Zero (field trip).
- **CODE:** new statements, output, errors; returns none.
- **BODY:** The base room rebuilt from an empty scene (floor, camera, light, WorldEnvironment) plus a Label3D that prints its own text. Unplugged first: a written instruction for one body ('a cube, 1 m, one corner on the floor's centre') carried out on paper by a partner, as in a LeWitt wall drawing.
- **ARGUMENT:** axis *how precise the written instruction is*, values one word / one sentence / numbered steps / numbered steps with units and a fixed origin. PREDICT: The two numbered versions will look most alike across partners, because numbers and an origin take away the drafter's guesses; 'one word' and 'one sentence' will differ most from partner to partner. CLAIM: *The less an instruction fixes, the more the performer's body decides the form.*
- **DEBT:** GDScript's keywords are English, so the language already has a default speaker (the FLOW-MATIC case in Marino's Critical Code Studies), and the engine's defaults (grey, one sun at a fixed angle) are choices nobody told you about. Planted bug: a missing colon. Read the message: code can be valid and still not be what you meant (Montfort).
- **PLACE:** Stand in the empty base room on desktop. The floor is the first body you meet: Kandinsky's basic plane as a subject, not a given.
- **Godot:** Project Manager import; Run Project (F5) against Run Current Scene (F6); Scene dock and Inspector: change a property and see it in the running scene; print() to the Output panel; Debugger > Errors: read the line number and the message.
- **Lineage:** Processing: Handbook Structure 1 (code elements); Learning Processing ch2 (the editor, errors). NoC: Below NoC's entry level (NoC assumes a semester of this). Application: None directly; Illich and Freire from the application (open the tool, reflect and act). Klee: Before the point: the empty plane the point will walk on. Reference: Form+Code 'What is Code?' [mem]; LeWitt 'Paragraphs on Conceptual Art' (1967) and the wall drawings; Levin & Brain 'Computing without a Computer'.
- **Project step:** Start your hall: a folder, a base scene, and a written instruction for the body you want to have made by the end.

#### 2. Point Zero: the engine calls you

- **Spine:** primitives. **Halls:** Point_Zero (carrier).
- **CODE:** new variables, lifecycle, delta; returns statements, output, errors.
- **BODY:** Two columns at the hall's entrance. One grows by a fixed amount every frame, the other by delta (seconds). The kit's greeting is set once in _ready(); the counts change in _process().
- **ARGUMENT:** axis *frame rate the scene runs at (--fixed-fps)*, values 30 / 60 / 90 / 120. PREDICT: After five seconds the four delta-grown columns will be identical, so any two of them are the closest pair. The frame-grown columns will differ in proportion, and 90 and 120 will look most alike of those. CLAIM: *Only a body grown by delta is the same body on every machine: a headset at 90 Hz and a laptop at 60 Hz grow two different frame-bodies.*
- **DEBT:** A frame is not a second, and the device decides how many there are, so the headset's refresh rate becomes part of the body. Headless runs draw no frames at all (a documented Ada trap), so a rule that counts frames behaves differently there.
- **PLACE:** Walk around the two columns; in the headset they grow at 72 or 90 Hz and you see which one keeps time.
- **Godot:** func _ready() runs once; func _process(delta) runs every frame; var and := ; a member variable keeps its value between calls; Engine.get_process_frames() beside an accumulated delta; Label3D.text with str() and % formatting.
- **Lineage:** Processing: Learning Processing ch3 (setup/draw) and ch4 (variables); Handbook 'Structure 2: Continuous' arrives early because Godot calls your code. NoC: NoC Intro assumes frame-based animation; delta is the part it leaves implicit. Application: None. Klee: The point before it walks: potential energy. Reference: Form+Code 'Form and Computers' (the computer as a machine that repeats in time) [mem]; GDQuest Learn GDScript lessons 10-11 (game loop, delta).
- **Project step:** Put a counter at your hall's entrance that shows seconds, not frames.

#### 3. Point One: a body is a node plus a mesh, and a collider that is not the mesh

- **Spine:** primitives. **Halls:** Point_One (carrier); Primitives_Ignorance (field trip).
- **CODE:** new calling, meshes, collision; returns variables, lifecycle, errors.
- **BODY:** A point built in _ready() from MeshInstance3D.new() and SphereMesh.new(), added with add_child(), then given a StaticBody3D and a CollisionShape3D whose radius is set apart from what you see.
- **ARGUMENT:** axis *collider radius as a fraction of the visible radius (still taken with Debug > Visible Collision Shapes on and the supplied walker standing on top)*, values none (ghost) / 0.5x / 1x / 2x. PREDICT: 0.5x and 1x will look most alike, because in the plain render all four spheres are identical; only the walker's feet (sunk in at 0.5x, touching at 1x, floating at 2x, absent for the ghost) separate them. CLAIM: *In Godot what a body looks like and what it holds are two separate decisions.*
- **DEBT:** The primitive mesh is a default body with its own resolution (64 segments, 32 rings): a sphere on screen is a polyhedron somebody chose. Gaboury's chapter on the Utah teapot asks which bodies are default and who made them standard.
- **PLACE:** Stand on it: the supplied walker steps onto the solid point and falls through the ghost.
- **Godot:** MeshInstance3D.new(), SphereMesh.new(), add_child(); StaticBody3D + CollisionShape3D + SphereShape3D; Debug > Visible Collision Shapes; the Remote scene tree while running.
- **Lineage:** Processing: Handbook Shape 1 (coordinates, primitives); Learning Processing ch1 (a creature from primitives). NoC: None. Application: Polycount against smooth deformation (application l.89), first glimpsed. Klee: I.1 the point as origin of the active line. Reference: Form+Code 'Form and Computers' (the primitive as the machine's first vocabulary) [mem]; Gaboury, Image Objects ch3 (the Utah teapot).
- **Project step:** Put one solid and one ghost body in your hall and label which is which.

#### 4. Point Coordinates: where is a body? Position, parent, pickup

- **Spine:** primitives. **Halls:** Point_Coordinates (carrier); Trans_Introduction (encounter).
- **CODE:** new vectors, properties, transforms; returns calling, meshes, variables.
- **BODY:** A point with a child point: change the parent's X, Y and Z and read position against global_position; the child is a satellite body that keeps its relation.
- **ARGUMENT:** axis *parent offset, with the child's local position fixed (still over the floor grid)*, values (0,0,0) / (1,0,0) / (1,1,0) / (1,1,1). PREDICT: The parent-child pair will look identical in all four stills (the same gap and angle), so any two are the closest pair; only the floor grid shows that both moved. CLAIM: *A child keeps its relation, not its place.*
- **DEBT:** A coordinate system is a choice: Y up, right-handed, metres, and an origin that is privileged. Far from the origin floats lose precision and bodies jitter (the Critical Engineering Manifesto's exploit: walk far out and watch).
- **PLACE:** Carry it: pick up the point with the supplied hand (XR or desktop) and drop it on a target. Pickup belongs to this chapter (TUTORIAL_LINEAGE ruling).
- **Godot:** Vector3 and its x, y, z; position against global_position; parent and child transforms in the scene tree; the supplied pickup (XRToolsPickable or the desktop hand), used, not yet opened.
- **Lineage:** Processing: processing.org 'Coordinate System and Shapes'; Learning Processing ch1. NoC: NoC 1.1 vectors as positions. Application: Vectors as a basic concept (application l.9). Klee: II the space box; the vertical axis that shifts with the viewer. Reference: LeWitt's location drawings (corner, midpoint, centre) as a coordinate system before Vector3.
- **Project step:** Place three bodies in your hall at coordinates you wrote down before you ran the scene.

#### 5. Point Lines: a relation between two bodies

- **Spine:** primitives. **Halls:** Point_Lines (carrier); Vectors_Act1_WhatAVectorIs (field trip).
- **CODE:** new expressions, functions, parameters; returns vectors, properties, transforms, meshes.
- **BODY:** A line between two carried points, drawn with the supplied SKETCH helper line(a, b); the student writes thickness_for(a, b) that returns a thickness from b - a and its length, so three lines of 0.5, 1 and 2 m carry an argument.
- **ARGUMENT:** axis *exponent p in thickness = 0.05 * length^p (three lines of 0.5, 1 and 2 m in each variant)*, values -1 / 0 / 1 / 2. PREDICT: p = -1 and p = 1 will use about the same total ink and so look closest in weight, but read in opposite directions; p = 2 is the outlier, with its long line five times thicker than at p = 0. CLAIM: *A line's thickness is an argument about distance: one exponent turns the same three relations into strain or attraction.*
- **DEBT:** A line does not exist in 3D. Godot has no line(): it is a stretched box, or a one-pixel strip the headset draws with no thickness. The SKETCH helper hides that, so open it at the end of the chapter. Chun's 'sourcery' applies here: reading the helper's code still leaves the GPU hidden.
- **PLACE:** Walk through it: bring the two endpoints close and the barrier line breaks (Point Lines' do_not_cross_barrier). The line is a threshold for the body.
- **Godot:** b - a, length(), distance_to(); func thickness_for(a: Vector3, b: Vector3); the supplied SKETCH helper line(a, b) (segment.gd show_between), opened last; Label3D readout of the distance.
- **Lineage:** Processing: Learning Processing ch7 (functions); processing.org PVector. NoC: NoC 1.2-1.5 (vector subtraction, magnitude). Application: Vectors (application l.9). Klee: I.1-I.4 the active, medial and passive line. Reference: DBN 'Line' then 'Lines' (singular before plural); Kandinsky, Point and Line to Plane.
- **Project step:** Draw the first relation in your hall: two bodies joined by a line whose thickness makes an argument.

#### 6. Synthesis 1: a collage room, where a scanned body meets coded bodies, in the headset

- **Spine:** primitives. **Halls:** Primitives_Melencolia (field trip); Point_One (encounter).
- **CODE:** new import_assets, xr, export_build; returns meshes, collision, transforms, functions.
- **BODY:** A scanned body (phone photogrammetry, Tilt Brush or Blender) imported as glTF, with a collider generated for it, standing among the coded point, line and sphere.
- **ARGUMENT:** axis *decimation of the scanned mesh (share of triangles kept)*, values 100% / 25% / 5% / 1%. PREDICT: 100% and 25% will look most alike at 2 m, because the eye stops counting triangles past a density; at 1% the scan turns into a faceted polyhedron that looks coded. CLAIM: *Below some polycount a scanned body starts to look procedural: the line between found and made is a triangle budget.*
- **DEBT:** A scan is not a copy: it fills holes, smooths, and bakes the light into its texture. Scanners fail on hair, dark skin, glass and moving bodies, which is a body politics (Queer 3D's 'bias'; Blas's Facial Weaponization Suite). The Quest's 72/90 Hz budget makes the 100% scan unaffordable.
- **PLACE:** Become it: enter your room in the headset through the supplied XR rig and stand beside the scan at 1:1 scale. A classmate walks it from your exported build.
- **Godot:** drag a .glb into the FileSystem dock; import settings (scale, generate collision); MeshInstance3D.create_trimesh_collision(); swap the desktop walker for the supplied XR rig (Godot XR Tools; commons/scenes/vr_staging.tscn); Project > Export: a desktop build, and the Android/Quest preset (Day Zero describes the headset route; Ada has not yet verified it).
- **Lineage:** Processing: Handbook 'Synthesis 1: Form and Code'. NoC: None. Application: VR as the medium (the application's premise); open-source sharing (Illich). Klee: I.11 genesis: building stone on stone against carving away. Reference: Queer 3D World 2024 week 1 (scanning, Tilt Brush, export to Blender); Hannah Hoch's collage; Anthropy's Twine book (share in chapter 1).
- **Project step:** Checkpoint 1: your hall holds one found body and three made bodies, and a classmate has walked it from your build.

### Repeat

#### 7. Point Trace: repeat in time, the walk kept

- **Spine:** primitives. **Halls:** Point_Trace (carrier); Point_Lines (encounter).
- **CODE:** new arrays, conditions, booleans; returns lifecycle, functions, vectors, expressions.
- **BODY:** A trace body: a carried point's positions kept in a list (the list comes before append), with a new sample taken only past a distance gate (the condition comes before the threshold), drawn as a strip by the supplied ImmediateMesh helper.
- **ARGUMENT:** axis *distance gate for taking a sample (the same recorded walk replayed)*, values 0.01 m / 0.05 m / 0.2 m / 0.5 m. PREDICT: 0.01 and 0.05 will look most alike (both read as a smooth curve); at 0.5 the gesture becomes a polygon with visible corners. CLAIM: *The gate decides whether a kept walk reads as a gesture or as a polyline: memory has a resolution.*
- **DEBT:** A record is a sampling: whatever happens between samples is lost, and ch2's frame rate decides how often you sample. A list that only grows needs a cap (pop_front), so the body also has to decide what it forgets.
- **PLACE:** Walk it: record your own walk through the hall and leave the trace as a body others can follow.
- **Godot:** Array[Vector3], append(), size(), pop_front(); if pos.distance_to(last) > gate; a bool recording flag toggled by a supplied input action; ImmediateMesh LINE_STRIP (supplied here, written at ch9).
- **Lineage:** Processing: Learning Processing ch5 (conditionals) and ch9 (arrays: the mouse history). NoC: NoC 0's walker trail, previewed. Application: None. Klee: I.1 'an active line on a walk'. Reference: Form+Code 'Repeat' (repetition in time) [mem]; Klee, Pedagogical Sketchbook I.1.
- **Project step:** Record the route you want visitors to take through your hall and keep it as a faint trace.

#### 8. Embedded iteration: many bodies in a row, a grid, a lattice

- **Spine:** primitives, array_tutorial. **Halls:** Point_Line_Grid (carrier); Array (carrier); Tutorial_3D (field trip).
- **CODE:** new loops, nested_loops, materials; returns arrays, conditions, calling, meshes, collision.
- **BODY:** A 5x5 grid and then a 4x4x4 lattice of boxes built with nested loops, the materials alternating by (x + z) % 2 (Klee's chessboard).
- **ARGUMENT:** axis *gap between cells as a fraction of the cell size*, values 0 / 0.1 / 0.5 / 1.0 / 3.0. PREDICT: 0 and 0.1 will look most alike, since both read as one mass; by 1.0 the lattice reads as many separate bodies. CLAIM: *Whether a repetition is one body or many is decided by the gap, not by the count.*
- **DEBT:** Every cube is its own node, mesh and draw call: 64 of them cost nothing, 64,000 stall the headset (paid off at ch10 with a MultiMesh). The grid is also the order (Klee's 'purely repetitive and therefore structural') that chance will disturb at ch11. It is a norm, not neutral ground.
- **PLACE:** Stand on it: the lattice floor with a collider per cell. At a gap of 1.0 it becomes stepping stones; at 3.0 it cannot be walked.
- **Godot:** for i in range(n); nested for x / for z / for y; StandardMaterial3D.new(), albedo_color, material_override; a make_box(pos, size) helper that only adds (return comes in ch9).
- **Lineage:** Processing: Learning Processing ch6 (loops, nested grid); Handbook 'Control 2: Repetition'. NoC: None. Application: None. Klee: I.5-I.6 structure as repetition; the chessboard. Reference: Form+Code 'Repeat: Embedded Iteration' [V code example]; DBN 'Dot' then 'Dots'; Molnar's molnar_cube_study in the Array hall.
- **Departure:** array_tutorial (spine 3) comes before transformation (spine 2). Form+Code puts Repeat before Transform, and in this course a transform means most once there are many bodies to transform: ch13 rotates this lattice. Position and the parent transform are not delayed; they were met at ch4, where Godot needs them.
- **Project step:** Build the floor or one wall of your hall as a lattice whose gap you chose and can defend.

#### 9. A triangle is a list: the first authored surface

- **Spine:** primitives. **Halls:** Point_Triangle_Context (carrier); Primitives_Polythedra (carrier); Point_Animatedcube (field trip).
- **CODE:** new surface_tool, normals, return; returns arrays, loops, collision, functions.
- **BODY:** A fan body, the triangles repeated around a centre: make_fan(n, radius, height) returns an ArrayMesh built with SurfaceTool, and a ConvexPolygonShape3D is made from the same points.
- **ARGUMENT:** axis *how the normals are made (an 8-sided fan, same vertices)*, values none / flat (one per face) / smooth (generate_normals) / inverted winding. PREDICT: 'none' and 'inverted' will look most alike from outside (both dark or missing); flat and smooth differ most at 8 sides and would converge at 64. CLAIM: *Light reads a surface through its normals, not its vertices: the same eight triangles become a crystal, a cone or a hole.*
- **DEBT:** Godot winds front faces clockwise, and when the winding is wrong the body is invisible from outside: a hole. Smooth shading lies about polycount, since the 'smooth' cone is 8 facets pretending, which is the first form of the application's polycount question. The convex hull fills in the open corner, so the collider lies too.
- **PLACE:** Stand on it: the walker can stand on your surface only because the collider came from the same points. Watch where the hull differs.
- **Godot:** SurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES), add_vertex(), generate_normals(), commit(); func make_fan(n: int) -> ArrayMesh; ConvexPolygonShape3D.points from the same PackedVector3Array; cull_mode and winding order.
- **Lineage:** Processing: Learning Processing ch14 (vertex shapes); Handbook 'Shape 2: Vertices'; PShape. NoC: None. Application: Polycount against smooth deformation (l.89); 'queer meshes' (WP2). Klee: I.4 medial lines whose figures read as planes. Reference: Form+Code 'Form and Computers' [mem]; Catlike Coding 'Procedural Meshes: Creating a Mesh'; Godot docs 'Using the SurfaceTool'.
- **Project step:** Replace one primitive in your hall with a surface you listed vertex by vertex.

#### 10. Tiling: the tile and its rule (regularity)

- **Spine:** array_tutorial, tiling. **Halls:** Tutorial_Tiling_Floor (carrier); Symmetry_Seventeen (carrier); Tutorial_Disco (carrier); Pattern_Foundry (field trip).
- **CODE:** new uv, multimesh, audio; returns nested_loops, materials, conditions, delta.
- **BODY:** A floor: one 4x4 tile made pixel by pixel as an Image, repeated by a symmetry rule over a MultiMesh carpet. The disco version recolours by (x + z + phase) % 2 on a delta clock and plays a generated tone on each step.
- **ARGUMENT:** axis *repeat rule (wallpaper operation) applied to the same 4x4 tile*, values p1 translate / pm mirror / pg glide / p2 half-turn / p4 quarter-turn. PREDICT: pm and pg will look most alike: both reflect, and the glide only shifts alternate rows by half a tile. CLAIM: *The rule, not the tile, decides what a floor says: the same 16 pixels read as a stripe, a zigzag or a pinwheel.*
- **DEBT:** Regularity is the order that randomness needs (10 PRINT's chapter order puts Regularity before Randomness). The grid is also a norm the floor imposes on bodies (lanes). A MultiMesh has no per-tile collision, so what you see is not what you walk on.
- **PLACE:** Dance on it: the disco floor under your feet, where the step sequencer's pattern is the floor's rhythm.
- **Godot:** Image.create(), set_pixel(), ImageTexture; UV repeat (uv1_scale) with nearest filtering; MultiMeshInstance3D with use_colors and set_instance_color(); AudioStreamWAV filled from a sample loop; AudioStreamPlayer3D.
- **Lineage:** Processing: Handbook 'Image 1', 'Color 1'; processing.org '2D Arrays'. NoC: None. Application: WP1 sound experiments, moved early with the disco floor. Klee: I.5 rhythm as repetition; I.7 proportion. Reference: Form+Code 'Repeat' [mem]; Recreating the Past, 'Pattern' (Riley, Albers); 10 PRINT ch30 'Regularity'.
- **Departure:** tiling (spine 5) comes before color (spine 4) and transformation (spine 2), because Form+Code's Repeat gathers every kind of repetition before any transform. Colour as a system returns under Visualize (ch22). Audio arrives early because the application lists sound experiments as a Basic Element (WP1) and the disco floor is the spine's earliest generated tone.
- **Project step:** Tile one surface of your hall with a rule you can name (p1, pm, pg, p2, p4) and let it keep time.

#### 11. Chance 1: disorder in the grid

- **Spine:** randomness, array_tutorial. **Halls:** Array (carrier); Randomness_10_PRINT_Algorithm (carrier); Random_Definition (carrier); Random_Remove (field trip).
- **CODE:** new random, seeds, ai_assist; returns nested_loops, multimesh, collision, functions, materials.
- **BODY:** A Schotter lattice (Nees 1968): rows of cubes whose random rotation and displacement grow row by row. Then a 10 PRINT floor-maze whose walls are one of two diagonals per cell.
- **ARGUMENT:** axis *disorder amount (molnar_cube_study's 'amount')*, values 0 / 0.1 / 0.25 / 0.5 / 1.0. PREDICT: 0.5 and 1.0 will look most alike: past a threshold the eye stops reading the grid, and any further disorder reads simply as 'random'. CLAIM: *Disorder is visible only against an order that can still be read: chance needs the grid.*
- **DEBT:** Pseudo-randomness: the same seed gives the same 'chance' (Random_Definition, 'a pattern that returns'), because the RNG is a deterministic function. Whose chance is it? Nake's Hommage a Paul Klee (1965) used random numbers in place of intuition. AI debt: ask an AI for the Schotter ramp, state what must change (the ramp), what must not (row 0 under seed 1968), and which still would prove it wrong, then check with the seed replay.
- **PLACE:** Walk through it: the 10 PRINT maze has a collider per wall and can be walked. In the Schotter floor the bottom rows cannot be walked, so the body finds where order ends.
- **Godot:** RandomNumberGenerator, randf_range(), randi() % 2; rng.seed = 1968 to replay; randomize() for a new layout; the supplied maze walls (MultiMesh + a BoxShape3D per cell); ai_assist protocol: brief; 'must change / must not change / proof it is wrong'; read the diff before running it.
- **Lineage:** Processing: Learning Processing ch4 (random() as a value); Handbook 'Math 4: Random'. NoC: NoC 0 Randomness (first met here; returns at ch29). Application: WP1 randomness, moved to where the application puts it. Klee: None: Klee has no chance; Nake (1965) adds it to Klee's 'Hauptweg und Nebenwege'. Reference: Form+Code 'Repeat' [mem]; 10 PRINT ch40 'Randomness'; Nees, Schotter (1968); Molnar, (Des)Ordres (1974); Recreating the Past, 'Chaos and Order'.
- **Departure:** randomness is spine 10; here it is chapter 11 of 37, straight after the grid and the tile instead of after forces and waves. Three reasons: the 2023 application lists randomness as a Basic Element (WP1), Palle's Queer 3D foundation list starts with it, and 10 PRINT argues that regularity must come just before randomness so the disorder has something to disturb. The spine's randomness sequence (walks, distributions, entropy) returns at ch29.
- **Project step:** Put one disorder ramp in your hall with a fixed seed, so every visitor sees the same one, and write the seed on the wall.

#### 12. Recursive tree: repeat inside itself

- **Spine:** fractals. **Halls:** Fractal_Recursion (carrier); Fractal_RecursiveTrees (carrier); FormFinding_Equilibrium (encounter).
- **CODE:** new recursion, debugging; returns functions, parameters, return, transforms, random, seeds.
- **BODY:** A tree: branch(pos, dir, length, depth) calls itself twice with shorter lengths, and each branch is thinner than the one before (Munari's rule).
- **ARGUMENT:** axis *depth limit*, values 1 / 3 / 5 / 7 / 9. PREDICT: 7 and 9 will look most alike: past depth about 7 the new twigs are too small to see from 2 m, though the tip count goes from 128 to 512. CLAIM: *A recursive body is finished by its stop rule, not by its growth rule: depth beyond perception is pure cost.*
- **DEBT:** Recursion must always be controlled (Queer 3D). Remove the base case and read the stack overflow: that is the chapter's planted bug. The invisible twigs still cost nodes, so count them in the debugger. Munari's 'mad branch': add one exception to the rule and see that the family still reads.
- **PLACE:** Walk under it: a tree at 1:1 in the hall with a collider on the trunk only, so the canopy is a ghost.
- **Godot:** a function that calls itself with depth - 1; the base case: if depth == 0: return; Debugger: breakpoint, step, the Stack Trace panel, the stack overflow message; Monitors: object and node count.
- **Lineage:** Processing: Handbook 'Shape 3: Parameters, Recursion'; Learning Processing ch13. NoC: NoC 8 Fractals, moved early. Application: WP2 fractal subdivision (early visit). Klee: I.11 propagation and growth (the plant). Reference: Form+Code 'Repeat: Recursive Tree' [V code example; the anchor files recursion under Repeat]; Munari, Drawing a Tree (1978); Kawaguchi's growth model.
- **Departure:** fractals (spine 14) are met here, eleven sequences early, because the anchor files the recursive tree under Repeat and Palle's Queer 3D foundation asks about for-loops and recursion in the same breath. The fractals sequence stays whole as returns: Fractal_KochSierpinski is a field trip from ch31, and FormFinding_Equilibrium's recursive mobile returns at ch30.
- **Project step:** Checkpoint 2 (end of Repeat): your hall has a lattice, a tiled surface, a seeded disorder and one recursive body. Take four stills and write what repeats in each.

### Transform

#### 13. Pivot and order: a body of joints

- **Spine:** transformation. **Halls:** Trans_Rotation (carrier); Trans_Body (carrier); Trans_Introduction (field trip).
- **CODE:** new basis, composition, instancing; returns transforms, loops, vectors, nested_loops.
- **BODY:** A limb: one scene (a bone mesh under a pivot node) instanced three times as a chain of upper arm, forearm and hand (Klee's bone, tendon and muscle), each joint turning about its own pivot. Then the ch8 lattice with each cell rotated by its index (Mohr's Cubic Limit).
- **ARGUMENT:** axis *pivot position along each limb segment (same joint angles)*, values at the start / a quarter along / the middle / at the end. PREDICT: 'start' and 'a quarter along' will look most alike, because the long lever dominates the pose; 'at the end' folds the chain into a different body. CLAIM: *The same rotation makes a different body depending on where the pivot sits: a joint is a decision about where a body may bend.*
- **DEBT:** Euler angles lie: rotation order matters (Y then X is not X then Y) and gimbal lock is real. The Basis is the truth; the three numbers in the Inspector are an approximation of it. A skeleton imposes an anatomy, so queer the joint: put one where no anatomy has it.
- **PLACE:** Become it: attach the chain to your XR hand (or the desktop hand) so your arm grows an extra joint, an extrapolated body.
- **Godot:** Basis, rotate_object_local(), look_at(); limb.tscn instanced with PackedScene.instantiate(); composition: skin (mesh) separate from pivot (Node3D), GDQuest's skin/controller split; transform.basis * vector.
- **Lineage:** Processing: Learning Processing ch14 (pushMatrix/popMatrix become child nodes); Handbook 'Transform 1-2'. NoC: NoC 3 angular motion, previewed. Application: None. Klee: I.9-I.10 bone, ligament, tendon and muscle as passive, medial, active. Reference: Form+Code 'Transform' [mem]; Mohr, Cubic Limit; Levin & Brain, 'Personal Prosthetic' and 'Extrapolated Body'.
- **Departure:** transformation is spine 2 but arrives after Repeat: the anchor's order is Repeat then Transform, and this chapter transforms the lattice (ch8) and the tree (ch12). Position and the parent transform were not delayed: they came at ch4, where Godot needs them.
- **Project step:** Give your hall one jointed body whose pivots you placed on purpose.

#### 14. Scale: the room or the body?

- **Spine:** transformation. **Halls:** Trans_Scale (carrier); Trans_Pit (carrier); Tutorial_3D (field trip).
- **CODE:** new player, input, camera; returns transforms, collision, composition, conditions.
- **BODY:** The player body opened: the supplied walker's CharacterBody3D, capsule, camera and input map read line by line. Then scale the room by 4, or scale the body by a quarter, and test which doors the fixed capsule fits through.
- **ARGUMENT:** axis *room scale with the body fixed (still: the capsule in front of the same door)*, values 0.25 / 0.5 / 1 / 2 / 4. PREDICT: 0.25 and 0.5 will look most alike: the capsule cannot pass either door and both read as a dollhouse. From 1 upward the door reads as a door. CLAIM: *A room's size can only be read against a body: scale is a relation, not a property.*
- **DEBT:** The default body: a 1.8 m capsule with eyes at about 1.6 m. Montfort's 'Critique My Starter Programs', turned on Godot's own starter player, asks who the default user is. Headset height and IPD are defaults too (Bagnall's hardware chapter in Queer Game Studies). The camera is an eye the engine places for you.
- **PLACE:** Become it: play at a quarter scale and at 4x. In the headset, XROrigin3D world_scale changes how your own body reads.
- **Godot:** CharacterBody3D, velocity, move_and_slide(), is_on_floor(); Input Map actions, Input.get_vector(); Camera3D as a child of the body; mouse look; XRCamera3D; XROrigin3D.world_scale against node scale.
- **Lineage:** Processing: Learning Processing ch3 (interaction: mouse and keys). NoC: None. Application: VR presence (the application's premise). Klee: II.18 'the tightrope walker is the scale'. Reference: Form+Code 'Transform' [mem]; Montfort, Exploratory Programming ch7; GDQuest 3D module 7 (skin against controller).
- **Departure:** Part of the transformation block (ch13-15), which sits after Repeat; see ch13.
- **Project step:** Decide your hall's scale against the supplied body, and put in one door only a smaller body can pass.

#### 15. Easing: between two states

- **Spine:** transformation. **Halls:** Trans_Pre (carrier); Trans_Introduction (encounter).
- **CODE:** new interpolation, areas, signals; returns lifecycle, delta, transforms, player.
- **BODY:** A pickup body that bobs and spins, and when the player enters its Area3D it eases towards the player and shrinks away: the Mario pickup in four stages.
- **ARGUMENT:** axis *easing curve over the same two positions (a multiple-exposure still at 10 equal time steps)*, values linear / ease-in / ease-out / ease-in-out / elastic. PREDICT: ease-in and ease-in-out will look most alike, because both bunch their exposures at the start; elastic overshoots and is the outlier. CLAIM: *An easing curve is a character: the same two positions become a lunge, a hesitation or a spring.*
- **DEBT:** A tween is time bent by a stock formula (Penner's easings [mem]): 'natural' motion is a canned curve that everyone's games share. A signal separates the part that detects from the part that acts; the Area3D does not know what the pickup means.
- **PLACE:** It comes to you: walking into the Area3D makes the body come. In XR you reach for it.
- **Godot:** lerp(), Vector3.move_toward(), create_tween().tween_property() with set_trans()/set_ease(); Area3D + CollisionShape3D, the body_entered signal; connect() and your own signal collected(value); queue_free() after the tween.
- **Lineage:** Processing: Handbook 'Math 2: Curves' (norm, lerp, map). NoC: None. Application: None. Klee: IV.33 kinetic energy: the top begins to move. Reference: Form+Code 'Transform' [mem].
- **Departure:** Part of the transformation block after Repeat; see ch13.
- **Project step:** Make one body in your hall react to a visitor's arrival with an easing you chose.

#### 16. Slit-scan: the pendulum's time laid into space (pendulum, circle, spiral)

- **Spine:** wavefunctions. **Halls:** WaveFunctions_Pendulum (carrier); WaveFunctions_Unit_Circle (carrier); Wavefunctions_Bernini (field trip); WaveFunctions_Effect_Sound (field trip); WaveFunctions_Synthesis_Lab (encounter); Fractal_GoldenSpiral (encounter).
- **CODE:** new trig, queues; returns lifecycle, delta, multimesh, audio, arrays.
- **BODY:** A pendulum bob whose positions go into a bounded queue every physics tick and are laid out along an axis, a slit-scan body in space. Then (cos t, sin t) as a runner on a circle, and a radius that grows with t to give a spiral column (Bernini).
- **ARGUMENT:** axis *radius growth per turn*, values -0.2 / -0.05 / 0 / 0.05 / 0.2. PREDICT: -0.05 and 0.05 will look most alike (two near-circles that drift in opposite directions); -0.2 closes to a point and 0.2 opens into a coil. CLAIM: *One number turns a circle into a spiral of life or of death: Klee's pendulum becomes a direction.*
- **DEBT:** sin and cos are computed approximations, and physics ticks sample time: change physics_ticks_per_second and see the steps in the slit-scan. A queue forgets its oldest sample. Additive waves (Synthesis_Lab) are the Fourier idea from WP2, met here as an encounter only.
- **PLACE:** Walk through it: at room scale the slit-scan body is a corridor along the pendulum's past. Wavefunctions_Sky_Stairs is a trig body you can climb.
- **Godot:** sin(), cos(), TAU, wrapf(); _physics_process with an accumulator; physics_ticks_per_second; a queue: push_back() and pop_front() on a capped Array; a MultiMesh of N marks updated from the queue; a pitch from position (AudioStreamPlayer3D).
- **Lineage:** Processing: Handbook 'Math 3: Trigonometry'. NoC: NoC 3 Oscillation, before forces here. Application: WP1 sine curves and resonance; Fibonacci (Fractal_GoldenSpiral, encounter); Fourier (encounter). Klee: IV.33-IV.37 pendulum, then circle, then the expanding and contracting spiral. Reference: Form+Code 'Transform: Slit-Scan' [V code example]; Whitney, 'Animation and Harmony' (Recreating the Past, week 2).
- **Departure:** wavefunctions (spine 9) comes before forces (7) and formfinding (8). Form+Code files time-into-space (slit-scan) under Transform, and Klee derives circle and spiral from the pendulum without any forces: the sine is a transform of time. The pendulum returns at ch28 as an integrated spring (Vectors_Act4b_Oscillation).
- **Project step:** Lay one motion from your hall out in space as a slit-scan body.

#### 17. Transcoded landscape: a function becomes ground

- **Spine:** change, wavefunctions. **Halls:** Change_Intro (carrier); WaveFunctions_Sine_Space (carrier); Wavefunctions_Sky_Stairs (field trip); Noise_Space_10 (encounter).
- **CODE:** new packed_arrays, physics_bodies; returns surface_tool, normals, trig, nested_loops, collision, return.
- **BODY:** A heightfield h(x, z) = A sin(kx) cos(kz) sampled on a grid into a PackedVector3Array, turned into a mesh with SurfaceTool and a collider with create_trimesh_shape(), with RigidBody3D spheres dropped onto it.
- **ARGUMENT:** axis *grid resolution (samples per metre) over the same function*, values 2 / 4 / 8 / 16 / 32. PREDICT: 16 and 32 will look most alike; at 2 the wave is aliased into a different, slower landscape and the spheres settle in different valleys. CLAIM: *Below a sampling rate the ground is a different body: the function stays the same, the landscape does not.*
- **DEBT:** Sampling debt: a fine wave sampled coarsely becomes another wave (aliasing, moire). The mesh and the collider are two approximations that have to agree; the ball rolls on the trimesh, not on the formula.
- **PLACE:** Stand on it and roll on it: walk the landscape and watch the spheres gather in the valleys you made.
- **Godot:** PackedVector3Array vertices, PackedInt32Array indices; SurfaceTool from a grid; generate_normals(); ArrayMesh.create_trimesh_shape() in a StaticBody3D; RigidBody3D spheres: mass, bounce.
- **Lineage:** Processing: Handbook 'Shape 2: Vertices'; P3D beginShape(TRIANGLE_STRIP). NoC: None. Application: WP1 sine curves. Klee: III the gravitational curve: the rolling ball traces a trajectory on your ground. Reference: Form+Code 'Transform: Transcoded Landscape' [V code example]; Catlike Coding 'Mathematical Surfaces'.
- **Departure:** change (spine 6) comes after wavefunctions (9), and both come before forces (7): a plotted function is a transform of numbers into ground, which is the anchor's Transform. Flow_Field, the other change hall, waits for noise (ch23), because it samples a noise field that does not exist yet.
- **Project step:** Checkpoint 3 (end of Transform): your hall has a ground made from a function; a visitor can walk it and a ball can roll on it.

### Parameterize (an addition to the spine, declared)

#### 18. Describe a body in a single class

- **Spine:** primitives. **Halls:** Primitives_Melencolia (carrier); Primitives_Ignorance (carrier); Color_Context_Placed (field trip).
- **CODE:** new classes, methods, types; returns functions, parameters, return, surface_tool, loops, trig.
- **BODY:** class_name Pyramid extends MeshInstance3D, with typed fields base_sides, radius, height and a build() method that makes the mesh: the base ring with sin and cos in a loop, so base_sides = 3 gives a tetrahedron (Ada's pyramid.gd).
- **ARGUMENT:** axis *base_sides*, values 3 / 4 / 6 / 12 / 48. PREDICT: 12 and 48 will look most alike: past about a dozen sides a pyramid reads as a cone. CLAIM: *A class's fields decide which bodies are possible: base_sides makes pyramid and cone one family, and no value of it makes a sphere.*
- **DEBT:** The modelling choice is the critique (the CCSWG prompt 'describe war in a single class', turned to a body). What your class cannot express (a body with no apex, or two apexes) and what its types forbid (an int cannot have 3.5 sides) are borders. Write them in a comment.
- **PLACE:** Stand on it: the pyramids as seats and steps. Which of them can you stand on top of?
- **Godot:** class_name and extends; func build() -> void as a method; self; typed fields: var base_sides: int = 4; static typing warnings in the editor.
- **Lineage:** Processing: Learning Processing ch8 (objects: Zoog becomes a class). NoC: NoC 0-1: the Walker and Mover classes. Application: None. Klee: I.7 divisional proportion. Reference: Form+Code 'Parameterize' [V theme]; CCSWG 2024 teaching thread ('describe war in a single class'); Durer, Melencolia I (the hall's precedent).
- **Departure:** Parameterize has no spine sequence; this whole part is an addition, declared as one. It returns to primitives halls (Melencolia, Ignorance) because their works are already families (pyramid base_sides, sphere tessellation), and 74% of Ada's scripts are built this way.
- **Project step:** Rewrite the body you care most about in your hall as one class, with the fewest fields that still make it.

#### 19. @export: the family in the Inspector

- **Spine:** primitives, color, softbodies, isosurfaces. **Halls:** Color_Context_Placed (carrier); Topology_Entropy_Morphogenesis (carrier); ISO_LookupTable (field trip); Primitives_Melencolia (encounter).
- **CODE:** new export, setters, tool_scripts; returns classes, methods, types, instancing.
- **BODY:** The Pyramid class with @export_range fields, setters that rebuild on change, and @tool so the family changes live in the editor. Then a sweep scene: five instances side by side with one field stepped, the comparison sheet as a scene.
- **ARGUMENT:** axis *apex offset as a fraction of the base radius (Ada's apex_stance axis)*, values 0 / 0.25 / 0.5 / 1.0 / 2.0. PREDICT: 0 and 0.25 will look most alike (both upright pyramids); past 1.0 the apex leaves the base and the body leans, first an oblique pyramid and then a blade. CLAIM: *One exported field can carry a body across a category of form: from monument to lean-to.*
- **DEBT:** The Inspector slider hides what each value costs and what it breaks. Defaults are sacred: an Ada artifact can have hundreds of live placements, so changing a default silently changes every hall it stands in. A setter that rebuilds on every change can stall the editor.
- **PLACE:** Carry it: a supplied in-world slider changes the family while you hold the body.
- **Godot:** @export, @export_range, @export_enum; a setter: set(value): x = value; _rebuild(); @tool and Engine.is_editor_hint(); a sweep scene of five labelled instances.
- **Lineage:** Processing: Handbook 'Shape 3: Parameters'. NoC: None. Application: None directly (the application's families are its DNA). Klee: I.7 linear variation. Reference: Form+Code 'Parameterize: Chair' [V code example]; Generative Design's numbered variant series; Albers: fix the material, vary one thing.
- **Departure:** Parameterize is an addition (see ch18). Topology_Entropy_Morphogenesis (spine 17) and ISO_LookupTable (18) are visited early only for their setter and @tool patterns; both return in full at ch32 and ch25.
- **Project step:** Turn your hall's main body into a family with one exported axis and hang the five-variant sheet at the entrance.

#### 20. The budget: polycount measured, a claim tested

- **Spine:** primitives, formfinding. **Halls:** Primitives_Portals (carrier); Primitives_Ignorance (carrier); FormFinding_Catenary (carrier).
- **CODE:** new testing, profiling; returns export, loops, surface_tool, uv, functions.
- **BODY:** A parametric surface, the catenoid (u, v) -> point, with exported u_steps and v_steps; a torus ring whose segments double while its gap to the true circle is printed and asserted.
- **ARGUMENT:** axis *u_steps of the catenoid*, values 6 / 12 / 24 / 48 / 96. PREDICT: 48 and 96 will look most alike at 2 m, while the Profiler shows 96 costing about four times as much to draw; the prediction is also written as a test: gap_to_circle(n) < 0.01 for n >= 48. CLAIM: *A parametric surface has a step count below which it is a different body and above which it is only cost: the test finds the first, the profiler the second.*
- **DEBT:** Polycount against smooth deformation (application l.89): 'smooth' is a budget decision, and in a headset at 72/90 Hz every triangle is drawn once per eye. A green test is a fact about the question you asked, not about the body.
- **PLACE:** Stand in it: the catenoid as a neck you walk through at room scale (collider from the mesh). The headset's frame time is the debt you feel: stutter makes people sick, so comfort is not polish.
- **Godot:** assert() in a headless check (godot --headless --script); Profiler and Monitors: frame time, draw calls, primitives; Time.get_ticks_usec() around a build; a surface from (u, v) with UVs.
- **Lineage:** Processing: Handbook 'Development 2: Iteration, Debugging'. NoC: None. Application: Polycount (l.89); the headset's frame rate. Klee: None. Reference: Form+Code 'Parameterize: Wave' [V code example]; Catlike Coding 'Measuring Performance'; Primitives_Portals 'Circular Approximation and Limits'.
- **Departure:** formfinding (spine 8) is visited early for one surface: the catenoid is a parametric (u, v) body, and the anchor's Parameterize is where it belongs. Form found by force returns at ch30.
- **Project step:** Measure your hall's frame time in the headset and cut the one body that costs most without changing what it argues.

#### 21. Genes as files: a family saved, a body recalled

- **Spine:** proceduralgeneration, randomness, tiling. **Halls:** PG_Genetic_Evolution (carrier); Random_Definition (carrier); Pattern_Foundry (field trip); LSystems_Living (encounter).
- **CODE:** new dictionaries, resources, save_load; returns classes, export, random, seeds, instancing.
- **BODY:** A creature genome as a custom Resource (segments, limb_count, limb_angle, colour, seed) and a builder that turns it into primitive-mesh parts. The chosen specimen is saved as .tres or to user:// and returns after a restart.
- **ARGUMENT:** axis *the limb_count gene*, values 0 / 2 / 4 / 6 / 12. PREDICT: 6 and 12 will look most alike from above: past about six limbs the body reads as radial, a star or a flower, not as an animal. CLAIM: *A genome draws a border between kinds: somewhere between 4 and 6 limbs, a creature becomes a flower.*
- **DEBT:** A saved body is a frozen choice. The genome decides which creatures are possible and which can never be born, and that is the dark spot of the encoding. Resources are shared by default, so two bodies can secretly share one gene; duplicate(true) is the fix.
- **PLACE:** Carry it: the specimen is a pickable object that survives leaving and re-entering the hall, a museum specimen.
- **Godot:** Dictionary literals and lookups (a body as a recipe); class_name Genome extends Resource with @export fields; ResourceSaver.save(), load(); a save and load round trip in user://; resource.duplicate(true) against a shared resource.
- **Lineage:** Processing: Learning Processing ch18 (data). NoC: NoC 9 genotype and phenotype, previewed. Application: WP3 evolutionary algorithms, previewed. Klee: None. Reference: Form+Code 'Parameterize' (the parametric chair as a recipe) [mem]; Levin & Brain 'Virtual Creature'; Sims, Evolved Virtual Creatures (1994) [mem].
- **Departure:** proceduralgeneration (spine 16) is visited early for its genome-as-file pattern, which is where Parameterize ends: a family becomes data that can be saved, shared and bred. Evolution itself returns at ch35.
- **Project step:** Midterm (long track): save your hall's family as files, show the sheet, and let a classmate load and breed one specimen.

### Visualize

#### 22. Value to colour: the chroma stack

- **Spine:** color. **Halls:** Color_Context_Placed (carrier); Color_Rainbow (carrier); Color_Walls (carrier); Color_Pillar (field trip); Color_Nails (field trip).
- **CODE:** new ui, strings; returns materials, interpolation, dictionaries, export, signals.
- **BODY:** A stack of blocks coloured by a rule (chroma_stack's rule), an arch of N bands coloured by Color.from_hsv(i / N), and one grey block that is moved across five grounds. A 3D slider sets N; labels show each colour's hex string.
- **ARGUMENT:** axis *ground colour behind one fixed grey block (Albers)*, values black / dark blue / mid grey / yellow / white. PREDICT: Black and dark blue will make the grey look most alike (both push it lighter); yellow and white push it darker, and yellow also tints it violet. CLAIM: *A colour value is not a colour: the same material reads as two colours on two grounds.*
- **DEBT:** RGB is a device model, not perception (sRGB, gamma, the headset's panel). A hex code names a number, not what anyone sees. ROYGBIV is Newton's seven bands, chosen to match the musical scale [mem], so even the rainbow is a convention.
- **PLACE:** Walk through it: the rainbow arch as a gate. In VR the Albers wall changes as you move, so the same body looks different depending on where you stand.
- **Godot:** Color.from_hsv(), Color.lerp(), to_html(); string formatting with % and Label3D; a Control slider in a SubViewport on a 3D panel (or the supplied 3D slider); lerp_rgb against lerp_hsv over one strip of boxes.
- **Lineage:** Processing: Handbook 'Color 1-2'; processing.org 'Color'. NoC: None. Application: WP3 shading algorithms (colour as the first shading). Klee: IV.40-IV.43 colour as energy; the colour circle where the arrow becomes superfluous. Reference: Form+Code 'Visualize: Displaying Data' [V code example]; Albers, Interaction of Color ('1 colour appears as 2'); Recreating the Past (Riley, Albers).
- **Departure:** color is spine 4; here it opens Visualize at chapter 22, after materials were used as values (ch8) and tiles as images (ch10). Klee ends his book in colour, and Form+Code treats colour mapping as visualizing a value, so colour as a system comes when there are values worth mapping. All the spine's colour halls that carry code are visited here.
- **Project step:** Give your hall a colour rule that encodes one value (height, age, distance) and test it on two grounds.

#### 23. Noise: a field you cannot see

- **Spine:** noise, change, randomness. **Halls:** Noise_Perlin_Simplex (carrier); Noise_Space_10 (carrier); Noise_Columns (field trip); Flow_Field (field trip); Random_Space_Geometry (field trip).
- **CODE:** new noise; returns random, seeds, packed_arrays, surface_tool, collision, export.
- **BODY:** The ch17 landscape with the sine replaced by FastNoiseLite: a walkable terrain whose generator, frequency and octaves are exported.
- **ARGUMENT:** axis *noise generator (same seed, frequency and octaves)*, values simplex / perlin / value / cellular. PREDICT: simplex and perlin will look most alike (both smooth blobs); cellular is the outlier, with cells and ridges. CLAIM: *The blob look belongs to the generator, not to the ground: change the noise type and a landscape changes species.*
- **DEBT:** The blob aesthetic (Queer 3D): noise is deterministic chance on a lattice, and Perlin's gradient grid shows through as axis-aligned artefacts. Read Palle's 'overflow rate' comparison (Perlin 45, random 635, Voronoi 0, sine 3284) as a debt table. Noise_Space_10 stops its octaves at 4, with a comment saying why; read that comment as a confession in the Climategate sense.
- **PLACE:** Stand on it: walk the terrain; cross the Random_Space_Geometry bridge whose planks move with the seed.
- **Godot:** FastNoiseLite: noise_type, frequency, fractal_octaves, seed; get_noise_2d(x, z) inside the heightfield loop; refuse to rebuild while the player stands on it; an ImageTexture from the noise for a quick look.
- **Lineage:** Processing: Learning Processing ch13 (noise()). NoC: NoC 0, the Perlin noise section. Application: WP1 Perlin noise; Voronoi via TYPE_CELLULAR; WP2 flow fields (Flow_Field field trip). Klee: None. Reference: Form+Code 'Visualize' (a hidden field made visible) [the anchor does not name noise; our placement]; Book of Shaders ch11; Catlike Coding 'Pseudorandom Noise'.
- **Departure:** noise (spine 11) is taught after colour and far from its randomness partner (ch11): here noise is the visualization of a field you cannot see rather than a sequel to randomness. Flow_Field (spine 6) is visited now that noise exists, not at its spine place.
- **Project step:** Grow one surface of your hall from noise and name the generator on a label.

#### 24. A shader draws every pixel at once

- **Spine:** shaders, tiling. **Halls:** Shader_01_Shaping (carrier); Tutorial_Pattern (carrier); Shader_09_FBM (carrier); Shader_05_Patterns (field trip); Shader_11_QueerRubber (field trip); Shader_10_ReactionDiffusion (encounter).
- **CODE:** new shaders, uniforms; returns uv, noise, materials, export, tool_scripts.
- **BODY:** A surface shaded by a function of UV (step and smoothstep bands), then a vertex shader that displaces a subdivided plane with fBm: the queer rubber body.
- **ARGUMENT:** axis *fBm octaves (uniform int layers)*, values 1 / 2 / 3 / 4 / 6. PREDICT: 4 and 6 will look most alike: each octave adds half the amplitude at twice the frequency, so after 4 the new detail falls below a pixel at 2 m. CLAIM: *Detail has diminishing returns the eye can predict: most of a fractal surface's character is in its first three octaves.*
- **DEBT:** What you see is not what holds you. Vertex displacement moves the picture, not the collider (Shader_09_FBM's glass slab: visible deformation, unchanged collision). Gaboury's frame-buffer chapter: a shader is a picture machine, not a body.
- **PLACE:** Walk on it: step onto the displaced rubber floor and feel that it is flat, the gap between seen and held.
- **Godot:** shader_type spatial; fragment() with UV, TIME, step(), smoothstep(); uniform float frequency : hint_range(...); set_shader_parameter() from GDScript; vertex(): VERTEX += NORMAL * h; ShaderMaterial on a PlaneMesh with subdivisions.
- **Lineage:** Processing: Handbook 'Render Techniques' extension / PShader. NoC: None. Application: WP3 shading algorithms; WP2 'queer meshes and textures'; reaction-diffusion (encounter). Klee: IV colour as energy. Reference: Form+Code 'Visualize: Superformula' (a formula made visible) [V code example]; Book of Shaders ch5-13; Gaboury, Image Objects ch2.
- **Departure:** shaders (spine 12) follows noise (11) as in the spine. Tiling is revisited on purpose: Shader_05_Patterns tiles in UV what ch10 tiled with a MultiMesh, a 'port' in 10 PRINT's sense.
- **Project step:** Port one body of your hall into a shader and write down what the port lost (its collider).

#### 25. Implicit bodies: the hidden field as a surface

- **Spine:** isosurfaces, boolean_surfaces. **Halls:** ISO_Introduction (carrier); ISO_LookupTable (carrier); ISO_Metaballs (carrier); Boolean_Verbs (carrier); ISO_TorusGyroid (field trip).
- **CODE:** new raycasts; returns noise, packed_arrays, surface_tool, normals, collision, player.
- **BODY:** A density field of two balls (metaballs), sampled into a grid and extracted by a supplied marching-cubes function into a mesh with a trimesh collider. Beside it, the same body built with a CSG union.
- **ARGUMENT:** axis *fusion: the distance between two sources (the shared ISO/Boolean vocabulary)*, values distinct / necked / lobed / single. PREDICT: lobed and single will look most alike from 3 m; 'necked' is the value where two bodies become one. CLAIM: *A neck is where two bodies become one: the threshold, not the sources, decides how many bodies there are.*
- **DEBT:** The lookup table is a code-critique station (after Marino's chapter on Kittler's raytracer): read and annotate 30 of its lines, because someone decided the ambiguous cases. The smooth-minimum blend radius is where the blob aesthetic comes from (Quilez). A ray that crosses one column three times finds an overhang no heightfield could make: the implicit body escapes the landscape's rule.
- **PLACE:** Walk through it: an implicit tunnel (ISO_TorusGyroid). A shape cast answers whether a capsule the size of the player fits the opening before you try it.
- **Godot:** density(p); sampling a 3D grid into a PackedFloat32Array; the supplied marching_cubes(field, threshold) -> ArrayMesh (the table is read, not written); PhysicsRayQueryParameters3D and intersect_ray(); ShapeCast3D with a capsule; CSGCombiner3D union, intersection, subtraction with use_collision.
- **Lineage:** Processing: None. NoC: None. Application: WP2 'queer meshes' (blob, fusion); topology (l.89). Klee: I.11 building up against carving away (union against difference). Reference: Form+Code 'Visualize' (the invisible made visible) [our placement]; Marino, Critical Code Studies ch6 (Kittler's code); Lague, Coding Adventure: Marching Cubes; Quilez, smooth minimum.
- **Departure:** isosurfaces and boolean_surfaces (spine 18-19) come before the simulation sequences (13-20), because an implicit body is the most literal case of Visualize: a surface drawn where an invisible field crosses a threshold. The simulations follow in Simulate.
- **Project step:** Carve one space of your hall as an implicit body and prove a visitor fits through it.

#### 26. Visualize a relation: a graph laid out and searched

- **Spine:** graphtheory. **Halls:** GT_Foundations (carrier); GT_Network_Analysis (carrier); GT_Layout (field trip); GT_Spanning_Trees (field trip).
- **CODE:** new graphs, search, await; returns dictionaries, classes, materials, recursion, queues.
- **BODY:** A graph as a Dictionary of adjacency lists, drawn as spheres and edge lines, with BFS and DFS replayed as timed light over the same graph.
- **ARGUMENT:** axis *layout rule for the same graph*, values circle / grid / random (seeded) / by BFS depth (tree) / force-directed (supplied). PREDICT: circle and random will look most alike for a dense graph, both a hairball; the BFS tree and force-directed differ most, since one ranks and the other clusters. CLAIM: *The same relations drawn five ways say five different things: a layout is an argument about which relations matter.*
- **DEBT:** A layout is not the graph. Network defaults make like cluster with like (Chun's homophily, Discriminating Data [mem]), and centrality colour ranks bodies by a formula someone chose.
- **PLACE:** Walk it: the graph at room scale; walk the BFS order. The spanning-tree maze is a place.
- **Godot:** a Dictionary of Arrays as adjacency; BFS with a queue, DFS with recursion; await get_tree().create_timer(0.2).timeout to replay a search; a RefCounted Graph (data) separate from the Node3D renderer.
- **Lineage:** Processing: None. NoC: None. Application: WP3 graph theory ('How do we navigate an auto-generated world?'). Klee: None. Reference: Form+Code 'Visualize: Displaying Data' [V code example]; Code Societies, 'Building Nets for Floating Data' [V session title]; Chun, Discriminating Data [mem].
- **Departure:** graphtheory is spine 22 but comes here, before the simulation sequences: Form+Code's Visualize is where relations become pictures, and the 2023 application puts graph theory in WP3 with world building. The graph returns at ch34, where a body must walk one.
- **Project step:** Draw your hall's route network as a graph and colour the node every route passes through.

#### 27. Visualize a judgment: classification and its bias

- **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Classification (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (carrier); ML_Perception (field trip).
- **CODE:** new sorting, json; returns dictionaries, arrays, uv, save_load, ui, materials.
- **BODY:** A floor painted by a k-nearest-neighbour classifier: labelled sample bodies stand on it, and every floor pixel takes the colour of the majority of its k nearest samples (sorted by distance).
- **ARGUMENT:** axis *k (neighbours consulted)*, values 1 / 3 / 7 / 15 / 31. PREDICT: 15 and 31 will look most alike: the boundary is smooth and the lone minority sample's island has been swallowed; k = 1 keeps every outlier. CLAIM: *Smoothing a judgment erases its minorities: as k grows, the lone sample's region disappears.*
- **DEBT:** Machine-learning models are always biased (Queer 3D). k is a politics of neighbourhood, and the labelled data is the dark spot: whoever labelled the samples decided the floor. Collect and label your own tiny dataset of bodies first (Feminist Data Set).
- **PLACE:** Stand on it: walk onto the floor and become a sample, so your position is classified; the bias hall's perspective blend lets you see a cluster from inside.
- **Godot:** Array.sort_custom() by distance; an Image written per pixel, an ImageTexture on a floor quad; JSON.stringify() and JSON.parse_string() to save the labelled samples; a Button to add a sample of the other class.
- **Lineage:** Processing: None. NoC: NoC 10 classification, previewed. Application: WP3 neural networks (preview); Queer 3D's 'models are always biased'. Klee: None. Reference: Form+Code 'Visualize' [our placement]; Sinders, Feminist Data Set; Queer 3D World 2024, the debt layer.
- **Departure:** machinelearning (21) and postfoundationscrisis (25) are visited early for one judgment made visible: a classifier is a picture before it is a learner, and bias belongs beside the other pictures that hide their choices. Learning returns at ch35, and the critical halls at ch36.
- **Project step:** Classify something in your hall (routes, kinds of body) and show what the smoothing erased.

### Simulate

#### 28. Forces: your own integrator

- **Spine:** forces. **Halls:** Vectors_Act3_FieldsAndMotion (carrier); VFM_03_Motion (carrier); Vectors_Act4b_Oscillation (carrier); Vectors_Act5_ForceAsPlace (carrier); VFM_05_Launch (field trip).
- **CODE:** new forces, integration; returns vectors, physics_bodies, areas, delta, classes, trig.
- **BODY:** A Mover class with position, velocity and acceleration: apply_force() accumulates and a fixed-step integrator moves it. Then the same mover as a RigidBody3D with apply_central_force(), then an Area3D that replaces gravity.
- **ARGUMENT:** axis *integration step on a damped spring (trail still)*, values 1/15 s / 1/30 s / 1/60 s / 1/120 s / 1/240 s. PREDICT: 1/120 and 1/240 will look most alike; at 1/15 explicit Euler gains energy and the trail spirals outward instead of settling. CLAIM: *An integrator is a physics of its own: a coarse step invents energy, and the trail is the method's signature.*
- **DEBT:** Engine physics is an approximation you did not write: sleeping, tunnelling at speed, settling that depends on the tick rate (an Ada die read 15/16 at 90 Hz and 2/16 at 60 Hz). Explicit Euler invents energy.
- **PLACE:** Become it: step into the force-field zone (its law axis: gravity, flow ...) and let it carry your body across a chasm (Vectors_Act5_ForceAsPlace).
- **Godot:** velocity += acceleration * dt; position += velocity * dt (semi-implicit Euler); a fixed-step accumulator in _physics_process; RigidBody3D.apply_central_force(), mass, linear_damp; Area3D gravity_space_override.
- **Lineage:** Processing: Handbook 'Simulate 2: Physics'. NoC: NoC 1-3 (Vectors, Forces, Oscillation). Application: Vectors (l.9); WP4 chaos, previewed (sensitivity to the step). Klee: III the gravitational curve (bullet, stone, meteor). Reference: Form+Code 'Simulate: Particles' [V code example]; NoC ch2 'Forces'.
- **Departure:** forces (spine 7) comes at chapter 28, much later than its spine place, because the anchor puts Simulate last and because an integrator the student writes needs classes (ch18), packed arrays (ch17) and the pendulum's trig (ch16). Vector arithmetic was met at ch4-5, where the spine's forces halls first use it.
- **Project step:** Make one place in your hall where forces differ, and let a visitor's body feel it.

#### 29. Particles and aggregation: many short lives build one body

- **Spine:** randomness, proceduralgeneration, softbodies. **Halls:** Random_Walk (carrier); Random_Gaussian (carrier); PG_Sculpted_Forms (carrier); SoftBodies_Affect_Theory_Visualization (field trip); Random_Game (encounter).
- **CODE:** new particles, lifetime; returns random, seeds, forces, integration, multimesh, surface_tool.
- **BODY:** Diffusion-limited aggregation: random walkers are released, wander, and freeze when they touch the growing cluster; the frozen walkers are skinned into one mesh. Beside it, a GPUParticles3D emitter shows what short lives look like when nothing is kept.
- **ARGUMENT:** axis *stickiness (probability of freezing on contact)*, values 1.0 / 0.5 / 0.2 / 0.05. PREDICT: 0.2 and 0.05 will look most alike (both dense coral); 1.0 gives the thin, branching fern. CLAIM: *Stickiness trades branching for mass: the less a walker commits, the more solid the body it builds.*
- **DEBT:** A particle's life is a design parameter (lifetime, emission shape). GPU particles are pictures, not bodies: they collide with nothing but a heightfield or SDF. DLA is slow because every walker is a random walk, which is the cost of chance. Compare randfn() with a hand-written Box-Muller.
- **PLACE:** Walk around it: the coral grows over minutes in your hall, and a visitor's hand can seed it (touch makes a sticky point).
- **Godot:** an Array of walkers: spawn, age, remove_at(), queue_free(); GPUParticles3D: amount, lifetime, ParticleProcessMaterial, emission shape; randfn() against Box-Muller; freeze and skin: SurfaceTool over the frozen positions.
- **Lineage:** Processing: Handbook 'Simulate 1: Biology'. NoC: NoC 0 random walks (return); NoC 4 Particle Systems. Application: WP1 particle systems; WP1 randomness (return). Klee: None. Reference: Form+Code 'Simulate: Diffusion-Limited Aggregation' [V code example]; Levin & Brain 'Unpredictability' (drunk walk).
- **Departure:** A declared return to randomness (spine 10): the walks and distributions the spine teaches in its randomness sequence come back as the engine of a body, after chance was first met in the grid (ch11). Particle systems, which WP1 lists and no spine hall teaches, get their home here.
- **Project step:** Grow one body in your hall by aggregation. Fix the seed so it grows the same for everyone, or don't, and say why.

#### 30. Balance: form found by force, and a first complete game

- **Spine:** formfinding. **Halls:** FormFinding_Forge (carrier); FormFinding_Equilibrium (carrier); FormFinding_Relaxation (field trip); VFM_09_Legs (field trip).
- **CODE:** new state_machines, groups; returns physics_bodies, signals, recursion, seeds, save_load, audio, ui, player, export_build.
- **BODY:** A stack of grabbed RigidBody3D stones that must settle, and a recursive Calder mobile whose pivots are solved and then hung for real with joints.
- **ARGUMENT:** axis *top stone's centre-of-mass offset as a fraction of its half-width (still after 3 s)*, values 0 / 0.25 / 0.45 / 0.55 / 0.8. PREDICT: 0.45 and 0.55 will look most alike before release and split after it: one holds, one topples. 0 and 0.25 stay alike. CLAIM: *Balance is invisible until it fails: the tipping point is at the edge of the support, not where the eye expects it.*
- **DEBT:** Physics decides 'settled' by a threshold (sleep), so the game's judgment is a number. The solved mobile balances in the solver but not always in the engine: two models of one body disagree.
- **PLACE:** Carry it: stack the stones with your hands (XR grab); the tightrope walker is the scale. The whole loop runs: menu, play, win (stones settled), score saved, replay, exported as a build.
- **Godot:** enum State { BUILDING, SETTLING, SOLVED, FAILED } with match; add_to_group('stones'); get_tree().get_nodes_in_group(); RigidBody3D.sleeping or a linear_velocity threshold for 'settled'; the small complete game: UI score, AudioStreamPlayer, best score saved to user://, export.
- **Lineage:** Processing: Learning Processing ch10 (algorithms: a small game taken apart). NoC: NoC 6 Physics Libraries. Application: None. Klee: II disturbed and corrected balance, stacked toppling stones; III 'to stand despite all possibilities to fall'. Reference: Form+Code 'Simulate' [mem]; Moholy-Nagy's balance studies; Calder; Squash the Creeps parts 7-8 (game states, score, replay).
- **Departure:** formfinding (spine 8) follows forces (ch28) as in the spine, but late overall; see ch28. It is also where the small complete game is assembled, because a balance puzzle has a natural win state and needs no enemies.
- **Project step:** Give your hall a goal: a state it can be put into, recognized, saved and replayed.

#### 31. Rules that grow: automata and grammars

- **Spine:** cellularautomata, lsystems, fractals. **Halls:** CA_Introduction (carrier); CA_GameOfLife (carrier); LSystems_Grammar_Lab (carrier); LSystems_Growth (carrier); Fractal_KochSierpinski (field trip); CA_AgentsCircuits (field trip).
- **CODE:** new buffers, stacks; returns arrays, strings, dictionaries, recursion, multimesh, collision.
- **BODY:** A 1D automaton whose history is stacked into a walkable bridge (each live cell a floor tile), and an L-system turtle whose [ and ] push and pop a stack of {pos, dir} to grow a plant.
- **ARGUMENT:** axis *elementary rule number*, values 30 / 90 / 110 / 184 / 250. PREDICT: 30 and 110 will look most alike at a glance (both irregular, triangle-filled histories), though 30 is chaotic and 110 is structured; 90 (Sierpinski) and 250 are the most regular. CLAIM: *Two neighbours and one number decide a world: a rule becomes visible only as the history it grows.*
- **DEBT:** Synchronous update is a fiction kept up by a double buffer; update in place and the body changes (CA_ExpandingSpace compares the two). A grammar grows exponentially and has to be capped with a symbol budget, so recursion must be controlled again.
- **PLACE:** Walk on it: the CA bridge whose gaps are the rule's holes, which you can fall through.
- **Godot:** two arrays (current, next) and a swap: double buffering; an Array used as a stack: push_back() / pop_back() of a Dictionary state; string rewriting: for c in s: out += rules.get(c, c); history as a MultiMesh; one merged collider.
- **Lineage:** Processing: Handbook 'Simulate 1: Biology' [mem]. NoC: NoC 7 Cellular Automata; NoC 8 L-systems. Application: WP2 L-systems, cellular automata. Klee: I.11 propagation. Reference: Form+Code 'Simulate' (Conway's Life) [mem]; Munari's 'mad branch'.
- **Departure:** A declared return: fractals (recursion at ch12) come back as rules (Rule 90's Sierpinski in CA_AgentsCircuits). cellularautomata and lsystems are taught together because both apply a rule to a whole state at once.
- **Project step:** Let one body in your hall be grown by a rule you can write in one line.

#### 32. Soft bodies: polycount against deformation

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); SoftBodies_Cloth_Physics (carrier); SoftBodies_Playground_of_Joy (field trip); ProceduralGeneration_Reaction_Diffusion_Systems (field trip); Topology_Entropy_Morphogenesis (encounter).
- **CODE:** new timers; returns physics_bodies, export, profiling, setters, signals.
- **BODY:** A SoftBody3D jelly made from a subdivided box, pinned at two points, with stiffness and pressure exported; a cloth whose pins are released by a Timer.
- **ARGUMENT:** axis *subdivisions of the jelly (still taken while it is struck)*, values 1 / 2 / 4 / 8 / 16. PREDICT: 8 and 16 will look most alike at rest and when struck; 1 and 2 dent as rigid facets, because only enough vertices can bend smoothly. CLAIM: *A body can only deform as smoothly as its polycount allows: the application's topology question in one still.*
- **DEBT:** Polycount against smooth deformation, the application's own phrase. The solver's stiffness is not a material (rubber is a number). A soft body costs per vertex, so the headset frame budget comes back.
- **PLACE:** Touch it: press the jelly with your hand (XR), walk through hanging cloth, play in the Playground of Joy.
- **Godot:** SoftBody3D from a subdivided BoxMesh: simulation_precision, pressure_coefficient; set_point_pinned(); a Timer node: one_shot, the timeout signal; frame time per subdivision in the Profiler.
- **Lineage:** Processing: None. NoC: NoC 6 soft bodies (toxiclibs); a course week, no book chapter. Application: WP2 soft body simulation (cloth, liquids, rubber); polycount (l.89); Turing's morphogenesis (reaction-diffusion field trip). Klee: I.9 bone, tendon, muscle: soft tissue. Reference: Form+Code 'Simulate' [mem]; Bellmer and Bourgeois as lineage for deformable bodies (Queer 3D).
- **Departure:** Back in spine order (softbodies 17 after lsystems 15). It only looks like a step back because ch25-27 visited isosurfaces, graphs and classification early, and those departures are declared there.
- **Project step:** Give your hall one body that deforms when touched, at the polycount your frame budget allows.

#### 33. Collective bodies: flocks and swarms

- **Spine:** swarmintelligence. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_PhysarumColony (carrier); Random_Pheromone (field trip); SwarmIntelligence_Swarm_Intelligence_Algorithms (field trip).
- **CODE:** new inheritance; returns classes, forces, multimesh, profiling, groups, state_machines, dictionaries.
- **BODY:** A flock: an Agent base class with steer(); Boid and Ant extend it and override perceive(); all drawn as one MultiMesh.
- **ARGUMENT:** axis *separation weight*, values 0 / 0.5 / 1.5 / 3 / 10. PREDICT: 0 and 0.5 will look most alike (a clump); at 10 the flock becomes a lattice of lonely birds. CLAIM: *Separation alone decides whether many bodies read as one: a flock's shape is a negotiation of weights.*
- **DEBT:** Emergence is authored: someone chose the weights. Inheritance fixes a family tree of agents, so the base class decides what every agent can perceive. A swarm model of people is a politics.
- **PLACE:** Walk among them: your body is an obstacle or a leader, the player as a boid.
- **Godot:** class_name Agent; extends Agent; override a method; super(); neighbour search with a spatial hash (a Dictionary of cells); a MultiMeshInstance3D updated every frame; Profiler: nodes against MultiMesh at 30, 300 and 3000 agents.
- **Lineage:** Processing: Learning Processing ch22 (inheritance). NoC: NoC 5 Autonomous Agents (flocking). Application: WP4 swarm intelligence. Klee: None. Reference: Form+Code 'Simulate' [mem]; Reynolds, Boids (1987) [mem].
- **Departure:** Back in spine order (swarmintelligence 20 after softbodies 17); the apparent inversion comes from the declared early visits at ch25-27.
- **Project step:** Let a population live in your hall and decide what it does when a visitor arrives.

#### 34. Navigate a generated world

- **Spine:** proceduralgeneration, graphtheory, lsystems. **Halls:** PG_Caves_Mazes (carrier); GT_Pathfinding (carrier); GT_Spanning_Trees (field trip); LSystems_Architecture (field trip).
- **CODE:** new navigation; returns graphs, search, random, seeds, player, collision, stacks, await.
- **BODY:** A maze carved by a seeded depth-first backtracker (a stack) or by Kruskal, given walls and a baked NavigationMesh; a NavigationAgent3D with the player's radius finds a route.
- **ARGUMENT:** axis *maze algorithm on the same grid*, values DFS backtracker / Kruskal / Prim / random-walk cave / 10 PRINT (from ch11). PREDICT: Kruskal and Prim will look most alike (short dead ends, an even texture); the DFS backtracker gives long corridors and is the outlier. CLAIM: *A maze algorithm has a handwriting: the same grid carved by two methods gives two different walks.*
- **DEBT:** A route in the array is not a route for a body: a path can exist in the graph and not for a capsule of radius 0.4 (the Ada walk map cannot see CSG collision). Navigation assumes a default body (radius, height, step), so who fits?
- **PLACE:** Walk it: get lost in your own generated maze; the agent shows the way it thinks a body goes.
- **Godot:** NavigationRegion3D, bake_navigation_mesh(), NavigationAgent3D; AStar3D or AStarGrid2D; agent_radius equal to the player capsule; maze generation spread over frames with await.
- **Lineage:** Processing: None. NoC: NoC 5 path following. Application: WP3 'How do we navigate an auto-generated world?'; procedural generation; graph theory. Klee: None. Reference: Form+Code 'Simulate' [our placement]; 10 PRINT ch65 'Maze Walker in BASIC'.
- **Departure:** graphtheory (22) returns here beside proceduralgeneration (16): a declared return from ch26, where graphs were drawn, to now, where a body must walk one.
- **Project step:** Generate part of your hall and prove the supplied body can always reach the exit.

#### 35. Bodies that learn

- **Spine:** machinelearning. **Halls:** ML_Evolution (carrier); ML_Neural_Networks (carrier); ML_Gradient_Landscape (carrier); PG_Genetic_Evolution (encounter).
- **CODE:** new threads; returns resources, random, seeds, surface_tool, classes, profiling, timers, multimesh.
- **BODY:** A population of genome creatures (from ch21) that reproduce on energy with no fitness function, beside one bred by a fitness function; a tiny network whose weights are drawn as cylinder thickness while it trains on a worker thread.
- **ARGUMENT:** axis *selection pressure*, values none (energy only) / weak / medium / strong / single champion. PREDICT: strong and single champion will look most alike after 50 generations (a monoculture); 'none' keeps the most kinds. CLAIM: *A fitness function is a norm: the stronger the selection, the fewer bodies remain possible.*
- **DEBT:** A fitness function decides which bodies deserve to live. Training data and loss are the dark spot. A worker task must be waited on before it is released (an Ada trap), and in the headset the frame must never stall.
- **PLACE:** Walk among them: the evolving population lives in your hall. If a visitor's gaze becomes the fitness function (look at a creature and it breeds), argue whether that is fair.
- **Godot:** WorkerThreadPool.add_task() and wait_for_task_completion(); Thread; call_deferred() to hand results to the scene (the main-thread rule); crossover and mutation over Resources; Timer-driven training batches.
- **Lineage:** Processing: None. NoC: NoC 9 Evolutionary Computing, 10 Neural Networks, 11 Neuroevolution. Application: WP3 neural networks and evolutionary algorithms; WP4 algorithmic life and AI; Turing's B-type machines. Klee: None. Reference: Form+Code 'Simulate' [mem]; Sims, Evolved Virtual Creatures [mem].
- **Departure:** A declared return: machinelearning (21) was first met at ch27 as a picture (a classifier); here it comes back as learning, in spine order after swarms (20).
- **Project step:** Plan your final project now, two chapters before the end (Aesthetic Programming's flowchart unit): a one-page flowchart of your hall and its argument.

#### 36. Critical simulation: what the model cannot hold

- **Spine:** foundationscrisis, qfeplaboratory, postfoundationscrisis. **Halls:** Godel_Incompleteness (carrier); NonEuclidean_Spaces (carrier); PostCrisis_Synthesis (carrier); Escher_Impossible (field trip); QFEP_Edge_Of_Chaos (field trip); CriticalAlgorithms_Applied_Ethics (field trip).
- **CODE:** new files; returns raycasts, shaders, uniforms, camera, signals, save_load, json, testing.
- **BODY:** A non-Euclidean triangle whose angle sum is set by a curvature uniform, beside an impossible body (Penrose triangle, Escher staircase) that is whole from one camera position only; a signal fires when you are aligned.
- **ARGUMENT:** axis *curvature of the triangle's space*, values -1 / -0.3 / 0 / 0.3 / 1. PREDICT: -0.3, 0 and 0.3 will look most alike on a small triangle: curvature only shows at scale. CLAIM: *Space bends only at a scale: a small enough triangle is always Euclidean, which is why the flat assumption goes unnoticed.*
- **DEBT:** The model's limits become content: 'not found within budget' is not 'unprovable' (Godel, the halting problem); an impossible object is possible from one viewpoint only (the camera as the condition of truth); the sightline check asks who the room's shape excludes. Chun's sourcery again: open code still hides.
- **PLACE:** Become it: walk the impossible staircase. The museum reads back a record you left in an earlier hall, state that survives the hall.
- **Godot:** FileAccess read and write in user:// across scene changes; get_viewport().get_camera_3d() alignment test and a signal; a per-frame step budget for an unbounded search; curvature as a vertex-shader uniform; collision stays flat.
- **Lineage:** Processing: None. NoC: None. Application: WP4 non-Euclidean spaces, chaos; paradox, infinity and entropy (2022 prototype). Klee: None. Reference: Code Societies, 'Critical Simulation' (Nora Khan) [V session title]; Form+Code has no chapter here: an Ada addition; Queer 3D ontology layer ('impossible possible space').
- **Project step:** Write your hall's final.md: the argument, the prediction you got wrong, and what the model cannot hold.

#### 37. Synthesis: your hall in the endless museum

- **Spine:** qfeplaboratory, postfoundationscrisis. **Halls:** QFEP_Sandbox (carrier); QFEP_Synthesis (carrier); Crisis_Synthesis (field trip); SpeculativeComputation_Rhizome_Network (field trip).
- **CODE:** new none (a synthesis, as in the Handbook); returns export_build, xr, import_assets, ai_assist, save_load, audio, ui, player, profiling, testing, export.
- **BODY:** The student's own hall: one family of bodies with one axis, placed where a body meets it, beside the class's other halls.
- **ARGUMENT:** axis *the student's own family axis (one exported field of their hall's main body)*, values value A / value B / value C / value D. PREDICT: Written and dated before the final render: which two will look most alike and why. Graded on the reasoning, not on being right; a prediction the render contradicts is worth the most. CLAIM: *One sentence the comparison sheet supports.*
- **DEBT:** A debt comment in the student's own code (after Marino's Climategate chapter [mem]) saying what the approximation owes, and one post in the class's code-critique thread (a snippet, its context, one question).
- **PLACE:** The hall joins the class's endless museum and is walked in the headset by the class.
- **Godot:** a Quest build and a desktop build; frame time at 72/90 Hz; a headless test of the family's claim; a ReadMe beside the code in Git.
- **Lineage:** Processing: Handbook 'Synthesis 4'. NoC: NoC's Ecosystem Project (creatures for a museum exhibit). Application: All four work packages as a menu. Klee: The book as a whole: element to energy. Reference: Form+Code (the essay plus precedent gallery per theme, as the model for the final.md); Aesthetic Programming's final project (artifact plus ReadMe).
- **Project step:** Final project shown to the class: the hall, the sheet, the claim, the debt comment.

## What it learned from comparable courses

- Form+Code (the anchor) [V themes and code examples]: name the parts by what code does to form, not by language feature. Repeat before Transform (the opposite of spine 2-3); recursion filed under Repeat; Parameterize as its own verb, which Ada's spine lacks although 74% of its scripts are built that way. Each theme has an essay and a precedent gallery, the model for each chapter's lineage and for the final.md. The anchor has no exercises, no skill ladder and no critique, so the course had to add all three.
- Processing Handbook, 1st ed. [V]: a Synthesis checkpoint closes each part (ch6, ch12, ch17, ch21, ch37), and there are two tables of contents: the course's reading order and a by-spine index (in the markdown), so a departure shows as a jump in spine numbers. Static before continuous is kept only partly, because Godot calls your code from Point Zero on.
- 10 PRINT [V contents]: Regularity comes before Randomness, so chance sits straight after the grid and the tile (ch11), not at spine place 10. 'Ports' become declared returns (the tile ported to a shader at ch24), and 'Maze Walker' becomes a place (ch34).
- Code as Creative Medium [V/agg]: Unpredictability after iteration and conditionals; named body prompts for the short-track mini project (Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic); short exercises (CODE) kept apart from open assignments (BODY plus ARGUMENT); 'Computing without a Computer' as Day Zero.
- Aesthetic Programming [V]: a critical theme tied to each piece of syntax with no separate theory track, which is how DEBT sits inside each chapter; pause weeks in the long track; the final project planned two units before the end (ch35); the ReadMe beside the code in Git (ch37).
- Critical Code Studies (Marino) and CCSWG [V]: the lookup table as a code-critique station modelled on Kittler's raytracer (ch25); a confessing debt comment in the student's own code (Climategate [mem]); 'describe a body in a single class' (ch18); write first, then read the debt; the forum-style critique thread (ch37).
- Montfort, Exploratory Programming [V]: errors on day one ('valid and intentional are different', ch1); 'Critique My Starter Programs' turned on Godot's own capsule player (ch14).
- Recreating the Past (SFPC) [V]: recreate a precedent (Nees's Schotter, Molnar, 10 PRINT, Durer's Melencolia) as the baseline for the ARGUMENT, with the difference as the DEBT; its close in Body and then Glitch/Deformation mirrors this course's close in soft bodies and critical simulation.
- Code Societies (SFPC, 3 weeks) [V]: the short track's length and guest-session rhythm; 'Critical Simulation' as the model for ch36, the Ada addition Form+Code lacks.
- Klee, Pedagogical Sketchbook [V via the braid's OCR read]: pendulum, circle, spiral is one derivation (ch16, under Transform); balance and falling (ch30); Part I's bone, tendon and muscle (ch13); the book ends in colour, which supports colour late as a system (ch22).
- Albers, Interaction of Color [V]: fix the material and vary one thing (the family); 'one colour appears as two' as ch22's argument.
- Gaboury, Image Objects [V contents]: the default body (ch3, ch14), the frame buffer (ch24) and object orientation (ch18) as chapter-grain debt readings.
- The Nature of Code [V]: a cumulative chapter-end project that is literally a museum exhibit of creatures, which is why project_step always adds to the student's hall; the NoC order is kept inside Simulate (forces, particles, physics libraries, CA, fractals-as-rules, agents, evolution, networks).
- GDQuest [V]: use before make (the SKETCH helper, the walker, the pickup are used first and opened later) and the skin/controller split (ch13), which is what lets the desktop body be swapped for the XR body.
- Chun, Programmed Visions [V contents]: 'sourcery' is named at the first supplied helper that gets opened (ch5) and again at ch36, so the course does not claim that reading code reveals everything.
- What no comparable course had and Ada supplies: a written, falsifiable prediction of the closest pair before every render (after dna.predicted_degeneracy), and the BODY and PLACE strands in 3D and VR. All the canon courses are 2D and web-first.

## Sieve notes on this candidate (not a score)

- **Thickens:** each chapter is named by what happens to a body, so a student who forgets the syntax can still say where they are ('I am repeating', 'I am making a family'). Parameterize becomes a named capacity. The spine never had it, and it is how Ada's bodies are actually made.
- **Forecloses:** some topics are split across verbs and a student meets them twice: colour is used at ch8 and taught as a system at ch22; chance is met at ch11 and returns at ch29; graphs are drawn at ch26 and walked at ch34. Forces come very late (ch28), so the first half of the course has motion only by transform and easing, never by cause. A student who arrives for physics waits two parts for it. Visualize pulls graphs (spine 22) and classification (21, 25) into the middle, which the spine keeps for the end.
- **Dark spot:** the anchor is a design book whose stance is formal, and 'what bodies are possible' is not its question. The queer and critical layer is carried by the DEBT field and the Ada additions (ch36), not by the verbs. If DEBT is taught thinly, the course falls back into Form+Code's formalism: beautiful families with no debt. The verb order also hides that a verb is a choice of lens; Simulate could as well be read as a politics (Code Societies) as a technique.

## Mechanical self-check (run on the JSON before returning)

37 chapters in 6 parts; every code id in the vocabulary is introduced once, all 85; no ladder violation; no chapter with more than 3 new ideas; every hall exists in spine.json (136 hall uses, 115 distinct halls); spine coverage 25/25. Order agreement with the spine is 0.76 over strict pairs by primary sequence, 0.86 counting ties as agreement and 0.85 excluding ties, inside the 0.6-0.95 band. 27 chapters carry a departure note. The game kit (player, input, camera, ui, save_load, audio, export_build, physics_bodies, instancing, signals) is complete by ch30, whose balance puzzle is the small complete game. xr, import_assets and ai_assist all arrive by ch11. The short track has 12 chapters and a mini project, and its skipped prerequisites are supplied and named.

## Verification notes

- [V] Form+Code's five themes, the ten code examples, the authors (with LUST), the publisher and 176 pages: formandcode.com, fetched 2026-10-01.
- [mem] 2010 publication year; the opening essays 'What is Code?' and 'Form and Computers'; which artists each essay discusses (Molnar and Nees under Repeat, Conway's Life under Simulate). The chapters mark these 'Form+Code ... [mem]'.
- Hall hooks and carrier axes come from `doc/book/iterations/claude-godot-path-2026-09-30/survey_bundle.json` and `braid/maps/ada.json` (pyramid base_sides and apex_stance, molnar_cube_study amount, the generator and fusion vocabularies, sphere tessellation, ca_rule_explorer rule, force_field_zone law). Precedents and course facts come from the braid research files, whose [V]/[mem] marks carry over.
- The maps `braid/maps/lineage.json` and `ada.json` appeared during the run and were used. Nothing in the Ada repo was edited, staged or committed.
