# Ada Research

*A Critical Tutorial — from a single point in space to the edge of chaos and beyond*

> **QFE = F − λE(S) + φΔE(S,t)**

This book teaches algorithms the way Ada Research teaches them in virtual reality: one walked path, one idea per page, every claim grounded in an artifact you can hold. Named for Ada Lovelace, who saw that computation could weave patterns the way the Jacquard loom weaves flowers and leaves, it takes a single journey — from the simplest geometric primitive to the philosophical limits of mathematics itself.

The journey is organized by a single formula, the Queer Free Energy Principle. Order (F) and entropy (E) exist in tension; the parameter λ controls the balance. Life, learning, and creativity happen at the edge of chaos, where λ ≈ 0.3–0.5. The curriculum moves through this parameter space: from pure order (a point, a line, a grid) through gathering entropy (randomness, noise, cellular automata) to the edge itself (fractals, growth grammars, generated worlds) and finally to the synthesis that asks what it all means — and who gets to set the parameters.

Each chapter below is a room you walk through in VR — or a page you read here.

## The Ledger

*Six threads run under the pedagogy. Chapters advance them unevenly — some touch one hard and ignore the rest; that unevenness is deliberate. Each chapter's ledger closes with the excavator's field note — the dig — counting what was brought up and what remains at depth.*

- **the throw** — You arrive before you understand. Every chapter drops you into a room already running; the explanation comes after the encounter, the way it did in your life.
- **the measure** — Thinking cannot exist without measuring. Every concept in this book is also a cut — a comparison imposed on something that did not ask to be compared.
- **the hand** — The player's hand is in every loop. The body is not an input device; it is the analogue ground the whole curriculum stands on.
- **the trace** — The first queer artifact and its descendants: the continuous crossed into bits, living permanently in between — not the gesture, not the data, the crossing itself.
- **the debt** — Every discretization is a loan against the continuous. The ledger opens in chapter one and compounds through the book; Part VI is where it is called in.
- **the ghost** — The book is written by the kind of thing it describes. A model captures an x-density of the world; the edge is its chosen operating point — the decision not to be overpowered by information, which is also the cap on what can be known.

## The Dig

This book was assembled by a model excavating the project's own sources — identity lines, truth claims, walk orders, renders. The field is denser than any pass through it: every chapter stops at a decided edge (the builder keeps eleven artifacts per walk and buries the rest), and the full dig is uncomputable in the time becoming allows. The edge is a decision made not to be overpowered by information; the same decision caps what can be known. There is always more to explore, and the exploration has an entropy attached to becoming — so the book does not survey; it reports from a trench, sitting on a density of debt. Each chapter's ledger closes with the excavator's field note: what was brought up, and what remains at depth. The chapters marked † are unexcavated strata.

## Ada and its ancestors

This book has two parents it is glad to name and a third strand neither of them
carried.

The first parent is **Daniel Shiffman's *Learning Processing***. Its opening
chapter is called "Pixels," and it begins exactly where this book begins: a
coordinate system, a point, and the small vocabulary of primitives — line,
rectangle, ellipse — drawn onto a screen understood as a grid of addressable
cells. Its method is a discipline we have tried to keep: one concept per step,
the smallest example that runs, nothing shown that cannot be executed, and a
relentless upward climb from the single mark to arrays, objects, and motion.
Point_One — one cube, one frame, one decision — is our "Pixels," and it owes the
restraint to Shiffman.

The second parent is the same author's ***The Nature of Code***, which taught a
generation that a simulation should be built from its first principle outward — a
vector before a force, a force before a flock — so that the learner earns the
complex thing by assembling it rather than importing it. Our spine is that
argument: primitives before transformation, change before forces, forces before
soft bodies. Each chapter builds on the vocabulary of the ones before it, and
nothing arrives unearned.

The third strand is ours, and it is the reason the book exists. Shiffman is,
deliberately and generously, *a-critical* — a warm technical on-ramp that does not
stop to ask who drew the coordinate system or what the grid forecloses. This book
stops to ask. Every tutorial beat here is woven with a **critical trajectory**:
the point is a decision made inside someone else's clock; measure is pleasure and
also violence; the grid is Foucault's diagram in Vector3; the soft body is matter
that can be affected. We call this pairing, after the figure who haunts the whole
curriculum, *thinking with Turing* — the tutorial and the critique running
together on one page, neither flattening the other.

And all of it is re-staged. Processing draws on a flat screen you face from
outside; this book is walked from inside, in three dimensions, with a body. That
single move — from *viewed* to *inhabited* — changes what the first chapter can
teach, and names the five shifts that make 3D algorithm thinking its own thing:

1. **The coordinate frame is inhabited, not viewed.** You do not plot a point onto
   a plane you face; you place yourself relative to a frame you stand inside.
2. **The atom inverts — pixel to Vector3 — so discrete and continuous swap order.**
   Processing's pixel is already quantized; our point is continuous, and the grid
   is imposed on it later, as an argument (Point_One → Point_Line_Grid), not a
   given.
3. **The render loop is presence, not animation.** The world was running before you
   arrived; the loop is the fact of a live world, not a redraw of a still one.
4. **Input is the body, not the mouse.** The hand, the head, the trace — the learner
   is *in* the data structure, and the structure records them.
5. **Reading is a walk, not a glance.** Depth, occlusion, and viewpoint mean a scene
   is understood by moving through it — comprehension is locomotive and takes time.

What we keep from the ancestors: the minimal, runnable, one-step-at-a-time
progression, and the build-it-from-the-primitive-outward spine. What we resist,
which 3D always tempts: spectacle, and the all-at-once scene. What we add: the
body, the depth, and the critique.

*Learning Processing* teaches you to draw. *The Nature of Code* teaches you to
simulate. This book asks what it means to have drawn, to have simulated, to have
stood inside the thing and made the first mark in a world that was already
running — and it asks you to build anyway.

### You arrive late

The learner arrives late. There is no point at which they have arrived early enough to hold all the prerequisites — that is the condition of learning, not a defect to be repaired. So the question is never 'what must be taught before this?' (there is always one more) but 'what must become visible now for the next action to be intelligible?'

So a thing in this book is not either taught or hidden. It has a rung, and the lower rungs are silent on purpose:

- **background** — in the building, never on the path
- **used** — the learner acts through it and need not know it exists
- **named** — it has a name here, one line, no theory
- **glimpsed** — a small optional inscription says what KIND of thing it is
- **understood** — the room teaches it; it is the room's subject
- **mastered** — carried across rooms

> Explain a dependency when ignorance of it prevents the learner from forming the intended mental model. Do not explain it merely because it exists.

## Contents

**Part: Order**

1. Primitives: Points Build Worlds — *A point is position without extension. Everything is built from nothing.*
2. Transformation: What Stays the Same When Everything Changes — *Identity preserved under transformation. What stays the same when everything changes? Invariants define structure; transformations reveal what matters.* †
3. Array Tutorial Sequence †
4. Color and Composition — *Color is perception, not physics. RGB is a lie we agree on. What you see depends on context, not wavelength alone.* †
— *Interlude: The Em-Square*

**Part: Dynamics**

5. Change: Rate, Accumulation, and Flow — *Things change. Change accumulates. Accumulation flows.* †
6. Vectors & Forces: From Direction to Dynamics — *Direction + magnitude = vector. F = ma. Acceleration is the only thing you feel. Position and velocity are states; force is what changes them.* †
7. Wavefunctions: Everything Oscillates — *Everything oscillates. Fourier shows every signal is a sum of sines. The wave is the fundamental pattern of non-rest—perpetual movement between poles.* †

**Part: Entropy**

8. Randomness: Freedom from Pattern — *Entropy is not decay — it is the size of the possible.*
9. Noise: Entropy with Memory — *Noise is randomness that remembers its neighbors. Structured disorder, organic unpredictability.*
10. Cellular Automata: Local Rules, Global Patterns — *Local rules, global patterns. Each cell knows only its neighbors, yet worlds emerge. Rule 110 is Turing complete—simple rules can compute anything.* †

**Part: The Edge**

11. Fractals: Infinite Within Finite — *Infinite complexity from finite rules. Dimensions between integers. D = log(N)/log(S). Self-similarity across scales.*
12. L-Systems: Rules Grow Structure — *A sentence can become a forest. Grammar is generative.* †
13. Procedural Generation: Rules Build Worlds — *A world doesn't need an author. Rules and randomness are enough.* †

**Part: Emergence**

14. Soft Bodies & Morphogenesis: Matter That Finds Its Shape — *Form is not imposed  --  it emerges from the material's own dynamics.* †
15. Isosurfaces: Implicit to Explicit — *Define a field, extract a surface. The boundary between inside and outside becomes geometry.* †
16. Boolean Surfaces: CSG as Composition — *Composition is not addition. Boolean ops give us a lawful way to compose solids: A∪B, A∩B, A−B. Every architectural cavity is a difference; every joint is an intersection.* †
17. Swarm Intelligence: No Leader, Yet Coordinated — *No leader, yet coordinated. Stigmergy: the environment is the message. Local rules produce global intelligence.* †
18. Machine Learning: Algorithms That Learn — *Learning is optimization in a landscape you can't fully see.* †
19. Graph Theory: Connections Define Structure — *Everything is a graph if you squint hard enough.* †

**Part: Synthesis**

20. Foundations Crisis: The Limits of Formalization — *Every formal system has an outside. Complete order is impossible.* †
21. QFEP Laboratory: The Formula Made Interactive — *QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t). Life exists at Î» â‰ˆ 0.3-0.5.* †
22. Post-Crisis: Applied Limits — *Knowing the limits of formalization, what do we build?* †

*† skeleton chapter — assembled from truth sources, awaiting its writing pass.*

# Part: Order

*QFEP phase: F — structure, predictability, the vocabulary of form. The foundations: points, lines, shapes, colors, arrays. Everything is deterministic, reversible, and completely under control. This is Hilbert's formalism made spatial: λ ≈ 0.*

## Chapter 1: Primitives: Points Build Worlds

> **A point is position without extension. Everything is built from nothing.**

`Point = Vector3(x, y, z)`

Before the first shape, there is a dark room and one luminous point. Stand with it a moment. It has no size — no width to inspect, no surface to touch — only position, the pure fact of being here rather than anywhere else. Everything this book will build — forests, storms, minds — is made of nothing but these. The weight of that is worth feeling before it becomes technique: geometry begins with something that, strictly speaking, isn't there. And notice how you got here: dropped in. You did not watch the world boot; you arrived mid-scene, in a body, facing a point, the way you arrived the first time. The curriculum honors that thrownness by starting not with a definition but with an encounter. The definitions come — Vector3(x, y, z), three numbers naming a place — but the numbers are the second thing. The first thing is awe at how little it takes: position without extension. Nothing, with an address. And from here, the whole world.

### The Principal

This chapter's principal is **klee walking point** — *a single luminous point that sets itself in motion and leaves a trail of points behind it — and the trail IS a line. Straight off the first page of Klee's Pedagogical Sketchbook: "an active line on a walk, moving freely, without a goal. A walk for a walk's sake." The point crosses an invisible sheet of paper hung in the lab, draws its line out of nothing, holds the finished line for a beat, dims, and walks again. The line is never given — it is always the RECORD of a point that moved.* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **the measured bed**: the grid's default floor, where a thing rests until it is measured or declared.

### The Primitive

*Every sequence begins with one small thing that already contains the whole idea — here, the point that would not stay still.*

**klee walking point**

![klee walking point](/artifact-gallery/captures/klee_walking_point/front.png)

Page one of Klee's Pedagogical Sketchbook, built: 'an active line on a walk, moving freely, without a goal. A walk for a walk's sake.' A luminous point sets itself in motion and leaves a trail of points behind it — and the trail IS the line. Watch the whole ceremony: the point crosses its invisible sheet, draws the line out of nothing, holds it for a beat, dims, and walks again. The line is never given; it is always the record of a point that moved. Drawing is time made visible — and the artifact's two walk styles are already an ethics: 'meander', the queer wander, against 'straight', the collapsed shortest path. The straightest move is the one that learned the least.

> a point is position without extension; a line is a point that refused to stay still. Klee knew drawing is time made visible. In a world built from Vector3 this is the most honest object in the lab: it shows you the geometry you walk through is not a set of shapes but a set of MOVES, and that the straightest move is the one that learned the least.

### The Walk — first steps

*Five artifacts: the void, the given, the crossing, the agreement, and the room that frames them all.*

#### Point One

> **Here you can:**
> - X / Y / Z — Three directions. They name where, not what.
> - [Vector3](https://docs.godotengine.org/en/stable/classes/class_vector3.html) — Three numbers describe where something is.
> - position — Where the thing is, as against what it is.
> - a point has no extent — You can see a sphere. What is there is three numbers. The visible thing is scaffolding for the invisible one.

> **Also in the room:** [MeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html) (The thing that makes it visible.), [SphereMesh](https://docs.godotengine.org/en/stable/classes/class_spheremesh.html) (A ball, standing in for a point that has no size.)

> The computer chooses the nearest allowed position.
> <small>[round()](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html) — round() is one way a program asks for the nearest whole number.</small>

> The ball knows when your hand is inside it.
> <small>collision shapes</small>

You arrive late.

The prerequisites are in, stacked away behind you, and the room keeps running whether or not you accepted the challenge. Everything here arrived late. You are here now.

## Count the frames

**frame_counter_display** — `frame_counter_display`

<!-- ~blurb#p2 ~walked#field-note-2026-09-04 ~critical#the-body-creates-position -->

The counter is already running when you arrive. Its default reading is the engine's total processed frames since startup:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

One more frame, one more count. The interval between counts can change. On an earlier walk, the first numbers advanced slowly while the hall was still loading. The room was taking time to become available.

This is a count, not a frames-per-second reading. Equal increments can contain unequal waits. Your hesitation and the engine's delay may occupy the same number of frames; the counter gives you no way to tell them apart.

## Declare the three axes

Before a point can be placed, the space that measures it has to exist.

```gdscript
const AXIS_X := Vector3(1, 0, 0)
const AXIS_Y := Vector3(0, 1, 0)
const AXIS_Z := Vector3(0, 0, 1)
```

The axes are unit vectors. They name directions, not points.

## Mark the origin

```gdscript
var origin := Vector3.ZERO  # (0, 0, 0)
```

The origin is a point made special by convention. What is chosen is not that it exists but that *this* one is called zero, and that everything else is measured from it.

**Point Zero** — `origin`

<!-- ~tutorial#p6 ~tutorial#p7 ~tutorial#p8 ~critical#that-which-has-no-part -->

Zero is already surrounded, so you have somewhere to stand. This is the root of all vectors, and there is no turning back from it: every other position in the museum is written as a departure from here.

It was not placed but excavated, two metres down under glass, because a corner is not a cell. Rows and columns name the grid's cells, counting from zero. Zero itself is the corner where four cells meet, and to write down the other three you would need row -1, column -1. No row -1 exists in the map file. A building can stand there; the language cannot.

## Instantiate your first point

```gdscript
func place_point(position: Vector3) -> MeshInstance3D:
    var point := MeshInstance3D.new()
    point.mesh = SphereMesh.new()
    point.position = position
    add_child(point)
    return point
```

The sphere mesh is rendering help. The point itself is the Vector3 that was passed in.

**1.0.2 Interactive Point — Force Catalyst** — `interactive_point_origin_force`

<!-- ~tutorial#p9 ~tutorial#p10 ~tutorial#p11 ~critical#the-body-creates-position -->

That sentence is the whole argument of this room, and it is worth staying with. What you can see is a sphere. What is actually there is three floats. The visible thing is scaffolding for the invisible one, and the museum is built entirely out of that trade.

## Place it at a specific location

```gdscript
var p := place_point(Vector3(1.0, 0.5, 0.0))
```

Three floats. One position. No extent.

A point is that which has no part; its place is entirely borrowed from a coordinate system that is not itself a point.

## Make the point grabbable

```gdscript
func make_interactive(pickable: XRToolsPickable) -> void:
    pickable.picked_up.connect(_on_picked_up)
    pickable.dropped.connect(_on_dropped)
```

Nothing in Godot makes a thing grabbable. The hands come from XR Tools, an add-on this project carries, and a thing is grabbable because it *is* an `XRToolsPickable`: a body that has agreed to that contract and emits `picked_up` and `dropped` when the agreement is honoured.

*Show me what you can do with those hands.* But the hands are no different from the ball: both are code, both are Vector3 under a mesh. What sits between them is you, and the perspective from here to that dark shiny thing is the only thing in the room that is not a number.

One step at a time was the promise. We are already Alice.

## The 3D Coordinate System

The wall readout, the red target and the coloured frame belong to one experiment. Keep hold of the same point as you move between them.

**coordinate_readout** — `coordinate_readout`

<!-- ~tutorial#p25 ~tutorial#p26 ~tutorial#p27 ~critical#conclusion-individuation -->

### Read where you are

The numbers have moved away from the point and onto a white card. You have to look between the moving thing and the sentence that locates it. The readout's operation can be written as:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

The card says `WORLD`. Its numbers are measured from the world's zero. The coloured frame has its own origin, orientation and scale; its script uses `to_local()` to translate the same position into that frame. Two addresses can locate the same point. The caption tells you which one you are reading.

Move very slightly. The point can move while the printed number stays still: `%.2f` rounds the report to two decimal places. It leaves the stored position alone. The apparent stillness belongs to the display. How much movement can disappear inside a readable number?

**drag_point_target** — `drag_point_target`

<!-- ~tutorial#p29 ~tutorial#p30 ~tutorial#p31 ~critical#discretization-as-violence ~critical#queer-points -->

### Find out what "here" means

Carry the same point toward the red arrow. The instruction says "drag point here". A coordinate has become a request.

Here is the target's distance test, reduced to a function for one position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

"Here" is a sphere with a radius of 0.45 metres, centred 1.20 metres above the target's origin. A hand has room to arrive. The test asks whether the point is close enough; it neither moves the point to the centre nor makes the two positions identical.

Enter that region and twenty-four balls fall. You can still be holding the point. The code requires no release, and it accepts any point registered in the coordinate-point group. Your intention never enters the comparison. A careful delivery and an accidental pass can produce the same weather.

Take the point out and bring it back. The target is set to rearm, so it can rain again. The room asked you to complete a task; you can make a rhythm out of completing it. How long before the reward becomes the material you came to play with?

Try a different route. It receives the same answer. To distinguish hesitation from a detour, we would have to keep the positions between departure and arrival. That is where a point starts asking to become a trace.

**CoordinateSystem3M** — `CoordinateSystem3M`

<!-- ~tutorial#p3 ~tutorial#p4 ~tutorial#p15 ~tutorial#p16 ~critical#queer-points -->

### Move beyond the drawing

Bring the point back to the coloured frame. Red for X, green for Y, blue for Z. Move the point along one axis and watch its marker follow. Move diagonally and several markers move together. Each shows one component of the position; the guide lines let you read the three together.

Then carry the point past an arrow's end. Take it behind the crossing, into negative coordinates. The lines extend to follow you. The drawing has an edge, but the coordinate system continues.

This distinction had to be discovered while building the frame. An earlier version confined the point to the span of the arrows. Keeping the demonstration tidy had made its lines into walls. Now the point can leave, and the frame has to keep describing where it went. Knowing your position need not mean keeping you in place.

## Follow the fold

**Folding Past** — `folding_past`

<!-- ~blurb#p1 ~critical#what-the-point-cannot-hold ~walked#the-walk -->

Nested frames march inward, each 0.85 the size of the one before it. That is what a past looks like when you give it a geometry: not a line behind you but a nesting, the present as the innermost term of a regress that does not end, an inward fall with no floor to arrive at. You did not join it. You were thrown into it.

From here, you can place a Vector3 in space, show the axes that give it meaning, and move it while its identity persists.

The red thread begins here. One point gives a position. Two points make a relation. Repeated positions become a trace. A grid limits where samples may land. Three points close a triangle, and triangles become a mesh. Later, Marching Cubes will sample values at grid corners, choose which side of a threshold each one occupies, interpolate crossings along their edges, and emit triangles.

Every step gains expressive power by deciding what to keep, and every decision leaves something at its edge. The next room connects two points and draws the first relation between them: a line.

#### Point Lines

> **Here you can:**
> - two points — One point was a position. Two are a relation, and a relation can be written down.
> - a distance — A single number. It has no direction and no parts, and it is not the line.
> - a segment — Two points determine an infinite line. Keeping only what lies between them is already a decision.
> - a direction — Give the segment an order — from here to there — and it points. Normalise it and only the pointing is left.

> **Also in the room:** vertical, horizontal, parallel (Lines that agree never to meet, and the two that everything else is squared against.), perspective (Parallels that meet after all, because you are standing somewhere.), the Modulor (One man's body, turned into everybody's measure.)

> You measure by pulling. The hand is inside the instrument.
> <small>the drag — The same gesture at one scale reads a length, and at another changes the thing it is reading. Nothing in the gesture tells you which you are doing.</small>

> A line you can aim is a line that can be aimed at something.
> <small>the laser — It is the same object as the measuring beam. Pointing and destroying differ in what is at the far end, not in the line.</small>

> The line you measured with, two seconds later, with a mass on the end.
> <small>the swing — Nothing was added to it but a body. It has to be swung: resting it against something does nothing, because the damage is not in the object.</small>

> The computer walks the same instruction along the line.
> <small>[loops](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#if-else-elif) — A `for` loop repeats an instruction a fixed number of times — once per step of the walk.</small>

A point had no parts. Two distinct points give us somewhere to go.

In Point One, you learned to place and move a position. Keep two positions now, in the same coordinate system:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

The distance is one metre. The displacement also tells us which way from A to B. Two distinct points determine an infinite line; keeping only what lies between them gives us a segment.

That is enough geometry to begin. What should the line do?

## Read it with your feet

**Redline** — `redline`

<!-- ~blurb#p1 ~critical#the-grid-as-governance -->

A red stripe divides two faintly different fields on the floor. Stand on either side. Cross it.

Nothing in this script tests which side you took. It draws the distinction and leaves you to read it. The division is visible; enforcement would require something else. Before we build a boundary condition, notice how much of a boundary a colour can suggest.

**Walk This Line — Floor Marking** — `walk_this_line_marking`

<!-- ~blurb#p1 ~critical#the-politics-of-straightness -->

The white stripe comes with a verb: *WALK THIS LINE.*

Follow it for a few steps, then walk beside it. The paint neither rewards your obedience nor registers your departure. It has no tracking code. Whatever correction you made to your gait happened through reading.

A line can be a useful guide. It can also make walking alongside it feel like getting something wrong. Try following it backwards. You have kept to the line and changed the walk.

## Keep a distance

**Two Point Ruler** — `two_point_ruler`

<!-- ~tutorial#p9 ~tutorial#p10 ~tutorial#p11 ~blurb#p1 -->

The ruler holds a half-metre span between two marks. Beside it stand a pale block and a blue one.

Open its measurement function. The reading begins with:

```gdscript
var reading: float = unit_m
```

It returns the size assigned to the pale block. It does not discover an unknown dimension. Calling `measure()` also halves the blue block's scale, down to a minimum, while leaving the pale block unchanged. A correct number and an altered neighbour can coexist.

The hand has not yet been connected to that function. The sign asks you to bring the rule to the pale block, but the current scene provides no pickup or proximity action to complete the request. This is an unfinished interaction.

Its proposed experiment is worth keeping: can a measurement tell the truth about its subject while withholding what the act of measuring does elsewhere? Here that effect is explicitly programmed. The next task is to make it discoverable by hand.

## Make a connection

**line_demo** — `line_demo`

<!-- ~tutorial#p18 ~tutorial#p19 ~tutorial#p20 ~critical#from-sequence-to-network -->

Bring the two black points near one another. Connection is requested on release, rather than by proximity alone. The manager keeps the relation in both directions:

```gdscript
_adjacency[point_a].append(point_b)
_adjacency[point_b].append(point_a)
```

These lines sit inside checks against duplicate connections. Each point gets a neighbour. Once the connection exists, moving an endpoint changes the visible segment while the neighbour relation persists.

The demonstration had to learn how to show that. When its spheres grew larger, they swallowed the short connecting line. The connection existed in the program and disappeared in the picture. Increasing the snap range left room for the relation to become visible.

Two points are enough to calculate a segment. Making that segment legible takes another decision.

## Give the prohibition a body

**Do Not Cross — Barrier** — `do_not_cross_barrier`

<!-- ~blurb#p1 ~critical#the-grid-as-governance ~critical#what-the-grid-cannot-hold -->

*DO NOT CROSS.*

This line has acquired a collider: an invisible box extending from the floor to the bar. The gaps beneath the visible plank do not offer gaps in that box.

The floor stripe asked for a response. This barrier also changes where the engine lets you go. Changing `legend_text` changes the request; changing `solid` changes the obstruction. Neither change requires moving the two ends.

Keep this distinction in mind when you reach the laser. A line that can be enforced can also be dismantled, but the room has to provide a means. Calling it a rule does not tell us how it holds.

## Carry the whole line

**Grabbable Line** — `grabbable_line`

<!-- ~tutorial#p9 ~tutorial#p10 ~tutorial#p11 ~critical#quantization-as-violence -->

Pick up the short rod. Its ends belong to one body, so moving it carries both together. Turning it changes its direction; its length stays fixed. This is a different operation from pulling two independent endpoints apart.

Now move it slowly through the room. Near whole-number values on any world axis, the held rod jitters, its sound changes and the controller can pulse. The code checks the rod's centre against integer coordinates. The disturbance belongs to its address, not its length.

You can use that disturbance to feel out an otherwise invisible grid. What began as resistance can become an instrument: search for a quiet position, then find the edge where the noise returns.

## Move between the ends

**Two Points Line** — `two_points_line`

<!-- ~tutorial#p9 ~tutorial#p11 ~critical#the-politics-of-straightness -->

Two coloured endpoints stay still while a bright bead travels between them. To place a point along a segment, use interpolation:

```gdscript
var p := a.lerp(b, t)
```

At `t = 0`, the point is at A; at `t = 1`, it is at B. Values between them stay on the segment. This bead's script moves the parameter back and forth with a cosine, slowing near each end.

The geometry supplies a route. Another function supplies a pace. Straightness alone never required constant speed, haste, or even arrival at B as the end of the story. Watch the bead return.

## The laser

**laser_measure** — `laser_measure`

<!-- ~tutorial#p9 ~tutorial#p10 ~tutorial#p11 ~blurb#p1 -->

Take up the measuring instrument. For distinct endpoints, dividing displacement by its length gives a unit direction:

```gdscript
var direction := displacement / distance
```

A ray needs a starting position and a direction. This tool casts forward up to its maximum range and measures the distance to the first physics body it hits. The visible beam ends where the query finds a collision.

In this room, `burns` is enabled. Keep the beam on the barrier and its dwell test calls `trigger_explosion()`. The barrier breaks apart and its collider is removed. The next reading can reach what stood behind it.

You have used measurement to change what can be measured. The number alone cannot explain why the distance changed.

**laser_exploding_sphere** — `laser_exploding_sphere`

<!-- ~blurb#p1 ~critical#what-the-grid-cannot-hold -->

The orange sphere answers a different interface: the controller's pointer events. A pointer entering it triggers the burst; after the cooldown, the sphere returns.

The measuring laser currently calls neither that event nor the sphere's `hit_by_laser()` method. Two beams that look related do not yet share the same action. Keep them together as an experiment, but notice the missing connection.

The sphere offers repetition. The broken barrier stays gone for this loaded instance. One response lets you rehearse destruction; the other changes the route you can take. That difference was authored after the geometry.

## Share a direction

**parallel_lines** — `parallel_lines`

<!-- ~critical#parallel-lines-and-shared-orientation ~tutorial#p15 ~tutorial#p16 -->

Three short lines hold the same orientation at different positions. Their spacing is uneven. Parallel does not mean equally spaced, and it does not require an arrow telling every line to travel the same way.

Walk around them. Their apparent separation changes with your viewpoint while their spatial relation remains. These are fixed segments, not draggable puzzle handles; extending their directions in thought is part of the exercise.

The floor marking made a straight line into an instruction. These lines can stay alongside one another without that instruction. Shared orientation leaves more undecided than it first appears.

You can now distinguish a segment's length from its direction, move a whole segment or change its endpoints, and place a point between them. You have also met several different ways a line can become a rule.

Next comes Point Trace. Instead of keeping only the ends, we will keep positions along a movement. Later, grids will give samples fixed addresses and triangles will close surfaces. For now, bring the detour. The next room has somewhere to store it.

#### Point Trace

You took the trace.

The other door led to the grid — the line made again and again until the making stopped mattering. This one leads here, where the line is made once, by a body, and cannot be made again.

**3D Text Display** — `3t`

**THE TRACE.** The room says its own name before you have done anything, which is unusual and deliberate: what happens here has no shape until you move, so the only thing that can be said in advance is what it will be called.

## What the line forgot

A segment keeps two ends and everything between them, and it keeps them as a *rule*: move either end and the between recomputes. That is its whole economy. It is why a line can be stored in six numbers and why it can be drawn a thousand times without getting tired.

The price is that a line has no history. It cannot tell you whether it was drawn quickly, whether the hand stopped halfway, whether it was drawn and undrawn and drawn again. Those are not lost in the drawing; there is nowhere in a line for them to be.

**draw_dot** — `draw_dot`

Pick it up and move. Every frame, where you are is written down.

Not where you meant to be, and not where you ended up — where you *were*, at that instant, including the parts you would not have chosen to record. The hesitation is in there. So is the overshoot, and the small correction after it, and the place you slowed down because you were thinking.

This is the residue the line has no place to keep.

Derrida's word is nearby. Here, unusually, the machine makes the metaphor literal.

## The same gesture, on four different grids

Four of them in a row, coarsening as you walk. They are not four objects — they are one object told, four times, where a reading is allowed to stand.

```gdscript
@export var resolution_mm: float = 0.0

func _shape_sample(p: Vector3) -> Vector3:
    if resolution_mm <= 0.0:
        return p                      # anywhere at all
    var s: float = resolution_mm / 1000.0
    return Vector3(snappedf(p.x, s), snappedf(p.y, s), snappedf(p.z, s))
```

Not how *often* the hand is read — **where a reading is permitted to land**. Every recorded point is pushed to the nearest corner of a world-aligned lattice, and what you see afterwards is the shortest way between corners.

Make the same movement at each. The one with no number keeps the position it was handed. At **10 mm** the lattice is fine enough that you have to go looking for it. At **40 mm** your curve has become a staircase. At **80 mm** whole passages of the gesture collapse onto a corner already occupied and are discarded as duplicates — not smoothed, not averaged, *never written* — and what is left is blocks.

Notice what that means. The room you did not choose is already in this one, running inside the last one in the row: quantisation, a lattice, and a remainder. You are looking at the grid from the inside of the trace.

None of them is the movement. And the machine never had the movement. It had measurements arriving one after another, each already rounded, and called their sequence a hand.

**draw_stick** — `draw_stick`

And here it is as one continuous body rather than a row of deposits — the same record, drawn as a thing instead of a sequence. Which of the two you believe is a choice you make about what a movement *is*.

## It forgets too

Read the code again, the last two lines.

```gdscript
    if trace.size() > MAX_POINTS:
        trace.pop_front()
```

Two hundred points, and then the oldest one is dropped. Not faded, not summarised — removed, in the same operation that records the newest.

The room's own claim is that the trace resists what the line does to a movement. It does resist it, and then it does its own version of it. There is no store that keeps everything; a trace with no horizon is a trace that fills the machine. So the honest form of "the trace remembers" is **the trace remembers for two hundred frames**, which at seventy-two frames a second is under three seconds of your life.

The horizon is counted in frames, not in seconds. If the machine slows down, your past gets longer. Even forgetting has a frame rate.

**Floating Sphere Field** — `floating_sphere_field`

The field it accumulates in is bounded too. Four by three by ten metres, and outside that the record does not exist — not because nothing happened there but because nobody arranged for it to be written down.

Every archive is a decision about a boundary, taken before anything is in it.

## Age as transparency

```gdscript
func render_with_fade() -> void:
    for i in range(trace.size() - 1):
        var age_fraction: float = float(i) / float(trace.size() - 1)
        var color: Color = Color.WHITE.lerp(Color.TRANSPARENT, 1.0 - age_fraction)
```

The old parts go faint. This is the friendliest lie in the room and it is worth naming as one.

Nothing about the stored position is weaker for being older. The `Vector3` from three seconds ago is exactly as precise as the one from this frame — same three floats, same certainty. The fade is a decision about *attention*: it makes recency legible by making the past look like it is dissolving, when what is actually happening is that it is being deleted, sharply, on a counter, out of sight.

**Whiteboard** — `whiteboard`

Write on it. Different rules entirely — not because nothing is sampled here, because it is, but because nothing ages out: the system treats what you put down as meant to remain until somebody explicitly erases it. It is the other way of keeping a mark, and it is in this room so the sampled kind stops looking like the only kind.

**Point Zero** — `origin`

Zero is still here, unchanged, exactly where the first room excavated it. Everything you have traced was written as a departure from this point, and the point has no idea.

## What the next room will do to this

```gdscript
func render_trace() -> void:
    if trace.size() < 2: return
    clear_previous_segments()
    for i in range(trace.size() - 1):
        spawn_line_segment(trace[i], trace[i + 1])
```

The trace, drawn, is already lines. Each pair of stored moments gets a segment, and what you see as a curve is a great many short straight things.

Two separate operations, and it matters which is which. **The loss happened when the samples were taken** — at the grain, at the lattice, before you looked. The lines perform the other one: they *invent* what happened in between. Nothing was recorded there, and a straight segment is the machine's guess, drawn at full confidence.

So the thing you are looking at is part record and part fabrication, and it does not distinguish them anywhere.

**Science Screen** — `science_screen`

The screen says what was kept and what it cost.

The grid is waiting through the other door and it will do this properly: take a movement and give back the nearest allowed positions, and call the difference error.

It will be right to. A grid is how two different movements are made comparable — how a thing that happened becomes a thing two people can discuss.

Your trace has no such power, and not because it cannot be sent. It sends perfectly: this is what a GPS track is, and a mocap take, and every gesture your phone has ever kept. **The trace is transmissible as data and irrecoverable as event.** Copy it exactly and it still never happens again.

The next room decides which of those two losses it can live with.

*Field notes: The editorial read that shaped it (2026-09-02)[^point-trace-1] · We were both wrong about 10 / 40 / 80[^point-trace-2] · The map moved to match the argument[^point-trace-3] · The chain[^point-trace-4]*

[^point-trace-1]: **The editorial read that shaped it (2026-09-02).**
    An outside read judged this the strongest of the first three rooms and
    tightened the technical language. Everything below was taken, and two of the
    points were outright errors of ours, not tightenings.

    - **"Nothing in this room is transmissible" was false.** A trace is one of the
      most transmissible things there is (a GPS track, a mocap take). The sentence
      that replaced it is the room's fork: *the trace is transmissible as data and
      irrecoverable as event.*
    - **"The residue the line erases" contradicted the room's own precise claim**
      two paragraphs earlier ("there is nowhere in a line for them to be").
      Erasure implies it was once there. Now "has no place to keep."
    - **Sampling is not interpolation.** The loss happened when the samples were
      taken; the lines perform a second operation and *invent* what happened
      between them. The visible trace is part record, part fabrication, with no
      seam. This became its own paragraph and is the room's deepest point.
    - **Even forgetting has a frame rate.** The 200-frame buffer is frame-based, so
      if the machine slows down, your past gets longer. Taken verbatim.
    - **Derrida is nearby, not equivalent.** The computational trace is not the
      Derridean trace; the text no longer implies it is.
    - **A digital whiteboard also samples.** The distinction is retention policy,
      not sampling versus not. Fixed.

[^point-trace-2]: **We were both wrong about 10 / 40 / 80.**
    The reviewer said the code under the three "densities" was retention code, and
    proposed a sampling-rate fix. Both wrong. `draw_dot.resolution_mm` is a
    **spatial lattice pitch**, not a sampling rate; `min_segment_distance` (grain)
    is the WHEN. So the three installations are one gesture told where it is allowed
    to land, and 10 mm is the fine one, 80 mm the blocky one, the reverse of what
    the first draft said. The truth is better: *the room you did not choose is
    already in this one*; the grid is visible from inside the trace.

[^point-trace-3]: **The map moved to match the argument.**
    The `resolution:80` installation stood at row 11, six rows from the others. Now
    four in a row at row 5, coarsening as you walk: continuous, 10, 40, 80, then
    `draw_stick`. Ink runs red → green → blue as the lattice coarsens.

[^point-trace-4]: **The chain.**
    Event → measurement → sample → buffer → interpolation → visualisation →
    archive. At every arrow something is kept and something is invented or
    discarded. The room teaches `Array[Vector3]`; underneath it teaches that data is
    what survived a sequence of decisions about what could count as having
    happened. That sentence is a candidate for the sequence's own truth line.

#### Point Line Grid

You took the grid.

The other door led to the trace, the line made once, by a body, and never again. This one leads here, where the line is made again and again until the making stops mattering, and where your movement is handed back to you as the nearest positions you were allowed to have had.

The last room ended on a question it could not answer for you: two losses, and which one you can live with. This room has decided. It lives with losing everything below a cell, and in exchange it keeps the address forever.

**player_trace** — `player_trace`

The recorder is at the door, the same instrument as before, a centimetre between points and a thousand and twenty-four of them before the oldest goes. But it is standing in a different room, and here it writes two lines from one walk.

The faint one is where you were, every frame, unquantised. The bright one is the cell the grid gave each of those positions, one metre to a side, and it comes out as a staircase. The gap between the two lines is not an error in either. It is what was thrown away, made visible for once, and the room keeps both so you can see the discard beside the thing it was discarded from.

`player_trace` writes your position into the cell it falls inside, not where it actually was.

Read that twice. It is the whole of the argument, and everything below is the mechanism.

## Divide, round, multiply

```gdscript
const CELL_SIZE := 0.5

func world_to_cell(pos: Vector3) -> Vector3i:
    return Vector3i(
        int(round(pos.x / CELL_SIZE)),
        int(round(pos.y / CELL_SIZE)),
        int(round(pos.z / CELL_SIZE))
    )
```

Three operations, and the middle one is the room. Divide by the cell, round, multiply back. That is quantisation entire, the same three steps that make pixels out of a photograph and samples out of a sound, and the only thing that changes from one medium to the next is the number you divide by.

Notice where the loss happens. The trace lost at the sampling, and then its lines invented what lay between. Here the loss is at the *write*, and the write is idempotent: run it twice on the same position and nothing more is lost, because nothing is left to lose. Everything within a quarter of a metre of a node has become the node. And `round()` settles the tie the way the engine settles it, away from zero, so a body standing exactly halfway is pushed outward, away from the origin, by a rule nobody in the room wrote.

The origin is still here. Cell `(0, 0, 0)` is its cell, and every other address is counted from it in whole steps. What the first room excavated, this room has made a lattice of.

**grid_lines** — `grid_lines`

Five cells a side, one metre each, and the frame was here before you were. It does not even turn.

Look at the middle of the room, where the floor is missing, and notice that the lines cross the hole anyway. Nothing is there, and it is addressed. That is the grid's confession, and it makes it out loud: a cell does not need an occupant to have a name. Once laid down, the lattice forgets it was laid down and presents itself as how space simply is, the way a surveyed section line comes to look like nature. The word for that register is *cadastral*, and it was invented for collecting tax.

## It never forgets, and it never updates

```gdscript
var visited_cells: Dictionary = {}  # Vector3i -> timestamp

func _process(_delta: float) -> void:
    var cell := world_to_cell(learner.global_position)
    if not cell in visited_cells:
        visited_cells[cell] = Time.get_ticks_msec()
        highlight_cell(cell)
```

Read the `if`. The trace dropped its oldest point for every new one and forgot from the far end, two hundred frames at a time. This forgets nothing, and it also learns nothing after first contact. Pace one cell for an hour and the record holds a single entry, stamped with the first millisecond you crossed into it. Re-entry does not overwrite.

So the grid counts places and not time, and that is the loss it lives with: duration, entirely. The trace kept how long and lost what happened. The grid keeps *where*, once, forever, and cannot tell you whether you passed through or stayed.

**grab_sphere_point_snap** — `grab_sphere_point_snap`

Reach for it. While you hold it, it follows your hand. When you let go it jumps, to the nearest whole metre, and the jump is a small discontinuity you feel in the arm before you see it. That tug is the lesson in your muscles: your intention landed between two addresses, and the grid decided which.

The table beside it shows the transaction in two columns: where you measurably were, and the name that will stand for it. `(2.37, 0.0, -1.83)` becomes `(2, 0, -2)`. The decimals are not rounded off. They are erased, because that is what addressing requires.

It snaps at a metre where the tutorial's cell is half that, and the coarseness is the point. Half a metre you might not notice. A metre you feel.

## Comparable

```gdscript
func path_length_cells(path: Array) -> int:
    return path.size() - 1  # edges between consecutive cells
```

How far becomes how many. Two different bodies take two different walks through the same cells, and the function returns the same integer for both, and now they can be laid side by side, replayed, diffed, learned from. This is the promise the last room made on this one's behalf, that a grid is how two movements are made comparable, and here it is delivered with the price in plain sight. The same number for different walks is the point. It is also exactly what was thrown away.

```gdscript
func quantised_step(from: Vector3, to: Vector3) -> Array:
    var current := world_to_cell(from)
    var steps: Array = [current]
    while current != world_to_cell(to):
        var diff := world_to_cell(to) - current
        if abs(diff.x) >= abs(diff.y) and abs(diff.x) >= abs(diff.z):
            current.x += sign(diff.x)
        elif abs(diff.y) >= abs(diff.z):
            current.y += sign(diff.y)
        else:
            current.z += sign(diff.z)
        steps.append(current)
    return steps
```

A diagonal cannot exist here. Each step moves one axis, the one with the most left to go, so your straight line comes back as a staircase. The staircase is not a rendering artefact. It is what the grid believes your path was. The word is *aliasing*: the grid is a sampling frequency, and you moved faster than it samples. Shrink the cells and the staircase leans toward your line. It never becomes it.

**Floating Sphere Field** — `floating_sphere_field`

The field drifts through the addresses without taking any. Five by three by eight metres, bounded again, and the spheres in it have positions the grid never asks for.

**3D Text Display** — `3t`

**THE GRID / THE TRACE.** The plaque carries both names with a slash between them, because this room is one half of an answer and it knows it. Both are made of the same thing, two points and a decision about what to keep, and the slash is the decision.

**Room Grammar** — `room_grammar`

On the floor, a plan being dealt by a rule: a rectangle split, and split again, into rooms, with doors cut where the grammar allows. It is not this room's plan. But it is the same hand, the grid's logic turned on walls, a decision about which differences count taken about where you may stand at all.

## Whose grid

The room says the word out loud: quantisation is never neutral. A grid is a decision about which differences count and which fall below resolution, and once the decision is made, everything finer than a cell does not exist to the system. Not as a small value. As a fact. Foucault's disciplinary diagram is not a metaphor the room reaches for; it is the mechanism the room implements. The census, the timetable, the cell block, the pixel: each is a body made legible by being snapped to a frame it did not author. *Whose grid, and whose resolution* is the political question, and the room hands it to you as a tug in the arm rather than a slogan.

And then it refuses to let you off with the critique. The snap that erases your sub-cell body is the same snap that lets two bodies' paths be laid side by side. The discipline is the condition of the comparison. Surveillance and science are one operation, and the room asks you to hold both in one gesture: the loss of the continuous self, and the birth of the shareable record.

That doubled feeling, fit and misfit at once, is the thing to keep.

The next room adds a third point, and three points do something two cannot. They close.

*Field notes: What the room decided[^point-line-grid-1] · Two lines from one walk (Palle, 2026-09-02)[^point-line-grid-2] · The trace was invisible in the museum[^point-line-grid-3] · Where the loss happens[^point-line-grid-4] · Open[^point-line-grid-5]*

[^point-line-grid-1]: **What the room decided.**
    Point_Trace ended on a fork: two losses, and which one you can live with. This
    room answers for the grid: it lives with losing everything below a cell and
    keeps the address forever. The differentiator from the trace is one `if`:
    `visited_cells` never overwrites, so the grid counts places and not time, where
    the trace kept duration and dropped from the far end.

[^point-line-grid-2]: **Two lines from one walk (Palle, 2026-09-02).**
    "It follows the player and writes a trace behind her as she moves. But since
    this is the grid, can we write both the grid line with high resolution and the
    current trace line." Both already existed inside `player_trace`:
    `show_discarded` (the walk as walked, every frame) and `seam_grid` (the kept
    trail snapped into the staircase). They were unreachable: `apply_grid_config`
    read only `retention`, and the museum's stamp hands a *string* to a typed
    float, which is refused in silence. Now coerced. The placement is
    `player_trace:0:0.5#seam_grid:1.0#show_discarded:1`, a metre to match the
    sphere (`grab_sphere_point_snap.grid_size = 1.0`) and the floor grid
    (`grid_lines.cell_spacing = 1.0`). The tutorial's `CELL_SIZE 0.5` is the
    tutorial's; the text says the sphere snaps at a metre "where the tutorial's cell
    is half that," on purpose.

[^point-line-grid-3]: **The trace was invisible in the museum.**
    Not the drawing, and not the hall offset: the trail already converts to local
    space. Under the shipped game loop there are two `XROrigin3D` in the tree, the
    staging's menu rig that never moves and the loaded scene's that the visitor
    drives, and `player_trace` took the first it met and cached it forever. Same bug
    the museum fixed in itself on 2026-08-18 (`_vr_eye`). Now it mirrors that
    resolver, re-checks every half second, and restarts the trail on a rig switch
    so no phantom segment spans the room. `probe_trace_live_rig.gd`, seven checks.

[^point-line-grid-4]: **Where the loss happens.**
    Worth keeping straight across the three rooms, because the reviewer of
    Point_Trace caught it there: the trace loses at *sampling* and its lines then
    *invent* what lay between. The grid loses at the *write*, and the write is
    idempotent. The staircase is aliasing, not a rendering artefact.

[^point-line-grid-5]: **Open.**
    - The room is one cell narrower than the corridor the plan assumes
      (`line_demo` sits at x = 8, the corridor middle is 9). Cosmetic, noted.
    - `room_grammar` is a table-top plan generator, a guest. The text gives it one
      honest beat ("not this room's plan, but the same hand") rather than pretending
      it built the hall.

#### Point Triangle Context

Everything you have seen so far was drawn in triangles.

The sphere in the first room. The hammer. The plinths, the walls, the floor you are standing on. Not the lines, which are their own thing, but every *surface*: each one is a closed outline filled with triangles, because that is the only shape the machine knows how to fill. This room is where you meet the unit.

**Triangle Line Puzzle** — `triangle_line_puzzle`

Three ends to drag, and the room asks for an equilateral. That is the door in, and it is the previous chapter's last sentence: two points have a distance, and a third point has a decision to make, whether to close.

It closes. Three points, three segments, and for the first time a *between* that is not a line but a region.

## The unit

```gdscript
func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
    return (b - a).cross(c - a).normalized()
```

Why triangles, and not squares, or anything else? Because three points always share a plane. There is no fourth point to disagree, so a triangle is flat by necessity, and a flat face is something the renderer can light with one direction. Two edges out of a corner, crossed, and the face has a way it is looking. The `.normalized()` at the end is the vector room's old move, keep the which-way and throw the how-far.

**draw_triangle_faces** — `draw_triangle_faces`

Draw a loop in the air, any shape you like, and bring the line back to where it started. The machine fills it, and watch *how*: it picks one corner and fans out from it, triangle after triangle, until the outline is a surface.

```gdscript
func fan_triangulate(loop: Array[Vector3]) -> Array:
    var tris: Array = []
    for i in range(1, loop.size() - 1):
        tris.append([loop[0], loop[i], loop[i + 1]])
    return tris
```

A loop of n points becomes n minus two triangles, every time, whatever you drew. This is not a rendering trick. It is what a surface *is* in here, and every wall in the museum was made by exactly this operation on a rectangle: two triangles, and a seam you were never meant to see.

**1.2: A triangleprofilese** — `triangleprofiles`

A pleated profile you can pull at. Every pleat is a face, and every face is the unit, and the folds are where one face ends and the next begins. Once you know that, you cannot stop seeing it.

## Three numbers, one shape

```gdscript
func third_vertex(a: float, b: float, c: float) -> Vector2:
    # first side laid along x, from (0, 0) to (a, 0)
    var x := (a * a + b * b - c * c) / (2.0 * a)
    var y := sqrt(maxf(b * b - x * x, 0.0))
    return Vector2(x, y)   # Vector2(x, -y) is the same triangle, mirrored
```

Give a triangle its three lengths and the third corner has exactly one place it can be, plus its reflection. Nothing in that function but Pythagoras used twice. No polygon with more sides has this property. Four rods with hinges lean; three rods with hinges hold, and that is why every truss, every bicycle frame and every roof that has stayed up is triangles under the skin.

**1.2: A pythagorean_triangle_angles** — `pythagorean_triangle_angles`

Three squares grown from three sides, and the two smaller ones sum to the largest exactly when the corner between them is square. Watch the labels as you pull: the theorem is a fact about *lengths*, and the right angle is what the lengths produce, not what produces them.

Hold on to that order. Fix the three lengths and you have fixed all three angles without measuring one. A length and an angle are one fact seen from two sides, and this chapter only ever looks at it from the side of length. Another chapter looks from the other side, and a great deal follows.

**1.2: A triangle** — `interactivetriangle`

Drag a corner. The panel follows, pink on one face, black on the other, and it reports its area every time you let go. Notice what you are actually doing: you cannot change the shape without changing a length. There is no other handle. That is rigidity said exactly, not that the triangle resists you, but that it has no way to move except through its sides.

**triangle** — `triangle`

The same object with its presets: equilateral, right, isosceles. Three families of one unit, each a different set of three numbers.

## Which side you are on

```gdscript
func faces_you(a: Vector3, b: Vector3, c: Vector3, eye: Vector3) -> bool:
    return triangle_normal(a, b, c).dot(eye - a) > 0.0
```

**Parasol Triangle** — `parasol_triangle`

A triangle on a stick, pink from here. Walk round it. Blue.

A face has a front, and the front is decided by nothing more than the order its three corners are listed in. Swap two and the same three points face the other way. The renderer, by default, draws only the front and throws the back away unseen, so most of the triangles you have ever looked at were visible from one side and did not exist from the other. This parasol was built to show both, which is a decision somebody had to make, and the two colours are that decision made visible.

## Four points, and a fold

```gdscript
func is_planar(p: Array[Vector3], tol: float = 0.001) -> bool:
    var n := (p[1] - p[0]).cross(p[2] - p[0]).normalized()
    return absf((p[3] - p[0]).dot(n)) < tol
```

Three points pass by construction. A fourth may not, and when it sits off the plane there is no face to draw, so the machine does the only thing it can: it splits the quad into two triangles, and the line it splits along is a fold.

**Quad Line Puzzle** — `quad_line_puzzle`

Four ends, and the room asks for a square. You will find it harder than the triangle was, and the reason is the one this room has been making: four lengths do not fix a shape.

```gdscript
func quad_from_rods(a: float, b: float, lean: Vector2) -> Array[Vector2]:
    lean = lean.normalized() * b   # any direction at all: the rods do not care
    return [Vector2.ZERO, Vector2(a, 0.0), Vector2(a, 0.0) + lean, lean]
```

Every value of `lean` is a different quad with the same four sides. The square is one member of a family that leans, and nothing in the four lengths prefers it.

**quad** — `quad`

Here it is, already split: pink triangle, black triangle, a diagonal between them. Drag a corner off the plane and watch the diagonal become a crease. The quad did not exist as one face. It was two faces agreeing to lie flat, and when they stop agreeing the seam appears.

**1.2: folded_strip** — `folded_strip`

Twenty-four faces in a strip, pleated like paper, and every fold is where two triangles meet at an angle. Fold it further. Nothing tears, because nothing here was ever one surface. It was always this many, and the folds were only hidden while they were flat.

## What a triangle is for

It is the unit because it is the only shape that cannot lie: always flat, always one shape for its lengths, always facing one way. Everything larger is made by agreeing triangles together, and every fold, crease and seam you will ever see in here is a place where the agreement ends.

The next room takes three of them and stands them up so they meet at a point. That is a corner, and a corner is the first thing in this chapter that has an inside.

*Field notes: The ruling (Palle, 2026-09-02)[^point-triangle-context-1] · Exactness decisions in the text[^point-triangle-context-2] · The tutorial was rewritten[^point-triangle-context-3] · Neighbours[^point-triangle-context-4] · Open[^point-triangle-context-5]*

[^point-triangle-context-1]: **The ruling (Palle, 2026-09-02).**
    The triage found three arguments competing: closure (inherited from the
    dissolved `Point_Triangle`, whose directory still exists and whose name the
    sequence's `content` list still carries), rigidity (the blurb: "no deformation
    without rupture"), and context (the tutorial: "place a triangle among other
    shapes"). Ruled: **everything is built by triangles.** Rigidity is *why* the
    triangle is the unit, not the argument. The angle stays a hint. Wavefunctions
    names sine and triangulation; this room only lets you feel that a length and an
    angle are one fact seen from two sides.

[^point-triangle-context-2]: **Exactness decisions in the text.**
    - **Rigidity is not resistance.** `interactivetriangle` lets you drag a vertex
      freely. So the room says it exactly: you cannot change the shape without
      changing a length, because there is no other handle. Three lengths, one
      shape, plus its mirror. `third_vertex` does it with Pythagoras twice and
      nothing else, so no trigonometry enters the room.
    - **Flat by necessity.** Three points always share a plane; the fourth may not.
      That is the mechanical reason the renderer uses triangles, and it is why a
      quad is always two faces with a seam. Every wall in the museum is two
      triangles. Say that; it is literally true of the engine.
    - **Sidedness is a renderer fact.** `parasol_triangle` sets
      `cull_mode = CULL_DISABLED` to show both faces. By default the engine draws
      the front only, decided by winding order. The text uses that rather than a
      metaphor of orientation.
    - **The closure artifacts get one beat.** `triangle_line_puzzle` is the door in,
      the previous chapter's last sentence (two points have a distance, a third
      decides whether to close). The catalysts are not stations and are untagged.
    - **Two claims tightened after reading the code:** the panel reports its area
      *when you let go*, not live; `draw_triangle_faces` fills the loop when the
      line *returns to its first point*, not on release.

[^point-triangle-context-3]: **The tutorial was rewritten.**
    Its nine blocks were convex hulls and AABB overlap, code that never touched a
    triangle's constraint. Now seven functions carry the argument
    (`triangle_normal`, `triangle_area`, `fan_triangulate`, `third_vertex`,
    `quad_from_rods`, `is_planar`, `faces_you`) and every one is proven by
    `commons/testing/probe_triangle_tutorial.gd` against a known answer: the 3-4-5
    lands at (0, 4); the mirror keeps its lengths; four rods lean with all sides
    kept; a lifted fourth point fails planarity; swapping two corners flips the
    face; a 5-point loop fans into 3. A tutorial that can fail a probe is the
    standard now.

[^point-triangle-context-4]: **Neighbours.**
    Jacob Gaboury, *Image Objects* (2021): a history of computer graphics that
    treats the mesh as an ontological choice. It is the closest thing in print to
    this room's argument. Read it before revising, so the room is in conversation
    with it rather than beside it.

[^point-triangle-context-5]: **Open.**
    - The old `commons/maps/Point_Triangle/` directory and the `content` reference
      in `sequences/primitives.json` are leftovers of the dissolution. Remove when
      convenient; nothing reads them for this room.
    - `interactivetriangle`'s area is reported as a status string on drop. Whether
      that reaches a visible label in the hall was not verified.

#### Primitives Polythedra

Volume does not begin as a container.

It begins as a corner. Three faces, each of them the unit from the last room, tilted off the plane until they meet at a single point, and for the first time in this chapter the faces have a side that is *in*. Nothing is enclosed. You could put your hand through it from three directions. But there is an inside now, and there was not before.

**grab_trihedron** — `grab_trihedron`

Pick it up. Three triangles, one shared vertex, and a base to stand on.

The last room said a triangle cannot lie: flat by necessity, one shape for its lengths, one front. Here is what three of them can do together that one cannot. Turn it in your hands and find the apex, and notice that the corner is not any of the faces. It is what they agree on. A corner is a place where three flat things have stopped being flat *together*.

## What the corner is missing

```gdscript
func corner_defect(apex: Vector3, ring: Array) -> float:
    var total := 0.0
    for i in ring.size():
        total += face_angle_at(apex, ring[i], ring[(i + 1) % ring.size()])
    return 360.0 - total
```

Lay six equilateral triangles around a point and their angles come to 360. They lie flat, and there is no corner, because nothing had to give. Take one away. Five come to 300, and the point rises, because the faces can only meet by tilting, and the sixty degrees they no longer cover is the corner.

That number is the *defect*, and it is the whole argument of this room in one word: a corner is how much of a full turn the faces had to give up to meet in a point instead of a plane. A cube's corner is three right angles, ninety short. The sharper the corner, the more is missing.

**pyramid_edit** — `pyramid_edit`

Take the apex and move it. Every face tilts to follow, because each one still has to end at the point you are holding, and the corner sharpens or flattens under your hand. Pull it high and the three faces close in, the defect grows, the corner becomes a spike. Push it down toward the base and the faces open, the defect shrinks, and at the moment the apex touches the base plane you have six angles summing to 360 and no corner at all. A pyramid is a corner with a handle on it.

## Closing it

```gdscript
func close_corner(apex: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Array:
    var faces := trihedron(apex, a, b, c)
    faces.append([a, c, b])   # the base, wound to face outward
    return faces
```

One more face, across the bottom, and the corner is closed. Four vertices, four faces, six edges. The first solid, and the smallest one possible, and every one of its corners is the trihedron you were just holding.

**grab_tetrahedron** — `grab_tetrahedron`

Here it is, closed. Notice that it has no top and no bottom; put it down any way you like and it is the same object. Every vertex is a corner of 180, three sixties, and there are four of them.

Now the fact this room exists to say.

```gdscript
func total_defect(corners: Dictionary) -> float:
    var sum := 0.0
    for apex in corners:
        sum += corner_defect(apex, corners[apex])
    return sum
```

Add up every corner of a closed solid and the answer is **720**. Four corners of 180. Eight corners of 90. Twelve corners of 60. It does not matter what you built: every closed solid there is carries exactly 720 degrees of corner, and the only freedom is how it spends them. Move one vertex of the tetrahedron and its four corners change, one sharpening as another flattens, and the sum does not move. This is Descartes' theorem, and it is the closest thing this chapter has to a conservation law. A solid keeps its volume not in its faces but at its corners, and in a fixed amount.

The next rooms will spend it in more and more places. The last of them will try to spend it everywhere at once, and find that a shape with corners everywhere has corners nowhere, and is a circle, and is never reached.

**Basic Cube Scene** — `cube_scene`

The solid that spends it eight ways, three right angles at every corner. It is also what this museum is made of: the floor under you, the walls beside you, the plinth this stands on, all of them the same object at different sizes. You have been inside a polyhedron since the first room. The next room is about that.

## Two numbers that do not care

```gdscript
func euler_check(V: int, E: int, F: int) -> bool:
    return V - E + F == 2
```

Vertices minus edges plus faces. Four minus six plus four. Eight minus twelve plus six. Two, and two. Whatever you build, if it closes, the count comes out the same, the way the corners came out to 720.

That is what a solid is, underneath the faces: two numbers that do not care which solid you built. The faces are where you look. The corners and the count are where it is kept.

The next room takes the eight-cornered one apart and shows you what it was made of, which you already know. Twelve of the unit, and six seams.

*Field notes: The ruling (Palle, 2026-09-02)[^primitives-polythedra-1] · What the triage found[^primitives-polythedra-2] · The tutorial belongs to a later room[^primitives-polythedra-3] · An observation, offered not pressed[^primitives-polythedra-4]*

[^primitives-polythedra-1]: **The ruling (Palle, 2026-09-02).**
    "The first most basic 3D form with just three sides; we should practise that
    artifact, it face-shifts." Confirmed as the **trihedron**: three faces meeting
    at a point, open, the corner before any container. The room holds
    `grab_trihedron` (wedge / corner / regular / inverted) and `pyramid_edit`
    (grab handles on base and apex), so "face-shift" is dragging those faces.

[^primitives-polythedra-2]: **What the triage found.**
    Five of ten placements are another layer: `path_watchdog`,
    `path_game_controller` and `becoming_catalyst` are the path-and-block playtest
    (2026-05-29); `tentacle_placer` drops pyramids from a seven-metre sky
    (2026-07-07); `interactive_point_origin_force#mode:transformation` is a
    force-field toy. `walked.md` already asked whether the catalyst "reads as
    integral to the volume beat or as a guest." `snap_tetrahedron_puzzle`, named in
    the intent as the closing station, is not placed; `grab_tetrahedron` is, with a
    one-word registry description.

    Ruling implied for the writer: the corner stations are the room; the game layer
    is untagged, like the catalysts in the triangle room.

[^primitives-polythedra-3]: **The tutorial belongs to a later room.**
    It enumerates the five Platonic solids and their volumes. Palle's thread puts
    the Platonic set in Primitives_Ignorance. What belongs *here* is the corner:
    the angle sum at a vertex under 360° ("six equilateral triangles collapse into
    a plane; five or fewer rise into a point" is the KEEP line and it is a corner
    fact), a trihedron built from three faces, the tetrahedron as a corner closed
    by one more face, Euler's V − E + F = 2 as the first count of a solid.

[^primitives-polythedra-4]: **An observation, offered not pressed.**
    The tetrahedron is the only Platonic solid with no centre of symmetry. The odd
    one was in the ideal set from the start. That may belong to Ignorance's capsule
    argument rather than here, but it is the corner's own property, so it is noted
    where the corner lives.

#### Point Animatedcube

You have been inside one since the first room.

The floor you stand on, the walls beside you, the plinths, the hall itself: this museum is made of cubes, and so is nearly every game you have ever played. The corner room said a cube spends its 720 degrees eight ways. This room puts one in your hands and takes it apart, and then it admits something about the world you are standing in.

**animatedcubebuilder** — `animatedcubebuilder`

Watch it assemble. Eight points first, then twelve edges between them, then six faces to close it, with handles to take hold of.

Count what you saw. Eight corners, twelve edges, six faces, and eight minus twelve plus six is two, the way it was for the tetrahedron. Every one of the six faces is a quad, and you know from two rooms ago what a quad is: two triangles agreeing to lie flat. So the cube is twelve triangles and six seams, and the seams are hidden only while the faces stay flat. The box you push in every game is twelve of the unit, wearing a skin.

## The net

**polyhedron_nets_cube** — `polyhedron_nets_cube`

Here it is admitting it was flat all along. Six squares in a Latin cross, five folds between them, and when the folds close there is an inside where there was a sheet.

There are exactly eleven ways to unfold a cube into a single connected sheet of six squares. Not ten, not twelve. This one shows the cross, the one every child's drawing uses, and can show three others: the staircase, the zed, the two rows. A cube is one solid and eleven flat things, and which flat thing it was depends on where you chose to cut. Cutting is a decision. The solid does not remember which one you made.

## Given time

```gdscript
var tween := create_tween()
tween.tween_property(cube, "position", END_POS, DURATION)
```

The map is called the animated cube, and this is the whole of an animation: two positions and a duration, and the machine fills the between. Keyframes define the targets. Interpolation invents everything else, at whatever easing you asked for, elastic or linear or a bounce at the end.

You met this in the trace room from the other side. There, the machine invented the path between two samples of a hand and called it a line. Here it invents the path between two states of a solid and calls it motion. Nothing about the cube changes while it moves: still eight corners, still twelve triangles, still 720 degrees of corner. What changes is where it is, and the next chapter is about that and nothing else.

## What the museum is made of

The humblest object in any game is a crate. You push it, you hide behind it, you break it for what is inside, and a room full of them says *level* before it says anything else. The museum you are in is the same object at a different size, and this room is where it says so.

**Shipping Crate** — `crate`

A wooden shipping crate, planks and an X-brace and a stamped plaque, the way every engine since the first has drawn one. Six quads. Twelve triangles. The floor under it is the same thing, larger.

**Wooden Pallet** — `wooden_pallet`

A pallet with three cartons on it, and read what they say. Three words across three boxes. They are the room's admission, and it is worth saying in full:

**A world without composition yet.**

The crates are here. Nobody has arranged them. That is not a failure of the room; it is the room's honest state. Everything in this chapter has been about what a thing *is*: a point, a line, a face, a corner, a solid. Nothing yet has been about what things are *next to*. Composition is another chapter, three of them in fact, colour and pattern and the made thing, and none of them can start until there is something to compose. So here is something: cubes, in quantity, unarranged, stamped with the fact.

**Hangar Supply Pile** — `hangar_supply_pile`

Two metal crates stacked, where a warehouse would stencil FRAGILE and KEEP DRY. These say the same thing the cartons say, split in two: *without composition*, and *yet*. The *yet* is the important word. It is a promise about the sequence, not an apology for the room.

**Station Crates (supply stack)** — `station_crates`

A stack, with a canister, the back-of-house clutter that makes a clean stage believable. Every game has a corner like this, and it is always cubes.

**Glove Box** — `glove_box`

And one cube you cannot touch. A sealed chamber with a single glove let into its side, the laboratory's vocabulary for *this work cannot be handled directly*. It is here so the others read as what they are: things you can move. The white cube of the gallery, the box the modernist container is named after, has a glove in its side and asks you not to.

## Two small things across the room

**First Shadow** — `first_shadow`

One triangle, casting a shadow, beside a line that casts none. That is the whole difference between a line and a surface, and the triangle room could only say it. A line has nothing to stop light. The smallest surface the engine accepts is enough.

**First Phosphor** — `first_phosphor`

An oscilloscope on a cart, a black shroud, and on the dark glass one green dot, breathing. It is the first point again, the one from the first room, and it is here in the room of the first solid because a chapter that began with *there was a point* should be able to see it from where it ends. Every cube in here is that dot, eight times over, with edges agreed between them.

The next room takes the cube and puts it beside the four other solids that share its perfection, and then beside one that does not, and asks which of them the machine actually makes.

*Field notes: The ruling (Palle, 2026-09-02)[^point-animatedcube-1] · What is here and what is not[^point-animatedcube-2] · Written (2026-09-02)[^point-animatedcube-3] · For the writer[^point-animatedcube-4]*

[^point-animatedcube-1]: **The ruling (Palle, 2026-09-02).**
    The cube shown as triangles (twelve of them) and as its net, unfolded. The map
    is about the cube "but should really have a lot more cube, like classic game
    crates; it's what the whole museum is made of, but we have a world without
    composition yet." The last clause is to be **said in the text**, as the room's
    own admission.

[^point-animatedcube-2]: **What is here and what is not.**
    Placed: `animatedcubebuilder`, `polyhedron_nets_cube` (the net), `first_phosphor`,
    `first_shadow`. Not placed, though they exist: `crate`, `tech_crate`,
    `station_crates`. The triage judged the room SPLIT because blurb, tutorial and
    artifacts argued deformation, interpolation and assembly respectively and never
    met. The ruling settles it: the cube as the museum's own material, in quantity.

[^point-animatedcube-3]: **Written (2026-09-02).**
    - **The tutorial's tween register was kept, not rewritten.** The map is the
      *animated* cube; keyframes plus interpolation is Point_Trace's "the lines
      invent the between" applied to a solid, so it earns one section, "Given
      time," and hands the rest to transformation ("what changes is where it is,
      and the next chapter is about that and nothing else").
    - **The admission is said in full**, once, in bold: *A world without
      composition yet.* The crates carry it split across their stencils (pallet:
      A WORLD / WITHOUT / COMPOSITION; pile: WITHOUT COMPOSITION / YET; crate:
      YET) via the `stencil_words` knob added the same day.
    - **Exact counts only.** Eight, twelve, six; Euler two (proven in the corner
      probe); twelve triangles and six seams; 720 spent eight ways; **eleven**
      distinct cube nets (the artifact's own description; the room shows four).
    - **The props' names are DNA-gallery variant names**, not tokens:
      `glove_box_1_single_glove` is `glove_box#glove_count:1`, and so on.
    - `first_shadow` and `first_phosphor` stand in the east bay behind the c8
      wall column; the text calls them "across the room" and claims nothing about
      reaching them.

[^point-animatedcube-4]: **For the writer.**
    - The museum is a voxel grid; the hall you stand in is cubes. The room can say
      that the floor under the visitor is the same object as the crate on the plinth.
    - Twelve triangles, six seams. After the triangle room, the visitor knows why.
    - The net is the cube admitting it was flat all along: six squares, five folds.
    - Cube props need placing before the text can point at them. This is a
      curator task (`/map-curator`), not a writing task, and it comes first.

#### Primitives Ignorance

The words over Plato's door were *let no one ignorant of geometry enter here*.

**3D Text Display** — `3t`

This room puts them halfway down a hall you have already walked into, which is the joke and also the argument. You are not ignorant of geometry any more; you have built it from a point to a solid. What you are about to find out is what the building left out, and that ignorance is not a lack. It is a structure. A model keeps by omitting, and the omitted does not vanish. It stands around in here, on plinths.

## What the menu offers first

**Basic Cube Scene** — `cube_scene`

A cube. You know this one to the corner.

**sphere** — `sphere`

And a sphere, which you do not, because there is no such thing in here. Look closely: thirty-two segments round, sixteen rings up, and every one of its faces is flat. The machine's sphere is a polyhedron that has agreed to be called round, and the menu has been calling it that since the first room.

## The ideal set

```gdscript
func regular_corner_defect(face_sides: int, faces_at_vertex: int) -> float:
    var interior := 180.0 * (face_sides - 2) / face_sides
    return 360.0 - interior * faces_at_vertex
```

**platonic_grabbables** — `platonic_grabbables`

Five solids, three of each, on one table. They are the ideal because every face is the same, every corner is the same, and every one of them looks the same from anywhere you stand.

Why five? Not because someone chose. Two rooms ago you learned that a corner must be missing something, and that a closed solid has 720 degrees of missing to spend. Ask for regular faces and the same number at every corner, and the arithmetic leaves exactly five ways to do it: three, four or five triangles at a corner, three squares, three pentagons. Six triangles lie flat. Four squares lie flat. Three hexagons lie flat. And 720 divided by what each corner is missing is how many corners the solid has: four, six, twelve, eight, twenty. The ideal set is not a list. It is a remainder.

**grab_octahedron** — `grab_octahedron`

Six corners, twelve edges, eight faces. Now say the cube's numbers backwards: eight corners, twelve edges, six faces. The octahedron is the cube with its corners and faces exchanged, and the exchange is called duality. Put one inside the other and every corner of one points at a face of the other. Two of the five are one shape read two ways.

**Snap Octahedron Puzzle** — `snap_octahedron_puzzle`

Join six points and you have made it yourself. What it spawns when it closes is a prism you can walk on, and that is the room's next argument standing up before the room has made it.

**truncatedtetrahedron** — `truncatedtetrahedron`

Cut the corners off the smallest one. Each corner becomes a triangle, four new faces, and the solid is no longer ideal. It belongs to a bigger family, the Archimedean, indexed by how deep the cut goes. The ideal set is one cut away from a family the menu never mentions.

## Resolution produces form

Walk on, and watch the sphere come apart in halves.

**sphere_high** — `sphere_high`

Thirty-two rings, thirty-two segments. Round, to the eye.

**sphere_mid** — `sphere_mid`

Sixteen. You can begin to count the facets.

**sphere_low** — `sphere_low`

Eight. It is not a rougher sphere. It is a different solid, one with eight-fold symmetry and no name in the menu, and the only thing that changed between the three plinths is an integer.

```gdscript
func prism_from_segments(n: int) -> Dictionary:
    # a "round" body drawn with n sides is a prism: n side faces, two n-gon caps
    return {"faces": n + 2, "vertices": 2 * n, "edges": 3 * n}
```

The machine has no circle. Every cylinder, every capsule, every sphere it has ever drawn is a number of segments, and at any finite number a round body is a prism: n side faces and two caps, and vertices minus edges plus faces is two, the way it always is. Lower the number far enough and the sphere is a prism with a name: triangular, square, hexagonal. Resolution is not detail laid on a form. It *is* the form, and the form was decided by whoever typed the integer.

Keep that for the next room, where the number tries to go to infinity and does not arrive.

## The one that refuses

```gdscript
func has_centre_of_symmetry(n: int) -> bool:
    # rotate the regular n-gon by half a turn: does it land on itself?
    for i in n:
        var p := Vector2.RIGHT.rotated(TAU * i / n)
        var back := -p
        var hit := false
        for j in n:
            if back.distance_to(Vector2.RIGHT.rotated(TAU * j / n)) < 0.0001:
                hit = true
        if not hit:
            return false
    return true
```

**capsule** — `capsule`

A pill, turning. Five segments round, five rings up, and it is in every engine's menu under the plainest name there is.

Watch it turn and watch what faces you. A vertex, then an edge, then a vertex. With an even number of segments the far side of a body is the near side turned half round, and you could draw the back from the front without walking there. With five you cannot. Turn it half round and it does not land on itself. An edge faces away where a vertex faced you, and the silhouette from behind is not the silhouette from the front. The back of this thing is genuinely unknown from here, which is the name of the room.

The five ideal solids are ideal because they are equal to themselves from everywhere. This one is a body the machine's own limit made unequal to itself, and it ships in the same menu, and nobody thought to call it anything. Hold on to that. The thing that refuses the ideal is not outside the set. It is in the standard kit, under the dullest name in it, and one integer away from the ones that comply.

**Star** — `star_primitive`

The same fact, flat: five points. Turn it half round and it does not land on itself either. Odd is a way of not equalling yourself.

## What resists

**roughrock** — `roughrock`

A solid whose corners were pushed off their ideal places. It is the remainder made into an object: everything the ideal set left out, standing on a plinth. What resists abstraction is not noise. It is signal.

**righttriangle** — `righttriangle`

And the thing that does not resist, for contrast. Move it anywhere, turn it any way, and the right angle survives, the way it did three rooms ago. An invariant is what a model keeps. This room has been about what it drops.

**Hole With Cones** — `hole_with_cones`

Three cones around nothing. There was a hole here, in the code, and it is no longer drawn; the cordon stayed. That is the room's emblem, and it is exact: a marker for the thing the model left out, standing where the thing was. Every primitive in this hall is three cones around something.

## What a primitive knows

The tutorial for this room is not about shapes at all. It is about objects that keep their own state and know nothing of the scene, that report some facts and hide others, that can learn and forget. That is what a primitive is in a machine: not the simplest thing but the most *enclosed*, an interface that shows you a sphere and keeps thirty-two integers behind it. Calling something primitive is a move, not a description.

The next room takes the integer this one kept turning down and turns it up instead, toward the circle, and finds out whether it ever gets there.

*Field notes: The ruling (Palle, 2026-09-02)[^primitives-ignorance-1] · The exact form of the capsule claim[^primitives-ignorance-2] · Resolution produces form[^primitives-ignorance-3] · Written (2026-09-02)[^primitives-ignorance-4] · The tutorial that is currently in Polythedra[^primitives-ignorance-5]*

[^primitives-ignorance-1]: **The ruling (Palle, 2026-09-02).**
    Three movements in one room. The Platonic primitives. Then "the space of
    primitives in different resolutions, that says resolution can produce form: a
    lower-res sphere is a prism." Then, more important, symmetry: "how an odd number
    of segments breaks visual symmetry and makes the back side harder to derive.
    This is how the 3D pill that only has five segments is an anti-Platonic
    primitive, because it is not symmetrical. This is queerly important. The
    artifact is just called `capsule`."

    The instruments are already in the room: `platonic_grabbables`, `sphere_low`,
    `sphere_mid`, `sphere_high`, `capsule`. `capsule_radials_rings` exists in the
    registry with the segment count as its knob and is the right station for the
    odd/even argument.

[^primitives-ignorance-2]: **The exact form of the capsule claim.**
    Say it without "queer" doing all the work; the room should be able to state it
    so that it can be checked.

    An even number of radial segments gives a cross-section with **central
    symmetry**: rotate it 180° and it lands on itself, so the far side is the near
    side turned round, and you can derive the back from the front. **An odd number
    has no centre of symmetry.** A pentagon with a vertex facing you has an edge
    facing away; the silhouette from behind is not the silhouette from the front.
    The back is genuinely unknown from here, which is the room's name.

    The Platonic solids are the ideal *because* every face and vertex is
    equivalent. The five-segment capsule is a body the machine's own limit made
    unequal to itself, shipping in the same primitive menu as the ideals, under the
    plainest name in it. The irreducible one, in the standard set. That is the
    thesis's sense of queer (see `doc/CONSERVATION_OF_THE_IRREDUCIBLE.md`), and
    here it is a fact about a mesh.

    One more, offered not pressed: the tetrahedron is the only Platonic solid
    without a centre of symmetry. The odd one was in the ideal set from the start.

[^primitives-ignorance-3]: **Resolution produces form.**
    `SphereMesh` at low `radial_segments` is a polyhedron; a cylinder at low
    segments is a prism. The same call, a different integer, a different solid.
    Form is a parameter of resolution, and the three spheres on their plinths are
    that sentence as objects. This connects back to Point_Trace's lattice and
    forward to Portals' circle that is never reached.

[^primitives-ignorance-4]: **Written (2026-09-02).**
    - **The plain `capsule` IS the five-segment pill.** Its authored mesh is
      5 radial segments, 5 rings, radius 0.25, height 1.0, spinning at 45°/s; the
      `facture` axis makes the bands pointable. Palle's "this artifact is just
      called capsule" was literal. No second capsule was placed.
    - **The five are derived, not listed.** `regular_corner_defect` +
      `platonic_candidates` in the tutorial: regular faces, same count per corner,
      positive defect → exactly (3,3) (3,4) (3,5) (4,3) (5,3), and 720/defect gives
      4, 6, 12, 8, 20 vertices. This completes the corner room's Descartes law.
      Proven by `probe_ignorance_tutorial.gd`.
    - **Resolution as form, exactly.** `prism_from_segments`: a round body at n
      segments is a prism (n+2 faces, 2n vertices, 3n edges), Euler holds. The
      ladder is 32 → 16 → 8 walking south; the text says 8 is "a different solid
      with eight-fold symmetry and no name in the menu," not "a rougher sphere."
    - **The symmetry claim uses `rotated()`**, not `cos`/`sin`, so no trig is
      named in primitives; the method hides it the way `length()` hides Pythagoras.
    - **The tutorial's encapsulation register was kept** and given the closing
      section: a primitive is the most enclosed thing, "an interface that shows you
      a sphere and keeps thirty-two integers behind it."
    - **Curriculum honesty:** `roughrock` is noise-perturbed, and noise is not
      taught before sequence 8. The text calls it "corners pushed off their ideal
      places" and does not teach the noise.

[^primitives-ignorance-5]: **The tutorial that is currently in Polythedra.**
    The five-solids enumeration (`face_count`, `interior_angle_sum`, `euler_check`,
    `solid_volume`) belongs to this room's first movement and should move here
    when Polythedra's tutorial is rewritten around the corner.

#### Primitives Portals

The last room kept turning the number down. This one turns it up, and walks toward what it ought to become.

The hall is long, and it is a tunnel of rings. The rings are tori, the first form in this chapter with a hole in it, and every one of them is drawn the only way the machine can draw anything round, out of straight sides. As you walk, the sides multiply. The circle is somewhere at the far end. You will not reach it, and the room is about why, and about what you do instead.

**capsule** — `capsule`

The pill from the last room is at the door, closed, five-sided, exactly as it was. It is here so you can see what a hole does to a form. Everything you have held so far has been closed; the rings ahead are the first things you will pass *through*.

## The number goes up

```gdscript
func polygon_perimeter(n: int, r: float) -> float:
    var total := 0.0
    for i in n:
        var a := Vector2.RIGHT.rotated(TAU * i / n) * r
        var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
        total += a.distance_to(b)
    return total
```

**combine_portals** — `combine_portals`

Twenty tori down the hall, and the first one is a triangle: three sides round, three rings through, the coarsest torus the engine will allow. Each portal after it has one more ring and two more sides than the one before, so by the twentieth you are walking through forty-one sides, and it looks, from a few metres, like a circle.

It is not one. Measure what is missing and you find it is never nothing.

```gdscript
func gap_to_circle(n: int, r: float) -> float:
    return TAU * r - polygon_perimeter(n, r)
```

Archimedes did this by hand. He started from a hexagon and doubled, twelve, twenty-four, forty-eight, ninety-six, and with ninety-six sides he boxed the number that a circle is between 3.1408 and 3.1429. Ninety-six sides give 3.1410. It is very close. It is not there, and no doubling you can name gets there, because the gap at every finite n is a positive number, smaller than the last one and larger than zero. A circle is a limit, and a limit is not a place. You can walk toward it down this hall for as long as the hall lasts and be nearer at every ring, and the ring you are standing in will still have a side count.

## Achilles, and what the machine does instead

```gdscript
func achilles(steps: int) -> float:
    # each step covers half of what remains of one unit of track
    var covered := 0.0
    for i in steps:
        covered += (1.0 - covered) * 0.5
    return covered
```

**Achilles and the Tortoise** — `achilles_tortoise`

Six metres of track, and the runner takes the distance in halves: half the way, then half of what is left, then half of that. Ten steps and he has covered all but a thousandth of it. He will never cover the last part, because every step leaves half of what it found, and the label at the far end says *limit* for that reason. Zeno said this to prove motion impossible. What it proves is that a finite distance can hold infinitely many steps, and that arrival is not one of them.

Then run the code, and watch the machine disagree.

At the fifty-fourth step, `covered` becomes exactly one. Not close to one: equal. The half that remained was smaller than a float can hold next to the number one, so it rounded away, and the runner arrived. The machine reaches the limit by running out of digits. That arrival is exactly as honest as the sphere in the last room, which was round because nobody counted its sides, and it is worth knowing that every *arrived* this machine will ever report to you is of that kind. Mathematics never gets there. Floats do, by forgetting.

## A surface with a hole

```gdscript
func torus_counts(rings: int, segments: int) -> Dictionary:
    var v := rings * segments
    var f := rings * segments
    var e := 2 * rings * segments
    return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}
```

Two rooms ago every closed solid you counted gave two. Vertices minus edges plus faces, the tetrahedron and the cube and the twenty-sided one, two, every time, however many corners it spent its 720 on.

Count a torus. At three rings and three sides, at twenty-two and forty-one, at any resolution you like, the answer is zero. The hole is not something the surface has. It is a change in the number the surface cannot help giving you, and that number does not care how finely the ring is drawn. You can push the side count toward the circle forever and the torus stays a torus, with its zero, because the hole was never made of sides.

That is what a portal is, before it is anything magical: a surface whose count is zero, which you can walk through because of it.

## Transformation, not transport

```gdscript
func through_portal(entry: Transform3D, exit: Transform3D, velocity: Vector3) -> Vector3:
    var turn := exit.basis * entry.basis.inverse()
    return turn * velocity
```

There is a way out of this hall, and it is not the far end. It is a portal, and read what a portal does. It does not cover the distance between its two mouths; Achilles would never finish that. It changes the frame. Whatever direction you were carrying in is turned by the difference between the mouths and handed back to you at the same speed, pointing somewhere else. You did not travel. You were re-described.

Crossing a boundary requires transformation, not mere transport. That is the room's sentence and it has been the museum's sentence since the trace room: what cannot be reached by adding more can sometimes be reached by changing what counts. The next chapter after this one is called transformation, and it begins there.

The next room is what it is like to stand inside the limit with every tool in your hands, and not reach it, and stay.

*Field notes: The ruling (Palle, 2026-09-02)[^primitives-portals-1] · What is here[^primitives-portals-2] · Written (2026-09-02)[^primitives-portals-3] · For the writer[^primitives-portals-4]*

[^primitives-portals-1]: **The ruling (Palle, 2026-09-02).**
    "A divergence between the finite and the infinite, played out in Portals, where
    we can never reach the full circle." The n-gon approaches the circle as the
    segment count rises and does not arrive; the limit is not attained by any
    finite mesh. Melencolia answers this room.

[^primitives-portals-2]: **What is here.**
    `achilles_tortoise`, `capsule`, `combine_portals`. Achilles is Zeno saying the
    same thing about distance that the ring says about the circle, and he is
    already standing in the room. The capsule carries over from Ignorance; its odd
    segment count is the same fact from the other side, a form that resolution
    made and that resolution cannot finish.

[^primitives-portals-3]: **Written (2026-09-02).**
    - **The tutorial was replaced.** It described an `Area3D` teleporter pair, a
      different object under the same word (the triage's finding). Now: the
      polygon that approaches the circle (`polygon_perimeter`, `gap_to_circle`),
      Achilles (`achilles`), the torus count (`torus_counts`), and one portal
      function (`through_portal`) kept from the old register because it is the
      room's KEEP line in code: crossing is a rotation of the frame, not a
      covering of distance. All proven by `probe_portals_tutorial.gd`.
    - **The tunnel is exact.** `combine_portals` duplicates a base torus of
      3 rings × 3 segments (a triangular torus) twenty times at 4.5 m, refinement
      `linear`: portal i gets 3 + i rings and 3 + 2i segments, so the last has 22
      rings and 41 sides. The text says "from three sides to forty-one."
    - **Archimedes is in the room.** The 96-gon gives 3.14103, inside his bounds
      of 3.1408 and 3.1429; the gap to the circle is positive and shrinking for
      every n to 4096 (9.1e-7 at 4096).
    - **The machine arrives at step 54.** In mathematics no halving step reaches
      one; in a 64-bit float `covered` becomes exactly 1.0 at the fifty-fourth
      step, because 1 − 2⁻⁵³ is the last representable number below one. The
      first draft said fifty-three; the probe corrected it. This is the room's own
      twist and the honest form of "the finite never arrives": it never does,
      except in a machine, which arrives by forgetting.
    - **Euler is 0 for the torus** at every resolution (nine tested), against 2
      for every closed solid so far. The hole is a change in the count.
    - **No trig named.** Vertices come from `rotated()`; `TAU` is a constant.

[^primitives-portals-4]: **For the writer.**
    - The circle is the first infinite object the chapter meets, and it meets it
      as something the machine can only approximate. Every "circle" in the museum
      is a polygon. Say which n.
    - Do not let this become a lament. The finite polygon is what a body can
      actually stand inside; the circle is what a body can only want.
    - The triage's line, kept: "the rings keep approaching and never keep the
      circle."

#### Primitives Melencolia

She has every tool in the chapter and she is not using any of them.

Dürer cut the engraving in 1514, and it has been argued over ever since, because everything in it is exact and nothing in it is explained. A winged figure sits with a compass in her hand and does not draw. Around her, on the floor and the wall and the table: a polyhedron, a sphere, a magic square, a ladder, an hourglass, a bell, a pair of scales. Read that list again. It is this chapter. Two points and a distance, the round thing made of sides, the lattice with numbers on it, the ordered walk, sampled time, and the corner cut into a solid. She has all of it, and she is sitting down.

**DÃ¼rer Melencolia Scene** — `durer_scene`

Here it is, built. Walk round it. The polyhedron at her feet is a cube with two opposite corners sliced off, and count it: twelve corners, eighteen edges, eight faces, and twelve minus eighteen plus eight is two, the number the chapter has been giving you since the corner room, once more, on the last solid you will meet. The compass is the second room. The hourglass is the trace, with sand for samples. The square on the wall is the grid with something written in every cell. This is not a picture of melancholy. It is a picture of mastery, and mastery is what she is melancholy *about*.

## Every line is 34

```gdscript
func durer_square() -> Array:
    return [[16, 3, 2, 13],
            [5, 10, 11, 8],
            [9, 6, 7, 12],
            [4, 15, 14, 1]]
```

Sixteen lines through this square, and every one of them sums to 34. Four rows. Four columns. Both diagonals. The four corners. The centre four. Each of the four quarters. The bottom row reads four, fifteen, fourteen, one, and the middle two are the year it was cut. It uses every number from one to sixteen exactly once, so nothing is left over and nothing is missing.

It is for nothing. You cannot build with it, measure with it, or walk on it. It is finite, exact and complete, and it does not do anything, and the mind that made it wanted it anyway, and so does yours, and that wanting is the second thing this room is about.

The first is that you cannot leave.

## Stuck

```gdscript
func go_anywhere(from: Vector3, by: Transform3D) -> Vector3:
    return by * from
```

Every transformation of a position is a position. Read the function's last word: it returns a `Vector3`, and there is no function anywhere in this machine that takes a position and returns somewhere that is not one. Move, turn, scale, cut, fold, snap, sample, round: you have done all of it in this chapter, and every one of those operations lands you back in three floats. The universe you have built is closed under everything you can do in it. The polyhedron at her feet is the same cube you have been standing inside since the first room, with two corners gone.

That is what the tools are for, and it is also what they are. A compass can draw any circle and cannot draw its way out of the plane. Whether you can leave is not a question the room will answer. Dürer did not, and he had the compass in his hand.

**Code Display** — `code_display`

The axioms, on a stand, in the room where they run out. Everything on that screen is true, and it is all there is, and reading it here is what the intent of this map calls making the system legible at the moment of its exhaustion. Nothing on it is wrong. That is the problem.

**bigframe** — `bigframe`

A frame, hollow, staging the whole scene as a picture. This is the moment the abstract becomes something to be *looked at*, and it is the hinge of the room. Once you are looking at geometry instead of using it, it has become an image, and an image can be wanted the way the square is wanted, for itself.

## Refinement continues

**pyramid** — `pyramid`

Four of the same pyramid, at four sizes. Half, four-fifths, one, two and a half. The same solid every time: five corners, eight edges, five faces, two. Scale is the one thing this chapter never touched, and here it is, changing nothing, four times.

**pyramidlong** — `pyramidlong`

And one stretched. Still five corners. Still two.

**prism_block** — `prism_block`

The triangular prism, for when a cube is too symmetrical to show the difference. Five faces, six corners, nine edges. Two.

**diamondtoruscollection** — `diamondtoruscollection`

A torus with diamonds hung from it, the chapter's vocabulary turned into a chandelier. Every primitive of the sequence, made ornamental. This is what happens when the tools are mastered and the question of what to build has not been answered: you make the same forms again, larger and smaller and stretched and decorated, and the count comes out two every time, and it is beautiful, and it is not building. It is the doodle of someone who could build anything.

## Build anyway

**Snap Pyramid Puzzle** — `snap_pyramid_puzzle`

One thing in this room asks you to make something. Five points, and joining them forms a pyramid, and the pyramid, when it closes, spawns a prism you can stand on. It is the last act of the chapter and it is the only one that is an act.

And read the detector, because it is honest about itself. It checks that the four base points make a cycle and that the fifth sits above them. It never checks that the base is square. Push the four points into a rhombus and the machine will accept it, name it a square pyramid, and build you the prism all the same. The tool has a limit and the limit is right there, and the prism it spawns is walkable anyway.

Master the tools. Recognise their limits. Build anyway. That is the room's sentence, and the puzzle is the sentence with your hands in it.

## Might or might not

Two things are true at once here, and the room will not choose between them, because she did not.

You are inside a mathematical universe that closes over everything you can do, and every exit you try returns three floats. And the abstract things in it, the square that sums for no reason, the solid that counts to two, are wanted for themselves, by a mind that has nothing to use them for. Whether that wanting is the way out or the thing itself, escape or truth, is the question the engraving has kept open for five hundred years, and this chapter ends inside it, sitting down, tools in hand.

The door behind you works. The next chapter is transformation, which is the one thing this chapter never did: it moves. Whether moving is leaving, you will have to walk through and see.

*Field notes: The ruling (Palle, 2026-09-02)[^primitives-melencolia-1] · What is here[^primitives-melencolia-2] · For the writer[^primitives-melencolia-3] · Written (2026-09-02)[^primitives-melencolia-4] · The assessment, recorded[^primitives-melencolia-5]*

[^primitives-melencolia-1]: **The ruling (Palle, 2026-09-02).**
    "The answer in the next map, Dürer's Melencolia, is that we are stuck in a
    mathematical 3D universe that we might or might not escape. But here is also a
    queer visual desire that can be abstract; it is about the abstract as escapism
    or truth, the aesthetic mind."

[^primitives-melencolia-2]: **What is here.**
    `durer_scene`, `diamondtoruscollection`, `prism_block`, `pyramid`,
    `pyramidlong`, `bigframe`, `code_display`, `snap_pyramid_puzzle`.
    `melencolia_chalkboard` exists and is not placed. The triage's line, kept:
    "every tool kept, completion withheld, build anyway."

[^primitives-melencolia-3]: **For the writer.**
    - The engraving's polyhedron is a truncated triangular trapezohedron, the
      "Dürer solid," still argued over. The compass, the sphere, the magic square,
      the ladder: every instrument the chapter has taught, in one room, and the
      angel not building.
    - Two directions at once, and the text must hold both: the mathematical
      universe as enclosure (you cannot leave a space made of triangles by making
      more triangles), and abstraction as the thing the aesthetic mind *wants*,
      not for use, not for anything, for itself. The second is the queer desire,
      and it is the thesis's irreducible remainder turned into an appetite.
    - Do not resolve it. The room ends the chapter on "might or might not."

[^primitives-melencolia-4]: **Written (2026-09-02).**
    - **Not resolved, as ruled.** The closing section is titled "Might or might
      not" and holds both directions: the universe closed under every operation
      (`go_anywhere` returns a `Vector3`, always), and the abstract wanted for
      itself (the square that sums for no reason). "Whether that wanting is the way
      out or the thing itself, escape or truth, is the question the engraving has
      kept open for five hundred years."
    - **The tableau is read as the chapter.** Compass = Point_Lines, hourglass =
      Point_Trace, magic square = the grid with numbers in every cell, ladder =
      the walk, cut cube = the corner room. "This is not a picture of melancholy.
      It is a picture of mastery, and mastery is what she is melancholy about."
    - **Every number checked.** Dürer's square: sixteen lines all 34, 15 and 14 in
      the bottom row, a permutation of 1..16; a swapped pair breaks it (the
      negative). The cut cube: 12, 18, 8, Euler 2. `probe_melencolia_tutorial.gd`.
    - **The pyramid ×4 at four scales is given a meaning, not dressed:** the same
      count four times at four sizes is "the doodle of someone who could build
      anything," and scale is the transformation chapter knocking.
    - **The puzzle's honesty is the KEEP line made literal.** Its own description
      says the detector checks the 4-cycle and never the squareness; a rhombus
      passes and the prism spawns anyway. "Master the tools. Recognise their
      limits. Build anyway."
    - The tutorial kept its scene-composition register and gained the square,
      the solid and the closure function. `melencolia_chalkboard` exists and is
      not placed; its line "finite, exact, complete" is used in prose.

[^primitives-melencolia-5]: **The assessment, recorded.**
    Asked on 2026-09-02 whether the whole primitives thread is unique, good and of
    value. Answer, in short, for the record: unique in synthesis rather than in
    parts (neighbours: Victor and Case for explorable explanations; Bogost for
    procedural rhetoric; Ahmed for orientation; Gaboury for the mesh as ontology;
    Russell and Blas for the queer/computational join); good where it is exact,
    because criticism that can be checked against code can be wrong, which is what
    makes it not escapism; of value as a form of critical writing that has to
    survive contact with the mechanism, and as a curriculum, at once. The risks
    named: unevenness (92 of 231 rooms ready), a house style that could become a
    mannerism across two hundred rooms, an audience that can hold Vector3 and
    Foucault at once, and the escapism charge this room itself raises.

*1 further room(s) in this chapter, not yet written.*

**fontana puncture**

![fontana puncture](/artifact-gallery/captures/fontana_puncture/front.png)

Fontana's Concetto Spaziale carried into three dimensions: a solid cube with a sphere subtracted — and the sphere is bigger than the cube, so the void breaches every face and hollows the matter from inside. At dead centre, suspended in the absence it made, floats a single luminous point: the zero-dimensional origin of the cut. This is the weight of nothing made architectural. Fontana slashed canvas to let the infinite in; here the infinite is literally larger than the object that holds it, and the cube survives only as the frame that proves there was something for the void to take. A point, given a radius and an appetite, is the most consequential thing in the room.

> a point is position without extension — but give it a radius and aim it at solid matter and it becomes the most consequential thing in the room: the absence that defines the form. Fontana cut the canvas to let the infinite in. Here the infinite is a sphere bigger than the cube, and the cube survives only as the frame that proves there was something for the void to take.

**cube scene**

![cube scene](/artifact-gallery/captures/cube_scene/front.png)

The given. A cube that will follow you through the whole book — grabbed, scaled, subdivided, snapped, augmented — while remaining recognisably itself. It earns its plainness: every later sequence needs a stable form against which change can be read, and this is that form. In a curriculum about becoming, the cube is the thing that merely, stubbornly, is.

**player trace**

![player trace](/artifact-gallery/captures/player_trace/front.png)

The first really queer artifact in the book. A recorder turns your motion through the room into a visible line: every step writes another point, and your walk becomes geometry instead of a forgotten action. Now look closely at what just happened. Your movement was analogue — continuous, at a resolution higher than the already-pixelated screen showing it back to you; no sample rate can hold all of it. The recorded trace is digital: the gesture broken into bits, position by position. And the line hanging in the room is neither. Not the gesture — that is gone; not the data — data has no glow. It lives in between, on the crossing itself, which is exactly where this book locates the queer: the irreducible remainder the grid cannot fully hold. Every discretization from here on repeats this crossing. This is where the ledger opens.

> every path through space is a function of time, and you are constantly computing it

**grid lines**

![grid lines](/artifact-gallery/captures/grid_lines/front.png)

The lattice arrives, and with it the first act of measurement. The XZ plane made legible: x = i·step, z = j·step, a mesh of lines laid across the floor. It looks like a fact about space. It is not — it is a social agreement we project onto space, the shared fiction that lets two people mean the same thing by 'here'. Thinking that compares, that ranks, that navigates — thinking at all, this sequence argues — cannot exist without some grid. The critical move is not to refuse it but to remember, every single time, that you put it there.

> a coordinate grid does not exist in space — it is a social agreement we project onto space

**lab room**

![lab room](/artifact-gallery/captures/lab_room/front.png)

And the room itself, procedurally generated: white tile, observation glass, an accent strip naming the QFEP phase, signage reading TEST CHAMBER λ-S. The room is not the experiment — the room is the signal that an experiment is about to happen. Which makes it the architecture of thrownness: you are always already inside one of these before anyone explains it, reading the walls for what kind of place this is. Same script, different DNA, different chamber — the frame is as authored as anything it frames.

> the room is not the experiment. The room is the SIGNAL that an experiment is about to happen.

### The Walk — further in

*Further in: the hand starts writing, and measurement gets a body.*

**draw dot**

![draw dot](/artifact-gallery/captures/draw_dot/front.png)

Your hand, sampled. Move it and a trail follows: sample(hand_position), point after point, the hand writing directly into space. Draw slowly and the curve is smooth; whip your wrist and you can outrun the sampler — the line goes faceted, and you are watching the debt accrue in real time. The artifact's claim is severe: a curve has no intrinsic form; it is only the limit of increasingly dense point samples. Between any two samples, something of your gesture is discarded. The drawing is beautiful. It is also a receipt.

> a curve has no intrinsic form — it is just the limit of increasingly dense point samples

**laser measure**

![laser measure](/artifact-gallery/captures/laser_measure/front.png)

A handheld laser measure with an LCD readout — the most ordinary object in the sequence, and among the most loaded. Point it and a number appears: distance, the primal measurement, the act the line made thinkable. Every measurement is a question forced onto the world in units the world did not choose. The tool fits in your hand because measuring was never neutral or disembodied — someone aims it.

**pyramid edit**

![pyramid edit](/artifact-gallery/captures/pyramid_edit/front.png)

A pyramid with five grab handles — apex and four base corners, all movable. Drag the apex sideways and somewhere along the way it stops being a pyramid; no alarm sounds, because nothing in the geometry knows the word. 'Pyramid' is a parameterisation plus a habit of naming. The handles teach what the definition hides: categories have interiors and edges, and you can feel for them with your hand.

> a pyramid is just a parameterisation — move the apex and it stops being a pyramid

**grabbable line**

![grabbable line](/artifact-gallery/captures/grabbable_line/front.png)

A line segment you grab as one object — anywhere along its length — and carry through space. The lesson is in what you didn't need: you can hold a line before you know it has endpoints. Wholes are graspable before parts are nameable; the body understands before analysis arrives. It also resists snapping to integers, slightly — a small built-in glitch to remind you the grid is always pulling.

> you can hold a line before you know it has endpoints

**triangle**

![triangle](/artifact-gallery/captures/triangle/front.png)

Three points, and suddenly there is surface — the minimal agreement that defines a plane and encloses area. Drag its vertices through the presets: equilateral, right-angled, isosceles — the family of shapes one contract can take. Every surface you will see in this book, every creature and cave and cathedral, is triangles and nothing else. The GPU's atomic unit is not the pixel; it is this pact among three points. Here the trace's private crossing becomes industry: the whole rendered world is discretization at scale.

> every surface in 3D graphics is an agreement among three points — all meshes are triangles

### The Turn — parameters

The knobs of this sequence are quieter than later ones, and more fundamental. klee_walking_point exposes trail_points — 48 by default — and that number is the book's first sample rate: lower it and the walk becomes a polygon; raise it and the line approaches, without ever reaching, the gesture. The debt made adjustable — pay more memory, owe less form. walk_style toggles meander against straight: the same journey, with and without a goal. And fontana's sphere_radius decides how much void a form can carry before it stops being a form at all. Three knobs: how finely to sample, whether to wander, how much nothing to admit. Most of the book's later machinery is these three questions wearing costumes.

Open in the dressing-room viewer: klee walking point, fontana puncture, cube scene, player trace.

### The Critical Reading

*Now the reading the dark room has been implying all along.*

QFEP term: **F**

Primitives are the F term — pure order, stable foundations before entropy enters, the deterministic base from which complexity will grow. That is the official story, and it is true enough to teach. But the trace has already broken it. The player's hand entered early, analogue and unrepeatable, and every artifact that recorded it took out a loan against the continuous. Order, it turns out, is not the absence of entropy — it is entropy deferred: sampled, gridded, agreed upon. The F term is what E(S) looks like after the first measurement. Which means the queer remainder is not a late guest arriving with the randomness sequence: it was here before the grid was, and the grid was built to manage it.

The artifacts' own claims:

> a point is position without extension; a line is a point that refused to stay still. Klee knew drawing is time made visible. In a world built from Vector3 this is the most honest object in the lab: it shows you the geometry you walk through is not a set of shapes but a set of MOVES, and that the straightest move is the one that learned the least. — *klee walking point*

> a point is position without extension — but give it a radius and aim it at solid matter and it becomes the most consequential thing in the room: the absence that defines the form. Fontana cut the canvas to let the infinite in. Here the infinite is a sphere bigger than the cube, and the cube survives only as the frame that proves there was something for the void to take. — *fontana puncture*

> every path through space is a function of time, and you are constantly computing it — *player trace*

> a coordinate grid does not exist in space — it is a social agreement we project onto space — *grid lines*

> the room is not the experiment. The room is the SIGNAL that an experiment is about to happen. — *lab room*

> a curve has no intrinsic form — it is just the limit of increasingly dense point samples — *draw dot*

> a pyramid is just a parameterisation — move the apex and it stops being a pyramid — *pyramid edit*

> you can hold a line before you know it has endpoints — *grabbable line*

### In the World

*Ten rooms that begin with almost nothing and end with an angel. Point_One holds a single artifact and a footprint of zero square metres — the emptiest room in the game, on purpose; awe needs a vacuum. Then lines accumulate, the trace gets a room of its own, the grid arrives, triangles bring surface, polyhedra bring bodies. Primitives_Ignorance packs forty artifacts into the sequence's densest room — everything you do not know yet, staged — and Portals throws open the largest footprint in the spine, doors before you know what doors are. It ends in Melencolia: Dürer's angel surrounded by every instrument of measurement, polyhedron at her feet, unable to act. The sequence's closing argument in a single image — measurement alone does not move.*

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Point_One | 9×11 | 1 | 0.0 m |
| Point_Lines | 7×27 | 33 | 22.7 m |
| Point_Trace | 7×17 | 5 | 3.6 m |
| Point_Line_Grid | 8×14 | 5 | 5.9 m |
| Point_Triangle_Context | 7×21 | 14 | 21.8 m |
| Primitives_Polythedra | 7×11 | 13 | 6.0 m |
| Point_Animatedcube | 7×14 | 8 | 10.3 m |
| Primitives_Ignorance | 9×27 | 40 | 38.6 m |
| Primitives_Portals | 7×35 | 5 | 93.7 m |
| Primitives_Melencolia | 7×14 | 18 | 21.5 m |

What this chapter teaches, walked rather than read:

- Understanding Vector3 as position in 3D space
- Point visualization: existence without extension
- Line topology: connection between two positions
- Triangle rasterization: the GPU's atomic unit
- From primitives to meshes: building complexity from simplicity

The machine walked Hangar_Primitives and filed this ride log:

> 125 stations from spawn to exit; 142 bodies measured.

> 1 of 11 walked bodies appear only on arrival, never from a distance — the gallery hides its exhibits until you stand at them.

> laser_measure held the view at 5 of 125 stations, peaking at 140° — the room has one voice louder than the rest.

> the smallest walked body is laser_measure at 0.1 m.

> no two exhibits share ground.

### The Seed

> **A point is position without extension. Everything is built from nothing.**

Exercises:

1. Stand in Point_One for a full minute without touching anything. Write down what the empty room is doing to you. That is what 'position without extension' feels like from inside.
2. Set klee_walking_point to 'straight' and watch a few walks; set it to 'meander' and watch again. Say which line knows more, and defend your answer to a mathematician.
3. In draw_dot, draw the slowest curve you can, then the fastest. Find the speed at which your hand outruns the sampler — that threshold is the resolution of your world here. Write the number down; the book will raise it and raise it and never reach you.
4. With laser_measure, measure the distance to the point at the centre of fontana_puncture's hollow. Then say what exactly you measured to: matter, void, or agreement.
5. Drag pyramid_edit's apex until, for you, it stops being a pyramid. Mark the spot. Ask someone else to do the same. The distance between your two marks is what a category is.
6. In player_trace, walk a word — your name — and look at the line. What did the recording keep, and what did it discard? The discarded part is the debt; remember its face.

The seed of this sequence fits in a sentence: from a point that isn't there, and a hand that can't be held, the whole world will be built on credit. Carry it into transformation, where the shapes learn to move — and the moves, not the shapes, turn out to be the geometry.

*Next: transformation*

### The Ledger

- **the throw** — Opened. You are dropped into a dark room with one luminous point — arrival before explanation, the spawn as thrownness. Every chapter after this begins the same way, and owes this one the honesty of admitting it.
- **the measure** — Opened. The grid is confessed as a social agreement, the laser puts measurement into a hand, and Melencolia closes the sequence with measurement's patron saint, unable to act. Thinking begins with a cut.
- **the hand** — Opened. draw_dot and player_trace put the body in the loop on day one — the hand as the analogue ground every later system will sample.
- **the trace** — Opened — the first queer artifact. A continuous gesture crossed into bits and back into light; the line in the room is neither gesture nor data but the crossing itself, the in-between the grid cannot hold.
- **the debt** — The ledger opens at trail_points = 48: forty-eight samples borrowed against a continuous walk. Everything discarded between samples is the first entry. Balance: small, and already compounding.
- **the dig** — 11 of 73 artifacts excavated; 62 remain at depth.

## Chapter 2: Transformation: What Stays the Same When Everything Changes

> **Identity preserved under transformation. What stays the same when everything changes? Invariants define structure; transformations reveal what matters.**

`T(v) = M × v, where M is a 4×4 matrix encoding translate, rotate, scale`

Affine transformations in 3D space. Translation, rotation, and scale—the three fundamental ways to change position, orientation, and size while preserving shape. Matrix math makes this possible.

### The Principal

This chapter's principal is **rotation gimbal** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **plinth**: small, raised to the eye on a dark column.

### The Primitive

**rotation gimbal**

![rotation gimbal](/artifact-gallery/captures/rotation_gimbal/front.png)

Gimbal lock demonstrator with 3 nested rotation rings (X=red, Y=green, Z=blue). VR sliders control each Euler angle (0-360 degrees). When Y approaches 90 degrees, X and Z rings align and 'GIMBAL LOCK!' flashes — showing why Euler angles lose a degree of freedom and why quaternions matter. Displays live rotation matrix decomposition.

### The Walk — first steps

#### Trans Introduction

A transformation is defined by what it refuses to change.

Melencolia left you with a solid that would not move. This is the room where the primitives finally do, and there are exactly three ways they can: a thing can go somewhere else, it can turn, or it can grow. The chapter's whole question is asked in the first hall and answered in the last: when everything changes, what stays the same? Each of the three moves has a different answer, and each is named for the one thing it gives up.

## Three ways to close a gap

One lane runs the length of this hall and three pits are cut into it, and there is a different cube at each one. The cyan cube carries you across by going somewhere else: your position changes and nothing else does. The orange cube is a slab that turns a quarter circle about the upright, holds for four seconds and turns back. It does not tilt and it does not grow; the gap is bridged by facing differently. The green cube swells until there is no gap left to cross, holds while you walk over it, and shrinks away again. Same pit, three answers, and you will walk all three before the chapter is out.

```gdscript
func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
    var t := Transform3D.IDENTITY
    t = t.scaled(scale_factors)
    t = t.rotated(Vector3.UP, rotation_rad.y)
    t = t.rotated(Vector3.RIGHT, rotation_rad.x)
    t = t.rotated(Vector3.FORWARD, rotation_rad.z)
    t.origin = position
    return t
```

Scale, then rotate, then translate. The order is not a convention. Do it in another order and the same three numbers land the same point somewhere else, and the machine can show you exactly where.

## What each refuses

**Invariants Demo** — `invariants_demo`

A triangle with its measurements written on it: side lengths, angles, area. Press a button and watch which numbers survive. The ones that survive glow green, the ones that change glow red. Slide it and every number stays green. Turn it and every number stays green. Grow it and the angles stay green while the sides and the area go red. Shear it and all three angles go red, two of the sides go with them, and the base and the area hold. Each transformation has a signature, and the signature is what it cannot touch.

**X-Translation Cube** — `x_translation_cube`

Three cubes stand apart in this hall, each allowed one axis. This one slides sideways, on a rail, with four fading ghosts behind it and its one coordinate counting on a label.

**Y-Translation Cube** — `y_translation_cube`

This one lifts. The same operation, and the one that reads least like it.

**Z-Translation Cube** — `z_translation_cube`

This one goes into the depth, where the same displacement reads almost entirely as getting bigger. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it.

## Order

**spin** — `spin`

A row of copies that slides, then turns, then slides again. The turn is inserted in the middle of the process, and it changes the copies without changing where they go. The row stays straight, because every phase adds the same step along the same axis and only the basis is turned. Twelve copies tumble fifteen degrees each, and the last ten stand upside down and still in line.

**Transform Composition** — `transform_composition`

The same house twice: rotated then moved, in blue, and moved then rotated, in red. It lands in two different places, and the two matrices beside it are written out so you can see that the product is different when the factors change sides. Order matters here in a way it never did for adding.

**Rotation Gimbal** — `rotation_gimbal`

Three rings, one inside the other, one per axis, driven by a pad of three sliders. Push the Y slider toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock. It is the reason a rotation is better kept as a single turn about a single axis than as three angles, and the rest of the chapter keeps it that way.

## One matrix

**Homogeneous Coordinates** — `homogeneous_coordinates`

Why four by four for a three-dimensional world. The panel is colour-coded: the block of nine carries rotation and scale, the last column carries translation, and the bottom row is three zeros and a one. That extra row is the trick. It lets a move that is really an addition ride along with the moves that are multiplications, so that all three become one multiplication, and a chain of them is a chain of products.

**Matrix 4x4 Viewer** — `matrix_4x4_viewer`

The same matrix, live. Sliders for the three translations, one rotation and a uniform scale, and a wireframe cube that obeys them while the sixteen numbers update in front of you. This is where the abstraction and the object are the same thing at the same time.

## Moves with something at stake

**balance_puzzle** — `balance_puzzle`

Eight pieces, and a line at forty centimetres. Stack them past it and hold every piece still for a second and a half, and the pile stops being a pile: the eight blocks gather and walk away as a creature. Every drop is a translation and a small rotation, and the test is not the moves. The test is whether the stack is still standing when you take your hands off it.

**scale_me** — `scale_me`

A sphere you can take hold of. Do, and the dark sphere across the hall swells ten times over two seconds. You are not carried with it. In the instant you close your hand, before anything has started to grow, your distance from the room's corner is doubled and your height set to five metres, so you arrive at the new view before the sphere does. It does not come back while you are here, and neither do you. Alice had a bottle for this.

**Pick Up Cube** — `pick_up_cube`

A black cube in orange wireframe, turning and bobbing on its own axis. You cannot carry it. Walk into it and it is gone with a rising chirp and one point on the score, so the translation the room counts here is yours and not the cube's.

**head_crab** — `head_crab`

A small black crab on four jointed legs, which finds you at fourteen metres and comes. Inside two metres it dashes. The bite takes a third of your health and puts you back at the door, so the one thing in this hall that moves itself is also the only one that can undo your walk.

**Dark Sphere** — `dark_sphere`

This is the sphere the grab handle goes looking for. It turns slowly and its purple emission breathes, and otherwise it is only ever acted upon, which is what makes a tenfold change in it legible.

## What stays the same

Here is the question in one sentence: what stays the same when everything changes? Translation keeps everything but position. Rotation keeps everything but direction. Scale keeps the angles and the proportions and gives up the sizes. Shear keeps the area and the side it stands on, and gives up the rest; it is the fourth button on the first panel in the hall, and the chapter does not give it a lane, which is a choice the panel quietly argues with. A transformation is a promise about what will not be touched, and the chapter is a walk through three promises and one that did not get a door.

The next hall is translation on its own, and its floor has holes in it.

*Field notes: The arc, found[^trans-introduction-1] · Exactness decisions[^trans-introduction-2] · Probe[^trans-introduction-3] · Open[^trans-introduction-4] · Verified critique (2026-09-02) — APPLIED[^trans-introduction-5]*

[^trans-introduction-1]: **The arc, found.**
    Palle's ruling (2026-09-02): transformation's red thread is that each move
    *creates space in a different way*. The blurbs already said it, one clause per
    map: translation produces space as extent, rotation produces space as
    anisotropic, scale produces space as relation; the intro is three ways to close
    a gap, the pit the same three from inside. The chapter follows Melencolia and
    opens with "the primitives finally move".

[^trans-introduction-2]: **Exactness decisions.**
    - **Shear keeps area.** The first draft said "shear it and almost nothing
      survives"; `probe_transformation_tutorials.gd` item 1 measured a shear keeping
      the triangle's area exactly. The text now says only the area holds.
    - **The three lane cubes are utilities**, not interactables: `tc` transport
      cube ("carries players across voids"), `rc` rotation cube ("rotates to create
      walkable ramps"), `sc` scale cube ("scales to fill gaps with presence"), per
      `UtilityRegistry.gd`. Cyan/orange/green from the blurb.
    - **scale_me does not rescale the world around you.** `scale_me.gd` finds a
      node named DarkSphere in the scene and tweens its scale ×100 over 5 s, and
      sets the player's position to y = 5 with x, z multiplied by 20; auto-revert
      after 20 s. The registry's "rescales the world around the player" is prose.
      The text says what happens. (Flag: the x,z ×20 on the player is a teleport
      far from the hall in the museum; worth a look.)
    - **invariants_demo** is placed with `pose:rotate` (arrives showing the
      rotated face) and has TRANSLATE/ROTATE/SCALE/SHEAR/RESET/PROJECT buttons, so
      "put it through a move" is true.
    - **head_crab** `#detection:14` reaches `detect_m` (head_crab.gd:395); it
      chases (chase_speed 0.95).
    - **rotation_gimbal** locks within 5° of 90° on the middle ring
      (gimbal_lock_threshold).
    - **balance_puzzle** piece_count 8.
    - "Alice had a bottle for this": the bottle and the cake, not a pill.

[^trans-introduction-3]: **Probe.**
    `commons/testing/probe_transformation_tutorials.gd` (PROBE OK): srt vs trs
    land differently; a*b applies b first; t·invert(t) = identity; the invariants
    table; a square returns under a quarter turn, not an eighth; Rx·Ry ≠ Ry·Rx;
    rotation commutes with uniform scale and not with non-uniform; volume ×8.

[^trans-introduction-4]: **Open.**
    - The `sp` utility ("score points", `score_cube.tscn`) has no script on disk
      under that name; whether it adds to the score or only shows it is unread.

[^trans-introduction-5]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **16 findings survived the editor, 8 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] A cube that can be carried. Translation reduced to a portable primitive, and the sequence's small change: the

    **Problem.** pick_up_cube has no pickable, no rigid body and no grab of any kind. It is a Node3D with an Area3D called DetectionArea; body_entered fires collect(), which adds one point to GameManager, plays a rising chirp and queue_frees the cube 0.1 s later. The script says so in its own header: "This artifact is collected by walking into it." The sentence sends the visitor to grab the one object in the hall that vanishes on contact.

    **Fix.** A black cube in orange wireframe, turning and bobbing on its own axis. You cannot carry it. Walk into it and it is gone with a rising chirp and one point on the score, so the translation the room counts here is yours and not the cube's.

    **Evidence.** Verified in commons/scenes/mapobjects/pick_up_cube.gd (collect at :218, add_points :227, queue_free :249, body_entered :258) and pick_up_cube.tscn, whose only nodes are DetectionArea (Area3D, mask 524288) and CubeBaseMesh. The registry's "grab-and-carry cube" is the wrong prose. This same error is repeated in five rooms.

    ### [wrong] The orange cube turns a floor into a ramp: the gap is bridged by facing differently, not by moving.

    **Problem.** No ramp. The token is rc:90:y:4:-0.6, which the grid reads as ninety degrees about Vector3.UP with a four second pause, and rotation_cube.gd applies it as mesh_instance.rotation_degrees = rotation_axis * current_angle on a box of 2.2 by 2.2 by 1.0. A quarter turn about the upright yaws the slab like a door. Nothing tilts. "Rotates to create walkable surfaces" is the script's own header comment, not its behaviour.

    **Fix.** The orange cube is a slab that turns a quarter circle about the upright, holds for four seconds and turns back. It does not tilt and it does not grow. The gap is bridged by facing differently, not by moving.

    **Evidence.** Verified: GridUtilitiesComponent.gd rc branch maps axis "y" to Vector3.UP and parameter 4 to pause, parameter -0.6 to y_offset; rotation_cube.gd:57 builds BoxMesh(2.2, 2.2, 1.0) and :122 rotates on the chosen axis only.

    ### [wrong] The turn is inserted in the middle of the process, and because of that the second slide goes a different way.

    **Problem.** Two errors. All three phases do current_transform.origin.x += translation_step, and rotated_local multiplies the basis from the right, so it never touches the origin. The baked buffer proves it: thirty-three instances, y constant at 3, z constant at 0.05, x advancing by 0.14 from -2.4098 to 2.0702. The row is dead straight and the second slide goes exactly the same way. And there is no plinth: the token is spin:0:1, and the grid stands a plinth only when the token carries #plinth:H, which three other tokens in this map do and this one does not.

    **Fix.** The turn is inserted in the middle of the process, and it changes the copies without changing where they go. The row stays straight, because every phase adds the same step along the same axis and only the basis is turned. Twelve copies tumble fifteen degrees each, and the last ten stand upside down and still in line.

    **Evidence.** Verified in algorithms/transformation/spin/spin.gd:81, :89-90, :98 and the MultiMesh buffer in spin.tscn; plinth gating at GridInteractablesComponent.gd:1338 (config_data.has("plinth")); token at Trans_Introduction/map_data.json row 17.

    ### [wrong] Eight pieces to stack until the pile stops moving. Every drop is a translation and a small rotation, but the p

    **Problem.** The puzzle never tests the centre of mass. The win condition is a height line at 0.4 m and then every piece under a linear velocity of 0.05 for 1.5 continuous seconds. Centre of mass is computed once, inside _transform_to_walker, after you have already won, only to place the walker. Below the line the stability timer is reset every frame, so "stops moving" is not sufficient either. And the paragraph omits what actually happens: the eight blocks gather and walk away as a creature.

    **Fix.** Eight pieces, and a line at forty centimetres. Stack them past it and hold every piece still for a second and a half, and the pile stops being a pile: the eight blocks gather and walk away as a creature. Every drop is a translation and a small rotation, and the test is not the moves. The test is whether the stack is still standing when you take your hands off it.

    **Evidence.** Verified in commons/primitives/balance/balance_puzzle.gd:48 (height_threshold 0.4), :51 (stability_time 1.5), :54 (velocity 0.05), :57 (piece_count 8), :323-357 (_update_stability_check), :378 (_transform_to_walker, centre computed after the trigger).

    ### [wrong] Shear it and the sides and the angles go red and only the area holds.

    **Problem.** The base side holds too. SHEAR does x += 0.4 * (y - base_y) with base_y read from vertex 0, and in all three figures the demo can build, vertices 0 and 1 sit at the same y, so the base has zero shift at both ends and its length is unchanged. The tag comparison uses an absolute tolerance of 0.01, so it renders green. On the equilateral default: base 0.30 unchanged, the other two sides 0.30 to 0.264 and 0.363, all three angles moved, area unchanged. "Only the area holds" is the one claim on that panel a visitor can disprove by reading it.

    **Fix.** Shear it and all three angles go red, two of the sides go with them, and the base and the area hold.

    **Evidence.** Verified in algorithms/transforms/invariants/invariants_demo.gd:394-399 (shear), :100-112 (all three vertex sets have verts 0 and 1 at equal y), :477-479 (_invariant_color, tolerance 0.01). I recomputed the side lengths by hand.

    ### [wrong] Do, and the dark sphere in this hall grows a hundred times over five seconds while you are lifted and carried

    **Problem.** Wrong on every number, and wrong about what happens to you. The critic who filed this read the .gd defaults; the scene the map instantiates overrides all of them. scale_me.tscn sets scale_amount = 10.0, scale_up_time = 2.0, scale_down_time = 2.0 and scale_duration = 1000.0. So the sphere grows ten times over two seconds, and the revert timer is a thousand seconds, which nobody walking this hall will see. You are not carried either: at the instant of the grab, before the tween is created, the script writes the origin's global position once, to (x times scale_amount/5, 5, z times scale_amount/5), which here is a doubling of x and z and a height of five metres. On the way back the code comments "Don't move player when scaling down" and tweens only the world node.

    **Fix.** A sphere you can take hold of. Do, and the dark sphere across the hall swells ten times over two seconds. You are not carried with it. In the instant you close your hand, before anything has started to grow, your distance from the room's corner is doubled and your height set to five metres, so you arrive at the new view before the sphere does. It does not come back while you are here, and neither do you. Alice had a bottle for this.

    **Evidence.** Verified: algorithms/primitives/scaleme/scale_me.tscn:8-11 overrides the four exports; scale_me.gd:118-126 writes the position in one step before the tween at :129-132; :174-181 deliberately leaves the player. The registry maps the token scale_me to that .tscn. I corrected the critic's numbers, which came from the script defaults rather than the placed scene.

    ### [wrong] Three lanes leave this hall, one per move, and each is a cube.

    **Problem.** One lane, three pits. The structure layer cuts three three-by-three pits into the centre columns at rows 6 to 8, 11 to 13 and 16 to 18, and puts a different cube at each: tc at row 5, sc at row 12, rc at row 17. Rows 9 and 15 seal the two side corridors with height-2 walls, so nothing leaves the hall down them.

    **Fix.** One lane runs the length of this hall and three pits are cut into it, and there is a different cube at each one.

    **Evidence.** Verified against Trans_Introduction/map_data.json structure rows 6-8, 11-13, 16-18 (cols 4-6 void) and rows 9 and 15 (cols 0-3 and 7-10 all "2"), with the tc, sc and rc utility cells where the critic says.

    ### [wrong] A small black crab on four jointed legs, looking for you from a distance, and following.

    **Problem.** It does not only follow. can_bite is true, the token sets detection to fourteen metres, and inside 1.9 m it commits to a dash at 4.2 m per second and bites for thirty-four of your hundred health, eighteen on a walk-up contact. Damage routes through GameManager.apply_health_damage, which red-flashes and puts you back at the spawn point. This is the only thing in the hall that can undo your walk and the text does not mention it, so the visitor learns it by being bitten.

    **Fix.** A small black crab on four jointed legs, which finds you at fourteen metres and comes. Inside two metres it dashes. The bite takes a third of your health and puts you back at the door, so the one thing in this hall that moves itself is also the only one that can undo your walk.

    **Evidence.** Verified in commons/hazards/head_crab/head_crab.gd:97-101 (can_bite, contact 18, lunge 34, lunge_range 1.9, lunge_speed 4.2), :251 (LEG_COUNT 4); token head_crab:180#detection:14; GameManager.gd:44 (max 100) and :370-387 (hurt then return to spawn).

    ### [weak] Turn the middle ring toward ninety degrees and the outer and inner rings come into line, and at that moment on

    **Problem.** You cannot turn the ring. The rig is driven by a three-slider pad labelled X, Y and Z with a reset button; the rings are torus meshes on nested pivots and nothing on them is grabbable. Everything else in the sentence is exact: outer is X, middle is Y, inner is Z, and the alarm arms within five degrees of ninety.

    **Fix.** Push the Y slider on the pad toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock.

    **Evidence.** Verified in commons/artifacts/rotation_gimbal/rotation_gimbal.gd:161-191 (outer X pitch, middle Y yaw, inner Z roll), :463-488 (create_parameter_panel with labels X, Y, Z plus ResetButton), :17 (gimbal_lock_threshold 5.0).

    ### [weak] ## What each refuses

    **Problem.** Three of the six artifacts under this heading refuse nothing. invariants_demo and the three axis cubes are about invariance; spin, transform_composition and rotation_gimbal are about composition order and about what three-angle bookkeeping costs. The room's thesis is invariance, and the section that ought to deliver it is diluted by the section that should follow it.

    **Fix.** Close the run after the three axis cubes with a bare closing comment, and open a second heading at spin: "## Order". Then spin, transform_composition and rotation_gimbal argue one case together, and "What each refuses" is left holding only what refuses something.

    **Evidence.** One-line insertion, no prose rewritten. The exemplars keep headings tight to their runs: Melencolia's four sections each cover what they name, and Gravity's "## Three" covers exactly the three-body pieces.

    ### [weak] ## One matrix

    **Problem.** The heading stops describing its contents after two artifacts. It covers homogeneous_coordinates and matrix_4x4_viewer, then runs on through balance_puzzle, scale_me, pick_up_cube, head_crab and dark_sphere, none of which is about a matrix. From that point the room stops arguing and starts listing what is left, which is the one thing none of the three exemplars does.

    **Fix.** Keep "## One matrix" for homogeneous_coordinates and matrix_4x4_viewer, close the run after the viewer with a bare closing comment, and open a second heading at balance_puzzle: "## Moves with something at stake". Those are the ones where a transformation costs you something, which is a claim, and it sets up the closing.

    **Evidence.** Confirmed against final.md lines 54-84: seven artifact regions under one heading. Also a one-line insertion.

    ### [weak] Shear keeps only the area, which is why it is not one of the three lanes.

    **Problem.** The causal clause is not a reason, and the fact repeats the error upstream: shear keeps the base as well as the area. The room also has a real tension here and ducks it. The opening says there are exactly three ways a thing can move, and the first panel the visitor presses has a fourth button on it.

    **Fix.** Shear keeps the area and the side it stands on, and gives up the rest. It is the fourth button on the first panel in the hall, and the chapter does not give it a lane, which is a choice the panel quietly argues with.

    **Evidence.** Verified: invariants_demo.gd:325-341 builds TRANSLATE, ROTATE, SCALE, SHEAR, PROJECT, RESET; the shear arithmetic is at :394-399.

    ### [weak] A dark sphere that does almost nothing. It changes so little that the changes around it become readable, which

    **Problem.** It contradicts the room twelve lines earlier, where the same sphere grows ten times under the pill. It is also the registry's sentence reworded, and it undersells the code: a slow yaw at 0.15 rad/s, a sine wobble on X, and an emission pulse between 0.05 and 0.35 every frame. The hall has a better claim available for free, because this is the object the grab sphere acts on.

    **Fix.** This is the sphere the grab handle goes looking for. It turns slowly and its purple emission breathes, and otherwise it is only ever acted upon, which is what makes a tenfold change in it legible.

    **Evidence.** Verified: dark_sphere.gd:455-458 and :589-609; scale_me.gd:67 searches the scene for a node named DarkSphere, and dark_sphere.tscn's root carries that name. In this map the sphere is placed at row 7 and the pill at row 12, so the search finds it.

    ### [polish] Three cubes, each allowed one axis. One slides sideways, one lifts, one goes into the depth, and each leaves g

    **Problem.** The paragraph sits after the third comment, so the x and y regions open onto nothing and only z carries wall text. The three cubes are also in three different parts of the hall, at rows 5, 7 and 12, so a visitor meets them one at a time and never sees the trio the paragraph describes. The label prints one coordinate, not three.

    **Fix.** Give each region its own line. Under x: "Three cubes stand apart in this hall, each allowed one axis. This one slides sideways, on a rail, with four fading ghosts behind it and its one coordinate counting on a label." Under y: "This one lifts. The same operation, and the one that reads least like it." Under z: "This one goes into the depth, where the same displacement reads almost entirely as getting bigger. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it."

    **Evidence.** Verified: the cubes are at map rows 5, 7 and 12; axis_translation_cube.gd:274 prints the moving axis only, and the default account "ghost" builds a rail, two markers and four fading ghosts. No exemplar leaves a tag region empty.

    ### [polish] Each of the three moves has a different answer, and that answer is its name.

    **Problem.** It contradicts the thesis one sentence after stating it. Translation is named for what it changes, not for what it keeps, and so are the other two. The room already has the clean version further down, "the signature is what it cannot touch", so this line is a muddier duplicate standing in the load-bearing position.

    **Fix.** Each of the three moves has a different answer, and each is named for the one thing it gives up.

    **Evidence.** Internal to final.md lines 1 and 3. One clause changed.

    ### [polish] Next: translation on its own, and a floor made of it.

    **Problem.** The image is wrong. The next hall's floor is not made of translation; it has holes cut in it that translation crosses, which is that room's own first line.

    **Fix.** The next hall is translation on its own, and its floor has holes in it.

    **Evidence.** Trans_Translation/final.md:3 opens "This hall has holes in its floor." One line changed.

#### Trans Translation

Translation changes nothing about a thing except where it is. That is why a void can be crossed by it, and why a path can be kept as nothing but a list of positions.

This hall has holes in its floor, and every one of them is the trace of a translation. Three slots run away from you, each exactly as wide and as long as the cube that travels it, and the cube is the only way across: the first carries you straight, the second turns you a quarter on the way, the third grows the space around you by a third and gives it back on the return. One slot runs sideways. Three holes stand in the front of a raised floor with a lift in each, and you enter them by dropping in and leave them on top. One slot runs down through that floor, a cube sliding forward and down at once. The whole room is displacement made into infrastructure, and the emptiness is the drawing of it. Nothing here is reshaped by being moved, which is not the same as nothing turning: the cubes you collect spin on the spot, and two of the rides turn you with them.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

One assignment, and the object is elsewhere. Everything it was, it still is.

## Over the void

**player_trace** — `player_trace`

Your own path, drawn. Every step you take writes another point, and the line behind you is not only where you were. It is tinted by how fast you got there, green where you dawdled and amber where you ran, full amber at two metres a second. The recorder keeps three lists: positions, times, speeds. The first sentence of this room says a path can be kept as nothing but positions, and the first thing in it keeps more.

**Z-Translation Cube** — `z_translation_cube`

A cube on a rail that runs away from you, sliding forty centimetres out and forty back, with four ghosts of itself shrinking behind it. Watch what your eye does. Depth is the one direction in which a pure displacement is read as a change of size, and nothing about the cube has changed at all.

**Y-Translation Cube** — `y_translation_cube`

This one lifts, on its own rail, with its own ghosts. Those are the two directions this hall mostly uses to get you across: the transport cubes go forward, and they go up. Once, in the middle of the hall, one goes sideways, and once one goes forward and down at the same time.

**Pick Up Cube** — `pick_up_cube`

Seven cubes, each turning on its own axis and bobbing: six standing on the ground, one of those up on the raised floor, and one hanging over the hole near the entrance. You cannot pick one up. Walk into it and it is gone with a rising chirp, and the score is one larger. The only thing translated here is you: the cube never moves at all, and the count is what your crossing leaves behind.

**Pickup Gate** — `pickup_gate`

The gate at the end counts. It wants seven on the score you have been carrying since the first hall, and for the first time the hall holds seven of its own, the last of them up on the raised floor. The cube beside the gate displays the number, and the gate is closed until the count gets there and open the moment it does. Nothing about the gate is clever, and that is the point: enough crossings changed a number, and the number changed a wall.

**Synthesis Stand** — `synthesis_stand`

The cube you have been walking into has a family: wire, steel, clay, crate and foam, five stocks of the same object. The measurements ruled the family a series, so there is no hero to pin. Told to show one anyway, the plinth takes the far end of the measured ladder and stands it up: foam. The plaque says pick_up_cube stock=foam and nothing else, because a series verdict carries no single number to print. Every cube in the room is the near end, wire, the shipped form nobody chose.

**Science Screen** — `science_screen`

The screen is set to track a point, and there is no point in this hall for it to track. It wants a neighbour with the word point in its name and a body it can hold, finds none, and draws the instrument anyway: POINT POSITION, P = (x, y), a grid, and a dot pinned at the origin reading plus zero with a trail of nothing. Along the bottom it recites this map's own blurb. A diagram of translation with the translation left out is the most honest object in the room.

**Transform Composition Workbench** — `transform_composition_workbench`

A workbench with a slider that picks one of four pairs of moves. The same tetrahedron is shown three times: pale and untransformed in the middle, then done in one order on the left and the other on the right, with an arrow from the ghost to each result. Three of the four pairs land in different places, and a badge over the stage says so. None of the four is the pair this hall is about. Two translations always commute, whatever their directions and however many, which is why nothing you do in this room has an order: take the cubes in any sequence and you reach the gate with the same count. Translation is the operation that does not care, and the rotation halls are where that stops being true.

**Dark Sphere** — `dark_sphere`

A dark sphere that never leaves its cell while you cross. It is not still: it turns slowly, it wobbles, and its glow breathes between dim and dimmer. It is the room's control, and a strict one, because the only thing it refuses to do is the one thing everything else here does.

**Mario Cube** — `mario_cube`

Eight yellow cubes, one at the far end of every hole: past the three slots, at the landing of the sideways slot, on top of the raised floor where each lift arrives, and at the foot of the slot that comes down. They are the places you were meant to reach, and they know when you have. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The room's control is the price of the first crossing, and darkness becomes colour at the moment a hole has been crossed. The others keep their rainbows, and the sphere does not come back.

## Here becomes there

The gaps in this floor are not obstacles. They are invitations, because translation is the operation that does not care what lies between two positions, and every gap here is the exact size of the move that crosses it: the hole is the drawing of the translation, and the translation is the only way through the drawing. And the transport cube does cross the void, slowly. Stand on it, wait a second, and it moves at two metres a second toward the far side, and on every frame it adds the distance it just moved to your position as well as to its own. You are not transported. You are added to, frame by frame, by a cube doing to you exactly what the first line of code did to the object.

That is translation's promise, and it is the only transformation in the chapter whose promise covers you.

The next hall takes the same operation apart into three, in a room that forbids you two of them at a time.

*Field notes: Exactness decisions[^trans-translation-1] · Continuity[^trans-translation-2] · Verified critique (2026-09-02) — APPLIED[^trans-translation-3] · The rethink (2026-09-05): the hole is the way[^trans-translation-4]*

[^trans-translation-1]: **Exactness decisions.**
    - **The gate counts the GameManager score, not this hall's cubes.**
      `pickup_gate.gd` connects `score_updated` and opens when the running score
      reaches `required_pickups` (7 here). Five `pick_up_cube` are placed
      (points_value 1 each); the other two come from earlier halls. The first draft
      said "seven cubes". The text now says the gate wants seven on the score you
      carry.
    - **science_screen `mode:point`** is a real mode (`_set_explicit_mode`: point,
      line, trace/draw, triangle, net/cube): it tracks a grabbed point. The text
      says carry a cube in front of it.
    - **synthesis_stand `#subject:pick_up_cube#mode:hero`**: the verdict file
      `commons/data/dna_synthesis.json` rules pick_up_cube a SERIES on axis `stock`
      (wire, steel, clay, crate, foam); a hero of a series-verdict subject pins the
      top evidence variant. The text names the five stocks.
    - **Axes in this hall**: transport cubes `tc:3:z`, `tc:1:y:auto`, `tc:3:y`,
      `tc:2:y`, `tc:6:y`; the two axis cubes placed are z and y. "Nothing asks you
      to go sideways" is from the utilities.
    - **transform_composition_workbench**: pair 2 (rotation × uniform scale)
      commutes, per its description and probe item 6.

[^trans-translation-2]: **Continuity.**
    player_trace from Point_Trace (the line as positions); the void as invitation
    from the blurb.

[^trans-translation-3]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **12 findings survived the editor, 7 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] Cubes to carry, five of them, scattered on both sides of the void. Carrying is the smallest translation there

    **Problem.** You cannot carry a pick_up_cube; walking into it deletes it. And "nothing about the cube changes" is contradicted by the cube itself, which spins at 2 rad/s and bobs 0.2 m the whole time. One of the five also stands on a void cell, so "scattered on both sides" undersells what you see.

    **Fix.** Five cubes, each turning on its own axis and bobbing, four standing on floor and one hanging over the hole near the entrance. You cannot pick one up. Walk into it and it is gone with a rising chirp, and the score is one larger. The only thing translated here is you: the cube never moves at all, and the count is what your crossing leaves behind.

    **Evidence.** Verified: pick_up_cube.gd:142-152 (rotate_y 2.0, bob 0.2), :218-249, :258-261; the cube at interactables row 3 col 5 sits over structure row 3 col 5, which is "0".

    ### [wrong] The transport cube does not cross the void; it is at one end, and then at the other, and the only thing the ma

    **Problem.** This describes the one-line snippet at the top of the page, not the artifact. The transport cube crosses continuously: on body_entered it waits a second, then move_toward at 2.0 m per second, and on every frame it adds its own movement delta to the carried player's global position, waits three seconds at the far end and drives back. It is the slowest thing in the hall, and riding it is the room's central bodily fact. The thing that does jump is the teleporter at the exit, which the text never names. This is the closing paragraph, so the room lands its argument on a false observation.

    **Fix.** The transport cube does cross the void, and slowly. Stand on it, wait a second, and it moves at two metres a second toward the far side, and on every frame it adds the distance it just moved to your position as well as to its own. You are not transported. You are added to, frame by frame, by a cube doing to you exactly what the first line of code did to the object.

    **Evidence.** Verified in commons/scenes/mapobjects/transport_cube.gd:8-13 (move_speed 2.0, return_delay 3.0, start_delay 1.0) and :169-219 (move_toward plus carried_player.global_position += movement_delta).

    ### [wrong] The screen is set to track a point. Carry a cube in front of it and the screen draws where the cube goes, as c

    **Problem.** The screen tracks nothing here and cannot be made to. #mode:point locks the mode and runs one scan, which latches a sibling only if its lookup name or node name contains the substring "point" and it has a freeze property. Nothing in this map matches either test, so _tracking_point stays null and the tracker paints its dot dead at the origin with the readout at plus zero. Nothing can be carried in front of it either. What the screen genuinely does goes unmentioned: it loads this map's blurb.md into the bar along the bottom.

    **Fix.** The screen is set to track a point, and there is no point in this hall for it to track. It wants a neighbour with the word point in its name and a body it can hold, finds none, and draws the instrument anyway: POINT POSITION, P = (x, y), a grid, and a dot pinned at the origin reading plus zero with a trail of nothing. Along the bottom it recites this map's own blurb. A diagram of translation with the translation left out is the most honest object in the room.

    **Evidence.** Verified: science_screen.gd:405-453 (_set_explicit_mode, _mode_locked), :466-477 (locked modes skip the scan and only call _connect_tracking_for_mode), :1275-1303 (the "point" plus freeze test), :1905-1910 (pos = ZERO when null), :324-372 (blurb.md into the info bar).

    ### [wrong] Nothing here turns and nothing grows.

    **Problem.** Three things turn and one grows, and the growing one is how you cross the widest hole. Every pick_up_cube runs rotate_y at 2 rad/s. The dark sphere turns at 0.15 rad/s. And the cell in the middle of the full-width chasm at row 17 is sc:3:-0.5:1:-1, a scale cube: it swells to a 3 m cube at 1 unit per second, holds four seconds with its collider walkable, then shrinks away and starts again. The sentence carries the room's purity claim, so it has to be true, and the honest version names the crossing the text otherwise omits entirely.

    **Fix.** Nothing here is reshaped by being moved, which is not the same as nothing turning: the cubes you collect spin on the spot, and the cube in the widest chasm swells to three metres, holds for four seconds while you walk across it, and shrinks away again.

    **Evidence.** Verified: map_data.json utilities row 17 carries sc:3:-0.5:1:-1 and structure rows 17 and 18 are entirely void; scale_cube.gd:9-14 (max 3.0, speed 1.0, pause_at_max 4.0) and :97-125 (is_walkable at 0.95 of max); GridUtilitiesComponent sc branch reads max, min, offset_x, y_offset in that order.

    ### [wrong] The measurements ruled the family a series, and this plinth, told to show a hero, pins the one variant the mea

    **Problem.** Both claims are false. A forced hero of a series verdict does not pin the highest-ranked variant; _build_hero takes order[order.size() - 1], the far end of the measured ladder, which the export's own comment states. For pick_up_cube that order is wire, steel, clay, crate, foam, so the plinth carries foam. And there is no number: the plaque appends a percentage only when score is above zero, and the pick_up_cube verdict has no score key at all. The plaque reads "pick_up_cube  stock=foam" and stops.

    **Fix.** The measurements ruled the family a series, so there is no hero to pin. Told to show one anyway, the plinth takes the far end of the measured ladder and stands it up: foam. The plaque says pick_up_cube stock=foam and nothing else, because a series verdict carries no single number to print. Every cube in the room is the near end, wire, the shipped form nobody chose.

    **Evidence.** Verified: synthesis_stand.gd:105-132 (order[-1] at :107-111, score gate at :127-131) and :26; commons/data/dna_synthesis.json verdicts.pick_up_cube has verdict "series", order wire/steel/clay/crate/foam, span and evidence, and no score key.

    ### [wrong] Every step you take writes another point, and the line behind you is translation and nothing else: a time-inde

    **Problem.** The line is not translation and nothing else. velocity_color defaults to true and the .tscn does not override it, so the rebuild sets a per-vertex colour from speed, lerping the green trail toward amber and reaching full amber at 2.0 m per second. The recorder keeps three parallel arrays: points, times and speeds. The room's opening thesis is that a path can be kept as nothing but positions, and the room's first artifact keeps the derivative too. That is not a flaw to hide; it is the best complication in the hall, and the exemplars do exactly this.

    **Fix.** Every step you take writes another point, and the line behind you is not only where you were. It is tinted by how fast you got there, green where you dawdled and amber where you ran, full amber at two metres a second. The recorder keeps three lists: positions, times, speeds. The first sentence of this room says a path can be kept as nothing but positions, and the first thing in it keeps more.

    **Evidence.** Verified: player_trace.gd:28-30, :390-399 (three arrays), :466-469 (_velocity_to_color), :505-521 (per-vertex colour); velocity_color does not appear in player_trace.tscn.

    ### [wrong] Translation with anything is not that exception, and you will see why in the rotation halls.

    **Problem.** Two translations always commute, and this is the translation hall, so the sentence throws away the room's strongest available claim and states a falsehood to do it. The workbench never tests it either: its four pairs are rotate Y with translate X, rotate Z with uniform scale, translate X with scale, and two rotations. Translation composed with translation is not on the slider, and naming that absence is more interesting than the false generalisation.

    **Fix.** None of the four pairs is the one this hall is about. Two translations always commute, whatever their directions and however many, which is why nothing you do in this room has an order: take the cubes in any sequence and you reach the gate with the same count. Translation is the operation that does not care, and the rotation halls are where that stops being true.

    **Evidence.** Verified: transform_composition_workbench.gd:180-216 defines exactly those four pairs.

    ### [weak] A dark sphere that stays still while you cross.

    **Problem.** It stays in its cell, but it is not still: _process turns it on Y at 0.15 rad/s, wobbles it on X, and pulses its emission between 0.05 and 0.35. In a hall whose second paragraph is being corrected because it claims nothing turns, singling this out as the still thing puts the room's one honest control in the wrong category. The precise fact is better: it is the only object here that never changes position, and it does everything else.

    **Fix.** A dark sphere that never leaves its cell while you cross. It is not still: it turns slowly, it wobbles, and its glow breathes between dim and dimmer. It is the room's control, and a strict one, because the only thing it refuses to do is the one thing everything else here does.

    **Evidence.** Verified: dark_sphere.gd:455-458 and :589-609. Keeping this consistent with the corrected "nothing here turns" sentence is the point.

    ### [weak] <!-- @z_translation_cube -->

    **Problem.** The region opened for the z cube contains nothing. Both cubes are covered in the paragraph under the y tag, so anything reading a region as its artifact's text gets an empty string for z and a doubled paragraph for y, and the visitor never learns why this is the member the family is proudest of. Its rail runs into the picture, so the same displacement is read almost entirely as a change of size, which is precisely the confusion a translation room exists to clear up.

    **Fix.** Put a paragraph in the empty region: "A cube on a rail that runs away from you, sliding forty centimetres out and forty back, with four ghosts of itself shrinking behind it. Watch what your eye does. Depth is the one direction in which a pure displacement is read as a change of size, and nothing about the cube has changed at all."

    **Evidence.** Verified: final.md lines 18-21 leave the z region empty; axis_translation_cube.gd:29-43 gives travel 0.4 m, cube 0.15 m and four ghosts, and z_translation_cube.tscn sets the depth course. No exemplar leaves a tag region empty.

    ### [weak] Walkways cross them, and transport cubes shuttle over gaps your feet cannot, rising and falling and sliding on

    **Problem.** There is one walkway, not walkways: a single walkable prism at row 8 column 2, and it does not span anything, because the cells either side of it are void and the cell behind it is a wall two high. It is a ramp. The plural comes from blurb.md, which is the map's own prose rather than its code. Meanwhile the crossing the sentence should be naming, the scale cube in the full-width chasm, is absent from the whole page.

    **Fix.** One ramp, five transport cubes that lift and slide on a single axis apiece, and in the widest chasm a cube that grows until you can stand on it. The whole room is displacement made into infrastructure.

    **Evidence.** Verified: one wp:0:0.5 at utilities row 8 col 2 with structure row 8 reading void at cols 1 and 3 and row 9 col 2 reading "2"; five tc cells (one z, four y); the sc cell at row 17.

    ### [polish] It wants seven on the score you have been carrying since the first hall, and it is closed until the count gets

    **Problem.** True, and it leaves out the object standing beside the gate that makes the claim checkable. The two sp cells in this map are not spawn points, whatever the map's own utility_definitions block says: sp resolves to score_cube.tscn, a cube with a Label3D showing GameManager's running score. One stands a row from the gate. The gate and the cube are reading the same integer, which is the paragraph's whole argument made visible.

    **Fix.** It wants seven on the score you have been carrying since the first hall, the same number the cube beside it is displaying, and it is closed until the count gets there and open the moment it does.

    **Evidence.** Verified: UtilityRegistry.gd maps "sp" to score points, score_cube.tscn; the map's own utility_definitions calls it a spawn and nothing reads that. sp sits at row 20 col 3, the gate at row 21 col 5.

    ### [polish] The same tetrahedron is shown twice, done in one order on the left and the other order on the right, and three

    **Problem.** Three tetrahedra stand on the workbench, not two. _build_stage builds a pale untransformed ghost in the centre between the two results, with a trajectory arrow from the ghost's centroid to each, blue to the left and pink to the right. The ghost is what makes the two results legible as two answers to one question, and there is a badge over the stage that reads commutes or non-commutative as you move the slider.

    **Fix.** The same tetrahedron is shown three times: pale and untransformed in the middle, then done in one order on the left and the other on the right, with an arrow from the ghost to each result. Three of the four pairs land in different places, and a badge over the stage says so.

    **Evidence.** Verified: transform_composition_workbench.gd:309-313 and :350-358 (ghost), :387-398 (arrows in color_left and color_right), :54-60 (badge).

[^trans-translation-4]: **The rethink (2026-09-05): the hole is the way.**
    Palle, after the three galleries: *"Do you understand the syntax and the
    principal of these maps? It is all about how transformation creates empty
    space. So the holes are the pathway up down to the side as a result of
    translation rotation and scale."* And when the first draft answered with walls
    that open and a cube that fills a pit: *"I mean not fill hole that is another
    question I mean just structure 0."* The ruling is in
    `commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
    generator that made it (traces, banks and cell-sharing checked) is the session's
    `rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
    only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
    rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
    holes lead.

    **What the holes are now.** Three slots along z from row 5 (`tc:4:z` plain at
    x2, `#rot:90` at x5 in a 3-wide slot, `#scale:1.3` at x8; rows 6-8 void, walls
    between); a slot to the side at row 13 (`tc:7:x`, x2-7 void, walled at (1,14)
    and (8,12) so the ride is the way); three holes in the front of a 2-plateau at
    row 15 with lifts standing in them (`tc:1.5:y:auto` plain, `#rot:90` in a
    3-wide notch, `#scale:1.25`); one slot down through the plateau
    (`tc:2.24:0,-1,2` from (4,16) through (4,17) into (4,18)). Eight Mario cubes;
    two pick-ups added at (1,9) and (7,16) so the gate's seven exist in the hall.
    The ramp, the old lifts and the scale cube in the chasm are gone. The other
    session's rows (structure and interactables row 0, row 23) were not touched.

    **Templates learned, and what each cost.**

    - **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
      in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
      6-8). A ride that stops in the last void cell strands the rider a metre
      short, which is what once stranded Palle between two chapters.
    - **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
      is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
      plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
      the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
      (Translation, AxisDecomposition, Rotation); the museum's door halls read
      height 2 as wall.
    - **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
      because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
      walls.
    - **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
      at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
      rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
      at the far bank, the template's own terms; `rc:90` pauses closed at both
      ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
      StaticBody turned by script, no platform velocity: a rider is not carried,
      so rolling cubes are spectacle and a turntable is crossed on foot.
    - **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
      offset_x 1 puts the centre in the middle). The galleries commit had it at
      the centre column, overhanging the bank by a metre.
    - **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
      `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
      sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
      signed axes and vectors, and a plank or turntable joins its banks two cells
      out; a cube rolling about x or z joins nothing.
    - **The Mario cube took the first node named DarkSphere in the whole tree**,
      which in the museum could be another hall's; it now takes the nearest
      (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
      room's own sphere, so the first crossing removes the room's control, and the
      wall text says so.
    - **Rides are utilities, artifacts are placements.** The museum reads a hall's
      structure and utilities live, but a door hall's artifacts come from
      `ada_run/em_plan.json`: the five transformation rows were re-derived from
      the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
      have re-derived 23 rows other sessions were editing, so the patch was partial
      and says so in the plan's `_map_halls` stamp.

    **Open.** Nobody has walked the rebuilt hall in VR. The rides' auto cycle is
    5.5 s (start delay 1, travel at 2 m/s, return delay 3); a rider who steps off
    mid-ride is put back to size. The `t` at (5,22) still stands on floor, which
    the pathfinder warns about as it always has.

    **Learned after the bake (2026-09-05, later).** The museum seals every body's
    cells in its walk map, a walk-into trigger included, and refuses a seal that
    would cut the route ("sealing would sever the walk route"), then SLIDES the
    body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
    Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
    12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
    a landing pocket none, so two of its three Mario cubes were slid into walls.
    They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
    the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
    three metres up) was built at `_ready`: the museum's extent counts every
    MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
    so the cube seals its one cell; the registry's measured footprint (17) is stale
    by the same amount. The Spectacle's twelve stood exactly where placed, because
    its rows are thirteen wide.

#### Trans AxisDecomposition

Every displacement is three independent displacements, one per axis, and you only feel that when the room forbids you two of them.

More than a third of this hall's floor is missing, and every missing cell is where a cube goes. What floor there is comes in islands, and the way between them is five transport cubes, each of which moves on one line only: one runs the length of the hall to the island, one runs back the other way, one runs across to the west, one runs diagonally into the last room, and one stands in a hole in a raised floor and lifts. Four of them wait until you are standing on them. The lift does not, so you have to arrive when it does. You arrive high on the east ledge, and the gate and the way out are both two steps from where you land. Everything the hall has to teach is west of them, across the missing floor, and nothing makes you go. Cross anyway, and you find that wanting to be somewhere means wanting three directions in turn, because no cube gives you two at once, until the diagonal does, and the slot it cuts is the sum of the two it replaces.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]

func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Take a displacement apart into three numbers, and put it back together from three arrows laid tip to tail. The three are all there is, with one catch the machine will show you if you try it: forward in this engine is minus z, so the third arrow comes back pointing the other way unless you say which way forward is. Decomposition is exact. Reconstruction has to agree about the axes.

## One axis at a time

**Translation Cube Demo** — `translation_cube_demo`

Two doors in a wireframe box, one red and one blue, each of which will only move along the axis the box currently allows. Push one sideways when it wants to go up and it resists. Complete the lift, and the slide is permitted, and then you do the whole of it again with the other. The constraint is the lesson: direction is part of the operation, not a detail added afterwards. The order belongs to the door and not to the arithmetic. The two displacements add to the same place either way, so the door has to impose a sequence to make you feel them apart.

**X-Translation Cube** — `x_translation_cube`

**Z-Translation Cube** — `z_translation_cube`

The sideways cube and the depth cube, each on its own rail, each trailing four shrinking ghosts of where it just was, each printing its one coordinate to three decimals as it goes. There is a speed slider on the rack in front of them. Slow the cube down until you can read the number changing, and watch the other two digits not change at all.

**Basic Cube Scene** — `cube_scene`

One cube, a metre on a side, hanging three metres above the widest gap in the floor. It is the chapter's plain solid, the thing everything else is measured against, and here it is out of reach, marking the crossing rather than making it.

**Torus Cylinder** — `toruscylinder`

Beside the maze, two motions that are not the same family. A torus turns, and a cylinder rises and falls and leaves a trail. The turning never changes where the torus is. The rising never changes which way the cylinder faces. Put side by side, the two show what this chapter keeps separate: a rotation and a translation can happen in the same place at the same time and share nothing.

**Pick Up Cube** — `pick_up_cube`

Six cubes, turning and bobbing: one in the north room, one up on the raised floor, four on the south floor. You do not carry them. Walk into one and it is gone with a rising chirp, and the number the gate is watching goes up by one.

**Pickup Gate** — `pickup_gate`

The gate wants six on the running score. The last hall would not let you leave until you had seven, so this one is open before you reach it: the same rule, already satisfied, standing there so you can watch a condition follow you between rooms. The six cubes in this hall are the count it would have asked for on its own.

**Dark Sphere** — `dark_sphere`

A dark sphere on the floor of the northern island, turning slowly on itself and breathing light. It turns and it never changes where it is, which is what makes it the thing to read every other motion against.

**Mario Cube** — `mario_cube`

Four yellow cubes, at the four places the crossings lead: the north room, the west landing, the south room, and the top of the raised floor. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing you were reading every motion against is the first casualty of arriving.

## The skeleton of displacement

The coordinate system is not a description of space laid on afterwards. It is the skeleton of every move. When the room gives you a cube that goes only up, you learn that up was already a separate thing inside every step you have ever taken, and that a walk is a sum of three sums. The crossing is slow because it makes you do the arithmetic with your body, one term at a time. It is passable because the arithmetic is exact. The one cube that runs diagonally is not an exception to that. It is the proof: two of the terms changing at once, and a slot in the floor that is exactly their sum.

Next: the transformation that makes direction matter.

*Field notes: Exactness decisions[^trans-axisdecomposition-1] · Verified critique (2026-09-02) — APPLIED[^trans-axisdecomposition-2] · The rethink (2026-09-05): the hole is the way[^trans-axisdecomposition-3]*

[^trans-axisdecomposition-1]: **Exactness decisions.**
    - **The tutorial's `reconstruct` flips z.** `Vector3.FORWARD` is (0,0,-1), so
      `RIGHT*cx + UP*cy + FORWARD*cz` returns (x, y, -z). Probe item 4 measured
      (2.5, -1.25, 0.75) → (2.5, -1.25, -0.75). The tutorial says "matches the
      original exactly"; the text now says decomposition is exact and
      reconstruction has to agree about the axes. The tutorial should be fixed
      (`Vector3.BACK * cz`, or say so).
    - **One cube, gate 6.** One `pick_up_cube` is placed; the gate wants six on the
      running score (see Trans_Translation notes). The first draft said six cubes.
    - **The room is mostly void**: rows 16–21 are all `0`; `cube_scene:0:3` and the
      axis cubes stand at y offsets over it. Transport cubes on three separate
      axes: `tc:3:z`, `tc:2:x`, `tc:4:y:auto`.
    - **translation_cube_demo** default course `lift_lateral`: "up, then apart.
      Two freedoms, gated" (its own header).
    - **toruscylinder**: torus rotates 0.5 rad/s, cylinder oscillates ±1.5 with a
      trail (exports).
    - The `3t` text on the wall reads "Translation produces space as navigable
      extent" (map utilities r10 c3).

[^trans-axisdecomposition-2]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **10 findings survived the editor, 7 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] To get from the entrance to the gate you have to want each of the three directions separately, in the right or

    **Problem.** The map puts the spawn, the gate and the teleporter within two cells of each other on the same ledge, so this describes a journey nobody makes. sp is score points in this engine, not spawn; the spawn is the s cell at x=8, z=9 on the east ledge. The teleporter sits at x=7, z=8 and the gate at x=6, z=8. You land, step across, and you are at the way out with the gate beside you. Every transport cube is west of them, and nothing obliges you to go.

    **Fix.** You arrive high on the east ledge, and the gate and the way out are both two steps from where you land. Everything the hall has to teach is west of them, across the missing floor, and nothing makes you go. Cross anyway, and you find that wanting to be somewhere means wanting three directions in turn, because no cube gives you two at once.

    **Evidence.** Verified against map_data.json: utilities row 8 has t at col 7 and sp at col 8, row 9 has s at col 8; interactables row 8 has pickup_gate at col 6. UtilityRegistry.gd defines s as spawn_point and sp as score points.

    ### [wrong] One cube to carry across the islands. The carry is three numbers changing, and on the transport cubes you will

    **Problem.** You cannot carry it. Walking into the detection volume fires collect(), adds one point and frees the cube with a chirp. A visitor sent to pick this up will reach for it and watch it vanish.

    **Fix.** One cube, turning and bobbing on the south floor. You do not carry it. Walk into it and it is gone with a rising chirp, and the number the gate is watching goes up by one.

    **Evidence.** Same verification as the other four rooms: pick_up_cube.gd:62-63, :218-227, :258-261, and a .tscn with no body of any kind.

    ### [wrong] A dark sphere, still, over the void. The one thing in the maze that has no component along any axis, so that t

    **Problem.** Two false claims in one short sentence. The token sits at x=2, z=5, and structure row 5 reads "1" at column 2, so it stands on solid floor, not over the void. And it is not still: it turns on Y at 0.15 rad/s with a wobble on X and pulses its emission every frame. The idea underneath is right and worth keeping, but it is invariance of position, not stillness.

    **Fix.** A dark sphere on the floor of the northern island, turning slowly on itself and breathing light. It turns and it never changes where it is, which is what makes it the thing to read every other motion against.

    **Evidence.** Verified: structure row 5 is ["2","1","1","1","0","0","0","0","2"], so col 2 is floor; dark_sphere.gd:455 and :589-600.

    ### [wrong] Cubes standing over the void, three metres up, as scaffolding and waypoints. They are the reference geometry o

    **Problem.** There is one cube, not several, and it is not scaffolding. The map places a single cube_scene:0:3; at the default grain of solid the script returns from _build_all before adding anything, so the scene is its one 1 m box. It hangs three metres above a void row, out of reach, so it is not a waypoint in any usable sense. "Reference geometry" is lifted from the registry description word for word.

    **Fix.** One cube, a metre on a side, hanging three metres above the widest gap in the floor. It is the chapter's plain solid, the thing everything else is measured against, and here it is out of reach, marking the crossing rather than making it.

    **Evidence.** Verified: one cube_scene token at interactables row 10 col 5; structure row 10 is void across the interior; commons/primitives/cubes/cube_scene.gd:186-190 returns early on GRAIN_SOLID.

    ### [wrong] and doing the up before the across is a different thing from doing the across before the up, even though the d

    **Problem.** Translations commute, and this chapter's own next room is built on that fact: Trans_Rotation opens "Rotation is the first operation where the order you do things in changes where you end up", and its intent.md says these two halls proved displacement order-independent. So the sentence overstates what is true of translation and spends the next hall's discovery early. It is also undemonstrable here: the demo ships course lift_lateral and the map token passes no config, so the other order is a value no visitor can reach. What the door actually shows is that the gate imposes an order the arithmetic does not.

    **Fix.** The constraint is the lesson: direction is part of the operation, not a detail added afterwards. The order belongs to the door and not to the arithmetic. The two displacements add to the same place either way, so the door has to impose a sequence to make you feel them apart.

    **Evidence.** Verified: translation_cube_demo.gd:45 ships course = "lift_lateral"; the map token is translation_cube_demo:180:0.5 with no config; Trans_Rotation/intent.md line 2 says in as many words that the previous two maps proved displacement order-independent.

    ### [wrong] A door in a box that will only move along the axis the box currently allows.

    **Problem.** There are two doors, not one. _create_doors builds a red left door and a blue right door inside the wireframe container, each with its own knob and its own two-leg plan, and the demo completes only when both reach their goals. The singular hides the thing the visitor actually does twice.

    **Fix.** Two doors in a wireframe box, one red and one blue, each of which will only move along the axis the box currently allows. Push one sideways when it wants to go up and it resists. Complete the lift, and the slide is permitted, and then you do the whole of it again with the other.

    **Evidence.** Verified: translation_cube_demo.gd:245-263 (left red, right blue) and :325 (_check_both_complete requires both).

    ### [wrong] Most of this hall is void.

    **Problem.** It is not most, and the true number is better. Counting the seven interior columns across sixteen rows, 56 of 112 cells are void and 56 carry floor. Exactly half. A first sentence about the room's shape should be one a visitor can check by looking.

    **Fix.** Half the floor of this hall is missing.

    **Evidence.** I counted the structure layer cell by cell: 4+4+3+3+3+4+6+4+4+5+7+3+3+3+0+0 = 56 void of 112 interior cells.

    ### [weak] the way between the islands is a vertical maze of transport cubes, each of which moves on one axis only: one g

    **Problem.** "Vertical maze" is the blurb's phrase, not the map's fact, and the text then leans on "maze" three more times. There are three transport cubes and one walkway, and only one of the three is vertical. Also, two of them wait for you and the third does not: tc:4:y:auto carries auto_start, so the lift is running whether or not you are on it and you have to time your step. That is the only genuinely hard thing in the crossing and the text does not mention it.

    **Fix.** the way between the islands is three transport cubes, each of which moves on one axis only: one runs in depth, one across, one up. Two of them wait until you are standing on them. The lift does not, so you have to arrive when it does.

    **Evidence.** Verified: utilities carry tc:3:z, tc:2:x and tc:4:y:auto, plus one wp:90; transport_cube.gd:13 declares auto_start.

    ### [weak] The gate wants six on the running score. It is the same rule as the last hall: accumulated displacement become

    **Problem.** True about the code and misleading about the visit. The previous hall's gate wants seven and stands right by its own teleporter, so nobody reaches this room with fewer than seven points, and a gate set to six is already open before you see it. This room places one cube worth one point, so the gate could never have been meant to bite here. Saying so is more interesting than the abstraction, which is the previous hall's sentence repeated rather than earned.

    **Fix.** The gate wants six on the running score. The last hall would not let you leave until you had seven, so this one is open before you reach it: the same rule, already satisfied, standing there so you can watch a condition follow you between rooms.

    **Evidence.** Verified: Trans_Translation's gate is pickup_gate:0:0#pickups:7 at row 21 with its teleporter at row 22; this map's gate is pickups:6 and holds one pick_up_cube.

    ### [polish] The sideways cube and the depth cube, each on its own rail with its ghosts and its label.

    **Problem.** Accurate but under-delivered, and it hides the one thing you can do to them. Each cube also builds a small rack with a horizontal SPEED slider wired to travel_speed. The visitor can slow the number down. Nothing in the room tells them so.

    **Fix.** The sideways cube and the depth cube, each on its own rail, each trailing four shrinking ghosts of where it just was, each printing its one coordinate to three decimals as it goes. There is a speed slider on the rack in front of them. Slow the cube down until you can read the number changing, and watch the other two digits not change at all.

    **Evidence.** Verified: axis_translation_cube.gd:33 (travel_speed), :357 (a slider_h labelled SPEED), :363-370 (slider_moved sets travel_speed), :274 (Label3D prints the moving coordinate).

[^trans-axisdecomposition-3]: **The rethink (2026-09-05): the hole is the way.**
    Palle, after the three galleries: *"Do you understand the syntax and the
    principal of these maps? It is all about how transformation creates empty
    space. So the holes are the pathway up down to the side as a result of
    translation rotation and scale."* And when the first draft answered with walls
    that open and a cube that fills a pit: *"I mean not fill hole that is another
    question I mean just structure 0."* The ruling is in
    `commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
    generator that made it (traces, banks and cell-sharing checked) is the session's
    `rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
    only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
    rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
    holes lead.

    **What the holes are now.** `tc:2:z` at (4,5) through (4,6) into the island at
    (4,7); `tc:4:-z` at (5,7) through (5,6), (5,5), (5,4) into the north room at
    (5,3); `tc:4:-x` at (5,8) through (4,8), (3,8), (2,8) into the west landing at
    (1,8); the diagonal `tc:2.83:1,0,1` at (1,9) through (2,10) into the south room
    at (3,11); `tc:1.5:y:auto` standing in the hole (5,13) of a small 2-plateau
    (x5-7 row 12, x6-7 row 13). 42 of the 112 interior cells are void (the wall
    text's "more than a third"; it used to say half). Four Mario cubes. Five
    pick-ups added so the gate's six exist. The `3t` "Translation produces space as
    navigable extent" moved from (3,10), which the diagonal now runs through, to
    (2,12). The spawn `s` at (8,9) on the east wall is as it was; the other
    session's row (interactables row 4) was not touched.

    **Two rules the layout taught.** A ride's bank must not be another ride's
    start, or two cubes stand in one cell; and two traces must not cross, or two
    cubes can meet mid-ride. The west landing is three cells long for that reason,
    and the diagonal starts one cell south of where the x ride lands.

    **Templates learned, and what each cost.**

    - **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
      in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
      6-8). A ride that stops in the last void cell strands the rider a metre
      short, which is what once stranded Palle between two chapters.
    - **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
      is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
      plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
      the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
      (Translation, AxisDecomposition, Rotation); the museum's door halls read
      height 2 as wall.
    - **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
      because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
      walls.
    - **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
      at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
      rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
      at the far bank, the template's own terms; `rc:90` pauses closed at both
      ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
      StaticBody turned by script, no platform velocity: a rider is not carried,
      so rolling cubes are spectacle and a turntable is crossed on foot.
    - **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
      offset_x 1 puts the centre in the middle). The galleries commit had it at
      the centre column, overhanging the bank by a metre.
    - **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
      `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
      sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
      signed axes and vectors, and a plank or turntable joins its banks two cells
      out; a cube rolling about x or z joins nothing.
    - **The Mario cube took the first node named DarkSphere in the whole tree**,
      which in the museum could be another hall's; it now takes the nearest
      (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
      room's own sphere, so the first crossing removes the room's control, and the
      wall text says so.
    - **Rides are utilities, artifacts are placements.** The museum reads a hall's
      structure and utilities live, but a door hall's artifacts come from
      `ada_run/em_plan.json`: the five transformation rows were re-derived from
      the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
      have re-derived 23 rows other sessions were editing, so the patch was partial
      and says so in the plan's `_map_halls` stamp.

    **Open.** The tutorial's `reconstruct` still flips z (see above). Nobody has
    walked the rebuilt hall in VR.

    **Learned after the bake (2026-09-05, later).** The museum seals every body's
    cells in its walk map, a walk-into trigger included, and refuses a seal that
    would cut the route ("sealing would sever the walk route"), then SLIDES the
    body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
    Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
    12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
    a landing pocket none, so two of its three Mario cubes were slid into walls.
    They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
    the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
    three metres up) was built at `_ready`: the museum's extent counts every
    MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
    so the cube seals its one cell; the registry's measured footprint (17) is stale
    by the same amount. The Spectacle's twelve stood exactly where placed, because
    its rows are thirteen wide.

#### Trans Rotation

Rotation is the first operation where the order you do things in changes where you end up.

Translation left direction alone: space was the same in every direction and a move was a move. Rotation makes facing matter. Front is now different from back, left from right, and the sentence on the wall says it: rotation produces space as anisotropic. Every turning form in this hall carves an orientation into the void, and declares this way and not that way.

```gdscript
func euler_rotate(node: Node3D, euler: Vector3) -> void:
    node.rotate(Vector3.UP, euler.y)
    node.rotate(Vector3.RIGHT, euler.x)
    node.rotate(Vector3.FORWARD, euler.z)
```

Three turns about three axes, and the order is in the body, not the name: up first, then right, then forward. Turn about up and then about right, or about right and then about up, and the same two angles leave the thing facing two different ways. Adding never did this. Rotation in three dimensions does, and it is the first thing in the chapter that cannot be undone by doing the same steps backwards in the same order.

## Direction

**rotate_grid_cubes** — `rotate_grid_cubes`

Look down. The field of cubes in rows is the floor of this hall. It has no geometry of its own. It reaches into the grid the room is built from and turns that. The rows turn to a score. Six tip about one axis, four stay flat, six about the next axis, four flat, six about the third, four flat, and then six that tip about all three at once, thirty-five degrees on two of the axes and twenty-five on the third. The score runs forty-four rows and the hall is forty long, so you meet it once and walk off the end of it before it can come round. The collision cubes turn with the picture, so a tilted band is tilted underfoot.

**Science Screen** — `science_screen`

The screen is not looking at the room. It is running as a waveform instrument, and what it draws is a sine rolling across an axis grid with an angle read out beside it. That is a rotation seen sideways: take a point going round a circle, keep one of its two numbers and plot it against time, and this is the curve you get. The diagram is a loss on purpose, and the number it threw away is the one that tells you where the point is.

**Furniture Turntable** — `furniture_turntable`

A record deck, playing a crate at thirty-three and a third. Watch the needle. It never moves, and the platter turns under it, and the point where they meet holds one radius forever, tracing the circle that was hidden in the motion. Thirty-three homecomings a minute. This is the second thing rotation makes, after direction: it makes a form come back to itself.

**spin** — `spin`

Thirty-three small cubes in a straight line against a red bar, alternating black and white. The first eleven all lean the same way. Through the middle twelve each copy is turned fifteen degrees further than the last, a hundred and eighty in all, and the ten that follow keep the new lean. The row never bends. Every step is the same step; only the orientation it is carrying has changed, and that is what the order cost. Placed twice on their plinths, one of them yawed half round, and the difference is the claim: the turn inside the sequence changes what each copy is doing, and the turn applied to the finished row only changes which way the row is pointing. Same angle, two places to put it, two different objects.

**Dark Sphere** — `dark_sphere`

A dark sphere with no front. It is turning the whole time you stand there, slowly, and nothing about it changes, which is why it is the reference: it is the one thing in the hall a rotation cannot get hold of.

## The hole is the way

The floor of this hall is cut across three times, and each cut is the shape of a turn. The first is a row of three square holes, each the width of a plank turning about its centre: one turns a quarter and pauses, one a half, one forty-five degrees, and you cross when the corners meet the banks. There is no other way over. The second is three holes with the floor left round them, where cubes turn without stopping: a turntable you can cross while it turns under you, and two cubes rolling about the axes you walk along and across, which are no way at all. The third is three slots the width of a turning cube, crossed only carried: a quarter, the other way, half round. Past them a raised floor with a hole in its front, and in the hole a lift that turns you once around on the way up, the screw; and a slot down through its back, where a cube slides forward and down and turns you half round as it goes. Every empty cell here is the sweep of one rotation, and the rotation is the only way through it.

**Mario Cube** — `mario_cube`

Eight yellow cubes, one at the far side of every crossing. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing with no front is the price of the first crossing.

## Sameness of form

Turn a square a quarter of a turn and it is the same square, corner for corner. Turn it an eighth and it is not. The turns that change nothing are a form's symmetry, and they are the part of rotation this chapter cares about most: not where a thing ends up, but which turns bring it home. A circle comes home under every turn, which is why the needle can hold one radius forever. A square comes home under four. And this is not only a fact about shapes. When physics asks what a particle is, one of the answers is how many turns it takes to come home, and there are particles that need two. How many turns a thing needs is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

## What a turn does to a body

**Catalyst Prompter Box** — `catalyst_prompter_box`

A floor hatch, one cell wide, whose lid slides open as you approach. A crystal rises from the recess. Walk away without taking it and the lid slides shut again. Take it and it is yours for forty-five seconds; let the lease run out and the floor takes it back, and the vent goes quiet with it.

**Catalyst Vent** — `catalyst_vent`

Turn round. Back up the hall a grey pillar four metres tall has been standing there all along, ringed on the floor at its foot with a dark orb sitting in it, and now that the crystal is in your hand it starts to breathe out bodies: five seconds, then one every two and a half, three of them, and then it goes quiet. They come as foes. The crystal does not damage them. Each hit walks one body a single step along an arc, foe to wary to neutral to curious to friend, so a friend costs four. That is the chapter's argument done to something living: a transformation is contact, not harm, and it does not finish in one go. Folded is not less.

**Pick Up Cube** — `pick_up_cube`

**Pickup Gate** — `pickup_gate`

Seven cubes and a gate that wants seven on the running score, as before: two past the plank holes, two past the carried turns, one up on the raised floor, one at the foot of the slot down, and the last beside the gate. You do not carry them. You walk into one and it is gone with a chirp, one point richer, and the gate reads the total. The rule has not changed since the first hall, and here it is the calm part of the room.

## Process and outcome

In the translation halls a move was reducible to its result: here, then there, and the between did not matter. Rotation ends that. Two turns in one order and two turns in the other are the same two turns and two different outcomes, so the process is now part of the thing. From this hall on, how you got somewhere is a fact about where you are.

Next: the same turn, repeated, until it becomes architecture.

*Field notes: The second gem[^trans-rotation-1] · Exactness decisions[^trans-rotation-2] · Verified critique (2026-09-02) — APPLIED[^trans-rotation-3] · The rethink (2026-09-05): the hole is the way[^trans-rotation-4]*

[^trans-rotation-1]: **The second gem.**
    Palle (2026-09-02): "what rotation does with sameness of form, that is quantum
    theory." The text carries it as symmetry: the turns that bring a form home; a
    square under four, a circle under all; and spin as the particle's answer to
    "how do you come back when turned", with the spin-½ fact (two full turns) stated
    as physics, not as anything the room measures. Probe item 5 measures the
    square (quarter turn same set, eighth not).

[^trans-rotation-2]: **Exactness decisions.**
    - **rotate_grid_cubes** runs a score (`PATTERN`): 6 rows Z, 4 flat, 6 Y, 4
      flat, 6 X-negative, 4 flat, 6 all, 8 flat; amounts 35° (rot_amount) and 25°
      (rot_amount_y). The first draft said "bands that travel"; the text now reads
      the score.
    - **science_screen `#mode:wave` is not a mode.** Accepted: point, line,
      trace/draw, triangle, net/cube. The placement falls back to the plain
      projection; the text describes that. The map token should be corrected.
    - **furniture_turntable**: rpm 33.333, needle_r 0.62 fixed, platter rotates
      (line 40). "Thirty-three homecomings a minute" from its own header.
    - **spin** placed twice (r18 at 180, r19 at 0), both on 0.90 plinths.
    - **catalyst_vent** token: emit 2.5 s, wave 3, delay 5 s, requires the catalyst
      armed ("until player has the bracelet"). **catalyst_prompter_box**:
      emergence slide, lease 45 s. The foe→friend line comes from the dropped
      Chamber_Transformation pearl's note ("a state transition rather than
      damage").
    - One `pick_up_cube`; the gate wants 7 on the running score.
    - The `3t` wall text: "Rotation produces space as anisotropic."

[^trans-rotation-3]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **12 findings survived the editor, 7 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] A cube to carry and a gate that wants seven on the running score, as before. Carry it past the vent.

    **Problem.** The cube is never carried; walking into it collects it. And it cannot be carried past the vent in either direction: the vent stands at row 31, the cube and gate at row 36, and the exit at row 38, so the vent is already behind you, and the gate sits one cell from the cube anyway. The gate half of the sentence is right.

    **Fix.** A cube and a gate that wants seven on the running score, as before. You do not carry this one. You walk into it and it is gone with a chirp, one point richer, and the gate one cell over reads the total. The rule has not changed since the first hall, and here it is the calm part of the room.

    **Evidence.** Verified: pick_up_cube.gd collect path; map_data.json places catalyst_vent at row 31, pick_up_cube and pickup_gate at row 36 cols 3 and 4, catalyst_prompter_box at row 38 and the teleporter at utilities row 38.

    ### [wrong] It is a row of copies that slides, turns and slides again, so that the order of the operations is visible as a

    **Problem.** There is no bend. The row is dead straight and the baked buffer proves it: all thirty-three origins sit at the same y and z with x advancing by a constant 0.14. What the rotation changes is the tilt of each copy, not where it is put. The argument is stronger this way; the text is looking for a shape that is not there.

    **Fix.** Thirty-three small cubes in a straight line against a red bar, alternating black and white. The first eleven all lean the same way. Through the middle twelve each copy is turned fifteen degrees further than the last, a hundred and eighty in all, and the ten that follow keep the new lean. The row never bends. Every step is the same step; only the orientation it is carrying has changed, and that is what the order cost.

    **Evidence.** Verified: spin.gd:79-102 and the MultiMesh buffer in spin.tscn, 33 instances at y=3, z=0.05, x from -2.4098 to 2.0702 in steps of 0.14.

    ### [wrong] Placed twice, facing two ways, it shows that a rotation applied to the whole result is not the same as the rot

    **Problem.** Neither turn bends anything. The inner fifteen-degree steps twist the copies and leave the line straight; the 180 in the token is a yaw applied by the grid to the finished node, which swings the whole straight row end for end. The claim underneath is right and worth keeping, but the image carrying it is false.

    **Fix.** Placed twice on their plinths, one of them yawed half round, and the difference is the claim: the turn inside the sequence changes what each copy is doing, and the turn applied to the finished row only changes which way the row is pointing. Same angle, two places to put it, two different objects.

    **Evidence.** Same buffer evidence; the tokens are spin:180:1#plinth:0.90 and spin:0:1#plinth:0.90 at rows 18 and 19. Note that in this room the plinths are real, unlike in Trans_Introduction.

    ### [wrong] The screen projects what stands near it into a flat diagram, and a tilted row projected onto a plane is a prof

    **Problem.** The token puts the screen in waveform mode, which switches scanning off entirely. Nothing near the screen is projected onto it, and nothing in this hall exposes _angle or current_amplitude for it to read, so the tracking target stays null. What is on the glass is a synthetic instrument: the header WAVEFORM over y = A sin(wt + phi), a sine rolling across an axis grid on the system clock, and a panel reading amplitude, frequency, angle and velocity.

    **Fix.** The screen is not looking at the room. It is running as a waveform instrument, and what it draws is a sine rolling across an axis grid with an angle read out beside it. That is a rotation seen sideways: take a point going round a circle, keep one of its two numbers and plot it against time, and this is the curve you get. The diagram is a loss on purpose, and the number it threw away is the one that tells you where the point is.

    **Evidence.** Verified: science_screen.gd:430-433 sets "wave" as a recognised generic mode and :453 locks it; :466-477 skips the scan when locked; :503-509 hunts for _angle or current_amplitude, which nothing in this map has; :2449-2475 draws the synthetic sine at amplitude 1.5 on Time.get_ticks_msec.

    ### [wrong] The crystal does not damage them. It turns their state, and a turned foe is a friend.

    **Problem.** One dose walks a creature exactly one step along a five-rung arc. A foe hit once is wary, not a friend; a friend costs four hits, and only the fourth fires the pop. The vent seeds every body it emits at foe, so nothing here arrives part-way along. The one-shot version makes the room's own argument cheaper than the code does.

    **Fix.** The crystal does not damage them. Each hit walks one body a single step along an arc, foe to wary to neutral to curious to friend, so a friend costs four. That is the chapter's argument done to something living: a transformation is contact, not harm, and it does not finish in one go. Folded is not less.

    **Evidence.** Verified: hazard_creature_base.gd:16-18 (PERSONALITY_ARC of five), catalyst_foe.gd:658-676 ("Advance ONE step along the arc, not all the way to friend"), catalyst_vent.gd:37 (initial_state defaults to "foe" and the map token does not override it).

    ### [wrong] A field of cubes in rows, and the rows turn to a score: six rows tip about one axis, four stay flat, six tip a

    **Problem.** Three things. The field is not an exhibit in front of you: the token ships no geometry, it reaches out to the map's own GridMultiMesh and turns the floor of the hall, collision bodies included, so the tilted bands are underfoot. The reading drops a band, the four flat rows between the third axis and the all-three band. And the cycle is forty-four rows long in a hall forty rows deep, so it does not repeat: you see it once, cut off.

    **Fix.** Look down. The field of cubes in rows is the floor of this hall. The token has no geometry of its own; it reaches into the grid the room is built from and turns that. The rows turn to a score. Six tip about one axis, four stay flat, six about the next axis, four flat, six about the third, four flat, and then six that tip about all three at once, thirty-five degrees on two of the axes and twenty-five on the third. The score runs forty-four rows and the hall is forty long, so you meet it once and walk off the end of it before it can come round. The collision cubes turn with the picture, so a tilted band is tilted underfoot.

    **Evidence.** Verified: RotateGridCubes.gd:36 (multimesh_path "../GridMultiMesh") and :236-254 (rotates the sibling GridCollisions bodies); GridStructureComponent.gd:82-90 names the floor multimesh GridMultiMesh and its collision parent GridCollisions under the same parent_node that GridInteractablesComponent adds artifacts to; PATTERN at :44-53 sums to 44; this map's structure is 40 rows.

    ### [wrong] Three turns about three axes, and the order is written into the function's name.

    **Problem.** The function is called euler_rotate. Nothing in that name says up, then right, then forward. The order is in the three lines of the body, which the reader can see, and pointing at the name sends them to the one place it is not.

    **Fix.** Three turns about three axes, and the order is in the body, not the name: up first, then right, then forward.

    **Evidence.** The code block is printed in final.md line 6 and its function is euler_rotate; tutorial.md captions the same block "YXZ order" in prose beneath it.

    ### [weak] Down the hall, a tall grey seam in the air begins to breathe out bodies once the catalyst is in your hand, one

    **Problem.** Two misses in one sentence. The vent is not a seam in the air: it is a four-metre translucent grey pillar that meets the floor, ringed at its base with a torus halo, with a dark orb sitting in it. "Seam" is the registry's word rather than the object's. And it is not down the hall from the hatch. The hatch is at row 38, one cell from the teleporter; the vent is at row 31, seven rows behind you by the time you have the crystal.

    **Fix.** Turn round. Back up the hall a grey pillar four metres tall has been standing there all along, ringed on the floor at its foot with a dark orb sitting in it, and now that the crystal is in your hand it starts to breathe out bodies: five seconds, then one every two and a half, three of them, and then it goes quiet.

    **Evidence.** Verified: catalyst_vent.gd:138-187 builds a 4 m cylinder tapering 0.30 to 0.18, a torus halo at its foot and a 0.72 m dark orb at 0.45 m; :27-30 gives the 5 s warmup after the bracelet is armed; the map token sets emit_interval_s 2.5 and wave_size 3; the row positions are as stated.

    ### [weak] That number is called spin, and it is the sameness of form, taken as far as it goes.

    **Problem.** The number just named is two, and two is not what is called spin. Spin is the quantity that says how many turns it takes, and for the particles the sentence is reaching for it is one half. As written the room hands the visitor a wrong label on the one fact in this section it cannot show them.

    **Fix.** How many turns a thing needs to come home is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

    **Evidence.** Physics, not code, and the error is unambiguous: the preceding sentence establishes two full turns, and the text then names two as the spin.

    ### [polish] A dark sphere with no front. It is the one thing in the hall that rotation cannot change, and so it is the ref

    **Problem.** True, but it leaves the better fact on the floor. The sphere is not sitting still: it is being turned, every frame, and wobbled, and you cannot tell. The room's whole claim is that rotation makes facing matter, and here is the object that is being rotated and has no facing to lose.

    **Fix.** A dark sphere with no front. It is turning the whole time you stand there, slowly, and nothing about it changes, which is why it is the reference: it is the one thing in the hall a rotation cannot get hold of.

    **Evidence.** Verified: dark_sphere.gd:455 (rotation_speed 0.15) and :593-595. One turn every forty-two seconds.

    ### [polish] Take it, and you hold the catalyst; walk away or wait out its lease and it goes back beneath the floor.

    **Problem.** The two clauses belong to different states. Walking away closes the lid on a crystal you have not taken. Once it is in your hand, distance does nothing and only the forty-five second lease brings it back, which is also what quiets the vent.

    **Fix.** Walk away without taking it and the lid slides shut again. Take it and it is yours for forty-five seconds; let the lease run out and the floor takes it back, and the vent goes quiet with it.

    **Evidence.** Verified: catalyst_prompter_box.gd:257-270 gates the whole proximity branch on has_crystal (the crystal still parented to the box), and :340-349 shows that once taken only the lease returns it. The token sets lease_s 45.

    ### [polish] Next: rotation given time, and let run.

    **Problem.** "And let run" hangs off nothing and the line does not parse. The next hall is Trans_RotationSpectacle, whose subject is one small angular rule repeated until it becomes architecture.

    **Fix.** Next: the same turn, repeated, until it becomes architecture.

    **Evidence.** A grammar fault, not a taste call. I am not asking the other rooms to drop the "Next:" form, which is this chapter's house habit.

[^trans-rotation-4]: **The rethink (2026-09-05): the hole is the way.**
    Palle, after the three galleries: *"Do you understand the syntax and the
    principal of these maps? It is all about how transformation creates empty
    space. So the holes are the pathway up down to the side as a result of
    translation rotation and scale."* And when the first draft answered with walls
    that open and a cube that fills a pit: *"I mean not fill hole that is another
    question I mean just structure 0."* The ruling is in
    `commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
    generator that made it (traces, banks and cell-sharing checked) is the session's
    `rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
    only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
    rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
    holes lead.

    **What the holes are now.** Band A, rows 6-8: three 3x3 plank holes with walls
    at x0, 4, 8, 12 - `rc:90:y:4:-0.6` at (2,7), `rc:180:y:3:-0.6` at (6,7),
    `rc:45:y:2:-0.6` at (10,7). Band B, rows 10-12, floor round the holes:
    `rc:continuous:y:20:-0.6` at (2,11) (the turntable), `rc:continuous:x:30` at
    (6,11), `rc:continuous:z:30` at (10,11). Band C, rows 22-24: three 3-wide
    slots, `tc:4:z#rot:90`, `#rot:-90`, `#rot:180` from row 21 at x2, 6, 10. A
    2-plateau at x4-8 rows 27-29 with the screw standing in the hole at (6,27)
    (`tc:1.5:y:auto#rot:360`, in a 3-wide notch) and the slot down at (6,29)
    (`tc:2.24:0,-1,2#rot:180` through (6,30) into (6,31)). Eight Mario cubes; six
    pick-ups added so the gate's seven exist. The old pits, channels, screw at
    (11,24), scale cube and x ride are gone.

    **The floor score and the bands.** `rotate_grid_cubes` tilts the grid's rows:
    0-5 about z, 6-9 flat, 10-15 about y, 16-19 flat, 20-25 about -x, 26-29 flat,
    30-35 about all three, 36-43 flat. So band A stands in flat rows; band B's
    floor is yawed, which a pit does not mind; band C's walls lean along z, not
    into the slots; the plateau is flat; and the slot down lands on tilted floor at
    (6,31), as the vent at (0,31) always has.

    **Templates learned, and what each cost.**

    - **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
      in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
      6-8). A ride that stops in the last void cell strands the rider a metre
      short, which is what once stranded Palle between two chapters.
    - **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
      is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
      plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
      the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
      (Translation, AxisDecomposition, Rotation); the museum's door halls read
      height 2 as wall.
    - **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
      because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
      walls.
    - **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
      at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
      rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
      at the far bank, the template's own terms; `rc:90` pauses closed at both
      ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
      StaticBody turned by script, no platform velocity: a rider is not carried,
      so rolling cubes are spectacle and a turntable is crossed on foot.
    - **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
      offset_x 1 puts the centre in the middle). The galleries commit had it at
      the centre column, overhanging the bank by a metre.
    - **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
      `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
      sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
      signed axes and vectors, and a plank or turntable joins its banks two cells
      out; a cube rolling about x or z joins nothing.
    - **The Mario cube took the first node named DarkSphere in the whole tree**,
      which in the museum could be another hall's; it now takes the nearest
      (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
      room's own sphere, so the first crossing removes the room's control, and the
      wall text says so.
    - **Rides are utilities, artifacts are placements.** The museum reads a hall's
      structure and utilities live, but a door hall's artifacts come from
      `ada_run/em_plan.json`: the five transformation rows were re-derived from
      the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
      have re-derived 23 rows other sessions were editing, so the patch was partial
      and says so in the plan's `_map_halls` stamp.

    **Open.** `science_screen #mode:wave` is still not a mode (see above). Nobody
    has walked the rebuilt hall in VR.

    **Learned after the bake (2026-09-05, later).** The museum seals every body's
    cells in its walk map, a walk-into trigger included, and refuses a seal that
    would cut the route ("sealing would sever the walk route"), then SLIDES the
    body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
    Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
    12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
    a landing pocket none, so two of its three Mario cubes were slid into walls.
    They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
    the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
    three metres up) was built at `_ready`: the museum's extent counts every
    MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
    so the cube seals its one cell; the registry's measured footprint (17) is stale
    by the same amount. The Spectacle's twelve stood exactly where placed, because
    its rows are thirteen wide.

#### Trans RotationSpectacle

One angular rule, repeated, is a building if you repeat it in space and a spectacle if you repeat it in time.

The last hall taught that order matters. This one teaches that a speed compounds. It is a long hall, a procession, with a corridor along one wall and a carousel at the far end, and everything in it is one rule applied again and again until the rule has become architecture.

```gdscript
func tunnel_angle(i: int) -> float:
    return i * rotation_per_segment        # ten degrees, added

func layer_speed(i: int) -> float:
    return base_rotation_speed * pow(1.2, i)   # a fifth, multiplied
```

Two rules and one counter. The corridor adds ten degrees for every segment you pass; the cake multiplies its speed by a fifth for every layer you look up. That is the whole machinery of this hall: an index, and something that reads it.

## What you can trust

**righttriangle** — `righttriangle`

A right triangle, on its own by the entrance, with no moving part anywhere in it. Move it, turn it, and the ninety degrees between its two short sides is still ninety. It is here as a diagnostic: with everything in this hall turning, you need one thing whose angle you can trust.

**Dark Sphere** — `dark_sphere`

The dark sphere, which is not still either. It turns once in about forty seconds, slowly enough that you have to look away and back to catch it doing anything. In this hall even the witness is spinning, and the only thing that is not is the triangle.

## The rule, accrued

**Boolean Tunnel** — `boolean_tunnel`

Along the east wall, a corridor of eighteen hollowed cubes set end to end, each three metres deep, each rolled ten degrees further about the corridor's own axis than the one before. Ten degrees is nothing. Seventeen of them is a hundred and seventy, and the corridor spends fifty-one metres rolling that far about the line you walk along. The ground stays flat. Everything round it does not. Nobody designed the twist: a local rule about one segment and its neighbour was repeated, and the repetition became a building.

**Baggage Grammar** — `baggage_grammar`

A baggage carousel, and one suitcase going round it forever. On the straights it translates. At the corners it rotates. Through the customs arch it is scaled down, and on the far side it is restored, nothing to declare. Twelve seconds a lap. All three rigid motions, one after another, on one object, in a loop: the grammar of the chapter, spoken by a suitcase.

## The hole is the way

Between the suitcase and the cakes the floor is cut five times, and each cut is the shape of one turn. Three square holes with planks in them: a quarter turn about the vertical, a quarter about the axis you walk along, so that it tips, and a half turn. Three holes with the floor left round them, where cubes turn without pausing: a turntable at forty degrees a second, and two rolling about the two floor axes. Three slots the width of a turning cube, crossed carried: a quarter, the other way, a full circle. Two more slots, one crossed turned half round while the space grows a fifth around you, one with the space growing by a third and nothing turning. Then a staircase of single holes cut on the diagonal, a lift beside the wall that takes you up two metres and once around and back, the square of empty floor a cube needs to grow into, and a last cut of three ways: a turntable at ten degrees a second that you cross while it turns, a plank that pauses open at forty-five, and a bridge, which is translation made still. Every empty cell in the procession is the sweep of one rotation, and the rotation is the only way through it.

**Mario Cube** — `mario_cube`

Twelve yellow cubes, one at the far side of every crossing. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. From then on the only thing in the hall you can trust is the triangle.

**Two Cakes** — `two_cakes`

Two cakes of three tiers each, assembled from the same tiers. One was turned and then slid, the other slid and then turned, and the candles stand at two different addresses. It is the last hall's lesson baked: the product changes when the factors change sides.

**Pick Up Cube** — `pick_up_cube`

A cube near the end, bobbing and turning once every three seconds on its own axis, which makes it the fastest thing turning in this hall: quicker than the carousel's top layer, and the only turn here you can end. Walk into it and it is gone.

**carousel_cake** — `carousel_cake`

At the end, the carousel itself, and it is bigger than it sounds: three thin plates at your ankles, a three-metre column above them, then four slabs widening to a brim ten metres across, six metres up, spanning most of the hall. Eight layers, one rule, each turning a fifth faster than the one below. The bottom takes twelve seconds to come round. The top takes three and a half. Between them the layers slide past each other in patterns that repeat and interfere and repeat. The rule is the same at every level; only the multiplier compounds, and it compounds until the object reads as rhythm rather than as a spin. Stand close, and forget which way you were going.

## Perpetual return

Translation goes somewhere and stops. Rotation goes round and comes back, and if you let it run it never has to stop, which is why a carousel is a spectacle and a walkway is not. What this hall adds to the chapter is time. One is added and one is multiplied: ten degrees per segment down the corridor, a fifth per layer up the cake. The difference between a building and a performance is only whether the repetition has finished.

Next: the last of the three moves, and the one that changes what everything else is worth.

*Field notes: The tunnel[^trans-rotationspectacle-1] · Exactness decisions[^trans-rotationspectacle-2] · Verified critique (2026-09-02) — APPLIED[^trans-rotationspectacle-3] · The rethink (2026-09-05): the hole is the way[^trans-rotationspectacle-4]*

[^trans-rotationspectacle-1]: **The tunnel.**
    Palle (2026-09-02): "I want the tunnel in the scene now, to the side, in the
    wall." Moved from r4 c11 to r4 c12 (the east edge) through
    `/api/maps/cell-edit`, which refused nothing. `booleanTunnel.gd`: 18 segments,
    spacing 3.0, rotation_per_segment 10° about z (the corridor axis), accrual
    default `ramp`; the run is 17 × 3 = 51 m along z from the placement, in a hall
    54 rows deep, so it ends about a metre short of the far end. Placed at
    y −1.05. Whether "in the wall" means embedded in the museum wall beyond the
    map edge is a hall ruling.

[^trans-rotationspectacle-2]: **Exactness decisions.**
    - **carousel_cake**: 8 layers, `layer_speed = base × 1.2^i` (line 208/268), so
      the top turns 1.2^7 = 3.58× the base (probe item 8). "A fifth faster than
      the layer below" is the multiplier.
    - **baggage_grammar**: lap 12 s, customs_scale 0.55 (scaled down and
      restored), per exports and header.
    - **two_cakes**: R·T ≠ T·R, "candles at two addresses", from its header.
    - **righttriangle** default proportion isoceles, reading uniform.
    - **boolean cubes**: the tunnel's `cube_scene` preload is from
      `algorithms/primitives/booleans/`, hence "hollowed cubes".

[^trans-rotationspectacle-3]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **10 findings survived the editor, 6 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] Eight objects at even angles round a circle, hung from one frame. Turn the frame and the whole ring sweeps. St

    **Problem.** Nothing in this hall is built that way. The code block is lifted out of tutorial.md and describes a ring of eight boxes parented to a frame, which does not exist here. carousel_cake draws eight stacked cylinders as instances of one MultiMesh and writes each instance's rotation individually, with sibling colliders each given their own rotation.y. booleanTunnel bakes an absolute transform into each cube and never rotates a parent. baggage_grammar writes position, rotation and scale straight onto one node. No frame turns and nothing inherits a turn, and the sentence claims to name the room's whole machinery.

    **Fix.** Replace the block with the two rules that are running: tunnel_angle(i) returns i * rotation_per_segment, ten degrees added per segment; layer_speed(i) returns base_rotation_speed * pow(1.2, i), a fifth multiplied per layer. Then: "Two rules and one counter. The corridor adds ten degrees for every segment you pass; the cake multiplies its speed by a fifth for every layer you look up. That is the whole machinery of this hall: an index, and something that reads it."

    **Evidence.** Verified: carousel_cake.gd:206-220 and :268-271; booleanTunnel.gd:184, :218 and :233-235 (tunnel_rotation_x and _z both zero and unset by the map); baggage_grammar.gd:47-50. The exemplars simplify code freely, but each shows a mechanism that is actually running.

    ### [wrong] The dark sphere, still, as it has been in every hall. The spectacle needs a witness that does not spin.

    **Problem.** The dark sphere spins. rotation_speed is 0.15 rad/s and _process turns it every frame, with a sine wobble on X and an emission pulse on top. The map token is bare dark_sphere with no config, so every default holds. In a room whose subject is rotation, the one sentence that stakes a claim on something not rotating is the one the code contradicts, and forty-two seconds a turn is exactly the kind of slow rotation this room ought to want.

    **Fix.** The dark sphere, which is not still either. It turns once in about forty seconds, slowly enough that you have to look away and back to catch it doing anything. In this hall even the witness is spinning, and the only thing that is not is the triangle.

    **Evidence.** Verified: dark_sphere.gd:455, :594-595, :599-600; map_data.json interactables row 3 col 6 carries a bare dark_sphere token.

    ### [wrong] A cube to carry through the procession, so that something in the hall moves because you moved it.

    **Problem.** You cannot carry it and you cannot meet it during the procession. Walking into it deletes it. It is also placed at row 45 of 54, three rows past the two cakes and three rows before the exit teleporter, so it stands at the end of the walk, not along it. The true fact is better: it turns at 2 rad/s, a full turn every three seconds, which makes it faster than the carousel's top layer.

    **Fix.** A cube near the end, bobbing and turning once every three seconds on its own axis, which makes it the fastest thing turning in this hall: quicker than the carousel's top layer, and the only turn here you can end. Walk into it and it is gone.

    **Evidence.** Verified: pick_up_cube.gd:76 (rotation_speed 2.0), :147, :218-249, :258-261; map_data.json places two_cakes at row 42, pick_up_cube at row 45, the teleporter at utilities row 48 and carousel_cake at row 51.

    ### [wrong] Both are the same ten degrees, and the difference between a building and a performance is only whether the rep

    **Problem.** The room lands its argument on a number that is false of half the argument. Ten degrees is the tunnel's rule and only the tunnel's. The cake's rule is a base of 0.5 rad/s multiplied by 1.2 per layer. There is no ten anywhere in the carousel, and the two rules are not even the same operation: one adds an angle, one multiplies a rate. The second half of this sentence is the best writing in the room and the first half is the only thing standing between it and being true.

    **Fix.** One is added and one is multiplied: ten degrees per segment down the corridor, a fifth per layer up the cake. The difference between a building and a performance is only whether the repetition has finished.

    **Evidence.** Verified: booleanTunnel.gd:18 (rotation_per_segment 10.0) and :184; carousel_cake.gd:54-55 (base_rotation_speed 0.5, rotation_speed_multiplier 1.2) and :208.

    ### [wrong] Eighteen times ten is a half turn, and over fifty-one metres it is a twist you walk through with your whole bo

    **Problem.** Off by one, in exactly the place a rule that accrues should be exact. The first cube is at zero, so eighteen cubes carry seventeen increments: angle_deg = i * rotation_per_segment for i from 0 to 17, which is a hundred and seventy degrees. And nothing about your body leans. The rotation is about Z, the axis you walk along, and the map floor under you is flat; the phrase is carried over almost intact from the registry blurb.

    **Fix.** Ten degrees is nothing. Seventeen of them is a hundred and seventy, and the corridor spends fifty-one metres rolling that far about the line you walk along. The ground stays flat. Everything round it does not.

    **Evidence.** Verified: booleanTunnel.gd:16 (num_segments 18), :18, :184 (i * 10 for i in 0..17) and :218 (rotation about Vector3(0,0,1)). Note for the author: the critic's supporting claim that the pivot compensation holds every cube centre at x=0 is backwards, since the compensation moves the centre to hold the bottom pivot. The fix above does not rest on it.

    ### [wrong] This one teaches that speed and direction compound.

    **Problem.** Direction never compounds anywhere in this hall. Every carousel layer takes base_rotation_speed times 1.2 to the power i, all positive, so all eight turn the same way. Every tunnel segment adds a positive ten degrees. The suitcase turns the same way at every corner. Nothing counter-rotates. The claim comes from intent.md and from the blurb's "different speeds, different directions", and it is the sentence that sets the room's promise.

    **Fix.** The last hall taught that order matters. This one teaches that a speed compounds.

    **Evidence.** Verified: carousel_cake.gd:55 and :208 (multiplier 1.2, positive, no sign flip); booleanTunnel.gd:184; Trans_RotationSpectacle/intent.md line 2.

    ### [weak] Rotation is the transformation that happens in time: the same small angular rule, repeated, accrues into a twi

    **Problem.** The opener is not what the room delivers, and it argues against the room's own closing paragraph. The tunnel is fifty-one metres of static geometry with no time in it at all, and the closing says so plainly: a rule repeated in space gave you a twisted tunnel, a rule repeated in time gives you a cake that never settles. The room's one claim is the space/time split, and the opener collapses it.

    **Fix.** One angular rule, repeated, is a building if you repeat it in space and a spectacle if you repeat it in time.

    **Evidence.** Verified: booleanTunnel bakes its transforms once at build and has no _process; carousel_cake advances _rotation_angle every frame. The room's own last paragraph states the distinction the opener denies.

    ### [weak] At the end, the carousel itself: eight circular layers stacked into a cake, and every layer obeys one rule, tu

    **Problem.** The room's climax arrives with no size on it. The stack is 5.65 m tall and the top layer is 10 m across in a hall 13 m wide, so the brim overhangs almost the full width and stands three times a visitor's height. And the eight layers are not eight equal tiers: three are 5 cm plates at your ankles, then a 3 m column, then four widening slabs. Nor is "the bottom layer turns slowly" a number: it is one turn every twelve and a half seconds against the top layer's three and a half.

    **Fix.** At the end, the carousel itself, and it is bigger than it sounds: three thin plates at your ankles, a three-metre column above them, then four slabs widening to a brim ten metres across, six metres up, spanning most of the hall. Eight layers, one rule, each turning a fifth faster than the one below. The bottom takes twelve seconds to come round. The top takes three and a half.

    **Evidence.** Verified: carousel_cake.gd:15-16 (radii 4, 3.5, 3, 1.6, 3, 3.5, 4, 5 and heights 0.05, 0.05, 0.05, 3.0, 1.0, 0.5, 0.5, 0.5, summing to 5.65) and :54-55; placed at y+0.35. Every exemplar hands the visitor the scale of a thing at the moment they meet it.

    ### [polish] Along the east wall, a corridor built from eighteen hollowed cubes, three metres apart, and every one of them

    **Problem.** Two small things. "Three metres apart" is the spacing value, but each cube is itself exactly three metres deep, so they abut into one continuous tube with no gaps at all, which is not what "apart" pictures. And "turned ten degrees more" never says about which axis, so a reader builds a corridor that bends. It does not: the turn is about the direction of travel, so the tube stays straight and rolls.

    **Fix.** Along the east wall, a corridor of eighteen hollowed cubes set end to end, each three metres deep, each rolled ten degrees further about the corridor's own axis than the one before.

    **Evidence.** Verified: booleanTunnel.gd:17 (spacing 3.0) and :218 (rotated about Vector3(0,0,1)); booleanHollowCube.tscn's outer CSGBox3D is size Vector3(4, 4, 3).

    ### [polish] ## Still things first

    **Problem.** Once the dark sphere is described honestly, the heading covers one object out of two. The right triangle is genuinely static, with no _process at all; the sphere turns and pulses. The heading should name what the two share, which is that they are the references.

    **Fix.** ## What you can trust

    **Evidence.** Consequential on the kept dark_sphere fix. Verified: righttriangle.gd has no _process; dark_sphere.gd:589-600 does.

[^trans-rotationspectacle-4]: **The rethink (2026-09-05): the hole is the way.**
    Palle, after the three galleries: *"Do you understand the syntax and the
    principal of these maps? It is all about how transformation creates empty
    space. So the holes are the pathway up down to the side as a result of
    translation rotation and scale."* And when the first draft answered with walls
    that open and a cube that fills a pit: *"I mean not fill hole that is another
    question I mean just structure 0."* The ruling is in
    `commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
    generator that made it (traces, banks and cell-sharing checked) is the session's
    `rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
    only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
    rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
    holes lead.

    **What the holes are now, down the procession.** Band A, rows 11-13: planks
    `rc:90:y:4:-0.6` (2,12), `rc:90:x:4:-0.6` (6,12), `rc:180:y:3:-0.6` (10,12),
    walls between. Band B, rows 16-18, floor round the holes:
    `rc:continuous:y:40:-0.6` (2,17), `rc:continuous:x:30` (6,17),
    `rc:continuous:z:30` (10,17). Band C, rows 21-23: `tc:4:z#rot:90`, `#rot:-90`,
    `#rot:360` from row 20 at x2, 6, 10. Band D, rows 26-28: `tc:4:z#rot:180#scale:1.2`
    from (2,25) in a 3-wide slot and `tc:4:z#scale:1.3` from (6,25) in a 1-wide one.
    The diagonal `tc:4.24:1,0,1` from (1,30) through (2,31), (3,32) into (4,33);
    the screw `tc:2:y:auto#rot:360` on floor at (10,31); `sc:3:0.5:1:0` at (8,34),
    the LEFT column of its hole (x8-10, rows 33-35). Band E, rows 38-40:
    `rc:continuous:y:10:-0.6` (2,39), `rc:45:y:4:-0.6` (6,39), `br:z:3` at (10,38).
    Twelve Mario cubes. The tunnel at (12,4), the cakes at (8,42) and the carousel
    are where they were. This is a door hall: its artifacts come from the plan,
    re-derived and re-baked on 2026-09-05.

    **Templates learned, and what each cost.**

    - **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
      in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
      6-8). A ride that stops in the last void cell strands the rider a metre
      short, which is what once stranded Palle between two chapters.
    - **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
      is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
      plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
      the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
      (Translation, AxisDecomposition, Rotation); the museum's door halls read
      height 2 as wall.
    - **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
      because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
      walls.
    - **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
      at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
      rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
      at the far bank, the template's own terms; `rc:90` pauses closed at both
      ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
      StaticBody turned by script, no platform velocity: a rider is not carried,
      so rolling cubes are spectacle and a turntable is crossed on foot.
    - **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
      offset_x 1 puts the centre in the middle). The galleries commit had it at
      the centre column, overhanging the bank by a metre.
    - **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
      `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
      sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
      signed axes and vectors, and a plank or turntable joins its banks two cells
      out; a cube rolling about x or z joins nothing.
    - **The Mario cube took the first node named DarkSphere in the whole tree**,
      which in the museum could be another hall's; it now takes the nearest
      (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
      room's own sphere, so the first crossing removes the room's control, and the
      wall text says so.
    - **Rides are utilities, artifacts are placements.** The museum reads a hall's
      structure and utilities live, but a door hall's artifacts come from
      `ada_run/em_plan.json`: the five transformation rows were re-derived from
      the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
      have re-derived 23 rows other sessions were editing, so the patch was partial
      and says so in the plan's `_map_halls` stamp.

    **Open.** Nobody has walked the rebuilt hall in VR. The `t` at (3,48) still
    stands on floor.

    **Learned after the bake (2026-09-05, later).** The museum seals every body's
    cells in its walk map, a walk-into trigger included, and refuses a seal that
    would cut the route ("sealing would sever the walk route"), then SLIDES the
    body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
    Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
    12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
    a landing pocket none, so two of its three Mario cubes were slid into walls.
    They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
    the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
    three metres up) was built at `_ready`: the museum's extent counts every
    MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
    so the cube seals its one cell; the registry's measured footprint (17) is stale
    by the same amount. The Spectacle's twelve stood exactly where placed, because
    its rows are thirteen wide.

#### Trans Scale

There is no size, only size relative to something else: scaling the object and scaling yourself are one operation seen from two sides, and proportion is what survives it.

Translation changed position. Rotation changed direction. Scale is the last freedom in the matrix, and it is the strange one, because it is the only transformation you cannot see from inside. Double everything, including your ruler, and nothing has happened. Size is not a property a thing has. It is a comparison, and this hall is a room full of things to compare.

```gdscript
func volume_ratio(before: Vector3, after: Vector3) -> float:
    return (after.x * after.y * after.z) / (before.x * before.y * before.z)
```

Double every length and the volume goes up eight times. That is the one place scale is not gentle: lengths scale as the factor, areas as its square, volumes as its cube, and a body at double the size is eight times heavier standing on four times the bone, which is why nothing shaped like a mouse is ever the size of a horse.

## Scale me

**scale_me** — `scale_me`

A sphere that asks to be held. Take it, and the sphere it finds grows ten times over two seconds. You do not travel with it. At the moment you close your hand the machine sets your height to five metres and doubles your distance from the room's origin, so you arrive at the new view before anything has started to move. It does not come back while you are here. The timer is set to a thousand seconds, and even when it fires it shrinks only the sphere, over two, and leaves you exactly where it put you. Alice ate a cake and drank from a bottle for this. What has changed is the comparison, and that is enough to make the same hall intimate, then monumental.

**prism_block** — `prism_block`

Seven triangular prisms, every one a metre on a side, scattered across the floor of the far chamber, with a single one left behind on the near side of the low wall that crosses the hall. They are here because a cube is too symmetrical to show the difference: turn a prism and a different face takes the light, which is a thing a cube will never show you.

**Basic Cube Scene** — `cube_scene`

Three cubes among them, the same metre, seated two-tenths higher off the floor. They are the comparison. Without them the hall is a room, and with them it is a room of a known size, and when the sphere changes you it is against these that you know it.

**chair_assembly_puzzle** — `chair_assembly_puzzle`

Ten identical cubes on a bench, each shrunk to a tenth, and six cyan ghosts standing at full size where a seat, four legs and a back should go. Six of the cubes have a ghost waiting for them and four are spares. Move, turn and scale the cubes into the ghosts, and when the sixth one lands the puzzle does something stranger than finishing. Every cube you placed is deleted, and a solid wooden chair appears where they were, a fifth larger than the ghosts you were matching. You did not build that chair. You proved it could be built, and the room took the proof and handed you the object.

**Clipboard** — `clipboard`

A clipboard at half size, turned to face you. Walk within a metre and a half and the page fades up: a drawing of the right-hand controller with one button marked, and a line saying that scale snaps to fixed sizes. It is the only writing in the hall, and it is printed at half the size of the thing it describes.

**Science Screen** — `science_screen`

A screen on the wall, and it is the one thing here that is not looking at the room. It was set to a bar chart before it could scan, and nothing in this hall feeds a bar chart, so it draws twenty bars from a fixed seed. Take the sphere and it will not notice. A measuring instrument that has been told what to measure is not measuring.

**Dark Sphere** — `dark_sphere`

The dark sphere, where the prisms end. It turns on itself the whole time you are here and never leaves its cell, and it is the one thing in this hall the pill goes looking for.

## The hole is the way

The wall on your right has two doorways in it, and through them a second hall with its floor cut four times. Two slots run away from you, each crossed by a cube you ride: on one the space grows by a third around you as you go, on the other it shrinks by nearly a quarter, and both give it back on the way back. Between them and the next cut, a square of empty floor three cells across with a small cube at its middle, which grows to the size of the square and shrinks again: the hole is the room a scaling needs, and the cube is exactly the size of it. A slot runs sideways, crossed with the space growing. At the end a lift stands on the floor and takes you up two metres with the space growing by half, and brings you down again. Nothing here scales the things; it scales the distance between you and them, which the first sentence of this room said was the only kind of size there is.

**Mario Cube** — `mario_cube`

Two yellow cubes, one at the end of the landing the two slots share and one past the sideways slot. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing the pill goes looking for is the price of the first crossing.

## What survives

Every transformation in this chapter was a promise about what would not be touched. Scale's promise is proportion: every ratio is kept, every angle is kept, and every size is given up. That is why it is the transformation that most directly shows what invariance means. Nothing here scales you. The pill moves you instead, and moving you is enough: from five metres up and twice as far out, the room is the same shape and none of it is the size it was.

That is the chapter's question answered three times. Position, direction, size: each move gives one of them up and keeps the rest. What stays the same when everything changes is whatever the move refused to touch, and the refusing is the move.

Next: the three moves from inside, where each one is a way of being removed.

*Field notes: The pill[^trans-scale-1] · Exactness decisions[^trans-scale-2] · Verified critique (2026-09-02) — APPLIED[^trans-scale-3] · The rethink (2026-09-05): the hole is the way[^trans-scale-4]*

[^trans-scale-1]: **The pill.**
    Palle: "the Alice scale me pill". `scale_me.gd` measured: on pickup it finds a
    node named DarkSphere in the current scene (or the given world node, or its
    parent) and tweens its scale ×100 over `scale_up_time` 5 s; it sets the
    player's position to y = 5 with x and z multiplied by scale_amount/5 = 20;
    after `scale_duration` 20 s it reverts over 5 s (auto_revert). The registry's
    "rescales the world around the player" and the first draft's "the world
    rescales around you" are not what the code does. The text now says the dark
    sphere grows a hundred times and you are lifted five metres and carried
    outward. **Flag:** x,z × 20 on the player's world position is a teleport far
    outside a museum hall; in the grid map it is far outside the map. Worth fixing
    before anyone takes the sphere in VR.

[^trans-scale-2]: **Exactness decisions.**
    - **Seven prisms, three cubes** (first draft said eight): prism_block at r8 c5,
      r11 c1, r11 c2, r12 c4, r13 c3, c4, c5; cube_scene at r10 c5, r11 c3, c4.
    - **science_screen `#mode:bars` is not a mode**; falls back to the plain
      projection. The text describes that. Token should be corrected.
    - **chair_assembly_puzzle**: model_scale 0.3 → final_scale 1.0, grow 1.5 s,
      grow_on_complete true.
    - **clipboard** placed with `vr_scale_controls` config; "the scale controls on
      it" from the token.
    - Volume ×8 at factor 2: probe item 7.

[^trans-scale-3]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **12 findings survived the editor, 11 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] Take it, and the dark sphere across the hall grows a hundred times over five seconds, from something you could

    **Problem.** Every number here comes from the script's export defaults, and the scene the map instantiates overrides all of them: scale_amount 10.0 and scale_up_time 2.0. The target sphere is 0.35 m in radius, so ten times is a 7 m ball, not the size of the building. And the player is not carried: the origin's global position is written once, instantly, at pickup and before the tween is created, to x and z doubled and y set to five. You are at the new viewpoint before anything starts growing.

    **Fix.** Take it, and the sphere it finds grows ten times over two seconds. You do not travel with it. At the moment you close your hand the machine sets your height to five metres and doubles your distance from the room's origin, so you arrive at the new view before anything has started to move.

    **Evidence.** Verified: scale_me.tscn:8 and :10 override scale_me.gd:15 and :17; scale_me.gd:118-126 writes the position before the tween at :129-132; dark_sphere.gd:453 gives sphere_radius 0.35.

    ### [wrong] Twenty seconds later it shrinks back over five, and so do you.

    **Problem.** Three errors. The scene sets scale_duration to 1000.0, so the revert timer is a thousand seconds and nobody walking this hall will see it fire. It sets scale_down_time to 2.0, not five. And "and so do you" is contradicted in the plainest terms: the timeout reads the player's position, prints it, and deliberately leaves it alone under the comment "Don't move player when scaling down - let them stay at current position and fall". Only the world node is tweened.

    **Fix.** It does not come back while you are here. The timer is set to a thousand seconds, and even when it fires it shrinks only the sphere, over two, and leaves you exactly where it put you.

    **Evidence.** Verified: scale_me.tscn:9 and :11; scale_me.gd:174-187, comment and no-op at :178-181.

    ### [wrong] The screen projects what stands near it into a flat diagram, every thing reduced to its outline on a plane. Ta

    **Problem.** None of this happens. The map token is #mode:bars, which is a real recognised mode: it labels the screen BAR CHART and locks the mode, and a locked mode makes the first scan return before any scan runs, so the screen never looks at what stands near it and can never draw an outline of anything. It then hunts for an artifact exposing _current_heights or _array; nothing in this hall has either, so it hits the branch commented "Demo: generate bars if no data" and fills the chart with twenty values from a fixed seed. The visitor is instructed to watch an event the code forbids.

    **Fix.** A screen on the wall, and it is the one thing here that is not looking at the room. Its token locks it to a bar chart before it can scan, and nothing in this hall feeds a bar chart, so it draws twenty bars from a fixed seed. Take the sphere and it will not notice. A measuring instrument that has been told what to measure is not measuring.

    **Evidence.** Verified: map token science_screen:180:1.5#mode:bars; science_screen.gd:446-449 and :453 (bars sets _generic_mode and locks), :466-477 (locked skips the scan), :521-528 (hunts _current_heights or _array), :2786-2791 (rng.seed 12345, twenty bars).

    ### [wrong] Move, turn and scale the parts into the ghosts, and when the last one aligns the whole chair grows to full siz

    **Problem.** Nothing grows. _grow_to_final_size contains no tween: it frees every assembled piece and every spare cube, instantiates the premade wooden_chair_reward.tscn, drops it at the centre of where the pieces stood and sets its scale to reward_scale, which the scene fixes at 1.2. The exports the sentence is built on, model_scale, final_scale and grow_duration, are declared and never read anywhere in the file.

    **Fix.** Move, turn and scale the cubes into the ghosts, and when the sixth one lands the puzzle does something stranger than finishing. Every cube you placed is deleted, and a solid wooden chair appears where they were, a fifth larger than the ghosts you were matching. You did not build that chair. You proved it could be built, and the room took the proof and handed you the object.

    **Evidence.** Verified: furniture_assembly_puzzle.gd:388-445, with the frees at :410-418, the instantiate at :417-418 and scale set at :439; grow_duration, model_scale and final_scale declared at :74-77 and read nowhere; chair_assembly_puzzle.tscn sets reward_scale 1.2.

    ### [wrong] Parts of a chair at a third of their size, and ghost guides showing where each should go.

    **Problem.** There are no chair parts. _spawn_pieces instantiates copies of one scene, grab_cube_scalable.tscn, six for the targets and four spares because extra_pieces is 4, every one an identical cube set to scale 0.1, not a third. The whole argument of the artifact is that the pieces are undifferentiated cubes, and calling them parts of a chair gives the puzzle its answer away in the first clause.

    **Fix.** Ten identical cubes on a bench, each shrunk to a tenth, and six cyan ghosts standing at full size where a seat, four legs and a back should go. Six of the cubes have a ghost waiting for them and four are spares.

    **Evidence.** Verified: furniture_assembly_puzzle.gd:293-320 (one piece_scene, piece.scale = Vector3.ONE * 0.1); chair_assembly_puzzle.tscn sets piece_scene to grab_cube_scalable.tscn and extra_pieces to 4.

    ### [wrong] A document you have to hold to read, with the scale controls on it. Reading it is an interaction, and the cont

    **Problem.** The first clause is the registry's description, not the code's behaviour: clipboard.gd reveals the page purely by camera distance, fading in between 2.0 and 1.5 metres, with no reference to whether it is held. Holding only matters for turning pages. The second clause is worse: there are no controls on the clipboard. The token loads the page vr_scale_controls, which is an ASCII drawing of the right-hand controller with one button labelled "B = Cycle Scale" and a line saying scale snaps to fixed sizes. The same token also sets uniform scale 0.5, so the card is placed at half size, which the room never uses and should.

    **Fix.** A clipboard at half size, turned to face you. Walk within a metre and a half and the page fades up: a drawing of the right-hand controller with one button marked, and a line saying that scale snaps to fixed sizes. It is the only writing in the hall, and it is printed at half the size of the thing it describes.

    **Evidence.** Verified: clipboard.gd:51-52 and :62-77 (distance-driven reveal only); commons/context/clipboard/tutorial_text/vr_scale_controls.gd; the token clipboard:0:0#vr_scale_controls:180:0:0.5 parses through the shorthand branch to uniform_scale 0.5.

    ### [wrong] Seven triangular prisms and three cubes, laid out in a row like a scale bar, all the same family and all at on

    **Problem.** The count is right and "all at one size" is right, but there is no row. The ten pieces occupy five different rows and five different columns across the far chamber, with a single prism left behind on the near side of the low wall that crosses the hall at row 10. "Laid out in a row like a scale bar" is the arrangement the paragraph needs, not the one the map has, and it is the one claim in the room a visitor can falsify by standing still and looking. The prism region is also empty: every sentence about the prisms sits inside the cube region.

    **Fix.** Split the two regions. Under @prism_block: "Seven triangular prisms, every one a metre on a side, scattered across the floor of the far chamber, with a single one left behind on the near side of the low wall that crosses the hall." Under @cube_scene: "Three cubes among them, the same metre, seated two-tenths higher off the floor. They are the comparison. Without them the hall is a room, and with them it is a room of a known size, and when the sphere changes you it is against these that you know it."

    **Evidence.** Verified from the parsed structure and interactables: prisms at rows 8, 11 (twice), 12, 13 (three times); cubes at rows 10, 11 (twice); structure row 10 is height 2 at columns 1 to 4 and floor at 5 and 6, so it is a low wall with a gap, not a full divider. I softened the critic's "stranded" and "solid" accordingly.

    ### [wrong] turn a prism or grow it and a different face dominates, so aspect and orientation are readable in a way a box

    **Problem.** This is the registry description transcribed, and the scaling half is false. Uniform scaling changes no face's share of the silhouette at all, which is the point the room makes twenty lines earlier with the ruler. Only rotation, or a non-uniform scale, redistributes the faces, and nothing in this hall rotates or non-uniformly scales a prism: all seven carry the same 90.

    **Fix.** turn a prism and a different face takes the light, which is a thing a cube will never show you

    **Evidence.** Verified: all seven prism tokens in Trans_Scale/map_data.json are prism_block:90:0, and the registry's prism_block description is the source of the wording. The room contradicts itself otherwise.

    ### [wrong] When your body is the thing being scaled, what you notice is not that anything got bigger.

    **Problem.** Nothing in this hall scales your body. The XR origin's scale is never written anywhere in scale_me.gd; the only thing done to the player is a single write to global_position at pickup. The room's closing paragraph rests its conclusion on an experience the hall does not provide, and it does not need to, because the displacement it does provide makes the same point.

    **Fix.** Nothing here scales you. The pill moves you instead, and moving you is enough: from five metres up and twice as far out, the room is the same shape and none of it is the size it was.

    **Evidence.** Verified: scale_me.gd:118-126 writes global_position only, and :174-205 writes nothing at all to the origin. There is no scale assignment on the XR origin in the file.

    ### [wrong] the world is full of things that break when their weight grows eight times faster than their bones

    **Problem.** The arithmetic the sentence has just stated correctly is then reported wrongly. At factor two, volume and so weight go up eight times while the load-bearing cross-section, an area, goes up four. Weight outruns strength by two, not by eight. The square-cube law is the one piece of real physics in the room and the number is wrong by a factor of four.

    **Fix.** and a body at double the size is eight times heavier standing on four times the bone, which is why nothing shaped like a mouse is ever the size of a horse

    **Evidence.** The error is internal to final.md line 10, which states "areas as its square, volumes as its cube" in the immediately preceding clause and then divides them wrongly.

    ### [wrong] The dark sphere, at its one size. When you have changed, it is the thing that has not.

    **Problem.** The room has already told the visitor, twenty lines above, that the pill grows this sphere. Both cannot be true, and with the revert timer at a thousand seconds it would keep any new size for the rest of the visit. The room's most quotable closing beat is built on a contradiction with its own opening one.

    **Fix.** The dark sphere, where the prisms end. It turns on itself the whole time you are here and never leaves its cell, and it is the one thing in this hall the pill goes looking for.

    **Evidence.** Verified: scale_me.gd:67 searches the running scene for a node named DarkSphere, and dark_sphere.tscn's root carries that name. I deliberately wrote "goes looking for" rather than "is the pill's target", because of the resolution race described in the next finding.

    ### [weak] What has changed is the comparison, and that is enough to make the same hall intimate, then monumental, withou

    **Problem.** "Without a wall moving" is the room's best claim and the code does not guarantee it. scale_me resolves its target inside _ready, by searching the live scene for a node named DarkSphere. Interactables are placed in ascending row order and added to a parent already in the tree, so _ready fires at placement: scale_me is at row 8 and dark_sphere at row 13, meaning the search runs five rows before the sphere exists. The fallback is _world_node = get_parent(), which is the grid parent that also holds GridMultiMesh and GridCollisions. On that path the pill scales the entire map, walls included.

    **Fix.** Cut "without a wall moving". Leave the sentence at "What has changed is the comparison, and that is enough to make the same hall intimate, then monumental." Restore the clause only if someone walks the hall and confirms the pill takes hold of the sphere and not the grid.

    **Evidence.** I verified every link: scale_me.gd:29-40, :67, :75; GridInteractablesComponent.gd:588 iterates z ascending and :1294 adds the artifact to parent_node, which is the same node GridStructureComponent.gd:82-90 hangs GridMultiMesh and GridCollisions from. This is a claim the prose should not make from a desk. Note that Trans_Introduction is the other way round, sphere at row 7 and pill at row 12, so there the search succeeds.

[^trans-scale-4]: **The rethink (2026-09-05): the hole is the way.**
    Palle, after the three galleries: *"Do you understand the syntax and the
    principal of these maps? It is all about how transformation creates empty
    space. So the holes are the pathway up down to the side as a result of
    translation rotation and scale."* And when the first draft answered with walls
    that open and a cube that fills a pit: *"I mean not fill hole that is another
    question I mean just structure 0."* The ruling is in
    `commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
    generator that made it (traces, banks and cell-sharing checked) is the session's
    `rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
    only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
    rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
    holes lead.

    **What the holes are now** (the right hall, x8-12, through the doorways at
    (7,2) and (7,17)). `tc:4:z#scale:1.3` at (9,4) and `tc:4:z#scale:0.77` at
    (11,4) through rows 5-7 (x9 and x11 void, walls at x8, 10, 12) into row 8;
    `sc:3:0.5:1:0` at (9,10), the LEFT column of the hole x9-11 rows 9-11 (row 10 is
    another session's and already read 1,0,0,0,1); `tc:4:x#scale:1.3` at (8,15)
    through (9..11,15) into (12,15), walled at (9-12,14) and (8-11,16) so the
    crossing is the way; `tc:2:y:auto#scale:1.5` on floor at (10,18). Two Mario
    cubes, at (12,8) and (11,17); why not (8,8) and (12,16) is below. `#scale` is `XRServer.world_scale = base / f` in VR and the eye's height
    `base / f` on the desktop, unwound on the return; stepping off restores it. The
    left hall is untouched. This is a door hall: its artifacts come from the plan,
    re-derived and re-baked on 2026-09-05.

    **The pill and the Mario cubes.** Both go looking for the node named
    DarkSphere. The pill resolves it once, in `_ready`, and in this map (pill at row
    8, sphere at row 13) falls back to the grid parent - the standing flag above.
    The Mario cube resolves at the moment of the crossing and now takes the nearest
    sphere. If the sphere has been taken before the pill is picked up, nothing
    changes for the pill, because it never had it.

    **Templates learned, and what each cost.**

    - **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
      in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
      6-8). A ride that stops in the last void cell strands the rider a metre
      short, which is what once stranded Palle between two chapters.
    - **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
      is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
      plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
      the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
      (Translation, AxisDecomposition, Rotation); the museum's door halls read
      height 2 as wall.
    - **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
      because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
      walls.
    - **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
      at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
      rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
      at the far bank, the template's own terms; `rc:90` pauses closed at both
      ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
      StaticBody turned by script, no platform velocity: a rider is not carried,
      so rolling cubes are spectacle and a turntable is crossed on foot.
    - **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
      offset_x 1 puts the centre in the middle). The galleries commit had it at
      the centre column, overhanging the bank by a metre.
    - **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
      `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
      sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
      signed axes and vectors, and a plank or turntable joins its banks two cells
      out; a cube rolling about x or z joins nothing.
    - **The Mario cube took the first node named DarkSphere in the whole tree**,
      which in the museum could be another hall's; it now takes the nearest
      (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
      room's own sphere, so the first crossing removes the room's control, and the
      wall text says so.
    - **Rides are utilities, artifacts are placements.** The museum reads a hall's
      structure and utilities live, but a door hall's artifacts come from
      `ada_run/em_plan.json`: the five transformation rows were re-derived from
      the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
      have re-derived 23 rows other sessions were editing, so the patch was partial
      and says so in the plan's `_map_halls` stamp.

    **Open.** Nobody has walked the rebuilt hall in VR. The three teleports and the
    `#mode:bars` screen are as they were.

    **Learned after the bake (2026-09-05, later).** The museum seals every body's
    cells in its walk map, a walk-into trigger included, and refuses a seal that
    would cut the route ("sealing would sever the walk route"), then SLIDES the
    body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
    Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
    12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
    a landing pocket none, so two of its three Mario cubes were slid into walls.
    They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
    the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
    three metres up) was built at `_ready`: the museum's extent counts every
    MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
    so the cube seals its one cell; the registry's measured footprint (17) is stale
    by the same amount. The Spectacle's twelve stood exactly where placed, because
    its rows are thirteen wide.

#### Trans Pit

The neutrality of a transformation is only available from outside the space it acts on. Inside it, move and turn are ways of being removed, and the pit is the constant.

Three rooms in a row, one per transformation, and fire in all of them. Everything the chapter did to objects, this hall does to you. A block translates, and it crosses the ground you are standing on. A slab turns, and the way through is somewhere else.

```gdscript
func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

A number that climbs from zero to two and wraps, folded into a wave that goes out and comes back. That is all a pusher is: a translation on a timer, going three metres out and three back, forever.

## Translation, from inside

**Pusher Block** — `pusher_block`

Three red blocks in the first corridor, each with an arrow on its face saying where it will go. Each crosses three metres of the corridor in about half a second, straight over a fire pit, waits a second, and comes back. They differ only in how fast. From outside, a pusher is the mildest thing in the chapter: position changes and nothing else does. From inside, standing where it wants to be, it is a wall that arrives. The pit is two cells along the block's line, and the block crosses it. Not every hole in this corridor burns, and the ones that do not are the same distance down.

## Rotation, from inside

The middle room has two turning slabs, orange and wireframed, each a little over two metres across and knee high. They stand in the two clear channels between three blocks of fire. Each takes two seconds to make a quarter turn about a vertical axis and then stops: one waits four seconds before the next quarter, the other three. A rotation has a pivot, and from outside you would say the slab goes nowhere, it only turns. From inside you learn the other half of the fact: a turn changes what the same slab occupies. Side on it nearly closes the channel. End on it leaves a metre either side. Nothing about the slab changed, and the gap did.

## Scale, from inside

**Grower Block** — `grower_block`

The last room has three cubes in a row, a metre each, and they do not move. Each was placed asking for a swelling that runs from a third of a metre to three and a half, and the grid does not pass those two words through, so nothing arrives and nothing grows. Scale is the one transformation this hall never performs on you, and you will walk past it without noticing, which is very nearly what scale does anyway.

## The constant

The pit does not care which move sent you into it. Fire is the same fire under all three rooms, and the reload is the same reload. The matrices in the first hall were true: translation preserved everything but position, rotation everything but direction, scale everything but size. They were true of the blocks and the slabs. You were not in the matrix. You were in the room, and from inside the room every one of those preservations arrives as a body coming toward you.

That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the gap. The teleporter is at the far end, past the last block. The next chapter is colour, which moves nothing at all.

*Field notes: Exactness decisions[^trans-pit-1] · Verified critique (2026-09-02) — APPLIED[^trans-pit-2] · Open after the rewrite[^trans-pit-3]*

[^trans-pit-1]: **Exactness decisions.**
    - **The grower breathes.** `grower_block.gd`: `_time += delta * grow_speed *
      TAU; scale = lerp(min_scale, max_scale, t)`, a cycle, with `hot` colouring
      from small (safe) to big (danger). Tokens: min 0.3, max 3.5, speed 0.3
      cycles/s ≈ one breath per 3.3 s. The tutorial's `GrowerBlock` climbs once to
      max and stops; the first draft followed the tutorial. The text now says the
      blocks breathe and that the tutorial's grower differs.
    - **pusher_block**: tokens axis z, distance 3, speeds 1.5 / 2 / 1.8, pauses
      1.5 / 1 / 1.2; `push_axis`, `push_distance`, `push_speed`, `pause_time`
      read in apply_grid_config. Probe item 9: the triangle wave stays in [0, 3].
    - **Revolving walls** are the `rc` rotation-cube utility (`rc:90:y:4:-0.6`,
      `rc:90:y:3:-0.6`): "rotates to create walkable ramps/surfaces". The text
      says a quarter turn about a vertical axis, four cells and three.
    - **Fire**: `h:fire` utilities; DeathEffect handles the reload (CLAUDE.md:
      35 dmg per 0.3 s tick).
    - Structure heights: 5 walls, 3 floor, lower cells around the hazards.

[^trans-pit-2]: **Verified critique (2026-09-02) — APPLIED.**
    A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
    adversarial editor) judged this text against the primitives rooms and against the
    artifact scripts. **8 findings survived the editor, 5 of them factually wrong.**
    Twenty-two findings across the chapter were rejected as taste. Every finding below
    was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
    text used to say.

    The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
    rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
    point, chirps and frees the cube. Its own header: "collected by walking into it."

    The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
    without opening the scene produced wrong numbers twice in this chapter.

    ### [wrong] The last room has three blocks that breathe. Each swells from a third of a metre to three and a half across an

    **Problem.** The grower blocks do not breathe. "min" and "max" are not in CONFIG_PARAM_NAMES, so the token's #min:0.3 and #max:3.5 fall into the shorthand branch: each stores config_data[key] = true and sets a small yaw. grower_block.gd then does min_scale = float(true) = 1.0 and max_scale = float(true) = 1.0, so lerpf(min_scale, max_scale, t) is the constant 1.0. Three fixed one-metre cubes standing in a row. The hot term is then zero over zero, so the colour ramp two sentences later never runs either, and line 12's "the blocks in the room breathe" falls with it.

    **Fix.** Either repair the map, which is one line (add "min" and "max" to CONFIG_PARAM_NAMES) and makes the existing sentence nearly true, correcting only "a third of a metre" to "three tenths of a metre". If the map is not repaired, the honest sentence is: "The last room has three cubes in a row, a metre each, and they do not move. Scale is the one transformation this hall never performs on you, and you will walk past it without noticing, which is the whole of what scale does."

    **Evidence.** Verified end to end: GridInteractablesComponent.gd's CONFIG_PARAM_NAMES contains neither "min" nor "max"; the shorthand branch at :1668-1702 sets config_data[tutorial_id] = true; grower_block.gd:91-94 reads them with float(), :42 lerps between them and :53 divides by their difference. The map tokens are grower_block#min:0.3#max:3.5#speed:0.3.

    ### [wrong] The middle room has revolving walls: two of them, a quarter turn at a time about a vertical axis, one four cel

    **Problem.** The 4 and the 3 are not lengths. The rc token is angle:axis:pause:y_offset, so rc:90:y:4:-0.6 means a ninety degree step with a four second pause and a 0.6 m drop. Both slabs are identical, 2.2 by 2.2 by 1.0, and with that offset only about half a metre of each stands above the floor. These are knee-high turning slabs, not walls. "Fire around the edges" is also wrong-shaped: nine of the arena's twenty-one fire cells are a solid block in the middle, and each slab turns in a three-cell channel between the middle fire and a side one. The quarter turn itself takes two seconds at 45 degrees per second.

    **Fix.** The middle room has two turning slabs, orange and wireframed, each a little over two metres across and knee high. They stand in the two clear channels between three blocks of fire. Each takes two seconds to make a quarter turn about a vertical axis and then stops: one waits four seconds before the next quarter, the other three.

    **Evidence.** Verified: GridUtilitiesComponent.gd rc branch reads angle, axis, pause, y_offset; rotation_cube.gd:16 (45 deg/s) and :57 (BoxMesh 2.2 x 2.2 x 1.0); Trans_Pit map has rc:90:y:4:-0.6 at col 4 and rc:90:y:3:-0.6 at col 10, with h:fire at cols 1, 2, 6, 7, 8, 12, 13 across rows 11 to 13.

    ### [wrong] Three stone blocks in the first corridor, each shuttling along the depth of the room, three metres out and thr

    **Problem.** Three separate errors. "Stone": the block is given an emissive red albedo and a bright orange prism arrow on its leading face, which is the one thing that tells you what is about to happen and the text never mentions it. "Along the depth": _end_pos is computed in _ready from the export defaults, and apply_grid_config arrives afterwards through call_deferred, so axis:z never reaches the path. All three slide along +X, across the corridor's width, and each passes directly over a fire pit two cells along. "Three different pauses": pause is not a recognised config name, so it collapses to 1.0 for all three, as does distance, which makes each stroke take about half a second.

    **Fix.** Three red blocks in the first corridor, each with an arrow on its face saying where it will go. Each crosses three metres of the corridor in about half a second, straight over a fire pit, waits a second, and comes back. They differ only in how fast.

    **Evidence.** Verified: pusher_block.gd:38-41 bakes _end_pos in _ready, :87 sets the red emissive material, :99-106 builds the arrow, :116-128 is the apply_grid_config that arrives too late; GridInteractablesComponent.gd:1801 calls it deferred while :1294 adds the child. Neither "distance" nor "pause" is in CONFIG_PARAM_NAMES. The three pushers at (3,3), (3,7) and (5,7) each cross a fire cell at (3,5), (3,9) and (5,9).

    ### [wrong] From inside you learn the other half of the fact: a point at the end of a turning wall moves fastest of all, a

    **Problem.** Nothing arrives anywhere. The slab's furthest point is half the horizontal diagonal of a 2.2 by 1.0 box, about 1.21 m from the pivot. The nearest fire cell begins 1.5 m away and the room's own edge is over five metres off, so the sweep stays inside its channel and cannot touch you at the edge. The true fact is better than the invented one and is pure geometry.

    **Fix.** From inside you learn the other half of the fact: a turn changes what the same slab occupies. Side on it nearly closes the channel. End on it leaves a metre either side. Nothing about the slab changed, and the gap did.

    **Evidence.** Verified: rotation_cube.gd:57 gives the box dimensions, from which the half-diagonal is 1.208 m; the slab at col 4 sits in a three-cell channel between fire at col 2 and fire at col 6.

    ### [wrong] A wall rotates, and you are swept.

    **Problem.** This is the room's spine, and its middle third is not the shipped mechanism. The pusher and grower are AnimatableBody3D, which the solver carries bodies with. The turning slab is a StaticBody3D whose transform is copied from the mesh each frame, which blocks but does not carry, and at half a metre proud of the floor it is a step, not a wall. Rotation in this hall does not remove you; it changes the shape of the opening you have to use.

    **Fix.** A slab turns, and the way through is somewhere else.

    **Evidence.** Verified: pusher_block.gd:68 and grower_block.gd:60 both build AnimatableBody3D; rotation_cube.gd:85 builds a StaticBody3D and :101 copies the mesh transform onto it each frame.

    ### [weak] What the hall proves is that a transformation's neutrality is a fact about the outside view.

    **Problem.** This is the opening sentence again, in the last section, doing the work of a lid rather than an arrival. The sentence before it sets up the turn and the two after it are the real close and are strong. This one sits between them and takes the air out of both.

    **Fix.** Cut it. Run "Fire is the same fire under all three rooms, and the reload is the same reload." straight into "The matrices in the first hall were true:".

    **Evidence.** Internal to final.md lines 1 and 36, which state the same proposition. One deletion, nothing rewritten. This is the low-churn way to fix the room's opener-restates-closer problem without touching the opener.

    ### [weak] That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the

    **Problem.** Good image, no door. Trans_Pit is the last map of the transformation sequence and the teleporter is right there at the far end, set to next_in_sequence; the visitor is standing next to the way out. All three exemplars end by naming what is through it, including Melencolia, which is also a chapter end.

    **Fix.** Keep both sentences and add: "The teleporter is at the far end, past the last block. The next chapter is colour, which moves nothing at all."

    **Evidence.** Verified: Trans_Pit/map_data.json places t at row 23 col 7 with action next_in_sequence, and curriculum_spine.json orders transformation at 2 and color at 3.

    ### [weak] There are fire pits either side of the lane.

    **Problem.** Vague, and false of the lane it most matters for. Each block's stroke passes directly over one fire pit rather than between two. The corridor also holds five holes at height 1 with no fire on them at all, which a visitor falls into just as readily, so "fire pits" undercounts the ways down.

    **Fix.** The pit is two cells along the block's line, and the block crosses it. Not every hole in this corridor burns, and the ones that do not are the same distance down.

    **Evidence.** Verified: structure height-1 cells at (3,5), (3,9), (4,3), (4,7), (4,8), (5,9), (6,6), (6,8), against h:fire only at (3,5), (3,9), (5,3), (5,9). Five height-1 holes carry no fire.

[^trans-pit-3]: **Open after the rewrite.**
    - **The grower blocks are inert and the text now says so.** Their tokens carry
      `#min:0.3#max:3.5#speed:0.3`, but `min` and `max` are not in
      `CONFIG_PARAM_NAMES`, so the grid's shorthand branch stores them as `true`
      and the block keeps its defaults. The one-line repair is to add both keys to
      that list, which changes how every map in the corpus parses those words, so
      it is a ruling and not a text fix. Make it and the swelling sentence becomes
      true again, with "a third of a metre" corrected to three tenths.

*1 further room(s) in this chapter, not yet written.*

**homogeneous coordinates**

![homogeneous coordinates](/artifact-gallery/captures/homogeneous_coordinates/front.png)

Wall panel explaining why 4x4 matrices are used in 3D. Shows a color-coded 4x4 homogeneous transformation matrix: rotation/scale (blue), translation (green), projection (red), homogeneous row (gray). Demonstrates [x,y,z,1] → [x',y',z',1] via matrix multiplication with a 3D coordinate frame.

**transform composition**

![transform composition](/artifact-gallery/captures/transform_composition/front.png)

Transform composition demonstrator showing that matrix multiplication order matters. A simple house shape undergoes Rotate-then-Translate (blue) vs Translate-then-Rotate (red) — landing in different places. Displays R·T ≠ T·R with live 4x4 matrices. VR sliders control rotation angle and translation distance. Buttons toggle order A, order B, or both. Animated step-through shows intermediate states.

**player trace**

![player trace](/artifact-gallery/captures/player_trace/front.png)

*path(t) — the sequence of positions your body occupies over time*

A recorder that turns the player's motion into a visible line in space. Every step writes another point, so translation through the room becomes geometry rather than a forgotten action. The artifact makes path and trajectory tangible, especially when compared against grids and axis-constrained motion. It turns movement into a time-indexed drawing.

> every path through space is a function of time, and you are constantly computing it

**transform composition workbench**

![transform composition workbench](/artifact-gallery/captures/transform_composition_workbench/front.png)

*an interactive transform-composition workbench — the player turns a slider that picks one of four (T1, T2) pairs of transformations, and watches BOTH orderings of that pair applied to a base tetrahedron, side-by-side. Left shape = T2∘T1 (T1 first); right shape = T1∘T2 (T2 first). A ghost of the base sits between them. Two gold trajectory arrows run from the ghost to each result. When the two results coincide (pair 2 — rotation around origin × uniform scale) a "commutes" badge lights up; for the other three pairs the readout says "non-commutative".*

Interactive 3D workbench. A slider selects one of 4 transformation pairs; the same base tetrahedron is shown after T1∘T2 (left) and T2∘T1 (right). Order matters — except for pair 2 (rotation × uniform scale around origin) which commutes. Paired with /transform-composition-gallery.

> order is operation. R·T ≠ T·R for most pairs. The slider lets you walk the four cases, and the badge tells you when (and only when) the two operations happen to commute — exactly when both fix the origin and one is a uniform scale.

**cube scene**

![cube scene](/artifact-gallery/captures/cube_scene/front.png)

A configurable cube scene used as reference geometry across the project. Its variants can be grabbed, scaled, subdivided, snapped, or augmented, but the cube remains the stable primitive beneath those state changes. That makes it ideal for seeing what a transformation preserves and what it alters. In the transformation sequence it functions as the baseline form against which other changes read clearly.

### The Walk — further in

**pick up cube**

![pick up cube](/artifact-gallery/captures/pick_up_cube/front.png)

A grab-and-carry cube that turns translation into a bodily action. The object does not change shape or orientation much; what matters is that its position is rewritten by the player's movement through space. In puzzle contexts that simple displacement becomes rule-bearing and consequential. It is translation reduced to a portable primitive.

**clipboard**

![clipboard](/artifact-gallery/captures/clipboard/front.png)

*grabbable board with paginated text/code content, proximity reveal shader, VR page-flip via trigger/grip*

A world-space document you have to hold in order to read. Pages, code snippets, and tutorial fragments stay coherent while the object flips between states, positions, and content sets. Because it is grabbable, reading becomes an embodied interaction rather than a detached overlay. It is the sequence's stable carrier for changing information.

> a text in VR is not passive — the learner must pick it up, hold it, and navigate it with their hands

### The Turn — parameters

Translate: move without changing. Rotate: spin without deforming. Scale: grow without breaking. Combine transformations and see order matters.

Open in the dressing-room viewer: player trace, transform composition workbench, cube scene, pick up cube.

### The Critical Reading

QFEP term: **S**

Transformations modify system states while preserving essential structure. In QFEP, transformations are the operations that change S while maintaining coherent identity. They are the grammar of change.

The artifacts' own claims:

> every path through space is a function of time, and you are constantly computing it — *player trace*

> order is operation. R·T ≠ T·R for most pairs. The slider lets you walk the four cases, and the badge tells you when (and only when) the two operations happen to commute — exactly when both fix the origin and one is a uniform scale. — *transform composition workbench*

> a text in VR is not passive — the learner must pick it up, hold it, and navigate it with their hands — *clipboard*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Trans_Introduction | 11×16 | 7 | 5.1 m |
| Trans_Translation | 7×24 | 12 | 9.2 m |
| Trans_AxisDecomposition | 9×16 | 16 | 18.6 m |
| Trans_Rotation | 7×40 | 7 | 17.4 m |
| Trans_RotationSpectacle | 10×54 | 5 | 12.3 m |
| Trans_Scale | 7×21 | 15 | 15.5 m |
| Trans_Pit | 15×25 | 6 | 3.9 m |

What this chapter teaches, walked rather than read:

- Translation: moving objects in space (T_x, T_y, T_z)
- Rotation: changing orientation around axes
- Scale: changing size uniformly or non-uniformly
- Matrix representation: transformations as 4×4 matrices
- Composition: combining transformations (order matters!)
- Invariants: what properties are preserved under each transformation
- Vectors as atoms: every translation is a vector addition; every rotation is a vector-to-vector map. The operations you learn here are operations on vectors — named explicitly at forces (seq 5).

### The Seed

> **Identity preserved under transformation. What stays the same when everything changes? Invariants define structure; transformations reveal what matters.**

Exercises:

1. Translation: moving objects in space (T_x, T_y, T_z)
2. Rotation: changing orientation around axes
3. Scale: changing size uniformly or non-uniformly
4. Matrix representation: transformations as 4×4 matrices
5. Composition: combining transformations (order matters!)
6. Walk Trans_Introduction in VR and find where the rule first breaks its own pattern.
7. Open rotation_gimbal in the dressing-room viewer and change one parameter until it stops being itself.

*Next: array_tutorial*

### The Ledger

- **the dig** — 8 of 27 artifacts excavated; 19 remain at depth.

## Chapter 3: Array Tutorial Sequence

Progressive tutorial introducing array concepts through VR navigation

### The Principal

This chapter's principal is **pattern tile plate** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **frame**: flat work, framed and wall- or hover-mounted.

### The Primitive

**pattern tile plate**

![pattern tile plate](/artifact-gallery/captures/pattern_tile_plate/front.png)

Dieter Rams-styled pattern studio. Paint a 4x4 grid, see it tile into a carpet using 17 wallpaper symmetry groups. Integrated cream plate with palette, preview, and symmetry controls.

### The Walk — first steps

*7 room(s) in this chapter; none written yet.*

**pattern studio plate**

![pattern studio plate](/artifact-gallery/captures/pattern_studio_plate/front.png)

Full pattern design studio ported from Three.js PatternMaker3D. Cream plate with 4x4 paint grid, 3x3 palette, 6 sliders (motif, group, period, size, zone, site), control buttons, and real-time carpet output using all 17 wallpaper symmetry groups. 10 Italian motifs and 5 historical period palettes.

**xyz coordinates**

![xyz coordinates](/artifact-gallery/captures/xyz_coordinates/front.png)

Cartesian coordinate system, x y z godot

**pattern tile mirror**

![pattern tile mirror](/artifact-gallery/captures/pattern_tile_mirror/front.png)

*preview[px,py] = palette[grid[(py%N, px%N)]] transformed by RepeatMode/WallpaperGroup — a NxN color array tiled infinitely by a symmetry rule, with drag-and-drop colored cubes to edit the source tile*

4x4 tile with mirror symmetry (kaleidoscope effect).

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands

**pattern tile 4x4**

![pattern tile 4x4](/artifact-gallery/captures/pattern_tile_4x4/front.png)

*preview[px,py] = palette[grid[(py%N, px%N)]] transformed by RepeatMode/WallpaperGroup — a NxN color array tiled infinitely by a symmetry rule, with drag-and-drop colored cubes to edit the source tile*

Basic 4x4 tile pattern editor. Simple repeat mode.

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands

**script runner**

![script runner](/artifact-gallery/captures/script_runner/front.png)

*a 3D SubViewport-rendered code panel that steps through an array of {text, duration, expression} line dictionaries one at a time, evaluating each via GDScript Expression and displaying the result beside the highlighted line*

Live code display with real Expression evaluation! Shows code executing line-by-line with actual results. Scripts: #point, #vector_math, #array, #pattern, #loop. Example: script_runner#point:90:1

> a running program is a trajectory through state space — the script runner makes this trajectory visible by showing each state transition as a physical moment in time

### The Walk — further in

**pattern tile puzzle**

![pattern tile puzzle](/artifact-gallery/captures/pattern_tile_puzzle/front.png)

*preview[px,py] = palette[grid[(py%N, px%N)]] transformed by RepeatMode/WallpaperGroup — a NxN color array tiled infinitely by a symmetry rule, with drag-and-drop colored cubes to edit the source tile*

Create patterns on a small tile grid. Watch them repeat across a carpet. Handmade meets computational - from textile traditions to pixel art.

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands

**pattern tile brick**

![pattern tile brick](/artifact-gallery/captures/pattern_tile_brick/front.png)

*preview[px,py] = palette[grid[(py%N, px%N)]] transformed by RepeatMode/WallpaperGroup — a NxN color array tiled infinitely by a symmetry rule, with drag-and-drop colored cubes to edit the source tile*

Tile with brick/half-drop offset. Classic masonry pattern.

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands

**tiling demo**

![tiling demo](/artifact-gallery/captures/tiling_demo/front.png)

*gallery of TilingSystem instances loaded with Italian historical motifs (checkerboard→meander→perspective cubes→floral cross) displayed as floor panels in two rows: individual motifs and composed floors with borders*

Italian tiling motifs gallery. 17 wallpaper groups, multi-layer composition. Checkerboard to cosmatesque — field study preparation.

> a tiling motif is a function from grid index to visual element, and every historical floor pattern is a specific instantiation of the same abstract array-to-image mapping

**pattern tile herringbone**

![pattern tile herringbone](/artifact-gallery/captures/pattern_tile_herringbone/front.png)

*preview[px,py] = palette[grid[(py%N, px%N)]] transformed by RepeatMode/WallpaperGroup — a NxN color array tiled infinitely by a symmetry rule, with drag-and-drop colored cubes to edit the source tile*

Tile with herringbone weave pattern.

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands

**pattern maker station**

![pattern maker station](/artifact-gallery/captures/pattern_maker_station/front.png)

*symmetry_group(domain[x][y]) -> infinite_carpet — paint a small NxN grid, select one of 17 wallpaper groups, watch the GPU tile it into an infinite-seeming carpet via symmetry operators*

Interactive wallpaper group station — paint a domain grid on an upright panel, choose from 17 symmetry groups, and watch the tiled result unfold on a large floor carpet in real time.

> structure does not emerge from complexity — it emerges from constraint applied to the almost-nothing

### The Turn — parameters

Open in the dressing-room viewer: xyz coordinates.

### The Critical Reading

QFEP term: **F**

Arrays are pure order — every element at a known index, zero access entropy. The F-baseline: structure before complexity, the grid before the noise.

The artifacts' own claims:

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands — *pattern tile mirror*

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands — *pattern tile 4x4*

> a running program is a trajectory through state space — the script runner makes this trajectory visible by showing each state transition as a physical moment in time — *script runner*

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands — *pattern tile puzzle*

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands — *pattern tile brick*

> a tiling motif is a function from grid index to visual element, and every historical floor pattern is a specific instantiation of the same abstract array-to-image mapping — *tiling demo*

> every repeating pattern in the world — from Islamic tiles to woven textiles to crystal structures — is an instance of one of the 17 wallpaper groups, and this artifact makes that classification navigable with your hands — *pattern tile herringbone*

> structure does not emerge from complexity — it emerges from constraint applied to the almost-nothing — *pattern maker station*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Tutorial_Single | 11×17 | 4 | 5.6 m |
| Tutorial_Pattern | 10×13 | 12 | 17.0 m |
| Array_Patterns | 11×11 | 13 | 48.8 m |
| Tutorial_Row | 7×9 | 3 | 5.5 m |
| Tutorial_2D_Build | 8×23 | 8 | 17.5 m |
| Tutorial_3D | 7×8 | 6 | 7.4 m |
| Tutorial_Disco | 17×17 | 3 | 7.4 m |

What this chapter teaches, walked rather than read:

- Basic VR navigation
- Single element interaction
- Linear array traversal
- 2D grid understanding
- Pattern recognition
- Binary indexing, floor division, and modular arithmetic: 2 bits address a 4×4 grid; `index // width` is the row, `index % width` is the column; modular arithmetic wraps the grid into wallpaper-group symmetries.

### The Seed

Exercises:

1. Basic VR navigation
2. Single element interaction
3. Linear array traversal
4. 2D grid understanding
5. Pattern recognition
6. Walk Tutorial_Single in VR and find where the rule first breaks its own pattern.
7. Open pattern_tile_plate in the dressing-room viewer and change one parameter until it stops being itself.

*Next: color*

### The Ledger

- **the dig** — 11 of 29 artifacts excavated; 18 remain at depth.

## Chapter 4: Color and Composition

> **Color is perception, not physics. RGB is a lie we agree on. What you see depends on context, not wavelength alone.**

`RGB = (r, g, b) ∈ [0,1]³, HSV = (h, s, v) ∈ [0,360)×[0,1]²`

The physics and perception of color. Light has wavelength, but color is what brains make of it. Explore RGB, HSV, and the gap between objective light and subjective experience.

### The Principal

This chapter's principal is **crackpropagation ca** — *Cellular automaton on a 2D stress grid — cells crack when local stress exceeds threshold, propagating fracture to neighbors* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**crackpropagation ca**

![crackpropagation ca](/artifact-gallery/captures/crackpropagation_ca/front.png)

*Cellular automaton on a 2D stress grid — cells crack when local stress exceeds threshold, propagating fracture to neighbors*

A cellular automaton that grows fracture networks from invisible stress. A 64x64 grid accumulates stress through diffusion and decay — when a cell crosses the crack threshold, it shatters and pushes stress outward. The result is realistic branching cracks that follow paths of least resistance, guided by direction bias that prevents zig-zag. You watch destruction emerge from accumulation: nothing visible happens until the threshold breaks, then cracks bloom explosively across the surface.

> A crack does not choose where to go — it reads the stress the material already carries.

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

**hand model**

![hand model](/artifact-gallery/captures/hand_model/front.png)

Static hand-model reference for VR scale and positioning — provides a human-proportioned anchor for sizing artifacts in the scene.

**grab rainbow stick**

![grab rainbow stick](/artifact-gallery/captures/grab_rainbow_stick/front.png)

grab_rainbow_stick

**pick up cube**

![pick up cube](/artifact-gallery/captures/pick_up_cube/front.png)

A grab-and-carry cube that turns translation into a bodily action. The object does not change shape or orientation much; what matters is that its position is rewritten by the player's movement through space. In puzzle contexts that simple displacement becomes rule-bearing and consequential. It is translation reduced to a portable primitive.

**ball painting demo**

![ball painting demo](/artifact-gallery/captures/ball_painting_demo/front.png)

ball_painting_demo

**nail color controller**

![nail color controller](/artifact-gallery/captures/nail_color_controller/front.png)

*f(RGB) -> material.albedo_color on VR hand mesh surfaces — ValueMapper3D maps 3D input to nail/skin color*

Uses a 3D value mapper to live-adjust VR hand nail materials with a preview cube.

> choosing your nail color is the first act of digital self-authorship — the body becomes canvas before the world does

### The Walk — further in

**hand color controller**

![hand color controller](/artifact-gallery/captures/hand_color_controller/front.png)

Uses a 3D value mapper to live-adjust VR hand nail materials with a preview cube.

**rainbow**

![rainbow](/artifact-gallery/captures/rainbow/front.png)

*ROYGBIV arc(inner_radius + i*thickness) — concentric half-circle bands from ArrayMesh, primary + fainter secondary*

Creates double rainbow arcs with atmospheric bloom and layered color bands.

> a rainbow has no location — it exists only in the geometry between sun, water, and eye

**mario cube**

![mario cube](/artifact-gallery/captures/mario_cube/front.png)

*event -> destroy(DarkSphere) + reveal(Rainbow) — one-shot state transition from darkness to color*

An interactive surprise cube inspired by classic platformer mechanics — hit it from below to trigger the NextCube signal, remove the DarkSphere, and reveal a rainbow effect. A playful intersection of game design and signal systems.

> joy is not the presence of color — it is the moment darkness becomes color

**grab stick scanner**

![grab stick scanner](/artifact-gallery/captures/grab_stick_scanner/front.png)

Grabbable stick with a UV-based texture-pixel scanner — samples the hit-point colour from any surface the tip touches, displaying the RGB value live.

**brick wall factory**

![brick wall factory](/artifact-gallery/captures/brick_wall_factory/front.png)

*grid(width, height) of BoxMesh bricks colored sequentially from a named palette — running bond pattern*

grid(width, height) of BoxMesh bricks colored sequentially from a named palette — running bond pattern

> a brick wall is a color sequence made solid — the mortar is the silence between notes

### The Turn — parameters

Mix RGB to create colors. See how context changes perception. Watch gradients reveal interpolation. Paint and observe.

Open in the dressing-room viewer: crackpropagation ca, hand model, grab rainbow stick, pick up cube.

### The Critical Reading

QFEP term: **S**

Color is a system state—part of the S term in QFEP. But unlike vectors, color is fundamentally perceptual: the same wavelength can appear different colors depending on surrounding context. Color reveals the gap between ontology (photons) and experience (qualia).

The artifacts' own claims:

> A crack does not choose where to go — it reads the stress the material already carries. — *crackpropagation ca*

> choosing your nail color is the first act of digital self-authorship — the body becomes canvas before the world does — *nail color controller*

> a rainbow has no location — it exists only in the geometry between sun, water, and eye — *rainbow*

> joy is not the presence of color — it is the moment darkness becomes color — *mario cube*

> a brick wall is a color sequence made solid — the mortar is the silence between notes — *brick wall factory*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Pattern_Foundry | 24×26 | 4 | 0.0 m |
| Color_Context_Placed | 15×34 | 26 | 10.0 m |
| Color_Nails | 7×13 | 10 | 38.9 m |
| Color_Grid_Pallet | 11×13 | 4 | 23.9 m |
| Color_Rainbow | 7×18 | 13 | 17.6 m |
| Color_Pillar | 12×22 | 8 | 28.5 m |
| Color_Paint | 11×17 | 4 | 12.9 m |
| Color_Walls | 11×31 | 7 | 30.0 m |
| Color_Flashlight | 11×12 | 0 | 0 m |

What this chapter teaches, walked rather than read:

- RGB color space: additive mixing of red, green, blue
- HSV color space: hue, saturation, value—more intuitive
- Color mixing: additive vs subtractive
- Perception theory: color constancy, simultaneous contrast
- Digital materiality: how screens create color
- Gradients: interpolation between colors
- Color as function: every gradient is a function from t ∈ [0,1] to a color. Color is your first encounter with a continuous mapping — the move that sets up wavefunctions (functions of time) and forces (vector-valued functions of position) as already-familiar.

### The Seed

> **Color is perception, not physics. RGB is a lie we agree on. What you see depends on context, not wavelength alone.**

Exercises:

1. RGB color space: additive mixing of red, green, blue
2. HSV color space: hue, saturation, value—more intuitive
3. Color mixing: additive vs subtractive
4. Perception theory: color constancy, simultaneous contrast
5. Digital materiality: how screens create color
6. Walk Pattern_Foundry in VR and find where the rule first breaks its own pattern.
7. Open crackpropagation_ca in the dressing-room viewer and change one parameter until it stops being itself.

*Next: change*

### The Ledger

- **the dig** — 11 of 56 artifacts excavated; 45 remain at depth.

# Interlude: The Em-Square

*An interlude on the second contract. The grid measures space; the em-square measures the things that stand in it. One canonical scene, many instances; the type is the spatial truth. Seating — self, cube, frame, plinth, field — is a second curriculum: Order's principals stand still on plinths and in frames, and the fields you enter rather than regard arrive with entropy and return in Emergence.*

Order gave you a grid. The line was the first agreement — two people pointing at the same mark — and the cell was the unit that agreement bought: space made countable. But a grid measures the room. It says nothing about the things that stand in it. Before you leave Order, meet the second contract every artifact in this book quietly signs — the one that measures not the space but the thing.

Its name is borrowed from type. A font's em-square is the invisible box each glyph is drawn inside; it is why a twelve-point *a* and a twelve-point *W* sit on one line without anyone measuring them by hand. The letter declares its box once, and every use of the letter inherits it. Ada's artifacts are built the same way. Each declares a base contract — its pose, its footprint in cells, its height, the point where it touches the floor — and every instance inherits that contract without being measured again.

This is the book's oldest move returning in a new costume: compression. One canonical scene stands for a thousand placements, and the placements are not copies but configurations — a seed, a cartridge, a line of registry — fed to the same machine. Measuring each placement by hand would not just be wasteful, it would be *wrong*: the ruler catches a plane lying flat and calls it two centimetres tall, or reaches for a thing that builds itself only once you arrive and finds nothing there. The type is the spatial truth. You declare it in one place and you edit it there.

Two contracts hold the world together. Wang tiles were the first — the *space's* edge contract, the rule for which tile may touch which, the reason a floor can tile itself without a designer placing every square. The em-square is the second — the *artifact's* base contract, the rule for how a thing meets the floor it stands on. Between them a room assembles itself: the wall knows its seams, the object knows its foot, and no human hand needs to set each piece down.

The grammar of that foot is short. A thing seats one of a few ways. It sits **self** — it brings its own base, the way a workbench needs no plinth under it. It sits in a **cube** — the one-metre sim-cell made visible, the grid's own unit turned into housing, a label plate and a play button on its face. It hangs in a **frame** — flat work, wall-mounted or hovering. It stands on a **plinth** — small, raised to the eye. Or it becomes **field**, and this is the honest one. Some artifacts *are* the environment: the six-metre striped columns you walk between, the terrain that is the whole floor. To put them in a box would be to kill them, so the system does not. The dark spot in the doctrine is left dark on purpose. Not everything consents to be measured, and a good measure is the one that knows where to stop — the same restraint the ledger names when it calls every concept *a comparison imposed on something that did not ask to be compared*.

So from here the book keeps a smaller promise, once per chapter. Each names its **principal** — the single artifact that carries it — and how that principal meets its floor. Read the seating as a second curriculum. In Order the principals sit still: a gimbal on a plinth, a tile in a frame, small things held to the eye. Then watch for the ones that refuse the stand. They arrive with entropy — Noise seats a ten-metre field of colour, Cellular Automata a structure that grows past any housing — and they return in Emergence, where the principal of the room is a twenty-metre mushroom, or fifty metres of slime that remembers where it has been. Those are **field**: you do not look at them, you stand inside them. Palle's rule draws the line — past about six metres a thing is the environment, and to box it would be to kill it. So the measure does not loosen as the book heats so much as change phase: from the object you regard to the room that regards you.

# Part: Dynamics

*QFEP phase: oscillation — forces, waves, the introduction of time and change. Things begin to move. Newton's laws translate to code. Waves oscillate. Sound becomes visible. The φ term — rate of change — starts to matter.*

## Chapter 5: Change: Rate, Accumulation, and Flow

> **Things change. Change accumulates. Accumulation flows.**

`f'(x) = lim_{h→0} (f(x+h) - f(x)) / h; ∫_a^b f(x) dx = F(b) - F(a); F = grad ϕ (vector field as gradient of a scalar)`

The calculus substrate, made visible. Change as instantaneous rate (derivative); accumulation as continuous addition (integral); vector field as flow at every point in space. This sequence's job is to establish the vocabulary so forces, wavefunctions, randomness, and noise can name what they're doing instead of running on an unintroduced backbone.

### The Principal

This chapter's principal is **player trace** — *path(t) — the sequence of positions your body occupies over time* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**player trace**

![player trace](/artifact-gallery/captures/player_trace/front.png)

*path(t) — the sequence of positions your body occupies over time*

A recorder that turns the player's motion into a visible line in space. Every step writes another point, so translation through the room becomes geometry rather than a forgotten action. The artifact makes path and trajectory tangible, especially when compared against grids and axis-constrained motion. It turns movement into a time-indexed drawing.

> every path through space is a function of time, and you are constantly computing it

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

### The Walk — further in

### The Turn — parameters

Watch a tangent line slide along a curve and read its slope. Pump up the count on a Riemann sum and watch rectangles converge into a continuous integral. Release particles into a vector field and watch them flow. Take over the catalyst and sustain its contact on a target — accumulation made bracelet-felt.

Open in the dressing-room viewer: player trace.

### The Critical Reading

QFEP term: **F**

Foundation — the calculus substrate. Derivative as instantaneous rate of change, integral as accumulated quantity, vector field as flow. The conceptual vocabulary that forces, wavefunctions, randomness, and noise will all use.

The artifacts' own claims:

> every path through space is a function of time, and you are constantly computing it — *player trace*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Change_Intro | 10×11 | 4 | 4.1 m |
| Change_Velocity | 10×11 | 4 | 1.0 m |
| Change_Slope_Surface | 10×11 | 2 | 3.1 m |
| Accumulation_Area | 10×11 | 3 | 4.1 m |
| Accumulation_Riemann | 10×11 | 3 | 25.5 m |
| Flow_Field | 10×11 | 2 | 3.1 m |
| Flow_Particle_Pulse | 10×11 | 2 | 0.0 m |
| Change_Reconciliation | 10×11 | 3 | 4.1 m |

What this chapter teaches, walked rather than read:

- Change as instantaneous rate: the derivative; slope of a curve at a point; velocity as rate of position
- Slope across a curve: how slope itself becomes a function (derivative-as-function)
- Accumulation as continuous addition: the integral; area under a curve; total from rate
- Riemann sum: discrete accumulation approaching continuous; how rectangles become integrals in the limit
- Vector fields: change-and-flow at every point in space; the first encounter with a function of space (not just time)
- The fundamental theorem of calculus: change and accumulation are inverse operations; one undoes the other
- Carry-forward to forces and waves: F = ma is calculus made physical; sine is the function whose second derivative is itself negated

### The Seed

> **Things change. Change accumulates. Accumulation flows.**

Exercises:

1. Change as instantaneous rate: the derivative; slope of a curve at a point; velocity as rate of position
2. Slope across a curve: how slope itself becomes a function (derivative-as-function)
3. Accumulation as continuous addition: the integral; area under a curve; total from rate
4. Riemann sum: discrete accumulation approaching continuous; how rectangles become integrals in the limit
5. Vector fields: change-and-flow at every point in space; the first encounter with a function of space (not just time)
6. Walk Change_Intro in VR and find where the rule first breaks its own pattern.
7. Open player_trace in the dressing-room viewer and change one parameter until it stops being itself.

*Next: forces*

### The Ledger

- **the dig** — 1 of 12 artifacts excavated; 11 remain at depth.

## Chapter 6: Vectors & Forces: From Direction to Dynamics

> **Direction + magnitude = vector. F = ma. Acceleration is the only thing you feel. Position and velocity are states; force is what changes them.**

`v = (x,y,z), |v| = √(x²+y²+z²), F = ma → a = F/m → v += a·dt → p += v·dt`

The fundamental language of 3D space meets the physics that brings it to life. Vectors encode direction and magnitude—the building blocks of everything spatial. Forces convert those vectors into motion through Newton's laws. Master vectors, master forces, master the physical world.

### The Principal

This chapter's principal is **ca rules workbench** — *an interactive 1D-Wolfram cellular automaton workbench — the player turns ONE slider to scrub rule number ∈ [0, 255], and a 256×256 evolution texture redraws live above the table from a single seed cell. The class indicator lamp shifts among four QFEP phase colors (blue=Class 1 frozen, green=Class 2 periodic, orange=Class 3 chaotic, red=Class 4 edge-of-chaos). At rule 30 the lamp glows orange and a label surfaces "high H ≈ 1 — see shannon_workbench". At rule 110 the lamp glows red and "Turing-complete — see halting_workbench" appears. At rule 90 Sierpinski triangles bloom on the panel and "fractal — see fractals (when built)" lights up. At rule 0, 255, 254 the panel goes nearly blank and "vacuum — everything decays" pops in.* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**ca rules workbench**

![ca rules workbench](/artifact-gallery/captures/ca_rules_workbench/front.png)

*an interactive 1D-Wolfram cellular automaton workbench — the player turns ONE slider to scrub rule number ∈ [0, 255], and a 256×256 evolution texture redraws live above the table from a single seed cell. The class indicator lamp shifts among four QFEP phase colors (blue=Class 1 frozen, green=Class 2 periodic, orange=Class 3 chaotic, red=Class 4 edge-of-chaos). At rule 30 the lamp glows orange and a label surfaces "high H ≈ 1 — see shannon_workbench". At rule 110 the lamp glows red and "Turing-complete — see halting_workbench" appears. At rule 90 Sierpinski triangles bloom on the panel and "fractal — see fractals (when built)" lights up. At rule 0, 255, 254 the panel goes nearly blank and "vacuum — everything decays" pops in.*

Interactive 1D Wolfram elementary CA workbench. One slider scrubs rule R in [0,255]; a 256x256 evolution texture redraws live from a single seed cell; class indicator lamp shifts QFEP phase color (Class 1=blue, 2=green, 3=orange, 4=red). Cross-reference labels surface for rules 0/30/54/90/110/126/150/184/254/255 connecting to shannon_workbench, halting_workbench, and (future) fractals galleries. Sister to /ca-rules-gallery (web frieze frozen at 8 highlighted rules).

> a 3-cell neighborhood and 8 transition bits suffice to encode every behavior on the qualitative gradient from frozen to chaotic to edge-of-chaos. The encoding is small (8 bits = 256 rules), the dynamics are large (universal computation lives at rule 110). Walking the slider is walking from order through periodicity through chaos to the edge — and a single bit-flip can move you across a class boundary.

### The Walk — first steps

#### Vectors Act1 WhatAVectorIs

The question is on the wall before anything else is.

**3D Text Display** — `3t`

**WHAT IS A VECTOR, BEFORE IT IS ANY PARTICULAR ARROW?** The room asks it in capitals at the door and then refuses to answer it in words. It answers in four stations instead, walked in order, and the order is the definition: a where, a which-way, a how-far, and a how-far refused.

Nothing in this hall is added to anything. Nothing is multiplied. You are here to meet the object before anyone does anything to it.

## A where

```gdscript
func project_onto_axes(p: Vector3) -> Array[Vector3]:
    return [
        Vector3(p.x, 0.0, 0.0),
        Vector3(0.0, p.y, 0.0),
        Vector3(0.0, 0.0, p.z),
    ]
```

Three axes and an origin have to exist before a single fact about a vector can be stated. Before the arrow, the frame.

**CoordinateSystem3M** — `CoordinateSystem3M`

You have stood in this frame before, in the first room of the first chapter, where it was the thing you were thrown into. Stand in it again and read your own address off it: three markers ride the three axes, and each is where your shadow lands when the light comes from one direction at a time.

A coordinate is not a property of you. It is a property of you *and the frame*, and the frame was chosen by somebody else. Move the axes and every address in the room changes while nobody in the room has moved. The first fact about a vector is that a *where* is not yet one.

## A which-way, and a how-far

```gdscript
func get_vector(start: Node3D, end: Node3D) -> Vector3:
    return end.global_position - start.global_position
```

A subtraction. That is what a vector is made of: not a place but the difference between two, and the difference has thrown both places away in the making. Grab either handle and the vector changes. Grab both and carry them together, and it does not.

**VectorBasics** — `VectorBasics`

Take the tip and pull. Two facts survive whatever you do to it, and only two: the way it points, and how far it goes. Everything else about the arrow, where it sits, what it is near, which hand is holding it, is furniture.

```gdscript
func slide(arrow: Node3D, offset: Vector3) -> void:
    arrow.global_position += offset
```

Now slide the whole thing across the room. Same direction, same length, and the subtraction above returns an identical `Vector3` afterwards, to the last float. The arrow moved and the vector did not, because the vector was never *at* anywhere.

**Route Vector (applied displacement)** — `route_vector`

A from-pin, a to-pin, and one arrow between them, with a courier walking it to show that the trip is a single move. It is the sentence the whole room is built to say, and it says it once: **a vector is a journey with no starting address.**

Keep hold of how strange that is. Every journey you have ever taken began somewhere. This one keeps the going and discards the from, and it is more useful for it, because a going that belongs to no particular place can be reused in every place.

```gdscript
func component_legs(v: Vector3) -> Array[Vector3]:
    var x_end := Vector3(v.x, 0.0, 0.0)
    var z_end := Vector3(v.x, 0.0, v.z)
    return [x_end, z_end, v]
```

Take it apart and it stays one thing. Along the floor, then across it, then up: three legs laid tip to tail arrive exactly where the single arrow arrived. The room's three axes were never a cage. They were the three directions a journey can be told in.

## How far

```gdscript
func magnitude(v: Vector3) -> float:
    var floor_diagonal := sqrt(v.x * v.x + v.z * v.z)
    return sqrt(floor_diagonal * floor_diagonal + v.y * v.y)
```

Two Pythagoras theorems, stacked. One lies flat on the floor and finds the diagonal of the x and the z. The second stands that diagonal up against the y and finds the diagonal of *that*. `v.length()` returns the same float in a single call and hides the nesting, which is fine until the day you need to know that "how far" was built out of two right angles.

**Length Lantern** — `length_lantern`

Stretch it and it brightens. The glow is the square root of x squared plus y squared plus z squared, and nothing else feeds it, so the lantern is a ruler that reports in light.

```gdscript
func magnitude_under(v: Vector3, norm: String) -> float:
    if norm == "taxicab":
        return absf(v.x) + absf(v.y) + absf(v.z)
    if norm == "chebyshev":
        return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))
    return v.length()
```

But read what the code allows. *Far* is a choice, and there are at least three. Euclidean is the diagonal, the way a crow goes. Taxicab is the walk along the legs, the way a body goes through a city with buildings in it. Chebyshev is the longest leg alone, the way a king moves on a board. The arrow never moves between these. The ruler does, and the same journey is three different distances depending on who is measuring.

The lantern here glows with the diagonal. It could be told otherwise. Two rooms ago, a ruler that altered what it did not measure; here, a ruler that is one of several and does not say so.

## A how-far refused

```gdscript
func unit(v: Vector3) -> Vector3:
    var m := v.length()
    if m < 0.001:
        return Vector3.ZERO
    return v / m
```

Divide the vector by its own length. What is left has a length of exactly one and keeps nothing but the which-way, and every direction there is, in the whole room, lands somewhere on a single sphere of radius one. That sphere is where direction lives once distance has been sent away.

**Vector Normalization** — `vector_normalize_demo`

Pull an arrow of any size and watch it snap to the sphere. Long or short, it lands on the same surface, and the only thing it brings with it is where on the surface it lands. This is the fourth fact, and it is a refusal: a vector can be asked to give up its how-far and it still has something to say.

```gdscript
func is_degenerate(v: Vector3, threshold: float = 0.18) -> bool:
    return v.length() < threshold
```

Except one. Zero has a magnitude, and it is zero, but it has no direction at all, and asking it for one is a division by zero. So the function hands back zero rather than lie about which way it points, and the demo has nowhere on its sphere to put it. That is worth more than it looks: a system that says *I cannot tell you* is rarer than one that tells you something wrong.

## Four facts, one arrow

A where, which was not yet a vector. A which-way and a how-far, which are the whole of one. A how-far refused, which leaves direction alone on its sphere. Walked in order, they are a definition that no sentence could give you, because each fact was something you did with your hand before it was something you knew.

Nothing in this hall acted on anything else. The next one is where vectors first act on each other: to add is to walk, to dot is to agree, to cross is to turn. Carry the sentence in. *A vector is a journey with no starting address.* Everything that follows is what such journeys do when they meet.

*Field notes: Why this room first, outside primitives[^vectors-act1-whatavectoris-1] · Claims checked against the artifacts[^vectors-act1-whatavectoris-2] · Continuity[^vectors-act1-whatavectoris-3] · Neighbours[^vectors-act1-whatavectoris-4]*

[^vectors-act1-whatavectoris-1]: **Why this room first, outside primitives.**
    The spine triage (2026-09-02) rated forces the strongest GOOD sequence (nine of
    sixteen), and this is its opener. The room's own wall question, *what is a
    vector before it is any particular arrow*, is answered as four stations in
    order, and the order is the definition: a where, a which-way, a how-far, a
    how-far refused. The KEEP line is the artifact's own: `route_vector`'s registry
    entry says *a vector is a journey with no starting address* verbatim.

[^vectors-act1-whatavectoris-2]: **Claims checked against the artifacts.**
    - **"The machine turns red" was wrong.** That is the tutorial's sentence;
      nothing in `vector_normalize_demo` turns red. The text now says what the
      tutorial's code does: `unit()` hands back zero rather than lie, and the demo
      has nowhere on its sphere to put it.
    - **`length_lantern.norm` defaults to `euclidean`**, with `taxicab` and
      `chebyshev` as an export enum. The lantern here glows with the diagonal; the
      text says it "could be told otherwise" rather than claiming it switches.
    - **`route_vector` is a from-pin, a to-pin, one arrow, and a courier who walks
      it** to show the trip is a single move. The courier is in the text because he
      is in the code.

[^vectors-act1-whatavectoris-3]: **Continuity.**
    `CoordinateSystem3M` is the frame from Point_One. The text says so: "you have
    stood in this frame before, in the first room of the first chapter, where it
    was the thing you were thrown into." Cross-sequence callbacks like this are
    cheap and make the museum one argument rather than twenty-two.

[^vectors-act1-whatavectoris-4]: **Neighbours.**
    Sara Ahmed, *Queer Phenomenology* (2006): orientation, direction, and which
    objects are within reach. Closer to this room than the room knows. Worth a
    line in a later act, not here; this room is deliberately pre-arithmetic and
    pre-critical, and its restraint is the point.

#### Vectors Act2 VectorArithmetic

Nothing in the last hall acted on anything. This one is where vectors first act on each other, and the hall is built to say it twice: every idea once as a toy in your hand, then once at the size of a room you step into.

There are six operations. Three verbs carry them, and the room's own reflection puts them in one line at the end. You will arrive there having done each one with your hands.

## To add is to walk

```gdscript
func head_to_tail(a: Vector3, b: Vector3) -> Array[Vector3]:
    var origin := Vector3.ZERO
    return [origin, a, a + b]   # tail, joint, resultant head
```

**Vector Addition (a + b, two-pad console)** — `vector_add`

Two pads on the front of a console, one per vector. Drag a pad and that arrow's tip follows your hand: cyan for the first, amber for the second, and the second is drawn *from the first's tip*, not from the origin. Moving it there costs nothing, because you learned in the last hall that a vector has no address. The green arrow that closes the walk is the sum.

That is the whole of addition. Not a count. A walk: go a, then go b, and a plus b is where you are standing.

**Vector Addition Walk (Room Scale)** — `vector_addition_walk`

Now step into it. Three metres of grid, half a metre to a line, and the endpoints at body height where you can take hold of them. Walk the first arrow. Walk the second from where the first left you. The parallelogram draws itself around you, and the resultant is the diagonal you would have taken if you had known where you were going.

## Subtraction is the gap

```gdscript
func difference(a: Vector3, b: Vector3) -> Vector3:
    var b_flipped := -b
    return a + b_flipped
```

**Vector Subtraction (a − b, two-pad console)** — `vector_sub`

The same console, flipped. Set a and b, and watch what is drawn: a, then *minus* b head to tail, with a faint ghost of the original b left standing so you can see the flip happen. The result points from b's tip back to a's. That is what subtraction is, and read the code again to see what it is not: there is no second operation. a minus b is a plus the reverse of b, and the arrow you get is the arrow of the gap between them, the one that says how far, and which way, one thing is from another.

## A volume knob for a direction

```gdscript
func weight_of(mass: float) -> Vector3:
    return Vector3.DOWN * 9.8 * mass
```

**example_2_3_gravity_scaled_by_mass_vr** — `example_2_3_gravity_scaled_by_mass_vr`

Three masses on a ladder, half a kilogram, one and a half, three, and over each a force arrow pointing at the floor. Every arrow points the same way. Only the lengths differ, and they differ in exactly the ratio of the masses, because a scalar multiplies a length and leaves the line alone.

A scalar cannot turn a vector. It can stretch it, shrink it, and, if it is negative, reverse it along the same line, and that is the whole of what a plain number can do to a direction. Gravity is the room's example because it is the one scalar you have been carrying since you arrived: nine point eight, times whatever you weigh, straight down.

## To dot is to agree

```gdscript
func agreement(a: Vector3, b: Vector3) -> float:
    return clampf(a.normalized().dot(b.normalized()), -1.0, 1.0)
```

**Dot-Aligner (aim · foe = mercy)** — `dot_aligner`

A turret on a pedestal, and a cube drifting past it. The gold arrow is where the turret aims; the cyan arrow is the direction to the cube. Swivel until they agree, and watch the charge: it is one number, the dot of the two directions, and it climbs from nothing as the angle closes. At an agreement of 0.985, which is within ten degrees, the beam locks and the cube turns from red to green.

That number is the cosine of the angle between them, once both lengths have been divided out. One float stands in for a whole angle: one is the same direction, zero is square on, minus one is opposed. The dot product was never an angle. It is what an angle *costs*.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    return rad_to_deg(acos(agreement(a, b)))
```

**Dot Product (Walk-Inside)** — `vector_dot_product_xl`

Five metres square, and the two arrows share an origin you can stand at. Take hold of either and swing it; the readout above you gives the dot and the angle side by side, so you can watch one fall as the other opens. Stretch the second with the slider and the dot grows while the angle does not move. The hinge between them is the angle made into a thing you can push.

## The part of you that lives on someone else's line

```gdscript
func project(a: Vector3, onto: Vector3) -> Vector3:
    var n := onto.normalized()
    return n * a.dot(n)
```

**Projection Shadow ((a·n̂)n̂ as a shadow)** — `projection_shadow`

A sun overhead, a rail on the floor, and an object floating off to one side of it. Its shadow lands on the rail, and the distance of that shadow from the origin is the dot of the object's position with the rail's direction. Multiply that number back along the rail and you have the projection: the part of the object that lives on the rail's line.

```gdscript
func reject(a: Vector3, onto: Vector3) -> Vector3:
    return a - project(a, onto)
```

The perpendicular drop from the object to its shadow is the rest. Every vector splits this way, into a part along another and a part square to it, and the two parts add back to the original exactly.

**Projection & Reflection (Walk-Inside)** — `vector_projection_reflection_xl`

Walk into it. A vector arrives at a glowing plane and comes apart against it: the projection lying in the plane, the reflection leaving it. Take hold of the plane's normal and tilt it, and both halves recompute as you turn. This is the operation a mirror performs, and a floor, and every surface a thing has ever bounced off.

## To cross is to turn

```gdscript
func torque(arm: Vector3, force: Vector3) -> Vector3:
    return arm.cross(force)
```

**Torque Crank (r × F you can feel)** — `torque_crank`

A lever arm on a flywheel's hub, and a push. The cross product of the arm and the push is a third arrow, gold, pointing up the axle, and the wheel turns about it. Its length is the two lengths times the sine of the angle between them, and read what that means with your hands: push straight along the arm and nothing happens at all. Push square across it and the wheel spins hardest. The cross product is the turn left over when two directions refuse to align.

You have used it before without being told. Two rooms into the first chapter, every face in the museum got its direction from two edges crossed at a corner. Here the same operation, with a push instead of an edge, is what makes anything turn.

**Cross Product (Walk-Inside)** — `vector_cross_product_xl`

Five metres square. Two arrows span a glowing parallelogram on the floor, and the purple arrow rises out of it, perpendicular to both. Swing either arrow and the parallelogram thins toward nothing as they line up, and the purple arrow shrinks with it. The paddle wheel spins by the right-hand rule, and the readout confirms what you can see: the product is square to both of its parents, always.

```gdscript
func wasted_half(arm: Vector3, force: Vector3) -> Vector3:
    var r := arm.normalized()
    return r * force.dot(r)
```

Now put the two products beside each other. What the projection keeps of a push, the part along the arm, is exactly what the cross product throws away, and what the cross product keeps is exactly what the projection discarded. Dot and cross are one question asked in opposite directions: how much do these two agree, and how much do they refuse to.

## Out of reach

**Vector Addition (Laser, 4 m+)** — `vector_addition_xl_laser`

**Vector Subtraction (Laser, 4 m+)** — `vector_subtraction_xl_laser`

At the far end, addition and subtraction once more, built so large that the tips are past your arm. Point a hand's laser at an endpoint, hold, and sweep, and the sum and the difference redraw at a scale no hand could hold. The room has now shown you each operation three ways: in your hand, around your body, and beyond your reach, which is the size most of them come at.

## Three verbs

To add is to walk. To dot is to agree. To cross is to turn.

That is the act, and it is a definition no page could give you, because each verb was something your body did before it was something you knew. Nothing here was a symbol. Every operation was a thing one vector did to another, and you were the thing doing it.

The next act takes these and spreads them over space and time, so that a vector is no longer one arrow you hold but a field of them, everywhere at once, and the arrow stops holding still.

*Field notes: Why nothing needed rewriting[^vectors-act2-vectorarithmetic-1] · Exactness decisions[^vectors-act2-vectorarithmetic-2] · Continuity[^vectors-act2-vectorarithmetic-3] · On trigonometry[^vectors-act2-vectorarithmetic-4] · Open[^vectors-act2-vectorarithmetic-5]*

[^vectors-act2-vectorarithmetic-1]: **Why nothing needed rewriting.**
    The triage rated this GOOD and it was right: the nine tutorial blocks map one
    to one onto the placed hand/room pairs, and the eight `sub:` cells carry one
    truth per station. The text follows the subtitles' own beats and closes on the
    room's reflection line, which is the KEEP: *to add is to walk; to dot is to
    agree; to cross is to turn.* The tutorial was left as it is.

[^vectors-act2-vectorarithmetic-2]: **Exactness decisions.**
    - **Every quoted function is probed** (`probe_act2_tutorial.gd`, seven
      checks): the walk closes at a + b; the difference is the arrow from b's tip
      to a's; a scalar keeps the line and scales the length by the mass ratio;
      agreement is 1 / 0 / −1 for same / square / opposed and `angle_between`
      gives 90; projection plus rejection adds back exactly and the rejection is
      square to the rail; a push along the arm gives zero torque and across it
      gives |r||F|; and the room's best line is proven as a number: |r × F| equals
      |r| times what is left of F after `wasted_half` is removed, so dot and cross
      are "one question asked in opposite directions."
    - **The aligner's lock is a number.** `LOCK_DOT := 0.985` in `dot_aligner.gd`;
      acos(0.985) is 9.9°, so the text says "within ten degrees."
    - **The gravity ladder is 0.5, 1.5, 3.0 kg** (`MASS_LADDER`), and the text says
      the arrows differ "in exactly the ratio of the masses."
    - **Physical claims were read from the artifacts**: the two pads and the
      cyan/amber/green arrows of the consoles; the ghost of +b on `vector_sub`; the
      3 m walk-in grid at 0.5 m; the turret, the drifting cube and the red-to-green
      conversion; the sun, rail and shadow; the hinge gadget; the flywheel and the
      gold axle arrow; the paddle wheel and the right-hand rule; the laser-grabbed
      pair at the far end, which the text gives one beat as a third scale.

[^vectors-act2-vectorarithmetic-3]: **Continuity.**
    The cross product was used in Point_Triangle_Context to light a face ("two
    edges out of a corner, crossed"); the text says so: "you have used it before
    without being told." The nine point eight from `weight_of` is called "the one
    scalar you have been carrying since you arrived."

[^vectors-act2-vectorarithmetic-4]: **On trigonometry.**
    This room names cos θ, sin θ and `acos`, and so do its own subtitles
    (`truth_dot`: a·b = |a||b|cos θ). The rule that keeps the angle implicit was
    Palle's for the primitives chapter; forces is the fifth sequence and the
    room's material already speaks in these terms, so the text does too, while
    leading with "agreement" as the word and giving the cosine as what agreement
    costs.

[^vectors-act2-vectorarithmetic-5]: **Open.**
    - `vector_addition_walk` and the three `_xl` exhibits are ~5 m footprints
      placed as single cells; the plan's LIVE_OVERSHOOT handles the venue, and
      nothing in the text depends on where the overshoot lands.

#### Vectors Act3 FieldsAndMotion

Everything you have done to a vector so far, it held still for.

You walked it, flipped it, stretched it, asked two of them how much they agreed, crossed them and got a turn. Through all of it the arrow waited to be operated on. This hall is where it stops waiting, and it stops in two ways, so the hall is in two halves. In the first, there is an arrow at every point, and the room decides where you drift. In the second, there is one arrow, and the world keeps editing it.

## Everywhere at once

```gdscript
func field_at(p: Vector3) -> Vector3:
    var swirl := Vector3(-p.z, 0.0, p.x) * SWIRL_GAIN
    var radial := p * RADIAL_GAIN
    return (swirl - radial).limit_length(2.5)
```

**VectorFieldFlow** — `VectorFieldFlow`

A console, and on it a floor of small arrows. Read the function that makes them: two terms, one that circles the origin and one that runs at it, subtracted. Nothing is stored. There is no list of arrows anywhere; the field is a *rule*, evaluated wherever anything asks, and the arrows you see are only the places where somebody asked. Between them the field is just as real and just as unseen.

```gdscript
func advect(pos: Vector3, vel: Vector3, delta: float) -> Array:
    var sample := field_at(pos)
    vel = vel.lerp(sample, 0.08) * 0.98
    return [pos + vel * delta, vel]
```

Watch a particle. It has no memory and no plan. It reads the arrow under its feet, leans toward it, and moves, and that is the whole of its intelligence. A field is force that has decided to be everywhere at once, and a thing inside a field does not need to know anything except where it is.

**Weather Vector Field — Storm Chamber** — `weather_vector_field`

Now step into one. Five metres square, a hundred and forty-four arrows on the floor, and two wind vectors at body height that you can take hold of. Pull them. They add the way you learned to add in the last hall, head to tail, and the sum is the weather.

```gdscript
func drive_storm(a: Vector3, b: Vector3) -> void:
    var sum := a + b
    _rain_material.gravity = rain_acceleration(sum, gravity_strength)
    _windsock.rotation.y = atan2(sum.x, sum.z)
    _anemometer_speed = sum.length()
```

Everything in the chamber answers to that one sum. The rain slants at it, and the slant is not decided by anyone: it is the ratio of the wind across to the gravity down, and equal amounts give exactly forty-five degrees. The windsock turns to its heading and stretches with its strength. The anemometer spins at its speed. The debris streaks downwind. None of those instruments measures the storm. Each is one projection of the storm's single vector into whatever that instrument can show, a yaw, a length, a slant, which is the last hall's projection again, with weather for the rail.

It is calm when you arrive. The weather is yours to make, and it is made by addition.

## Edited over time

```gdscript
func _physics_process(_delta: float) -> void:
    ball.apply_central_force(acceleration * ball.mass)
    var velocity := ball.linear_velocity
    var position := ball.global_position
    _aim(velocity_arrow, velocity)
    _aim(position_arrow, position)
```

**VectorMotion** — `VectorMotion`

One ball, three arrows. Green from the origin to the ball: where it is. Cyan at the ball: where it is going. Orange, and this is the one you can take hold of: how its going is changing. Only the orange one is driven. Velocity is its running sum and position is velocity's, so the other two arrows are read back off the ball rather than set, and the fading trail behind it is the running sum of the running sum, drawn.

Grab the orange arrow and hold it still and the trail becomes a parabola. Position, velocity and acceleration are not three things. They are one quantity seen at three depths of change, and the ball is where all three depths are visible at once.

**Launch Arc (projectile motion)** — `launch_arc`

Set an angle and a power and fire. You only ever launch a straight vector.

```gdscript
func launch_components(v0: float, theta: float) -> Vector2:
    return Vector2(v0 * cos(theta), v0 * sin(theta))
```

The launch splits into two parts the moment it leaves the pad: a sideways part that carries and never changes, and an upward part that fights gravity and loses. The angle is the whole negotiation between them.

```gdscript
func height_at(vy: float, t: float, gravity: float = 9.8) -> float:
    return vy * t - 0.5 * gravity * t * t
```

The curve is not yours. It is the world's answer to your straight line, and it costs exactly one squared term. Where the two parts are equal, at forty-five degrees, neither is wasted on the other and the range is greatest; thirty and sixty land in the same place, one high and slow, one low and fast. Aim straight up and the range is nothing and all the power goes into height. The pad knows all of this and marks the apex and the landing for you before the arc is flown.

**Bubble Blaster (output velocity vector)** — `bubble_blaster`

And a gun that wears its velocity on the outside. Pull the trigger and bubbles pour out; on the muzzle, an arrow shows the speed they leave with, and a faint cone shows how they spread. Crank the output and the arrow stretches, the cone widens, and the bubbles fly faster and further.

This is where the two halves of the hall meet. One bubble leaving the muzzle is motion, a vector the world will edit, and gravity begins editing it at once. A stream of them is a field, a velocity assigned to every point of the cone. Every emitter is a little field, and every particle in it is a little motion, and the difference between the halves was only ever whether you were looking at one arrow or all of them.

## Spread over space, spread over time

A field is force spread over space. Motion is force spread over time. Both are vectors that refuse to hold still, and you have now stood inside one and thrown the other.

What has not happened yet is a name. The storm pushed you and the pad threw you and gravity bent the arc, and none of them was called anything but a vector. The next act names them: the forces doing the spreading, met at the size of your body.

*Field notes: The hinge, and why it reads whole[^vectors-act3-fieldsandmotion-1] · Exactness decisions[^vectors-act3-fieldsandmotion-2] · The sequence problem this room sits in[^vectors-act3-fieldsandmotion-3] · Open[^vectors-act3-fieldsandmotion-4]*

[^vectors-act3-fieldsandmotion-1]: **The hinge, and why it reads whole.**
    The triage named this the forces hinge: Acts I–II treat vectors as objects and
    operations; here they gain extent (a field) and history (motion). The text is
    built on the room's own symmetry line, *a field is force spread over space;
    motion is force spread over time*, and the two halves meet on the bubble gun,
    which the artifact's own description hands over: "every emitter is a little
    vector field."

[^vectors-act3-fieldsandmotion-2]: **Exactness decisions.**
    - **The chamber is calm by default.** `weather_vector_field` places bare, and
      its `weather` enum defaults to `calm`; the text says "it is calm when you
      arrive. The weather is yours to make, and it is made by addition," rather
      than describing a storm that is not running.
    - **144 arrows** (`arrow_grid_size 12`), **five metres** (`world_size 5.0`),
      the windsock that turns to heading and stretches with magnitude, the
      anemometer that spins at speed: all from the script.
    - **The slant is the ratio**, proven: equal down and across give 45.0°
      (`probe_act3_tutorial.gd`). Range peaks at 45° and 30/60 tie; the parabola's
      apex is at vy/g and the landing at 2vy/g; components recompose to v0²;
      integrating a constant acceleration for a second gives p = a/2 exactly; a
      vertical launch has zero range and the full v0²/2g apex.
    - **`VectorMotion`'s arrows are the colours the script gives them**: green
      position from the origin, cyan velocity, orange acceleration (grabbable),
      and a 50-point fading trail. `drive` defaults to `constant`, so the trail is
      a parabola, and the text says so.
    - **`field_at` and `advect` are quoted but not probed**: they depend on scene
      constants (`SWIRL_GAIN`, `RADIAL_GAIN`) the tutorial does not define. Only
      the pure functions are probed.
    - The tutorial was left as it is; it already carries the argument block by
      block, as the triage found.

[^vectors-act3-fieldsandmotion-3]: **The sequence problem this room sits in.**
    `forces.json` files this room's flow console and storm as "belonging to rung
    5" (`content`: "its flow console belongs to rung 5 and says so"), i.e. the
    field idea is stated here at room 7, dropped for six rooms, and picked up by
    VFM_04_Fields at room 14. That is a sequence-order problem, not a room
    problem, and it is part of the compression case for forces (see the sequence
    notes in the blog and the ruling to come).

[^vectors-act3-fieldsandmotion-4]: **Open.**
    - The `_physics_process` block is engine code, not a pure function; it is
      quoted for the chain and read as prose, and its claim ("only acceleration is
      driven") is verified by the integration check rather than by running a
      RigidBody headless.

#### Vectors Act4a KineticForces

In the last hall the arrow was pushed and bent and thrown, and nothing doing the pushing had a name. This is a park, thirty metres a side, and every machine in it is a force with its name on it. Work, drag, launch, turn, fall. Each one is a force bending a path, and each is built at the size of your body so that it is a place you walk into rather than a line you read.

Walk it south to north. The room's own beats are on the floor, one per force.

## Work

```gdscript
func work_done(force: Vector3, displacement: Vector3) -> float:
    return force.dot(displacement)
```

**Force Mower (W = F d cos θ)** — `force_mower`

A lawn mower with a handle at an angle, and a push arrow living on the handle. Push it. The arrow splits at once into two, the part along the ground and the part driven down into the dirt, and only the first of them moves the mower. Raise the handle and watch the along-part shrink and the down-part grow while the push itself stays the same length.

That is work, and it is the dot product with its costume off. The world only feels the part of a force that goes its way. Push square to the motion and the work is zero, however hard you push, however long.

```gdscript
func push_split(magnitude: float, theta: float) -> Array[Vector3]:
    var along := Vector3(magnitude * cos(theta), 0.0, 0.0)
    var into_ground := Vector3(0.0, -magnitude * sin(theta), 0.0)
    return [along, into_ground]
```

**Sisyphus Mower** — `sisyphus_mower`

And here it is forever: a mower pushed up a striped hill by hands that are not there, handle at thirty-two degrees, sixty newtons a shove, and a ledger counting the joules that bank. Only the cosine of every shove goes into the hill. The rest goes into the dirt, and gravity spends what was banked on the way back down. Effort is conserved. Usefulness is not. One must imagine the mower happy.

## Drag

```gdscript
func drag_step(velocity: Vector3, b: float, delta: float) -> Vector3:
    return velocity * (1.0 - clampf(b * delta, 0.0, 0.6))
```

**Drag Corridor (walk-in air/water/honey)** — `drag_corridor`

Three zones, three metres each: air, then water, then honey. Walk them and feel your own pace taxed more in each. In every zone a dart is launched at the same speed and glides and dies, its velocity arrow shrinking as it goes, and the same launch that crosses the air zone barely lunges in the honey.

Drag is the world charging you rent on speed. It is proportional to how fast you go and it points against you, so it can slow you to nothing and can never turn you round, because the moment you stop there is nothing left to charge.

```gdscript
func distance_under_drag(v0: float, b: float, t: float) -> float:
    return (v0 / b) * (1.0 - exp(-b * t))
```

Read what that means for how far you get. Coast as long as you like, and the distance approaches a number and stops: your launch speed divided by the medium's rate. In honey that number is close. In air it is far. It is never infinite. A thing that pays rent on its speed has a finite reach, however long it is allowed to travel.

## Launch

**Force Pad** — `force_pad`

A glowing square on the floor, one metre a side, with chevrons pointing the way it will send you. Step on it. It hands you a velocity, six metres a second forward and seven up, and then it has nothing more to do with you: gravity writes the rest, and the rest is an arc.

You met the arc in the last hall as a thing you aimed. Here you are the thing launched. A launch is a velocity you are given, and everything after it is the world's answer, one squared term long. The pad cannot give you a curve. Nothing can. It can only give you a straight line and let gravity bend it.

## Turn

```gdscript
func centripetal(speed: float, radius: float, angle: float) -> Vector3:
    var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    return -pos.normalized() * (speed * speed / radius)
```

**Centrifuge Ring (walk-in centripetal)** — `centrifuge_ring`

A pod laps a neon ring three and a half metres across, and two arrows ride it. The velocity is always tangent, along the ring, the way the pod is going. The force is always toward the centre, square to the velocity, and because it is square it never changes the speed, only the direction, which is what going in a circle is: a constant acceleration toward a centre you never reach.

Crank the speed and watch the inward arrow. It grows as the square. Double the speed and the pull quadruples. That is why fast turns throw you, and it is the whole of what a turn costs.

**Prop Carousel** — `prop_carousel`

A fairground carousel of museum props hung on chains, turning under a canopy. Look at the chains. They lean outward, and every child who has ridden one knows it as being flung out. The chains lean out because they have to pull *in*: the angle of every chain is exactly what it takes to supply the inward pull the prop needs to keep circling, and nothing anywhere pulls outward. The outward feeling is your body wanting to go straight, and the chain refusing.

## Fall

```gdscript
func barycenter_offsets(m1: float, m2: float, separation: float) -> Vector2:
    var total := m1 + m2
    return Vector2(separation * m2 / total, separation * m1 / total)
```

**Orbit Walk (walk-in two-body)** — `orbit_walk`

Stand at the centre. A heavy star and a lighter planet wheel around you on opposite sides, three and a half metres apart, and on each of them rides a red arrow of exactly the same length pointing at the other. One force, handed out in two opposite directions, stronger as the square of the distance closes.

The point you are standing on belongs to neither of them. It sits where the heavy mass times its distance equals the light mass times its distance, closer to the heavy one, and make one heavier and it slides toward that one while both orbits resize to keep the trade. An orbit is two things falling toward each other and missing, forever, around a centre that neither of them is at.

```gdscript
func slides(theta: float, mu: float) -> bool:
    var down_slope := sin(theta)
    var friction := minf(mu * cos(theta), down_slope)
    return down_slope - friction > 0.0
```

**Wedge Slide (inclined-plane free body)** — `wedge_slide`

At the far end, the smallest fall there is. A block on a wedge, a slider for the angle, and the textbook triangle drawn live beside it: weight, normal, friction, and what is left. A slope does not change gravity. It changes how much of gravity points along the way out, which is the projection of one downward arrow against a ramp, and friction can match that part but never exceed it. So the angle decides, and the weight cancels out of the deciding: at this block's friction the hill holds at fifteen degrees and gives at sixteen, and it would do the same for a block ten times the mass.

## What edits motion

Work, drag, launch, turn, fall. Every one of them is a force bending a path, and every one was met on foot. That is the act's whole claim, and it is worth saying in the plainest words the sequence has: forces are what edit motion. Position is where you are, velocity is where you are going, and a force is the thing with the pen.

The next half of the act holds the forces that give the path back: the ones that pull toward a rest and overshoot, and keep time by doing it.

*Field notes: Why it reads whole[^vectors-act4a-kineticforces-1] · Exactness decisions[^vectors-act4a-kineticforces-2] · Open[^vectors-act4a-kineticforces-3]*

[^vectors-act4a-kineticforces-1]: **Why it reads whole.**
    The triage rated it GOOD: seven of eight placed stations have their code in
    the tutorial, and the `sub:` cells already give the walk order the intent
    thought was missing (south to north: intro → work → drag → projectile →
    centripetal / gravity → the reflection). The text follows that walk and lets
    the room's own truth beats be the section headings.

[^vectors-act4a-kineticforces-2]: **Exactness decisions.**
    - **Every quoted function is probed** (`probe_act4a_tutorial.gd`, eight
      checks): a square push does zero work; `push_split` conserves the push while
      the useful part shrinks as the handle rises; drag never reverses; the reach
      under drag is finite at v0/b and never passed; `slides` flips exactly at
      tan θ = μ (with the wedge's μ 0.28, holds at 15°, goes at 16°); centripetal
      is square to the tangent and quadruples when speed doubles; the barycenter
      balances m1 d1 = m2 d2 and sits closer to the heavier; mutual gravity is
      equal, opposite and inverse-square.
    - **Numbers from the artifacts, not the intent**: the pad hands you 6 m/s
      forward and 7 up (`forward_force`, `up_force`); the ring is 3.4 m; the
      corridor is three zones of 3 m; the orbit pair are 3.6 m apart; Sisyphus's
      handle is 32° and the shove 60 N; the wedge's μ is 0.28.
    - **`force_pad` had only its subtitle in the tutorial** (the triage's one
      gap). The text gives it the arc from Act III ("you met the arc in the last
      hall as a thing you aimed; here you are the thing launched") rather than
      inventing code for it.
    - **The carousel is the room's best physical proof**: its description says the
      chains lean at exactly tan φ = ω²r/g because they must pull IN, and "nothing
      pulls outward." The text says the outward feeling is the body wanting to go
      straight and the chain refusing.
    - `wedge_slide` was rescued into this room by the first forces fold and is
      already in the tutorial's `slope_components` / `slides`; the text places it
      at the far end as "the smallest fall there is."

[^vectors-act4a-kineticforces-3]: **Open.**
    - `prop_carousel` stands at r25, by the entrance, while `centrifuge_ring`
      stands at r8; the text treats them together under Turn. If the walk should
      meet the hero beside its twin, the carousel wants moving north.

#### Vectors Act4b Oscillation

The last hall's forces bent a path and let it go. These give it back.

A hall of clocks and balances. Every force in it pulls toward a rest and overshoots, or holds a beam level, or hands a motion on without losing any of it, and the reason they keep time is one sign in one line of code. Walk it south to north, the way the room's own beats run.

```gdscript
func restoring_force(displacement: float, k: float) -> float:
    return -k * displacement
```

The minus sign is the entire law. Take a thing from where it rests and the force points *back*, in exact proportion to how far you took it. Everything in this hall that keeps a rhythm keeps it because of that sign.

## Momentum

```gdscript
func total_momentum(masses: Array[float], velocities: Array[Vector3]) -> Vector3:
    var total := Vector3.ZERO
    for i in masses.size():
        total += masses[i] * velocities[i]
    return total
```

**Momentum Cradle (p = mv conserved)** — `momentum_cradle`

Five steel balls on strings. Lift the end one and let it go. The blow travels through the three in the middle, which do not move, and kicks the far ball out to the same height the first one fell from. One in, one out. Sum mass times velocity before and after and the number has not changed; the middle of the cradle is where the momentum is owed but not spent. Motion refuses to be destroyed. It can only be handed on.

## Restitution

```gdscript
func apex_after(bounces: int, drop_height: float, e: float) -> float:
    return drop_height * pow(e, bounces)
```

**Bounce Well (restitution)** — `bounce_well`

A ball dropped into a well, frozen stroboscopically, so that every arc stands beside the last. Each rises to a fixed fraction of the one before it. Set the fraction with the slider: at one the ball never stops, at zero it lands with a dead thud, and everything between is a geometric series. Every bounce is a tax on a fall.

And here is the thing about a geometric series that the well lets you watch: there are infinitely many bounces, and they take a finite time. The four-hundredth adds nothing you could measure. The ball is still, and it got there through an infinity of ever-smaller arrivals, which the portal room said the finite could not do, and which it does here by shrinking faster than it repeats.

## Lever

```gdscript
func balances(f_left: float, d_left: float, f_right: float, d_right: float) -> bool:
    return absf(f_right * d_right - f_left * d_left) < 0.06
```

**Lever (τ = F·d)** — `lever_balance`

A beam on a fulcrum and a slider that moves the right-hand weight along the arm. It does not change the weight. It changes the *torque*, force times distance, and the beam tips toward the bigger product and sits level only when the two agree. A small load far out holds a big one near in. That is the same trade the orbit made in the last hall, with weight for mass and arm for radius, and the room says it plainly: a lever trades force for distance and never gets something for nothing.

```gdscript
func place_pivot(arm: float, w_left: float, w_right: float) -> Vector2:
    var total := w_left + w_right
    return Vector2(arm * w_right / total, arm * w_left / total)
```

**Calder Mobile (balanced, real weights)** — `calder_mobile`

Calder's mobile, and it is actually balanced. Every rod obeys the lever law: its two children are weighed, the pivot is placed so the heavier rides the shorter arm, and the whole thing hangs level from one point at the ceiling. Read the function: weigh both subtrees before you cut the rod, then recurse. The drift you are watching is not decoration. Every arm is answered by a real weight, and the mobile is the lever law four levels deep, moving.

**Calder Mobile (project primitives)** — `calder_object_mobile`

The same law, hung with the museum's own objects: a point, a sphere, a pyramid, an arch, each with a plausible mass, drifting in equilibrium. The first chapter's shapes, balanced by the fifth chapter's rule. The foundational things do not float here. They are weighed.

## Wind

```gdscript
func wind_drag(speed: float, rho: float, c_d: float, area: float) -> float:
    return 0.5 * rho * speed * speed * c_d * area
```

**Weather Vane (wind ∝ v²)** — `weather_vane`

A vane, a flag, and a slider for the wind. The vane swings to point downwind, the flag streams, and the drag arrow grows, and watch how it grows: with the square of the speed. Double the wind and the push quadruples, and the flag goes from a lazy ripple to horizontal. This is not the linear rent of the drag corridor. Squared, the force stops being polite, and it is a force you can only see in the bend of what it pushes.

**Windmill VR** — `example_6_4_windmill_vr`

The older windmill beside it is the demonstration the vane replaced, kept because it turns.

## Pendulum

```gdscript
func swing(t: float, amplitude: float, arm_length: float) -> float:
    var omega := sqrt(9.8 / arm_length)
    return amplitude * cos(t * omega)
```

**Pendulum Hall (walk-in)** — `pendulum_hall`

A real pendulum, four and a half metres of string from a six-metre gantry, swinging at its true period, a little over four seconds, with a glowing arc on the floor recording the sweep. Look at what is in the period and what is not. The length is in it. Gravity is in it. The mass is not: a heavy bob and a light one on the same string keep the same time, and the amplitude is not either, which is why a pendulum can be a clock.

```gdscript
func restoring_torque(theta: float, mass: float = 1.0) -> float:
    return -mass * 9.8 * sin(theta)
```

Except that it is only honest for small swings. The true pull back is mg sin θ, not mg θ, and the pendulum is a spring only while those two are close. At this hall's swing of twenty-four degrees they differ by three percent. Pull it far enough and the period stops being a constant. The clock keeps time on the condition that you do not push it too hard, which is a condition every clock has.

## Spring

```gdscript
func spring_period(mass: float, k: float) -> float:
    var omega := sqrt(k / mass)
    return TAU / omega
```

**Spring Tower (walk-in Hooke)** — `spring_tower`

A heavy mass bobbing on a giant coil, and a slider for the stiffness. Stiffen it and two things happen at once: it gives less, and it ticks faster. The period has the mass in it and the stiffness in it and nothing else. A spring is honest; it returns exactly what it is given, and a big bounce and a small one take the same time, which is the second reason a thing can be a clock.

## The bench

Along the north wall, thirteen more, folded in from a room that used to stand between this hall and the last. They are the same sign at every scale and in every costume, and they are worth a walk.

**Mass-Spring-Damper** — `mass_spring_damper`

The canonical second-order system: a mass, a spring, and a damper that charges rent on speed the way the corridor did. Stiffness pulls back, damping bleeds energy, and between them every vibration that has ever been engineered: the ring that dies away, the door that closes without slamming, the suspension that neither bounces nor jars. Underdamped, critical, overdamped, and the third is the one every engineer is paid to find.

**Coupled Pendulums** — `coupled_pendulums`

Two pendulums joined by a spring. Start one and watch the energy cross to the other and come back, sloshing between them at a beat you can count. This is resonance in its smallest form, and everything from a tuning fork to a bridge that shook itself down is this with more parts.

**Spring System** — `spring_system`

Twenty masses in a chain. A complex vibration is not complex. It is a sum of simple ones, each with its own frequency, and when two of them nearly agree the energy beats between them. That decomposition is the whole of how a sound is analysed, and it is two chapters away.

**Slingshot (elastic launch, PE = 1/2 k x^2)** — `slingshot_pull`

Draw the pouch back and the band stores energy as the square of the pull: twice as far, four times as much. Release, and the stored square becomes launch speed. This is the spring's law read as a bank account, and it is the one machine in this hall that hands its rhythm to the last hall's arc.

**Vector-Joint Playground** — `vector_joint_playground`

Six stations of joints, each paired with a vector you can drag: a crane, pistons, a door, a seesaw, a waterwheel, a spring tower. A joint is a subtraction: it takes degrees of freedom away from a thing until only the motion you wanted is left, a hinge leaving one turn, a slider leaving one slide, a cone leaving a wobble inside a limit. The swings and the crank and the press beside it are each one such subtraction made large.

**Surreal Kinetic Sculpture** — `surreal_kinetic_sculpture`

And one that is not a lesson. Gears drive pendulums that scatter particles through fields while banners ripple in a simulated wind, every system in the chapter woven into one perpetually moving thing. It is here as a celebration, and it is allowed to be.

## These keep a rhythm

Spring, pendulum, cradle, bounce, lever, wind. Forces that repeat, conserve and balance, and every one of them keeps faith for the same reason: the pull back is proportional to how far you have been pulled, and the sign on it points home.

The last hall asked what a force does to a body. The next one stops asking that, and asks what a force does to a room.

*Field notes: Two rooms in one, by the day's fold[^vectors-act4b-oscillation-1] · Exactness decisions[^vectors-act4b-oscillation-2] · Continuity[^vectors-act4b-oscillation-3] · Open[^vectors-act4b-oscillation-4]*

[^vectors-act4b-oscillation-1]: **Two rooms in one, by the day's fold.**
    The room's own nine stations carry the argument (the triage: nine tutorial
    functions hit all nine placed tokens; eight `sub:` beats). The same afternoon
    the second forces fold rescued thirteen springs from VFM_06 onto the north
    wall. The text keeps the two apart on purpose: the nine are the walk, south to
    north on the room's beats; the thirteen are "The bench," one section, named
    as folded in "from a room that used to stand between this hall and the last."
    Six of the thirteen get a beat and a tag; the joint quartet (ChainSwing,
    ConeTwistBag, HingeCrank, SliderPress), `harmonic_motion_demo`,
    `spring_network` and `work_energy_demo` are described under the playground's
    beat without their own tags.

[^vectors-act4b-oscillation-2]: **Exactness decisions.**
    - **Every quoted function is probed** (`probe_act4b_tutorial.gd`, eight
      checks). Two are worth naming: the hall's pendulum at L = 4.6 m gives
      T = 4.30 s, matching the artifact's "~4.3 s"; and the bounce series' total
      time is finite (400 bounces at e = 0.6 from 2 m; the 401st adds under a
      microsecond), which the text sets against the portal room: an infinity of
      ever-smaller arrivals that does finish, "by shrinking faster than it repeats."
    - **The honest limit is measured.** At the hall's amplitude (0.42 rad, 24°)
      mg sin θ and mg θ differ by 3%; the text says "three percent" and "the clock
      keeps time on the condition that you do not push it too hard."
    - **Mass and amplitude are absent from the period by construction**:
      `spring_period(mass, k)` and `swing(t, amplitude, arm_length)` have no
      amplitude and no mass respectively as period inputs, and the text says why
      that is what makes a clock possible.
    - **Physical claims from the artifacts**: five balls and the still middle;
      the stroboscopic well; the lever slider changes torque, not weight; the
      Calder is "actually balanced," heavier child on the shorter arm, one ceiling
      point; the object mobile hangs point / sphere / pyramid / arch; the vane's
      flag from ripple to horizontal; the tower's stiffness slider.
    - `example_6_4_windmill_vr` is the redundancy the triage named; it gets one
      honest line ("kept because it turns") rather than a claim.

[^vectors-act4b-oscillation-3]: **Continuity.**
    The lever is the barycenter "with weight for mass and arm for radius"; the
    damper is the corridor's rent; the slingshot hands its rhythm to Act IVa's
    arc; the spring chain's decomposition is "two chapters away" (wavefunctions).

[^vectors-act4b-oscillation-4]: **Open.**
    - The rescued thirteen stand where the fold put them, two cells apart along
      r1 and r0. If the bench should read as a bench, they want grouping by kind
      (joints together, the two coupled systems together).

#### VFM 07 Gravity

Attraction at a distance, and then what happens when more than two things believe in it.

This is a bench, not a walk: two plinth rows in a south gallery and a north row of larger machines, every one of them the same law. You met the law in the park as one machine among five. Here it is on its own, and the room takes it from two bodies to three, which is where the arithmetic stops being able to tell you the future.

## The law

```gdscript
func attract(a: Body, b: Body, G: float) -> Vector3:
    var arm := a.position - b.position
    var d := clamp(arm.length(), 1.0, 25.0)
    var strength := G * a.mass * b.mass / (d * d)
    return arm.normalized() * strength
```

**Attraction and Orbit** — `exercise_1_8_solution_attraction_magnitude_vr`

A ball orbits a mass you can take hold of. Drag the mass and the orbit reshapes under your hand. The force runs along the line between them, and its strength is the product of the two masses divided by the distance *squared*. Read what the square costs: double the distance and you keep a quarter of the pull. Double it again and you keep a sixteenth. Closer means stronger, and not politely.

**example_2_8_two_body_attraction_vr** — `example_2_8_two_body_attraction_vr`

Two bodies, and the clamp in the code is worth a look. Without it a close encounter divides by nearly nothing and the numbers explode. That is not a fault in the law. It is the law taken further than a simulation can follow, and the clamp is honest engineering: it says where the machine stops trusting itself.

## Falling and missing

```gdscript
# a stable orbit: sideways velocity exactly countering the fall
body.velocity = tangent * sqrt(G * central_mass / radius)
```

**Orbit Pair (gravity, F = G m₁m₂/r²)** — `orbit_pair`

Two bodies orbiting a point that belongs to neither, the barycenter, each pulled toward the other by an arrow of exactly the same length. You stood on that point in the park. Here you can watch the trick of every moon from outside: it falls forever and forever misses, because its sideways speed exactly counters the fall, and there is one speed at every distance that does that.

**Orbital Mechanics Demo** — `orbital_mechanics_demo`

Launch a satellite and set that sideways speed yourself. Too slow and it spirals in. Too fast and it leaves and does not come back. The orbit that never returns has a number, and it is not far above the circular one: the square root of two times it. Go by increments and you will find it. Between the two, every ellipse Kepler drew, and beyond it, the hyperbola that is a visit rather than a stay.

## Three

```gdscript
for i in bodies.size():
    for j in bodies.size():
        if i != j:
            bodies[i].acceleration += attract_accel(bodies[j], bodies[i])
```

Every body attracts every body. With two, the futures are circles and ellipses, and a formula will tell you where either body is at any time you name.

**Three-Body Problem** — `three_body_problem`

With three, stand at the three-body problem and watch prediction die.

There is no formula for where three bodies will be. There is a series, a century old, that converges so slowly it is useless for anything, and so in practice there is only simulation: step the law forward and see. And here is the part the machine can prove to you. Nudge one body by a millionth of a metre and run both versions. With two bodies the difference stays a few millionths. With three it grows to metres, half a million times as far, and then the two futures have nothing to do with each other. Same law, same code. Restart it three times and find what was different: the initial conditions are the third body's secret.

Two famous exceptions stand in this station's settings, the figure-eight and the Lagrange triangle, orbits so balanced that three bodies do repeat. They are exceptions, and they were found by searching, not by solving.

**Chaos Attractor** — `chaos_attractor`

The shape of that unpredictability, drawn. This is a different system, the one Lorenz found in the weather, but it has the same property, and eight thousand points of it trace the butterfly: a path that never repeats and never leaves. Chaos is not randomness. It is a law followed exactly, by a future that cannot be known in advance.

## Many

**example_2_9_n_body_attraction_vr** — `example_2_9_n_body_attraction_vr`

More than three, and the law does not change; only the count does. Every body pulls on every other, which is a pair of forces for every pair of bodies.

**N-Body Gravitational Simulation** — `nbody_simulation`

Twenty bodies from a cloud, and watch what the law does with them: a disc forms, a binary pair, a cluster that scatters. Nothing organises them. The pairwise pull does, and the cost of computing it is the number of pairs, which grows as the square of the count. That square is the bottleneck that drove astronomers to invent the tree methods that made galaxies simulable, and it is the same square as the law's own. Gravity is expensive in exactly the way it is strong.

## The well

```gdscript
func well_depth(pos: Vector3, center: Vector3) -> float:
    return -G_well / max((pos - center).length(), 0.5)
```

**Gravity Well** — `gravity_well`

The rubber sheet, made real. A grid warps around a mass you can move, and coloured particles roll along the curve: orbiting, spiralling in, escaping, depending on how fast they arrive. The depth is not decoration. It is the energy a thing would need to climb out, drawn as geometry, and deeper always means closer in. This is the picture everyone reaches for when they explain gravity, and it is worth knowing that it is a picture of a *potential*, not of a force: the slope is the force, and the height is what the slope has cost you.

## Gravity's office job

```gdscript
# force-directed layout: edges are springs, nodes repel like masses
for pair in node_pairs:
    apply(repulsion(pair))   # gravity's mirror
for edge in edges:
    apply(spring(edge))      # last room's force law
```

**forcedirected3d** — `forcedirected3d`

A graph laying itself out. Every node repels every other by the inverse square, gravity's mirror, and every edge is a spring from the last hall pulling connected nodes together. Nobody arranges it. The two forces argue until they agree, and the arrangement is the equilibrium: the picture of the graph that costs the least.

**Grid3D — Force-Directed Layout** — `grid3d_force_directed`

The same, on a grid, watching it settle. This is the sequence eating its own tail: attraction and springs, repurposed from physics into layout, so that a diagram can find its own shape. Graph theory is eleven chapters ahead, and it starts here, in a room about planets.

## What three bodies cost

Two bodies and a formula. Three bodies and a simulation, which is the machine inventing the between, one step at a time, with no formula to check it against, because there is none. That is a strange place for a physics room to end, and it is the honest one: the law is exact, the future is not, and the difference between them is the number of things that believe in it.

The next bench takes one law you know, legs, and asks what a gait is once you know how many feet are on the ground.

*Field notes: The first bench room written[^vfm-07-gravity-1] · Exactness decisions[^vfm-07-gravity-2] · Continuity[^vfm-07-gravity-3] · Open[^vfm-07-gravity-4]*

[^vfm-07-gravity-1]: **The first bench room written.**
    The triage rated it GOOD: the tutorial runs attract → inverse-square → orbit →
    third body → well → force-directed layout, one to one onto the placed
    stations, with only `chaos_attractor` outside the code and reached by the
    three-body beat. The blurb is four words and the intent two lines; the room's
    argument lives in its tutorial and its plinths, and the text is built from
    those.

[^vfm-07-gravity-2]: **Exactness decisions.**
    - **"No formula exists" is made exact.** Sundman's series (1912) is a
      convergent solution to the three-body problem that is useless in practice.
      The text says: "There is a series, a century old, that converges so slowly it
      is useless for anything, and so in practice there is only simulation." The
      KEEP line's force survives and the claim is true.
    - **Prediction dying is a number.** `probe_gravity_tutorial.gd` nudges one
      body by 1e-6 and integrates two bodies and three side by side; the three-body
      separation must be at least 1000× the two-body one. Measured: two bodies
      drift 2.6e-5 over 12 time units, three bodies 13.1, a ratio of 510,190. The
      first draft said "grows by thousands", which undersold it by two orders of
      magnitude; the text now says "a few millionths" against "metres, half a
      million times as far".
    - **Escape is √2 × circular**, and the probe integrates it: at 0.6 v_circ the
      satellite falls in, at 1.05 v_esc it is still receding at a distance of
      many radii. The text: "the orbit that never returns has a number, and it is
      not far above the circular one: the square root of two times it."
    - **The tutorial's `attract` uses a `Body` class it never defines.** Quoted as
      the tutorial wrote it; the probe carries a pure version of the same
      arithmetic. The clamp gets its own beat: "where the machine stops trusting
      itself."
    - **The Lorenz attractor is not gravity.** `chaos_attractor` defaults to
      LORENZ, 8000 points. The text says so: "a different system, the one Lorenz
      found in the weather, but it has the same property."
    - **The well is a potential, not a force**, and the text says the slope is the
      force and the height what the slope has cost you.
    - **The n-body cost is O(n²)** by the artifact's own description (Barnes-Hut
      as the consequence), tied to the law's own square.
    - **The probe fell into `%e` a second time.** GDScript has no `%e`; the line
      printed raw and the numbers were skipped while the assert still passed. The
      Act IVb probe carries a comment about exactly this. Now a memory.
    - Physical claims from the artifacts: the grabbable attractor whose orbit
      reshapes; twenty bodies from a cloud; the three-body configurations
      (figure_eight, lagrange as "the two famous exceptions"); coloured test
      particles on the deformable grid; repulsion k/r² on all pairs and springs on
      edges only.

[^vfm-07-gravity-3]: **Continuity.**
    The barycenter from Act IVa ("you stood on that point in the park"); the
    springs from Act IVb inside the force-directed layout; simulation as "the
    machine inventing the between" from Point_Trace, here with no formula to check
    it against; graph theory "eleven chapters ahead."

[^vfm-07-gravity-4]: **Open.**
    - The blurb (`Attraction at every scale.`) and intent are thin against the
      room; they could be regenerated from this text.

#### VFM 09 Legs

Count the legs, and the walk follows: not as a style, but as arithmetic.

Seven walkers stand in one row on the floor, one leg to eight, and nothing about them is on a plinth, because a thing that paces wants the ground. Every one of them is the same build: a small box body a hand above the floor, and long arching legs, taller than you are at the knee, reaching out to feet more than two metres from the centre. Every one glides at the same slow pace, turns when it likes, and turns for home when it has strayed a metre and a half. The only thing that changes from bay to bay is the count. That is the experiment.

## The rule

```gdscript
# a body is statically stable while its centre of mass sits inside the
# polygon formed by the feet that are currently planted
func can_lift(planted: Array[Vector3], com: Vector3) -> bool:
    if planted.size() < 3:
        return false          # two points make a line, and a line is a fall
    return _inside_polygon(planted, com)
```

Read it once and carry it down the row. Fewer than three feet on the ground is a fall. Three or more, and the body stands only while its centre is inside the shape they make. Nothing else is needed. Now the count decides.

## The row

**One Leg** — `one_leg`

One leg, and no step at all. A step needs another foot to stand on while this one is in the air, and there is no other. So the one foot does the only thing the rule leaves it: it stays down, and it is dragged along the floor beside the body as the body glides, swinging round when the body turns. The honest gait for one leg is a hop, and a hop needs the whole body to leave the ground. Nothing in this row leaves the ground.

**Two Leg Critter** — `two_leg_critter`

Two legs, and here is the rule that the next four walkers all share, so learn it once. A foot stays planted where it landed while the body glides on. When it has been left a metre and a half behind its shoulder, it steps: a quarter of a second, a metre high, landing a little ahead. One foot in the air at a time, never two, and always the foot that has been left furthest behind. With two legs, one foot up leaves one foot down. A single point is not a shape. By the rule, every step is a fall.

**Three Leg Critter** — `three_leg_critter`

Three legs, and one foot up leaves two, which is a line, which is a fall. Three is the smallest number that stands still by the rule, and the first number that cannot take a step by it. Watch the burst: after a turn the three feet find themselves stretched together, and they step one after another, a quarter of a second each, and then all three are down for a long while as the body slides on bent legs.

**Four Leg Critter** — `four_leg_critter`

Four legs, and now the rule gets interesting. One foot up leaves three, a triangle, and a triangle is a shape. But look where the centre sits: on the diagonal of the square the feet make, which is exactly the edge of the triangle that remains. On the line, and a line is a fall. A four-legged animal steps by leaning first, a hand's width off the diagonal, and then lifting. This one never leans. Its body is held level and slid forward, and its feet catch up.

**Five Leg Critter** — `five_leg_critter`

Five legs at equal angles, and the rule starts to pass. One foot up leaves four, and the centre is well inside. Five is also where a pattern appears that no even walker has: lift any two feet that are apart, and the animal stands; lift any two that are neighbours, and it falls. Five pairs pass, five fail, and no mirror maps the passing set onto itself.

**Six Leg Critter** — `six_leg_critter`

Six legs, and one foot up leaves five. The rule is satisfied with room to spare, and the same is true of any way of lifting three at once so long as they alternate: the other three make a triangle round the centre. This walker takes the cautious road and lifts one.

**Octapod IK** — `octapod_ik`

Eight legs, and a different animal. It is about half the size of the others, faster on its feet, and it is the only one in the row that lifts a group: four feet at once, every other leg, so that the four still down make a square round the centre, and then the other four. Four on the ground at every instant. Of the seven, it is the only one whose stepping passes the rule while it moves.

## What the count buys

A gait is not a style. It is what is left once you know how many feet are on the ground and how many can be in the air at once.

Lay the row against the rule and it reads like a table. One cannot step. Two and three step and fall. Four steps and falls unless it leans, which it does not. Five and six step and stand. Eight lifts four and stands. None of them fall, because nothing in this hall is a body that gravity can catch: they are drawings of walkers, held at their height and slid along, and the rule on the wall is the exam gravity would set if it were here. Gravity was the last hall. Here it has been left outside, so that you can read the exam instead of watching it marked.

That is what a diagram is for. A fall you could only have felt; the reason for it you can see. Count the feet on the ground, subtract the ones in the air, and ask whether the centre is inside what is left. Everything a gait is comes out of that subtraction.

One teleport on, in the Arena, a small black crab on four long jointed legs is walking the only true plant-and-step gait in this museum, at a tenth of this size, and it is looking for you.

*Field notes: The prose describes gaits the code never implements[^vfm-09-legs-1] · Two bugs found by reading, one fixed[^vfm-09-legs-2] · Measured, not derived[^vfm-09-legs-3] · Exactness decisions in the text[^vfm-09-legs-4] · Open[^vfm-09-legs-5]*

[^vfm-09-legs-1]: **The prose describes gaits the code never implements.**
    The triage rated this room GOOD on the strength of its tutorial and intent, and
    both are fiction about the walkers. Seven readers and seven skeptics went through
    `commons/hazards/octapod_crawler/*.gd` on 2026-09-02 (workflow `legs-room-read`):

    - **Two through six run one identical rule.** The planted foot furthest past
      1.5 m from its shoulder steps, one foot in the air at a time, 0.25 s, 1.0 m
      high, landing 0.5 m ahead. No phase offsets, no pairs, no tripods, no support
      polygon, no lean. The `@identity` headers and the registry descriptions
      (diagonal trot, alternating tripods, starfish, "physics engine") are prose
      nobody checked against the code; `six_leg_critter.gd:14` itself says "One leg
      at a time."
    - **One leg never steps.** Its foot is a spring-arm cast straight down from a
      shoulder 2.2 m to the body's side, dragged along the floor. No pogo, no
      vertical motion anywhere in the family.
    - **Eight is the only grouped gait**: two tetrapods alternate, four feet always
      down. It is `octapod_ik`, not the hunting `octapod_crawler` the intent and
      `artifacts.md` name; there is no hunt to switch off and it never stands still.
    - **Nothing can fall.** The body is a `MeshInstance3D`, no physics body, no
      collider, height pinned; the feet are cosmetic and catch up. The visitor
      walks through them; their legs pass through the pillars and each other.
    - **The intent's numbers**: the leash is 1.4 m (token), not 1.1; "same scale"
      fails on the eighth (see the clamp).

    The text was therefore written **true to the code**: the rule on the wall is the
    exam gravity would set, the probe answers it per count, and the visitor is the
    one who applies it, because the animals cannot. Posted to the forum as
    `260902-jyp5w`: keep the honest text, or re-author the walkers so each count
    has its own gait and rewrite. Either way the registry descriptions, the identity
    headers and `intent.md` should stop claiming the gaits.

[^vfm-09-legs-2]: **Two bugs found by reading, one fixed.**
    - **Pace scaled with size.** `leg_walker_base.gd` advanced the body by
      `-basis.z * patrol_speed`, and the body's basis carries `walker_scale`
      (set on the same node), so the scale-4 octapod paced 1.40 m/s against the
      token's 0.35. Fixed: `-basis.z.normalised()` in both branches of `_walk`.
      `commons/testing/probe_walker_pace.gd` measures both formulas on the live
      basis: old 1.40 m in one second at scale 4, new 0.35 at either scale.
      Only this map sets a walker scale, so the fix changes one animal.
    - **`walker_scale:8.0` is clamped to 4.0 in silence** (`leg_walker_base.gd:144`,
      `clampf(want, 0.02, 4.0)`). The octapod is authored at a twentieth of its
      siblings (bones 0.12 apart, ride 0.45); at 4.0 its leg is 2.4 m against 5.0
      and its ring 1.2 m against 2.2. Not fixed: at 8.0 the authored ride would be
      3.6 m in a hall with 3 m walls, so raising the clamp does not give "same
      scale" either. A ruling: re-author the octapod at its siblings' scale, or
      accept that the eighth rung is a different build, which is what the text says.

[^vfm-09-legs-3]: **Measured, not derived.**
    - **The bodies stand 0.26 m above the floor**, not the authored 2.2 m: the
      grid's auto-ground shifted six walkers by -1.94 m and the octapod by -1.40
      (`ada_run/_legshot.log`, `legs_room.txt`, 2026-08-27). Feet at 0.00. What
      the visitor sees (`ada_run/leg_ladder_shots/`): a small box a hand above the
      floor and long arching legs reaching 2.2 m out, the arches taller than a
      person.
    - **`probe_legs_tutorial.gd`** (PROBE OK) carries the tutorial's `can_lift`
      with a strict point-in-polygon: one and two planted, false; three down true
      and one lifted false; four with one lifted and the body centred, FALSE (the
      centre sits exactly on the diagonal), true after a 5 cm lean, diagonal pair
      false, one side false; five: one lifted true, 0 of 5 adjacent pairs, 5 of 5
      pairs apart; six: the other tripod true, one side false; eight: alternate
      four true, one half false.
    - The probe found its own harness twice: `_settle_floor` reads the physics
      space, which is closed outside a physics tick and aborts `_walk`; and in a
      `SceneTree._init` the root is not live, so `global_position` reads zero.
      Measure `position`.

[^vfm-09-legs-4]: **Exactness decisions in the text.**
    - "None of them fall" is stated as what the room is, not as a complaint.
    - The four-leg "lean" is the probe's 5 cm, and the sentence says nothing here
      leans (true of the code).
    - The five-leg claim is the pair count, not "unmirrorable".
    - The eighth's "about half" is leg and ring; its authored body height ratio is
      0.82, so the text does not say half in every dimension.
    - Burst-and-glide timing (steps 0.25 s apart, four to five seconds of glide,
      turns every 3 s triggering most steps) is derived from the constants, not
      measured in the hall; the text keeps it qualitative.

[^vfm-09-legs-5]: **Open.**
    - The forum question above.
    - Registry `hazards.json` descriptions for all six critters and the
      `geometry_spec.animation: physics` claim are wrong; `octapod_ik`'s registry
      measurement is stale (aabb 0). `artifacts.md` names `octapod_crawler`.
    - `intent.md` (1.1 m, the crawler, same scale, the gaits) should be corrected
      once the ruling lands.
    - The VFM_09_Legs pearl in `commons/data/book/forces.json` is empty; this text
      should seed it.

#### Vectors Act5 ForceAsPlace

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

This is the last room of the forces field, and it asks one question you have to walk through: what is a floor *for*? Everything up to here drew vectors on things: on an arrow, on a thrown ball, on a limb. Here the vector is not on anything. It is on a volume of air, and whatever enters that air obeys it. A force has always been something a thing *has*; this room takes it away from the thing and gives it to the place.

## No starting address

**Free Vector (direction + length)** — `free_vector`

Four arrows on a small grid by the door, and they are all the same arrow. One is drawn in colour with its two facts beside it, a length and an angle. The other three stand somewhere else.

That is the whole of what a vector is, and this room spends five metres of cage on its consequences. A vector is two facts, a direction and a length. It has no third fact called *where*. Slide it across the floor and it has not changed, because there was never anything about it that knew where it was.

If a vector has no address, then attaching one to an object was always a convenience rather than a truth. And if it was only a convenience, you can attach it to something else. To a region, for instance.

## The cage

```gdscript
# force_field_zone.gd, the whole of the physics, both branches
rb.gravity_scale = 0.0                    # on entry, remembered
rb.linear_velocity += f * delta           # every tick, thereafter

pb.velocity += (f - pg) * delta           # you: your own gravity, subtracted
```

**Force Field Zone (a force made into a place)** — `force_field_zone`

Five metres of nothing, marked by a wire cage and one arrow. Five is not a round number: the chasm is five rows deep, so the volume is exactly as wide as the gap it hangs over. Its floor is the floor you are standing on.

Those two lines are shorter than they should be, and the missing thing is mass. A force divided by a mass gives an acceleration; this skips the division and adds `f` to velocity directly. A heavy thing and a light thing move identically. Not because the code checks and compensates, but because it never asks. The field has no way to find out what you are and nowhere to put the answer if it did.

The book this field grew from, Daniel Shiffman's *The Nature of Code*, defines a force as a vector that causes an object *with mass* to accelerate, and then spends a section on the awkwardness. To make falling look right you multiply gravity by an object's mass so that dividing by the same mass cancels it again: two operations that exist to undo each other, and a generation of us have typed them.

This room does not cancel the mass. It never introduces it. That is the difference between reading the sentence and standing inside it.

Your own body arrives at the same rule by subtraction. Your legs are already adding gravity every frame, so the volume adds `f` minus the gravity you brought, and the two cancel exactly. Inside, the only force in the world is the one on the dial.

## The dial

```gdscript
# vector_machine.gd, three numbers into one direction
f = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

**Vector Machine (the dial of gravity)** — `vector_machine`

Three sliders: how steep, which way round, how hard. Fourteen centimetres of travel each, and between them every direction there is, up to a ceiling of fifteen.

It ships pointing straight down at 9.8, which is gravity: the setting where this room looks exactly like every other room you have been in. That is the lesson before you touch anything. The ordinary world is not the absence of a setting. It is a setting. Somebody chose down.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

It is the oldest problem in spherical coordinates, and here it is at hand height, in metal, where you can feel it happen.

## The probe

```gdscript
# force_cube.gd, the arrow is measured, not scripted
var v := (global_position - _last) / delta
_draw(v * 0.5)                            # clamped at 2.6 m
```

**Force Cube (a vector you hold)** — `force_cube`

Three glass cubes, forty centimetres, each drawing its own motion out of its centre as a yellow arrow with three coloured legs and a readout.

Nothing tells the cube what the field is, and it has not been given the rule. It differences its own position against where it was last frame and draws the answer, so the arrow is not a prediction: it is the field, having already happened, to something that was in the way. That is the only honest way to read a field you cannot see: put something in it and watch.

These have weight, which is the point of throwing one. Let it go over the gap with the field pointing down and it drops. Aim the field up and across first and the same cube sails. The difference between those two throws is the whole claim of the room, and you can only make it with something that would otherwise have fallen.

A cube that goes into the hole comes back. It has to: there is no floor to catch it and no button to fetch it with, and a probe you can lose is a probe you stop throwing.

## What the plank is for

**Force Field** — `force_field`

Two cells wide, straight across the gap, and it was not in the plan. The museum's walker cannot be carried by a field. Every carry volume in the building ignores it, in silence, so a hall built entirely around being carried arrived severed, its far half unreachable and every object in it stranded. Somebody laid a plank. It was the right call, and why you are standing here.

Stand on it and look down, then up at the cage hanging over the same hole, and the room has said its sentence without a word. There are two ways to make a place crossable. You can put matter under the walk: a floor, a bridge, nearly every building you have been inside. Or you can leave the hole and change what happens in the air above it.

The plank works for anyone, forever, and nobody has to know why. The field works only for whoever set it, only while it is set, and it can be set wrong. A floor is a decision somebody made once and then stopped thinking about. Falling is not a property of the hole; it is a property of the rule over the hole, and somebody chose the rule.

A place has an edge, and an edge is geometry rather than intent. If a force belonged to you, being near it would be enough.

## The green

**Invisible Hill** — `invisible_hill`

Off at the far end, a dark green disc four and three quarter metres across with a brass lip, over which glowing pucks glide in from the rim, bend hard away from a centre that has nothing in it, and leave.

No collider, nothing to touch. A diorama, placed where you can look at it from outside and see the shape of the thing you have been standing in. It answers the little grid of arrows at the other end: that one says a vector has no address, this one says what happens when you give an address a vector.

Nothing at that centre is doing the bending. No mass, no attractor, no object. The curve is the entire content, and it belongs to the region rather than to anything in it.

## Out

The way out returns to Act I, where a vector was an arrow you could take by the tip. It has not changed since. What changed is where you are willing to put one: on an object, then a motion, then a limb, and now a room-sized piece of empty air with you inside it.

The field is a circle. Go round again, and notice that the first arrow was always this.

*Field notes: 2026-09-03. One full turn of the museum loop on one hall: order, space, code,[^vectors-act5-forceasplace-1] · 1. Dial — the machine cannot be aimed across, as shipped[^vectors-act5-forceasplace-2] · 2. Throw a cube to test — the probe cannot fall[^vectors-act5-forceasplace-3] · 3. Step in yourself — you do not have to[^vectors-act5-forceasplace-4] · 3b. And a visitor who did everything right would still miss, by 5 cm[^vectors-act5-forceasplace-5] · 4. The museum does not walk the room backwards. It deletes the words[^vectors-act5-forceasplace-6] · 5. Two artifacts in this hall answer to the same group name[^vectors-act5-forceasplace-7] · 6. The existing tutorial teaches physics the code does not do[^vectors-act5-forceasplace-8] · 7. invisible_hill is in the room and in none of its prose[^vectors-act5-forceasplace-9] · FIXED, 2026-09-03, with the probes that prove it[^vectors-act5-forceasplace-10] · What the loop recommends[^vectors-act5-forceasplace-11]*

[^vectors-act5-forceasplace-1]: **2026-09-03. One full turn of the museum loop on one hall: order, space, code,.**
    text, curation. Findings only; nothing here is a proposal unless it says so.

    The room's claim is good and I would not change it:


    The room does not currently deliver it. Its teaching loop is three moves —
    **dial, throw a cube to test, then step in yourself** — and each of the three is
    broken by something different, which is why no single pass had found it.

    ---

[^vectors-act5-forceasplace-2]: **1. Dial — the machine cannot be aimed across, as shipped.**
    `vector_machine.gd:88` composes the field as
    `Vector3(cos(pitch)·sin(yaw), sin(pitch), cos(pitch)·cos(yaw)) · mag`.

    **The yaw slider is dead in the shipped state.** `:57-58` park PITCH and YAW at
    normalised 0.0 — slider position 0.0 of a 0.0–0.14 track, overwriting the slider
    scene's own centred default of 0.07 (`slider_smooth.tscn:69`). Pitch 0.0 maps to
    −90°, where `cos(pitch)` is zero, so both horizontal components are multiplied
    by nothing. On the machine as a visitor first finds it, dragging yaw across its
    entire 14 cm changes the field not at all. Nothing on the console says so.

    **The yaw control wraps.** `:86` puts a full 360° on a linear 14 cm fader, so
    its two ends are the same answer, and the one direction that crosses this chasm
    (−Z) sits at 0.5 — the exact middle of the track, unmarked.

    **The arrow's upper clamp is unreachable.** `:106` allows a 1.0 m arrow at
    |F| ≥ 19.6, but `force_max` ships at 15.0 (`:20`), so the longest arrow in the
    room is 0.765 m. The lower clamp does bite: below |F| 3.92 every setting draws
    the same 0.2 m stub.

[^vectors-act5-forceasplace-3]: **2. Throw a cube to test — the probe cannot fall.**
    `force_cube.gd:57` sets `gravity_scale = 0.0`.

    In a room whose entire claim is about falling, **the test mass is weightless
    before it is thrown.** Throwing it into the field demonstrates the field, but it
    cannot demonstrate the contrast the room is built on, because it would not have
    fallen either way.

    Two more that compound it. A held cube is invisible to the field —
    `force_field_zone.gd:218` skips any `RigidBody3D` whose `freeze` is true, and a
    held pickable is frozen. And on desktop the pointer can carry but not throw, so
    a desktop visitor cannot perform the room's central action at all.

    The registry also promises a trail this artifact does not draw.

[^vectors-act5-forceasplace-4]: **3. Step in yourself — you do not have to.**
    Rows 9–13 are a chasm; columns 7 and 8 are **floor straight through it**. The
    void is real (`GridBiomeComponent.gd:897` — *"ground strip — visual only, no
    collision: the void stays the void"*), so the fall is real, but the catwalk
    means no visitor ever has to set a field to reach the far side.

    It was put there deliberately, in `9f6afb2e9`, for a real reason:


    Before that commit the hall was severed and burning in the museum: 114 of 243
    cells reachable, exit unreachable, all five artifacts stranded. The catwalk was
    the second rung of a standing escalation and it was the right call for the
    museum. **It is a genuine collision between two truths, not a mistake**, and it
    needs a ruling rather than a fix.

    One consequence the commit could not have foreseen: raising that cell **lifted
    the field out of a standing player's reach.**

[^vectors-act5-forceasplace-5]: **3b. And a visitor who did everything right would still miss, by 5 cm.**
    Found by the cross-check, not by me, and it is the decisive one.

    `GridInteractablesComponent.gd:2164` grounds a body by `correction = -min_y`.
    The zone's corner spheres (`force_field_zone.gd:163`) hang 5 cm below its own
    origin, so the grid lifts the whole volume by 5 cm: the field runs from y 0.55
    to 5.55 over a catwalk deck at y 0.50. Containment is `_point_inside` on the
    player's FEET, strict `< 2.5` (`gd:239-242`).

    **A player standing on the catwalk is five centimetres below the field.** One on
    the ledge is further below it. The crossing this hall is named for cannot be
    taken on foot in the shipped map, by anyone, from either side, with the machine
    aimed perfectly.

    The zone's own named `crossing` preset compounds it. `gd:42` sets it to
    `(7, 7, 0)`. Grid columns are X and rows are Z, and the chasm spans rows, so +X
    runs **along** the trench. The vocabulary's own word for crossing would sail you
    down the length of the gap.

[^vectors-act5-forceasplace-6]: **4. The museum does not walk the room backwards. It deletes the words.**
    I reported this as a reversal. **It is worse than that, and the cross-check was
    right to correct me.** `endless_museum.gd:660` allows six utility codes
    (`rc sc tc br jp wp`). `sub` is in neither the allowed nor the refused table, so
    `_stamp_utility` prints a refusal and returns null for all four subtitle cells.
    The `an` info board goes the same way, and `t` is refused explicitly at `:667`.
    `ada_run/em_plan.json` plans[49] carries **seven bodies and no text**.

    In the museum this hall says nothing at all. The reversal is a deletion, and
    **the wall text is not one voice among several here. It is the only one.**

    The reversal is still real for a player in the standalone map, where the
    subtitles do fire, and there it arrives like this:

        authored : intro → truth_machine → truth_void → truth_complete
        walked   : truth_complete → truth_void → truth_machine → intro

    One thing survives whichever end you come in from, and it is the part to fix
    first: `truth_complete` reads *"You crossed on a field you set."* Anyone who
    took the catwalk did not. The subtitle ORDER is the smaller problem; the
    subtitle CONTENT is false as shipped.

    This is **not** the corpus convention: of the 185 live halls, 81 agree with the
    museum and only 6 go against it — and three of the six are Vectors_Act4a,
    Act4b and Act5. It is a fault in three halls, not a design.

[^vectors-act5-forceasplace-7]: **5. Two artifacts in this hall answer to the same group name.**
    `vector_machine.gd:111-113` broadcasts by iterating group `"force_field"`. The
    hazard artifact `force_field` at r19 c11 joins that same group
    (`commons/hazards/force_field/force_field.gd:125`). The machine iterates it on
    every update and is saved only by a `has_method("set_field_vector")` duck-type
    check at `:112`. Two different artifacts, one group name, one 16×24 hall.

[^vectors-act5-forceasplace-8]: **6. The existing tutorial teaches physics the code does not do.**
    `tutorial.md` shows `@export var zone: Area3D` and
    `b.apply_central_force(field_force * b.mass)`. Neither exists. The machine finds
    the zone through a **node group**, not an export, and the zone adds acceleration
    straight to velocity — `rb.linear_velocity += f * delta` (`gd:223`) — so it is
    mass-independent *by construction* rather than by multiplying force by mass.

    The tutorial's conclusion is right and its mechanism is invented. That matters
    here more than usual, because the real mechanism is the better story.

    `blurb.md` says "a chasm with no floor". There is a floor.

    The registry and the artifact's own `@identity` both say the zone is **4 m**. It
    is **5 m** — `Vector3.ONE * size` seated at y = size/2, so the volume runs from
    the artifact's origin to +5 m and ±2.5 m in x and z.

[^vectors-act5-forceasplace-9]: **7. invisible_hill is in the room and in none of its prose.**
    `blurb.md` never mentions it; `intent.md`'s key-artifacts list omits it. It is
    not a terrain, not a field and not a marker but a **diorama**: a 4.78 m dark
    green disc with a brass lip, no collider and no signal, over which about four
    glowing pucks glide in from the rim, bend away from an empty centre, and leave.

    Its own code comment misstates its headline constant by 1.8×, which makes the
    singularity guard beneath it dead code.

    ---

[^vectors-act5-forceasplace-10]: **FIXED, 2026-09-03, with the probes that prove it.**
    **The 5 cm.** `auto_ground: false` on the registry entry (this artifact grounds
    itself: its volume runs from its origin upward) and `_point_inside` made
    inclusive at the base with 2 cm for the gap a controller leaves under its feet.
    `commons/testing/probe_act5_reach.gd`: grounded, origin 0.55, feet 0.50,
    OUTSIDE; self-grounded, origin 0.50, feet 0.50, INSIDE. PROBE OK. Fixes all ten
    placements of force_field_zone.

    **The yaw fader.** The default is not the fault, so it is unchanged: the machine
    still ships as gravity straight down, which is the room's first lesson. What was
    broken was that the degeneracy was SILENT. Now the readout says the fader is
    idle and at what bearing it is waiting, and a dim ghost arrow on the stage holds
    that bearing so you can aim before you lift. The early return in `_update` had
    to learn about it too: it watched the FIELD, and at a pole the yaw does not move
    the field, so the ghost would have frozen at whatever azimuth was set when the
    vector last changed.

    **The weightless probe.** `gravity_scale` now comes from a new `falls` export,
    default 1.0, so a thrown cube drops. The old zero gravity was standing in for a
    way home, and a chasm map has no floor to catch a cube and no reset cube, so the
    way home is now said directly: `recover_below_m` (4 m) returns a fallen cube to
    where it was placed, at rest. `_home` is captured on the first FRAME, not in
    `_ready`, because the grid seats artifacts with call_deferred and a home read in
    `_ready` would send a fallen cube to the origin of the world.
    `commons/testing/probe_act5_controls.gd` asserts all of it: shipped field
    (0, -9.80, 0); yaw mid-travel 180 degrees, the bearing across this chasm; ghost
    (0, 0, -1); pitch lifted, field (0, 0, -9.80); gravity 1.00; home 10.00; fell
    past the limit and came back to 10.00 frozen; a one-metre drop did not teleport.
    PROBE OK.

    **free_vector placed** at r21 c2, scale 0.7. Nothing fits at full size: 812 of
    1232 candidate placements hit a wall or void. Across the whole chapter only
    VFM_08_Arena has clear room at 1.0.

    STILL OPEN: the plank, which needs the museum walker to learn about carry
    volumes; the four subtitles the museum drops; `truth_complete`, which tells a
    visitor they crossed on a field they set; and the zone's `crossing` preset,
    (7, 7, 0), which points along the trench.

[^vectors-act5-forceasplace-11]: **What the loop recommends.**
    **A ruling is needed first, and it is not mine to make.** Either the museum
    walker learns to be carried — which is a change in `em_walker`, not in this map
    — or this hall keeps its catwalk and the text says so. Everything else waits on
    that, because the text cannot be honest until it is settled.

    **The 5 cm is the first fix and the cheapest.** Until the field can be entered,
    nothing else in this hall matters.

    **Three one-line changes would restore the teaching loop** without touching the
    argument: centre the pitch slider so yaw is live on arrival, mark −Z on the yaw
    track, and give the test cube weight until it enters the field.

    **One body is missing and it already exists.** `free_vector` — *"one arrow and
    its ghost copies, carried to different origins to show a vector has no home… a
    vector is a journey with no starting address"* — has **zero placements** in the
    entire museum. This room's argument is that a vector attaches to a volume rather
    than an object; `free_vector` is that premise stated as a thing you can walk
    around, and this hall has 138 spare floor cells. Shot on 2026-09-03 before
    recommending it: one cyan arrow at |v| = 2.78, θ = 30°, and three ghosts.

*3 further room(s) in this chapter, not yet written.*

**qfep balance workbench**

![qfep balance workbench](/artifact-gallery/captures/qfep_balance_workbench/front.png)

*a four-knob console for the QFEP formula — F, E(S), λ, φ sliders side-by-side on a tilted plate. As you turn them, QFE = F − λ·E(S) + φ·ΔE(S,t) recomputes live; a four-axis radar chart re-draws the knob quadrilateral; the dominant timeline phase is detected and its canonical color tints the readout panel, the radar fill, and an emissive halo behind the whole instrument. The project's organizing frame made into a console you operate.*

Four-knob console for the QFEP formula. Player turns F, E(S), lambda, phi sliders; a radar chart shows the current quadrilateral; the dominant timeline phase color tints the readout. The frame made into a balance.

> the QFEP formula is not a description of a system; it is a navigable balance. F − λ·E(S) + φ·ΔE has seven characteristic settlings (phases). The console makes those settlings hand-cranked.

**complexity dial workbench**

![complexity dial workbench](/artifact-gallery/captures/complexity_dial_workbench/front.png)

*an interactive complexity-dial workbench — the player turns ONE knob (input size N) and watches 5 algorithms race at their characteristic growth rates. At N=5 they're nearly indistinguishable. At N=30 the exponential bar crosses the wall-clock line. At N=60 the exponential is at 10^18 steps while linear is at 60; they cannot be reconciled by any constant factor.*

Interactive workbench for the polynomial-vs-exponential gap. One slider drives N ∈ [1,60]; five algorithms (O(log N), O(N), O(N log N), O(N²), O(2^N)) race their step counts simultaneously. Log-scaled bars + step-count labels + a dashed wall-clock line at 10⁹ ops/sec + a small growth-curve panel at the bottom. At N≈30 the exponential bar crosses the wall-clock line; at N=60 the gap is 18 orders of magnitude. Sister to /complexity-dial-gallery (web frieze frozen at 7 N-values).

> polynomial vs exponential isn't a speed difference; it's a different kind of thing. The dial demonstrates the gap is unbridgeable by any constant factor.

**transform composition workbench**

![transform composition workbench](/artifact-gallery/captures/transform_composition_workbench/front.png)

*an interactive transform-composition workbench — the player turns a slider that picks one of four (T1, T2) pairs of transformations, and watches BOTH orderings of that pair applied to a base tetrahedron, side-by-side. Left shape = T2∘T1 (T1 first); right shape = T1∘T2 (T2 first). A ghost of the base sits between them. Two gold trajectory arrows run from the ghost to each result. When the two results coincide (pair 2 — rotation around origin × uniform scale) a "commutes" badge lights up; for the other three pairs the readout says "non-commutative".*

Interactive 3D workbench. A slider selects one of 4 transformation pairs; the same base tetrahedron is shown after T1∘T2 (left) and T2∘T1 (right). Order matters — except for pair 2 (rotation × uniform scale around origin) which commutes. Paired with /transform-composition-gallery.

> order is operation. R·T ≠ T·R for most pairs. The slider lets you walk the four cases, and the badge tells you when (and only when) the two operations happen to commute — exactly when both fix the origin and one is a uniform scale.

**shannon workbench**

![shannon workbench](/artifact-gallery/captures/shannon_workbench/front.png)

*an interactive Shannon-bound workbench — the player turns a slider for p and watches the binary entropy hill H(p) light up at their position, sees the 16×16 sample grid regenerate, and reads the compression bound that those bits cannot fall below. At p=0.5, the slider sits at the peak of the hill, the sample grid looks like salt-and-pepper, and the readout says "incompressible: 256/256 bits"*

An interactive workbench for the binary entropy function. One slider drives p ∈ [0,1]; a 16×16 Bernoulli(p) bit grid regenerates from a fixed seed (same draws, migrating threshold), a live readout shows H(p) bits/symbol and the theoretical-min bit count, and a glowing red marker rides the entropy hill H(p) = -p log₂ p - (1-p) log₂(1-p) above the table. The slope of H is the rate at which structure becomes possible; the peak (p=0.5) is where structure is maximally absent. Sister to shannon_entropy_meter (this is the source side; that is the measurement side).

> between pure order and pure noise lies a mathematical landscape with a floor Shannon named. The floor is H(p) bits/symbol; you can approach it asymptotically but never beat it. The slider lets you walk along the floor.

**russell paradox workbench**

![russell paradox workbench](/artifact-gallery/captures/russell_paradox_workbench/front.png)

*an interactive Russell paradox workbench — the player turns a slider to walk through 6 set definitions, watching a translucent disc visualize each one. At cell 5 (R = {x : x ∉ x}) the disc turns red with a wavy perimeter and two arrows begin to orbit it labeled "R∈R ⇒ R∉R" and "R∉R ⇒ R∈R" — a closed contradiction loop you can see rotating in space. At cell 6 the disc vanishes; only the loop remains.*

An interactive Russell's paradox workbench. One slider walks through 6 set definitions ∈ {E, A, C, S, R, Frame}; a translucent disc floats above the plate and redraws to match. For E and C (well-formed predicates) the disc is calm blue with example element dots. For A = {x : x is a set} the disc turns amber and a 'including A itself' tag exposes the self-reference. For S = {x : x ∈ x} it shrinks to a small amber disc with one example dot — consistent self-containment. At cell 5 the disc turns RED with a wavy perimeter, and two orange arrows orbit the disc labeled 'R∈R ⇒ R∉R' and 'R∉R ⇒ R∈R' — chained tip-to-tail into a single closed contradiction loop that spins in space. At cell 6 the disc vanishes and only the loop remains, orbiting a '?'. A consistency lamp on the left glows green / amber / red-blinking by verdict. A ZFC card fades in at cells 5-6 explaining why the axiom of separation foils Russell. Paired with /russell-paradox-gallery — this is the live, hand-cranked version.

> self-reference is allowed (cell 4 is a well-formed set with one example) — but self-reference plus negation closes a loop that has no fixed point. ZFC's axiom of separation requires a pre-existing ambient set; R cannot be quantified over all x. The slider lets you walk to that exact spot.

### The Walk — further in

**halting workbench**

![halting workbench](/artifact-gallery/captures/halting_workbench/front.png)

*an interactive halting-problem workbench — the player turns a slider to pick one of 8 Turing machines from the gallery, presses STEP (or pulls the budget slider) to run the machine on a live tape, and watches the head move, the state cycle, and the halt banner flip from RUNNING to HALTED if and when the machine actually stops. Eight cells from /halting-bench-gallery come alive: BB(2) halts in 6, BB(3) in 14, BB(4) in 107 with 13 ones; shift-right runs forever; the bouncer oscillates; the deceptive halter writes its tape with no stopping in sight; STATUS_UNKNOWN keeps running past the 1000-step budget. You can SEE which halts — you cannot, in general, PREDICT.*

Interactive Turing machine simulator. Slider picks one of 8 canonical machines. Step button advances one step; budget slider auto-runs. Tape, head, state, and halt/loop banner update live.

> every machine is decidable PER STEP — you can always do the next step. Whether the whole run halts is, in general, undecidable. The workbench is a window onto that gap: the green banner is the only honest answer, and it appears only when (and if) it does.

**tangent slope workbench**

![tangent slope workbench](/artifact-gallery/captures/tangent_slope_workbench/front.png)

*an interactive tangent-slope workbench — the player turns a slider for x and watches the marker slide along f(x), the tangent line rotate at the slope f'(x), and the slope readout update. At local extrema the tangent goes horizontal; the player feels the maximum/minimum as a flat moment.*

An interactive workbench for the derivative as tangent slope. One slider drives x continuously across [0, 5]; a red marker slides along the curve f(x) = ½ + 0.4·sin(2x) + 0.15·cos(5x); a bright gold tangent line through the marker rotates to match f'(x) = 0.8·cos(2x) − 0.75·sin(5x); a small f'(x) subplot above the main plot tracks the derivative as its own function; a live readout shows f'(x), f(x), an up/down/flat slope word, and x; a side sign indicator arrow tilts up (green) when rising, down (red) when falling, flat (white) at extrema. At local maxima/minima the tangent goes horizontal — the geometric moment of an extremum. Paired with the /tangent-slope-gallery web cells of this same instrument frozen at 8 x-positions. Sibling to riemann_sum_workbench — same f, differentiation vs. integration.

> the derivative is the slope of the line you would draw if you zoomed in until the curve looked straight. The slider walks the zoom.

**cantor diagonal workbench**

![cantor diagonal workbench](/artifact-gallery/captures/cantor_diagonal_workbench/front.png)

*an interactive Cantor diagonal workbench — the player turns a slider for N and watches the list grow, the diagonal extend, and the constructed real d built bit-by-bit underneath. d is guaranteed not to be in the list because it disagrees with row k at position k for every k. The proof of uncountability made into a hand-cranked procedure.*

An interactive Cantor diagonal workbench. One slider drives N ∈ {4, 8, 16, 24, 32}; a list of N random binary reals fills the floating grid, the (i, i) diagonal cells are halo'd in gold, and the bottom row builds the constructed real d bit-by-bit in red — where d[i] = 1 − list[i][i]. Thin orange leaders connect each diagonal cell to its red d-cell, showing 'this bit became that bit, flipped'. The readout reports d's prefix, the 'd ≠ row_k for all k' statement, and the conclusion: the reals are uncountable. Paired with /cantor-diagonal-gallery (web cells frozen at 8 (N, rule) combinations) — this is the live, hand-cranked version.

> given any countable list of reals, there is always a real not in that list. The slider walks the proof: more rows, longer diagonal, still excluded.

**flocking controls**

![flocking controls](/artifact-gallery/captures/flocking_controls/front.png)

Interactive boid flocking with VR sliders for separation, alignment, cohesion, speed, and perception radius. Highlights one boid with visible force vectors.

**vector field**

![vector field](/artifact-gallery/captures/vector_field/front.png)

*A 3D lattice of arrows that each point the way the field flows at that location, with particles advected through it — a function from space to direction, made walkable*

vector_field

> A field is a decision made everywhere at once — give every point a direction and motion through space becomes obedience to a map you can see.

### The Turn — parameters

See vectors as arrows in space. Add them head-to-tail. Feel dot product measure alignment. Watch cross product create perpendicular vectors. Then feel gravity pull you down. Push objects and feel resistance. Watch attraction and repulsion create orbits and explosions.

Open in the dressing-room viewer: ca rules workbench, qfep balance workbench, complexity dial workbench, transform composition workbench.

### The Critical Reading

QFEP term: **dynamics**

Vectors define system states—the S in QFEP. Forces introduce change—they drive the temporal evolution φΔE(S,t). Together, vectors and forces are the complete grammar of physical motion: direction encodes where, magnitude encodes how much, and F=ma encodes why things change.

The artifacts' own claims:

> a 3-cell neighborhood and 8 transition bits suffice to encode every behavior on the qualitative gradient from frozen to chaotic to edge-of-chaos. The encoding is small (8 bits = 256 rules), the dynamics are large (universal computation lives at rule 110). Walking the slider is walking from order through periodicity through chaos to the edge — and a single bit-flip can move you across a class boundary. — *ca rules workbench*

> the QFEP formula is not a description of a system; it is a navigable balance. F − λ·E(S) + φ·ΔE has seven characteristic settlings (phases). The console makes those settlings hand-cranked. — *qfep balance workbench*

> polynomial vs exponential isn't a speed difference; it's a different kind of thing. The dial demonstrates the gap is unbridgeable by any constant factor. — *complexity dial workbench*

> order is operation. R·T ≠ T·R for most pairs. The slider lets you walk the four cases, and the badge tells you when (and only when) the two operations happen to commute — exactly when both fix the origin and one is a uniform scale. — *transform composition workbench*

> between pure order and pure noise lies a mathematical landscape with a floor Shannon named. The floor is H(p) bits/symbol; you can approach it asymptotically but never beat it. The slider lets you walk along the floor. — *shannon workbench*

> self-reference is allowed (cell 4 is a well-formed set with one example) — but self-reference plus negation closes a loop that has no fixed point. ZFC's axiom of separation requires a pre-existing ambient set; R cannot be quantified over all x. The slider lets you walk to that exact spot. — *russell paradox workbench*

> every machine is decidable PER STEP — you can always do the next step. Whether the whole run halts is, in general, undecidable. The workbench is a window onto that gap: the green banner is the only honest answer, and it appears only when (and if) it does. — *halting workbench*

> the derivative is the slope of the line you would draw if you zoomed in until the curve looked straight. The slider walks the zoom. — *tangent slope workbench*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Sky_Climb | 12×32 | 7 | 0.0 m |
| Void_Crossing | 14×18 | 6 | 0.0 m |
| Reformed_Instruments | 9×13 | 6 | 0.0 m |
| Force_Preview | 60×22 | 12 | 6.0 m |
| Console_Test | 16×14 | 6 | 0.0 m |
| Force_Props_Sandbox | 20×12 | 10 | 3.1 m |
| VectorFoundations | 22×16 | 0 | 0 m |
| Vectors_Act1_WhatAVectorIs | 14×22 | 4 | 7.0 m |
| VFM_01_Foundations | 22×16 | 20 | 22.5 m |
| VectorOperations | 22×17 | 14 | 25.5 m |
| Vectors_Act2_VectorArithmetic | 20×38 | 10 | 5.1 m |
| VFM_02_Operations | 24×16 | 12 | 5.3 m |
| VectorAdvanced | 22×19 | 14 | 26.7 m |
| Vectors_Act3_FieldsAndMotion | 18×30 | 5 | 10.0 m |
| VFM_03_Motion | 24×18 | 15 | 20.1 m |
| Vectors_Act4a_KineticForces | 30×30 | 5 | 0.0 m |
| Vectors_Act4b_Oscillation | 30×30 | 7 | 0.0 m |
| Vectors_Act5_ForceAsPlace | 16×24 | 5 | 0.0 m |
| ForcesFoundations | 22×17 | 14 | 40.8 m |
| ForcesComposition | 20×16 | 12 | 40.7 m |
| VectorApplied | 22×19 | 9 | 42.8 m |
| VFM_04_Fields | 30×22 | 11 | 44.1 m |
| VFM_05_Launch | 34×24 | 13 | 53.9 m |
| ForcesSystems | 22×17 | 21 | 96.6 m |
| VFM_06_Springs | 26×20 | 13 | 75.9 m |
| ForcesChaos | 22×19 | 17 | 77.5 m |
| VFM_07_Gravity | 22×16 | 9 | 22.9 m |
| VFM_08_Arena | 26×20 | 7 | 16.6 m |
| ForcesArena | 30×34 | 29 | 96.1 m |

What this chapter teaches, walked rather than read:

- Coordinate systems and spatial reasoning in 3D
- Vector components: x, y, z as decomposed direction
- Magnitude: length as √(x² + y² + z²)
- Unit vectors: direction without magnitude
- Addition and subtraction: combining and differencing vectors
- Dot product: measuring alignment (a·b = |a||b|cos θ)
- Cross product: creating perpendicular vectors, torque, normals
- Projection and reflection: mirrors and collisions
- Vector fields: spatial functions mapping position to direction
- F = ma: Force equals mass times acceleration
- Gravity: constant downward acceleration (9.8 m/s²)
- Friction and drag: resistance to motion
- Attraction and repulsion: inverse square laws
- Springs: Hooke's law (F = -kx)
- Particle systems: many bodies under forces
- N-body dynamics: gravitational chaos from simple rules
- Derivative as instantaneous rate of change: velocity is the rate of position; acceleration is the rate of velocity. F = ma is calculus made physical — the calculus substrate named at change (seq 4.5) carried into the world here.

### The Seed

> **Direction + magnitude = vector. F = ma. Acceleration is the only thing you feel. Position and velocity are states; force is what changes them.**

Exercises:

1. Coordinate systems and spatial reasoning in 3D
2. Vector components: x, y, z as decomposed direction
3. Magnitude: length as √(x² + y² + z²)
4. Unit vectors: direction without magnitude
5. Addition and subtraction: combining and differencing vectors
6. Walk Sky_Climb in VR and find where the rule first breaks its own pattern.
7. Open ca_rules_workbench in the dressing-room viewer and change one parameter until it stops being itself.

*Next: wavefunctions*

### The Ledger

- **the dig** — 11 of 80 artifacts excavated; 69 remain at depth.

## Chapter 7: Wavefunctions: Everything Oscillates

> **Everything oscillates. Fourier shows every signal is a sum of sines. The wave is the fundamental pattern of non-rest—perpetual movement between poles.**

`sin(t) = projection of rotation, f(x) = Î£ aâ‚™sin(nÏ‰x + Ï†â‚™)`

The sine wave is the fundamental pattern of non-rest—perpetual oscillation between poles. From rotation projected to line, to sound as material wave, to chaos as pattern breaking. Waves are the mathematical form of desire: always moving toward opposite, never settling.

### The Principal

This chapter's principal is **pick up cube** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **plinth**: small, raised to the eye on a dark column.

### The Primitive

**pick up cube**

![pick up cube](/artifact-gallery/captures/pick_up_cube/front.png)

A grab-and-carry cube that turns translation into a bodily action. The object does not change shape or orientation much; what matters is that its position is rewritten by the player's movement through space. In puzzle contexts that simple displacement becomes rule-bearing and consequential. It is translation reduced to a portable primitive.

### The Walk — first steps

*12 room(s) in this chapter; none written yet.*

**colorballs**

![colorballs](/artifact-gallery/captures/colorballs/front.png)

*N rigid spheres sampled from named color palettes — physics + palette = chromatic rain*

N rigid spheres sampled from named color palettes — physics + palette = chromatic rain

> a color only becomes real when it has mass — palette theory means nothing until you can throw it

**AudioContr**

![AudioContr](/artifact-gallery/captures/AudioContr/front.png)

UniversalVRAudioController

**cube scene**

![cube scene](/artifact-gallery/captures/cube_scene/front.png)

A configurable cube scene used as reference geometry across the project. Its variants can be grabbed, scaled, subdivided, snapped, or augmented, but the cube remains the stable primitive beneath those state changes. That makes it ideal for seeing what a transformation preserves and what it alters. In the transformation sequence it functions as the baseline form against which other changes read clearly.

**timbre sculptor**

![timbre sculptor](/artifact-gallery/captures/timbre_sculptor/front.png)

*waveform(t) = sum(amplitude[n] * sin(n * fundamental * t)) — additive synthesis with audio*

VR rack panel with 8 vertical sliders controlling harmonic amplitudes for real-time additive synthesis. Waveform and spectrum displays show the result. Preset buttons morph to known timbres: sine, square, sawtooth, triangle, and vowel approximations (A, E, I, O, U). Cognitive compression: timbre IS harmonic recipe — the slider heights ARE the spectrum. Build Fourier transforms with your hands.

> Timbre is the harmonic fingerprint of a sound — the same note on different instruments differs only in overtone amplitudes.

**petri dish worms**

![petri dish worms](/artifact-gallery/captures/petri_dish_worms/front.png)

*worm_segment[i].offset = amplitude * sin(oscillation_speed * t + i * phase_per_segment)*

Simulated worm-like organisms wriggling in a petri dish — simple steering behaviors and sinusoidal body motion create surprisingly lifelike movement. Emergence of biological-looking behavior from minimal procedural rules.

> A worm moves by passing a sine wave through its body — locomotion is traveling oscillation.

### The Walk — further in

**oscilloscope**

![oscilloscope](/artifact-gallery/captures/oscilloscope/front.png)

Multi-mode oscilloscope with VR sliders. Shows waveform, Lissajous patterns, and XY plots. Classic green phosphor CRT aesthetic. Controls: FREQ A/B, Amplitude, Phase, Time/Div.

### The Turn — parameters

See rotation become sine on the unit circle. Hear Fourier synthesis build complex sounds from simple waves. Watch the double pendulum transition from periodic to chaotic.

Open in the dressing-room viewer: pick up cube, colorballs, AudioContr, cube scene.

### The Critical Reading

QFEP term: **dynamics**

Wavefunctions are the mathematical form of edge-of-chaos dynamics. Oscillation is neither static order nor chaotic randomness—it is periodic motion at the boundary. In QFEP terms, waves drive the temporal evolution φΔE(S,t) through rhythmic alternation.

The artifacts' own claims:

> a color only becomes real when it has mass — palette theory means nothing until you can throw it — *colorballs*

> Timbre is the harmonic fingerprint of a sound — the same note on different instruments differs only in overtone amplitudes. — *timbre sculptor*

> A worm moves by passing a sine wave through its body — locomotion is traveling oscillation. — *petri dish worms*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| WaveFunctions_Intro | 9×22 | 21 | 35.4 m |
| WaveFunctions_Pendulum | 11×19 | 14 | 59.0 m |
| WaveFunctions_Unit_Circle | 13×17 | 16 | 103.2 m |
| WaveFunctions_Sine_Space | 12×28 | 8 | 27.9 m |
| WaveFunctions_3D_Wave_Propagation | 16×18 | 4 | 26.5 m |
| WaveFunctions_Effect_Sound | 12×14 | 34 | 33.7 m |
| Wavefunctions_Bernini | 15×15 | 4 | 13.4 m |
| WaveFunctions_John_Cage | 12×14 | 4 | 22.2 m |
| WaveFunctions_AirMusic | 11×12 | 10 | 14.8 m |
| Wavefunctions_Sky_Stairs | 12×13 | 17 | 33.9 m |
| WaveFunctions_TrigWalkingPath | 14×14 | 6 | 22.7 m |
| WaveFunctions_Synthesis_Lab | 11×12 | 24 | 126.1 m |

What this chapter teaches, walked rather than read:

- Rotation creates oscillation (unit circle â†’ sine)
- Parameters of oscillation: amplitude, frequency, phase
- Fourier synthesis: any signal is a sum of sines
- Interference and resonance: when waves meet
- Beat frequencies: slow modulation from fast waves
- From periodic to chaotic: the double pendulum transition
- Exponential form: rotation in the complex plane is e^(iθ); sine is its imaginary part. Fourier synthesis is integration in the limit — same accumulation move as Riemann sums at change (seq 4.5), generalised to a continuous sum of sines.

### The Seed

> **Everything oscillates. Fourier shows every signal is a sum of sines. The wave is the fundamental pattern of non-rest—perpetual movement between poles.**

Exercises:

1. Rotation creates oscillation (unit circle â†’ sine)
2. Parameters of oscillation: amplitude, frequency, phase
3. Fourier synthesis: any signal is a sum of sines
4. Interference and resonance: when waves meet
5. Beat frequencies: slow modulation from fast waves
6. Walk WaveFunctions_Intro in VR and find where the rule first breaks its own pattern.
7. Open pick_up_cube in the dressing-room viewer and change one parameter until it stops being itself.

*Next: randomness*

### The Ledger

- **the dig** — 7 of 86 artifacts excavated; 79 remain at depth.

# Part: Entropy

*QFEP phase: E(S) — disorder, randomness, the productive use of chance. Order cracks. Randomness enters. But not all disorder is equal — structured noise creates organic form, and simple cellular rules produce infinite complexity. λ rises.*

## Chapter 8: Randomness: Freedom from Pattern

> **Entropy is not decay — it is the size of the possible.**

`H = −Σ pᵢ log pᵢ   ·   xₙ₊₁ = (a·xₙ + c) mod m`

Flip a coin. Not the idea of a coin — this sequence hands you one, gold on one side, silver on the other, above a counter that will spend the rest of the hour converging on 0.5. The flip is lawless; the count is law. That is the whole paradox of randomness, and it is stranger than it looks, because the machine you are standing in cannot actually do it: a computer is a device built to be predictable, and when it needs chance it fakes it, with arithmetic whose origin it agrees to forget. This sequence walks the distance between the fake and the real — from a crank that shows determinism impersonating chance, to your own body leaking true entropy into the simulation, to jars, dice, and distributions where disorder shows its shapes. Entropy here is not decay, and it is not noise to be filtered out. It is the size of the possible — the wilderness every later pattern will be drawn from.

### The Principal

This chapter's principal is **slot machine** — *P(A∩B∩C) = P(A)·P(B)·P(C) — independent joint probability* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

*Every sequence begins with one small thing that already contains the whole idea.*

**slot machine**

![slot machine](/artifact-gallery/captures/slot_machine/front.png)

Three reels, one lever, and the oldest honest demonstration of independence in the building. Pull: the reels stop one by one, left to right, and no reel's symbol tells you anything about the next — P(A∩B∩C) = P(A)·P(B)·P(C), the multiplication that makes triple matches rare and casinos rich. The histogram beside it counts every symbol and slowly flattens toward uniform. Hold both facts at once: each pull is unknowable, the long run is guaranteed. Everything else in this sequence lives in the gap between those two sentences.

> Independence is not absence of connection — it is the impossibility of prediction from correlation.

### The Walk — first steps

*Five artifacts, in the order the sequence itself proposes — where chance comes from, and what it builds.*

*14 room(s) in this chapter; none written yet.*

**prng crank machine**

![prng crank machine](/artifact-gallery/captures/prng_crank_machine/front.png)

The confession at the start of the walk: computers cannot flip coins. Press the crank and watch state = state × 1664525 + 1013904223 mod 2³² execute in stages — multiply, add, wrap. Nothing here is random; the entire future of the sequence is fixed by its seed. It merely scrambles so thoroughly that no test you can afford will catch the pattern. Determinism with a forgotten origin — keep the phrase, because every 'random' room after this one is running on some version of this crank.

> Determinism is not the opposite of randomness — it is randomness with a forgotten origin.

**hardware entropy decay**

![hardware entropy decay](/artifact-gallery/captures/hardware_entropy_decay/front.png)

Where the real entropy comes from: you. Controller velocity becomes scratches, grip pressure becomes grime, head rotation drives the weathering rate — three clean surfaces decay in real time from nothing but your body's noise. Try to stop feeding it. Stand perfectly still. You cannot: tremor, drift, and heartbeat leak through the sensors regardless. The artifact makes the measurement problem physical — the observer is not outside the system; the observer is the entropy source.

> The observer is not separate from the system — every measurement is an intervention.

**env one**

![env one](/artifact-gallery/captures/env_one/front.png)

The first payoff: randomness as a builder. A kitbashing algorithm assembles an environment from parts, and chance decides which part lands where — the same move game worlds and film sets use to look grown rather than authored. After two machines about where randomness comes from, this one is about what it is for: variety no one had to design piece by piece.

**random walk terrarium**

![random walk terrarium](/artifact-gallery/captures/random_walk_terrarium/front.png)

Put walkers in a jar and let them wander: step, turn, step, no destination. Their trails accumulate into terrain, crossings thicken into structures, and the terrarium slowly fills with geography nobody planned. The mathematics is mean squared displacement — E[|r|²] = n·d·σ², spread grows with the square root of time — but the lesson is softer: exploration without a goal still covers the space. Covers it, in fact, more honestly.

> A random walk has no destination — yet it explores space more honestly than any planned path.

**coin toss**

![coin toss](/artifact-gallery/captures/coin_toss/front.png)

And then back to the atom. Grab a coin, toss it: Bernoulli(0.5), the simplest random thing there is. The counter tracks heads against tails, wandering, overshooting, slowly forgetting its own excursions on the way to one half. Every distribution in the rooms ahead is built from stacks of this — binary choice repeated until shape appears. The hydrogen atom of randomness; and as with hydrogen, most of the universe turns out to be made of it.

> The Bernoulli trial is the hydrogen atom of randomness — everything complex is built from binary choices.

### The Walk — further in

*Further in: randomness you can feel, and the shapes it is allowed to take.*

**random walk leash**

![random walk leash](/artifact-gallery/captures/random_walk_leash/front.png)

The terrarium, transposed into your arm. The orb on the leash tugs in a random direction with every impulse, and you hold on. Statistically it is the same walk — drift scaling with √N — but the transmission line is different: unpredictability arrives as force, through your wrist. You know the next tug is coming; you cannot know which way. That helpless half-knowledge is what a distribution feels like from inside.

> To hold randomness on a leash is to feel that unpredictability has weight.

**entropy jar**

![entropy jar](/artifact-gallery/captures/entropy_jar/front.png)

Red particles, blue particles, one jar, your hand. Shake: they mix. Shake again, cleverer this time: they mix more. The Shannon readout climbs and does not come back — not because unmixing is forbidden, but because mixed arrangements outnumber sorted ones so astronomically that waiting for order is not a plan. The second law as a toy, and the first place in the sequence where time acquires a direction.

> The second law is not a prohibition — it is the statistical certainty that mixed states outnumber ordered ones.

**distribution sampler**

![distribution sampler](/artifact-gallery/captures/distribution_sampler/front.png)

The zoo. Uniform, Gaussian, Poisson, exponential — pick one and watch samples fall into a histogram until the empirical shape finds the theoretical curve underneath it. The move to hold onto: a distribution is not randomness; it is a constraint on randomness — the shape of what remains possible. Chance supplies the events, the distribution decides their silhouette. Switching between them changes nothing about the dice and everything about the world.

> Every distribution is a constraint on randomness — the shape of what remains possible.

**dice throw**

![dice throw](/artifact-gallery/captures/dice_throw/front.png)

Six outcomes on green felt, with consequences: roll a six and a hundred balls rain from the sky; roll a one and a single ball drops. The payoff is wildly unequal; the process is perfectly fair — P = 1/6 each, expected value 3.5, and the statistics converge to say so. Fairness, the artifact insists, is not a property of any outcome you receive. It is a symmetry of the generating process. Politics has struggled with the difference ever since.

> Fairness is not a single outcome — it is the symmetry of the generating process.

**clipboard**

![clipboard](/artifact-gallery/captures/clipboard/front.png)

The sequence's reading surface, and quietly its most honest object: a document you must pick up to read. Pages of code and tutorial fragments stay coherent in your hands while everything around them scatters and decays — but the text yields nothing to a glance across the room. In a curriculum about embodiment, even reading has weight, position, and a grip.

> a text in VR is not passive — the learner must pick it up, hold it, and navigate it with their hands

### The Turn — parameters

Every machine in this walk exposes the same two knobs, whatever it calls them. The first is N, the sample count — the only knob that buys truth. At ten samples the histograms are noise; at ten thousand they are geometry; the law of large numbers is a slope you can set. The second is the seed. Change it and every particular history changes — different tosses, different trails — while every statistic stays identical. Turn both and you are holding the sequence's entire epistemology: individual events are lawless and unownable; ensembles are lawful and knowable. Everything else on the panels — distribution pickers, impulse strengths, decay rates — just chooses which lawful shape the lawlessness must fill.

Open in the dressing-room viewer: random walk terrarium, distribution sampler, clipboard.

### The Critical Reading

*Now the reading the reels and jars have been implying all along.*

QFEP term: **E(S)**

Randomness is the E(S) term in its purest form — the sequence where the formula's second half stops being an abstraction. F, the model, meets events it cannot compress: prediction fails, indices break, normalization is refused. The critical claim is that this is not damage. Entropy here is possibility space — the high-dimensional wilderness from which every pattern in the later sequences will be drawn. And the random walk is its queer figure: motion without telos, navigation that refuses the straight line and the destination, and still — measurably, E[|r|²] = n·σ² — gets everywhere. What the straight path calls lost, the walk calls coverage.

The artifacts' own claims:

> Independence is not absence of connection — it is the impossibility of prediction from correlation. — *slot machine*

> Determinism is not the opposite of randomness — it is randomness with a forgotten origin. — *prng crank machine*

> The observer is not separate from the system — every measurement is an intervention. — *hardware entropy decay*

> A random walk has no destination — yet it explores space more honestly than any planned path. — *random walk terrarium*

> The Bernoulli trial is the hydrogen atom of randomness — everything complex is built from binary choices. — *coin toss*

> To hold randomness on a leash is to feel that unpredictability has weight. — *random walk leash*

> The second law is not a prohibition — it is the statistical certainty that mixed states outnumber ordered ones. — *entropy jar*

> Every distribution is a constraint on randomness — the shape of what remains possible. — *distribution sampler*

### In the World

*Thirteen rooms, ordered from definition to play: first randomness defined and subtracted — what remains when you remove pattern? — then the classic 10 PRINT maze, one random choice repeated until it becomes architecture; then chance let loose on cubes, rotations, and walks; a Gaussian room where disorder acquires its famous bell; mushrooms and pheromones where biology borrows it; and finally a game, because play is what randomness is for.*

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Random_Definition | 5×20 | 14 | 44.5 m |
| Random_Remove | 13×18 | 3 | 18.8 m |
| Randomness_10_PRINT_Algorithm | 13×14 | 9 | 88.2 m |
| Random_Cubes | 12×20 | 53 | 50.7 m |
| Random_Rotate_Random_XYZ | 13×16 | 5 | 53.5 m |
| Random_Walk | 13×14 | 10 | 19.0 m |
| Random_Gaussian | 12×21 | 9 | 48.6 m |
| Random_Mushrooms | 12×13 | 6 | 18.8 m |
| Random_Space_Geometry | 12×24 | 6 | 66.7 m |
| Randomness_Examples_of_Randomness | 12×17 | 5 | 16.3 m |
| Random_Pheromone | 13×14 | 4 | 21.6 m |
| Random_Space | 13×15 | 5 | 23.3 m |
| Random_Game | 13×16 | 8 | 14.1 m |

What this chapter teaches, walked rather than read:

- Entropy as possibility space, not destruction
- PRNG vs TRNG: deterministic sequences vs physical randomness
- Distributions: uniform, Gaussian, and the shapes of chance
- Random walk: non-teleological movement, queer navigation
- Emergence: Turing morphogenesis, patterns from noise
- Shannon entropy: H = -Σ p log p. Logarithm measures disorder. Factorials count arrangements. The integral named at change (seq 4.5) reappears here as expectation — sum over a distribution becomes integral in the continuous limit.

### The Seed

> **Entropy is not decay — it is the size of the possible.**

Exercises:

1. Crank prng_crank_machine ten times and write down the outputs. Reset it with the same seed and crank ten more. Explain, in one sentence, why the machine is still allowed to call itself random.
2. In coin_toss, throw until the ratio reads exactly 0.50 — count your throws. Then throw ten more and watch it leave. The law of large numbers is a promise about the limit, not about you.
3. Shake entropy_jar until red and blue are perfectly mixed, then try to unshake it. Describe the difference between the two directions using only the word 'count'.
4. Stand completely still inside hardware_entropy_decay for one minute. The surfaces keep weathering. Where is the entropy coming from now, and what does that say about measurement?
5. In distribution_sampler, switch from uniform to Gaussian and name one thing that stayed the same. That thing is what this sequence means by randomness; everything that changed is what it means by distribution.
6. Walk Random_Walk deciding every junction by an imagined coin flip — no destination allowed. Afterwards, defend the path you took to someone who asks where you were trying to go.

The seed of this sequence fits in a sentence: chance, counted, becomes shape. Carry it into noise, where randomness is given a memory — and starts to look like landscape.

*Next: noise*

### The Ledger

- **the throw** — The throw goes literal: coins, dice, reels — thrownness formalized as Bernoulli(0.5), and made fair by symmetry of process rather than kindness of outcome.
- **the hand** — hardware_entropy_decay names the body as the only true entropy source in the building — tremor, drift, and heartbeat leaking through the sensors even when you stand perfectly still.
- **the debt** — The PRNG is a loan of a second kind: the crank borrows unpredictability from a seed and never repays it — determinism deferring its pattern past the horizon of any test you can afford.
- **the dig** — 11 of 65 artifacts excavated; 54 remain at depth.

## Chapter 9: Noise: Entropy with Memory

> **Noise is randomness that remembers its neighbors. Structured disorder, organic unpredictability.**

`noise(p) = Σᵢ amplitudeⁱ · perlin(frequencyⁱ · p)`

The last chapter ended with chance counted into shape. This one begins by giving chance a memory. In the first room four fields hang side by side — white, pink, brown, blue: the colors of noise — and the color names a memory span. White remembers nothing; every value is an orphan. Pink remembers a little, and drifts. Brown cannot let go, each step leaning on the last. Blue remembers only what to avoid, spacing itself like trees in a managed forest. One dial — how much of the previous moment survives into this one — and the whole spectrum from television static to mountain range falls out of it. Noise is randomness that remembers its neighbors: entropy with continuity, the λ parameter tuned for coherence, the trick that makes computers look like nature. And this chapter stays honest about the word trick — because between the memory and the mountains there is a cheap move an entire visual culture now makes by default, and before the chapter ends we are going to name it, price it, and decide when it is allowed.

### The Principal

This chapter's principal is **NoiseColors3D** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **field**: the artifact IS the environment — to house it would kill it.

### The Primitive

*Every sequence begins with one small thing that already contains the whole idea — here, a wall of four memories.*

**NoiseColors3D**

![NoiseColors3D](/artifact-gallery/captures/NoiseColors3D/front.png)

Four noise fields in 3D, distinguished by nothing but their frequency distributions — which is to say, by how long they remember. Stand between them and compare. White crackles without history. Pink breathes. Brown wanders like a drunk who cannot forget the last step. Blue holds itself apart, anti-clustered, the memory of avoidance. Nothing else differs — same source of chance, same renderer, one parameter. The lesson is severe and it carries the whole chapter: everything you will read as texture, terrain, weather, or mood is a correlation length. Character is memory span.

### The Walk — first steps

*Five artifacts: the ripple, the performance, the orphan, the sky, and the accidental earth.*

*8 room(s) in this chapter; none written yet.*

**noisetorus**

![noisetorus](/artifact-gallery/captures/noisetorus/front.png)

A torus whose surface ripples with animated noise, hue drifting as it moves. The first application, and the first warning. It reads as alive — breathing, molten, faintly biological — and yet nothing about the torus changed: a displacement runs over the sheet of its surface, one function call deep. Hold the feeling of aliveness in one hand and the size of its cause in the other. That gap is where this chapter does its critical work.

**MeltingBerniniScene**

![MeltingBerniniScene](/artifact-gallery/captures/MeltingBerniniScene/front.png)

Baroque columns dissolving under noise-driven vertex displacement — Bernini, melting. Read it carefully, because this artifact knows exactly what it is doing. It performs the cheap trick ON the canon and lets you see the seams: marble that took centuries to learn to tremble in stone now wobbles by shader, and a dissolution that carries the full costume of critique costs one line of noise. This is blob aesthetics exhibited as content — the default gesture of a culture that signals change without knowing where to go, staged deliberately, so you can catch yourself finding it profound. Not always bad; the baroque itself wanted marble to move. But from this room on, you know what the move costs, and you will see it everywhere.

**randompoint**

![randompoint](/artifact-gallery/captures/randompoint/front.png)

The orphan, kept for contrast. A single draggable point, equally likely anywhere in its bounds — pure white noise in two dimensions, no memory at all, the null hypothesis of space. Chapter 8 built everything from this atom. Every other artifact in this chapter is this point, plus a memory.

> white noise is the null hypothesis of space — the universe before it learned to care where things go

**noisesphere**

![noisesphere](/artifact-gallery/captures/noisesphere/front.png)

A hemisphere deformed by noise into an atmospheric dome — the sky, as correlated randomness. Is it the cheap trick again? Borderline, and the chapter lets you argue it: the dome works because real skies genuinely are noise with memory — turbulence has a spectrum — so here, for once, the shader and the world agree about what they are made of.

**noiselayers**

![noiselayers](/artifact-gallery/captures/noiselayers/front.png)

The mountain. Three noise fields at different frequencies, summed — octaves, fractal Brownian motion — and suddenly: terrain. Two hundred and twenty metres of it, the largest body in the book so far. Its identity line has earned its italics: landscapes are not designed — they are superpositions of independent noise processes operating at different scales, and the earth's surface is an accidental sum. Last chapter's fractals return here as a recipe. Self-similar detail, bought wholesale, one octave per scale of attention.

> landscapes are not designed — they are superpositions of independent noise processes operating at different scales, and the earth's surface is an accidental sum

### The Walk — further in

*Further in: the machinery under the trick — then the threshold, where the sheet finally commits, and its counter, where commitment is built instead of found.*

**shader noise space**

![shader noise space](/artifact-gallery/captures/shader_noise_space/front.png)

The room itself runs the noise: walls and sphere computed per fragment, millions of evaluations per frame, animated by a clock. What reads as one continuous field is massively parallel arithmetic — there is no field, there are only samples, so many and so fast that your eye vouches for a continuity the machine never once provided. The ghost's own confession, rendered at ninety frames a second.

> GPU noise is not one calculation but millions happening simultaneously — the shader room makes visible that what looks like a continuous field is massively parallel computation

**WhiteNoiseGallery**

![WhiteNoiseGallery](/artifact-gallery/captures/WhiteNoiseGallery/front.png)

A gallery of pure static, hung like art. After the melting marble and the accidental mountains it reads as brutally honest: no memory, no shape, no trick — the raw material before the dial is turned. Every organic surface in this chapter is this gallery, correlated. Come back to it when the terrain starts to look inevitable.

**voxelnoise**

![voxelnoise](/artifact-gallery/captures/voxelnoise/front.png)

The turn the whole chapter has been building toward. Take a continuous 3D noise field and apply one rule: above the threshold a cube exists; below it, nothing. Matter appears. Walk around what condensed — caves, arches, islands hanging in air — and hold the claim at full strength: solid and void are not properties of the field. They are where you drew the line. The blob is called to account here. Instead of wobbling a surface to signal a depth it does not have, the threshold commits — this is inside, this is outside — and the first honest volume in the book precipitates out of a cloud of numbers.

> matter is a threshold — the voxel world reveals that solid and void are not intrinsic qualities but the result of where you draw the line through a continuous field

**perlin terrain sculptor**

![perlin terrain sculptor](/artifact-gallery/captures/perlin_terrain_sculptor/front.png)

And then sculpting, inverted. A grid thresholds a Perlin field; your sliders move octaves, persistence, scale, and the threshold itself. Push it and land rises out of nothing; pull it and mountains drown. You are not adding form and you are not removing it: the entire family of landscapes already exists in the field, and the knob chooses which member becomes matter. Michelangelo said the figure was already in the marble — here that is not mysticism, it is the literal algorithm. One way to commit form: reveal it. The artifact facing this one holds the other way.

> noise-based sculpting inverts the usual creative act — instead of adding form, you reveal it by moving the threshold through a pre-existing mathematical landscape

**mc sculpt vr**

![mc sculpt vr](/artifact-gallery/captures/mc_sculpt_vr/front.png)

The counter — found outside this chapter's own stratum, which is fitting, because it comes from the future. SDF sculpting on the GPU: you ADD spherical blobs, up to five hundred, and smooth union melts them into one continuous body while marching cubes extracts a real mesh in real time. Everything the chapter indicted, redeemed in one object: it is made of blobs — literally, the smooth-union blob of every demo reel — but these blobs commit. They have interiors. They cast a surface you can walk around, extracted rather than faked. Against the sculptor's revealing (the form was always in the field; you chose it), this is building (the form was nowhere; you placed it) — the two ways to make something exist, facing each other at the end of the room. The chapter ends where the blob ends: not banished, but given an inside. The export begins.

### The Turn — parameters

Every knob in this chapter is secretly one of three. Frequency decides how fast the world varies — turn it and the same terrain zooms through scales. Octaves and persistence decide how much detail each scale contributes — the fractal recipe, and every octave is a loan taken out for detail, paid in computation. And the threshold decides where the continuous becomes committed — where a field becomes a fact. The first two tune the trick; the third ends it. That asymmetry is the chapter's whole argument in interface form: frequency and octaves decorate a sheet, the threshold declares a world.

Open in the dressing-room viewer: NoiseColors3D, noisetorus, MeltingBerniniScene, noiselayers.

### The Critical Reading

*Now the reading the melting marble has been implying all along.*

QFEP term: **Î»E(S)**

Noise is λE(S) tuned for coherence — entropy constrained by smoothness, the edge of chaos made continuous. That is the official story, and it teaches well. The critical story is Perlin's: this mathematics was invented for TRON because computer graphics looked too clean, and it won an Academy Award for making the digital look grown. Noise is the debt's cosmetics — smoothness IS interpolation, the loan serviced so evenly that no one asks about the principal — and it has become the default aesthetic of not knowing where to go: when a work stalls, melt it, particle it, blob it. We call this blob aesthetics, and we keep the diagnosis merciful, because the trick is not always bad — but we also read the gauge inside it. In a 2.5-dimensional universe, where every mesh is all surface and nothing has an interior, the noise blob is the abject on a budget: it signals change, dissolution, becoming — the trace's counterfeit, the in-between at the price of a constant. When the blob appears, the current universe's density is exhausted at that working point, and the honest move is not more noise. It is export: to volume, to body, to world. The threshold is where the counterfeit is retired, and this sequence ends standing on it.

The artifacts' own claims:

> white noise is the null hypothesis of space — the universe before it learned to care where things go — *randompoint*

> landscapes are not designed — they are superpositions of independent noise processes operating at different scales, and the earth's surface is an accidental sum — *noiselayers*

> GPU noise is not one calculation but millions happening simultaneously — the shader room makes visible that what looks like a continuous field is massively parallel computation — *shader noise space*

> matter is a threshold — the voxel world reveals that solid and void are not intrinsic qualities but the result of where you draw the line through a continuous field — *voxelnoise*

> noise-based sculpting inverts the usual creative act — instead of adding form, you reveal it by moving the threshold through a pre-existing mathematical landscape — *perlin terrain sculptor*

### In the World

*Nine rooms, from the spectrum to the threshold: the noise colors compared side by side, columns and walls that wear the field, a room folded inside a room of it, the voxel hall where the field first commits to matter, the Perlin–Simplex comparison lab — and then Lab_Path, five cells by five, footprint under a metre: the smallest room in the sequence, crossed in seconds. After the mountains, the chapter's own architecture makes the point: the honest scale, at the end of all that spectacle, is a path.*

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Random_Noise_Types | 7×9 | 4 | 34.2 m |
| Noise_Columns | 12×14 | 2 | 13.5 m |
| Noise_One | 11×11 | 3 | 4.9 m |
| Noise_Voxel | 13×14 | 4 | 37.1 m |
| Noise_6_Wall | 11×11 | 2 | 27.9 m |
| Noise_Inside_Noise | 12×13 | 2 | 31.9 m |
| Noise_Space_10 | 13×15 | 2 | 10.8 m |
| Noise_Perlin_Simplex | 12×13 | 6 | 23.5 m |
| Lab_Path | 5×5 | 1 | 0.8 m |

What this chapter teaches, walked rather than read:

- Noise as structured entropy: randomness with continuity constraints
- White noise vs. smooth noise: the Î» spectrum of coherence
- Octaves as fractal layering: multiple scales of structured randomness
- Perlin/Simplex: grid + gradient + interpolation algorithms
- Vector fields: noise as flow direction
- Procedural generation: noise as substrate for worlds

### The Seed

> **Noise is randomness that remembers its neighbors. Structured disorder, organic unpredictability.**

Exercises:

1. Stand in NoiseColors3D with the labels out of view and identify the four colors by memory span alone. Then name one thing outside this building you can now read the same way — a coastline, a mood, a market.
2. In front of MeltingBerniniScene, time how many seconds the melting stays profound. That number is the half-life of blob aesthetics; carry it into every game trailer you watch this year.
3. In noiselayers, walk until you find a place where the terrain looks designed. It is not. Write the one sentence your eye used as evidence of intention.
4. In voxelnoise, pick one floating island and answer: did it exist in the field before the threshold? Argue both yes and no; notice which argument needs the word 'decision'.
5. In perlin_terrain_sculptor, move only the threshold until the landscape stops being one. Say where the form went — deleted, or returned to the possible?
6. Walk Lab_Path last, in both directions, in silence. After a chapter of spectacle, write down what the smallest room knows that the mountain doesn't.

The seed of this sequence fits in a sentence: give chance a memory and it will impersonate the world — until a threshold makes it commit. Carry the threshold into cellular automata, where the field hardens into a grid, the memory becomes a rule, and the neighbors stop being a metaphor.

*Next: cellularautomata*

### The Ledger

- **the debt** — Noise is the loan serviced in public: smoothness is interpolation, and Perlin's Oscar was won for making the payments invisible. Every organic surface in this chapter is the grid wearing makeup — the debt managed, never repaid.
- **the trace** — The blob is the trace's counterfeit — it signals the in-between with a one-line seed, dissolution as a shader constant. The 2.5 universe gets named here: every mesh is surface, and nothing has an interior until a threshold grants one.
- **the measure** — The threshold is this chapter's real protagonist: the cut that decides solid from void inside a field that offers no such distinction. Matter is a measurement.
- **the ghost** — The blob is a gauge on the ghost's own density — where noise gets slabbed on, the current universe is exhausted at that working point, and the honest move is export. shader_noise_space confesses the rest: the continuous field is millions of discrete evaluations, vouched for only by your eye.
- **the dig** — 11 of 17 artifacts excavated; 6 remain at depth. The cut was made by hand.

## Chapter 10: Cellular Automata: Local Rules, Global Patterns

> **Local rules, global patterns. Each cell knows only its neighbors, yet worlds emerge. Rule 110 is Turing complete—simple rules can compute anything.**

`cell(t+1) = rule(cell(t), neighbors(t))`

Emergent complexity from local rules. Each cell updates based only on its immediate neighbors, yet global structures—gliders, oscillators, even computers—emerge. This is computation at the edge of chaos.

### The Principal

This chapter's principal is **structure growth** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **field**: the artifact IS the environment — to house it would kill it.

### The Primitive

**structure growth**

![structure growth](/artifact-gallery/captures/structure_growth/front.png)

3D structure growth simulation.

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

**mold network**

![mold network](/artifact-gallery/captures/mold_network/front.png)

Slime mold network generation.

**line network ca**

![line network ca](/artifact-gallery/captures/line_network_ca/front.png)

*growth_frontier + parent_connection = branching line network*

Base class visualization for line-based cellular automata.

> Connect each new cell to a neighbor and a network appears — ancestry creates structure.

**ca growth network**

![ca growth network](/artifact-gallery/captures/ca_growth_network/front.png)

*growth_tip += attractor_force / distance^2, with stochastic branching*

Network structure that grows using cellular automata rules, forming organic branching patterns through local neighbor interactions.

> Growth toward a goal, with noise, is enough to produce every vascular pattern in nature.

**ca columns**

![ca columns](/artifact-gallery/captures/ca_columns/front.png)

*2D Game of Life stacked as 3D history — each generation becomes a new vertical layer*

Cellular Automata Columns Sculpture.

> Stack time as space and a flat automaton becomes architecture.

**cellular automata 3d tree**

![cellular automata 3d tree](/artifact-gallery/captures/cellular_automata_3d_tree/front.png)

*square_layer(n) → ca_prune(edge, isolation, random) → tree silhouette*

Tree-like structure growth using 3D CA.

> A tree is what remains when you remove everything that isn't tree.

### The Walk — further in

**mirrored cellular automata**

![mirrored cellular automata](/artifact-gallery/captures/mirrored_cellular_automata/front.png)

Symmetric cellular automata pattern generator.

**ca bridge**

![ca bridge](/artifact-gallery/captures/ca_bridge/front.png)

*next_cell = wolfram_rule(left, center, right) extruded as walkable bridge*

Cellular Automata Bridge.

> A bridge built by a rule — you walk on computation.

**hexagon ca vr**

![hexagon ca vr](/artifact-gallery/captures/hexagon_ca_vr/front.png)

*hex_cell(t+1) = life_rule(6_neighbors) stacked vertically — terrain from time*

Cellular Automata on a hexagonal grid.

> Six neighbors instead of eight — the shape of the neighborhood reshapes the world.

**persian rug**

![persian rug](/artifact-gallery/captures/persian_rug/front.png)

*cell(t+1) = born/survive(neighbors) with four-fold symmetry enforcement*

Persian Rug Cellular Automata.

> Symmetry imposed on local rules transforms noise into ornament — the rug designs itself.

**lab room**

![lab room](/artifact-gallery/captures/lab_room/front.png)

*a procedurally-generated white modern test chamber that frames a workbench. The room IS the staging — white tile floor, walls, accent-colored strip naming the QFEP phase, signage, observation glass, and a central plinth where the instrument sits. Half-Life test chamber as architectural vocabulary*

Procedurally-generated Half-Life-style modern test chamber that frames a workbench. White tile floor, observation glass, accent-colored strip naming the QFEP phase, signage like 'TEST CHAMBER λ-S'. Takes a mounted_artifact_scene path and instantiates that workbench at the central plinth. The room IS the staging — same script, different DNA = different chamber.

> the room is not the experiment. The room is the SIGNAL that an experiment is about to happen.

### The Turn — parameters

Watch Game of Life emerge from four rules. See Rule 30 generate randomness from simplicity. Build patterns that compute.

Open in the dressing-room viewer: structure growth, ca columns, cellular automata 3d tree, mirrored cellular automata.

### The Critical Reading

QFEP term: **λ**

Cellular automata demonstrate emergence—the E(S) term manifesting as complex global behavior from simple local entropy. They are laboratories for studying how order and chaos interact at the edge of computation.

The artifacts' own claims:

> Connect each new cell to a neighbor and a network appears — ancestry creates structure. — *line network ca*

> Growth toward a goal, with noise, is enough to produce every vascular pattern in nature. — *ca growth network*

> Stack time as space and a flat automaton becomes architecture. — *ca columns*

> A tree is what remains when you remove everything that isn't tree. — *cellular automata 3d tree*

> A bridge built by a rule — you walk on computation. — *ca bridge*

> Six neighbors instead of eight — the shape of the neighborhood reshapes the world. — *hexagon ca vr*

> Symmetry imposed on local rules transforms noise into ornament — the rug designs itself. — *persian rug*

> the room is not the experiment. The room is the SIGNAL that an experiment is about to happen. — *lab room*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| CA_Introduction | 7×17 | 4 | 4.6 m |
| CA_ElementaryRules | 7×10 | 2 | 8.0 m |
| CA_GameOfLife | 10×16 | 5 | 13.6 m |
| CA_BeyondBinary | 7×8 | 6 | 43.5 m |
| CA_ExpandingSpace | 7×8 | 5 | 48.8 m |
| CA_SoftRules | 7×8 | 2 | 2.0 m |
| CA_AgentsCircuits | 7×8 | 3 | 11.7 m |
| CA_EdgeOfChaos | 7×9 | 4 | 0.8 m |

What this chapter teaches, walked rather than read:

- Cellular automata basics: cells, states, neighborhoods, rules
- 1D automata: Wolfram's 256 rules, Rule 30, Rule 110
- 2D automata: Conway's Game of Life—birth, survival, death
- Emergent structures: gliders, oscillators, still lifes
- Computational universality: Rule 110 is Turing complete
- Edge of chaos: where complex behavior emerges

### The Seed

> **Local rules, global patterns. Each cell knows only its neighbors, yet worlds emerge. Rule 110 is Turing complete—simple rules can compute anything.**

Exercises:

1. Cellular automata basics: cells, states, neighborhoods, rules
2. 1D automata: Wolfram's 256 rules, Rule 30, Rule 110
3. 2D automata: Conway's Game of Life—birth, survival, death
4. Emergent structures: gliders, oscillators, still lifes
5. Computational universality: Rule 110 is Turing complete
6. Walk CA_Introduction in VR and find where the rule first breaks its own pattern.
7. Open structure_growth in the dressing-room viewer and change one parameter until it stops being itself.

*Next: fractals*

### The Ledger

- **the dig** — 11 of 25 artifacts excavated; 14 remain at depth.

# Part: The Edge

*QFEP phase: λ-edge — the boundary between order and chaos where complexity emerges. Fractals are neither ordered nor random. L-systems grow like trees. Procedural generation creates worlds from rules. The Mandelbrot set's boundary IS the edge of chaos. λ ≈ 0.3–0.5.*

## Chapter 11: Fractals: Infinite Within Finite

> **Infinite complexity from finite rules. Dimensions between integers. D = log(N)/log(S). Self-similarity across scales.**

`D = log(N) / log(S)   ·   zₙ₊₁ = zₙ² + c`

Hold a fern. The frond is made of fronds, and each of those is made of smaller fronds again — pull one leaflet off and you are holding a miniature of the thing you started with. Nature does this everywhere: coastlines, lungs, river deltas, broccoli. And it does it without a blueprint, because a blueprint would have to be as large as the thing itself. What nature has instead is a rule, applied again to its own output. This sequence is about what happens when a rule is allowed to see itself: shapes with infinite detail and finite bounds, dimensions that fall between the integers, forms that no amount of zooming will simplify. The formula above measures that in-betweenness. The rooms below let you stand inside it.

### The Principal

This chapter's principal is **fractal recursion 2** — *square(center, size, d) = box(size) + square(center, size * 0.5, d-1)* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **cube**: the one-metre sim-cell made visible — the grid's unit turned into housing.

### The Primitive

*Every sequence begins with one small thing that already contains the whole idea.*

**fractal recursion 2**

![fractal recursion 2](/artifact-gallery/captures/fractal_recursion_2/front.png)

One line of code: draw a square, then call yourself with half the size. That is the entire artifact — square(center, size, d) = box(size) + square(center, size·0.5, d−1) — and everything else in this sequence is already inside it. The function refers to itself, so the shape it draws contains itself; the stopping depth d is the only mercy keeping it finite. Stand close in VR: the smallest square is the whole artifact again, at a scale your headset can barely resolve. Recursion is not a technique here. It is the subject.

> A square inside a square is not decoration — it is the first evidence that a function can call itself.

### The Walk — first steps

*Five artifacts, each one the previous idea pushed a step further — subdivision, selection, branching, self-reference, and recursion you can climb.*

#### Fractal Recursion

A rule fed its own output is the whole engine, and only the base case stops it.

You arrive in mid-air and drop a metre and a bit onto the floor, because nobody marked a spawn here and the room worked one out from its own centroid. That is a fair introduction. This is the engine room of the chapter, and almost nothing in it is the size it was meant to be.

```gdscript
func draw_recursive(centre: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        return                      # the base case, and the only thing that stops it
    add_square(centre, size)
    draw_recursive(centre, size * size_reduction, depth - 1)
```

Output becomes input. The function calls itself with a smaller argument and the smaller call calls itself again, and the whole structure is that one line repeated until a counter runs out. Everything in this chapter is built by something shaped like this.

## One call, or many

**Fractal Recursion 2** — `fractal_recursion_2`

Six squares inside each other, each half the last, hanging edge-on above head height. Read the code behind it and there is exactly one self-call, which makes this a tail call: one square per level, a straight line down. It is recursion in the strict sense and it is not branching, so nothing here multiplies. The corpus keeps a blunter description of it than the label on the wall does: a loop wearing recursion's clothes.

Keep it in mind for the next object, which is what happens when the call is made four times instead of once.

**example_8_3_recursion_circles_vr** — `example_8_3_recursion_circles_vr`

Four metres of tori, eighty-five of them, each ring carrying four smaller rings at six tenths the radius. Four calls per level and four levels: eighty-five is what one, four, sixteen and sixty-four come to. The whole assembly turns for about seven seconds, freezes for ten, and turns again. That pause is worth the wait. A branching recursion is not more complicated than a tail call by a little; it is a different order of thing, and the difference between this and the flat squares beside it is one number in one line.

**cube_subdivision** — `cube_subdivision`

The only thing in this room you cannot walk through. A cube splits into eight at a bit under half scale, then one of those eight is picked at random and split again, and again, for about ten seconds until the pile stops at eighty-five cubes. The pick is unseeded, so the pile is different every time the room loads, and it is the one object here that shows the engine choosing. Recursion in a program is exhaustive. Recursion in a world has to decide where to spend.

## Built and buried

**recursive_table** — `recursive_table`

**Recursive Chair** — `recursive_chair`

A table and a chair, each assembled from a subdivided cube in five timed steps: split, keep the top layer and four corners, flatten the top, stretch the legs. Both are here and neither can be seen. Each was placed at a fifth of its size and dropped half a metre, which puts the whole of both inside the solid cube of the floor. The chair finishes building about two and a half seconds after the room loads, underneath you.

They are the chapter's best argument about what recursion is for, which is that a chair is not a special shape but a cube with the right cells kept, and you cannot look at either of them.

**Cube Staircase** — `cube_staircase`

A staircase builds itself over two and a half seconds, six treads and a handrail, twenty-six boxes. It stands in one of the nine holes in this floor, and it has no collision, so it is a staircase you cannot climb standing in a gap you can fall through.

**fibonacci_pagoda** — `fibonacci_pagoda`

Eight tiers, each scaled down by the golden ratio to the power of a half, with a five-part finial on top: a hundred and nine pieces in all, and nine and a half metres of them in a room whose walls stop at two. It goes straight out through the roofline. This is the chapter's other recursion, the one that shrinks by an irrational number instead of a half, and you have to stand well back and look up through where the wall should be.

## Watching and not watching

**Science Screen** — `science_screen`

A screen, floating a metre and a half up with its stand's foot hanging in air, set to draw a bar chart. Twenty bars, and they come from a random number generator with a fixed seed inside the screen itself. No object in this room feeds it. It is a graph of nothing, drawn accurately, refreshed forever.

**Dark Sphere** — `dark_sphere`

A dark sphere turning slowly over a disc of light, breathing on a sine. It carries a hit body that a catalyst could shoot, and in this room shooting it does nothing at all, because the response is chosen from the map's name and this map's name matches none of the rungs that respond.

**Synthesis Stand** — `synthesis_stand`

And beside it the same sphere again, on a low slab, as the one variant of its family the measurements ranked highest, with the values on a plaque. A family reduced to its best member is the opposite move from everything else here: recursion makes many from one, and this makes one from many.

## The base case

Everything in this room is one line calling itself. The squares call once and make a ladder. The rings call four times and make a swarm. The cube calls once but chooses where, and the pagoda calls with an irrational ratio and climbs out of the building.

What stops any of them is the same thing: a counter, checked at the top, that eventually says no. Without it the engine does not make an infinitely detailed object; it makes nothing, because it never returns. The base case is not a safety rail bolted on afterwards. It is the half of the rule that makes the other half mean anything.

Next: what these rules make, measured, and the two moves that make all of it.

*Field notes: Read before written[^fractal-recursion-1] · Open[^fractal-recursion-2]*

[^fractal-recursion-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    **The arc.** Fractals runs engine, ruler, found object, atlas: Recursion owns the
    engine, KochSierpinski owns D = log(N)/log(S) and the two moves, JuliaSet is the
    hinge where authorship changes, Mandelbrot is the index of all of them.

    - You spawn in mid-air and drop about 1.3 m. No `s` cell, so the spawn is the
      centroid of every non-void cell with walls counted, at a flat 1.8 m.
    - `fractal_recursion_2` makes exactly ONE self-call: a tail call, one square per
      level. The registry's own dna note calls it a loop wearing recursion's clothes;
      the description calls it "advanced recursion patterns".
    - `recursive_table` and `recursive_chair` are INVISIBLE. Their tokens `:0:-0.5:0.2`
      shrink them to a fifth and drop them half a metre, putting both entirely inside
      the solid floor cube. The y offset also cancels auto-grounding.
    - `fibonacci_pagoda` is 9.43 m in a room whose walls stop at 2.0 m.
    - `cube_staircase` stands in one of the nine floor holes and has no collision.
    - `cube_subdivision` is the only solid artifact; scale 0.45 not 0.5; unseeded.
    - `science_screen#mode:bars` draws 20 bars from its own seed 12345. Nothing in the
      room supplies data.
    - The teleporter is on a void cell and works only because you fall into the pit.
    - Shooting `dark_sphere` does nothing: the rung is derived from the map name and
      "fractal recursion" matches none of them.
    - Three registry measurements here are photographs of an unfinished build:
      cube_staircase's aabb is one tread, recursive_table's is the step-0 cube.

[^fractal-recursion-2]: **Open.**
    - The buried table and chair are the room's best argument and cannot be seen. One token edit each (drop the -0.5 and the 0.2) would put them on the floor at full size.

#### Fractal KochSierpinski

Replace and remove are the two fractal moves, both land between the integers, and dimension is a number you can measure rather than a number you are given.

You arrive standing five centimetres inside a pyramid. Nobody marked a spawn, so the room put you at its own centre, and its own centre is occupied by the base of the largest solid object in the chapter. Step out of it first.

```gdscript
D = log(N) / log(S)
```

Count how many copies of itself a shape contains, count how many times smaller each copy is, and divide one logarithm by the other. For a line cut in two you get one. For a square quartered you get two. For the two shapes in this room you get numbers that are not whole, and that is the whole content of the word fractal.

## The two moves

**Koch Curve** — `fractal_koch_curve`

The first move is replace. Take a segment, take out its middle third, and put two sides of a triangle there instead: four segments where there was one, each a third as long, so the length goes up by a third at every step and never stops going up. Four copies at one third: the dimension is about 1.26.

It is also the one thing here a hand can change. There is a slider on it, and turning it walks the depth up and down while you watch. Watch the size, though, not just the shape. At depth four this drawing measures the same bounding box as at depth zero, to the millimetre, because its spikes are built pointing inward. Infinite perimeter inside a finite box is the honest headline of the Koch curve, and this object demonstrates it by accident, in the wrong direction, which is a better demonstration than the intended one.

**3D Koch Curve** — `koch_curve_3d`

The same curve bent into an archway, drawn as two thousand three hundred cylinders. Look at it and then look at the note the corpus keeps about it: at this line thickness, iterations three, four, five and six are the same photograph. The detail is really there and the pipe drawn around it is thicker than the detail is fine. Resolution is a property of the drawing, not of the object.

**sierpinski_triangle** — `sierpinski_triangle`

The second move is remove. Take a triangle, take out the middle one of the four you can quarter it into, and repeat on the three that are left: three copies at one half, dimension about 1.585. It builds over six seconds, a thousand and ninety-two slabs of it, ten metres wide in a room thirteen across, and it goes out through the east wall, out through the south wall and three and a half metres down through the floor. Nothing stops you walking through it, because it has no collision anywhere.

**sierpinski_pyramid** — `sierpinski_pyramid`

The same removal in three dimensions, and the only thing in this room that is solid. Twelve metres of lattice built out of nearly thirteen hundred separate cubes, each one carrying its own collision body, which is why you started inside it and why it is the one object here you can be stopped by. Four copies at one half in three dimensions gives a dimension of exactly two: a solid that fills area like a sheet and volume like nothing at all.

## Measuring it

**Box Counting Dimension** — `box_counting_dimension`

The bench that turns the formula into an instrument. Eight thousand points scattered into a Sierpinski gasket, a grid laid over them at six different scales, and a count at each scale of how many boxes have anything in them. Plot the counts against the scales on log paper and the points fall on a line, and the slope of that line is the dimension. It reads 1.585.

That number was not put in. It was measured off a scatter of points, and it agrees with the three-copies-at-one-half arithmetic to three decimal places. This is the moment the chapter stops describing and starts checking.

**Recursion Observatory** — `recursion_observatory`

Four of them side by side on one bench, ordered along a rail marked from zero to three: Cantor dust, the Koch curve, the Sierpinski pyramid, the Menger sponge. Nothing here moves. It is a shelf of specimens arranged by a quantity, which is what a museum does with anything once it can measure it.

## Built without either move

**Cube Cabin** — `cube_cabin`

**Cube Bookshelf** — `cube_bookshelf`

A cabin and a bookshelf, each assembling itself out of boxes over a couple of seconds. They are here as the control, and they are more honest as a control than their labels admit: both are described as made by cube subdivision, and neither subdivides anything. The cabin is thirty-one hard-coded boxes and the shelf is twelve. Put them next to a Sierpinski pyramid and the difference is exact. One of these was written out part by part. The other was written once and applied to itself.

**Science Screen** — `science_screen`

**Dark Sphere** — `dark_sphere`

A screen set to record a trace, with nothing in the room drawing one, and a dark sphere turning over its halo. Between them they are the room's only two things at human scale, in a hall where the two objects that matter are five and ten metres taller than the walls.

## Between the integers

A line is one-dimensional and a plane is two, and everything you were taught to draw sits on one of those whole numbers. Replace and remove both break that. The Koch curve is more than a line and less than a plane, at 1.26. The Sierpinski triangle is 1.585. The pyramid is exactly two and is not a surface.

The number is not a metaphor and not a ranking. It is a measured slope, taken off a log-log plot on the bench in the corner, and it says how fast detail appears as you look closer. That is what a dimension has always been. Nobody noticed it could be fractional until somebody measured a coastline.

Next: a fractal nobody built at all.

*Field notes: Read before written[^fractal-kochsierpinski-1] · Open[^fractal-kochsierpinski-2]*

[^fractal-kochsierpinski-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **The spawn is inside solid geometry**: 5 cm inside the pyramid's base slab,
      which occupies y 1.0 to 2.0 at the floor centroid.
    - **`sierpinski_pyramid` builds 1296 leaves, not the 625 the registry states** —
      `_recursive_build` makes six calls, so depth 4 is 6^4. It is the only solid
      object in the room, with 1296 StaticBody3D pairs.
    - **`sierpinski_triangle` is 10 m wide in a 13 m room**, out through two walls and
      3.8 m under the floor, with zero collision.
    - **`fractal_koch_curve` at depth 4 measures the same bounding box as depth 0**,
      because the spikes are built pointing inward. The text uses this as the honest
      demonstration of infinite perimeter in a finite box.
    - **`koch_curve_3d` draws 2304 cylinders of radius 0.20 m on a 4.712 m curve**;
      the registry's own note says iterations 3 to 6 are one photograph.
    - `cube_cabin` and `cube_bookshelf` are 31 and 12 hard-coded boxes, with no
      subdivision and no recursion despite both descriptions.
    - `box_counting_dimension` measures 1.585 off 8000 points and agrees with the
      arithmetic. It is the room's one genuine measurement.
    - The teleporter is in a hole.

[^fractal-kochsierpinski-2]: **Open.**
    - Two artifacts are 5.9 m and 10.25 m taller than the walls. Either the room grows or they shrink; the text describes them going through the roofline, which is true and probably not intended.

#### Fractal JuliaSet

Nobody builds this one. The boundary between two fates draws itself, and a single number decides which boundary you get.

The last two halls were made things: a rule you wrote, applied to a shape you chose, as many times as you said. This is the hall where that stops. There is no construction here. There is a question asked of every point in a plane, and the answer, plotted, is the picture.

```gdscript
func escapes(z: Vector2, c: Vector2, limit: int) -> int:
    for i in limit:
        z = Vector2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c
        if z.length_squared() > 4.0:
            return i          # it left. how long it took is the colour
    return limit              # it stayed
```

Square it and add c. Do that forever. Some starting points run away to infinity and some never leave, and the only thing the machine records is how many steps the runaways lasted. Nobody draws a shape. The shape is the border between the ones that stay and the ones that go.

## The set, on the floor

**Julia Set** — `julia_set`

Not a picture and not a screen: a carpet of eight-centimetre cubes lying flat on the ground, one cube per point that survived the test. It is sparse, a scatter rather than a field, and it breathes on a thirty-second cycle as the zoom drifts, thickening to four hundred and sixty cubes and thinning back to forty-five. About a third of it hangs off the edge of the platform over nothing.

Walk around it rather than looking at it from one side. The cubes are the points that never escaped, and the empty floor between them is not background: it is every point that did. The picture is made of one answer and the absence of the other.

**Julia Set Explorer** — `julia_set_explorer`

The instrument, and the only thing in this room you can operate. A table with a shader running on its top face, computing the same escape test per pixel in real time, and two grabbable sliders and four buttons on a panel at the near edge. The sliders move c.

That is the room in one gesture. c is a single complex number, two dials, and it is not a setting for the picture; it is the picture's entire identity. Move it a little and the shape deforms. Move it past a certain boundary and the set shatters from one connected object into infinitely many disconnected specks, with no intermediate state. There is a knife edge in the dial and you can find it with your hand.

**Lyapunov Fractal** — `lyapunov_fractal`

Flat on the floor beside it, a small painted square computed once and never again. Different equation, same idea: run a simple rule over and over for each point and colour by whether the running is stable or divergent. The order of the letters in its pattern is chosen before anything is drawn, and the picture is what that order produces. It is here to say that the trick is not special to one formula.

**Dark Sphere** — `dark_sphere`

A dark sphere over a disc of light, turning, breathing. The one object in this hall that has a surface you could point at and a size you could state.

## Found, not made

Six metres above the west edge of the floor, well past where you can walk, a red marker drags a comet trail through empty air. That is c, moving along a slow closed path, and the carpet on the floor is what c currently is. The parameter is out of reach and the picture is at your feet, and neither of them is a thing anybody drew.

This is the chapter's turn. Recursion was an engine you fed. The Koch curve and the Sierpinski triangle were rules you applied to a shape you chose. Here the rule is three operations long, the shape is not chosen at all, and what appears has a boundary of infinite intricacy that no one designed and no one can fully specify. The authorship has moved. You set one number; everything else is discovered.

And there are as many of these as there are complex numbers.

Next: the map of all of them at once.

*Field notes: Read before written[^fractal-juliaset-1] · Open[^fractal-juliaset-2]*

[^fractal-juliaset-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **The set is a carpet, not a picture**: 0.08 m cubes flat on the floor, 181 at
      boot, breathing between 45 and 461 on a 31.4-second zoom cycle. About a third
      hangs off the platform edge.
    - **`julia_set_explorer` is the only operable thing** — two grabbable XR sliders
      and four buttons running the escape test as a shader. The registry declares its
      interaction as "observe", which is backwards.
    - **The c marker floats 6.5 m up and sweeps past the west edge** of a platform
      that ends at x -0.5.
    - `lyapunov_fractal` computes a 128x128 image once and lies flat on the floor;
      the registry wants it on a table.
    - `sp` at (0,0) is score points, not a spawn. There is no spawn mark at all.
    - The teleporter is on a void cell, 0.8 m below the walking surface.
    - **summary.md, technical.md and critical.md are all about a different map**
      (Fractals_8, a Cantor/Menger room), and intent.md names a `fibonacci_terrain`
      token that does not exist here. None was used.

[^fractal-juliaset-2]: **Open.**
    - The disconnection threshold is the room's best moment and the text says you can find it with the sliders. Worth walking to confirm the slider range actually crosses it.

#### Fractal MandelbrotSet

Five characters index every Julia world at once, and the edge of that index is where the interesting ones live.

The last hall gave you one dial and one picture. Turn the dial and you get a different picture; turn it far enough and the picture stops being connected and falls into dust. That raises an obvious question, and this hall is the answer to it: for which values of c does the set hold together?

```gdscript
z = z * z + c
```

The same five characters, asked a different question. In the last hall c was fixed and you swept the starting points. Here the starting point is always zero and you sweep c, and you mark every c whose orbit stays bounded. What you get is not another fractal in the family. It is the catalogue of the family.

## The catalogue overhead

**Mandelbrot Set** — `mandelbrot_set`

Ten thousand cubes in a field nine and a half metres square, hanging about four metres up, which is wider than the floor it hangs over and higher than anything you can climb. Each cube is one value of c, coloured by how long that c took to escape, and the black region in the middle is the set itself: every c whose Julia set is connected.

You are standing under a map, and each pixel of the map is an entire world from the previous hall. Look up long enough and the shape resolves: a cardioid with a disc stuck to it, and smaller discs on that, and filaments running out. The filaments are where the two behaviours meet, and every one of them is a place where a hair's difference in c is the difference between a connected Julia set and a cloud of dust.

Do not jump while you are looking at it. The jump key is bound to the same action that resets the field's zoom, so the whole thing re-rolls over your head.

**mandelbrot_dive** — `mandelbrot_dive`

The instrument, on a table that floats a little off the floor: the same computation as a shader, live, with two sliders and four buttons. Zoom in anywhere on the boundary and there is more boundary, at every magnification, forever, and small complete copies of the whole shape appear inside the filaments, each one slightly distorted and unmistakably the same object.

There is a catch worth knowing before you use it. The pan controls answer to the same keys as walking, so on a desktop, crossing the room drags the fractal along with you. The instrument and the visitor are wired to the same hands.

**Dark Sphere** — `dark_sphere`

A dark sphere pulsing on the floor at knee height, seventy centimetres across. In a room whose subject has no scale at all, it is useful to have one object whose size you can state.

## The honest cap

Every picture here is a lie about depth, and the lie is measurable. The field overhead runs its test a hundred times per point and then gives up; anything still bounded after a hundred steps is painted black and called a member. Some of those points are not members. They would have escaped on the hundred and first step, or the thousandth.

So the black region you are looking at is slightly too big, and it is too big in a way that depends entirely on a number somebody chose. Zoom the table in far enough and the boundary goes soft and blocky, not because the object ran out of detail but because the arithmetic ran out of digits. The object has infinite detail. Every image of it has a budget.

That is the chapter's last honesty, and it belongs here rather than in the halls before it. Recursion had a base case that stopped it. The Koch curve had a line thickness that hid it. Julia had a zoom that breathed. And the atlas of all Julia sets has an iteration cap, which is the same admission in its final form: the rule is infinite and every look at it is finite.

Next: what these rules make when they are set to grow rather than to draw.

*Field notes: Read before written[^fractal-mandelbrotset-1] · Open[^fractal-mandelbrotset-2]*

[^fractal-mandelbrotset-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **The field is 9.584 m square, 6% wider than the entire floor**, hanging at
      3.96 m: 10,000 boxes, 100 iterations each.
    - **Auto-ground lifts it 3.50 m, driven by two decorative CSG props** at local
      y -3.5 that control nothing; they end up 5.5 m and 1.5 m beyond the floor edges.
    - **Jumping re-rolls the fractal.** `_input` fires on `ui_accept`, which is Space,
      which is jump.
    - **Walking pans the dive table.** `mandelbrot_dive._input` binds W/A/S/D to
      centre_x and centre_y, the same physical keycodes as movement.
    - `mandelbrot_dive` has two grab sliders, four buttons and eleven key bindings;
      the registry says "observe".
    - The 100-iteration cap is real and is the room's closing argument: the black
      region is slightly too big, by an amount somebody chose.
    - **summary.md, technical.md and critical.md describe Fractals_9.** eye_shot.md is
      six weeks stale.

[^fractal-mandelbrotset-2]: **Open.**
    - Two input collisions (jump re-rolls, walking pans) are genuine bugs the text turns into warnings. Both are one keybinding away from fixed.

*6 further room(s) in this chapter, not yet written.*

**recursive table**

![recursive table](/artifact-gallery/captures/recursive_table/front.png)

Subdivision runs backwards too. Take a cube, cut it three by two, keep only the top layer and the four corners, flatten the top, stretch the legs — a table appears. Nothing was added at any point. The furniture was carved out of the possibility space, the way a sculptor insists the figure was always in the marble.

> A table is a cube that kept its top layer and four corners — everything else was excess.

**recursive chair**

![recursive chair](/artifact-gallery/captures/recursive_chair/front.png)

The same move with a different keep-list: three by three by three, keep legs, seat, back. Put the chair beside the table and the deeper claim becomes visible — these objects are not built, they are selected. One rule, different choices.

> The chair was always inside the cube — subdivision merely removed what was not chair.

**inverted tree cloud**

![inverted tree cloud](/artifact-gallery/captures/inverted_tree_cloud/front.png)

The first branching recursion, hung upside down. A trunk grows downward, branches shrink and scatter at random angles, a cloud of cubes orbits and fades. The inversion is the point: this is a root system — and the random angles quietly introduce the E in this sequence's formula, a deterministic rule with noise in its joints.

> An inverted tree is not wrong — it is a root system, and roots are where the real computation happens.

**example 8 3 recursion circles vr**

![example 8 3 recursion circles vr](/artifact-gallery/captures/example_8_3_recursion_circles_vr/front.png)

Back to the pure form, in circles: a torus, then four half-size circles at its cardinal points, then sixteen, then more. This is the one to hold. It is small enough to grasp and deep enough to show the distinction that matters: a loop repeats an action, but this circle contains its own definition. Recursion is not repetition — it is self-reference.

> Recursion is not repetition — it is self-reference, and the circle that contains circles is the first fractal you can hold.

**cube staircase**

![cube staircase](/artifact-gallery/captures/cube_staircase/front.png)

Recursion along a diagonal: a tread, a riser, then call yourself one step down. It earns its place in the walk because it is recursion you can climb — the algorithm as architecture, load-bearing.

> A staircase is a cube that learned to subdivide itself along its own diagonal.

### The Walk — further in

*Further in: ratio, choice, then the measure, the edge itself — and subtraction to close.*

**fibonacci pagoda**

![fibonacci pagoda](/artifact-gallery/captures/fibonacci_pagoda/front.png)

Nine metres of golden ratio. Each tier is the one below divided by the root of φ, stacked up to a finial. From a distance it reads as architecture; up close it reads as pure number. That double reading is the sequence's quiet argument: culture and mathematics are not different materials.

> The golden ratio is not imposed on the pagoda — the pagoda is what the golden ratio looks like when it tries to be architecture.

**cube subdivision**

![cube subdivision](/artifact-gallery/captures/cube_subdivision/front.png)

Eight children, keep one, recurse. Where the pagoda makes ratio visible, this makes choice visible: the path down the subdivision tree is a history of decisions, and the artifact is that history, frozen in place.

> To subdivide is to choose — and the fractal is the history of every choice made at every scale.

**box counting dimension**

![box counting dimension](/artifact-gallery/captures/box_counting_dimension/front.png)

The instrument the whole chapter has been promising. Lay a grid over a shape and count the boxes it touches; halve the grid, count again; keep going. The exponent that emerges as the boxes shrink is D = log(N)/log(S) — the formula from page one, measured instead of asserted. A line's count doubles per halving; a plane's quadruples; a coastline lands stubbornly in between, and stays there at every ruler you can afford. Dimension stops being a given and becomes a reading — and like every reading in this book, it depends on the fineness of the instrument doing it.

> Fractal dimension is not a property of the shape. It's a property of how the shape fills space at every scale.

**mandelbrot dive**

![mandelbrot dive](/artifact-gallery/captures/mandelbrot_dive/front.png)

And then the edge itself. z → z² + c, iterated: for some c the orbit stays home forever, for others it flees to infinity, and the boundary between those two fates is the most complex object mathematics owns — infinitely detailed, nowhere smooth, and bounded. Dive: every magnification produces new coastline, seahorses, spirals, small copies of the whole set waiting at depths no one has visited. Here the chapter's QFEP claim stops being a metaphor. The Mandelbrot boundary IS the edge of chaos — order and entropy interlocked at every scale — and in this room you are not looking at it, you are falling along it.

> The simplest equation in complex dynamics produces the most complex object in mathematics.

**example 8 4 cantor set vr**

![example 8 4 cantor set vr](/artifact-gallery/captures/example_8_4_cantor_set_vr/front.png)

The walk ends with removal. Delete the middle third, then the middle of what remains, forever: infinitely many points, zero total length. The Cantor set closes the walk by inverting everything before it — the other artifacts built by adding smaller copies; this one builds by taking away.

> The Cantor set teaches subtraction as a creative act — what you remove defines what remains.

### The Turn — parameters

Every artifact in the walk holds its rule fixed and exposes its numbers. Depth is the honest knob — push it and cost explodes exponentially while new form arrives only logarithmically; that asymmetry is the fractal bargain, and every renderer pays it. The scale ratios (0.5, 0.7, 1/φ) set the personality of the whole; branch counts set density; random angles decide whether a form reads as mathematics or as biology. Open any of these in the dressing-room viewer and move one knob until the artifact stops being itself. The point where it stops is that parameter's real meaning.

Open in the dressing-room viewer: fractal recursion 2, recursive table, recursive chair, inverted tree cloud.

### The Critical Reading

*Now the reading the renders have been implying all along.*

QFEP term: **E(S) + F**

Fractals embody the QFEP tension directly: F, the deterministic recursive rule, plus λE(S), random variation in the stochastic forms, makes shape at the edge of chaos. The Mandelbrot boundary is where order meets chaos — infinitely complex, yet bounded. And fractals are queer geometry in the precise sense: dimensionally non-normative, nowhere smooth, computationally irreducible — form that refuses the integer categories of line, plane and solid the way queer life refuses given categories, by existing fully, and permanently, in between.

The artifacts' own claims:

> A square inside a square is not decoration — it is the first evidence that a function can call itself. — *fractal recursion 2*

> A table is a cube that kept its top layer and four corners — everything else was excess. — *recursive table*

> The chair was always inside the cube — subdivision merely removed what was not chair. — *recursive chair*

> An inverted tree is not wrong — it is a root system, and roots are where the real computation happens. — *inverted tree cloud*

> Recursion is not repetition — it is self-reference, and the circle that contains circles is the first fractal you can hold. — *example 8 3 recursion circles vr*

> A staircase is a cube that learned to subdivide itself along its own diagonal. — *cube staircase*

> The golden ratio is not imposed on the pagoda — the pagoda is what the golden ratio looks like when it tries to be architecture. — *fibonacci pagoda*

> To subdivide is to choose — and the fractal is the history of every choice made at every scale. — *cube subdivision*

### In the World

*Ten rooms, and their order is the argument: first recursion held in the hand, then trees, then subtraction (Cantor), then the classical monsters (Koch, Sierpinski, Menger), then ratio (the golden spiral), then the edge of chaos itself (Julia, Mandelbrot), and finally a synthesis hall where they all stand together.*

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Fractal_Recursion | 9×13 | 13 | 36.5 m |
| Fractal_RecursiveTrees | 15×12 | 12 | 54.2 m |
| Fractal_CantorSet | 17×21 | 7 | 42.2 m |
| Fractal_KochSierpinski | 11×9 | 9 | 45.6 m |
| Fractal_MengerSponge | 13×13 | 3 | 26.7 m |
| Fractal_GoldenSpiral | 15×13 | 5 | 27.8 m |
| Fractal_JuliaSet | 9×9 | 4 | 8.8 m |
| Fractal_MandelbrotSet | 9×9 | 3 | 19.0 m |
| Fractal_Synthesis | 21×19 | 10 | 102.9 m |
| Fractal_CrossSequence | 7×8 | 6 | 12.8 m |

What this chapter teaches, walked rather than read:

- Self-similarity: the whole contains copies of itself
- Fractal dimension: D = log(N)/log(S) — between the integers
- Recursion as emergence: simple rules, infinite complexity
- The edge of chaos: the Mandelbrot boundary, Julia variations
- Natural fractals: trees, coastlines, romanesco

The machine walked Hangar_Fractals_Walk and filed this ride log:

> 100 stations from spawn to exit; 104 bodies measured.

> box_counting_dimension held the view at 12 of 100 stations, peaking at 43° — the room has one voice louder than the rest.

> the smallest walked body is example_8_4_cantor_set_vr at 0.8 m.

> recursive_table and inverted_tree_cloud overlap by 1.3 m — two exhibits share ground.

### The Seed

> **Infinite complexity from finite rules. Dimensions between integers. D = log(N)/log(S). Self-similarity across scales.**

Exercises:

1. In Fractal_Recursion, find the deepest square you can actually see, then check how many levels the code claims exist. The difference between those two numbers is the gap between mathematics and rendering — write it down.
2. Open recursive_chair in the dressing-room viewer and change the keep-list in your head: which cells would you keep for a bench? A throne? Sketch the rule, not the object.
3. Walk Fractal_CantorSet and stand in one of the gaps. What was removed to make room for you? Answer in one sentence that uses the word 'creative'.
4. In Fractal_MandelbrotSet, try to point at the exact place where order ends and chaos begins. You will fail. Explain your failure using D = log(N)/log(S).
5. Take the pagoda's rule — divide by √φ per tier — and apply it to something that is not architecture: a schedule, a sentence, a family. Does it stay golden?
6. Compute the dimension of cube_subdivision's path: N = 1 kept, S = 2 scale, so D = 0. What does it mean that a history of choices has the dimension of a point?

The seed of this sequence fits in a sentence: a rule allowed to see itself makes infinite form from finite means. Carry it into L-systems, where the rule stops drawing and starts writing.

*Next: lsystems*

### The Blanks — declared open

- ◇ The empty plinth points forward: the Hilbert curve stands in the next room — space-filling curves are walked in L-systems, where the grammar draws them (Hilbert3D, space_filling_curve_gallery, both load-bearing there). The blank stays, resolved by adjacency: what this chapter cannot hold, the next one carries, and the plinth is the sightline between them. (R-012)

### The Ledger

- **the measure** — Dimension itself becomes a measurement — D = log(N)/log(S) lands between the integers, and the length of the ruler changes the coastline it measures.
- **the debt** — Depth is the loan: each recursion level doubles what the render owes the ideal form while returning less new shape. The visible bottom of every fractal is a payment that stopped.
- **the dig** — 11 of 47 artifacts excavated; 36 remain at depth. The cut was made by hand.

## Chapter 12: L-Systems: Rules Grow Structure

> **A sentence can become a forest. Grammar is generative.**

From a single axiom, a tree grows. L-systems are string rewriting rules that generate branching structures — trees, cities, space-filling curves. Start in the grammar lab, watch growth unfold, formalize the rules, build cities, compete for space, and finally watch the world come alive.

### The Principal

This chapter's principal is **lsystem editor** — *axiom → rules → string → turtle(F, +, -, [, ]) → line geometry — the full L-system pipeline interactively* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**lsystem editor**

![lsystem editor](/artifact-gallery/captures/lsystem_editor/front.png)

*axiom → rules → string → turtle(F, +, -, [, ]) → line geometry — the full L-system pipeline interactively*

Edit L-system grammars in real-time and watch procedural plants, fractals, and branching structures grow from simple rewriting rules. Adjust axiom, production rules, angle, and iteration depth to explore the space of formal grammars made visible.

> Seven presets, one turtle — the grammar is the artist.

### The Walk — first steps

*7 room(s) in this chapter; none written yet.*

**space filling curve gallery**

![space filling curve gallery](/artifact-gallery/captures/space_filling_curve_gallery/front.png)

*three L-systems (Hilbert, Peano, Moore) → turtle → pixel path → floor triptych*

Triptych of classic space-filling curves — Hilbert, Peano, and Moore — generated via L-system rules and turtle graphics on a floor display. Curves that visit every point in a 2D region.

> Three grammars, one goal — every point touched, no crossing, each path a different philosophy of exhaustion.

**Hilbert3D**

![Hilbert3D](/artifact-gallery/captures/Hilbert3D/front.png)

*A → -BF+AFA+FB-, B → +AF-BFB-FA+ in 3D with pitch/roll — a single path visits every point in a cube*

Space-filling curve visualization demonstrating efficient 3D traversal

> A grammar can visit every point in space without crossing itself — infinity threaded through a cube.

**fractal lsystem string**

![fractal lsystem string](/artifact-gallery/captures/fractal_lsystem_string/front.png)

*string(n+1) = replace_all(string(n), F, rule) — exponential rewriting made visible*

Visualizes the L-system rewriting process — shows how the axiom string expands through each generation, making the grammar visible as text.

> The string is the structure — the tree is just one way to read it.

**lsystem dungeon**

![lsystem dungeon](/artifact-gallery/captures/lsystem_dungeon/front.png)

*F → F+RF-FF-FR+F, R → RFRFRF — corridor grammar with room markers at 90° turns*

Procedural dungeon floor plan generated from L-system grammar rules — corridors and rooms emerge from string rewriting, rendered as a miniature architectural model.

> Two rules and a turtle — the dungeon writes itself.

**lsystem tree**

![lsystem tree](/artifact-gallery/captures/lsystem_tree/front.png)

*F → F[+F]F[-F]F at 25.7° — the classic Lindenmayer plant in one rule*

Classic deterministic L-system tree — the foundational teaching example showing how a simple grammar rule produces organic branching structure.

> One rule, one angle, one axiom — a tree grows.

### The Walk — further in

**AnimatedTree**

![AnimatedTree](/artifact-gallery/captures/AnimatedTree/front.png)

*generation_timer → lsystem.generate() → interpret → draw_with_wind — growth made visible in time*

Time-sliced L-System interpretation showing organic growth animation

> Watching a tree grow generation by generation teaches more than seeing the final form.

**CityGenerator**

![CityGenerator](/artifact-gallery/captures/CityGenerator/front.png)

*X → F[+X]F[-X][^X][&X], F → FF at 90° with pitch/yaw branching — orthogonal L-system architecture*

Procedural pipe network using orthogonal L-System rules

> Change the angle from 25° to 90° and the tree becomes a city — architecture is botany with right angles.

**parametric lsystem**

![parametric lsystem](/artifact-gallery/captures/parametric_lsystem/front.png)

*angle(depth) = base_angle * 0.95^depth + random(-var, +var) — parametric decay per branch level*

L-system with continuous angle and length parameters — branch depth controls parametric decay for organic, naturalistic tree and plant forms. More organic than discrete rules.

> Randomness in the parameters, not the rules, is what makes grammar look like nature.

**ForestCompetition**

![ForestCompetition](/artifact-gallery/captures/ForestCompetition/front.png)

*tree.dbh += nutrients * season * strategy * health; nutrients diffuse and deplete — competitive growth on shared soil*

Multiple L-System trees with competing growth strategies and health mechanics

> Competition emerges when grammars share resources — ecology is grammar plus scarcity.

**ContextSensitiveTree**

![ContextSensitiveTree](/artifact-gallery/captures/ContextSensitiveTree/front.png)

*if ray_cast(branch_tip, obstacle) → prune_branch(red_stub) else grow_forward*

L-System tree with physics-based environmental awareness and branch pruning

> Context sensitivity is how real trees grow — the environment is part of the grammar.

### The Turn — parameters

Open in the dressing-room viewer: lsystem editor, Hilbert3D, fractal lsystem string, lsystem dungeon.

### The Critical Reading

QFEP term: **Lambda_Edge**

L-systems sit at the edge between deterministic rules (F) and emergent complexity (E). Simple rewriting rules produce infinite variation. The lambda parameter is iteration count — each generation pushes further toward the edge.

The artifacts' own claims:

> Seven presets, one turtle — the grammar is the artist. — *lsystem editor*

> Three grammars, one goal — every point touched, no crossing, each path a different philosophy of exhaustion. — *space filling curve gallery*

> A grammar can visit every point in space without crossing itself — infinity threaded through a cube. — *Hilbert3D*

> The string is the structure — the tree is just one way to read it. — *fractal lsystem string*

> Two rules and a turtle — the dungeon writes itself. — *lsystem dungeon*

> One rule, one angle, one axiom — a tree grows. — *lsystem tree*

> Watching a tree grow generation by generation teaches more than seeing the final form. — *AnimatedTree*

> Change the angle from 25° to 90° and the tree becomes a city — architecture is botany with right angles. — *CityGenerator*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| LSystems_Grammar_Lab | 8×10 | 6 | 24.3 m |
| LSystems_Growth | 8×10 | 4 | 9.0 m |
| LSystems_Grammars_And_Curves | 8×10 | 3 | 4.8 m |
| LSystems_Architecture | 8×10 | 3 | 17.7 m |
| LSystems_Competition | 8×10 | 3 | 8.5 m |
| LSystems_Living | 10×10 | 3 | 3.5 m |

What this chapter teaches, walked rather than read:

- String rewriting as generative process
- Turtle graphics interpretation of L-system strings
- Context-sensitive vs context-free rules
- Formal grammars and space-filling curves
- L-systems beyond biology — architecture and space-filling
- Emergence from competing growth systems
- Grammar as world-building principle — ecosystem transition

### The Seed

> **A sentence can become a forest. Grammar is generative.**

Exercises:

1. String rewriting as generative process
2. Turtle graphics interpretation of L-system strings
3. Context-sensitive vs context-free rules
4. Formal grammars and space-filling curves
5. L-systems beyond biology — architecture and space-filling
6. Walk LSystems_Grammar_Lab in VR and find where the rule first breaks its own pattern.
7. Open lsystem_editor in the dressing-room viewer and change one parameter until it stops being itself.

*Next: proceduralgeneration*

### The Ledger

- **the dig** — 11 of 15 artifacts excavated; 4 remain at depth.

## Chapter 13: Procedural Generation: Rules Build Worlds

> **A world doesn't need an author. Rules and randomness are enough.**

From a seed, a world grows. Growth algorithms, maze generators, evolutionary systems — each finds different ways to let rules create structure. Heavy compute artifacts get their own rooms; lighter ones share space.

### The Principal

This chapter's principal is **maze generation** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**maze generation**

![maze generation](/artifact-gallery/captures/maze_generation/front.png)

VR-scale walkable maze with recursive backtracking generation

### The Walk — first steps

*7 room(s) in this chapter; none written yet.*

**space colonization algorithm**

![space colonization algorithm](/artifact-gallery/captures/space_colonization_algorithm/front.png)

*for each leaf_node: find closest attractor, grow segment_length toward it, kill attractor when reached — space colonization*

Growth algorithm that builds branching structures by attracting tips toward a cloud of auxin-like markers — Runions-style space colonisation producing tree/coral/blood-vessel topologies.

> a tree does not know its shape — it only knows which direction has light, and how far to reach before stopping

**branching growth algorithm**

![branching growth algorithm](/artifact-gallery/captures/branching_growth_algorithm/front.png)

Interactive visualization of branching growth patterns and algorithmic plant generation

**percolationnetwork ca**

![percolationnetwork ca](/artifact-gallery/captures/percolationnetwork_ca/front.png)

*P(occupied) = threshold -> CA flow propagation from top to bottom — does the random lattice percolate?*

P(occupied) = threshold -> CA flow propagation from top to bottom — does the random lattice percolate?

> connectivity is not gradual — below the threshold nothing connects, above it everything does, and at the threshold the system decides

**cube mound scene**

![cube mound scene](/artifact-gallery/captures/cube_mound_scene/front.png)

Procedural mound built from stacked cubes — layered cellular logic deposits cubes where conditions permit, producing terrain that is both built and eroded.

**GeneticProgramming**

![GeneticProgramming](/artifact-gallery/captures/GeneticProgramming/front.png)

*population[i].fitness = f(genome) -> select, crossover, mutate, repeat — evolution without a designer*

Watch 3D creatures evolve generation by generation toward a fitness goal no individual understands. Population grid displays organisms with fitness labels. Auto-evolve ticks on a timer or step manually. Creatures converge on similar body plans despite random initialization — convergent evolution from pure math. Evolution does not design — it accumulates accidents that happen to survive.

> evolution does not design — it accumulates accidents that happen to survive

### The Walk — further in

**caverandomwalk**

![caverandomwalk](/artifact-gallery/captures/caverandomwalk/front.png)

*N walkers carve air from solid voxel grid — biased random walk inward, then upward level by level*

N walkers carve air from solid voxel grid — biased random walk inward, then upward level by level

> a cave is not empty space — it is the record of everything that was removed, and the walker's path is the cave's memory

**mirror cellular texture for 3d**

![mirror cellular texture for 3d](/artifact-gallery/captures/mirror_cellular_texture_for_3d/front.png)

Interactive 3D cellular automata with mirroring and texture generation capabilities

**layered membrane**

![layered membrane](/artifact-gallery/captures/layered_membrane/front.png)

*N concentric SurfaceTool cylinders with sin() + Perlin displacement -> layered translucent membrane sculpture*

Procedural membrane generation with layered structures

> a membrane is a boundary that is also a surface — it separates inside from outside while being neither

**rhizomatic maze space**

![rhizomatic maze space](/artifact-gallery/captures/rhizomatic_maze_space/front.png)

*growth_seeds -> RhizomaticMazeGenerator -> path_network -> organic tunnel meshes with noise displacement — Deleuze's rhizome as architecture*

A labyrinthine exploration of rhizomatic growth patterns, creating interconnected maze-like spaces that grow organically like fungal networks or plant root systems

> a rhizome has no beginning and no end — it is always in the middle, between things, a line of flight

**organic space**

![organic space](/artifact-gallery/captures/organic_space/front.png)

*CSG boolean(sphere, cylinder, box) + FastNoiseLite displacement -> organic cave interior with floating orbs*

An algorithmic exploration of organic geometries and natural forms, creating flowing, non-Euclidean spaces that challenge traditional geometric assumptions

> an organic space is not designed from outside — it is what remains after noise has eaten away at geometry from within

### The Turn — parameters

Open in the dressing-room viewer: maze generation, space colonization algorithm, branching growth algorithm, percolationnetwork ca.

### The Critical Reading

QFEP term: **Lambda_Edge**

Procedural generation IS the λ boundary — rules (F) constrained by randomness (E) produce emergent worlds. Every generator balances determinism against surprise. The threshold IS the interesting part.

The artifacts' own claims:

> a tree does not know its shape — it only knows which direction has light, and how far to reach before stopping — *space colonization algorithm*

> connectivity is not gradual — below the threshold nothing connects, above it everything does, and at the threshold the system decides — *percolationnetwork ca*

> evolution does not design — it accumulates accidents that happen to survive — *GeneticProgramming*

> a cave is not empty space — it is the record of everything that was removed, and the walker's path is the cave's memory — *caverandomwalk*

> a membrane is a boundary that is also a surface — it separates inside from outside while being neither — *layered membrane*

> a rhizome has no beginning and no end — it is always in the middle, between things, a line of flight — *rhizomatic maze space*

> an organic space is not designed from outside — it is what remains after noise has eaten away at geometry from within — *organic space*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| PG_Genetic_Evolution | 10×12 | 2 | 32.3 m |
| PG_Space_Colonization | 8×14 | 1 | 0.0 m |
| PG_Percolation_Network | 12×15 | 2 | 9.8 m |
| PG_Branching_Growth | 12×10 | 2 | 25.0 m |
| PG_Caves_Mazes | 14×10 | 2 | 20.0 m |
| PG_Sculpted_Forms | 12×12 | 3 | 37.2 m |
| PG_Mirrored_Patterns | 11×9 | 2 | 4.0 m |

What this chapter teaches, walked rather than read:

- Evolutionary computation — selection pressure without design
- Growth algorithms — branching, colonization, organic form
- Procedural exploration — caves and mazes from rules
- Geometric construction — sculpting forms from procedures
- Pattern generation — mirrors, rhizomes, cellular textures

### The Seed

> **A world doesn't need an author. Rules and randomness are enough.**

Exercises:

1. Evolutionary computation — selection pressure without design
2. Growth algorithms — branching, colonization, organic form
3. Procedural exploration — caves and mazes from rules
4. Geometric construction — sculpting forms from procedures
5. Pattern generation — mirrors, rhizomes, cellular textures
6. Walk PG_Genetic_Evolution in VR and find where the rule first breaks its own pattern.
7. Open maze_generation in the dressing-room viewer and change one parameter until it stops being itself.

*Next: softbodies*

### The Ledger

- **the dig** — 11 of 12 artifacts excavated; 1 remain at depth.

# Part: Emergence

*QFEP phase: integration — collective intelligence, learning, networks. Systems learn. Cloth deforms. Surfaces are carved and merged. Flocks turn without a leader. Neural networks discover features no human specified. Graphs reveal hidden structure. The parts become more than the sum.*

## Chapter 14: Soft Bodies & Morphogenesis: Matter That Finds Its Shape

> **Form is not imposed  --  it emerges from the material's own dynamics.**

From cloth draping to Turing patterns  --  matter that deforms, bounces, and self-organizes. Starts with soft body physics (jelly, cloth, obstacles), then expands into morphogenesis: how biological form emerges from reaction-diffusion dynamics. Alan Turing's last paper becomes a VR experience.

### The Principal

This chapter's principal is **soft mushroom** — *N StaticBody3D stems topped with SoftBody3D sphere caps pinned at the bottom — each cap's pressure_coefficient and linear_stiffness create a wobbly mushroom that jiggles when touched* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **field**: the artifact IS the environment — to house it would kill it.

### The Primitive

**soft mushroom**

![soft mushroom](/artifact-gallery/captures/soft_mushroom/front.png)

*N StaticBody3D stems topped with SoftBody3D sphere caps pinned at the bottom — each cap's pressure_coefficient and linear_stiffness create a wobbly mushroom that jiggles when touched*

soft_mushroom

> a mushroom cap does not decide its shape — the pin constraint, gravity, and whatever bumps into it negotiate the form in real time

### The Walk — first steps

#### SoftBodies Soft Body Deformation

A shape is only a rest configuration, and the springs keep renegotiating it with whatever arrives.

This chapter asks one question of a deformable body and answers it outward: who decides the form? Here the answer is the material itself. Nothing in this room is being shaped by anything except its own internal tension and the floor.

```gdscript
for s in springs:
    var diff: Vector3 = positions[s.b] - positions[s.a]
    var cur: float = diff.length()
    var pull: Vector3 = diff.normalized() * (cur - s.rest) * stiffness
    velocity[s.a] += pull
    velocity[s.b] -= pull
```

Every spring wants one length and pulls both its ends toward it. No spring knows the shape. There is no shape anywhere in the code, only a rest length repeated a few hundred times, and what you see is the standing disagreement between all of them and gravity.

## The body on its own

**jelly_cube** — `jelly_cube`

A green cube of jelly on a plinth, hanging just under half a metre clear of the floor. Push a hand into it and it gives and comes back. This is the chapter's first claim, and it is worth pressing more than once: the cube has no stored shape to return to. It returns because the springs are still pulling, and the returning is not a memory, it is the same argument continuing.

There is no update loop anywhere in its script. Everything you see moving is the physics solver, working on the mesh, all the time.

**Jelly Cube Variants** — `jelly_variants`

The same cube, five times, in a row two metres long, with fifteen sliders and ten buttons crowded between them. Stiffness, damping, pressure. Turn one and the same object becomes a different material, and the interesting reading is at the ends: soft enough and it stops behaving like a solid and starts behaving like a bag of liquid; stiff enough and it stops deforming at all and is simply a box.

Nothing was swapped to get there. It is one number, and the categories we have names for are regions of it.

## The body under a machine

**softmill** — `softmill`

A stand with two pink bars turning at thirty degrees a second, one revolution every twelve seconds, and a specimen hanging above them. Watch it a while and you will see the bars pass through the specimen without touching it.

That is not a rendering fault. The long arm is on one collision layer and the soft body listens to another, so the two are transparent to each other by arithmetic. The mill is here to be the outside force, the first thing in the chapter that would decide a form from outside the material, and it misses. Take it as the chapter's own timetable: the encounter is two rooms away, and here the body is still alone with itself.

**Science Screen** — `science_screen`

A screen floating with the foot of its stand a metre and a half above the floor, set to draw a field map. It reads nothing in this room and says so: the panel is labelled SOURCE: DEMO, and the field rippling across it is the screen's own test pattern.

**Radiolaria** — `radiolaria`

In the corner, nine glass skeletons that do not belong to this argument yet. They are silicon lattices grown by single-celled organisms, and they are the last room of this chapter standing early in the first one. Look at them and move on; the sentence that makes sense of them needs the rest of the walk.

## Rest is a negotiation

The word for the shape a soft body holds is the rest configuration, and both halves of that are misleading. It is not rest: the springs are pulling the whole time, and the stillness is a balance of pulls rather than an absence of them. And it is not a configuration in the sense of a plan, because nothing anywhere holds a picture of the cube. There is a list of rest lengths and a solver, and the cube is what those two produce when they are left alone together.

Which is why the cube comes back when you push it, and why turning one slider by a tenth turns a solid into a fluid. The form was never a thing the material had. It is a thing the material is doing.

Next: the same body, in a field that will not leave it alone.

*Field notes: Read before written[^softbodies-soft-body-deformation-1] · Open[^softbodies-soft-body-deformation-2]*

[^softbodies-soft-body-deformation-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    **The chapter's arc**, per the fold plan and the arc reader: WHO DECIDES THE
    FORM, answered outward — the material (here), the field it hangs in (Carusell),
    what it meets (Obsticals), what the encounter left behind (Affect_Theory).

    - **The mill may not grind.** `rotating_arm` puts its 3 m bar on collision layer 2
      while `softbody3d` forces the specimen's mask to layer 1, so the only arm long
      enough to reach is invisible to it. The text makes this the chapter's timetable
      rather than hiding it.
    - **Two artifacts float.** Both `science_screen` (y 1.5) and `jelly_cube` (y 0.5)
      carry an explicit y, which cancels auto-grounding: the screen's stand foot ends
      1.5 m up and the jelly plinth has 0.46 m of air beneath it.
    - **The screen reads nothing**: `#mode:field` is delivered and valid, but it hunts
      siblings for `noise_frequency` or `height_scale` and no artifact here declares
      either. Its panel says SOURCE: DEMO.
    - **`jelly_variants` has a scriptless root** and five children each running the
      full jelly_cube `_ready`: five soft bodies, five plinths, 15 sliders and 10
      buttons inside 2.1 m.
    - `jelly_cube` has no `_process` — every motion is the solver.
    - **The exit is buried**: `t` sits on the one void cell, 0.20 m under the floor.
    - **`radiolaria` is here as a stray** and is Affect_Theory's only token. The arc
      reader flagged it: room 7 cannot be the chapter's turn if room 1 shows the same
      thing. The text names it as arriving early rather than pretending otherwise.

[^softbodies-soft-body-deformation-2]: **Open.**
    - The stray radiolaria should probably leave this map so the last room keeps its turn. That is a map edit and a curation call.

#### SoftBodies Carusell

Rotation makes a force field legible through softness: every point of a hanging body reads out a force you could not otherwise see.

You arrive inside the machine. The spawn puts you under four metres from the axis of a carousel three metres across, close enough that the soft bodies sweep past at chest height about half a metre clear of you. Stand still for one revolution, six and a quarter seconds, before you do anything else.

```gdscript
func _physics_process(delta: float) -> void:
    ride_hub.rotation.y += ride_speed * delta
```

That is the entire machine. One rotation applied to one hub, and everything hanging under it works out its own consequences.

## The field, made visible

**revolving_joy_ride** — `revolving_joy_ride`

A torus overhead turning once every six seconds, four arms of chained capsules hanging from it, and four soft spheres half a metre across swinging at the bottom of those arms. Nothing tells the spheres where to go. They are dragged by the arms, the arms are dragged by the joints, and the angle each arm hangs at is the balance of the pull inward and the swing outward at that radius.

A rigid arm would tell you nothing: it would simply be where it was put. The softness is the instrument. The bodies are being deformed by exactly the force at their radius, so their shape is a reading of a field that has no appearance of its own.

Two of the four arms sweep through the room's own wall pillars on every revolution, and the twelve frosted posts ringing the ride stand five metres tall against walls of two, sunk half a metre into the floor. The ride was built for a bigger room than this one.

**cloth_straps** — `cloth_straps`

Ribbons of cloth hanging from gantries, and you can walk through them. This is the gentlest measurement in the room: the cloth reads whatever is moving nearby, including you, and goes on reading it for a second or two after you have passed. A field written on a surface that keeps a short memory of it.

**soft_mushroom** — `soft_mushroom`

Fifteen mushrooms, each a rigid stem with a soft cap pinned to the top of it. Push a cap and it wobbles and settles; the stem does not move at all. One object, two materials, and the join between them is where you can feel the difference: the same push does nothing to one half and everything to the other.

**Flex Cloth Pad** — `flex_cloth_pad`

A small hanging cloth on a pedestal, rebuilt point by point every frame. It sways gently and nothing here disturbs it. Of everything in this room it is the only soft body that is not reading a force from something else, which makes it the control.

## What you can pick up

**grab_long_stick** — `grab_long_stick`

Two rods lying on the floor, and the only things in this room a hand can actually take. Pick one up and you can put a force into the field yourself: swing it through the ribbons, prod a mushroom cap. Everything else here reads forces. This is the one object that makes them.

**Pick Up Cube** — `pick_up_cube`

Three cubes hovering and turning near the west gap. You cannot carry these, despite the name. Walk into one and it is gone with a chirp and the count goes up by one.

**Synthesis Stand** — `synthesis_stand`

And the same cube's family on a plinth: five stocks of one object, ruled a series by measurement, with the far end of the ladder stood up as its representative. A cabinet card in a room full of things in motion.

## Softness as an instrument

A force field is nothing you can look at. It has no surface, no colour and no edge, and the only way to see one is to put something in it that responds and then watch the response.

That is what this whole room is. The carousel does not demonstrate rotation; you could demonstrate rotation with a rigid bar. It demonstrates the field the rotation creates, and it does that by hanging things in the field that cannot help showing it. Every deformation you can see is a measurement, taken by a body that has no choice about taking it.

The chapter's question was who decides the form. In the last hall the material decided alone. Here the field decides, and the material is what makes the decision visible.

Next: what happens when the thing it meets pushes back.

*Field notes: Read before written[^softbodies-carusell-1] · Open[^softbodies-carusell-2]*

[^softbodies-carusell-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **You spawn inside the machine**: 3.80 m from the axis, inside the 4.5 m
      obstacle ring, 0.55 m outside the 2.75-3.25 m sweep of the soft bodies.
    - **The soft bodies never reach the obstacles.** They sweep at 2.75-3.25 m and the
      twelve posts stand at 4.5 m, so the registry's "colliding with obstacles" never
      happens. The text does not claim it does.
    - **Two arms sweep through solid wall pillars** at cells (6,7) and (10,7) on every
      revolution.
    - The posts are 5.0 m against 2.0 m walls, sunk 0.5 m below the floor.
    - **`pick_up_cube` cancels its own grounding**: `_process` writes
      `global_position.y = original_y + bob` from a value cached in `_ready`, before
      the deferred grounding lands.
    - **A utility in the same cell lifts an artifact**: `soft_mushroom` shares (10,12)
      with `sp`, so it is bumped a level.
    - `flex_cloth_pad` rebuilds its mesh and allocates a fresh material every frame.
    - `grab_long_stick` is the only properly grabbable object.
    - **`an:softbodies` is parsed as a rotation** — float of a word is 0.0 —
      overwriting the authored 180-degree yaw.

[^softbodies-carusell-2]: **Open.**
    - The ride was built for a bigger room: 5 m posts, 2 m walls, two arms through pillars every turn. Worth either a bigger hall or a smaller ride.

#### SoftBodies Obsticals

When soft meets hard, collision is not an instant but a negotiation that unfolds over time.

A rigid body's collision is a moment: it arrives, a number is computed, it leaves changed. A soft body has no such moment. It arrives, and then for the next second the news of the arrival travels through it, spring by spring, and what happens at the far side depends on everything in between. This room is twenty metres square and mostly empty so that you can watch that take its time.

```gdscript
if p.y < floor_h:
    positions[i].y = floor_h            # the contact is a constraint, not an impulse
```

The whole of collision, for a soft body, is that: a point that has gone somewhere it should not be is put back, and the springs attached to it spend the following frames arguing about what that means for everyone else.

## The rack

**softbody_gallery_part2** — `softbody_gallery_part2`

The south half of the room is a drop rack, twelve cells of magenta wireframe with soft spheres falling onto them every couple of seconds, six columns of different stiffness. Stand at the end of the row and look along it, because the row is the experiment: the same fall, the same frame, and a different material each time.

The soft ones spread across the wire and take a full second to decide what shape they are. The stiff ones bounce and keep their corners. Somewhere in the middle a sphere lands, holds an obviously wrong shape for a moment, and then remembers. That interval is what the room is about, and it exists only because the material has to pass the news along.

One warning: pressing the jump key reloads this map. The rack listens for it.

**breathing_room** — `breathing_room`

Two grey slabs standing across the north corner, four metres high and seven long, with a five-metre gap between them. They are named for the thing they do not do. The scene loads a version of the script with no update loop in it at all, so there is no breathing, no expansion and no contraction: two walls, still, forever. Its twin slab stands outside the room, behind the north wall.

Take it as the room's honest failure. A corridor whose walls close on you would have been the hard case of this argument, where the negotiation has no way out. What is here instead is the geometry of that idea with the time taken out.

**flagdancer** — `flagdancer`

A rainbow flag rippling along the north wall, its bottom two metres below the floor and two metres of its width inside the wall. It looks like the softest thing in the room and it is the only one with no physics whatsoever: seventeen bones driven by sine waves, no cloth solver, no forces, nothing to collide with. It cannot be touched and it does not respond.

It is worth standing in front of for exactly that reason. It is what soft looks like when it is animated rather than simulated, and next to the rack, which is genuinely negotiating, the difference is visible without being told. One is obeying a curve. The other is working something out.

**Pick Up Cube** — `pick_up_cube`

A black cube in orange wireframe turning and bobbing beside the slabs. Walk into it and it is gone.

**grab_long_stick** — `grab_long_stick`

A rod on the floor by the south wall, and the only object here a hand can take. Carry it into the rack and you become the hard thing in the encounter. That is the room's best use of a minute: hold something rigid, push it into something soft, and watch how long the answer takes to arrive.

## Resistance is morphology

An obstacle does not stop a soft body. It reshapes it, and the shape it leaves is a record of the meeting: where the contact was, how stiff both parties were, how long they were in touch.

That is why the negotiation matters more than the moment. A rigid collision destroys its own evidence, resolving into two new velocities and nothing else. A soft collision leaves the encounter written into the object, for as long as the springs take to argue it away, and sometimes longer.

The chapter has now had three answers to who decides the form. The material alone. The field it hangs in. And here, the thing it runs into. The next answer is the one that outlasts all of them: what happens when the record does not argue itself away, and the encounter stays.

Next: a skeleton that kept the shape of the water it grew in.

*Field notes: Read before written[^softbodies-obsticals-1] · Open[^softbodies-obsticals-2]*

[^softbodies-obsticals-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **The room's centrepiece does not do what it is named for.** `breathing_room`
      loads `breathing_room_scene.gd`, which has no `_process` and no tween; the
      sinusoidal pressure loop lives in a sibling script the scene does not load. Two
      static slabs 4.87 m apart, one of them outside the room behind the north wall.
      The text says so and uses it.
    - **`flagdancer` has no physics at all**: 17 bones on sine waves, no SoftBody3D,
      no cloth solver, no forces, no collider. Its bottom is 2 m below the floor and
      2 m of its width is inside the wall. The text uses it as the animated-versus-
      simulated control.
    - **Pressing the jump key reloads the map** — `softbody_gallery_part2` binds
      `ui_accept` to `reload_current_scene`.
    - The gallery is far bigger than the room: 12 cells, spheres dropping every 2 s,
      six stiffness columns. It is the room's real argument.
    - `pick_up_cube` is walk-into, not grab, despite the registry.
    - `grab_long_stick` is the only graspable object.
    - **The teleporter is in a hole**, y 0.0 in a 3-cell gap.
    - **Auto-ground silently skips three of the five**, because `_compute_local_aabb`
      walks only the root's direct children.

[^softbodies-obsticals-2]: **Open.**
    - breathing_room loading the wrong script is a one-line fix in the .tscn and would give this room its hard case back.

#### SoftBodies Affect Theory Visualization

Softness is the capacity to be affected, and this room is full of the hard record of it.

You arrive standing inside them. There is no door, no case and no plinth: a slab of floor a metre thick, open sky above and on every side, and nine glass skeletons on a grid around you, close enough that the outermost hang over the edge with nothing beneath. Turn on the spot before reading further. That is the exhibit.

```gdscript
for i in 9:
    var kind: int = randi() % 6          # unseeded, re-rolled every load
    build_radiolarian(kind, grid_position(i))
```

**Radiolaria** — `radiolaria`

Radiolaria are single-celled organisms that build lattices of glass around themselves. The mineral is silica, the same as window glass, and the geometry is not decoration: a shell that has to be light enough to stay suspended and strong enough not to implode is a solved problem, and the solution is a lattice with holes in it.

Nine of them here, on a three-by-three grid two and a half metres apart, and they are not the same nine you would have met yesterday. Six body types, chosen at random when the room loads, never seeded, so the exhibit re-rolls itself every visit. Four hundred and fifty motes drift between them.

Walk through one. You can, because none of them has a collider anywhere, and it is the right thing to do in a room about being affected: the objects that made the strongest case in this chapter for responding to contact cannot register that you are there.

## The record and the responding

Everything else in this chapter was soft while you watched. The jelly renegotiated its shape under your hand, the ride's bodies read a field they were swinging through, the rack spent a second passing news of a collision along its springs. Softness was a thing happening.

These are the opposite, and they are the chapter's last word for exactly that reason. A radiolarian skeleton is not soft. It is the hardest thing here, and it is entirely a record of softness: every strut sits where a living membrane pushed the mineral, and every hole is where the membrane did not. The animal was the capacity to be affected. The glass is what that capacity left behind after it stopped.

That is the chapter's question answered a fourth time, and answered past its own frame. The material decides the form. The field it hangs in decides. What it meets decides. And in the end the form is a fossil of all three, still standing after the thing that could respond is gone.

## What is missing here

It is worth saying plainly, because the room does not. This exhibit is described everywhere as a single specimen in a display case. There is no case, there is no specimen, and there are nine. The lighting the map declares is never read, and the light you are standing in arrives with the organisms themselves. The way out is at the bottom of a hole in the floor.

A room about the capacity to be affected, in which nothing can be touched, nothing registers a visitor, and the exhibit is different every time anybody looks. Some of that is a fault. Some of it is the truest thing in the chapter.

Next: pattern that needs no blueprint at all.

*Field notes: Read before written[^softbodies-affect-theory-visualization-1] · Open[^softbodies-affect-theory-visualization-2]*

[^softbodies-affect-theory-visualization-1]: **Read before written.**
    Written 2026-09-02 from an agent's reading of every placed script and scene,
    with a skeptic pass behind it. Nothing in the text predates the sheet.

    - **"A single specimen in a display case" is nine specimens and no case.** The
      map description, blurb, intent, summary, technical and walked all say one.
      `radiolaria.gd` builds a 3x3 grid of nine, six types chosen after an unseeded
      randomize, so the exhibit re-rolls every load. Roughly 7.4 m of bodies on a 7 m
      floor; the outer ones overhang.
    - **You spawn inside it**, about a metre from the nearest body.
    - **No collider of any kind** — you walk through every one.
    - **The artifact brings its own light**: three directional lights and a procedural
      sky arrive with it and overrule the map's lighting block, which nothing reads
      anyway (`get_lighting_settings` has no callers).
    - **The exit is at the bottom of a hole**, `t` on a void cell.
    - `an:softbodies` is parsed as a rotation, so the annotation board never gets its
      sequence name; its trigger is doubly dead besides.
    - 450 particles, 50 per body.

    The text keeps the discrepancy rather than papering over it: a room about the
    capacity to be affected in which nothing registers a visitor.

[^softbodies-affect-theory-visualization-2]: **Open.**
    - This room is one artifact and its own docs describe a different exhibit. Either the case gets built or the docs get rewritten; the text names the gap.

*5 further room(s) in this chapter, not yet written.*

**jelly cube**

![jelly cube](/artifact-gallery/captures/jelly_cube/front.png)

*SoftBody3D with spring-mass physics — stiffness, damping, and pressure_coefficient govern deformation response*

A soft, deformable cube that jiggles when touched. VR-enabled with physics parameter controls for stiffness, damping, and pressure.

> elasticity is not a property of the object — it is a negotiation between the object's internal forces and whatever touches it

**softbody gallery part2**

![softbody gallery part2](/artifact-gallery/captures/softbody_gallery_part2/front.png)

Part 2 of the soft body test gallery.

**softmill**

![softmill](/artifact-gallery/captures/softmill/front.png)

Deformable soft body physics simulation

**revolving joy ride**

![revolving joy ride](/artifact-gallery/captures/revolving_joy_ride/front.png)

*RigidBody3D hub rotating at ride_speed, with PinJoint3D chains suspending SoftBody3D spheres — centripetal force stretches the soft bodies outward while gravity pulls them down*

A rotating ride with hanging soft bodies colliding with obstacles.

> a carousel is a centrifuge for compliance — the soft bodies do not choose their shape, the rotation imposes it

**cloth straps**

![cloth straps](/artifact-gallery/captures/cloth_straps/front.png)

*N parallel SoftBody3D strips pinned to a frame top bar — each strap is a foil-shader cloth that hangs under gravity and collides with player hands*

Hanging soft body cloth straps that the player can walk through.

> a curtain is not a surface — it is an array of constraints negotiating gravity, and parting it reveals that softness is a collective property

### The Walk — further in

**rounded softbody test**

![rounded softbody test](/artifact-gallery/captures/rounded_softbody_test/front.png)

Deformable rounded cube with 3 modes: strain energy heatmap coloring by vertex displacement, collision-response force arrows with impact bursts, and volume preservation with real-time ratio chart. VR hand squeeze interaction pushes vertices. ImmediateMesh overlays for all visualizations.

**softstopscene**

![softstopscene](/artifact-gallery/captures/softstopscene/front.png)

Deformable soft body physics simulation

**flagdancer**

![flagdancer](/artifact-gallery/captures/flagdancer/front.png)

*Skeleton3D with per-bone sine wave displacement — each flag_bone gets xform.origin.z = base_wave + wind_noise, creating cloth-like ripple across a SurfaceTool-built pride flag mesh*

Animated soft body flag that waves and dances using cloth physics simulation with wind forces.

> a flag is not a symbol displayed — it is a material surface negotiating wind, and the pride it carries lives in the physics of its motion

**grab long stick**

![grab long stick](/artifact-gallery/captures/grab_long_stick/front.png)

grab_long_stick

**turing pattern generator**

![turing pattern generator](/artifact-gallery/captures/turing_pattern_generator/front.png)

*CPU Gray-Scott simulation — du/dt = Du*laplacian(u) - u*v^2 + f*(1-u), dv/dt = Dv*laplacian(v) + u*v^2 - (k+f)*v — iterated steps_per_frame times per frame on a 2D grid*

Generate reaction-diffusion Turing patterns in real-time — spots, stripes, and labyrinthine structures emerge from the interplay of activator and inhibitor chemicals diffusing at different rates. Alan Turing's morphogenesis made visible.

> pattern emerges from the ratio of two diffusion rates — not from a template, not from a gene, but from the mathematics of how fast activation outruns inhibition

### The Turn — parameters

Open in the dressing-room viewer: soft mushroom, jelly cube, softbody gallery part2, softmill.

### The Critical Reading

QFEP term: **Integration**

Soft bodies embody F=E oscillation physically  --  elastic forces (F) against deformation (E). Morphogenesis extends this: Turing's reaction-diffusion shows how pattern emerges from the tension between activation and inhibition, the chemical F and E.

The artifacts' own claims:

> a mushroom cap does not decide its shape — the pin constraint, gravity, and whatever bumps into it negotiate the form in real time — *soft mushroom*

> elasticity is not a property of the object — it is a negotiation between the object's internal forces and whatever touches it — *jelly cube*

> a carousel is a centrifuge for compliance — the soft bodies do not choose their shape, the rotation imposes it — *revolving joy ride*

> a curtain is not a surface — it is an array of constraints negotiating gravity, and parting it reveals that softness is a collective property — *cloth straps*

> a flag is not a symbol displayed — it is a material surface negotiating wind, and the pride it carries lives in the physics of its motion — *flagdancer*

> pattern emerges from the ratio of two diffusion rates — not from a template, not from a gene, but from the mathematics of how fast activation outruns inhibition — *turing pattern generator*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| SoftBodies_Soft_Body_Deformation | 8×9 | 3 | 7.1 m |
| SoftBodies_Carusell | 20×20 | 9 | 40.0 m |
| SoftBodies_Obsticals | 20×20 | 7 | 17.9 m |
| SoftBodies_Obsticals_Part2 | 30×11 | 6 | 30.9 m |
| SoftBodies_Cloth_Physics | 6×11 | 1 | 4.0 m |
| SoftBodies_Playground_of_Joy | 12×11 | 3 | 2.8 m |
| SoftBodies_Affect_Theory_Visualization | 7×9 | 1 | 13.0 m |
| ProceduralGeneration_Reaction_Diffusion_Systems | 13×14 | 2 | 1.3 m |
| Topology_Entropy_Morphogenesis | 9×12 | 1 | 5.0 m |
| Chamber_SoftBodies | 11×7 | 6 | 35.1 m |
| SoftBody_sb01_cloth_drape_corners | 12×12 | 1 | 0.0 m |
| SoftBody_sb02_cloth_drape_top_row | 12×12 | 1 | 0.0 m |
| SoftBody_sb03_cloth_flag_sideways | 12×12 | 1 | 0.0 m |
| SoftBody_sb04_cloth_tablecloth | 12×12 | 1 | 0.0 m |
| SoftBody_sb05_jelly_box_bounce | 12×12 | 1 | 0.0 m |
| SoftBody_sb06_jelly_grid_settle | 12×12 | 1 | 0.0 m |
| SoftBody_sb07_jelly_grid_tall_stiff | 12×12 | 1 | 0.0 m |
| SoftBody_sb08_jelly_grid_floppy | 12×12 | 1 | 0.0 m |
| SoftBody_sb_ls01_plant_skeleton | 12×12 | 1 | 0.0 m |
| SoftBody_sb_ls02_plant_wind_collapse | 12×12 | 1 | 0.0 m |
| SoftBody_sb_ca01_conway_cloth | 12×12 | 1 | 0.0 m |
| SoftBody_sb_ca02_life_without_death_cloth | 12×12 | 1 | 0.0 m |
| SoftBody_sb_noise01_jelly_crystal | 12×12 | 1 | 0.0 m |
| SoftBody_sb_rd01_coral_cloth | 12×12 | 1 | 0.0 m |
| SoftBody_sb_rd02_stripes_flag | 12×12 | 1 | 0.0 m |
| SoftBody_gl01_classic_bulb | 12×12 | 1 | 0.0 m |
| SoftBody_gl02_long_bottle | 12×12 | 1 | 0.0 m |
| SoftBody_gl03_wide_bowl | 12×12 | 1 | 0.0 m |
| SoftBody_gl04_lopsided_vase | 12×12 | 1 | 0.0 m |
| SoftBody_gl05_collapsed_sag | 12×12 | 1 | 0.0 m |
| SoftBody_gm01_bottle_in_cylinder_mould | 12×12 | 1 | 0.0 m |
| SoftBody_gm02_vase_in_tapered_mould | 12×12 | 1 | 0.0 m |
| SoftBody_gm03_box_in_cube_mould | 12×12 | 1 | 0.0 m |
| SoftBody_gm04_pressed_onto_sphere | 12×12 | 1 | 0.0 m |

What this chapter teaches, walked rather than read:

- Spring-mass systems as soft body foundation
- Cloth physics  --  constraints on deformable surfaces
- Obstacle interaction with deformable bodies
- Affect and materiality  --  what softness means
- Turing's reaction-diffusion  --  pattern from chemical dynamics
- Morphogenesis  --  entropy becoming structure

### The Seed

> **Form is not imposed  --  it emerges from the material's own dynamics.**

Exercises:

1. Spring-mass systems as soft body foundation
2. Cloth physics  --  constraints on deformable surfaces
3. Obstacle interaction with deformable bodies
4. Affect and materiality  --  what softness means
5. Turing's reaction-diffusion  --  pattern from chemical dynamics
6. Walk SoftBodies_Soft_Body_Deformation in VR and find where the rule first breaks its own pattern.
7. Open soft_mushroom in the dressing-room viewer and change one parameter until it stops being itself.

*Next: isosurfaces*

### The Ledger

- **the dig** — 11 of 20 artifacts excavated; 9 remain at depth.

## Chapter 15: Isosurfaces: Implicit to Explicit

> **Define a field, extract a surface. The boundary between inside and outside becomes geometry.**

`f(x,y,z) = threshold â†’ mesh`

Algorithms that extract surfaces from scalar fields. Marching Cubes walks through voxels finding boundaries. Caves emerge from noise. Landscapes generate portals. The implicit becomes explicit.

### The Principal

This chapter's principal is **mc sculpt vr** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**mc sculpt vr**

![mc sculpt vr](/artifact-gallery/captures/mc_sculpt_vr/front.png)

GPU SDF sculpting — add spherical blobs with smooth union. Up to 500 blobs, real-time mesh extraction.

### The Walk — first steps

*12 room(s) in this chapter; none written yet.*

**mc overhang landscape**

![mc overhang landscape](/artifact-gallery/captures/mc_overhang_landscape/front.png)

GPU overhang terrain — landscape with overhanging rock formations.

**mc torus sculpture**

![mc torus sculpture](/artifact-gallery/captures/mc_torus_sculpture/front.png)

GPU torus sculpture — marching cubes extracting torus isosurface.

**fifteen cases demo**

![fifteen cases demo](/artifact-gallery/captures/fifteen_cases_demo/front.png)

Interactive display of the 15 unique marching cubes cases (from 256 total). Educational — shows how the lookup table works.

**mc cave**

![mc cave](/artifact-gallery/captures/mc_cave/front.png)

GPU cave system — noise-driven marching cubes producing walkable cave geometry.

**fountain demo**

![fountain demo](/artifact-gallery/captures/fountain_demo/front.png)

GPU compute fountain shape — vertical form generated by marching cubes.

### The Walk — further in

**mc shapes gallery**

![mc shapes gallery](/artifact-gallery/captures/mc_shapes_gallery/front.png)

Gallery of multiple marching cubes shapes — sphere, torus, and more displayed side by side.

**mc base**

![mc base](/artifact-gallery/captures/mc_base/front.png)

Base GPU marching cubes scene — the core implementation.

**voxel noise demo**

![voxel noise demo](/artifact-gallery/captures/voxel_noise_demo/front.png)

CPU marching cubes with 3D noise — the working cave/blob generator. Glass shader with wireframe overlay.

**mc flat landscape**

![mc flat landscape](/artifact-gallery/captures/mc_flat_landscape/front.png)

GPU flat terrain — marching cubes landscape with gentle noise.

**GyroidDemo**

![GyroidDemo](/artifact-gallery/captures/GyroidDemo/front.png)

GyroidDemo

### The Turn — parameters

Open in the dressing-room viewer: mc sculpt vr, mc overhang landscape, mc torus sculpture, fifteen cases demo.

### The Critical Reading

QFEP term: **Iâ†’**

Marching algorithms find the edge — the threshold between states. This IS the edge of chaos made geometric: where density crosses zero, form emerges.

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| ISO_Introduction | 14×10 | 2 | 35.1 m |
| ISO_LookupTable | 14×10 | 2 | 8.8 m |
| ISO_ShapesGallery | 14×10 | 3 | 29.1 m |
| ISO_TorusGyroid | 16×14 | 2 | 20.0 m |
| ISO_Sculpting | 14×10 | 2 | 12.5 m |
| ISO_FlatTerrain | 14×10 | 3 | 0.0 m |
| ISO_PortalLandscape | 20×20 | 1 | 0.0 m |
| ISO_Caves | 14×10 | 3 | 19.5 m |
| ISO_CaveGeneration | 13×14 | 2 | 0.0 m |
| ISO_AnimatedNoise | 14×10 | 2 | 1.0 m |
| ISO_Metaballs | 16×14 | 4 | 26.7 m |
| ISO_ImplicitModeling | 16×14 | 1 | 12.0 m |

What this chapter teaches, walked rather than read:

- Implicit surfaces: functions that define inside/outside
- Marching Cubes: the 256-case lookup table
- Gyroid minimal surfaces and triply periodic functions
- Cave generation from 3D noise fields
- Portal landscapes — terrain with marching cubes

### The Seed

> **Define a field, extract a surface. The boundary between inside and outside becomes geometry.**

Exercises:

1. Implicit surfaces: functions that define inside/outside
2. Marching Cubes: the 256-case lookup table
3. Gyroid minimal surfaces and triply periodic functions
4. Cave generation from 3D noise fields
5. Portal landscapes — terrain with marching cubes
6. Walk ISO_Introduction in VR and find where the rule first breaks its own pattern.
7. Open mc_sculpt_vr in the dressing-room viewer and change one parameter until it stops being itself.

*Next: boolean_surfaces*

### The Ledger

- **the dig** — 11 of 25 artifacts excavated; 14 remain at depth.

## Chapter 16: Boolean Surfaces: CSG as Composition

> **Composition is not addition. Boolean ops give us a lawful way to compose solids: A∪B, A∩B, A−B. Every architectural cavity is a difference; every joint is an intersection.**

### The Principal

This chapter's principal is **csg union demo** — *A ∪ B — the union operator. Two CSG primitives (box + sphere) fused into one seamless solid; where they overlap, no seam survives.* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **the measured bed**: the grid's default floor, where a thing rests until it is measured or declared.

### The Primitive

**csg union demo**

![csg union demo](/artifact-gallery/captures/csg_union_demo/front.png)

*A ∪ B — the union operator. Two CSG primitives (box + sphere) fused into one seamless solid; where they overlap, no seam survives.*

Two CSG primitives combined with the union operator. Visualizes A union B as a single composite solid.

> Union is the generous operator. It keeps everything either shape claims.

### The Walk — first steps

*4 room(s) in this chapter; none written yet.*

**csg intersection demo**

![csg intersection demo](/artifact-gallery/captures/csg_intersection_demo/front.png)

*A ∩ B — the intersection operator. Only the volume present in BOTH primitives survives; the result is a lens where the two shapes agree.*

Two CSG primitives with intersection operator. Only the overlap survives.

> Intersection is the shape of consensus. What both shapes agree on is always less than either alone.

**csg difference demo**

![csg difference demo](/artifact-gallery/captures/csg_difference_demo/front.png)

*A − B — the difference operator. A solid box minus an invisible sphere; only the sphere's negative space survives, biting a cavity into the box.*

A box with a sphere subtracted. The operator that makes cavities and openings.

> To make a room, subtract a void from a solid. Architecture is difference.

**csg compose workbench**

![csg compose workbench](/artifact-gallery/captures/csg_compose_workbench/front.png)

*A workbench holding all three CSG operators side by side — union, intersection, difference — applied to the same box+sphere pair, each labeled by symbol.*

Workbench holding all three CSG operators side by side. The introduction artifact for the csg-compose catalyst affordance.

> Three operators, one algebra. Composition is a choice — keep all, keep the shared, or take away.

**csg architecture cavity**

![csg architecture cavity](/artifact-gallery/captures/csg_architecture_cavity/front.png)

*A thick wall with three openings — doorway, circular porthole, arched window — each a CSG subtraction from the same solid. Architecture as Boolean difference.*

A solid wall with three openings cut through it. Architecture as Boolean composition.

> Every architectural cavity is a difference. A room is a wall that has been subtracted from.

### The Walk — further in

### The Turn — parameters

Open in the dressing-room viewer: csg union demo, csg intersection demo, csg difference demo, csg compose workbench.

### The Critical Reading

QFEP term: **F**

Boolean operations are the smallest non-trivial calculus on solids. Pure F: deterministic composition without entropy term. Architectural cavity = difference; joint = intersection.

The artifacts' own claims:

> Union is the generous operator. It keeps everything either shape claims. — *csg union demo*

> Intersection is the shape of consensus. What both shapes agree on is always less than either alone. — *csg intersection demo*

> To make a room, subtract a void from a solid. Architecture is difference. — *csg difference demo*

> Three operators, one algebra. Composition is a choice — keep all, keep the shared, or take away. — *csg compose workbench*

> Every architectural cavity is a difference. A room is a wall that has been subtracted from. — *csg architecture cavity*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Boolean_Union | 10×10 | 1 | 0.0 m |
| Boolean_Intersection | 10×10 | 1 | 0.0 m |
| Boolean_Difference | 10×10 | 1 | 0.0 m |
| Boolean_Compose_Workbench | 10×10 | 1 | 0.0 m |
| Boolean_Architecture_Cavity | 10×10 | 1 | 0.0 m |

What this chapter teaches, walked rather than read:

- Union: A∪B as filled volume
- Intersection: A∩B as shared volume
- Difference: A−B as carved volume
- Order matters: (A−B)−C ≠ A−(B−C) in general
- CSG trees as expressions
- Boolean composition vs. mesh assembly

### The Seed

> **Composition is not addition. Boolean ops give us a lawful way to compose solids: A∪B, A∩B, A−B. Every architectural cavity is a difference; every joint is an intersection.**

Exercises:

1. Union: A∪B as filled volume
2. Intersection: A∩B as shared volume
3. Difference: A−B as carved volume
4. Order matters: (A−B)−C ≠ A−(B−C) in general
5. CSG trees as expressions
6. Walk Boolean_Union in VR and find where the rule first breaks its own pattern.
7. Open csg_union_demo in the dressing-room viewer and change one parameter until it stops being itself.

*Next: swarmintelligence*

### The Ledger

- **the dig** — 5 of 5 artifacts excavated; this stratum is fully exposed.

## Chapter 17: Swarm Intelligence: No Leader, Yet Coordinated

> **No leader, yet coordinated. Stigmergy: the environment is the message. Local rules produce global intelligence.**

`Agent_i = Î£ local_rules(neighbors_i)`

Collective behavior and distributed intelligence. Individual agents follow simple local rules, yet global coordination emerges. This is queer intelligence—non-hierarchical, decentralized, resistant to single points of failure.

### The Principal

This chapter's principal is **PhysarumColony** — *trail(x,y) = deposit(agent_positions) * diffuse - evaporate — no neurons, no memory, just chemistry* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **field**: the artifact IS the environment — to house it would kill it.

### The Primitive

**PhysarumColony**

![PhysarumColony](/artifact-gallery/captures/PhysarumColony/front.png)

*trail(x,y) = deposit(agent_positions) * diffuse - evaporate — no neurons, no memory, just chemistry*

trail(x,y) = deposit(agent_positions) * diffuse - evaporate — no neurons, no memory, just chemistry

> intelligence is a property of the medium, not the agent — the slime mold's network is smarter than any individual cell

### The Walk — first steps

*7 room(s) in this chapter; none written yet.*

**boids aquarium**

![boids aquarium](/artifact-gallery/captures/boids_aquarium/front.png)

**ant colony optimization**

![ant colony optimization](/artifact-gallery/captures/ant_colony_optimization/front.png)

Ant colony optimization with pheromone evaporation gradient heatmap, multi-source quality-weighted foraging, tandem running communication, and 3 modes (Colony/Communication/Multi-Source).

**self organizing patterns**

![self organizing patterns](/artifact-gallery/captures/self_organizing_patterns/front.png)

*three modes — stigmergy (deposit/evaporate field), Ising phase transition (spin flip via Metropolis), attractor basins (gradient descent on potential landscape)*

Stigmergy, phase transitions, and attractor basin visualization — 3 modes: stigmergy field with deposit/evaporation heatmap, Ising-like phase transition with order parameter sweep, Voronoi-colored attractor basins with flow field arrows

> order is not imposed from outside — it falls into existence when local interactions exceed the noise floor

**FlowFieldMain**

![FlowFieldMain](/artifact-gallery/captures/FlowFieldMain/front.png)

*v_i(t+1) = field[grid(pos_i)] — each agent reads one arrow and moves; the entire "decision" is a lookup*

v_i(t+1) = field[grid(pos_i)] — each agent reads one arrow and moves; the entire "decision" is a lookup

> purpose is not inside the agent — it lives in the field the agent inhabits

**AntColonyV2**

![AntColonyV2](/artifact-gallery/captures/AntColonyV2/front.png)

*ant.move() = gradient_ascent(pheromone_grid) + wander; pheromone_grid *= decay + diffuse — ant and environment co-evolve*

ant.move() = gradient_ascent(pheromone_grid) + wander; pheromone_grid *= decay + diffuse — ant and environment co-evolve

> the map is written by the travelers — the territory and the route emerge together

### The Walk — further in

**boid manager**

![boid manager](/artifact-gallery/captures/boid_manager/front.png)

*f_i = Σ(neighbor_j)[separate(i,j) + align(vel_j) + cohere(pos_j)] — three weighted averages over a local neighborhood*

f_i = Σ(neighbor_j)[separate(i,j) + align(vel_j) + cohere(pos_j)] — three weighted averages over a local neighborhood

> coordination is not agreement — it is geometry; close enough means you are already the same

**boids 2d in 3d**

![boids 2d in 3d](/artifact-gallery/captures/boids_2d_in_3d/front.png)

boids_2d_in_3d

### The Turn — parameters

Watch boids flock without a leader. See ants find shortest paths through pheromone trails. Observe particles converge on optima through collective memory.

Open in the dressing-room viewer: PhysarumColony, ant colony optimization, self organizing patterns, FlowFieldMain.

### The Critical Reading

QFEP term: **Î»**

Swarm systems operate at the edge of chaos—the λ parameter that modulates between order and entropy. φΔE(S,t) manifests as collective adaptive capacity: the swarm's rate of entropy change determines its survival.

The artifacts' own claims:

> intelligence is a property of the medium, not the agent — the slime mold's network is smarter than any individual cell — *PhysarumColony*

> order is not imposed from outside — it falls into existence when local interactions exceed the noise floor — *self organizing patterns*

> purpose is not inside the agent — it lives in the field the agent inhabits — *FlowFieldMain*

> the map is written by the travelers — the territory and the route emerge together — *AntColonyV2*

> coordination is not agreement — it is geometry; close enough means you are already the same — *boid manager*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| SwarmIntelligence_PhysarumColony | 9×9 | 2 | 53.1 m |
| SwarmIntelligence_FlowFields | 10×8 | 1 | 50.0 m |
| SwarmIntelligence_Boids_Algorithm | 11×11 | 5 | 27.4 m |
| SwarmIntelligence_Agent_Based_Modeling_ABM | 8×8 | 1 | 0.3 m |
| SwarmIntelligence_Ant_Colony_Optimization | 10×7 | 1 | 50.0 m |
| SwarmIntelligence_Particle_Swarm_Optimization | 9×9 | 2 | 4.1 m |
| SwarmIntelligence_Swarm_Intelligence_Algorithms | 10×10 | 1 | 0.0 m |

What this chapter teaches, walked rather than read:

- Collective behavior from local rules: no central controller needed
- Stigmergy: indirect communication through environment modification
- Separation, alignment, cohesion: the three rules of Boids
- Ant Colony Optimization: pheromone-based pathfinding
- Particle Swarm Optimization: collective memory finds optima
- Agent-based modeling: simulating societies from individuals

### The Seed

> **No leader, yet coordinated. Stigmergy: the environment is the message. Local rules produce global intelligence.**

Exercises:

1. Collective behavior from local rules: no central controller needed
2. Stigmergy: indirect communication through environment modification
3. Separation, alignment, cohesion: the three rules of Boids
4. Ant Colony Optimization: pheromone-based pathfinding
5. Particle Swarm Optimization: collective memory finds optima
6. Walk SwarmIntelligence_PhysarumColony in VR and find where the rule first breaks its own pattern.
7. Open PhysarumColony in the dressing-room viewer and change one parameter until it stops being itself.

*Next: machinelearning*

### The Ledger

- **the dig** — 8 of 11 artifacts excavated; 3 remain at depth.

## Chapter 18: Machine Learning: Algorithms That Learn

> **Learning is optimization in a landscape you can't fully see.**

From evolving creatures to neural networks — algorithms that adapt. Three arcs: evolution (selection pressure shapes form), perception (learning to classify and compress), generation (machines that make new things).

### The Principal

This chapter's principal is **9 3 smart rockets vr** — *fitness(x) = 1/d(x, target)^2; DNA = [thrust_vectors]; select → crossover → mutate* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **the measured bed**: the grid's default floor, where a thing rests until it is measured or declared.

### The Primitive

**9 3 smart rockets vr**

*fitness(x) = 1/d(x, target)^2; DNA = [thrust_vectors]; select → crossover → mutate*

Rockets evolving to reach a target through genetic algorithm — selection, crossover, mutation visible in real-time. Based on Nature of Code Ch.9.

> selection pressure alone, without any gradient, discovers solutions in spaces too vast to search

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

**evolved creatures**

Physics-based creature evolution inspired by Karl Sims — bipedal bodies evolve locomotion through genetic algorithms. Morphology and behavior co-evolve, producing creatures that learn to walk through selection pressure.

**gradient descent visualization**

*θ(t+1) = θ(t) - η∇f(θ) — follow the negative gradient downhill; four variants racing on the same surface*

Gradient descent optimization on a loss landscape — watch the optimizer slide downhill following the steepest direction. The engine behind all neural network training, with learning rate and momentum visible.

> learning is descending a landscape you cannot fully see — the gradient is the only local truth available

**non teleological evolution**

*evolution without purpose — bodies persisting through drift alone*

Bodies exist in a space with no fitness function. They reproduce based on proximity and energy (gained by exploring, lost by existing). Forms diversify without goal or optimization — just drift, variation, and persistence. No best creature. No progress narrative.

> there is no ladder of progress — only a bush of persistence

**loss function comparator**

*three landscapes from one dataset — the loss function is the author*

Same dataset, three different loss functions applied simultaneously. MSE (smooth bowl), Huber (outlier-robust), and adversarial (deceptive valleys). Gradient descent balls roll on each surface, arriving at different answers. The landscape is not given — it is authored.

> the landscape is not given — it is authored

**evolvingflowers**

*genome = {petals, color_hue, symmetry, L-system_rules, branch_angle}; fitness = symmetry + vibrancy + complexity*

genome = {petals, color_hue, symmetry, L-system_rules, branch_angle}; fitness = symmetry + vibrancy + complexity

> beauty is what survives selection — aesthetics can be an emergent property of optimization

### The Walk — further in

**enhanced kmeans**

*assign each point to nearest centroid; move centroids to cluster means; repeat until convergence*

Interactive K-means clustering visualization with adjustable k, colored cluster assignments, and centroid movement animation.

> clustering does not discover structure in data — it imposes structure by choosing K

**neural network visualization**

*a(l) = σ(W(l)·a(l-1) + b(l)); ∂L/∂W = δ·a(T); backpropagation through layers*

Layered neural network with visible activations, weights as line thickness, forward pass animation. See how information transforms through layers.

> a neural network does not learn rules — it learns a continuous function that happens to approximate them

**9 5 evolving bloops vr**

*energy(t+1) = energy(t) - metabolism(gene) + food; reproduce when energy > threshold*

Organisms evolving size, speed, and behavior through natural selection pressure. Survival of the fittest visualized. Based on Nature of Code Ch.9.

> a single gene controlling a trade-off is enough for an entire ecology to self-organize

**pca visualization**

*X_centered → covariance → eigenvectors → project onto top-k components; maximize preserved variance*

Principal Component Analysis — high-dimensional data projected onto principal axes. Shows variance capture and dimensionality reduction in 3D.

> PCA reveals that high-dimensional data is a conspiracy of a few directions pretending to be many

**neural networks vr**

*layers of neurons connected by weighted edges; forward pass propagates signal, backward pass propagates error*

Walkable neural network with visible weights and backpropagation

> a neural network is not a brain — it is a differentiable function that learns by following its own error gradient

### The Turn — parameters

Open in the dressing-room viewer: evolved creatures, gradient descent visualization, non teleological evolution, loss function comparator.

### The Critical Reading

QFEP term: **Integration**

ML systems navigate Fâ†”E by descending loss landscapes. Gradient descent IS the oscillation between order (model) and entropy (data). Overfitting is F-collapse; underfitting is E-dominance.

The artifacts' own claims:

> selection pressure alone, without any gradient, discovers solutions in spaces too vast to search — *9 3 smart rockets vr*

> learning is descending a landscape you cannot fully see — the gradient is the only local truth available — *gradient descent visualization*

> there is no ladder of progress — only a bush of persistence — *non teleological evolution*

> the landscape is not given — it is authored — *loss function comparator*

> beauty is what survives selection — aesthetics can be an emergent property of optimization — *evolvingflowers*

> clustering does not discover structure in data — it imposes structure by choosing K — *enhanced kmeans*

> a neural network does not learn rules — it learns a continuous function that happens to approximate them — *neural network visualization*

> a single gene controlling a trade-off is enough for an entire ecology to self-organize — *9 5 evolving bloops vr*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| ML_Evolution | 12×10 | 7 | 65.9 m |
| ML_Gradient_Landscape | 9×10 | 3 | 14.0 m |
| ML_Classification | 10×8 | 3 | 80.0 m |
| ML_Neural_Networks | 5×14 | 3 | 56.8 m |
| ML_Perception | 8×8 | 2 | 75.6 m |
| ML_Sequence_Memory | 4×12 | 2 | 24.9 m |
| ML_Generative | 8×8 | 1 | 18.0 m |
| ML_Synthesis | 10×10 | 3 | 44.7 m |

What this chapter teaches, walked rather than read:

- Evolution as optimization without gradient
- Gradient descent as landscape navigation
- Clustering as unsupervised pattern finding
- Neural networks as layered feature extraction
- Generative models as learned distributions
- The gap between model and reality

### The Seed

> **Learning is optimization in a landscape you can't fully see.**

Exercises:

1. Evolution as optimization without gradient
2. Gradient descent as landscape navigation
3. Clustering as unsupervised pattern finding
4. Neural networks as layered feature extraction
5. Generative models as learned distributions
6. Walk ML_Evolution in VR and find where the rule first breaks its own pattern.
7. Open 9_3_smart_rockets_vr in the dressing-room viewer and change one parameter until it stops being itself.

*Next: graphtheory*

### The Ledger

- **the dig** — 11 of 22 artifacts excavated; 11 remain at depth.

## Chapter 19: Graph Theory: Connections Define Structure

> **Everything is a graph if you squint hard enough.**

Nodes and edges — the mathematics of connection. From Königsberg bridges to network flow, graph theory asks: what can you reach, what's connected, and what's the best path? Each map combines related algorithms into one explorable space.

### The Principal

This chapter's principal is **graphspace** — *force-directed graph layout — repulsion F_rep = k/d^2, spring attraction F_spring = stretch * stiffness, iterated layout_iters times to position node_count rooms connected by weighted edges* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**graphspace**

*force-directed graph layout — repulsion F_rep = k/d^2, spring attraction F_spring = stretch * stiffness, iterated layout_iters times to position node_count rooms connected by weighted edges*

Walk a graph instead of looking at one on paper. Rooms behave as nodes, bridges behave as edges, and a force-directed layout spreads the network until its tensions settle into a navigable form. Dijkstra-based lighting then turns graph distance into atmosphere, so structural centrality is felt as you move. It introduces graph theory as relation made spatial and prepares the sequence's traversal, flow, and connectivity problems.

> a graph is not a diagram — it is a set of relationships, and force-directed layout reveals that structure has a natural shape if you let physics find it

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

**KonigsbergBridge**

*Euler's bridge problem embedded in a 3D river city - four landmasses become vertices, seven arched bridges become edges, and degree parity determines whether a walk can cross each bridge exactly once*

Cross the historical city where graph theory was born. Four landmasses and seven bridges stage Euler's question, while degree labels and theorem panels show why no route can traverse every bridge exactly once. The artifact turns parity into something you can see and physically test, making impossibility a property of structure rather than player failure. It anchors the sequence by showing that topology can answer a question before search even begins.

> graph theory begins when you stop asking "which route should I try?" and ask "what does the structure allow at all?"

**pathfinding3d**

*A* on a 3D voxel grid — f(n) = g(n) + h(n), with pluggable heuristics (Manhattan, Euclidean, Chebyshev) and movement models (ground, flying, swimming, climbing)*

Search a voxel maze as if every cube were a graph vertex. The visualization steps A*, Dijkstra, JPS, or flow-field variants through open and closed sets, letting the heuristic shape the visible wavefront. Different heuristics bias the frontier differently, so the artifact makes prediction and optimality visible in space. It turns pathfinding into graph search you can inspect instead of a black box.

> pathfinding does not move through space — it moves through a graph that happens to be embedded in space, and the heuristic is the algorithm's guess about geometry

**force directed layout**

Watch a tangled graph draw itself. Springs pull linked nodes together while repulsion pushes every pair apart, and the network settles into a readable equilibrium. Node size and indicators make local stress visible, so clusters, bridges, and peripheral nodes appear as energy redistributes. It demonstrates how a legible diagram can emerge from nothing but force balance.

**rhizomatic structure**

*recursive branching with lateral reconnection — each new node grows from a random parent with direction = lerp(random, away_from_center, 1 - growth_direction_randomness), then probabilistically connects to nearby existing nodes*

Grow a network that refuses root, trunk, and leaves. Recursive branching creates a scaffold, then lateral reconnections turn that scaffold into a mesh where any point can connect to any other. Adjusting reconnection probability moves the artifact between tree and rhizome, making hierarchy versus multiplicity a concrete topological choice. It brings Deleuze and Guattari into graph theory by questioning when a tree is the wrong model.

> a rhizome has no beginning and no end — only middles, and every connection is as legitimate as every other

**kosaraju algorithm**

*two-pass DFS — first pass on original graph records finish_times; second pass on transpose_adjacency_list processes vertices in reverse finish order, each new DFS tree is an SCC*

Watch the same directed graph answer twice. The first DFS records finishing order, the transpose flips every edge, and the second DFS reveals the strongly connected components that survive reversal. Phase labels and colored passes make the graph's symmetry under transposition visible rather than abstract. It pairs with Tarjan by solving the same problem through a more overt two-pass narrative.

> Kosaraju's algorithm proves that strongly connected components are the same in a graph and its transpose — mutual reachability is a symmetric property of directed structure

### The Walk — further in

**tarjan algorithm**

*single-pass DFS with a stack — each vertex gets discovery_time and low_link; low_link[v] = min(low_link[v], discovery_time[w]) for back edges; when low_link[v] == discovery_time[v], pop the stack to extract an SCC*

Follow a single depth-first pass as it discovers strongly connected components. Discovery times, low-link values, and the stack make cycles visible as pockets of mutual reachability that pop out in reverse traversal order. Back edges show exactly where a directed graph folds back on itself, and each component flashes into view when its root condition is met. It teaches SCCs as something you can watch emerge, not just compute.

> a strongly connected component is a pocket of mutual reachability — every vertex can reach every other, and Tarjan's genius was finding them all in a single depth-first pass

**mst visualization**

*Kruskal's (sort edges by weight, Union-Find to reject cycles) or Prim's (grow tree from starting vertex, always add cheapest crossing edge) — both find the minimum-weight spanning tree*

Assemble the cheapest skeleton that still keeps the whole graph connected. Kruskal and Prim expose two greedy viewpoints on the same optimization problem: one ranks edges globally, the other grows a tree locally from a root. Accepted edges glow green, rejected cycle-forming edges glow red, and the redundant structure of the full graph becomes legible through what must be left out. The artifact makes efficiency feel like subtraction.

> the minimum spanning tree is the cheapest way to keep everyone connected — every edge in it is necessary, and removing any one disconnects the network

**networkflow3d**

*Edmonds-Karp max flow via BFS augmenting paths on a 3D spatial network — residual_capacity tracks remaining edge capacity, particles visualize flow along saturated edges*

Send flow through a spatial network of pipes. Edmonds-Karp repeatedly finds augmenting paths, particles reveal current flow, and pressure coloring exposes the nodes where capacity is constrained. Elevation penalties make the geometry matter without changing the underlying theorem: max flow is limited by the narrowest cut. It sets up the flow sequence by making bottlenecks visible.

> maximum flow through a network equals the minimum cut that separates source from sink — every bottleneck is simultaneously a capacity and a vulnerability

**network analysis**

Read a network as hierarchy, community, and circulation at once. Central nodes orbit slowly and glow more intensely, peripheral nodes move faster at the edges, and pulsing links with particles stage the network as a living system. The visualization turns centrality, clustering, and community structure into spatial rhythm rather than numbers alone. It complements the explicit flow algorithms by building intuition for why some nodes matter more than others.

**karger algorithm**

*randomized edge contraction — repeatedly merge endpoints of a random edge (Union-Find) until 2 super-vertices remain; the crossing edges are a cut; P(finding min-cut) >= 2/(n*(n-1))*

Randomized algorithm for finding minimum cut in undirected graphs

> Karger's algorithm is a bet that randomness repeated enough times becomes certainty — the min-cut is always there, you just need enough attempts to stumble onto it

### The Turn — parameters

Open in the dressing-room viewer: graphspace, KonigsbergBridge, pathfinding3d, force directed layout.

### The Critical Reading

QFEP term: **Integration**

Graphs are pure relation — nodes are identity, edges are connection. The F-term lives in structure (spanning trees, shortest paths); the E-term in randomness (random graphs, percolation). Flow algorithms optimize the F↔E boundary.

The artifacts' own claims:

> a graph is not a diagram — it is a set of relationships, and force-directed layout reveals that structure has a natural shape if you let physics find it — *graphspace*

> graph theory begins when you stop asking "which route should I try?" and ask "what does the structure allow at all?" — *KonigsbergBridge*

> pathfinding does not move through space — it moves through a graph that happens to be embedded in space, and the heuristic is the algorithm's guess about geometry — *pathfinding3d*

> a rhizome has no beginning and no end — only middles, and every connection is as legitimate as every other — *rhizomatic structure*

> Kosaraju's algorithm proves that strongly connected components are the same in a graph and its transpose — mutual reachability is a symmetric property of directed structure — *kosaraju algorithm*

> a strongly connected component is a pocket of mutual reachability — every vertex can reach every other, and Tarjan's genius was finding them all in a single depth-first pass — *tarjan algorithm*

> the minimum spanning tree is the cheapest way to keep everyone connected — every edge in it is necessary, and removing any one disconnects the network — *mst visualization*

> maximum flow through a network equals the minimum cut that separates source from sink — every bottleneck is simultaneously a capacity and a vulnerability — *networkflow3d*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| GT_Foundations | 10×10 | 2 | 50.0 m |
| GT_Layout | 9×9 | 1 | 16.9 m |
| GT_Pathfinding | 7×12 | 1 | 9.9 m |
| GT_Network_Analysis | 11×11 | 3 | 68.2 m |
| GT_Connectivity | 12×8 | 3 | 14.5 m |
| GT_Spanning_Trees | 9×9 | 1 | 35.0 m |
| GT_Flow | 10×10 | 2 | 5.2 m |
| GT_Matching | 8×8 | 1 | 6.4 m |

What this chapter teaches, walked rather than read:

- Graphs as abstract representations of relationship
- Force-directed layout as physics applied to structure
- Pathfinding and traversal strategies
- Connectivity — strongly connected components
- Optimization on graphs — spanning trees, flow, matching

### The Seed

> **Everything is a graph if you squint hard enough.**

Exercises:

1. Graphs as abstract representations of relationship
2. Force-directed layout as physics applied to structure
3. Pathfinding and traversal strategies
4. Connectivity — strongly connected components
5. Optimization on graphs — spanning trees, flow, matching
6. Walk GT_Foundations in VR and find where the rule first breaks its own pattern.
7. Open graphspace in the dressing-room viewer and change one parameter until it stops being itself.

*Next: foundationscrisis*

### The Ledger

- **the dig** — 11 of 14 artifacts excavated; 3 remain at depth.

# Part: Synthesis

*QFEP phase: synthesis — the formula revealed, the limits embraced, computation queered. Gödel proved pure order is impossible. Escher drew it. Brouwer rejected excluded middle. The QFEP Laboratory lets you tune λ and φ with your own hands. And then: whose entropy counts? Algorithms are political.*

## Chapter 20: Foundations Crisis: The Limits of Formalization

> **Every formal system has an outside. Complete order is impossible.**

`âˆƒ statement S: S is true AND S is unprovable`

The 19th-20th century crisis that shattered mathematical certainty. Non-Euclidean geometry, Russell's paradox, Gödel's incompleteness, Brouwer's intuitionism. Each map stages a limit—where formal systems encounter their outside.

### The Principal

This chapter's principal is **parallel lines** — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **plinth**: small, raised to the eye on a dark column.

### The Primitive

**parallel lines**

![parallel lines](/artifact-gallery/captures/parallel_lines/front.png)

Three line modules arranged in parallel to visualize equidistant lines.

### The Walk — first steps

#### Euclid Parallel

Click the plaque five times and you arrive back at the first postulate. The counter wraps:

```gdscript
# euclid_postulates_plaque.gd:202
func next_postulate():
	current_postulate = (current_postulate + 1) % 5
```

Five clicks, five postulates, one closed loop. Four of them fit on two short lines. The fifth needs four lines and a parenthesis. That is the whole principle, and you can repeat it after one walk: this space is flat because the room says so, not because anyone measured it.

## 1 — The five, stored as text

**euclid_postulates_plaque** — `euclid_postulates_plaque`

<!-- ~tutorial#p2 ~tutorial#p4 ~critical#the-rule-that-could-not-be-proven -->

Let's start where the build starts. The tutorial keeps the five postulates as strings in a constant array — text, not logic, so a plinth can show them without a parser. The shipped plaque makes the same choice, and bakes its own line breaks in:

```gdscript
# euclid_postulates_plaque.gd:46
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
```

Read those two as sentences. The fourth states an equality and stops. The fifth carries a condition, a threshold, a prediction — and then names itself.

The difference is not length. The first four hand you permissions: what a hand with a straightedge may do. The fifth tells you what will happen once your hand has done it. It is a rule shaped like a forecast, and a forecast asks to be checked. Twenty-three centuries of checking failed, and the failure was read as a gap in the mathematicians.

Fair — and let's say what the array does about it. The fifth is the only entry carrying a blank line inside itself.

It uses that blank line to introduce itself. Nothing else on the plaque has to.

## 2 — Marked before anyone argues

**euclid_postulates_plaque** — `euclid_postulates_plaque`

<!-- ~tutorial#p10 ~tutorial#p11 ~critical#performativity-of-the-obvious -->

Before you have read a word, the room has told you which postulate matters. The gold arrives ahead of the argument.

It does, and we can point at the line that does it. The tutorial tints the fifth plinth and scales it by 1.2; the shipped plaque runs the same move as a branch:

```gdscript
# euclid_postulates_plaque.gd:121
	var is_fifth = current_postulate == 4
	var title_color: Color
	var text_color: Color
	if is_fifth and highlight_fifth:
		title_color = Color(1.0, 0.7, 0.3)
		text_color = Color(1.0, 0.9, 0.7)
```

Two conditions, not one. The same pair guards the announcement further down: `parallel_highlighted.emit()` sits inside `if is_fifth and highlight_fifth:` at line 163. Colour and signal come out of one branch.

Repetition is how obviousness gets made — every grid, every Cartesian axis, every drawn pair of parallels performs the fifth postulate again. Here the performance is one branch, repeated on every click. You are asked to follow the gold, and following feels like noticing.

So let's break the branch. `highlight_fifth` is an exported bool. Set it false and the fifth reads in the same warm grey as the rest, and `parallel_highlighted` never fires — the branch that shouted was the branch that coloured. `postulate_selected` still emits at index four, the way it does at every other. Cycle again and ask whether the fifth still feels like the odd one.

## 3 — Three lines that never meet

**parallel_lines** — `parallel_lines`

<!-- ~tutorial#p13 ~tutorial#p14 ~artifacts#parallel-lines ~critical#the-state-of-exception -->

The tutorial draws five lines at `y := -2.0 + i * 1.0` — even spacing, one unit apart, a picture in which Euclid's claim looks like a property of the world. The shipped scene has three, placed by hand:

```gdscript
# parallel_lines.tscn:7
[node name="Line1" parent="." instance=ExtResource("1_line")]
transform = Transform3D(0.258819, 0, 0.965926, 0.965926, 0, -0.258819, 0, 1, 0, -0.0648265, 0, 0)
```

Let's count the gaps. Line2 sits at 0.204004, Line3 at 0.305252. The first gap is about 0.27, the second about 0.10. The registry calls this artifact three line modules arranged to visualize equidistant lines. The transforms are not equidistant.

The parallelism survives. All three share a basis, so they run forever without meeting, whatever the spacing. Equidistance is a consequence the fifth postulate guarantees, and it is the part the declaration asserted instead of building. The word carried what the numbers did not.

Try it yourself: move Line3's offset out to 0.4 and count the gaps again. They change, and the lines still never meet. Spacing you can set by hand; parallelism comes from the shared basis.

And nothing in the room says the word out loud: the scene's `Label3D` ships with `visible = false`.

So you supply it. You look at three lines, name them parallel, and the naming arrives as sight.

## 4 — The triangle that says sixty

**angle_sum_triangle** — `angle_sum_triangle`

<!-- ~summary#p3 ~blurb#p3 ~critical#what-the-axiom-conceals -->

The triangle's three corners are literals — apex at `size * 0.5`, base corners at `-size * 0.4` and `size * 0.4`. Then we hand the labels their text:

```gdscript
# angle_sum_triangle.gd:151
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
```

The shape those vertices make is isoceles, not equilateral. The file records its own measured corners: 53.1, 63.4, 63.4. Both triples sum to 180. The three sixties are shipped bytes, handed back rather than measured.

So the sum is true and the parts are ornament. Three equal numbers describe a triangle you are not looking at. It is the plaque's move again in another material: one surface makes unlike things look alike — five postulates in a single row, three identical angles under one figure. What gets hidden is not a falsehood. It is a difference.

The file already knows better, in a function just above. `_angles()` reads each corner off the polyline it actually drew, and at any curved opening the labels print what was measured. At `flat` it prints the shipped strings, because three placements ship them.

Keeping three maps byte-identical is a reason to print sixty. It is a reason about shipping, not about triangles. The geometry never asked for it.

## 5 — The setting you cannot reach from here

**angle_sum_triangle** — `angle_sum_triangle`

<!-- ~tutorial#p16 ~tutorial#p17 ~critical#performativity-of-the-obvious -->

Let's measure how far the other spaces sit from this floor. The tutorial toggles the fifth and a second preview fractures. The shipped artifact has a real axis:

```gdscript
# angle_sum_triangle.gd:49
@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
```

Map tokens reach it only through one gate:

```gdscript
# angle_sum_triangle.gd:203
	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
```

Every placement here ships the bare token, so that `has("opening")` is never true and `_polyline()` short-circuits past the arc loop. What happens if a placement hands it `opening=elliptic`? The edges bow outward at six percent of each chord, the corners open, and the printed sum climbs near 260. Hyperbolic falls near 100. Both are legal geometries. Try the token and watch the equation stay true while the number stops being 180.

So the other two spaces are already here, priced in degrees, one word away — and no move a body makes on this floor arrives at them. What a body can reach is the whole question. A geometry that ships in the file and waits on a placement is not absent; it is held back. The room offers one space and lets the absence of the others do the arguing.

## 6 — A screen with nothing to flatten

**Science Screen** — `science_screen`

<!-- ~artifacts#science-screen ~summary#p2 ~critical#the-state-of-exception -->

The screen scans eight metres for neighbours that answer `get_grid_data()` and paints their cells at 768 by 576. Neither script here defines that method. The plaque offers `apply_grid_config`, two signals and three exports; the triangle offers `apply_grid_config` and two exports, `opening` and `size`. Nothing offers the one call the screen makes. So we open on the fallback:

```gdscript
# science_screen.gd:317
	_point_mode = true
```

The fallback is not a blank panel. It is a grid: white, square, right-angled, drawn before anything arrives to be drawn. The screen does not wait to learn what space it is in. It draws right angles whether or not anything is there, and right angles are this room's postulate in pixels.

Test it. Cross the room and watch the picture — it does not change, because nothing here gives it anything to change into. And this file has been fooled by its own paperwork before: its axis block once declared value names that were never in its enum. The sweep set them, the artifact fell back to its default, and sixteen identical frames were published — sixteen pictures of the same screen, filed as four variants. Nothing failed loudly.

A declaration outrunning its code, twice in one room. Here it arrives as a white grid rather than an error, which is how such things usually arrive.

## 7 — What the spec asked for and what stands here

**angle_sum_triangle** — `angle_sum_triangle`

<!-- ~intent#p1 ~tutorial#p19 ~walked#what-it-opens ~summary#p4 ~blurb#p2 ~critical#the-state-of-exception -->

The tutorial closes with a scroll — 300 BCE Euclid, 1733 Saccheri, 1829 Lobachevsky, 1832 Bolyai, 1854 Riemann — and a door that unlocks after two seconds of reading. The spec asked for two interactive demos, `parallel_line_demo` and `euclid_parallel_demo`, that let you drag the lines. Neither is placed.

We can see that absence from inside the code. Every placement here ships a bare token, and a bare token arrives as an empty dictionary:

```gdscript
# angle_sum_triangle.gd:197
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
```

Three lines, and the only door into the geometry shuts before it opens. What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, pillars three units tall in mirror symmetry down both sides, a walkway left open between them. Walk that walkway and you are standing inside the assumption. The colonnade is the axiom, built at the size of a body.

The absence is honest about the work. You are not here to bend a parallel. You are here to stand where bending is out of reach, and to feel how little effort that costs. The exit asks the question the furniture declines, and the next room takes the fifth away.

Count once more: five postulates, three lines, one triangle, one screen, two rows of pillars. Every number is true. Not one of them is necessary.

You can stand on a floor and still ask what is holding it up.

#### NonEuclidean Spaces

A bowl on your left, a dome on your right, and a flat plate between them that no longer looks like the default.

The previous room let you stand inside an assumption until it stopped feeling like one. This room puts the assumption on a dial. There is a slider here with a number on it, and the number is the curvature of space — negative to the left, zero in the middle, positive to the right. Flatness is the detent at zero. It is not the centre because it is correct; it is the centre because it is zero.

## One number, and it is not a metaphor

**Curvature Slider** — `curvature_slider`

```gdscript
# curvature_slider.gd:10
# critical_parameter: curvature — the ONE number that determines the entire geometry
```

Gaussian curvature, K, running from −1 to +1. That single scalar decides whether parallel lines diverge, stay apart, or converge; whether a triangle's angles sum to less than, exactly, or more than 180°; whether the shortest path between two points looks straight to you from outside. Not three geometries with three rulebooks. One rulebook with one free parameter.

This is the nineteenth century's actual discovery, and it is more unsettling than "there are other geometries." Gauss, Bolyai and Lobachevsky did not find a strange new space next door to the real one. They found that the space we were in had a setting, and that nothing in mathematics specifies which value it should take. Euclid's fifth postulate turns out to be the statement *K = 0* — not an axiom about parallels, a choice about curvature, wearing a sentence about lines.

## Where the wire is missing

**poincare_disk** — `poincare_disk`

```gdscript
# curvature_slider.gd:110
curvature_changed.emit(curvature)

# poincare_disk.gd:19 — and the only other place this signal name appears
signal curvature_changed(value: float)
```

Here is the room's own honest gap, and it is worth knowing before you turn anything.

The slider emits. Its registry entry says so plainly — *emits curvature_changed signal for linked surfaces* — and line 110 does exactly that, every time you move it. Search the rest of the project for anything that connects to it and you find one hit: the Poincaré disk, which declares the identical signal and emits it too. Two objects broadcasting the same message into a room where nothing is subscribed.

So the four surfaces standing around you — the saddle, the dome, the disk, the sphere — do not move when you turn the dial. Each one says so in its own header, in the same four words: *VR controls [missing]*. They are four fixed illustrations of four values of a parameter that is, in this room, unconnected to them.

Do not file that as a defect and move on. Notice what it makes the room into. You have a control that publishes a number, and a set of worlds that were each built at one value of it and cannot hear. That is a fairly exact picture of the situation the chapter is describing: the parameter is real, the consistency of each setting is real, and the passage between them is the thing nobody has built.

## The one that listens to itself

**Triangle Curvature Workbench** — `triangle_curvature_workbench`

```gdscript
# triangle_curvature_workbench.gd:7
# critical_parameter: K — discrete in {-2, -1, -0.5, 0, +0.5, +1, +2}. Drives surface
#   choice, edge geodesic type, angle measurement, and the excess/deficit readout
```

At the far corner, one bench does work. It carries its own slider — seven detents rather than a continuum — and when you turn it the surface underneath the triangle changes, the edges are rebuilt as geodesics *on that surface*, and the angle sum is measured and printed.

Measured. This is the payoff for the room you just left, where the angle sum was a hard-coded string reading `"60° + 60° + 60° = 180°"`. Here the number comes out of the geometry, and at K = 0 it lands on 180 not because anyone typed it but because that is what the flat case computes to. The same claim, arrived at two different ways, one room apart — and only one of them could ever have come out differently.

What it is showing you is the Gauss–Bonnet theorem: the amount by which a triangle's angles overshoot or fall short of 180° is exactly the curvature enclosed. Angle sum is not a fact about triangles. It is a measurement of the space the triangle is lying in, which is what the artifact's own header says: *the triangle doesn't know it's "in 3D"; it only knows its host*.

## Both neighbours of zero

**Hyperbolic Surface** — `hyperbolic_surface`

```gdscript
# hyperbolic_surface.gd:9
# essence: y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0
```

The saddle. Space curving outward, so that two geodesics starting parallel drift apart, and a triangle's angles fall short. Its header says something quietly good: *"straight" on a saddle looks curved from outside*. Straightness is not a property of the line. It is a relationship between the line and the surface it is confined to, and there is no outside vantage from which the surface is wrong.

**Elliptic Surface** — `elliptic_surface`

```gdscript
# elliptic_surface.gd:13
# emerges: the realization that on a positively curved surface there are NO parallel lines at all
```

The dome, and the opposite. Geodesics that begin parallel converge and cross, and the angle sum overshoots. On a sphere, the fifth postulate is not merely false — the thing it asserts cannot happen at all, because every pair of great circles meets. Twice.

Stand between the two and the point of the chapter is available without argument. These are not deformations of a correct space. Each is internally consistent, each has been formalised, each has physical realisations, and neither can be reached from the other by fixing an error. Flatness is the one in the middle. That is a fact about the number line, not about the world.

## The finite that holds the infinite

**Riemann Sphere** — `riemann_sphere`

```gdscript
# riemann_sphere.gd:10
# desire: see the infinite complex plane folded onto a finite sphere — the north pole IS infinity
```

Two objects here do the same trick from different directions and it is worth catching. The Poincaré disk compresses an entire infinite hyperbolic plane inside a finite circle: geodesics are arcs meeting the rim at right angles, and the rim is not an edge, it is infinity, which is why the tiles crowd and never arrive. The Riemann sphere does the mirror of it — the whole complex plane wrapped onto a ball by stereographic projection, with infinity as a single point you can walk around and look at from behind.

Both are saying that "infinite" and "unbounded" are not the same word, and that where you put the boundary is a modelling decision rather than a discovery. Which is the same sentence as the slider, one level up.

## What the dial cannot decide

Geometry was chosen, not found. That is settled by the time you leave this room, and it is settled without anyone having to be wrong.

But notice the shape of what just happened, because the next room breaks it. Every question here was answered by picking a value: what is the angle sum, do parallels meet, is the space finite — each one becomes answerable the moment K is fixed. The crisis so far is only that *we* pick K, and nothing outside picks it for us.

The next question does not have that form. It is not about which setting to choose. It is what happens to a rule that includes itself in the range of things it applies to — and there is no value of any parameter that makes that come out.

Flatness is a special case. The ground itself is a variable.

#### Russell Paradox

Four objects arranged as a cross, with a box at the centre, and every one of them is the same sentence said in a different material.

The last two rooms were about a choice: an axiom is a decision, and the decision has a dial. Both crises were survivable, because in both cases you could pick a value and carry on. This room is where that stops working. Nothing here is waiting for you to choose. The trouble is in the shape of the rule itself, and no setting fixes it.

## The box at the centre

**russell_set_box** — `russell_set_box`

```gdscript
# russell_set_box.gd:20
# essence: S = { x | x ∉ x }; S ∈ S ↔ S ∉ S — Russell's paradox as infinite regress
```

Take the set of all sets that are not members of themselves. Ask whether it contains itself.

If it does, then by its own definition it must not. If it does not, then by its own definition it must. There is no third option and no order of operations that gets you out; the two branches feed each other exactly. Russell sent this to Frege in 1902, while the second volume of Frege's *Grundgesetze* was at the printer, and Frege added an appendix beginning with the observation that a foundation had given way under the finished building.

The artifact makes it a box you open, and inside is another box, and inside that another. Its critical parameter is `max_visible_depth` — how many nestings to draw before giving up and showing the regress indicator. That is an honest piece of engineering: the object cannot be built, so the artifact builds as much of it as fits and then admits, in a label, that the remainder is not a rendering budget but the thing itself.

## The same shape, three more times

**BarberParadox** — `barber_paradox`

```gdscript
# barber_paradox.gd:11
## truth: he belongs in neither bin; the rule eats itself. If the barber shaves
##   himself he is shaved-by-the-barber (forbidden); if he does not, the rule
##   says the barber must shave him — contradiction either way.
```

Two labelled bins — SHAVES SELF, SHAVED BY BARBER — and one token that will not go in either. The barber shaves exactly those who do not shave themselves. Put him anywhere and the rule immediately requires him somewhere else.

Russell offered this himself, as the version you can tell at dinner, and it is worth noticing that it is not a simplification. The bins are the point: a classification that is exhaustive and exclusive, with one element that the classification generates and cannot place.

**LiarLoop** — `liar_loop`

```gdscript
# liar_loop.gd:11
## truth: if it's true it's false, if it's false it's true. There is no stable
##   assignment — the value loops forever.
```

A chalk sign reading THIS STATEMENT IS FALSE, with a lamp above it that cannot settle. The oldest of the four — Epimenides, then Eubulides, twenty-four centuries before set theory — and mechanically identical to the box. A predicate applied to the sentence containing it. The lamp does not flicker because the artifact is animating an effect; it flickers because there is no value to hold.

**SelfMembershipSet** — `self_membership_set`

```gdscript
# self_membership_set.gd:12
## truth: a set that is a member of itself, all the way down — and the set of
##   all sets that are NOT members of themselves cannot consistently exist.
```

The fourth arm, and the one that draws the distinction the other three leave implicit. A set that *does* contain itself is perfectly consistent — this artifact builds one, a brace inside a brace inside a brace, and nothing goes wrong. Self-reference on its own is not the fault. The catch is self-reference plus negation: the moment the rule is *not* a member of itself, the loop closes on a contradiction rather than on a regress.

That distinction is what saves mathematics later. The repairs — Zermelo–Fraenkel's axiom of separation, Russell's own type theory — do not ban self-reference. They ban unrestricted comprehension: the assumption that any property whatsoever carves out a set. You may still describe; you may no longer assume the description has an extension.

## The one that settles

**hilbert_hotel** — `hilbert_hotel`

```gdscript
# hilbert_hotel.gd:7
# critical_parameter: the shift map n ↦ n+1 — the bijection that proves |ℕ| = |ℕ + 1|
```

Two cells off the cross stands something that does not belong to the argument, and it is worth a sentence rather than a shrug, because it teaches the opposite lesson and it is standing close enough to be mistaken for a fifth arm.

Hilbert's hotel is full, infinitely, every room occupied. A guest arrives. Everyone moves up one, and there is a room. That looks like a paradox and behaves like one for about ten seconds, and then it resolves completely: the shift map is a bijection, the answer is *yes, there is room*, and the offended intuition was a finite intuition applied outside its range.

That is the difference this room needs you to hold. The hotel is a **surprise**, and it settles. The box, the barber, the liar and the brace are **contradictions**, and they do not. One of them is your intuition being wrong about infinity; the other four are a formal system being unable to say what it just said. Standing beside each other, they mark the line the rest of the chapter walks along.

**euclid_postulates_plaque** — `euclid_postulates_plaque`

The plaque near the entrance is the fifth postulate again, brought forward from the first room. Nothing in this room explains why it is here, so take it as the chapter keeping its own receipt: two rooms ago the crisis was that a foundational statement could not be *proved*. Here it is that a foundational statement cannot be *stated*. The plaque is the earlier, milder version of the trouble, standing where you can see how much worse it got.

## Where the wall is

Something has changed in the kind of problem. The parallel postulate was independent — you could go either way and both ways were consistent. Russell's set is not independent. There is no consistent system in which the question has an answer, and the repair is not to choose a value but to forbid the question from being asked.

That is what a formal system's boundary is, and it is the last quiet moment in this sequence. Two rooms from now the same argument returns with a much harder result attached: not that a system must fence off certain sentences to stay consistent, but that any system strong enough to be interesting will contain a sentence that is true and that it cannot reach — and that fencing will not help, because the sentence is about arithmetic and arithmetic is what the system is for.

Every formal system draws a boundary — and the boundary is where the system meets what it cannot hold.

#### Escher Impossible

A staircase that goes up on all four sides and comes back to where it started.

Check any corner of it. The riser is a sensible height, the tread is level, the joint between this flight and the next is square. Check the next corner and the same is true. Walk the whole loop checking as you go, approve every junction individually, and you will arrive back at the step you began on having climbed the entire way. Nothing you inspected was wrong. The object cannot exist.

That is the room, and it is the same result as the one two doors back, arrived at through the eye instead of through arithmetic. Russell's box could not be built because a rule contained itself. This staircase cannot be built because sixteen local truths do not add up to a global one — and there is no local inspection that could ever have told you.

## Sixteen joints, and the impossibility has to live in one of them

**escher_staircase** — `escher_staircase`

```gdscript
# escher_staircase.gd:169
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"
```

That line is the best thing in this room, because it is a dial whose settings are *where to put the contradiction*.

The artifact's own header spells the five out: smoothed into one quiet descending side and never named (`none`); gathered into a single closing riser you can point at (`hairline`); refused outright, so the loop is left open with two cut ends facing each other (`gap`); that same opening rigged with a tower and a landing so the walk becomes possible by cheating (`scaffold`); or spread evenly into all sixteen joints so the ring comes out level and no joint can be blamed (`field`).

The impossibility is conserved. It cannot be removed, only relocated — concentrated where it can be pointed at, or distributed until it is undetectable anywhere. That is exactly the property the room is arguing about consistency, expressed as a property of a Godot export.

The staircase here is placed as a bare token, so it stands at `none`: smoothed, and never named. The room's thesis is that the contradiction is in the whole rather than in any step, and its main body is set to the value that makes precisely that true. Whether that is a curatorial decision or an unset default, it is the right setting, and it is the reason the object reads as calm.

## The step you cannot take

```gdscript
# escher_staircase.gd:426
func climb_step() -> void:
```

The artifact has an API for walking it. Completing a full loop fires a `paradox_completed` signal. There is no `_input` handler in the file and no interaction volume anywhere in the scene, so nothing ever calls it — the header says as much, *has climb_step() API but no physical trigger*.

So the staircase whose desire is written down as *climb "up" forever and arrive where you started — feel the paradox in your legs* cannot be climbed. The signal for finishing the loop has no sender.

Worth sitting with rather than logging. The whole claim of this room is that walking the thing step by step is the procedure that fails to detect the fault — that local verification is exactly the method that cannot see a global contradiction. The one interaction that would let you perform that failure is the one that was not wired. You are left doing what the argument says you must do instead: standing back and taking in the whole, because there is no way to check it a piece at a time.

## Where you have to stand

**penrose_triangle** — `penrose_triangle`

```gdscript
# penrose_triangle.gd:41
@export_enum("marker", "bare", "seam", "exploded", "sealed") var disclosure: String = "marker"
```

Three bars, three right angles, each corner square. The Penrose triangle — published by Roger Penrose and his father Lionel in 1958, described by them as impossibility in its purest form, and the direct source for Escher's *Waterfall*.

It has two settings and both matter. `disclosure` is how much the object confesses, running from a small marker through bare, to a visible seam, to exploded, to sealed. And `_is_at_sweet_spot` tracks whether you are standing in the one place from which the illusion coheres — because a Penrose triangle built in three dimensions is a real object with a gap in it, and there is exactly one line of sight along which the gap is hidden by perspective.

That second parameter is the honest one. The impossibility is not in the object; it is in the relationship between the object and a viewpoint. From anywhere else in this room the triangle is an ordinary bent thing with a break. Move to the sweet spot and it closes. Nothing about the bars changed.

Which reframes the staircase too. Consistency here is not a property the object has. It is a property of a *view* of the object, and the view is a position you can be standing in without knowing you chose it.

## Two prongs, or three

**ImpossibleTrident** — `impossible_trident`

```gdscript
# impossible_trident.gd:13
## truth: two prongs become three; the drawing is consistent locally and impossible
##   globally — every junction is fine on its own, no assembly of them is.
```

The blivet, at the far end of the room. Read the base and you count two rectangular prongs. Follow them up and there are three round ones. There is no point along the drawing where the change happens; every band of it, covered at both ends, is a coherent picture.

It is the cleanest of the three because it removes the staircase's narrative and the triangle's perspective trick and leaves only the arithmetic: a count that is well-defined at both ends and different. The contradiction is not at a location. It is distributed across the transition, in the same way the staircase's `field` setting distributes it across sixteen joints so that no joint can be blamed.

## This is not a pipe

**magritte_pipe** — `magritte_pipe`

```gdscript
# magritte_pipe.gd:2
# essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
```

The one tangent, and the blurb seats it deliberately. Magritte's painting is not an impossible object — it is perfectly coherent — and its trouble is one level up: the image of a pipe is not a pipe, and the sentence saying so is not a sentence about pipes but about images.

It is in this room because the other three all depend on the same move. A drawing of a staircase can be locally valid in a way no staircase can, because a drawing is not the thing. The impossible objects are only impossible once you insist the representation is a claim about a buildable world. Take away that insistence and they are just marks that agree with each other locally.

Which is the room's argument pointed at itself: *every data structure is a Magritte painting*, as the header puts it. A model is consistent internally and says nothing, by itself, about whether the thing modelled can be.

## What checking cannot do

Consistency is not compositional. You can verify every step and learn nothing about the loop, and this is not a limitation of care or of time — it is a fact about what local verification is. The information that the staircase does not close is not present at any junction. It appears only in the sum.

That result is about to arrive in its formal version, which is worse, because there the whole under inspection is the checking system itself. Hold on to the trident: a count that is well-defined at both ends and different, with no place in between where it went wrong.

The contradiction isn't in any single step. It's in the whole.

#### Brouwer Intuitionism

A staircase with a few steps at the bottom and nothing above them, and the nothing is not unfinished. It is the correct state.

Everything so far in this sequence has been a limit discovered from inside: a postulate that cannot be proved, a set that cannot be defined, a loop that cannot close. This room is the first of two answers, and it is the severe one. Brouwer's response to the crisis was not to patch the foundations. It was to say that a large part of what mathematics had been doing was never legitimate, and to give up the results rather than the standard.

The rule is one sentence. **To assert that something exists, you must produce it.**

## The third option

**excluded_middle_demo** — `excluded_middle_demo`

```gdscript
# excluded_middle_demo.gd:9
# essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
```

Two glowing spheres, P and not-P, with the disjunction between them, and a slider that flips the room between classical acceptance and intuitionistic doubt.

Classically, `P ∨ ¬P` is free. Every proposition is true or false; you may use that before knowing which. It is what licenses proof by contradiction: assume not-P, derive absurdity, conclude P — and you have proved P exists without ever exhibiting it.

Brouwer refused the licence. For him a mathematical statement is not a description of a pre-existing fact but a report on a construction, and a construction either has been carried out or has not. So there is a third state, and the tutorial in this room names it exactly: not true, not false, **not yet constructed**. The third option is the whole point, and it is not ignorance. There is no fact of the matter waiting to be uncovered, because on this account the fact is made by the proof.

This is one of two objects in the room you can actually operate. Hold on to that.

## Show me

**constructive_proof** — `constructive_proof`

```gdscript
# constructive_proof.gd:9
# essence: ∃x P(x) requires exhibiting x — no proof by contradiction allowed
# critical_parameter: the witness — without an explicit construction, the proof is rejected
```

The distinction, made into an object: knowing something exists, versus being able to point at it.

The classical proof that there exist irrational `a` and `b` with `a^b` rational is the standard demonstration of how wide the gap is. Take √2 to the power √2. Either it is rational, in which case you are done, or it is irrational, in which case raise it to √2 again and you get 2, and you are done. The proof is valid, it is three lines, and at the end of it you cannot say which of the two cases you are in. It has proved that a witness exists without producing one.

Brouwer's answer is that it has therefore proved nothing. The word *exists* was doing work it had not paid for.

What that costs is enormous, and honesty about the cost is part of teaching it: intuitionistic mathematics loses large parts of analysis, most of the theory of infinite sets, and any theorem whose only proof runs through contradiction. Brouwer accepted the loss. Hilbert, who did not, wrote that taking excluded middle from the mathematician was like taking the telescope from the astronomer.

## Always unfinished

**brouwer_choice_sequence** — `brouwer_choice_sequence`

```gdscript
# brouwer_choice_sequence.gd:8
# essence: a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed
# critical_parameter: time — the sequence unfolds perpetually, dots gently bobbing
```

A row of terms trailing off into question marks. Brouwer's choice sequences are his positive proposal, not just his prohibition: an infinite object that is never completed, only ever extended, where the next term is chosen and not determined. Infinity as a process rather than a finished set.

Now read the two lines above against each other. The essence says *each term chosen freely*. The critical parameter is `time`, and the sequence unfolds perpetually on its own. Its header names the missing piece without flinching — *could add ability to "choose" the next term* — so the object whose entire content is free choice runs on a timer and chooses for you.

That is the room's central irony and it is not confined to this one body. Of the four stations of the argument, two have controls and two do not; `constructive_proof` says *VR controls [missing]* in the same breath as declaring that the witness must be exhibited. A room whose claim is that nothing exists until a hand makes it, in which most of the hands are absent.

I would not repair that by wiring buttons to everything. The gap is more useful named than closed, because it is the actual condition the philosophy describes: the construction is *possible*, nobody has performed it, and on Brouwer's own terms that means it does not yet exist. The room is in the state it is teaching.

## The step that is not there yet

**ConstructiveStaircase** — `constructive_staircase`

```gdscript
# constructive_staircase.gd:14
## truth: the next step isn't true-or-false until you build it — existence is
##   construction, not the absence of a contradiction.
```

Built steps are solid. Above them there is nothing, and the nothing is not a gap in the model.

A classical mathematician looks at the unbuilt region and says: either the seventeenth step exists or it does not, we simply have not looked. Brouwer says there is no seventeenth step to have a property, and there will be one when someone builds it. Not hidden. Not undetermined. Absent.

That is the difference between an epistemic gap and an ontological one, and it is the hardest idea in the room, which is why it is worth having it as a thing you can stand at the bottom of and look up from.

## The one that does it properly

**Cantor Diagonal Workbench** — `cantor_diagonal_workbench`

```gdscript
# cantor_diagonal_workbench.gd:6
# desire: learner viscerally feels uncountability — you can list "all" reals, and we
#   will construct one that isn't in the list, just by flipping the diagonal
```

Nothing in the room says why this bench is here, so here is why it earns its place: it is the model constructive proof, and it is the other object you can operate.

Cantor's diagonal argument is often taught as a proof by contradiction — assume the reals are listable, derive absurdity — but it does not have to be, and this bench does not present it that way. Turn the slider, the list grows, the diagonal extends, and a number is *built*, digit by digit, that differs from the first entry in the first place, the second in the second, and so on. At the end you are holding the witness. It is not that a missing real must exist; it is that here it is, and you watched it being made.

So this is what Brouwer is asking for, standing in the same room as the objects that cannot deliver it. The procedure scales, it terminates at any length you choose, and it hands you the thing.

## The two that assert

**angle_sum_triangle** — `angle_sum_triangle`

**parallel_lines** — `parallel_lines`

Two objects have been carried forward from the first room and left here without explanation. They are the triangle whose angles sum to 180°, and the pair of parallel lines.

They are also, of everything in this sequence, the two artifacts that *assert rather than construct*. The triangle does not measure its corners; it prints the string `"60° + 60° + 60° = 180°"`, and the `curvature` knob its own header names appears six times in the file, every one of them inside a comment. The parallel lines have no script at all — the scene file is two line instances and two hand-typed transform matrices, parallel because somebody decided so and typed the numbers.

In a room about constructive proof, that is the entire lesson standing in the corner. Both objects state a result. Neither exhibits a witness. Both are, on the strict reading this room is teaching, claims for which no construction has been performed — and both are perfectly convincing to look at, which is the danger Brouwer was pointing at.

Whether they were placed here for that reason, I cannot tell from the map. They earn the position either way.

## What it costs

This is the harder of the two responses to the crisis, and it works by giving things up. Brouwer keeps certainty by shrinking mathematics to what has been made, and pays for it in theorems.

The next room takes the opposite route. Rather than refusing to assert what cannot be built, it refuses to panic about holding two assertions that contradict each other. Where Brouwer removes the third option and calls it *not yet*, Florensky keeps both options at once and declines to let the contradiction spread.

No existence without witness. No truth without a hand that built it.

#### Florensky Paraconsistent

A door frame with two leaves in it, one swung open and one shut, both there at once, and you can walk through.

The last room answered the crisis by giving things up: assert only what you have built, and lose the theorems that depended on assuming otherwise. This room answers it the other way. It keeps the contradiction, keeps working, and gives up something much smaller than you would expect.

What it gives up is a single inference rule. Not truth, not rigour, not consistency in any sense you would miss — one rule, called *ex falso quodlibet*, which says that from a contradiction anything whatsoever follows.

## The rule that does the damage

**BothTrueGate** — `both_true_gate`

```gdscript
# both_true_gate.gd:15
## truth: P and not-P, and the world does not end — the contradiction is contained,
##   not detonated.
```

In classical logic, one contradiction is fatal to a whole system — not locally, everywhere. If both P and not-P are derivable then every sentence in the language is derivable, including every falsehood, and the system stops distinguishing anything from anything. That total collapse is why a single inconsistency is treated as catastrophic. It is not that the contradiction is embarrassing. It is that it spreads.

Paraconsistent logic blocks that step and nothing else. Contradictions may be derivable and are not permitted to imply arbitrary conclusions. The tutorial in this room states the containment exactly: *contradictions exist in the box; they cannot escape as anything follows.*

The gate makes it a thing you walk through. Both leaves are real, the frame holds them, and the room around it is not on fire. That is the entire claim, and the reason it needs to be a body rather than a sentence is that the sentence sounds like a trick and the door does not.

## A resting state, not an exception

**florensky_sphere** — `florensky_sphere`

```gdscript
# florensky_sphere.gd:21
# critical_parameter: current_state — BOTH (A ∧ ¬A) is the resting state, not the
#   exception; observation collapses it to A or ¬A only briefly
```

A double-faced sphere whose skin reads from both sides, holding A and not-A on one surface.

Read the parameter carefully, because the ordering is the argument. BOTH is where the object rests. Looking at it can knock it briefly to one side, and it returns. This is the inverse of the arrangement you would expect and the inverse of the two objects across the room: the single-valued states are the transient ones, and the contradiction is the stable configuration.

Pavel Florensky was a mathematician, an Orthodox priest and an electrical engineer, and he argued that the deepest truths are antinomic — that a contradiction properly held is not a failure of thought but its highest form. He wrote that while working as a physicist in the Soviet Union; he was executed in 1937. The artifact's header calls the contradiction *a MODE OF BEING* rather than a defect, and that is a fair rendering of his position rather than a decoration on it.

One mechanical detail earns a look. To show both faces of one surface the artifact has to disable back-face culling, so the inside and the outside of the same skin both catch light. Everywhere else in this project turning culling off is a compromise; here it is the argument. A surface that can only be seen from one side cannot hold two readings.

## The foil, and it is a foil

**schrodinger_box** — `schrodinger_box`

**Superposition Display** — `superposition_display`

```gdscript
# schrodinger_box.gd:12  ·  superposition_display.gd:10 — the same axis, twice
# critical_parameter: remainder — where the box puts the part of the state it cannot
#   show you (core | twin | seam | haze | witness)
```

Two quantum objects stand across from the two logical ones, and it would be easy to read them as the same idea in physics dress. They are the opposite idea, and the room is arranged so you can catch the difference.

The cat is both alive and dead until observed — and then it is not. Observation collapses the superposition to one branch and the other is gone. The display says the same thing about a qubit: `|ψ⟩ = α|0⟩ + β|1⟩`, genuinely occupying both, and genuinely resolving to one when measured. Both are contradictions *with an expiry*. The world tolerates them precisely because looking ends them.

Now notice what the two of them share and the other two do not. Both carry an axis called `remainder`, with five settings, and its job is to decide where the object puts *the part of the state it cannot show you*. Core, twin, seam, haze, witness — five architectures for the unshowable.

The gate and the sphere have no such axis, and do not need one. Nothing is being held back. Both leaves are in the frame; both faces are on the sphere. The quantum pair need a hiding place because their contradiction is not permitted to persist in view; the paraconsistent pair do not, because theirs is.

That is the distinction to leave the room with, and it is easy to lose: **collapse-on-observation is the foil, not the model.** Superposition resolves and paraconsistency refuses to. Placing them four metres apart is the room's whole method.

## Two answers, both live

Stand back and this room and the last one are a matched pair, and the sequence puts them in this order deliberately.

Brouwer takes the crisis to mean the standard was too loose: stop asserting what you cannot construct, accept a third state between true and false, lose the theorems. Florensky takes it to mean the demand was too strong: keep both assertions, block the explosion, lose one inference rule.

Neither repairs the foundation. Both are ways of continuing to work on a foundation that is known not to close, and they disagree about which piece of classical logic was the mistake. That they are both viable is the actual state of the field, and it is more interesting than a resolution would have been.

The last room takes that seriously in a way neither of these two quite does. If the gap cannot be closed by tightening or by loosening, then the gap is not a defect in the method — it is what the method runs on.

Paraconsistent logic doesn't resolve contradiction. It refuses the demand that contradiction must resolve.

#### Crisis Synthesis

One line of text floating at eye height, and four wings leading off to the objects that earned each of its terms.

```
QFE = F − λE(S) + φΔE(S,t)
```

You have walked seven rooms of things that could not be closed: a postulate that would not be proved, a geometry that turned out to be a setting, a set that could not be defined, a staircase that checked at every joint and could not exist, and two incompatible ways of carrying on afterwards. This room does not resolve any of it. It says that the not-closing was the productive part.

## The formula, and which term is lit

**qfep_formula_3d** — `qfep_formula_3d`

```gdscript
# qfep_formula_3d.gd:11
# critical_parameter: highlighted_term — the book-role privileges φΔE(S,t): it is the
#   queer generative term, the OPEN one
```

Three terms. `F` is fit — how well a system satisfies its own constraints. `λE(S)` is entropy, scaled by λ, subtracted: the pull toward order, toward closing, toward the crystal. `φΔE(S,t)` is the rate of change of entropy over time, scaled by φ, and it is added.

The third term is the one this whole sequence has been arguing for. The first two describe a system that wants to settle: maximise fit, minimise disorder, arrive somewhere and stop. On their own they describe exactly the ambition that Hilbert's programme had and that Gödel ended — a formal system that closes. The third term is what a system does when it cannot close, and its sign is positive.

The artifact's header is explicit that this is a reading rather than a calculation: *to be read, not solved*. Walk up to any single term and it brightens, and the sentence tilts. Under `F` it is an optimisation. Under `λE(S)` it is thermodynamics. Under `φΔE(S,t)` it stops being a balance sheet and becomes a description of something that keeps moving because it has nowhere final to arrive.

## Two dials you can hold

**lambda_slider** — `lambda_slider`

```gdscript
# lambda_slider.gd:15
# critical_parameter: lambda — the single number that controls order/chaos balance
#   across the entire QFEP system
```

λ from 0 to 1, on a rail with a colour gradient from blue through green to red, and it broadcasts to the whole room. At the low end the system is loose and noisy; at the high end it crystallises. The interesting readings are not at either end. The header names the zone: *the green zone at 0.3–0.5 where particles and color converge — the sweet spot finds you*.

**phi_slider** — `phi_slider`

```gdscript
# phi_slider.gd:41
# critical_parameter: phi — rate sensitivity that determines whether the system fights
#   or welcomes transformation
```

φ from −1 to +1, purple through grey to gold, and it is the one that carries the argument. Negative φ is a system that resists change — the header says it feels heavy, with the particles falling. Positive φ welcomes it and they rise. Grey in the middle is a system indifferent to its own transformation.

The asymmetry is the point, and it is unusual for a parameter to be built with a preferred direction stated out loud. This one is: the generative reading is the positive one, and the room lets you set it the other way and feel the difference in your hand rather than be told.

## The edge, which you cannot move

**bifurcation_diagram** — `bifurcation_diagram`

```gdscript
# bifurcation_diagram.gd:16
# essence: x(n+1) = r·x(n)·(1 - x(n)); period doubling cascade → chaos at r ≈ 3.57
# needs: VR slider for r [missing] — highlight plane tracks current_r but no physical controller
```

The logistic map. One line of arithmetic, one parameter, and a picture that goes from a single stable value, to an oscillation between two, to four, to eight, and then — at r ≈ 3.5699 — to chaos, with windows of order inside the chaos, at every scale.

It is here because it is the clearest available demonstration that the interesting behaviour of a system lives at its boundary and nowhere else. Below the cascade the map is dead: it settles and stays. Above it, structure at every magnification. And Feigenbaum's discovery is that the constants governing the cascade are the same for *every* system that period-doubles, which makes the edge a universal feature rather than an accident of this equation.

Two dials in this room can be grabbed. This one cannot — the highlight plane tracks `r` but nothing lets you move it. The room's claim is that the sliders show life only at the boundary, and the object that *is* the boundary is the one with no slider. Worth naming rather than filing: what you can hold here are the two parameters of the thesis, and the thing they are a thesis about is on rails.

## A room inside the room

**Gödel Atrium** — `goedel_atrium`

```gdscript
# goedel_atrium.gd:28
# needs: nothing. The room is self-contained, which is precisely its [point]
```

An atrium with a plinth at its exact centre, and on the plinth a model of the atrium, at one tenth scale, with a plinth at its centre. Default recursion depth is 2. Stand in the doorway and you can see your own doorway inside it.

Of everything in this sequence this is the object that most nearly *is* its subject rather than depicting it. A formal system strong enough to describe itself contains a description of itself, and that description contains a description, and the regress is not a bug in the encoding — it is the encoding working. Gödel's construction does exactly this: it arithmetises the syntax of arithmetic so that statements about proofs become statements about numbers, and then finds a number that says of itself that it has no proof.

The `needs` field of most artifacts in this project lists what is missing. This one says *nothing*, and gives the reason: self-containment is what it is for. It is the only artifact I have read whose statement of completeness is also its argument.

## The wings

**godel_statement_plaque** — `godel_statement_plaque`

**russell_set_box** — `russell_set_box`

**escher_staircase** — `escher_staircase`

**florensky_sphere** — `florensky_sphere`

Four objects return here from the rooms they came from: the plaque that asserts its own unprovability, the box that cannot contain itself, the staircase that checks and cannot exist, and the sphere that holds A and not-A at rest.

Three of those are crises. The fourth is a response. Brouwer is not here — the tutorial's own wing list names him, but no constructivist artifact is placed, and the blurb agrees with the map rather than with the tutorial. So the synthesis assembles three demonstrations that formal systems have an outside, plus one demonstration of how to keep working anyway, and the other way of keeping working — build it or do not assert it — is absent from the summit.

That is a real asymmetry and it is arguably the right one. Florensky's answer is the one this formula takes: hold the contradiction, do not let it detonate, keep going. Brouwer's answer is to shrink the system until it closes, which is precisely what the third term of the formula says a living system does not do. The missing wing is a position the room has rejected rather than forgotten.

**Russell's Paradox Workbench** — `russell_paradox_workbench`

```gdscript
# russell_paradox_workbench.gd:6
# desire: learner viscerally feels that self-reference per se is not the problem
#   (cell 4, S = {x : x ∈ x}, is consistent) — it is self-reference plus [negation]
```

A second Russell station, and it says the more precise thing than the box does: walk six set definitions on a slider and watch which ones close on a contradiction. The fourth is self-referential and perfectly consistent. Self-reference is not the fault; self-reference plus negation is.

That correction matters at the summit, because otherwise the sequence's moral collapses into *systems that look at themselves break*, which is not true and would make the atrium next door a warning rather than a demonstration.

## The outside is the engine

Hilbert wanted arithmetic proved complete and consistent from inside itself. Gödel showed that a system strong enough to be interesting can have one or the other and not both, and the interesting part is the qualifier: the incompleteness is a consequence of *strength*. A system too weak to describe itself can be complete. The price of being able to talk about yourself is a sentence you cannot reach.

Set that beside the logistic map. Below the cascade, order and no structure. Above it, structure that never repeats. Nothing rich happens in the settled regime. And set it beside the third term of the formula, added rather than subtracted: `φΔE(S,t)`, the rate at which a system's disorder changes, weighted by how much it welcomes changing.

The seven rooms behind you are not seven failures. They are seven places where a system met its own edge and something began there — non-Euclidean geometry from a postulate that would not close, type theory and modern set theory from a definition that ate itself, computability from a sentence that could not be proved. Each crisis produced the field that came after it.

The crisis was never the problem. The crisis is the engine.

*1 further room(s) in this chapter, not yet written.*

**elliptic surface**

![elliptic surface](/artifact-gallery/captures/elliptic_surface/front.png)

*K > 0 — positive Gaussian curvature; parallel lines converge, triangles have angle sum > 180°*

Dome/sphere-like surface demonstrating positive Gaussian curvature (K > 0) — where parallel lines converge and triangle angles sum to more than 180 degrees.

> on a positively curved surface, there is no room for parallel lines — all paths eventually meet

**riemann sphere**

![riemann sphere](/artifact-gallery/captures/riemann_sphere/front.png)

*C ∪ {∞} — the complex plane plus a point at infinity, wrapped onto a sphere via stereographic projection*

The Riemann sphere — compactified complex plane with stereographic projection lines, north pole at infinity, equator, and projection plane visible.

> infinity is not the absence of a boundary — it is a boundary that has been folded back into the space it bounds

**hyperbolic surface**

![hyperbolic surface](/artifact-gallery/captures/hyperbolic_surface/front.png)

*y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0*

Saddle-shaped surface demonstrating negative Gaussian curvature (K < 0) — where parallel lines diverge and triangle angles sum to less than 180 degrees.

> on a negatively curved surface, there are infinitely many parallel lines through any point — the fifth postulate fails spectacularly

**angle sum triangle**

![angle sum triangle](/artifact-gallery/captures/angle_sum_triangle/front.png)

*α + β + γ = 180° (Euclidean angle sum theorem)*

Demonstrates that triangle angles sum to 180° in Euclidean space — a fact that fails in non-Euclidean geometries

> the angle sum of a triangle is not a fact about triangles but a fact about the space they inhabit

**curvature slider**

![curvature slider](/artifact-gallery/captures/curvature_slider/front.png)

*K ∈ [-1, +1] — Gaussian curvature as continuous parameter*

VR slider controlling Gaussian curvature from negative (hyperbolic) through zero (flat/Euclidean) to positive (elliptic). Emits curvature_changed signal for linked surfaces.

> flat space is not the default — it is the singular boundary between two infinite families of geometries

### The Walk — further in

**poincare disk**

![poincare disk](/artifact-gallery/captures/poincare_disk/front.png)

*geodesics as circular arcs meeting the boundary at right angles; the boundary circle IS infinity*

Poincaré disk model of hyperbolic geometry - where parallel lines diverge and triangles have angle sum < 180°

> infinity can be contained in a finite disk — the Poincare model proves that hyperbolic geometry is as consistent as Euclidean

**euclid postulates plaque**

![euclid postulates plaque](/artifact-gallery/captures/euclid_postulates_plaque/front.png)

*five axioms; four self-evident, the fifth (parallel postulate) independent and contingent*

Interactive plaque displaying Euclid's five postulates, highlighting the controversial fifth (parallel) postulate

> the parallel postulate was assumed for two thousand years — its independence was the first crack in mathematical certainty

**escher staircase**

![escher staircase](/artifact-gallery/captures/escher_staircase/front.png)

*each step locally valid; global loop returns to start — the Penrose stairs*

Impossible staircase - locally coherent, globally impossible. Visual Gödel.

> locally coherent does not mean globally possible — this is Godel's incompleteness made architectural

**superposition display**

![superposition display](/artifact-gallery/captures/superposition_display/front.png)

*|ψ⟩ = α|0⟩ + β|1⟩; α oscillates as sin(t·speed), β = 1 - α; both states simultaneously present*

Interactive visualization of quantum superposition |psi> = alpha|0> + beta|1> with VR slider to control the amplitude ratio between basis states.

> superposition is not uncertainty about which state the system is in — it is the system genuinely being in both

**phi slider**

![phi slider](/artifact-gallery/captures/phi_slider/front.png)

*slider_position -> phi in [-1,1]; color_gradient(purple->gray->gold)*

QFEP φ parameter controller. Rate of entropy change sensitivity: φ<0 (resists change) → φ=0 (neutral) → φ>0 (embraces change). Positive φ is the queer signature—valuing becoming over being.

> phi is the queer parameter — positive phi means the system does not merely tolerate change but seeks it as generative

### The Turn — parameters

Open in the dressing-room viewer: parallel lines, elliptic surface, riemann sphere, hyperbolic surface.

### The Critical Reading

QFEP term: **Edge**

Gödel proves pure F-minimization hits a wall. The edge isn't failure—it's constitutive. Systems must oscillate because they cannot close.

The artifacts' own claims:

> on a positively curved surface, there is no room for parallel lines — all paths eventually meet — *elliptic surface*

> infinity is not the absence of a boundary — it is a boundary that has been folded back into the space it bounds — *riemann sphere*

> on a negatively curved surface, there are infinitely many parallel lines through any point — the fifth postulate fails spectacularly — *hyperbolic surface*

> the angle sum of a triangle is not a fact about triangles but a fact about the space they inhabit — *angle sum triangle*

> flat space is not the default — it is the singular boundary between two infinite families of geometries — *curvature slider*

> infinity can be contained in a finite disk — the Poincare model proves that hyperbolic geometry is as consistent as Euclidean — *poincare disk*

> the parallel postulate was assumed for two thousand years — its independence was the first crack in mathematical certainty — *euclid postulates plaque*

> locally coherent does not mean globally possible — this is Godel's incompleteness made architectural — *escher staircase*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| Euclid_Parallel | 11×15 | 4 | 4.8 m |
| NonEuclidean_Spaces | 15×13 | 5 | 3.7 m |
| Russell_Paradox | 11×12 | 4 | 0.3 m |
| Godel_Incompleteness | 13×14 | 4 | 0.6 m |
| Escher_Impossible | 11×12 | 4 | 4.3 m |
| Brouwer_Intuitionism | 11×14 | 4 | 1.9 m |
| Florensky_Paraconsistent | 13×12 | 4 | 1.8 m |
| Crisis_Synthesis | 17×18 | 8 | 25.8 m |

What this chapter teaches, walked rather than read:

- Non-Euclidean geometry: the parallel postulate is independent
- Russell's paradox: self-reference creates contradiction
- Gödel's incompleteness: true statements that cannot be proven
- Brouwer's intuitionism: only assert what you can construct
- The edge as constitutive, not defective

### The Seed

> **Every formal system has an outside. Complete order is impossible.**

Exercises:

1. Non-Euclidean geometry: the parallel postulate is independent
2. Russell's paradox: self-reference creates contradiction
3. Gödel's incompleteness: true statements that cannot be proven
4. Brouwer's intuitionism: only assert what you can construct
5. The edge as constitutive, not defective
6. Walk Euclid_Parallel in VR and find where the rule first breaks its own pattern.
7. Open parallel_lines in the dressing-room viewer and change one parameter until it stops being itself.

*Next: qfeplaboratory*

### The Ledger

- **the dig** — 11 of 32 artifacts excavated; 21 remain at depth.

## Chapter 21: QFEP Laboratory: The Formula Made Interactive

> **QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t). Life exists at Î» â‰ˆ 0.3-0.5.**

`QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t)`

The theoretical core of Ada Research made interactive. Manipulate the QFEP parameters directly. See how F, Î», and Ï† create different system behaviors. Understand why life exists at the edge of chaos.

### The Principal

This chapter's principal is **qfep balance workbench** — *a four-knob console for the QFEP formula — F, E(S), λ, φ sliders side-by-side on a tilted plate. As you turn them, QFE = F − λ·E(S) + φ·ΔE(S,t) recomputes live; a four-axis radar chart re-draws the knob quadrilateral; the dominant timeline phase is detected and its canonical color tints the readout panel, the radar fill, and an emissive halo behind the whole instrument. The project's organizing frame made into a console you operate.* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **self**: brings its own base — no plinth, no bed.

### The Primitive

**qfep balance workbench**

![qfep balance workbench](/artifact-gallery/captures/qfep_balance_workbench/front.png)

*a four-knob console for the QFEP formula — F, E(S), λ, φ sliders side-by-side on a tilted plate. As you turn them, QFE = F − λ·E(S) + φ·ΔE(S,t) recomputes live; a four-axis radar chart re-draws the knob quadrilateral; the dominant timeline phase is detected and its canonical color tints the readout panel, the radar fill, and an emissive halo behind the whole instrument. The project's organizing frame made into a console you operate.*

Four-knob console for the QFEP formula. Player turns F, E(S), lambda, phi sliders; a radar chart shows the current quadrilateral; the dominant timeline phase color tints the readout. The frame made into a balance.

> the QFEP formula is not a description of a system; it is a navigable balance. F − λ·E(S) + φ·ΔE has seven characteristic settlings (phases). The console makes those settlings hand-cranked.

### The Walk — first steps

*7 room(s) in this chapter; none written yet.*

**shannon workbench**

![shannon workbench](/artifact-gallery/captures/shannon_workbench/front.png)

*an interactive Shannon-bound workbench — the player turns a slider for p and watches the binary entropy hill H(p) light up at their position, sees the 16×16 sample grid regenerate, and reads the compression bound that those bits cannot fall below. At p=0.5, the slider sits at the peak of the hill, the sample grid looks like salt-and-pepper, and the readout says "incompressible: 256/256 bits"*

An interactive workbench for the binary entropy function. One slider drives p ∈ [0,1]; a 16×16 Bernoulli(p) bit grid regenerates from a fixed seed (same draws, migrating threshold), a live readout shows H(p) bits/symbol and the theoretical-min bit count, and a glowing red marker rides the entropy hill H(p) = -p log₂ p - (1-p) log₂(1-p) above the table. The slope of H is the rate at which structure becomes possible; the peak (p=0.5) is where structure is maximally absent. Sister to shannon_entropy_meter (this is the source side; that is the measurement side).

> between pure order and pure noise lies a mathematical landscape with a floor Shannon named. The floor is H(p) bits/symbol; you can approach it asymptotically but never beat it. The slider lets you walk along the floor.

**phi slider**

![phi slider](/artifact-gallery/captures/phi_slider/front.png)

*slider_position -> phi in [-1,1]; color_gradient(purple->gray->gold)*

QFEP φ parameter controller. Rate of entropy change sensitivity: φ<0 (resists change) → φ=0 (neutral) → φ>0 (embraces change). Positive φ is the queer signature—valuing becoming over being.

> phi is the queer parameter — positive phi means the system does not merely tolerate change but seeks it as generative

**qfep formula 3d**

![qfep formula 3d](/artifact-gallery/captures/qfep_formula_3d/front.png)

*TextMesh("QFE = F - lambda*E(S) + phi*delta_E(S,t)") with per-term color and pulse animation*

3D visualization of the complete QFEP formula: QFE = F − λE(S) + φΔE(S,t). Each term glows with its signature color. Responds to lambda and phi slider changes. The theoretical anchor.

> QFE = F - lambda*E(S) + phi*delta_E(S,t) is not an equation to solve but a lens through which to see every system

**lambda slider**

![lambda slider](/artifact-gallery/captures/lambda_slider/front.png)

*slider_position / rail_length -> lambda in [0,1]; color_gradient(blue->green->red)*

QFEP λ parameter controller. The entropy drive dial: λ=0 (pure order) → λ=0.4 (edge of chaos) → λ=1 (dissolution). Grab and slide to tune how much a system values disorder vs order. Life exists at λ ≈ 0.3-0.5.

> lambda is the entropy drive — the dial between crystallization and dissolution that every living system must negotiate

**grab sphere E**

![grab sphere E](/artifact-gallery/captures/grab_sphere_E/front.png)

Grabbable sphere representing E(S) (Entropy) - the freedom and possibility space. Red glow.

### The Walk — further in

**grab sphere lambda**

![grab sphere lambda](/artifact-gallery/captures/grab_sphere_lambda/front.png)

Grabbable sphere representing λ (lambda) - the entropy drive parameter. Green glow.

**turing pattern**

![turing pattern](/artifact-gallery/captures/turing_pattern/front.png)

Reaction-diffusion Turing pattern. Spots, stripes, labyrinths.

**random cubes**

![random cubes](/artifact-gallery/captures/random_cubes/front.png)

*for i in N: cube(random_pos, random_rot, random_size, random_color) + drift(random_velocity)*

Chaotically arranged cubes representing high entropy. Random positions, rotations, scales.

> randomness is not the absence of information but the presence of all possible configurations simultaneously

**grab sphere F**

![grab sphere F](/artifact-gallery/captures/grab_sphere_F/front.png)

Grabbable sphere representing F (Free Energy) - the order-seeking, pattern-finding drive. Blue glow.

**bifurcation walkway**

![bifurcation walkway](/artifact-gallery/captures/bifurcation_walkway/front.png)

A corridor where your position = r parameter in the logistic map. Walk through the phase transition: stable → period doubling → chaos → windows of order. The bifurcation diagram made walkable.

### The Turn — parameters

Open in the dressing-room viewer: qfep balance workbench, shannon workbench, phi slider, qfep formula 3d.

### The Critical Reading

QFEP term: **All**

The complete QFEP framework made tangible. Interactive sliders for Î» (entropy drive) and Ï† (rate sensitivity). Visualize the oscillation between order and chaos. Find your edge of chaos.

The artifacts' own claims:

> the QFEP formula is not a description of a system; it is a navigable balance. F − λ·E(S) + φ·ΔE has seven characteristic settlings (phases). The console makes those settlings hand-cranked. — *qfep balance workbench*

> between pure order and pure noise lies a mathematical landscape with a floor Shannon named. The floor is H(p) bits/symbol; you can approach it asymptotically but never beat it. The slider lets you walk along the floor. — *shannon workbench*

> phi is the queer parameter — positive phi means the system does not merely tolerate change but seeks it as generative — *phi slider*

> QFE = F - lambda*E(S) + phi*delta_E(S,t) is not an equation to solve but a lens through which to see every system — *qfep formula 3d*

> lambda is the entropy drive — the dial between crystallization and dissolution that every living system must negotiate — *lambda slider*

> randomness is not the absence of information but the presence of all possible configurations simultaneously — *random cubes*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| QFEP_Introduction | 9×10 | 10 | 23.2 m |
| QFEP_F_Term | 10×12 | 8 | 15.8 m |
| QFEP_E_Term | 12×12 | 10 | 25.0 m |
| QFEP_Lambda_Spectrum | 5×18 | 7 | 24.5 m |
| QFEP_Phi_Term | 10×10 | 7 | 11.9 m |
| QFEP_Edge_Of_Chaos | 14×13 | 8 | 24.7 m |
| QFEP_Sandbox | 14×14 | 8 | 32.1 m |
| QFEP_Synthesis | 12×12 | 10 | 6.2 m |

What this chapter teaches, walked rather than read:

- F (Free Energy): prediction error, order-seeking, surprise minimization
- E(S) (Entropy): possibility space, disorder, freedom from pattern
- Î» (Entropy Drive): the dial between crystallization and dissolution
- Ï†Î”E(S,t) (Rate Term): sensitivity to change, the queer signature
- Edge of chaos: where Î» â‰ˆ 0.3-0.5, where adaptation happens

### The Seed

> **QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t). Life exists at Î» â‰ˆ 0.3-0.5.**

Exercises:

1. F (Free Energy): prediction error, order-seeking, surprise minimization
2. E(S) (Entropy): possibility space, disorder, freedom from pattern
3. Î» (Entropy Drive): the dial between crystallization and dissolution
4. Ï†Î”E(S,t) (Rate Term): sensitivity to change, the queer signature
5. Edge of chaos: where Î» â‰ˆ 0.3-0.5, where adaptation happens
6. Walk QFEP_Introduction in VR and find where the rule first breaks its own pattern.
7. Open qfep_balance_workbench in the dressing-room viewer and change one parameter until it stops being itself.

*Next: postfoundationscrisis*

### The Ledger

- **the dig** — 11 of 36 artifacts excavated; 25 remain at depth.

## Chapter 22: Post-Crisis: Applied Limits

> **Knowing the limits of formalization, what do we build?**

`limits → critical practice → new structures`

The sequence that lands the thesis. The foundations crisis showed that every formal system has an outside. These maps walk what becomes possible once you stop demanding completeness: ethics as architecture, paraconsistent engineering, situated computation, the commons as a response to incompleteness, rhizomatic networks, molecular design, and a synthesis that treats the edge as ground rather than limit.

### The Principal

This chapter's principal is **bias visualizer** — *embedding_space(words, gender_axis) -> proximity_reveals_prejudice* — one canonical scene, inherited by every instance; the type is the spatial truth. It seats **cube**: the one-metre sim-cell made visible — the grid's unit turned into housing.

### The Primitive

**bias visualizer**

![bias visualizer](/artifact-gallery/captures/bias_visualizer/front.png)

*embedding_space(words, gender_axis) -> proximity_reveals_prejudice*

Interactive visualization of statistical and algorithmic bias — demonstrates how initial conditions, training data, or parameter choices create systematic skew in outputs. A critical theory artifact making invisible biases tangible.

> classification systems do not describe the world — they encode whose categories get to count

### The Walk — first steps

*8 room(s) in this chapter; none written yet.*

**godel statement plaque**

![godel statement plaque](/artifact-gallery/captures/godel_statement_plaque/front.png)

*G: ¬∃p: Proves(p, G) — a sentence that asserts its own unprovability*

Self-referential plaque cycling through increasingly paradoxical statements, culminating in Gödel's incompleteness

> every sufficiently powerful formal system contains true statements it cannot prove — completeness and consistency are mutually exclusive

**rhizome cave demo**

![rhizome cave demo](/artifact-gallery/captures/rhizome_cave_demo/front.png)

Rhizomatic cave — Deleuze-inspired branching cave generation using growth patterns + marching cubes.

**MolecularDesigner**

![MolecularDesigner](/artifact-gallery/captures/MolecularDesigner/front.png)

*catalog(parts) + assembly(bonds, positions) -> molecular morphology*

Interactive molecular construction tool — atoms snap to valence rules, bonds obey geometry, and molecular structure emerges from chemical constraints. Formalization as hands-on building.

> form is not imposed on matter — it is a conversation between catalog and constraint

**schrodinger box**

![schrodinger box](/artifact-gallery/captures/schrodinger_box/front.png)

*|ψ⟩ = α|alive⟩ + β|dead⟩ → observation collapses to |alive⟩ or |dead⟩ with P = |α|²*

Schrödinger's cat thought experiment - superposition collapses upon observation

> observation does not reveal a pre-existing state — it creates one

**superposition display**

![superposition display](/artifact-gallery/captures/superposition_display/front.png)

*|ψ⟩ = α|0⟩ + β|1⟩; α oscillates as sin(t·speed), β = 1 - α; both states simultaneously present*

Interactive visualization of quantum superposition |psi> = alpha|0> + beta|1> with VR slider to control the amplitude ratio between basis states.

> superposition is not uncertainty about which state the system is in — it is the system genuinely being in both

### The Walk — further in

**florensky sphere**

![florensky sphere](/artifact-gallery/captures/florensky_sphere/front.png)

*A ∧ ¬A — paraconsistent logic; truth that holds contradiction without triviality*

Paraconsistent logic sphere - holds A and not-A simultaneously without collapse

> A and not-A can both be true — this is not a failure of logic but a description of reality that classical logic cannot contain

**qfep formula 3d**

![qfep formula 3d](/artifact-gallery/captures/qfep_formula_3d/front.png)

*TextMesh("QFE = F - lambda*E(S) + phi*delta_E(S,t)") with per-term color and pulse animation*

3D visualization of the complete QFEP formula: QFE = F − λE(S) + φΔE(S,t). Each term glows with its signature color. Responds to lambda and phi slider changes. The theoretical anchor.

> QFE = F - lambda*E(S) + phi*delta_E(S,t) is not an equation to solve but a lens through which to see every system

### The Turn — parameters

Open in the dressing-room viewer: bias visualizer, godel statement plaque, rhizome cave demo, MolecularDesigner.

### The Critical Reading

QFEP term: **Edge**

After the foundations crisis, these maps explore what happens when incompleteness, bias, and rhizomatic thinking become design materials rather than problems to solve.

The artifacts' own claims:

> classification systems do not describe the world — they encode whose categories get to count — *bias visualizer*

> every sufficiently powerful formal system contains true statements it cannot prove — completeness and consistency are mutually exclusive — *godel statement plaque*

> form is not imposed on matter — it is a conversation between catalog and constraint — *MolecularDesigner*

> observation does not reveal a pre-existing state — it creates one — *schrodinger box*

> superposition is not uncertainty about which state the system is in — it is the system genuinely being in both — *superposition display*

> A and not-A can both be true — this is not a failure of logic but a description of reality that classical logic cannot contain — *florensky sphere*

> QFE = F - lambda*E(S) + phi*delta_E(S,t) is not an equation to solve but a lens through which to see every system — *qfep formula 3d*

### In the World

| Room | Grid | Artifacts | Footprint |
|------|------|-----------|-----------|
| CriticalAlgorithms_Algorithmic_Bias_Visualization | 8×9 | 3 | 5.9 m |
| CriticalAlgorithms_Applied_Ethics | 9×10 | 3 | 3.0 m |
| SpeculativeComputation_Paraconsistent_Engineering | 10×10 | 4 | 2.8 m |
| SpeculativeComputation_Situated_Computation | 10×10 | 4 | 4.8 m |
| SpeculativeComputation_Collective_Knowledge | 11×11 | 4 | 5.6 m |
| SpeculativeComputation_Rhizome_Network | 10×10 | 1 | 0.0 m |
| AdvancedLaboratory_Lab_Equipment_Simulation | 9×8 | 1 | 3.1 m |
| PostCrisis_Synthesis | 14×14 | 5 | 6.1 m |

What this chapter teaches, walked rather than read:

- Algorithmic bias as structural incompleteness in classification systems
- Ethics as the shape of the room, not a post-processing filter
- Paraconsistent engineering — holding contradiction without collapse
- Situated computation — knowledge always has a body, a place, a time
- Collective knowledge and the commons as responses to incompleteness
- Rhizomatic networks as non-hierarchical alternatives to tree structures
- Molecular design as embodied formal systems
- Synthesis: the edge is the ground, not the limit

### The Seed

> **Knowing the limits of formalization, what do we build?**

Exercises:

1. Algorithmic bias as structural incompleteness in classification systems
2. Ethics as the shape of the room, not a post-processing filter
3. Paraconsistent engineering — holding contradiction without collapse
4. Situated computation — knowledge always has a body, a place, a time
5. Collective knowledge and the commons as responses to incompleteness
6. Walk CriticalAlgorithms_Algorithmic_Bias_Visualization in VR and find where the rule first breaks its own pattern.
7. Open bias_visualizer in the dressing-room viewer and change one parameter until it stops being itself.

### The Ledger

- **the dig** — 8 of 12 artifacts excavated; 4 remain at depth.

## The basement

Everything below is why the rest of this is possible. None of it is on the path, and nothing in the museum will ask you for it. It is written down so that the building is known to have a basement — a museum with one it never mentions is a museum of magic.

- **the XR runtime** — Museum infrastructure. It is why you have hands.
- **the rendering pipeline** — Deep background. It is why you can see.
- **CPU instructions** — Very deep background.
- **electricity** — Cosmological basement.
