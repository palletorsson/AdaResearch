# Candidate c6_engine_geometry: Bodies from functions

*Geometry through code in an engine. Grown from one reference: Catlike Coding's progression (a graph of a function, mathematical surfaces, procedural meshes, pseudorandom noise, measuring performance), The Book of Shaders' order, and Sebastian Lague's Coding Adventures. Bodies from mathematics first; the museum's halls as carriers and field trips.*

Written 2026-10-01 for the braid auto-research run. Marks: **[V]** checked this session, either in the research sweeps (which name their sources) or in Ada's own files (spine.json, survey_bundle.json, maps/ada.json, maps/lineage.json); **[mem]** recalled and not checked. Nothing in the Ada repo was edited, staged or committed.

## Thesis (for the student)

Every body in this course is a function made visible. You begin with one point the engine keeps calling, then place many bodies by a function (a graph you can climb), then a field by a function of two numbers, then a jointed body that moves in time. You leave the grid for surfaces written as functions of (u, v), build the faces yourself, compare three ways of building one sphere, and turn your body into a family you can hold as a class. Next, light becomes a function (colour as a path, the first shader, pattern as symmetry), and only then chance, because a computer's randomness is also a function (a hash) and noise is chance that remembers its neighbours; this is the order in which engine and shader tutorials build geometry, and it is why randomness comes earlier here than in the museum. After that, bodies move by rules in time (forces, relaxation, oscillation, soft bodies), grow by rules applied to themselves (recursion, grammars, automata), appear from fields (marching cubes, carving), and choose (flocks, mazes, learning), until you reach where functions break (curved and impossible space) and the arc from order toward entropy. The museum's halls are where you see each idea at full scale; sometimes you visit them early, and each departure from the museum's order says why. Every chapter asks six things of you: build a body in code, make a family of it on one axis, write down before rendering which two will look most alike, make one comparison image and one sentence it supports, say what the approximation owes or hides, and put the body where another body meets it.

## The one idea behind the order

Engine and shader curricula agree on one ladder, and Ada's spine only partly follows it: **the dimensionality of the function**. A point is a constant. A graph is f(x). A grid or heightfield is f(x, z). A surface is (u, v) -> point. A mesh is the function tabulated as vertices and faces. A shader is f(uv) -> light. Chance is hash(position, seed). Noise is a smoothed hash. Motion is f(state, t) stepped by an integrator. Rules are f applied to its own output (recursion, grammars, automata). Implicit bodies are f(x, y, z) = 0. Choices are functions over structures (graphs, search, learning). Limits are where a function cannot decide.

Read against the spine this ladder:

