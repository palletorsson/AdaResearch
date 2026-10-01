# The Sketchbook in Drag, Parameterized: point, line, plane, family, balance, fall, swing, colour, and out

**Status: 2026-09-30. A proposal from an auto-research run. No tutorial, kit or curriculum.json was changed.** It is the winning candidate of that run (`d2_ada_first`), refined with the notes of the second-generation judges; what was repaired and what was left is listed near the end. The other ten candidates are in `candidates/`, and `LEARN.md` answers Palle's question about comparable courses.

Marks: **[V]** checked during the run, in the Klee text, the research sweeps, the hall digest built from the repo, or the Ada repo itself; **[mem]** recalled, not checked. The planted-bug messages are mostly [mem] and should be triggered once in Godot 4.6 before class.

Files here: `COURSE.md` (this), `course.json` (the same course as data, for an outline page), `candidates.json` and `candidates/` (all eleven candidates with scores and judges' notes), `LEARN.md` (comparable courses) with its five research sweeps in `research/`, `CONTRACT.md` (the shape every candidate had to have, and how it was scored; the working files it names, BRIEF.md, APPLICATION.md, QUEER3D.md and spine.json, stayed in the run's scratchpad: spine.json is read from commons/maps/curriculum_spine.json, and the application is addons/VR_VR_PT_2023.txt).

## For the student

### Why this order

This course walks the way Paul Klee's Pedagogical Sketchbook walks, the book Ada's own research plan says it wants to put 'in drag, in VR'. A point goes for a walk and becomes a line; the line closes into a plane you can stand on; the plane repeats and becomes structure; chance disturbs the structure and, given a memory, becomes ground; the body gets joints, becomes a family, stands, falls along a curve, swings, sounds and glows, and the book ends in colour. Where Klee stops, the course follows Ada's spine out of the sketchbook and says so. Every chapter also carries one of five verbs (repeat, transform, parameterize, visualize, simulate), so you can always say what your code is doing to form, and each verb needs the one before it: disorder is invisible without a grid, a family needs a class, a simulation needs all of these. The programming ideas arrive when a body needs them: a point needs a variable, a line a function, a walk a list, a floor a loop, a family a class, a balance physics, a curve your own gravity, a swing sine. In every chapter you build a body in GDScript, vary it along one axis, write down before rendering which two variants will look most alike, defend one sentence with the picture, ask what the approximation owes or hides, and then stand on the body, carry it, walk through it or become it. 'In drag' names an operation in the code: Klee maps active, medial and passive onto brain, tendon and bone and onto male and female, and the scene tree does the same with parent and child. You will learn that hierarchy, and then make the passive end drive.

The rule, briefly: The order follows Klee's Pedagogical Sketchbook where it gives the student a reason (a point walks and becomes a line, a plane, a structure, a family; the body stands, falls, swings, and the book ends in colour). After Klee's last page the course follows Ada's spine. A chapter that leaves the spine's order says why, and a chapter that comes back says it is a return.

### The four strands

Every chapter braids four things.

- **CODE.** One programming idea met for the first time, named from the course's vocabulary of 83 ideas. An idea may return later; it never returns before the chapter that introduces it.
- **BODY.** A body you build in GDScript: a point, a line, a floor, a creature, a field. Most of Ada's works are made this way, as a procedure with parameters.
- **ARGUMENT.** A family of that body along one axis, three to five values. Before you render, you write which two members will look most alike and why. After, you make one comparison image and write one sentence it supports. The axis must show in a still.
- **PLACE.** Where another body meets yours: you stand on it, walk through it, carry it or become it, on the desktop or in the headset.

### The three layers

The layers come from Palle's Queer 3D World course. Every chapter passes through all three, on a small scale.

- **FOUNDATION.** The lab: how the thing works. The chapter itself.
- **DEBT.** What the approximation owes or hides: pseudo-randomness, the blob look of noise, recursion that has to be stopped, polycount against smooth deformation, bias. Read after you have made the body, and from ch14 on written as a comment in your own code.
- **ONTOLOGY.** The body leaves the lab: a hybrid room, an impossible space, a build that runs on another machine or in a headset.

### The lesson rhythm

Each chapter is a brief with a precedent (the lineage line names it), a closed exercise, and an open make, as in Code as Creative Medium, and as Albers set his cut-paper problems before free studies. Inside it:

1. Decode the hall: walk the chapter's carrier hall first and guess how its work is built (PRIMM's Predict; Aesthetic Programming's Decode).
2. Run, investigate and modify the kit or the supplied body: change one line and see what moves.
3. The closed exercise is the argument: one exported axis, three to five values. Write the prediction in your sketchbook README before rendering, with the arithmetic when there is one. Then make the comparison sheet and write one claim it supports. The prediction is a floor, not a forecast: when the sheet comes back less different than you predicted, look for the fault before you believe it.
4. The planted bug: each chapter has one real error, and you read its message before you fix it.
5. Make: build your own body (the project step) and carry it into your room.
6. Debt, after the making: what the approximation owes or hides, in one reading or one code-critique snippet of Ada's own code.
7. Place: a body meets yours. Stand on it, walk through it, carry it, become it.

Every chapter also carries one of Form+Code's verbs (repeat, transform, parameterize, visualize, simulate; Part I is 'code and form'), so you can say what your code does to form, and names its visit to each spine sequence ('randomness, visit 2 of 7'), so you can say where you are in Ada.

### The two tracks

**Three weeks: the sketchbook's first page and one family (Queer 3D World format).** 3 weeks (15 days). Week 1 (Part I on the runnable kits, two chapters a day on days 1-3): ch01-ch08. On day 4 (ch07) there is also a scanning / Tilt Brush session; the teacher imports the scans that evening, and each student's scan stands in their room for the first export on day 5 (ch08). Week 2: ch09, ch11, ch12, ch14, ch18 (export on Friday; the mini-project brief is due the same day as a flowchart and a paper prototype). Week 3: mini project, with two critique sessions in the SFPC Code Societies format and no new code: (a) Klee's active/passive passage and the scene tree's command chain, walked as encounters in Trans_Body and VFM_09_Legs; then each student opens a supplied three-segment organism, makes the foot the root in the Scene dock (right-click, Make Scene Root [mem]) and moves it: the chain that the brain commanded now follows the foot, without a line of code (the long track does it in code at ch21); (b) the blob aesthetic and the default body, walked in ISO_Metaballs and ML_Classification. The class shows on day 15.

- Chapters: 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 14, 18. Thirteen chapters, 35 new ideas, ladder-clean on their own: no chapter in the track uses an idea the track has not introduced.
- Day by day: D1 ch01 + ch02 (day-zero and point-zero kits). D2 ch03 + ch04 (point-one, point-coordinates). D3 ch05 + ch06 (point-lines, point-trace). D4 ch07, and the scanning session. D5 ch08, first export, with your scan in the room. D6 ch09. D7 ch11 (random-definition kit). D8 ch12. D9 ch14. D10 ch18, second export; the brief is due as a flowchart and a paper prototype. D11-D14 mini project, with critique sessions on D11 and D13. D15 showing.
- Supplied: Named, not taught, each with the chapter where the long track opens it: the desktop walker and the XR rig (commons/scenes/vr_staging.tscn with Godot XR Tools; opened at ch19); the runnable kits in doc/book/studies/ (day-zero, point-zero, point-one with contact_probe.gd, point-coordinates, point-lines, point-trace, random-definition with display.gd); the place_at(where) helper for ch01 (to be written; opened at ch05); the SKETCH helper point(p), line(a, b), box(p, size), seeded by point-lines' segment.gd (opened at ch05); each student's scan, imported by the teacher on day 4 (opened at ch18); the sweep_sheet scene that lays out labelled members (to be written; opened and rewritten at ch15); a heightfield-to-mesh-and-collider helper for ch12 (to be written); the trig one-liners wave_height(x, z), catenoid(u, v) and gap_to_circle(n) (to be written; opened at ch24); a three-segment organism scene for critique session (a) (to be written; built in code at ch13); pickables and a desktop carry; one AudioStreamPlayer3D sound; a phone-scan or Tilt Brush route to glTF through Blender; an export preset per machine. Skipped and covered by those parts: ch10 (pattern), ch13 (the organism: delta and pivots arrive inside the walker), ch15-17, and Parts IV-VII.
- Mini project: A family in drag (prompts after Code as Creative Medium and Form+Code: Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic). One class of your own with one exported axis of 3-5 values; the closest pair predicted in writing before rendering; the comparison sheet; one claim sentence the sheet supports; one debt comment in the code saying what the approximation owes or hides; the members placed with your scanned or sculpted body in the walkable room of your ch18 build, where a visitor can stand on, walk through, carry or become one of them. Shown to the class as a desktop build and, where a headset is available, walked in VR.

**One year: the whole sketchbook, parameterized, and out of it.** 42 weeks as written: Part I at two chapters a week (4 weeks), ch09-ch41 at one chapter a week (33 weeks), and a pause week with no new code after each of the five syntheses (ch08, ch18, ch25 midterm, ch30, ch41 final), Aesthetic Programming's rhythm. For a 36-week school year, run six pairs as one week each; no pair carries more than three new ideas: ch17 + ch18 (a body saved as a file, a body arriving as a file), ch22 + ch23 (one integrator, two laws), ch26 + ch27 (the swing, then heard), ch29 + ch30 (colour, then the pixel's colour), ch32 + ch33 (the tree, then its grammar), ch37 + ch38 (bodies with rules, then bodies that learn). The final project is planned at ch40, two units before the end, from the student's own prediction log.

- Chapters: all 41. Midterm at ch25: a round in your room that a classmate can lose, exported and played. Final at ch41: your hall in Ada's endless museum, built from your families and exported to desktop and Quest; for each body a prediction, a comparison sheet, a claim and a debt comment, plus one public sculpture with a stated edit rule (NoC's Ecosystem Project turned into a museum room that others may revise).

## The parts

| Part | Chapters | Verbs | Spine drawn on | What it promises |
|---|---|---|---|---|
| Point, line, plane (Kandinsky; Klee I.1-4) | 1-8 | code and form | primitives (1), postfoundationscrisis (25) | From a point you place to a plane you walked and can stand on, and a first build that runs outside your editor. You learn that the engine calls your code, that everything is an object in a tree, that a line is a record of a walk, and that a machine drafter fills your gaps with its defaults. |
| Structure: repetition, disorder, articulation (Klee I.5-12; Nake, Nees, Molnar) | 9-13 | repeat, transform | array_tutorial (3), primitives (1), color (4), tiling (5), randomness (10), noise (11), transformation (2) | Repeat a body and it becomes a floor; move the rule into the surface and it becomes a pattern; disturb it and chance appears; give chance a memory and it becomes ground you can walk; articulate the body and it moves by itself. |
| The family (Klee I.7-8; Albers; Molnar): Parameterize, declared as an addition | 14-18 | parameterize | primitives (1), color (4), softbodies (17), formfinding (8), proceduralgeneration (16), randomness (10) | You describe a body in a single class whose exported fields make a family, sweep one axis into a comparison sheet, measure what each value costs, save a body as a file, and bring a found body into the family's room. The short track pivots into its mini project here. |
| Dimension and balance (Klee II) | 19-21 | transform, simulate | transformation (2), foundationscrisis (23), formfinding (8), forces (7) | The eye and the standing body: perspective as a fact about eye height, balance as a fact about the centre of mass, and legs that let the passive end drive. The walker you have used since day one is opened. |
| The gravitational curve (Klee III) | 22-25 | simulate | change (6), forces (7), wavefunctions (9), randomness (10), formfinding (8) | You write gravity yourself: a curve from steps, regions with other laws, a stair that is a function, and a small complete game about staying upright. |
| Kinetic and chromatic energy (Klee IV; Albers) | 26-30 | transform, visualize | wavefunctions (9), fractals (14), array_tutorial (3), change (6), forces (7), noise (11), color (4), shaders (12) | Motions that return: pendulum, circle, spiral, sound, the arrow and the field of arrows; then colour as a system and the shader. Each makes something invisible visible, and each picture hides a choice. |
| Out of the sketchbook: bodies in drag (spine 13-25) | 31-41 | simulate, repeat, visualize | cellularautomata (13), softbodies (17), fractals (14), lsystems (15), proceduralgeneration (16), graphtheory (22), formfinding (8), isosurfaces (18), boolean_surfaces (19), noise (11), swarmintelligence (20), randomness (10), machinelearning (21), postfoundationscrisis (25), foundationscrisis (23), qfeplaboratory (24) | Where Klee has no page: rules in time, recursion that must be stopped, grammars, generated worlds, soft, implicit and collective bodies, bodies that learn, the crisis of foundations, entropy measured on your own predictions, and your hall in the collective museum. |

### Reading order

