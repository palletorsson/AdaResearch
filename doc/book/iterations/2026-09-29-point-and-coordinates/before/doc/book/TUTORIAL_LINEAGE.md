# A lineage the student can carry

Teaching direction, 29 September 2026. This is the agreement for the next making pass. It describes what we need to deliver; the existing tutorials and downloads do not yet fulfil every step.

The corridor gives the order of encounters. The tutorial must also give the student something they can carry into another situation. A lineage needs both: a reason to meet the next object, and a working ability with which to change it.

## Follow one work as it becomes capable of more

Begin with a running scene. In that scene, a point becomes visible, resists contact, and can be carried. Make a second point and connect the two. Move one endpoint: the connection and its measured length change. Keep successive positions of the moving point: the connection becomes a trace. Choose which positions the trace may occupy. Close three edges, then give their boundary a face. Combine faces into a mesh and meet the engine's prepared primitives as decisions we can now recognise and alter.

The student should not have to abandon their point and start in an unrelated framework at each chapter. Each starting scene must visibly inherit the relevant parts of the preceding result.

| Stage | What the student already has | New work worth learning here | What can travel onward |
| --- | --- | --- | --- |
| Day Zero | A computer and the supplied project | Edit, run and stop the prepared scene; establish the XR route before a lesson requires it | A dependable place to test a change |
| Point Zero | A running scene | Initialise in _ready(); keep a value; update it in _process() | A small script that begins once and continues |
| Point One | That script and prepared surroundings | Give a position a visible body, a collision boundary and a supplied pickup capability; distinguish the position from its appearances and permissions | A point the student can place, resize and make available to a hand; a second independently movable point |
| Point Lines | Two points whose positions can change | Connect A to B; measure their separation; update the relation when either moves | A connection and a distance measurement reusable with another pair of objects |
| Point Trace | A moving point, an update function and a connection between positions | Introduce a small ordered list; retain selected positions and join successive entries | A drawing made from movement, with an explicit choice about what is kept |
| Point Line Grid | A position and its recorded path | Snap a copy to a chosen spacing; compare it with the original | A way to change the permitted addresses without losing the comparison |
| Triangle, first encounter in Point_Triangle_Context | Points and segments | Use three points to close three edges; see what happens when the points line up | An editable triangular boundary |
| Triangle, next encounter in Point_Triangle_Context | The triangular boundary | Add a face; introduce vertex order and the side from which a face is seen | A small editable surface |
| Polyhedra and cube | Familiar vertices and faces | Combine faces and identify the shared construction | A first mesh the student can change |
| Primitive studies | An authored mesh and prepared components | Compare procedural primitive types, resolution and configuration | A choice between constructing a form and configuring a supplied one |

Some later halls chiefly compare, reflect or make strange what we already know. They need no compulsory new code lesson. The preceding capabilities still give the student something with which to answer the encounter.

## Point One includes using pickup

The student should learn to make their own point grabbable here. Merely observing a museum object that can be held does not deliver that ability.

Supply an XR scene with its player, controllers and pickup function already working. At the held-point station, teach the object-side part: use the prepared pickable body with the familiar sphere mesh and matching collision shape. Explain what that component adds, where the learner attaches or instances it, and how to test the result. Then let the student give the same capability to a second point.

The project already has this separation. interactive_point_origin.tscn inherits the XR Tools pickable scene, its script extends XRToolsPickable, and the controller uses a separate XRToolsFunctionPickup. The museum point adds labels, haptics, an origin line and other work that the first student component can omit. Do not invent a single grab() call that supposedly installs the whole interaction.

Learning to use a component is real learning. Its interface and assumptions must be explained; its full implementation can remain supplied. Input bindings, controller tracking, release physics and signal programming need not all become new subjects in Point One. Return to those mechanisms when a later work needs to alter them.

The current Point One download has only desktop comparisons and no pickup rig. Adding a small usable XR starter and testing its object-side lesson is therefore the next delivery task. Native tests cannot stand in for a headset trial. The current tutorial remains accurate about this limitation until that starter exists.

## Distance belongs to the line

Point One gives us an address. Point Lines gives us a relation between two addresses. Keep the distance arrow as a supplied coordinate aid in Point One; teach the measurement when the student makes the connection itself.

Start with one pair, in a shared coordinate frame. A and B must be positions expressed relative to the same reference before we subtract them or measure between them. Teach the segment first, its separation next, and a change of an endpoint after that. Reuse Point Zero's continuing update so a carried point can change the line as it moves. Explain displacement and direction where they are needed to orient the visible connection; the mesh-making helper can be supplied with its inputs and result made explicit.

The first transferable work could be a measuring string between two grabbable points. Move either end, rotate the pair around one fixed end, then move both by the same amount. What changes, and what stays the same? Carry the same connection to two other objects. The student has learned a relation that can leave its original demonstration.

Grids, nested loops, neighbour search and graph counts are not prerequisites for making that first line. The current Point_Lines tutorial starts with an 8-by-8 grid and must be rebuilt around the two-point handover. Those later ideas can return where their use earns the additional complexity.

## Choose what to teach by what the student can do next

For each making passage, prepare five answers before expanding it:

1. What working scene and understood ideas does the student arrive with?
2. What new choice does this encounter make possible?
3. What must the student construct or configure to exercise that choice, and what can we supply?
4. Can they use it in a second situation without being given another complete recipe?
5. Which next lesson actually uses the result?

Keep an operation when it is necessary for the promised work or helps it travel to another work. Defer a mechanism when it only explains the machinery surrounding today's choice. This is a judgement about dependencies and usefulness, not a quota of one concept or a fixed number of lines per chapter.

A step that compiles is not yet proof of learning. First follow the exact exercise. Then ask for an intentional variation. Finally ask the student to use the same capability on another object or arrangement. If that last step needs a fresh unexplained helper, the handover is incomplete.

For Trace, introduce the list before using append, and the condition before using a distance threshold. The first version should reuse Line's distance measurement and Point Zero's updates. Rounding, bounded memory, whiteboard contact and record export can follow as comparisons; they should not all arrive inside the first recording excerpt.

## Keep the critical and poetic stakes in what can be changed

A sphere can be visible without resisting a body. A boundary can exceed the surface that seems to promise it. The same point can be fixed for one visitor and available to another hand. A line can measure a separation without giving anyone permission to cross it. A trace can preserve a route while losing its pauses.

These are material decisions the student's toolbox can expose. The critical reading can ask what those decisions permit, conceal or normalise; the making passage gives the reader a way to try another arrangement. Neither text has to carry the other's full explanation.

The next concrete handover is Point One's reusable held point into Point Lines' moving, measurable connection. Completing that pair will give us a better model for the rest of the spine than expanding every tutorial at once.


## Across the active spine

The [interactive lineage atlas](http://localhost:3003/tutorial-lineage) extends this agreement to all active sequences. Its tree shows capability dependencies; its walking-order view preserves the current museum route. The editable plan is [tutorial-lineage/curriculum.json](tutorial-lineage/curriculum.json). Every active hall has a source entry, but the proposed learning targets are not a claim that every current tutorial is complete or runnable.
