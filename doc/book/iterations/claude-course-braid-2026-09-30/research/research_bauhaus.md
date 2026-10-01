# Sweep: the Bauhaus and art-pedagogy lineage (2026-10-01)

Marks: **[V]** checked against a real page or text during this sweep (source named). **[mem]** recalled, not checked.
Nothing staged or committed. The Klee text was read in full from the 1960 Praeger paperback PDF (text extracted to `work/klee_ps.txt`).

---

## 0. The finding that changes the brief

APPLICATION.md summarises Klee as "the point walks and becomes a line, then plane and dimension, balance and gravitation (the pendulum, the spinning top), then kinetic forms (the arrow, circle, spiral)". The real order is close, but three details matter for a course: **[V]**

1. **The pendulum and the spinning top are not in the gravity part.** They open Part IV (kinetic). Part III (gravity) is the plumb line, stacked stones, and trajectories: a bullet, a stair climber, a balloon, a falling stone, a meteor.
2. **The circle and the spiral come out of the pendulum.** Klee swings the pendulum, lets it go all the way round (the circle), then changes the radius as it turns (the spiral). A contracting spiral dies in the centre; an expanding one breaks free. He calls it "the question of life and death".
3. **The book ends in colour, not in form.** The arrows get colour (black, hot, cold, green-red arrows). The last diagram is the colour circle, where the arrow "is superfluous". For Klee, colour is the only motion without an end.

Plus one that no summary mentions: **Part I is a book about bodies.** After the line and proportion, Klee teaches structure through bone, ligament, tendon and muscle (active, medial and passive organs), then the watermill, plant propagation and the heart and blood. The tightrope walker "is the scale". *What bodies are possible* is on Klee's own first pages.

---

## 1. Paul Klee, *Pedagogical Sketchbook* [V]

- **Source:** *Pädagogisches Skizzenbuch*, Bauhausbuch 2, 1925 (layout by László Moholy-Nagy). English 1953, Praeger, introduction and translation by Sibyl Moholy-Nagy, 87 illustrations. Checked against the 1960 Praeger paperback PDF (openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf) and the bauhaus-bookshelf.org entry.
- **Kind / audience / length:** a condensed abstract of his Bauhaus form teaching, for Bauhaus students. About 60 pages of numbered sections (I.1 to IV.43). Each section is one diagram and a few lines of text.
- **Ordered units** (Sibyl Moholy-Nagy's four divisions, confirmed in the body text):
  - **I. Proportionate Line and Structure (1-13).** An active line on a walk. The same line with complementary forms. An active line limited by fixed points. The medial line. Passive lines made by activated planes. Three cases: active line with passive plane, medial, active plane with passive line. Structural rhythm as repetition ("purely repetitive and therefore structural", I.6). Divisional proportion: 2:3:5, 7:11:13:17, the golden section. Bone, ligament, tendon and muscle. The waterwheel and hammer, the watermill, propagation, building "stone upon stone" against carving "chip from chip". The heart and the blood. The eye must "graze" over a surface.
  - **II. Dimension and Balance (14-25).** Three dimensions. Parallel lines and railroad tracks, where perspective is the third dimension added as optical illusion. A vertical axis that shifts as the viewer moves. The horizon and eye level, tested with inserted "space boxes". The tightrope walker, who "is the scale". Balance disturbed and corrected by a counterweight. Light and dark as weight. Stacked stones that each topple and correct, until a keystone. Key sentence: "non-symmetrical balance".
  - **III. Gravitational Curve (26-32).** The plumb line and "regions with different laws" (water and air). The swimmer. Trajectories: a bullet, a stair climber (rigid continuity), a balloon, a falling stone, a meteor (loose continuity). Axiom (from the introduction): to stand despite all possibilities to fall.
  - **IV. Kinetic and Chromatic Energy (33-43).** The spinning top: a balance on one point, saved by rotation. A double top on a string. The pendulum, then the circle ("the purest of mobile forms"), then the spiral. The arrow: shaft, point, rudder; uneven rudders give a curved course; the physical against the cosmic curve. Black, hot, cold and green-red arrows. Movement meeting counter-movement gives a central grey. It ends at the spectral colour circle.
  - **Teacher's programme** (Sibyl Moholy-Nagy's concluding note): I = line as point progression, planar definition, mathematical proportion, path of motion. II = line as optical guide, optical reason, psychological balance. III = line as energy projection. IV = line as centrifugal and centripetal symbol, as will and infinity, as colour mutation.
