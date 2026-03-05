# Constraints

A hinge allows one rotation. A slider allows one translation. A ball-and-socket allows three. Every joint is a statement about what motion is permitted — which means every joint is a statement about what motion is forbidden.

Pendulum chains swing from anchors. Rope bridges sag under load. Ragdolls collapse through hierarchies of restricted freedom. Slider rails enforce linearity. Doors swing on invisible axes. Spring-damper systems fight between compliance and resistance. Each demonstration strips degrees of freedom from rigid bodies until what remains is behavior — not programmed, but geometrically inevitable.

The constraint solver works by projection. A body drifts into an illegal state; the solver maps it back onto the constraint manifold. Every frame, violation and correction. The physics engine doesn't simulate freedom — it simulates the reduction of freedom until only the possible remains. Identity is what's left when you subtract everything a body cannot do.