| n | Chapter | Verb | Spine visits | Code new | Argument axis | Departure | Tracks | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Day Zero: the instruction is the work | code and form | primitives (1) 1/12 | statements, output, errors | wording of the instruction | - | short/long | runnable (day_zero) |
| 2 | Point: a body with no size must be given one | code and form | primitives (1) 2/12 | variables, properties, lifecycle | point radius seen from 2 m | - | short/long | runnable (Point_Zero) |
| 3 | Solid and ghost: one if decides what a body is | code and form | primitives (1) 3/12 | conditions, booleans, calling | collider radius as a fraction of the visible radius (still taken with the probe's feelers paused against each sphere) | - | short/long | runnable (Point_One) |
| 4 | Coordinates: carry the point | code and form | primitives (1) 4/12 | vectors, expressions, xr | which axis the same 1 m offset goes into | - | short/long | runnable (Point_Coordinates) |
| 5 | Line: distance belongs to the line | code and form | primitives (1) 5/12 | functions, parameters, return | thickness as a fraction of length | - | short/long | runnable (Point_Lines) |
| 6 | The walk: a line is a record | code and form | primitives (1) 6/12 | arrays, loops, meshes | sampling gate | - | short/long | runnable (Point_Trace) |
| 7 | Plane: when the line closes | code and form | primitives (1) 7/12 | surface_tool, normals, collision | winding and normals | - | short/long | planned |
| 8 | When things go wrong: the drafter is a machine | code and form | primitives (1) 8/12; postfoundationscrisis (25) 1/3 | ai_assist, debugging, export_build | how much the prompt fixes | yes | short/long | planned (W01_break_it_on_purpose) |
| 9 | The chessboard: purely repetitive and therefore structural | repeat | array_tutorial (3) 1/3; primitives (1) 9/12; color (4) 1/3 | nested_loops, instancing, materials | rhythm rule over the same 8 x 8 cubes | yes | short/long | planned |
| 10 | Pattern: structure moves into the surface | repeat | tiling (5) 1/1; array_tutorial (3) 2/3 | uv, dictionaries | wallpaper rule over one 4 x 4 source | yes | long | planned |
| 11 | Disturbed order: chance enters the grid | repeat | randomness (10) 1/5 | random, seeds | disorder amplitude (maximum rotation in the last row) | yes | short/long | runnable |
| 12 | Noise: chance that remembers its neighbour | repeat | noise (11) 1/4 | noise, packed_arrays | where the heights come from, all at the same amplitude and grid | yes | short/long | planned |
| 13 | The organism: bone, tendon, muscle | transform | transformation (2) 1/3 | transforms, basis, delta | where the pivot sits on each segment (same joint angles) | yes | long | planned |
| 14 | Families: one body in a single class | parameterize | primitives (1) 10/12 | classes, export, types | sphere segments (rings = half) | yes | short/long | planned |
| 15 | The family in the editor: setters, @tool and the sheet opened | parameterize | color (4) 2/3; softbodies (17) 1/3 | setters, tool_scripts, methods | where the apex sits over the base: apex_stance, the @export_enum in Ada's pyramid.gd (base 0.6 m, height 0.8 m) | yes | long | planned |
| 16 | The budget: polycount measured, a claim tested | parameterize | primitives (1) 11/12; formfinding (8) 1/4 | testing, profiling | u_steps of the catenoid | yes | long | planned |
| 17 | Genes as files: a family saved, a body recalled | parameterize | proceduralgeneration (16) 1/2; randomness (10) 2/5 | resources, save_load | the limb_count gene | yes | long | planned |
| 18 | Collage: a found body joins the family | parameterize | primitives (1) 12/12 | import_assets | how the body was made | yes | short/long | planned |
| 19 | Eye level: the walker opened | transform | transformation (2) 2/3; foundationscrisis (23) 1/2 | camera, input, player | eye height | yes | long | planned |
| 20 | The tightrope walker: balance | simulate | formfinding (8) 2/4; forces (7) 1/5 | physics_bodies, signals | centre-of-mass offset relative to the support polygon (still 3 s after release) | yes | long | planned |
| 21 | Legs: the passive part drives | transform | forces (7) 2/5; transformation (2) 3/3 | raycasts, composition | segments per leg, same total length | yes | long | planned |
| 22 | The bullet: a curve made of steps | simulate | change (6) 1/2; forces (7) 3/5 | integration | time step dt, same launch | yes | long | planned |
| 23 | Regions with other laws | simulate | forces (7) 4/5 | forces, areas | the region's gravity (still 0.5 s after six family members are released) | yes | long | planned |
| 24 | The stair climber: a spiral you can walk | simulate | wavefunctions (9) 1/3 | trig | rise per tread | yes | long | planned |
| 25 | To stand despite all possibilities to fall: a round | simulate | randomness (10) 3/5; formfinding (8) 3/4 | state_machines, ui, timers | warning time before a stone sinks (still 20 s into the same seeded round) | yes | long | planned |
| 26 | Pendulum, circle, spiral: time laid into space | transform | wavefunctions (9) 2/3; fractals (14) 1/2 | queues, multimesh | radius change per turn (still at the tenth turn) | yes | long | planned |
| 27 | Sound: the swing heard | visualize | wavefunctions (9) 3/3; array_tutorial (3) 3/3 | audio | frequency ratio of the two tones | yes | long | planned |
| 28 | The arrow and the field of arrows | visualize | change (6) 2/2; forces (7) 5/5; noise (11) 2/4 | particles, lifetime | the field's noise frequency | yes | long | planned |
| 29 | A colour has many faces | visualize | color (4) 3/3 | interpolation | the space the same two complementaries are mixed in | yes | long | planned |
| 30 | The pixel's colour circle: shaders | visualize | shaders (12) 1/1; noise (11) 3/4 | shaders, uniforms | the rim exponent p in pow(1.0 - dot(NORMAL, VIEW), p) | - | long | planned |
| 31 | Rules in time: cellular automata | simulate | cellularautomata (13) 1/1; softbodies (17) 2/3 | buffers | the rule number, from one live cell | yes | long | planned |
| 32 | The tree and its mad branch: recursion | repeat | fractals (14) 2/2 | recursion | depth limit | - | long | planned |
| 33 | The point walks again: grammars and the turtle | repeat | lsystems (15) 1/1 | strings, stacks | branching angle, same rules and generations | - | long | planned |
| 34 | How do we navigate an auto-generated world? | simulate | proceduralgeneration (16) 2/2; graphtheory (22) 1/1 | graphs, search, navigation | carving algorithm, same grid and seed | yes | long | planned |
| 35 | Soft bodies: the organism returns | simulate | softbodies (17) 3/3; formfinding (8) 4/4 | inheritance | constraint iterations per step | yes | long | planned |
| 36 | Stone upon stone, chip from chip: implicit and boolean bodies | visualize | isosurfaces (18) 1/1; boolean_surfaces (19) 1/1; noise (11) 4/4 | threads | threshold (iso level) of the same field | yes | long | planned |
| 37 | Many bodies with rules: swarms | simulate | swarmintelligence (20) 1/1; randomness (10) 4/5 | groups | cohesion weight (separation and alignment fixed) | yes | long | planned |
| 38 | Bodies that learn: whose data trains the body | visualize | machinelearning (21) 1/1; postfoundationscrisis (25) 2/3 | json | who labelled the training points | yes | long | planned |
| 39 | The crisis of foundations: impossible possible space | simulate | foundationscrisis (23) 2/2 | await | the viewer's distance from the locked standpoint | - | long | planned |
| 40 | Order toward entropy: the QFEP laboratory | visualize | qfeplaboratory (24) 1/1; randomness (10) 5/5 | sorting | how the same 200 symbols are arranged | yes | long | planned |
| 41 | Out of the lab: your hall in the collective museum | simulate | postfoundationscrisis (25) 3/3 | files | who may change the sculpture | - | long | planned |

## The chapters

### Point, line, plane (Kandinsky; Klee I.1-4)

From a point you place to a plane you walked and can stand on, and a first build that runs outside your editor. You learn that the engine calls your code, that everything is an object in a tree, that a line is a record of a walk, and that a machine drafter fills your gaps with its defaults.

#### 1. Day Zero: the instruction is the work

- Verb: code and form. Spine: primitives (1), visit 1 of 12. Halls: Point_Zero (encounter). Tracks: short, long.
- Status: runnable, /course stop day_zero, kit doc/book/studies/day-zero. The Day Zero kit runs in Godot 4.6 (desktop; the headset route is written but untried). The place_at() helper this chapter calls is not in it yet.
- CODE new: statements, output, errors. Returns: none.
- BODY: A LeWitt location drawing turned into one body: in the supplied base.tscn (floor, camera, light, Label3D) you type one line that calls a supplied place_at(where), and a cube appears at 'corner', 'midpoint' or 'centre'; one print() writes your instruction to the Output panel.
- ARGUMENT: axis *wording of the instruction*: corner / midpoint / centre / somewhere near the middle. Predict: 'midpoint' and 'centre' will look most alike from the fixed camera: on a square floor both land on the middle line, and they differ only if 'midpoint' is read as the midpoint of an edge, which is exactly the ambiguity. 'somewhere near the middle' will not run at all: the helper refuses an unknown word with an error. Claim: *An instruction a partner can interpret is not one the engine can run: ambiguity shows up as an error, not as a variation.*
- DEBT: LeWitt's drafters interpreted; the engine refuses. Literalness is the price of repeatability, the course's first debt. GDScript's English keywords are programming's default language (Marino on FLOW-MATIC), a cheap first question for Swedish-speaking students.
- PLACE: Stand, reach and turn in the room (the supplied desktop walker, or the headset through the supplied XR rig); then a partner executes your written instruction on paper and you compare it with the run.
- Godot: project against scene; F5 against F6; save · print() and the Output panel · reading a red error in the Debugger panel: file, line, message · calling a supplied helper before writing any (use before make) · the Day Zero kit, doc/book/studies/day-zero [V repo] · planted bug: a misspelled node name in get_node(): read 'Node not found' and fix the name, not the code around it.
- Lineage: Processing: Learning Processing ch2 (run, errors) [mem]; Processing Handbook 'Structure 1: Code Elements' [V proc_contents via c4]. NoC: none (NoC assumes this semester). Application: pre-WP foundation: Freire's reflection and action (write, run, compare). Klee: Introduction: the axiom 'to stand despite all possibilities to fall' [V klee_ps l.226]. Reference: Sol LeWitt, Paragraphs on Conceptual Art (1967) and his wall-drawing instructions [mem]; Code as Creative Medium 'Computing without a Computer' [V ToC via LEARN]; Molnar's machine imaginaire [V research_bauhaus].
- Project step: Start a sketchbook repository whose README will hold every prediction, comparison image, claim and debt comment of the course.

#### 2. Point: a body with no size must be given one

- Verb: code and form. Spine: primitives (1), visit 2 of 12. Halls: Point_Zero (carrier). Tracks: short, long.
- Status: runnable, /course stop Point_Zero, kit doc/book/studies/point-zero. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: variables, properties, lifecycle. Returns: statements, output, errors.
- BODY: A point built in _ready(): a MeshInstance3D whose SphereMesh radius is a variable, placed by setting its position property; then three points by hand, and a Label3D beside them that counts the frames the engine has called you for (Point Zero's frame counter).
- ARGUMENT: axis *point radius seen from 2 m*: 0.01 m / 0.05 m / 0.25 m / 1.0 m. Predict: 0.01 and 0.05 will look most alike: at 2 m both subtend under 1.5 degrees, a few pixels, and read as dots. 1.0 stops being a point and reads as a body; 0.25 is the one that changes category as you walk. Claim: *A point is a relation between size and viewing distance: Kandinsky's point becomes a plane when it grows.*
- DEBT: Mathematically a point has no extent; to be seen it needs a mesh of hundreds of triangles. The engine can show a point only by lying about its size, the first approximation of the course. And the frame counter counts frames, not seconds: in a 90 Hz headset it runs 1.5 times faster than at 60 Hz on the desktop. The repair (delta) is held back to ch13 and named there.
- PLACE: Walk toward and away from the four points: the 0.25 m point changes category as you approach.
- Godot: Node3D and MeshInstance3D; SphereMesh.new() and its radius property · position as a property you set · _ready() against _process() · Engine.get_process_frames() shown in a Label3D · the Point Zero kit, doc/book/studies/point-zero [V repo] · planted bug: radius set on a mesh variable that is still null ('Invalid set index radius on base Nil'): the order of statements matters.
- Lineage: Processing: Learning Processing ch1 Pixels [mem]; Handbook 'Shape 1' [V proc_contents via c4]. NoC: none. Application: pre-WP: the application's 'basic algorithmic concepts like noise and vectors' begin with a position. Klee: I.1 'The mobility agent, is a point, shifting its position forward' [V klee_ps l.279]. Reference: Kandinsky, Point and Line to Plane, 'The Point' (size decides point or plane) [mem]; Fontana's buchi as the point that cuts (doc/book/BASE_LAYER.md) [V via LEARN].
- Project step: Place three points whose sizes you chose; write your first PREDICTION before you look.

#### 3. Solid and ghost: one if decides what a body is

- Verb: code and form. Spine: primitives (1), visit 3 of 12. Halls: Point_One (carrier). Tracks: short, long.
- Status: runnable, /course stop Point_One, kit doc/book/studies/point-one. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: conditions, booleans, calling. Returns: variables, properties, lifecycle, errors.
- BODY: Point One's three stations rebuilt: a boolean solid decides, in one if, whether a sphere gets a collider, and a second number sets the collider's radius apart from the visible radius. You call the supplied make_solid() and make_ghost() before you open them; the kit's contact probe (pink feelers) runs through the stations.
- ARGUMENT: axis *collider radius as a fraction of the visible radius (still taken with the probe's feelers paused against each sphere)*: 0 (ghost, no collider) / 0.5 / 1.0 / 1.5. Predict: The ghost and 0.5 will look most alike: in both the feeler has entered the visible sphere (it passes through the ghost and stops halfway inside the 0.5 sphere). 1.5 stops the feeler in mid-air before it touches the surface. Claim: *What you see and what stops you are separate properties: one if and one number decide what a body is for another body.*
- DEBT: A still cannot show collision without a witness: the argument needs a second body (the probe) to make the first one's solidity visible, and so do players. Invisible walls and walkable ghosts are the course's first uncanny, and the gap between collider and mesh is a decision every game hides.
- PLACE: Walk into each sphere with the walker: the ghost lets you through, 0.5 lets you sink in, 1.0 stops you at the skin, 1.5 stops you before you touch it.
- Godot: if / else and bool · StaticBody3D, CollisionShape3D and its disabled property · SphereShape3D.radius against SphereMesh.radius · Debug > Visible Collision Shapes · calling functions you did not write · the Point One kit with its supplied contact_probe.gd, doc/book/studies/point-one [V repo] · planted bug: 'if solid = true:' (assignment where a comparison was meant) is refused by the parser: read the underline before running.
- Lineage: Processing: Learning Processing ch5 Conditionals [mem]; Handbook 'Control 1: Decisions' [mem]. NoC: none. Application: the application's polycount question has a cousin here: the collider is a cheaper body than the mesh. Klee: I.2-4 active, medial and passive lines: what acts and what is acted on [V c4, klee_ps]. Reference: Kandinsky's polarities (repose against tension) [mem]; GDQuest Learn GDScript: call supplied functions first [V research_engine]; Point One's CONSTRUCTION.md names its borrowed parts [V repo].
- Project step: Mark one of your points as a ghost and write one sentence on why a visitor should be able to walk through it.

#### 4. Coordinates: carry the point

- Verb: code and form. Spine: primitives (1), visit 4 of 12. Halls: Point_Coordinates (carrier); Trans_Introduction (encounter). Tracks: short, long.
- Status: runnable, /course stop Point_Coordinates, kit doc/book/studies/point-coordinates. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: vectors, expressions, xr. Returns: variables, properties, calling.
- BODY: A carried point that writes its own Vector3 beside itself in a Label3D, and a second point placed at an expression of the first (a + Vector3.UP, a * 0.5) that follows whenever you move the first.
- ARGUMENT: axis *which axis the same 1 m offset goes into*: (1, 0, 0) / (0, 1, 0) / (0, 0, 1) / (0.58, 0.58, 0.58). Predict: x and z will look most alike from a standing eye: both lie in the floor plane and differ only by a quarter turn. y does not, because up is the one direction your body has. Claim: *The three axes are equal in the maths and unequal for a standing body: height is the one you feel.*
- DEBT: Godot's Y-up, metres and handedness are conventions baked into every later body; the headset adds a default floor height that assumes a standing adult (Bagnall on normativity in hardware, in Queer Game Studies).
- PLACE: Pick the point up (desktop carry, or an XR Tools pickable in the headset) and watch its coordinates change as you move it. Pickup belongs here, by the standing ruling.
- Godot: Vector3 arithmetic · position against global_position · str() into a Label3D · the supplied XRToolsPickable and desktop carry · the one place the desktop walker is swapped for the XR rig (commons/scenes/vr_staging.tscn [V repo]) · the Point Coordinates kit, doc/book/studies/point-coordinates [V repo] · planted bug: the label reads the child's local position, which never changes while you carry the parent.
- Lineage: Processing: Learning Processing ch1 coordinates [mem]; Handbook 'Shape 1: Coordinates' [V via c4]. NoC: ch1 Vectors, as positions only. Application: the application's first named concepts, 'noise and vectors'. Klee: II three dimensions, borrowed early [V klee_ps l.473]. Reference: LeWitt's corner, midpoint and centre as a coordinate system before Vector3 [mem]; the Point Coordinates TUTORIAL [V repo].
- Project step: Put your three points in 3D, one of them above head height, and carry one.

#### 5. Line: distance belongs to the line

- Verb: code and form. Spine: primitives (1), visit 5 of 12. Halls: Point_Lines (carrier); Vectors_Act1_WhatAVectorIs (field trip). Tracks: short, long.
- Status: runnable, /course stop Point_Lines, kit doc/book/studies/point-lines. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: functions, parameters, return. Returns: vectors, expressions, conditions, calling.
- BODY: A segment between two carried points: your function show_between(a, b) places, scales and orients a thin box and returns the distance; a do-not-cross barrier reacts when that distance falls below a threshold (condition before threshold).
- ARGUMENT: axis *thickness as a fraction of length*: 0.005 / 0.02 / 0.1 / 0.4. Predict: 0.005 and 0.02 will look most alike: on a 1 m line both are under 2 cm and read as lines. 0.4 reads as a slab. Claim: *A line in 3D is a thin body: the ratio of thickness to length decides whether we read a line or a plane.*
- DEBT: The engine has no one-dimensional thing to show: the line is a box pretending. Distance is a return value, and every later threshold is a design decision hidden as a number.
- PLACE: Hold both ends (two hands in the headset: Klee's maker 'who has only two hands') and stretch the line until it crosses the barrier.
- Godot: func, parameters, return · distance_to() · look_at() · scale · the supplied segment.gd show_between() opened, and with it the SKETCH helper's line(a, b) (doc/book/studies/point-lines [V repo]) · planted bug: look_at() when both points coincide fails with an error: a line of length zero has no direction.
- Lineage: Processing: Learning Processing ch7 Functions [mem]; Handbook 'Shape 1' line() [V via c4]. NoC: ch1 Vectors (magnitude). Application: vectors: magnitude as a return value. Klee: I.1 an active line; I.3 a line limited by fixed points; the maker 'who has only two hands' [V klee_ps l.459]. Reference: Kandinsky, 'The Line' [mem]; the Point Lines kit [V repo].
- Project step: Connect two of your points with your own function, named after what it makes.

#### 6. The walk: a line is a record

- Verb: code and form. Spine: primitives (1), visit 6 of 12. Halls: Point_Trace (carrier). Tracks: short, long.
- Status: runnable, /course stop Point_Trace, kit doc/book/studies/point-trace. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: arrays, loops, meshes. Returns: functions, return, conditions, vectors, lifecycle.
- BODY: A trace recorder: in _process the carried point appends its position to an array once it has moved further than a gate distance (list before append; condition before threshold), and a loop redraws the array as an ImmediateMesh line strip.
- ARGUMENT: axis *sampling gate*: 0.01 m / 0.05 m / 0.2 m / 0.5 m. Predict: 0.01 and 0.05 will look most alike: both are below the width a hand-drawn curve shows at 2 m, so both read as continuous. 0.5 turns the walk into a polygon with visible corners. Claim: *A recorded line is a sampling decision: below a few centimetres the walk looks continuous; above it the corners become the drawing.*
- DEBT: Continuity is faked from a list. Memory is not free, so the trace must forget (a bounded array), and forgetting is a choice about which past counts.
- PLACE: Become the pen: the trace follows your hand (headset) or the carried point (desktop) while you walk a line through the hall, Klee's 'walk for a walk's sake'.
- Godot: Array, append(), size(), pop_front() · for ... in · ImmediateMesh PRIMITIVE_LINE_STRIP: surface_begin, surface_add_vertex, surface_end · the Point Trace kit (trace.gd, trace_strip.gd), doc/book/studies/point-trace [V repo] · planted bug: the array declared inside _process, so it is born empty every frame and the trace is never longer than one point.
- Lineage: Processing: Learning Processing ch6 Loops and ch9 Arrays (the mouse history) [mem]; Handbook 'Control 2: Repetition' [V via c4]. NoC: ch0 the random walk, as a later return (ch11). Application: pre-WP: drawing in space, as Tilt Brush does in Queer 3D's first week. Klee: I.1 'an active line on a walk, moving freely, without goal'; 'a walk for a walk's sake' [V klee_ps l.279]. Reference: Point_Trace's final.md cites Klee [V c4]; Logo's turtle [mem]; Tilt Brush in Queer 3D 2024 [V QUEER3D.md].
- Project step: Record one walk of your own and keep it as data in your project.

#### 7. Plane: when the line closes

- Verb: code and form. Spine: primitives (1), visit 7 of 12. Halls: Point_Triangle_Context (carrier); Primitives_Polythedra (field trip). Tracks: short, long.
- Status: planned
- CODE new: surface_tool, normals, collision. Returns: arrays, loops, meshes, vectors.
- BODY: Close the walk: the recorded points become a triangle fan through SurfaceTool, normals are generated, and a collider made from the mesh lets you stand on the plane you walked.
- ARGUMENT: axis *winding and normals*: clockwise, flat normals / clockwise, smooth normals / counter-clockwise (reversed) / reversed, double-sided. Predict: 'clockwise flat' and 'reversed double-sided' will look most alike from above: both are visible and flat-lit. 'reversed' alone vanishes from the front. Claim: *A surface has a side: what you see of a plane is a promise its winding and normals make (Godot winds front faces clockwise).*
- DEBT: Culling (Gaboury, Image Objects, 'Culling Vision'): hidden-surface algorithms decide what exists for the eye; a one-sided plane is invisible from behind while its collider still stops you. The fan also fails on concave walks: the approximation owes the shape its dents.
- PLACE: Stand on your walk: the plane made from your own trace becomes floor; walk to its edge and look under it.
- Godot: SurfaceTool PRIMITIVE_TRIANGLES, add_vertex(), generate_normals(), commit() · ArrayMesh · create_trimesh_shape() on a StaticBody3D · cull_mode · planted bug: vertices added counter-clockwise (the OpenGL habit): the plane is invisible from above and visible from below.
- Lineage: Processing: Learning Processing ch14 vertex shapes [mem]; Handbook 'Shape 2: Vertices' [V via c4]. NoC: none. Application: WP2 'queer meshes and textures' start here: a mesh is a list someone ordered. Klee: I.2-4 'once completed, this linearity is replaced by planarity' [V klee_ps l.294]. Reference: Kandinsky, 'The Basic Plane' [mem]; Gaboury, Image Objects ch1 'Culling Vision' [V research_ccs].
- Project step: Your room so far: one plane you walked, three points and one line. Commit it.

#### 8. When things go wrong: the drafter is a machine

- Verb: code and form. Spine: primitives (1), visit 8 of 12; postfoundationscrisis (25), visit 1 of 3. Halls: Point_Animatedcube (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter). Tracks: short, long.
- Status: planned, /course stop W01_break_it_on_purpose. The debugger half of this chapter is the existing workshop W01 (Break it on purpose, then look it up), whose messages come from Godot 4.6 runs. The AI drafter protocol and the first export are not written. The opening's checkpoint CP1 (a draft) fits between ch07 and ch08.
- CODE new: ai_assist, debugging, export_build. Returns: errors, surface_tool, normals, arrays, functions, calling.
- BODY: A cube from 8 corners and 12 triangles (Point_Animatedcube's body), drafted by an AI assistant from your written instruction under a protocol of three lines: what should change, what must not change, and one observation that would prove the code wrong. You run it, step through it with breakpoints until you find where its faces turn inside out, repair it, and export a desktop build.
- ARGUMENT: axis *how much the prompt fixes*: vague ('make a cube') / counted ('8 corners, 12 triangles') / measured ('0.5 m, resting on the floor') / located ('at the end of my walk, in Godot's clockwise winding'). Predict: vague and counted will look most alike: both come back as a default 1 m cube at the origin, and both are likely inside out, because the model's idea of a cube comes from engines that wind counter-clockwise. Only 'located' is right side out on the first try. Claim: *Where the prompt is open, the model fills in its defaults: the generated body shows the model's idea of a body and of an engine, not yours.*
- DEBT: Algorithmic enclosure and the default body: the assistant learned from other people's code and repeats its norms (a cube at the origin, a capsule player, OpenGL winding). Chun's 'sourcery': seeing generated source is not knowing what it does. A build is a second machine with its own errors (read-only res://, another refresh rate).
- PLACE: Run your exported build on a classmate's laptop, or on the headset where one is available (the headset is an export): the first time your room exists outside your editor, and you stand in it. In the short track, the scans made on day 4 are imported by the teacher (glTF, scale fixed) and already stand in your room for this first export, so the collage reaches the headset in week one; ch18 teaches the import and makes the scan a member of your family.
- Godot: breakpoints, step over and step into, the Debugger's Stack Frames and Members · the remote scene tree while the game runs · push_error() and assert() as your own error messages · Project > Export: a desktop preset, and the Android/Quest preset with its templates · planted bug (supplied by the drafter): counter-clockwise triangles, found by stepping through the loop that emits them.
- Lineage: Processing: Processing Handbook 'Development 1: Sketching' and 'Development 2: Iteration, Debugging' [V via c7]. NoC: none. Application: the application's hacker ethics: Illich's transparency and repairability; Queer 3D 2024 'use ChatGPT to write simpler programs' [V QUEER3D.md]. Klee: none: Klee's maker has two hands, this drafter has none. Reference: Code as Creative Medium interview theme 'When Things Go Wrong' [V ToC via c7]; LeWitt's drafters as the model for directing a machine drafter [V research_bauhaus]; Montfort, Exploratory Programming: 'valid and intentional are different' [V research_ccs]; Chun, Programmed Visions, 'On Sourcery' [V contents via LEARN].
- Departure: Directing generated code has no spine sequence: it is Palle's own Queer 3D practice, and every later planted bug assumes the debugger, so it closes week one. The bias hall (postfoundationscrisis, spine 25) is walked as an encounter only; it returns as a carrier at ch38.
- Project step: SYNTHESIS I: export your room (the walked plane, three points, one line and the repaired drafted cube) and stand in it on another machine. Keep the prompt, the model's first answer and your repair in the README.

### Structure: repetition, disorder, articulation (Klee I.5-12; Nake, Nees, Molnar)

Repeat a body and it becomes a floor; move the rule into the surface and it becomes a pattern; disturb it and chance appears; give chance a memory and it becomes ground you can walk; articulate the body and it moves by itself.

#### 9. The chessboard: purely repetitive and therefore structural

- Verb: repeat. Spine: array_tutorial (3), visit 1 of 3; primitives (1), visit 9 of 12; color (4), visit 1 of 3. Halls: Point_Line_Grid (carrier); Array (carrier); Tutorial_3D (field trip); Color_Rainbow (field trip). Tracks: short, long.
- Status: planned
- CODE new: nested_loops, instancing, materials. Returns: loops, arrays, conditions, expressions, collision, booleans.
- BODY: A floor of cubes instanced from a PackedScene in a nested loop. Each cube gets a StandardMaterial3D made in code, coloured by a rule over (x, z): first two colours of your own, then a hue from the index, Color.from_hsv(float(x + z) / (2 * n), s, v).
- ARGUMENT: axis *rhythm rule over the same 8 x 8 cubes*: every cell alike / (x + z) % 2 chessboard / x % 3 stripes / hue from x + z. Predict: The chessboard and the x % 3 stripes will look most alike from 6 m, where both read as texture. The hue ramp is the only floor with a direction; 'every cell alike' is the only one without rhythm. Claim: *Structure is the repetition rule, not the cube: the same 64 bodies make four different floors.*
- DEBT: The grid is the unexamined ground of 3D (editor grids, voxels, the frame buffer as a grid, after Gaboury); it is a choice, and the standing ruling holds that the first line did not need it. HSV promises equal steps of hue, and the eye does not see them as equal: the yellow band looks brighter and wider than the blue one.
- PLACE: Walk the floor; turn one cell into a ghost with ch3's if and fall through it.
- Godot: nested for over range() · PackedScene.instantiate() and add_child() · StandardMaterial3D.new() and albedo_color; one material per cube against one shared · Color.from_hsv() · the % operator · stepping through the inner loop with a breakpoint (ch8's debugger returns) · planted bug: hue = (x + z) / (2 * n) in integers is 0 for every cell, the whole floor comes out red, and the editor's integer-division warning says why (float() is the repair; types are named in ch14).
- Lineage: Processing: Learning Processing ch6 nested loops [mem]; Handbook 'Control 2' [V via c4]; Form+Code 'Repeat: Embedded Iteration' [V c3]. NoC: none. Application: pre-WP: the application's 'increasingly complex control structures' begin with a loop inside a loop. Klee: I.5-6 structural rhythm, the chessboard, 'purely repetitive and therefore structural'; I.7 divisional proportion 2:3:5 [V klee_ps l.182]. Reference: Point_Line_Grid's plan_vitrine 5 x 5 nested loop with two materials [V digest]; Color_Rainbow's Color.from_hsv(i/N) bands [V digest]; Albers: a constrained palette first [V research_bauhaus].
- Departure: array_tutorial (spine 3) comes before transformation (spine 2), and colour (spine 4) enters inside it as a value: Klee puts structure (I.5-6) before the organism (I.9-12), Form+Code puts Repeat before Transform, and bodies can be repeated with position alone. Transform arrives with the organism (ch13); colour as a system returns at Klee's close (ch29).
- Project step: Lay a floor for your room with a rhythm rule of your own and two colours you chose.

#### 10. Pattern: structure moves into the surface

- Verb: repeat. Spine: tiling (5), visit 1 of 1; array_tutorial (3), visit 2 of 3. Halls: Tutorial_Tiling_Floor (carrier); Symmetry_Seventeen (carrier); Tutorial_Pattern (field trip); Pattern_Foundry (field trip); Shader_05_Patterns (encounter). Tracks: long.
- Status: planned
- CODE new: uv, dictionaries. Returns: nested_loops, materials, functions, conditions.
- BODY: A tile written pixel by pixel into an Image from a 4 x 4 source kept as a Dictionary recipe {size, source, rule}, wrapped as an ImageTexture and repeated over your floor by UV scale; one get_color(x, y) function per symmetry rule (Symmetry_Seventeen's p1, pm and pg).
- ARGUMENT: axis *wallpaper rule over one 4 x 4 source*: p1 translation / pm mirror / pg glide / p4 rotation. Predict: pm and pg will look most alike: both keep one mirror direction, and the glide only shifts alternate rows by half a tile. p4 is the outlier, the only one without a single preferred direction. Claim: *The same sixteen pixels make four patterns: symmetry is a rule applied to a source, and the rule is what we see.*
- DEBT: Texture filtering and mipmaps blur the rule at a distance (nearest against linear); the seventeen wallpaper groups are a closed classification that the ornament traditions they describe never needed.
- PLACE: Floor and walls of your room share one texture; walk away until the pattern reads as tone rather than tiles. Then walk Shader_05_Patterns: the same kind of symmetry rule, computed for every pixel on every frame by the graphics card instead of written once into an Image. You write one at ch30.
- Godot: Image.create() and set_pixel() · ImageTexture.create_from_image() · uv1_scale and texture_filter · Dictionary literals and lookup (a body as a recipe) · planted bug: set_pixel at x == size is out of bounds; the wrap (x % size) is both the repair and the pattern's own rule.
- Lineage: Processing: Learning Processing ch15 Images and Pixels [mem]; Handbook 'Image 1' [mem]. NoC: none. Application: WP3 'pattern and world building' (in name). Klee: I.6 quantitative structure moving into two dimensions [V c4]. Reference: SFPC Recreating the Past: Pattern (Anni Albers, Bridget Riley) [V research_creative]; Symmetry_Seventeen's three get_color rules [V digest]; The Book of Shaders 'Patterns' as a later return (ch30) [V research_engine].
- Departure: tiling (spine 5) comes before transformation (2) and before colour as a system (4): regularity is taught right before randomness, as 10 PRINT argues, so the next chapter has a pattern to disturb.
- Project step: Give your room one pattern of your own made from a 4 x 4 source.

#### 11. Disturbed order: chance enters the grid

- Verb: repeat. Spine: randomness (10), visit 1 of 5. Halls: Randomness_10_PRINT_Algorithm (carrier); Random_Definition (carrier); Random_Remove (field trip); Random_Walk (field trip). Tracks: short, long.
- Status: runnable, kit doc/book/studies/random-definition. The kit runs in Godot 4.6 and carries the chapter's body; the chapter's argument sheet, prediction and planted bug are not yet written into it.
- CODE new: random, seeds. Returns: nested_loops, instancing, materials, collision, loops.
- BODY: Schotter as a floor: your chessboard of cubes rotated and displaced by a seeded RandomNumberGenerator, more with every row; and 10 PRINT as a walkable maze, one of two rotations per cell.
- ARGUMENT: axis *disorder amplitude (maximum rotation in the last row)*: 0 degrees / 5 degrees / 20 degrees / 90 degrees. Predict: 0 and 5 will look most alike: 5 degrees moves a 1 m cube's corner about 6 cm, less than the gap between cubes, so the grid still reads. Somewhere between 5 and 20 it stops reading as a grid. Claim: *Randomness is visible only against a structure already built: the grid is what lets us see disorder.*
- DEBT: Computer randomness is pseudo-random: the same seed returns the same 'chance' (Random_Definition: a pattern that returns). Nake's question from Hommage a Paul Klee (1965): can a pseudo-random number stand in for the artist's intuition? And a seed is a promise of repeatability that someone else can use to reproduce you.
- PLACE: Walk down the Schotter floor until the disorder makes it unwalkable (the colliders follow the cubes); get lost in the 10 PRINT maze.
- Godot: RandomNumberGenerator, seed, randf_range(), randi_range() · per-instance rotation · the random-definition kit: display.gd supplied, six steps as recovery points (doc/book/studies/random-definition [V repo]) · planted bug: randomize() left in after setting the seed, so the 'repeatable' floor changes on every run.
- Lineage: Processing: Learning Processing ch4 random() [mem]; Handbook 'Math 4: Random' [V LEARN]. NoC: ch0 Randomness; the random walk (field trip). Application: WP1 Basic Elements: randomness. Klee: absent from Klee: the lineage's first departure. Reference: Frieder Nake, Hommage a Paul Klee (1965); Georg Nees, Schotter (1968); Vera Molnar, (Des)Ordres [V research_bauhaus]; 10 PRINT: 'Regularity' before 'Randomness' [V research_ccs]; the random-definition kit [V repo].
- Departure: randomness (spine 10) is met at chapter 11 of 41, right after the grid and the tile: it enters Klee's lineage in 1965-68 as the disturbance of a grid already built (Nake, Nees, Molnar); the 2023 application puts it in WP1, and Queer 3D's foundation asks 'what is randomness' first. It returns as the midterm round (ch25) and as entropy (ch40).
- Project step: Add a seeded disorder to your floor and record the seed you keep.

#### 12. Noise: chance that remembers its neighbour

- Verb: repeat. Spine: noise (11), visit 1 of 4. Halls: Noise_Space_10 (carrier); Noise_Columns (field trip); Random_Space_Geometry (field trip); Random_Noise_Types (encounter). Tracks: short, long.
- Status: planned
- CODE new: noise, packed_arrays. Returns: random, seeds, surface_tool, normals, collision, nested_loops.
- BODY: A small walkable terrain: FastNoiseLite sampled on a grid into a PackedFloat32Array of heights, multiplied by an edge envelope and emitted as an ArrayMesh with a collider made from it (Noise_Space_10's body). A supplied heightfield helper covers the mesh step in the short track.
- ARGUMENT: axis *where the heights come from, all at the same amplitude and grid*: randf() per vertex / sin(x) * sin(z), from the supplied wave_height(x, z) / Perlin noise / cellular (Voronoi) noise. Predict: The sine and the Perlin terrain will look most alike from above at this frequency: both roll smoothly, and the sine is only too regular. randf() is the outlier, a field of spikes, because no vertex knows its neighbour. Claim: *Noise is randomness with a memory of its neighbour: only the sources that remember can be walked on.*
- DEBT: The blob aesthetic (Queer 3D 2024): smooth noise became CGI's look of the 'natural'. And the grid decides how much of the noise exists: octaves finer than the vertex spacing are computed and never seen. Queer 3D's overflow-rate comparison of noise types (Perlin 45, random 635, Voronoi 0, sine-curve space 3284) says the same with numbers.
- PLACE: Walk your terrain. Which source makes ground you can cross? randf()'s cannot be walked; the cellular one is a field of cells with ridges between them.
- Godot: FastNoiseLite: noise_type, frequency, seed, get_noise_2d() · PackedFloat32Array and PackedVector3Array · an ArrayMesh from arrays, or SurfaceTool · create_trimesh_shape() · the supplied one-liner wave_height(x, z), which returns sin(x) * sin(z): you call it here and open it at ch24, where trig is taught · planted bug: frequency 1.0 on a 1 m grid samples the noise once per cycle, the terrain looks like randf() (aliasing), and the repair is a smaller number, not a new source.
- Lineage: Processing: Learning Processing ch13 noise() [mem]; Handbook 'Math 4' noise() [mem]. NoC: ch0 Perlin noise. Application: WP1 Perlin noise and Voronoi diagrams (the cellular source). Klee: none. Reference: Queer 3D 2024: first principles (randomness, then simplex noise), the blob aesthetic, the overflow rate [V QUEER3D.md]; Noise_Space_10 and Noise_Columns [V digest]; Ken Perlin (1985) [mem]; Catlike Coding hashes before noise [V research_engine].
- Departure: noise (spine 11) follows chance straight away, at chapter 12: Queer 3D's first principles put simplex noise second, after randomness, and the application lists Perlin noise and Voronoi in WP1. The noise sequence's other halls return later: the field of arrows (ch28), fBm in the shader (ch30) and the voxel volume (ch36).
- Project step: Give your room ground: a noise terrain you can walk, with its seed and frequency recorded.

#### 13. The organism: bone, tendon, muscle

- Verb: transform. Spine: transformation (2), visit 1 of 3. Halls: Trans_Rotation (carrier); Trans_Body (carrier); Trans_Translation (field trip); Trans_Pre (field trip). Tracks: long.
- Status: planned
- CODE new: transforms, basis, delta. Returns: vectors, lifecycle, instancing, loops.
- BODY: A limb of three segments as a parent-child chain with pivots, each joint turning by angle += speed * delta in _process: the course's first body that moves by itself. Beside it, Trans_Body's lattice loses cells where the limb passes.
- ARGUMENT: axis *where the pivot sits on each segment (same joint angles)*: at the end / at one third / at the centre / outside the segment. Predict: 'at the end' and 'at one third' will look most alike after 30 degrees: both bend like a finger. 'outside' makes the chain orbit instead of bend. Claim: *A body's motion is decided by where its joints are, not by what its parts look like.*
- DEBT: Klee maps active, medial and passive onto brain, tendon and bone, and onto male and female organs ('Male organs (anthers), active'). The scene tree encodes the same command chain: the parent moves the child, never the reverse. That hierarchy is taught here and inverted in ch21. And frames are not time: speed per frame runs 1.5 times faster at the headset's 90 Hz than at 60 Hz; delta is the repair promised in ch2.
- PLACE: Become it: attach the chain to your hand (headset) or the carried point and walk it through Trans_Body's lattice, carving a passage with your own movement ('chip from chip').
- Godot: the Node3D hierarchy, transform and basis · rotate_object_local() · pivots as parent nodes · _process(delta) · to_global() and to_local() · planted bug: rotation applied to the mesh child instead of the pivot, so each segment spins on its own centre and the chain comes apart.
- Lineage: Processing: Learning Processing ch14 Transformations [mem]; Handbook 'Transform 1-2' [V via c4]. NoC: ch3 angular motion, previewed. Application: pre-WP: vectors become frames. Klee: I.9-12 bone, tendon and muscle; 'First organ active (brain)'; 'Male organs (anthers), active' [V klee_ps l.359-415]; 'stone upon stone' against 'chip from chip' [V klee_ps l.420-428]. Reference: Gaboury, Image Objects, 'Object Paradigms' [V research_ccs]; the Processing Handbook's static-before-continuous order [V LEARN]; Trans_Body's carve_grid [V digest].
- Departure: transformation (spine 2) comes after repetition, chance and noise: Klee's organism (I.9-12) follows structure (I.5-6) and Form+Code puts Transform after Repeat. Position was never delayed (ch4); what waited is the frame, the pivot and time (delta), promised since ch2.
- Project step: Give one body in your room a jointed part that moves.

### The family (Klee I.7-8; Albers; Molnar): Parameterize, declared as an addition

You describe a body in a single class whose exported fields make a family, sweep one axis into a comparison sheet, measure what each value costs, save a body as a file, and bring a found body into the family's room. The short track pivots into its mini project here.

#### 14. Families: one body in a single class

- Verb: parameterize. Spine: primitives (1), visit 10 of 12. Halls: Primitives_Ignorance (carrier); Primitives_Polythedra (encounter). Tracks: short, long.
- Status: planned
- CODE new: classes, export, types. Returns: functions, parameters, instancing, loops, meshes, variables.
- BODY: Describe a body in a single class: class_name with two typed @export fields (for a sphere, rings and segments; for your own body, whatever makes it) and a build() function that makes the mesh in _ready(). The supplied sweep sheet instances four members side by side, labelled.
- ARGUMENT: axis *sphere segments (rings = half)*: 4 / 8 / 16 / 64. Predict: 16 and 64 will look most alike at 2 m: the silhouette of 16 segments misses the true circle by 1 - cos(11.25 deg), about 2% of the radius. 4 is not a coarse sphere but another body, close to an octahedron. The chord arithmetic is given to you here; at ch24 you compute it with cos() yourself. Claim: *Above about 16 segments a sphere stops paying visibly; below 8 it changes category: the class's integer decides which body you have.*
- DEBT: A class's fields decide which bodies are possible (the CCSWG prompt 'describe it in a single class', turned to a body): an int cannot have 3.5 segments, and no value of rings makes a torus. Polycount against smooth deformation, the application's topology question, enters here. And a typed set() refuses a wrong type in silence, so a sweep can publish four identical members and look finished (the Ada project's own science_screen case).
- PLACE: Walk the sheet as a gallery wall; carry one member into your room.
- Godot: class_name and extends · @export and @export_range · typed variables (var rings: int = 16); the integer-division warning of ch9 named · the supplied sweep_sheet scene (to be written for the course; Ada's tools/build_dna_gallery.py is the adult version) · counting triangles from mesh.surface_get_arrays(0) · planted bug: the sweep sets rings from a text field as the string '16'; set() on a typed int refuses it in silence and four identical spheres come back. Read the printed triangle counts before believing the sheet.
- Lineage: Processing: Learning Processing ch8 Objects (Zoog becomes a class) [mem]; Handbook 'Shape 3: Parameters' [V LEARN]. NoC: ch0-1 the Walker and Mover classes. Application: WP2 'queer meshes' (polycount against smooth deformation, application l.89). Klee: I.7 individual articulation by proportion; I.8 linear variation [V c4]. Reference: Form+Code 'Parameterize' [V c3]; Vera Molnar's series [V research_bauhaus]; CCSWG 2024 teaching thread ('describe it in a single class') [V research_ccs]; Primitives_Ignorance's sphere_high and budget_of_smoothness [V digest]; the Ada CLAUDE.md on silent typed set() [V repo].
- Departure: Parameterize has no spine sequence: this part (ch14-18) is an addition, declared as one, and it returns to primitives halls (spine 1) whose works are already families. It comes after chance and noise so that the seed and the frequency can become axes of the family; 74% of Ada's scripts are built this way (@export) [V BRIEF].
- Project step: Turn one of your bodies into a class with two axes; write the closest-pair prediction before rendering its sheet.

#### 15. The family in the editor: setters, @tool and the sheet opened

- Verb: parameterize. Spine: color (4), visit 2 of 3; softbodies (17), visit 1 of 3. Halls: Color_Context_Placed (carrier); Topology_Entropy_Morphogenesis (carrier). Tracks: long.
- Status: planned
- CODE new: setters, tool_scripts, methods. Returns: classes, export, types, instancing, loops.
- BODY: Your class with setters that rebuild on change, a rebuild() method, and @tool so the family changes live in the editor (Color_Context_Placed's chroma_stack with its @export_enum rule is the precedent). Then open the supplied sweep sheet and rewrite it yourself, one labelled member per value. For the argument the sheet sweeps Ada's own pyramid (commons/primitives/pyramid/pyramid.gd), whose @export_enum you read rather than retype. pyramid.gd builds its mesh only in _ready(), so the sheet must set apex_stance before add_child(): set it afterwards and nothing changes, which is the reason your own class gets a setter.
- ARGUMENT: axis *where the apex sits over the base: apex_stance, the @export_enum in Ada's pyramid.gd (base 0.6 m, height 0.8 m)*: centred / edge / corner / beyond. Predict: corner and beyond will look most alike. In pyramid.gd's own numbers the apex sits at (0, 0), (0, -0.3), (-0.3, -0.3) and (-0.48, -0.48) in plan: corner and beyond are 0.25 m apart, the closest pair, while centred to edge and edge to corner are 0.30 m apart, and corner and beyond lean along the same diagonal. What the sheet has to show is the one thing the distances do not rank: beyond is the only member whose apex has left its own footprint. Claim: *One exported enum carries a pyramid from monument to lean-to, and the step that changes the category is not the largest step.*
- DEBT: The Inspector slider hides what each value costs and what it breaks. Defaults are sacred: an Ada artifact can have hundreds of live placements, so changing a default silently changes every hall it stands in. A setter that rebuilds on every change can stall the editor, and a @tool script runs your bugs inside the editor itself. And the values on your sheet must be read from the code, not typed from memory: a value the class's match does not know falls back to the default without an error, and the sheet shows the same body several times (the Ada DNA programme's science_screen case).
- PLACE: Carry it: a supplied in-world slider changes the family while you hold the body.
- Godot: set(value): field = value; _rebuild() · @tool and Engine.is_editor_hint() · methods on your own class · @export_enum · Ada's pyramid.gd as the swept class: read its @export_enum("centred", "edge", "corner", "beyond") [V repo] and its _apex_position(); its base ring uses sin and cos, opened at ch24 · the sweep sheet opened and rewritten · planted bug: the setter calls _rebuild() before the node is ready, so errors fill the Output as soon as the scene opens (guard with is_node_ready()).
- Lineage: Processing: Handbook 'Shape 3: Parameters' [V LEARN]. NoC: none. Application: the application's families are its DNA: a queer mesh is a family, not one mesh. Klee: I.8 linear variation [V c4]. Reference: Form+Code 'Parameterize: Chair' [V c3]; Generative Design's numbered variants [V research_creative]; Albers: fix the material, vary one thing [V research_bauhaus]; Topology_Entropy_Morphogenesis's setter that lerps three parameters [V digest].
- Departure: Color_Context_Placed (color, spine 4) and Topology_Entropy_Morphogenesis (softbodies, spine 17) are visited only for their @export_enum and setter patterns. The colour hall returns as a system at ch29, the soft hall in full at ch35.
- Project step: Turn your room's main body into a family with one exported axis and hang its comparison sheet at the entrance.

#### 16. The budget: polycount measured, a claim tested

- Verb: parameterize. Spine: primitives (1), visit 11 of 12; formfinding (8), visit 1 of 4. Halls: Primitives_Portals (carrier); FormFinding_Catenary (carrier); Primitives_Ignorance (field trip). Tracks: long.
- Status: planned
- CODE new: testing, profiling. Returns: export, loops, surface_tool, uv, functions.
- BODY: A parametric surface, the catenoid (u, v) -> point, with exported u_steps and v_steps: you write the two loops over u and v and the SurfaceTool emission, and call a supplied catenoid(u, v) for the point itself (FormFinding_Catenary's formula, with cosh and cos, read now and opened at ch24). Beside it, Primitives_Portals' torus ring, whose segments double while its gap to the true circle is printed and asserted, using the supplied one-liner gap_to_circle(n) = 1 - cos(PI / n).
- ARGUMENT: axis *u_steps of the catenoid*: 6 / 12 / 24 / 48 / 96. Predict: 48 and 96 will look most alike at 2 m: at 48 steps the chord misses the circle by 1 - cos(3.75 deg), about 0.2% of the radius, while 96 costs twice the triangles. The prediction is also written as a test: gap_to_circle(n) < 0.01 passes from n = 24 (0.86%) and fails at 12 (3.4%). Claim: *A parametric surface has a step count below which it is a different body and above which it is only cost: the test finds the first, the profiler the second.*
- DEBT: 'Smooth' is a budget decision (application l.89: polycount against deforming a body smoothly), and in a headset at 72-90 Hz every triangle is drawn once per eye. A green test is a fact about the question you asked, not about the body (Montfort: valid and intentional are different).
- PLACE: Stand in it: the catenoid as a neck you walk through at room scale (collider from the mesh). The headset's frame time is the debt you feel: stutter makes people sick, so comfort is not polish.
- Godot: assert() in a headless check: godot --headless --script · the Profiler and Monitors: frame time, draw calls, primitives · Time.get_ticks_usec() around a build · a surface from (u, v) with UVs · the supplied catenoid(u, v) and gap_to_circle(n): called here, opened and rewritten at ch24 · planted bug: the test compares floats with == (gap == 0.0 never passes): write a tolerance.
- Lineage: Processing: Handbook 'Development 2: Iteration, Debugging' [V via c3]. NoC: none. Application: polycount (application l.89); the headset's frame rate. Klee: none. Reference: Form+Code 'Parameterize: Wave' [V c3]; Catlike Coding 'Measuring Performance' [V research_engine]; Primitives_Portals's gap_to_circle per n [V digest].
- Departure: formfinding (spine 8) is visited early for one surface: the catenoid is a parametric (u, v) body and belongs with Parameterize. Form found by force returns with balance (ch20) and the soft bodies (ch35).
- Project step: Measure your room's frame time on the target machine and cut the one body that costs most without changing what it argues.

#### 17. Genes as files: a family saved, a body recalled

- Verb: parameterize. Spine: proceduralgeneration (16), visit 1 of 2; randomness (10), visit 2 of 5. Halls: PG_Genetic_Evolution (carrier); Random_Definition (field trip); LSystems_Living (encounter). Tracks: long.
- Status: planned
- CODE new: resources, save_load. Returns: classes, export, dictionaries, random, seeds, instancing.
- BODY: A creature genome as a custom Resource (segments, limb_count, limb_angle, colour, seed) and a builder that turns it into primitive-mesh parts; the chosen specimen is saved as .tres in user:// and comes back after a restart.
- ARGUMENT: axis *the limb_count gene*: 0 / 2 / 4 / 6 / 12. Predict: 6 and 12 will look most alike from above: past about six limbs the body reads as radial, a star or a flower, not an animal. Claim: *A genome draws a border between kinds: somewhere between 4 and 6 limbs, a creature becomes a flower.*
- DEBT: A saved body is a frozen choice: the genome decides which creatures are possible and which can never be born, the dark spot of the encoding. Resources are shared by default, so two bodies can secretly share one gene.
- PLACE: Carry it: the specimen is a pickable that survives leaving and re-entering the room, a museum specimen.
- Godot: class_name Genome extends Resource with @export fields · ResourceSaver.save() and load() · a save-and-load round trip in user:// · resource.duplicate(true) · planted bug: five bodies built from one Genome instance: mutate one and all five change (duplicate() is the repair).
- Lineage: Processing: Learning Processing ch18 Data [mem]. NoC: ch9 genotype and phenotype, previewed. Application: WP3 evolutionary algorithms, previewed. Klee: none. Reference: Form+Code 'Parameterize' [mem]; Levin and Brain 'Virtual Creature' [V research_creative]; Karl Sims, Evolved Virtual Creatures (1994) [mem]; Ada's DNA programme (dna.axes in the registry) [V repo CLAUDE.md].
- Departure: proceduralgeneration (spine 16) is visited early for its genome-as-file pattern, where Parameterize ends: a family becomes data that can be saved, shared and bred. Evolution itself returns with the bodies that learn (ch38).
- Project step: Save your room's family as files and let a classmate load and breed one specimen.

#### 18. Collage: a found body joins the family

- Verb: parameterize. Spine: primitives (1), visit 12 of 12. Halls: Primitives_Melencolia (carrier). Tracks: short, long.
- Status: planned
- CODE new: import_assets. Returns: classes, export, meshes, surface_tool, ai_assist, export_build, errors.
- BODY: Recreate a precedent: the truncated solid of Durer's Melencolia I built as a member of your family, beside a body you scanned (phone photogrammetry in week one) or drew in Tilt Brush or Blender and imported as glTF.
- ARGUMENT: axis *how the body was made*: hand-coded / AI-coded from your instruction / scanned / sculpted in VR. Predict: The hand-coded and the AI-coded will look most alike: same instruction, same primitives. The scan is the outlier by triangle count, not by silhouette. Claim: *How a body was made shows less in its silhouette than in its triangle count and its errors.*
- DEBT: Recreation (SFPC Recreating the Past): the difference between Durer's solid and yours is where the debt is written; the Melencolia hall already says its hidden surfaces 'are decisions we have made'. The scan has millions of triangles, holes and no inside, and whose bodies scan well is not neutral (Queer 3D: stretchability, topology, bias).
- PLACE: A hybrid room (Queer 3D's ontology layer): imported and procedural bodies share one floor. Export the build and show it.
- Godot: glTF import and its settings: scale, root type, generate collision · fixing scale and origin; decimating in Blender · a scanned mesh inside your family's scene · planted bug: the import arrives 100 times too large (centimetres against metres): read its AABB in the Inspector before moving the camera.
- Lineage: Processing: Handbook 'Synthesis 1: Form and Code' [V via c4]. NoC: none. Application: the application's commons (open, repair, change: Illich, Freire); WP2 queer meshes: the scan is a mesh nobody ordered. Klee: I.12 additive and subtractive making, 'stone upon stone' against 'chip from chip' [V klee_ps l.420-428]. Reference: Hannah Hoch and Hans Bellmer (collage, Queer 3D 2024) [V QUEER3D.md]; the ReCode Project [V research_creative]; Durer, Melencolia I; Primitives_Melencolia's durer_scene [V digest].
- Departure: A deliberate return to the last primitives hall (Melencolia, spine 1) as the synthesis of Parts I-III; it closes the teaching half of the short track, which pivots into the mini project here.
- Project step: SYNTHESIS II and the short track's pivot: export your room as a build with your family and one found body. The mini project starts from this build.

### Dimension and balance (Klee II)

The eye and the standing body: perspective as a fact about eye height, balance as a fact about the centre of mass, and legs that let the passive end drive. The walker you have used since day one is opened.

#### 19. Eye level: the walker opened

- Verb: transform. Spine: transformation (2), visit 2 of 3; foundationscrisis (23), visit 1 of 2. Halls: Trans_Scale (carrier); Escher_Impossible (field trip). Tracks: long.
- Status: planned
- CODE new: camera, input, player. Returns: transforms, collision, vectors, conditions, xr, delta.
- BODY: The walker you have used since ch1, opened: a CharacterBody3D with move_and_slide(), InputMap actions and your own Camera3D whose height and field of view you change. Its capsule is swapped for a body of your family, and railroad tracks made in a loop run to the horizon.
- ARGUMENT: axis *eye height*: 0.3 m (crawling) / 1.1 m (seated, or a child) / 1.7 m (standing adult) / 8 m (bird). Predict: 1.1 and 1.7 will look most alike: the horizon sits mid-frame in both and the ties converge alike. 8 m flips the tracks into a plan. Claim: *Perspective is a fact about the eye's height, not about the tracks: the same geometry gives a plan or a corridor.*
- DEBT: The camera decides what exists (frustum, near plane; 'an iso view is half blind'), and the default player is a capsule with an eye at a standing adult's height; the headset's default floor height and eye distance assume the same body (Bagnall). Montfort's 'Critique My Starter Programs', turned on Godot's capsule.
- PLACE: In the headset your head is the camera: crouch and the horizon moves with you. Trans_Scale scales the room by four and relocates you: you are the scale that changed.
- Godot: CharacterBody3D: velocity, move_and_slide(), is_on_floor() · InputMap actions and Input.get_vector() · Camera3D: fov, current · _unhandled_input for mouse look · the skin separated from the controller, so the XR rig can replace it · planted bug: gravity added to velocity.y and then velocity replaced by the input vector, so the walker floats off every ledge.
- Lineage: Processing: Learning Processing ch14 (the P3D camera) [mem]. NoC: none. Application: VR presence, the application's premise. Klee: II railroad ties and eye level: 'A line connecting all spatial points, lying on eye level'; 'It isn't wrong logically' but psychologically [V klee_ps l.478-530]. Reference: Montfort, Exploratory Programming, 'Critique My Starter Programs' [V research_ccs]; GDQuest's skin and controller split [V research_engine]; Godot's 'Your first 3D game' as the precedent critiqued [mem].
- Departure: A second transformation hall (spine 2) after the family part; Escher_Impossible (foundationscrisis, spine 23) is a field trip for one viewpoint and returns as a carrier at ch39. The player is opened in Klee's part on the eye rather than with the forces, so the small-game kit can come together at ch25.
- Project step: Put the player in your room at an eye height you choose, and write why.

#### 20. The tightrope walker: balance

- Verb: simulate. Spine: formfinding (8), visit 2 of 4; forces (7), visit 1 of 5. Halls: FormFinding_Equilibrium (carrier); FormFinding_Forge (carrier); VFM_09_Legs (field trip). Tracks: long.
- Status: planned
- CODE new: physics_bodies, signals. Returns: collision, transforms, instancing, conditions, player.
- BODY: A plate on posts as a RigidBody3D whose centre of mass you move, released onto two, three or four legs (VFM_09_Legs' tip-or-hold); a signal fallen() fires when it tips and a counter listens; then a stack of your family members that must stand (FormFinding_Forge's balance puzzle).
- ARGUMENT: axis *centre-of-mass offset relative to the support polygon (still 3 s after release)*: at its centre / halfway to the edge / on the edge / outside. Predict: 'centre' and 'halfway' will look most alike: both stand, level. 'outside' has fallen. 'on the edge' is the prediction's risk: it may hold or tip, and the still decides. Claim: *Standing is a fact about the centre of mass and the support polygon, not about how heavy or large the body looks.*
- DEBT: The engine's rigid body is a promise that nothing bends; stacking is solved by iterations, so a tower that should stand can jitter and one that should fall can fall asleep. Klee: the tightrope walker 'is the scale', balance as a relation, not a posture.
- PLACE: Stand on it: step onto the plate yourself (the player is a body too) and feel where it tips.
- Godot: RigidBody3D: mass, center_of_mass_mode and center_of_mass, freeze · the sleeping state · signal fallen, emit(), connect() · body_entered · planted bug: a signal connected to a method with the wrong number of arguments is refused at every emit and the counter never moves (count the arguments).
- Lineage: Processing: none: Processing has no physics engine [mem]. NoC: ch5 physics libraries. Application: WP2 soft body simulation's rigid ancestor. Klee: II the tightrope walker: 'He is the scale' [V klee_ps l.540-550]; the stone arch that balances [V klee_ps l.572-584]. Reference: FormFinding_Forge's balance puzzle [V digest]; VFM_09_Legs's tip-or-hold with Geometry2D.convex_hull [V digest]; Gaudi's hanging models [mem].
- Departure: formfinding (spine 8) comes before the rest of forces (spine 7): Klee's balance (II) precedes the gravitational curve (III). Stand the body before you push it: here the engine's gravity does the work; in Part V you write gravity yourself.
- Project step: Make one of your family stand on as few points as it can; predict which member falls.

#### 21. Legs: the passive part drives

- Verb: transform. Spine: forces (7), visit 2 of 5; transformation (2), visit 3 of 3. Halls: VFM_09_Legs (carrier); Trans_Pit (field trip). Tracks: long.
- Status: planned
- CODE new: raycasts, composition. Returns: transforms, basis, physics_bodies, signals, loops, classes, noise.
- BODY: A leg as a chain that follows its foot: each segment looks at the next and keeps its length (the follow half of FABRIK, one loop), so the foot leads and the hip follows. Feet find the ground with raycasts, and four Leg scenes are composed into a creature that walks over your noise terrain from ch12.
- ARGUMENT: axis *segments per leg, same total length*: 1 / 2 / 3 / 6. Predict: 3 and 6 will look most alike on uneven ground: both bend smoothly around a step. 1 cannot bend at all, so its foot hangs above or sinks below the ground. Claim: *How many joints a limb has decides which grounds it can meet: the foot's target drives, and the body follows.*
- DEBT: 'In drag' as a code operation: in ch13 the parent commanded the child; here the passive end drives and the chain follows. Klee's active and passive (and his male and female) are inverted in the scene tree, not in a costume. The ray only sees colliders on its mask: which ground exists for the foot is a layer setting.
- PLACE: Carry the foot: grab one foot target (desktop carry or XR hand) and drag it; the leg follows you, and the creature's body follows the leg.
- Godot: RayCast3D, force_raycast_update(), get_collision_point() · collision layers and masks · a Leg scene instanced four times and composed under one body · look_at() along a chain · planted bug: the ray's target_position left at its local default (0, -1, 0), so on a rotated hip it points sideways and the foot steps into the air.
- Lineage: Processing: none. NoC: ch6 autonomous agents (steering) as a cousin [mem]; The Coding Train's inverse kinematics (follow the target) [mem]. Application: WP4 algorithmic life: a creature assembled from rules. Klee: I.9-12 active and passive, inverted; II the walker [V klee_ps]. Reference: FABRIK (Aristidou and Lasenby, 2011) [mem]; GDQuest's composition over inheritance [V research_engine]; VFM_09_Legs [V digest].
- Departure: A forces hall (spine 7) visited before the rest of forces: stepping and tipping belong with balance, which is Klee's order (II before III). It softens the parent's IK chapter: the follow pass of FABRIK only, no solver.
- Project step: Give one body in your room legs that find the ground, or a part that follows the visitor's hand.

### The gravitational curve (Klee III)

You write gravity yourself: a curve from steps, regions with other laws, a stair that is a function, and a small complete game about staying upright.

#### 22. The bullet: a curve made of steps

- Verb: simulate. Spine: change (6), visit 1 of 2; forces (7), visit 3 of 5. Halls: Change_Intro (carrier); VFM_05_Launch (carrier); VFM_07_Gravity (field trip). Tracks: long.
- Status: planned
- CODE new: integration. Returns: delta, vectors, loops, arrays, meshes, physics_bodies.
- BODY: A launched body moved by your own loop (velocity += gravity * dt; position += velocity * dt), its path kept in an array and drawn as a line (ch6's trace, now written by physics); beside it the same launch as a RigidBody3D.
- ARGUMENT: axis *time step dt, same launch*: 1/10 s / 1/30 s / 1/60 s / 1/240 s. Predict: 1/60 and 1/240 will look most alike: their landing points are a few centimetres apart. 1/10 is visibly a polygon and lands somewhere else. Claim: *A simulated curve is a sequence of steps: below some step size it is the curve, above it the steps are the drawing. The trace's sampling gate (ch6) returns as physics.*
- DEBT: Integration is an approximation that owes energy: explicit Euler makes an orbit leak outward (the VFM_07_Gravity field trip), semi-implicit Euler keeps it nearly closed, and the engine's own integrator hides the same choice behind 'physics ticks per second'.
- PLACE: Stand where you predict it will land and let it hit you (a soft collision); then move to where it lands.
- Godot: _physics_process(delta) against _process · Engine.physics_ticks_per_second · your own integrator beside a RigidBody3D · ImmediateMesh for the path · planted bug: the two update lines swapped (explicit against semi-implicit Euler), so the orbit in the field trip spirals outward.
- Lineage: Processing: none (Nature of Code territory). NoC: ch1-2 velocity, acceleration, forces (the Mover). Application: WP4 chaos, previewed: sensitivity to the step; vectors. Klee: III the bullet and the falling stone [V klee_ps l.214, l.601]. Reference: The Nature of Code ch1-2 [V research_creative]; Change_Intro and VFM_05_Launch halls [V spine.json].
- Departure: change (spine 6) comes after balance: the curve follows balance, as Klee's gravitational curve (III) follows balance (II). It sits below chance and noise (spine 10-11), which were met early and are declared at ch11-12.
- Project step: Launch something in your room with your own integrator; keep the dt you chose and why.

#### 23. Regions with other laws

- Verb: simulate. Spine: forces (7), visit 4 of 5. Halls: Vectors_Act5_ForceAsPlace (carrier); Vectors_Act4a_KineticForces (carrier); VFM_03_Motion (field trip). Tracks: long.
- Status: planned
- CODE new: forces, areas. Returns: physics_bodies, integration, vectors, signals, player.
- BODY: An Area3D that replaces gravity with an @export acceleration for any body inside it, the player included, and restores it on exit; your own drag and wind as functions that return force vectors, summed per step (NoC's apply_force).
- ARGUMENT: axis *the region's gravity (still 0.5 s after six family members are released)*: normal (0, -9.8, 0) / half / zero / reversed. Predict: half and zero will look most alike: after 0.5 s the half-gravity bodies have fallen about 0.6 m and the zero-gravity ones not at all, so both clusters hang near the release height; normal (1.2 m down) and reversed (1.2 m up) are mirror images. Claim: *A law is a property of a place: the same body falls, floats or rises depending on the region it is in.*
- DEBT: Whose physics is 'normal'? The default gravity is Earth's, tuned for a standing body; a region with another law is a room where other bodies are the norm. A field is also control: the Area3D decides what enters it.
- PLACE: Walk into it: the player's own gravity changes at the border; jump in each region.
- Godot: Area3D: gravity_space_override, gravity_direction, gravity · body_entered and body_exited · apply_central_force() · forces summed in _physics_process · planted bug: the Area3D's collision mask does not include the player's layer, so the region works on boxes and not on you.
- Lineage: Processing: none. NoC: ch2 Forces (wind, drag, friction). Application: WP4 non-Euclidean spaces, previewed: a room where 'down' is local. Klee: III regions of different density: the swimmer and the balloon that 'rises from a warm into a' colder layer [V klee_ps l.597-616]. Reference: Vectors_Act5_ForceAsPlace [V digest]; The Nature of Code ch2 [V research_creative].
- Departure: Back to the forces sequence (spine 7) after change (6); its halls on balance and legs were visited early (ch20-21), and chance and noise (spine 10-11) were met early (declared at ch11-12).
- Project step: Give your room one region where the law is yours.

#### 24. The stair climber: a spiral you can walk

- Verb: simulate. Spine: wavefunctions (9), visit 1 of 3. Halls: Wavefunctions_Sky_Stairs (carrier); WaveFunctions_TrigWalkingPath (field trip); WaveFunctions_Unit_Circle (encounter). Tracks: long.
- Status: planned
- CODE new: trig. Returns: surface_tool, collision, loops, player, functions, testing.
- BODY: A spiral stair: tread i placed at (r cos(i a), i rise, r sin(i a)) with a collider per tread, climbed by the walker from ch19; a headless test asserts that the walker reaches the top.
- ARGUMENT: axis *rise per tread*: 0.10 m / 0.18 m / 0.30 m / 0.60 m. Predict: 0.10 and 0.18 will look most alike: both read as a stair. 0.60 reads as a column of blocks, and the walker cannot climb it, because its step limit is lower. Claim: *A stair is a relation between a function and a leg: the same spiral is a path for one body and a wall for another.*
- DEBT: Klee's stair climber assumes legs: every rise excludes a body that does not climb, and the capsule's step height is a hidden standard of who can go up. The collider is a flight of boxes approximating a curve.
- PLACE: Climb it, and look down the well from the top. Then build the ramp version and walk both.
- Godot: sin() and cos() in radians, TAU, deg_to_rad() · a StaticBody3D per tread, or one ConcavePolygonShape3D · CharacterBody3D floor_max_angle and floor snap · ch16's headless test returns as a walk test · the trig one-liners you have called since ch12 (wave_height, catenoid, gap_to_circle, and the base ring in pyramid.gd) opened and rewritten · planted bug: degrees passed to sin() (sin(30) is not one half), so the stair wraps several times around its column.
- Lineage: Processing: Learning Processing ch13 trigonometry [mem]. NoC: ch3 Oscillation: angles and polar coordinates. Application: WP1 sine curves. Klee: III the stair climber, 'of stairs, ascending' [V klee_ps l.611]; the spiral foreshadowed (IV). Reference: Wavefunctions_Sky_Stairs: treads and colliders from a function, tested by walking [V digest]; Aimi Hamraie, Building Access (crip critique of design) [mem].
- Departure: A wavefunctions hall (spine 9) before the rest of the wave sequence: the stair is a function made walkable, and trig belongs where Klee has the stair climber (III), before the pendulum (IV). It sits below chance and noise (spine 10-11), declared at ch11-12.
- Project step: Give your room a way up that a body can take, and write whom it excludes.

#### 25. To stand despite all possibilities to fall: a round

- Verb: simulate. Spine: randomness (10), visit 3 of 5; formfinding (8), visit 3 of 4. Halls: Random_Game (carrier); FormFinding_Forge (field trip); Random_Cubes (field trip). Tracks: long.
- Status: planned
- CODE new: state_machines, ui, timers. Returns: random, seeds, player, signals, physics_bodies, input, save_load, areas, export_build.
- BODY: A small complete game: stones that stand or sink on seeded random waits with a telegraphing ring (Random_Game's body), and the player crossing them. An enum state machine per stone (STANDING, WARNING, SINKING, GONE) and for the round (MENU, PLAYING, FALLEN, WON); a HUD with the time; the best time saved; a supplied sound on each sink (opened at ch27).
- ARGUMENT: axis *warning time before a stone sinks (still 20 s into the same seeded round)*: 0.25 s / 0.5 s / 1.0 s / 2.0 s. Predict: 1.0 and 2.0 will look most alike: most stones are still standing and the gaps are few. At 0.25 s the field is mostly gaps, because stones sink before any player can react. Claim: *Fairness is a number in a state machine: the warning time decides who can cross, not the chance itself.*
- DEBT: Chance returns as fate: the seed is the same for everyone, the reaction time is not. A state machine is a list of allowed states, and what it cannot name it cannot do (c8's 'the enum as allowed identities').
- PLACE: Play it in the headset: the stones are the ground you stand on; fall, and the round restarts.
- Godot: enum and match · a Timer node and its timeout signal · Control nodes, Label and a CanvasLayer HUD; a world-space Label3D for VR · the best time saved with ch17's save_load · the round exported as a build · planted bug: the state changes but the stone's timer is not stopped, so a GONE stone sinks again and the round is lost twice.
- Lineage: Processing: Handbook 'Synthesis 2' [V via c4]. NoC: the midterm project (ITP). Application: WP1 randomness returns as a game. Klee: Introduction and III: 'TO STAND DESPITE ALL POSSIBILITIES TO FALL!' [V klee_ps l.226]. Reference: Random_Game's enum state machine of stones [V digest]; FormFinding_Forge [V digest]; The Nature of Code's midterm [V research_creative]; Anna Anthropy, Rise of the Videogame Zinesters (share early) [mem].
- Departure: A declared return to randomness (spine 10) as the long track's midterm: the chance met at ch11 now drives a whole round, and the small-game kit (player, input, camera, ui, save, build) comes together.
- Project step: MIDTERM: a round in your room that a classmate can lose, exported and played, with its warning time argued.

### Kinetic and chromatic energy (Klee IV; Albers)

Motions that return: pendulum, circle, spiral, sound, the arrow and the field of arrows; then colour as a system and the shader. Each makes something invisible visible, and each picture hides a choice.

#### 26. Pendulum, circle, spiral: time laid into space

- Verb: transform. Spine: wavefunctions (9), visit 2 of 3; fractals (14), visit 1 of 2. Halls: WaveFunctions_Pendulum (carrier); WaveFunctions_Unit_Circle (carrier); Fractal_GoldenSpiral (field trip); Vectors_Act4b_Oscillation (field trip). Tracks: long.
- Status: planned
- CODE new: queues, multimesh. Returns: trig, delta, arrays, integration, loops.
- BODY: A pendulum sampled in _physics_process into a bounded queue and laid out in space as one MultiMesh of marks, so the swing's time becomes a sculpture; then the same runner at (cos t, sin t), a circle; then the radius changes each turn, a spiral starting at 0.5 m.
- ARGUMENT: axis *radius change per turn (still at the tenth turn)*: -0.2 m / -0.05 m / 0 / +0.05 m / +0.2 m. Predict: -0.2 and -0.05 will look most alike: both have died into the centre by the tenth turn (-0.2 after two and a half turns, -0.05 exactly at the tenth). 0 is the only closed form; the growing ones differ only in how wide they open. Claim: *The sign of one number decides whether the form lives or dies: Klee's lengthening radius makes a 'vibrant spiral', the shortening one 'dies suddenly in the static center'.*
- DEBT: A MultiMesh draws thousands of marks in one call and pays in flexibility: every mark shares one mesh and one material. The queue forgets: the sculpture is only the last N samples. And a pendulum that returns forever is an idealisation (the damping you left out).
- PLACE: Walk through the swing's sculpture; stand inside the dying spiral's centre.
- Godot: a bounded queue: push_back(), pop_front(), a maximum length · MultiMeshInstance3D: instance_count, set_instance_transform() · a fixed-step accumulator in _physics_process · planted bug: instance_count set after the transforms (setting it clears them), so the sculpture is empty.
- Lineage: Processing: Handbook 'Math 3' sin and cos [mem]. NoC: ch3 Oscillation: the pendulum, polar coordinates. Application: WP1 sine curves and resonance; Fibonacci (the golden spiral field trip). Klee: IV the top and the pendulum open Part IV; the circle from the pendulum, 'vibrant spiral' and 'dies suddenly in the static center' [V klee_ps l.656-685]. Reference: Form+Code 'Transform: Slit-Scan' [V c3]; WaveFunctions_Pendulum's time-to-space recorder [V digest]; Marey's chronophotography [mem].
- Departure: wavefunctions (spine 9) resumes after the midterm. Fractal_GoldenSpiral (fractals, spine 14) is visited early as a field trip: Klee derives the spiral from the pendulum, and the golden section returns with recursion (ch32).
- Project step: Lay one motion of your room into space as a sculpture a visitor can walk through.

#### 27. Sound: the swing heard

- Verb: visualize. Spine: wavefunctions (9), visit 3 of 3; array_tutorial (3), visit 3 of 3. Halls: WaveFunctions_Effect_Sound (carrier); WaveFunctions_AirMusic (carrier); WaveFunctions_Synthesis_Lab (field trip); Tutorial_Disco (field trip). Tracks: long.
- Status: planned
- CODE new: audio. Returns: trig, loops, packed_arrays, areas, multimesh, timers.
- BODY: Two tones rendered sample by sample into an AudioStreamWAV (a PackedByteArray), played from an AudioStreamPlayer3D inside an Area3D you walk into; the same two sines drawn as a Lissajous figure in a MultiMesh, so the chord is also a body.
- ARGUMENT: axis *frequency ratio of the two tones*: 1:1 / 2:1 / 3:2 / 45:32. Predict: 2:1 and 3:2 will look most alike: both close into small knots of a few lobes. 45:32 (the tritone) closes only after 32 turns of the slower tone, so in the still it fills its square. Claim: *Consonance has a shape: simple ratios close into small figures, and the tritone fills the square before it closes.*
- DEBT: Sampling again: 44 100 numbers a second stand in for a wave, and anything above half that rate folds back as another tone (aliasing). The octave and the fifth are one tuning tradition's consonances, not nature's.
- PLACE: Walk into the chord: stand in each Area3D and hear it; stand where two overlap.
- Godot: AudioStreamWAV: data, mix_rate, 16-bit format · PackedByteArray.encode_s16() · AudioStreamPlayer3D and attenuation · AudioStreamGenerator as the live alternative (Wavefunctions_Bernini) · planted bug: samples written as floats between -1 and 1 into the 16-bit buffer without scaling to 32767: silence.
- Lineage: Processing: Processing's Sound library [mem]. NoC: ch3 Oscillation: amplitude and period. Application: WP1 sound experiments, sine curves and resonance frequencies; WP2 Fourier transforms (the synthesis lab's additive tones). Klee: IV 'Motion and counter-motion of the pendulum' [V klee_ps l.665]. Reference: WaveFunctions_Effect_Sound's per-sample AudioStreamWAV [V digest]; John Cage (WaveFunctions_John_Cage hall) [V spine.json]; Winnie Soon's Vocable Code [V research_ccs]; Lissajous figures [mem].
- Departure: Tutorial_Disco (array_tutorial, spine 3) is revisited for its step sequencer, the spine's earliest generated tone. Sound, a WP1 Basic Element with no early spine place, gets its home here with the swing it hears.
- Project step: Give your room a sound that is computed, not recorded.

#### 28. The arrow and the field of arrows

- Verb: visualize. Spine: change (6), visit 2 of 2; forces (7), visit 5 of 5; noise (11), visit 2 of 4. Halls: Flow_Field (carrier); Vectors_Act3_FieldsAndMotion (carrier); Noise_Inside_Noise (field trip). Tracks: long.
- Status: planned
- CODE new: particles, lifetime. Returns: noise, vectors, forces, raycasts, multimesh, random.
- BODY: A field of arrows sampled from noise over the room (an arrow per cell, one MultiMesh) and particles released into it that live a few seconds and follow it. Your hand's ray (ch21) is Klee's arrow: where it points, the field bends toward you (Code as Creative Medium's Personal Prosthetic).
- ARGUMENT: axis *the field's noise frequency*: 0.02 / 0.05 / 0.2 / 1.0. Predict: 0.02 and 0.05 will look most alike: broad currents, a few long streams. At 1.0 every arrow disagrees with its neighbour, the field is fur, and the particles go nowhere. Claim: *A field is invisible until bodies move through it: the frequency decides whether it is weather or static.*
- DEBT: The blob aesthetic returns as flow: smooth noise makes 'natural' currents because it was built to. GPU particles are a black box you configure rather than write, and their lifetime is a budget, not a life. Reach is power: which bodies the arrow can touch is a collision mask.
- PLACE: Become the arrow: point your hand and the field bends; walk through the stream and the particles part around your collider.
- Godot: GPUParticles3D and ParticleProcessMaterial: lifetime, amount · CPUParticles3D where you need to read positions · sampling the field per particle · queue_free() and lifetimes for spawned bodies · planted bug: local_coords left on for a moving emitter, so the stream travels with your hand instead of staying in the field.
- Lineage: Processing: none directly. NoC: ch4 Particle Systems; ch6 flow field following. Application: WP2 flow fields; WP1 particle systems. Klee: IV the arrow: 'The father of the arrow is the thought: how do I expand my reach?' [V klee_ps l.699]. Reference: Code as Creative Medium 'Personal Prosthetic' [V ToC via c7]; Flow_Field [V spine.json]; Tyler Hobbs on flow fields [mem].
- Departure: Flow_Field (change, spine 6) comes after the wave sequence and after noise (met at ch12): The Nature of Code puts flow fields after noise, and Klee's arrow closes his kinetic part.
- Project step: Give the visitor an arrow: a way to reach into your room from a distance and change it.

#### 29. A colour has many faces

- Verb: visualize. Spine: color (4), visit 3 of 3. Halls: Color_Walls (carrier); Color_Flashlight (carrier); Color_Paint (field trip); Color_Pillar (field trip); Color_Nails (encounter). Tracks: long.
- Status: planned
- CODE new: interpolation. Returns: materials, classes, export, resources, raycasts, loops.
- BODY: A wall of steps between two complementary colours, lerped in RGB and in HSV side by side; a flashlight whose light colour you carry changes what the wall's colours look like (Albers: one colour made to look like two).
- ARGUMENT: axis *the space the same two complementaries are mixed in*: RGB / HSV / linear-light RGB / a supplied perceptual space (OKLab). Predict: RGB and linear-light RGB will look most alike: both pass through a grey middle, Klee's central grey, and differ only in where the grey falls. HSV swings round through the hues in between and never reaches grey. Claim: *The middle between two colours is not in the colours but in the space you mix them in: RGB finds Klee's central grey, HSV walks around it.*
- DEBT: Colour spaces are standards built for a measured 'average' eye and calibrated on particular skins (the Shirley card); sRGB against linear is the engine's hidden correction. Albers: colour deceives continually.
- PLACE: Carry the flashlight along the wall: the same painted step changes colour under your light; then paint the wall with your ray (Color_Paint).
- Godot: Color.lerp(), Color.from_hsv(), h, s and v · lerp() on floats · SpotLight3D light_color · Color.srgb_to_linear() · a palette Resource shared by the room · planted bug: hue lerped from 0.9 to 0.1 goes the long way round, through green, instead of across red: wrap the difference.
- Lineage: Processing: Learning Processing ch1 colour [mem]. NoC: none. Application: WP3 shading algorithms: colour as the first shading. Klee: IV coloured arrows, 'the central grey (Fig. 83)', and the colour circle where the 'arrows are superfluous' [V klee_ps l.816-827]. Reference: Josef Albers, Interaction of Color (1963) [V research_bauhaus]; Color_Walls' lerp_rgb against lerp_hsv and Color_Flashlight [V digest]; Lorna Roth on the Shirley card [mem].
- Departure: color (spine 4) returns here as a system, where Klee's book ends in colour and Albers puts theory after experience; colour as a value was met at ch9, and chance and noise (spine 10-11) were met early (declared at ch11-12).
- Project step: Choose your room's palette by argument: one pair of colours, one mixing space, one sentence.

#### 30. The pixel's colour circle: shaders

- Verb: visualize. Spine: shaders (12), visit 1 of 1; noise (11), visit 3 of 4. Halls: Shader_01_Shaping (carrier); Shader_11_QueerRubber (carrier); Shader_09_FBM (field trip); Shader_05_Patterns (field trip); Shader_10_ReactionDiffusion (encounter); Shader_12_PinkExtravaganza (encounter). Tracks: long.
- Status: planned
- CODE new: shaders, uniforms. Returns: uv, interpolation, materials, trig, normals, noise, tool_scripts.
- BODY: A spatial shader on one of your family members: a shaping function over UV (step, smoothstep, sin) in fragment(), a fresnel rim from dot(NORMAL, VIEW), and fBm noise computed per pixel; uniforms set from GDScript.
- ARGUMENT: axis *the rim exponent p in pow(1.0 - dot(NORMAL, VIEW), p)*: 0.5 / 1 / 3 / 8. Predict: 3 and 8 will look most alike from 2 m: both give a thin bright edge on a dark body. 0.5 floods the whole body with the rim colour, so it reads as unlit. Claim: *A skin can be computed from the angle between the body and your eye: the same body is rubber or glass depending on one exponent (Shader_11_QueerRubber).*
- DEBT: The GPU computes every pixel at once and remembers nothing between them (Gaboury on the GPU). The shader's noise is not the CPU's: compare Shader_09_FBM with ch12's terrain, the look is shared and the body is not, and you cannot stand on a shader. A skin computed from the viewer changes with who looks.
- PLACE: Walk around it: the rim follows your eye, so each visitor sees a different skin.
- Godot: ShaderMaterial and shader_type spatial · fragment(): ALBEDO, EMISSION, NORMAL, VIEW, UV, TIME · uniform with hint_range · set_shader_parameter() · planted bug: a sampler2D uniform left unbound reads as white, so EMISSION from it makes the whole body glow.
- Lineage: Processing: Processing PShader [mem]. NoC: none. Application: WP3 shading algorithms; WP2 queer textures; WP3 reaction-diffusion, Turing's 1952 pattern, met as an encounter in Shader_10_ReactionDiffusion. Klee: IV the colour circle as the synthesis [V c4]. Reference: The Book of Shaders: shaping functions, patterns, fBm [V research_engine]; Gaboury, Image Objects, the GPU [V research_ccs]; Shader_11_QueerRubber's fresnel rim [V digest].
- Project step: SYNTHESIS IV: give your family a computed skin; your room's colour and skin now argue together.

### Out of the sketchbook: bodies in drag (spine 13-25)

Where Klee has no page: rules in time, recursion that must be stopped, grammars, generated worlds, soft, implicit and collective bodies, bodies that learn, the crisis of foundations, entropy measured on your own predictions, and your hall in the collective museum.

#### 31. Rules in time: cellular automata

- Verb: simulate. Spine: cellularautomata (13), visit 1 of 1; softbodies (17), visit 2 of 3. Halls: CA_Introduction (carrier); CA_GameOfLife (carrier); CA_EdgeOfChaos (field trip); ProceduralGeneration_Reaction_Diffusion_Systems (field trip). Tracks: long.
- Status: planned
- CODE new: buffers. Returns: arrays, packed_arrays, loops, conditions, collision, multimesh.
- BODY: An elementary automaton whose rows stack upward as walkable floor (CA_GameOfLife's history turned into collidable cells), read from one buffer and written to another; the same double-buffer step then drives Turing's reaction-diffusion on a floor you stand on.
- ARGUMENT: axis *the rule number, from one live cell*: 30 / 90 / 110 / 250. Predict: 90 and 250 will look most alike: both grow a symmetric triangle at the same speed, 90 as Sierpinski's nested holes and 250 as a regular checker. 30 and 110 are both lopsided: 30 is disorderly on one side, 110 grows toward one side only. Claim: *A rule of eight bits decides between order, fractal and chaos, and you cannot read which from the rule, only from running it.*
- DEBT: A CA is a grid that must end: the edges wrap or die, and the choice shows at the floor's border. Rule 30's 'randomness' is fully determined (it has been used as a random generator): pseudo-randomness returns. Reaction-diffusion is Turing's 1952 morphogenesis, the application's embodied throughline: 'can twisted rooms transcend power?' (Queer 3D).
- PLACE: Stand on the history: the rows are floor and the rule's gaps are holes you fall through; walk up Sierpinski's rows.
- Godot: two PackedByteArray buffers swapped each step · (rule >> index) & 1 · wrapping with (i + n) % n · a merged collider per row · planted bug: reading and writing the same buffer, so the rule sees its own new values and the pattern leans to one side.
- Lineage: Processing: Handbook 'Simulate' (Life) [mem]. NoC: ch7 Cellular Automata. Application: WP2 cellular automata; WP3 reaction-diffusion (Turing's morphogenesis, 1952). Klee: none. Reference: Wolfram, A New Kind of Science (rule classes) [mem]; Turing, 'The Chemical Basis of Morphogenesis' (1952) [mem]; CA_GameOfLife's history as floor and the Gray-Scott port in ProceduralGeneration_Reaction_Diffusion_Systems [V digest].
- Departure: ProceduralGeneration_Reaction_Diffusion_Systems (softbodies, spine 17) is visited early as a field trip: reaction-diffusion is a double-buffer rule like the automaton; the soft-body sequence it belongs to is taught at ch35.
- Project step: Let a rule grow one part of your room over time; keep the rule number.

#### 32. The tree and its mad branch: recursion

- Verb: repeat. Spine: fractals (14), visit 2 of 2. Halls: Fractal_RecursiveTrees (carrier); Fractal_Recursion (carrier); Fractal_KochSierpinski (field trip); Fractal_MengerSponge (field trip). Tracks: long.
- Status: planned
- CODE new: recursion. Returns: functions, parameters, transforms, random, seeds, multimesh, debugging, errors.
- BODY: A tree that calls itself: branch(depth, length, frame) draws one segment and calls branch twice with a shorter length and a turned frame, until a depth limit stops it; one seeded 'mad branch' breaks the symmetry.
- ARGUMENT: axis *depth limit*: 3 / 6 / 9 / 12. Predict: 9 and 12 will look most alike at 3 m: with a 1 m trunk and a length ratio of 0.67, the twigs added past depth 9 are under 2 cm and merge into the crown, while 12 costs eight times the segments (2^12 against 2^9). Claim: *Recursion must be stopped, and past some depth it only costs: the stop is a design decision the tree cannot make for itself.*
- DEBT: 'Recursion must always be controlled' (Queer 3D): an unstopped recursion is a stack overflow, the engine's refusal. The fractal is an idealisation: real trees stop for reasons (light, weight, damage), and the depth limit is where the model's honesty lives.
- PLACE: Walk under the crown; climb the first branches (colliders on the thick segments only, which is another budget).
- Godot: a function that calls itself · the Debugger's Stack Frames while stepping into it · Transform3D composition: basis rotated, origin moved · MultiMesh for the segments · planted bug: branch(depth, ...) instead of branch(depth - 1, ...) gives 'Stack overflow', and the Stack Frames panel shows the same function hundreds of times.
- Lineage: Processing: Handbook 'Shape 3: Recursion' [V LEARN]. NoC: ch8 Fractals. Application: WP2 fractal subdivision; Fibonacci returns with the golden spiral. Klee: none: Klee's tree metaphor is in On Modern Art, not in the Sketchbook [mem]. Reference: Form+Code 'Repeat: Recursive Tree' [V c3]; Yoichiro Kawaguchi's growth bodies (Queer 3D 2024) [V QUEER3D.md]; Fractal_RecursiveTrees [V spine.json].
- Project step: Grow one body in your room by recursion, and say in a comment where and why it stops.

#### 33. The point walks again: grammars and the turtle

- Verb: repeat. Spine: lsystems (15), visit 1 of 1. Halls: LSystems_Grammar_Lab (carrier); LSystems_Growth (carrier); LSystems_Architecture (field trip); LSystems_Shape_Grammars (field trip); Assemblage_Same_Desire (encounter). Tracks: long.
- Status: planned
- CODE new: strings, stacks. Returns: dictionaries, loops, recursion, meshes, transforms, player.
- BODY: An L-system: an axiom string rewritten by a Dictionary of rules n times, then read by a 3D turtle that draws on F, turns on + and -, and pushes and pops its frame on [ and ]. Klee's walking point from ch6, now walking a grammar.
- ARGUMENT: axis *branching angle, same rules and generations*: 15 degrees / 22.5 degrees / 25.7 degrees / 45 degrees. Predict: 22.5 and 25.7 will look most alike: both read as plants (the textbook angles of one family). 45 turns the plant into a lattice. Claim: *A grammar is a family whose one angle decides whether it grows as a plant or as architecture.*
- DEBT: Performativity (Butler, as c2 reads it): the body is its repeated rewriting, and the grammar's alphabet decides what can be said. String growth is exponential, so the rewriting must also be stopped. Lindenmayer modelled algae; the 'plant' look is an aesthetic, not biology.
- PLACE: Walk the grown structure as architecture (LSystems_Architecture): the turtle's path becomes corridors.
- Godot: String and concatenation; a loop over characters · a Dictionary of rules · an Array as a stack of Transform3D: push_back(), pop_back() · planted bug: rules applied in place to the string being read, so newly written symbols are rewritten again in the same generation.
- Lineage: Processing: none directly [mem]. NoC: ch8 L-systems. Application: WP2 L-systems. Klee: I.1 the active line on a walk, now following a grammar [V klee_ps l.279]. Reference: Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants (1990) [mem]; Judith Butler, Gender Trouble (performativity) [mem]; LSystems_Grammar_Lab [V spine.json].
- Project step: Write a grammar for a body of your family and let the turtle build it.

#### 34. How do we navigate an auto-generated world?

- Verb: simulate. Spine: proceduralgeneration (16), visit 2 of 2; graphtheory (22), visit 1 of 1. Halls: PG_Caves_Mazes (carrier); GT_Pathfinding (carrier); GT_Spanning_Trees (field trip); Randomness_10_PRINT_Algorithm (field trip). Tracks: long.
- Status: planned
- CODE new: graphs, search, navigation. Returns: arrays, dictionaries, stacks, queues, random, seeds, player, collision.
- BODY: A maze carved by a randomised search over a grid graph (a spanning tree), then walked: breadth-first search for the path, AStar3D, and a NavigationRegion3D baked for a companion that follows you.
- ARGUMENT: axis *carving algorithm, same grid and seed*: randomised depth-first search / Prim's / Kruskal's / 10 PRINT (no guarantee). Predict: Prim's and Kruskal's will look most alike from above: many short dead ends, a bushy texture. Depth-first search makes long winding corridors, and 10 PRINT alone may not connect at all. Claim: *A maze's character is the search that carved it: the same grid gives corridors or thickets depending on whether a stack or a queue decides.*
- DEBT: 'How do we navigate an auto-generated world?' (the application's WP3 question). The shortest path is one value among others (the desire line, Ahmed's queer phenomenology); a navigation mesh decides where a body may walk, and the agent's radius is a body norm.
- PLACE: Get lost in it, then follow the companion; walk a desire line through a wall you broke.
- Godot: a graph as a Dictionary of neighbour arrays · a queue (breadth-first) against a stack (depth-first) · AStar3D: add_point(), connect_points(), get_point_path() · NavigationRegion3D and NavigationAgent3D · planted bug: the visited set is never updated, so the search queues the same cells forever and the frame freezes (the 16-second rule).
- Lineage: Processing: none. NoC: none: graphs are outside The Nature of Code. Application: WP3 graph theory; WP3 procedural generation; 'How do we navigate an auto-generated world?'. Klee: none. Reference: 10 PRINT's Maze Walker [V research_ccs]; Sara Ahmed, Queer Phenomenology (desire lines) [mem]; GT_Pathfinding's AStar3D [V digest].
- Departure: graphtheory (spine 22) is pulled forward into procedural generation (spine 16): the application's WP3 puts graph theory with world building, and a maze needs a graph. The rest of graph theory stays an encounter.
- Project step: Generate one part of your room and prove that a visitor can reach every place in it.

#### 35. Soft bodies: the organism returns

- Verb: simulate. Spine: softbodies (17), visit 3 of 3; formfinding (8), visit 4 of 4. Halls: SoftBodies_Soft_Body_Deformation (carrier); FormFinding_Relaxation (carrier); Topology_Entropy_Morphogenesis (carrier); SoftBodies_Playground_of_Joy (encounter). Tracks: long.
- Status: planned
- CODE new: inheritance. Returns: integration, physics_bodies, classes, export, packed_arrays, profiling, setters, xr.
- BODY: A Verlet cloth written as your own classes: Particle, and PinnedParticle extends Particle and overrides step() to stay put; distance constraints relaxed n times per step. Beside it Godot's SoftBody3D with pinned points and exported stiffness.
- ARGUMENT: axis *constraint iterations per step*: 1 / 4 / 16 / 64. Predict: 16 and 64 will look most alike: the cloth hangs taut, and the extra passes remove less than a centimetre of stretch. 1 sags like rubber. Claim: *Stiffness is not a material but a budget: the same net is rubber or chain depending on how many times you ask it to keep its lengths.*
- DEBT: Polycount against smooth deformation (application l.89): a soft body needs vertices to bend, and every vertex costs per frame and per eye. Inheritance is a taxonomy: making 'pinned' a subclass decides that being held is a kind of particle, not a relation.
- PLACE: Carry it: grab a corner of the cloth (XR hand or desktop carry) and drag it through the room; let it drape over your family.
- Godot: class Particle extends RefCounted; class PinnedParticle extends Particle · overriding a method; super() · SoftBody3D: set_point_pinned(), simulation_precision · profiling the cloth's step · planted bug: the subclass's _init forgets super(), so pinned particles have no position and the cloth hangs from the origin.
- Lineage: Processing: Handbook 'Simulate' [mem]. NoC: ch5 physics libraries (springs). Application: WP2 soft body simulation (cloth, liquids, rubber); polycount (l.89). Klee: I.9-12 the organism: tendon and muscle as constraints [V klee_ps l.359-386]. Reference: Jakobsen, 'Advanced Character Physics' (Verlet, 2001) [mem]; FormFinding_Relaxation's 40-line Verlet cloth [V digest]; c6's 'the same net is rubber or chain' [V c6 notes].
- Departure: formfinding (spine 8) returns by name: FormFinding_Relaxation's cloth belongs with the soft bodies, where relaxation becomes flesh.
- Project step: Give one body in your room a soft part that a visitor can deform.

#### 36. Stone upon stone, chip from chip: implicit and boolean bodies

- Verb: visualize. Spine: isosurfaces (18), visit 1 of 1; boolean_surfaces (19), visit 1 of 1; noise (11), visit 4 of 4. Halls: ISO_Introduction (carrier); ISO_Metaballs (carrier); Boolean_Verbs (carrier); ISO_LookupTable (field trip); Noise_Voxel (field trip). Tracks: long.
- Status: planned
- CODE new: threads. Returns: noise, nested_loops, surface_tool, normals, arrays, tool_scripts, profiling, packed_arrays.
- BODY: A body with no vertices until you ask: a scalar field (metaballs plus noise) sampled on a 3D grid and polygonised by marching cubes with the supplied lookup table, built on a worker thread; beside it a CSG body carved by union, subtraction and intersection.
- ARGUMENT: axis *threshold (iso level) of the same field*: 0.2 / 0.4 / 0.6 / 0.8. Predict: 0.4 and 0.6 will look most alike: both show separate blobs, one set fatter. At 0.2 the blobs fuse into one body; at 0.8 they shrink into beads. Claim: *An implicit body's identity is a threshold: one number decides whether there are three bodies or one.*
- DEBT: The blob aesthetic in its purest form (Queer 3D): metaballs fuse because the field sums them. The lookup table is inherited code nobody in the class wrote, so this chapter holds a code-critique station on Ada's own marching-cubes table (read its comments, find its assumptions). The grid's resolution decides what can be thin.
- PLACE: Stand inside it: sculpt the field with your hand (ISO_Sculpting's gesture) and walk through the tunnels your subtraction made.
- Godot: WorkerThreadPool.add_task() and wait_for_task_completion() · building an ArrayMesh off the main thread and adding it with call_deferred() · CSGCombiner3D: operation, use_collision · planted bug: add_child() called from the worker thread errors or crashes until the node is handed back with call_deferred().
- Lineage: Processing: none. NoC: none. Application: WP2 queer meshes (fusion and topology); Voronoi and Perlin noise return as volume. Klee: I.12 'stone upon stone' (additive) against 'chip from chip' (subtractive) [V klee_ps l.420-428]. Reference: Lorensen and Cline, marching cubes (1987) [mem]; Blinn's blobby objects (1982) [mem]; Sebastian Lague's marching-cubes Coding Adventure [mem]; Marino, Critical Code Studies (code read as text) [V research_ccs].
- Departure: Noise_Voxel (noise, spine 11) returns as a field trip: ch12's terrain becomes a volume.
- Project step: Carve or fuse one body in your room from a field or with boolean verbs.

#### 37. Many bodies with rules: swarms

- Verb: simulate. Spine: swarmintelligence (20), visit 1 of 1; randomness (10), visit 4 of 5. Halls: SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_PhysarumColony (carrier); SwarmIntelligence_Swarm_Intelligence_Algorithms (field trip); Random_Pheromone (field trip). Tracks: long.
- Status: planned
- CODE new: groups. Returns: classes, inheritance, vectors, forces, multimesh, profiling, random.
- BODY: A flock of your family members as boids: separation, alignment and cohesion as three forces summed per body; each boid joins a group so the others can find it; moved from one node per boid to one MultiMesh when the frame time says so.
- ARGUMENT: axis *cohesion weight (separation and alignment fixed)*: 0 / 0.5 / 1 / 4. Predict: 0 and 0.5 will look most alike: a loose scatter moving roughly one way. At 4 the flock collapses into a ball. Claim: *A collective body is a ratio of rules: one weight decides whether many bodies are a crowd, a flock or a clump.*
- DEBT: The all-pairs neighbour search costs n squared: a swarm is limited by its budget before it is limited by its rules. Who counts as a neighbour is a radius, a politics of proximity. 'Emergence' is also a way of saying that nobody decided.
- PLACE: Walk into the flock: your body is an obstacle in its rules; stand still and be surrounded.
- Godot: add_to_group() and get_tree().get_nodes_in_group() · a Boid class that extends a shared Agent class · MultiMeshInstance3D for many · the Profiler at n = 50, 200, 800 · planted bug: each boid reads neighbours already moved this frame (update in place), so the flock drifts in the order of the group.
- Lineage: Processing: Shiffman's Flocking example [mem]. NoC: ch6 Autonomous Agents (flocking). Application: WP4 swarm intelligence; WP4 algorithmic life. Klee: none. Reference: Craig Reynolds, Boids (1987) [mem]; Physarum models (Jeff Jones, 2010) [mem]; SwarmIntelligence_Boids_Algorithm's MultiMesh and spatial hash [V digest].
- Departure: Random_Pheromone (randomness, spine 10) is a field trip: the pheromone walk is chance with a memory left in the ground, a return of ch11-12.
- Project step: Let a crowd of your family move through your room by rules.

#### 38. Bodies that learn: whose data trains the body

- Verb: visualize. Spine: machinelearning (21), visit 1 of 1; postfoundationscrisis (25), visit 2 of 3. Halls: ML_Classification (carrier); ML_Neural_Networks (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (carrier); ML_Gradient_Landscape (field trip); ML_Evolution (field trip). Tracks: long.
- Status: planned
- CODE new: json. Returns: arrays, dictionaries, loops, uv, materials, save_load, testing, ai_assist.
- BODY: A classifier painted on the floor: labelled points (your ch6 walk traces and classmates', with consent, loaded from a JSON file that records who labelled each one) and a k-nearest-neighbour rule that colours every floor cell by its nearest labels; then a perceptron's line on the same data, and a gradient landscape you walk down.
- ARGUMENT: axis *who labelled the training points*: you / the class (with consent) / a default dataset / random labels. Predict: The class and the default dataset will look most alike: smooth, confident regions. Random labels give a speckled field, and your own labels draw the most particular map. Claim: *The decision field is a map of who labelled the data: the machine's confidence is borrowed from its labellers.*
- DEBT: Models are always biased (Queer 3D 2024), and raising k erases the lone sample's region (k as a politics of neighbourhood). The course's own AI assistant (ch8) was trained on labels nobody in the room chose: ask it for 'a human body' and study what it returns. A test proves only what you thought to ask: the perceptron fails XOR.
- PLACE: Stand on your own portrait: the field under your feet says which class your position belongs to; walk across the boundary the data drew.
- Godot: JSON.stringify() and JSON.parse_string() · a Dictionary per sample {x, z, label, labelled_by} · an Image written per cell as the floor texture · a headless assert that the perceptron fails XOR · planted bug: the Image is rewritten but the ImageTexture is not updated, so the floor never changes (texture.update(image) is the repair).
- Lineage: Processing: none. NoC: ch10 Neural Networks (the perceptron). Application: WP3 neural networks; WP3 evolutionary algorithms (ML_Evolution field trip); WP4 algorithmic life and AI; Turing's B-type unorganised machines. Klee: none. Reference: Code as Creative Medium 'Data Self-Portrait' [V ToC via c7]; Aesthetic Programming ch10 'Machine Unlearning' [V research_ccs]; Feminist Data Set [V research_queer via c7]; c3's k as a politics of neighbourhood [V c3].
- Departure: CriticalAlgorithms_Algorithmic_Bias_Visualization (postfoundationscrisis, spine 25) is a carrier here, ahead of its sequence: bias belongs beside the learner that has it. It was walked as an encounter at ch8.
- Project step: Train something on data about your visitors or yourself, with consent, and write the test that would catch it lying.

#### 39. The crisis of foundations: impossible possible space

- Verb: simulate. Spine: foundationscrisis (23), visit 2 of 2. Halls: NonEuclidean_Spaces (carrier); Escher_Impossible (carrier); Godel_Incompleteness (field trip); Brouwer_Intuitionism (field trip); Euclid_Parallel (encounter); Russell_Paradox (encounter). Tracks: long.
- Status: planned
- CODE new: await. Returns: shaders, uniforms, camera, signals, state_machines, raycasts.
- BODY: An impossible figure that exists from one standpoint only: a Penrose triangle of three straight beams that closes when your camera reaches the one point (the figure emits viewpoint_locked and the room awaits it); and a corridor whose curvature is a shader uniform, so parallel lines meet.
- ARGUMENT: axis *the viewer's distance from the locked standpoint*: 0 m / 0.1 m / 0.5 m / 2 m. Predict: 0.5 and 2 m will look most alike: both plainly show three separate beams. 0 is the only closed triangle; 0.1 already shows a hairline gap. Claim: *An impossible body is a possible body seen from one place: the impossibility is in the standpoint, not in the geometry.*
- DEBT: Mathematics has 'limits and areas of unpredictability and undecidability' (Queer 3D: Godel, the halting problem): no test suite can prove a program halts. Brouwer's third value as enum Truth {TRUE, FALSE, NOT_YET} (c1): allowing 'not yet' is a political choice. Failure before futures: the course names what its models cannot hold before it builds its own hall.
- PLACE: Find the standpoint: walk until the figure closes, take one step and watch it break; walk the curved corridor until you come back to where you began.
- Godot: await on a signal (await viewpoint_locked) · get_viewport().get_camera_3d() read each frame · a vertex shader driven by a curvature uniform · an enum with a third value · planted bug: await on a signal that already fired before the await line, so the room waits forever (check the state first, or connect earlier).
- Lineage: Processing: none. NoC: none. Application: WP4 non-Euclidean spaces; WP4 chaos; the 2022 prototype's paradoxes of infinity and entropy. Klee: II 'It isn't wrong logically', but psychologically [V klee_ps l.521-530]. Reference: Escher, Reutersvard and Penrose in Queer 3D 2024's lineage [V QUEER3D.md]; Godel (1931) and Turing's halting problem (1936) [mem]; Queer Game Studies, failure before futures [V research_queer]; Escher_Impossible's viewpoint_locked [V digest].
- Project step: Put one impossibility in your room, and say from where it is possible.

#### 40. Order toward entropy: the QFEP laboratory

- Verb: visualize. Spine: qfeplaboratory (24), visit 1 of 1; randomness (10), visit 5 of 5. Halls: QFEP_F_Term (carrier); QFEP_Lambda_Spectrum (carrier); QFEP_Edge_Of_Chaos (field trip); Random_Entropy (field trip). Tracks: long.
- Status: planned
- CODE new: sorting. Returns: random, seeds, arrays, packed_arrays, multimesh, json, dictionaries.
- BODY: Your own prediction log becomes a body: every prediction and observation you wrote since ch2, loaded from your sketchbook, with F = |prediction - observation| per chapter drawn as a line you walk along (QFEP's F term). Beside it, 200 seeded symbols sorted by a tween while their Shannon entropy is counted (Random_Entropy).
- ARGUMENT: axis *how the same 200 symbols are arranged*: seeded random / sorted by value / sorted by colour / sorted by value, reversed. Predict: 'sorted by value' and 'reversed' will look most alike: they are mirror images. All four carry exactly the same counted entropy: the picture changes and the number does not. Claim: *Entropy counts what there is, not how it is arranged: order is a picture, not a quantity.*
- DEBT: Shannon entropy measures a distribution and is blind to arrangement: the metric hides exactly what a visual argument shows. QFEP is the project's own framework, and the F term measured on the course's learners must not become a score (c2's warning): the log is for the student, not for the grade.
- PLACE: Walk your own F curve: the chapters where your prediction was most wrong are the highest points; stand on them.
- Godot: Array.sort() and sort_custom() · a Tween over per-instance transforms · counting frequencies in a Dictionary; log() for entropy · reading your sketchbook's predictions from a JSON file · planted bug: log() of a zero count is -inf and the entropy reads nan: skip the symbols that never occur.
- Lineage: Processing: none. NoC: none. Application: the application's arc: 'As we step towards more entropy, noise - information, difference, and diversity increase'; WP4 chaos; QFEP's F -> E direction. Klee: none. Reference: Claude Shannon (1948) [mem]; Ada's QFEP framework (doc/ENTRY.md) [V repo CLAUDE.md]; c1's prediction log as the F term [V c1 notes]; Random_Entropy's sort-and-count and QFEP_F_Term's PackedFloat32Array chart [V digest].
- Departure: Random_Entropy (randomness, spine 10) returns as a field trip: week two's chance comes back as a measure.
- Project step: Plan the final project: from your F curve, pick the chapter where you were most wrong and build your hall's argument on it.

#### 41. Out of the lab: your hall in the collective museum

- Verb: simulate. Spine: postfoundationscrisis (25), visit 3 of 3. Halls: SpeculativeComputation_Collective_Knowledge (carrier); CriticalAlgorithms_Applied_Ethics (carrier); PostCrisis_Synthesis (carrier); SpeculativeComputation_Situated_Computation (field trip). Tracks: long.
- Status: planned
- CODE new: files. Returns: json, save_load, xr, export_build, profiling, testing, classes, resources, import_assets, ai_assist, audio, ui.
- BODY: Your hall in Ada's endless museum, built from your families, each body with its prediction, comparison sheet, claim and debt comment; one public sculpture whose visitors' changes are kept as provenance records (who, when, what) in files under user://, readable by the next visitor; exported to desktop and Quest.
- ARGUMENT: axis *who may change the sculpture*: only the author / anyone, last write wins / anyone, with kept history / no one (sealed). Predict: 'only the author' and 'sealed' will look most alike in any still: to a visitor both are unchanging. Last write wins drifts toward the latest visitor, and kept history grows layers. Claim: *A public body is its edit rule: who may revise it, and whether revisions are kept, shows in its shape over a week.*
- DEBT: Can the work keep its conditions, exclusions and possible revisions available to others (the post-crisis question)? Illich's repairability and the application's commoning: a hall that can be opened and changed. Collective memory is also surveillance: the provenance log records its visitors, so it asks for consent at the door.
- PLACE: Show it: the hall stands in the class's shared museum, where classmates walk, carry, revise or become its bodies, on desktop and in the headset.
- Godot: FileAccess: open(), store_line(), get_line() · DirAccess to list other halls' records · UndoRedo for a visitor's changes · export presets for desktop and Quest, and the final checklist (frame time, comfort, labels) · planted bug: opening the log with WRITE on every visit truncates it, so the history is always one entry long (READ_WRITE and seek_end() are the repair).
- Lineage: Processing: Handbook 'Synthesis 4' [V via c4]. NoC: the Ecosystem Project, a museum exhibit of creatures [V research_creative]. Application: the application's hacker ethics (Freire, Illich, commoning) and open publication; all four work packages as the student's menu. Klee: IV the close, where the line returns to the dot of page one [V via c7]. Reference: Code as Creative Medium 'Virtual Public Sculpture' and 'Collective Memory' [V ToC via c7]; SFPC Code Societies 'Distributed Web of Care' [V research_creative via c7]; Zach Blas, Facial Weaponization Suite (a collective body, consent first) [V research_queer]; SpeculativeComputation_Collective_Knowledge's provenance, DISPUTE, REVISE and UndoRedo [V digest].
- Project step: FINAL: your hall in the collective museum, exported and walked, with every body's prediction, sheet, claim and debt comment, and its edit rule.

## For the teacher

### Supplied parts, and where each is opened

| Supplied part | Used from | Opened at | Where it lives | Exists? |
|---|---|---|---|---|
| desktop walker and XR rig (skin separated from controller) | ch01 | ch19 | commons/scenes/vr_staging.tscn with Godot XR Tools | yes [V repo] |
| runnable kits: day-zero, point-zero, point-one, point-coordinates, point-lines, point-trace | ch01 | each in its own chapter (ch01-ch06) | doc/book/studies/ | yes [V repo] |
| place_at(where) helper | ch01 | ch05 (you write functions) | the day-zero kit holds base.tscn, project.godot, README.md and DAY_ZERO.md; no place_at anywhere in doc/book/studies/ | no: to be written [V repo] |
| make_solid() / make_ghost() and the contact probe | ch03 | ch03 | doc/book/studies/point-one/solid.gd, contact_probe.gd | yes [V repo] |
| pickables and desktop carry | ch04 | ch19 (the walker opened) | XRToolsPickable; the point-coordinates kit | yes [V repo] |
| SKETCH helper point(p), line(a, b), box(p, size) | ch01 | ch05 | seeded by point-lines/segment.gd show_between() | partly: line exists, point and box to be written |
| each student's scan, imported by the teacher (glTF, scale fixed) | ch08 (short track) | ch18 | made on day 4, placed in the student's room before the day-5 export | made in class |
| random-definition kit (display.gd, six steps) | ch11 | ch11 | doc/book/studies/random-definition | yes [V repo] |
| heightfield-to-mesh-and-collider helper | ch12 (short track) | ch12 (the long track writes it) | Noise_Space_10 is the model | no: to be written |
| trig one-liners wave_height(x, z), catenoid(u, v), gap_to_circle(n) | ch12, ch16 | ch24 | to be written for the course | no: to be written |
| Ada's pyramid.gd as the swept class | ch15 | its base ring at ch24 | commons/primitives/pyramid/pyramid.gd (@export_enum apex_stance, line 43) | yes [V repo] |
| sweep_sheet scene (labelled members side by side) | ch01 | ch15 (rewritten by the student) | Ada's tools/build_dna_gallery.py is the adult version | no: to be written |
| in-world slider | ch15 | never (a component) | Ada's slider_horizontal.tscn | yes [mem, project memory] |
| three-segment organism scene for critique session (a) | short track, week 3 | ch13 (the long track builds it in code) | to be written for the course | no: to be written |
| one sound player | ch25 | ch27 | AudioStreamPlayer3D | engine |
| marching-cubes lookup table | ch36 | ch36 (as a code-critique station) | ISO_LookupTable's table | yes [V spine.json] |
| export presets (desktop, Android/Quest) | ch08 | ch08 | Project > Export; the Quest route as in Day Zero, not yet tried on a headset in this edition | engine |

Before the short track can run as written, six parts must be written: place_at(), the point and box one-liners of SKETCH, the sweep sheet, the heightfield helper, the trig one-liners and the organism scene. All six are small; none needs a new engine feature.

### The planted-bug catalogue

One real error per chapter, whose message the student reads before fixing it. The messages are recalled from Godot 4 behaviour [mem] unless the chapter names an Ada source; trigger each once before class.

| ch | Planted bug |
|---|---|
| 1 | a misspelled node name in get_node(): read 'Node not found' and fix the name, not the code around it |
| 2 | radius set on a mesh variable that is still null ('Invalid set index radius on base Nil'): the order of statements matters |
| 3 | 'if solid = true:' (assignment where a comparison was meant) is refused by the parser: read the underline before running |
| 4 | the label reads the child's local position, which never changes while you carry the parent |
| 5 | look_at() when both points coincide fails with an error: a line of length zero has no direction |
| 6 | the array declared inside _process, so it is born empty every frame and the trace is never longer than one point |
| 7 | vertices added counter-clockwise (the OpenGL habit): the plane is invisible from above and visible from below |
| 8 | (supplied by the drafter) counter-clockwise triangles, found by stepping through the loop that emits them |
| 9 | hue = (x + z) / (2 * n) in integers is 0 for every cell, the whole floor comes out red, and the editor's integer-division warning says why (float() is the repair; types are named in ch14) |
| 10 | set_pixel at x == size is out of bounds; the wrap (x % size) is both the repair and the pattern's own rule |
| 11 | randomize() left in after setting the seed, so the 'repeatable' floor changes on every run |
| 12 | frequency 1.0 on a 1 m grid samples the noise once per cycle, the terrain looks like randf() (aliasing), and the repair is a smaller number, not a new source |
| 13 | rotation applied to the mesh child instead of the pivot, so each segment spins on its own centre and the chain comes apart |
| 14 | the sweep sets rings from a text field as the string '16'; set() on a typed int refuses it in silence and four identical spheres come back. Read the printed triangle counts before believing the sheet |
| 15 | the setter calls _rebuild() before the node is ready, so errors fill the Output as soon as the scene opens (guard with is_node_ready()) |
| 16 | the test compares floats with == (gap == 0.0 never passes): write a tolerance |
| 17 | five bodies built from one Genome instance: mutate one and all five change (duplicate() is the repair) |
| 18 | the import arrives 100 times too large (centimetres against metres): read its AABB in the Inspector before moving the camera |
| 19 | gravity added to velocity.y and then velocity replaced by the input vector, so the walker floats off every ledge |
| 20 | a signal connected to a method with the wrong number of arguments is refused at every emit and the counter never moves (count the arguments) |
| 21 | the ray's target_position left at its local default (0, -1, 0), so on a rotated hip it points sideways and the foot steps into the air |
| 22 | the two update lines swapped (explicit against semi-implicit Euler), so the orbit in the field trip spirals outward |
| 23 | the Area3D's collision mask does not include the player's layer, so the region works on boxes and not on you |
| 24 | degrees passed to sin() (sin(30) is not one half), so the stair wraps several times around its column |
| 25 | the state changes but the stone's timer is not stopped, so a GONE stone sinks again and the round is lost twice |
| 26 | instance_count set after the transforms (setting it clears them), so the sculpture is empty |
| 27 | samples written as floats between -1 and 1 into the 16-bit buffer without scaling to 32767: silence |
| 28 | local_coords left on for a moving emitter, so the stream travels with your hand instead of staying in the field |
| 29 | hue lerped from 0.9 to 0.1 goes the long way round, through green, instead of across red: wrap the difference |
| 30 | a sampler2D uniform left unbound reads as white, so EMISSION from it makes the whole body glow |
| 31 | reading and writing the same buffer, so the rule sees its own new values and the pattern leans to one side |
| 32 | branch(depth, ...) instead of branch(depth - 1, ...) gives 'Stack overflow', and the Stack Frames panel shows the same function hundreds of times |
| 33 | rules applied in place to the string being read, so newly written symbols are rewritten again in the same generation |
| 34 | the visited set is never updated, so the search queues the same cells forever and the frame freezes (the 16-second rule) |
| 35 | the subclass's _init forgets super(), so pinned particles have no position and the cloth hangs from the origin |
| 36 | add_child() called from the worker thread errors or crashes until the node is handed back with call_deferred() |
| 37 | each boid reads neighbours already moved this frame (update in place), so the flock drifts in the order of the group |
| 38 | the Image is rewritten but the ImageTexture is not updated, so the floor never changes (texture.update(image) is the repair) |
| 39 | await on a signal that already fired before the await line, so the room waits forever (check the state first, or connect earlier) |
| 40 | log() of a zero count is -inf and the entropy reads nan: skip the symbols that never occur |
| 41 | opening the log with WRITE on every visit truncates it, so the history is always one entry long (READ_WRITE and seek_end() are the repair) |

## How the course relates to the spine

**Order agreement 0.866.** Take each chapter's lowest spine number and count the chapter pairs that keep the spine's order: 710 of 820 pairs do. The spine itself (the control candidate c1) scores 1.000; the contract's band for 'related, not forced' is about 0.6-0.95. Of the 110 pairs out of order, 37 involve the two chapters that bring chance and noise forward (ch11, ch12): that single move accounts for a third of the distance from the spine.

**Departures.** 29 chapters carry a departure note and none is missing one (the workflow's rule: a chapter whose lowest spine number is below an earlier chapter's must say why). 21 of them sit below the spine order of an earlier chapter; the other 8 (ch08-ch12, ch31, ch34, ch38) draw on a later sequence early and say why a student needs it then. Seventeen of the 21 are ch13-ch29, which draw on spine 1-9 after chance and noise (spine 10-11) were met at ch11-12; the other four (ch35, ch36, ch37, ch40) are returns in Part VII.

The 29 departures fall into seven kinds:

| Kind | Count | Chapters |
|---|---|---|
| Chance and noise met early: the student needs a pattern to disturb and ground to walk in the first month (application WP1, Queer 3D's first principles, 10 PRINT) | 3 | 10, 11, 12 |
| Klee's order: structure before the organism, balance before the curve, the stair before the pendulum, colour at the end | 9 | 9, 13, 19, 20, 21, 22, 24, 26, 29 |
| Parameterize: an addition the spine has no place for (74% of Ada's scripts are families) | 4 | 14, 15, 16, 17 |
| A declared return to a sequence met earlier | 7 | 18, 23, 25, 35, 36, 37, 40 |
| One hall visited early for one pattern, its sequence taught later | 2 | 31, 38 |
| An idea the spine has no sequence for (the AI drafter, sound) | 2 | 8, 27 |
| Another reference's order: The Nature of Code (flow after noise), the application (graphs with world building) | 2 | 28, 34 |

Nine of the 29 come from Klee's order. That is the second-generation judges' main objection to this course: in those nine places Klee's book, not the student's need, decides. Each of the nine is kept because Klee's order is also a physical one a student can follow (stand the body before you push it; the curve follows the balance; the spiral comes out of the pendulum), and each says so in its note. A teacher who wants colour and the shader sooner can move ch29 to follow ch21 and ch30 to follow ch24 without breaking the ladder (checked on the JSON: colour needs the rays of ch21, the shader needs the trig of ch24 and the interpolation of ch29). The force block cannot be turned round: the integrator (ch22) and the regions (ch23) use the bodies and signals ch20 introduces, and the pendulum (ch26) needs ch24's trig.

### Every departure, with its reason

| ch | Title | Kind | Below the spine order? | Reason |
|---|---|---|---|---|
| 8 | When things go wrong: the drafter is a machine | no_spine_place | no, ahead | Directing generated code has no spine sequence: it is Palle's own Queer 3D practice, and every later planted bug assumes the debugger, so it closes week one. The bias hall (postfoundationscrisis, spine 25) is walked as an encounter only; it returns as a carrier at ch38. |
| 9 | The chessboard: purely repetitive and therefore structural | klee_order | no, ahead | array_tutorial (spine 3) comes before transformation (spine 2), and colour (spine 4) enters inside it as a value: Klee puts structure (I.5-6) before the organism (I.9-12), Form+Code puts Repeat before Transform, and bodies can be repeated with position alone. Transform arrives with the organism (ch13); colour as a system returns at Klee's close (ch29). |
| 10 | Pattern: structure moves into the surface | chance_early | no, ahead | tiling (spine 5) comes before transformation (2) and before colour as a system (4): regularity is taught right before randomness, as 10 PRINT argues, so the next chapter has a pattern to disturb. |
| 11 | Disturbed order: chance enters the grid | chance_early | no, ahead | randomness (spine 10) is met at chapter 11 of 41, right after the grid and the tile: it enters Klee's lineage in 1965-68 as the disturbance of a grid already built (Nake, Nees, Molnar); the 2023 application puts it in WP1, and Queer 3D's foundation asks 'what is randomness' first. It returns as the midterm round (ch25) and as entropy (ch40). |
| 12 | Noise: chance that remembers its neighbour | chance_early | no, ahead | noise (spine 11) follows chance straight away, at chapter 12: Queer 3D's first principles put simplex noise second, after randomness, and the application lists Perlin noise and Voronoi in WP1. The noise sequence's other halls return later: the field of arrows (ch28), fBm in the shader (ch30) and the voxel volume (ch36). |
| 13 | The organism: bone, tendon, muscle | klee_order | yes | transformation (spine 2) comes after repetition, chance and noise: Klee's organism (I.9-12) follows structure (I.5-6) and Form+Code puts Transform after Repeat. Position was never delayed (ch4); what waited is the frame, the pivot and time (delta), promised since ch2. |
| 14 | Families: one body in a single class | addition | yes | Parameterize has no spine sequence: this part (ch14-18) is an addition, declared as one, and it returns to primitives halls (spine 1) whose works are already families. It comes after chance and noise so that the seed and the frequency can become axes of the family; 74% of Ada's scripts are built this way (@export) [V BRIEF]. |
| 15 | The family in the editor: setters, @tool and the sheet opened | addition | yes | Color_Context_Placed (color, spine 4) and Topology_Entropy_Morphogenesis (softbodies, spine 17) are visited only for their @export_enum and setter patterns. The colour hall returns as a system at ch29, the soft hall in full at ch35. |
| 16 | The budget: polycount measured, a claim tested | addition | yes | formfinding (spine 8) is visited early for one surface: the catenoid is a parametric (u, v) body and belongs with Parameterize. Form found by force returns with balance (ch20) and the soft bodies (ch35). |
| 17 | Genes as files: a family saved, a body recalled | addition | yes | proceduralgeneration (spine 16) is visited early for its genome-as-file pattern, where Parameterize ends: a family becomes data that can be saved, shared and bred. Evolution itself returns with the bodies that learn (ch38). |
| 18 | Collage: a found body joins the family | return | yes | A deliberate return to the last primitives hall (Melencolia, spine 1) as the synthesis of Parts I-III; it closes the teaching half of the short track, which pivots into the mini project here. |
| 19 | Eye level: the walker opened | klee_order | yes | A second transformation hall (spine 2) after the family part; Escher_Impossible (foundationscrisis, spine 23) is a field trip for one viewpoint and returns as a carrier at ch39. The player is opened in Klee's part on the eye rather than with the forces, so the small-game kit can come together at ch25. |
| 20 | The tightrope walker: balance | klee_order | yes | formfinding (spine 8) comes before the rest of forces (spine 7): Klee's balance (II) precedes the gravitational curve (III). Stand the body before you push it: here the engine's gravity does the work; in Part V you write gravity yourself. |
| 21 | Legs: the passive part drives | klee_order | yes | A forces hall (spine 7) visited before the rest of forces: stepping and tipping belong with balance, which is Klee's order (II before III). It softens the parent's IK chapter: the follow pass of FABRIK only, no solver. |
| 22 | The bullet: a curve made of steps | klee_order | yes | change (spine 6) comes after balance: the curve follows balance, as Klee's gravitational curve (III) follows balance (II). It sits below chance and noise (spine 10-11), which were met early and are declared at ch11-12. |
| 23 | Regions with other laws | return | yes | Back to the forces sequence (spine 7) after change (6); its halls on balance and legs were visited early (ch20-21), and chance and noise (spine 10-11) were met early (declared at ch11-12). |
| 24 | The stair climber: a spiral you can walk | klee_order | yes | A wavefunctions hall (spine 9) before the rest of the wave sequence: the stair is a function made walkable, and trig belongs where Klee has the stair climber (III), before the pendulum (IV). It sits below chance and noise (spine 10-11), declared at ch11-12. |
| 25 | To stand despite all possibilities to fall: a round | return | yes | A declared return to randomness (spine 10) as the long track's midterm: the chance met at ch11 now drives a whole round, and the small-game kit (player, input, camera, ui, save, build) comes together. |
| 26 | Pendulum, circle, spiral: time laid into space | klee_order | yes | wavefunctions (spine 9) resumes after the midterm. Fractal_GoldenSpiral (fractals, spine 14) is visited early as a field trip: Klee derives the spiral from the pendulum, and the golden section returns with recursion (ch32). |
| 27 | Sound: the swing heard | no_spine_place | yes | Tutorial_Disco (array_tutorial, spine 3) is revisited for its step sequencer, the spine's earliest generated tone. Sound, a WP1 Basic Element with no early spine place, gets its home here with the swing it hears. |
| 28 | The arrow and the field of arrows | reference_order | yes | Flow_Field (change, spine 6) comes after the wave sequence and after noise (met at ch12): The Nature of Code puts flow fields after noise, and Klee's arrow closes his kinetic part. |
| 29 | A colour has many faces | klee_order | yes | color (spine 4) returns here as a system, where Klee's book ends in colour and Albers puts theory after experience; colour as a value was met at ch9, and chance and noise (spine 10-11) were met early (declared at ch11-12). |
| 31 | Rules in time: cellular automata | early_visit | no, ahead | ProceduralGeneration_Reaction_Diffusion_Systems (softbodies, spine 17) is visited early as a field trip: reaction-diffusion is a double-buffer rule like the automaton; the soft-body sequence it belongs to is taught at ch35. |
| 34 | How do we navigate an auto-generated world? | reference_order | no, ahead | graphtheory (spine 22) is pulled forward into procedural generation (spine 16): the application's WP3 puts graph theory with world building, and a maze needs a graph. The rest of graph theory stays an encounter. |
| 35 | Soft bodies: the organism returns | return | yes | formfinding (spine 8) returns by name: FormFinding_Relaxation's cloth belongs with the soft bodies, where relaxation becomes flesh. |
| 36 | Stone upon stone, chip from chip: implicit and boolean bodies | return | yes | Noise_Voxel (noise, spine 11) returns as a field trip: ch12's terrain becomes a volume. |
| 37 | Many bodies with rules: swarms | return | yes | Random_Pheromone (randomness, spine 10) is a field trip: the pheromone walk is chance with a memory left in the ground, a return of ch11-12. |
| 38 | Bodies that learn: whose data trains the body | early_visit | no, ahead | CriticalAlgorithms_Algorithmic_Bias_Visualization (postfoundationscrisis, spine 25) is a carrier here, ahead of its sequence: bias belongs beside the learner that has it. It was walked as an encounter at ch8. |
| 40 | Order toward entropy: the QFEP laboratory | return | yes | Random_Entropy (randomness, spine 10) returns as a field trip: week two's chance comes back as a measure. |

### The spine index

Each spine sequence, the chapters that draw on it (in visit order), and the halls used. A jump in the chapter numbers is a departure or a return, and the chapter says which.

| Spine | Sequence | Chapters (visits) | Halls used |
|---|---|---|---|
| 1 | primitives | 1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 16, 18 | 12 of 12: Point_Animatedcube, Point_Coordinates, Point_Line_Grid, Point_Lines, Point_One, Point_Trace, Point_Triangle_Context, Point_Zero, Primitives_Ignorance, Primitives_Melencolia, Primitives_Polythedra, Primitives_Portals |
| 2 | transformation | 13, 19, 21 | 7 of 7: Trans_Body, Trans_Introduction, Trans_Pit, Trans_Pre, Trans_Rotation, Trans_Scale, Trans_Translation |
| 3 | array_tutorial | 9, 10, 27 | 4 of 5: Array, Tutorial_3D, Tutorial_Disco, Tutorial_Tiling_Floor |
| 4 | color | 9, 15, 29 | 7 of 8: Color_Context_Placed, Color_Flashlight, Color_Nails, Color_Paint, Color_Pillar, Color_Rainbow, Color_Walls |
| 5 | tiling | 10 | 3 of 8: Pattern_Foundry, Symmetry_Seventeen, Tutorial_Pattern |
| 6 | change | 22, 28 | 2 of 2: Change_Intro, Flow_Field |
| 7 | forces | 20, 21, 22, 23, 28 | 9 of 13: VFM_03_Motion, VFM_05_Launch, VFM_07_Gravity, VFM_09_Legs, Vectors_Act1_WhatAVectorIs, Vectors_Act3_FieldsAndMotion, Vectors_Act4a_KineticForces, Vectors_Act4b_Oscillation, Vectors_Act5_ForceAsPlace |
| 8 | formfinding | 16, 20, 25, 35 | 4 of 6: FormFinding_Catenary, FormFinding_Equilibrium, FormFinding_Forge, FormFinding_Relaxation |
| 9 | wavefunctions | 24, 26, 27 | 7 of 12: WaveFunctions_AirMusic, WaveFunctions_Effect_Sound, WaveFunctions_Pendulum, WaveFunctions_Synthesis_Lab, WaveFunctions_TrigWalkingPath, WaveFunctions_Unit_Circle, Wavefunctions_Sky_Stairs |
| 10 | randomness | 11, 17, 25, 37, 40 | 9 of 14: Random_Cubes, Random_Definition, Random_Entropy, Random_Game, Random_Pheromone, Random_Remove, Random_Space_Geometry, Random_Walk, Randomness_10_PRINT_Algorithm |
| 11 | noise | 12, 28, 30, 36 | 5 of 9: Noise_Columns, Noise_Inside_Noise, Noise_Space_10, Noise_Voxel, Random_Noise_Types |
| 12 | shaders | 30 | 6 of 6: Shader_01_Shaping, Shader_05_Patterns, Shader_09_FBM, Shader_10_ReactionDiffusion, Shader_11_QueerRubber, Shader_12_PinkExtravaganza |
| 13 | cellularautomata | 31 | 3 of 8: CA_EdgeOfChaos, CA_GameOfLife, CA_Introduction |
| 14 | fractals | 26, 32 | 5 of 7: Fractal_GoldenSpiral, Fractal_KochSierpinski, Fractal_MengerSponge, Fractal_Recursion, Fractal_RecursiveTrees |
| 15 | lsystems | 33 | 6 of 8: Assemblage_Same_Desire, LSystems_Architecture, LSystems_Grammar_Lab, LSystems_Growth, LSystems_Living, LSystems_Shape_Grammars |
| 16 | proceduralgeneration | 17, 34 | 2 of 7: PG_Caves_Mazes, PG_Genetic_Evolution |
| 17 | softbodies | 15, 31, 35 | 4 of 9: ProceduralGeneration_Reaction_Diffusion_Systems, SoftBodies_Playground_of_Joy, SoftBodies_Soft_Body_Deformation, Topology_Entropy_Morphogenesis |
| 18 | isosurfaces | 36 | 3 of 13: ISO_Introduction, ISO_LookupTable, ISO_Metaballs |
| 19 | boolean_surfaces | 36 | 1 of 3: Boolean_Verbs |
| 20 | swarmintelligence | 37 | 3 of 7: SwarmIntelligence_Boids_Algorithm, SwarmIntelligence_PhysarumColony, SwarmIntelligence_Swarm_Intelligence_Algorithms |
| 21 | machinelearning | 38 | 4 of 8: ML_Classification, ML_Evolution, ML_Gradient_Landscape, ML_Neural_Networks |
| 22 | graphtheory | 34 | 2 of 8: GT_Pathfinding, GT_Spanning_Trees |
| 23 | foundationscrisis | 19, 39 | 6 of 8: Brouwer_Intuitionism, Escher_Impossible, Euclid_Parallel, Godel_Incompleteness, NonEuclidean_Spaces, Russell_Paradox |
| 24 | qfeplaboratory | 40 | 3 of 8: QFEP_Edge_Of_Chaos, QFEP_F_Term, QFEP_Lambda_Spectrum |
| 25 | postfoundationscrisis | 8, 38, 41 | 5 of 8: CriticalAlgorithms_Algorithmic_Bias_Visualization, CriticalAlgorithms_Applied_Ethics, PostCrisis_Synthesis, SpeculativeComputation_Collective_Knowledge, SpeculativeComputation_Situated_Computation |

134 hall references, 122 distinct halls, all present in the spine's 204. Not every hall has a chapter: encounters stay encounters, and the standing rulings of doc/book/TUTORIAL_LINEAGE.md hold where a chapter uses those halls.

## Lineage

Each spine sequence against the 2023 application's work packages, Klee's Pedagogical Sketchbook, the Processing books, The Nature of Code, and the reference course or text that shaped its chapter.

| Spine | Sequence | Chapters | Application | Klee | Processing | Nature of Code | Reference |
|---|---|---|---|---|---|---|---|
| 1 | primitives | 1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 16, 18 | pre-WP foundation; WP2 queer meshes (polycount, ch14 and ch16) | I.1-4 the point on a walk, the line, the plane | Learning Processing ch1-9; Handbook Shape 1-3, Control 1-2 | ch0-1 (the Walker; vectors as positions) | Code as Creative Medium 'Computing without a Computer'; GDQuest Learn GDScript; LeWitt's instructions; Montfort (modify before write) |
| 2 | transformation | 13, 19, 21 | pre-WP (vectors become frames); VR presence | I.9-12 bone, tendon, muscle; II eye level | Learning Processing ch14; Handbook Transform 1-2 | ch3 angular motion | Form+Code 'Transform'; Gaboury, 'Object Paradigms' |
| 3 | array_tutorial | 9, 10, 27 | 'increasingly complex control structures'; WP1 sound (Tutorial_Disco) | I.5-6 structural rhythm, the chessboard | Learning Processing ch6 and ch9; Handbook Control 2 | none | Form+Code 'Repeat'; Molnar's series |
| 4 | color | 9, 15, 29 | WP3 shading algorithms | IV the central grey, the colour circle | Learning Processing ch1 colour | none | Albers, Interaction of Color; Code as Creative Medium 'Color' |
| 5 | tiling | 10 | WP3 pattern and world building | I.6 structure moves into two dimensions | Learning Processing ch15 images and pixels | none | 10 PRINT 'Regularity'; the seventeen wallpaper groups |
| 6 | change | 22, 28 | WP2 flow fields; WP4 chaos, previewed | III the bullet; IV the arrow | none | ch1-2 motion; ch6 flow field following | Code as Creative Medium 'Personal Prosthetic' (ch28) |
| 7 | forces | 20, 21, 22, 23, 28 | WP2 soft bodies' rigid ancestor; WP4 algorithmic life | II balance ('He is the scale'); III regions of different density | none (Processing has no physics engine) | ch2 Forces; ch5 physics libraries; ch6 steering | The Nature of Code's midterm; The Coding Train |
| 8 | formfinding | 16, 20, 25, 35 | WP2 soft body simulation; polycount | II balance | none | ch5 physics libraries (springs) | Catlike Coding's mathematical surfaces; c6's constraint iterations as stiffness |
| 9 | wavefunctions | 24, 26, 27 | WP1 sine curves, resonance, sound; WP2 Fourier | III the stair climber; IV pendulum, circle, spiral | Learning Processing ch13; Handbook Math 3 | ch3 Oscillation | Form+Code's slit-scan (time laid into space); Hamraie, Building Access (the stair) |
| 10 | randomness | 11, 17, 25, 37, 40 | WP1 randomness | absent from Klee: the lineage's first departure | Learning Processing ch4; Handbook Math 4 | ch0 Randomness, the random walk | Nake, Nees, Molnar; 10 PRINT; Queer 3D's first principles |
| 11 | noise | 12, 28, 30, 36 | WP1 Perlin noise, Voronoi | none | Learning Processing ch13 noise(); Handbook Math 4 | ch0 Perlin noise | Queer 3D's blob aesthetic; Catlike Coding (hash before noise); The Book of Shaders (fBm) |
| 12 | shaders | 30 | WP3 shading; WP2 queer textures; WP3 reaction-diffusion | IV the colour circle | Processing PShader | none | The Book of Shaders; Gaboury on the GPU |
| 13 | cellularautomata | 31 | WP2 cellular automata; WP3 reaction-diffusion (Turing 1952) | none | Handbook 'Simulate' (Life) | ch7 Cellular Automata | Turing, 'The Chemical Basis of Morphogenesis' [mem] |
| 14 | fractals | 26, 32 | WP2 fractal subdivision; WP1 Fibonacci | none in the Sketchbook | Handbook Shape 3 (recursion) | ch8 Fractals | Form+Code 'Repeat: Recursive Tree' |
| 15 | lsystems | 33 | WP2 L-systems | I.1 the walk, now following a grammar | none | ch8 L-systems | Butler on performativity (the debt of ch33) |
| 16 | proceduralgeneration | 17, 34 | WP3 procedural generation, evolutionary algorithms: 'How do we navigate an auto-generated world?' | none | Learning Processing ch18 data | ch9 genotype and phenotype | 10 PRINT's maze walker; Ahmed's desire lines [mem] |
| 17 | softbodies | 15, 31, 35 | WP2 soft body simulation (cloth, liquids, rubber) | I.9-12 tendon and muscle as constraints | Handbook 'Simulate' | ch5 springs | c6's 'the same net is rubber or chain' |
| 18 | isosurfaces | 36 | WP2 queer meshes (fusion, topology) | I.12 'stone upon stone' against 'chip from chip' | none | none | a code-critique station on Ada's marching-cubes table (Critical Code Studies) |
| 19 | boolean_surfaces | 36 | WP2 queer meshes | I.12 additive and subtractive making | none | none | the same station |
| 20 | swarmintelligence | 37 | WP4 swarm intelligence, algorithmic life | none | Shiffman's Flocking example | ch6 Autonomous Agents | Reynolds's boids [mem] |
| 21 | machinelearning | 38 | WP3 neural networks, evolutionary algorithms; WP4 AI | none | none | ch10 Neural Networks | Code as Creative Medium 'Data Self-Portrait' |
| 22 | graphtheory | 34 | WP3 graph theory | none | none | none (graphs are outside The Nature of Code) | Ahmed's desire lines against the shortest path [mem] |
| 23 | foundationscrisis | 19, 39 | WP4 non-Euclidean spaces; the 2022 prototype's paradoxes of infinity | II 'It isn't wrong logically', but psychologically | none | none | the crisis halls (Escher, Godel, Brouwer, Russell) |
| 24 | qfeplaboratory | 40 | the application's arc toward entropy | none | none | none | c1's prediction log as the F term; c5's chance returning as entropy |
| 25 | postfoundationscrisis | 8, 38, 41 | hacker ethics: Freire, Illich, commoning; all four WPs gathered | IV the close, where the line returns to the dot | Handbook 'Synthesis 4' | the Ecosystem Project | Code as Creative Medium 'Virtual Public Sculpture'; SFPC Code Societies |

Sources and what each does in the course:

- **Paul Klee, Pedagogical Sketchbook (1925; Praeger 1953).** the macro-order of Parts I-VI, checked against the Praeger text; its active/passive mapping is the course's structural queer argument (ch13, ch21)
- **The 2023 research application, 'Klee's Pedagogical Sketchbook in drag, in VR'.** the model the course takes at its word; the four work packages and the arc toward entropy
- **Ada's spine (commons/maps/curriculum_spine.json: 25 sequences, 204 halls).** the halls that carry each chapter, the order of Part VII, and the index every departure is measured against
- **The /course opening (doc/book/course/opening.json) and the kits in doc/book/studies/.** chapters 1-6 run on existing kits, in the opening's own order; ch11 runs on the random-definition kit
- **Palle Torsson, Queer 3D World (Konstfack, 2024).** the three layers in every chapter; randomness then noise as first principles; scanning in week one; the three-week short track
- **Wassily Kandinsky, Point and Line to Plane (1926).** Part I's polarity questions as the first argument axes
- **Josef Albers, Interaction of Color (1963).** the method of every argument: one constrained material, one varied property, compared side by side
- **Frieder Nake, Georg Nees, Vera Molnar (1965-74); 10 PRINT (2012).** where chance enters: as the disturbance of a grid already built, regularity before randomness
- **Casey Reas, Chandler McWilliams, LUST, Form+Code (2010).** the five verbs as a handle on every chapter; Parameterize as a part of its own
- **Golan Levin, Tega Brain, Code as Creative Medium (2021).** the chapter format (brief with precedent, closed exercise, open make); When Things Go Wrong, Personal Prosthetic, Data Self-Portrait, Virtual Public Sculpture
- **Casey Reas, Ben Fry, Processing: A Programming Handbook (2007).** two tables of contents, a synthesis closing each part, static before continuous
- **Daniel Shiffman, The Nature of Code (2012; 2024).** the order of forces, oscillation, particles, CA, fractals, agents and learning inside Parts V-VII; the midterm; the Ecosystem Project as the final hall
- **Winnie Soon, Geoff Cox, Aesthetic Programming (2020).** one critical question per piece of syntax; write first, read the debt second; pause weeks; the final planned two units before the end
- **Mark Marino, Critical Code Studies (2020); the CCSWG.** code-critique stations on Ada's own code after making; 'describe it in a single class'
- **Nick Montfort, Exploratory Programming (2021).** modify before write; 'valid and intentional are different'; critique of starter programs, turned on Godot's walker
- **SFPC: Code Societies (2019), Recreating the Past (2018-20).** three weeks with critique sessions beside code (the short track's week 3); recreate a precedent and write the debt in the difference (ch18)
- **Jacob Gaboury, Image Objects (2021).** one technical object per chapter as the debt's lens
- **Wendy Hui Kyong Chun, Programmed Visions (2011).** 'sourcery' at the first generated and first supplied code (ch08)

## How this was chosen

The run, 2026-09-30 to 2026-10-01. Palle asked for 'a good middle ground that has a logical progression relating to the spine but not forced by it', and whether courses in critical code studies with this scope exist. Five research sweeps read comparable courses (critical code studies, creative coding, engines and shaders, Bauhaus pedagogy, queer and critical making; see LEARN.md). A contract (CONTRACT.md) fixed the shape every candidate had to have: every chapter braids code, body, argument and place, fills the debt and ontology layers, names the spine sequences and existing halls it draws on, and declares any departure from the spine's order. Eight first-generation candidates were each grown from one reference course or tradition, one of them a control that keeps the spine's order exactly. Each was scored mechanically from its JSON and by two independent judges on four rubrics (student logic, Ada intent, teachability, Godot competence, 1-10). The top three (c7, c3, c4) were bred into three second-generation candidates with different emphases, which new judges scored; they also rescored c7 as a calibration.

The composite reproduces as the mean of the mechanical score (0-1) and the rubric mean divided by ten [V, recomputed for all eleven, within rounding]. As far as the numbers show, the mechanical score falls when a course leaves the order band (c1), leaves departures undeclared (c2, c4, c5, c6, c8) or misses an application algorithm (c4).

| Candidate | Gen | Grown from | Chapters | Order agreement | Undeclared departures | Student logic | Ada intent | Teachability | Godot | Composite |
|---|---|---|---|---|---|---|---|---|---|---|
| d2_ada_first | 2 | bred from c4 (trunk), c3, c7 for Ada intent | 41 | 0.866 | 0 | 7 | 9 | 8.75 | 8.25 | **0.913** |
| d1_student_first | 2 | bred from c7, c3, c4 for student logic | 38 | 0.902 | 0 | 8 | 8.25 | 8 | 8.25 | **0.906** |
| d3_middle_ground | 2 | bred from c7, c3, c4 around a spine rule with numbered returns | 39 | 0.853 | 0 | 7.75 | 8.75 | 7.5 | 8.5 | **0.906** |
| c7_creative_medium | 1 | Levin and Brain, Code as Creative Medium | 35 | 0.948 | 0 | 8 | 7 | 9 | 8 | **0.900** |
| c3_form_code | 1 | Reas, McWilliams, LUST, Form+Code | 37 | 0.880 | 0 | 8.5 | 7.25 | 8 | 8 | **0.897** |
| c4_klee_kandinsky | 1 | Klee's Pedagogical Sketchbook; Kandinsky; Albers | 39 | 0.911 | 6 | 8 | 9 | 7.5 | 7.5 | **0.891** |
| c2_aesthetic_programming | 1 | Soon and Cox, Aesthetic Programming | 38 | 0.885 | 2 | 7 | 7.75 | 8.5 | 7.5 | **0.882** |
| c5_randomness_first | 1 | randomness first (The Nature of Code; Queer 3D's first principles) | 37 | 0.754 | 5 | 7.5 | 7.5 | 8 | 7.25 | **0.872** |
| c8_queer3d_layers | 1 | Queer 3D World's three layers | 37 | 0.932 | 4 | 7 | 9 | 7.5 | 6.5 | **0.870** |
| c6_engine_geometry | 1 | engine geometry (Catlike Coding; The Book of Shaders) | 36 | 0.873 | 7 | 7.5 | 7 | 7 | 8.5 | **0.866** |
| c1_spine_control | 1 | Ada's spine as it stands (the control) | 39 | 1.000 | 0 | 7 | 6.25 | 8 | 8.5 | **0.863** |

Calibration: the second-generation judges rescored c7 at 0.825 against its first-generation 0.900, so the second panel was stricter, and the three second-generation composites are not inflated against the first.

The margin is small. d2 leads d1 and d3 by 0.007, less than one rubric point from one judge. It won on Ada intent (9) and teachability (8.75); d1 has the better student logic (8) and d3 the more direct answer to 'related, not forced'. d3's ordering device, numbered visits to each spine sequence, is grafted into this version.

**The measured claim against the spine control.** Both courses are ladder-clean (0 violations in either track) and declare every departure. They differ in where the ideas arrive:

| Idea | d2 (this course) | c1 spine control | d1 | d3 | c7 | c3 | c4 |
|---|---|---|---|---|---|---|---|
| chance | ch11 of 41 | ch23 of 39 | ch12 of 38 | ch11 of 39 | ch13 of 35 | ch11 of 37 | ch11 of 39 |
| noise | ch12 of 41 | ch25 of 39 | ch13 of 38 | ch18 of 39 | ch14 of 35 | ch23 of 37 | ch25 of 39 |
| colour as a value | ch9 of 41 | ch15 of 39 | ch11 of 38 | ch10 of 39 | ch11 of 35 | ch8 of 37 | ch8 of 39 |
| a class (the family) | ch14 of 41 | ch15 of 39 | ch15 of 38 | ch14 of 39 | ch10 of 35 | ch18 of 37 | ch9 of 39 |
| first export | ch8 of 41 | ch10 of 39 | ch9 of 38 | ch8 of 39 | ch7 of 35 | ch6 of 37 | ch13 of 39 |
| headset | ch4 of 41 | ch4 of 39 | ch9 of 38 | ch4 of 39 | ch4 of 35 | ch6 of 37 | ch4 of 39 |
| an imported body | ch18 of 41 | ch12 of 39 | ch9 of 38 | ch8 of 39 | ch9 of 35 | ch6 of 37 | ch13 of 39 |
| delta | ch13 of 41 | ch11 of 39 | ch2 of 38 | ch12 of 39 | ch3 of 35 | ch2 of 37 | ch12 of 39 |
| the player opened | ch19 of 41 | ch12 of 39 | ch20 of 38 | ch20 of 39 | ch24 of 35 | ch14 of 37 | ch19 of 39 |
| forces (the code idea) | ch23 of 41 | ch18 of 39 | ch22 of 38 | ch21 of 39 | ch18 of 35 | ch28 of 37 | ch18 of 39 |
| sound | ch27 of 41 | ch14 of 39 | ch26 of 38 | ch13 of 39 | ch22 of 35 | ch10 of 37 | ch24 of 39 |
| a shader | ch30 of 41 | ch26 of 39 | ch14 of 38 | ch17 of 39 | ch16 of 35 | ch24 of 37 | ch27 of 39 |

Against the control, this course brings chance forward from ch23 to ch11 and noise from ch25 to ch12, where the control supplies disorder four times before it teaches chance (the judges' note on c1). Import of a found body arrives later (ch18 against ch12; in the short track the scan is supplied from day 5). The control is earlier on the player (ch12 against ch19), sound (ch14 against ch27) and shaders (ch26 against ch30): those are the costs of following Klee, and the section below names them.

## What changed after the second-generation judges

| Judges' note | What was done | Where |
|---|---|---|
| Hidden ladder break: trig is new at ch24, but ch12's height-source axis uses sin(x)*sin(z) and ch14/ch16 predictions use cosine chord arithmetic (judge 1). | Every use of sin or cos before ch24 is now a supplied one-liner that the student calls and does not write (wave_height at ch12, catenoid and gap_to_circle at ch16, the base ring of pyramid.gd at ch15), listed in the supplied-parts table and opened at ch24, where the stair climber teaches trig. The chord arithmetic in the ch14 and ch16 predictions is given as a worked number and recomputed by the student at ch24. | ch12, ch14, ch15, ch16, ch24 |
| ch15 calls a numeric apex offset (0-2.0) 'Ada's apex_stance axis', but pyramid.gd declares a String enum centred/edge/corner/beyond: the transcription trap CLAUDE.md warns about (judge 1). | The axis is now the code's own enum, read from pyramid.gd [V repo: line 43 and _apex_position()], with a prediction computed from the file's numbers (the closest pair is corner and beyond, 0.25 m, yet only beyond leaves the footprint). The debt now names the transcription trap, and the body explains why the sheet must set the enum before add_child(), which motivates the setter. | ch15 |
| Supplied parts that do not exist yet; place_at() is not in the day-zero kit (judge 2). | The supplied-parts table now says so: the day-zero kit holds base.tscn, project.godot, README.md and DAY_ZERO.md, and a search of doc/book/studies/ finds no place_at [V repo, 2026-10-01], so it is listed as to be written, with the sweep sheet, the heightfield helper, the SKETCH one-liners, the trig one-liners and the organism scene. The table has a column for what exists and what does not. | ch01 |
| The scanned/collage body waits until ch18 (day 10 of the short track), so the headset collage lands late (judge 1). | In the short track the teacher imports each scan on day 4 and places it in the student's room before the day-5 export (ch08), as a named supplied part; ch18 still teaches the import. No code idea moved, so the ladder is unchanged. | ch08, ch18 |
| The short track has no drag in code: ch13 and ch21 are long-track only (judge 2). | Critique session (a) in week 3 now has an operation, not only a walk: each student makes the foot the root of a supplied three-segment organism in the Scene dock and moves it, so the command chain turns over without code. The organism scene is listed as to be written. The code version stays at ch21 in the long track. | short track |
| 41 chapters in 'about 36 teaching weeks' is tight (judge 1). | The long track now states its real length, 42 weeks (4 + 33 + 5 pause weeks), and names six pairs that fit it into a 36-week year, each pair carrying at most three new ideas and sharing one body. | long track |
| Colour as a system waits until ch29 and shaders until ch30, late for art students and for a project with 303 .gdshader files (both judges). | Only partly repaired: ch10 now walks Shader_05_Patterns as an encounter, so the long-track student sees a pattern computed per pixel in the second month. The shader chapter cannot move before ch24 without breaking the ladder (it uses ch24's trig and ch29's interpolation). Colour after ch21 and the shader after ch24 would keep the ladder; that move is offered to the teacher in the spine section and not made, because it gives up Klee's close in colour. | ch10 |
| d3's device, adopted: numbered returns make the spine an index, not an order (breed note on d3, both judges). | Every chapter now names its visit to each spine sequence ('randomness (10), visit 2 of 7'), so a return reads as a return. The chapter order did not change. | all |

Left as it was, and why:

- Klee sets the order in nine places (colour as a system at ch29, the shader at ch30, trig at ch24, the stair before the pendulum). Moving them all would make this a different course; a move that keeps the ladder (colour after ch21, the shader after ch24) is named in the spine section as a teacher's option, not made.
- The walker stays supplied for 18 chapters and is opened at ch19; the small complete game comes together at ch25. A game-first teacher will want the walker opened earlier.
- Sound, a WP1 Basic Element, is taught at ch27 (a supplied sound plays from ch25). Turing's morphogenesis is a field trip at ch30 and ch31, not a chapter of its own; d3's 'Turing's skin' (a CPU buffer ported to a GPU ping-pong shader) is the obvious graft if one is wanted.
- Week one of the short track still includes SurfaceTool and normals (ch07, day 4, alone on its day). It is the chapter where the walked line closes into a plane you can stand on, and the course's first standable body depends on it.
- 33 chapters carry [mem] items, mostly planted-bug messages. They are marked, and the teacher's catalogue says to trigger each once before class.
- The spine still has no family sequence. Parameterize (ch14-ch18) is declared as an addition, so a reader walking the spine hall by hall will not see why those chapters exist.

## What we learned from comparable courses

The full answer is `LEARN.md`. In short: no course found covers all of Ada's scope (critical theory, writing code, 3D or VR bodies, art students who are beginners). The closest cover two or three of those.

- **Aesthetic Programming** (Soon and Cox) is closest in method: each piece of syntax is tied to a critical theme, and each week ends in code plus writing. Taken here: write first and read the debt second, pause weeks, the final planned two units before the end. Changed: the open ReadMe becomes a prediction that can be wrong.
- **Code Societies** (SFPC, 2019) is closest in shape to the short track: three weeks, critique sessions beside code. Taken: the short track's third week.
- **Claudia Hart's Experimental 3D** (SAIC) is closest to 'Klee in drag': a Bauhaus basic course redone in 3D for art students, without code. This course adds the code and the drag.
- **Gaboury's Image Objects** is the only critical reading of 3D graphics found, a book, not a course. Taken: one technical object per chapter as the debt's lens.
- **Code as Creative Medium, Form+Code, the Processing Handbook, 10 PRINT, The Nature of Code, Montfort's Exploratory Programming**: the chapter format, the verbs, the two tables of contents, regularity before randomness, the physics middle and the museum project, modify before write.

The critique in that canon is social and linguistic: data, platforms, language. Ada's geometric and bodily critique (polycount against deformation, the blob look of noise, recursion that has to be stopped, impossible space, the passive end that drives) has almost no precedent, and the course says so rather than borrowing authority.

## What the course forecloses, and what it hides

- **What it makes thinkable.** Three handles on every chapter at once: Klee's part (a story you can hold), the verb (what code does to form) and the spine visit (where you are in Ada). The prediction before every render makes each chapter falsifiable, and ch40 turns the course's predictions into a body the student walks.
- **What it forecloses.** A start from randomness (c5's order) or from the student's scanned body (c8's) is not available: the course starts where Klee starts, with a point. Bauhaus universalism is a risk the drag only partly answers: Klee's grammar is re-assigned, but his book still sets the order.
- **What it hides.** A still image cannot hold time, touch or collision, so several chapters need a witness body to show anything (ch03's probe, ch20's still taken 3 s after release). The prediction can become a scoreboard; ch40 names that risk and keeps the prediction log out of grading.

## Verification notes

- **Checks rerun on the refined JSON** [V, 2026-10-01]: 41 chapters; 0 unknown code ids; every one of the 83 ideas introduced exactly once; no chapter with more than three new ideas; ladder violations long 0, short 0; order agreement 0.866; 29 declared departures, 0 undeclared; 25 spine sequences touched; 134 hall references, 122 distinct halls, all in spine.json.
- **New in this version** [V repo]: pyramid.gd declares `@export_enum("centred", "edge", "corner", "beyond") var apex_stance` (line 43) and places the apex at the first base vertex times 1.6 for 'beyond'; base_size 0.6 and pyramid_height 0.8 give the plan positions used in ch15's prediction. No file under doc/book/studies/ contains place_at. The /course stops and their status are read from doc/book/course/opening.json.
- **Klee** [V work/klee_ps.txt, via the candidate]: 'The mobility agent, is a point' (l.279), 'planarity' (l.294), 'purely repetitive and therefore structural' (l.182), 'TO STAND DESPITE ALL POSSIBILITIES TO FALL!' (l.226), 'Male organs (anthers), active' (l.415), 'He is the scale' (l.550), the stair climber (l.611), the pendulum (l.656-676), 'the central grey' (l.816-827).
- **Recalled** [mem]: Godot API names and error texts in the planted bugs; the Scene dock's Make Scene Root; Kandinsky's chapter titles; dates of Perlin, Reynolds, Turing 1952; Hamraie, Ahmed, Butler as readings.
- **Arithmetic** (checked by hand in the run, and for ch15 here): 1 - cos(11.25 deg) = 1.9%; 1 - cos(7.5 deg) = 0.86%; 1 - cos(15 deg) = 3.4%; 1 - cos(3.75 deg) = 0.21%; ch15 apex distances 0.30, 0.30 and 0.25 m (0.18 x sqrt 2).

