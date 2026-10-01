# Candidate c4_klee_kandinsky: The Sketchbook in Drag: point, line, plane, balance, fall, swing, colour, and out

Auto-research candidate, 2026-10-01. Grown from one reference: Paul Klee, Pedagogical Sketchbook (Bauhausbuch 2, 1925; Praeger 1953) for the macro-order, verified against the 1960 Praeger text: I Proportionate Line and Structure, II Dimension and Balance, III Gravitational Curve, IV Kinetic and Chromatic Energy. Wassily Kandinsky, Point and Line to Plane (1926) for Part I. Josef Albers, Interaction of Color (1963) for the exercise method of every ARGUMENT. Nake, Nees and Molnar (1965-74) for where chance enters the lineage.

Marks: **[V]** checked in a source during this run (the Klee text in `work/klee_ps.txt`, the research sweeps, or the Ada repo); **[mem]** recalled, not checked. Nothing in either repo was edited, staged or committed.

## For the student: why this order

This course walks the way Paul Klee's Pedagogical Sketchbook walks. A point goes for a walk and becomes a line; the line closes into a plane; the plane repeats and becomes structure; structure gets depth and must balance; the balanced body falls along a curve; what falls starts to swing, circle, spiral, sound and glow, and the book ends in colour. Kandinsky named the first three steps (point, line, plane) and Albers gave the method: every chapter is a controlled problem with a visible target, solved in one constrained material and compared side by side. You build each body in GDScript, give it parameters so it becomes a family, write down which two members will look most alike before you render them, and then stand on it, carry it or walk through it. The programming ideas arrive in the order the bodies need them: a point needs a variable, a line needs a function, a walk needs a list, a floor needs a loop, a family needs a class, a balance needs physics, a curve needs your own gravity, a swing needs sine. Klee never had randomness, noise, recursion or a headset. Chance enters where it entered his lineage, as disturbance of a grid you have already built (Nake's Hommage a Paul Klee, 1965). Where his book stops, the course follows Ada's spine out of the sketchbook and says so. 'In drag' means taking Klee's grammar seriously enough to re-assign it: his first part maps active, medial and passive onto brain, muscle and bone and onto male and female; the scene tree does the same with parent and child. You will make the passive part drive.

## The shape in one table: Klee's walk against Ada's spine

| Part | Klee / lineage [V] | Chapters | Spine sequences drawn on (order) | What moves against the spine, and why |
|---|---|---|---|---|
| I Point, line, plane | Kandinsky Point, Line, Basic Plane; Klee I.1-4 (the active line on a walk; once completed, 'linearity is replaced by planarity') | 1-7 | primitives (1) | nothing: the /course opening already follows Klee's first pages |
| II Repetition is structure | Klee I.5-13 ('purely repetitive and therefore structural', 2:3:5, bone/tendon/muscle, stone upon stone / chip from chip); Nake, Nees, Molnar | 8-13 | array_tutorial (3), tiling (5), randomness (10), transformation (2), primitives (1) | arrays and tiling before transformation (Form+Code: Repeat before Transform); randomness pulled forward as disturbance of the grid (application WP1); colour held back |
| III Dimension and balance | Klee II (railroad ties, eye level, space boxes, the tightrope walker 'is the scale', non-symmetrical balance) | 14-16 | transformation (2), formfinding (8), forces (7) | balance (formfinding) before forces: stand the body before you push it |
| IV The gravitational curve | Klee III (the bullet, the swimmer, the balloon, the stair climber, the stone, the meteor; 'to stand despite all possibilities to fall') | 17-21 | change (6), forces (7), wavefunctions (9, Sky_Stairs only), randomness (10, the game) | the player enters as Klee's stair climber; chance returns as the midterm game |
| V Kinetic and chromatic energy | Klee IV (top, pendulum, circle, spiral, arrow, coloured arrows, central grey, colour circle); Albers | 22-27 | wavefunctions (9), change (6, Flow_Field), noise (11, first meeting), color (4), shaders (12) | colour taught late, as Klee's book ends in colour; the flow field as Klee's arrow |
| VI Out of the sketchbook | none in Klee: Munari's tree, LeWitt's rule, Chun, Gaboury, Queer 3D's ontology layer | 28-39 | noise (11) to postfoundationscrisis (25), graph theory pulled into procedural generation | follows the spine, with graphs moved to world building (application WP3) |

Measured on the JSON (primary spine sequence per chapter): order agreement with the spine 0.928 (ties counted in order; 0.924 without ties), 25 of 25 sequences touched, 113 distinct halls, 17 declared departures, 0 ladder violations, no chapter with more than three new code ideas, every vocabulary id used once as new. The agreement sits at the top of the 0.6-0.95 band because Part VI keeps the spine's order: the Klee reordering is concentrated in the first two thirds, where the spine is itself Klee plus introductory Processing (lineage.json notes).

## Three corrections this candidate takes from the Klee text [V]

1. The pendulum and the spinning top open Part IV (kinetic), not the gravity part. Part III is the plumb line and trajectories (bullet, stair climber, balloon, falling stone, meteor). So forces (Part IV here) come before wavefunctions (Part V), as in the spine.
2. Klee derives the circle from the pendulum and the spiral from the circle: 'Lengthening of the radius creates a vibrant spiral' and the contracting one 'dies suddenly in the static center'. That is one chain of code (ch22 to ch23) with a ready axis: the sign of the radius change.
3. The book ends in colour: coloured arrows, the central grey, the colour circle where 'all the arrows are superfluous'. This is the argued reason for teaching colour late (ch26) and the shader's colour circle as Part V's synthesis (ch27). RGB interpolation between complementaries literally produces Klee's central grey.

And the dark spot, verbatim in Part I: active/medial/passive is mapped onto 'Male organs (anthers), active' and 'Female organs (fruit), passive', and onto brain, muscle and bone. The scene tree has the same grammar (the parent moves the child). The course teaches that hierarchy (ch12) and then inverts it with inverse kinematics (ch16): the passive end drives. That is the concrete meaning of 'in drag' here, not a costume.

## Parts

- **Point, line, plane (Kandinsky; Klee I.1-4)** (ch01 to ch07). From a point you place to a plane you can stand on. You learn that the engine calls your code, that everything is an object in a tree, and that a line is a record of a walk.
- **Repetition is structure (Klee I.5-13; Nake, Nees, Molnar)** (ch08 to ch13). Repeat a body and it becomes a floor; give it parameters and it becomes a family; disturb the structure and chance appears; articulate it and it becomes an organism. The part ends in a collage of found and made bodies that you export and show.
- **Dimension and balance (Klee II)** (ch14 to ch16). The eye, the camera and the standing body: perspective as a fact about eye height, balance as a fact about the centre of mass, and legs that let the passive end drive. The engine's gravity does the work.
- **The gravitational curve (Klee III)** (ch17 to ch21). You write gravity yourself: a curve from steps, regions with different laws, a player who climbs, an orbit that leaks energy, and a small complete game about staying upright.
- **Kinetic and chromatic energy (Klee IV; Albers)** (ch22 to ch27). Top, pendulum, circle, spiral, sound, the arrow and the field of arrows, then colour and the shader: the motions that do not end.
- **Out of the sketchbook: bodies in drag (spine 11-25)** (ch28 to ch39). Where Klee has no page: noise as ground, rules in time, recursion, grammars, generated worlds, soft, implicit, boolean and collective bodies, bodies that learn, the crisis of foundations, entropy, and your own hall in the headset.

## Tracks

### Three weeks: the sketchbook's first page (`short`)

