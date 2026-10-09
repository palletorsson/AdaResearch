# A growing toolbox for making

Author direction, 29 September 2026. This is a writing and lesson-design rule, not a claim that the current tutorial files already satisfy it.

The student should leave the opening able to make a small work and recognise some of the decisions it carries. We do not need to explain every system that makes the work possible. Each chapter should give enough usable material to make another choice, while preserving the pleasure and questions that make the choice worth pursuing.

## A promise about prerequisites

The author's phrase "type safe" names a pedagogical promise: a step should accept knowledge the student already has, or a working component we explicitly supply. It should leave an ability the next step can actually use. This is a metaphor for dependable learning dependencies, alongside ordinary type correctness in code.

No unexplained helper should be required to make the promised example work. If a snippet uses a variable, function, scene or add-on, it must have been introduced or be present in the supplied starting material. A declared type alone does not make a lesson usable.

Keep three roles clear during editing:

- **An excerpt to inspect** exposes a particular decision in the museum's code. It can be incomplete if its context and purpose are clear. It does not by itself count as a usable addition to the student's toolbox.
- **A step to build** belongs to an identified starting scene or script, says where the change goes and gives a visible result to look for. Required helpers are present. The student can make a deliberate variation.
- **A part to borrow** is supplied working: a camera, floor, lighting, input or pickup system, for example. State what the student can rely on and change. We can return to its construction when it becomes the subject of an encounter.

These distinctions belong in the preparation of the lesson. They do not require a repeated checklist or warning around every paragraph in the book.

The concrete opening progression is recorded in [A lineage the student can carry](TUTORIAL_LINEAGE.md). That agreement now includes teaching use of the supplied pickup component in Point Coordinates and distance in Point Lines. The portable XR lesson is still to be delivered.

## What each hall contributes

Before expanding its code, record what the reader brings, what new distinction matters here, what is supplied, what the student can make afterwards and where that ability returns. A hall can primarily supply an encounter rather than a new construction skill. Do not force an equal code quota across the spine.

| Hall | Main work here | What can enter the student's toolbox |
| --- | --- | --- |
| Day Zero (preface) | Establish a working environment and recognise inherited infrastructure | Open, change, save, run and stop the supplied base; establish the separate headset route before its use. |
| Point_Zero | Arrival in something already underway; once at readiness and repeatedly during processing | Set a greeting in _ready(), keep an integer between calls, and change a counter in _process(). The display is supplied; engine construction and timing calculations wait. |
| Point_One | Encounter appearance, resistance and light | Change the visible and collision radii independently. Inspect the removable sun without teaching its renderer. |
| Point_Coordinates | Hold a point; name its reference | Use the supplied pickup in Ada; change X/Y/Z in the desktop study; distinguish local and world position and prepare A and B. Portable XR starter pending. |
| Point_Lines | Put two known positions into relation | A reusable way to connect and measure between positions, using the points already made. |
| Point_Trace | Let successive positions remain | A small introduced list of positions and a supplied or taught way to display it. Do not silently assume the later Array sequence has already been read. |
| Point_Line_Grid | Compare movement with selected addresses | A way to snap a position and compare the result with the unsnapped position or trace. |
| Point_Triangle_Context, first encounter | Close three familiar segments | A triangular boundary from three points; compare it with the points lying on one line. |
| Point_Triangle_Context, next encounter | Give the boundary a surface | A way to make a face from familiar positions; extend the existing material rather than restarting in a new unexplained system. |

These are learning targets for the next tutorial pass. Audit and build the starting materials before claiming the abilities have been delivered.

## Point One: enough for a first work

A first work could arrange three points carrying the same name, while their sizes and boundaries differ. Which can be passed through? Which must be walked around? What can a shadow suggest about an object that has no collision? The student chooses the arrangement and what it makes another body encounter. Holding joins this vocabulary in Point Coordinates.

Point One's tutorial follows absence, visibility and resistance. It selects small real changes to the visible radius and collision radius, then reads the removal of light as one decision. The surrounding construction is supplied. Point Coordinates begins with the held point, then reads its components and references. The axes, distance arrow and labels help that comparison; constructing them would introduce a different subject.

