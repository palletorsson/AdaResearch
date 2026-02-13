# PhysicsSim_Bodies - Critical Reflection

## The Core Tension

A rigid body is a thing that *refuses to deform*. It is the idealized, perfect solid — infinitely stiff, internally consistent, unchangeable. Every part of it moves exactly together. There is no give, no flex, no yield.

This is a profoundly normative concept. It defines the default simulated object as one that maintains its shape under all circumstances — that resists the world's attempts to change it. The rigid body is the physics engine's closet: a container that holds its form by refusing internal complexity.

## What This Concept Normalizes

**Rigidity as default.** In the simulation sequence, rigid bodies come first (after foundations). Deformable bodies (springs, cloth, fluids) come later, as complications. This teaches a hierarchy: rigid is normal, deformable is special. But in the physical world, *nothing* is truly rigid. Every material deforms under force — steel bends, diamond cracks, concrete flows on geological timescales. Rigidity is an approximation so convenient that it became ontology.

**Binary collision.** Collision detection returns a boolean: colliding or not colliding. Two objects either touch or they don't. There is no "almost touching," no "ambiguously overlapping," no gradient of contact. This binary logic maps uncomfortably onto cultural binaries — in/out, same/different, self/other. The collision normal defines a clear boundary: here is me, there is you.

**Coefficient of restitution.** The bouncing ball's "bounciness" is a single number between 0 and 1. This quantifies how much energy survives a collision — how much of the encounter you retain. A perfectly elastic collision (e=1) means nothing is lost; a perfectly inelastic collision (e=0) means everything is absorbed. But real encounters are more complex than a scalar. What is gained? What is transformed? What is exchanged?

**Constraints as restriction.** The map presents constraints as things that *limit* degrees of freedom. A hinge removes all but one rotational axis. A ball joint removes translational freedom. Constraints are presented as reduction — as taking things away. But constraints also *enable*: a hinge enables a door; a joint enables an arm. The map's framing of constraints as restriction rather than enablement reflects a particular (negative, limiting) view of structure.

## The Body and Collision

VR changes collision from abstraction to experience. When a simulated rigid body hits a wall, the player doesn't compute an impulse vector — they *see* the bounce, *feel* the stop (if haptics are enabled), *anticipate* the deflection. The body knows collision before the math.

But whose collision? The simulation assumes that all bodies collide the same way — same detection algorithm, same response impulse. There is no concept of *differential* collision, of different bodies experiencing contact differently. A collision between two rigid bodies is symmetric: same force, opposite direction (Newton's Third Law). But in embodied experience, collisions are asymmetric — who gets hurt depends on who is harder, heavier, moving faster. Power differentials vanish in the math.

The bouncing ball — the "hello world" of physics — is particularly telling. It is a sphere: the most symmetric object, with no orientation, no face, no distinguishing features. It is the default object stripped of all identity. Its collision with the ground is the simplest possible encounter between self and world: a brief contact, a loss of energy, a return to flight. It is depersonalized physics.

## Historical/Political Context

**Rigid body mechanics was the physics of war.** Cannonballs, projectiles, battering rams — the first rigid bodies studied were weapons. The abstraction of "rigid body" emerged from the need to predict where objects of destruction would land. Every rigid body simulation carries this genealogy.

**Collision detection is a surveillance problem.** "Are these two things touching?" is the fundamental question of boundary enforcement. Broad-phase culling (quickly eliminating pairs that *can't* collide) is triage. Narrow-phase testing (precisely determining contact) is inspection. The two-phase approach — filter, then examine — mirrors security architectures, immigration systems, and panoptical logics.

**Constraints were formalized for machines.** Joints, hinges, sliders — the vocabulary is industrial. The rigid body constraint system is a model of the factory: objects connected by fixed relationships, each performing its designated range of motion. There is no improvisation in a constraint system. Each body does what it is allowed to do.

## Queer Bodies (Rigid and Otherwise)

**Rigidity as identity.** The rigid body assumes a fixed shape — an essence that persists through all interactions. Queer theory has long critiqued this kind of essentialism. Identity is not a rigid body; it deforms under social pressure, reshapes through encounter, flows between states. A simulation that can only represent rigid bodies can only represent fixed identities.

**Collision as encounter.** Sara Ahmed writes about "being stopped" — the experience of bodies that don't flow smoothly through institutional spaces. Collision detection is the computational version of being stopped: a boundary is enforced, motion is redirected. The question "are these two touching?" is not neutral when some bodies are stopped more than others.

**Constraints as closet.** The constraint system restricts degrees of freedom — removes possibilities, narrows the range of motion to what is "allowed." This is the logic of the closet, the dress code, the gender norm: you may move, but only within these bounds. Queering constraints would mean asking: what if the constraint is the thing to be broken? What if the hinge was never necessary?

**The bouncing ball as assimilation.** The ball falls, hits the ground, loses energy, bounces lower and lower, and eventually comes to rest — perfectly still, at the lowest point, motionless. This is the physics of normalization: every encounter with the boundary (the ground, the norm) drains energy until the deviant motion is fully absorbed. The ball doesn't escape. It doesn't tunnel through. It doesn't transform. It just... stops.

What would a queer bouncing ball look like? One that *gains* energy from collision? One that changes shape on impact? One that merges with the ground instead of bouncing off?

## QFEP Connection

In the Queer Free Energy Principle, rigid bodies represent low-entropy, high-stability states — deep attractors that resist perturbation. They maintain their internal configuration (shape, mass distribution) by refusing to engage with deforming forces.

The **inertia tensor** — the resistance to angular acceleration — is a QFEP concept. It measures how much a body resists being *changed*. A sphere has uniform inertia (equal resistance in all directions). A long thin rod has highly anisotropic inertia (easy to spin one way, hard another). The inertia tensor is a map of rigidity — of which changes are easy and which are hard. In QFEP terms, it defines the free energy landscape of the body's rotational identity.

**Collision response** is the moment of maximum free energy change. Two bodies meet, exchange impulse, separate. In QFEP, this is the encounter that forces both systems to update their models. The coefficient of restitution determines how much of the encounter survives: e=1 means the encounter was fully elastic (nothing absorbed, nothing changed); e=0 means the encounter was fully plastic (everything absorbed, permanent deformation of trajectory). Most encounters are in between — some change, some persistence.

The constraint system defines the **boundary conditions** of the free energy landscape: not all configurations are accessible. Joints restrict the topology of configuration space. In QFEP terms, constraints define which states the system *can't* reach — the forbidden configurations, the impossible identities. Queering constraints means asking whether those boundaries are necessary or imposed.

## Conclusion

The arena is dark, theatrical, dramatic. Objects crash under spotlights. This is physics as spectacle — collision as entertainment. But every crash encodes assumptions: that bodies are rigid, that collisions are binary, that constraints are restrictions, that energy always dissipates toward rest.

The bouncing ball comes to rest. The rigid body maintains its shape. The constraints enforce their limits. This is the physics of normalization. The question the critical viewer carries to the next map (Springs) is: what happens when bodies are allowed to *deform*?