- **Pedagogy:** induction. From one small observed thing (a top, a railroad tie, a tendon) to a general law. Each division has one key sentence. There are no assignments; the teacher is meant to supply new phenomena, and the introduction lists tree rings, tides, bird flight, lightning and a swing.
- **Critical stance:** spiritual naturalism, "from the particular to the universal". **The dark spot, verbatim in the text:** in I, the active/medial/passive trichotomy is mapped onto sex ("Male organs (anthers), active... Female organs (fruit), passive") and onto command (brain active, muscle obeys, bone passive). This is the most precise place to put Klee "in drag": the grammar of the course is a hierarchy of activity, and a queer course can re-assign it.
- **What Ada can learn:**
  - **Reorder the middle by Klee:** line, repetition and structure, then dimension, the eye and balance, then gravity, then oscillation, circle and spiral, then colour as energy. The spine puts colour at 4 and waves at 9. Klee is a documented reason to treat colour twice: early as appearance, late (shaders) as energy.
  - **Balance and falling as one unit** (tightrope walker, stacked stones, spinning top). Its place: the first physics body (RigidBody3D), when you can stand on it or topple it. FormFinding_Equilibrium and Vectors_Act4a_KineticForces carry it.
  - **Pendulum, then circle, then spiral as one derivation chain in code:** oscillate, go full circle with sin/cos, then grow the radius. The contracting and expanding spiral is a ready prediction axis (radius growth -0.2 / 0 / +0.2: which two look most alike?). WaveFunctions_Pendulum and WaveFunctions_Unit_Circle carry it, with Fractal_GoldenSpiral as a return.
  - **"Purely repetitive and therefore structural"** is the thesis sentence for the loops/arrays chapter (Array, Tutorial_Tiling_Floor).
  - **Bone, tendon, muscle** gives an early composite-body chapter: a skeleton of transforms with a pivot (Trans_Body).
  - **The format:** one numbered diagram, one to three lines, one key sentence per part. This fits a hall-sized study card.
- **Caution:** there are no exercises, so the teacher must invent them. The universalism ("child of the Universe") and the gendered trichotomy should be read critically, not reproduced. Randomness is entirely absent.

## 2. Wassily Kandinsky, *Point and Line to Plane* (1926) and the Analytical Drawing course [V]

- **Source:** *Punkt und Linie zu Fläche*, Bauhausbuch 9, 1926. English 1947, Guggenheim / Museum of Non-Objective Painting, translated by Howard Dearstyne and Hilla Rebay. Checked against the archive.org record and bauhaus-bookshelf.org. Teaching format from the Getty *Bauhaus: Building the New Artist* pages.
- **Ordered units [V]:** Introduction, then POINT, then LINE, then BASIC PLANE, then an Appendix of diagrams. The subsections are [mem]: under Point, the geometric point, its size and shape, and the point in nature, music and dance (Palucca). Under Line, straight lines (horizontal, vertical, diagonal, free), angular lines (acute, right, obtuse), curves and waves, then lines in the other arts. Under Basic Plane, the format, and the weight of top/bottom and left/right.
- **Pedagogy [V, Getty]:** elements taught as polarities (repose against tension). The primary forms are circle, square and triangle; "the circle is a plane, the spiral is a line". Freehand circles and spirals are drawn first and checked with instruments afterwards. Squares are subdivided to study rhythm and weight. **Analytical drawing:** a still life of planks and strips is not copied but reduced, in stages, to lines of tension and structure.
- **Critical stance:** formalist-spiritual. Elements have inner "sounds" and fixed emotional values, which is a universalism.
- **What Ada can learn:**
  - **The analytical-drawing move as an exercise format:** take a finished Ada work, have the student reduce it in code to its skeleton (debug-draw points, lines and the bounding box), then write down what the reduction lost. That is the DEBT layer as an exercise.
  - **Freehand first, instrument second:** predict and sketch by hand, then render in code and compare. This is PRIMM with a pencil.
  - **The "basic plane" as its own unit:** in Ada the plane is the floor or grid that bodies stand on (Point_Line_Grid). Kandinsky makes the ground a subject rather than a given.