Point One starts with study.tscn and its three condition scripts in doc/book/studies/point-one. The separate doc/book/studies/point-coordinates kit starts with coordinates.tscn and points.gd. These fixed-camera kits do not supply portable walking or XR pickup. CONSTRUCTION.md preserves an earlier fuller explanation. Native execution and a beginner's ability to work independently are separate checks.

## Keep the reason for Ada in the operation

The main text retains bodily action, necessary explanation, desire and the question opened by the encounter. The coding lesson gives the student means to make and alter those conditions. Learning that a collider is separate from a visible surface makes a critical choice available: must what is visible also stop a body?

The first work should allow a choice whose outcome matters to its maker. Copying the correct demonstration is a beginning, not the only acceptable destination. A component can return later with a new body, scale, receiver or question; that is how a small vocabulary becomes more capable without requiring everything at the entrance.

Before calling a lesson ready, run its stated steps from its stated starting material. Then ask a beginner to try an authored variation without filling gaps for them. Code execution and learner understanding are different checks; neither should be claimed on behalf of the other.


## Read the encounter, then choose to make

Point One is testing two consecutive readings. The main chapter sustains the bodily, critical and poetic encounter; a separate making passage teaches its construction. Syntax such as constructors, resource types and scene attachment carries its own learning load even in a short block. Avoid treating a line limit as an adequate measure of difficulty.

Keep only code whose wording helps the current encounter. Put the longer reduced implementation after the encounter, with the working parts explicitly supplied. The reader should be able to follow the main chapter without switching into code analysis. Every hall can add an ability to make, notice or question; it does not require an equal allocation of prose and code. This remains a local Point One trial before wider adoption.


## Preparation is a prerequisite, not a repeated lesson

Day Zero (doc/book/day-zero.md) carries environment setup as a practical chapter of the preface. Later making passages assume the student can open the supplied project, select the intended scene, edit, save, run and stop. The initial editor, scene and device setup does not recur inside each artifact explanation.

doc/book/studies/day-zero supplies project.godot and a self-contained base.tscn for desktop testing. Point One inherits an identical copy of this base. The player, XR Tools and Quest deployment are named as a separate borrowed system and preparation route; they are not silently implied by the desktop base. No headset acceptance claim follows from a desktop test.


## One agreement, three selections

For each hall, use intent.md to record: what we arrive with; what we investigate here; which encounters carry the inquiry and how; what the first tutorial lets us make; what leaves for the next hall. The hall, main text and tutorial are overlapping selections, not matching inventories.

Each attachment has a purpose and a cost in attention. Technical helpers can be supplied; critical comparisons can remain experiences without becoming coding exercises; atmosphere and pleasure can justify space. Repetition earns a place when it changes a relation. Reconsider an unrelated object through its placement before assuming more explanation will make it belong.

Follow the construction lineage from position to connection to retained positions to edges and faces, with the grid's choice of addresses where the actual sequence places it. The critical lineage asks what these operations make visible, possible or excluded. Let the encountered differences produce the writing; do not require every hall to restate an identical philosophical formula.

Finish a hall's agreement, encounter selection, main prose and small usable tutorial together, then inspect the next handover. Point Coordinates now supplies two positions. Point Lines' existing grid tutorial is a recorded gap for the next pass, not an already fulfilled continuation.


## Point Zero hands over readiness

The hello-world tutorial at commons/maps/Point_Zero/tutorial.md sits between Day Zero setup and Point One's appearance and resistance. Its supplied study teaches _ready(), _process(), assignment and a retained named value. The counter is a small concrete case of once and again. Point One can assume familiarity with _ready() and var while introducing a position. Coordinates then makes that position's components and reference explicit.

These functions belong here because arrival and continuation are the hall's subject. Selecting them does not require teaching the engine loop, display construction or all uses of elapsed time. The main encounter remains a separate reading.


## A tutorial can follow the walk without teaching every mechanism

The author correction is about order, not simply adding the word point. Absent → visible → solid → removable light belongs to Point One. Holding → coordinates → reference belongs to Point Coordinates. The making passages inherit those encounters while choosing short changes where they expose the current relation. Supplied behavior or observation can carry the other stops. Separate texts can select different depths while keeping the same movement of attention.
