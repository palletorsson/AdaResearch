> This file answers Palle's second question in the 2026-09-30 auto-research run: are there courses in critical code studies and nearby fields with a scope like Ada's, and what can the course learn from them? The course it fed is `COURSE.md` in this folder. The five research sweeps it names are copied into `research/` beside it.

# What comparable courses teach Ada: lessons learned (2026-10-01)

Written from five research sweeps in this folder: `research_ccs.md` (critical code and software studies), `research_creative.md` (creative-coding curricula), `research_engine.md` (engines, shaders, graphics), `research_bauhaus.md` (Bauhaus and art pedagogy), `research_queer.md` (queer, feminist and critical making). The details and sources are in those files.

**Marks.** They are carried over from the sweeps. [V] means a sweep checked a primary page this session: a publisher, an open-access text, a syllabus, a repository or a table of contents. [V-2] means only a search index or a secondary summary was seen. [mem] means recalled and not checked. I did not re-open the web sources. I did check the Ada anchors named below against the repo [V repo]: the study kits under `doc/book/studies/` (day-zero, point-zero, point-one, point-coordinates, point-lines, point-trace, random-definition), the hall folders cited, Molnar in `commons/maps/Array/final.md`, Albers in `commons/maps/Color_Paint/`, and `klee_walking_point` in `doc/book/BASE_LAYER.md`.

## The short answer to Palle's question

Yes, courses in critical code studies and nearby fields have a scope that can teach Ada something. **No course found covers all of Ada's scope**: critical theory, writing code, 3D space or VR, and art students who are beginners. Each of the closest ones covers two or three of those:

- **Aesthetic Programming** (Soon and Cox) is closest in *method*: each piece of syntax is tied to a critical theme, and every week ends in code plus writing.
- **Code Societies** (SFPC 2019) is closest in *shape to the short track*: three weeks, critique sessions set beside coding.
- **Claudia Hart's Experimental 3D** (SAIC) is closest to *"Klee in drag"*: a Bauhaus basic course redone in 3D for art students, but with no code.
- **Gaboury's Image Objects** is the only *critical reading of 3D graphics* found, and it is a book, not a course.

The critique in the canon is social and linguistic: data, platforms, language, surveillance. Ada's geometric and bodily critique (polycount against smooth deformation, noise's blob aesthetic, recursion that has to be stopped, impossible space) has almost no precedent. The course should say so plainly rather than borrow authority the canon does not give it.

---

## 1. The comparable courses

**Length** means the taught length where there is one, otherwise the size of the book. **Order** is the unit sequence compressed to one line.

### 1a. Critical code and software studies