- Length: 3 weeks (15 days). Week 1 (Part I, two short chapters a day on the runnable kits): ch01-ch07, plus a scanning / Tilt Brush session whose results wait for ch13. Week 2: ch08, ch09, ch11, ch12, ch13 (export on Thursday). Week 3: mini project, with two critique sessions in the SFPC Code Societies format (Klee's active/passive passage and the blob aesthetic, walked as encounters in Noise_Space_10 and ISO_Metaballs, no code).
- Chapters: ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch08, ch09, ch11, ch12, ch13
- Supplied and named: Named, not taught: the walker and XR rig (commons/scenes/vr_staging.tscn with Godot XR Tools), the SKETCH helper (point, line, box), the joint pivots of ch12 as a helper, a two-colour palette Resource, the runnable kits in doc/book/studies/ (day-zero, point-zero, point-coordinates, point-lines, point-trace, random-definition), and an export preset. Skipped and covered by those parts: ch10 (pattern) and Parts III-VI; the camera, input and physics a visitor needs arrive inside the supplied walker and pickables.
- Mini project: A family in drag (after Code as Creative Medium's 'Extrapolated Body' and 'Virtual Creature'): one body class of your own with one axis of four values, a written prediction of the closest pair, the comparison image and a one-sentence claim; the four members placed with one scanned or sculpted body in the small walkable room of your ch13 build; one debt comment in the code saying what the approximation owes. Shown to the class as a desktop build and, where a headset is available, walked in VR.

### One year: the whole sketchbook and out of it (`long`)

- Length: About 34 teaching weeks: six parts, each closed by a synthesis (ch07, ch13, ch16, ch21 midterm, ch27, ch39 capstone) followed by a pause week with no new code (Aesthetic Programming's rhythm); the final project is planned at ch36, two units before the end.
- Chapters: ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch08, ch09, ch10, ch11, ch12, ch13, ch14, ch15, ch16, ch17, ch18, ch19, ch20, ch21, ch22, ch23, ch24, ch25, ch26, ch27, ch28, ch29, ch30, ch31, ch32, ch33, ch34, ch35, ch36, ch37, ch38, ch39
- Final: Capstone: your own hall in Ada's endless museum, exported to the Quest, built from your families; the README holds a prediction, comparison image, claim and debt comment for each body (NoC's Ecosystem Project, turned into a museum room).

The short track is ladder-clean on its own (checked: no chapter in it returns an idea its track has not introduced). It is the first half of the long track, as ITP's ICM is two seven-week halves, and it pivots into the mini project at ch13 (end of week 2), as the research asked.

## The lesson rhythm inside every chapter

Walk the hall first and guess how the work is built (PRIMM Predict, Aesthetic Programming's 'Decode'); run the kit; investigate; modify one line; make your own body. Before the sweep of four values you write the PREDICTION (the closest pair and why) in the sketchbook README; after it, the comparison image and a one-sentence CLAIM it supports. Each chapter has one planted bug whose message you read. Write first, read second: the DEBT step comes after making, and from ch13 on it includes a debt comment in your own code (after Marino's Climategate chapter). The PLACE step always ends with a body meeting yours: stand on it, walk through it, carry it, become it.

## Chapters

### Point, line, plane (Kandinsky; Klee I.1-4)

#### 1. Day Zero: the instruction is the work

- Spine: primitives (1). Halls: Point_Zero (encounter). Tracks: short, long.
- CODE new: statements, output, errors. Returns: none.
- BODY: A LeWitt location drawing turned into one body: in the supplied base.tscn (floor, camera, light, Label3D) you type one line that calls a supplied place_at(where) and a cube appears at 'corner', 'midpoint' or 'centre'; one print() writes your instruction to the Output panel.
- ARGUMENT: axis *wording of the instruction*: corner / midpoint / centre / somewhere near the middle. Predict: 'midpoint' and 'centre' will look most alike from the fixed camera (on a square floor both land on the middle line); 'somewhere near the middle' will not run at all. Claim: *An instruction a partner can interpret is not one the engine can run: ambiguity shows up as an error, not as a variation.*
- DEBT: LeWitt's drafters interpreted; the engine refuses. The planted bug (a misspelled node name) is the first debt: literalness is the price of repeatability. GDScript's English keywords are the default of programming (Marino on FLOW-MATIC), a cheap first question for Swedish-speaking students.
- PLACE: Itten's warm-up before the pencil: stand, reach and turn in the room (desktop, or the headset through the supplied walker); then a partner executes your written instruction on paper and you compare it with the run.
- Godot: project vs scene; F5 vs F6; save; an Inspector property edit seen in the running scene; print() and the Output panel; reading an error in the Debugger; calling a supplied helper before writing any (use before make).
- Lineage: Processing: LP ch2 Processing (run, errors); Handbook Structure 1 Code Elements. NoC: none (NoC assumes this semester). Application: pre-WP foundation. Klee: Introduction: the teacher supplies phenomena; axiom 'to stand despite all possibilities to fall'. Reference: Sol LeWitt, Paragraphs on Conceptual Art (1967) and Wall Drawing 159; Itten's Vorkurs warm-up; CCM 'Computing without a Computer'; Molnar's machine imaginaire.
- Project step: Start a sketchbook repository whose README will hold every prediction, comparison image, claim and debt comment of the course.

#### 2. Point: a body with no size must be given one

- Spine: primitives (1). Halls: Point_Zero (carrier). Tracks: short, long.
- CODE new: variables, properties, lifecycle. Returns: statements, output, errors.
- BODY: A point built in _ready(): a MeshInstance3D whose SphereMesh radius is a variable, placed by setting its position property; then three points by hand, and a Label3D that counts the frames the engine has called you for.
- ARGUMENT: axis *point radius seen from 2 m*: 0.01 m / 0.05 m / 0.25 m / 1.0 m. Predict: 0.01 and 0.05 look most alike (both read as dots); 1.0 stops being a point and reads as a body or a plane. Claim: *A point is a relation between size and viewing distance: Kandinsky's point becomes a plane when it grows.*
- DEBT: Mathematically a point has no extent; to be seen it needs a mesh of hundreds of triangles. The engine can only show a point by lying about its size, the first approximation of the course.
- PLACE: Walk toward and away from the four points: the 0.25 m point changes category as you approach.
- Godot: Node3D and MeshInstance3D; SphereMesh.new(), radius; position; _ready() vs _process(); the Point Zero runnable kit (doc/book/studies/point-zero).
- Lineage: Processing: LP ch1 Pixels (point, coordinates); Handbook Shape 1. NoC: none. Application: pre-WP. Klee: I.1 'the mobility agent is a point'. Reference: Kandinsky, Point and Line to Plane: Point (size and shape); Fontana's buchi as the point that cuts (Ada BASE_LAYER.md).
- Project step: Place three points whose sizes you chose; write your first PREDICTION.

#### 3. Solid and ghost: one if decides what a body is

- Spine: primitives (1). Halls: Point_One (carrier). Tracks: short, long.
- CODE new: conditions, booleans, calling. Returns: variables, properties, lifecycle, errors.
- BODY: A row of bodies whose solid boolean decides, in one if, whether their collision shape is enabled and how opaque they are; the supplied make_solid() and make_ghost() are called before they are opened.
- ARGUMENT: axis *solidity and opacity*: solid opaque / solid transparent / ghost opaque / ghost transparent. Predict: 'solid opaque' and 'ghost opaque' look identical except for the test ball dropped on each (resting on one, on the floor under the other). Claim: *What you see and what stops you are separate properties; collision is invisible until another body meets it.*
- DEBT: A still (and a screenshot) cannot show collision: the visual argument has a blind spot, and so do players. Invisible walls and walkable ghosts are the course's first uncanny.
- PLACE: Walk into each body: two stop you, two let you through, and one of the transparent ones surprises you.
- Godot: if / else, bool; StaticBody3D + CollisionShape3D (supplied), disabled; StandardMaterial3D transparency; calling functions you did not write.
- Lineage: Processing: LP ch5 Conditionals. NoC: none. Application: pre-WP. Klee: I.2-4 active, medial and passive lines (what acts and what is acted on). Reference: Kandinsky's polarities (repose against tension); GDQuest Learn GDScript lesson 3 (call supplied functions first).
- Project step: Mark one of your points as a ghost and say in one sentence why.

#### 4. Coordinates: carry the point

- Spine: primitives (1). Halls: Point_Coordinates (carrier). Tracks: short, long.
- CODE new: vectors, expressions, xr. Returns: variables, properties, calling.
- BODY: A carried point that writes its own Vector3 beside itself (Label3D), and a second point placed at an expression of the first (a + Vector3.UP, a * 0.5).
- ARGUMENT: axis *which axis the same length goes into*: (1,0,0) / (0,1,0) / (0,0,1) / (0.58,0.58,0.58). Predict: x and z look most alike from a standing eye; y does not, because up is the direction your body has. Claim: *The three axes are equal in the maths and unequal for a standing body: height is the one you feel.*
- DEBT: Godot's Y-up, metres and axis handedness are conventions baked into every later body; VR adds a default floor height that assumes a standing adult (Bagnall in Queer Game Studies on normativity in hardware).
- PLACE: Pick the point up (desktop carry, or an XR Tools pickable in the headset) and watch its coordinates change as you move it. Pickup belongs here, by the standing ruling.
- Godot: Vector3 arithmetic; global_position; Label3D; supplied XRToolsPickable and desktop carry; where the desktop rig is swapped for the XR rig.
- Lineage: Processing: LP ch1 coordinates; Handbook Shape 1 Coordinates. NoC: ch1 Vectors (as positions only). Application: pre-WP (the application names 'vectors' as a basic concept). Klee: II.14 three dimensions (borrowed early). Reference: LeWitt's corner, midpoint and centre as a coordinate system before Vector3.
- Project step: Put your three points in 3D, one of them above head height.

#### 5. Line: distance belongs to the line

- Spine: primitives (1). Halls: Point_Lines (carrier). Tracks: short, long.
- CODE new: functions, parameters, return. Returns: vectors, expressions, conditions, calling.
- BODY: A segment between two carried points: your function show_between(a, b) places, scales and orients a thin box and returns the distance; a do-not-cross barrier reacts when that distance falls below a threshold (condition before threshold).
- ARGUMENT: axis *thickness as a fraction of length*: 0.005 / 0.02 / 0.1 / 0.4. Predict: 0.005 and 0.02 look most alike (both read as lines); 0.4 reads as a slab. Claim: *A line in 3D is a thin body: the ratio of thickness to length decides whether we read a line or a plane.*
- DEBT: The engine has no one-dimensional thing to show: the line is a box or an eight-sided cylinder pretending. Distance is a return value, and every later threshold is a design decision hidden as a number.
- PLACE: Hold both ends (two hands in the headset: Klee's maker 'who has only two hands') and stretch the line until it crosses the barrier.
- Godot: func, parameters, return; Vector3.distance_to; look_at; Node3D.scale; the supplied SKETCH helper line(a, b), opened.
- Lineage: Processing: LP ch7 Functions; Handbook Shape 1 line(). NoC: ch1 Vectors (magnitude). Application: pre-WP. Klee: I.1 an active line; I.3 a line limited by fixed points. Reference: Kandinsky, Line (straight, angular, curved); the Point Lines kit.
- Project step: Connect two of your points with your own function, named after what it makes.

#### 6. The walk: a line is a record

- Spine: primitives (1). Halls: Point_Trace (carrier). Tracks: short, long.
- CODE new: arrays, loops, meshes. Returns: functions, return, conditions, vectors.
- BODY: A trace recorder: the carried point appends its position to an array once it has moved further than a gate distance (list before append, condition before threshold), and a loop redraws the array as an ImmediateMesh line strip.
- ARGUMENT: axis *sampling gate*: 0.01 m / 0.05 m / 0.2 m / 0.5 m. Predict: 0.01 and 0.05 look most alike (both read as continuous); 0.5 turns the walk into a polygon with visible corners. Claim: *A recorded line is a sampling decision: below a few centimetres the walk looks continuous, above it the corners become the drawing.*
- DEBT: Continuity is faked from a list. Memory is not free, so the trace must forget (a bounded array), and forgetting is a choice about which past counts.
- PLACE: Become the pen: the trace follows your hand (headset) or the carried point (desktop) while you walk a line through the hall, Klee's 'walk for a walk's sake'.
- Godot: Array, append, size(); for ... in; ImmediateMesh PRIMITIVE_LINE_STRIP; the Point Trace runnable kit.
- Lineage: Processing: LP ch6 Loops, ch9 Arrays (mouse history); Handbook Control 2 Repetition. NoC: ch0 the random walk (as a later return). Application: pre-WP. Klee: I.1 'an active line on a walk, moving freely, without goal'. Reference: Klee I.1 (Point_Trace's final.md already cites it); Logo's turtle; Tilt Brush drawing in space (Queer 3D 2024).
- Project step: Record one walk of your own and keep it as data in your project.

#### 7. Plane: when the line closes

- Spine: primitives (1). Halls: Point_Triangle_Context (carrier); Primitives_Polythedra (field trip). Tracks: short, long.
- CODE new: surface_tool, normals, collision. Returns: arrays, loops, meshes, vectors.
- BODY: Close the walk: the recorded points become a triangle fan through SurfaceTool, normals are generated, and a collider made from the mesh lets you stand on the plane you walked.
- ARGUMENT: axis *winding and normals*: clockwise, flat normals / clockwise, smooth normals / counter-clockwise (reversed) / reversed, double-sided. Predict: 'clockwise flat' and 'reversed double-sided' look most alike from above; 'reversed' alone vanishes from the front. Claim: *A surface has a side: what you see of a plane is a promise its winding and normals make (Godot winds front faces clockwise).*
- DEBT: Culling (Gaboury, Image Objects ch1): hidden-surface algorithms decide what exists for the eye; a one-sided plane is invisible from behind while its collider still stops you. The fan also fails on concave walks: the approximation owes the shape its dents.
- PLACE: Stand on your walk: the plane made from your own trace becomes floor; walk to its edge and look under it.
- Godot: SurfaceTool PRIMITIVE_TRIANGLES; generate_normals, commit; create_trimesh_shape, StaticBody3D; cull_mode.
- Lineage: Processing: LP ch14 vertex shapes; Handbook Shape 2 Vertices. NoC: none. Application: pre-WP (the application's 'queer meshes' start here). Klee: I.2-4 'once completed, this linearity is replaced by planarity'. Reference: Kandinsky, Basic Plane; Gaboury, Image Objects I 'Culling Vision'.
- Project step: SYNTHESIS I: your first room is one plane you walked, three points and one line. Commit it.

### Repetition is structure (Klee I.5-13; Nake, Nees, Molnar)

#### 8. The chessboard: purely repetitive and therefore structural

- Spine: array_tutorial (3), primitives (1). Halls: Point_Line_Grid (carrier); Array (carrier); Tutorial_3D (field trip). Tracks: short, long.
- CODE new: nested_loops, instancing, materials. Returns: loops, arrays, conditions, expressions, collision, booleans.
- BODY: A floor of cubes instanced from a PackedScene in a nested loop and coloured by a rule over (x, z) from a supplied palette of two materials.
- ARGUMENT: axis *rhythm rule*: every cell / (x+z)%2 chessboard / x%3 stripes / 2:3:5 proportional widths. Predict: The chessboard and the x%3 stripes look most alike from far away, where both read as texture; 'every cell' is the only floor without rhythm. Claim: *Structure is the repetition rule, not the cube: the same 64 bodies make four different floors.*
- DEBT: The grid is the unexamined ground of 3D (editor grids, voxels, Gaboury's frame buffer as a random-access grid). It is a choice, and the standing ruling holds that the first line did not need it.
- PLACE: Walk the floor; turn one cell into a ghost with Chapter 3's if and fall through it.
- Godot: nested for over range(); PackedScene.instantiate(), add_child; StandardMaterial3D shared vs per instance; the % operator.
- Lineage: Processing: LP ch6 nested loops; Handbook Control 2; Form+Code Repeat. NoC: none. Application: pre-WP. Klee: I.5-6 structural rhythm, the chessboard, 'purely repetitive and therefore structural'; I.7 divisional proportion 2:3:5. Reference: Albers's constrained material: the two-colour palette is supplied like Color-aid paper.
- **Departure:** array_tutorial (spine 3) comes before transformation (spine 2): Klee puts structure (I.5-8) before dimension (II), and Form+Code puts Repeat before Transform. Bodies can be repeated with position alone; the full transform waits for the organism (ch12).
- Project step: Lay a floor for your room with a rhythm rule of your own.

#### 9. Families: one body, one axis, a series

- Spine: primitives (1). Halls: Primitives_Ignorance (carrier); Primitives_Portals (field trip). Tracks: short, long.
- CODE new: classes, export, types. Returns: functions, parameters, instancing, loops, meshes, variables.
- BODY: Describe a body in a single class: a class_name with two typed @export axes (for example rings and taper of a column), built procedurally in _ready(); a sweep instances four members side by side as a sheet.
- ARGUMENT: axis *sphere segments (rings = half)*: 4 / 8 / 16 / 64. Predict: 16 and 64 look most alike at 2 m; 4 is not a coarse sphere but another body, close to an octahedron. Claim: *Above about 16 segments a sphere stops paying visibly; below 8 it changes category: polycount decides which body you have.*
- DEBT: Polycount against smooth deformation (the application's topology question) and the triangle budget. A typed set() on a mistyped @export is refused in silence, so a sweep can publish four identical members and look finished (the project's own science_screen case).
- PLACE: Walk the sheet as a gallery wall; carry one member into your room.
- Godot: class_name, @export, @export_range; typed variables; procedural builder in _ready(); counting triangles from surface_get_arrays.
- Lineage: Processing: LP ch8 Objects (Zoog as a class); Handbook Shape 3 Parameters. NoC: (the prerequisite semester). Application: WP2 'queer meshes' (polycount). Klee: I.7 individual articulation by proportions; I.8 linear variation. Reference: Vera Molnar's series and the 1%; Albers's controlled problem; CCSWG 2024 'describe it in a single class'; Generative Design's numbered variants.
- **Departure:** A deliberate return to a late primitives hall (Primitives_Ignorance, spine 1): the family needs loops and instancing (ch8) first, and it must come before chance so that the seed can become an axis.
- Project step: Turn one of your bodies into a class with two axes; write the closest-pair prediction before rendering its sheet.

#### 10. Pattern: structure moves into the surface

- Spine: tiling (5), array_tutorial (3). Halls: Tutorial_Tiling_Floor (carrier); Symmetry_Seventeen (carrier); Tutorial_Pattern (field trip); Pattern_Foundry (field trip). Tracks: long.
- CODE new: uv, dictionaries, methods. Returns: nested_loops, materials, classes, conditions.
- BODY: A tile written pixel by pixel into an Image from a small 4x4 source kept as a Dictionary recipe, wrapped as an ImageTexture and repeated over your floor by UV scale; one get_color(x, y) method per symmetry rule.
- ARGUMENT: axis *wallpaper rule over one 4x4 source*: p1 translation / pm mirror / pg glide / p4 rotation. Predict: pm and pg look most alike (both keep one mirror direction; the glide only shifts alternate rows). Claim: *The same sixteen pixels make four patterns: symmetry is a rule applied to a source, and the rule is what we see.*
- DEBT: Texture filtering and mipmaps blur the rule at a distance (nearest vs linear); the seventeen wallpaper groups are a closed classification that the ornament traditions they describe never needed.
- PLACE: Floor and walls of your room share one texture; walk away until the pattern reads as tone rather than tiles.
- Godot: Image.create, set_pixel; ImageTexture.create_from_image; uv1_scale, texture_filter; Dictionary; methods on your own script.
- Lineage: Processing: Handbook Image 1; LP ch15 Images and Pixels. NoC: none. Application: WP3 'pattern and world building' (in name). Klee: I.6 quantitative structure moving into two dimensions (the chessboard). Reference: Recreating the Past: Pattern (Bridget Riley, Anni Albers); The Book of Shaders 'Patterns' as a later return (ch27).
- **Departure:** tiling (spine 5) before color (spine 4): colour is taught late, where Klee ends his book (ch26); until then the two-colour palette stays supplied.
- Project step: Give your room one pattern of your own made from a 4x4 source.

#### 11. Disturbed order: chance enters the grid

- Spine: randomness (10). Halls: Randomness_10_PRINT_Algorithm (carrier); Random_Definition (carrier); Random_Remove (field trip); Random_Walk (field trip). Tracks: short, long.
- CODE new: random, seeds. Returns: nested_loops, instancing, classes, export, collision.
- BODY: Schotter as a floor: your chessboard of cubes rotated and displaced by a seeded RandomNumberGenerator, more with every row; and 10 PRINT as a walkable maze (one of two rotations per cell).
- ARGUMENT: axis *disorder amplitude (maximum rotation in the last row)*: 0 deg / 5 deg / 20 deg / 90 deg. Predict: 0 and 5 look most alike: the grid still reads. Somewhere between 5 and 20 it stops reading as a grid. Claim: *Randomness is visible only against a structure already built: the grid is what lets us see disorder.*
- DEBT: Computer randomness is pseudo-random: the same seed returns the same 'chance' (Random_Definition: a pattern that returns). Nake's question from Hommage a Paul Klee (1965): can a pseudo-random number stand in for intuition?
- PLACE: Walk down the Schotter floor until the disorder makes it unwalkable (the colliders follow the cubes); get lost in the 10 PRINT maze (10 PRINT's Maze Walker).
- Godot: RandomNumberGenerator, seed; randf_range, randi_range; per-instance rotation; the random-definition runnable kit.
- Lineage: Processing: LP ch4 random(); Handbook Math 4 Random. NoC: ch0 Randomness. Application: WP1 Basic Elements: randomness. Klee: absent from Klee: the lineage's first departure. Reference: Frieder Nake, Hommage a Paul Klee 13/9/65 Nr. 2; Georg Nees, Schotter (1968); Vera Molnar, (Des)Ordres; 10 PRINT 'Regularity before Randomness'.
- **Departure:** randomness (spine 10) is met a third of the way in: it enters Klee's lineage in 1965-68 as the disturbance of a grid already built (Nake, Nees, Molnar); the 2023 application puts it in WP1, Queer 3D's foundation asks 'what is randomness' first, and Code as Creative Medium places Unpredictability right after iteration. It returns as a game (ch21) and as noise (ch25, ch28).
- Project step: Add a seeded disorder axis to your family and record the seed you keep.

#### 12. The organism: bone, tendon, muscle

- Spine: transformation (2). Halls: Trans_Rotation (carrier); Trans_Body (carrier); Trans_Translation (field trip); Trans_Pre (field trip). Tracks: short, long.
- CODE new: transforms, basis, delta. Returns: vectors, classes, export, lifecycle, instancing.
- BODY: A limb of three segments as a parent-child chain with pivots, each joint turning by angle += speed * delta in _process (the course's first moving body); and Trans_Body's lattice that loses cells where a body passes.
- ARGUMENT: axis *where the pivot sits on each segment*: at the end / at one third / at the centre / outside the segment. Predict: 'at the end' and 'at one third' look most alike after 30 degrees; 'outside' makes the chain orbit instead of bend. Claim: *A body's motion is decided by where its joints are, not by what its parts look like.*
- DEBT: Klee maps active, medial and passive onto brain, muscle and bone, and onto male and female organs (I.9-12, verified in the Praeger text). The scene tree encodes the same command chain: the parent moves the child, never the reverse. Klee in drag starts here: make the passive bone drive (inverse kinematics follows in ch16).
- PLACE: Become it: attach the chain to your hand (headset) or the carried point and walk it through Trans_Body's lattice, carving a passage with your own movement ('chip from chip').
- Godot: Node3D hierarchy, transform, basis; rotate_object_local; pivots as parent nodes; _process(delta); to_global / to_local.
- Lineage: Processing: LP ch14 Transformations; Handbook Transform 1-2. NoC: ch3 Oscillation (angular motion, preview). Application: pre-WP. Klee: I.9-12 bone, ligament, tendon and muscle; active/medial/passive; 'stone upon stone' against 'chip from chip'. Reference: Gaboury, Image Objects IV 'Object Paradigms'; Processing Handbook's static-before-continuous order.
- **Departure:** transformation (spine 2) comes after arrays, tiling and chance: Klee's organism follows structure (I.9 after I.5-8) and Form+Code puts Transform after Repeat; the still bodies of Part I needed only position. It also opens _process(delta) only now, as the Processing Handbook opens 'continuous' in its second part.
- Project step: Give one body in your room a jointed part that moves.

#### 13. Collage: a found body meets a made one

- Spine: primitives (1). Halls: Primitives_Melencolia (carrier). Tracks: short, long.
- CODE new: import_assets, export_build, ai_assist. Returns: classes, export, meshes, surface_tool, transforms, errors.
- BODY: Recreate a precedent: the truncated solid of Durer's Melencolia I built procedurally, beside a body you scanned or drew in Tilt Brush or Blender and imported as glTF; one of the two is written with an AI assistant under the LeWitt protocol (you write the instruction, it writes the code, you check the wall).
- ARGUMENT: axis *how the body was made*: hand-coded / AI-coded from your instruction / scanned / sculpted in VR. Predict: The hand-coded and the AI-coded look most alike (same instruction, same primitives); the scan is the outlier by triangle count, not by silhouette. Claim: *How a body was made shows less in its silhouette than in its triangle count and its errors.*
- DEBT: Recreation (SFPC Recreating the Past): the difference between Durer's solid and yours is where the debt is written; the Melencolia hall already says its hidden surfaces 'are decisions we have made'. The AI's code guessed wherever your instruction was ambiguous. The scan has millions of triangles, holes and no inside; whose bodies get scanned?
- PLACE: A hybrid room (Queer 3D's ontology layer): imported and procedural bodies share one floor. Export a desktop build and show it, sharing early as Anthropy's Twine book does in its first chapter.
- Godot: glTF import and import settings; fixing scale and origin; Export dialog, templates, a desktop build; directing and checking generated GDScript: what should change, what must not, what observation would show it is wrong.
- Lineage: Processing: Handbook Synthesis 1 'Form and Code'. NoC: none. Application: the application's commons (open, repair, change: Illich, Freire). Klee: I.12 additive and subtractive making, 'both time bound'. Reference: Hannah Hoch and Bellmer (collage, Queer 3D 2024); the ReCode Project; LeWitt protocol for ai_assist; Durer, Melencolia I.
- **Departure:** A deliberate return to the last primitives hall (Melencolia, spine 1) as Part II's synthesis; it closes the teaching half of the short track, which pivots into the mini project here.
- Project step: SYNTHESIS II and the short track's pivot: export your room as a build with one found and one made body. The mini project starts from this build.

### Dimension and balance (Klee II)

#### 14. Eye level: the vertical axis moves with you

- Spine: transformation (2). Halls: Trans_Scale (carrier); Escher_Impossible (field trip). Tracks: long.
- CODE new: camera, input. Returns: transforms, loops, instancing, vectors.
- BODY: Railroad tracks: rails and ties made in a loop running to the horizon, seen by your own Camera3D whose height and field of view you change with input actions; a 'space box' is inserted at several depths.
- ARGUMENT: axis *eye height*: 0.3 m (crawling) / 1.1 m (seated, or a child) / 1.7 m (standing adult) / 8 m (bird). Predict: 1.1 and 1.7 look most alike (horizon mid-frame, ties converging alike); 8 m flips the tracks into a plan. Claim: *Perspective is a fact about the eye's height, not about the tracks: the same geometry gives a plan or a corridor.*
- DEBT: The camera decides what exists (frustum, near plane; 'an iso view is half blind'), and VR's default height and IPD assume a standing adult body. Klee draws 'a house wall logically right but psychologically wrong'.
- PLACE: In the headset your head is the camera: crouch and the horizon moves with you. Trans_Scale scales the room by four and relocates you, so you are the scale that changed.
- Godot: Camera3D, fov, current; InputMap actions, Input.is_action_pressed; _unhandled_input; scaling a room vs moving the eye.
- Lineage: Processing: LP ch14 Transformations and 3D; Handbook Transform 2. NoC: none. Application: pre-WP. Klee: II.14-20 railroad ties and perspective, the vertical axis that shifts with the viewer, eye level, space boxes. Reference: Gaboury, Image Objects I (visibility); Queer Game Studies III (normativity in hardware).
- **Departure:** A second transformation hall after chance and the organism: Klee's dimension (II) follows structure and the organism (I).
- Project step: Choose the eye height your room is made for, and write why.

#### 15. The tightrope walker: balance

- Spine: formfinding (8). Halls: FormFinding_Equilibrium (carrier); FormFinding_Forge (carrier). Tracks: long.
- CODE new: physics_bodies, signals. Returns: loops, instancing, collision, transforms, conditions.
- BODY: A stack of RigidBody3D blocks built in a loop with an offset per block (a tower whose pivots zig-zag around the vertical, Klee II.25), a mobile hung with joints (its recursive builder supplied), and a signal when the stack settles or falls.
- ARGUMENT: axis *centre-of-mass offset per block (fraction of block width)*: 0 / 0.1 / 0.3 / 0.5. Predict: 0 and 0.1 look most alike after settling (both stand); 0.3 leans and stands; 0.5 falls. Claim: *A body stands while its centre of mass is over its base: Klee's non-symmetrical balance is an equivalence of unequal parts, not a symmetry.*
- DEBT: Stability is a setting: solver iterations, sleep thresholds and the physics tick change the verdict (in this project a die read 15 of 16 at 90 Hz and 2 of 16 at 60 Hz). The engine's gravity is a global default nobody chose.
- PLACE: Stack the blocks with your own hands (XR pickables) until the tower holds; walk under the mobile.
- Godot: RigidBody3D, mass, center_of_mass, sleeping; signal, emit, connect; HingeJoint3D (supplied); physics ticks per second.
- Lineage: Processing: Handbook Simulate 2 Physics (preview). NoC: ch6 Physics Libraries (2024 order). Application: pre-WP (Ada-only formfinding). Klee: II.21-25 the tightrope walker 'is the scale'; non-symmetrical balance; disturbed and restored balance. Reference: Moholy-Nagy's Vorkurs balance studies (c. 1924).
- **Departure:** formfinding (spine 8) before forces (spine 7): Klee's balance (II) precedes the gravitational curve (III). Stand the body before you push it: here the engine's gravity does the work; in Part IV you write gravity yourself.
- Project step: Make one body in your room that must balance, and predict whether it holds.

#### 16. Legs: the passive part drives

- Spine: forces (7). Halls: VFM_09_Legs (carrier); Trans_Pit (field trip). Tracks: long.
- CODE new: raycasts. Returns: physics_bodies, transforms, basis, loops, signals.
- BODY: A plate on procedural legs: each foot finds the ground with a raycast and each leg chain is solved from the foot back to the hip (FABRIK), reversing Chapter 12's parent-child command.
- ARGUMENT: axis *number of legs under the same off-centre plate*: 2 / 3 / 4 / 6. Predict: 4 and 6 look most alike (both hold: their convex hull contains the centre of mass); 2 tips; 3 depends on where the centre sits. Claim: *Whether a body stands is decided by the convex hull of its feet, so the number of legs is an argument, not a style.*
- DEBT: Inverse kinematics lets the passive end (the foot, Klee's bone) drive the chain: the scene tree's hierarchy of command is a convention you can invert. IK also approximates (iterations, joint limits), and a leg finds only what its ray hits.
- PLACE: Walk your legged body across Trans_Pit's moving blocks; its feet re-plant as the ground moves.
- Godot: RayCast3D / intersect_ray; Geometry2D.convex_hull; a FABRIK solver (supplied, then opened); collision layers.
- Lineage: Processing: none. NoC: ch5 Autonomous Agents (steering, preview). Application: WP2 organic bodies (preview). Klee: II.25 stumbling; I.9 bone as the passive organ, reversed. Reference: Klee in drag (active and passive re-assigned); Critical Engineering Manifesto 6 (the machine includes bodies).
- **Departure:** A forces hall (spine 7) visited before the rest of forces: tip-or-hold belongs with balance, which is Klee's order.
- Project step: SYNTHESIS III: a body in your room that finds its own footing.

### The gravitational curve (Klee III)

#### 17. The bullet: a curve made of steps

- Spine: change (6), forces (7). Halls: Change_Intro (carrier); VFM_05_Launch (carrier). Tracks: long.
- CODE new: integration. Returns: delta, vectors, loops, arrays, meshes.
- BODY: A thrown body whose path you integrate yourself (velocity += gravity * dt; position += velocity * dt), drawn as a predicted arc of 64 samples beside a plot of height against time; Change_Intro's Riemann sum is the same loop.
- ARGUMENT: axis *integration time step*: 1/10 s / 1/30 s / 1/60 s / 1/240 s. Predict: 1/60 and 1/240 look most alike; 1/10 lands visibly off the true parabola. Claim: *A computed trajectory is a sum of steps: the curve is the limit the steps approach, and a coarse step draws a different throw.*
- DEBT: Euler integration owes the curve its accuracy, and the frame rate becomes physics (delta vs a fixed step). The smooth curve you see is a polygon of decisions.
- PLACE: Throw it yourself (XR release velocity or a desktop launch) and stand where your prediction says it lands.
- Godot: _physics_process and a fixed step; an ImmediateMesh polyline; Engine.physics_ticks_per_second.
- Lineage: Processing: Handbook Motion 1 Lines, Curves. NoC: ch1 Vectors (velocity); ch2 Forces (gravity). Application: pre-WP. Klee: III.26-30 'a bullet, fired at a steep angle, rises ... and falls to earth with accelerated energy'. Reference: Change_Intro's secant and Riemann sum; Lague's naive-attempt-first form.
- **Departure:** change (spine 6) after formfinding: the curve follows balance, as Klee's gravitational curve (III) follows balance (II).
- Project step: Something in your room is thrown or falls along a curve you computed.

#### 18. Regions with different laws

- Spine: forces (7). Halls: Vectors_Act4a_KineticForces (carrier); Vectors_Act5_ForceAsPlace (carrier); VFM_03_Motion (field trip). Tracks: long.
- CODE new: forces, areas. Returns: physics_bodies, integration, vectors, signals.
- BODY: A balloon rising through stacked air strata: Area3D regions that each replace gravity and add drag (-b * velocity) for any body inside, applied with apply_central_force.
- ARGUMENT: axis *drag of the medium*: vacuum b=0 / air b=0.1 / water b=2 / honey b=10. Predict: Vacuum and air look most alike over a short throw; water and honey both end in near-vertical falls. Claim: *A trajectory is a portrait of its medium, not of its thrower.*
- DEBT: Who writes the law? ProjectSettings holds one gravity for the world and an Area3D overrides it locally; linear drag is a guess at what real fluids do.
- PLACE: Walk into a region yourself: the player's gravity changes inside it (Klee's swimmer between water and air).
- Godot: apply_central_force, linear_damp; Area3D gravity_space_override; body_entered / body_exited.
- Lineage: Processing: Handbook Simulate 2 Physics. NoC: ch2 Forces (friction, drag). Application: pre-WP. Klee: III.26-29 earth, water and air as 'regions with different laws'; the swimmer; the balloon. Reference: Vectors_Act5 'force as place'.
- Project step: Give your room one region where the law is different.

#### 19. The stair climber: the player opened

- Spine: forces (7), wavefunctions (9). Halls: Wavefunctions_Sky_Stairs (carrier); Trans_Introduction (field trip). Tracks: long.
- CODE new: player, composition. Returns: physics_bodies, collision, input, camera, xr, classes.
- BODY: Stairs generated from a function (tread heights rising step by step, colliders matching), and your own CharacterBody3D: a controller node with a separate skin you can swap (the capsule, a member of your family, the XR rig).
- ARGUMENT: axis *step height against the player's step*: 0.1 m / 0.25 m / 0.4 m / 0.6 m. Predict: 0.1 and 0.25 look most alike in the still (the player standing at the top of both); at 0.4 the capsule is stuck at the bottom. Claim: *A stair is an agreement between a function and a body's step: the same function makes a path or a wall depending on who climbs.*
- DEBT: Critique the starter (Montfort, 'Critique My Starter Programs'): the capsule is every tutorial's default human, as the Utah teapot is the default object (Gaboury ch3). What body does it assume, and what do VR comfort defaults (snap turn, vignette) assume?
- PLACE: Climb it with the desktop skin, then swap the skin for the XR body in the headset; the controller does not change.
- Godot: CharacterBody3D, velocity, move_and_slide; floor_snap_length and steps; skin vs controller as composition; swapping the desktop rig for the XR rig.
- Lineage: Processing: none. NoC: ch2 Forces on a controlled body. Application: pre-WP. Klee: III.28 'a climber of stairs, ascending with increasing energy from step to step (rigid continuity)'. Reference: GDQuest Learn 3D Gamedev module 7 (skin vs controller); Godot's Squash the Creeps player; Montfort, Exploratory Programming ch7.
- **Departure:** A wavefunctions hall (spine 9) visited early: the stair is a function made walkable, and the player belongs where Klee has the stair climber (III).
- Project step: Replace the supplied walker in your room with your own controller and one skin.

#### 20. The meteor: an orbit that leaks

- Spine: forces (7). Halls: VFM_07_Gravity (carrier); Vectors_Act3_FieldsAndMotion (carrier). Tracks: long.
- CODE new: testing, debugging. Returns: integration, forces, arrays, loops, camera.
- BODY: A small n-body system (a planet and a meteor deflected by it) stepped over an array of bodies; a headless test asserts that energy stays within a tolerance, and the debugger steps the integrator when it does not.
- ARGUMENT: axis *integrator*: explicit Euler / semi-implicit Euler / velocity Verlet / velocity Verlet at half the step. Predict: The two Verlet runs look most alike (closed orbits); explicit Euler spirals outward. Claim: *An orbit drawn by a computer is a property of its integrator: Euler invents energy, Verlet keeps it.*
- DEBT: The approximation owes energy: a planet that escapes is a numerical artefact, not physics. A test is an argument you can lose, and a green test on the wrong quantity is a recurring trap in this very project.
- PLACE: Ride the meteor: the camera follows it past the planet (become it).
- Godot: a headless test script, assert, push_error; breakpoints, the Debugger stack, stepping; an array of small classes or dictionaries.
- Lineage: Processing: Handbook Development 2 Iteration, Debugging. NoC: ch2 Forces (gravitational attraction). Application: WP4 chaos theory (preview). Klee: III.30-32 a meteor deflected by the earth, barely escaping 'the peril to be tied forever to the earth'. Reference: Montfort, Exploratory Programming ch4 ('valid and intentional are different').
- Project step: Add one test to your project that could fail.

#### 21. To stand despite all possibilities to fall: a round

- Spine: randomness (10), formfinding (8). Halls: Random_Game (carrier); Random_Cubes (field trip); FormFinding_Forge (field trip). Tracks: long.
- CODE new: state_machines, ui, save_load. Returns: random, seeds, player, signals, physics_bodies, input.
- BODY: A small complete game on Klee's axiom: stones that stand or sink after seeded random waits, a player who must stay upright, menu / play / fall / score as an enum state machine, a HUD, and the best time saved to user://.
- ARGUMENT: axis *warning time before a stone sinks*: 0 s / 0.3 s / 1 s / 3 s. Predict: 1 s and 3 s look most alike in a still (rings visible, player standing); 0 s shows a fallen player. Claim: *Fairness in a chance game is visible: the telegraph turns randomness into something a body can answer.*
- DEBT: Seeded chance can be replayed and therefore learned: is the game random or a memory test? The score reduces a body's play to one number (Queer Game Studies IV on failure).
- PLACE: Play it on the desktop, then in the headset: stand despite all possibilities to fall.
- Godot: enum + match state machine; Control, CanvasLayer HUD, Label, Button; FileAccess or ConfigFile in user://; Timer (supplied), scene reload.
- Lineage: Processing: LP ch10 Algorithms (a game taken apart). NoC: ch0 Randomness (return); the NoC course's midterm project. Application: WP1 randomness. Klee: Introduction axiom 'TO STAND DESPITE ALL POSSIBILITIES TO FALL!'. Reference: Squash the Creeps parts 7-8 (score, replay); Code as Creative Medium 'One-Button Game'.
- **Departure:** A return to randomness (spine 10) as the long track's midterm: the chance met in ch11 now drives a whole round, and the small-game kit (player, input, camera, ui, save) is complete.
- Project step: MIDTERM (long track): a round in your room that a visitor can lose and replay.

### Kinetic and chromatic energy (Klee IV; Albers)

#### 22. Top and pendulum: motion that returns

- Spine: wavefunctions (9). Halls: WaveFunctions_Intro (carrier); WaveFunctions_Pendulum (carrier); Vectors_Act4b_Oscillation (field trip). Tracks: long.
- CODE new: trig, queues. Returns: integration, delta, arrays, signals, meshes.
- BODY: A pendulum stepped in _physics_process (the restoring force from sin of the angle) that records its bob into a bounded queue drawn on moving 'paper', so time becomes space.
- ARGUMENT: axis *pendulum length*: 0.25 m / 0.5 m / 1 m / 2 m. Predict: Every doubling stretches the trace by the same factor (the square root of 2), so no pair is closest in ratio; in absolute wavelength the two short ones look most alike. Claim: *Period grows with the square root of length: the trace shows a law you cannot see in the swing.*
- DEBT: The small-angle formula is an approximation, and the numerical pendulum drifts (energy again). Klee's spinning top may fall in the engine anyway, since solver gyroscopics are approximate [mem: test it].
- PLACE: Stand under a 2 m pendulum and swing it by hand; its trace is drawn beside you.
- Godot: sin, cos, TAU, deg_to_rad; a bounded queue: push_back and pop_front; a signal on the zero crossing.
- Lineage: Processing: Handbook Math 3 Trigonometry; LP ch13 Mathematics. NoC: ch3 Oscillation. Application: WP1 sine curves and resonance frequencies. Klee: IV.33-35 the spinning top; the pendulum, 'motion and counter-motion'. Reference: Klee IV (the pendulum opens Part IV, not the gravity part); John Whitney in Recreating the Past.
- Project step: One thing in your room swings, and its trace is recorded.

#### 23. Circle and spiral: the question of life and death

- Spine: wavefunctions (9), fractals (14). Halls: WaveFunctions_Unit_Circle (carrier); Change_Choreography (field trip); Fractal_GoldenSpiral (field trip). Tracks: long.
- CODE new: multimesh. Returns: trig, loops, transforms, surface_tool, collision.
- BODY: The pendulum freed from gravity: a runner at (cos t, sin t); then the radius changes every turn, 2000 points along the spiral are drawn as one MultiMesh, and a walkable spiral ramp is built from the same function.
- ARGUMENT: axis *radius change per turn*: -20% / 0 / +20% / x1.618 per quarter turn (golden). Predict: 0 and -20% look most alike in the first turn, but -20% dies in the centre; +20% and golden look alike until the third turn. Claim: *The sign of one number decides between the circle, the spiral that dies in the centre and the spiral that frees itself.*
- DEBT: Motion 'no longer finite' must be cut off, so the spiral needs a stop condition. The golden spiral carries a myth of nature's law: Fibonacci as norm is a claim to test, not to teach. One MultiMesh instead of 2000 nodes: the frame budget is also a debt.
- PLACE: Walk the spiral ramp inward toward the static centre, or outward until it lets you go.
- Godot: a parametric curve from cos and sin; MultiMeshInstance3D, set_instance_transform; a glimpse of frame time in the Profiler.
- Lineage: Processing: Handbook Math 3; Form+Code Parameterize (Wave). NoC: ch3 Oscillation (polar coordinates). Application: WP1 Fibonacci. Klee: IV.35-36 the circle, 'the purest of mobile forms'; the spiral, 'the question of life and death; and the decision rests with the small arrow'. Reference: The Book of Shaders, shaping functions.
- **Departure:** Fractal_GoldenSpiral (fractals, spine 14) is visited early as a field trip: Klee derives the spiral from the pendulum. The golden section returns with recursion in ch30.
- Project step: A spiral body in your room: choose the sign and defend it.

#### 24. Sound: the swing heard

- Spine: wavefunctions (9). Halls: WaveFunctions_Effect_Sound (carrier); WaveFunctions_AirMusic (carrier); WaveFunctions_Synthesis_Lab (field trip); WaveFunctions_John_Cage (field trip). Tracks: long.
- CODE new: audio, packed_arrays. Returns: trig, loops, areas, signals, multimesh.
- BODY: An instrument whose shape is its waveform: a row of bars whose heights are one period of the samples you write into a PackedByteArray and play as an AudioStreamWAV when a hand strikes it.
- ARGUMENT: axis *waveform*: sine / triangle / square / noise. Predict: Sine and triangle look (and sound) most alike; square and noise are outliers in different ways. Claim: *The shape you see is the timbre you hear: corners are overtones.*
- DEBT: Sampling rate and bit depth make the wave discrete; the square's corners alias; additive synthesis (Synthesis_Lab) is Fourier's claim that every shape is a sum of circles.
- PLACE: Strike the bars with your hands (Area3D contact, speed to volume): become the player of the body.
- Godot: AudioStreamWAV, PackedByteArray.encode_s16; AudioStreamPlayer3D, volume_db; AudioServer buses (glimpse).
- Lineage: Processing: Handbook Extension: Sound. NoC: ch3 Oscillation (waves). Application: WP1 sound experiments and resonance; WP2 Fourier transforms. Klee: I.5 rhythm; the sketchbook's musical composition. Reference: John Cage (chance) as a field trip; Levin and Brain, 'Synesthetic Instrument'.
- Project step: Your room makes one sound that is computed, not imported.

#### 25. The arrow and the field of arrows

- Spine: change (6), noise (11). Halls: Flow_Field (carrier); Vectors_Act1_WhatAVectorIs (field trip); Noise_Columns (field trip). Tracks: long.
- CODE new: noise, particles, lifetime. Returns: random, seeds, vectors, forces, areas, multimesh.
- BODY: An arrow in every cell of a grid whose angle is read from FastNoiseLite; particles are born, follow the arrows, leave trails and die, so bodies are drawn by the field.
- ARGUMENT: axis *source of the arrows*: one constant direction / random per cell / noise, frequency 0.02 / noise, frequency 0.2. Predict: 'random per cell' and 'noise 0.2' look most alike (neighbours disagree, trails tangle); only low-frequency noise makes rivers. Claim: *Noise is randomness with neighbours: trails form only where nearby arrows agree.*
- DEBT: The blob aesthetic starts here: the smoothness of noise is a design decision (Perlin's noise was made for film images [mem]) that later reads as 'natural'. Particles must die or the frame dies: lifetime is a budget.
- PLACE: Walk into the field as a particle: an Area3D pushes you along the local arrow.
- Godot: FastNoiseLite, get_noise_2d, frequency, seed; GPUParticles3D or your own particles; lifetime and queue_free.
- Lineage: Processing: LP ch13 noise(). NoC: ch4 Particle Systems; flow-field following in ch5. Application: WP1 Perlin noise and particle systems; WP2 flow fields. Klee: IV.37-38 the arrow: shaft, point, rudder; 'the father of the arrow is the thought: how do I expand my reach?'. Reference: Klee IV.37-38; Code as Creative Medium 'Unpredictability' (noise).
- **Departure:** Flow_Field (change, spine 6) comes after the wave sequence, and noise (spine 11) is first met here: NoC puts flow fields after noise, and Klee's arrow closes his kinetic part. Noise returns as ground in ch28.
- Project step: Something in your room is moved by a field.

#### 26. A colour has many faces

- Spine: color (4). Halls: Color_Walls (carrier); Color_Flashlight (carrier); Color_Paint (field trip); Color_Rainbow (field trip); Color_Context_Placed (field trip). Tracks: long.
- CODE new: resources, interpolation. Returns: materials, classes, export, loops, instancing.
- BODY: A strip of bodies coloured between two complementary colours by lerp in RGB and in HSV, from a palette saved as your own Resource (.tres) and shared by their materials; one albedo placed under two lamps.
- ARGUMENT: axis *path between two complementary colours*: RGB lerp / HSV lerp, short way / HSV lerp, long way / four stepped bands. Predict: RGB lerp and the stepped bands look most alike at a distance; RGB lerp passes through Klee's central grey, HSV through the colour circle. Claim: *The grey in the middle belongs to the RGB space, not to the colours: the same two ends give a grey or a rainbow.*
- DEBT: A colour is never one value: sRGB against linear, tone mapping, the lamp, the headset's display. Albers's universal eye and Klee's colour spiritualism are claims. A shared Resource makes every body change colour at once: the bug is the lesson in sharing.
- PLACE: Albers in a room: carry one body from a warm-lit to a cold-lit room (Color_Flashlight). Make one colour look like two, then find two bodies that look alike.
- Godot: Color, lerp, Color.from_hsv; a custom Resource with @export colours; ResourceSaver; duplicate() vs shared resources; SpotLight3D colour; Environment tonemap.
- Lineage: Processing: LP ch1 RGB; Handbook Color 1-2. NoC: none. Application: WP3 shading (colour). Klee: IV.39-43 black, hot, cold and green-red arrows; the central grey; the colour circle 'where all the arrows are superfluous'. Reference: Josef Albers, Interaction of Color (1963): one colour appears as two, two colours look alike (Color_Paint already cites Albers).
- **Departure:** color (spine 4) is taught late, because Klee's book ends in colour and Albers puts theory after experience. Since ch8 you have worked with a supplied fixed palette (Albers's coloured paper); now the palette becomes yours.
- Project step: Replace the supplied palette with your own Resource; make one colour in your room look like two.

#### 27. The pixel's colour circle: shaders

- Spine: shaders (12). Halls: Shader_01_Shaping (carrier); Shader_11_QueerRubber (carrier); Shader_05_Patterns (field trip); Shader_09_FBM (field trip); Shader_12_PinkExtravaganza (encounter). Tracks: long.
- CODE new: shaders, uniforms. Returns: uv, interpolation, materials, trig, normals.
- BODY: The colour circle as a surface: a spatial shader that computes hue per pixel; then a fresnel rim from dot(NORMAL, VIEW) on a rubber body, with uniforms set from GDScript.
- ARGUMENT: axis *what drives the hue*: UV angle / world height / surface normal / view angle (fresnel). Predict: Normal and view angle look most alike on a sphere seen head-on; they separate as you walk around it. Claim: *A colour that depends on the viewer is a different kind of body from one that depends on its own surface.*
- DEBT: The GPU as 'procedure crystallized' (Gaboury ch5): per-pixel parallelism fixes what can be asked. Shader deformation does not move collision (Shader_09_FBM): the body you see and the body you meet part ways.
- PLACE: Walk around the rubber body: its colour follows you (become the light).
- Godot: ShaderMaterial, shader_type spatial, fragment(); ALBEDO, EMISSION, NORMAL, VIEW, UV, TIME; uniform with hint_range; set_shader_parameter.
- Lineage: Processing: PShader; Handbook 2nd ed. Render Techniques [agg]. NoC: none. Application: WP3 shading algorithms. Klee: IV.43 the spectral colour circle. Reference: The Book of Shaders ch5-7; Inigo Quilez; Gaboury V 'Procedure Crystallized'.
- Project step: SYNTHESIS V: one body in your room whose colour is computed per pixel.

### Out of the sketchbook: bodies in drag (spine 11-25)

#### 28. Noise as ground: the blob aesthetic

- Spine: noise (11). Halls: Noise_Space_10 (carrier); Noise_Perlin_Simplex (carrier); Noise_Voxel (field trip); Random_Noise_Types (field trip). Tracks: long.
- CODE new: setters, tool_scripts. Returns: noise, packed_arrays, surface_tool, collision, export, resources, player.
- BODY: A walkable noise terrain: FastNoiseLite sampled on a grid into one PackedVector3Array that feeds both an ArrayMesh and its ConcavePolygonShape3D; @export setters rebuild it live and @tool shows it in the editor.
- ARGUMENT: axis *noise type at the same frequency*: value / Perlin / simplex / cellular. Predict: Perlin and simplex look most alike at walking scale (they differ in grid artefacts, not landscape); cellular is another body. Claim: *Noise types are one family of blob, except cellular: what differs is the artefact, not the ground.*
- DEBT: The blob aesthetic (Queer 3D): noise produced a look that now reads as 'nature'. Palle's own overflow-rate comparison (Perlin 45, random 635, Voronoi 0, sine space 3284) shows that choosing a field is choosing what escapes.
- PLACE: Walk the terrain and find the slope where your player can no longer climb (ch19 returns).
- Godot: @tool; @export with a setter and a deferred rebuild; ArrayMesh, ConcavePolygonShape3D; FastNoiseLite as a shared Resource.
- Lineage: Processing: LP ch13 noise(). NoC: ch0 Perlin noise. Application: WP1 Perlin noise and Voronoi diagrams. Klee: beyond the sketchbook (I.13 the eye 'grazes' the surface). Reference: Queer 3D 2024 (blob aesthetic, overflow rates); Catlike Coding, Pseudorandom Noise (hash quality).
- **Departure:** noise (spine 11) after shaders (spine 12): noise was first met as a field of arrows (ch25); as ground it is taught here, where the shader chapter lets you compare CPU noise with Shader_09_FBM's fBm.
- Project step: The ground of your room becomes generated and editable in the editor.

#### 29. Rules in time: cellular automata

- Spine: cellularautomata (13). Halls: CA_Introduction (carrier); CA_GameOfLife (carrier); CA_EdgeOfChaos (field trip); CA_SoftRules (field trip). Tracks: long.
- CODE new: buffers. Returns: arrays, packed_arrays, loops, conditions, collision, multimesh.
- BODY: A one-dimensional automaton written into two buffers (current and next, swapped each step), its history stacked row by row into a floor of collidable cells.
- ARGUMENT: axis *rule number*: 30 / 90 / 110 / 184. Predict: 30 and 110 look most alike (both irregular); 90 is a clean Sierpinski triangle and 184 flows like traffic. Claim: *Eight bits of rule decide between order, fractal, chaos and flow: complexity lives in the rule table, not in the cells.*
- DEBT: Determinism can look like chance (rule 30 has served as a random generator [mem]); 'complexity from simple rules' hides who chose the rule and the edges (wrap or wall).
- PLACE: Walk on the history floor: the rule's gaps are holes you fall through (CA_GameOfLife's walkable history).
- Godot: two buffers swapped per step; (i - 1 + n) % n wrap; (rule >> k) & 1; rows as MultiMesh or StaticBody3D.
- Lineage: Processing: Handbook Simulate 1 Biology (Life). NoC: ch7 Cellular Automata. Application: WP2 cellular automata; WP4 chaos. Klee: beyond the sketchbook (I.5 rhythm as rule). Reference: LeWitt: the instruction as the work, run by a machine.
- Project step: A floor or wall in your room grows by a rule you can name in one number.

#### 30. The tree and its mad branch: recursion

- Spine: fractals (14). Halls: Fractal_RecursiveTrees (carrier); Fractal_Recursion (carrier); Fractal_CantorSet (field trip); Fractal_MengerSponge (field trip). Tracks: long.
- CODE new: recursion. Returns: functions, parameters, transforms, random, seeds, multimesh, errors.
- BODY: Munari's tree as a recursive function: the trunk splits in two, each branch thinner by a ratio, until a base case; a seeded 'mad branch' breaks the rule once.
- ARGUMENT: axis *thinning ratio*: 0.5 / 0.6 / 0.7 / 0.8. Predict: 0.7 and 0.8 look most alike in silhouette (both dense crowns); 0.5 reads as a bare fork. Claim: *The ratio, not the depth, decides whether a tree reads as a tree; the mad branch shows that the family survives its exception.*
- DEBT: 'Recursion must always be controlled' (Queer 3D): without a base case the stack overflows (the planted bug) and the frame freezes; an explicit-stack version with a per-frame budget is the repair. Botanical naturalness as a norm; the mad branch as a queer reading.
- PLACE: Walk the Cantor bridge (the removed thirds are ghosts: ch3 returns) and stand under your tree.
- Godot: a recursive func with a base case; the stack-overflow error; an explicit Array stack rewrite; a MultiMesh of branch segments.
- Lineage: Processing: Handbook Shape 3 Recursion; Form+Code Recursive Tree. NoC: ch8 Fractals. Application: WP2 fractal subdivision. Klee: I.7 the golden section (returns). Reference: Bruno Munari, Drawing a Tree (1978); Kawaguchi's growth bodies (Queer 3D lineage).
- Project step: A grown body in your room with a stop condition you can defend.

#### 31. The point walks again: grammars and the turtle

- Spine: lsystems (15). Halls: LSystems_Grammar_Lab (carrier); LSystems_Growth (carrier); LSystems_Architecture (field trip); LSystems_Shape_Grammars (field trip). Tracks: long.
- CODE new: strings, stacks. Returns: dictionaries, loops, recursion, meshes, transforms, player.
- BODY: A string rewritten by rules (F -> F[+F]F[-F]F) and read by a turtle that walks and draws, pushing and popping its state on a stack at [ and ]; then the turtle's path becomes walkable corridors.
- ARGUMENT: axis *turn angle*: 22.5 deg / 25.7 deg / 60 deg / 90 deg. Predict: 22.5 and 25.7 look most alike (both plants); 90 turns the same grammar into architecture. Claim: *One grammar is many bodies: the angle decides whether it reads as plant, snowflake or building.*
- DEBT: Strings explode, so a symbol budget is needed; Lindenmayer's botany naturalises the grammar; the turtle is Klee's walking point made obedient.
- PLACE: Walk the L-system corridors (LSystems_Architecture) at a clear width tested with your own player.
- Godot: String building, for c in s; Dictionary of rules; push_back / pop_back as a stack; an ImmediateMesh turtle.
- Lineage: Processing: Handbook Shape 3. NoC: ch8 L-systems. Application: WP2 L-systems. Klee: I.1 the walk, returned as grammar. Reference: Logo's turtle; Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants [mem].
- Project step: A grammar of your own draws one element of your room.

#### 32. How do we navigate an auto-generated world?

- Spine: proceduralgeneration (16), graphtheory (22). Halls: PG_Caves_Mazes (carrier); GT_Pathfinding (carrier); GT_Spanning_Trees (field trip); Randomness_10_PRINT_Algorithm (field trip). Tracks: long.
- CODE new: graphs, search, navigation. Returns: arrays, dictionaries, stacks, queues, random, seeds, player, collision.
- BODY: A maze generated as a graph (cells as nodes, open walls as edges) by depth-first backtracking and built as walls with colliders; a path searched with BFS or AStar3D; a NavigationAgent3D with the player's radius sent through.
- ARGUMENT: axis *maze algorithm*: DFS backtracker / Kruskal spanning tree / 10 PRINT random / cellular cave. Predict: DFS and Kruskal look most alike from above (both perfect mazes), but DFS makes long corridors and Kruskal many short dead ends. Claim: *Each generator has a signature texture you can see from above and a different experience you can only walk.*
- DEBT: The navigation mesh assumes one body radius (the capsule again); the shortest path is the norm of every search; a route in the array is not a route for a body.
- PLACE: Get lost in it, then follow your own search's path; send an agent with a wider body and watch it fail.
- Godot: a graph as neighbour lists; BFS with a queue; AStar3D; NavigationRegion3D bake, NavigationAgent3D.
- Lineage: Processing: none. NoC: ch5 path following. Application: WP3 graph theory and procedural generation: 'How do we navigate an auto-generated world?'. Klee: beyond the sketchbook. Reference: 10 PRINT 'Maze Walker'; Chun, Discriminating Data (homophily) [mem].
- **Departure:** graphtheory (spine 22) is pulled forward into procedural generation (spine 16): the application's WP3 puts graph theory with world building, and a maze needs a graph.
- Project step: Your room gets a generated passage a visitor must find their way through.

#### 33. Soft bodies: the organism returns

- Spine: softbodies (17), formfinding (8). Halls: SoftBodies_Soft_Body_Deformation (carrier); FormFinding_Relaxation (carrier); SoftBodies_Cloth_Physics (field trip); SoftBodies_Playground_of_Joy (encounter). Tracks: long.
- CODE new: profiling. Returns: integration, physics_bodies, classes, export, packed_arrays, xr.
- BODY: A mass-spring body you step yourself (Verlet points and distance constraints), then the same shape as a SoftBody3D with pinned points; subdivision is the family axis and the profiler measures each member.
- ARGUMENT: axis *subdivision of the same box*: 2 / 4 / 8 / 16. Predict: 8 and 16 look most alike when pressed; 2 cannot bend at all, it can only tilt. Claim: *A body can only bend where it has vertices: polycount is the body's capacity for deformation, and every vertex costs frame time.*
- DEBT: Polycount against smooth deformation (the application's topology question), measured instead of asserted; solver instability; 'joy' as a design claim (SoftBodies_Affect_Theory_Visualization).
- PLACE: Push into it with your hands; walk through soft walls that narrow below your width (SoftBodies_Obsticals).
- Godot: Verlet by hand, distance constraints; SoftBody3D, set_point_pinned, simulation_precision; Profiler and Performance monitors; frame time at 72 / 90 Hz.
- Lineage: Processing: Handbook Simulate 2 (springs). NoC: ch6 Physics Libraries (the ITP course's soft-body week). Application: WP2 soft body simulation (cloth, liquids, rubber). Klee: I.9 ligament 'a fibrous web'; tendon. Reference: Moholy-Nagy's material studies.
- Project step: A body in your room you can deform, with its frame cost measured.

#### 34. Stone upon stone, chip from chip: implicit and boolean bodies

- Spine: isosurfaces (18), boolean_surfaces (19). Halls: ISO_Introduction (carrier); ISO_Metaballs (carrier); ISO_LookupTable (field trip); Boolean_Verbs (carrier); ISO_Sculpting (encounter). Tracks: long.
- CODE new: threads. Returns: noise, nested_loops, surface_tool, normals, arrays, tool_scripts, profiling.
- BODY: A body defined by a density function (metaballs joined by a smooth minimum) and extracted with marching cubes from a supplied lookup table, rebuilt on a worker thread; then the same body as a CSG union, intersection and difference.
- ARGUMENT: axis *blend radius k of the smooth minimum*: 0 / 0.2 / 0.5 / 1.0. Predict: 0 and 0.2 look most alike (two bodies touching); somewhere before 0.5 a neck appears and two sources become one body. Claim: *The blob look is one parameter: the neck between sources appears at a threshold you can predict.*
- DEBT: The lookup table is supplied, so seeing the code still hides something (Chun's 'sourcery'). Code-critique station: read 30 lines of Ada's own table code and write a debt comment into yours (after Marino's readings of Kittler's raytracer and the Climategate comment). Ambiguous cases leave holes; CSG leaves z-fighting and frame cost; Klee: building and reducing are both 'time bound'.
- PLACE: Sculpt with your hands (ISO_Sculpting) and carve a burrow with CSG subtraction you can crawl into.
- Godot: density(p) and a triple loop to a bitmask; a supplied marching-cubes table; WorkerThreadPool and waiting for the task; CSGCombiner3D, use_collision, baking CSG to a mesh.
- Lineage: Processing: none. NoC: none. Application: WP2 'queer meshes'; WP3 procedural generation. Klee: I.12 the work grows 'stone upon stone' (additive) or is hewn 'chip from chip' (subtractive). Reference: Sebastian Lague, Marching Cubes (and his Godot-Marching-Cubes repo); Inigo Quilez, smooth minimum; Marino, Critical Code Studies ch6.
- Project step: A sculpted or carved body in your room, with one debt comment in its code.

#### 35. Many bodies with rules: swarms

- Spine: swarmintelligence (20). Halls: SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_Swarm_Intelligence_Algorithms (carrier); SwarmIntelligence_PhysarumColony (field trip). Tracks: long.
- CODE new: inheritance, groups. Returns: classes, vectors, multimesh, profiling, random, player.
- BODY: Boids from a base class Agent (separation, alignment, cohesion) extended by subclasses: first one node per boid in a group, then one MultiMesh with a spatial hash.
- ARGUMENT: axis *alignment weight*: 0 / 0.5 / 1 / 2. Predict: 1 and 2 look most alike (one stream); 0 is a cloud. Claim: *A flock is one weight away from a crowd: alignment turns many bodies into one.*
- DEBT: The collective as an average: alignment is conformity made numeric; emergence rhetoric hides three hand-tuned weights; the frame budget decides how many bodies may exist.
- PLACE: Be a predator or an attractor: the swarm reacts to your body.
- Godot: class_name + extends, super(); add_to_group, get_nodes_in_group; a spatial hash; MultiMesh updates per frame.
- Lineage: Processing: Handbook Structure 5 Objects II. NoC: ch5 Autonomous Agents (flocking). Application: WP4 swarm intelligence. Klee: beyond the sketchbook. Reference: Craig Reynolds, Boids [mem]; Lague, Slime Simulation.
- Project step: Your room is inhabited by a collective body.

#### 36. Bodies that learn

- Spine: machinelearning (21). Halls: ML_Neural_Networks (carrier); ML_Gradient_Landscape (carrier); ML_Classification (field trip); ML_Evolution (field trip); FormFinding_Descent (field trip). Tracks: long.
- CODE new: timers. Returns: packed_arrays, loops, materials, surface_tool, random, seeds, signals.
- BODY: A tiny network trained in small batches on a Timer's timeout, so the frame never stalls, each weight shown as a cylinder's thickness and colour; the loss as a terrain you walk down.
- ARGUMENT: axis *training steps*: 0 / 10 / 100 / 1000. Predict: 100 and 1000 look most alike (the weight-body stops changing) even though the error still falls. Claim: *A trained network is a body whose shape settles long before it stops being wrong.*
- DEBT: Machine-learning models are always biased (Queer 3D); the classifier's boundary is its data's boundary; labelling is labour (Feminist Data Set). Gradient descent is formfinding by another name.
- PLACE: Walk the loss landscape as the optimiser: become gradient descent (FormFinding_Descent returns).
- Godot: Timer, timeout, batches per tick; weights in a PackedFloat32Array mapped to transforms and materials; training vs showing as two rates.
- Lineage: Processing: none. NoC: ch10 Neural Networks; ch9 Evolutionary Computing (ML_Evolution). Application: WP3 neural networks and evolutionary algorithms; WP4 AI. Klee: beyond the sketchbook. Reference: Turing's B-type unorganised machines (the application); Caroline Sinders, Feminist Data Set.
- Project step: Final project plan, two units before the end: write the prediction and the claim your hall will argue.

#### 37. The crisis of foundations: impossible possible space

- Spine: foundationscrisis (23). Halls: NonEuclidean_Spaces (carrier); Escher_Impossible (carrier); Godel_Incompleteness (field trip); Euclid_Parallel (encounter); Russell_Paradox (encounter). Tracks: long.
- CODE new: await. Returns: shaders, uniforms, camera, search, timers, signals.
- BODY: The same room grid warped by a curvature uniform in a vertex shader (hyperbolic, flat, spherical), and an Escher object that closes only from one viewpoint.
- ARGUMENT: axis *curvature*: -1 / 0 / 0.5 / 1. Predict: 0 and 0.5 look most alike near the centre; they separate at the edges. Claim: *Parallel lines are a setting: the same code draws Euclid's room or another geometry.*
- DEBT: Euclid's fifth postulate is the engine's default (Vector3 is flat). Godel and the halting problem: some searches end 'not found within budget', which is not the same as 'unprovable'. This is mostly a reflect chapter (standing ruling: reflect halls need no compulsory code); its one small new idea is await, so a search can be spread over frames and stopped.
- PLACE: Walk a room whose parallels meet; stand at the one place where the impossible triangle closes.
- Godot: vertex() displacement; a uniform driven from GDScript; a camera-alignment test; a step-budgeted search with await.
- Lineage: Processing: none. NoC: none. Application: WP4 non-euclidean spaces; the application's paradoxes of infinity. Klee: II 'a house wall drawn logically right but psychologically wrong' (perspective as illusion, returned). Reference: Escher, Reutersvard, Penrose (Queer 3D lineage); Gaboury's queer history of computing (Turing).
- Project step: Your hall gets one impossible element.

#### 38. Order toward entropy: the QFEP laboratory

- Spine: qfeplaboratory (24), randomness (10). Halls: QFEP_Lambda_Spectrum (carrier); QFEP_F_Term (carrier); QFEP_Edge_Of_Chaos (field trip); Random_Entropy (field trip). Tracks: long.
- CODE new: sorting. Returns: random, seeds, arrays, packed_arrays, multimesh, vectors, player.
- BODY: A population of your family members arranged by a lambda that moves them from sorted order (F) to seeded shuffle (E), with a histogram and an entropy readout logged over time.
- ARGUMENT: axis *lambda (order to entropy)*: 0 / 0.25 / 0.5 / 1. Predict: 0 and 0.25 look most alike (the rows still read); 0.5 is where the arrangement starts to lose its rows. Claim: *Entropy is visible as the loss of rows: the edge of chaos is a place on a slider, not a property of the bodies.*
- DEBT: Entropy as noise or as 'order from before' (Queer 3D; with Haraway and Ahmed a resistance); measuring a body's entropy flattens it to one number; sorting imposes an order that the shuffle only undoes.
- PLACE: Walk the lambda track: your position is the parameter (become the variable).
- Godot: Array.sort_custom; a seeded shuffle; a histogram in an Array; a PackedFloat32Array log drawn as a line.
- Lineage: Processing: none. NoC: ch7 edge of chaos (CA). Application: the application's arc toward entropy (F to E). Klee: the book's close: the line as coordinator of motion, back to the dot of page one. Reference: QFEP (Ada's framework); Shannon; Turing and entropy.
- Project step: Put your hall's bodies on an order-to-entropy axis and choose where it stands.

#### 39. Out of the lab: situated bodies and your hall

- Spine: postfoundationscrisis (25). Halls: CriticalAlgorithms_Algorithmic_Bias_Visualization (carrier); CriticalAlgorithms_Applied_Ethics (carrier); PostCrisis_Synthesis (carrier); SpeculativeComputation_Collective_Knowledge (field trip). Tracks: long.
- CODE new: json, files. Returns: raycasts, save_load, xr, export_build, profiling, testing, classes, dictionaries.
- BODY: Your final hall: bodies from your families placed with a provenance record (who made it, how, from what) saved as JSON in user:// and read back in another hall, and an accessibility check that raycasts sightlines from every standing point.
- ARGUMENT: axis *layout rule for the same bodies*: rows / ring / clusters / seeded random. Predict: Ring and clusters look most alike in sightline coverage; rows leave the back blind. Claim: *A layout is a decision about who can see: the accessibility map is the comparison image of the argument.*
- DEBT: Algorithmic bias and the default body (whose eye height the sightline test uses); provenance as care (Collective Knowledge); algorithmic enclosure (Queer 3D after Zuboff). The course's own promise to 'reveal the black box' is tested against what your hall still hides.
- PLACE: The body leaves the lab: your hall in the endless museum, walked in the headset with the XR body swapped in, exported to the Quest.
- Godot: JSON.stringify, JSON.parse_string; FileAccess in user://; sightline raycasts; Android / Quest export and the 72 / 90 Hz frame budget.
- Lineage: Processing: Handbook Synthesis 4. NoC: the Ecosystem Project (a museum exhibit). Application: WP4 algorithmic life and AI; the application's commons. Klee: the close: back to the dot; the teacher's programme 'line as will and infinity'. Reference: NoC Ecosystem Project; SFPC Code Societies 'Critical Simulation'; FemTechNet's nodal course.
- Project step: CAPSTONE: your hall, shipped to the headset, with its prediction, comparison image, claim and debt comment in the README.

## Departures, collected

- **ch08 The chessboard: purely repetitive and therefore structural** (array_tutorial, primitives): array_tutorial (spine 3) comes before transformation (spine 2): Klee puts structure (I.5-8) before dimension (II), and Form+Code puts Repeat before Transform. Bodies can be repeated with position alone; the full transform waits for the organism (ch12).
- **ch09 Families: one body, one axis, a series** (primitives): A deliberate return to a late primitives hall (Primitives_Ignorance, spine 1): the family needs loops and instancing (ch8) first, and it must come before chance so that the seed can become an axis.
- **ch10 Pattern: structure moves into the surface** (tiling, array_tutorial): tiling (spine 5) before color (spine 4): colour is taught late, where Klee ends his book (ch26); until then the two-colour palette stays supplied.
- **ch11 Disturbed order: chance enters the grid** (randomness): randomness (spine 10) is met a third of the way in: it enters Klee's lineage in 1965-68 as the disturbance of a grid already built (Nake, Nees, Molnar); the 2023 application puts it in WP1, Queer 3D's foundation asks 'what is randomness' first, and Code as Creative Medium places Unpredictability right after iteration. It returns as a game (ch21) and as noise (ch25, ch28).
- **ch12 The organism: bone, tendon, muscle** (transformation): transformation (spine 2) comes after arrays, tiling and chance: Klee's organism follows structure (I.9 after I.5-8) and Form+Code puts Transform after Repeat; the still bodies of Part I needed only position. It also opens _process(delta) only now, as the Processing Handbook opens 'continuous' in its second part.
- **ch13 Collage: a found body meets a made one** (primitives): A deliberate return to the last primitives hall (Melencolia, spine 1) as Part II's synthesis; it closes the teaching half of the short track, which pivots into the mini project here.
- **ch14 Eye level: the vertical axis moves with you** (transformation): A second transformation hall after chance and the organism: Klee's dimension (II) follows structure and the organism (I).
- **ch15 The tightrope walker: balance** (formfinding): formfinding (spine 8) before forces (spine 7): Klee's balance (II) precedes the gravitational curve (III). Stand the body before you push it: here the engine's gravity does the work; in Part IV you write gravity yourself.
- **ch16 Legs: the passive part drives** (forces): A forces hall (spine 7) visited before the rest of forces: tip-or-hold belongs with balance, which is Klee's order.
- **ch17 The bullet: a curve made of steps** (change, forces): change (spine 6) after formfinding: the curve follows balance, as Klee's gravitational curve (III) follows balance (II).
- **ch19 The stair climber: the player opened** (forces, wavefunctions): A wavefunctions hall (spine 9) visited early: the stair is a function made walkable, and the player belongs where Klee has the stair climber (III).
- **ch21 To stand despite all possibilities to fall: a round** (randomness, formfinding): A return to randomness (spine 10) as the long track's midterm: the chance met in ch11 now drives a whole round, and the small-game kit (player, input, camera, ui, save) is complete.
- **ch23 Circle and spiral: the question of life and death** (wavefunctions, fractals): Fractal_GoldenSpiral (fractals, spine 14) is visited early as a field trip: Klee derives the spiral from the pendulum. The golden section returns with recursion in ch30.
- **ch25 The arrow and the field of arrows** (change, noise): Flow_Field (change, spine 6) comes after the wave sequence, and noise (spine 11) is first met here: NoC puts flow fields after noise, and Klee's arrow closes his kinetic part. Noise returns as ground in ch28.
- **ch26 A colour has many faces** (color): color (spine 4) is taught late, because Klee's book ends in colour and Albers puts theory after experience. Since ch8 you have worked with a supplied fixed palette (Albers's coloured paper); now the palette becomes yours.
- **ch28 Noise as ground: the blob aesthetic** (noise): noise (spine 11) after shaders (spine 12): noise was first met as a field of arrows (ch25); as ground it is taught here, where the shader chapter lets you compare CPU noise with Shader_09_FBM's fBm.
- **ch32 How do we navigate an auto-generated world?** (proceduralgeneration, graphtheory): graphtheory (spine 22) is pulled forward into procedural generation (spine 16): the application's WP3 puts graph theory with world building, and a maze needs a graph.

## Comparable courses: what this candidate learned from them

Is there a course with this scope? Not found in the sweeps: no course teaches queer or critical theory together with procedural 3D or VR programming for beginners. The closest partial matches are Claudia Hart's Intro to Experimental 3D at SAIC (a Bauhaus basic course redone in 3D, with units named after art lineages, in Maya and without a queer lens) [V in research_queer.md], SFPC's Code Societies (three weeks, critique beside code) and Recreating the Past (recreate a precedent), and the Aesthetic Programming / Critical Code Studies pairing at USC (2D, web). None faces Godot's three demands (the engine calls you, everything is an object in a tree, nothing is drawn immediately in 3D).

- Klee's Pedagogical Sketchbook (verified text): its four parts give the macro-order; its correction to the project's own summary matters (pendulum and top open Part IV, not gravity; circle and spiral are derived from the pendulum; the book ends in colour), so colour is taught late and the pendulum-circle-spiral chain is one derivation (ch22-23).
- Klee's Part I is a body book (bone, tendon, muscle; heart and blood; 'the tightrope walker is the scale'); its active/medial/passive trichotomy mapped onto male and female is the precise place for 'in drag': the scene tree's parent-child command chain is taught (ch12) and then inverted by IK (ch16).
- Kandinsky, Point and Line to Plane: Part I's three steps and its polarity questions (when does a point become a plane; when does a line become a slab) become the first ARGUMENT axes (ch02, ch05); the basic plane is a subject, not a given (ch07-08).
- Albers, Interaction of Color: every ARGUMENT is a controlled problem with a stated visual target in one constrained material, variants compared side by side, theory after experience; the supplied two-colour palette is his coloured paper, and 'make one colour look like two' is ch26's place.
- Nake (Hommage a Paul Klee, 1965), Nees (Schotter), Molnar ((Des)Ordres, the series and the 1%): randomness enters the Klee lineage as disturbance of a grid already built, which fixes its place right after the chessboard and families (ch11), a declared departure from spine 10 matching the application's WP1.
- Processing Handbook (2007): static before continuous (delta waits until ch12), a synthesis closing each part, and debugging as a chapter of its own mid-course (ch20).
- Learning Processing / GDQuest Learn GDScript: call supplied functions before defining them, the planted error early, one student body rebuilt as each idea arrives (the student's room and family are carried through every project_step).
- Aesthetic Programming: pause weeks without new syntax after each synthesis, peer feedback on each week's work, the ReadMe beside the code in Git (the sketchbook README), and the final project planned two units before the end (ch36).
- Critical Code Studies and the CCSWG: 'describe it in a single class' (ch09), the confessing comment turned into a student's debt comment (ch13 onward), and a code-critique station on Ada's own supplied code at the DEBT step, never at the opening (ch34, after Marino on Kittler's raytracer); Chun's 'sourcery' as the dark spot of 'revealing the black box'.
- Montfort, Exploratory Programming: 'Critique My Starter Programs' turned on Godot's capsule player (ch19); 'valid and intentional are different' as the theory of the planted bug (ch20).
- 10 PRINT: 'Regularity before Randomness' (ch11), the Maze Walker as a walkable pattern (ch11, ch32), and ports as returns.
- Code as Creative Medium: Unpredictability placed right after iteration; body-shaped briefs (Extrapolated Body, Virtual Creature) for the short track's mini project; short exercises beside open assignments.
- SFPC Recreating the Past and Code Societies: recreate a precedent and write the debt in the difference (ch13, Melencolia); a three-week critical format with critique sessions set beside code, used for the short track's third week.
- Gaboury, Image Objects: one technical object per chapter as a critical lens (culling at ch07, the grid at ch08, object orientation at ch12, the default body at ch19, the GPU at ch27).
- Queer 3D World (2024): the three layers per chapter, the blob aesthetic and the overflow-rate simulation (ch28), scanning and importing as a real strand (ch13), and AI-assisted code taught as directing and checking (ch13, LeWitt protocol).
- The Nature of Code: its order for forces, oscillation, particles, CA, fractals, agents and learning is kept inside Parts IV-VI; its cumulative Ecosystem Project, a museum exhibit of creatures, becomes the student's own hall (project_step, ch39).
- What no comparable course has, and the course says so: bodies in 3D and VR that a person stands on, carries or becomes; a falsifiable PREDICTION of the closest pair before every render; and a geometric and topological queering (polycount against deformation, the blob, impossible space) that the critical-code canon does not yet cover.

## What this candidate forecloses, and what it hides (a sieve pass on itself)

- **Thickens:** every chapter has a named precedent a student can look at (Klee's numbered diagram, a Nees plot, an Albers plate), so theory is pulled in by a body and a code idea, not pushed by a reading list. The Klee grammar gives a reason for most of the order that a student can hold in one sentence per part.
- **Forecloses:** randomness-first (Nature of Code, the 2023 application's WP1, Queer 3D's foundation list) is only half-served: chance comes at ch11, not ch1. Colour-as-appearance is postponed to ch26, which some art students will feel as a long wait; the supplied palette is the cost. Sound and particles (WP1) arrive in Part V, not at the start.
- **Dark spot:** the Bauhaus frame carries universalism (Klee's 'child of the Universe', Kandinsky's fixed emotional values, Albers's universal eye). The course uses these as claims for the ARGUMENT strand to test, and names the gendered trichotomy, but a Klee-shaped course can still make formalism look like the natural order of learning. Part VI has no Klee counterpart and follows the spine; the claim to be Klee-shaped holds for Parts I-V only.

## Verification notes

- [V] Klee's part divisions, the pendulum-circle-spiral passage, the tightrope walker, 'purely repetitive and therefore structural', the anthers passage, the arrows and the colour circle: read in `work/klee_ps.txt` (Praeger 1960 text) during this run.
- [V] Ada anchors: `commons/maps/Color_Paint/final.md` cites Albers; `commons/maps/Array/final.md` cites Molnar's (Des)Ordres; `commons/maps/Point_Trace/final.md` cites Klee's active line; `commons/maps/Primitives_Melencolia/final.md` says its hidden surfaces 'are decisions we have made'; `doc/book/BASE_LAYER.md` names `klee_walking_point`; runnable kits exist under `doc/book/studies/` (day-zero, point-zero, point-one, point-coordinates, point-lines, point-trace, random-definition). Per-hall hooks from `doc/book/iterations/claude-godot-path-2026-09-30/survey_bundle.json`.
- [V] Every hall name in the JSON exists in `spine.json` (checked by `work/c4_build.py`); the ladder, vocabulary and load checks pass on both tracks.
- [mem] Perlin noise's origin in film imagery (ch25), rule 30 used as a random generator (ch29), Reynolds's boids (ch35), The Algorithmic Beauty of Plants (ch31), Chun's Discriminating Data on homophily (ch32), and whether Godot's solver keeps a spinning top up (ch22: to be tested, not asserted).
- The 15-of-16 vs 2-of-16 die result (ch15) is the project's own memory note on settle tests and physics rate, not re-measured here.

Files: `cand_c4_klee_kandinsky.json` (the candidate), `work/c4_build.py` (builds and checks it), `work/c4_md.py` (writes this page).