- **Caution:** fixed emotional values ("warm horizontal") are exactly the kind of claim the ARGUMENT strand should test, not teach. The subsection order is [mem].

## 3. Josef Albers, *Interaction of Color* (1963) [V]

- **Source:** Yale University Press, 1963. The original was a silkscreen portfolio with about 150 plates (the Albers Foundation says about 200 reproductions). 1971 paperback with 10 studies; 2013 50th-anniversary edition with about 60. Taught at Black Mountain College, fully developed at Yale (chair of design 1950-58). Checked against yalebooks.yale.edu and albersfoundation.org. Contents list from a search-index copy of the Yale edition's table of contents; that exact page was not fetched.
- **Ordered units (contents, in order):** colour recollection (visual memory); colour reading and contexture; why colour paper instead of pigment; a colour has many faces (relativity); lighter and/or darker; gradation studies; colour intensity; 1 colour appears as 2; 2 different colours look alike; why colour deception (after-image, simultaneous contrast); colour mixture in paper (illusion of transparence); factual mixtures (additive and subtractive); transparence and space illusion; colour boundaries and plastic action; optical mixture; the Bezold effect; colour intervals and transformation; the middle mixture again; juxtaposition, harmony and quantity; film colour and volume colour; **free studies**; stripes; fall-leaf studies; the masters; the Weber-Fechner law; colour temperature to humidity; vibrating boundaries; equal light intensity (vanishing boundaries); **colour theories and systems (near the end)**; on teaching colour.
- **Pedagogy [V]:** "experience before theory". Each chapter is a problem with a stated perceptual target, such as *make one colour look like two* or *make two different colours look alike*. It is solved with cut coloured paper, not paint: paper removes mixing skill and makes the result exact and repeatable. Solutions are compared across the class, and students count as co-authors, since the plates are their work. Theory and systems come last.
- **Critical stance:** anti-system, empirical, relativist about perception ("a colour has many faces"). Still universalist about the eye.
- **What Ada can learn:**
  - **This is the ARGUMENT strand's direct ancestor.** A stated visual target, one constrained material, variants side by side, and the closest pair named. *Make two different bodies look alike* is a strong exercise: find two parameter settings that nearly coincide, which is `dna.predicted_degeneracy` as an assignment.
  - **Coloured paper is the model for "fix the body, expose the parameters".** Constrain the material so the comparison is honest: a supplied body with 1-2 `@export` axes, not a blank script.
  - **Name the theory after the experience:** the code vocabulary word (arrays, noise) is introduced after the student has seen the effect.
  - **Put "free studies" after the controlled problems,** as the mini-project slot. That matches the short track's shape.
- **Caution:** Color-aid paper has a physical, closed palette. The screen equivalent (a fixed palette resource) must be supplied or the constraint disappears. Paper colour on a monitor or in a headset is a different perceptual case; VR adds tone mapping and lighting, so a "colour" is never one value.

## 4. The Bauhaus Vorkurs: Itten, then Moholy-Nagy and Albers [V general; exact order not verified]

