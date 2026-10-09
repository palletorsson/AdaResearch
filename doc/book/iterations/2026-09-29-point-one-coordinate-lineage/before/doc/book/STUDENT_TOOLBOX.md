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

## What each hall contributes

Before expanding its code, record what the reader brings, what new distinction matters here, what is supplied, what the student can make afterwards and where that ability returns. A hall can primarily supply an encounter rather than a new construction skill. Do not force an equal code quota across the spine.

| Hall | Main work here | What can enter the student's toolbox |
| --- | --- | --- |
| Day Zero (preface) | Establish a working environment and recognise inherited infrastructure | Open, change, save, run and stop the supplied base; establish the separate headset route before its use. |\n| Point_Zero | Arrival in something already underway; choosing somewhere to count from | Permission to begin with inherited work. The counter is available to inspect; building its whole system is not an entrance requirement. |
| Point_One | Distinguish a position, visible shape, collision and pickup; locate the same body in two references | A supplied starting scene in which the student can place and vary a point, then compare visible-only, solid and borrowed pickable versions. |
| Point_Lines | Put two known positions into relation | A reusable way to connect and measure between positions, using the points already made. |
| Point_Trace | Let successive positions remain | A small introduced list of positions and a supplied or taught way to display it. Do not silently assume the later Array sequence has already been read. |
| Point_Line_Grid | Compare movement with selected addresses | A way to snap a position and compare the result with the unsnapped position or trace. |
| Point_Triangle_Context | Let three positions bound a surface | A way to make a face from familiar positions; extend the existing material rather than restarting in a new unexplained system. |

These are learning targets for the next tutorial pass. Audit and build the starting materials before claiming the abilities have been delivered.

## Point One: enough for a first work

A first work could arrange three points carrying the same name, while their positions, sizes and permissions differ. Which can be passed through? Which must be walked around? Which can leave its place in a hand? The student chooses the arrangement and what it makes another body encounter.

Teach position, visible dimensions and a separate physical boundary through that comparison. Lend the working camera, lighting and movement setup. Supply the pickup component rather than requiring a beginner to implement XR interaction. Reading WORLD and LOCAL can extend the same point into another reference without teaching all of transform mathematics at once.

Point One now has a first construction study at doc/book/studies/point-one and an aligned tutorial.md: complete scripts build from position to visible sphere to fixed collision, with a supplied camera, floor and lighting. The main chapter keeps one position line and explains the operations through their consequences. The cumulative construction is read separately in the making passage. This covers an arrangement of visible and solid points; the study has a fixed camera. Movement and a portable configured pickup component remain a further teaching step. Do not claim the complete making target, or a beginner learner trial, from this first study.

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
