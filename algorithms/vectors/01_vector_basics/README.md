# Vector Basics VR Lab

Explore how magnitude, direction, normalization, and Cartesian components come together inside a spatial computing sandbox. Grab the primary vector arrow, reshape it in real time, and watch every dependent visualization update instantly.

## Highlights
- **Vector Arrow Primitive** – Interactive arrow built from `res://commons/primitives/line/line.tscn` with a live magnitude label and draggable endpoint spheres.
- **Unit Direction Companion** – A locked unit-length arrow mirrors the direction of the primary vector to emphasise normalization.
- **Axis-Aligned Components** – Three color-coded component vectors (red/x, green/y, blue/z) update continuously as you reposition the main arrow.
- **Floating Analytics** – A billboard panel reports raw components, magnitude, and unit-vector coordinates.

## Interaction Cheatsheet
- **Grab Yellow Endpoint** – Change the magnitude and direction of vector *a*.
- **Observe Unit Arrow** – The magenta arrow always reflects the normalized direction.
- **Read Components** – Component arrows shrink, flip, and grow with each axis contribution.
- **Reset** – Use the global `R` key (available across labs) to return auxiliary visuals to their defaults.

## Learning Goals
1. Understand vectors as oriented segments anchored at the origin.
2. Decompose any vector into orthogonal x, y, and z components.
3. Interpret normalization as "direction only" with magnitude constrained to one.
4. Build geometric intuition for how magnitude responds to endpoint motion.

## Scene Path
```
res://algorithms/vectors/01_vector_basics/VectorBasics.tscn
```