- **Source:** Getty *Bauhaus: Building the New Artist* (the Itten pages), bauhaus.de (balance study object, about 1924), purebauhaus.com (Vorkurs article). The Bauhaus Kooperation Itten page could not be reached (its redirect is broken).
- **Kind / length:** a compulsory preliminary course of about one semester to a year, taken before the workshops.
- **Ordered phases:**
  - **Itten (1919-23):** rhythmic body exercises before drawing; contrast studies (light/dark, rough/smooth, hard/soft); material and texture studies and assemblages; analysis of old masters; nature drawing.
  - **Moholy-Nagy and Albers (1923-28):** first semester with Albers, handwork in paper, card and wire; second semester with Moholy-Nagy, "material and space". Balance studies in metal, wood, glass and wire, meant to stand balanced or appear to float.
  - **Albers alone (1928-32/33):** economy, precision, tight constraints, material exercises such as paper folding [mem for folding].
- **Pedagogy:** making before theory; one material under a constraint; results shown together.
- **Critical stance:** it moves from the subjective and spiritual (Itten) to the objective and industrial (Moholy-Nagy). It is also a known site of gender channelling, with women steered into weaving [mem].
- **What Ada can learn:**
  - **Itten's warm-up:** the VR body moves before it makes. Day Zero standing and reaching in the room is the Vorkurs's rhythmic warm-up, and legitimately comes first.
  - **Balance studies are the Place strand:** build a body that stands, or seems to float, and prove it with physics (does it topple?). That pairs with Klee II/III.
  - **The shift from Itten to Moholy-Nagy is itself the debt question:** intuition against the objectivity claim.
- **Caution:** Itten's esotericism (Mazdaznan diet and breathing) [mem]. The objectivity of Moholy-Nagy's phase is a claim to question, not a neutral method.

## 5. László Moholy-Nagy, *Von Material zu Architektur* (1929), in English *The New Vision* [V]

- **Source:** Bauhausbuch 14, 1929, from his Bauhaus teaching 1923-28. English 1932 (Brewer, Warren & Putnam). Checked against bauhaus-bookshelf.org.
- **Ordered units:** Introduction; I. Preliminaries (the education, sensory training); II. The Material (surface treatment, tactile exercises, and four terms: structure, texture, surface aspect, massing); III. Volume (sculpture); IV. Space (architecture). His sculpture stages, from blocked-out volume to kinetic or virtual volume, are [mem].
- **Pedagogy:** tactile charts and material studies. Experience cannot be delivered through description.
- **What Ada can learn:** **surface, then volume, then space** maps one to one onto Ada's surface (SurfaceTool, UVs and materials), then body (volume: a closed mesh and a collider), then place (a hall you stand in). His "kinetic/virtual volume" [mem] is a body made by motion: a rotating line sweeps a solid, which Ada can build with a MultiMesh trail or a lathe mesh.
- **Caution:** industrial optimism. The stages are [mem].

## 6. Bruno Munari, *Drawing a Tree* (*Disegnare un albero*, 1978) [V]

- **Source:** themarginalian.org review (2021), Printed Matter and Corraini listings. The Brera children's workshops (*Giocare con l'arte*, 1977) and the *Discovery of the Square / Circle / Triangle* trilogy are [mem].
- **Kind / audience:** a picture book for children and anyone, one exercise across the whole book.
- **Order:** one rule, stated and repeated about ten times: the trunk splits in two, each branch is slenderer than the one before. Then variations: straight, curved and bent trees; wind; a lightning wound and regrowth; snow; insects; species; individuals; and "mad branches", which appear in almost every family.
- **Pedagogy:** a one-sentence generative rule, varied by environment. The student draws by the rule.
- **What Ada can learn:** **this is the recursion chapter as a family exercise.** The rule is the recursive function; the axes are environmental (wind strength, thinning ratio, damage). The "mad branch" is the planted exception, and it gives a queer reading of recursion: the family still reads through the exception. Fractal_RecursiveTrees and LSystems_Growth carry it. It also gives the DEBT sentence "recursion must always be controlled" a body, since without a thinning ratio the tree never stops.
- **Caution:** a children's book. It needs a critique partner (L-systems' botanical realism, or the "natural" rule) to reach the debt layer.

