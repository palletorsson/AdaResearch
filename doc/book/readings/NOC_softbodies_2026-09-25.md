# What the soft-body chapters can learn from *Nature of Code* ch. 6

Read 25 September 2026 against the nine `final.md` of the `softbodies` sequence (3,558 words: Soft_Body_Deformation 358 · Cloth_Physics 796 · Carusell 322 · Obsticals 330 · Obsticals_Part2 292 · Playground_of_Joy 476 · Affect_Theory_Visualization 297 · Reaction_Diffusion 371 · Topology_Entropy_Morphogenesis 316) and, for the Verlet half of the chapter, the six of `formfinding` (6,329 words; all eighteen of its tasks closed by Codex). Source: https://natureofcode.com/physics-libraries/ (Daniel Shiffman, 2nd ed., ch. 6 "Physics Libraries", about 18,400 words: why an engine (collisions), Matter.js bodies, static bodies, compound bodies and the misdrawn lollipop, constraints (distance, revolute, mouse), forces at a point, collision events, the integration interlude (Euler, symplectic Euler, Runge–Kutta, Verlet, Jakobsen), Toxiclibs springs, string, cloth, the soft-body character and its internal springs, force-directed graphs, attraction behaviours). Code read: `jelly_cube.gd`, `cloth_straps.gd`, `revolving_joy_ride.gd`, `breathing_room.gd`, `rounded_softbody.gd`, `frozen_glass_vessel.gd` (with `commons/soft_body/soft_body_sim.gd`), `verlet_workbench.gd`, `radiolaria.gd`. No agents.

## Where Ada is ahead

NOC's chapter teaches two libraries' vocabularies; Ada's halls stand inside Godot's soft-body solver and ask what it is doing to a body, with the visitor's body as the second instrument:

- **Boundary conditions as the subject.** Cloth_Physics takes the gantry away and the cloth goes on hanging: "the frame is not a party to the arrangement." Then PINS from eight to two, then RELEASE. NOC has `lock()` as a mechanic and never asks what a pin is.
- **Pressure.** Jelly's PRESSURE and the breathing room's sine-driven walls. NOC has no pressure at all; its soft bodies are held open by internal springs.
- **Stopping as an act.** The stop scene "raises damping and stiffness rather than recording the vertex positions"; the vessel's "clock is part of the genome." NOC never stops a simulation.
- **A seed that does not promise the same physics twice.** Obsticals_Part2: "A fixed seed repeats a recipe for initial conditions; it does not promise bit-for-bit identical physics on every computer." NOC has no reproducibility at all.
- **The instrument that acts back.** Playground's FEEDBACK drives pressure toward a recorded volume and the chapter says what the instrument measures (the axis-aligned box, not the enclosed space).
- **Units.** The carousel's rate is radians per second; the strips are a forearm wide and twice your height. NOC's Matter.js world is pixels; it praises Box2D for metres and kilograms and then declines them.
- **Form finding already has the whole Verlet half:** the bench's PASSES (nudged 1 · worked 4 · pressed 8 · held 12), the MEAN/WORST spring errors, Verlet 1967 footnoted, the vessel as a fossil of forces. NOC's Toxiclibs section is that bench without the readouts.

## What to learn (eight items for soft bodies, two for form finding)

