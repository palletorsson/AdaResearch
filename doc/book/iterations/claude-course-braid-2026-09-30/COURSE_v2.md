# The Sketchbook in Drag: a grammar of bodies

*Place, join, extrude, articulate, repeat, vary, surface, move, disturb, displace, grow, deform, combine, learn, release: the operations of form in Ada's order, each part closed by an assemblage*

Status, 1 October 2026. v2, refined by hand on 2026-10-01 from the auto-research winner (d2_ada_first, course_v1.json): the same 41 chapters reordered into the spine's order of form operations, three assemblage chapters added, one chapter split; then two operations (extrude, displace), a process strip per assemblage, and the project's MeshGrammar as the tool behind both. A proposal: no tutorial, kit, spine or curriculum.json changed.

## For the student: why this order

Every chapter adds one operation of form to the student's toolkit (place, join, articulate, repeat, vary, surface, move, disturb, grow, deform, combine, learn), in the order Ada's spine puts them; and every part ends in an assemblage, a body composed from the operations learned so far, made of parts of different origin. The spine's order is the order of operations; a chapter that returns to an earlier sequence says it is a return. The capacity the course builds is the capacity to make different assemblages: by the end the student can make a body by any of the operations and compose them.

The course has four strands in every chapter: **code** (one programming idea), **body** (a body you build in code), **argument** (a family of that body, one axis varied, a prediction written before you render, one comparison image and one claim), and **place** (where a body meets yours). It has three layers in every chapter, from Palle's Queer 3D World course: **foundation** (the lab: how it works), **debt** (what the approximation owes or hides) and **ontology** (the body leaves the lab). The lesson rhythm is unchanged from v1:

- Decode the hall: walk the chapter's carrier hall first and guess how its work is built (PRIMM's Predict; Aesthetic Programming's Decode).
- Find the family in the hall: where the hall shows one work at several values of one axis, predict which two look most alike before you read anything beside them. It is the same question the kit will ask of your own body.
- Run, investigate and modify the kit or the supplied body: change one line and see what moves.
- The closed exercise is the argument: one exported axis, three to five values. Write the prediction in your sketchbook README before rendering, with the arithmetic when there is one. Then make the comparison sheet and write one claim it supports. The prediction is a floor, not a forecast: when the sheet comes back less different than you predicted, look for the fault before you believe it.
- The planted bug: each chapter has one real error, and you read its message before you fix it.
- Make: build your own body (the project step) and carry it into your room.
- Debt, after the making: what the approximation owes or hides, in one reading or one code-critique snippet of Ada's own code.
- Place: a body meets yours. Stand on it, walk through it, carry it, become it.
- The process strip: for an assemblage, and for any body made by more than one operation, one still after each operation with the operation named under it, in order. It is the body's recipe, and it is what you hand in. A body built with MeshGrammar gets its strip for free: the grammar keeps every generation.
- The plate: each part ends on one question about the course's opening picture: what of it can you make now? The answer goes in your sketchbook, as a sketch or a still.
- Decide, and say why: follow or settle. If your prediction was wrong, or two ways of looking disagreed (the picture and the marble, the editor and the exported build, one camera and another), you may follow it: change one more thing and look again. Or you may settle and build your body. Either is a good decision; a stop is part of the work. Write which, and the reason, in your field note: question, baseline, intervention, prediction, observation, another cause, decision, reason, how to run it again.

### The toolkit

Each chapter adds one operation. By the end of a part you can do everything in its row.

| part | operations added | the assemblage that closes it |
|---|---|---|
| Place and join (primitives; Klee I.1-4) | instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship | - |
| Articulate (transformation) | articulate, assemble | I: A body of parts: the first assemblage |
| Repeat and vary (arrays; the family; Melencolia) | repeat, parameterise, tune, budget, collage | II: Collage: a found body joins the family (assemblage II) |
| Surface (colour, tiling) | colour, pattern | III (dressed, inside the chapter): Pattern: structure moves into the surface |
| Move by law (change, forces, form finding, waves) | integrate, walk, push, follow, balance, climb, swing, sound, field | - |
| Disturb, field, skin (randomness, noise, shaders) | disturb, noise, displace, skin, play | IV (midterm): To stand despite all possibilities to fall: a round (assemblage IV, midterm) |
| Grow by rule (cellular automata, fractals, L-systems, procedural generation) | rule in time, recurse, grow, save a genome, navigate, assemble | V: Same desire: grown bodies join made ones (assemblage V) |
| Deform, imply, combine, flock (soft bodies, isosurfaces, boolean surfaces, swarms) | deform, imply, combine, flock | VI: Combine: union, subtraction, intersection (assemblage VI) |
| Learn, break, measure, release (machine learning, graph theory, the crises, QFEP, post-crisis) | learn, break, measure, release | VII (final): Out of the lab: your hall in the collective museum (assemblage VII, final) |

### What an assemblage is here

A body composed from parts of different origin and different operations: a part made by code, a part drawn by hand, a part scanned, a part grown by a rule, a part carved by subtraction, under one root whose choice is itself a decision. There are seven, and each uses everything learned before it: I a body of parts (the scene tree), II collage (a found body joins the family), III dressed (inside the pattern chapter), IV the round (the midterm game), V grown bodies join made ones, VI combine (boolean), VII your hall in the museum (the final).

### The project's own grammar of operations

MeshGrammar is the project's own grammar of mesh operations (commons/mesh_grammar/): a seed mesh, a list of rules, applied generation by generation. A rule is a selector (which faces: all, upward, random, tagged) plus an operation plus parameters. The grammar keeps a snapshot of every generation, so a body built with it carries its own process strip. Used through one supplied function at ch45 (the learner has no dictionaries yet), used directly at ch46, opened at ch43, where a rule is read as a selector, an operation and its parameters.

| the slide's node | MeshGrammar |
|---|---|
| Extrude Mesh | ExtrudeFaceOp: distance, scale (below 1 tapers) |
| Scale Elements | ScaleFaceOp: scale; InsetFaceOp: amount |
| Voronoi Texture, Wave Texture (as displacement) | NoiseDisplaceOp: amplitude, frequency, noise_type (simplex, perlin, cellular), direction (normal, radial, y) |
| subdivided seed | SplitFaceOp: pattern (midpoint, fan); MeshData.create_icosahedron |
| Set Material | PaintByTagOp |
| Mesh Bevel | none; InsetFaceOp is the nearest |
| Mesh Boolean | none; CSG, at ch44 Combine |

On the spine: LSystems_Grammar_Lab (mesh_grammar_lsystem_tree), LSystems_Architecture (coral fingers, petal flower), ProceduralGeneration_Reaction_Diffusion_Systems (detailed bulge). Off the spine: Gallery_MeshGrammar and the encyclopedia's /mesh-grammar-gallery hold all twenty-one.

Measured 2026-10-01, commit 0f506f14b. Until that day the twenty-one mesh_grammar_* registry names all loaded one scene with no rules, so placed in a hall each was the bare seed. Nineteen now have a scene of their own that names a recipe, and the demo and the halls build from one shared list. The sphere seed was repaired in the same commit: it was wound inward and was not closed, so every operation along the normal grew into it; it is now a closed surface wound outward. In stills, all nine works this course points at read as their name. Nine of the twenty recipes are unseeded, so two builds of one name differ; branching coral is a bare seed in about one build of thirty-six. A draft hall, PG_Mesh_Grammar (not in any sequence), shows fourteen grammar steps on the icosahedron.

### The families already in the halls