## 7. Frieder Nake, *Hommage à Paul Klee 13/9/65 Nr. 2* (1965) [V]

- **Source:** V&A collection entry (O211685). Plotter drawing computed on a Standard Elektrik Lorenz ER56 and drawn on a Zuse Graphomat Z64. It is based on Klee's painting *Hauptweg und Nebenwege* (1929).
- **Method:** a horizontal and vertical framework from parameters, with random variables deliberately written in, so the computer chooses among options. The random element stands in for the artist's intuition.
- **What Ada can learn:** **this is where randomness enters the Klee lineage.** Klee has none; Nake adds it to Klee as a replacement for intuition. That is the historical and logical reason randomness can arrive right after structure and repetition: randomness as disturbance of a grid you already built. It is a departure from spine 10 toward the application's WP1. It is also a ready DEBT question: can a pseudo-random number stand in for intuition?
- **Caution:** it belongs to information aesthetics (Max Bense) with its objectivist claims [mem]. Nake himself later wrote critically about early computer art [mem].

## 8. Georg Nees, *Schotter* (Gravel, 1968) [V via V&A search summary]

- **Method:** 12 squares per row. Going down the rows, the random rotation and displacement grow, so order descends into disorder.
- **What Ada can learn:** **the entropy arc (QFEP F to E) in one image, and a perfect first seeded-randomness body:** a grid (arrays) plus a disorder ramp (random, seeds). The prediction question writes itself: at which row does the grid stop reading as a grid? Randomness_10_PRINT_Algorithm and Random_Cubes carry it. It is also a Place exercise: walk down the rows in VR as a disorder gradient.
- **Caution:** it is the most-copied generative sketch. Ask for a body version (cubes a person can stand on, where disorder makes the floor unwalkable) so it is not a cliché. The V&A page itself was behind a robot check; details come from the search summary.

## 9. Vera Molnar, *machine imaginaire* (1946-68) and *(Dés)Ordres* (1974) [V]

- **Source:** Digital Art Museum (dam.org) artist page. Ada already cites the *(Dés)Ordres* page in `commons/maps/Array/final.md`.
- **Method:** before she had a computer she wrote programs in her head: simple rules of combinatorial variation, small increments, a series judged side by side. From 1968 she used a real computer (Sorbonne experimental psychology lab, Fortran and Basic, plotter). In *(Dés)Ordres*, concentric squares are randomly disrupted. She accepted only a very small percentage of the possibilities (the "1%").
- **What Ada can learn:** **the series is the argument.** Molnar's method is the DNA family sheet: one rule, one axis, small steps, and the artist chooses. The *machine imaginaire* is also an exercise format for Day Zero or unplugged work: run the program by hand on paper before typing it.
- **Caution:** her selection by eye is aesthetic judgement. Make it explicit (the prediction plus the claim) rather than taste.

## 10. Manfred Mohr, *Cubic Limit* (from 1973) [V]

- **Source:** emohr.com. First computer drawings 1969, after information aesthetics and work with Pierre Barbaud (1967). From 1973 *Cubic Limit*: 2D sign constructs from the cube, later the hypercube.
- **What Ada can learn:** **one body as a whole vocabulary.** A single cube, rotated, cut and projected, carries decades of work. For the transformation chapter: the cube's 12 edges under a rotation become signs. The hypercube projection is a ready return in the foundations-crisis halls (NonEuclidean_Spaces).
- **Caution:** a strict formalism, and the source is the artist's own site.

