# Explore vector magnitude and direction — Summary

## The arrow

Everything in 3D space that moves, pulls, pushes, or points is a vector. Not a number. Not a scalar sitting alone on a number line. A vector carries two pieces of information simultaneously: how much and which way. Magnitude and direction, fused into a single object. A scalar says "five." A vector says "five, northeast, climbing." That directional encoding changes everything.

Position is a vector — displacement from an origin. Velocity is a vector — speed with a heading. Acceleration is a vector. Force is a vector. The entire grammar of physics speaks in directed quantities. Strip the direction and you lose the physics. Keep only the direction and you lose the scale. The vector holds both, irreducibly.

Graphically, a vector is an arrow. The tail sits at a point; the head points somewhere else. The length of the shaft encodes magnitude. The orientation encodes direction. This is not metaphor — it is literal representation. Every vector visualization in every physics engine, every textbook, every simulation renders the same primitive: a line segment with a pointed end. The arrow is the vector's body.

## Components

A vector in three-dimensional space decomposes into three numbers: x, y, z. These are its components — projections onto each coordinate axis. The vector v = (3, 4, 0) means: three units along x, four units along y, zero along z. The components are not the vector. They are the vector's address in a particular coordinate system. Change the coordinate system, the components change. The vector itself — the arrow in space — does not.

This distinction matters. Components are frame-dependent. The arrow is frame-independent. A force pushing a box doesn't care what coordinate system an observer chooses. The push is the push. But to compute with that push, to simulate it, to render it — components are required. Computation demands decomposition.

The Basis Vectors Rig makes this decomposition tangible. Three arrows — î along x, ĵ along y, k̂ along z — define the coordinate frame. Each has unit length: magnitude one, pure direction. Any point P in space is a linear combination of these three basis vectors: P = xî + yĵ + zk̂. The rig shows the component lines stretching from each axis to the target point, tracing the rectangular path through space. The point is not on any axis. It is the sum of contributions from all three.

Basis vectors are the alphabet. Components are the spelling. The vector is the word.

## Magnitude

Given components, magnitude falls out of geometry. For v = (x, y, z), the magnitude |v| = √(x² + y² + z²). Pythagoras, extended to three dimensions. The formula measures the length of the arrow — the straight-line distance from tail to head.

Magnitude strips direction. It collapses the vector to a scalar — a single number representing intensity, strength, distance. Speed is the magnitude of velocity. The magnitude of a force vector is how hard the push. Magnitude answers "how much" by forgetting "which way."

A unit vector has magnitude one. It is pure direction, no intensity. Any vector divided by its own magnitude becomes a unit vector: v̂ = v / |v|. This operation — normalization — separates the two components of vectorness. Direction gets isolated. Magnitude gets discarded. Then they can be recombined at will: any vector equals its magnitude times its direction. v = |v| · v̂. Decomposition and recomposition. The vector's anatomy, laid bare.

## The coordinate frame as assumption

The Basis Vectors Rig encodes something subtle. The three arrows — red, green, blue for x, y, z — look natural. Obvious. Of course space has three perpendicular axes. But those axes are a choice. The coordinate system is not given by space itself. It is imposed by the observer.

In QFEP terms, the coordinate system is structure — pure F. It is the frame that makes measurement possible, the order that converts continuous space into discrete components. At λ = 0.3, this map sits firmly on the ordered side. Low entropy. High predictability. The basis vectors are rigid, orthogonal, fixed. Nothing fluctuates.

This rigidity is the point. Before anything can oscillate, flow, or dissolve, the frame must exist. Before forces drive temporal evolution — the φ·ΔE(S,t) term that animates physics — the state space must be defined. Vectors define that state space. They are the S in the free energy equation. Position, velocity, configuration — all encoded as vectors, all measured against a basis.

The coordinate system is the first assumption. Every assumption that follows — about motion, about forces, about dynamics — inherits its frame. Choose different basis vectors, get different components, same physics. The invariance of physical law under coordinate transformation is one of the deepest principles in science. It starts here, with three colored arrows and a target point.

## From primitives to arrows

This map builds on primitives and transformation. Primitives gave geometric objects — meshes, shapes, bodies in space. Transformation gave operations on those objects — translation, rotation, scale. Vectors formalize what transformation already implied. Translation is a vector. The axis of rotation is a vector. Scale factors along each axis are components of a vector. Every transformation encountered so far was already vector arithmetic, unnamed.

Now it gets named. The informal becomes formal. The intuitive becomes computable.

## What follows

VectorSubtraction comes next — the difference between two vectors, which yields displacement, relative position, the gap between here and there. Then addition, dot product, cross product. Each operation builds on components and magnitude. Each reveals new geometric meaning. Dot product measures alignment. Cross product generates perpendicularity. Projection and reflection handle collisions and mirrors.

Beyond vector operations, the sequence moves into forces. F = ma. Acceleration is a vector. Force is a vector. Mass is a scalar that mediates between them. The entire apparatus of Newtonian mechanics — gravity, friction, springs, attraction, repulsion — is vector arithmetic applied to time-evolving systems. The dt in v += a·dt is where vectors meet dynamics, where static arrows become trajectories.

Vectors unlock physics simulation, swarm intelligence, soft bodies. Every agent in a swarm has a velocity vector. Every vertex in a soft body has a position vector acted on by force vectors. Every particle in an N-body system computes gravitational vectors to every other particle. The arrow is the primitive of motion.

## The dark sphere

The Dark Sphere floats in the map — pulsing purple emission, slow rotation. An ambient marker. It is not a vector. It is a point of presence, an atmospheric anchor, a reminder that the space being formalized is also a space being inhabited. The sphere rotates, the glow breathes, and the coordinate axes hold still. Order and oscillation, already coexisting. λ = 0.3, but the pulse hints at what comes next.

## Ground

A vector is the simplest object that encodes both quantity and direction. Three components, one magnitude, one heading. From this, all of physics. The basis vectors are not discovered — they are declared. The coordinate system is not found — it is built. Every measurement that follows depends on a frame that was chosen, not given. The arrow points. The question is always: who drew the axes.