1. **STIFFNESS is a fraction, and the solver's effort is a pass count.** Godot's `SoftBody3D.linear_stiffness` is bounded 0..1, the same 0..1 "stiffness" NOC's constraints carry ("1 being fully rigid and 0 being completely soft", default 0.7): how much of a spring's error is corrected per pass, not a modulus. `jelly_cube.gd:193`, `cloth_straps.gd:360` and `breathing_room.gd:85` all set `simulation_precision = 5`, the pass count, which no panel shows. Form Finding's bench put exactly that knob on a panel and showed a cloth stiffen with passes alone; the soft-body halls never say the engine's solver is the same kind of thing.
2. **What holds the cube together.** The hall's title question. The SoftBody3D's springs are the edges of the subdivided box, the surface only; nothing crosses the inside. NOC's soft-body character: perimeter-only springs "would instantly collapse onto itself. This is where additional internal springs come into play." Godot's answer is pressure instead of struts, and the artifact's own header says what happens without it: "at low pressure it drapes over the pedestal like cloth."
3. **The hand is the body that teleports.** NOC's mouse constraint: assign a body's position and "Matter.js no longer knows how to compute the physics properly… tie a string"; Toxiclibs' `lock()`/`unlock()`. A tracked hand is a position written every frame, the one body the solver cannot push. Jelly meets it as a collider (`collision_mask` includes the hand layers); the rounded body meets it as a push within 25 cm on grip (`_squeeze_radius 0.25`, `_squeeze_strength 2.0`). Neither can move the hand. Task .004 asks how a hand squeezes; this says what a hand is to a solver.
4. **The hinge and the kinematic hub.** Carusell: "its angle is advanced by the program." `revolving_joy_ride.gd`: a frozen kinematic RigidBody3D with `rotation.y += ride_speed * delta` each physics step; the links hang on `PinJoint3D` pairs, NOC's revolute constraint ("a regular Constraint of length 0… the bodies can rotate around a common anchor point"). The hub is the mouse constraint from the support's side: moved by assignment, pushed back by nothing.
5. **What ties the 112 points.** Cloth_Physics counts them; `cloth_straps.gd:351-354` makes them (a PlaneMesh subdivided 6 by 12: 8 × 14) and the springs are the triangle edges: across, down and one diagonal per cell. NOC's cloth exercise ties "vertical and horizontal neighbours" only; the diagonal is why a strip does not shear into a parallelogram.
6. **The vessel returns.** `frozen_glass_vessel` stands in FormFinding_Relaxation (index 7), where 300 words made it a fossil of forces and named its solver as the bench's (`soft_body_sim.gd`, `constraint_passes = 5`); Playground_of_Joy (index 15) meets it as a stranger.
7. **Put a hand to a spike.** `radiolaria.gd` builds no collision and no soft body; in the museum the forms are venues. NOC's lollipop drawn at the wrong centre: "you won't get an error… the world you're seeing won't be aligned with the world as Matter.js understands it." The Affect chapter argues the contrast; the hall can perform it in one gesture.
8. **The integrator interlude, as a name only.** NOC lists Euler, symplectic Euler (Box2D), Runge–Kutta and Verlet (Matter.js, Toxiclibs). Ada's halls run three integrators — Godot's soft body, the bench's Verlet, the carousel's rigid bodies — and the sequence never says a body's motion depends on which. Kept out of the tasks: Form Finding's Relaxation already carries the one that matters, and the rest is a list.

Form finding:

9. **Jakobsen beside Verlet.** Relaxation credits the position update to Verlet (1967) and the corrections to "this implementation". The pass-by-pass relaxation of distance constraints is Thomas Jakobsen's, "Advanced Character Physics" (2001), which NOC calls the paper "from which just about every Verlet computer graphics simulation is derived."
10. **The bench next door could hang the chain the cable only draws.** NOC's Example 6.12 hangs a bob from a string of particles. Catenary's honest object is a Bezier that "resembles a hanging cable because its maker supplied a rule for sag"; a row of the Relaxation bench's particles hung from two points would settle toward the curve the laundry lines evaluate, without being told `cosh`. The chapter's forward link points at the bench without saying so.

## Not to learn

- Two libraries' vector syntaxes; `Composite.add` and the body that was never added to the world (Ada's equivalent is the grid's own lane, already policed by the museum's walk model).
- Collision events and the `plugin` back-reference: engineering, not encounter.
- Force-directed graphs and attraction behaviours: graph theory's and swarm's, not this sequence's.
- Box2D's real units: Ada has them.

## Tasks

Eight tasks appended to `doc/tasks/book_softbodies.json` (`.015`–`.022`) and two to `doc/tasks/book_formfinding.json` (`.019`–`.020`), source "Nature of Code ch. 6 reading, 25 Sept", shown on `/book-tasks`. Not applied. The soft workshop console standing in every hall (`soft_workshop.gd`, untracked, claimed on forum 260923-n9p6t) is not touched or described.
