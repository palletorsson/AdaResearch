# Vector Algorithms Collection

Immersive VR-first demonstrations that connect vector mathematics to spatial intuition. Every scene uses the shared draggable arrow primitive located at `res://commons/primitives/line/line.tscn`, now updated with an arrowhead and live magnitude display.

## Scenes
- **Vector Basics** - Magnitude, normalization, and axis components. `res://algorithms/vectors/01_vector_basics/VectorBasics.tscn`
- **Vector Addition** - Tip-to-tail resultant construction. `res://algorithms/vectors/02_vector_addition/VectorAddition.tscn`
- **Dot Product & Projection** - Parallel/perpendicular decomposition. `res://algorithms/vectors/03_dot_product/VectorDotProduct.tscn`
- **Vector Subtraction** - Adding the opposite and relative displacement. `res://algorithms/vectors/04_vector_subtraction/VectorSubtraction.tscn`
- **Vector Forces & Newton's Law** - Force controllers inspired by *The Nature of Code*. `res://algorithms/vectors/05_vector_forces/VectorForces.tscn`
- **Cross Product & Oriented Area** - Surface area and right-hand normals. `res://algorithms/vectors/06_vector_cross_product/VectorCrossProduct.tscn`
- **Projection & Reflection on a Plane** - Surface normals and mirror vectors. `res://algorithms/vectors/07_vector_projection_reflection/VectorProjectionReflection.tscn`
- **Motion Vectors & Kinematics** - Acceleration-driven dynamics with live velocity readouts. `res://algorithms/vectors/08_vector_motion/VectorMotion.tscn`
- **Torque & Moment Arm** - Rotational effects from `tau = r x F`. `res://algorithms/vectors/09_vector_torque/VectorTorque.tscn`
- **Vector Field Flow** - Particle advection through a dynamic field. `res://algorithms/vectors/10_vector_field_flow/VectorFieldFlow.tscn`

## Core Concepts Covered
- Vector magnitude, direction, and normalization
- Addition, subtraction, and component decomposition
- Dot and cross products, projections, and angle relationships
- Surface reflections, oriented areas, torque, and right-hand normals
- Force accumulation, drag, and acceleration-driven motion
- Vector fields and particle advection

Each scene is designed for VR controllers but remains keyboard friendly (`R` reset, `Space` pause forces). Use the glowing spheres on the arrow heads to drag vectors through space and observe the immediate feedback projected nearby.
