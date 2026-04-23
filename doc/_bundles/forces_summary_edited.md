<<<ADA_BUNDLE>>>
sequence: forces
file: summary.md
maps: 10
skipped_passing: 0
created: 2026-04-23T19:12:09
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: VectorFoundations>>>
# Vector Foundations — Summary

VectorFoundations opens the Vectors and Forces sequence. Three small islands float in open space, each teaching one fragment of the same grammar: what a vector is, how vectors add, and how they decompose. The map treats these as hands-on instruments rather than textbook definitions.

The first island plants three basis vectors in the ground. One points east, one up, one north. The learner grabs any point in the space and the map labels it as a combination of those three arrows: P = xi + yj + zk. Moving the point updates the coefficients live. Basis is shown as the minimum equipment needed to name a location at all.

The second island stacks vectors tip to tail. The learner drags a red arrow, then a blue one, and the green resultant that closes the triangle is drawn automatically. Stretching either input rescales the resultant. The parallelogram rule appears as a visible consequence, not a memorised identity.

The third island runs the operation in reverse. A single vector projects shadow components onto each axis; sliders decompose the vector back into its parts. A becoming_catalyst pickup sits at the edge of this island, handing the learner the force-related tool that every later map in the sequence will extend.

Within the sequence, this is the grammar lesson. The next map takes these three moves and turns them into operations with consequence — dot, cross, and projection.

<<<MAP: VectorOperations>>>
# Vector Operations — Summary

VectorOperations turns vectors from arrows into operators. Three islands teach the three operations that make vectors useful: dot product, cross product, and projection. Each operation is demonstrated on a pair of draggable arrows, with a readout that updates as the arrows move.

On the first island, two arrows meet at the same root. A projection tool drops the shadow of one onto the other, and a scalar panel reads out A · B = |A||B|cos(θ). Turning one arrow toward the other drives the dot product toward its maximum; rotating it perpendicular drives the value to zero. Alignment becomes a number you can watch.

The second island holds a cross-product rig. Two input arrows lie in a plane; the cross product rises out of that plane at a right angle, its length equal to the area of the parallelogram the inputs would span. Reversing the input order flips the result, so the handedness of the operation is visible rather than memorised.

The third island grounds the abstractions in a small mechanical scene. A ball rests on an inclined surface. Gravity decomposes into a component parallel to the slope and a component perpendicular to it. The parallel component moves the ball; the perpendicular component meets the normal force and cancels. The projection tool from the first island is the same tool doing this decomposition.

Within the sequence, this map converts notation into behaviour. VectorApplied will use it next to aim turrets, drive weather, and fill space with instructions.

<<<MAP: VectorApplied>>>
# Vector Applied — Summary

VectorApplied is the map where vector operations stop being demos and start doing jobs. Three stations in an open space put the learner to work using the dot and cross products and the projection tool from the previous maps.

The first station is a turret. A target drone moves through the space; the turret needs a firing direction. The map shows the operation explicitly: subtract the turret position from the target position, normalise, and you have a unit vector that points from one to the other. A dot-product check against the turret's current facing decides whether a shot can fire. The arithmetic is visible on a panel above the gun.

The second station is a small weather system. Three vector fields — gravity, wind, and turbulence — are superposed, and a swarm of light particles drifts through their sum. Each field can be toggled, and the particles redraw their paths as soon as the composition changes. The map argues that superposition is the usual case, not the exception.

The third station is a field visualiser. A cubic grid of arrow glyphs fills a volume, and the learner selects between gravitational, electric, and magnetic fields. The arrows change length and orientation to match. Placing a small test mass anywhere in the grid plays its motion along the field.

Within the sequence, this is where the learner leaves pure geometry for application. VectorAdvanced will extend the same operations into rotation, attraction, and embodied throwing.

<<<MAP: VectorAdvanced>>>
# Vector Advanced — Summary

VectorAdvanced pushes vectors from observation to action across four islands linked by bridges. Each island takes one concept — torque, bouncing and acceleration, attraction and steering, or throwing — and stages it as a practice ground.

On the torque island, the learner drags a force vector off-centre on a free-spinning object and watches the cross product compute the resulting rotational impulse. Shifting the application point changes the torque; reversing the force reverses the spin. A field-flow panel alongside shows why the cross product produces an out-of-plane vector.

The bouncing island runs a small simulation of a ball under random acceleration. Each bounce projects the incoming velocity onto the surface normal, reflects it, and plays the result. The map marks the reflection operation explicitly so the learner can see the same projection tool from earlier maps doing the collision.

The attraction island holds a grabbable attractor that pulls a satellite body into orbit. Dragging the attractor reshapes the orbit in real time. The steering demo next to it shows a small agent using the desired-velocity vector to steer toward a moving target, substituting one vector for another each frame.

The fourth island turns the learner into the experiment. Picking up a ball and throwing it records the release vector and draws it as a live arrow, so muscle memory and maths share a display.

Within the sequence, this map ends the pure-vector sub-sequence and hands the tools to the forces half.

<<<MAP: ForcesFoundations>>>
# Forces Foundations — Summary

ForcesFoundations grounds Newton's three laws in three physical scenes. The map is arranged as three islands connected by a jump pad, and the jump pad is part of the lesson: the learner does not walk across, they are thrown across, and the throw is a force applied over a short interval.

The first island hosts Newton's laws as interactive demonstrations. A sliding block resists a push; raising its mass raises the force required to accelerate it, and the F = ma relationship is live on a panel. An action-reaction rig pairs two carts on a shared spring so the learner can feel the symmetry of the third law. A low-friction track makes inertia visible as continued motion in the absence of force.

