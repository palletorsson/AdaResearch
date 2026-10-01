# Sweep: critical code studies and software studies, as taught

2026-10-01, auto-research for the Ada course braid. [V] = verified this session from a real page (publisher, open-access text, the table of contents, or a syllabus). [mem] = recalled, not checked this session.

## The short answer to Palle's question

Yes, courses like this exist, and the closest one is almost a twin in method. **Aesthetic Programming** (Soon & Cox, 2020) is a 10-chapter, 14-week course for humanities students who have never programmed. Each chapter ties one piece of syntax to one critical theme, and every week's exercise has two halves: code (RunMe) and writing about the code (ReadMe). The other traditions add parts, but none of them builds a whole course:
- **Marino's critical code studies (CCS)** adds close reading of real code as a cultural text.
- **Montfort** adds the idea of modifying before writing, errors taught early, and repeated "free projects".
- **10 PRINT** adds a structure that alternates essays with code interludes, and places regularity before randomness.
- **Fuller's Lexicon** adds one reading per programming idea, in alphabetical rather than progressive order.
- **Chun** adds a critique of "seeing the source code reveals the thing".
- **Levin & Brain** add named assignment prompts about bodies and objects.

**What none of them has:** 3D, a game engine's lifecycle, or bodies built from geometry. Their critique is mostly social (data, surveillance, APIs, language), not geometric. So Ada's geometric critique (the debt of polycount against smooth deformation, noise's blob look, recursion that has to be stopped) is new territory, with only a few footholds in the canon: Kittler's raytracer, 10 PRINT's regularity and randomness, and the Lexicon's "Pixel", "Glitch" and "Elegance".

---

## 1. Aesthetic Programming: A Handbook of Software Studies (Winnie Soon & Geoff Cox, 2020) [V]

- **Kind:** open-access handbook and a real course. Open Humanities Press, GNU GPL v2, on GitLab, "forking" invited. Built from five years of teaching at Aarhus University's Digital Design bachelor programme. p5.js. [V preface]
- **Audience and length:** humanities students with little or no programming, 14 weeks, including **"pause weeks"** that revisit concepts without new syntax and project weeks for assessed work [V preface]. The 2018 Aarhus run [V github.com/AUAP/AP2018]:
  - each week: a 3-hour lecture, a 2-hour compulsory tutorial, an optional 4-hour "Shutup and code" session (first five weeks only), and about 20 hours of self-study (20 ECTS);
  - every week a miniX with peer feedback (about 20 minutes, in class), plus peer-tutoring presentations;
  - assessment: a final group project (ReadMe, runnable software, presentation) and an oral exam.
- **Ordered units (book):**
  1. Getting started: the working environment, the web console's "Hello World", reading the reference, Git. MiniX: modify a reference example.
  2. Variable geometry: coordinates, variables, `beginShape`/`vertex`, conditionals, operators. MiniX: **"Geometric emoji"**. Theme: the emoji as a politics of representation, identity, race and colonialism. Sample work: David Reinfurt's *Multi*, 1,728 faces from minimal typographic elements.
  3. Infinite loops: functions, `translate`/`rotate`, `push`/`pop`, arrays, `for`/`while`, `frameCount`, `millis`, `%`. MiniX: **"Designing a throbber"**. Theme: computational time, Ernst, the halting problem.
  4. Data capture: DOM buttons, mouse, keyboard, microphone, webcam and face tracker. MiniX: "Capture All". Theme: datafication (Zuboff, Couldry and Mejias).
  5. Auto-generator: `random`, `noise`, 10 PRINT, Langton's ant, 2D arrays and nested loops. MiniX: **"A generative program"**: at least two rules, at least one loop and one conditional, no interaction. Reading: *10 PRINT*'s "Randomness" chapter. Theme: control, autonomy, care; Pritchard and Soon's *Recurrent Queer Imaginaries*.
  6. Object abstraction: `class`, `constructor`, `this`, `new`, arrays of objects. MiniX: **"Games with objects"**. Reading: Fuller and Goffey, "The Obscure Objects of Object Orientation". Theme: abstraction as a political choice of which properties count.
  7. Vocable code: JSON, strings, `loadSound`. MiniX: e-lit in groups. Sample work: Soon's *Vocable Code*, with voices completing "Queer is...". Theme: code as speech act.
  8. Que(e)ry data: web APIs, `loadImage`, `loadPixels`. MiniX: an API work in groups. Sample work: Sollfrank's *net.art generator*.
  9. Algorithmic procedures: flowcharts. MiniX: flowchart one earlier exercise alone, then in groups brainstorm two **final-project** ideas as flowcharts.
  10. Machine unlearning: ml5.js, ELIZA, LSTM, Teachable Machine. The miniX is the **final project**: a critical-technical artifact plus a 6-8 page ReadMe. [all V, chapter pages]
- **Per-chapter structure:** each chapter opens with a flowchart of how the technical and the conceptual meet [V preface]. Then:
  - setup() and start();
  - one artist's roughly 100-line source code, often opened with a **"Decode"** exercise (read the running work and guess how it is made before learning the syntax);
  - syntax sections, with exercises and discussion in class;
  - **While()**, the critical essay part;
  - the MiniX (RunMe and ReadMe), then required and further reading.
- **Pedagogy:** "low floors, high ceilings"; open tasks plus questions; peer feedback on every miniX; ReadMe and RunMe kept as markdown in a Git repository. [V]
- **Stance:** programming is "reading, writing and thinking with" software; power relations built into the code. The queer lens is explicit in chapters 5, 7 and 8. [V]
- **Revision worth noticing:** the 2018 course ran Object Orientation (week 5) *before* Generativity (week 6). The 2020 book swapped them: Auto-generator (5), then Object abstraction (6). The authors themselves moved randomness earlier. [V: both orders]
- **What Ada can learn:**
  1. The miniX **RunMe and ReadMe pair** is Ada's BODY/ARGUMENT pair in another form. Keep the two halves, but make the ReadMe sharper. AP asks open questions; Ada asks for a PREDICTION before rendering and a one-sentence CLAIM the comparison image supports, which can be proven wrong. The ReadMe prompts can supply Ada's DEBT and PLACE questions: "what does the throbber hide?" becomes "what does this noise body hide?"
  2. **"Decode" before syntax** is Predict and Investigate in PRIMM form. Open each chapter by walking the finished hall work and guessing how it was built.
  3. **Name each chapter's assignment as a body.** "Geometric emoji" is a face made of primitives with a politics attached, the closest thing in the canon to Ada's Point halls plus Trans_Body.
  4. **Pause weeks** for the LONG track: a week with no new code ideas lightens the load and gives the returns a place.
  5. **The order evidence:** geometry, then loops/transforms/arrays, then input, then randomness and rules, then objects, then data, then algorithms, then ML. Randomness sits at the middle (5 of 10), after loops and conditionals and before classes.
  6. **The final project starts in chapter 9** (flowcharts), two units before the end. Ada's short track needs the same pivot.
- **Caution:**
  - 2D web canvas: no engine calling you back, no persistent 3D objects, no bodies to stand on.
  - Half the critique is about data and platforms (APIs, capture, surveillance), which fits Ada's post-foundations halls but not its geometric core.
  - New syntax every week plus a reflective essay every week is heavy. Aarhus students had about 25 hours a week for 20 ECTS; a three-week Konstfack course does not.

## 2. Critical Code Studies (Mark C. Marino, MIT Press 2020, Software Studies series) [V ToC via Google Books, EuropeNow review, criticalcodestudies.com]

- **Kind:** a monograph of method. Six chapters of case studies plus a revised manifesto and a look ahead. Each case opens with a **small, self-contained passage of code**, read as a text with meaning beyond what it does.
- **Audience:** humanities scholars and code readers; no programming needed to follow it. [V]
- **Ordered units:**
  1. Introduction
  2. Critical Code Studies: A Manifesto
  3. The Transborder Immigrant Tool: a hacktivist art project on the US-Mexico border
  4. Climategate
  5. FLOW-MATIC: Grace Hopper's language, and US English as the default of programming
  6. Kittler's Code: a core file of **Friedrich Kittler's raytracer**, in C and assembly
  7. Generative Code: Nick Montfort's *Taroko Gorge* and its remixes
  8. Futures of Critical Code Studies [V titles and the Kittler and Taroko subjects]
  - The Climategate case turns on a programmer's comment admitting an adjustment in climate-data code ("fudge factor") [mem]. The Transborder Immigrant Tool code is Java, with poetry embedded [mem].
- **Pedagogy:** the code critique. Annotate, contextualise, ask what the code means beyond its function, and read comments, names and structure as authored choices.
- **Stance:** code is culture. Who writes it, for whom, in whose language, and what its comments confess.
- **What Ada can learn:**
  1. **Kittler's Code is the model for the DEBT layer in 3D.** A media theorist's raytracer is rendering code read critically. Ada can hold a code-critique station at the DEBT step of chosen chapters: read 20-40 lines of Ada's own approximating code and annotate what it owes. Candidates: the RNG behind Random_Definition, the marching-cubes table in ISO_LookupTable, the noise call in Noise_Perlin_Simplex.
  2. **The confessing comment (Climategate) as an exercise.** The student writes a "debt comment" in their own body code, saying what the approximation owes. It is short and gradable, and it teaches that comments carry meaning.
  3. **Remix (Taroko Gorge)** is the family axis at the level of a work. Students remix an existing Ada artifact's parameters and defend the remix with a CLAIM.
  4. **FLOW-MATIC:** GDScript's English keywords are a DEBT topic for Swedish students. It is cheap to raise in the first week (statements, errors).
- **Caution:** CCS is reading, not making. Put in front of absolute beginners it alienates; see the 2024 working-group advice below (write first, then critique). The cases are 1950s-2000s texts and none is geometric except Kittler.

## 3. The Critical Code Studies Working Group (CCSWG), and CCS as taught [V wg.criticalcodestudies.com]

- **Kind:** a biennial online think tank. About four weeks of weekly themed plenary threads plus **"code critique" threads**: a participant posts a snippet with context and questions, and the group annotates it. No programming expertise is required; code is "the entry point into a discussion of technoculture".
  - 2022 (7th, Jan 15-Feb 14): anti-racist and decolonizing critique, code and fibre arts, accessibility, creative coding.
  - 2024 (8th, Feb 2-29): **Queer(ing) Code**, CCS and AI, **Teaching Code and Code Studies**.
  - 2026 (Jan 12-Feb 6): "Critical in CCS", "AI and CCS", "Code as Cultural Heritage", "New Work and New Directions". [V]
- **Syllabi (from the 2024 "Teaching CCS" thread, Craig Dietrich with Marino, Douglass and others)** [V]:
  - Three course types: code classes with theory mixed in; literary classes with code mixed in; CCS taught start to finish.
  - UCSB, winter 2023: Jeremy Douglass, "Decoding Digital Literature: Critical Code Studies", for non-programmer humanities majors. It used *10 PRINT*, the Electronic Literature Collections and Marino, with a **midterm remix** and a **final forensic analysis**.
  - USC, fall 2023: Marino paired *Aesthetic Programming* with *Critical Code Studies*, plus *Poetic Operations* (micha cárdenas) and *If Hemingway Wrote JavaScript*.
  - Assignment formats: collaborative close-reading annotation through GitHub pull requests; creative code studies (modify a generative work and reflect; Leonardo Flores); remixes of 10 PRINT and Taroko Gorge; forensic investigation; comparative writing.
  - One contributor (Période) found that **writing first worked better than reading first**: students answered prompts like "describe war in a single class" and then critiqued each other's code.
  - Marino's 2022 "A Critical Code Studies Syllabus" thread shows that a full syllabus was still being gathered from the community. The seed texts: Marino, Soon & Cox, Montfort, cárdenas, *10 PRINT*. [V]
- **What Ada can learn:**
  1. **"Describe a body in a single class"** is a ready prompt for Ada's classes/@export chapter, taken straight from CCS teaching practice: the modelling choice (which properties does a body get?) is the critique.
  2. **The code-critique thread format.** Each student posts a snippet of their own body code, its context and one question. Ada already runs an append-only agent forum; a class-scale version is the same shape.
  3. **Write first, then critique** should be the order inside each Ada chapter: make the body, then read its debt. Reading existing code comes second.
  4. **The 2024 "Queer(ing) Code" week** is a live community for the queer lens. Ada's bodily and topological version of it is not represented there yet.
- **Caution:** the working group is a seminar of peers, not a course for beginners, and its threads are open-ended. The syllabus thread confirms there is no settled CCS curriculum to copy.

## 4. Exploratory Programming for the Arts and Humanities, 2nd ed. (Nick Montfort, MIT Press 2021) [V open-access PDF, CC BY-NC-SA 4.0, archive.org]

- **Kind:** textbook for a semester. Python 3 plus Processing. No prerequisites.
- **Ordered units:**
  1. Introduction
  2. Installation and Setup
  3. **Modifying a Program** (appropriating a page; Free Project 3-1: modify a simple text machine)
  4. Calculating and Using Jupyter Notebook ("Encountering an Error"; concepts: **"Syntax Errors Help Us Attain Formal Validity"**, **"Valid and Intentional Are Different"**)
  5. Double, Double (type in a function, try it, describe it)
  6. Programming Fundamentals (functions, scope, iteration, polymorphism, equality, `if`)
  7. Standard Starting Points (Hello World, temperature conversion, factorial). Exercise 7-6: **"Critique My Starter Programs"**; concept 7-1: **"Computing Is Cultural"**
  8. Text I: Strings and Their Slices
  9. Text II: Regular Expressions
  10. Image I: Pixel by Pixel (nested iteration)
  11. Image II: Pixels and Neighbors
  12. Statistics, Probability, and Visualization
  13. Classification
  14. **Image III: Visual Design and Interactivity** (Processing), with Free Projects 14-1 "Recreate Geometric Designs", 14-2 **"Parametric Geometric Designs"**, 14-3 "Novel Clocks" and 14-5 **"Create a Navigable Generated Landscape"**
  15. Text III: Advanced Text Processing (Free Project: automate your own cut-up)
  16. Sound, Bytes, and Bits (bytebeat)
  17. Onward
  - Appendices: Why Program? and Contexts for Learning. [V ToC]
- **Pedagogy:** "Four Methods": (1) read and study, (2) type in the code and run it, (3) do the exercises, (4) define, pursue and share your **free projects**. Free projects are deliberately under-specified; they should be "tractable, computational, and interesting" and done **several times**. Every chapter ends with numbered **Essential Concepts**. [V]
- **Stance:** exploration against exploitation, programming as inquiry, free software. Montfort even defends "exploration" against the charge of being touristic or colonial. [V]
- **What Ada can learn:**
  1. **Modify before write:** chapter 3 comes before the fundamentals (chapter 6). That backs PRIMM's Modify before Make, and Ada opening on a runnable kit: the Point kits in doc/book/studies.
  2. **Errors as a positive topic in the first week.** "Valid and intentional are different" is the theory behind Ada's one planted bug per lesson. A body that compiles is not yet the body you meant.
  3. **"Critique My Starter Programs".** Ada can critique the canonical Godot starter (the capsule player of "Squash the Creeps", the default cube) as its first DEBT exercise: what body does the tutorial assume?
  4. **The same free project, repeated,** is the family axis in time: one body prompt answered three times across the course.
  5. **Essential Concepts** at chapter end is the one-sentence CLAIM, collected into a glossary. Free Projects 14-2 and 14-5 are Ada's parameterise and place steps in 2D.
- **Caution:** text comes first and the visuals arrive late (chapter 14 of 17), the opposite of what Ada needs. Python and Jupyter, no engine. Critique is light: cultural remarks rather than a theory track.

## 5. 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 (Montfort, Baudoin, Bell, Bogost, Douglass, Marino, Mateas, Reas, Sample, Vawter; MIT Press 2012) [V 10print.org and the PDF contents page; CC BY-NC-SA]

- **Kind:** a co-authored monograph about **one line of code**. It is a course text, not a course: its "Randomness" chapter is Aesthetic Programming's required reading for chapter 5, and UCSB taught from it.
- **Ordered units** (numbered like BASIC lines; REM "remark" chapters are code interludes):
  - 10 Introduction
  - 15 REM Variations in BASIC
  - 20 Mazes
  - 25 REM Ports to Other Platforms
  - 30 **Regularity**
  - 35 REM Variations in Processing
  - 40 **Randomness**
  - 45 REM One-Liners
  - 50 BASIC
  - 55 REM A Port to the Atari VCS
  - 60 The Commodore 64
  - 65 REM **Maze Walker in BASIC**
  - 70 Conclusion
  - 75 End
  - 80-100 back matter, including "Variants of 10 PRINT". [V]
- **Pedagogy:** a close reading from many angles (the token CHR$ 205.5, the grid, chance, the language, the platform), **alternating essay chapters with code chapters** (variations and ports).
- **What Ada can learn:**
  1. **Regularity before Randomness** gives a principled reason for the spine's order: tiling (5) and the grid before randomness (10). You need the regular grid to see chance at all. A course can keep "grid/tiling, then chance" as a declared, argued adjacency even while it moves randomness earlier than the spine does.
  2. **The REM rhythm.** Alternate an essay or critique beat with a code-variation beat. Ada's ARGUMENT step is a REM: variations of one body along one axis.
  3. **"Ports"** are an ordering move for returns: re-implement a body you already built in another representation (nodes, then MultiMesh, then a shader) and argue what changed. A deliberate return with a declared reason.
  4. **"Maze Walker"** turns the pattern into a walkable place: 10 PRINT's own PLACE and ONTOLOGY step. Ada already has the hall Randomness_10_PRINT_Algorithm (randomness sequence) and a maze hall, PG_Caves_Mazes.
- **Caution:** one program, and 8-bit nostalgia. Not a teaching sequence. It is 2D; its 3D Ada version must earn its axis ("visible in a still").

## 6. Software Studies: A Lexicon (Matthew Fuller, ed., MIT Press 2008) [V LOC table of contents]

- **Kind:** an edited lexicon, **alphabetical**; the Library of Congress contents list 38 entries (listing below).
- **Entries relevant to Ada's code vocabulary:**
  - Algorithm (Goffey), Function (Robinson), Lists (Adam), Loop (Hou Je Bek), Variable (Robinson), Memory (Sack), Interrupt (Yuill)
  - Object Orientation (Crutzen & Kotkamp), Class Library (Harwood)
  - Code (Kittler), Source Code (Krysa & Sedek), Obfuscated Code (Montfort), Programmability (Chun)
  - Glitch (Goriunova & Shulgin), Pixel (Harwood), Elegance (Fuller), Copy (Parikka), Import/Export (Manovich), Codecs (Mackenzie)
  - Ethnocomputing (Tedre & Eglash), Weird Languages (Mateas), Interaction (Murtaugh), Interface (Cramer & Fuller)
- **Pedagogy:** none prescribed. It is a reference to read in any order.
- **What Ada can learn:**
  1. **One entry per code idea.** Pair each chapter's `code_new` with a Lexicon entry:
     - loops with "Loop"; variables with "Variable"; functions with "Function"; arrays with "Lists"
     - classes and inheritance with "Object Orientation"; import_assets with "Import/Export"
     - noise and glitch with "Glitch"; recursion with "Elegance"; shaders and images with "Pixel"
  2. **The ordering insight:** the code ladder is sequential, but the critical reading is a lexicon. That is one clean way to be "related, not forced": theory is pulled in by the code idea, not pushed by a theory sequence.
- **Caution:** dense theory for first-year art students; use excerpts. It dates from 2008 (before GPU shaders and ML as everyday tools).

## 7. Wendy Hui Kyong Chun: Programmed Visions: Software and Memory (MIT Press 2011) and "Programmability" (2008) [V ToC via search snippets of the MIT Press OA preview; Discriminating Data is mem]

- **Ordered units:**
  - Part I, "Invisibly Visible, Visibly Invisible": 1 "On Sourcery and Source Codes"; 2 "Daemonic Interfaces, Empowering Obfuscations".
  - Part II, "Regenerating Archives": 3 "Order from Order, or Life According to Software"; 4 "Always Already There, or Software as Memory". [V]
  - *Discriminating Data* (MIT Press 2021) covers correlation, homophily and network science as the logic of segregation [mem].
- **Stance:** "sourcery" names the fetish that reading the source makes the thing visible. Software as ideology; the program as a metaphor for genes and life (chapter 3). [V chapter summaries]
- **What Ada can learn:**
  1. **Chun is the dark spot for Ada's founding claim.** Palle's Queer 3D intro says the labs "reveal the black box". Chun warns that showing the source can itself be sourcery. Put this in the DEBT step of the chapter that first opens a supplied helper (the SKETCH helper, the first-person walker): *what does seeing the code still hide?*
  2. **"Order from Order"** (life according to software) is the critical partner for Ada's DNA families and Turing morphogenesis (the reaction-diffusion hall, the shaders sequence).
  3. **Discriminating Data's homophily** [mem] is the critical partner for the graph theory and ML halls: GT_Pathfinding, ML_Classification, CriticalAlgorithms_Algorithmic_Bias_Visualization.
- **Caution:** a monograph, not a course, and hard reading. Use one argument per chapter, not whole chapters.

## 8. Code as Creative Medium: A Handbook for Computational Art and Design (Golan Levin & Tega Brain, MIT Press 2021) [V Penguin Random House ToC; exercise solutions at github.com/golanlevin/exercises]

- **Kind:** a teachers' compendium, not critical code studies proper, but the best source of *assignment prompts* for art students. [V]
- **Ordered units:**
  - **Part One, Assignments:** Iterative Pattern, Face Generator, Clock, Generative Landscape, **Virtual Creature**, Custom Pixel, Drawing Machine, Modular Alphabet, Data Self-Portrait, Augmented Projection, One-Button Game, Bot, Collective Memory, Experimental Chat, Browser Extension, Creative Cryptography, Voice Machine, Measuring Device, **Personal Prosthetic**, **Parametric Object**, **Virtual Public Sculpture**, **Extrapolated Body**, Synesthetic Instrument.
  - **Part Two, Exercises:** **Computing without a Computer**, Graphic Elements, Iteration, Color, Conditional Testing, **Unpredictability** (coin toss, drunk walk, **Ten Print**, noise mountains), Arrays, Time and Interactivity, Typography, Curves, Shapes, Geometry, Image, Visualization, Text and Language, **Simulation** (recursive tree, flow field, circle packing, Life), Machine Learning, Sound, Games.
  - **Part Three, Interviews:** The First Day, The Bimodal Classroom, When Things Go Wrong, Encouraging a Point of View, and others. [V]
- **What Ada can learn:**
  1. **Named body prompts.** Face Generator, Virtual Creature, Parametric Object, Extrapolated Body, Personal Prosthetic and Virtual Public Sculpture are ready names for Ada chapters' BODY and PLACE strands, and for the short track's mini project.
  2. **The split between open assignments and closed exercises** matches Ada's project_step against PRIMM drills.
  3. **Computing without a Computer comes first:** precedent for Ada's Day Zero.
  4. **Their exercise order puts Unpredictability 6th of 19,** after iteration, color and conditionals, *before* arrays. Color is 4th. That is more evidence that the creative-coding canon puts chance in the first third.
  5. **"The Bimodal Classroom"** interview is on mixed-experience groups, which is Konstfack's reality.
- **Caution:** an uncritical and at times techno-cheerful canon. Part Two is an unordered menu of topics. Mostly 2D.

---

## Cross-cutting insights for the Ada braid

1. **Code and critique are braided per unit everywhere they work.** In Aesthetic Programming, each theme is attached to the syntax: coordinates to the politics of faces, loops to time, random to control and care, classes to abstraction. In 10 PRINT, the REM chapters alternate with the essays. The UCSB and USC courses pair making with forensic reading. Nobody who teaches this well runs a separate theory track. That supports Ada's four strands. What Ada adds, and nobody else has, is the BODY and PLACE strands in 3D and VR.
2. **Where randomness goes: evidence for a middle position.**

   | Source | Randomness appears at | Before it |
   |---|---|---|
   | Aesthetic Programming (book) | chapter 5 of 10 | loops, transforms, arrays, input |
   | Levin & Brain exercises | 6th of 19 | iteration, color, conditionals |
   | Nature of Code | its introduction | nothing |
   | Palle's 2023 application | WP1 | nothing |
   | Ada spine | 10 of 25 | transformation, arrays, color, tiling, change, forces, formfinding, wave functions |

   10 PRINT adds a rule: **regularity before randomness**. A good middle ground places chance after loops, conditions and a grid or tiling body, around chapter 5-7 of 17. That is a declared departure from the spine (earlier), and the tiling-then-chance pair stays adjacent as the argued reason.
3. **Write first, then read.** Montfort modifies a program before the fundamentals; CCS teachers found that writing a model first ("describe war in a single class") beat reading others' code first. Inside each Ada chapter, then: make the body, then read its debt. A code-critique station on Ada's own approximating code goes at the DEBT step, never at the opening.
4. **Critique formats Ada can adopt:**
   - ReadMe beside RunMe (AP)
   - Essential Concepts (Montfort)
   - a debt comment in the student's own code (after Climategate)
   - a code-critique thread: snippet, context, question (CCSWG)
   - REM variations and ports (10 PRINT)
   - one Lexicon entry per code idea (Fuller)
   - remix and forensic analysis (UCSB)

   Ada's PREDICTION plus CLAIM is **sharper than all of them**, because it can be falsified; AP's ReadMe questions are open. Keep the falsifiable version and borrow AP's weekly peer feedback and Git-archived ReadMe.
5. **Shape of a long track:** Aesthetic Programming's 14 weeks have pause weeks (no new syntax) and project weeks, and the final project is planned two units before the end (AP chapter 9's flowcharts). The short track needs the same pivot: a mini-project brief by the start of week 3 at the latest.
6. **The queer lens has company but not in geometry.** AP's queerness is linguistic and data-centred (*Vocable Code*, *Recurrent Queer Imaginaries*, Que(e)ry data); the CCSWG 2024 had a Queer(ing) Code week. Ada's queerness is topological and bodily: deformation, polycount, impossible space. That is a real gap in the field, and Ada's contribution.
7. **Critique of geometry has only three footholds:** Kittler's raytracer (Marino chapter 6), 10 PRINT's regularity and randomness, and the Lexicon's "Pixel", "Glitch" and "Elegance". Everything else in the canon critiques data, platforms and language. The course should say so and not borrow more authority than the canon gives.
8. **Chun cuts against Ada's own premise** ("reveal the black box"). Naming that openly in a DEBT step is more honest than hiding it, and it is exactly what the Sieve's third question (the dark spot) asks for.

## Sources
- https://aesthetic-programming.net/ (preface; chapters 1-10 pages) [V]
- https://github.com/AUAP/AP2018 (the 2018 Aarhus course schedule) [V]
- https://books.google.com/books/about/Critical_Code_Studies.html?id=k4LPDwAAQBAJ ; https://www.europenowjournal.org/2022/03/24/critical-code-studies-by-mark-c-marino/ ; https://criticalcodestudies.com/kittler.html [V via search]
- https://wg.criticalcodestudies.com/ (start-here thread, "A Critical Code Studies Syllabus" (2022), "Teaching Critical Code Studies" (2024)) [V]
- https://archive.org/details/montfort-exploratory-programming-2e (open-access PDF; contents extracted) [V]
- https://10print.org/ and its PDF contents page [V]
- https://catdir.loc.gov/catdir/toc/ecip081/2007039724.html (Lexicon contents) [V]
- https://direct.mit.edu/books/oa-monograph/3341 (Programmed Visions, via search snippet) [V partial]
- https://penguinrandomhousesecondaryeducation.com/book/?isbn=9780262542043 ; https://github.com/golanlevin/exercises (Code as Creative Medium) [V]
