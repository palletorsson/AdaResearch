# Walk, Repeat, Stand, Grow: a middle-ground course for Ada

Candidate `d3_middle_ground`, second generation, bred from `c7_creative_medium`, `c3_form_code` and `c4_klee_kandinsky` (2026-10-01). Marks: **[V]** verified this session (in this folder's files, the parents' JSON, `spine.json`, or the Ada repo's CLAUDE.md and memory index); **[V x via y]** verified by a sweep or parent and carried over, not reopened by me; **[mem]** recalled, not checked; **(per c4)** a Klee section number taken from the c4 parent, which read the 1960 Praeger text.

## For the student: why this order

This course starts where Klee's Pedagogical Sketchbook starts: a point that goes for a walk and becomes a line, a record, and a plane you can stand on. Then one rule makes many bodies, a seed disturbs them, joints articulate them, a sine lays their time into space, and your body becomes a class: a family of possible bodies with one axis you can argue about. With a family in hand you give it surfaces (colour, tile, pixel, noise), then forces (the walker that carried you is opened, gravity is written by hand, legs let the passive part drive), then fields that decide what the picture hides, then rules that grow. It ends by leaving the lab: failure before futures, and your family placed in a shared museum where others may change it. The order relates to Ada's spine without being forced by it. Every chapter names the spine sequence it walks and is numbered inside it ('Randomness 1' at chapter 11, 'Randomness 2' at chapter 24, 'Randomness 3' at chapter 38), so you mostly walk Ada's halls in the spine's order. Where you meet a hall early, the chapter says why you need it now (chance right after the first grid, noise as your first ground, the model that drafts your code in week one), and when the sequence comes back, the chapter says it is a return. In every chapter you build a body, turn it into a family, write down before rendering which two members will look most alike, say in one sentence what the comparison shows, write what the approximation owes or hides, and put the body where someone meets it.

## The middle ground: how the order relates to the spine

The rule this course follows is one sentence: **walk the spine unless the student needs a hall earlier, and say so when you leave it and when you come back.** Every chapter names the spine sequence it walks and carries its number inside that sequence (the Processing Handbook's device), so the spine is the course's index, not its order.

- **Order agreement 0.853** with the spine (fraction of chapter pairs in spine order, by each chapter's earliest sequence). I reproduced the workflow's formula on all eight first-generation candidates before using it (c7 0.948, c3 0.88, c4 0.911, c5 0.754, c1 1.0: exact matches) [V]. The target was about 0.7 to 0.9: related, not forced.
- **0 undeclared departures**: every chapter that sits after a later-spine chapter carries a departure note (the workflow's rule, also reproduced [V]).
- **Nine early visits, each for a named student need** (the only real reorderings): Machine learning 1 at d3_09 (the drafter in week one), Array before Transformation at d3_10, Randomness 1 at d3_11 (chance right after the first grid), Waves 1 at d3_13 (sin is already in the organism; sound is WP1), Shaders 1 at d3_17 (the tile rule written per pixel), Noise 1 at d3_18 (the short track's ground), Isosurfaces at d3_26 (the noise field thresholded while it is fresh), Machine learning 2 at d3_28 (the fourth field), Graph theory at d3_34 (WP3's navigate question).
- **Everything else keeps the spine's order**, with returns named as returns (Randomness 2 and 3, Waves 2, Noise 2, Shaders 2 and 3, Transformation 2 and 3, Tiling 2, Machine learning 3). Where a chapter is in order but after an early visit, its note says 'no move of its own'.
- **Kept in spine order on purpose, against a parent:** colour stays early (c4 held it to the end, as Klee does; art students need it); forces stay in the middle (c3 held them to chapter 28); recursion stays in the rules part (c3 moved it to chapter 12, which judges found early for beginners).

## Parents: what was taken from whom

| From | Taken | Changed or fixed from the judges' notes |
|---|---|---|
| **c7 Code as Creative Medium** (0.90) | The chapter unit (brief with precedent, a closed exercise, an open make); the short track's one-chapter-a-day cadence; c07 'When Things Go Wrong' as d3_09 (the three-line AI protocol, the debugger, a build in week one); c20 Personal Prosthetic (d3_22), c33 Data Self-Portrait (d3_28), c35 Virtual Public Sculpture (d3_39); Modular Alphabet leading into chance; the flow field, the recursive tree, the bred creature, the maze walker. | Its order sat at 0.948, near the spine; here 0.853. Its short track skipped line, trace and arrays; here they are days 1-3 with the runnable kits. Its queer lens was implicit; here it is structural (d3_12 and d3_23). Point Zero comes before Point One again, as in the existing /course. The AI chapter is tagged as the machine-learning visit it is. |
| **c3 Form+Code** (0.897) | Parts labelled by what code does to form (Repeat, Transform, Parameterize, Visualize, Simulate); Parameterize as a strand (the single class, the family in the Inspector, genes as files, the measured budget); the collage room with a scan in the headset and a first export in week one (d3_08); the slit-scan pendulum (d3_13); the value of the two tables of contents; 'visualize a judgment' as a field (d3_28); the soft body as the polycount chapter (d3_35). | Recursion is not early (c3 ch12 was judged early); forces are not late (c3 ch28); Simulate is split into two parts (force, rules) instead of one grab bag; the crisis, QFEP and post-crisis are three chapters, not one; Parameterize is spread across four chapters so it is met when a family is needed and finished when a budget is. The sweep sheet is named as a supplied scene and opened at d3_25. |
| **c4 Klee and Kandinsky** (0.891) | The opening walk (point, line, record, plane you stand on, d3_01 to d3_07); the organism as the first moving body (d3_12) with Klee's active/passive = male/female read as the scene tree's command chain, and the inversion by legs (d3_23); Nake and Nees putting chance right after the chessboard (d3_10, d3_11); the chessboard itself with Albers's supplied two colours; the midterm round on Klee's axiom (d3_24); Melencolia as the collage precedent. | Colour is not delayed (c4 ch26, a lost motivator); noise is in week two and in the short track (c4 had none); the player is opened at d3_20, not ch19, and the walker is a body from day one; the legs use a supplied two-bone IK helper plus a small state machine, instead of FABRIK from scratch (judged steep); all its six undeclared departures are now declared. |
| Smaller borrowings | c1: the frame-rate debt in Point Zero with delta held back as a named repair (d3_02 to d3_12), and the student's own prediction log as QFEP's F (d3_38). c2: planted bugs of the kind it catalogued (integer hue, randomize() after a seed, a shared Resource, clockwise winding, add_child from a worker thread) and the reaction-diffusion port (d3_30). c5: chance returning as entropy (d3_38) and the recipe as a .tres others can repair (d3_25). c8: the category-crossing parameter with nothing in the class marking where (d3_14); the enum as a list of allowed states (d3_23); the camera as the course's dark spot (d3_37). | |

## How a chapter runs

1. **Brief and precedent** (from c7): one body prompt and one or two works that answered it before (`lineage.reference`).
2. **Decode** (Aesthetic Programming): walk the carrier hall and predict what its primary work does before touching code.
3. **Closed exercise** (PRIMM: predict, run, investigate, modify): a running kit with one code idea; one **planted bug** whose message the student reads (the last line of each chapter's `godot` list).
4. **Make**: build the body (`body`).
5. **Family and prediction**: one axis, 3-5 values; the closest pair and the reason, written before rendering (`argument.predict`). A prediction the render disagrees with is the valuable one; if the render comes in far below the prediction, stop and look (the Ada DNA programme's floor rule [V CLAUDE.md]).
6. **Compare and claim**: one comparison still, one sentence (`argument.claim`).
7. **Debt**, after making, never before: one reading or one code-critique snippet of Ada's own code (`debt`).
8. **Place**: stand on it, walk through it, carry it, become it (`place`); then one move in your own hall (`project_step`).

## Parts

- **p1 One body: point, line, plane (Code and form)** (d3_01 to d3_09): From an instruction to a plane you walked and can stand on, with a scanned body beside it in the headset and a drafted body checked by you: the engine calls you, everything is an object, a line is a record, a surface has a side.
- **p2 Many bodies: repeat, disturb, articulate, parameterize** (d3_10 to d3_14): One rule makes a floor; a seed disturbs it; joints make an organism whose parent commands its child; a sine lays time into space and sound; and your body becomes a class whose exported axis is a family you can argue about.
- **p3 Surfaces that argue: colour, tile, pixel, noise (Visualize 1)** (d3_15 to d3_18): Colour as a path through a space, a tile as a truth table, the same rule per body, per texel and per pixel, and noise as chance that remembers its neighbour: a ground for your family.
- **p4 Bodies under force: flow, walk, fall, reach, stand (Simulate 1)** (d3_19 to d3_24): The walker that carried you is opened; you write gravity yourself, extend your reach with a ray, invert the command chain with legs, and build a small complete round about standing despite every possibility of falling.
- **p5 Fields that decide what the picture hides (Visualize 2)** (d3_25 to d3_28): A ground others can repair, a skin a threshold extracts, a skin a shader fakes, and a floor a classifier paints: four fields, four things each picture hides.
- **p6 Rules that grow: bodies and worlds that make themselves (Simulate 2)** (d3_29 to d3_34): Neighbour rules, Turing's pattern on two buffers, recursion you stop, grammars that walk, bodies bred from files, and a generated world navigated as a graph.
- **p7 Leaving the lab: failure before futures** (d3_35 to d3_39): Soft and collective bodies measured against the headset, then the model's limits (one standpoint, a third truth value, your own prediction error as entropy) before your family stands in the shared museum under an edit rule.

## Tracks

### Three weeks: a family in drag, in your own hall (`short`)

3 weeks, 15 days, in the Queer 3D format. Week 1 (Code and form, headset from day 2): Mon d3_01+d3_02, Tue d3_03+d3_04, Wed d3_05+d3_06 (the six runnable /course kits, two a day), Thu d3_08 (scan day, then a Quest export), Fri d3_09 (the AI drafter). Week 2 (Many bodies): Mon d3_10+d3_11 (one grid, then one line of chance), Tue d3_12, Wed d3_14, Thu d3_15, Fri d3_18. Week 3: mini project; Tue d3_37 as a guest critique session walked without compulsory code (Code Societies format), Wed a second critique on the blob aesthetic walked in Noise_Space_10 and ISO_Metaballs, Fri the showing. Supplied and named because the short track skips them: heightfield_skin.gd (SurfaceTool mesh plus collider, which the long track writes in d3_07 and d3_18), the normal display in Color_Flashlight, the sweep_sheet scene, the walker and the XR rig.

Chapters: d3_01, d3_02, d3_03, d3_04, d3_05, d3_06, d3_08, d3_09, d3_10, d3_11, d3_12, d3_14, d3_15, d3_18, d3_37

**Project:** A FAMILY IN DRAG. One class of your own with one exported axis of 3-5 values (or the organism's joint axis), a prediction of the closest pair written before rendering, the comparison still from the sweep sheet, one claim sentence and a debt comment in the code. The members stand on a noise ground in your hall beside one scanned or sculpted body; one member is drafted by an AI under the three-line protocol (what should change, what must not, what observation would prove it wrong) and checked. Exported to the headset or a classmate's laptop and shown on day 15. Prompts to choose from: Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic (Levin and Brain), or 'the body the scanner could not see'.

### One year: from an instruction to a public body (`long`)

About 40 sessions over two terms, one chapter per session. Each part closes with a synthesis (d3_08, d3_14, d3_18, d3_24, d3_28, d3_34, d3_39) followed by a pause session with no new code where the year allows (Aesthetic Programming's rhythm). Term 1 ends with the midterm round (d3_24). The final brief is written at d3_37, two units before the end, and shown at d3_39.

Chapters: d3_01, d3_02, d3_03, d3_04, d3_05, d3_06, d3_07, d3_08, d3_09, d3_10, d3_11, d3_12, d3_13, d3_14, d3_15, d3_16, d3_17, d3_18, d3_19, d3_20, d3_21, d3_22, d3_23, d3_24, d3_25, d3_26, d3_27, d3_28, d3_29, d3_30, d3_31, d3_32, d3_33, d3_34, d3_35, d3_36, d3_37, d3_38, d3_39

**Project:** Midterm (d3_24): a round in your hall that a visitor can lose and replay, with a start, one way to fail, a score, a sound and a restart, saved to user://. Final (d3_39): your family placed in the class's collective museum hall with its prediction, comparison still, claim, debt comment and edit rule, walked in the headset from an exported build (the Nature of Code Ecosystem Project turned into a museum room).

## The two indexes

### Reading order

| n | id | title | spine number | earliest spine place | tracks |
|---|---|---|---|---|---|
| 1 | d3_01 | Day Zero: the instruction is the work | Primitives 1 | 1 | short, long |
| 2 | d3_02 | Point Zero: the engine calls you, and counts frames | Primitives 2 | 1 | short, long |
| 3 | d3_03 | Point One: solid or ghost, one if decides what a body is | Primitives 3 | 1 | short, long |
| 4 | d3_04 | Point Coordinates: carry the point, name its reference | Primitives 4 | 1 | short, long |
| 5 | d3_05 | Point Lines: distance belongs to the line | Primitives 5 | 1 | short, long |
| 6 | d3_06 | Point Trace: a line is a record | Primitives 6 | 1 | short, long |
| 7 | d3_07 | Plane: when the walk closes | Primitives 7 | 1 | long |
| 8 | d3_08 | Collage: a found body among made ones, in the headset | Primitives 8 | 1 | short, long |
| 9 | d3_09 | When things go wrong: the drafter is a model | Machine learning 1 / Post-crisis 1 | 21 | short, long |
| 10 | d3_10 | The chessboard: purely repetitive and therefore structural | Array 1 | 3 | short, long |
| 11 | d3_11 | Chance 1: disorder in the grid | Randomness 1 | 10 | short, long |
| 12 | d3_12 | The organism: pivot and swing (Klee in drag I) | Transformation 1 | 2 | short, long |
| 13 | d3_13 | Pendulum, circle, spiral: time laid into space, and heard | Waves 1 | 9 | long |
| 14 | d3_14 | A body is a family: one class, one axis, a sheet | Primitives 9 (Parameterize 1) | 1 | short, long |
| 15 | d3_15 | Colour is a rule: the midpoint lives in the space | Color 1 | 4 | short, long |
| 16 | d3_16 | The tile and its rule | Tiling 1 | 5 | long |
| 17 | d3_17 | Shader 1: the tile drawn per pixel | Shaders 1 | 12 | long |
| 18 | d3_18 | Noise 1: chance that remembers its neighbour, a ground to stand on | Noise 1 | 11 | short, long |
| 19 | d3_19 | Flow field: a weather of bodies | Change 1 | 6 | long |
| 20 | d3_20 | The walker opened: velocity, scale, and a skin you can swap | Forces 1 / Transformation 2 | 2 | long |
| 21 | d3_21 | Gravity by hand: your own integrator | Forces 2 / Waves 2 | 7 | long |
| 22 | d3_22 | Personal prosthetic: the arrow extends your reach | Forces 3 / Color 2 | 4 | long |
| 23 | d3_23 | Legs: the passive part drives (Klee in drag II) | Forces 4 / Transformation 3 | 2 | long |
| 24 | d3_24 | To stand despite all possibilities to fall: a round (midterm) | Formfinding 1 / Randomness 2 | 8 | long |
| 25 | d3_25 | Noise 2: the blob aesthetic, a recipe others can repair | Noise 2 (Parameterize 2) | 11 | long |
| 26 | d3_26 | Implicit body: a field decides where the skin is | Isosurfaces 1 / Boolean 1 | 18 | long |
| 27 | d3_27 | Shader 2: a skin that lies about its shape | Shaders 2 | 12 | long |
| 28 | d3_28 | Data self-portrait: whose data draws the field | Machine learning 2 / Post-crisis 2 | 21 | long |
| 29 | d3_29 | Life: a rule for neighbours | Cellular automata 1 | 13 | long |
| 30 | d3_30 | Turing's skin: two buffers on the GPU | Shaders 3 / Soft bodies 1 | 12 | long |
| 31 | d3_31 | The tree and its mad branch: recursion that must be stopped | Fractals 1 | 14 | long |
| 32 | d3_32 | Grammar: the point walks again | L-systems 1 / Tiling 2 | 15 | long |
| 33 | d3_33 | Bred, not designed: genes as files | Procedural generation 1 / Machine learning 3 (Parameterize 3) | 16 | long |
| 34 | d3_34 | How do we navigate an auto-generated world? | Procedural generation 2 / Graph theory 1 | 16 | long |
| 35 | d3_35 | Soft: polycount against deformation, measured | Soft bodies 2 (Parameterize 4) | 17 | long |
| 36 | d3_36 | Many bodies, local rules: a species | Swarm 1 | 20 | long |
| 37 | d3_37 | Impossible figure: what a model lets you claim (failure first) | Foundations crisis 1 | 23 | short, long |
| 38 | d3_38 | Order toward entropy: your own prediction errors | QFEP 1 / Randomness 3 | 10 | long |
| 39 | d3_39 | Virtual public sculpture: who may change it | Post-crisis 3 | 25 | long |

### By spine sequence

| spine place | sequence | chapters (in reading order) |
|---|---|---|
| 1 | primitives | d3_01, d3_02, d3_03, d3_04, d3_05, d3_06, d3_07, d3_08, d3_14 |
| 2 | transformation | d3_12, d3_20, d3_23 |
| 3 | array_tutorial | d3_10 |
| 4 | color | d3_15, d3_22 |
| 5 | tiling | d3_16 |
| 6 | change | d3_19 |
| 7 | forces | d3_20, d3_21, d3_22, d3_23 |
| 8 | formfinding | d3_24 |
| 9 | wavefunctions | d3_13 |
| 10 | randomness | d3_11, d3_24, d3_38 |
| 11 | noise | d3_18, d3_25 |
| 12 | shaders | d3_17, d3_27, d3_30 |
| 13 | cellularautomata | d3_29 |
| 14 | fractals | d3_31 |
| 15 | lsystems | d3_32 |
| 16 | proceduralgeneration | d3_33, d3_34 |
| 17 | softbodies | d3_30, d3_35 |
| 18 | isosurfaces | d3_26 |
| 19 | boolean_surfaces | d3_26 |
| 20 | swarmintelligence | d3_19, d3_36 |
| 21 | machinelearning | d3_09, d3_28, d3_33 |
| 22 | graphtheory | d3_34 |
| 23 | foundationscrisis | d3_37 |
| 24 | qfeplaboratory | d3_38 |
| 25 | postfoundationscrisis | d3_09, d3_28, d3_39 |

## The departures, in one place

- **9. When things go wrong: the drafter is a model** (Machine learning 1 / Post-crisis 1): Machine learning 1, an early and declared visit (spines 21 and 25 at chapter 9). Queer 3D's first principles put 'what are machine-learning models like the LLMs behind ChatGPT?' in the foundation, and its practice is 'use ChatGPT to write simpler programs', so the short track needs the checking protocol in week one, before a student meets a generated bug alone. The halls are walked, not coded. Machine learning returns as a field over the floor at chapter 28 (Machine learning 2) and as selection at chapter 33.
- **10. The chessboard: purely repetitive and therefore structural** (Array 1): array_tutorial (spine 3) comes before transformation (spine 2), which follows at chapter 12. All three parents agree here: Klee puts structure (I.5-8) before the organism (I.9), Form+Code puts Repeat before Transform, and Code as Creative Medium opens with Iterative Pattern. In Godot a body already has a transform from chapter 4, so the student needs many bodies before articulated ones.
- **11. Chance 1: disorder in the grid** (Randomness 1): Randomness 1, declared early (spine 10 at chapter 11). The student needs chance right after the first grid: regularity before randomness (10 PRINT), and chance entered Klee's lineage as Nake's and Nees's disturbance of a grid already built. Queer 3D's first principles and the application's WP1 both open with randomness. Randomness returns at its spine place as a round (chapter 24, Randomness 2) and as entropy (chapter 38, Randomness 3).
- **12. The organism: pivot and swing (Klee in drag I)** (Transformation 1): transformation (spine 2) comes after the chessboard and chance (spines 3 and 10). The organism is a chain built by chapter 10's loop, Klee's organism follows structure (I.9 after I.5-8), and Form+Code puts Transform after Repeat. The delta promised in chapter 2 is paid with the first body that moves by itself.
- **13. Pendulum, circle, spiral: time laid into space, and heard** (Waves 1): Waves 1, declared early (spine 9 at chapter 13, before colour 4 and forces 7). The organism's swing already runs on sin, and sin and cos are in 45% of Ada's scripts [V BRIEF], so the student meets the wave as a function while it is fresh; sound and sine curves are WP1 basic elements with no early place in the spine. This pendulum is a function of time. Klee's own order (the pendulum after gravity) is kept at chapter 21, where the forced pendulum returns as Waves 2.
- **14. A body is a family: one class, one axis, a sheet** (Primitives 9 (Parameterize 1)): Parameterize has no spine sequence, so this chapter returns to primitives halls (spine 1) after spine 9. The return is where the student needs it: 74% of Ada's scripts are @export families [V BRIEF], the ARGUMENT strand has asked for a family since chapter 1 on supplied bodies, and from here the student writes their own. The Parameterize strand continues as named returns: setters and @tool at chapter 25, genes as files at chapter 33, the measured budget at chapter 35.
- **15. Colour is a rule: the midpoint lives in the space** (Color 1): Colour (spine 4) is in spine order relative to its neighbours; the metric sees a step back only because chance and waves (spines 9-10) were met early at chapters 11 and 13. Colour is kept early on purpose, against the Klee parent that held it to the end as Klee's book does: art students need colour as a motivator, and the short track's families use it.
- **16. The tile and its rule** (Tiling 1): Tiling (spine 5) follows colour (4) as in the spine; the metric flags it only because chance and waves were visited early (chapters 11 and 13). It returns to randomness on purpose: the coin replaces the rule, which is 10 PRINT's own move.
- **17. Shader 1: the tile drawn per pixel** (Shaders 1): Shaders 1, declared early (spine 12 at chapter 17). The tile rule the student just wrote is the clearest possible first shader (the Book of Shaders teaches patterns before noise), and appearance by code early serves art students. The shader sequence returns at chapter 27 (Shaders 2, a skin that lies about its shape) and chapter 30 (Shaders 3, Turing's pattern on two buffers).
- **18. Noise 1: chance that remembers its neighbour, a ground to stand on** (Noise 1): Noise 1, declared early (spine 11 at chapter 18), straight after chance and the tile. Noise is second in Queer 3D's first principles and a WP1 basic element, and the short track's mini project needs a ground to stand its family on. Noise returns as wind at chapter 19 and as an editable, shared recipe at chapter 25 (Noise 2).
- **19. Flow field: a weather of bodies** (Change 1): change (spine 6) opens the force part after the early visits to chance, waves, shaders and noise (spines 9-12): the field is a noise field, so the ladder puts it after Noise 1. From here Part 4 walks spines 6-8 in order, with named returns.
- **20. The walker opened: velocity, scale, and a skin you can swap** (Forces 1 / Transformation 2): A declared return to transformation (Trans_Scale, spine 2) inside the force block. The supplied walker has carried the student since chapter 1, and it is opened where velocity is taught (NoC 1), because a walker is a velocity; scale is argued here because a room's size can only be read against a body the student now owns. The rest of the chapter is spine 7 in order.
- **21. Gravity by hand: your own integrator** (Forces 2 / Waves 2): Forces (spine 7) follow change (6) as in the spine; the metric flags the chapter only because of the early visits in Parts 2 and 3. Waves 2 is a named return: chapter 13's pendulum was a function of time, and here it is a spring integrated by force, which is Klee's order (pendulum after gravity) and NoC's (oscillation after forces).
- **22. Personal prosthetic: the arrow extends your reach** (Forces 3 / Color 2): A field trip back to colour (Color_Paint, spine 4) from the force block: the painting ray needs raycasts, which the student meets only now. The forces hall that carries the chapter is in spine order.
- **23. Legs: the passive part drives (Klee in drag II)** (Forces 4 / Transformation 3): Trans_Pit (transformation, spine 2) is revisited as the ground the legs cross; otherwise the chapter is spine 7 in order. It sits straight after raycasts because a foot finds the ground by a ray, and it answers chapter 12 (in drag I). The eleven chapters between them are what the student needs first: rays, a state, and a body they own.
- **24. To stand despite all possibilities to fall: a round (midterm)** (Formfinding 1 / Randomness 2): Formfinding and Randomness 2 (spines 8 and 10) close the force part as its synthesis. Formfinding follows forces as in the spine; chance returns at its own spine place as the engine of a round. Waves (spine 9) were met early at chapter 13, so no chapter sits between them.
- **25. Noise 2: the blob aesthetic, a recipe others can repair** (Noise 2 (Parameterize 2)): Noise 2, a declared return to spine 11 after the force part: the ground met at chapter 18 becomes editable in the editor and shareable as a file. The Parameterize strand continues here (setters, @tool, the recipe), and the sweep sheet supplied at chapter 14 is opened.
- **26. Implicit body: a field decides where the skin is** (Isosurfaces 1 / Boolean 1): isosurfaces and boolean surfaces (spines 18-19) are visited early, straight after Noise 2 and before cellular automata (13). An implicit body is the noise field the student just made, thresholded, so the student needs it now, not seven chapters later. Soft, collective and learning bodies (17, 20, 21) keep their spine order.
- **27. Shader 2: a skin that lies about its shape** (Shaders 2): Shaders 2, a declared return to spine 12 after the implicit body (18-19): the skin chapter 26 extracted is now painted and displaced by the GPU, so the student compares a skin that holds (marching cubes) with one that only shows (vertex displacement).
- **28. Data self-portrait: whose data draws the field** (Machine learning 2 / Post-crisis 2): Machine learning 2, a declared early visit (spine 21 at chapter 28, before the rule sequences 13-16). A classifier's decision field is the fourth picture of a field in this part, after the noise field, the implicit field and the shader, and Queer 3D puts 'models are always biased' in its foundation. Machine learning comes back as selection at chapter 33.
- **29. Life: a rule for neighbours** (Cellular automata 1): Cellular automata (spine 13) open the rules part in spine order; the metric flags the chapter only because implicit bodies and machine learning (spines 18-21) were visited earlier, in Part 5.
- **30. Turing's skin: two buffers on the GPU** (Shaders 3 / Soft bodies 1): Shaders 3 and a soft-bodies hall (spines 12 and 17) come right after Life: reaction-diffusion is Life's double buffer with continuous values, so it follows the buffer rather than the shader sequence, and the student ports the CPU version to the GPU met at chapters 17 and 27.
- **31. The tree and its mad branch: recursion that must be stopped** (Fractals 1): Fractals (spine 14) follow cellular automata as in the spine; flagged only because of earlier visits in Part 5.
- **32. Grammar: the point walks again** (L-systems 1 / Tiling 2): L-systems (spine 15) follow fractals as in the spine; flagged only because of earlier visits in Part 5. Named return: chapter 16's two modules become the grammar's symbols.
- **33. Bred, not designed: genes as files** (Procedural generation 1 / Machine learning 3 (Parameterize 3)): Procedural generation (spine 16) follows L-systems as in the spine; Machine learning 3 (ML_Evolution) is visited as a field trip because selection is learning without a gradient. The genes-as-files step of the Parameterize strand lands here.
- **34. How do we navigate an auto-generated world?** (Procedural generation 2 / Graph theory 1): Graph theory (spine 22) is pulled forward into procedural generation (16), before soft, collective and learning bodies (17, 20, 21). The application's WP3 asks 'How do we navigate an auto-generated world?' of exactly this pair, and it is the rules part's synthesis.
- **35. Soft: polycount against deformation, measured** (Soft bodies 2 (Parameterize 4)): Soft bodies (spine 17) come after graph theory (22), which was pulled forward at chapter 34; the return to spine order is declared here. The Parameterize strand closes: the family is measured against the headset's budget.
- **36. Many bodies, local rules: a species** (Swarm 1): Swarm intelligence (spine 20) follows soft bodies (17) as in the spine; flagged only because graph theory (22) came earlier at chapter 34.
- **38. Order toward entropy: your own prediction errors** (QFEP 1 / Randomness 3): Randomness 3, a declared return to spine 10 inside the QFEP chapter (spine 24): the chance met at chapter 11 comes back as a measure, closing the application's arc from order toward entropy.

## Chapters

### One body: point, line, plane (Code and form)

*From an instruction to a plane you walked and can stand on, with a scanned body beside it in the headset and a drafted body checked by you: the engine calls you, everything is an object, a line is a record, a surface has a side.*

#### 1. Day Zero: the instruction is the work (`d3_01`, Primitives 1; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Zero (encounter)
- **Code, new:** statements, output, errors. **Returns:** none
- **Body:** A LeWitt location drawing turned into one body: in the supplied base scene (floor, light, Label3D) you type one line that calls a supplied place_at(where) and a cube appears at 'corner', 'midpoint' or 'centre'; one print() writes your instruction to the Output panel.
- **Argument:** wording of the instruction: corner / midpoint / centre / somewhere near the middle. *Predict:* 'midpoint' and 'centre' will look most alike from the fixed camera (on a square floor both land on the middle line); 'somewhere near the middle' will not run at all, so it has no picture. *Claim:* An instruction a partner can interpret is not one the engine can run: ambiguity shows up as an error, not as a variation.
- **Debt:** LeWitt's drafters interpreted; the engine refuses. Literalness is the price of repeatability, and it is the first algorithmic debt the course names. GDScript's English keywords are the default of programming (Marino's FLOW-MATIC chapter), a cheap first question for Swedish-speaking students.
- **Place:** Stand, reach and turn in the room (desktop, or the headset through the supplied walker); then a partner executes your written instruction on paper and you compare the paper with the run.
- **Godot:** project against scene; F5 against F6; save; print() and the Output panel; reading an error in the Debugger panel; calling a supplied helper before writing one (use before make); Planted bug: a misspelled node name; read 'Node not found' aloud and fix it
- **Lineage:** Processing: Learning Processing ch2 (run, errors); Processing Handbook 'Structure 1: Code Elements'. NoC: none (NoC assumes this semester). Application: pre-WP foundation. Klee: Introduction: 'to stand despite all possibilities to fall' (the axiom returns at chapter 24). Reference: Sol LeWitt, Paragraphs on Conceptual Art (1967) and Wall Drawing 159 [mem]; Code as Creative Medium 'Computing without a Computer' [V ToC via c7]; Itten's warm-up before the pencil [mem]
- **Project step:** Start a sketchbook repository whose README will hold every prediction, comparison image, claim and debt comment of the course.

#### 2. Point Zero: the engine calls you, and counts frames (`d3_02`, Primitives 2; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Zero (carrier)
- **Code, new:** variables, expressions, lifecycle. **Returns:** statements, output, errors
- **Body:** A column that grows: its height is a variable set once in _ready() and increased by h += 0.01 in _process(); a Label3D beside it prints the frame count. The delta parameter is visible in the signature and deliberately unused.
- **Argument:** frame rate the scene runs at (--fixed-fps), height after five seconds: 30 / 60 / 90 / 120. *Predict:* 90 and 120 will look most alike (heights 4.5 m and 6 m, a ratio of 4:3); 30 is half of 60. A body grown per frame is a different body on every device. *Claim:* Growth counted in frames belongs to the machine: the headset at 90 Hz grows a column 1.5 times taller than a laptop at 60 Hz in the same five seconds.
- **Debt:** A frame is not a second, and the device decides how many there are, so the refresh rate becomes part of the body. The repair (delta) is held back on purpose until chapter 12, and the sketchbook says so. Headless runs draw no frames at all (an Ada trap), so a rule that counts frames behaves differently there.
- **Place:** Stand next to the column; note when it passes your head height on the desktop and again in the headset, and compare the two times.
- **Godot:** extends Node3D; func _ready(); func _process(delta); var and :=; a member variable keeps its value between calls; Label3D.text with str(); running with --fixed-fps to fix the frame rate; Planted bug: the variable declared inside _process, so it resets every frame and the column never grows; read the script, not the error
- **Lineage:** Processing: Learning Processing ch3 (setup/draw) and ch4 (variables); Handbook 'Structure 2: Continuous', early because Godot calls your code. NoC: NoC's draw() loop, assumed; delta is what it leaves implicit. Application: pre-WP. Klee: I.1 the point before it walks: potential energy (per c4, Praeger text). Reference: /course Point Zero kit [V BRIEF]; GDQuest Learn GDScript lessons 10-11 (game loop, delta) [V research_engine via c3]; the frame-rate debt is c1's ch2
- **Project step:** Put a counter at your hall's entrance and write down whether it counts frames or seconds.

#### 3. Point One: solid or ghost, one if decides what a body is (`d3_03`, Primitives 3; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_One (carrier)
- **Code, new:** calling, properties, conditions. **Returns:** variables, lifecycle, errors
- **Body:** A row of four bodies whose solid variable decides, in one if, whether their collision shape is enabled and how opaque they are; the supplied make_solid() and make_ghost() are called before they are opened, and a test ball is dropped on each.
- **Argument:** solidity and opacity: solid opaque / solid transparent / ghost opaque / ghost transparent. *Predict:* 'solid opaque' and 'ghost opaque' will look identical except for the test ball (resting on one, on the floor under the other). *Claim:* What you see and what stops you are separate properties; collision is invisible until another body meets it.
- **Debt:** A still, and every screenshot, cannot show collision: the visual argument has a blind spot, and so do players. Invisible walls and walkable ghosts are the course's first uncanny.
- **Place:** Walk into each body: two stop you, two let you through, and one of the transparent ones surprises you.
- **Godot:** if / else; comparison operators; a property by dot: $Shape.disabled, material.albedo_color.a; calling functions you did not write; StaticBody3D and CollisionShape3D (supplied); Planted bug: 'if solid = true:' (assignment in a condition); read the parse error's line number
- **Lineage:** Processing: Learning Processing ch5 Conditionals. NoC: none. Application: pre-WP. Klee: I.2-4 active, medial and passive lines: what acts and what is acted on (per c4). Reference: Kandinsky's polarities (repose against tension) [mem]; GDQuest Learn GDScript lesson 3: call supplied functions first [V research_engine via c4]
- **Project step:** Mark one of your points as a ghost and say in one sentence why.

#### 4. Point Coordinates: carry the point, name its reference (`d3_04`, Primitives 4; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Coordinates (carrier)
- **Code, new:** vectors, transforms, xr. **Returns:** properties, expressions, variables
- **Body:** A carried point that writes its own Vector3 beside itself, twice: global_position and position. A second point is placed at an expression of the first (a + Vector3.UP, a * 0.5). When you pick the point up it is reparented to your hand, and its local position jumps while its global one does not.
- **Argument:** which axis the same length goes into: (1,0,0) / (0,1,0) / (0,0,1) / (0.58,0.58,0.58). *Predict:* x and z will look most alike from a standing eye; y will not, because up is the direction your body has. *Claim:* The three axes are equal in the maths and unequal for a standing body: height is the one you feel.
- **Debt:** Y-up, metres and handedness are conventions baked into every later body. VR adds a default floor height and an eye height that assume a standing adult (Bagnall on normativity in hardware, Queer Game Studies [mem]). A transform is always relative to a parent, and whose hand is the parent is a question.
- **Place:** Pick the point up (desktop carry, or an XR Tools pickable in the headset) and watch both coordinates change as you move it. Pickup belongs here by the standing ruling.
- **Godot:** Vector3 arithmetic; global_position against position; reparenting to the hand; to_local / to_global; the supplied desktop carry and XRToolsPickable; where the desktop rig is swapped for the XR rig (commons/scenes/vr_staging.tscn [mem path]); Planted bug: position set instead of global_position after reparenting, so the point flies away; read both labels
- **Lineage:** Processing: Learning Processing ch1 coordinates; Handbook 'Shape 1: Coordinates'. NoC: ch1 Vectors, as positions only. Application: pre-WP ('vectors' as a basic concept, application l.9). Klee: II.14 three dimensions, borrowed early (per c4). Reference: LeWitt's corner, midpoint and centre as a coordinate system before Vector3; the Point Coordinates kit [V BRIEF]
- **Project step:** Put your three points in 3D, one of them above head height, and carry one of them.

#### 5. Point Lines: distance belongs to the line (`d3_05`, Primitives 5; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Lines (carrier)
- **Code, new:** functions, parameters, return. **Returns:** vectors, conditions, transforms, calling
- **Body:** A segment between two carried points: your function show_between(a, b) places, scales and orients a thin box and returns the distance; a do-not-cross barrier reacts when that distance falls below a threshold (condition before threshold).
- **Argument:** thickness as a fraction of length: 0.005 / 0.02 / 0.1 / 0.4. *Predict:* 0.005 and 0.02 will look most alike (both read as lines); 0.4 reads as a slab. *Claim:* A line in 3D is a thin body: the ratio of thickness to length decides whether we read a line or a plane.
- **Debt:** The engine has nothing one-dimensional to show: the line is a box pretending. Distance is a return value, and every later threshold is a design decision hidden as a number.
- **Place:** Hold both ends (two hands in the headset: Klee's maker 'who has only two hands') and stretch the line until it crosses the barrier.
- **Godot:** func, parameters, return, typed return -> float; Vector3.distance_to, look_at; Node3D.scale; the supplied SKETCH helper line(a, b), used here and opened in chapter 6; Planted bug: look_at called while the two points coincide; read the 'up vector and direction are aligned' warning
- **Lineage:** Processing: Learning Processing ch7 Functions; Handbook 'Shape 1' line(). NoC: ch1 Vectors (magnitude). Application: pre-WP. Klee: I.1 an active line; I.3 a line limited by fixed points (per c4). Reference: Kandinsky, Point and Line to Plane [mem]; the Point Lines kit and its segment.gd [V BRIEF]
- **Project step:** Connect two of your points with your own function, named after what it makes.

#### 6. Point Trace: a line is a record (`d3_06`, Primitives 6; tracks: short, long)

- **Spine:** primitives. **Halls:** Point_Trace (carrier)
- **Code, new:** arrays, loops, meshes. **Returns:** functions, conditions, vectors, lifecycle
- **Body:** A trace recorder: the carried point appends its position to an array once it has moved further than a gate distance (list before append, condition before threshold), and a for loop redraws the array as an ImmediateMesh line strip. This opens the SKETCH helper you have been calling: its line() was an ImmediateMesh all along.
- **Argument:** sampling gate: 0.01 m / 0.05 m / 0.2 m / 0.5 m. *Predict:* 0.01 and 0.05 will look most alike (both read as continuous); 0.5 turns the walk into a polygon with visible corners. *Claim:* A recorded line is a sampling decision: below a few centimetres the walk looks continuous, above it the corners become the drawing.
- **Debt:** Continuity is faked from a list, and memory is not free, so the trace must forget (a bounded array): forgetting is a choice about which past counts. Chun's 'sourcery': opening the helper shows its source, not what the GPU does with the strip; seeing code is not knowing it.
- **Place:** Become the pen: the trace follows your hand (headset) or the carried point (desktop) while you walk a line through the hall, Klee's walk for a walk's sake.
- **Godot:** Array, append(), size(), pop_front() for the bound; for p in points; ImmediateMesh PRIMITIVE_LINE_STRIP: surface_begin, surface_add_vertex, surface_end; the Point Trace runnable kit [V BRIEF]; Planted bug: points[points.size()] (index out of range); read the Debugger's message and the line it names
- **Lineage:** Processing: Learning Processing ch6 Loops, ch9 Arrays (mouse history); Handbook 'Control 2: Repetition'. NoC: ch0 the random walk, as a later return. Application: pre-WP. Klee: I.1 'an active line on a walk, moving freely, without goal' (per c4). Reference: Klee I.1 (Point_Trace's final.md cites it, per c4); Tilt Brush drawing in space (Queer 3D 2024 week 1) [V QUEER3D.md]; Chun, Programmed Visions ch1 [V contents via LEARN]
- **Project step:** Record one walk of your own and keep it as data in your project.

#### 7. Plane: when the walk closes (`d3_07`, Primitives 7; tracks: long)

- **Spine:** primitives. **Halls:** Point_Triangle_Context (carrier); Primitives_Polythedra (field trip)
- **Code, new:** surface_tool, normals, collision. **Returns:** arrays, loops, meshes, vectors, conditions
- **Body:** Close the walk: the recorded points become a triangle fan through SurfaceTool, normals are generated, and a collider made from the mesh lets you stand on the plane you walked.
- **Argument:** winding and normals: clockwise, flat normals / clockwise, smooth normals / counter-clockwise (reversed) / reversed, double-sided. *Predict:* 'clockwise flat' and 'reversed double-sided' will look most alike from above; 'reversed' alone vanishes from the front. *Claim:* A surface has a side: what you see of a plane is a promise its winding and normals make (Godot winds front faces clockwise).
- **Debt:** Culling (Gaboury, Image Objects ch1): hidden-surface rules decide what exists for the eye; a one-sided plane is invisible from behind while its collider still stops you. The fan also fails on a concave walk: the approximation owes the shape its dents.
- **Place:** Stand on your walk: the plane made from your own trace becomes floor; walk to its edge and look under it.
- **Godot:** SurfaceTool PRIMITIVE_TRIANGLES; generate_normals(); commit(); create_trimesh_shape(); StaticBody3D; cull_mode on the material; Planted bug: triangles wound counter-clockwise; the plane is gone and no error is printed, so the still is the message
- **Lineage:** Processing: Learning Processing ch14 vertex shapes; Handbook 'Shape 2: Vertices'. NoC: none. Application: pre-WP; the application's 'queer meshes' start here. Klee: I.2-4 'once completed, this linearity is replaced by planarity' (per c4, Praeger text). Reference: Kandinsky, Basic Plane [mem]; Gaboury, Image Objects I 'Culling Vision' [V research_engine via c4]
- **Project step:** Your first room is one plane you walked, three points and one line. Commit it.

#### 8. Collage: a found body among made ones, in the headset (`d3_08`, Primitives 8; tracks: short, long)

- **Spine:** primitives. **Halls:** Primitives_Melencolia (carrier); Point_One (encounter)
- **Code, new:** import_assets, instancing, export_build. **Returns:** xr, meshes, transforms, functions
- **Body:** Recreate a precedent, then depart: the truncated solid of Durer's Melencolia I built procedurally, beside a body you scanned (phone photogrammetry), drew in Tilt Brush or sculpted in Blender, imported as glTF and instanced as a scene with a generated collider. Then export a desktop build and a Quest build.
- **Argument:** decimation of the scanned mesh (share of triangles kept): 100% / 25% / 5% / 1%. *Predict:* 100% and 25% will look most alike at 2 m, because the eye stops counting triangles past a density; at 1% the scan turns into a faceted polyhedron that looks coded. *Claim:* Below some polycount a scanned body starts to look procedural: the line between found and made is a triangle budget.
- **Debt:** A scan is not a copy: it fills holes, smooths, and bakes the light into its texture. Scanners fail on hair, dark skin, glass and moving bodies, which is a body politics (Queer 3D's 'bias'; Blas's Facial Weaponization Suite [V research_queer via c3]). The Quest's 72/90 Hz budget makes the 100% scan unaffordable. The Melencolia hall says its hidden surfaces 'are decisions we have made' (per c4).
- **Place:** Become it: enter your room in the headset through the supplied XR rig and stand beside your scan at 1:1 scale. A classmate walks it from your exported build: the first time your body exists outside your editor.
- **Godot:** drag a .glb into the FileSystem dock; import settings (scale, generate collision); PackedScene.instantiate() and add_child(): a scene is a body you can stamp; swap the desktop walker for the supplied XR rig; Project > Export: a desktop preset and the Android/Quest preset (the headset is an export); Planted bug: the scan imported at 100x scale; read the Inspector's transform before blaming the code
- **Lineage:** Processing: Handbook 'Synthesis 1: Form and Code'. NoC: none. Application: VR as the medium (the application's premise); open-source sharing (Illich). Klee: I.11-12 building stone upon stone against carving away (per c4). Reference: Queer 3D World 2024 week 1: scanning, Tilt Brush, export [V QUEER3D.md]; Hannah Hoch's collage (Queer 3D lineage) [V QUEER3D.md]; SFPC Recreating the Past [V research_creative via LEARN]; Durer, Melencolia I (1514)
- **Project step:** SYNTHESIS I (checkpoint): your hall holds one found body and three made bodies, and a classmate has walked it from your build.

#### 9. When things go wrong: the drafter is a model (`d3_09`, Machine learning 1 / Post-crisis 1; tracks: short, long)

- **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Generative (field trip); ML_Sequence_Memory (encounter); CriticalAlgorithms_Algorithmic_Bias_Visualization (encounter)
- **Code, new:** ai_assist, debugging, types. **Returns:** errors, functions, parameters, arrays, instancing
- **Body:** Your Day Zero instruction body, drafted a second time by an AI assistant as GDScript. You write three lines before you prompt: what should change, what must not change, and one observation that would prove the code wrong. You run it, break it on purpose, step through it with breakpoints, then add static types so the editor catches what the model guessed.
- **Argument:** how much the prompt fixes: vague / counted / measured / located. *Predict:* 'vague' and 'counted' will look most alike: both come back as a default cube or capsule at the origin, because the model fills every open slot with its most common answer. *Claim:* Where the prompt is open, the model fills in its defaults; the generated body shows the model's idea of a body, not yours.
- **Debt:** The default body and algorithmic enclosure: the assistant learned from other people's code and repeats its norms (the capsule player, the cube at the origin). ML_Generative shows a generated cloud that stays near its training cloud: the drafter samples near what it has seen. Chun's 'sourcery' again: generated source you can read is not code you know. A green run is not a check: a typed set() on a mistyped property is refused in silence (Ada's own science_screen case [V CLAUDE.md]), so the falsifying observation must be something you look at.
- **Place:** Walk ML_Generative: stand where the real and the generated clouds overlap, then where the generated cloud never goes. Your hand-made and your drafted body stand side by side in your hall.
- **Godot:** breakpoints, step over / into, the Debugger's stack and variables; the remote scene tree while the game runs; static typing: var n: int, -> Vector3; the editor's warnings; push_error() and assert() as your falsifying observation; Planted bug: the generated script calls a Godot 3 method (translation instead of position); read the error and name what the model remembered
- **Lineage:** Processing: Handbook 'Development 1: Sketching' and 'Development 2: Iteration, Debugging'. NoC: none. Application: WP4 AI (early encounter); the application's hacker ethics: Illich's transparency and repairability. Klee: none. Reference: Code as Creative Medium 'When Things Go Wrong' [V ToC via c7]; LeWitt's drafters as the model for directing a machine drafter [V research_bauhaus via c7]; Queer 3D 2024 'use ChatGPT to write simpler programs' [V QUEER3D.md]; Chun, 'On Sourcery' [V contents via LEARN]
- **Departure:** Machine learning 1, an early and declared visit (spines 21 and 25 at chapter 9). Queer 3D's first principles put 'what are machine-learning models like the LLMs behind ChatGPT?' in the foundation, and its practice is 'use ChatGPT to write simpler programs', so the short track needs the checking protocol in week one, before a student meets a generated bug alone. The halls are walked, not coded. Machine learning returns as a field over the floor at chapter 28 (Machine learning 2) and as selection at chapter 33.
- **Project step:** Have your Day Zero body built once by an assistant and once by yourself; keep both, the prompt and the three lines.

### Many bodies: repeat, disturb, articulate, parameterize

*One rule makes a floor; a seed disturbs it; joints make an organism whose parent commands its child; a sine lays time into space and sound; and your body becomes a class whose exported axis is a family you can argue about.*

#### 10. The chessboard: purely repetitive and therefore structural (`d3_10`, Array 1; tracks: short, long)

- **Spine:** array_tutorial. **Halls:** Array (carrier); Tutorial_3D (field trip); Tutorial_Tiling_Floor (encounter)
- **Code, new:** nested_loops, materials. **Returns:** loops, instancing, conditions, properties, collision
- **Body:** A floor of cubes instanced from a PackedScene in a nested loop and coloured by a rule over (x, z) from a supplied palette of two materials, Albers's constrained paper.
- **Argument:** rhythm rule: every cell / (x+z)%2 chessboard / x%3 stripes / 2:3:5 proportional widths. *Predict:* The chessboard and the x%3 stripes will look most alike from far away, where both read as texture; 'every cell' is the only floor without rhythm. *Claim:* Structure is the repetition rule, not the cube: the same 64 bodies make four different floors.
- **Debt:** The grid is the unexamined ground of 3D (editor grids, voxels, the frame buffer as a random-access grid in Gaboury). It is a choice, and the standing ruling holds that the first line did not need it. Molnar's series in the Array hall [V LEARN] asks what one rule leaves out.
- **Place:** Walk the floor; turn one cell into a ghost with chapter 3's if and fall through it.
- **Godot:** nested for over range(); StandardMaterial3D shared against per instance; the % operator; Planted bug: one material instance edited in the loop, so every cube changes colour at once; the still is the message
- **Lineage:** Processing: Learning Processing ch6 nested loops; Form+Code 'Repeat'. NoC: none. Application: pre-WP. Klee: I.5-6 structural rhythm, the chessboard, 'purely repetitive and therefore structural'; I.7 proportion 2:3:5 (per c4). Reference: Albers's constrained material: the two-colour palette is supplied like Color-aid paper [V research_bauhaus via c4]; Code as Creative Medium 'Iterative Pattern' [V ToC via c7]
- **Departure:** array_tutorial (spine 3) comes before transformation (spine 2), which follows at chapter 12. All three parents agree here: Klee puts structure (I.5-8) before the organism (I.9), Form+Code puts Repeat before Transform, and Code as Creative Medium opens with Iterative Pattern. In Godot a body already has a transform from chapter 4, so the student needs many bodies before articulated ones.
- **Project step:** Lay a floor for your hall with a rhythm rule of your own.

#### 11. Chance 1: disorder in the grid (`d3_11`, Randomness 1; tracks: short, long)

- **Spine:** randomness. **Halls:** Random_Definition (carrier); Randomness_10_PRINT_Algorithm (carrier); Random_Remove (field trip)
- **Code, new:** random, seeds. **Returns:** nested_loops, instancing, materials, transforms, collision
- **Body:** Schotter as a floor: your chessboard of cubes rotated and displaced by a seeded RandomNumberGenerator, more with every row; then 10 PRINT as a walkable maze, one of two rotations per cell.
- **Argument:** disorder amplitude (maximum rotation in the last row): 0 deg / 5 deg / 20 deg / 90 deg. *Predict:* 0 and 5 will look most alike: the grid still reads. Somewhere between 5 and 20 it stops reading as a grid. *Claim:* Randomness is visible only against a structure already built: the grid is what lets us see disorder.
- **Debt:** Computer randomness is pseudo-random: the same seed returns the same 'chance' (Random_Definition: a pattern that returns). Nake's question from Hommage a Paul Klee (1965): can a pseudo-random number stand in for intuition? Who chose the seed is who chose the disorder.
- **Place:** Walk down the Schotter floor until the disorder makes it unwalkable (the colliders follow the cubes); get lost in the 10 PRINT maze.
- **Godot:** RandomNumberGenerator, seed, randf_range, randi_range; per-instance rotation_degrees; the random-definition runnable kit [V BRIEF]; Planted bug: randomize() left in after setting the seed, so the 'same' floor differs on every run; compare two screenshots
- **Lineage:** Processing: Learning Processing ch4 random(); Handbook 'Math 4: Random'. NoC: ch0 Randomness. Application: WP1 Basic Elements: randomness. Klee: absent from Klee: chance enters his lineage in 1965-68 (per c4). Reference: Frieder Nake, Hommage a Paul Klee 13/9/65 Nr. 2 [V research_bauhaus via c4]; Georg Nees, Schotter (1968) [V]; Vera Molnar, (Des)Ordres [mem]; 10 PRINT 'Regularity' before 'Randomness' [V research_ccs]
- **Departure:** Randomness 1, declared early (spine 10 at chapter 11). The student needs chance right after the first grid: regularity before randomness (10 PRINT), and chance entered Klee's lineage as Nake's and Nees's disturbance of a grid already built. Queer 3D's first principles and the application's WP1 both open with randomness. Randomness returns at its spine place as a round (chapter 24, Randomness 2) and as entropy (chapter 38, Randomness 3).
- **Project step:** Add a seeded disorder to your floor and record the seed you keep.

#### 12. The organism: pivot and swing (Klee in drag I) (`d3_12`, Transformation 1; tracks: short, long)

- **Spine:** transformation. **Halls:** Trans_Rotation (carrier); Trans_Body (carrier); Trans_Introduction (field trip); Trans_Pre (encounter)
- **Code, new:** basis, delta, trig. **Returns:** transforms, vectors, loops, instancing, lifecycle, expressions
- **Body:** A limb of three segments as a parent-child chain with pivots, built by a loop; each joint's angle is amplitude * sin(TAU * f * t + phase), with t += delta, the course's first body that moves by itself. The frame-rate debt from chapter 2 is repaid here.
- **Argument:** where the pivot sits on each segment: at the end / at one third / at the centre / outside the segment. *Predict:* 'at the end' and 'at one third' will look most alike after 30 degrees; 'outside' makes the chain orbit instead of bend. *Claim:* A body's motion is decided by where its joints are, not by what its parts look like.
- **Debt:** Klee maps active, medial and passive onto brain, muscle and bone and onto male and female organs (I.9-12, per c4's reading of the Praeger text). The scene tree encodes the same command chain: the parent moves the child, never the reverse. Klee in drag starts here as a code fact, not a costume; chapter 23 inverts it.
- **Place:** Become it: attach the chain to your hand (headset) or the carried point and walk it through Trans_Body's lattice, carving a passage with your own movement.
- **Godot:** Node3D hierarchy; pivots as parent nodes; Basis and rotate_object_local; sin(), TAU; angles in radians; _process(delta) at last: the column from chapter 2 now grows by seconds; Planted bug: rotation_degrees fed radians; the limb spins wildly; read the numbers in the Inspector
- **Lineage:** Processing: Learning Processing ch14 Transformations; Handbook 'Transform 1-2'. NoC: ch3 Oscillation, angular motion (preview). Application: WP1 sine curves (first meeting). Klee: I.9-12 bone, tendon and muscle; active, medial and passive (per c4). Reference: Gaboury, Image Objects IV 'Object Paradigms' [V research_engine via c4]; Form+Code 'Transform' [V themes via c3]
- **Departure:** transformation (spine 2) comes after the chessboard and chance (spines 3 and 10). The organism is a chain built by chapter 10's loop, Klee's organism follows structure (I.9 after I.5-8), and Form+Code puts Transform after Repeat. The delta promised in chapter 2 is paid with the first body that moves by itself.
- **Project step:** Give one body in your hall a jointed part that swings.

#### 13. Pendulum, circle, spiral: time laid into space, and heard (`d3_13`, Waves 1; tracks: long)

- **Spine:** wavefunctions. **Halls:** WaveFunctions_Pendulum (carrier); WaveFunctions_Unit_Circle (carrier); WaveFunctions_Effect_Sound (field trip); Wavefunctions_Bernini (field trip); WaveFunctions_John_Cage (encounter)
- **Code, new:** queues, audio. **Returns:** trig, delta, lifecycle, arrays, instancing, loops
- **Body:** A pendulum bob moved by a sine of time; each tick its position goes into a bounded queue and the queue is laid out along an axis as a row of marks, a slit-scan body in space. Then (cos t, sin t) as a runner on a circle, and a radius that grows with t for a spiral column (Bernini). The bob's height sets the pitch of a generated tone.
- **Argument:** radius growth per turn: -0.2 / -0.05 / 0 / 0.05 / 0.2. *Predict:* -0.05 and 0.05 will look most alike (two near-circles drifting in opposite directions); -0.2 closes to a point and 0.2 opens into a coil. *Claim:* One number turns a circle into a spiral of life or of death: Klee's pendulum becomes a direction.
- **Debt:** sin and cos are computed approximations, and ticks sample time: change physics_ticks_per_second and see the steps in the slit-scan. A queue forgets its oldest sample. The tone is sampled too, and a high pitch aliases. The golden spiral carries a myth of nature's law, a claim to test, not to teach.
- **Place:** Walk through it: at room scale the slit-scan body is a corridor along the pendulum's past, and the tone follows you down it.
- **Godot:** push_back() and pop_front() on a capped Array (a queue); _physics_process and physics_ticks_per_second; AudioStreamGenerator or AudioStreamWAV; AudioStreamPlayer3D; a row of instanced marks updated from the queue; Planted bug: the queue is never capped; watch the node count in the Monitors climb and the frame time follow
- **Lineage:** Processing: Handbook 'Math 3: Trigonometry'. NoC: ch3 Oscillation, met here as a function of time before forces. Application: WP1 sine curves, resonance frequencies and sound experiments; WP2 Fourier transforms (Synthesis_Lab named as the return). Klee: IV.33-37 pendulum, then circle, then the expanding and contracting spiral (per c4 and c3). Reference: Form+Code 'Transform: Slit-Scan' [V code example via c3]; Whitney, Animation and Harmony [mem]; John Cage's chance operations (encounter) [mem]
- **Departure:** Waves 1, declared early (spine 9 at chapter 13, before colour 4 and forces 7). The organism's swing already runs on sin, and sin and cos are in 45% of Ada's scripts [V BRIEF], so the student meets the wave as a function while it is fresh; sound and sine curves are WP1 basic elements with no early place in the spine. This pendulum is a function of time. Klee's own order (the pendulum after gravity) is kept at chapter 21, where the forced pendulum returns as Waves 2.
- **Project step:** Lay one motion from your hall out in space, and let it make one computed sound.

#### 14. A body is a family: one class, one axis, a sheet (`d3_14`, Primitives 9 (Parameterize 1); tracks: short, long)

- **Spine:** primitives. **Halls:** Primitives_Ignorance (carrier); Primitives_Polythedra (field trip); Primitives_Portals (encounter)
- **Code, new:** classes, export, methods. **Returns:** functions, parameters, return, trig, loops, instancing, types
- **Body:** class_name Pyramid extends MeshInstance3D with typed @export fields base_sides, radius and height and a build() method that makes the mesh: the base ring with sin and cos in a loop, so base_sides = 3 gives a tetrahedron. A supplied sweep_sheet scene instances five members side by side, the comparison still as a scene.
- **Argument:** base_sides: 3 / 4 / 6 / 12 / 48. *Predict:* 12 and 48 will look most alike: past about a dozen sides a pyramid reads as a cone. *Claim:* A class's fields decide which bodies are possible: base_sides makes pyramid and cone one family, and no value of it makes a sphere.
- **Debt:** The modelling choice is the critique (the CCSWG prompt 'describe it in a single class', turned to a body). One integer carries the body across a category, pyramid to cone, and nothing in the class marks where; the category was never in the code. What the class cannot express (two apexes, no apex) and what its types forbid (3.5 sides) are borders: write them in a comment. Primitives_Ignorance counts triangles: every family has a price.
- **Place:** Walk the sheet as a gallery wall, then stand on the members as steps; which ones can you stand on top of?
- **Godot:** class_name and extends; func build() -> void as a method; self; @export and @export_range with typed fields; the supplied sweep_sheet.gd (opened in chapter 25); Planted bug: @export var base_sides := 4.0 (a float), so the sweep writes 3.5 and the ring breaks; read the type in the Inspector
- **Lineage:** Processing: Learning Processing ch8 Objects (Zoog becomes a class); Handbook 'Shape 3: Parameters'. NoC: ch0-1 the Walker and Mover classes. Application: WP2 'queer meshes' (polycount); the application's families. Klee: I.7-8 proportion and linear variation (per c4). Reference: Form+Code 'Parameterize' [V themes via c3]; CCSWG 2024 'describe war in a single class' [V research_ccs via c3]; Code as Creative Medium 'Parametric Object' [V ToC via c7]; Generative Design's numbered variants [V via LEARN]
- **Departure:** Parameterize has no spine sequence, so this chapter returns to primitives halls (spine 1) after spine 9. The return is where the student needs it: 74% of Ada's scripts are @export families [V BRIEF], the ARGUMENT strand has asked for a family since chapter 1 on supplied bodies, and from here the student writes their own. The Parameterize strand continues as named returns: setters and @tool at chapter 25, genes as files at chapter 33, the measured budget at chapter 35.
- **Project step:** SYNTHESIS II: rewrite your hall's main body as one class with one exported axis, write the closest-pair prediction, then render the sheet.

### Surfaces that argue: colour, tile, pixel, noise (Visualize 1)

*Colour as a path through a space, a tile as a truth table, the same rule per body, per texel and per pixel, and noise as chance that remembers its neighbour: a ground for your family.*

#### 15. Colour is a rule: the midpoint lives in the space (`d3_15`, Color 1; tracks: short, long)

- **Spine:** color. **Halls:** Color_Grid_Pallet (carrier); Color_Flashlight (carrier); Color_Walls (field trip); Color_Rainbow (encounter)
- **Code, new:** interpolation, dictionaries. **Returns:** materials, classes, export, nested_loops, normals
- **Body:** A floor of pixel bodies you stand on: each tile a box whose albedo is computed from its index by a rule between two complementary colours; a Dictionary keyed by Vector2i finds the tile under your feet and recolours it. One albedo is then placed under two lamps.
- **Argument:** the space a nine-tile gradient walks through: RGB lerp / HSV short way / HSV long way / HSV stepped in 4. *Predict:* 'HSV short way' and 'HSV stepped' will look most alike (stepping only quantises the same path); RGB lerp passes through a grey in the middle and stands apart. *Claim:* The midpoint of two colours is not in the colours but in the space you choose to walk between them; Klee's central grey belongs to RGB.
- **Debt:** Colour on screen is a gamut, a lamp and a normal, not a property of the body: the same albedo reads differently under the flashlight because light meets the surface at an angle. Film stock calibrated to one skin tone (the Shirley card) [mem]: the pixel has a politics. Albers's universal eye and Klee's colour spiritualism are claims to test.
- **Place:** Stand on it: the tile under your feet changes by the rule; hold the flashlight and see the surface change while the material does not.
- **Godot:** Color.lerp() and Color.from_hsv(); Dictionary with Vector2i keys; has() and get(); StandardMaterial3D.new(), albedo_color; SpotLight3D and the Environment's tonemap (glimpse); Planted bug: hue = i / 9 with integers, so every tile is red (hue 0); print the value
- **Lineage:** Processing: Learning Processing ch1 (RGB); Handbook 'Color 1-2'. NoC: none. Application: WP3 shading (colour as appearance). Klee: IV.39-43 chromatic energy, the colour circle and the central grey, visited early (per c4). Reference: Albers, Interaction of Color (1963) [V research_bauhaus]; Code as Creative Medium 'Custom Pixel' [V ToC via c7]; Knowlton and Harmon, Studies in Perception I (1966) [mem]
- **Departure:** Colour (spine 4) is in spine order relative to its neighbours; the metric sees a step back only because chance and waves (spines 9-10) were met early at chapters 11 and 13. Colour is kept early on purpose, against the Klee parent that held it to the end as Klee's book does: art students need colour as a motivator, and the short track's families use it.
- **Project step:** Give your family a colour rule computed from its index, not picked by hand.

#### 16. The tile and its rule (`d3_16`, Tiling 1; tracks: long)

- **Spine:** tiling. **Halls:** Pattern_Foundry (carrier); Tutorial_Pattern (field trip); Symmetry_Seventeen (field trip); Array_Patterns (encounter)
- **Code, new:** uv, booleans, multimesh. **Returns:** nested_loops, conditions, dictionaries, materials, random, seeds
- **Body:** A Truchet alphabet in 3D: two module bodies (a quarter-arc tile and its turned twin) placed by a boolean rule of the cell index and drawn as one MultiMesh when the floor reaches 64 by 64; the rule is then replaced by a seeded coin (10 PRINT returns), and finally baked into an Image repeated across one plane by UV scale, the flat port.
- **Argument:** the rule that decides which module goes where: all the same / checker (i + j) % 2 / row parity i % 2 / diagonal i == j / xor of both parities. *Predict:* Checker and xor will look most alike, identical in fact: the xor of the two parities is the checker written another way. 'All the same' stands apart as long waves. *Claim:* Two rules that read differently can be one rule; the pattern shows the rule's truth table, not its wording.
- **Debt:** The seventeen wallpaper groups are a closed list; a pattern the list does not name is still a pattern (tiling's standing ruling: cumulative encounters, not a derivation). A texture is a promise: the UV plane looks tiled but is flat to the feet. One MultiMesh is one draw call: the frame budget decides how many bodies a floor can have.
- **Place:** Walk the floor of module bodies; then step onto the flat textured port and feel no arcs underfoot.
- **Godot:** bool; and / or / not; %; MultiMeshInstance3D; set_instance_transform; Image.create() and set_pixel(); ImageTexture; uv1_scale on StandardMaterial3D; Planted bug: instance_count set after the transforms, so the floor is empty; read the docs line for instance_count
- **Lineage:** Processing: Learning Processing ch5 (else, and, or); Handbook 'Control 1: Decisions'. NoC: none. Application: WP3 'unique and dynamic patterns'. Klee: I.5-6 the chessboard, quantitative structure in two dimensions (per c4). Reference: Code as Creative Medium 'Modular Alphabet' [V ToC via c7]; Truchet (1704) [mem]; 10 PRINT ch30 'Regularity' [V research_ccs]
- **Departure:** Tiling (spine 5) follows colour (4) as in the spine; the metric flags it only because chance and waves were visited early (chapters 11 and 13). It returns to randomness on purpose: the coin replaces the rule, which is 10 PRINT's own move.
- **Project step:** Design two modules for your body and a rule that places them; keep the rule, because a coin will replace it.

#### 17. Shader 1: the tile drawn per pixel (`d3_17`, Shaders 1; tracks: long)

- **Spine:** shaders. **Halls:** Shader_05_Patterns (carrier); Shader_01_Shaping (carrier)
- **Code, new:** shaders. **Returns:** uv, booleans, interpolation, materials, trig
- **Body:** The Truchet rule of chapter 16 written a third time, in fragment(): floor(UV * n) finds the cell, mod decides the module, step and smoothstep draw the arc. Three floors stand side by side: per body (MultiMesh), per texel (the baked Image) and per pixel (the shader).
- **Argument:** where the same rule is evaluated: per body / per texel (baked Image) / per pixel (shader) / per pixel, with a smoothstep edge. *Predict:* The baked Image and the shader will look most alike at 3 m (the same rule sampled near pixel density); up close the Image blurs and the shader stays sharp, and only 'per body' has relief. *Claim:* The same rule at three resolutions is three bodies: only the per-body floor has an underside, and only the shader has no pixels of its own.
- **Debt:** The GPU as 'procedure crystallized' (Gaboury, Image Objects ch5): every pixel asks the same question at once and cannot remember its neighbour, which is why noise and reaction-diffusion will need buffers. A shader is a picture, not a body: the pattern has no collider.
- **Place:** Walk from the MultiMesh floor onto the shader floor: relief gives way to paint. Kneel (headset) and see which floor turns into pixels.
- **Godot:** ShaderMaterial; shader_type spatial; fragment(); UV, TIME, floor(), mod(), step(), smoothstep(); ALBEDO and EMISSION; Planted bug: an int literal where a float is expected (mod(uv.x, 2)); read the shader compile error, which the script checker cannot see
- **Lineage:** Processing: Handbook 2nd ed. 'Render Techniques' [mem]. NoC: none. Application: WP3 shading algorithms. Klee: IV colour as energy (per c4). Reference: The Book of Shaders, 'Patterns' before 'Random' and 'Noise' [V research_engine]; Gaboury, Image Objects V [V research_engine via c4]
- **Departure:** Shaders 1, declared early (spine 12 at chapter 17). The tile rule the student just wrote is the clearest possible first shader (the Book of Shaders teaches patterns before noise), and appearance by code early serves art students. The shader sequence returns at chapter 27 (Shaders 2, a skin that lies about its shape) and chapter 30 (Shaders 3, Turing's pattern on two buffers).
- **Project step:** Port one surface of your hall to a shader and write down what the port lost.

#### 18. Noise 1: chance that remembers its neighbour, a ground to stand on (`d3_18`, Noise 1; tracks: short, long)

- **Spine:** noise. **Halls:** Noise_Columns (carrier); Noise_Space_10 (carrier); Random_Noise_Types (field trip); Noise_Voxel (encounter)
- **Code, new:** noise, packed_arrays. **Returns:** random, seeds, nested_loops, instancing, multimesh, surface_tool, collision, export
- **Body:** Two grounds side by side: a grid of columns whose heights come from randf(), and the same grid with heights from FastNoiseLite.get_noise_2d(x, z). The noise heights are then stored in a PackedFloat32Array and turned into one continuous skin with a collider you can walk on.
- **Argument:** octaves (fractal layers of the noise): 1 / 2 / 4 / 8. *Predict:* 4 and 8 will look most alike: each octave halves the amplitude, so after four the added detail is smaller than one column. 1 is the smooth blob landscape. *Claim:* Noise is chance that remembers its neighbours; octaves add detail only down to the size of the bodies that show it.
- **Debt:** The blob aesthetic (Queer 3D): Perlin and simplex noise made a whole era of 3D look alike, soft hills and organic blobs, 'nature' chosen for being cheap and smooth. Palle's overflow comparison (Perlin 45, random 635, Voronoi 0, sine space 3284) [V QUEER3D.md] shows how differently the families escape.
- **Place:** Stand on it: the randf ground is unwalkable, the noise ground is a stroll; at eight octaves your feet catch on the fine steps.
- **Godot:** FastNoiseLite: noise_type (incl. cellular), frequency, fractal_octaves, seed; PackedFloat32Array; SurfaceTool from a height grid; create_trimesh_shape(); Planted bug: the noise sampled at integer coordinates with frequency 1, so every height is 0; print five samples
- **Lineage:** Processing: Learning Processing ch13 noise(); Handbook 'Math 4'. NoC: ch0 'Perlin Noise (a Smoother Approach)'. Application: WP1 Perlin noise and Voronoi diagrams. Klee: none. Reference: Code as Creative Medium 'Generative Landscape' [V ToC via c7]; Montfort's free project 'Create a Navigable Generated Landscape' [V research_ccs]; Perlin (1985) [mem]
- **Departure:** Noise 1, declared early (spine 11 at chapter 18), straight after chance and the tile. Noise is second in Queer 3D's first principles and a WP1 basic element, and the short track's mini project needs a ground to stand its family on. Noise returns as wind at chapter 19 and as an editable, shared recipe at chapter 25 (Noise 2).
- **Project step:** SYNTHESIS III (the short track's last teaching day): give your family a ground, a noise field it stands on, with a seed you can print.

### Bodies under force: flow, walk, fall, reach, stand (Simulate 1)

*The walker that carried you is opened; you write gravity yourself, extend your reach with a ray, invert the command chain with legs, and build a small complete round about standing despite every possibility of falling.*

#### 19. Flow field: a weather of bodies (`d3_19`, Change 1; tracks: long)

- **Spine:** change, swarmintelligence. **Halls:** Flow_Field (carrier); Change_Intro (field trip); SwarmIntelligence_FlowFields (encounter)
- **Code, new:** particles, lifetime. **Returns:** noise, packed_arrays, delta, vectors, lifecycle, arrays, meshes
- **Body:** A particle system of your own: positions in a PackedVector3Array advected through a noise angle field in _process, each particle reborn at the edge when its lifetime runs out, trails drawn from a bounded buffer; then the same field driving a GPUParticles3D emitter, to compare.
- **Argument:** field frequency: 0.01 / 0.03 / 0.1 / 0.3. *Predict:* 0.1 and 0.3 will look most alike: above some frequency the trails turn into hair or fur, a texture rather than currents. 0.01 reads as one wind. *Claim:* Below a frequency a flow field is a place you could be carried through; above it, it is a texture on the air.
- **Debt:** The field is noise again (the blob returns as wind), and particles exist only as long as a number you chose (lifetime) and the frame budget allow. A trail is an integral you draw (Change_Intro's rate and accumulation).
- **Place:** Stand in the flow: particles stream around you; on the XR route the field itself carries the player slowly, with no rotation, and you learn why VR comfort is not polish.
- **Godot:** GPUParticles3D and ParticleProcessMaterial; lifetime, one_shot, emitting; PackedVector3Array updated in place; Planted bug: the array copied by value inside a loop, so no particle moves; read what PackedVector3Array does on assignment
- **Lineage:** Processing: Handbook 'Motion 1-2'. NoC: ch4 Particle Systems; flow fields in ch5. Application: WP1 particle systems; WP2 flow fields. Klee: III.27 water and air as transitional regions (per c7). Reference: Code as Creative Medium 'Simulation' exercises (flow field) [V repo via c7]; Tyler Hobbs's flow-field essays [mem]
- **Departure:** change (spine 6) opens the force part after the early visits to chance, waves, shaders and noise (spines 9-12): the field is a noise field, so the ladder puts it after Noise 1. From here Part 4 walks spines 6-8 in order, with named returns.
- **Project step:** Put your body in a weather: a field that moves particles, or copies of your body, around it.

#### 20. The walker opened: velocity, scale, and a skin you can swap (`d3_20`, Forces 1 / Transformation 2; tracks: long)

- **Spine:** forces, transformation. **Halls:** VFM_03_Motion (carrier); Trans_Scale (carrier); Vectors_Act1_WhatAVectorIs (field trip)
- **Code, new:** player, input, composition. **Returns:** vectors, transforms, delta, collision, xr, classes
- **Body:** The supplied first-person walker that has carried you since chapter 1, opened line by line: a CharacterBody3D whose velocity is a direction times a speed in metres per second, read from the input map, moved by move_and_slide(). The controller and its skin are separate children, so the skin can be the capsule, a member of your family or the XR rig. Then scale the room by 4, or the body by a quarter, and test which doors the body fits through.
- **Argument:** room scale with the body fixed (still: the body in front of the same door): 0.25 / 0.5 / 1 / 2 / 4. *Predict:* 0.25 and 0.5 will look most alike: the body cannot pass either door and both read as a dollhouse. From 1 upward the door reads as a door. *Claim:* A room's size can only be read against a body: scale is a relation, not a property.
- **Debt:** Critique the starter (Montfort, 'Critique My Starter Programs'): the capsule is every tutorial's default human, as the Utah teapot is the default object (Gaboury ch3). A CharacterBody3D is a collider with a velocity, not a body with weight, joints or feeling. Headset height and comfort defaults (snap turn, vignette) assume a body too (Bagnall [mem]).
- **Place:** Become it: walk your hall at a quarter scale and at four times; then swap the skin for the XR body in the headset. The controller does not change.
- **Godot:** CharacterBody3D, velocity, move_and_slide(), is_on_floor(); Input Map actions; Input.get_vector(); skin against controller as composition (a scene of scenes); XROrigin3D world scale against node scale; Planted bug: velocity multiplied by delta before move_and_slide (which already applies it); the walker crawls at 90 Hz; read the docs line
- **Lineage:** Processing: Learning Processing ch3 (interaction). NoC: ch1 Vectors (velocity). Application: VR presence (the application's premise); pre-WP. Klee: II.18 'the tightrope walker is the scale' (per c3); III.28 the climber of stairs (per c4). Reference: GDQuest Learn 3D Gamedev, skin against controller [V research_engine]; Godot 'Your first 3D game' player [V research_engine]; Montfort, Exploratory Programming ch7 [V research_ccs]
- **Departure:** A declared return to transformation (Trans_Scale, spine 2) inside the force block. The supplied walker has carried the student since chapter 1, and it is opened where velocity is taught (NoC 1), because a walker is a velocity; scale is argued here because a room's size can only be read against a body the student now owns. The rest of the chapter is spine 7 in order.
- **Project step:** Replace the supplied walker in your hall with your own controller and one skin, and put in one door only a smaller body can pass.

#### 21. Gravity by hand: your own integrator (`d3_21`, Forces 2 / Waves 2; tracks: long)

- **Spine:** forces. **Halls:** VFM_05_Launch (carrier); Vectors_Act4b_Oscillation (carrier); VFM_07_Gravity (field trip); Vectors_Act4a_KineticForces (encounter)
- **Code, new:** forces, integration, physics_bodies. **Returns:** vectors, delta, arrays, meshes, classes, trig
- **Body:** A Mover class with position, velocity and acceleration: apply_force() accumulates, and a fixed-step integrator moves it. A thrown body's arc of 64 predicted samples; then chapter 13's pendulum rebuilt as a spring integrated by force (Waves 2); then the same mover as a RigidBody3D, to compare.
- **Argument:** integration step on a damped spring (trail still): 1/15 s / 1/30 s / 1/60 s / 1/120 s / 1/240 s. *Predict:* 1/120 and 1/240 will look most alike; at 1/15 explicit Euler gains energy and the trail spirals outward instead of settling. *Claim:* An integrator is a physics of its own: a coarse step invents energy, and the trail is the method's signature.
- **Debt:** The smooth curve you see is a polygon of decisions. Engine physics is an approximation you did not write: sleeping, tunnelling at speed, and settling that depends on the tick rate (an Ada die read 15/16 at 90 Hz and 2/16 at 60 Hz [V MEMORY]).
- **Place:** Throw it yourself (XR release velocity or a desktop launch) and stand where your prediction says it lands.
- **Godot:** velocity += acceleration * dt; position += velocity * dt; a fixed-step accumulator in _physics_process; RigidBody3D.apply_central_force(), mass, linear_damp; an ImmediateMesh polyline for the predicted arc; Planted bug: acceleration never reset after the step, so forces pile up and the body leaves the hall; print acceleration each tick
- **Lineage:** Processing: Handbook 'Simulate 2: Physics' [via c3]. NoC: ch1 Vectors (velocity); ch2 Forces; ch3 Oscillation (the spring). Application: WP4 chaos, previewed (sensitivity to the step). Klee: III.26-30 the bullet, the stone and the meteor (per c4); IV.33 the pendulum after gravity. Reference: NoC ch2 'Forces' [V]; Form+Code 'Simulate: Particles' [V code example via c3]; Lague's naive-attempt-first form [V research_engine]
- **Departure:** Forces (spine 7) follow change (6) as in the spine; the metric flags the chapter only because of the early visits in Parts 2 and 3. Waves 2 is a named return: chapter 13's pendulum was a function of time, and here it is a spring integrated by force, which is Klee's order (pendulum after gravity) and NoC's (oscillation after forces).
- **Project step:** Something in your hall is thrown or falls along a curve you computed.

#### 22. Personal prosthetic: the arrow extends your reach (`d3_22`, Forces 3 / Color 2; tracks: long)

- **Spine:** forces, color. **Halls:** Vectors_Act5_ForceAsPlace (carrier); Color_Paint (field trip); Color_Flashlight (encounter)
- **Code, new:** raycasts, areas, signals. **Returns:** xr, physics_bodies, forces, export, materials
- **Body:** A tool worn on the hand: a held node casts a RayCast3D (Klee's arrow); where it hits, it paints, pulls, drops an Area3D gravity zone or turns a collider off, and it emits its own signal hit(body) that another node listens to.
- **Argument:** what the ray does at its point: marks (paint) / pulls (force) / lifts (gravity zone) / removes (collider off). *Predict:* After thirty seconds of use, 'pulls' and 'lifts' will look most alike (bodies gathered near where the ray landed); 'marks' leaves every body in place and changes only surfaces. *Claim:* A prosthetic is defined by what its point does; the same ray is a brush, a hand or a law depending on one function.
- **Debt:** Whose hand is extended, and which bodies can the ray reach? Collision layers decide what exists for it. The controller assumes two hands and a trigger finger (Bagnall [mem]). Klee calls the arrow born of the wish to extend one's reach: reach is power.
- **Place:** Become it: wear it on the XR hand, or on the desktop crosshair, and change the hall from a distance.
- **Godot:** RayCast3D and intersect_ray(); Area3D with a gravity override; body_entered; signal hit(body); emit(); connect(); collision layers and masks; Planted bug: a one-argument signal connected to a zero-argument method; the button is dead and the error names the arity (Ada's own lesson [V MEMORY])
- **Lineage:** Processing: none (mouse picking is 2D). NoC: ch2 forces applied by the user. Application: WP4 algorithmic life acting on the player (early). Klee: IV.37-38 the arrow: shaft, point, rudder (per c7). Reference: Code as Creative Medium 'Personal Prosthetic' [V ToC via c7]; Rebecca Horn, Finger Gloves (1972) [mem]; Stelarc, Third Hand [mem]
- **Departure:** A field trip back to colour (Color_Paint, spine 4) from the force block: the painting ray needs raycasts, which the student meets only now. The forces hall that carries the chapter is in spine order.
- **Project step:** Give the visitor a prosthetic for your body: a way to reach, paint, push or unmake it.

#### 23. Legs: the passive part drives (Klee in drag II) (`d3_23`, Forces 4 / Transformation 3; tracks: long)

- **Spine:** forces, transformation. **Halls:** VFM_09_Legs (carrier); Trans_Pit (field trip)
- **Code, new:** state_machines. **Returns:** raycasts, basis, transforms, composition, signals, physics_bodies, loops
- **Body:** VFM_09_Legs drops a plate on two to four posts with its centre of mass moved and asks: tip or hold? Your version replaces the posts with procedural legs: each foot finds the ground with a raycast, each leg is solved from the foot back to the hip by a supplied two-bone inverse kinematics helper (law of cosines, opened as a stretch), and each leg runs a small state machine: STANCE, where the planted foot drives the chain, and SWING, where the hip leads.
- **Argument:** number of legs under the same off-centre plate: 2 / 3 / 4 / 6. *Predict:* 4 and 6 will look most alike (both hold: the convex hull of their feet contains the centre of mass); 2 tips; 3 depends on where the centre sits. *Claim:* Whether a body stands is decided by the convex hull of its feet, so the number of legs is an argument, not a style.
- **Debt:** Inverse kinematics lets the passive end, Klee's bone, drive the chain: chapter 12's command hierarchy is a convention you can invert, and 'in drag' becomes a code operation. The enum lists the states a leg may be in; what a body does between STANCE and SWING has no name in the code. IK approximates too (joint limits), and a foot finds only what its ray hits.
- **Place:** Walk your legged body across Trans_Pit's moving blocks; its feet re-plant as the ground moves under them.
- **Godot:** enum State {STANCE, SWING}; match; RayCast3D per foot; a two-bone IK helper (supplied, then opened); FABRIK named as the general method; Geometry2D.convex_hull() for the support polygon; Planted bug: the foot target set in the leg's local space, so every foot plants at the hip; compare global and local, as in chapter 4
- **Lineage:** Processing: none. NoC: ch5 Autonomous Agents (steering, preview). Application: WP2 organic bodies (preview); WP4 algorithmic life. Klee: II.25 stumbling; I.9 the bone as the passive organ, reversed (per c4). Reference: Klee in drag: active and passive re-assigned (c4's structural move); Critical Engineering Manifesto 6 [V research_ccs via c4]; LEARN 'what not to copy' 8 (Bauhaus universalism)
- **Departure:** Trans_Pit (transformation, spine 2) is revisited as the ground the legs cross; otherwise the chapter is spine 7 in order. It sits straight after raycasts because a foot finds the ground by a ray, and it answers chapter 12 (in drag I). The eleven chapters between them are what the student needs first: rays, a state, and a body they own.
- **Project step:** A body in your hall that finds its own footing.

#### 24. To stand despite all possibilities to fall: a round (midterm) (`d3_24`, Formfinding 1 / Randomness 2; tracks: long)

- **Spine:** formfinding, randomness. **Halls:** Random_Game (carrier); FormFinding_Relaxation (carrier); FormFinding_Catenary (field trip); FormFinding_Forge (field trip); Random_Cubes (encounter)
- **Code, new:** ui, save_load, timers. **Returns:** state_machines, player, input, signals, physics_bodies, random, seeds, audio, integration
- **Body:** A small complete game on Klee's axiom: stepping stones that sink after seeded random waits, a hanging bridge whose form is found by relaxation (a chain of points pulled toward rest length every tick) as the only safe path, a player who must stay upright, menu / play / fall / score as a state machine, a HUD, a sound per state and the best time saved to user://.
- **Argument:** warning time before a stone sinks: 0 s / 0.5 s / 1 s / 2 s. *Predict:* In a mid-round still, 1 s and 2 s will look most alike (many stones wear warning rings and the player stands on a safe one); at 0 s no ring is ever visible. *Claim:* Fairness in a chance game is visible: a warning is a ring in space before it is a rule in time.
- **Debt:** Seeded chance can be replayed and so learned: is the game random or a memory test? The score reduces a body's play to one number (Queer Game Studies on failure [V research_queer]). The bridge is a catenary by iteration: the number of relaxation passes is its stiffness, a material made of loops.
- **Place:** Play it on the desktop, then in the headset: stand despite all possibilities to fall.
- **Godot:** Control, CanvasLayer HUD, Label, Button; a world-space panel for the headset; FileAccess or ConfigFile in user://; Timer nodes; the timeout signal; restart by resetting state, not reloading the scene; Planted bug: the save path written to res://, which is read-only in an export; the build fails silently where the editor worked
- **Lineage:** Processing: Learning Processing ch10 Algorithms (a game taken apart). NoC: ch0 Randomness (return); the NoC course's midterm project [V research_creative]. Application: WP1 randomness; WP3 'How do we navigate an auto-generated world?' (a first answer). Klee: Introduction axiom 'TO STAND DESPITE ALL POSSIBILITIES TO FALL!' (per c4); III the gravitational curve. Reference: Code as Creative Medium 'One-Button Game' [V ToC via c7]; Godot 'Your first 3D game' parts 7-8 (score, replay) [V research_engine]
- **Departure:** Formfinding and Randomness 2 (spines 8 and 10) close the force part as its synthesis. Formfinding follows forces as in the spine; chance returns at its own spine place as the engine of a round. Waves (spine 9) were met early at chapter 13, so no chapter sits between them.
- **Project step:** MIDTERM (SYNTHESIS IV): turn your hall into a round with a start, one way to fail, a score, a sound and a restart.

### Fields that decide what the picture hides (Visualize 2)

*A ground others can repair, a skin a threshold extracts, a skin a shader fakes, and a floor a classifier paints: four fields, four things each picture hides.*

#### 25. Noise 2: the blob aesthetic, a recipe others can repair (`d3_25`, Noise 2 (Parameterize 2); tracks: long)

- **Spine:** noise. **Halls:** Noise_Perlin_Simplex (carrier); Noise_Inside_Noise (field trip); Noise_6_Wall (field trip); Noise_One (encounter)
- **Code, new:** tool_scripts, setters, resources. **Returns:** noise, packed_arrays, surface_tool, collision, export, classes, player
- **Body:** The chapter 18 ground as a tool: exported setters rebuild the terrain live, @tool shows it in the editor, and the noise settings are saved as a Resource (.tres) that a classmate can load into their own hall, open and change. The supplied sweep_sheet from chapter 14 is opened here: it was a @tool script.
- **Argument:** noise type at the same frequency: value / Perlin / simplex / cellular. *Predict:* Perlin and simplex will look most alike at walking scale (they differ in grid artefacts, not in landscape); cellular is another body. *Claim:* Noise types are one family of blob, except cellular: what differs is the artefact, not the ground.
- **Debt:** The blob aesthetic, named: noise produced a look that now reads as 'nature', and choosing a field is choosing what escapes (the overflow rates). A recipe as a file is Illich's repairability in practice, and it has its own debt: a shared Resource changes every body that uses it at once.
- **Place:** Walk the terrain in a classmate's hall with your recipe loaded, and find the slope where your walker (chapter 20) can no longer climb; in Noise_Inside_Noise, walk a field warped by another field.
- **Godot:** @tool and Engine.is_editor_hint(); a setter: set(value): x = value; _rebuild(); a custom Resource; ResourceSaver.save(); load(); duplicate() against a shared resource; Planted bug: one Resource shared by five terrains, so tuning one retunes all; the still of five identical grounds is the message
- **Lineage:** Processing: Learning Processing ch13 noise(). NoC: ch0 Perlin noise (return). Application: WP1 Perlin noise and Voronoi diagrams; the application's commons (open, repair, change). Klee: beyond the sketchbook: I.13 the eye 'grazes' the surface (per c4). Reference: Queer 3D 2024 (blob aesthetic, overflow rates) [V QUEER3D.md]; Catlike Coding 'Pseudorandom Noise' [V research_engine]; Illich, Tools for Conviviality [mem]
- **Departure:** Noise 2, a declared return to spine 11 after the force part: the ground met at chapter 18 becomes editable in the editor and shareable as a file. The Parameterize strand continues here (setters, @tool, the recipe), and the sweep sheet supplied at chapter 14 is opened.
- **Project step:** The ground of your hall becomes editable in the editor, and its recipe is a file another student can repair.

#### 26. Implicit body: a field decides where the skin is (`d3_26`, Isosurfaces 1 / Boolean 1; tracks: long)

- **Spine:** isosurfaces, boolean_surfaces. **Halls:** ISO_Introduction (carrier); ISO_LookupTable (carrier); ISO_Metaballs (carrier); Boolean_Verbs (field trip); ISO_TorusGyroid (field trip)
- **Code, new:** threads. **Returns:** noise, packed_arrays, surface_tool, normals, collision, raycasts, tool_scripts
- **Body:** A density field of two balls (metaballs) sampled into a grid and extracted by a supplied marching-cubes function into a mesh with a collider, run on a worker thread so the headset does not stall. Beside it the same body built with a CSG union, and your chapter 25 noise field thresholded into a cave.
- **Argument:** fusion: the distance between two sources: distinct / necked / lobed / single. *Predict:* 'lobed' and 'single' will look most alike from 3 m; 'necked' is the value where two bodies become one. *Claim:* A neck is where two bodies become one: the threshold, not the sources, decides how many bodies there are.
- **Debt:** The lookup table is a code-critique station (after Marino's chapter on Kittler's raytracer): read and annotate thirty of its lines, because someone decided the ambiguous cases. The smooth-minimum blend radius is where the blob comes from. How many bodies there are is a threshold, a number someone chose.
- **Place:** Walk through an implicit tunnel (ISO_TorusGyroid). A shape cast answers whether a body the size of your walker fits the opening before you try.
- **Godot:** density(p) sampled into a PackedFloat32Array; the supplied marching_cubes(field, threshold) -> ArrayMesh (the table is read, not written); WorkerThreadPool.add_task() and wait_for_task_completion(); CSGCombiner3D union, intersection, subtraction; use_collision; Planted bug: add_child() called from the worker thread; read the error, then use call_deferred
- **Lineage:** Processing: none. NoC: none. Application: WP2 'queer meshes' (blob, fusion); the application's topology question. Klee: I.11 building up against carving away (union against difference). Reference: Marino, Critical Code Studies ch6 (Kittler's code) [V contents]; Lague, Coding Adventure: Marching Cubes [V research_engine]; Quilez, smooth minimum [mem]
- **Departure:** isosurfaces and boolean surfaces (spines 18-19) are visited early, straight after Noise 2 and before cellular automata (13). An implicit body is the noise field the student just made, thresholded, so the student needs it now, not seven chapters later. Soft, collective and learning bodies (17, 20, 21) keep their spine order.
- **Project step:** Carve one space of your hall as an implicit body and prove a visitor fits through it.

#### 27. Shader 2: a skin that lies about its shape (`d3_27`, Shaders 2; tracks: long)

- **Spine:** shaders. **Halls:** Shader_11_QueerRubber (carrier); Shader_09_FBM (carrier); Shader_12_PinkExtravaganza (encounter)
- **Code, new:** uniforms. **Returns:** shaders, noise, normals, uv, export, setters
- **Body:** A subdivided floor whose vertex shader displaces it with fBm, and a rubber body with a fresnel rim from dot(NORMAL, VIEW); the family's axis is now a uniform, set from GDScript by the same exported setter as chapter 25. The collider stays the flat floor.
- **Argument:** displacement amplitude (uniform) on a floor whose collider is fixed: 0 m / 0.05 m / 0.2 m / 0.6 m. *Predict:* 0 and 0.05 m will look most alike (a textured floor); at 0.6 m the picture shows hills your feet will walk through. *Claim:* What you see is not what holds you: past a step's height, the body you see and the body you meet part ways.
- **Debt:** Vertex displacement moves the picture, not the collider (Shader_09_FBM's glass slab: visible deformation, unchanged collision). The implicit skin of chapter 26 holds you; this one only shows. The queer rubber is a surface whose promise and whose contact disagree, which the course names as uncanny rather than as a bug.
- **Place:** Walk on it: step onto the displaced rubber floor and feel it is flat; walk around the rubber body and its rim follows your eye.
- **Godot:** vertex(): VERTEX += NORMAL * h; uniform float amplitude : hint_range(0.0, 1.0); set_shader_parameter() from a GDScript setter; fresnel from dot(NORMAL, VIEW); Planted bug: the uniform name misspelled in set_shader_parameter; nothing happens and nothing is printed; read the shader's uniform list
- **Lineage:** Processing: Handbook 2nd ed. PShader [mem]. NoC: none. Application: WP3 shading algorithms; WP2 'queer meshes and textures'. Klee: IV.43 the spectral colour circle (per c4). Reference: The Book of Shaders ch13 (fBm) [V research_engine]; Gaboury, Image Objects ch2 [V research_engine]; Ada's Shader_11_QueerRubber and the gloss shader [V MEMORY]
- **Departure:** Shaders 2, a declared return to spine 12 after the implicit body (18-19): the skin chapter 26 extracted is now painted and displaced by the GPU, so the student compares a skin that holds (marching cubes) with one that only shows (vertex displacement).
- **Project step:** One body in your hall has a skin whose appearance lies about its shape; mark the lie or hide it, and say why.

#### 28. Data self-portrait: whose data draws the field (`d3_28`, Machine learning 2 / Post-crisis 2; tracks: long)

- **Spine:** machinelearning, postfoundationscrisis. **Halls:** ML_Classification (carrier); CriticalAlgorithms_Algorithmic_Bias_Visualization (carrier); ML_Perception (field trip)
- **Code, new:** sorting, json. **Returns:** arrays, dictionaries, materials, loops, uv, save_load
- **Body:** A self-portrait as a classifier: your chapter 6 walk traces, and classmates' with consent, become labelled points; a k-nearest-neighbour classifier (neighbours sorted by distance; the hall itself steps k-means, and you write kNN because it sorts) paints its decision field onto the floor you stand on; the labelled samples are saved as JSON.
- **Argument:** who labelled the training data: you / the class / a default dataset / random labels. *Predict:* 'the class' and 'a default dataset' will look most alike (smooth, confident regions); random labels give a speckled field; your own labels draw the most particular map. *Claim:* The decision field is a map of who labelled the data; the machine's confidence is borrowed from its labellers.
- **Debt:** Models are always biased (Queer 3D). k is a politics of neighbourhood: as k grows the lone sample's island is swallowed, and smoothing a judgment erases its minorities. The Feminist Data Set labels slowly and in public. This returns to chapter 9: the drafter that writes your code was also trained on someone's labels.
- **Place:** Stand on your own portrait: the field under your feet says which class your position belongs to; walk across the boundary the data drew.
- **Godot:** Array.sort_custom() by distance; an Image written per pixel; ImageTexture on a floor quad; JSON.stringify() and JSON.parse_string(); a Button (or a hand gesture) to add a sample; Planted bug: sort_custom's comparator returns an int instead of a bool; read the error before trusting the floor
- **Lineage:** Processing: none. NoC: ch10 Neural Networks (the perceptron, named). Application: WP3 neural networks; WP4 AI; Turing's B-type machine. Klee: none. Reference: Code as Creative Medium 'Data Self-Portrait' [V ToC via c7]; Aesthetic Programming ch10 'Machine unlearning' [V research_ccs]; Caroline Sinders, Feminist Data Set [V research_queer]
- **Departure:** Machine learning 2, a declared early visit (spine 21 at chapter 28, before the rule sequences 13-16). A classifier's decision field is the fourth picture of a field in this part, after the noise field, the implicit field and the shader, and Queer 3D puts 'models are always biased' in its foundation. Machine learning comes back as selection at chapter 33.
- **Project step:** SYNTHESIS V: classify something in your hall (routes, kinds of body) and show what the smoothing erased.

### Rules that grow: bodies and worlds that make themselves (Simulate 2)

*Neighbour rules, Turing's pattern on two buffers, recursion you stop, grammars that walk, bodies bred from files, and a generated world navigated as a graph.*

#### 29. Life: a rule for neighbours (`d3_29`, Cellular automata 1; tracks: long)

- **Spine:** cellularautomata. **Halls:** CA_Introduction (carrier); CA_ElementaryRules (carrier); CA_GameOfLife (field trip); CA_EdgeOfChaos (encounter)
- **Code, new:** buffers. **Returns:** arrays, booleans, nested_loops, multimesh, collision, packed_arrays
- **Body:** A tower grown from a one-dimensional automaton: each generation a row of boxes computed from the row below by a rule number read as bits, with two buffers (current, next) swapped each step; stacked upward, the history is a body you can climb.
- **Argument:** rule number: 30 / 90 / 110 / 184. *Predict:* 30 and 110 will look most alike from a distance (both irregular); 90 is a clean Sierpinski triangle and 184 a traffic of diagonals. *Claim:* One byte of rule decides a whole body; neighbours make a form that no single cell contains.
- **Debt:** The edge: the row wraps with (i + n) % n, a torus nobody sees. Without a second buffer, cells read neighbours already updated, an order-of-evaluation bug that looks like a new rule. Wolfram's classes are a taxonomy, not a law, and Life is not alive.
- **Place:** Climb it: live cells are steps (CA_GameOfLife's floor), and the rule's gaps are where you fall.
- **Godot:** PackedByteArray double buffer and swap; bit operations (rule >> k) & 1; MultiMesh history; one merged collider for the live cells; Planted bug: one buffer read and written in the same pass; the pattern leans to one side, and the picture is the message
- **Lineage:** Processing: Handbook 'Simulate 1: Biology' [mem]. NoC: ch7 Cellular Automata. Application: WP2 cellular automata; WP4 chaos. Klee: I.5 divisional articulation, rhythm by rule (per c7). Reference: Wolfram's elementary automata [mem]; Code as Creative Medium 'Simulation' exercises (Life) [V research_ccs via c7]
- **Departure:** Cellular automata (spine 13) open the rules part in spine order; the metric flags the chapter only because implicit bodies and machine learning (spines 18-21) were visited earlier, in Part 5.
- **Project step:** Grow one part of your body by a neighbour rule, one generation per step.

#### 30. Turing's skin: two buffers on the GPU (`d3_30`, Shaders 3 / Soft bodies 1; tracks: long)

- **Spine:** shaders, softbodies. **Halls:** Shader_10_ReactionDiffusion (carrier); ProceduralGeneration_Reaction_Diffusion_Systems (carrier); Topology_Entropy_Morphogenesis (encounter)
- **Code, new:** await. **Returns:** buffers, shaders, uniforms, packed_arrays, materials
- **Body:** Turing's 1952 morphogenesis: Gray-Scott reaction-diffusion on two buffers, first on the CPU into an Image, then ported to a ping-pong shader in a SubViewport; the pattern is read back after an awaited frame and grows across a skin you can walk round.
- **Argument:** regime (feed and kill presets): spots / stripes / maze / mitosis / coral. *Predict:* 'maze' and 'stripes' will look most alike (both elongated bands, the maze only more branched); spots and mitosis are the next closest pair. *Claim:* Two numbers decide whether a skin grows spots or stripes: the body's pattern is a location in a parameter space.
- **Debt:** Turing is the application's throughline (entropy, AI, paradox, morphology, queer joy and death), and Queer 3D asks whether twisted rooms can challenge normative structures. The port costs: the same body in two representations runs at very different speeds, so speed decides which bodies are affordable. A GPU result arrives a frame late: the picture you read is already the past.
- **Place:** The pattern grows on a skin you walk round, and spreads across the floor of the hall while you stand in it.
- **Godot:** Image.set_pixel() into an ImageTexture (CPU version); SubViewport ping-pong; ViewportTexture; await RenderingServer.frame_post_draw before get_image(); Planted bug: reading and writing the same texture in one pass; the pattern smears, and the picture is the message
- **Lineage:** Processing: Processing's pixel convolution examples [mem]. NoC: ch7 continuous cellular automata (nearest). Application: WP3 reaction-diffusion; Turing's morphogenesis (application throughline). Klee: none. Reference: Turing, 'The Chemical Basis of Morphogenesis' (1952) [V APPLICATION.md]; 10 PRINT 'REM Ports' [V research_ccs via c2]; Aesthetic Programming's pixel chapter [V via c2]
- **Departure:** Shaders 3 and a soft-bodies hall (spines 12 and 17) come right after Life: reaction-diffusion is Life's double buffer with continuous values, so it follows the buffer rather than the shader sequence, and the student ports the CPU version to the GPU met at chapters 17 and 27.
- **Project step:** A skin in your hall grows its own pattern; write both timings (CPU and GPU) in the README.

#### 31. The tree and its mad branch: recursion that must be stopped (`d3_31`, Fractals 1; tracks: long)

- **Spine:** fractals. **Halls:** Fractal_RecursiveTrees (carrier); Fractal_Recursion (field trip); Fractal_MengerSponge (encounter); Fractal_GoldenSpiral (encounter)
- **Code, new:** recursion, stacks. **Returns:** functions, parameters, return, basis, multimesh, seeds, queues
- **Body:** A tree after Munari's rule: branch(pos, basis, length, depth) calls itself twice with a thinner, shorter child until depth reaches 0; then the same tree grown with an explicit stack (depth first) and a queue (breadth first), one generation per step, with one seeded 'mad branch' that breaks the rule.
- **Argument:** recursion depth: 2 / 4 / 6 / 8. *Predict:* 6 and 8 will look most alike: each generation halves the branch, so depth 8's twigs are finer than the silhouette can show, at four times the nodes of depth 6. *Claim:* An apparent infinity is a finite budget: past the depth the eye can resolve, recursion only spends.
- **Debt:** 'Recursion must always be controlled' (Queer 3D): with no base case there is no tree, only a stack overflow. Munari's mad branches turn up in nearly every family: the exception as the queer reading of the rule. The golden spiral hall's Fibonacci is a proportion, not nature's law.
- **Place:** Walk under the canopy and look up; in the headset stand inside the Menger sponge's hollow at depth 3.
- **Godot:** a recursive function with a base case; Array as a stack: push_back / pop_back; Array as a queue (chapter 13 returns); Planted bug: the base case checks depth == 0 while depth decreases by 2; read the stack overflow and the call stack in the Debugger
- **Lineage:** Processing: Handbook 'Shape 3: Parameters, Recursion'. NoC: ch8 Fractals. Application: WP2 fractal subdivision; WP1 Fibonacci. Klee: I.7 proportion; I.12 additive building (per c7). Reference: Munari, Drawing a Tree (1978) [V research_bauhaus]; Kawaguchi's growth-model bodies (Queer 3D lineage) [V QUEER3D.md]
- **Departure:** Fractals (spine 14) follow cellular automata as in the spine; flagged only because of earlier visits in Part 5.
- **Project step:** Let one part of your body contain smaller copies of itself, and choose where it stops.

#### 32. Grammar: the point walks again (`d3_32`, L-systems 1 / Tiling 2; tracks: long)

- **Spine:** lsystems. **Halls:** LSystems_Grammar_Lab (carrier); LSystems_Growth (carrier); LSystems_Architecture (field trip); Assemblage_Same_Desire (encounter)
- **Code, new:** strings. **Returns:** dictionaries, stacks, recursion, meshes, transforms, player
- **Body:** A string rewritten by rules (F -> F[+F]F[-F]F) held in a Dictionary and read by a turtle that walks and draws, pushing and popping its state at [ and ]; chapter 16's modules become symbols, and the turtle's path becomes walkable corridors.
- **Argument:** turn angle: 22.5 deg / 25.7 deg / 60 deg / 90 deg. *Predict:* 22.5 and 25.7 will look most alike (both plants); 90 turns the same grammar into architecture. *Claim:* One grammar is many bodies: the angle decides whether it reads as plant, snowflake or building.
- **Debt:** Strings explode, so a symbol budget is needed. Lindenmayer's botany naturalises the grammar, and a body produced by repeating rules is Butler's performativity in code [mem]. The turtle is Klee's walking point of chapter 6 made obedient.
- **Place:** Walk the L-system corridors (LSystems_Architecture) at a width you tested with your own walker.
- **Godot:** String building; for c in s; Dictionary of rules; push_back / pop_back of the turtle state; an ImmediateMesh turtle; Planted bug: the rewrite reads and writes the same string; generation two is garbage; read one generation at a time
- **Lineage:** Processing: Handbook 'Shape 3' [via c4]. NoC: ch8 L-systems. Application: WP2 L-systems. Klee: I.1 the walk, returned as grammar (per c4). Reference: Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants [mem]; Logo's turtle [mem]; Code as Creative Medium 'Modular Alphabet' as the numbered return [V ToC via c7]
- **Departure:** L-systems (spine 15) follow fractals as in the spine; flagged only because of earlier visits in Part 5. Named return: chapter 16's two modules become the grammar's symbols.
- **Project step:** A grammar of your own draws one element of your hall.

#### 33. Bred, not designed: genes as files (`d3_33`, Procedural generation 1 / Machine learning 3 (Parameterize 3); tracks: long)

- **Spine:** proceduralgeneration, machinelearning. **Halls:** PG_Genetic_Evolution (carrier); ML_Evolution (field trip); PG_Space_Colonization (encounter)
- **Code, new:** files. **Returns:** json, resources, sorting, random, seeds, classes, export, save_load
- **Body:** A population of your chapter 23 legged bodies whose genomes (leg count, lengths, centre of mass) are custom Resources, mutated and crossed; the fittest by a criterion you write are sorted, kept and written as JSON files in user://, so evolution continues after you quit.
- **Argument:** fitness criterion: distance walked / height reached / time upright / nearness to the player. *Predict:* After twenty generations 'distance walked' and 'time upright' will look most alike (both breed low, wide, many-legged bodies); 'height reached' breeds towers that fall. *Claim:* The evolved body is a portrait of its fitness function: change the criterion and a different creature wins.
- **Debt:** What counts as a desirable body? Fitness is a norm written as one number, and selection is a judgment you handed over. Evolved creatures are known to exploit physics bugs to win [mem]: evolution finds the engine's debts before you do.
- **Place:** The elite creature is released into your hall; with 'nearness to the player' it walks toward you on the headset route.
- **Godot:** FileAccess.open() in user://; DirAccess to list generations; Resource.duplicate(true) for a child genome; JSON round trip (chapter 28 returns); Planted bug: FileAccess opened for writing before reading, which empties the file; read what WRITE does (an Ada trap [V MEMORY])
- **Lineage:** Processing: Learning Processing ch18 Data (JSON). NoC: ch9 Evolutionary Computing. Application: WP3 evolutionary algorithms and procedural generation. Klee: I.10 propagation (per c7). Reference: Code as Creative Medium 'Virtual Creature' (second visit) [V ToC via c7]; Karl Sims, Evolved Virtual Creatures (1994) [mem]; Latham and Todd, Mutator [mem]
- **Departure:** Procedural generation (spine 16) follows L-systems as in the spine; Machine learning 3 (ML_Evolution) is visited as a field trip because selection is learning without a gradient. The genes-as-files step of the Parameterize strand lands here.
- **Project step:** Let the visitor's choice breed your body, and save and reload the population between sessions.

#### 34. How do we navigate an auto-generated world? (`d3_34`, Procedural generation 2 / Graph theory 1; tracks: long)

- **Spine:** proceduralgeneration, graphtheory. **Halls:** PG_Caves_Mazes (carrier); GT_Pathfinding (carrier); GT_Spanning_Trees (encounter)
- **Code, new:** graphs, search, navigation. **Returns:** queues, stacks, dictionaries, random, seeds, player
- **Body:** A generated maze read as a graph: cells are nodes, open walls are edges in a Dictionary of neighbour lists; breadth-first search finds the route and lays a line of lights; then a NavigationAgent3D with your walker's radius walks it, and a button closes an edge and forces a re-plan.
- **Argument:** probability that a wall between two cells is open: 0.3 / 0.45 / 0.5 / 0.6 / 0.8. *Predict:* 0.6 and 0.8 will look most alike (a route exists and the lights reach the exit); at 0.3 and 0.45 the lights stop short. The switch lies near 0.5, the bond percolation threshold of a square grid. *Claim:* Connectedness is not proportional to openness: near one probability a world snaps from islands to a continent.
- **Debt:** The navmesh is baked for one body radius: a wheelchair, a crawling body or a flying one gets another world. Which relation survives when the picture is rearranged? Homophily in network models (Chun, Discriminating Data) [mem].
- **Place:** Walk the maze by the lights; in the headset close an edge with your hand and watch the route re-plan around you.
- **Godot:** Dictionary adjacency lists; breadth-first search with a queue; AStar3D or AStarGrid2D; NavigationRegion3D baking; NavigationAgent3D radius; Planted bug: the visited set is never updated, so the search loops forever; stop it, then read the frame counter
- **Lineage:** Processing: none. NoC: ch5 path following [mem]. Application: WP3 graph theory and 'How do we navigate an auto-generated world?'. Klee: II.15 railroad tracks as the measure of a path (per c7). Reference: 10 PRINT ch65 'Maze Walker in BASIC' [V research_ccs]; Montfort's 'Navigable Generated Landscape' [V research_ccs]
- **Departure:** Graph theory (spine 22) is pulled forward into procedural generation (16), before soft, collective and learning bodies (17, 20, 21). The application's WP3 asks 'How do we navigate an auto-generated world?' of exactly this pair, and it is the rules part's synthesis.
- **Project step:** SYNTHESIS VI: make your hall navigable by a body other than yours; bake it for another radius and see what changes.

### Leaving the lab: failure before futures

*Soft and collective bodies measured against the headset, then the model's limits (one standpoint, a third truth value, your own prediction error as entropy) before your family stands in the shared museum under an edit rule.*

#### 35. Soft: polycount against deformation, measured (`d3_35`, Soft bodies 2 (Parameterize 4); tracks: long)

- **Spine:** softbodies. **Halls:** SoftBodies_Soft_Body_Deformation (carrier); SoftBodies_Cloth_Physics (carrier); SoftBodies_Playground_of_Joy (field trip); SoftBodies_Affect_Theory_Visualization (encounter)
- **Code, new:** profiling, testing. **Returns:** physics_bodies, export, setters, timers, signals, await
- **Body:** A SoftBody3D jelly made from a subdivided box, pinned at two points, with stiffness and pressure exported; a cloth whose pins are released by a Timer. A headless test awaits a settle, measures the dent, and fails if the frame time exceeds the headset's budget.
- **Argument:** subdivisions of the jelly (still taken while it is struck): 1 / 2 / 4 / 8 / 16. *Predict:* 8 and 16 will look most alike at rest and when struck; 1 and 2 dent as rigid facets, because only enough vertices can bend smoothly. *Claim:* A body can only deform as smoothly as its polycount allows: the application's topology question in one still.
- **Debt:** Polycount against smooth deformation, the application's own phrase. The solver's stiffness is not a material (rubber is a number). A settle test depends on the physics rate (Ada's die, again), and a test proves only what you thought to ask.
- **Place:** Touch it: press the jelly with your hand (XR), walk through hanging cloth, play in the Playground of Joy.
- **Godot:** SoftBody3D: simulation_precision, pressure_coefficient, set_point_pinned(); the Profiler and Monitors; frame time per subdivision; a headless test scene run from the command line; assert(); Planted bug: the test measures before the body settles (no await), so it passes on a body that is still falling; read the timestamps
- **Lineage:** Processing: none. NoC: ch6 soft bodies (toxiclibs), a course week. Application: WP2 soft body simulation (cloth, liquids, rubber); the application's polycount line. Klee: I.9 bone, tendon, muscle: the soft tissue (per c3). Reference: Bellmer and Bourgeois as lineage for deformable bodies (Queer 3D) [V QUEER3D.md]; Form+Code 'Parameterize' budget chapter (c3 ch20)
- **Departure:** Soft bodies (spine 17) come after graph theory (22), which was pulled forward at chapter 34; the return to spine order is declared here. The Parameterize strand closes: the family is measured against the headset's budget.
- **Project step:** Give your hall one body that deforms when touched, at the polycount your frame budget allows, with the test that proves it.

#### 36. Many bodies, local rules: a species (`d3_36`, Swarm 1; tracks: long)

- **Spine:** swarmintelligence. **Halls:** SwarmIntelligence_Boids_Algorithm (carrier); SwarmIntelligence_PhysarumColony (field trip); SwarmIntelligence_Agent_Based_Modeling_ABM (encounter)
- **Code, new:** inheritance, groups. **Returns:** classes, vectors, forces, multimesh, areas, profiling
- **Body:** A flock of your bodies: a base class Agent whose steer() is overridden by Boid, Follower and Shy subclasses; neighbours found through a group or an Area3D sensor; drawn as one MultiMesh once the node count gets expensive.
- **Argument:** separation weight: 0 / 0.5 / 1.5 / 4. *Predict:* 1.5 and 4 will look most alike in a still (an evenly spaced flock); 0 collapses into a clump and 0.5 into tight strings. *Claim:* A flock's shape is three weights; the collective decision is a spacing rule that nobody holds.
- **Debt:** Whose local information contributes to the apparent collective decision? Inheritance freezes a taxonomy of bodies (Agent above Boid). A group call reaches every hall (Ada's call_group lesson [V MEMORY]).
- **Place:** Stand in the flock: the boids avoid your head and hands (an Area3D on the XR rig or the walker).
- **Godot:** extends a custom class; super(); overriding; add_to_group() and get_nodes_in_group(); Area3D as a sensor; Planted bug: the subclass forgets super() in _ready, so it never joins the group; read the empty neighbour count
- **Lineage:** Processing: Learning Processing ch22 Advanced OOP (inheritance). NoC: ch5 Autonomous Agents (steering, flocking). Application: WP4 swarm intelligence. Klee: none. Reference: Craig Reynolds, Boids (1987) [mem]; Code as Creative Medium 'Bot' [V ToC via c7]; Lague, Boids [V research_engine]
- **Departure:** Swarm intelligence (spine 20) follows soft bodies (17) as in the spine; flagged only because graph theory (22) came earlier at chapter 34.
- **Project step:** Make your body a species: a base class and two behaviours that inherit from it.

#### 37. Impossible figure: what a model lets you claim (failure first) (`d3_37`, Foundations crisis 1; tracks: short, long)

- **Spine:** foundationscrisis. **Halls:** Escher_Impossible (carrier); NonEuclidean_Spaces (field trip); Brouwer_Intuitionism (field trip); Godel_Incompleteness (encounter)
- **Code, new:** camera. **Returns:** signals, vectors, shaders, uniforms, state_machines, search
- **Body:** An anamorphic body: three disconnected beams that close into a Penrose triangle from one standpoint only; a script reads the active Camera3D's position and forward vector and emits viewpoint_locked when the visitor stands there. Beside it, Brouwer's propositions get a third value, NOT_YET, as an enum instead of a bool.
- **Argument:** where the camera stands: the locked point / 0.5 m off / 2 m off / from above. *Predict:* 0.5 m off and 2 m off will look most alike (both plainly broken); only the locked point closes the figure; from above shows three separate beams. *Claim:* An impossible body is possible from exactly one place; like a proof, it holds only where it is made to be seen.
- **Debt:** The camera is the course's dark spot: every comparison still in this course was taken from one standpoint, and Ada's own DNA programme found five of seven 'inert' verdicts false from another angle [V CLAUDE.md]. Godel and the halting problem: 'not found within budget' is not 'unprovable'. A bool is a two-valued decision; a third value is a political choice.
- **Place:** Find the one spot: walk until the triangle closes; in the headset your head is the camera, so it closes for your eyes only. Step off and watch it break.
- **Godot:** get_viewport().get_camera_3d(); forward as -global_transform.basis.z; near, far and culling; enum Truth {TRUE, FALSE, NOT_YET}; a SubViewport camera for a second standpoint; Planted bug: the alignment test compares positions only, so the triangle 'closes' while you face away; add the dot product with the forward vector
- **Lineage:** Processing: Learning Processing ch14 camera() and perspective(). NoC: none. Application: WP4 non-euclidean spaces; the paradoxes of infinity and entropy that ended the 2022 prototype. Klee: II.15-20 perspective as illusion: a wall 'logically right but psychologically wrong' (per c7 and c4). Reference: Code Societies 'Critical Simulation' session as the model of critique beside code [V research_creative]; Reutersvard and Penrose (Queer 3D lineage) [V QUEER3D.md]; Queer Game Studies IV to V, failure before futures [V research_queer]
- **Project step:** FINAL BRIEF (two units before the end): place one work in your hall that only closes from one standpoint and mark the spot, or refuse to; write the final brief. Short track: this is the guest critique session of week 3, walked without compulsory code.

#### 38. Order toward entropy: your own prediction errors (`d3_38`, QFEP 1 / Randomness 3; tracks: long)

- **Spine:** qfeplaboratory, randomness. **Halls:** QFEP_F_Term (carrier); QFEP_E_Term (carrier); Random_Entropy (field trip); QFEP_Lambda_Spectrum (encounter)
- **Code, new:** none (returns only). **Returns:** files, json, sorting, dictionaries, random, seeds, packed_arrays
- **Body:** Two measures. Your own course log as data: each chapter's predicted closest pair against the measured one, read from the sketchbook's JSON files and drawn as a line (F = |prediction - observation|, as QFEP_F_Term does). And 200 seeded symbols as bodies, sorted in place, with Shannon entropy computed from their counts before and after.
- **Argument:** share of the sorted row shuffled back: 0% (sorted) / 10% / 50% / 100% (as drawn). *Predict:* 50% and 100% will look most alike: after half the swaps a sorted row already reads as disorder. The entropy of the counts is the same in all four stills. *Claim:* Sorting changes the arrangement and leaves the entropy of the counts untouched: the disorder you see is not the disorder the measure counts.
- **Debt:** A metric is a body too: F measures your prediction error, not the world, and QFEP is a framework, not a law (never call a spread Shannon entropy). Entropy as resistance to an imposed order, through Haraway and Ahmed (Queer 3D). This is the application's arc from order toward entropy, measured on the learner.
- **Place:** Walk the sorted row from order into the drawn end (QFEP_E_Term); then walk along the lambda track and let your position set the room's order.
- **Godot:** Array.sort() / sort_custom(); log() for entropy; Dictionary counts; reading your own sketchbook JSON (chapter 33's files); an ImmediateMesh line chart; Planted bug: log(0) for a symbol that never occurs; read the NaN on the label and skip empty counts
- **Lineage:** Processing: none. NoC: ch0 Randomness returns as distribution. Application: the application's arc toward entropy; Turing (Enigma). Klee: IV.43 the close: back to the dot of page one (per c5). Reference: QFEP (Ada's F to E) [V spine.json names]; c1's course log and c5's entropy chapter, bred together; Nees's Schotter as the order-to-entropy arc in one image [V research_bauhaus]
- **Departure:** Randomness 3, a declared return to spine 10 inside the QFEP chapter (spine 24): the chance met at chapter 11 comes back as a measure, closing the application's arc from order toward entropy.
- **Project step:** Every body in your hall gets its entropy on its label, and your own F curve hangs at the exit.

#### 39. Virtual public sculpture: who may change it (`d3_39`, Post-crisis 3; tracks: long)

- **Spine:** postfoundationscrisis. **Halls:** SpeculativeComputation_Collective_Knowledge (carrier); PostCrisis_Synthesis (field trip); CriticalAlgorithms_Applied_Ethics (encounter)
- **Code, new:** other:undo_redo. **Returns:** export_build, xr, save_load, json, resources, signals, import_assets, ai_assist
- **Body:** Your family placed as a public work in a shared hall: each visitor's change is kept as a provenance record with an undo history, the hall reads records written in other halls, and the build ships to the headset and to the class's shared museum.
- **Argument:** who may change the sculpture: only the author / anyone, last write wins / anyone, with kept history / no one (sealed). *Predict:* 'Only the author' and 'sealed' will look most alike to a visitor at any moment (unchanging); 'last write wins' drifts toward the latest visitor, and 'kept history' grows layers. *Claim:* A public body is its edit rule: who may revise it, and whether revisions are kept, shows in its shape over a week.
- **Debt:** Can the work keep its conditions, exclusions and possible revisions available to others? Illich's repairability and the application's commoning: a sculpture that can be opened and changed. Collective memory is also surveillance: the provenance log records its visitors. One of your works was drafted by a model (chapter 9): say which, in the label.
- **Place:** Show it: it stands in the shared museum hall, where classmates walk, carry, revise or become it, on desktop and headset.
- **Godot:** UndoRedo: create_action, add_do_method, add_undo_method, commit_action; Dictionary provenance records saved as JSON; export presets (desktop and Quest) and the final build checklist; Planted bug: the undo method captures the new value instead of the old one; undo does nothing; read the history panel
- **Lineage:** Processing: Handbook 'Synthesis 4'. NoC: the Ecosystem Project, a museum exhibit of creatures [V research_creative]. Application: the application's hacker ethics (Freire, Illich, commoning) and its year of publication. Klee: IV.43 the close, where the line returns to the dot of page one (per c7). Reference: Code as Creative Medium 'Virtual Public Sculpture' and 'Collective Memory' [V ToC via c7]; Code Societies 'Distributed Web of Care' [V research_creative]
- **Project step:** FINAL PROJECT (SYNTHESIS VII): place your family in the collective museum with its prediction, comparison still, claim, debt comment and edit rule.

## Are there similar courses? What this candidate learned from them

Short answer, from `LEARN.md` in this folder [V LEARN.md, sources as marked there]: **no course found covers all of Ada's scope** (critical theory, students writing code, 3D or VR bodies, art-school beginners). The closest each cover two or three parts: **Aesthetic Programming** (Soon and Cox) is closest in method, one critical theme per piece of syntax with code plus writing every week, but in 2D web; **Code Societies** (SFPC 2019) is closest in the shape of the short track, three weeks with critique sessions beside coding; **Claudia Hart's Experimental 3D** (SAIC) is closest to 'Klee in drag', a Bauhaus basic course redone in 3D for art students, but without code; **Gaboury's Image Objects** is the only critical reading of 3D graphics found, a book, not a course. Code as Creative Medium, Form+Code and The Nature of Code supply chapters and exercises with a mild or no critical stance. The canon's critique is social and linguistic; Ada's geometric and bodily debt has almost no precedent, and this course says so instead of borrowing authority for it.

- Processing Handbook, 1st ed. [V via LEARN]: two tables of contents and numbered returns. Every chapter here carries its spine number ('Noise 1' at 18, 'Noise 2' at 25), so a departure shows as a jump in the numbers and a return is named as one. This is the answer to 'related, not forced'.
- Code as Creative Medium [V ToC via c7]: the chapter unit is an assignment with a precedent, a short closed exercise and an open make; the short track runs one chapter a day; 'When Things Go Wrong' becomes the AI drafter chapter (d3_09); Personal Prosthetic, Data Self-Portrait and Virtual Public Sculpture keep their names.
- Form+Code [V themes via c3]: part names by what code does to form (Repeat, Transform, Parameterize, Visualize, Simulate) are kept as labels on the parts; Parameterize runs as a named strand across four chapters (d3_14, d3_25, d3_33, d3_35) rather than as one block, so it arrives when a family is needed and is finished when a budget is.
- Klee's Pedagogical Sketchbook [per c4, which checked the 1960 Praeger text; I did not reopen it]: the opening walk (point, line, record, plane) and the body book of Part I; active/medial/passive mapped onto male and female is the exact place for 'in drag', taught at d3_12 and inverted at d3_23. Klee's order is broken on purpose twice (colour early, the pendulum as a function before gravity) and each break is declared.
- 10 PRINT and Nake/Nees/Molnar [V research_ccs, research_bauhaus]: regularity before randomness; chance enters as the disturbance of a grid already built (d3_11 directly after d3_10).
- Aesthetic Programming [V research_ccs]: a critical theme tied to each code idea and read after making; pause weeks after each part; the final brief two units before the end; 'machine unlearning' turned on the course's own assistant (d3_09 and d3_28).
- Code Societies (SFPC 2019) [V research_creative]: the short track's third week uses guest critique sessions beside the student's own making, walked in halls without compulsory code (d3_37).
- Montfort, Exploratory Programming [V research_ccs]: modify before write, errors in week one, 'critique my starter programs' turned on the supplied walker when it is opened (d3_20).
- Albers [V research_bauhaus]: a constrained material and a stated perceptual target; the two-colour palette in d3_10 is supplied like Color-aid paper, and every chapter's prediction names the closest pair before the render.
- Chun, Programmed Visions [V contents via LEARN]: 'sourcery' sits in the debt of the first chapter that opens a supplied helper (d3_06) and again at the first generated code (d3_09).
- Gaboury, Image Objects [V research_engine]: one technical object read per chapter where it bites (culling at d3_07, the GPU at d3_17, the default object at d3_20).
- The Nature of Code [V]: the middle of the course (flow, forces, oscillation, agents, automata, fractals, evolution) keeps NoC's order, and the final is its Ecosystem Project turned into a museum hall.
- What no comparable course gives, stated plainly [V LEARN verdict]: none combines critique, writing code, 3D or VR bodies and art-school beginners. The canon's critique is social and linguistic; the geometric and bodily debts here (polycount against deformation, the blob aesthetic, recursion that must be stopped, the one standpoint that closes an impossible figure) have almost no precedent, so the course does not borrow authority for them.

## Sieve pass (Palle's three questions)

1. **Does it thicken the cognitive water?** Yes in two ways a student can hold: every chapter has two addresses (its place in the reading order and its number in a spine sequence), so the student can move through the course by body or by hall; and the numbered returns (Randomness 1-3, Noise 1-2, Shaders 1-3, Waves 1-2, Parameterize 1-4, Klee in drag I-II) make the course a braid with visible crossings rather than a line.
2. **What is foreclosed?** A student who wants to follow one strand to its end (all of randomness at once, all of shaders) must wait for its returns; the short track stops before force, so a three-week student never writes a physics body or opens the walker. Klee's own order is broken twice (colour early, the pendulum as a function before gravity), which weakens the claim to be 'Klee's sketchbook in drag' in its order; it keeps Klee in its opening walk and in its structural queer move.
3. **What lives in the dark spot?** The camera: every comparison still in the course is taken from one standpoint, and d3_37 turns that into the subject rather than leaving it hidden. The prediction can become a scoreboard; d3_38 measures the student's prediction error on purpose and names F as a model, not a grade. Encounter-only halls (the ML halls at d3_09) could read as token; they are there to name the model the student already uses, not to teach machine learning in week one.

## What this candidate still gets wrong

- **39 chapters is long for one year**; a 34-week year needs d3_13, d3_16, d3_17 and d3_30 taught as workshops inside their neighbours' weeks.
- **Part 2 carries three early visits in five chapters** (chance, waves, the family's return to primitives). Each is argued, but a student meets three 'departures' in a row.
- **Supplied parts that do not exist yet:** `sweep_sheet.gd`, `heightfield_skin.gd`, the two-bone IK helper, the in-hall normal display and the marching-cubes helper (Ada has marching-cubes code, but not in this shape) [unverified]. Only the six /course kits and the random-definition kit are known to run [V BRIEF].
- **The ML halls at d3_09 are encounters only**, and d3_28 visits machine learning early again; a strict reader may see two early ML visits where one would do.
- **d3_38 has no new code idea.** It is a reflect-and-measure chapter by design (returns only), which the ladder allows.
- **The bridge in the midterm (d3_24) uses relaxation**, which the formfinding halls teach with Verlet cloth (FormFinding_Relaxation [V digest]); a first-year student may need the hall's 40-line class supplied.

## Verification notes

- Self-computed with the workflow's formulas, reproduced on the parents [V]: chapters 39; order agreement 0.853; undeclared departures 0; spine coverage 25/25; halls named 119, all present in `spine.json` and each listed under a sequence the chapter names [V]; no chapter with more than 3 new code ideas [V]; no ladder violation (every return follows the chapter that introduces it) [V]; every vocabulary id is introduced somewhere (unused: none); game kit missing: none [V]; xr, import_assets and ai_assist present (d3_04, d3_08, d3_09) [V].
- Hall contents were checked against this folder's hall digest (`c5_halls_digest.txt`) for the halls whose content a chapter describes, and three roles were corrected after reading it (Noise_Perlin_Simplex carries the noise-type axis of Noise 2; FormFinding_Relaxation, not Catenary, carries the bridge; VFM_09_Legs is a plate on posts, which d3_23 extends to legs) [V].
- Ada facts quoted in debts come from the repo's CLAUDE.md and memory index: the science_screen silent typed set(), five of seven inert verdicts false from another angle, the die at 90 against 60 Hz, call_group crossing halls, open() for write truncating, a 1-arg signal on a 0-arg method [V CLAUDE.md / MEMORY.md]. The 74% @export and 45% sin/cos figures are from BRIEF.md [V BRIEF].
- Godot API names (AudioStreamGenerator, WorkerThreadPool, RenderingServer.frame_post_draw, UndoRedo, Geometry2D.convex_hull, SoftBody3D.set_point_pinned, --fixed-fps) are from memory of Godot 4 [mem]; none was run.
- Klee section numbers are c4's reading of the Praeger text (per c4); I did not reopen it. Precedent works marked [mem] were not checked.
- Nothing in the Ada repo was changed, staged or committed.
