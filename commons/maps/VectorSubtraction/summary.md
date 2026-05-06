# Compact gallery for vector subtraction visualization - Summary

## The operation that finds distance

Addition combines. Subtraction separates. Where vector addition asks "what happens when two forces act together," vector subtraction asks something more fundamental: what lies between two points? How far apart are they, and in which direction?

Vector subtraction computes the difference. Given two vectors **A** and **B**, the result **A - B** produces a third vector — the displacement from B to A. Not a scalar distance. A directed distance. A vector that encodes both how far and which way. This is the operation that turns two positions into a relationship.

The formula is mechanical: subtract component by component. If A = (3, 5, 2) and B = (1, 2, 1), then A - B = (2, 3, 1). Simple arithmetic. But what that result *means* depends entirely on context. It could be the gap between two objects. The velocity needed to reach one from the other. The error between prediction and measurement. Subtraction is how systems compute discrepancy.

## Negation as geometric mirror

There is a deeper way to understand subtraction: A - B is identical to A + (-B). Negate B — reverse its direction, keep its magnitude — then add. This reframing matters because it reveals subtraction as addition in disguise. The gallery makes this visible. Vector B appears alongside its negation, -B, a ghost arrow pointing the opposite way. Placing -B head-to-tail with A produces the same result vector as subtracting directly.

Negation is a reflection through the origin. Every vector has an opposite — same length, reversed direction. This is not destruction. It is inversion. The operation preserves magnitude while flipping orientation, and that flip is what turns addition into subtraction. One operation, two interpretations. The arithmetic doesn't care which frame you use.

## What the gallery shows

The interactive demonstration presents three vectors simultaneously: A (the starting vector), B (the vector being subtracted), and C = A - B (the result). Drag the handles, change A or B, and the result updates in real time. The geometry is immediate — the result vector always connects the tip of B to the tip of A.

This is the key visual insight. The difference vector doesn't start at the origin. It starts at the end of B and points toward the end of A. It answers the question: standing at B, which direction do I face, and how far do I walk, to reach A? The coordinate axes on the base platform provide reference, but the real lesson is in the arrows themselves. Three vectors forming a triangle. Subtraction completes the triangle that addition opens.

The dark sphere sits in the space as an ambient marker — a point of orientation in the gallery. Its pulsing emission is atmospheric, not instructive. But it serves a spatial purpose: a fixed reference against which the moving vectors can be perceived. Stillness against motion. The sphere does not subtract. It witnesses.

## Relative position and why it matters

Nearly every useful calculation in 3D space requires subtraction at some point. To compute the direction from a camera to a target: subtract camera position from target position, then normalize. To find how far a projectile has traveled: subtract launch position from current position. To determine if an enemy is in front of or behind the player: subtract, then dot product with the forward vector.

Subtraction converts absolute coordinates into relative ones. Two objects can be anywhere in the world, but their difference vector exists independent of the coordinate system's origin. Move the entire scene — translate everything by the same amount — and every position changes, but no difference vector does. Relative position is invariant under translation. This is not a convenience. It is a mathematical fact that makes navigation, targeting, collision detection, and physics simulation possible.

In the QFEP framework, the system state S encodes positions and configurations. But states alone are inert. What drives change is the *difference* between states — the gap between where the system is and where it could be. Free energy minimization operates on discrepancy. Prediction minus observation. Expected minus actual. The φ·ΔE(S,t) term tracks how entropy changes over time, and that change is computed through differences. Subtraction is the arithmetic of becoming. Without it, systems cannot measure their own distance from equilibrium.

## From basics to cross products

This map sits between VectorBasics and VectorCrossProduct in the sequence. VectorBasics established the primitives — direction, magnitude, components, the arrow-in-space representation. Subtraction builds on that foundation by introducing the first *relational* operation between vectors. Addition was compositional: put two things together. Subtraction is comparative: measure the space between two things.

The cross product, which comes next, takes the relationship further. Where subtraction finds the vector *between* two vectors (in an arithmetic sense), the cross product finds the vector *perpendicular* to two vectors (in a geometric sense). Subtraction lives in the plane defined by A and B. The cross product escapes that plane entirely, producing something orthogonal to both inputs. But the cross product relies on subtraction internally — computing surface normals, torques, and angular relationships all require difference vectors as intermediate steps.

The sequence progresses from existence (a vector is) to relation (the difference between vectors) to generation (two vectors produce a third in a new direction). Each operation builds on the last. Each reveals more structure in 3D space.

## Difference as direction

The beginner-level difficulty here is honest. The arithmetic is simple. Component-wise subtraction requires nothing beyond what a child learns in primary school. But the *interpretation* — that subtraction produces direction, that negation is reflection, that relative position is translation-invariant — these ideas carry weight far beyond their mechanical simplicity.

Every guidance system, every pathfinding algorithm, every physics engine begins with subtraction. Where am I? Where do I want to be? Subtract. The result is the correction vector — the direction and magnitude of necessary change. Autonomous agents subtract their position from their goal to determine their heading. Springs subtract rest length from current length to compute restoring force. Neural networks subtract predicted output from actual output to compute error gradients.

Subtraction is how systems locate themselves relative to something else. Not where they are in absolute terms — that number is arbitrary, contingent on the choice of origin. But how far they stand from another state, and in which direction that state lies. Difference is the primitive of navigation. The vector that points from where you are to where you are not.