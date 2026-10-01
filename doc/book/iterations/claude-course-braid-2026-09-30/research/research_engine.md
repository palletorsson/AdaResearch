# Sweep: geometry through code in game engines and shaders (2026-10-01)

Scope: curricula that teach geometry through code in engines and shaders, plus one critical history of 3D.
Marks: **[V]** = checked this session against a real page (publisher, repo, TOC, lesson source); **[mem]** = from memory, not checked.
No verbatim passages are reproduced; section and lesson titles are listed as structure.

---

## 1. Catlike Coding (Jasper Flick): Unity tutorial series, plus a Godot 4 intro

- **Kind:** free long-form written tutorials (web + PDF + repo), self-paced. Unity/C#, 2020.3 LTS upgrade of Basics on 18 May 2021 [V]. Godot 4 intro series Dec 2023 to Jan 2024, GDScript [V].
- **Audience:** Basics assumes no Unity or coding experience, only comfort with multi-window editors [V]. From Pseudorandom Noise on, the Basics series is prerequisite (Jobs, Burst, shader graph) [V].
- **Ordered units [V]:**
  - *Basics*: 1 Game Objects and Scripts (an analog clock from primitives, then rotating arms by time) - 2 Building a Graph (prefab, loop of cubes showing a function, colour by position in a surface shader, animate with time) - 3 Mathematical Surfaces (function library, delegates + enum, line to 2D grid, then "leaving the grid": parametric sphere and torus) - 4 Measuring Performance - 5 Compute Shaders - 6 Jobs - 7 Organic Variety.
  - *Pseudorandom Noise*: 1 Hashing - 2 Hashing Space - 3 Value Noise - 4 Perlin Noise - 5 Noise Variants - 6 Voronoi Noise - 7 Simplex Noise.
  - *Procedural Meshes*: 1 Creating a Mesh - 2 Square Grid - 3 Modified Grid - 4 Triangle Grid - 5 UV Sphere - 6 Cube Sphere - 7 Seamless Cube Sphere - 8 Octasphere - 9 Geodesic Octasphere - 10 Icosphere.
  - *Pseudorandom Surfaces*: Surface Elevation - Simplex Derivatives - Perlin Derivatives - Voronoi Derivatives - Spherical Elevation - Surface Flow.
  - *Godot 4 Introduction*: 1 Making a Clock (2D, built in the editor from nodes, no code) - 2 Programming a Clock (GDScript) - 3 Many Clocks (packed scenes, RigidBody2D, Area2D + signals, Timer, randf_range, export, class_name: "it rains clocks") - 4 Clocks With Rings (custom shader) - 5 Migrating to C#.
- **Pedagogy:** follow-along, code shown incrementally with before/after diffs, grey Q&A boxes for side questions, finished repo per step [V]. No exercises or assignments.
- **Critical stance:** none stated; craft and correctness, performance-minded.
- **What Ada can learn:**
  - *The graph-to-surface ladder.* Line of cubes plotting a function -> the same function on a 2D grid -> a parametric surface. This is Point_Lines -> Point_Line_Grid -> a surface, and it lets WaveFunctions_Sine_Space's sine arrive as "the graph" early without the whole wave sequence.
  - *Hashing before noise, with the debt made visible.* The Hashing tutorial shows a weak hash as obvious stripes and gradients on a grid of cubes, then mixes bits until each seed gives an unrelated pattern [V]. That is the DEBT layer as a ready-made ARGUMENT: axis = hash quality (sequence / naive hash / hash without avalanche / full hash), predict which two look most alike. Pairs with Random_Definition ("A pattern that returns").
  - *A body family whose axis is the construction.* UV -> cube -> octa -> geodesic -> ico sphere is one body built five ways; Cube Sphere says outright the UV sphere bunches vertices at the poles [V]. A wireframe still per construction is an Ada comparison image; pairs with Primitives_Portals ("Circular Approximation and Limits"), and it is the application's polycount-vs-deformation question.
  - *Four-step Godot opening:* editor-built body -> script it -> many of it (instancing + randomness + physics) -> a shader on it. Same shape as body -> family -> density -> appearance in the braid.