The second island is a projectile range. Cannons of adjustable muzzle velocity launch objects along parabolic trajectories. The learner studies the paths at range, then walks onto the jump pad and becomes the projectile — arcing across the gap to the third island with initial velocity and gravity as the only inputs.

The third island introduces friction and drag. A ramp lowers at an adjustable angle, and surface-property sliders change the coefficient of friction between block and slope. Air drag on a falling mass is tuned separately. The learner can stage the same trajectory on two surfaces and watch how motion degrades differently under each.

Within the sequence, Foundations sets the vocabulary that ForcesComposition and ForcesSystems will compound.

<<<MAP: ForcesComposition>>>
# Forces Composition — Summary

ForcesComposition brings every vector operation from the previous maps together on one table. Two draggable arrows, A and B, sit in a shared workspace. A panel next to them shows their addition, subtraction, dot product, cross product, projection, and reflection simultaneously, each computed from the current positions.

The workspace is deliberately uncluttered. As the learner rotates A, every derived quantity updates: the dot product rises and falls, the cross product flips when the angle crosses 180 degrees, the reflection pivots across A's axis, the projection slides along it. Labels on each output name the operation and the formula. Sliders adjust the magnitudes of A and B independently.

A small demonstration on one side extends the table to dynamics. Several force arrows attach to a single body; their sum is drawn in a contrasting colour as the net force. Adding or removing a force changes the sum immediately. The body accelerates along the net vector, so the learner sees superposition as the rule that turns any set of pulls into a single trajectory.

Within the sequence, this is the consolidation map. It closes the pure-vector half of the curriculum and hands the learner a single consolidated toolkit for the systems maps that follow.

<<<MAP: ForcesSystems>>>
# Forces Systems — Summary

ForcesSystems arranges four force regimes around a clockwise loop of islands, each connected by a jump pad. The loop is the lesson: the same vector primitives produce very different global behaviours depending on how they are organised across a population of objects.

The first island holds attractors. A central mass pulls a set of satellites into orbits; the learner can add or remove attractors and watch the orbits reshape. The second island renders a full vector field as a grid of arrows; test particles released into the field ride the streamlines the arrows describe. Superposition of two fields is toggled with a switch so the learner can compare one-field and two-field regimes.

The third island runs an array of coupled springs. A row of masses connected by identical springs oscillates according to Hooke's law. Striking one mass sends a wave down the row; the map reads off wavelength, amplitude, and damping. The fourth island runs a particle system of many independent agents under shared random forcing. No single particle is remarkable; the aggregate shape is.

Within the sequence, Systems is where single-object dynamics give way to population behaviour. ForcesChaos will next exploit the fact that some of these systems have no closed-form solution at all.

<<<MAP: ForcesChaos>>>
# Forces Chaos — Summary

ForcesChaos presents two islands of nonlinear dynamics with a long jump between them. The physical gap is the argument: small rules produce behaviour that outruns analytical solution, and the learner's ballistic crossing is a small enactment of that gap.

The first island holds gravitational simulations. A two-body system settles into stable orbits; a three-body system does not. The map runs the three-body simulation live, with sliders for each mass and each initial velocity. A small perturbation to any slider sends a previously stable configuration into ejection, collision, or slow precession. An n-body variant with a larger swarm shows the same sensitivity scaled up.

The second island hosts strange attractors. The Lorenz, Rössler, and Aizawa systems draw their trajectories in 3D space, so the learner can walk through the butterfly shape and see how two nearby starting points diverge. Alongside the attractors, a force-directed graph layout lets the learner grab nodes and watch a network of repulsions and attractions find a local minimum.

Within the sequence, Chaos marks the point where prediction gives way to description. ForcesArena will next ask the learner to act under these conditions rather than only observe them.

<<<MAP: ForcesArena>>>
# Forces Arena — Summary

ForcesArena is the sequence's closing map. Three large arenas sit connected by long jump pads, each asking the learner to apply accumulated vector and forces knowledge under pressure rather than in demonstration.

The first arena is a drone-combat range. An enemy drone moves, aims, and fires using the same subtraction, normalisation, and dot-product operations the learner studied in VectorApplied. The learner does the same to return fire. The maths is visible on a side panel, so the combat doubles as an open-book exam.

The second arena is a physics sandbox. Objects under impact decompose through one of eight fracture algorithms — Voronoi partitioning, Cantor recursion, planar cuts, constructive-solid-geometry booleans, and four others — each selectable from a control at the entrance. The learner hurls objects, triggers fractures, and compares how different rules cut the same geometry.

The third arena is an exhibition gallery. Every vector and force artifact built across the sequence is placed on a plinth with a short label. Walking the gallery is the sequence's self-review; the learner can pick up any of the tools and drop it back into play.

Within the sequence, Arena is the synthesis. It names what was learned by asking the learner to use it.

<<<MAP: Chamber_Forces>>>
# Chamber Forces — Summary

Chamber_Forces is the catalyst chamber for the Forces sequence. It is the last map before the learner returns to the Lab and the first map where force stops being aimed at targets and becomes a way of relating to another creature.

The chamber is small and amber-lit. A kresling_spire creature drifts around the space, unsettled on approach. The learner holds the force catalyst, which projects a slow, steady field rather than an impulse. Entering the field does not strike the creature; it slows it. The kresling eases out of its defensive posture as the field stabilises around it.

A science screen on one wall reads out both bodies as points in a small two-body system. The screen labels the interaction as a mutual force: the learner's projection pulls on the creature, and the creature's mass pulls back. Newton's third law is the chamber's hinge, reframed from a mechanical identity into a practice of contact.

Within the sequence, Chamber_Forces closes Forces by converting the accumulated vocabulary — fields, superposition, reaction — into a relationship with a creature the learner can calm rather than push. The chamber hands the learner back to the Lab with the force catalyst in their kit.