| Course or text | Authors | Year | Scope | Length | Order in one line | Critical stance | Checked |
|---|---|---|---|---|---|---|---|
| Aesthetic Programming: A Handbook of Software Studies | Winnie Soon, Geoff Cox | book 2020; taught at Aarhus Digital Design from about 2016 (2018 run on GitHub, AUAP/AP2018) | code plus critique in p5.js, 2D web; humanities and design students who have never programmed | 10 chapters over 14 weeks, including pause weeks and project weeks | getting started, then variable geometry, loops, data capture, auto-generator (random, noise), objects, vocable code, que(e)ry data, flowcharts, machine unlearning (final project) | software studies: power relations built into code; queer lens explicit in chapters 5, 7 and 8 | V |
| Critical Code Studies | Mark C. Marino | 2020 | close reading of real code as a cultural text | monograph, 8 chapters | manifesto, then cases (Transborder Immigrant Tool, Climategate, FLOW-MATIC, Kittler's raytracer, Taroko Gorge), then futures | code is culture: who wrote it, in whose language, what its comments confess | V contents; the Climategate "fudge factor" detail is mem |
| CCSWG; "Decoding Digital Literature: CCS" (UCSB); CCS course (USC) | the CCS working group; Jeremy Douglass (UCSB); Mark Marino (USC) | CCSWG 2022, 2024, 2026; UCSB winter 2023; USC fall 2023 | annotate, remix and forensically read code; non-programmers | CCSWG about 4 weeks online; one quarter at UCSB, one semester at USC | themed weeks (2024: Queer(ing) Code, Teaching Code and Code Studies); UCSB: 10 PRINT and e-lit, midterm remix, final forensic analysis | critique of technoculture with code as the entry point | V |
| Exploratory Programming for the Arts and Humanities, 2nd ed. | Nick Montfort | 2021 (1st ed. 2016) | Python and Processing for arts and humanities; no prerequisites | 17 chapters, one semester | modify a program, then errors, fundamentals, critique of starter programs, text, image, statistics, visual design in Processing (ch. 14), sound | exploration; "computing is cultural"; light critique | V |
| 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 | Montfort, Baudoin, Bell, Bogost, Douglass, Marino, Mateas, Reas, Sample, Vawter | 2012 | one line of BASIC read from every angle | monograph, used as a course text | essays alternating with REM code chapters: mazes, ports, **regularity**, variations, **randomness**, one-liners, BASIC, C64, maze walker | platform studies, close reading | V |
| Software Studies: A Lexicon | Matthew Fuller (ed.) | 2008 | 38 entries on the parts of software (Loop, Variable, Function, Lists, Object Orientation, Glitch, Pixel, Elegance ...) | reference | alphabetical, read in any order | software as culture | V |
| Programmed Visions | Wendy Hui Kyong Chun | 2011 | software, memory, source code | monograph, 4 chapters | on sourcery and source codes, then interfaces, order from order, software as memory | against the belief that seeing the source reveals the thing | V (contents, partial) |

### 1b. Creative coding

| Course or text | Authors | Year | Scope | Length | Order in one line | Critical stance | Checked |
|---|---|---|---|---|---|---|---|
| Design By Numbers | John Maeda | 1999 | a tiny language for "visual people", 2D grey canvas | 19 short chapters | line, lines, variables, repeat, calculate, dot, dots, nest, commands (your own), time, react ... | none stated | V (the 100x100 canvas is mem) |
| Processing: A Programming Handbook for Visual Designers and Artists | Casey Reas, Ben Fry | 2007; 2nd ed. 2014 | Processing, 2D, then extensions (3D, sound, electronics) | 4 parts, each closed by a Synthesis chapter and an Interviews chapter | Part 1 still pictures (shape, data, control, math, colour, random, transform); Part 2 continuous, functions, recursion, input; Part 3 motion, arrays, image; Part 4 objects, simulation | lineage through practitioner interviews; no critique | V 1st ed.; 2nd ed. order from a search summary |
| Learning Processing | Daniel Shiffman | 2008; 2nd ed. 2015 | Processing for beginners | 23 chapters grouped into lessons | pixels, interaction, variables, conditionals, loops, functions, objects, arrays, algorithms ... transformations and 3D (ch. 14) ... | none | V chapters; Zoog and the lesson grouping are mem |
| ICM: Introduction to Computational Media (NYU ITP) | ITP faculty (repos ITPNYU/ICM-2025-Code, ICM-2024-Media) | 2024, 2025 | p5.js for graduate art and design students | two 7-week halves | drawing, "Animation: Variables", "Interaction: Conditionals", "Repetition: Loops", "Organization: Functions", objects and arrays, final; media half: pixels, sound, text, data | none | V |
| The Nature of Code, and the ITP course | Daniel Shiffman | 2012; p5.js ed. 2024; course syllabus spring 2023 | simulating natural systems; assumes one semester of programming | 12 chapters; a 14-week course with a midterm project | randomness, vectors, forces, oscillation, particles, agents, physics libraries, CA, fractals, evolution, neural nets, neuroevolution | nature treated as simulable; debt never asked | V |
| Generative Design | Hartmut Bohnacker, Benedikt Gross, Julia Laub, Claudius Lazzeroni | 2009 German; English 2012 and 2018 (p5.js) | principles by visual element, then methods; addressable sketches | book plus code package | P: colour, shape, type, image; M: random and noise, oscillation, data trees, dynamic structures (formula surfaces and attractors in 1st ed.) | design craft | V; M.3/M.4 are mem |
| Form+Code in Design, Art, and Architecture | Casey Reas, Chandler McWilliams, LUST | 2010 | a survey of code and form | 5 themes, each with an essay, precedents and code | repeat, transform, parameterize, visualize, simulate | historical survey | V |
| Code as Creative Medium | Golan Levin, Tega Brain | 2021 | a compendium of assignments and exercises for art and design teachers | 23 assignments, exercise groups, educator interviews | exercises: computing without a computer, graphic elements, iteration, colour, conditionals, **unpredictability**, arrays ... simulation, ML | mild ("encouraging a point of view") | V assignment list; exercise order and the Brief/Variations format from a search summary |
| Recreating the Past | Zach Lieberman (SFPC) | 2018-2020 | recreate one historic artwork a week in openFrameworks; prior coding required | 10 weeks, 2 h a week | Molnar (chaos and order), Whitney, Cooper/Maeda, Riley/Albers, Knowlton/Schwartz, Burson/Salavon, body (Utterback, Krueger), **glitch/deformation** (Menkman, the Vasulkas) | historiography: whose computational art counts | V |
| Code Societies | organised by Melanie Hoff, SFPC; a different teacher each session | winter 2019 | critical theory paired with coding workshops | **3 weeks**, weekday evenings | 12 stand-alone sessions, from computational methods to cybernetics of sex, software as ideology and critical simulation | "ideological and corporeal attributes of computation" | V |
| Code! Programming with p5.js (The Coding Train) | Daniel Shiffman | ongoing | video track | 7 chapters, 35 videos | getting started (errors included), variables (random() included), conditionals, loops, functions, objects, arrays | none | V |

### 1c. Engines, shaders, graphics

| Course or text | Authors | Year | Scope | Length | Order in one line | Critical stance | Checked |
|---|---|---|---|---|---|---|---|
| Catlike Coding: Unity series and Introduction to Godot 4 | Jasper Flick | Unity Basics updated 2021; Godot intro 2023-24 | geometry and noise through code | long written tutorials, no exercises | clock, graph of cubes, mathematical surfaces; hashing, value, Perlin, Voronoi, simplex noise; meshes, grids, five spheres; Godot: clock in the editor, scripted, many clocks, a shader | craft and correctness | V |
| Coding Adventures | Sebastian Lague | about 2018 on | one algorithm per video, mostly Unity (Godot-Marching-Cubes 2023) | chronological episodes | caves, planets, marching cubes, boids, slime, reaction-diffusion, ray tracing, a software rasteriser ... | wonder; the failures are shown | V repos; episode contents mem |
| The Book of Shaders | Patricio Gonzalez Vivo, Jen Lowe | begun about 2015 (mem), unfinished | GLSL fragment shaders | 13 written chapters | shaping, colours, shapes, matrices, patterns, then random, noise, cellular noise, fbm | none | V |
| Articles | Inigo Quilez | 2000s on (mem) | SDFs, noise, raymarching, useful maths | categorical archive | by category, no sequence | demoscene elegance | V (index) |
| Learn GDScript From Zero | GDQuest | repo 2021; public about 2022 (mem) | GDScript in the browser, beginners | 28 lessons | what code is, **first error (lesson 2)**, calling functions, a supplied turtle, own functions, variables, **game loop (lesson 10)**, delta, conditions, vectors, loops, arrays, dictionaries, types | none, but honest that the turtle is a supplied teaching tool | V |
| Learn 3D Gamedev From Zero with Godot 4 | GDQuest | 2024 | 3D game mechanics | 15 modules, ending in a 10-20 h final challenge | pre-made parts, controllers, state machines, rigid bodies, skin vs controller, importing, animation, dialogue, navigation, final challenge | none | V (outline) |
| Godot docs: procedural geometry; Your first 3D game | Godot contributors | 4.x | the four mesh tools; one small game | reference pages; a 10-part tutorial | ArrayMesh, MeshDataTool, SurfaceTool, ImmediateMesh; game area, player, mobs, squash, score and replay | none | V |
| Image Objects: An Archaeology of Computer Graphics | Jacob Gaboury | 2021 | a history of computer graphics | monograph, 5 chapters | hidden surface, frame buffer, Utah teapot, object orientation, GPU | media archaeology; the author also writes queer computing history (Rhizome 2013) | V for the five objects; exact chapter titles from a search snippet |

### 1d. Bauhaus and art pedagogy

| Course or text | Authors | Year | Scope | Length | Order in one line | Critical stance | Checked |
|---|---|---|---|---|---|---|---|
| Pedagogical Sketchbook | Paul Klee | 1925; English 1953 | his Bauhaus form teaching, condensed | 4 parts, 43 numbered sections | proportionate line and structure (including bone, tendon, muscle); dimension and balance; gravitational curve; kinetic and chromatic energy (top, pendulum, circle, spiral, arrow, colour circle) | spiritual naturalism; active/passive mapped onto sex | V (full text) |
| Point and Line to Plane, and the analytical-drawing course | Wassily Kandinsky | 1926; English 1947 | the elements of painting | 3 main sections | point, line, basic plane | formalist-spiritual; fixed emotional values of lines | V; subsections mem |
| Interaction of Color | Josef Albers | 1963 | colour through problems solved in cut paper | about 30 short chapters | perceptual problems (one colour as two, two colours as one), then free studies, then colour theories last | empirical, relativist about perception | V; contents from a search-index copy |
| The Vorkurs | Johannes Itten; later László Moholy-Nagy and Josef Albers | 1919-1933 | the preliminary course | one semester to one year | rhythmic body exercises, contrast and material studies; later paper, card and wire, then balance studies | from Itten's subjective to Moholy-Nagy's claimed objectivity | V in general; exact phase order not verified |
| Von Material zu Architektur (The New Vision) | László Moholy-Nagy | 1929; English 1932 | sensory and spatial training | 4 parts | preliminaries, material, volume, space | industrial optimism | V; sculpture stages mem |
| Drawing a Tree | Bruno Munari | 1978 | one recursive drawing rule | picture book | the rule, variations by environment, "mad branches" | playful | V |
| Early computer art as method: Nake's *Hommage à Paul Klee* (1965), Nees's *Schotter* (1968), Molnar's *machine imaginaire* and *(Dés)Ordres*, Mohr's *Cubic Limit*, LeWitt's wall drawings, the ReCode Project | Frieder Nake, Georg Nees, Vera Molnar, Manfred Mohr, Sol LeWitt, Matthew Epler et al. | 1965-1974; ReCode about 2012 | works and methods, not courses | - | an order, then a disturbance of the order | information aesthetics; instruction as art | V; Schotter and ReCode from search summaries |

### 1e. Queer, feminist and critical making; 3D and VR in art schools

| Course or text | Authors | Year | Scope | Length | Order in one line | Critical stance | Checked |
|---|---|---|---|---|---|---|---|
| CCS 382 Critical Unmaking: Queer and Feminist Technologies | Jacob Gaboury (Stony Brook), after Zach Blas's Goldsmiths course | 2016 | theory plus making (Twine, Emotica) for undergraduates | one semester, two sessions a week | Histories, then Practice, then Tactics (obfuscation, new materialisms, **failure, futurities**); the workshops climb their own ladder | queer and feminist technoscience | V |
| AGPM 129 Queer and Trans Games | micha cárdenas (UC Santa Cruz) | 2020 | play, read, prototype and make in Twine | 11 weeks | play, read, **paper prototype (week 5), Twine (week 6)**, make, playtest, reflect | queer and trans game studies | V |
| Queer Game Studies | Bonnie Ruberg, Adrienne Shaw (eds.) | 2017 | reader, used in courses | 5 parts | defining, play and design, reading, **failures, futures** | queer game studies | V |
| Digital Love Languages | Melanie Hoff et al. (SFPC) | 2020, 2022, 2024 | small personal software in Python/JS | 10 weeks online | orientation, folder poetry, codes words spells, zines, hand-coding round robin, sharing, presentation | care, abolition | V |
| Facial Weaponization Suite workshops | Zach Blas | 2011-14 | scan, aggregate, fabricate, perform | up to a month (one week at UCSD 2013) | readings, scanning, aggregation into a collective mask, fabrication, public intervention | against biometric recognition | V |
| Experimental 3D (Intro to Experimental 3D, Digital Bodies, Virtual Installation ...) | Claudia Hart (SAIC) | 2007 on | a Bauhaus basic course redone in Maya for art students | a set of courses | 2D, 3D, then 4D (time): light and dark, form, rhythm, colour, proportion, volume | units named after art lineages; no explicit queer lens on the pages seen | V |
| VLST 2390 Virtual Reality for Artists | Gregory Vershbow (Penn) | 2022 | 360 photo, Blender, AR, Tilt Brush, Unity | one summer course, 4 assignments | 360 photo, VR gallery in Blender, AR intervention, personal project | each assignment has a "what does this medium take away?" prompt | V |
| FemTechNet DOCC: Dialogues on Feminism and Technology | FemTechNet | 2013 | shared video dialogues plus local "nodal" courses | one term | labour, sexualities, race, differences, body, machine, systems, place, infrastructure, archive, transformation | feminist "anti-MOOC" | V structure; themes V-2 |

**Used as sources, not courses:**
- *QueerOS: A User's Manual* (Barnett, Blas, cárdenas, Gaboury, Johnson, Rhee, 2016) [V]
- *Glitch Feminism* (Legacy Russell, 2020) [V-2]
- *Feminist Data Set* (Caroline Sinders, 2017 on) [V]
- The Critical Engineering Manifesto (Oliver, Savičić, Vasiliev, 2011) [V]
- Anna Anthropy's *Rise of the Videogame Zinesters* (2012) and *Make Your Own Twine Games!* (2019) [V-2]
- *Videogames for Humans* (merritt kopas, ed., 2015) [V-2]
- The Pixelles incubator (Montreal, 2013 on) [V-2]
- Lockard, "Bauhaus and Code" (ITP *Adjacent*, 2019) [V]
- Freire and hooks as used in SFPC's "Learning to Teach" [mem; V-2 for SFPC]

---

## 2. Which have a scope like Ada's

Ada's scope has four parts: (a) a critical layer; (b) the students write code; (c) 3D, space or VR, with bodies that can be stood on, walked through, carried or become; (d) art-school students who have never programmed. The table below scores each candidate on those four. It is an honest count, not a ranking by quality.

| Course | Critical | Writes code | 3D / space / VR | Art school, beginners | What it is to Ada |
|---|---|---|---|---|---|
| Aesthetic Programming | yes | yes | no (2D web) | partly (design and humanities programme, beginners) | **the closest in method**: one critical theme per piece of syntax, code plus writing every week |
| Code Societies (SFPC) | yes | yes (workshops) | no | yes (artist-run school), not a ladder | **the closest in shape to the short track**: three weeks, a guest per session, critique beside code |
| Experimental 3D (Hart, SAIC) | weak (lineage, no stated critical lens) | no (Maya) | yes | yes | **the closest to "Klee in drag"**: a Bauhaus basic course in 3D for art students |
| VLST 2390 VR for Artists | yes (a paired reading and prompt per assignment) | no | yes (VR, AR, 360) | yes | a critique prompt per studio unit, in VR |
| CCS 382 Critical Unmaking | yes | light (Twine) | no | humanities undergraduates | the two-clock braid: theory order and workshop order run separately and meet weekly |
| Recreating the Past | light (historiography) | yes | mostly 2D (the body week is interactive) | yes, but prior coding required | recreate a precedent, then depart |
| Code as Creative Medium | mild | yes | partly (Parametric Object, Virtual Public Sculpture, Extrapolated Body) | yes | named body-shaped assignments; exercises kept separate from assignments |
| UCSB and USC CCS courses | yes | reading and remixing, little writing | no | humanities | remix and forensic reading as assignments |
| Montfort, Exploratory Programming | light | yes | late and 2D | arts and humanities | modify before write; errors in week one |
| The Nature of Code | no | yes | 2D (a museum exhibit of creatures as the running project) | yes (ITP), after an intro semester | the spine's middle, and the cumulative exhibit |
| Facial Weaponization Suite workshops | yes | minimal | yes (scans, fabricated masks) | art workshop, not a course | a collective body from the class's own data |
| Image Objects (Gaboury) | yes | no | yes (the history of 3D) | a book | the only critical reading of 3D graphics, one object per chapter |
| Catlike, GDQuest, Book of Shaders, Godot docs | no | yes | yes | beginners, not art school | the Godot and geometry ladders, with no debt |

**Verdict:**
- **None has all four.** The nearest reach three: Aesthetic Programming lacks 3D, Code Societies lacks 3D and a ladder, VLST 2390 lacks code.
- **The combination is Ada's own ground.** The queer sweep's headline agrees: queer and feminist courses make in Twine, paper, zines or HTML, and 3D/VR art courses make in Maya, Blender or Unity without a queer lens.
- **Gaboury is the one person found on both sides.** He teaches queer and feminist making (CCS 382) and wrote the critical history of 3D graphics (Image Objects), but he has not been found putting the two in one course.
- **The canon's geometric critique has only three footholds**: Kittler's raytracer (Marino chapter 6), 10 PRINT's regularity and randomness, and the Lexicon's Pixel, Glitch and Elegance. Everything else critiques data, platforms and language. The 2024 CCSWG Queer(ing) Code week treats queerness through language and data. Ada's topological and bodily queering is not represented there.

**Unchecked leads.** The sweeps did not exhaust the field. These are the leads they named but did not open:
- Zach Blas's Queer and Feminist Technoscience course at Goldsmiths (the model for CCS 382).
- The syllabi collected in the 2024 CCSWG "Teaching Code and Code Studies" thread, beyond the two already read.
- Nordic art-school courses were not searched at all.

---

## 3. Ordering moves that recur

### 3a. Where randomness sits: early as a value, after regularity as a topic

| Source | Randomness appears at | What comes before it |
|---|---|---|
| The Coding Train, Code! | random() inside chapter 2, Variables | drawing, colour, errors |
| Processing Handbook (2007) | Math 4, end of Part 1, before Transform | shape, variables, control, curves, colour, trigonometry |
| Code as Creative Medium, exercises | Unpredictability, 6th of 19 | unplugged work, graphic elements, iteration, colour, conditionals |
| Aesthetic Programming (book) | chapter 5 of 10 (the 2018 course had it 6th, after objects; the 2020 book moved it earlier) | geometry, loops, transforms, arrays, input |
| The Book of Shaders | chapter 10, opening "generative designs" | shaping, colours, shapes, matrices, **patterns** |
| 10 PRINT | chapter 40 "Randomness" | chapter 30 "Regularity" |
| Nake 1965, Nees 1968, Molnar 1974 | randomness enters the Klee lineage as a disturbance of a grid already built | the grid |
| Catlike Coding, noise | hashing first, and weak hashes visibly stripe | a grid of cubes |
| Generative Design | M.1, the first method | all the principles (colour, shape, type, image) |
| The Nature of Code; recreating the Past; the 2023 application (WP1); the Queer 3D intro | first | nothing (NoC assumes an intro semester) |
| **Ada spine** | **10 of 25** | transformation, arrays, colour, tiling, change, forces, formfinding, wave functions |

- **Two findings sit together here.** Every tradition meets random() early as a *value*. The ones that treat randomness as a *topic* put it right after the regular grid, because you need regularity to see chance at all (10 PRINT, the Book of Shaders, the Nees/Molnar lineage).
- **The middle ground:** random() as a value in the many-bodies/loops chapter, and randomness as a topic right after the first grid or tiling body, around chapter 5-7 of 17. At that point the seed, pseudo-randomness and the hash stripe are the DEBT.
- **Relation to the spine:** this is a declared departure (earlier than place 10). The pair "tiling, then chance" stays adjacent as the argued reason, and spine place 10 becomes a return (noise, fields).

### 3b. Where objects and classes come
- **The 2D intro canon puts objects late:**
  - Learning Processing chapter 8 of 23;
  - ICM week 6 of 7 (together with arrays);
  - Coding Train objects before arrays;
  - Processing Handbook Part 4;
  - Aesthetic Programming chapter 6, just after generativity.
- **GDQuest's free course never reaches classes** (it stops at types).
- **In Godot the student *uses* objects from the first day.** Every node has properties and methods, and meshes and materials are resources. So the canon's question there is not "when do objects arrive" but "when does the student *define* a body type".
- **The critique attaches at that definition.**
  - Aesthetic Programming: abstraction as the political choice of which properties count (after Fuller and Goffey).
  - CCSWG 2024: "describe war in a single class" worked better than reading others' code first.
  - Gaboury: object orientation grew out of graphics (Sketchpad's master and instance).
  - Form+Code gives the same moment the name **Parameterize**, which is Ada's `@export` family (74% of Ada scripts use `@export`, BRIEF.md). It is one chapter with three names: class, family, parameter.

### 3c. Transform early in Godot; 3D late everywhere else
- **The 2D traditions put transformation late:** Learning Processing chapter 14, "Transformations and 3D"; the end of the Handbook's Part 1; Form+Code puts Repeat before Transform.
- **In Godot a node is a transform**, so the spine's early placement (transformation = sequence 2) is right. Keeping it is agreeing with the spine for a Godot reason, not a tradition reason.

### 3d. Static before continuous, singular before plural
- **Static before continuous:**
  - The Handbook's Part 1 is all still pictures; "Structure 2: Continuous" opens Part 2.
  - GDQuest delays `_process` to lesson 10 by giving a sandbox that runs statements.
  - For Ada: build bodies in `_ready()` first, and open `_process(delta)` when the first body moves. This matches the spine, where Point_Animatedcube comes late in primitives.
- **Singular before plural:**
  - DBN: Line, then Lines; Dot, then Dots.
  - Learning Processing: Zoog, then an array of Zoogs [mem].
  - Catlike Godot intro: one clock, then many clocks.
  - For Ada: one body, then a family, then many bodies.

### 3e. Errors early; modify before write; write before critical reading
- **Errors come in week one everywhere:**
  - Montfort chapter 4: "valid and intentional are different";
  - the Coding Train's Getting Started;
  - GDQuest lesson 2, with an error translator.
- **Modify comes before write:**
  - Montfort chapter 3, before the fundamentals in chapter 6;
  - Aesthetic Programming's first miniX modifies a reference example;
  - GDQuest calls supplied functions and drives a supplied turtle before any definitions;
  - ICM's objective of reading and modifying others' examples.
- **Critical reading comes after writing:** CCSWG 2024 found "write first, then critique" beat reading others' code first.
- **These do not conflict.** The order is: modify a running thing to *make*, then write your own, then read your own code *critically*. Reading others' code critically comes last.

### 3f. Critique is paired per unit, not run as a separate track
- **Tied to the syntax, one theme per chapter:**
  - Aesthetic Programming: coordinates with the politics of faces, loops with time, random with control and care, classes with abstraction.
  - 10 PRINT alternates essay chapters with REM code chapters.
  - Fuller's Lexicon gives one entry per code idea.
  - Gaboury gives one technical object per chapter.
  - VLST 2390 gives one "what does this medium take away?" prompt per assignment.
- **Two strands on separate clocks.** CCS 382 runs the theory order and the workshop order separately, and they meet weekly.
- **Ada's contract uses both variants.** Critique is tied inside each chapter (the DEBT layer), and the spine is a separate clock (principle 1 below).

### 3g. Failure before futures, at course scale
- **Four sources agree:**
  - *Queer Game Studies* Part IV (failures), then Part V (futures);
  - CCS 382: failure, then futurities;
  - *Glitch Feminism*: error, encrypts, anti-body, skin;
  - Recreating the Past ends in body, then glitch/deformation.
- **This backs Palle's layers.** FOUNDATION, then DEBT, then ONTOLOGY holds at course scale as well as inside a chapter. The late spine (foundations crisis, QFEP, post-crisis) is the course-scale DEBT, with ONTOLOGY after it.
- **Code Societies shows how to teach that late stretch:** as critique sessions set beside code, not as more code. No creative-coding curriculum has a counterpart to spine 22-25.

### 3h. Parts closed by a synthesis; the final project starts early
- **Synthesis points:**
  - The Handbook closes each of four parts with a Synthesis chapter and an Interviews (lineage) chapter.
  - The Nature of Code course has a midterm simulation project in week 7.
  - GDQuest ends in a 10-20 h final challenge built from earlier mechanics.
- **The final project starts early:**
  - Aesthetic Programming plans the final project two units before the end (chapter 9's flowcharts).
  - AGPM 129 moves to a paper prototype in week 5 of 11, before the tool.
- **The short track needs the same pivot:** a mini-project brief by the start of week 3 at the latest.

### 3i. Four parts, named by what happens to form
- **Several lineages are ordered from element to energy:**
  - Klee: line and structure, balance, gravity, kinetic and chromatic energy;
  - Moholy-Nagy: material, volume, space (Ada: surface, body, place);
  - Form+Code: repeat, transform, parameterize, visualize, simulate;
  - The Nature of Code: inanimate, living, intelligence;
  - the 2023 application's four work packages.
- **All of these name parts by what happens to form, not by language feature.**
- **Klee gives one reason to teach colour twice:** as appearance early (spine 4), and as energy late, with shaders (spine 12). Klee's book ends in the colour circle.

### 3j. The ordering device that answers "related, not forced"
- **The Processing Handbook (1st ed.) prints two tables of contents [V]:**
  - a reading order that weaves categories together;
  - the same chapters by category, numbered (Shape 1, Shape 2, Shape 3 ...).
- **A topic can return under a new number**: "Shape 3: Parameters, Recursion" arrives in Part 2.
- **Parallel devices:**
  - Generative Design's P/M split (the methods half can be taken in any order);
  - the Coding Train's tracks (ordered) against challenges (stand-alone);
  - FemTechNet's shared core with local nodes.
- **All four let one body of material carry several orders**, which is what Palle asked for.

---

## 4. Exercise formats Ada can adopt

### 4a. The MiniX, made falsifiable (from Aesthetic Programming; CCS; Montfort)

**The source.** Every Aesthetic Programming chapter ends in a miniX with two halves:
- RunMe: a program.
- ReadMe: reflective writing against the readings.

Peer feedback takes about 20 minutes in class, and both halves live in Git [V].

**The Ada version.** One commit per chapter holds:
- **RunMe:**
  - `body.gd`: `extends Node3D`, builds the body in `_ready()`, exposes one or two `@export` axes.
  - `family.tscn`: instances the body 3-5 times in a row with different values, so the comparison is a single still. Set the values as inspector overrides on each instance.
  - If the family is built in code instead, assign each value with its declared type and print it back. The Ada repo measured that `set()` on a typed property with a wrong-typed value is refused **without an error** (CLAUDE.md, "a typed set() is refused in silence"). A family can then render five identical bodies and look like a finding.
- **PREDICT.md, committed before the first render:**
  - which two variants will look most alike, and why;
  - the commit time is the proof it came first.
- **CLAIM:** one sentence the comparison image supports, saying what the axis changes and what it leaves alone. Montfort's numbered Essential Concepts show how these can be collected into a glossary.
- **A debt comment** (after Marino's Climategate chapter): one comment in `body.gd` on the line where the approximation is made. For example: `# DEBT: 12 segments - every horizontal slice of this "sphere" is a 12-gon`.
- **Peer feedback, 20 minutes in pairs:** the partner looks at the image *before* reading the claim, says which pair they see as closest, and only then reads the prediction.

**A worked example: "A face from primitives"** (after Aesthetic Programming's "Geometric emoji").
- Spheres and a box as children of a Node3D, with `@export var eye_spacing := 0.2` (distance between eye centres, eye radius 0.08), at values 0.0, 0.1, 0.2, 0.4.
- **Prediction:** 0.0 and 0.1 look most alike, because at 0.1 the two spheres still overlap into one mass.
- **Claim:** eye spacing decides whether a group of spheres reads as a face at all, and the head outline does not change.
- **DEBT:** which face the defaults assume (Aesthetic Programming's politics of representation; Reinfurt's *Multi*).
- **PLACE:** hang it at the visitor's eye height in the student's own hall.

### 4b. The assignment with precedent (from Code as Creative Medium; Recreating the Past; Form+Code; The Nature of Code)

**The source.** Code as Creative Medium frames each assignment with a Brief, Learning Objectives, Variations for skill levels, and an annotated gallery of historic and contemporary precedents [V gallery; V-2 format].

**The Ada version: "Virtual Creature".**
- **Brief:** a creature built in code from at least three parts joined at pivots. Parts are Node3D children with their own transforms, as in Trans_Body. It has one `@export` axis that changes *what kind* of body it is, not its size.
- **Precedents:**
  - Yoichiro Kawaguchi's growth-model bodies and Hans Bellmer's *La Poupée*, both on Palle's Queer 3D lineage list;
  - one Ada hall: Trans_Body.
- **Variations, the same brief at two depths:**
  - short track: start from a supplied kit, change the parts and the axis;
  - long track: build one part's mesh with SurfaceTool and compare flat and generated normals.
- **Place, after The Nature of Code's Ecosystem Project, which is literally a museum exhibit of creatures:** put it in your own hall of the endless museum and walk around it.

**Other bodies with the same shape** (all Levin and Brain's titles, all of them bodies):
- Parametric Object, Extrapolated Body, Virtual Public Sculpture (a body placed in the shared museum).
- Personal Prosthetic: a body attached to the XR hand. This is GDQuest's skin-vs-controller composition, and it makes the desktop-to-XR swap a creative brief instead of a porting chore.

### 4c. The Albers problem: a constrained material and a stated perceptual target

**The source.** Albers set problems with a perceptual target, such as "make one colour look like two" and "make two different colours look alike" [V].
- Students solved them with cut coloured paper instead of paint, so results were exact and repeatable.
- The class compared solutions side by side.
- Free studies came after the controlled problems, and colour theory came last.

**The Ada version: "Make two different bodies look alike".**
- **Supplied:** `round_body.gd` builds a sphere-like body with SurfaceTool from `@export var segments: int` and `@export var rings: int`. A long-track variant uses `@export_enum("uv", "cube", "ico") var construction`, after Catlike's five spheres. The kit also supplies one fixed material resource (the palette), a fixed camera and a fixed light.
- **The rule:** the student may change only the exports, never the script. That is the paper, not the paint.
- **Task 1:** find two settings, on *different* axes, that look alike in the still, and name the pair before rendering.
- **Task 2:** make one body look like two. This is the metaball neck in ISO_Metaballs ("A neck between sources"), where two sources merge at a threshold of the blend radius.
- **Theory last:** the code idea (a nested loop over rings times segments; the vertex count) is named after the student has seen its effect.
- **DEBT:** the 2023 application's polycount against smooth deformation is visible in the pair. A 6-segment "sphere" and a hexagonal prism look alike.
- **Anchors:** Primitives_Portals ("Circular Approximation and Limits"), ISO_Metaballs, and Color_Paint, which already cites Albers [V repo].
- **Constraint:** the palette must be supplied, or the constraint disappears. A colour in a headset is never one value, because of tone mapping and lighting.

### 4d. Recreating the past, then departing (from SFPC's Recreating the Past; the ReCode Project; 10 PRINT's ports)

**The source.** Each week of Recreating the Past studies one or two artists and recreates one of their works from scratch [V]. The ReCode Project re-codes historic plotter images from the picture alone [V-2]. 10 PRINT re-implements one program on other platforms [V].

**The Ada version: Nees's *Schotter* as a floor.**
- **Given only the image, write the procedure:** a grid 12 boxes wide.
  - Each box is a StaticBody3D with a BoxMesh and a CollisionShape3D.
  - Each box's random rotation and offset grow row by row.
  - A `RandomNumberGenerator` drives it, with an exported `seed` and an exported `disorder_gain`.
- **Argument:**
  - Axis: `disorder_gain` at 0, 0.5, 1, 2.
  - Prediction: at which row the floor stops reading as a grid, and which two gains look most alike.
- **Place:** walk down the rows, first with the desktop walker and later in the headset. At some row the floor stops being walkable, which gives a measurable threshold for the claim.
- **DEBT:** write what the recreation cannot recover (the plotter's line, the paper, the 1968 generator). Also: the same seed gives the same "disorder" every time, which is pseudo-randomness.
- **Then depart:** change one rule so the work becomes yours. Recreating the Past asks what modern tools add; Ada asks what a body can do on it.
- **Anchors:** Random_Cubes, Randomness_10_PRINT_Algorithm, and the runnable `doc/book/studies/random-definition` kit (which has a seed step) [V repo].
- **Caution:** *Schotter* is the most-copied generative sketch. The walkable version is what makes it Ada's.

### 4e. Shorter formats worth borrowing

| Format | Source | Ada version |
|---|---|---|
| Decode | Aesthetic Programming | Open the chapter by walking the finished hall work and guessing how it is built (PRIMM's Predict and Investigate). |
| Code-critique station | Marino's Kittler chapter; CCSWG thread format | At the DEBT step, 20-40 lines of Ada's own approximating code, posted as snippet, context and one question: the RNG behind Random_Definition, the table in ISO_LookupTable, the noise call in Noise_Perlin_Simplex. |
| Critique the starter | Montfort's "Critique My Starter Programs"; Gaboury on the Utah teapot | The first DEBT exercise: what body do Godot's capsule player, the default cube and Squash the Creeps assume? |
| Analytical reduction | Kandinsky | Reduce a finished Ada work to its skeleton with the SKETCH helper (points, lines, bounding box), then write what the reduction lost. |
| Instruction as work, and the ai_assist protocol | LeWitt; Molnar's *machine imaginaire* | Unplugged Day Zero: write an instruction and a partner executes it. Later, write the instruction, an AI writes the GDScript, and you check the run against the instruction; list where the AI had to guess. The ambiguity is the debt. |
| One rule with a mad branch | Munari | The recursion chapter as a family: axes of wind, thinning ratio and damage. Without a thinning ratio or depth limit the tree never stops ("recursion must always be controlled"). Halls: Fractal_RecursiveTrees, LSystems_Growth. |
| Ports | 10 PRINT | A declared return: the same body as nodes, then MultiMesh, then a shader, and argue what changed. |
| Question, comparison, provocation | CCS 382 | A weekly three-sentence response; the comparison is the comparison image. |
| Collective body | Blas, Facial Weaponization Suite | A short-track mini-project template: scan, aggregate in code, wear or become it; the axis is the number of faces aggregated. It needs biometric consent and matched topology, which is a hidden debt of its own. |

---

## 5. What not to copy, and why

1. **Language-feature order as the driver.** The creative-coding order (variables, conditionals, loops, functions, objects, arrays) is fine as a ladder. If it drives the course, geometry becomes illustration and "what bodies are possible" is never asked. Keep the ladder, and let the body decide why each idea arrives.
2. **Late transformation and late 3D** (Learning Processing chapter 14). This is wrong for Godot, where a node is a transform.
3. **Randomness at chapter 0** (The Nature of Code). It assumes an intro semester Ada has to supply itself, and it skips "regularity before randomness".
4. **A separate theory track, and the reading loads that come with one.**
   - CCS 382 asks for 50-75 pages a week, and Aesthetic Programming students had about 25 hours a week for 20 ECTS.
   - Neither fits three weeks at Konstfack.
   - Use one argument per chapter, lexicon excerpts, and one debt reading.
5. **Reading others' code first, with beginners** (CCS as a method). It alienates beginners. Write first; read critically afterwards.
6. **Open-ended ReadMe questions.**
   - Aesthetic Programming's ReadMe, Montfort's Essential Concepts and CCS annotations cannot be wrong.
   - Ada's prediction plus claim can be proven wrong.
   - The Ada repo's own DNA programme found that a prediction which disagrees with the render is the one worth having.
7. **Glitch as a shader style.** That is the thin reading of Russell, whose glitch is social and embodied.
8. **Bauhaus universalism, reproduced straight:**
   - Klee maps active/passive onto male/female (Part I);
   - Kandinsky gives lines fixed emotional values;
   - Moholy-Nagy claims objectivity.
   - "In drag" means reading and reassigning these, and turning the fixed values into claims to test.
9. **Supplied bodies as the subject** (GDQuest's Gobot, Squash the Creeps' capsule).
   - Supply the game kit, name it, and open it later, as GDQuest does honestly with its turtle.
   - Do not let a given body stand in for the question.
   - Chun's "sourcery" is the reminder: opening the supplied code does not by itself reveal what it hides.
10. **"Anyone can make games" without tool debt** (the Twine stance). Keep its courage, including sharing a build in chapter 1. But 3D and VR carry tool debt that the course must name.
11. **Performance engineering early** (Catlike Basics 4-6: jobs, compute shaders). The frame budget belongs with MultiMesh and density, not at the start.
12. **A catalogue without an order.** Code as Creative Medium, the Quilez articles, Lague's episodes and Code Societies' stand-alone sessions are sources for chapters, not sequences. On their own they make weak student logic.
13. **A green check as proof.** GDQuest's in-editor validation is worth copying as a verify step, but "valid and intentional are different" (Montfort). The comparison image and the claim decide.
14. **Borrowing authority for geometric critique.** Say plainly that the canon's critique is social and linguistic, and that Ada's geometric and topological queering is new.
15. **Recreation as pastiche, and Molnar's "1%" as taste.** Recreate, then depart. Make selection explicit with the prediction and the claim.

---

## 6. Five design principles these courses support

**1. Two indexes: the course has its own reading order, and the spine is its index.**
- Each chapter names its spine sequence and is numbered inside it, for example "Randomness 1" in week 2 and "Randomness 2" at spine place 10.
- A departure shows as a jump in the numbers and carries a one-line reason. A return is named as a return.
- Halls stay stand-alone "challenges" that several tracks can visit.
- This is what "related to the spine, not forced by it" looks like when it is built into the structure.
- *Sources:*
  - Processing Handbook 1st ed.: two tables of contents and numbered returns [V];
  - DBN's "Commands" taught twice [V];
  - Generative Design's P/M split [V];
  - the Coding Train's tracks against challenges [V];
  - CCS 382's theory and workshop strands on separate clocks [V];
  - Fuller's Lexicon, where the reading is pulled in by the code idea [V];
  - FemTechNet's shared core with local nodes [V].

**2. Make first, then read the debt, inside every chapter.**
- Critique is attached to the code idea that made the body, not run as a separate theory track. It comes after the making.
- The order inside a chapter:
  1. Walk the hall and guess (Decode).
  2. Modify a running kit.
  3. Make the body.
  4. Predict.
  5. Compare.
  6. Take one debt reading: one argument, a short text or a code-critique snippet of Ada's own code.
- *Sources:*
  - Aesthetic Programming's theme per syntax, Decode and While() [V];
  - 10 PRINT's alternation of essay and REM chapters [V];
  - CCSWG 2024: write first, then critique [V];
  - Montfort: modify before write [V];
  - Gaboury: one technical object per chapter [V];
  - VLST 2390: a "what does this medium take away?" prompt per assignment [V];
  - Albers: theory last [V].

**3. Regularity before chance, and chance before the spine puts it.**
- random() enters as a value in the many-bodies/loops chapter.
- Randomness as a topic comes right after the first grid or tiling body, around chapter 5-7 of 17: seeds, pseudo-randomness, a hash whose stripes show.
- This is a declared departure from spine place 10. The randomness and noise halls become the return, as fields and noise.
- *Sources:*
  - 10 PRINT: "Regularity" before "Randomness" [V];
  - Aesthetic Programming: random at 5 of 10, moved earlier between the 2018 course and the 2020 book [V];
  - Code as Creative Medium: unpredictability 6th of 19 [V/V-2];
  - Processing Handbook: Math 4 before Transform [V];
  - the Coding Train: random() in Variables [V];
  - Nake 1965, Nees 1968, Molnar 1974: disorder laid over a built order [V];
  - the Book of Shaders: drawing before generative [V];
  - Catlike: hashing before noise [V];
  - the 2023 application's WP1 and the Queer 3D first principles.

**4. The exercise is a constrained problem with a visible target and a written prediction, and the open work comes after.**
- The controlled problem:
  - a supplied body with one or two `@export` axes (the coloured paper);
  - 3-5 values;
  - the closest pair predicted before the render;
  - one claim sentence.
- Then a named open assignment (Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic):
  - placed in the student's own hall;
  - offered at two depths, one for each track.
- *Sources:*
  - Albers's problems in cut paper, with free studies after [V];
  - Molnar's series [V];
  - Generative Design's numbered variants [V];
  - Code as Creative Medium's split between exercises and assignments, with Variations by skill level [V/V-2];
  - Aesthetic Programming's RunMe/ReadMe [V];
  - Montfort's Essential Concepts and repeated free projects [V];
  - The Nature of Code's Ecosystem Project as a museum [V];
  - Freire's problem-posing [mem].

**5. One body carried through, parts closed by a synthesis, failure before futures, and a short track that is the long track's first part.**
- The student's body is rebuilt as each idea arrives: one body, then a family, then many bodies, then in time, then placed, then become.
- Each part ends in a synthesis that also serves as a checkpoint for the mini project. The pivot to the final work comes two units before the end.
- The course-scale DEBT (crisis, QFEP, post-crisis) comes before ONTOLOGY and is taught as critique sessions beside code.
- The three-week track is the first part plus guest critique sessions.
- *Sources:*
  - Learning Processing's Zoog [mem];
  - Catlike: one clock, then many clocks [V];
  - the Processing Handbook's four Synthesis chapters [V];
  - The Nature of Code's midterm project [V];
  - Aesthetic Programming: the final project planned in chapter 9 of 10 [V];
  - AGPM 129: paper prototype in week 5, the tool in week 6 [V];
  - ICM's two 7-week halves [V];
  - Code Societies' three-week critique format [V];
  - failure before futures: *Queer Game Studies* IV to V, CCS 382, and Recreating the Past's closing body and glitch weeks [V].

**Two riders sit beside the five.** The canon does not support them, because it is 2D.
- **Godot decides where the canon is silent:**
  - transformation stays early;
  - objects are used from day one and defined later;
  - `_process(delta)` opens when the first body moves;
  - supplied parts (the SKETCH helper, the walker) are named as teaching tools and opened later, with skin separated from controller so the XR body can be swapped in.
  - *Sources:* GDQuest, the Catlike Godot intro, the Handbook's static-before-continuous.
- **The course should state where the canon ends.** Ada's geometric and bodily queer critique is its own contribution. Chun's "sourcery" belongs in the DEBT step of the first chapter that opens a supplied helper, because Ada's premise that the labs "reveal the black box" is exactly what she questions.