- **Caution:** from Basics 4 onward the Unity series turns to performance engineering (Burst, jobs, compute shaders) that has no Godot equivalent for beginners; Godot series is 2D and stops after five parts; no assignments, so it is a text to adapt, not a course to run.

## 2. Sebastian Lague, *Coding Adventures* (YouTube, named in the 2023 application)

- **Kind:** video essays, one topic per episode, Unity/C# mostly; source per episode on GitHub. Channel repos from 2015, Coding Adventure repos from about 2018 [V: repo dates]. Episode titles/years below are inferred from repo names and dates [V repos; episode mapping mem].
- **Order:** not a curriculum; chronological. Repos in creation order that match spine topics: Procedural-Cave-Generation (2015), Procedural-Landmass-Generation (2016), Procedural-Planets (2018), Poisson-Disc-Sampling (2018), Hydraulic-Erosion (2019), Ray-Marching (2019), Marching-Cubes (2019, tagged Coding Adventure), Boids (2019), Clouds (2019), Portals (2020), Slime-Simulation + Ant-Simulation (2021), MN-Cellular-Automata + Reaction-Diffusion (2021), Terraforming (2021), Cloth-and-IK-Test (2021), Ray-Tracing (2023), **Godot-Marching-Cubes (2023)**, Fluid-Sim (2023), Text-Rendering (2024), Fluid-Planet (2025), Software-Rasterizer (2025), Smoke-Simulation (2025) [V].
- **Pedagogy [mem]:** narrated process: a naive first attempt, its visible failure on screen, a diagnosis with debug visualisations, a better attempt; no exercises; the repo is the handout.
- **Critical stance:** wonder and curiosity; no explicit critique. The honesty lies in showing the failures.
- **What Ada can learn:**
  - *The failed attempt as a chapter's spine.* Lague's "first try, visible failure, fix" is the planted bug and the PREDICTION at chapter scale: before the working body, show the plausible wrong one and ask what went wrong.
  - *Topic overlap is large:* marching cubes -> ISO_LookupTable/ISO_Metaballs; slime -> SwarmIntelligence_PhysarumColony; ants -> Random_Pheromone; boids -> SwarmIntelligence_Boids_Algorithm; portals -> Primitives_Portals (by name only); reaction-diffusion -> Shader_10_ReactionDiffusion; MN cellular automata -> CA_BeyondBinary; caves -> PG_Caves_Mazes; cloth -> SoftBodies_Cloth_Physics. A "watch this episode" field trip per late chapter costs nothing.
  - *Godot-Marching-Cubes exists* [V], so the isosurface chapter can cite a Godot source, not only Unity.
  - *Software-Rasterizer (2025)* is a companion to Gaboury's hidden-surface chapter: the same problem, rebuilt by hand.
- **Caution:** polished editing hides weeks of work and makes the process look easy; mostly Unity + compute shaders; not a course, no exercises. Treat it as field trips.

## 3. Patricio Gonzalez Vivo and Jen Lowe, *The Book of Shaders*

- **Kind:** free online book with live, editable GLSL fragment shaders on every page [V]. Began 2015 [mem]. Unfinished.
- **Ordered TOC [V]:** Getting started: 1 What is a shader? - 2 Hello world! - 3 Uniforms - 4 Running your shader. Algorithmic drawing: 5 Shaping functions - 6 Colors - 7 Shapes - 8 Matrices - 9 Patterns. Generative designs: 10 Random - 11 Noise - 12 Cellular noise - 13 Fractional Brownian motion - 14 Fractals (not written). Image processing, Simulation (pingpong, Conway, ripples, water colour, reaction diffusion) and 3D graphics (lights, normal maps, bump maps, ray marching, environment maps, reflect and refract): **all not written** [V].
- **Pedagogy [V, ch 5]:** a small plotted shader (the "fence": x plotted as a line over a brightness gradient); the reader edits one named line and swaps functions (pow, exp, log, sqrt, step, sin); a numbered list of small modifications; a "replicate this equation" task from Kynd's table; credits Golan Levin's shaping-function library and Quilez's GraphToy; closes with "For your toolbox" (LYGIA, GraphToy).
- **Critical stance:** none explicit; generative-art aesthetics.
- **Ada link [V, in repo]:** Ada's twelve Shader_ halls were built from this book. Shader_01_Shaping ... Shader_09_FBM are BoS chapters 5-13 one to one (Shaping, Colors, Shapes, Matrices, Patterns, Random, Noise, CellularNoise, FBM); Shader_10_ReactionDiffusion takes up a chapter BoS never wrote; Shader_11_QueerRubber and Shader_12_PinkExtravaganza are Ada's own. The spine's shaders sequence picks six of them (doc/book/iterations/claude-shaders-sequence-2026-09-25/DECISIONS.md).
- **What Ada can learn:**
  - *The spine's middle order is BoS's order at a larger scale:* drawing first (colour, shapes, transforms, patterns), generative second (random, noise, cellular, fbm). That is color(4) and tiling(5) before randomness(10) and noise(11). So a course can keep this order and explain it the BoS way, or run shaders as a **returning strand** (one short shader page per chapter: a colour chapter gets Shader_02_Colors, the tiling chapter gets Shader_05_Patterns, the chance chapter gets Shader_06_Random) instead of one block at spine 12.
  - *The "one editable line" exercise.* Each page names a line the student changes and predicts. This is PRIMM's Modify step at its smallest, and it transfers to Godot's shading language almost unchanged.
  - *A toolbox close.* Ending each chapter with a named, open library (LYGIA; for Ada, the studies kits and STUDENT_TOOLBOX.md) fits the Illich/commons line in the application.