## 11. Sol LeWitt, wall drawings and "Paragraphs on Conceptual Art" (Artforum, June 1967) [V]

- **Source:** MASS MoCA, Wall Drawing 159; the essay text (copies at Tufts and SFAQ).
- **Method:** "the idea becomes a machine that makes the art". A wall drawing is a written instruction using a small vocabulary of construction (corners, midpoints, centre), executed by drafters who interpret it. Each installation differs.
- **What Ada can learn:**
  - **The instruction is the source code; the wall is the run.** This is the unplugged format for Day Zero: students write an instruction, a partner executes it, and they compare.
  - **An ai_assist format:** the student writes the instruction, an AI writes the code, and the student checks the wall against the instruction. Where the drafter had to guess is where the instruction was ambiguous, and that is the debt.
  - **The "location drawing" vocabulary** (corner, midpoint, centre) as a first coordinate system before Vector3 (Point_Coordinates).
- **Caution:** the drafters' uncredited labour. "Execution is perfunctory" is a claim a queer and craft-aware course should contest.

## 12. The ReCode Project (Matthew Epler et al., about 2012) [V via search summary]

- **What:** re-coding works from *Computer Graphics and Art* (1976-78) in Processing under open licences. About 40 works, including Mohr, Molnar, Coqart, Franke and Kolomyjec.
- **What Ada can learn:** **the "re-code a historic image" exercise.** Given only the picture, write the procedure (PRIMM's Investigate, reversed). Then write what the translation cannot recover. Pairs well with Nees and Molnar.
- **Caution:** the site's upkeep is uncertain [mem].

## 13. Casey Reas, Chandler McWilliams and LUST, *Form+Code in Design, Art, and Architecture* (2010) [V]

- **Source:** Princeton Architectural Press; formandcode.com (code examples by section).
- **Ordered units:** Repeat (Embedded Iteration, Recursive Tree); Transform (Transcoded Landscape, Slit-Scan); Parameterize (Chair, Wave); Visualize (Displaying Data, Superformula); Simulate (Particles, Diffusion-Limited Aggregation). Each has an essay, code samples and historic examples.
- **What Ada can learn:** the computational heir of elements-to-composition. **Repeat comes before Transform**, which is the opposite of the spine (transformation 2, arrays 3). Parameterize is its own theme, which is Ada's family strand. Simulate comes last.
- **Caution:** a survey, not a course, with no exercises and no debt layer. It is probably covered in more depth by the Processing sweep.

## 14. Golan Levin and Tega Brain, *Code as Creative Medium* (MIT Press, 2021) [V, lists from a search summary of the contents]

- **Part One, assignments:** Iterative Pattern, Face Generator, Clock, Generative Landscape, Virtual Creature, Custom Pixel, Drawing Machine, Modular Alphabet, Data Self-Portrait, Augmented Projection, One-Button Game, Bot, Collective Memory, Experimental Chat, Browser Extension, Creative Cryptography, Voice Machine, Measuring Device, Personal Prosthetic, Parametric Object, Virtual Public Sculpture, Extrapolated Body, Synesthetic Instrument.
- **Part Two, exercises in order:** Computing without a Computer, Graphic Elements, Iteration, Color, Conditional Testing, **Unpredictability**, Arrays, Time and Interactivity, Typography, Curves, Shapes, Geometry, Image, Visualization, Text and Language, Simulation, Machine Learning, Sound, Games. Also interviews with educators.
- **What Ada can learn:** **unpredictability sits right after conditionals and before arrays**, which is early randomness (application WP1, not spine 10). Colour comes right after iteration. The course starts unplugged. The assignment briefs are body-shaped (Virtual Creature, Extrapolated Body, Personal Prosthetic, Parametric Object) and can be borrowed as mini-project briefs. Each assignment comes with historic precedents, a model for "one precedent per chapter".
- **Caution:** it is 2D, p5.js and screen-first. It has no 3D and no engine lifecycle. The Bauhaus framing is not stated on the pages checked.

## 15. Davíd Raphael Lockard, "Bauhaus and Code: A Tutorial Essay for the Digitally Alienated" (ITP *Adjacent*, issue 5, 2019) [V]

- **Format:** an essay-tutorial hybrid. The first half is the argument (against specialisation and technological alienation, quoting Gropius and Moholy-Nagy); the second half is a code tutorial after Kandinsky in a split-panel web editor.
- **What Ada can learn:** **the essay and the running code on one page, where the code proves the essay's claim.** That is the model for pairing a hall's final.md with a runnable kit.
- **Caution:** a single short piece; the tutorial is shallow.

---

## Cross-cutting: how this lineage taught "elements to composition"

1. **Element, then motion, then structure, then force, then energy.** Klee goes point (still), line (point in motion), plane (line's result), repetition (structure), balance, gravity, rotation and oscillation, colour. Kandinsky goes point, line, plane. Moholy-Nagy goes material, volume, space. Form+Code goes repeat, transform, parameterize, visualize, simulate. None of them starts with composition. All of them end with a free study.
2. **The exercise is a constrained problem with a visible target,** solved in a limited material and compared side by side (Albers's paper, Moholy-Nagy's balance studies, Kandinsky's reduced still life). That is Ada's ARGUMENT strand, and it has a hundred-year pedigree.
3. **Theory after experience** (Albers puts colour systems near the end; Moholy-Nagy says descriptions only prepare). Name the code idea after the student has seen what it does.
4. **Randomness is not in the Bauhaus.** It enters the lineage in 1965-68 (Nake, Nees, Molnar) as disturbance of an existing order. That fixes its logical place: **right after repetition and structure.**
5. **Instruction as art** (LeWitt, Molnar's *machine imaginaire*) gives the unplugged opening and the ai_assist format for free.

## A lineage-shaped order against the spine (for the breeders)

| Lineage step | Spine sequence (order) | Departure? |
|---|---|---|
| Point walks, becomes a line (Klee I.1; Kandinsky Point/Line) | primitives (1) | none |
| Repetition is structure (Klee I.6; Form+Code Repeat) | array_tutorial (3), tiling (5) | arrays before transformation, as Form+Code does |
| Disorder of the structure (Nees, Molnar, Nake) | randomness (10) | **early**: randomness as the first disturbance of a grid (application WP1; CCM puts unpredictability before arrays) |
| Dimension and the eye; the cube rotated (Klee II; Mohr) | transformation (2) | slightly later; perspective and camera belong here |
| Balance and falling (Klee II/III; Moholy-Nagy balance studies) | formfinding (8), forces (7) | balance before force: stand the body before you push it |
| The gravitational curve (Klee III: bullet, stone, meteor) | forces (7) (VFM_05_Launch) | in order |
| Pendulum, then circle, then spiral (Klee IV) | wavefunctions (9) | in order |
| Colour as energy (Klee IV end; Albers) | color (4), shaders (12) | **colour twice**: appearance early (4), energy late (with shaders) |
| A rule that grows, with its mad branch (Munari) | fractals (14), lsystems (15) | in order |
| The instruction is the work (LeWitt) | unplugged Day Zero; returns at cellular automata (13) | Day Zero; CA as instruction |

Sources: openendedgroup.com (Klee PDF), bauhaus-bookshelf.org (Bauhausbücher 2, 9, 14), archive.org (Kandinsky 1947), getty.edu Bauhaus pages (Itten; form), bauhaus.de (balance study), purebauhaus.com (Vorkurs), yalebooks.yale.edu and albersfoundation.org (Albers), themarginalian.org (Munari), collections.vam.ac.uk (Nake), dam.org (Molnar), emohr.com (Mohr), massmoca.org (LeWitt), formandcode.com, tegabrain.com (CCM), itp.nyu.edu/adjacent (Lockard).