- **agrees** on the opening (points, coordinates, lines, trace) and keeps transformation early, because in Godot a node is a transform;
- **visits early** the sine graph (wavefunctions), the catenoid (formfinding), the first shader (shaders), and graph theory in the maze, each with its reason stated;
- **moves** randomness and noise ahead of change, forces, form-finding and waves (the Book of Shaders order and the 2023 application's WP1), after the regular grid and the tiling floor they need (10 PRINT: regularity before randomness);
- **adds** one chapter the spine has no sequence for, families as classes (C12), because 74 % of Ada's scripts are procedures with @export parameters;
- **returns** to the spine's own order for time and force (change, forces, form-finding, waves) and for most of the late halls.

Measured on this JSON, the order agrees with the spine in about 0.9 of chapter pairs (0.83 counting strict order only): related, not forced.


## Parts

- **I Plot** (chapters 1-8): A body at every value: one point the engine keeps calling, then many bodies placed by a function, a record of a walk, a grid of two numbers, and a jointed body that moves in time and can be worn in the headset.
- **II Surface** (chapters 9-14): Leaving the grid: surfaces from two numbers, faces you author yourself, one sphere built three ways, families you can hold as classes, and a body you did not build carving one you did.
- **III Appearance** (chapters 15-17): Light is a function too: colour as a path through a space, the first shader as the graph read as light, and pattern as symmetry, saved to a file.
- **IV Chance and field** (chapters 18-23): Pseudo-randomness is a function: hashes, distributions, noise, a ground you walk with your own walker, fields you see only in what they move, and a first complete round.
- **V Time and force** (chapters 24-27): Bodies moved by rules in time: your own integrator, relaxation until a form stands, the pendulum that becomes a spiral and a sound, soft bodies.
- **VI Rules, fields, choices, limits** (chapters 28-36): The museum's late halls as field trips: recursion, grammars, automata, implicit and carved bodies, flocks, mazes, learning, impossible space, and the arc from order toward entropy.

## Tracks

### Short track: bodies from functions in three weeks (3 weeks full-time (15 days): 13 studio sessions of about 3 hours plus own work; the mini project starts on day 11)

Chapters: C01, C02, C03, C05, C06, C07, C08, C09, C10, C12, C14, C18, C20

**Mini project:** An Extrapolated Body (Levin and Brain's prompt, in 3D): one body family of your own, built by one function you wrote (a graph, a surface, a mesh or a noise field), with at least one imported or scanned part, two exported axes, and a place where a visitor meets it (stand on it, walk through it, carry it, or wear it in the headset). It is shown to the class with its sweep sheet (3-5 values of one axis), the prediction written before the render, one comparison image, the one-sentence claim, and a debt comment in the code saying what the approximation owes. Export it as a build.

**Supplied and named:** base.tscn and the vr_staging walker (desktop body and XR body, opened only in the long track, C21); the SKETCH segment helper (segment.gd show_between()); the Point_Trace recorder kit; the sweep-sheet script (a row of N instances of a class, one axis varied, with a capture button); the random-definition kit; a Quest export preset; an optional game kit (score label, win and lose, replay, best score saved; sized like parts 2-3 and 8 of Godot's 'Your first 3D game'). Skipped chapters and what stands in for them: C04 (expressions, methods, errors: met as supplied lines, and the W01 break-it habit is kept in every session's planted bug); C11 (packed arrays: the scan's vertex array in C14 and the heightfield arrays in C20 are given as ready lines; types and profiling are not taught); C13, C15-C17 (uv, colour, shaders, saving: not needed for the mini project); C19, C21-C36 (the long track).

**Rhythm:** Week 1: C01+C02 (day 1), C03, C05, C06, C07. Week 2: C08 (first headset session), C09 (AI assist), C10, C12, C14 (scan, import, first export). Week 3: C18 and C20 as two short morning sessions (days 11-12), mini project from day 11, a guest session, and a showing on day 15.

### Long track: geometry through code in an engine, one year (about 36 teaching weeks over two terms: one chapter a week, with C23, C35 and C36 as pause weeks for synthesis and a review week at the end of each part)

Chapters: C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20, C21, C22, C23, C24, C25, C26, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36

**Capstone:** Capstone: a body family in your own hall of the endless museum with an axis from order toward entropy, walked by the visitor, shown in a headset build with its prediction, comparison image, claim and debt comment, and a README beside the code. It is proposed in C34, prototyped in C35 and shown in C36. The midterm is C23's round.

**Rhythm:** Each week follows PRIMM: predict (walk the carrier hall first and guess how it is built), run, investigate, modify one named line, make. Each week carries one planted bug whose message the student reads, a written prediction before the render, a comparison image and a claim, and a ReadMe beside the code in Git. Peer critique of each chapter's body happens in the forum-style thread (a snippet, its context, one question). my_room grows through the year into the student's hall.


## The ladder at a glance

| C | part | title | spine | code_new | argument axis | tracks |
|---|---|---|---|---|---|---|
| 01 | I | Point Zero: the engine runs your lines | primitives | statements, output, lifecycle | which lifecycle hook runs the counting line | short/long |
| 02 | I | Point One: a body is a node, a mesh and a boundary | primitives | variables, calling, collision | collider radius as a fraction of the visible radius | short/long |
| 03 | I | Coordinates: a position is only a position inside a frame | primitives | properties, vectors, transforms | which node the student moves by +1 on X | short/long |
| 04 | I | The line: a distance is a number only once you choose what to measure it against | primitives | expressions, methods, errors | the unit the label measures in | long |
| 05 | I | The graph: one function, many bodies | change, wavefunctions | loops, trig, conditions | the function f | short/long |
| 06 | I | The trace: a list of where a body has been | primitives | arrays, functions, input | the distance gate | short/long |
| 07 | I | The grid: a function of two numbers | primitives, array_tutorial | nested_loops, instancing, materials | cells per metre | short/long |
| 08 | I | The limb: pivots, a jointed body and time | transformation | basis, delta, xr | where the pivot sits on each segment | short/long |
| 09 | II | Mathematical surfaces: a library of functions | wavefunctions, formfinding | parameters, return, ai_assist | the surface function | short/long |
| 10 | II | The first face: vertices, triangles, and which side is out | primitives | meshes, surface_tool, normals | normals and winding on a 12-sided prism | short/long |
| 11 | II | One sphere, three constructions: polycount against smoothness | primitives | packed_arrays, types, profiling | construction at an equal budget of about 320 triangles | long |
| 12 | II | A family you can hold: a body type as a class | primitives, color | classes, export, tool_scripts | pyramid base_sides (Primitives_Melencolia's pyramid.gd) | short/long |
| 13 | II | Repetition is structure: a floor from one rule and one exception | array_tutorial, color | uv, booleans, dictionaries | rotation rule | long |
| 14 | II | Collage: a scanned body carves a procedural one | transformation, proceduralgeneration | import_assets, lifetime, export_build | carve radius in lattice cells | short/long |
| 15 | III | Colour as a number: a path through a colour space | color | interpolation, areas, signals | interpolation space between the same blue and yellow | long |
| 16 | III | Shaping functions: the first shader | shaders | shaders, uniforms, ui | the shaping function on the same UV ramp | long |
| 17 | III | Pattern: sixteen cells, four fabrics | tiling, shaders | json, files, save_load | wallpaper rule on the same 16 cells | long |
| 18 | IV | Hashing: randomness is a function | randomness | random, seeds, testing | hash quality | short/long |
| 19 | IV | Distributions: scatter, walk, and a maze you can enter | randomness | multimesh, await, physics_bodies | probability of the left-leaning wall | long |
| 20 | IV | Noise: chance that remembers its neighbours | noise, randomness | noise | noise type at the same frequency and seed | short/long |
| 21 | IV | fBm terrain: a ground you can walk, and the walker opened | noise, shaders | player, camera, composition | octaves | long |
| 22 | IV | Flow fields: a field you see only through what it moves | change, softbodies | particles | field frequency | long |
| 23 | IV | Synthesis: a round, the small complete game | randomness, formfinding, noise | state_machines, groups | warning time before a stone sinks | long |
| 24 | V | Forces: write your own integrator | forces | forces, integration | integrator | long |
| 25 | V | Form-finding: relax until it stands | formfinding | debugging | constraint iterations per step | long |
| 26 | V | Oscillation: pendulum, circle, spiral, sound | wavefunctions, fractals | audio, queues | radius growth per turn | long |
| 27 | V | Soft bodies: smoothness is bought with points | softbodies | setters, timers | subdivisions of the same cube | long |
| 28 | VI | Recursion: a body that contains itself | fractals, formfinding | recursion | length ratio per generation | long |
| 29 | VI | Grammars and the turtle: a body written as a word | lsystems | strings, stacks, resources | branching angle | long |
| 30 | VI | Cellular automata: a rule with a memory buffer | cellularautomata, shaders | buffers | Wolfram rule | long |
| 31 | VI | Implicit bodies: density, marching cubes, the blob, and carving | isosurfaces, boolean_surfaces | threads | smooth-min blend radius k between two spheres | long |
| 32 | VI | Flocks: many bodies, one rule each | swarmintelligence, forces | inheritance, raycasts | separation weight | long |
| 33 | VI | Mazes and paths: a route for a body through a generated world | proceduralgeneration, graphtheory | graphs, search, navigation | maze-carving algorithm on the same 15x15 graph | long |
| 34 | VI | Bodies that learn: a landscape made of error | machinelearning, postfoundationscrisis | sorting | k in k-nearest neighbours | long |
| 35 | VI | Impossible space: where the function breaks | foundationscrisis | (pause: returns only) | curvature | long |
| 36 | VI | Order toward entropy: the laboratory, and after | qfeplaboratory, postfoundationscrisis | (pause: returns only) | lambda (order toward entropy) along the student's own family | long |

## Chapters


### Part I: Plot

*A body at every value: one point the engine keeps calling, then many bodies placed by a function, a record of a walk, a grid of two numbers, and a jointed body that moves in time and can be worn in the headset.*

#### C01 Point Zero: the engine runs your lines

- **Spine:** primitives. **Halls:** Point_Zero (carrier)
- **Code new:** statements, output, lifecycle. **Returns:** none
- **Body:** A Label3D that states its own count, beside the box of the supplied base room (Day Zero's base.tscn: floor, camera, light). The first body is a readout that changes because the engine keeps calling your code.
- **Argument:** axis *which lifecycle hook runs the counting line*: _ready / _process / _physics_process (60 Hz) / _process with Engine.max_fps = 30. **Predict:** After 5 s, _process and _physics_process show the closest numbers (both about 300 on a 60 Hz screen), _ready stays at 1 and the capped one reads about 150. On a 144 Hz monitor the pair breaks, which is itself the point. **Claim:** The same line of code reports a different world depending on who calls it and how often.
- **Debt:** A frame is not a second. The count depends on the monitor, on the headset (72 or 90 Hz) and on whether anything is drawn at all (a headless run draws no frames). In its first hour the student meets the engine's first hidden approximation: its clock.
- **Place:** Stand beside the four labels in the base room with the supplied desktop walker. On the XR route (opened in C08) the same room runs in the headset through the supplied vr_staging scene, and the numbers jump to the headset's refresh rate.
- **Godot:** Label3D, _ready(), _process(delta), _physics_process(delta), print(), Engine.get_process_frames(), F5 / F6, Output panel
- **Lineage:** Processing: setup() and draw(): the engine calls you (Learning Processing ch 3). NoC: -. Application: -. Klee: I.1 before the walk: the point at rest. Reference: GDQuest Learn GDScript lessons 1-2 (what code is like; your first error) [V]; Catlike Godot intro 1 (a clock built in the editor before any code) [V]
- **Project step:** Open my_room (a copy of base.tscn) and leave one label in it that states something true about you.

#### C02 Point One: a body is a node, a mesh and a boundary

- **Spine:** primitives. **Halls:** Point_One (carrier)
- **Code new:** variables, calling, collision. **Returns:** statements, lifecycle
- **Body:** A point built in code in _ready(): a MeshInstance3D given SphereMesh.new(), and a StaticBody3D whose CollisionShape3D radius is set separately from the visible radius (the Point_One kit).
- **Argument:** axis *collider radius as a fraction of the visible radius*: none / 0.5 / 1.0 / 2.0. **Predict:** With debug collision shapes off, all four stills are identical, so every pair is the closest pair (0 % difference). With them on, 0.5 and 1.0 look most alike because the wire sphere sits inside or on the mesh. **Claim:** What you see and what stops you are two separate decisions, and the render shows only one of them.
- **Debt:** The render lies about the body: a collider is invisible, and a mesh is not solid. A ghost body (seen but not felt) and an invisible wall (felt but not seen) are each one line of code. Ada has a real case of the two drifting apart: the museum's walk map cannot see CSG collision.
- **Place:** Walk into each of the four points with the supplied walker (desktop or XR body): which one stops you, and at what distance?
- **Godot:** MeshInstance3D, SphereMesh.new(), StaticBody3D, CollisionShape3D, SphereShape3D, add_child(), Debug > Visible Collision Shapes
- **Lineage:** Processing: ellipse() and point() draw, but nothing collides (Learning Processing ch 1). NoC: -. Application: -. Klee: I.1 the point that sets off. Reference: GDQuest 'use before make': call supplied functions before defining your own [V]; Catlike Godot intro 2 [V]
- **Project step:** Put three points in my_room with one name and three different boundaries (the learner room in STUDENT_TOOLBOX.md).

#### C03 Coordinates: a position is only a position inside a frame

- **Spine:** primitives. **Halls:** Point_Coordinates (carrier)
- **Code new:** properties, vectors, transforms. **Returns:** variables, calling, collision
- **Body:** A point parented to a plinth. The student changes its X, Y and Z, then moves and turns the parent, and a label shows position next to global_position.
- **Argument:** axis *which node the student moves by +1 on X*: the child / the parent / the parent after turning it 90 degrees / the grandparent after scaling it by 2. **Predict:** Child and parent look most alike: both land the point at x + 1 in world space. The turned parent sends it along world Z, and the scaled grandparent doubles the step. **Claim:** A move is always a move inside some frame: the same +1 lands in four places.
- **Debt:** The world origin and the metre-scaled, Y-up frame are defaults, not facts. Far from the origin floats lose precision and bodies jitter (the Critical Engineering 'exploit'), and the frame is set up for a standing viewer.
- **Place:** Carry the point with the desktop hand ('pickup belongs to Point Coordinates') and watch global_position change while position stays put. The XR hand does the same from C08.
- **Godot:** Node3D.position, global_position, rotation_degrees, scale, to_global(), Transform3D, Vector3
- **Lineage:** Processing: translate() and pushMatrix() arrive late in the 2D traditions (Learning Processing ch 14); in Godot a node IS a transform, so the spine's early place is kept. NoC: NoC 1.1 'The Point of Vectors'. Application: -. Klee: II.14-17 dimension, and the vertical axis that shifts with the viewer. Reference: Catlike Basics 1: a clock whose arms turn inside their parent [V]
- **Project step:** Nest one body inside another in my_room and give the pair a single handle to carry.

#### C04 The line: a distance is a number only once you choose what to measure it against

- **Spine:** primitives. **Halls:** Point_Lines (carrier)
- **Code new:** expressions, methods, errors. **Returns:** properties, vectors, output
- **Body:** A segment between two movable points (drawn by the supplied SKETCH helper, segment.gd show_between()), with a label that computes b - a, its length and a.distance_to(b) while either end moves.
- **Argument:** axis *the unit the label measures in*: metres / grid cells of 0.25 m / hand spans (0.2 m) / standing heights (1.7 m). **Predict:** Metres and standing heights look most alike (both are single digits at room scale); cells and hand spans both run into the tens. **Claim:** A distance is a number only once you choose a body to measure it against, and the engine's metre has already chosen one.
- **Debt:** The metre and the default XR standing height (about 1.7 m) assume one body; seated, small and wheelchair-using bodies measure the same room differently (Bagnall's hardware chapter in Queer Game Studies [mem]). W01 is folded in here: break the line on purpose (add a string to a number, misspell a method) and read Godot's exact message.
- **Place:** Stretch the line between your two hands in XR, or between the walker and a point on desktop: you become one end of the measure.
- **Godot:** b - a, length(), distance_to(), str(), snappedf(), the Errors panel, the class reference (F1)
- **Lineage:** Processing: dist() (Learning Processing ch 7). NoC: NoC 1.5 magnitude. Application: -. Klee: I.2 a line limited by fixed points. Reference: Exploratory Programming ch 4 'valid and intentional are different' [V]; GDQuest lesson 2 (errors as help) [V]
- **Project step:** Add a measuring line to my_room in a unit that is a body you choose, and say why in one sentence.

#### C05 The graph: one function, many bodies

- **Spine:** change, wavefunctions. **Halls:** Change_Intro (carrier); WaveFunctions_Sine_Space (field trip)
- **Code new:** loops, trig, conditions. **Returns:** expressions, properties, calling, collision
- **Body:** A colonnade of 24 box pillars placed by a for loop, each pillar's height f(x) written inline (Catlike's 'Building a Graph', with bodies in place of pixels). One if decides which pillars are solid: where f(x) < 0 the pillar is a ghost with no collider (Point One's distinction as one condition).
- **Argument:** axis *the function f*: x (a ramp) / x * x (a parabola) / sin(x) / abs(sin(x)). **Predict:** sin(x) and abs(sin(x)) look most alike: they are identical wherever sin is positive, so half the pillars match exactly. **Claim:** A shape is a function you can swap without touching the loop; the colonnade is the function made walkable.
- **Debt:** Sampling: 24 pillars stand in for a continuous curve, so the graph is really a staircase. What happens between samples is hidden, and a sine sampled at the wrong spacing lies (aliasing). Noise_Space_10's octave ceiling, set by the mesh's Nyquist limit, is the same debt returning in C21.
- **Place:** Climb the colonnade with the walker: which function makes a stair you can climb, which makes a wall, and where do the ghost pillars let you fall?
- **Godot:** for i in range(n), sin(), PI / TAU, if / else, BoxMesh, StaticBody3D
- **Lineage:** Processing: the nested-loop and function-plot sketches (Learning Processing ch 5-6). NoC: -. Application: WP1 sine curves. Klee: I.5 rhythm as repetition. Reference: Catlike Basics 2 'Building a Graph' (a loop of cubes shows a function) [V]; The Book of Shaders ch 5 'Shaping functions' (a function plotted as a line) [V]
- **Departure:** An early visit: change (spine 6) and wavefunctions (spine 9) are drawn on in the opening part. Every engine curriculum grows from a graph to a surface, so sine enters here as a graph; its motion, sound and physics come back at C26. The ruling 'condition before a distance threshold' holds: the if is met here, one chapter before Point_Trace's gate.
- **Project step:** Floor one strip of my_room with a colonnade of your own function; keep the function in one line.

#### C06 The trace: a list of where a body has been

- **Spine:** primitives. **Halls:** Point_Trace (carrier); Point_Lines (encounter)
- **Code new:** arrays, functions, input. **Returns:** conditions, methods, vectors, loops
- **Body:** A recorder that keeps a capped, gated Array[Vector3] of where a carried point has been, drawn as a line strip by the supplied helper. keep() and pause run on named input actions (the Point_Trace kit). keep() is written first with no parameter; its keep(p) form is opened in C09.
- **Argument:** axis *the distance gate*: 0 m (every frame) / 0.02 m / 0.1 m / 0.5 m. **Predict:** 0 and 0.02 look most alike: at hand speed a frame moves about 1-3 cm, so the gate barely filters. At 0.5 m a curve becomes a polygon. **Claim:** A record is what the gate lets through: the gate is authorship, not neutral storage.
- **Debt:** Memory is bounded: pop_front forgets the oldest points without asking, so every trace is also a record of what was dropped. Rounding and capacity are choices about what a body's history is allowed to be.
- **Place:** Walk a path through my_room with the recorder in hand and leave your trace hanging in the air: Klee's point on a walk, drawn by your own body.
- **Godot:** Array[Vector3], append(), size(), pop_front(), func keep() -> void, InputMap actions, Input.is_action_just_pressed(), ImmediateMesh LINE_STRIP (supplied)
- **Lineage:** Processing: the pmouseX continuous line and a mouse-history array (Learning Processing ch 3, 9). NoC: -. Application: -. Klee: I.1 'an active line on a walk'. Reference: Point_Trace runnable kit (47 checks pass) [V ada.json]; GDQuest lesson 5 'your first function' before lesson 6 'parameters' [V]
- **Departure:** Point_Trace comes one chapter later than in /course: the loop (C05) is met first, so drawing the recorder's line is not a mystery. The rulings 'list before append' and 'condition before a distance threshold' hold.
- **Project step:** Record one walk through my_room and keep it as a line in the room.

#### C07 The grid: a function of two numbers

- **Spine:** primitives, array_tutorial. **Halls:** Point_Line_Grid (carrier); Array (field trip)
- **Code new:** nested_loops, instancing, materials. **Returns:** loops, trig, conditions, collision
- **Body:** A field of columns instanced from one PackedScene by two nested loops, heights f(x, z) = sin(x) * cos(z), coloured with two StandardMaterial3Ds by (x + z) % 2 (Catlike's step from a line to a 2D grid).
- **Argument:** axis *cells per metre*: 2 / 4 / 8 / 16. **Predict:** 8 and 16 look most alike from walking distance: past about 8 cells per metre the steps stop reading and a surface appears. The cost does not stop: 16 has four times the colliders of 8. **Claim:** Density makes the grid disappear into a surface, but the grid does not disappear from the budget.
- **Debt:** The grid is the engine's default world (Cartesian, orthogonal, repeatable) and it is not neutral: Klee calls such structure 'purely repetitive'. Each column carries its own collider, and 256 of them already cost frames (measured in C11). By the standing ruling the grid is not a prerequisite for the line, so it comes after the trace.
- **Place:** Walk across the field and find where f(x, z) stops holding a walker; visit Array's molnar_cube_study, where the same indexed lattice is given local departures.
- **Godot:** nested for, preload(), PackedScene.instantiate(), StandardMaterial3D.new(), albedo_color, material_override
- **Lineage:** Processing: the nested-loop grid (Learning Processing ch 6); Design By Numbers 'Dot' then 'Dots' [V]. NoC: -. Application: -. Klee: I.5-I.6 structure as repetition; the chessboard. Reference: Catlike Basics 2-3 (a line of cubes becomes a 2D grid) [V]
- **Project step:** Floor part of my_room with a grid of your own function of two numbers.

#### C08 The limb: pivots, a jointed body and time

- **Spine:** transformation. **Halls:** Trans_Rotation (carrier); Trans_Introduction (field trip)
- **Code new:** basis, delta, xr. **Returns:** transforms, properties, instancing, functions
- **Body:** Klee's bone and tendon as code: three box segments chained by pivot Node3Ds, each turning at its own rate * delta like the arms of Catlike's clock; then the chain is parented to a controller so it becomes an extra limb.
- **Argument:** axis *where the pivot sits on each segment*: at the end / at 3/4 / at the centre / at 1/4. **Predict:** The end and 3/4 look most alike: the chain still sweeps as an arm. At the centre each segment spins in place like a propeller and the chain stops reaching. **Claim:** A joint is a choice of where a body turns; move the pivot and the same rotation makes a different creature.
- **Debt:** Rotation is approximated twice over. Euler angles can lock (gimbal lock) and are not uniform when randomised (Random_Rotate_Random_XYZ), and a Basis multiplied every frame drifts away from orthonormal unless it is re-orthonormalised. delta makes motion independent of frame rate only as far as the tick allows.
- **Place:** Become it: on the XR route the limb hangs from your controller and swings as you move, in the first headset session (the supplied vr_staging scene and Quest export preset). On desktop the walker's hand carries it.
- **Godot:** Basis, rotate_y(), orthonormalized(), pivot Node3D, delta in _process, XROrigin3D / XRController3D (supplied vr_staging), Quest export preset (supplied)
- **Lineage:** Processing: rotate() inside pushMatrix(); Zoog as a body of parts (Learning Processing ch 1, 14). NoC: NoC 3 angular motion. Application: -. Klee: I.9-I.10 bone, ligament, tendon and muscle as passive, medial and active organs. Reference: Catlike Basics 1 'Game Objects and Scripts' (a clock from primitives, its arms rotated by time) [V]
- **Departure:** Transformation is spine 2. Here it follows the grid (the array_tutorial hall Array was visited in C07) because a pivot is a transform of a transform and needs several bodies to arrange. The clock is Catlike's first lesson; Ada puts it after the point-walk opening so the student arrives with coordinates and loops.
- **Project step:** Give my_room a moving body of at least three jointed parts, and name the joint that makes it a creature.


### Part II: Surface

*Leaving the grid: surfaces from two numbers, faces you author yourself, one sphere built three ways, families you can hold as classes, and a body you did not build carving one you did.*

#### C09 Mathematical surfaces: a library of functions

- **Spine:** wavefunctions, formfinding. **Halls:** WaveFunctions_Unit_Circle (carrier); FormFinding_Catenary (field trip)
- **Code new:** parameters, return, ai_assist. **Returns:** nested_loops, trig, instancing, functions, loops
- **Body:** Small spheres placed by two nested loops at surface(u, v), from a library of functions the student writes. Each takes (u, v) and returns a Vector3: plane, cylinder, sphere, torus, catenoid (Catlike's 'Mathematical Surfaces', which leaves the grid).
- **Argument:** axis *the surface function*: plane / cylinder / sphere / torus / catenoid. **Predict:** Cylinder and catenoid look most alike: a catenoid is a cylinder pinched at the waist, with the same topology and the same (u, v) loops; only the radius term changes. **Claim:** Five bodies are one loop with five return statements: the form lives in the function, not in the loop.
- **Debt:** The parametrisation is not the surface. The sphere's points bunch at the poles and thin out at the equator (uneven attention, which C11 measures), and every surface here is a cloud of samples you can walk straight through. AI assistance enters here: ask a model for a sixth function (a Möbius strip or a Klein bottle). Your prediction written before the render is the test: what should change, what must not, and what observation would show the code is wrong. Models often return a surface that is mis-scaled or self-intersecting where it should not be.
- **Place:** Stand inside the sphere and the torus of points: they surround you but do not hold you (a ghost body). The catenoid becomes a doorway to walk through.
- **Godot:** func surface(u: float, v: float) -> Vector3, return, match on an @export_enum (or a Callable), cos() / sin(), TAU
- **Lineage:** Processing: P3D beginShape(POINTS); Form+Code 'Parameterize' [V]. NoC: NoC 3 polar coordinates. Application: WP1 sine curves. Klee: IV.36-38 the pendulum becomes the circle. Reference: Catlike Basics 3 'Mathematical Surfaces' (function library, delegates + enum, line to grid, sphere and torus) [V]
- **Departure:** Draws early on wavefunctions (spine 9) and formfinding (spine 8): the circle and the catenoid are functions of angle, and a student who can loop over (u, v) can meet them now as shapes. Their motion and their physics return at C24-C26.
- **Project step:** Add one surface of your own function to my_room, with the AI-proposed variant beside it and your verdict on it.

#### C10 The first face: vertices, triangles, and which side is out

- **Spine:** primitives. **Halls:** Point_Triangle_Context (carrier); Primitives_Polythedra (carrier)
- **Code new:** meshes, surface_tool, normals. **Returns:** arrays, parameters, return, collision, materials
- **Body:** A triangle from three Vector3s with SurfaceTool, then an open corner (a trihedron), then a closed 12-sided prism from a vertex list and index triples, with generate_normals() and a ConvexPolygonShape3D made from the same points (Point_Triangle_Context; Primitives_Polythedra's grab_trihedron).
- **Argument:** axis *normals and winding on a 12-sided prism*: no normals / flat (one normal per face) / smooth (shared vertices, generate_normals) / flipped winding. **Predict:** No normals and flipped winding look most alike: neither lights the outside properly, and flipped faces are also culled, so from outside the prism turns see-through. **Claim:** A surface has a side: light and culling read the normal and the winding, not the shape.
- **Debt:** Culling is what the renderer decides not to draw (Gaboury, Image Objects ch 1 'Culling Vision'). Godot winds front faces clockwise, opposite to many tutorials, so a borrowed snippet can silently turn a body inside out. Smooth normals lie about a faceted body so that it passes for round.
- **Place:** Walk into the closed prism: from inside its faces are culled and you see out. Give it a collider and it becomes a room that holds you but that you cannot see.
- **Godot:** SurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES), add_vertex(), set_normal(), generate_normals(), commit(), ConvexPolygonShape3D, cull_mode
- **Lineage:** Processing: beginShape(TRIANGLES) / vertex() and PShape (Learning Processing ch 14). NoC: -. Application: WP2 'queer meshes and textures'. Klee: I.3-I.4 medial lines whose figures read as planes. Reference: Catlike Procedural Meshes 1 'Creating a Mesh' [V]; Godot docs 'Using the SurfaceTool' [V]; Gaboury ch 1 [V structure]
- **Departure:** Point_Triangle_Context and Primitives_Polythedra sit inside primitives (spine 1). Here they follow the surface library, because C09's point cloud gives the student a reason to want a face: a cloud cannot hold a body.
- **Project step:** Replace one point cloud in my_room with a closed mesh you can stand on.

#### C11 One sphere, three constructions: polycount against smoothness

- **Spine:** primitives. **Halls:** Primitives_Ignorance (carrier); Primitives_Portals (carrier)
- **Code new:** packed_arrays, types, profiling. **Returns:** meshes, surface_tool, normals, parameters, loops
- **Body:** A sphere built three ways into an ArrayMesh from a PackedVector3Array, all at the same triangle budget: a UV sphere, a cube sphere (a subdivided cube pushed out to the radius) and an icosphere (a subdivided icosahedron). Triangle counts are read back from surface_get_arrays(), and frame cost from the Profiler.
- **Argument:** axis *construction at an equal budget of about 320 triangles*: UV sphere / cube sphere / icosphere. **Predict:** Cube sphere and icosphere look most alike in wireframe, because both spread their triangles evenly. The UV sphere is the odd one: dense at the poles, coarse at the equator. **Claim:** The same sphere is three distributions of attention; the UV sphere spends its triangles where nobody looks.
- **Debt:** The 2023 application's question in one still: polycount against the possibility of deforming a body smoothly. Godot's default SphereMesh is a UV sphere, a standard object in the line of the Utah teapot (Gaboury ch 3), and the student inherits its choices. Smoothness is bought with triangles and paid for in frame time, measured in the Profiler rather than guessed.
- **Place:** Stand on top of each sphere (trimesh collider): at a low budget the UV sphere's facets tilt the walker at the equator and not at the pole. Primitives_Portals shows the same limit as a torus whose gap to a true circle halves with each doubling of segments.
- **Godot:** PackedVector3Array, PackedInt32Array, ArrayMesh.add_surface_from_arrays(), Mesh.ARRAY_VERTEX, typed variables (: float, : int), Profiler, Monitors / Performance.get_monitor()
- **Lineage:** Processing: sphereDetail() (P3D). NoC: -. Application: polycount against smooth deformation (application text). Klee: -. Reference: Catlike Procedural Meshes 5-10 (UV sphere, cube sphere, octasphere, geodesic, icosphere) [V]; Catlike Basics 4 'Measuring Performance' [V]
- **Project step:** Measure one body in my_room: write its triangle count and its frame cost on a label beside it.

#### C12 A family you can hold: a body type as a class

- **Spine:** primitives, color. **Halls:** Primitives_Melencolia (carrier); Color_Context_Placed (field trip)
- **Code new:** classes, export, tool_scripts. **Returns:** parameters, return, meshes, surface_tool, loops, instancing
- **Body:** The student's own body type as a class_name with @export axes that rebuild in the editor under @tool ('describe a body in a single class'). Then a sweep sheet: five instances in a row, one value each, as in Ada's DNA families.
- **Argument:** axis *pyramid base_sides (Primitives_Melencolia's pyramid.gd)*: 3 / 4 / 6 / 12 / 32. **Predict:** 12 and 32 look most alike: past about a dozen sides the family forgets it was a pyramid and reads as a cone. **Claim:** A category is a resolution threshold: the family slides from pyramid to cone without any line of code saying so.
- **Debt:** Which properties a body gets is the modelling choice, and it is political (Fuller and Goffey; the CCS working group prompt). @export turns everything into a slider and hides whatever was not exported. Object orientation itself grew out of graphics (Sketchpad's master and instance, Gaboury ch 4). A family's declaration must be derived from its code, never typed by hand: Ada's science_screen declared four values its code did not have, and every stage stayed green.
- **Place:** Place the family as a row along one wall of my_room and walk it: the visitor meets the axis as a walk.
- **Godot:** class_name, @export, @export_range, @export_enum, @tool, Engine.is_editor_hint()
- **Lineage:** Processing: classes, and Zoog as an object (Learning Processing ch 8). NoC: NoC 1 the Mover class. Application: -. Klee: I.7 proportion (2:3:5) as a family of divisions. Reference: Form+Code 'Parameterize' [V site]; Generative Design numbered variant series [V]; CCSWG 'describe X in a single class' [research_ccs]
- **Departure:** An addition: the spine has no families sequence, yet 74 % of Ada's scripts use @export (measured, BRIEF.md). It sits right after the first meshes because a family needs a body worth varying. Color_Context_Placed (spine 4) is visited for chroma_stack, whose @export_enum turns the Inspector into a colour-rule switch.
- **Project step:** Turn one body in my_room into a class with two exported axes, and make a sweep sheet of five.

#### C13 Repetition is structure: a floor from one rule and one exception

- **Spine:** array_tutorial, color. **Halls:** Tutorial_Tiling_Floor (carrier); Color_Grid_Pallet (field trip)
- **Code new:** uv, booleans, dictionaries. **Returns:** nested_loops, conditions, materials, instancing, classes
- **Body:** A Truchet floor: one diagonal tile image (Image.create and set_pixel) laid over a grid with a per-cell rotation rule, and a Dictionary from Vector2i to cell state that marks one exception cell as a ghost with no collider.
- **Argument:** axis *rotation rule*: all the same / (x + z) % 2 / (x + z) % 4 / (x + z) % 4 with one exception. **Predict:** (x + z) % 4 and the floor with one exception look most alike: one tile in 64 differs, and it can only be found because the rule around it is strict. **Claim:** Regularity is the ground on which one difference can be read; without the rule, the exception would be noise.
- **Debt:** Repetition shows its period: the eye catches the repeat and the UV seam. The rule also decides who counts as the exception. The ghost cell is a norm's hole, and the Sieve's third question (what lives in the dark spot) is literal here: someone falls through.
- **Place:** Walk the floor and find the exception by falling through it.
- **Godot:** Image.create(), set_pixel(), ImageTexture.create_from_image(), UV / uv1_scale, Dictionary keyed by Vector2i, bool, and / or / not
- **Lineage:** Processing: 10 PRINT puts 'Regularity' (ch 30) before 'Randomness' (ch 40) [V contents]. NoC: -. Application: -. Klee: I.6 'purely repetitive and therefore structural'. Reference: The Book of Shaders ch 9 'Patterns' [V]
- **Departure:** array_tutorial (spine 3) comes after the family chapter because the tile rule is a family axis applied to a floor. It is also the regular ground that chance needs in C18.
- **Project step:** Floor or wall part of my_room with a rule and exactly one exception you can defend.

#### C14 Collage: a scanned body carves a procedural one

- **Spine:** transformation, proceduralgeneration. **Halls:** Trans_Body (carrier); PG_Sculpted_Forms (field trip)
- **Code new:** import_assets, lifetime, export_build. **Returns:** packed_arrays, nested_loops, instancing, classes, meshes
- **Body:** A 3D scan or a Tilt Brush sculpture (Queer 3D's week-one material) is imported as glTF into a lattice of instanced cubes. Every cube whose centre lies within the carve radius of the scan's vertices (read from surface_get_arrays) is freed, so the imported body carves the procedural one (Trans_Body's carve_grid, made by the student).
- **Argument:** axis *carve radius in lattice cells*: 0.5 / 1 / 2 / 4. **Predict:** 0.5 and 1 look most alike: both leave a lattice that still reads as the scan's silhouette. At 4 the scan becomes a blob-shaped cave. **Claim:** Collage in code is a distance test: the radius decides whether the two bodies keep their own outlines or melt into one.
- **Debt:** A scan carries a different debt: tens of thousands of triangles of noise and holes, against a procedural body of a few hundred, with a topology nobody chose (who scanned whom, under which light, with what left out). queue_free() against hiding is the choice between deleting and keeping a record (Ribbon_Patterns_01's hide-versus-keep). Exporting is where 'it works on my machine' meets another machine: res:// becomes read-only and shaders compile again.
- **Place:** Walk through the carved cave in the shape of a body (your own, if you scanned yourself), then export the scene and open it on a classmate's machine or in the headset.
- **Godot:** glTF import (.glb) and the Import dock, mesh.surface_get_arrays(0), queue_free() vs visible = false, Project > Export (Windows; Android/Quest preset)
- **Lineage:** Processing: loadShape() and OBJ import (P3D). NoC: -. Application: WP2 'queer meshes and textures'. Klee: -. Reference: Queer 3D World 2024 (scanning, Tilt Brush, export) [V QUEER3D.md]; the Höch / Bellmer collage lineage it teaches [V QUEER3D.md]; Anthropy shares the first work in chapter 1 [research_queer]
- **Departure:** Trans_Body is a transformation hall (spine 2) used here as a collage station: carving needs a body the student did not build, and its vertex array. PG_Sculpted_Forms (spine 16) is an early field trip: physics bodies skinned into one mesh.
- **Project step:** Bring one imported body into my_room, make a procedural body answer it, and export my_room once.


### Part III: Appearance

*Light is a function too: colour as a path through a space, the first shader as the graph read as light, and pattern as symmetry, saved to a file.*

#### C15 Colour as a number: a path through a colour space

- **Spine:** color. **Halls:** Color_Walls (carrier); Color_Rainbow (carrier); Color_Paint (encounter)
- **Code new:** interpolation, areas, signals. **Returns:** materials, loops, classes, export, conditions
- **Body:** A strip of eight boxes coloured by interpolating between two colours, and an arch split into N bands by Color.from_hsv(i / N). An Area3D in the arch cycles N when a body walks through.
- **Argument:** axis *interpolation space between the same blue and yellow*: RGB lerp / HSV lerp / step (no interpolation) / perceptual lerp (supplied OKLab helper). **Predict:** RGB and perceptual look most alike, both being near-straight paths. HSV swings through green, and RGB's midpoint is the greyest. **Claim:** A gradient is a path through a colour space: the same two ends give different middles.
- **Debt:** Colour spaces encode a standard observer: sRGB assumes a monitor, the 1931 CIE observer averages a small sample of viewers, and photographic film was calibrated on light skin (the Shirley card). The midpoint is a political choice before it is a mathematical one. Albers: make two different colours look alike.
- **Place:** Walk through the arch: your body passing the Area3D recolours the room. This is the first time a body's presence changes another body.
- **Godot:** Color.lerp(), Color.from_hsv(), lerp(), Area3D, body_entered, connect(), signal (custom)
- **Lineage:** Processing: color(), lerpColor(), colorMode(HSB) (processing.org 'Color'). NoC: -. Application: -. Klee: IV.40-43 the colour circle (colour as energy comes back in C16). Reference: Albers, Interaction of Color: '2 different colours look alike' [research_bauhaus]; The Book of Shaders ch 6 'Colors' [V]
- **Project step:** Give my_room a colour rule that changes when a body enters.

#### C16 Shaping functions: the first shader

- **Spine:** shaders. **Halls:** Shader_01_Shaping (carrier); Shader_09_FBM (field trip); Shader_11_QueerRubber (encounter)
- **Code new:** shaders, uniforms, ui. **Returns:** trig, interpolation, conditions, export, signals
- **Body:** A wall whose brightness is f(UV.x), The Book of Shaders' plotted ramp, written in Godot's shading language. A uniform frequency is bound to a world-space slider. Then the same function moves VERTEX in vertex() on a subdivided plane, so appearance becomes shape.
- **Argument:** axis *the shaping function on the same UV ramp*: linear / smoothstep(0.2, 0.8, x) / pow(x, 5.0) / step(0.5, x) / 0.5 + 0.5 * sin(x * TAU). **Predict:** Linear and smoothstep look most alike: they agree at 0, 0.5 and 1 and differ only in the shoulders. **Claim:** A shader is the C05 graph read as light: one ramp gives five surfaces, and the loop now belongs to the GPU.
- **Debt:** The GPU is 'procedure crystallized' (Gaboury ch 5): the function runs once per pixel and cannot print, so debugging is by colour. A vertex shader moves what you see and not what you stand on: the displaced wall keeps flat collision (Shader_09_FBM lays a glass slab over moving water).
- **Place:** Walk alongside the displaced wall and touch it: the collider is still flat where the surface bulges. On the field trip, stand on the basin's glass above moving water.
- **Godot:** ShaderMaterial, shader_type spatial, fragment() / vertex(), UV, TIME, VERTEX, uniform float : hint_range, set_shader_parameter(), world-space slider (Ada's slider_horizontal.tscn)
- **Lineage:** Processing: PShader (processing.org 'Shaders'). NoC: -. Application: WP3 shading algorithms. Klee: IV colour as energy. Reference: The Book of Shaders ch 5 'Shaping functions', crediting Golan Levin's shaping functions and Kynd's table [V]
- **Departure:** Shaders are spine 12. Here they enter right after colour, in The Book of Shaders' order (shaping, colours, shapes, matrices and patterns before random and noise), and then return as a strand: pattern (C17), fBm (C21), reaction-diffusion (C30), curvature (C35). Ada's Shader_01-09 halls are BoS chapters 5-13 one to one [V repo].
- **Project step:** Give one surface in my_room a shader with one uniform the visitor can move.

#### C17 Pattern: sixteen cells, four fabrics

- **Spine:** tiling, shaders. **Halls:** Symmetry_Seventeen (carrier); Pattern_Foundry (carrier); Shader_05_Patterns (field trip)
- **Code new:** json, files, save_load. **Returns:** dictionaries, uv, nested_loops, shaders, uniforms, arrays
- **Body:** A 4x4 source tile of palette indices, baked into a 32x32 Image by a symmetry rule and laid on the walls and floor of a small room. The source is saved to user:// as JSON and restored on the next run.
- **Argument:** axis *wallpaper rule on the same 16 cells*: p1 (translation) / pm (mirror) / pg (glide) / p4 (quarter turns). **Predict:** pm and pg look most alike: both reflect the motif, and the glide only adds a half-tile shift that the eye reads as the same fabric at a glance. **Claim:** The eye names the symmetry, not the motif: sixteen cells become four fabrics.
- **Debt:** The seventeen wallpaper groups are a closed classification, proven complete. What falls outside (quasi-periodic Penrose tilings, the hand-made 'error' in a woven or tiled work) is excluded by the taxonomy, not by the world. Saving is where a body becomes data that has to be validated before it is trusted (write_text truncates before validating: a trap Ada fell into).
- **Place:** Stand inside your saved fabric: the room is walled with it. Wear it as the surface of the walker's skin, and become it.
- **Godot:** Image, ImageTexture, fract() / floor() in a shader (field trip), JSON.stringify(), JSON.parse_string(), FileAccess.open('user://...', FileAccess.WRITE), a version key in the saved Dictionary
- **Lineage:** Processing: saveJSONObject() / loadJSONObject() (Learning Processing ch 18). NoC: -. Application: WP3 pattern and world building. Klee: I.5 divisional articulation and rhythm. Reference: The Book of Shaders ch 9 'Patterns' [V]; 10 PRINT's REM variations [V contents]
- **Project step:** Save one pattern of my_room to a file and load it back in a fresh run.


### Part IV: Chance and field

*Pseudo-randomness is a function: hashes, distributions, noise, a ground you walk with your own walker, fields you see only in what they move, and a first complete round.*

#### C18 Hashing: randomness is a function

- **Spine:** randomness. **Halls:** Random_Definition (carrier); Random_Entropy (field trip)
- **Code new:** random, seeds, testing. **Returns:** nested_loops, functions, return, materials, conditions
- **Body:** A 16x16 grid of cubes whose heights come from hash(x, z, seed): first a weak hash written by hand, then RandomNumberGenerator with a seed. A headless check asserts that the same seed rebuilds the same grid (Random_Definition's 'a pattern that returns', a runnable kit).
- **Argument:** axis *hash quality*: x + z (a sequence) / (x * 73 + z * 19) % 16 (naive) / an xorshift without avalanche / RandomNumberGenerator with a seed (full hash). **Predict:** The naive hash and the xorshift without avalanche look most alike: both still show diagonal stripes. Only the full hash hides its pattern. **Claim:** Randomness on a computer is a function that hides its pattern well; a weak hash shows its stripes.
- **Debt:** Pseudo-randomness, Queer 3D's first debt: the same seed returns the same world, so 'random' is a repeatable decision, not chance. Nake's Hommage à Paul Klee (1965) put random numbers in place of intuition: can a hash stand in for intuition? Chun's 'sourcery' applies as well: seeing the RNG's code still hides its choices.
- **Place:** Schotter as a floor (Nees, 1968): a grid of stepping stones whose random offset grows row by row. Walk from order into disorder and mark the row where it stops being walkable.
- **Godot:** RandomNumberGenerator, seed, randi_range(), randf(), hash(), a check script run with godot --headless --script, assert()
- **Lineage:** Processing: random() and randomSeed() (Learning Processing ch 4, 13). NoC: NoC 0 randomness (the chapter the book opens with). Application: WP1 randomness (a basic element). Klee: - (randomness is absent from Klee; it enters with Nake in 1965). Reference: Catlike Pseudorandom Noise 1-2 'Hashing', where weak hashes show as stripes [V]; The Book of Shaders ch 10 'Random' [V]; Nees, Schotter [research_bauhaus]
- **Departure:** Randomness is spine 10. Here it comes before change, forces, form-finding and waves (spine 6-9), directly after pattern, as in The Book of Shaders (patterns, then random) and in the 2023 application, where randomness is WP1. The regular grid and the tiling floor come first (C07, C13) because randomness is only visible against regularity (10 PRINT).
- **Project step:** Seed one arrangement in my_room, print its seed on a label, and write a test that it returns.

#### C19 Distributions: scatter, walk, and a maze you can enter

- **Spine:** randomness. **Halls:** Randomness_10_PRINT_Algorithm (carrier); Random_Gaussian (carrier); Random_Cubes (field trip); Random_Walk (encounter)
- **Code new:** multimesh, await, physics_bodies. **Returns:** random, seeds, nested_loops, collision, conditions, arrays
- **Body:** 10 PRINT as a walkable maze: each cell of a 20x20 grid gets one of two diagonal walls from a seeded RandomNumberGenerator, drawn as one MultiMesh with colliders and built over several frames with await. Beside it, 1000 stones scattered by randf and by randfn, and a thrown die (RigidBody3D) whose face is read when it goes to sleep.
- **Argument:** axis *probability of the left-leaning wall*: 0.0 / 0.25 / 0.5 / 0.75. **Predict:** 0.25 and 0.75 look most alike: they are mirror images, the maze leaning the other way with the same amount of structure. 0.0 is pure regularity; 0.5 is the classic maze. **Claim:** The maze's character is one probability: its mirror is the same maze, and the extreme is the grid again.
- **Debt:** A die in the engine is not random either: its face depends on the physics rate (Ada measured one die read 15 of 16 throws the same at 90 Hz and 2 of 16 at 60 Hz). A Gaussian from randfn is a model of 'normal'; the tails are where the non-normal lives, and every distribution is a claim about who is typical.
- **Place:** Enter the maze (10 PRINT's 'Maze Walker' as a place): does p = 0.5 leave a route from one side to the other? Throw the die in its centre.
- **Godot:** MultiMeshInstance3D, MultiMesh.set_instance_transform(), await get_tree().process_frame, RigidBody3D, apply_impulse(), sleeping_state_changed, randfn()
- **Lineage:** Processing: 10 PRINT variations in Processing (REM 35) [V contents]. NoC: NoC 0 random walk, Gaussian and custom distributions. Application: WP1 randomness. Klee: -. Reference: 10 PRINT 'Randomness' and 'Maze Walker in BASIC' [V contents]; Code as Creative Medium, 'Unpredictability' exercises (coin toss, drunk walk, Ten Print) [research]
- **Departure:** randomness (spine 10), placed early as in C18.
- **Project step:** Let chance build one walkable part of my_room, and keep the seed.

#### C20 Noise: chance that remembers its neighbours

- **Spine:** noise, randomness. **Halls:** Noise_Perlin_Simplex (carrier); Noise_Columns (carrier); Random_Noise_Types (field trip); Random_Space_Geometry (encounter)
- **Code new:** noise. **Returns:** random, seeds, functions, return, surface_tool, packed_arrays, export
- **Body:** A row of columns and a small heightfield whose values come from FastNoiseLite behind one sample(x, z) function, which can be swapped for sin or for the C18 hash; frequency and octaves are exported.
- **Argument:** axis *noise type at the same frequency and seed*: value / Perlin / simplex / cellular (Voronoi) / hash (no interpolation). **Predict:** Perlin and simplex look most alike: both are gradient noise with rounded hills. Value noise is blockier, cellular noise is crystalline, and the hash is static. **Claim:** Noise is randomness that remembers its neighbours; its type decides whether a body is a blob, a block or a crystal.
- **Debt:** The blob aesthetic (Queer 3D): gradient noise gives everything the same soft hills, a look so common it now reads as 'nature'. Perlin noise has grid-aligned artefacts that simplex noise was invented to hide, so the approximation shows along the axes.
- **Place:** Cross Random_Space_Geometry's bridge, whose planks are offset by noise, then your own heightfield: which noise type can a walker cross?
- **Godot:** FastNoiseLite, noise_type, frequency, fractal_octaves, seed, get_noise_2d(), ArrayMesh from a PackedVector3Array
- **Lineage:** Processing: noise() (Learning Processing ch 13). NoC: NoC 0 Perlin noise. Application: WP1 Perlin noise and Voronoi diagrams. Klee: -. Reference: Catlike Pseudorandom Noise 3-7 (value, Perlin, variants, Voronoi, simplex) [V]; The Book of Shaders ch 11-12 'Noise', 'Cellular noise' [V]
- **Departure:** noise (spine 11), placed early with randomness (see C18). Voronoi (WP1), which the spine keeps only in Shader_05_Patterns, arrives here as cellular noise.
- **Project step:** Replace one hand-placed element of my_room with a noise-driven one, and name its type.

#### C21 fBm terrain: a ground you can walk, and the walker opened

- **Spine:** noise, shaders. **Halls:** Noise_Space_10 (carrier); Noise_6_Wall (field trip); Shader_09_FBM (encounter)
- **Code new:** player, camera, composition. **Returns:** noise, surface_tool, normals, collision, packed_arrays, input, xr, shaders, uniforms
- **Body:** A walkable terrain: FastNoiseLite fBm sampled on a grid, multiplied by an edge envelope, and emitted as an ArrayMesh and a ConcavePolygonShape3D from the same PackedVector3Array. Then the supplied walker is opened: a CharacterBody3D with move_and_slide(), a Camera3D, and a skin node that can be swapped between the desktop body and the XR body.
- **Argument:** axis *octaves*: 1 / 2 / 4 / 8. **Predict:** 4 and 8 look most alike: at this grid spacing the mesh cannot show detail finer than about two cells, so octaves past 4 fall between vertices (Noise_Space_10 stops at 4 for exactly this reason). **Claim:** Past the mesh's resolution, extra detail is computed and thrown away: a surface cannot carry more than its vertices allow, whatever the function says.
- **Debt:** The Nyquist limit as debt: the grid decides which frequencies can exist. The walker's capsule is the game engine's default body (about 1.8 m tall; floor_max_angle decides what counts as walkable), so the terrain is judged by one body's step height. Skin versus controller separates what a body looks like from how it moves, and that is also how the XR body replaces the desktop one.
- **Place:** Walk your own terrain with your own walker on desktop, then swap in the XR body and walk it in the headset; find a slope the capsule cannot climb.
- **Godot:** CharacterBody3D, move_and_slide(), floor_max_angle, Camera3D.current, ConcavePolygonShape3D, a skin node swapped under one controller, XROrigin3D
- **Lineage:** Processing: 'Create a Navigable Generated Landscape' (Exploratory Programming ch 14 free project) [V]. NoC: NoC 0 two-dimensional noise. Application: WP3 'How do we navigate an auto-generated world?'. Klee: III 'to stand despite all possibilities to fall'. Reference: Catlike Pseudorandom Surfaces 'Surface Elevation' [V]; The Book of Shaders ch 13 fBm [V]; GDQuest 3D module 7, skin vs controller [V]; Godot 'Your first 3D game' parts 2-3 [V]
- **Departure:** noise (spine 11), early as in C18. The player is opened here and not at forces: a generated ground is the first place where the walker's own rules (step height, slope limit) decide what a body can do.
- **Project step:** Give my_room a generated ground and cross it with your own walker, not the supplied one.

#### C22 Flow fields: a field you see only through what it moves

- **Spine:** change, softbodies. **Halls:** Flow_Field (carrier); SoftBodies_Affect_Theory_Visualization (field trip)
- **Code new:** particles. **Returns:** noise, lifetime, packed_arrays, delta, vectors, multimesh, trig, areas, player
- **Body:** 500 particles advected by an angle field sampled from noise, each leaving a bounded trail. They are written by hand first (positions in a PackedVector3Array, spawned and freed) and then compared with one GPUParticles3D emitter (the radiolaria's EFFECTS toggle on the field trip).
- **Argument:** axis *field frequency*: 0.05 (broad currents) / 0.2 / 0.8 / a random angle per cell (no continuity). **Predict:** 0.05 and 0.2 look most alike: both give long parallel currents. At 0.8 the trails curl into eddies, and a random angle per cell gives scribble. **Claim:** A field is a body you cannot see: its shape appears only in what it moves, and continuity is what makes it a current.
- **Debt:** The field inherits noise's blob. GPU particles are fast because they forget: no particle has an identity you can query, a trade between knowing and scale. Lifetime decides how long a mark may exist.
- **Place:** Stand in the current: an Area3D adds the field's push to the walker's velocity, so you drift with the particles and your body joins what the field moves.
- **Godot:** PackedVector3Array, Vector2.from_angle(), GPUParticles3D, ParticleProcessMaterial, lifetime, one_shot
- **Lineage:** Processing: flow fields in Processing (NoC 2012 ch 6). NoC: NoC 4 particle systems; NoC 5 flow-field following. Application: WP1 particle systems; WP2 flow fields. Klee: IV the arrow (shaft, point, rudder). Reference: Flow_Field hall hook [V survey]; Lague, Slime-Simulation (2021) as a field trip [V repo]
- **Departure:** Flow_Field is a change hall (spine 6). It follows noise here because its field is made of noise (NoC puts flow fields after Perlin noise), and it closes the field part. Particle systems (WP1), which have no spine unit, get one here.
- **Project step:** Let a field move something in my_room that the visitor can stand in.

#### C23 Synthesis: a round, the small complete game

- **Spine:** randomness, formfinding, noise. **Halls:** Random_Game (carrier); FormFinding_Forge (field trip); Lab_Path (field trip)
- **Code new:** state_machines, groups. **Returns:** signals, areas, ui, player, camera, input, save_load, random, seeds, instancing, export_build, physics_bodies, classes, await
- **Body:** A round made of the student's own bodies: stones (their family class) that stand or sink according to a seeded state machine (IDLE, WARN, SINK, GONE), a score, a win and a lose state, a best score saved to user://, a replay, and an exported build.
- **Argument:** axis *warning time before a stone sinks*: 0 s / 0.5 s / 1.5 s / 3 s. **Predict:** In a still taken at 20 s, 1.5 s and 3 s look most alike: past about a second a walker can react, so most stones still stand. At 0 s almost none do. **Claim:** Fairness is legible time: the same chance is a game or a trap depending on how long the body is warned.
- **Debt:** A game loop decides what counts (the score) and who can play: its reaction time assumes one body's speed and eyesight, so accessibility is a design parameter, not polish. A state machine names every state a stone may be in; what has no state cannot happen.
- **Place:** Play it: the stones are the ground, and the walker (desktop or XR) has to cross before chance catches up. A classmate plays your exported build.
- **Godot:** enum State, match, add_to_group() / get_nodes_in_group(), a HUD (CanvasLayer or Label3D), reload_current_scene(), FileAccess (best score), Project > Export
- **Lineage:** Processing: 'Algorithms': a small game taken apart (Learning Processing ch 10). NoC: the NoC course's midterm simulation project [V research_creative]. Application: -. Klee: II disturbed and corrected balance. Reference: Godot 'Your first 3D game' part 8 'Score and replay' [V]; GDQuest 3D module 14 'The Final Challenge' (10-20 h) [V]; Random_Game capstone hook [V survey]
- **Departure:** A return, not a new sequence: the randomness capstone (Random_Game), the Forge's balance puzzle and Lab_Path's exit are gathered as the long track's midterm, once the player, saving and signals exist. It is a pause chapter for new syntax (two ideas only).
- **Project step:** Turn my_room into a round with a start, a state, a saved score and a replay; export it.


### Part V: Time and force

*Bodies moved by rules in time: your own integrator, relaxation until a form stands, the pendulum that becomes a spiral and a sound, soft bodies.*

#### C24 Forces: write your own integrator

- **Spine:** forces. **Halls:** Vectors_Act3_FieldsAndMotion (carrier); Vectors_Act5_ForceAsPlace (carrier); VFM_03_Motion (field trip); VFM_05_Launch (encounter)
- **Code new:** forces, integration. **Returns:** vectors, delta, physics_bodies, areas, player, packed_arrays
- **Body:** An orbiting body stepped by the student's own fixed-step integrator in _physics_process (velocity += acceleration * dt; position += velocity * dt), set beside the same body as a RigidBody3D pulled by apply_central_force().
- **Argument:** axis *integrator*: explicit Euler / semi-implicit Euler / Verlet / RigidBody3D (engine). **Predict:** After 20 orbits, semi-implicit Euler and Verlet look most alike: both keep a closed loop. Explicit Euler spirals outward; the engine body shrinks inward under its default damping. **Claim:** An orbit's shape after twenty turns is a property of the arithmetic, not only of gravity.
- **Debt:** Integration error invents or destroys energy (explicit Euler gains it). The fixed physics tick quantises motion, and 'realistic' physics is a chosen approximation with its own damping defaults.
- **Place:** Force as place (Vectors_Act5_ForceAsPlace): an Area3D replaces gravity with your exported acceleration for any body inside it, the walker included. Use it to cross a chasm.
- **Godot:** _physics_process(delta), Engine.physics_ticks_per_second, RigidBody3D.apply_central_force(), linear_damp, Area3D gravity_space_override, gravity_direction
- **Lineage:** Processing: velocity and acceleration by hand, the bouncing ball with gravity (Learning Processing ch 5). NoC: NoC 1-2 vectors and forces. Application: -. Klee: III the gravitational curve: bullet, falling stone, meteor. Reference: NoC 'Motion 101' [lineage.json]; the Vectors_Act3 hook (STEP = 1/120 accumulator) [V survey]
- **Departure:** From here the spine's own order returns (change, forces, form-finding, waves), after the chance-and-field part. Forces follow noise because the student already has fields to move bodies through.
- **Project step:** Give one body in my_room a motion you integrate yourself, and one place where a force replaces gravity.

#### C25 Form-finding: relax until it stands

- **Spine:** formfinding. **Halls:** FormFinding_Relaxation (carrier); FormFinding_Catenary (carrier); FormFinding_Equilibrium (field trip); FormFinding_Descent (encounter)
- **Code new:** debugging. **Returns:** integration, classes, packed_arrays, meshes, surface_tool, normals, physics_bodies, seeds
- **Body:** A hanging net (a 10x8 Verlet cloth written as a RefCounted class) relaxed under gravity with distance constraints until it settles into a catenary-like sag, drawn with an ArrayMesh rebuilt each step. Then the same pins are frozen and the net is flipped into a vault (Gaudí's inversion).
- **Argument:** axis *constraint iterations per step*: 1 / 4 / 16 / 64. **Predict:** 16 and 64 look most alike: the net has converged by about 16 iterations. At 1 it sags like rubber, and at 4 it is still visibly stretched. **Claim:** Stiffness here is not a material but a number of repetitions: the same net is rubber or chain depending on how often you insist.
- **Debt:** Relaxation can explode into NaN, and the failure is the teaching form (Lague shows the failed attempt first): the student debugs with breakpoints, the remote scene tree and monitors rather than by guessing. 'Finding' a form means accepting whatever an approximation settles into.
- **Place:** Walk under the inverted net as a vault. Hang Calder's mobile on the field trip (recursive and seeded) and see whether its computed pivots really balance in the engine.
- **Godot:** RefCounted class, breakpoints, Debugger: Stack Frames, Remote scene tree, Monitors, is_nan(), rebuild the ArrayMesh only when changed
- **Lineage:** Processing: -. NoC: NoC 6 physics libraries (springs, Verlet). Application: WP2 soft bodies (cloth). Klee: II non-symmetrical balance; the tightrope walker who 'is the scale'. Reference: Lague, Cloth-and-IK-Test, as a field trip [V repo]; Moholy-Nagy's balance studies [research_bauhaus]
- **Project step:** Find one form in my_room by relaxation instead of placing it, and keep the failed version beside it.

#### C26 Oscillation: pendulum, circle, spiral, sound

- **Spine:** wavefunctions, fractals. **Halls:** WaveFunctions_Pendulum (carrier); WaveFunctions_Effect_Sound (carrier); Wavefunctions_Sky_Stairs (field trip); WaveFunctions_Synthesis_Lab (field trip); Fractal_GoldenSpiral (encounter)
- **Code new:** audio, queues. **Returns:** trig, delta, multimesh, packed_arrays, integration, collision, player
- **Body:** A pendulum stepped in _physics_process, its bob sampled into a bounded queue and redrawn as a MultiMesh trail. Unrolled in time the trail draws a sine; swept around an axis with a growing radius it draws a spiral. Its frequency is rendered sample by sample into an AudioStreamWAV and played from the bob, and two sines added together make a beat (the smallest Fourier pair).
- **Argument:** axis *radius growth per turn*: -10 % (contracting) / 0 (circle) / +10 % / x 1.618 per quarter turn (golden). **Predict:** 0 and -10 % look most alike over three turns: a circle and a slowly closing coil. The golden spiral leaves the frame. **Claim:** Circle and spiral are one pendulum; the only difference is whether the radius remembers each turn.
- **Debt:** A sampled sine is quantised by the physics tick (change physics_ticks_per_second and watch the trail), and a rendered tone is 44 100 samples of a function per second. A spiral stair that is geometrically correct is not necessarily comfortable: VR comfort is a limit of the body, not polish.
- **Place:** Climb the spiral stair (Wavefunctions_Sky_Stairs) with the walker, in the headset if you can, and hear the pendulum from where you stand (AudioStreamPlayer3D).
- **Godot:** AudioStreamWAV, PackedByteArray.encode_s16(), AudioStreamPlayer3D, a capped queue (push_back / pop_front), MultiMesh.instance_count
- **Lineage:** Processing: sin() and cos() oscillation (processing.org's trigonometry tutorial now returns 404 [lineage.json]). NoC: NoC 3 oscillation. Application: WP1 sine curves, resonance frequencies, sound experiments; WP2 Fourier transforms. Klee: IV.36-38 pendulum, then circle, then expanding or contracting spiral (life or death) [V]. Reference: Klee, Pedagogical Sketchbook part IV [V research_bauhaus]; WaveFunctions_Effect_Sound hook [V survey]
- **Departure:** Waves are spine 9 and follow form-finding, as in the spine. The circle already appeared as a function (C09); here it moves and sounds. Fractal_GoldenSpiral (spine 14) is met early as the golden value of the axis.
- **Project step:** Give my_room one body that oscillates and makes its own sound.

#### C27 Soft bodies: smoothness is bought with points

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); SoftBodies_Cloth_Physics (carrier); SoftBodies_Obsticals (field trip); Topology_Entropy_Morphogenesis (field trip)
- **Code new:** setters, timers. **Returns:** physics_bodies, export, classes, tool_scripts, areas, player, trig
- **Body:** A jelly cube as a SoftBody3D made from a subdivided BoxMesh with two pinned points; stiffness, damping and pressure are exposed through setters that rebuild it. A cloth's top pins are released by a Timer.
- **Argument:** axis *subdivisions of the same cube*: 1 / 2 / 4 / 8. **Predict:** At rest all four are cubes, so the still is taken while a ball presses in: 4 and 8 look most alike (both dent smoothly), while 1 and 2 fold only at their corners. **Claim:** A soft body can only bend where it has vertices: smoothness is bought with points and paid for in frames.
- **Debt:** The application's polycount-against-deformation question, now physical. SoftBody3D is unstable at low stiffness and high speed, and its 'rubber' is a solver's compromise. The blob again: soft usually means rounded, and rounded usually means default.
- **Place:** Squeeze through the breathing room (SoftBodies_Obsticals): walls driven by a sine narrow below the walker's width, and the room decides when a body may pass.
- **Godot:** SoftBody3D, set_point_pinned(), simulation_precision, pressure_coefficient, a property setter that rebuilds, Timer, timeout, one_shot
- **Lineage:** Processing: -. NoC: NoC 6 physics libraries (soft bodies have a week in the ITP course but no book chapter) [V research_creative]. Application: WP2 soft body simulation (cloth, liquids, rubber). Klee: I.9 tendon and muscle. Reference: Topology_Entropy_Morphogenesis hook: 'the natural home for property setters' [V survey]
- **Departure:** Soft bodies are spine 17. Here they close the time-and-force part, directly after form-finding's Verlet cloth, because SoftBody3D is the engine's version of the same mass-spring net; the application also puts soft bodies in WP2, beside fractals.
- **Project step:** Make one body in my_room soft, with a subdivision count you chose and measured.


### Part VI: Rules, fields, choices, limits

*The museum's late halls as field trips: recursion, grammars, automata, implicit and carved bodies, flocks, mazes, learning, impossible space, and the arc from order toward entropy.*

#### C28 Recursion: a body that contains itself

- **Spine:** fractals, formfinding. **Halls:** Fractal_Recursion (carrier); Fractal_RecursiveTrees (carrier); Fractal_MengerSponge (field trip); FormFinding_Equilibrium (encounter)
- **Code new:** recursion. **Returns:** functions, parameters, return, multimesh, profiling, queues, collision, seeds
- **Body:** A branching tree grown by a function that calls itself with a shorter, thinner branch until a depth limit (Munari's rule in one sentence); then the Menger sponge as a body you can fly into.
- **Argument:** axis *length ratio per generation*: 0.5 / 0.6 / 0.7 / 0.8. **Predict:** 0.5 and 0.6 look most alike: both close into small bushes. At 0.8 the tree overruns the frame and the depth limit shows as a hard edge. **Claim:** Recursion must always be controlled, and the control shows: the ratio decides whether the limit is felt or hidden.
- **Debt:** Recursion that is not stopped does not end (the halting problem in a sapling), and the call stack has a depth limit. Munari's 'mad branch' is the planted exception, and the family still reads through it. Fractal self-similarity is a tidy approximation of messy growth.
- **Place:** Fly into the Menger sponge (merged collision) and find a room made of holes; stand under your own tree.
- **Godot:** a function that calls itself, a base case, get_stack() while debugging, MultiMesh (the sponge), Time.get_ticks_usec()
- **Lineage:** Processing: recursion (Learning Processing ch 13). NoC: NoC 8 fractals. Application: WP2 fractal subdivision; WP1 Fibonacci (Fractal_GoldenSpiral). Klee: I.11 propagation. Reference: Munari, Drawing a Tree [research_bauhaus]; Kawaguchi's fractal bodies (Queer 3D lineage) [V QUEER3D.md]
- **Departure:** Fractals (spine 14) come before cellular automata (spine 13): recursion is taught first as a spatial body, a body inside itself, and the grammar's explicit stack (C29) and the automaton's buffers (C30) follow as its unrolled forms.
- **Project step:** Grow one body in my_room by recursion, with a visible limit you chose.

#### C29 Grammars and the turtle: a body written as a word

- **Spine:** lsystems. **Halls:** LSystems_Grammar_Lab (carrier); LSystems_Growth (carrier); LSystems_Architecture (field trip); LSystems_Living (field trip)
- **Code new:** strings, stacks, resources. **Returns:** recursion, dictionaries, arrays, collision, player, export, save_load
- **Body:** A string rewritten by rules (F becomes F[+F]F[-F]F) for n generations, then read by a 3D turtle that pushes and pops its state on a stack at [ and ]. The rule set is saved as a custom Resource (.tres), so a plant is a file.
- **Argument:** axis *branching angle*: 15 degrees / 25.7 degrees / 45 degrees / 90 degrees. **Predict:** 15 and 25.7 degrees look most alike: both read as plants. At 90 degrees the plant turns into architecture, a grid of corridors. **Claim:** The same word is a weed or a building depending on one angle: the grammar holds the topology, the turtle holds the geometry.
- **Debt:** A grammar grows exponentially and must be budgeted (a symbol cap). The turtle is Logo, which is Klee's walking point with a memory. A Resource file is a body's recipe: it makes bodies shareable, and also standardisable.
- **Place:** Walk the corridors of your grammar at 90 degrees: centrelines become BoxMesh walls with colliders at a clear width the real walker fits through (LSystems_Architecture).
- **Godot:** String, for c in s, Dictionary of rules, Array as a stack (push_back / pop_back), custom Resource with @export, ResourceSaver.save(), load()
- **Lineage:** Processing: L-systems among the Processing examples. NoC: NoC 8 L-systems. Application: WP2 L-systems. Klee: I.1 the walking point, now with a memory. Reference: Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants [mem]; GDQuest's turtle is Logo [V]
- **Project step:** Save one body of my_room as a Resource file and grow a sibling from it.

#### C30 Cellular automata: a rule with a memory buffer

- **Spine:** cellularautomata, shaders. **Halls:** CA_Introduction (carrier); CA_GameOfLife (carrier); Shader_10_ReactionDiffusion (field trip); CA_EdgeOfChaos (encounter)
- **Code new:** buffers. **Returns:** arrays, booleans, nested_loops, collision, shaders, uniforms, packed_arrays, multimesh
- **Body:** A one-dimensional automaton computed row by row with two buffers (read the old, write the new, swap), each generation laid down as a row of floor tiles so the rule's history becomes a bridge. Then Turing's reaction-diffusion as two textures ping-ponged in a shader.
- **Argument:** axis *Wolfram rule*: 30 / 90 / 110 / 184. **Predict:** 30 and 110 look most alike at a glance: both are irregular triangles. 90 is a clean Sierpinski, and 184 settles into diagonal traffic. **Claim:** You walk on a rule's history: the rule number decides whether there is a path at all.
- **Debt:** The world wraps at its edges (the torus as a hidden default), and synchronous update is a choice (CA_ExpandingSpace compares SYNC, SCAN and REVERSE orders). Turing's 1952 morphogenesis is 'order from order' (Chun, Programmed Visions ch 3), and the edge of chaos is where the rule is most alive and least predictable.
- **Place:** Cross the bridge (CA_GameOfLife's ca_bridge): live cells are floor, dead cells are holes the walker falls through. Predict which rule leaves a crossable path.
- **Godot:** two Array[bool] (or PackedByteArray) buffers and a swap, (rule >> index) & 1, rows of StaticBody3D tiles, SubViewport + ViewportTexture ping-pong (field trip)
- **Lineage:** Processing: the Game of Life among the Processing examples. NoC: NoC 7 cellular automata. Application: WP2 cellular automata; WP3 reaction-diffusion; WP4 chaos theory. Klee: -. Reference: Lague, MN-Cellular-Automata and Reaction-Diffusion (2021) [V repo]; The Book of Shaders' planned 'Simulation' chapters, never written [V]
- **Departure:** Cellular automata (spine 13) come after fractals and grammars: the buffer is taught as the time-form of the grammar's rewrite (the whole word rewritten at once). Reaction-diffusion brings the shader strand back.
- **Project step:** Let a rule with memory build part of my_room over time, and write down the rule number.

#### C31 Implicit bodies: density, marching cubes, the blob, and carving

- **Spine:** isosurfaces, boolean_surfaces. **Halls:** ISO_LookupTable (carrier); ISO_Metaballs (carrier); Boolean_Works (carrier); ISO_ImplicitModeling (field trip); Boolean_Verbs (encounter)
- **Code new:** threads. **Returns:** functions, return, nested_loops, surface_tool, normals, tool_scripts, packed_arrays, profiling, shaders, uniforms, collision
- **Body:** A body defined by a density function f(x, y, z) (two or three metaballs), turned into a mesh by marching cubes with the supplied 256-entry table and built on a worker thread. Then the same field is carved with CSG union, intersection and difference into a burrow you can enter.
- **Argument:** axis *smooth-min blend radius k between two spheres*: 0 (hard union) / 0.1 / 0.3 / 0.8. **Predict:** 0 and 0.1 look most alike: a neck only appears once k is comparable to the gap. At 0.8 the two sources have become one blob. **Claim:** The blob is an operator: one number decides where two bodies become one.
- **Debt:** The blob aesthetic has a source (Quilez's smooth minimum). The 256-entry table is a block of supplied magic numbers, and seeing the code still hides why they are right (Chun's 'sourcery'). A thread builds faster but has to be waited on before its work is released (Ada learned this: a worker task must be waited).
- **Place:** Enter the burrow carved by CSG subtraction (use_collision), bake it to a static mesh and compare frame cost; stand in the neck between two metaballs.
- **Godot:** marching cubes with a supplied table, WorkerThreadPool.add_task() / wait_for_task_completion(), CSGCombiner3D, CSGSphere3D.operation, use_collision, @tool preview of eight corner values
- **Lineage:** Processing: -. NoC: -. Application: WP2 'the algorithmic topology of desire'. Klee: -. Reference: Lague, Marching-Cubes (2019) and Godot-Marching-Cubes (2023) [V repo]; Quilez, 'smooth minimum' [V index]; Gehry and Hadid's blob architecture (Queer 3D lineage) [V QUEER3D.md]
- **Project step:** Carve or blend one body in my_room from a field, and bake it.

#### C32 Flocks: many bodies, one rule each

- **Spine:** swarmintelligence, forces. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_PhysarumColony (field trip); SwarmIntelligence_Swarm_Intelligence_Algorithms (field trip); VFM_08_Arena (encounter)
- **Code new:** inheritance, raycasts. **Returns:** classes, groups, multimesh, vectors, forces, profiling, state_machines, dictionaries, player
- **Body:** A flock of 300 boids (separation, alignment, cohesion) that avoid walls by casting rays. First one Node per boid, a class extending a shared Agent base; then one MultiMesh with a spatial hash grid, watched in the Profiler.
- **Argument:** axis *separation weight*: 0 / 0.5 / 1.5 / 4. **Predict:** 0.5 and 1.5 look most alike: both read as a flock. At 0 it collapses into a clump; at 4 it spreads into an even, lattice-like cloud. **Claim:** A flock is a balance of three rules: one weight turns a crowd into a clump or a crystal.
- **Debt:** Emergence is sold as freedom, yet every boid obeys the same three rules and sees only neighbours inside a radius, and the base class decides what every agent is. Swarms are also the language of surveillance and drones; Chun's reading of homophily ('birds of a feather') applies [mem].
- **Place:** Walk into the flock: the walker is an obstacle the rays can see. Then let the flock's rule steer your own body for twenty seconds, and become a boid.
- **Godot:** extends a custom base class, super(), PhysicsDirectSpaceState3D.intersect_ray(), PhysicsRayQueryParameters3D, RayCast3D, a Dictionary spatial hash
- **Lineage:** Processing: the Flocking example (after Reynolds) among the Processing examples. NoC: NoC 5 autonomous agents. Application: WP4 swarm intelligence. Klee: -. Reference: Lague, Boids (2019) and Slime-Simulation (2021) [V repo]; Reynolds 1987 [mem]
- **Project step:** Populate my_room with agents of one class and one rule that the visitor can disturb.

#### C33 Mazes and paths: a route for a body through a generated world

- **Spine:** proceduralgeneration, graphtheory. **Halls:** PG_Caves_Mazes (carrier); GT_Spanning_Trees (carrier); GT_Pathfinding (field trip); GT_Foundations (encounter)
- **Code new:** graphs, search, navigation. **Returns:** stacks, queues, dictionaries, arrays, recursion, player, collision, await
- **Body:** A maze carved from a grid graph by depth-first search with an explicit stack, its walls instanced with colliders. A NavigationMesh is baked over it and an agent with the walker's radius is sent through; BFS from the exit colours every cell by its distance.
- **Argument:** axis *maze-carving algorithm on the same 15x15 graph*: depth-first backtracker / Kruskal (random edges and union-find) / Prim / random-walk cave. **Predict:** Kruskal and Prim look most alike: both make many short dead ends. The backtracker makes long winding corridors, and the cave is not a maze at all. **Claim:** A maze's feel is the algorithm's signature: the same grid gives long corridors or bushy dead ends.
- **Debt:** The shortest path is a default desire: Sara Ahmed's Queer Phenomenology asks which lines a body is directed along and which it strays from [mem]. A route in the array is not a route for a body, because the navmesh's agent radius decides who fits. Search is the step toward bodies that choose.
- **Place:** Walk the maze and race your walker against the NavigationAgent; then leave the shortest path and mark your own desire line.
- **Godot:** a graph as a Dictionary of neighbours, stack-based DFS, BFS with a queue, NavigationRegion3D.bake_navigation_mesh(), NavigationAgent3D.radius, AStar3D
- **Lineage:** Processing: -. NoC: NoC 5 path following. Application: WP3 graph theory and procedural generation: 'How do we navigate an auto-generated world?'. Klee: -. Reference: Lague, Procedural-Cave-Generation (2015) [V repo]; 10 PRINT 'Maze Walker' [V contents]
- **Departure:** Procedural generation (spine 16) is placed after swarms and joined with graph theory (spine 22, drawn on early): the maze is where search becomes necessary, and the application's WP3 puts graph theory with world building.
- **Project step:** Make my_room navigable by an agent with a body's radius, and keep one route that is not the shortest.

#### C34 Bodies that learn: a landscape made of error

- **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Gradient_Landscape (carrier); ML_Classification (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (field trip); ML_Neural_Networks (encounter); ML_Evolution (encounter)
- **Code new:** sorting. **Returns:** surface_tool, normals, seeds, integration, functions, uv, multimesh, interpolation, player
- **Body:** A loss function made into a surface you can walk (height is error), with three optimiser markers descending it from one seed. Beside it, a floor painted by a k-nearest-neighbour classifier that sorts the training bodies by distance to each floor cell.
- **Argument:** axis *k in k-nearest neighbours*: 1 / 3 / 9 / 27. **Predict:** 3 and 9 look most alike: smooth borders around the same regions. At k = 1 the border is jagged around every sample; at k = 27 the minority class is swallowed. **Claim:** A classifier's border is a vote: raise k and the minority's territory disappears without any line of code saying so.
- **Debt:** Bias as geometry (Queer 3D: 'machine-learning models are always biased'): the majority wins the vote and a parameter erases the minority class. A loss landscape flattens each body into one number.
- **Place:** Walk the loss landscape from a high point and feel which valley catches you; stand in the minority's region as k grows and watch the floor change under your feet.
- **Godot:** Array.sort_custom(), a distance function, Image.set_pixel() + ImageTexture.update(), a SurfaceTool heightfield
- **Lineage:** Processing: -. NoC: NoC 9-10 genetic algorithms and neural networks. Application: WP3 neural networks and evolutionary algorithms; WP4 algorithmic life and AI. Klee: -. Reference: Chun, Discriminating Data (homophily) [mem]; CriticalAlgorithms_Algorithmic_Bias_Visualization [V survey]
- **Departure:** Machine learning (spine 21) follows graph theory (spine 22) here: search over a graph is the step before search over a landscape of error. The bias hall (spine 25) is visited early because the vote is where bias becomes visible.
- **Project step:** Capstone proposal, two chapters before the end: flowchart one earlier body and write two capstone proposals (Aesthetic Programming ch 9's move).

#### C35 Impossible space: where the function breaks

- **Spine:** foundationscrisis. **Halls:** NonEuclidean_Spaces (carrier); Escher_Impossible (carrier); Godel_Incompleteness (field trip); Crisis_Synthesis (encounter)
- **Code new:** none (pause chapter). **Returns:** shaders, uniforms, camera, signals, vectors, await, search
- **Body:** A triangle on a surface whose curvature is a uniform: angle sums drift away from 180 degrees as curvature rises. And a Penrose triangle that is a closed body from one camera position only, and emits a signal when the viewer finds that position.
- **Argument:** axis *curvature*: -1 (hyperbolic) / 0 (flat) / +0.5 / +1 (spherical). **Predict:** 0 and +0.5 look most alike: small positive curvature bends the triangle only slightly. The hyperbolic triangle is the visibly thin one. **Claim:** 180 degrees is a property of one space, not of triangles: the same three points make different bodies in different geometries.
- **Debt:** Euclid's frame (C03's default world) is one choice among several. Gödel and the halting problem set limits on what a function can decide ('not found within budget' is not 'unprovable'). The impossible object exists for one viewpoint only, the way a rendered world exists only for its camera.
- **Place:** Walk into curved space and back; find the one standpoint where the Penrose triangle closes, so that the camera becomes the key.
- **Godot:** vertex() with a curvature uniform, get_viewport().get_camera_3d(), a dot-product alignment test, await inside a budgeted search
- **Lineage:** Processing: -. NoC: -. Application: WP4 non-Euclidean spaces; paradox and infinity (the application's arc). Klee: II.15-17 perspective as optical illusion. Reference: Escher, Reutersvärd and Penrose (Queer 3D lineage) [V QUEER3D.md]; Gaboury, A Queer History of Computing (Turing) [V listing]
- **Project step:** Prototype the capstone: build its body as a family and draft its prediction.

#### C36 Order toward entropy: the laboratory, and after

- **Spine:** qfeplaboratory, postfoundationscrisis. **Halls:** QFEP_E_Term (carrier); QFEP_Lambda_Spectrum (carrier); SpeculativeComputation_Rhizome_Network (field trip); PostCrisis_Synthesis (field trip); QFEP_Synthesis (encounter)
- **Code new:** none (pause chapter). **Returns:** classes, export, physics_bodies, multimesh, vectors, save_load, files, noise, random, seeds, player, xr, export_build, ai_assist, testing
- **Body:** The capstone body: a family (a class with exported axes) placed in the student's own hall of the endless museum, one of whose axes runs from order to entropy (QFEP's F toward E) and is laid out as a walk, so the visitor's position sets lambda (QFEP_Lambda_Spectrum's move: the body becomes the slider).
- **Argument:** axis *lambda (order toward entropy) along the student's own family*: 0 / 0.25 / 0.5 / 0.75 / 1. **Predict:** The student names the closest pair from their own family's arithmetic before the render, and by how much. Ada's DNA programme found such predictions to be lower bounds, so a sweep that comes back below the prediction is investigated. **Claim:** The student's own sentence, which the comparison must support (for example: 'past lambda 0.5 my body stops being one body').
- **Debt:** What QFEP's own encoding hides (the Sieve's third question): a single lambda flattens a body's many directions of becoming, and entropy can also be a resistance (Queer 3D, via Haraway and Ahmed). The capstone carries a debt comment in its own code, after the confessing comment in CCS's Climategate chapter.
- **Place:** The visitor walks the axis in your hall. You show it in the headset build, and a record written there survives into another hall (PostCrisis_Synthesis's user:// file).
- **Godot:** everything so far, a Quest export, a README beside the code in Git, a headless test for the family's axis
- **Lineage:** Processing: the Processing Handbook's Synthesis chapters [V]. NoC: NoC's Ecosystem Project: creatures for a museum exhibit [V research_creative]. Application: WP4 algorithmic life; the arc toward entropy (F to E). Klee: IV ends in colour, where 'the arrow is superfluous'. Reference: Aesthetic Programming's final miniX (an artifact plus a ReadMe) [research_ccs]; Recreating the Past closes with Body, then Glitch/Deformation [research_creative]
- **Project step:** Show the capstone in your hall with its prediction, comparison image, claim, debt comment and build.


## What this candidate learned from comparable courses

- Catlike Coding [V]: the graph-to-surface ladder (a loop of cubes plotting a function, then a 2D grid, then parametric sphere and torus) gives Part I and Part II their order (C05, C07, C09). Its clock from primitives (Basics 1) becomes the jointed limb (C08); its five sphere constructions become one argument whose axis is a construction method (C11); its hashing tutorial, where weak hashes show as stripes, becomes the first chance chapter (C18). Measuring performance comes early (C11), as in Basics 4.
- The Book of Shaders [V]: drawing before generating (shaping, colour, shapes, patterns, then random, noise, cellular, fBm) is the order of Parts III and IV, and it explains the spine's own colour/tiling-before-randomness/noise. The first shader enters right after colour as a returning strand (C16, C17, C21, C30, C35) rather than one block at spine 12. The 'edit one named line and predict' exercise is the Modify step at its smallest.
- Sebastian Lague's Coding Adventures [V repos; episode titles inferred]: the failed attempt shown before the fix is the chapter-scale form of the planted bug (C25 makes relaxation that explodes into the debugging lesson). His episodes are Part VI's field trips beside Ada's halls: cloth, slime, cellular automata, reaction-diffusion, marching cubes (including a Godot port), boids, caves.
- GDQuest [V]: use before make (drive supplied functions and a supplied turtle before defining your own), the planted error in the second lesson, keep() before keep(p) (C06, then C09), and skin versus controller as the concrete pattern for swapping the desktop body for the XR body (C21).
- Godot docs [V]: the four mesh tools (ImmediateMesh for the SKETCH line, SurfaceTool for the first standable face, ArrayMesh opened in C11) give the mesh order; 'Your first 3D game' parts 2-3 and 8 size the short track's supplied game kit and the long track's round (C23).
- Gaboury, Image Objects [V structure]: five DEBT readings placed at the code chapters they archaeologise: culling at the first face (C10), the default sphere as a Utah-teapot standard (C11), object orientation at the family class (C12), the GPU as 'procedure crystallized' at the first shader (C16). No engine curriculum in the sweep has a critical layer; this pairing is Ada's own.
- The Nature of Code [V]: its cumulative Ecosystem Project, creatures designed for a museum exhibit, is the model for my_room growing into the student's own hall; its midterm simulation project is C23; its order vectors, forces, oscillation is kept in Part V.
- Aesthetic Programming and the CCS courses [research_ccs]: no separate theory track; each code idea pulls in its own reading (Fuller's Lexicon entries map onto code_new). Pause weeks with no new syntax (C23, C35, C36), the capstone planned two chapters before the end (C34), a ReadMe beside the code, and a debt comment written into the student's own code after the Climategate chapter (C36). Write first, then read the debt: every chapter makes the body before its DEBT step.
- 10 PRINT [V contents]: regularity before randomness is why the grid (C07) and the tiling floor with one exception (C13) come before the hash (C18); 'Maze Walker' is the walkable maze (C19); 'ports' (nodes, then MultiMesh, then shader) return in C19, C32 and C31.
- Klee, Pedagogical Sketchbook [V via research_bauhaus]: the corrected order (line, structure, balance, gravity, then pendulum to circle to spiral in part IV, ending in colour) gives C06's walking line, C08's bone and tendon, C24's gravitational curve and C26's pendulum-circle-spiral axis. Colour appears twice, as appearance (C15) and as energy (C16).
- Albers [research_bauhaus]: a problem with a stated perceptual target and one constrained material is the ancestor of the ARGUMENT strand; 'make two different bodies look alike' is what every PREDICT line asks.
- Code as Creative Medium and SFPC [research_creative]: the short track's mini project takes Levin and Brain's 'Extrapolated Body' prompt; the three-week Code Societies format (critique beside code, a guest per session) matches Palle's Queer 3D course; Recreating the Past's 'recreate, then depart' is the shape of C18 (Nees's Schotter) and C14 (collage).
- Queer and feminist courses [research_queer]: making before the tool and sharing early (Anthropy) put import and a first export in week 2 (C14); failure comes before futures (C25 failure-as-teaching; C35-C36 limits, then the arc toward entropy); Ahmed's desire lines give the maze its debt (C33). No course found teaches queer theory together with procedural 3D for beginners, and this candidate says so instead of borrowing that authority.


## Numbers (computed by build_c6.py from the JSON)

- 36 chapters in 6 parts; order agreement with the spine (fraction of chapter pairs in spine order, by each chapter's first sequence) = 0.9; spine coverage 25 / 25; 22 chapters carry a departure note.
- Every code id in the vocabulary is introduced exactly once; no chapter introduces more than 3; the ladder has no violation in the full order. The short track skips C04, C11, C13 and C15-C17, and the ideas those introduce are named as supplied in the track's 'supplied' field.
- A small complete game: player (C21), input (C06), camera (C21), ui (C16), save_load (C17), audio (C26), export_build (C14), physics_bodies (C19), instancing (C07), signals (C15); assembled as a round in C23. xr (C08), import_assets (C14) and ai_assist (C09) all sit inside the short track.
- 2023 application coverage: randomness, Fibonacci (C26/C28), Perlin, Voronoi (C20), sine and resonance, sound (C26), particle systems (C22), fractal subdivision (C28), flow fields (C22), Fourier (a two-sine beat and the Synthesis_Lab field trip, C26; thin), L-systems (C29), CA (C30), queer meshes (C10, C14), soft bodies (C27), reaction-diffusion (C30), graph theory and procedural generation (C33), neural networks and evolution (C34; encounters only), shading (C16), swarms (C32), chaos (C30, the edge of chaos), algorithmic life and AI (C34, C36), non-Euclidean space (C35).

## Honest weak spots

- **The short track is dense**: 13 sessions in 15 days. If it has to shrink, drop C06 (supply the recorder) and C20 before touching C12 or C14, since families and collage are the Ada-specific core.
- **Randomness arrives at C18, not C5-7** as the CCS sweep suggested. The engine and shader tradition puts chance after drawing, and this candidate follows its anchor; the short track reaches the hash on day 11.
- **Part VI carries nine sequences in nine chapters**, so each late sequence gets one chapter and its halls are mostly field trips. That is the anchor's stance (Lague as field trips), but a teacher may want two weeks for isosurfaces or graphs.
- **Many 'predict' lines here are the designer's guesses**, made without renders. By Ada's DNA finding a prediction is a floor, not a forecast, and the course asks students to treat theirs the same way.
- **Unverified here**: Lague episode titles (inferred from repo names), Bagnall's hardware chapter, Ahmed's desire lines, Chun's homophily, and the Climategate comment are [mem]. The claim that 'no course teaches queer theory with procedural 3D' rests on a search that was not exhaustive.
- **Kits**: only Point_Zero, Point_One, Point_Coordinates, Point_Lines, Point_Trace and Random_Definition have runnable kits (maps/ada.json). Every other chapter needs a kit written, and the carriers' hooks in survey_bundle.json are the brief for each one.