- **Caution:** the chapters Ada needs most for 3D bodies (lights, normals, ray marching, simulation) do not exist. It is 2D fragment-only GLSL (u_time and gl_FragCoord against Godot's TIME, UV, FRAGCOORD, and vertex()). A pixel rule is not a body you can stand on, so a chapter that uses it still needs a PLACE.

## 4. Inigo Quilez, articles (iquilezles.org)

- **Kind:** reference archive of math-and-code articles with Shadertoy links; MIT-licensed code; plus video tutorials [V index]. Not a course; decades of work [mem: articles from the 2000s on].
- **Structure [V]:** *Indices of useful functions* (remapping functions, 2D/3D SDFs with and without gradients, bounding boxes, ray-surface intersectors, smoothstep, sigmoid, trigonometric functions, filterable procedurals); *Procedural noises* (FBM, gradient/value noise derivatives, domain warping, voronoise, smooth voronoi, voronoi edges); *SDFs & raymarching* (raymarching SDFs, smooth minimum, domain repetition, soft shadows, numerical normals, interior SDFs, Menger fractal, raymarching terrains...); texturing and filtering; lighting; *Useful maths* (computing mesh normals, simple IK without trigonometry, Fourier series, thinking with quaternions, float and random); *Fractals & complex dynamics* (Mandelbrot intro, Mandelbulb, 3D Julia, orbit traps, IFS); size coding (4k/64k demos).
- **Pedagogy:** derivation, then compact code, then a live Shadertoy; no exercises.
- **Critical stance:** demoscene "painting with maths": elegance, compactness.
- **What Ada can learn:**
  - *Smooth minimum is where the blob comes from.* Palle's Queer 3D intro names noise's "blob aesthetic" as algorithmic debt; the smooth-min article is the operator that makes blobs. An ARGUMENT with axis = blend radius k across 3-5 values, predicting where two sources "become one body", pairs with ISO_Metaballs ("A neck between sources").
  - *An appendix, not a chapter:* the "Indices of useful functions" format (remap, smoothstep, sigmoid, SDF list) as the course's reference card for the long track.
  - *Computing mesh normals* and *Simple IK without trigonometry* are short enough to set as long-track readings beside the surface_tool/normals chapter and VFM_09_Legs.
- **Caution:** math-dense; no progression; the culture prizes compactness, which a beginner reads as opacity. Link to specific articles only.

## 5. GDQuest: *Learn GDScript From Zero* (free) and *Learn 3D Gamedev From Zero with Godot 4* (paid)

### 5a. Learn GDScript From Zero ("Learn to Code From Zero with Godot")
- **Kind:** free, open-source, in-browser interactive app: lessons with quizzes and "practices" (code checked live) and an **error translator** [V]. Repo created May 2021 [V]; public release about 2022 [mem]. Team: GDQuest (Nathan Lovato et al.) [mem].
- **Ordered lessons [V, repo course/ folder]:** 1 What code is like - 2 Your first error - 3 Standing on the shoulders of giants (calling others' functions) - 4 Drawing a rectangle (a supplied **turtle**: move_forward, turn_right, turn_left) - 5 Your first function - 6 Multiple function parameters - 7 Member variables - 8 Defining variables - 9 Adding and subtracting - 10 The game loop (_process) - 11 Time delta - 12 Using variables - 13 Conditions - 14 Multiplying - (15 absent) - 16 2D vectors - 17 While loops - 18 For loops - 19 Creating arrays - 20 Looping over arrays - 21 Strings - 22 Functions that return values - 23 Append to arrays - 24 Access array indices - 25 Creating dictionaries - 26 Looping over dictionaries - 27 Value types - 28 Specifying types.
- **Pedagogy [V]:** short prose + a visual + a quiz + a practice with a goal and checks. Lesson 2 frames errors as help from programmers who came before and hands students a translator for the message. Lesson 4 tells students plainly that the turtle exists only in the app and will not work in the editor.
- **What Ada can learn:**
  - *Use before make:* call supplied functions (3) and drive a supplied turtle (4) before defining a function (5); change an object's own properties (7) before declaring your own variables (8). This supports the brief's supplied SKETCH helper (point, line, box), and GDQuest's honesty move shows how to present it: say that it is a teaching tool and when it will be opened.
  - *The error comes second.* A planted bug in lesson 2, with a translator, is the same move as Ada's "one planted bug per lesson whose message the student reads".
  - *The game loop can wait.* GDQuest delays _process to lesson 10 by giving a sandbox that runs your statements. That challenges the brief's "when does my code run is lesson one": with a supplied SKETCH/runner, Ada's first chapters can stay statement-level (Point Zero/One) and meet _process with delta at the first moving body.
  - *The turtle is Klee's walking point.* Lesson 4's turtle is Logo, which is the Pedagogical Sketchbook's point going for a walk. Point_Trace can own this.
- **Caution:** 2D, game-flavoured examples (health, sprites); no geometry beyond rectangles; no 3D, no meshes; stops at types.

### 5b. Learn 3D Gamedev From Zero with Godot 4
- **Kind:** paid course, early access from 30 Apr 2024, self-paced, prerequisite the 2D course, "Level II" [V outline PDF].
- **Ordered modules [V]:** 1 Introduction - 2 Get to know 3D (guided tours: assemble a mini-level from **pre-made parts**; 3D nodes, transforms, cameras, lights, materials) - 3 Gobot the Sorcerer (overhead character controller, instancing, hit/hurt boxes, kill plane, VFX) - 4 Patrol, Alert, Attack! (finite state machine mobs) - 5 Turn on the lights (first-person controller, collisions, interact) - 6 What's in the Chest (rigid bodies, runtime instancing, random loot) - 7 Walk in the Park (third-person controller; **separating the character skin from the controller**) - 8 New Coat of Paint (greyboxing, importing assets, lights, environment, collisions) - 9 It's Alive (glTF model, AnimationTree, animation state machine) - 10 Where's Gobot? (branching dialogue, 2D UI with 3D) - 11 To the Exit (navigation mesh, queued AI actions) - 12 Sophia's Rainbow (3D platformer, jump, collectibles) - 13 Time to Fight! (navigation mobs, stomp detection) - 14 The Final Challenge (build your own 3D game from the mechanics, 10-20 h) - 15 Where to go from here.
- **Pedagogy [V]:** GDTour (in-editor step-by-step wizard with live validation), GDPractice (exercises validated inside the Godot editor by a live testing panel), quizzes, glossary.
- **What Ada can learn:**
  - *Skin vs controller (module 7).* This is exactly the mechanism behind "desktop first, then swap the desktop body for the XR body". Name it as a code idea (composition) in the chapter where the player body is opened.
  - *Validated practice inside the editor.* Ada's runnable kits in doc/book/studies/ with a verify step are the same idea. Make every chapter's MAKE step end in a verify.
  - *A final challenge built from earlier mechanics* is the long track's capstone form. Its 10-20 h budget is about the size of a short-track mini project.
- **Caution:** every body is supplied (Gobot, Sophia, pre-made level parts); geometry is never the subject. Commercial and closed. A mechanics-per-module order would push Ada back toward option 2 in BRIEF.md.

## 6. Godot 4 docs: procedural geometry and "Your first 3D game"

- **Procedural geometry [V]:** sub-pages in order: Using the ArrayMesh - Using the MeshDataTool - Using the SurfaceTool - Using ImmediateMesh. The intro compares them: ArrayMesh is fastest and hardest; SurfaceTool is friendlier (generate_normals, index); ImmediateMesh is simple for geometry that changes every frame; MeshDataTool is slow but gives edges and faces. It introduces vertices, indices, normals and surfaces.
- **Your first 3D game, "Squash the Creeps" [V]:** 1 Setting up the game area - 2 Player scene and input actions - 3 Moving the player with code - 4 Designing the mob scene - 5 Spawning monsters - 6 Jumping and squashing - 7 Killing the player - 8 Score and replay - 9 Character animation - 10 Going further. Assets are supplied; the docs suggest doing the 2D game first.
- **What Ada can learn:** the docs' four-way mesh comparison is itself an ARGUMENT format: the same body built with ImmediateMesh (redrawn each frame, like the SKETCH helper), SurfaceTool (with generated normals: flat vs smooth), and ArrayMesh. Ada's own measurement is SurfaceTool / ArrayMesh / ImmediateMesh at about 12% of scripts each (BRIEF.md). Teaching order: ImmediateMesh as the SKETCH line, then SurfaceTool for the first standable surface, then ArrayMesh as an opened box in the long track. Squash the Creeps' parts 2-3 and 8 are the minimum player/input/score/replay a short track can borrow as a supplied kit.
- **Caution:** reference pages, not lessons for non-programmers; the 3D game's bodies are given.

## 7. Jacob Gaboury, *Image Objects: An Archaeology of Computer Graphics* (MIT Press, 3 Aug 2021, 312 pp.)

- **Kind:** scholarly media history [V publisher date via Berkeley page; page count via JCMS/UChicago listing].
- **Structure [V two sources agree on the five objects; exact chapter titles from a search snippet, treat as likely]:** Introduction - I Culling Vision: hidden surface algorithms and the problem of visibility (an algorithm) - II Random Access Images: interfacing memory and the history of the computer screen (an interface: the frame buffer) - III Model Objects: the Utah teapot as standard and icon (an object standard) - IV Object Paradigms: on the origins of object orientation (a programming paradigm) - V Procedure Crystallized: the GPU and the rise of computer graphics (a hardware platform). Centred on the University of Utah programme [mem].
- **Critical stance [V reviews]:** graphics made the computer an interactive medium rather than a calculator. "Image objects" are neither simply images nor simply things; graphics simulate rather than represent, and reshape computing itself. Reviewers flag long technical passages and a loosely defined "object".
- **Also [V]:** Gaboury wrote *A Queer History of Computing* (Rhizome, five parts, Feb-Jun 2013: queerness inside computational logic, starting from Turing) and *Queer Affects at the Origins of Computation* (JCMS 61.4). He is a direct bridge between the history of 3D and Ada's queer lens and Turing throughline.
- **What Ada can learn:** five DEBT readings that pair one to one with code chapters:
  1. *Hidden surface / culling* -> the camera and visibility chapter. What the renderer decides not to draw, and Ada's own finding that "an iso view is half blind" (memory). Its PLACE: stand where a face is culled.
  2. *Frame buffer* -> the Image/pixel/shader chapter. A picture is addressable memory, a grid.
  3. *Utah teapot* -> the primitive meshes chapter (BoxMesh, SphereMesh, Primitives_Polythedra): which bodies are default, who made them standard, what a test object normalises.
  4. *Object orientation* -> the classes/@export families chapter. A body type is a class; Gaboury shows the paradigm grew out of graphics (Sketchpad's master and instance), so "a family" has a history.
  5. *GPU, "procedure crystallized"* -> shaders and MultiMesh. The procedure hardened into silicon, and the frame budget as its politics.
- **Caution:** an academic monograph. For art students use excerpts or his shorter essays (the 2015 "Hidden Surface Problems" article; the Rhizome series). US-centred, Utah-centred history.

---

## Cross-sweep insights for the course candidates

1. **The spine's middle already follows the Book of Shaders.** Colour and pattern come before random and noise in both. Ada's Shader_01-09 halls are BoS chapters 5-13 one to one [V]. A candidate can either keep the order (and say "this is how the shader tradition teaches it") or braid a short shader page into each chapter from colour on, instead of one block at spine 12.
2. **Every engine curriculum grows from a graph to a surface.** Catlike: plot a function with cubes, then a grid, then a parametric surface. BoS: plot a shaping function as a line. So sine can enter early as a graph (WaveFunctions_Sine_Space / WaveFunctions_Unit_Circle) without moving the wave sequence; call it a deliberate early visit.
3. **Hashing is the honest first step into chance.** Catlike opens noise with a hash of coordinates plus seed, where weak hashes show visibly. Pseudo-randomness then arrives as a function, which is exactly the Queer 3D debt, with a comparison image built in (hash-quality axis). Pairs with Random_Definition.
4. **Construction as an axis.** Catlike's five spheres, the Godot docs' four mesh tools and IQ's smooth-min radius all make an axis that is a *method*, not a slider value. That is where polycount against smooth deformation (the application) becomes visible in one still: Primitives_Portals, ISO_Metaballs.
5. **Use before make, and say what is supplied.** GDQuest calls supplied functions and drives a supplied turtle before any definitions, and tells the student the turtle is a teaching tool. This supports the SKETCH helper and the named "supplied parts" in the short track, and it lets _process/delta wait until the first body moves.
6. **Skin vs controller** (GDQuest 3D module 7) is the concrete pattern behind "desktop first, XR body later". It belongs in the chapter that opens the player body, as composition.
7. **No engine curriculum here has a critical layer.** Gaboury supplies one, chapter-sized and paired to code (culling / frame buffer / teapot / object orientation / GPU). His queer computing history joins the Turing throughline. The pairing is Ada's own design work; nobody in this sweep has done it.
8. **Failure on screen is a teaching form.** Lague's episodes show the naive attempt failing before the fix. That is the chapter-scale version of the prediction and the planted bug, and his repos map to about ten spine sequences as optional field trips (Godot-Marching-Cubes exists).
9. **Game courses give the minimum complete game as a kit.** Squash the Creeps parts 2-3 and 8, and GDQuest's Final Challenge, show how little is needed: player, input, score, replay. The short track can supply that as a named kit so the three weeks go to bodies.

## Sources (checked this session)
- Catlike Coding: https://catlikecoding.com/unity/tutorials/ ; /basics/ ; /basics/game-objects-and-scripts/ ; /basics/building-a-graph/ ; /basics/mathematical-surfaces/ ; /pseudorandom-noise/ ; /pseudorandom-noise/hashing/ ; /procedural-meshes/ ; /procedural-meshes/cube-sphere/ ; /pseudorandom-surfaces/ ; https://catlikecoding.com/godot/introduction/1-making-a-clock/ ; /3-many-clocks/ ; forum post https://forum.godotengine.org/t/catlike-codings-introduction-to-godot-engine-4/35429
- Sebastian Lague repos: GitHub API users/SebLague/repos
- The Book of Shaders: https://thebookofshaders.com/ ; https://thebookofshaders.com/05/
- Inigo Quilez: https://iquilezles.org/articles/ (fetched with curl)
- GDQuest: https://github.com/GDQuest/learn-gdscript (course/ folder, lesson-2 and lesson-4 bbcode, lesson-10 opening) ; https://school.gdquest.com/outlines/learn_3d_gamedev_with_godot.pdf
- Godot docs: https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/index.html ; https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html
- Gaboury: https://artshumanities.berkeley.edu/publications/image-objects-archaeology-computer-graphics ; https://blog.animationstudies.org/review-image-objects-an-archaeology-of-computer-graphics-2021-by-jacob-gaboury/ ; https://rhizome.org/editorial/2013/feb/19/queer-computing-1/ (search listing) ; MIT Press page refused (403)
- Ada repo: doc/book/iterations/claude-shaders-sequence-2026-09-25/DECISIONS.md ; commons/maps/Shader_* ; map_info of Primitives_Portals, ISO_Metaballs, Random_Definition, WaveFunctions_Sine_Space, Primitives_Polythedra