The hall shows the family, the kit makes one. Where a chapter's hall holds a work with a declared axis, the hall shows that work at three to five values of the axis, side by side, and the first step of the lesson is to predict the closest pair there. The kit then sweeps an axis on the student's own body with the same sheet. A hall marked 'at its default' holds the work but not yet its family: adding the sibling tokens (name#axis:value) is the integration. Measured for this course: 916 artifacts declare 1349 axes; 44 of the 46 chapters have such a work standing in their halls, and 11 of them already show a family.

### The plate

The course opens with one picture and returns to it at the end of every part: plate 31 of Ernst Haeckel's Kunstformen der Natur (1904), Cyrtoidea, nine radiolarian shells. Read as rules it is one body with about ten numbers, shown nine times: a family on a comparison sheet. Haeckel drew the forms. D'Arcy Thompson (On Growth and Form, 1917) read a form as a diagram of forces and turned one form into another by transforming its grid. Turing (The Chemical Basis of Morphogenesis, 1952) asked whether a rule could grow them; his student Bernard Richards solved the equations on a sphere and matched radiolaria Haeckel drew for the Challenger report. Palle Torsson takes Turing as the project's muse. The three are the course's three ways of working: decode, transform, grow.

Ernst Haeckel and Adolf Giltsch, Kunstformen der Natur, Tafel 31, Cyrtoidea (Flaschenstrahlinge), 1904. Public domain. https://commons.wikimedia.org/wiki/File:Haeckel_Cyrtoidea.jpg The lesson is `doc/book/course/opening/PLATE.md`; the remake is commons/artifacts/cyrtoid_by_rule/ (lookup cyrtoid_by_rule; axes form and stage). Two rules were added to the mesh grammar for it on 2026-10-01: MeshData.create_lathe and CellInsetOp. Gate: commons/testing/probe_lathe_cells.gd. The remake's wall is a sheet with no thickness, its pores are hexagons where the plate has rounded holes, its feet are straight, and it has no wings. Each is a rule the project does not have yet.

### The decision and the field note

A proposed artistic research method for deciding when to hold an organisation together and when to reopen it: establish a configuration, observe it, make a limited intervention, inspect the consequence, decide what to follow, and either widen the inquiry or provisionally consolidate it. The course's argument was already prediction, comparison and claim; the method adds the decision, the alternative explanation and the kept trajectory. The template is `doc/book/course/opening/FIELD_NOTE.md`; a worked note from this project is `doc/book/course/field_notes/2026-10-01-pyramid-family.md`.

- Keep what was observed, what is concluded from it and what is guessed on separate lines.
- Do not say entropy rose unless a probability distribution and an estimator have been stated. Variational free energy, thermodynamic entropy, uncertainty in beliefs, diversity among samples and visual complexity are different quantities.
- QFEP is used here as a proposed method, not as an experimentally validated replacement for variational free energy; the QFE equation is heuristic.
- An ordinary cause (a collision margin, a clipping camera) does not make an observation less worth keeping.
- A screenshot alone cannot show that something can be passed; use a body (the marble, the walker).

### Two tracks

**Three weeks: place, join, articulate, repeat, vary, and one assemblage (Queer 3D World format)** - 3 weeks (15 days). Chapters: ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch08, ch13, ch42, ch09, ch14, ch18.

A family in drag, assembled: one class of your own with one exported axis of 3-5 values, instanced as parts into a body of parts (ch42) with one scanned or found part (ch18); the closest pair predicted in writing before rendering; the comparison sheet; one claim sentence and one debt comment; shown to the class on day 15. Week 1: ch1-ch6 two a day on days 1-3, ch7 and a scanning / Tilt Brush session on day 4, ch8 (first export) on day 5. Week 2: ch13, ch42, ch9, ch14, ch18 (export on Friday; the brief is due the same day as a flowchart and a paper prototype). Week 3: the mini project, with two critique sessions in the SFPC Code Societies format and no new code: (a) the command chain, walked in Trans_Body and VFM_09_Legs, then each student re-roots a supplied three-segment organism in the Scene dock and moves it; (b) the blob aesthetic and the default body, walked in ISO_Metaballs and ML_Classification.

**One year: the operations of form in Ada's order, with seven assemblages** - 46 weeks as written (Part 1 at two chapters a week, then one a week, and a pause week with no new code after ch8, ch18, ch25 and ch43); 36 weeks with the eight pairings below. Chapters: ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch45, ch08, ch13, ch42, ch09, ch14, ch15, ch16, ch18, ch29, ch10, ch22, ch19, ch23, ch21, ch20, ch24, ch26, ch27, ch28, ch11, ch12, ch46, ch30, ch25, ch31, ch32, ch33, ch17, ch34, ch43, ch35, ch36, ch44, ch37, ch38, ch39, ch40, ch41.

Midterm at ch25: a round in your room that a classmate can lose, on your own terrain, exported and played. Final at ch41: your hall in Ada's endless museum, built from your families and assemblages, exported to desktop and Quest; for each body a prediction, a comparison sheet, a claim and a debt comment, plus one public sculpture whose visitors' changes are kept as provenance records.

### Relation to the spine

The carrier sequences of the 46 chapters are in spine order for 0.979 of chapter pairs (v1, Klee-first: 0.894; the spine itself: 1.000). 6 chapters sit below the running spine order, all declared as returns:

- ch14 (n13) Families: one body in a single class: return: the family is declared at the first family hall (Primitives_Ignorance), once there are many to vary (after the chessboard).
- ch15 (n14) The family in the editor: setters, @tool and the sheet opened: return: tuning the family live belongs beside its declaration; the colour and softbodies halls are visits.
- ch16 (n15) The budget: polycount measured, a claim tested: return: the budget is the family's debt (polycount against deformation), so it is paid where the family is; the catenoid is a form-finding visit.
- ch18 (n16) Collage: a found body joins the family (assemblage II): return: Melencolia, the last primitives hall, closes the repeat-and-vary part as its assemblage; it needs the family and the import.
- ch28 (n27) The arrow and the field of arrows: return: the field of arrows (change, spine 6) closes Part 5 because it needs the part: forces for the particles, the hand's ray from legs, the MultiMesh from the swing; the field itself is a supplied function until noise (ch12).
- ch25 (n32) To stand despite all possibilities to fall: a round (assemblage IV, midterm): return: the round is the part's assemblage, built on the noise terrain (ch12) in the shader skin (ch30), so it follows them.

25 of 25 spine sequences are touched. Decisions a reader may want to flip: chance stays at its spine place (Part 6), with `random()` met as a value in the chessboard (ch9), as Nake, Nees and Molnar lay disorder over a built grid; the first shader stays at spine 12 (Part 6), not with colour; the player's body is opened where motion is the subject (Part 5), having been borrowed since day one.

## The chapters

### Place and join (primitives; Klee I.1-4)

*You can put a body where you say, give it size and a boundary, carry it, join two into a line, keep a walk as a record, close the record into a plane you can stand on, pull the plane up into a solid, and ship a build.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship.

Of the plate, now: The outline: one half of a shell as a recorded line, from the horn to the lip, and the axis beside it. With the turn handed to you as one function, a solid vase with joints (stage: profile, turned).

#### 1. Day Zero: the instruction is the work

- **Operation:** instruct. **Spine:** primitives. **Halls:** Point_Zero (encounter).
- **Code:** new statements, output, errors; returns -.
- **Body:** A LeWitt location drawing turned into one body: in the supplied base.tscn (floor, camera, light, Label3D) you type one line that calls a supplied place_at(where), and a cube appears at 'corner', 'midpoint' or 'centre'; one print() writes your instruction to the Output panel.
- **Argument:** axis wording of the instruction: corner / midpoint / centre / somewhere near the middle. Predict: 'midpoint' and 'centre' will look most alike from the fixed camera: on a square floor both land on the middle line, and they differ only if 'midpoint' is read as the midpoint of an edge, which is exactly the ambiguity. 'somewhere near the middle' will not run at all: the helper refuses an unknown word with an error. Claim: An instruction a partner can interpret is not one the engine can run: ambiguity shows up as an error, not as a variation.
- **Debt:** LeWitt's drafters interpreted; the engine refuses. Literalness is the price of repeatability, the course's first debt. GDScript's English keywords are programming's default language (Marino on FLOW-MATIC), a cheap first question for Swedish-speaking students.
- **Place:** Stand, reach and turn in the room (the supplied desktop walker, or the headset through the supplied XR rig); then a partner executes your written instruction on paper and you compare it with the run.
- **Families in the hall:** frame_counter_display.reading (count / rate / delta / budget) in Point_Zero: at its default; you_are_here.deixis (words_and_mark / words_only / mark_only / arrow / plan_fragment) in Point_Zero: at its default
- **In your room:** Start a sketchbook repository whose README will hold every prediction, comparison image, claim and debt comment of the course.

#### 2. Point: a body with no size must be given one

- **Operation:** place. **Spine:** primitives. **Halls:** Point_Zero (carrier).
- **Code:** new variables, properties, lifecycle; returns statements, output, errors.
- **Body:** A point built in _ready(): a MeshInstance3D whose SphereMesh radius is a variable, placed by setting its position property; then three points by hand, and a Label3D beside them that counts the frames the engine has called you for (Point Zero's frame counter).
- **Argument:** axis point radius seen from 2 m: 0.01 m / 0.05 m / 0.25 m / 1.0 m. Predict: 0.01 and 0.05 will look most alike: at 2 m both subtend under 1.5 degrees, a few pixels, and read as dots. 1.0 stops being a point and reads as a body; 0.25 is the one that changes category as you walk. Claim: A point is a relation between size and viewing distance: Kandinsky's point becomes a plane when it grows.
- **Debt:** Mathematically a point has no extent; to be seen it needs a mesh of hundreds of triangles. The engine can show a point only by lying about its size, the first approximation of the course. And the frame counter counts frames, not seconds: in a 90 Hz headset it runs 1.5 times faster than at 60 Hz on the desktop. The repair (delta) is held back to ch13 and named there.
- **Place:** Walk toward and away from the four points: the 0.25 m point changes category as you approach.
- **Families in the hall:** frame_counter_display.reading (count / rate / delta / budget) in Point_Zero: at its default; you_are_here.deixis (words_and_mark / words_only / mark_only / arrow / plan_fragment) in Point_Zero: at its default
- **In your room:** Place three points whose sizes you chose; write your first PREDICTION before you look.

#### 3. Solid and ghost: one if decides what a body is

- **Operation:** decide: solid or ghost. **Spine:** primitives. **Halls:** Point_One (carrier).
- **Code:** new conditions, booleans, calling; returns variables, properties, lifecycle, errors.
- **Body:** Point One's three stations rebuilt: a boolean solid decides, in one if, whether a sphere gets a collider, and a second number sets the collider's radius apart from the visible radius. You call the supplied make_solid() and make_ghost() before you open them; the kit's contact probe (pink feelers) runs through the stations.
- **Argument:** axis collider radius as a fraction of the visible radius (still taken with the probe's feelers paused against each sphere): 0 (ghost, no collider) / 0.5 / 1.0 / 1.5. Predict: The ghost and 0.5 will look most alike: in both the feeler has entered the visible sphere (it passes through the ghost and stops halfway inside the 0.5 sphere). 1.5 stops the feeler in mid-air before it touches the surface. Claim: What you see and what stops you are separate properties: one if and one number decide what a body is for another body.
- **Debt:** A still cannot show collision without a witness: the argument needs a second body (the probe) to make the first one's solidity visible, and so do players. Invisible walls and walkable ghosts are the course's first uncanny, and the gap between collider and mesh is a decision every game hides.
- **Place:** Walk into each sphere with the walker: the ghost lets you through, 0.5 lets you sink in, 1.0 stops you at the skin, 1.5 stops you before you touch it.
- **In your room:** Mark one of your points as a ghost and write one sentence on why a visitor should be able to walk through it.

#### 4. Coordinates: carry the point

- **Operation:** carry. **Spine:** primitives, transformation. **Halls:** Point_Coordinates (carrier), Trans_Introduction (encounter).
- **Code:** new vectors, expressions, xr; returns variables, properties, calling.
- **Body:** A carried point that writes its own Vector3 beside itself in a Label3D, and a second point placed at an expression of the first (a + Vector3.UP, a * 0.5) that follows whenever you move the first.
- **Argument:** axis which axis the same 1 m offset goes into: (1, 0, 0) / (0, 1, 0) / (0, 0, 1) / (0.58, 0.58, 0.58). Predict: x and z will look most alike from a standing eye: both lie in the floor plane and differ only by a quarter turn. y does not, because up is the one direction your body has. Claim: The three axes are equal in the maths and unequal for a standing body: height is the one you feel.
- **Debt:** Godot's Y-up, metres and handedness are conventions baked into every later body; the headset adds a default floor height that assumes a standing adult (Bagnall on normativity in hardware, in Queer Game Studies).
- **Place:** Pick the point up (desktop carry, or an XR Tools pickable in the headset) and watch its coordinates change as you move it. Pickup belongs here, by the standing ruling.
- **Families in the hall:** SoundscapeRadioRack.face (scale / presets / list / void) in Point_Coordinates: at its default; floating_sphere_field.density (sparse / scarce / dense / fog) in Point_Coordinates: at its default; fontana_puncture.breach (pierced / opened / severed / husk) in Point_Coordinates: at its default
- **In your room:** Put your three points in 3D, one of them above head height, and carry one.

#### 5. Line: distance belongs to the line

- **Operation:** join. **Spine:** primitives, forces. **Halls:** Point_Lines (carrier), Vectors_Act1_WhatAVectorIs (field trip).
- **Code:** new functions, parameters, return; returns vectors, expressions, conditions, calling.
- **Body:** A segment between two carried points: your function show_between(a, b) places, scales and orients a thin box and returns the distance; a do-not-cross barrier reacts when that distance falls below a threshold (condition before threshold).
- **Argument:** axis thickness as a fraction of length: 0.005 / 0.02 / 0.1 / 0.4. Predict: 0.005 and 0.02 will look most alike: on a 1 m line both are under 2 cm and read as lines. 0.4 reads as a slab. Claim: A line in 3D is a thin body: the ratio of thickness to length decides whether we read a line or a plane.
- **Debt:** The engine has no one-dimensional thing to show: the line is a box pretending. Distance is a return value, and every later threshold is a design decision hidden as a number.
- **Place:** Hold both ends (two hands in the headset: Klee's maker 'who has only two hands') and stretch the line until it crosses the barrier.
- **Families in the hall:** wall_abstract.work (divide_horizontal / divide_vertical / divide_diagonal / divide_off_centre / horizon_soft / point_one) in Point_Lines: family shown: cube_wire, divide_diagonal; perspective_lines.vanishing_points (one / two / three) in Point_Lines: one value shown: one; scale_lines.rungs (world / decade / body) in Point_Lines: one value shown: body
- **In your room:** Connect two of your points with your own function, named after what it makes.

#### 6. The walk: a line is a record

- **Operation:** record. **Spine:** primitives. **Halls:** Point_Trace (carrier).
- **Code:** new arrays, loops, meshes; returns functions, return, conditions, vectors, lifecycle.
- **Body:** A trace recorder: in _process the carried point appends its position to an array once it has moved further than a gate distance (list before append; condition before threshold), and a loop redraws the array as an ImmediateMesh line strip.
- **Argument:** axis sampling gate: 0.01 m / 0.05 m / 0.2 m / 0.5 m. Predict: 0.01 and 0.05 will look most alike: both are below the width a hand-drawn curve shows at 2 m, so both read as continuous. 0.5 turns the walk into a polygon with visible corners. Claim: A recorded line is a sampling decision: below a few centimetres the walk looks continuous; above it the corners become the drawing.
- **Debt:** Continuity is faked from a list. Memory is not free, so the trace must forget (a bounded array), and forgetting is a choice about which past counts.
- **Place:** Become the pen: the trace follows your hand (headset) or the carried point (desktop) while you walk a line through the hall, Klee's 'walk for a walk's sake'.
- **Families in the hall:** draw_dot.ink (magenta / cyan / amber / lime / white) in Point_Trace: family shown: 0000ff, 00ff00, ff0000; science_screen.support (stand / frame / cabinet / pylon) in Point_Trace: one value shown: pylon
- **In your room:** Record one walk of your own and keep it as data in your project.

#### 7. Plane: when the line closes

- **Operation:** close. **Spine:** primitives. **Halls:** Point_Triangle_Context (carrier), Primitives_Polythedra (field trip).
- **Code:** new surface_tool, normals, collision; returns arrays, loops, meshes, vectors.
- **Body:** Close the walk: the recorded points become a triangle fan through SurfaceTool, normals are generated, and a collider made from the mesh lets you stand on the plane you walked.
- **Argument:** axis winding and the side the face shows: clockwise / clockwise, flipped normals / counter-clockwise / counter-clockwise, double-sided. Predict: From above, clockwise and counter-clockwise double-sided will look most alike: both show a lit face and differ only by the shadow (measured: 0.82% of the frame). Counter-clockwise alone shows nothing from above and everything from below. Write which pair you expect before you render. Claim: A surface has a side: what you see of a plane is a promise its winding and normals make (Godot winds front faces clockwise).
- **Debt:** Culling (Gaboury, Image Objects, 'Culling Vision'): hidden-surface algorithms decide what exists for the eye; a one-sided plane is invisible from behind while its collider still stops you. The fan also fails on concave walks: the approximation owes the shape its dents. Measured in the kit: the collider is one-sided too. A marble falls through a counter-clockwise face from above unless backface_collision is set, so a surface that shows from one side also holds from one side.
- **Place:** Stand on your walk: the plane made from your own trace becomes floor; walk to its edge and look under it.
- **Families in the hall:** prism_block.grain (solid / split / quartered / lattice / shell) in Primitives_Polythedra: family shown: quartered, shell; triangle_line_puzzle.stock (racked / strewn / ringed) in Point_Triangle_Context: one value shown: ringed; draw_triangle_faces.retention (none / trace / lattice / archive / wax) in Point_Triangle_Context: at its default
- **In your room:** Your room so far: one plane you walked, three points and one line. Commit it.

#### 8. Extrude: the plane is pulled into a solid

- **Operation:** extrude. **Spine:** primitives. **Halls:** Primitives_Polythedra (carrier), Point_Triangle_Context (field trip).
- **Code:** new none (a synthesis); returns arrays, loops, vectors, functions, parameters, return, surface_tool, normals, collision.
- **Body:** Your walked outline from ch07, pulled up by a height into a solid. For every edge of the outline, a wall of two triangles between the edge and its copy above; the fan you already have is the top cap, and the same fan wound the other way is the bottom. A second number, the taper, scales the upper outline toward its centre: 1 gives a prism, 0 a pyramid. One function of your own, extrude(outline, height, taper), returns the mesh, and a collider made from it lets a body stand on top of your walk. Then the same move as the project makes it: a supplied function hands your solid to MeshGrammar, which pushes its upward faces out again by a distance and a scale, the same two numbers, and returns a spire.
- **Argument:** axis taper of the upper outline, same walk and height: 1.0: a prism / 0.6: a frustum / 0.2 / 0.0: a pyramid. Predict: Seen from the side, 1.0 and 0.6 will look most alike: both are flat-topped blocks, and only the slope of the walls differs. 0.0 is the odd one: the top cap has no area and the solid ends in a point. Write the pair you expect, and where the marble will rest on each, before you render. Claim: One outline and two numbers make a family of solids; the cube of the next chapter is this function called with a square and a taper of 1.
- **Debt:** An extrusion remembers only its outline. Every wall is flat, every section has the same shape, and the solid cannot bulge, lean or twist: it is the default body of drawing software, and most buildings on a screen are extrusions of their plan. The walls also want their own normals, so each wall carries four vertices of its own; a solid that looks like one piece is a set of flat pieces that do not share a corner.
- **Place:** Stand on top of your walk: the marble dropped over the solid rests on the cap at the height you chose, and rolls off the pyramid. In the headset it is a plinth made from your own path, at the height of your hand.
- **Borrows:** spire(mesh, distance, scale, times) -> ArrayMesh: hands a mesh to MeshGrammar, extrudes its upward faces 'times' times, returns the result (wraps MeshData.from_array_mesh, MeshSelector.by_normal_direction and ExtrudeFaceOp; opened at ch43) (use); MeshGrammar, a copy of commons/mesh_grammar/ supplied in the kit (use)
- **Works to see:** mesh_grammar_extruded_spire (two extrusions of the upward faces, each scaled down: the same two numbers as this chapter); mesh_grammar_inset_towers (inset, then extrude the inset: the order of operations matters)
- **Process strip:** the walked outline (ch07) -> a wall for every edge -> the top cap: the fan -> the bottom cap: the fan reversed -> taper the upper outline -> collider -> extrude the top again: a spire (ExtrudeFaceOp, borrowed)
- **Families in the hall:** prism_block.grain (solid / split / quartered / lattice / shell) in Primitives_Polythedra: family shown: quartered, shell; cube_scene.grain (solid / split / quartered / lattice / shell) in Primitives_Polythedra: at its default; diamonds.twist_rule (linear / fixed / alternating / accelerating) in Primitives_Polythedra: at its default
- **In your room:** A plinth in your room, extruded from a walk of your own, with its height and taper written on it; put one earlier body on top of it.

#### 9. When things go wrong: the drafter is a machine

- **Operation:** build, direct, ship. **Spine:** primitives, postfoundationscrisis. **Halls:** Point_Animatedcube (carrier), CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter).
- **Code:** new ai_assist, debugging, export_build; returns errors, surface_tool, normals, arrays, functions, calling.
- **Body:** A cube from 8 corners and 12 triangles (Point_Animatedcube's body), drafted by an AI assistant from your written instruction under a protocol of three lines: what should change, what must not change, and one observation that would prove the code wrong. You run it, step through it with breakpoints until you find where its faces turn inside out, repair it, and export a desktop build.
- **Argument:** axis which draft builds the cube: my one face / the one-line draft (make a cube) / the three-line draft / the repaired draft. Predict: From above, your one face and the three-line draft will look most alike (measured: 0.36% of the frame apart), because the draft's top is wound the wrong way and is absent. The one-line draft, wrong in every triangle, looks like a whole cube from above and like an open room from behind; a marble dropped on it comes to rest inside. Write which pair you expect, from above and from behind, before you render. Claim: An instruction fixes what it names; naming is not checking. The draft that looks most finished from one side is the one that is wrong everywhere.
- **Debt:** Algorithmic enclosure and the default body: the assistant learned from other people's code and repeats its norms (a cube at the origin, a capsule player, OpenGL winding). Chun's 'sourcery': seeing generated source is not knowing what it does. A build is a second machine with its own errors (read-only res://, another refresh rate). Measured in the kit's first export: assert() is skipped in a release build, push_error() loses its line number there, and the exe without its .pck answers that the project data could not be loaded; what the editor told you, the build may not.
- **Place:** Run your exported build on a classmate's laptop, or on the headset where one is available (the headset is an export): the first time your room exists outside your editor, and you stand in it. In the short track, the scans made on day 4 are imported by the teacher (glTF, scale fixed) and already stand in your room for this first export, so the collage reaches the headset in week one; ch18 teaches the import and makes the scan a member of your family.
- **Families in the hall:** pyramid.base_sides (3 / 4 / 5 / 6 / 8) in Point_Animatedcube: family shown: 3, 4, 5, 6, 8; station_crates.upkeep (service / store / scrap / works) in Point_Animatedcube: one value shown: store; animatedcubebuilder.order (ascend / descend / together) in Point_Animatedcube: at its default
- **In your room:** SYNTHESIS I: export your room (the walked plane, three points, one line and the repaired drafted cube) and stand in it on another machine. Keep the prompt, the model's first answer and your repair in the README.
- **Departure:** Directing generated code has no spine sequence: it is Palle's own Queer 3D practice, and every later planted bug assumes the debugger, so it closes week one. The bias hall (postfoundationscrisis, spine 25) is walked as an encounter only; it returns as a carrier at ch38.

### Articulate (transformation)

*You can nest parts into one body with pivots, move the whole and keep the parts' relations while it moves: the first assemblage.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble.

Of the plate, now: The joints as parts under one root: head, chest, belly. And Thompson's move: shift the points of one profile and the helmet becomes the flask.

#### 10. The organism: bone, tendon, muscle

- **Operation:** articulate. **Spine:** transformation. **Halls:** Trans_Rotation (carrier), Trans_Body (carrier), Trans_Translation (field trip), Trans_Pre (field trip).
- **Code:** new transforms, basis, delta; returns vectors, lifecycle, loops.
- **Body:** A limb of three segments as a parent-child chain with pivots, each joint turning by angle += speed * delta in _process: the course's first body that moves by itself. Beside it, Trans_Body's lattice loses cells where the limb passes.
- **Argument:** axis where the pivot sits on each segment, same joint angles: at the end / at one third / at the centre / outside the bar. Predict: At rest all four look the same: the pivot moves origins, not bars (measured: no pair differs on more than 0.18% of the frame). With every joint at 30 degrees, one third and the centre are the closest pair, and only the pivot at the end keeps the chain joined: the others open a gap at the knee (5 and 8 cm). Write the pair you expect, at rest and turned, before you render. Claim: A body's motion is decided by where its joints are, not by what its parts look like.
- **Debt:** Klee maps active, medial and passive onto brain, tendon and bone, and onto male and female organs ('Male organs (anthers), active'). The scene tree encodes the same command chain: the parent moves the child, never the reverse. That hierarchy is taught here and inverted in ch21. And frames are not time: speed per frame runs 1.5 times faster at the headset's 90 Hz than at 60 Hz; delta is the repair promised in ch2. Measured in the kit: delta repairs the speed, not the sampling. At 144, 60 and 30 frames a second one turn of the limb carves the same 33 cells; at 3 frames a second it carves 26, because the foot is only asked where it is when a frame comes.
- **Place:** Become it: attach the chain to your hand (headset) or the carried point and walk it through Trans_Body's lattice, carving a passage with your own movement ('chip from chip').
- **Families in the hall:** carousel_cake.profile (cake / ziggurat / column / spindle / flare) in Trans_Rotation: family shown: cake, column, flare, spindle, ziggurat; translation_cube_demo.course (lift_lateral / lateral_lift / lift_depth / lateral / free) in Trans_Translation: family shown: free, lift_lateral; boolean_tunnel.accrual (ramp / burst / mirror / plateau / none) in Trans_Rotation: one value shown: ramp
- **In your room:** Give one body in your room a jointed part that moves.

#### 11. A body of parts: the first assemblage

- **Operation:** assemble. **Spine:** transformation. **Halls:** Trans_Introduction (carrier), Trans_Scale (carrier), Trans_Body (field trip), Trans_Pre (encounter).
- **Code:** new instancing, composition; returns transforms, basis, properties, lifecycle, delta.
- **Body:** The parts you have made so far, saved as scenes and instanced into one body: the point (ch2), the cube (ch8), your plane (ch7) and the three-segment limb (ch13), each a PackedScene, each added as a child of one root Node3D with its own pivot. Move the root and every part follows; turn the limb and only the limb's children follow; scale the root and the whole body scales, cube and plane together. The scene tree is the first assemblage: a body is parts in relation, and the tree says which relation.
- **Argument:** axis how the same four parts are parented: flat: four children of the root / a chain: each part the child of the one before / a chain with offset pivots / two chains from one hip. Predict: At rest all four look the same, and they still look the same when the root turns 30 degrees: every pair differs on 0.00% of the frame, because a root carries everything below it whatever the tree looks like. Turn every pivot 30 degrees and they part: flat and two chains stay closest (0.55% of the frame), the offset chain and two chains are farthest (4.77%), and the toe travels 0.47 m in the flat body against 2.61 m at the end of the chain. Write which pair you expect closest, and when you expect any difference at all, before you render. Claim: The structure of an assemblage is invisible at rest and while only its root moves; it shows when a part inside moves. The tree, not the parts, says what the body does.
- **Debt:** A hierarchy is a command chain. The root moves, the leaves obey, and nothing in the picture shows who commanded whom. Klee drew it as brain, muscle, bone, active to passive; Godot draws it as a tree whose root you chose. The debt is that the choice of root is a choice of who gets to be the body's centre, and the default (the first node you made) is not a neutral one.
- **Place:** Carry the root: pick the whole body up (XR hand or desktop carry) and the parts come with it, pivots and all. Then walk into Trans_Scale with it: the room scales by four, the body scales with the room, and the door you could not use before is usable; the body's relations survive the scale, which is what a hierarchy is for.
- **Process strip:** point (ch02) -> + plane (ch07) -> + cube (ch08) -> + limb (ch13) -> pivots set -> a chain -> every pivot turned
- **Families in the hall:** matrix_4x4_viewer.pose (none / translate / rotate / scale / shear / project) in Trans_Introduction: one value shown: translate; balance_puzzle.tell (mark / none / ghost / exemplar) in Trans_Introduction: at its default; rotation_gimbal.regime (free / approaching / locked / past) in Trans_Introduction: at its default
- **In your room:** Your room's first assemblage: at least three parts of different origin (one made in code, one drawn by hand in the editor, one carried in from a classmate's scene) under one root. Decide the root and write one line in the README saying why that part commands.

### Repeat and vary (arrays; the family; Melencolia)

*You can make many from one by a rule, turn a body into a family with named parameters, tune it live, measure what a value costs, and let a scanned body join the family: the second assemblage.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage.

Of the plate, now: Counting round the axis: three feet, eighteen teeth. Then the shell as one class with its numbers, and the plate as a comparison sheet of one family (form).

#### 12. The chessboard: purely repetitive and therefore structural

- **Operation:** repeat. **Spine:** array_tutorial, primitives, color. **Halls:** Point_Line_Grid (carrier), Array (carrier), Tutorial_3D (field trip), Color_Rainbow (field trip).
- **Code:** new nested_loops, materials; returns loops, arrays, conditions, expressions, collision, booleans, instancing.
- **Body:** A floor of cubes instanced from a PackedScene in a nested loop. Each cube gets a StandardMaterial3D made in code, coloured by a rule over (x, z): first two colours of your own, then a hue from the index, Color.from_hsv(float(x + z) / (2 * n), s, v).
- **Argument:** axis rhythm rule over the same 8 x 8 cubes: every cell alike / (x + z) % 2 chessboard / x % 3 stripes / hue from x + z. Predict: Cell by cell, every cell alike and the x % 3 stripes are the closest pair: they differ in 24 of 64 cells (measured: 11.12% of the frame from the study camera). The chessboard and the stripes disagree on about half the floor (14.26%). Only when the cells are averaged away do the chessboard and the stripes come closest, and that distance was not rendered: it is arithmetic on the stills. The stripes have a direction too: swapping x and z changes 30 of their cells. Write the pair you expect before you render, and say from how far. Claim: Structure is the repetition rule, not the cube: the same 64 bodies make four different floors.
- **Debt:** The grid is the unexamined ground of 3D (editor grids, voxels, the frame buffer as a grid, after Gaboury); it is a choice, and the standing ruling holds that the first line did not need it. HSV promises equal steps of hue, and the eye does not see them as equal: the yellow band looks brighter and wider than the blue one. Measured in the kit: the planted integer division, (x + z) / (2 * n) without float(), gives hue 0 in all 64 cells, a red floor with one warning and no error. One material made before the loops is one material on 64 cubes: change one cube and all 64 change. And the gap a body meets depends on how fast it arrives: a marble let go at 0.75 m passes when the gap equals its width, to the millimetre; dropped from 2 m it passes 2 cm earlier and, just below that, sticks between the cubes. Why it switches where it does is not explained.
- **Place:** Walk the floor; turn one cell into a ghost with ch3's if and fall through it.
- **Process strip:** one cube -> a row -> the floor -> two colours -> hue by index -> a ghost cell -> spacing opened
- **Families in the hall:** column_3_z.notation (label / none / tape / tally / plate) in Array: one value shown: plate; grid_2d_4x4.notation (label / none / tape / tally / plate) in Array: one value shown: plate; modulor_man_demo.measure (body / scale / canon / module / crowd) in Point_Line_Grid: one value shown: scale
- **In your room:** Lay a floor for your room with a rhythm rule of your own and two colours you chose.

#### 13. Families: one body in a single class

- **Operation:** parameterise. **Spine:** primitives. **Halls:** Primitives_Ignorance (carrier), Primitives_Polythedra (encounter).
- **Code:** new classes, export, types; returns functions, parameters, instancing, loops, meshes, variables.
- **Body:** Describe a body in a single class: class_name with two typed @export fields (for a sphere, rings and segments; for your own body, whatever makes it) and a build() function that makes the mesh in _ready(). The supplied sweep sheet instances four members side by side, labelled.
- **Argument:** axis sphere segments (rings = half): 4 / 8 / 16 / 64. Predict: 16 and 64 will look most alike at 2 m (measured: they differ on 0.85% of the still from the side, 0.99% from above, and stay the closest pair lit flat, at 4.65%). Most of that likeness is smooth shading: the rim differs by a band about 3 pixels wide. From above, the outline of 16 misses the circle by 2.06% (the chord arithmetic gives 1.92%). 4 is another body, but not the octahedron: with rings at half it has two rings and 16 triangles. Write the pair you expect, and what you think the likeness is made of, before you render. Claim: The class's integer decides which body you have, and there is no step where a sphere stops paying: against 64 the difference falls evenly, 15.27, 5.17, 0.85, 0.19% for 4, 8, 16 and 32 segments. What looks like enough is a decision about distance and light.
- **Debt:** A class's fields decide which bodies are possible (the CCSWG prompt 'describe it in a single class', turned to a body): an int cannot have 3.5 segments, and no value of rings makes a torus. Polycount against smooth deformation, the application's topology question, enters here. Measured in the kit: set() on a typed int does not refuse a text. It converts it in silence: '16' becomes 16, 'sixteen' becomes 0, '4 8 16 64' becomes 481664, and 640 passes an @export_range of 4 to 64. What set() does refuse in silence is a name the class does not have, and a number handed to a String field. So the planted fault is a wrong field name: four members come back alike under four different plates, and only the printed triangle counts say so (the Ada project's own science_screen case).
- **Place:** Walk the sheet as a gallery wall; carry one member into your room.
- **Process strip:** a sphere, written out -> the same, as a class -> a row of four -> hung and named -> the axis by name: four alike -> the right name
- **Families in the hall:** prism_block.grain (solid / split / quartered / lattice / shell) in Primitives_Polythedra: family shown: quartered, shell; cube_scene.grain (solid / split / quartered / lattice / shell) in Primitives_Ignorance: one value shown: quartered; dark_sphere.body (orb / swarm / cage / cairn) in Primitives_Ignorance: one value shown: cairn
- **In your room:** Turn one of your bodies into a class with two axes; write the closest-pair prediction before rendering its sheet.
- **Departure:** return: the family is declared at the first family hall (Primitives_Ignorance), once there are many to vary (after the chessboard).

#### 14. The family in the editor: setters, @tool and the sheet opened

- **Operation:** tune. **Spine:** primitives, color, softbodies. **Halls:** Primitives_Ignorance (carrier), Color_Context_Placed (field trip), Topology_Entropy_Morphogenesis (field trip).
- **Code:** new setters, tool_scripts, methods; returns classes, export, types, instancing, loops.
- **Body:** Your class with setters that rebuild on change, a rebuild() method, and @tool so the family changes live in the editor (Color_Context_Placed's chroma_stack with its @export_enum rule is the precedent). Then open the supplied sweep sheet and rewrite it yourself, one labelled member per value. For the argument the sheet sweeps Ada's own pyramid (commons/primitives/pyramid/pyramid.gd), whose @export_enum you read rather than retype. pyramid.gd builds its mesh only in _ready(), so the sheet must set apex_stance before add_child(): set it afterwards and nothing changes, which is the reason your own class gets a setter.
- **Argument:** axis where the apex sits over the base: apex_stance, the @export_enum in Ada's pyramid.gd (base 0.6 m, height 0.8 m): centred / edge / corner / beyond. Predict: corner and beyond will look most alike. In pyramid.gd's own numbers the apex sits at (0, 0), (0, -0.3), (-0.3, -0.3) and (-0.48, -0.48) in plan: corner and beyond are 0.25 m apart, the closest pair, while centred to edge and edge to corner are 0.30 m apart, and corner and beyond lean along the same diagonal. What the sheet has to show is the one thing the distances do not rank: beyond is the only member whose apex has left its own footprint. Claim: One exported enum carries a pyramid from monument to lean-to, and the step that changes the category is not the largest step.
- **Debt:** The Inspector slider hides what each value costs and what it breaks. Defaults are sacred: an Ada artifact can have hundreds of live placements, so changing a default silently changes every hall it stands in. A setter that rebuilds on every change can stall the editor, and a @tool script runs your bugs inside the editor itself. And the values on your sheet must be read from the code, not typed from memory: a value the class's match does not know falls back to the default without an error, and the sheet shows the same body several times (the Ada DNA programme's science_screen case).
- **Place:** Carry it: a supplied in-world slider changes the family while you hold the body.
- **Families in the hall:** chroma_stack.stack (bauhaus / turned / cut / beads / discs / offset) in Color_Context_Placed: family shown: bauhaus, beads, cut, discs, festival, offset, turned; color_dna_stack.study (mondrian / albers / memphis / bauhaus_tall / blue / kras_rainbow) in Color_Context_Placed: family shown: albers, bauhaus_tall, blue, kras_rainbow, memphis, memphis_beacon, mondrian, rainbow_crown; cube_scene.grain (solid / split / quartered / lattice / shell) in Primitives_Ignorance: one value shown: quartered
- **In your room:** Turn your room's main body into a family with one exported axis and hang its comparison sheet at the entrance.
- **Departure:** return: tuning the family live belongs beside its declaration; the colour and softbodies halls are visits.

#### 15. The budget: polycount measured, a claim tested

- **Operation:** budget. **Spine:** primitives, formfinding. **Halls:** Primitives_Portals (carrier), FormFinding_Catenary (carrier), Primitives_Ignorance (field trip).
- **Code:** new testing, profiling; returns export, loops, surface_tool, functions.
- **Body:** A parametric surface, the catenoid (u, v) -> point, with exported u_steps and v_steps: you write the two loops over u and v and the SurfaceTool emission, and call a supplied catenoid(u, v) for the point itself (FormFinding_Catenary's formula, with cosh and cos, read now and opened at ch24). Beside it, Primitives_Portals' torus ring, whose segments double while its gap to the true circle is printed and asserted, using the supplied one-liner gap_to_circle(n) = 1 - cos(PI / n).
- **Argument:** axis u_steps of the catenoid: 6 / 12 / 24 / 48 / 96. Predict: 48 and 96 will look most alike at 2 m: at 48 steps the chord misses the circle by 1 - cos(3.75 deg), about 0.2% of the radius, while 96 costs twice the triangles. The prediction is also written as a test: gap_to_circle(n) < 0.01 passes from n = 24 (0.86%) and fails at 12 (3.4%). Claim: A parametric surface has a step count below which it is a different body and above which it is only cost: the test finds the first, the profiler the second.
- **Debt:** 'Smooth' is a budget decision (application l.89: polycount against deforming a body smoothly), and in a headset at 72-90 Hz every triangle is drawn once per eye. A green test is a fact about the question you asked, not about the body (Montfort: valid and intentional are different).
- **Place:** Stand in it: the catenoid as a neck you walk through at room scale (collider from the mesh). The headset's frame time is the debt you feel: stutter makes people sick, so comfort is not polish.
- **Families in the hall:** cable_builder.slack (catenary / chord / spline / festoon / truss) in FormFinding_Catenary: at its default; capsule.facture (cast / facet / armature / section / wear) in Primitives_Portals: at its default; combine_portals.taxonomy (table / ladder / stack / heap) in Primitives_Portals: at its default
- **In your room:** Measure your room's frame time on the target machine and cut the one body that costs most without changing what it argues.
- **Departure:** return: the budget is the family's debt (polycount against deformation), so it is paid where the family is; the catenoid is a form-finding visit.

#### 16. Collage: a found body joins the family (assemblage II)

- **Operation:** collage. **Spine:** primitives. **Halls:** Primitives_Melencolia (carrier).
- **Code:** new import_assets; returns classes, export, meshes, surface_tool, ai_assist, export_build, errors.
- **Body:** Recreate a precedent: the truncated solid of Durer's Melencolia I built as a member of your family, beside a body you scanned (phone photogrammetry in week one) or drew in Tilt Brush or Blender and imported as glTF.
- **Argument:** axis how the body was made: by hand / drafted from your three lines / found (a stand-in for a scan). Predict: By hand and drafted will look most alike, and here they are the same picture: 0.00% of the still differs from the side, from above and lit flat. The reason is not that they share primitives (one is built with SurfaceTool, the other from an indexed array); the three lines named every number the picture shows. Ask both for a value the lines did not name and they part: a cut of 0.9 is clamped by one and kept by the other, and the stills differ on 14.88%. The found body differs from the solid on about 3% and has 5,851 triangles to its 20. Whether a real scan is the outlier by count and not by silhouette is not tested here: the stand-in was made from the solid, so its outline is near by construction. Write the pair you expect, and what would make two bodies made the same way differ. Claim: Two bodies that look the same have agreed only about what was named. How a body was made shows in what it does with a value nobody asked for, and in its triangle count.
- **Debt:** Recreation (SFPC Recreating the Past): the difference between Durer's solid and yours is where the debt is written; the Melencolia hall already says its hidden surfaces 'are decisions we have made'. The scan has millions of triangles, holes and no inside, and whose bodies scan well is not neutral (Queer 3D: stretchability, topology, bias). Measured in the kit: the import arrives 99.04 m high, its lowest point 4.3 m up and 43 m from its plate, with none of its corners in view. Godot prints no error and still reports the triangle count; the picture shows an empty plate. Scale alone does not bring it home: the file has its own origin, and that is a second fault. The drafted answer in the kit came from one question put once to an assistant of the same kind as the one that wrote the lesson, so it is not an independent witness.
- **Place:** A hybrid room (Queer 3D's ontology layer): imported and procedural bodies share one floor. Export the build and show it.
- **Process strip:** the cube, pulled -> stood on its diagonal -> two corners cut -> a drafted answer -> a found body arrives -> its unit and its origin
- **Families in the hall:** code_display.support (none / stand / frame / pylon) in Primitives_Melencolia: at its default; cube_scene.grain (solid / split / quartered / lattice / shell) in Primitives_Melencolia: at its default; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Primitives_Melencolia: at its default
- **In your room:** SYNTHESIS II and the short track's pivot: export your room as a build with your family and one found body. The mini project starts from this build.
- **Departure:** return: Melencolia, the last primitives hall, closes the repeat-and-vary part as its assemblage; it needs the family and the import.

### Surface (colour, tiling)

*You can give any body a colour system and a patterned skin by rule, and dress the assemblage so that the seam between made and found stays visible.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern.

Of the plate, now: The pores: cells of six, opened, wider toward the mouth; bone white on black. Here the vase becomes a skeleton (stage: pored).

#### 17. A colour has many faces

- **Operation:** colour. **Spine:** color. **Halls:** Color_Walls (carrier), Color_Flashlight (carrier), Color_Paint (field trip), Color_Pillar (field trip), Color_Nails (encounter).
- **Code:** new interpolation; returns materials, classes, export, loops.
- **Body:** A wall of steps between two complementary colours, lerped in RGB and in HSV side by side; a flashlight whose light colour you carry changes what the wall's colours look like (Albers: one colour made to look like two).
- **Argument:** axis the space the same two complementaries are mixed in: RGB / HSV / linear-light RGB / a supplied perceptual space (OKLab). Predict: RGB and linear-light RGB will look most alike: both pass through a grey middle, Klee's central grey, and differ only in where the grey falls. HSV swings round through the hues in between and never reaches grey. Claim: The middle between two colours is not in the colours but in the space you mix them in: RGB finds Klee's central grey, HSV walks around it.
- **Debt:** Colour spaces are standards built for a measured 'average' eye and calibrated on particular skins (the Shirley card); sRGB against linear is the engine's hidden correction. Albers: colour deceives continually.
- **Place:** Carry the flashlight along the wall: the same painted step changes colour under your light; then paint the wall with your ray (Color_Paint).
- **Families in the hall:** color_constellation_office.mixture (bench / light / retina) in Color_Walls: at its default; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Color_Walls: at its default; flashlight_demo.ground (white / swatch / relief / mirror / none) in Color_Flashlight: at its default
- **In your room:** Choose your room's palette by argument: one pair of colours, one mixing space, one sentence.

#### 18. Pattern: structure moves into the surface

- **Operation:** pattern. **Spine:** tiling, array_tutorial, shaders. **Halls:** Tutorial_Tiling_Floor (carrier), Symmetry_Seventeen (carrier), Tutorial_Pattern (field trip), Pattern_Foundry (field trip), Shader_05_Patterns (encounter).
- **Code:** new uv, dictionaries; returns nested_loops, materials, functions, conditions.
- **Body:** A tile written pixel by pixel into an Image from a 4 x 4 source kept as a Dictionary recipe {size, source, rule}, wrapped as an ImageTexture and repeated over your floor by UV scale; one get_color(x, y) function per symmetry rule (Symmetry_Seventeen's p1, pm and pg).
- **Argument:** axis wallpaper rule over one 4 x 4 source: p1 translation / pm mirror / pg glide / p4 rotation. Predict: pm and pg will look most alike: both keep one mirror direction, and the glide only shifts alternate rows by half a tile. p4 is the outlier, the only one without a single preferred direction. Claim: The same sixteen pixels make four patterns: symmetry is a rule applied to a source, and the rule is what we see.
- **Debt:** Texture filtering and mipmaps blur the rule at a distance (nearest against linear); the seventeen wallpaper groups are a closed classification that the ornament traditions they describe never needed.
- **Place:** Floor and walls of your room share one texture; walk away until the pattern reads as tone rather than tiles. Then walk Shader_05_Patterns: the same kind of symmetry rule, computed for every pixel on every frame by the graphics card instead of written once into an Image. You write one at ch30.
- **Process strip:** a 4 x 4 source -> a symmetry rule -> pixels into an Image -> an ImageTexture -> UV scale over the floor -> dress each part of the assemblage
- **Families in the hall:** pattern_artifact.group (unset / p1 / p2 / pm / pg / cm) in Symmetry_Seventeen: at its default; pattern_atlas_gallery.credit (named / title_only / redacted / anonymous) in Symmetry_Seventeen: at its default; pattern_loom.colophon (none / repeat / symmetry / catalogue) in Symmetry_Seventeen: at its default
- **In your room:** Give your room one pattern of your own made from a 4 x 4 source. Then dress the assemblage from Part 3: every part of your body of parts gets a material from your palette (ch29) and one tiled skin by rule; the imported part keeps its own texture, so the seam between made and found stays visible.

### Move by law (change, forces, form finding, waves)

*You can write motion as steps, give a region its own law, open the walker you have used since day one, balance a body, make legs that follow, climb a spiral and hear a swing: bodies that move by rules you wrote.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern, integrate, walk, push, follow, balance, climb, swing, sound, field.

Of the plate, now: Feet that curve, drawn as a path made of steps. A shell that sinks and drifts under a force you wrote.

#### 19. The bullet: a curve made of steps

- **Operation:** integrate. **Spine:** change, forces. **Halls:** Change_Intro (carrier), VFM_05_Launch (carrier), VFM_07_Gravity (field trip).
- **Code:** new integration; returns delta, vectors, loops, arrays, meshes.
- **Body:** A launched body moved by your own loop (velocity += gravity * dt; position += velocity * dt), its path kept in an array and drawn as a line (ch6's trace, now written by physics) (the same launch as a RigidBody3D is compared at ch23, where bodies arrive).
- **Argument:** axis time step dt, same launch: 1/10 s / 1/30 s / 1/60 s / 1/240 s. Predict: 1/60 and 1/240 will look most alike: their landing points are a few centimetres apart. 1/10 is visibly a polygon and lands somewhere else. Claim: A simulated curve is a sequence of steps: below some step size it is the curve, above it the steps are the drawing. The trace's sampling gate (ch6) returns as physics.
- **Debt:** Integration is an approximation that owes energy: explicit Euler makes an orbit leak outward (the VFM_07_Gravity field trip), semi-implicit Euler keeps it nearly closed, and the engine's own integrator hides the same choice behind 'physics ticks per second'.
- **Place:** Stand where you predict it will land and let it hit you (a soft collision); then move to where it lands.
- **Families in the hall:** ftc_bridge.evidence (result / trace / longhand) in Change_Intro: one value shown: longhand; synthesis_stand.mode (auto / hero / series) in Change_Intro: one value shown: hero; ForceMagnitudeDemo.measure (both / acceleration / velocity / none) in VFM_05_Launch: at its default
- **In your room:** Launch something in your room with your own integrator; keep the dt you chose and why.

#### 20. Eye level: the walker opened

- **Operation:** walk. **Spine:** forces, transformation, foundationscrisis. **Halls:** VFM_03_Motion (carrier), Trans_Scale (field trip), Escher_Impossible (field trip).
- **Code:** new camera, input, player; returns transforms, collision, vectors, conditions, xr, delta.
- **Body:** The walker you have used since ch1, opened: a CharacterBody3D with move_and_slide(), InputMap actions and your own Camera3D whose height and field of view you change. Its capsule is swapped for a body of your family, and railroad tracks made in a loop run to the horizon.
- **Argument:** axis eye height: 0.3 m (crawling) / 1.1 m (seated, or a child) / 1.7 m (standing adult) / 8 m (bird). Predict: 1.1 and 1.7 will look most alike: the horizon sits mid-frame in both and the ties converge alike. 8 m flips the tracks into a plan. Claim: Perspective is a fact about the eye's height, not about the tracks: the same geometry gives a plan or a corridor.
- **Debt:** The camera decides what exists (frustum, near plane; 'an iso view is half blind'), and the default player is a capsule with an eye at a standing adult's height; the headset's default floor height and eye distance assume the same body (Bagnall). Montfort's 'Critique My Starter Programs', turned on Godot's capsule.
- **Place:** In the headset your head is the camera: crouch and the horizon moves with you. Trans_Scale scales the room by four and relocates you: you are the scale that changed.
- **Families in the hall:** ForceMagnitudeDemo.measure (both / acceleration / velocity / none) in VFM_03_Motion: at its default; VectorForces.regime (crosswind / freefall / stalemate / liftoff) in VFM_03_Motion: at its default; VectorMotion.drive (constant / central / inertial / resisted) in VFM_03_Motion: at its default
- **In your room:** Put the player in your room at an eye height you choose, and write why.

#### 21. Regions with other laws

- **Operation:** push. **Spine:** forces. **Halls:** Vectors_Act5_ForceAsPlace (carrier), Vectors_Act4a_KineticForces (carrier), VFM_03_Motion (field trip).
- **Code:** new forces, areas, physics_bodies; returns integration, vectors, player.
- **Body:** An Area3D that replaces gravity with an @export acceleration for any body inside it, the player included, and restores it on exit; your own drag and wind as functions that return force vectors, summed per step (NoC's apply_force).
- **Argument:** axis the region's gravity (still 0.5 s after six family members are released): normal (0, -9.8, 0) / half / zero / reversed. Predict: half and zero will look most alike: after 0.5 s the half-gravity bodies have fallen about 0.6 m and the zero-gravity ones not at all, so both clusters hang near the release height; normal (1.2 m down) and reversed (1.2 m up) are mirror images. Claim: A law is a property of a place: the same body falls, floats or rises depending on the region it is in.
- **Debt:** Whose physics is 'normal'? The default gravity is Earth's, tuned for a standing body; a region with another law is a room where other bodies are the norm. A field is also control: the Area3D decides what enters it.
- **Place:** Walk into it: the player's own gravity changes at the border; jump in each region.
- **Families in the hall:** drag_corridor.swimmer (dart / extinguisher) in Vectors_Act4a_KineticForces: at its default; force_cube.decomposition (both / chain / box / none) in Vectors_Act5_ForceAsPlace: at its default; force_field_zone.law (gravity / lift / crossing / weightless) in Vectors_Act5_ForceAsPlace: at its default
- **In your room:** Give your room one region where the law is yours.

#### 22. Legs: the passive part drives

- **Operation:** follow. **Spine:** forces, transformation. **Halls:** VFM_09_Legs (carrier), Trans_Pit (field trip).
- **Code:** new raycasts; returns transforms, basis, physics_bodies, loops, classes, composition.
- **Body:** A leg as a chain that follows its foot: each segment looks at the next and keeps its length (the follow half of FABRIK, one loop), so the foot leads and the hip follows. Feet find the ground with raycasts, and four Leg scenes are composed into a creature that walks over your noise terrain from ch12.
- **Argument:** axis segments per leg, same total length: 1 / 2 / 3 / 6. Predict: 3 and 6 will look most alike on uneven ground: both bend smoothly around a step. 1 cannot bend at all, so its foot hangs above or sinks below the ground. Claim: How many joints a limb has decides which grounds it can meet: the foot's target drives, and the body follows.
- **Debt:** 'In drag' as a code operation: in ch13 the parent commanded the child; here the passive end drives and the chain follows. Klee's active and passive (and his male and female) are inverted in the scene tree, not in a costume. The ray only sees colliders on its mask: which ground exists for the foot is a layer setting.
- **Place:** Carry the foot: grab one foot target (desktop carry or XR hand) and drag it; the leg follows you, and the creature's body follows the leg.
- **In your room:** Give one body in your room legs that find the ground, or a part that follows the visitor's hand.

#### 23. The tightrope walker: balance

- **Operation:** balance. **Spine:** formfinding, forces. **Halls:** FormFinding_Equilibrium (carrier), FormFinding_Forge (carrier), VFM_09_Legs (field trip).
- **Code:** new signals; returns collision, transforms, instancing, conditions, player, physics_bodies.
- **Body:** A plate on posts as a RigidBody3D whose centre of mass you move, released onto two, three or four legs (VFM_09_Legs' tip-or-hold); a signal fallen() fires when it tips and a counter listens; then a stack of your family members that must stand (FormFinding_Forge's balance puzzle).
- **Argument:** axis centre-of-mass offset relative to the support polygon (still 3 s after release): at its centre / halfway to the edge / on the edge / outside. Predict: 'centre' and 'halfway' will look most alike: both stand, level. 'outside' has fallen. 'on the edge' is the prediction's risk: it may hold or tip, and the still decides. Claim: Standing is a fact about the centre of mass and the support polygon, not about how heavy or large the body looks.
- **Debt:** The engine's rigid body is a promise that nothing bends; stacking is solved by iterations, so a tower that should stand can jitter and one that should fall can fall asleep. Klee: the tightrope walker 'is the scale', balance as a relation, not a posture.
- **Place:** Stand on it: step onto the plate yourself (the player is a body too) and feel where it tips.
- **Families in the hall:** balance_puzzle.tell (mark / none / ghost / exemplar) in FormFinding_Forge: at its default; calder_mobile.lever (solved / halved / inverted) in FormFinding_Equilibrium: at its default; science_screen.support (stand / frame / cabinet / pylon) in FormFinding_Equilibrium: at its default
- **In your room:** Make one of your family stand on as few points as it can; predict which member falls.

#### 24. The stair climber: a spiral you can walk

- **Operation:** climb. **Spine:** wavefunctions. **Halls:** Wavefunctions_Sky_Stairs (carrier), WaveFunctions_TrigWalkingPath (field trip), WaveFunctions_Unit_Circle (encounter).
- **Code:** new trig; returns surface_tool, collision, loops, player, functions, testing.
- **Body:** A spiral stair: tread i placed at (r cos(i a), i rise, r sin(i a)) with a collider per tread, climbed by the walker from ch19; a headless test asserts that the walker reaches the top.
- **Argument:** axis rise per tread: 0.10 m / 0.18 m / 0.30 m / 0.60 m. Predict: 0.10 and 0.18 will look most alike: both read as a stair. 0.60 reads as a column of blocks, and the walker cannot climb it, because its step limit is lower. Claim: A stair is a relation between a function and a leg: the same spiral is a path for one body and a wall for another.
- **Debt:** Klee's stair climber assumes legs: every rise excludes a body that does not climb, and the capsule's step height is a hidden standard of who can go up. The collider is a flight of boxes approximating a curve.
- **Place:** Climb it, and look down the well from the top. Then build the ramp version and walk both.
- **Families in the hall:** cube_scene.grain (solid / split / quartered / lattice / shell) in Wavefunctions_Sky_Stairs: at its default; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Wavefunctions_Sky_Stairs: at its default; math_objects.taxonomy (table / ladder / stack / heap) in Wavefunctions_Sky_Stairs: at its default
- **In your room:** Give your room a way up that a body can take, and write whom it excludes.

#### 25. Pendulum, circle, spiral: time laid into space

- **Operation:** swing. **Spine:** wavefunctions, fractals, forces. **Halls:** WaveFunctions_Pendulum (carrier), WaveFunctions_Unit_Circle (carrier), Fractal_GoldenSpiral (field trip), Vectors_Act4b_Oscillation (field trip).
- **Code:** new queues, multimesh; returns trig, delta, arrays, integration, loops.
- **Body:** A pendulum sampled in _physics_process into a bounded queue and laid out in space as one MultiMesh of marks, so the swing's time becomes a sculpture; then the same runner at (cos t, sin t), a circle; then the radius changes each turn, a spiral starting at 0.5 m.
- **Argument:** axis radius change per turn (still at the tenth turn): -0.2 m / -0.05 m / 0 / +0.05 m / +0.2 m. Predict: -0.2 and -0.05 will look most alike: both have died into the centre by the tenth turn (-0.2 after two and a half turns, -0.05 exactly at the tenth). 0 is the only closed form; the growing ones differ only in how wide they open. Claim: The sign of one number decides whether the form lives or dies: Klee's lengthening radius makes a 'vibrant spiral', the shortening one 'dies suddenly in the static center'.
- **Debt:** A MultiMesh draws thousands of marks in one call and pays in flexibility: every mark shares one mesh and one material. The queue forgets: the sculpture is only the last N samples. And a pendulum that returns forever is an idealisation (the damping you left out).
- **Place:** Walk through the swing's sculpture; stand inside the dying spiral's centre.
- **Families in the hall:** BigPipeSystem.slack (spline / chord / catenary / festoon / truss) in WaveFunctions_Pendulum: at its default; GlassRack.admission (none / bench / residue / exhibit) in WaveFunctions_Pendulum: at its default; VRAudioMonitor.feed (live / test / saturated) in WaveFunctions_Pendulum: at its default
- **In your room:** Lay one motion of your room into space as a sculpture a visitor can walk through.

#### 26. Sound: the swing heard

- **Operation:** sound. **Spine:** wavefunctions, array_tutorial. **Halls:** WaveFunctions_Effect_Sound (carrier), WaveFunctions_AirMusic (carrier), WaveFunctions_Synthesis_Lab (field trip), Tutorial_Disco (field trip).
- **Code:** new audio, packed_arrays; returns trig, loops, areas, multimesh.
- **Body:** Two tones rendered sample by sample into an AudioStreamWAV (a PackedByteArray), played from an AudioStreamPlayer3D inside an Area3D you walk into; the same two sines drawn as a Lissajous figure in a MultiMesh, so the chord is also a body.
- **Argument:** axis frequency ratio of the two tones: 1:1 / 2:1 / 3:2 / 45:32. Predict: 2:1 and 3:2 will look most alike: both close into small knots of a few lobes. 45:32 (the tritone) closes only after 32 turns of the slower tone, so in the still it fills its square. Claim: Consonance has a shape: simple ratios close into small figures, and the tritone fills the square before it closes.
- **Debt:** Sampling again: 44 100 numbers a second stand in for a wave, and anything above half that rate folds back as another tone (aliasing). The octave and the fifth are one tuning tradition's consonances, not nature's.
- **Place:** Walk into the chord: stand in each Area3D and hear it; stand where two overlap.
- **Families in the hall:** DualBallFMController.evidence (result / trace / sources / longhand) in WaveFunctions_Effect_Sound: one value shown: longhand; timbre_sculptor.waveform (sine / square / sawtooth / triangle / formant) in WaveFunctions_Effect_Sound: one value shown: square; rack_room.machinery (none / plate / vacancy / frame / works) in WaveFunctions_Effect_Sound: at its default
- **In your room:** Give your room a sound that is computed, not recorded.

#### 27. The arrow and the field of arrows

- **Operation:** field. **Spine:** change, forces. **Halls:** Flow_Field (carrier), Vectors_Act3_FieldsAndMotion (carrier).
- **Code:** new particles, lifetime; returns vectors, forces, raycasts, multimesh.
- **Body:** A field of arrows sampled over the room from a supplied field function (opened at ch12, Noise) (an arrow per cell, one MultiMesh) and particles released into it that live a few seconds and follow it. Your hand's ray (ch21) is Klee's arrow: where it points, the field bends toward you (Code as Creative Medium's Personal Prosthetic).
- **Argument:** axis the field's noise frequency: 0.02 / 0.05 / 0.2 / 1.0. Predict: 0.02 and 0.05 will look most alike: broad currents, a few long streams. At 1.0 every arrow disagrees with its neighbour, the field is fur, and the particles go nowhere. Claim: A field is invisible until bodies move through it: the frequency decides whether it is weather or static.
- **Debt:** The blob aesthetic returns as flow: smooth noise makes 'natural' currents because it was built to. GPU particles are a black box you configure rather than write, and their lifetime is a budget, not a life. Reach is power: which bodies the arrow can touch is a collision mask.
- **Place:** Become the arrow: point your hand and the field bends; walk through the stream and the particles part around your collider.
- **Borrows:** field.gd: sample(x, z) -> Vector3, a smooth field over the room (opened at ch12, where noise is taught) (use)
- **Families in the hall:** field_room.law (gravity / point_charge / dipole / vortex) in Vectors_Act3_FieldsAndMotion: at its default; VectorFieldFlow.field (spiral / orbit / sink / source) in Vectors_Act3_FieldsAndMotion: at its default; VectorMotion.drive (constant / central / inertial / resisted) in Vectors_Act3_FieldsAndMotion: at its default
- **In your room:** Give the visitor an arrow: a way to reach into your room from a distance and change it.
- **Departure:** return: the field of arrows (change, spine 6) closes Part 5 because it needs the part: forces for the particles, the hand's ray from legs, the MultiMesh from the swing; the field itself is a supplied function until noise (ch12).

### Disturb, field, skin (randomness, noise, shaders)

*You can let chance in with a seed, make ground from a field that remembers its neighbour, bend any body with that field, write a skin per pixel, and assemble a round someone can lose: the midterm.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern, integrate, walk, push, follow, balance, climb, swing, sound, field, disturb, noise, displace, skin, play.

Of the plate, now: Bristles from a seeded chance (stage: bristled). Pores whose size follows a noise field, as on the large shell in the middle of the plate. A shader for the engraved line.

#### 28. Disturbed order: chance enters the grid

- **Operation:** disturb. **Spine:** randomness. **Halls:** Randomness_10_PRINT_Algorithm (carrier), Random_Definition (carrier), Random_Remove (field trip), Random_Walk (field trip).
- **Code:** new random, seeds; returns nested_loops, instancing, materials, collision, loops.
- **Body:** Schotter as a floor: your chessboard of cubes rotated and displaced by a seeded RandomNumberGenerator, more with every row; and 10 PRINT as a walkable maze, one of two rotations per cell.
- **Argument:** axis disorder amplitude (maximum rotation in the last row): 0 degrees / 5 degrees / 20 degrees / 90 degrees. Predict: 0 and 5 will look most alike: 5 degrees moves a 1 m cube's corner about 6 cm, less than the gap between cubes, so the grid still reads. Somewhere between 5 and 20 it stops reading as a grid. Claim: Randomness is visible only against a structure already built: the grid is what lets us see disorder.
- **Debt:** Computer randomness is pseudo-random: the same seed returns the same 'chance' (Random_Definition: a pattern that returns). Nake's question from Hommage a Paul Klee (1965): can a pseudo-random number stand in for the artist's intuition? And a seed is a promise of repeatability that someone else can use to reproduce you.
- **Place:** Walk down the Schotter floor until the disorder makes it unwalkable (the colliders follow the cubes); get lost in the 10 PRINT maze.
- **Families in the hall:** ten_print_structure.form (floor / wall / overhead) in Randomness_10_PRINT_Algorithm: family shown: floor, wall; ten_print.semicolon (on / off) in Randomness_10_PRINT_Algorithm: one value shown: on; seed_replay_demo.comparison (single / replicas / seeds / ladder / offset) in Random_Definition: one value shown: replicas
- **In your room:** Add a seeded disorder to your floor and record the seed you keep.

#### 29. Noise: chance that remembers its neighbour

- **Operation:** noise. **Spine:** noise, randomness. **Halls:** Noise_Space_10 (carrier), Noise_Columns (field trip), Random_Space_Geometry (field trip), Random_Noise_Types (encounter).
- **Code:** new noise; returns random, seeds, surface_tool, normals, collision, nested_loops, packed_arrays.
- **Body:** A small walkable terrain: FastNoiseLite sampled on a grid into a PackedFloat32Array of heights, multiplied by an edge envelope and emitted as an ArrayMesh with a collider made from it (Noise_Space_10's body). A supplied heightfield helper covers the mesh step in the short track.
- **Argument:** axis where the heights come from, all at the same amplitude and grid: randf() per vertex / sin(x) * sin(z), from the supplied wave_height(x, z) / Perlin noise / cellular (Voronoi) noise. Predict: The sine and the Perlin terrain will look most alike from above at this frequency: both roll smoothly, and the sine is only too regular. randf() is the outlier, a field of spikes, because no vertex knows its neighbour. Claim: Noise is randomness with a memory of its neighbour: only the sources that remember can be walked on.
- **Debt:** The blob aesthetic (Queer 3D 2024): smooth noise became CGI's look of the 'natural'. And the grid decides how much of the noise exists: octaves finer than the vertex spacing are computed and never seen. Queer 3D's overflow-rate comparison of noise types (Perlin 45, random 635, Voronoi 0, sine-curve space 3284) says the same with numbers.
- **Place:** Walk your terrain. Which source makes ground you can cross? randf()'s cannot be walked; the cellular one is a field of cells with ridges between them.
- **Families in the hall:** dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Noise_Space_10: at its default; noise_space.generator (simplex / perlin / value / cellular) in Noise_Space_10: at its default; synthesis_stand.mode (auto / hero / series) in Noise_Columns: one value shown: hero
- **In your room:** Give your room ground: a noise terrain you can walk, with its seed and frequency recorded.

#### 30. Displace: a body pushed along its normals by a field

- **Operation:** displace. **Spine:** noise, softbodies. **Halls:** Noise_Inside_Noise (carrier), Noise_One (field trip), ProceduralGeneration_Reaction_Diffusion_Systems (field trip).
- **Code:** new none (a synthesis); returns noise, packed_arrays, dictionaries, surface_tool, normals, collision, loops, classes, export, seeds.
- **Body:** Take a body you have made and move every vertex along its own normal by the value of a field sampled at that vertex. First by hand, on your own mesh: read its vertices and normals as packed arrays, add normal times noise times an amplitude to each position, generate the normals again, rebuild the collider. Then as the project does it: a MeshGrammar with an icosahedron as its seed and two rules, SplitFaceOp to give the field somewhere to act and NoiseDisplaceOp to push. A sphere under cellular noise becomes a pebble; under a sine it becomes a ripple; your extruded plinth under either stops being an extrusion. Terrain (ch12) lifted a flat grid; this bends any body, and it is the organic half of making form.
- **Argument:** axis how many times the faces are split before the push, same field, seed and amplitude: 0 splits: 20 faces / 1 split: 80 faces / 2 splits: 320 faces / 3 splits: 1280 faces. Predict: 2 and 3 splits will look most alike: past a certain density the field is fully drawn and more faces change nothing you can see. With no split the body stays an icosahedron with its corners moved, because the field has almost nowhere to act. Write the pair you expect, and the split at which you think the body stops changing, before you render. Claim: A field can only show where there are vertices to move: resolution is the price of organic form, and it is paid in triangles.
- **Debt:** Polycount against smooth deformation, the application's own sentence, measured on your body. And the blob: bodies displaced by noise resemble each other more than they resemble what they were, so a room of them reads as one aesthetic. Push further than the body's own curvature and the surface passes through itself, which no picture from outside will show you; the marble will.
- **Place:** Grip it: an organic hold. On the desktop, carry it and let the marble settle in its hollows; in the headset, hold it in your hand and turn it. Then put it on the plinth from ch45, a geometric body carrying an organic one.
- **Borrows:** MeshGrammar, a copy of commons/mesh_grammar/ supplied in the kit: MeshData, MeshSelector, SplitFaceOp, NoiseDisplaceOp, used directly with their parameter dictionaries (opened at ch43) (use)
- **Works to see:** mesh_grammar_crumpled (Perlin noise pushes vertices along their normals); mesh_grammar_noise_sculpture (cellular noise, pushed radially); mesh_grammar_detailed_bulge (split every face first, then deform: resolution before the push; placed in the reaction-diffusion hall)
- **Process strip:** the seed: an icosahedron -> split every face (SplitFaceOp), k times -> sample the field at each vertex -> push along the normal (NoiseDisplaceOp) -> generate the normals again -> rebuild the collider -> paint
- **Families in the hall:** dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Noise_Inside_Noise: at its default; noisesphere.readout (relief / plate / none) in Noise_Inside_Noise: at its default; turing_pattern_generator.seeding (discs / centre / lattice / ring) in ProceduralGeneration_Reaction_Diffusion_Systems: one value shown: centre
- **In your room:** One displaced body in your room, made from a body you already had, with the field, the seed and the number of splits written beside it, and the split at which it stopped changing.

#### 31. The pixel's colour circle: shaders

- **Operation:** skin. **Spine:** shaders, noise. **Halls:** Shader_01_Shaping (carrier), Shader_11_QueerRubber (carrier), Shader_09_FBM (field trip), Shader_05_Patterns (field trip), Shader_10_ReactionDiffusion (encounter), Shader_12_PinkExtravaganza (encounter).
- **Code:** new shaders, uniforms; returns uv, interpolation, materials, trig, normals, noise, tool_scripts.
- **Body:** A spatial shader on one of your family members: a shaping function over UV (step, smoothstep, sin) in fragment(), a fresnel rim from dot(NORMAL, VIEW), and fBm noise computed per pixel; uniforms set from GDScript.
- **Argument:** axis the rim exponent p in pow(1.0 - dot(NORMAL, VIEW), p): 0.5 / 1 / 3 / 8. Predict: 3 and 8 will look most alike from 2 m: both give a thin bright edge on a dark body. 0.5 floods the whole body with the rim colour, so it reads as unlit. Claim: A skin can be computed from the angle between the body and your eye: the same body is rubber or glass depending on one exponent (Shader_11_QueerRubber).
- **Debt:** The GPU computes every pixel at once and remembers nothing between them (Gaboury on the GPU). The shader's noise is not the CPU's: compare Shader_09_FBM with ch12's terrain, the look is shared and the body is not, and you cannot stand on a shader. A skin computed from the viewer changes with who looks.
- **Place:** Walk around it: the rim follows your eye, so each visitor sees a different skin.
- **Families in the hall:** dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Shader_01_Shaping: at its default; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in Shader_11_QueerRubber: at its default; science_screen.support (stand / frame / cabinet / pylon) in Shader_01_Shaping: at its default
- **In your room:** SYNTHESIS IV: give your family a computed skin; your room's colour and skin now argue together.

#### 32. To stand despite all possibilities to fall: a round (assemblage IV, midterm)

- **Operation:** play. **Spine:** randomness, formfinding. **Halls:** Random_Game (carrier), FormFinding_Forge (field trip), Random_Cubes (field trip).
- **Code:** new state_machines, ui, timers; returns random, seeds, player, signals, physics_bodies, input, areas, export_build.
- **Body:** A small complete game: stones that stand or sink on seeded random waits with a telegraphing ring (Random_Game's body), and the player crossing them. An enum state machine per stone (STANDING, WARNING, SINKING, GONE) and for the round (MENU, PLAYING, FALLEN, WON); a HUD with the time; the best time saved; a supplied sound on each sink (opened at ch27). In v2 the round is built on your own ground: the stones stand on the noise terrain of ch12, wear the rim shader of ch30, and are members of your family.
- **Argument:** axis warning time before a stone sinks (still 20 s into the same seeded round): 0.25 s / 0.5 s / 1.0 s / 2.0 s. Predict: 1.0 and 2.0 will look most alike: most stones are still standing and the gaps are few. At 0.25 s the field is mostly gaps, because stones sink before any player can react. Claim: Fairness is a number in a state machine: the warning time decides who can cross, not the chance itself.
- **Debt:** Chance returns as fate: the seed is the same for everyone, the reaction time is not. A state machine is a list of allowed states, and what it cannot name it cannot do (c8's 'the enum as allowed identities').
- **Place:** Play it in the headset: the stones are the ground you stand on; fall, and the round restarts.
- **Process strip:** noise terrain (ch12) -> stones: family members (ch14) -> the rim shader as their skin (ch30) -> a state machine per stone -> the walker (ch19) -> HUD and restart -> export
- **Families in the hall:** cube_projectile_spawner.warning (none / stain / cage / beacon / shroud) in Random_Game: at its default; r_c.posture (cycle / seated / leaving / sunken / arriving) in Random_Game: at its default; coin_toss.disclosure (oracle / tally / ledger / works / origin) in Random_Cubes: one value shown: origin
- **In your room:** MIDTERM: a round in your room that a classmate can lose, exported and played, with its warning time argued.
- **Departure:** return: the round is the part's assemblage, built on the noise terrain (ch12) in the shader skin (ch30), so it follows them.

### Grow by rule (cellular automata, fractals, L-systems, procedural generation)

*You can grow bodies from rules in time, from recursion and from grammars, keep a genome as a file, generate a world and navigate it, and join grown bodies to made ones.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern, integrate, walk, push, follow, balance, climb, swing, sound, field, disturb, noise, displace, skin, play, rule in time, recurse, grow, save a genome, navigate, assemble.

Of the plate, now: Turing's question: do not place the pores and spines; let a rule decide where they come, and open and branch what it marks. One individual saved as a file of numbers.

#### 33. Rules in time: cellular automata

- **Operation:** rule in time. **Spine:** cellularautomata, softbodies. **Halls:** CA_Introduction (carrier), CA_GameOfLife (carrier), CA_EdgeOfChaos (field trip), ProceduralGeneration_Reaction_Diffusion_Systems (field trip).
- **Code:** new buffers; returns arrays, packed_arrays, loops, conditions, collision, multimesh.
- **Body:** An elementary automaton whose rows stack upward as walkable floor (CA_GameOfLife's history turned into collidable cells), read from one buffer and written to another; the same double-buffer step then drives Turing's reaction-diffusion on a floor you stand on.
- **Argument:** axis the rule number, from one live cell: 30 / 90 / 110 / 250. Predict: 90 and 250 will look most alike: both grow a symmetric triangle at the same speed, 90 as Sierpinski's nested holes and 250 as a regular checker. 30 and 110 are both lopsided: 30 is disorderly on one side, 110 grows toward one side only. Claim: A rule of eight bits decides between order, fractal and chaos, and you cannot read which from the rule, only from running it.
- **Debt:** A CA is a grid that must end: the edges wrap or die, and the choice shows at the floor's border. Rule 30's 'randomness' is fully determined (it has been used as a random generator): pseudo-randomness returns. Reaction-diffusion is Turing's 1952 morphogenesis, the application's embodied throughline: 'can twisted rooms transcend power?' (Queer 3D).
- **Place:** Stand on the history: the rows are floor and the rule's gaps are holes you fall through; walk up Sierpinski's rows.
- **Families in the hall:** synthesis_stand.mode (auto / hero / series) in CA_Introduction: one value shown: hero; ca_bridge.rule (30 / 90 / 110 / 250) in CA_GameOfLife: at its default; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in CA_Introduction: at its default
- **In your room:** Let a rule grow one part of your room over time; keep the rule number.

#### 34. The tree and its mad branch: recursion

- **Operation:** recurse. **Spine:** fractals. **Halls:** Fractal_RecursiveTrees (carrier), Fractal_Recursion (carrier), Fractal_KochSierpinski (field trip), Fractal_MengerSponge (field trip).
- **Code:** new recursion; returns functions, parameters, transforms, random, seeds, multimesh, debugging, errors.
- **Body:** A tree that calls itself: branch(depth, length, frame) draws one segment and calls branch twice with a shorter length and a turned frame, until a depth limit stops it; one seeded 'mad branch' breaks the symmetry.
- **Argument:** axis depth limit: 3 / 6 / 9 / 12. Predict: 9 and 12 will look most alike at 3 m: with a 1 m trunk and a length ratio of 0.67, the twigs added past depth 9 are under 2 cm and merge into the crown, while 12 costs eight times the segments (2^12 against 2^9). Claim: Recursion must be stopped, and past some depth it only costs: the stop is a design decision the tree cannot make for itself.
- **Debt:** 'Recursion must always be controlled' (Queer 3D): an unstopped recursion is a stack overflow, the engine's refusal. The fractal is an idealisation: real trees stop for reasons (light, weight, damage), and the depth limit is where the model's honesty lives.
- **Place:** Walk under the crown; climb the first branches (colliders on the thick segments only, which is another budget).
- **Families in the hall:** example_8_3_recursion_circles_vr.depth (1 / 2 / 3 / 4 / 5) in Fractal_Recursion: one value shown: 1; fractal_recursion_2.depth (1 / 2 / 4 / 6 / 7) in Fractal_Recursion: one value shown: 1; inverted_tree_cloud.aftermath (form / strata / envelope / apparatus) in Fractal_RecursiveTrees: one value shown: strata
- **In your room:** Grow one body in your room by recursion, and say in a comment where and why it stops.

#### 35. The point walks again: grammars and the turtle

- **Operation:** grow. **Spine:** lsystems. **Halls:** LSystems_Grammar_Lab (carrier), LSystems_Growth (carrier), LSystems_Architecture (field trip), LSystems_Shape_Grammars (field trip), Assemblage_Same_Desire (encounter).
- **Code:** new strings, stacks; returns dictionaries, loops, recursion, meshes, transforms, player.
- **Body:** An L-system: an axiom string rewritten by a Dictionary of rules n times, then read by a 3D turtle that draws on F, turns on + and -, and pushes and pops its frame on [ and ]. Klee's walking point from ch6, now walking a grammar. MeshGrammar is the same idea with faces for symbols: its rules rewrite a mesh generation by generation, and its own header says it is modelled after the L-system. LSystems_Grammar_Lab places one such tree beside the string grammar.
- **Argument:** axis branching angle, same rules and generations: 15 degrees / 22.5 degrees / 25.7 degrees / 45 degrees. Predict: 22.5 and 25.7 will look most alike: both read as plants (the textbook angles of one family). 45 turns the plant into a lattice. Claim: A grammar is a family whose one angle decides whether it grows as a plant or as architecture.
- **Debt:** Performativity (Butler, as c2 reads it): the body is its repeated rewriting, and the grammar's alphabet decides what can be said. String growth is exponential, so the rewriting must also be stopped. Lindenmayer modelled algae; the 'plant' look is an aesthetic, not biology.
- **Place:** Walk the grown structure as architecture (LSystems_Architecture): the turtle's path becomes corridors.
- **Works to see:** mesh_grammar_lsystem_tree (a tree grown by rules on faces, placed in LSystems_Grammar_Lab); mesh_grammar_coral_fingers (tube branches from upward faces, placed in LSystems_Architecture)
- **Families in the hall:** lsystem_editor.grammar (koch / sierpinski / dragon / plant / bush / fern) in LSystems_Grammar_Lab: one value shown: koch; dark_sphere.presence (witness / hush / beacon / eclipse / becoming) in LSystems_Grammar_Lab: at its default; lsystem_tree.evidence (result / trace / longhand / axiom) in LSystems_Grammar_Lab: at its default
- **In your room:** Write a grammar for a body of your family and let the turtle build it.

#### 36. Genes as files: a family saved, a body recalled

- **Operation:** save a genome. **Spine:** proceduralgeneration, randomness, lsystems. **Halls:** PG_Genetic_Evolution (carrier), Random_Definition (field trip), LSystems_Living (encounter).
- **Code:** new resources, save_load; returns classes, export, dictionaries, random, seeds, instancing.
- **Body:** A creature genome as a custom Resource (segments, limb_count, limb_angle, colour, seed) and a builder that turns it into primitive-mesh parts; the chosen specimen is saved as .tres in user:// and comes back after a restart.
- **Argument:** axis the limb_count gene: 0 / 2 / 4 / 6 / 12. Predict: 6 and 12 will look most alike from above: past about six limbs the body reads as radial, a star or a flower, not an animal. Claim: A genome draws a border between kinds: somewhere between 4 and 6 limbs, a creature becomes a flower.
- **Debt:** A saved body is a frozen choice: the genome decides which creatures are possible and which can never be born, the dark spot of the encoding. Resources are shared by default, so two bodies can secretly share one gene.
- **Place:** Carry it: the specimen is a pickable that survives leaving and re-entering the room, a museum specimen.
- **Families in the hall:** GeneticProgramming.alphabet (primitives / csg_tree / parametric / voxel) in PG_Genetic_Evolution: at its default; science_screen.support (stand / frame / cabinet / pylon) in PG_Genetic_Evolution: at its default; seed_replay_demo.comparison (single / replicas / seeds / ladder / offset) in Random_Definition: one value shown: replicas
- **In your room:** Save your room's family as files and let a classmate load and breed one specimen.

#### 37. How do we navigate an auto-generated world?

- **Operation:** navigate. **Spine:** proceduralgeneration, graphtheory, randomness. **Halls:** PG_Caves_Mazes (carrier), GT_Pathfinding (carrier), GT_Spanning_Trees (field trip), Randomness_10_PRINT_Algorithm (field trip).
- **Code:** new graphs, search, navigation; returns arrays, dictionaries, stacks, queues, random, seeds, player, collision.
- **Body:** A maze carved by a randomised search over a grid graph (a spanning tree), then walked: breadth-first search for the path, AStar3D, and a NavigationRegion3D baked for a companion that follows you.
- **Argument:** axis carving algorithm, same grid and seed: randomised depth-first search / Prim's / Kruskal's / 10 PRINT (no guarantee). Predict: Prim's and Kruskal's will look most alike from above: many short dead ends, a bushy texture. Depth-first search makes long winding corridors, and 10 PRINT alone may not connect at all. Claim: A maze's character is the search that carved it: the same grid gives corridors or thickets depending on whether a stack or a queue decides.
- **Debt:** 'How do we navigate an auto-generated world?' (the application's WP3 question). The shortest path is one value among others (the desire line, Ahmed's queer phenomenology); a navigation mesh decides where a body may walk, and the agent's radius is a body norm.
- **Place:** Get lost in it, then follow the companion; walk a desire line through a wall you broke.
- **Families in the hall:** ten_print_structure.form (floor / wall / overhead) in Randomness_10_PRINT_Algorithm: family shown: floor, wall; maze_generation.hand (backtracker / prim / binary_tree / sidewinder / labyrinth) in PG_Caves_Mazes: at its default; pathfinding3d.frontier (unsearched / route / expanded / flooded) in GT_Pathfinding: at its default
- **In your room:** Generate one part of your room and prove that a visitor can reach every place in it.

#### 38. Same desire: grown bodies join made ones (assemblage V)

- **Operation:** assemble. **Spine:** proceduralgeneration, lsystems, cellularautomata. **Halls:** PG_Branching_Growth (carrier), Assemblage_Same_Desire (carrier), LSystems_Architecture (field trip), CA_ExpandingSpace (field trip).
- **Code:** new none (a synthesis); returns recursion, strings, stacks, buffers, instancing, classes, export, seeds.
- **Body:** One body from three growth rules and one made family. The grammar of ch33 grows the frame; the recursion of ch32 branches it; your family members from ch14 hang on the branches as instanced parts, oriented by the turtle's frame; and the cellular automaton of ch31 decides, row by row, which branches are solid and which are ghosts (ch3's if, now driven by a rule in time). Assemblage_Same_Desire is the hall's own version: one array of small choices, drawn as marks, as paths, and as a floor that carries you. This is also where MeshGrammar, borrowed since ch45, is opened: a rule is a selector, an operation and a dictionary of parameters, and the frame may be grown by it (TubeBranchOp over two generations is the Branching Coral) as well as by your own turtle.
- **Argument:** axis which rule grows the frame, from the same seed and the same hung family: the L-system of ch33 / the recursive tree of ch32 / the branching growth of PG_Branching_Growth / a straight scaffold, no growth (the control). Predict: The L-system and the recursive tree will be the closest pair: both branch by angle and shortening, and from the same seed their crowns fill the same volume. The control will be farthest from all three. Write the predicted closest pair, then render the four with the same family hung on them. Claim: The same parts on different frames are different bodies: in an assemblage the growth rule is the body, and the hung family only clothes it.
- **Debt:** Every body a grammar grows looks like the grammar. A rule written in ten lines produces ten thousand branches that all carry its accent, and the accent passes for nature. Who wrote the rule, and what a rule cannot grow (a branch that joins another, a loop, a part that was never a symbol) is the debt; Assemblage_Same_Desire's name says it: the same desire, many paths.
- **Place:** Walk the array as floor, then climb the grown frame: the solid branches (the automaton's live cells) carry you, the ghost branches let you fall. Carry one family member off a branch and the frame does not notice.
- **Borrows:** MeshGrammar (commons/mesh_grammar/): MeshRule, MeshSelector and the operations, read and changed here (understand)
- **Works to see:** mesh_grammar_branching_coral (second-generation branches grow from the tips of the first); mesh_grammar_ca_growth (a cellular automaton on the faces decides which ones extrude)
- **Process strip:** axiom and rules (ch33) -> the turtle draws the frame -> recursion branches it (ch32) -> the automaton gates solid and ghost (ch31) -> hang the family on the frames (ch14) -> one seed for all three
- **Families in the hall:** synthesis_stand.mode (auto / hero / series) in Assemblage_Same_Desire: one value shown: hero; branching_growth_algorithm.aftermath (form / field / envelope / apparatus / strata) in PG_Branching_Growth: at its default; godel_statement_plaque.outside (quotation / margin / breach / omission / habitat) in Assemblage_Same_Desire: at its default
- **In your room:** A grown frame of your own with your family hung on it, and one rule you added that the grammar could not express (a branch that joins, a loop, a part that is not a symbol). Write what you had to do by hand to get it.

### Deform, imply, combine, flock (soft bodies, isosurfaces, boolean surfaces, swarms)

*You can make bodies that give, bodies with no vertices until asked, bodies combined by union and subtraction, and bodies that move as a crowd.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern, integrate, walk, push, follow, balance, climb, swing, sound, field, disturb, noise, displace, skin, play, rule in time, recurse, grow, save a genome, navigate, assemble, deform, imply, combine, flock.

Of the plate, now: A wall with thickness, and pores made by taking away. Many shells drifting together.

#### 39. Soft bodies: the organism returns

- **Operation:** deform. **Spine:** softbodies, formfinding. **Halls:** SoftBodies_Soft_Body_Deformation (carrier), FormFinding_Relaxation (carrier), Topology_Entropy_Morphogenesis (carrier), SoftBodies_Playground_of_Joy (encounter).
- **Code:** new inheritance; returns integration, physics_bodies, classes, export, packed_arrays, profiling, setters, xr.
- **Body:** A Verlet cloth written as your own classes: Particle, and PinnedParticle extends Particle and overrides step() to stay put; distance constraints relaxed n times per step. Beside it Godot's SoftBody3D with pinned points and exported stiffness.
- **Argument:** axis constraint iterations per step: 1 / 4 / 16 / 64. Predict: 16 and 64 will look most alike: the cloth hangs taut, and the extra passes remove less than a centimetre of stretch. 1 sags like rubber. Claim: Stiffness is not a material but a budget: the same net is rubber or chain depending on how many times you ask it to keep its lengths.
- **Debt:** Polycount against smooth deformation (application l.89): a soft body needs vertices to bend, and every vertex costs per frame and per eye. Inheritance is a taxonomy: making 'pinned' a subclass decides that being held is a kind of particle, not a relation.
- **Place:** Carry it: grab a corner of the cloth (XR hand or desktop carry) and drag it through the room; let it drape over your family.
- **Families in the hall:** verlet_workbench.relaxation (worked / nudged / pressed / held) in FormFinding_Relaxation: at its default; entropy_morphogenesis.found_state (sorted / stirred / mixed) in Topology_Entropy_Morphogenesis: at its default; jelly_cube.assay (none / gauge / control / chart / vitrine) in SoftBodies_Soft_Body_Deformation: at its default
- **In your room:** Give one body in your room a soft part that a visitor can deform.

#### 40. A body with no vertices until you ask: implicit bodies

- **Operation:** imply. **Spine:** isosurfaces, noise. **Halls:** ISO_Introduction (carrier), ISO_Metaballs (carrier), ISO_LookupTable (field trip), ISO_Sculpting (field trip).
- **Code:** new threads; returns noise, nested_loops, surface_tool, normals, arrays, tool_scripts, profiling, packed_arrays.
- **Body:** A scalar field (metaballs plus noise) sampled on a 3D grid and polygonised by marching cubes with the supplied lookup table, built on a worker thread so the room keeps its frame rate while the body is rebuilt. The CSG half of the winner's chapter is now ch44, Combine.
- **Argument:** axis threshold (iso level) of the same field: 0.2 / 0.4 / 0.6 / 0.8. Predict: 0.4 and 0.6 will look most alike: both show separate blobs, one set fatter. At 0.2 the blobs fuse into one body; at 0.8 they shrink into beads. Claim: An implicit body's identity is a threshold: one number decides whether there are three bodies or one.
- **Debt:** The blob aesthetic in its purest form (Queer 3D): metaballs fuse because the field sums them. The lookup table is inherited code nobody in the class wrote, so this chapter holds a code-critique station on Ada's own marching-cubes table (read its comments, find its assumptions). The grid's resolution decides what can be thin.
- **Place:** Stand inside it: sculpt the field with your hand (ISO_Sculpting's gesture) and walk through the tunnels your subtraction made.
- **Families in the hall:** metaball_world.emplacement (column / ring / pair / shell / scatter) in ISO_Metaballs: at its default; nakama_metaballs.imprint (relief / blank / swollen / flayed) in ISO_Metaballs: at its default; voxel_noise_demo.generator (simplex / perlin / value / cellular) in ISO_Introduction: at its default
- **In your room:** Carve or fuse one body in your room from a field or with boolean verbs.

#### 41. Combine: union, subtraction, intersection (assemblage VI)

- **Operation:** combine. **Spine:** boolean_surfaces, isosurfaces. **Halls:** Boolean_Verbs (carrier), Boolean_Works (carrier), Boolean_Gallery (field trip), ISO_Sculpting (field trip).
- **Code:** new other:csg; returns meshes, collision, instancing, classes, profiling.
- **Body:** A body carved from your assemblage with three verbs: the union of two family members, the subtraction of the implicit body of ch36 (its tunnel bored through the union), and the intersection with the shell of the scanned body from ch18. CSGCombiner3D holds the operands as children, in order; then the result is baked to a mesh with a collider made from it, because a CSG body is a renderer's interior and physics is told nothing (Boolean_Works' lesson: seventy-five objects offer themselves to your hand and are not there).
- **Argument:** axis the order of the same three operands and verbs: (A union B) minus C / (A minus C) union B / (A intersect B) minus C / A minus (B union C). Predict: The first two will be the closest pair: they differ only where C overlaps B, so with C's tunnel through A alone they are the same body. The third will lose most of its volume (an intersection keeps only the overlap). Write the predicted closest pair and the volume order, then render. Claim: Boolean combination is not commutative: the order of the verbs is part of the form, and a body carved by subtraction has an inside only where the physics was told so.
- **Debt:** The picture of an inside against an inside. A CSG interior renders perfectly and holds nothing: Boolean_Works hangs 'WALK THE HOLLOW' over a metre of solid rock beneath a cave whose floor is above your head. Baking fixes it at a cost: the seams of a subtraction multiply triangles (polycount against smooth deformation, ch16's debt returns), and the baked mesh forgets its verbs, so the body can no longer be re-carved. An interior is an agreement between the renderer and the physics, and someone has to write it.
- **Place:** Walk into the tunnel before baking and fall through the floor (the hall's own failure, now yours); bake, walk in, and stand in the hollow. Then put the baked body in the museum hall and let a classmate find the seam.
- **Process strip:** two family members -> union -> the implicit body's tunnel (ch36) -> subtraction -> the scanned shell (ch18) -> intersection -> bake the mesh and the collider -> material
- **Families in the hall:** removal_room.subtraction (cross / third / gasket / figure) in Boolean_Gallery: family shown: cross, figure, gasket, third; coincident_face.separation (coincident / clear / hairline / inverted) in Boolean_Gallery: family shown: clear, coincident, hairline, inverted; csg_difference_demo.workings (outcome / trace / operands / expression) in Boolean_Gallery: family shown: expression, operands, outcome, trace
- **In your room:** One carved body in your room with its verbs written beside it (the operand order as a line of text on the plinth), baked, standable, and its triangle count before and after baking in the README.

#### 42. Many bodies with rules: swarms

- **Operation:** flock. **Spine:** swarmintelligence, randomness. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier), SwarmIntelligence_PhysarumColony (carrier), SwarmIntelligence_Swarm_Intelligence_Algorithms (field trip), Random_Pheromone (field trip).
- **Code:** new groups; returns classes, inheritance, vectors, forces, multimesh, profiling, random.
- **Body:** A flock of your family members as boids: separation, alignment and cohesion as three forces summed per body; each boid joins a group so the others can find it; moved from one node per boid to one MultiMesh when the frame time says so.
- **Argument:** axis cohesion weight (separation and alignment fixed): 0 / 0.5 / 1 / 4. Predict: 0 and 0.5 will look most alike: a loose scatter moving roughly one way. At 4 the flock collapses into a ball. Claim: A collective body is a ratio of rules: one weight decides whether many bodies are a crowd, a flock or a clump.
- **Debt:** The all-pairs neighbour search costs n squared: a swarm is limited by its budget before it is limited by its rules. Who counts as a neighbour is a radius, a politics of proximity. 'Emergence' is also a way of saying that nobody decided.
- **Place:** Walk into the flock: your body is an obstacle in its rules; stand still and be surrounded.
- **Families in the hall:** PhysarumColony.anchorage (triad / pair / ring / scattered) in SwarmIntelligence_PhysarumColony: at its default; boid_manager.accord (school / orb / lane / lattice) in SwarmIntelligence_Boids_Algorithm: at its default; boids_aquarium.accord (school / orb / lane / lattice) in SwarmIntelligence_Boids_Algorithm: at its default
- **In your room:** Let a crowd of your family move through your room by rules.

### Learn, break, measure, release (machine learning, graph theory, the crises, QFEP, post-crisis)

*You can make a body that learns and say whose data taught it, a space that holds from one standpoint only, measure your own predictions, and release your hall: the final assemblage.*

Toolkit so far: instruct, place, decide: solid or ghost, carry, join, record, close, extrude, build, direct, ship, articulate, assemble, repeat, parameterise, tune, budget, collage, colour, pattern, integrate, walk, push, follow, balance, climb, swing, sound, field, disturb, noise, displace, skin, play, rule in time, recurse, grow, save a genome, navigate, assemble, deform, imply, combine, flock, learn, break, measure, release.

Of the plate, now: A hall of shells in the collective museum, each with its numbers shown, and what the plate hides said beside it.

#### 43. Bodies that learn: whose data trains the body

- **Operation:** learn. **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Classification (carrier), ML_Neural_Networks (carrier), CriticalAlgorithms_Algorithmic_Bias_Visualization (carrier), ML_Gradient_Landscape (field trip), ML_Evolution (field trip).
- **Code:** new json; returns arrays, dictionaries, loops, uv, materials, save_load, testing, ai_assist.
- **Body:** A classifier painted on the floor: labelled points (your ch6 walk traces and classmates', with consent, loaded from a JSON file that records who labelled each one) and a k-nearest-neighbour rule that colours every floor cell by its nearest labels; then a perceptron's line on the same data, and a gradient landscape you walk down.
- **Argument:** axis who labelled the training points: you / the class (with consent) / a default dataset / random labels. Predict: The class and the default dataset will look most alike: smooth, confident regions. Random labels give a speckled field, and your own labels draw the most particular map. Claim: The decision field is a map of who labelled the data: the machine's confidence is borrowed from its labellers.
- **Debt:** Models are always biased (Queer 3D 2024), and raising k erases the lone sample's region (k as a politics of neighbourhood). The course's own AI assistant (ch8) was trained on labels nobody in the room chose: ask it for 'a human body' and study what it returns. A test proves only what you thought to ask: the perceptron fails XOR.
- **Place:** Stand on your own portrait: the field under your feet says which class your position belongs to; walk across the boundary the data drew.
- **Families in the hall:** bias_from_inside.perspective_blend (0.0 / 0.5 / 1.0) in CriticalAlgorithms_Algorithmic_Bias_Visualization: at its default; bias_visualizer.disclosure (oracle / tally / ledger / works / origin) in CriticalAlgorithms_Algorithmic_Bias_Visualization: at its default; enhanced_kmeans.cohort (blobs / block / rings / braid / skew) in ML_Classification: at its default
- **In your room:** Train something on data about your visitors or yourself, with consent, and write the test that would catch it lying.

#### 44. The crisis of foundations: impossible possible space

- **Operation:** break. **Spine:** foundationscrisis. **Halls:** NonEuclidean_Spaces (carrier), Escher_Impossible (carrier), Godel_Incompleteness (field trip), Brouwer_Intuitionism (field trip), Euclid_Parallel (encounter), Russell_Paradox (encounter).
- **Code:** new await; returns shaders, uniforms, camera, signals, state_machines, raycasts.
- **Body:** An impossible figure that exists from one standpoint only: a Penrose triangle of three straight beams that closes when your camera reaches the one point (the figure emits viewpoint_locked and the room awaits it); and a corridor whose curvature is a shader uniform, so parallel lines meet.
- **Argument:** axis the viewer's distance from the locked standpoint: 0 m / 0.1 m / 0.5 m / 2 m. Predict: 0.5 and 2 m will look most alike: both plainly show three separate beams. 0 is the only closed triangle; 0.1 already shows a hairline gap. Claim: An impossible body is a possible body seen from one place: the impossibility is in the standpoint, not in the geometry.
- **Debt:** Mathematics has 'limits and areas of unpredictability and undecidability' (Queer 3D: Godel, the halting problem): no test suite can prove a program halts. Brouwer's third value as enum Truth {TRUE, FALSE, NOT_YET} (c1): allowing 'not yet' is a political choice. Failure before futures: the course names what its models cannot hold before it builds its own hall.
- **Place:** Find the standpoint: walk until the figure closes, take one step and watch it break; walk the curved corridor until you come back to where you began.
- **Families in the hall:** curvature_slider.witness (number / surface / normals) in NonEuclidean_Spaces: one value shown: surface; elliptic_surface.postulate (bare / parallels / triangle / net / euclid) in NonEuclidean_Spaces: at its default; escher_staircase.seam (none / hairline / gap / scaffold / field) in Escher_Impossible: at its default
- **In your room:** Put one impossibility in your room, and say from where it is possible.

#### 45. Order toward entropy: the QFEP laboratory

- **Operation:** measure. **Spine:** qfeplaboratory, randomness. **Halls:** QFEP_F_Term (carrier), QFEP_Lambda_Spectrum (carrier), QFEP_Edge_Of_Chaos (field trip), Random_Entropy (field trip).
- **Code:** new sorting; returns random, seeds, arrays, packed_arrays, multimesh, json, dictionaries.
- **Body:** Your own prediction log becomes a body: every prediction and observation you wrote since ch2, loaded from your sketchbook, with F = |prediction - observation| per chapter drawn as a line you walk along (a heuristic reading of QFEP's F term: a prediction error you wrote down, not a measured free energy). Beside it, 200 seeded symbols sorted by a tween while their Shannon entropy is counted (Random_Entropy).
- **Argument:** axis how the same 200 symbols are arranged: seeded random / sorted by value / sorted by colour / sorted by value, reversed. Predict: 'sorted by value' and 'reversed' will look most alike: they are mirror images. All four carry exactly the same counted entropy: the picture changes and the number does not. Claim: Entropy counts what there is, not how it is arranged: order is a picture, not a quantity.
- **Debt:** Shannon entropy measures a distribution and is blind to arrangement: the metric hides exactly what a visual argument shows. QFEP is the project's own framework, and the F term measured on the course's learners must not become a score (c2's warning): the log is for the student, not for the grade. The entropy counted here is the Shannon entropy of the symbol frequencies in one row, a stated distribution and a stated estimator. It is not the entropy of the room, of your search or of you, and the chapter makes no claim about those.
- **Place:** Walk your own F curve: the chapters where your prediction was most wrong are the highest points; stand on them.
- **Families in the hall:** lambda_slider.calibration (optimum / band / dispute / gap / none) in QFEP_F_Term: one value shown: none; bifurcation_walkway.regime (all / stable / cascade / chaos / period3) in QFEP_Lambda_Spectrum: at its default; complexity_pattern.rule (life / highlife / seeds / replicator / maze / coral) in QFEP_Lambda_Spectrum: at its default
- **In your room:** Plan the final project: from your F curve, pick the chapter where you were most wrong and build your hall's argument on it.

#### 46. Out of the lab: your hall in the collective museum (assemblage VII, final)

- **Operation:** release. **Spine:** postfoundationscrisis. **Halls:** SpeculativeComputation_Collective_Knowledge (carrier), CriticalAlgorithms_Applied_Ethics (carrier), PostCrisis_Synthesis (carrier), SpeculativeComputation_Situated_Computation (field trip).
- **Code:** new files; returns json, save_load, xr, export_build, profiling, testing, classes, resources, import_assets, ai_assist, audio, ui.
- **Body:** Your hall in Ada's endless museum, built from your families, each body with its prediction, comparison sheet, claim and debt comment; one public sculpture whose visitors' changes are kept as provenance records (who, when, what) in files under user://, readable by the next visitor; exported to desktop and Quest.
- **Argument:** axis who may change the sculpture: only the author / anyone, last write wins / anyone, with kept history / no one (sealed). Predict: 'only the author' and 'sealed' will look most alike in any still: to a visitor both are unchanging. Last write wins drifts toward the latest visitor, and kept history grows layers. Claim: A public body is its edit rule: who may revise it, and whether revisions are kept, shows in its shape over a week.
- **Debt:** Can the work keep its conditions, exclusions and possible revisions available to others (the post-crisis question)? Illich's repairability and the application's commoning: a hall that can be opened and changed. Collective memory is also surveillance: the provenance log records its visitors, so it asks for consent at the door.
- **Place:** Show it: the hall stands in the class's shared museum, where classmates walk, carry, revise or become its bodies, on desktop and in the headset.
- **Process strip:** choose the families -> their sheets, predictions and claims -> one public sculpture -> provenance records -> place them in the hall -> export to desktop and Quest
- **Families in the hall:** room_shape_demonstrator.plan (pair / head / circle / panopticon / vacant) in CriticalAlgorithms_Applied_Ethics: one value shown: head; synthesis_stand.mode (auto / hero / series) in CriticalAlgorithms_Applied_Ethics: one value shown: hero; bias_from_inside.perspective_blend (0.0 / 0.5 / 1.0) in CriticalAlgorithms_Applied_Ethics: at its default
- **In your room:** FINAL: your hall in the collective museum, exported and walked, with every body's prediction, sheet, claim and debt comment, and its edit rule.

## Lineage

| spine | chapters | application WP | Klee | Processing | NoC |
|---|---|---|---|---|---|
| 1 primitives | ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch45, ch08, ch09, ch14, ch15, ch16, ch18 | pre-WP foundation; WP2 queer meshes (polycount, ch14 and ch16) | I.1-4 the point on a walk, the line, the plane | Learning Processing ch1-9; Handbook Shape 1-3, Control 1-2 | ch0-1 (the Walker; vectors as positions) |
| 2 transformation | ch04, ch13, ch42, ch19, ch21 | pre-WP (vectors become frames); VR presence | I.9-12 bone, tendon, muscle; II eye level | Learning Processing ch14; Handbook Transform 1-2 | ch3 angular motion |
| 3 array_tutorial | ch09, ch10, ch27 | 'increasingly complex control structures'; WP1 sound (Tutorial_Disco) | I.5-6 structural rhythm, the chessboard | Learning Processing ch6 and ch9; Handbook Control 2 | none |
| 4 color | ch09, ch15, ch29 | WP3 shading algorithms | IV the central grey, the colour circle | Learning Processing ch1 colour | none |
| 5 tiling | ch10 | WP3 pattern and world building | I.6 structure moves into two dimensions | Learning Processing ch15 images and pixels | none |
| 6 change | ch22, ch28 | WP2 flow fields; WP4 chaos, previewed | III the bullet; IV the arrow | none | ch1-2 motion; ch6 flow field following |
| 7 forces | ch05, ch22, ch19, ch23, ch21, ch20, ch26, ch28 | WP2 soft bodies' rigid ancestor; WP4 algorithmic life | II balance ('He is the scale'); III regions of different density | none (Processing has no physics engine) | ch2 Forces; ch5 physics libraries; ch6 steering |
| 8 formfinding | ch16, ch20, ch25, ch35 | WP2 soft body simulation; polycount | II balance | none | ch5 physics libraries (springs) |
| 9 wavefunctions | ch24, ch26, ch27 | WP1 sine curves, resonance, sound; WP2 Fourier | III the stair climber; IV pendulum, circle, spiral | Learning Processing ch13; Handbook Math 3 | ch3 Oscillation |
| 10 randomness | ch11, ch12, ch25, ch17, ch34, ch37, ch40 | WP1 randomness | absent from Klee: the lineage's first departure | Learning Processing ch4; Handbook Math 4 | ch0 Randomness, the random walk |
| 11 noise | ch12, ch46, ch30, ch36 | WP1 Perlin noise, Voronoi | none | Learning Processing ch13 noise(); Handbook Math 4 | ch0 Perlin noise |
| 12 shaders | ch10, ch30 | WP3 shading; WP2 queer textures; WP3 reaction-diffusion | IV the colour circle | Processing PShader | none |
| 13 cellularautomata | ch31, ch43 | WP2 cellular automata; WP3 reaction-diffusion (Turing 1952) | none | Handbook 'Simulate' (Life) | ch7 Cellular Automata |
| 14 fractals | ch26, ch32 | WP2 fractal subdivision; WP1 Fibonacci | none in the Sketchbook | Handbook Shape 3 (recursion) | ch8 Fractals |
| 15 lsystems | ch33, ch17, ch43 | WP2 L-systems | I.1 the walk, now following a grammar | none | ch8 L-systems |
| 16 proceduralgeneration | ch17, ch34, ch43 | WP3 procedural generation, evolutionary algorithms: 'How do we navigate an auto-generated world?' | none | Learning Processing ch18 data | ch9 genotype and phenotype |
| 17 softbodies | ch15, ch46, ch31, ch35 | WP2 soft body simulation (cloth, liquids, rubber) | I.9-12 tendon and muscle as constraints | Handbook 'Simulate' | ch5 springs |
| 18 isosurfaces | ch36, ch44 | WP2 queer meshes (fusion, topology) | I.12 'stone upon stone' against 'chip from chip' | none | none |
| 19 boolean_surfaces | ch44 | WP2 queer meshes | I.12 additive and subtractive making | none | none |
| 20 swarmintelligence | ch37 | WP4 swarm intelligence, algorithmic life | none | Shiffman's Flocking example | ch6 Autonomous Agents |
| 21 machinelearning | ch38 | WP3 neural networks, evolutionary algorithms; WP4 AI | none | none | ch10 Neural Networks |
| 22 graphtheory | ch34 | WP3 graph theory | none | none | none (graphs are outside The Nature of Code) |
| 23 foundationscrisis | ch19, ch39 | WP4 non-Euclidean spaces; the 2022 prototype's paradoxes of infinity | II 'It isn't wrong logically', but psychologically | none | none |
| 24 qfeplaboratory | ch40 | the application's arc toward entropy | none | none | none |
| 25 postfoundationscrisis | ch08, ch38, ch41 | hacker ethics: Freire, Illich, commoning; all four WPs gathered | IV the close, where the line returns to the dot | Handbook 'Synthesis 4' | the Ecosystem Project |

## What changed from v1

- The order: v1 followed Klee's Pedagogical Sketchbook for 30 chapters (point, line, plane, structure, family, balance, gravity, kinetic forms, colour) and the spine after; v2 follows the spine's order of operations throughout, which keeps Klee's walk only where the spine already walks it (primitives).
- Parts are named by operations and each ends in an assemblage; the toolkit is printed per part.
- Three new chapters: ch42 a body of parts (assemblage I), ch43 same desire (assemblage V), ch44 combine (assemblage VI). ch36 is now implicit bodies only.
- Moved: the family (ch14-16, 18) to Part 3 after the chessboard; chance, noise and the first shader to Part 6 at their spine places; the walker, balance, legs, stairs, swing and sound to Part 5 with change, forces, form finding and waves; the genome file (ch17) to Part 7 with procedural generation; the round (ch25) to the end of Part 6 as the midterm.
- Re-anchored: ch19 on VFM_03_Motion (forces) with Trans_Scale as a visit; ch15 on Primitives_Ignorance; ch28 borrows a supplied field until noise is taught.
- Added after a slide Palle supplied (a body written as a chain of operations) and his pointer to MeshGrammar: ch45 extrude, right after the plane; ch46 displace, right after noise; a process strip on every assemblage and on both new chapters; MeshGrammar used at ch45, used directly at ch46, opened at ch43.
- Everything else is the winner's text. Untried with students; past the opening the chapters are plans.
