# Vector Addition in 3D

Visualise tip-to-tail composition, parallelogram construction, and magnitude relationships with a pair of draggable force-style arrows. The scene recomputes the resultant vector and helper geometry every frame so you can feel how two directions blend inside VR.

## Highlights
- **Interactive Vectors a and b** – Move either endpoint to reshape the operands.
- **Resultant Arrow** – The white arrow renders `a + b` from the origin.
- **Tip-to-Tail Mode** – Two translucent companions reposition a copy of each vector at the other vector's head to complete the parallelogram.
- **Live Metrics** – Magnitudes and triangle-inequality feedback float in space for quick reference.

## Interaction Cheatsheet
- **Grab Either Vector** – Drag the cyan or orange endpoint spheres to redefine vectors.
- **Observe Parallelogram** – The ghosted arrows close both diagonals for geometric intuition.
- **Check Inequality** – Watch how `|a + b| ≤ |a| + |b|` responds as you explore opposing directions.

## Learning Goals
1. Reinforce algebraic addition with geometric construction.
2. Interpret the resultant as the diagonal of a vector parallelogram.
3. Compare magnitudes and directions as the vectors align or oppose.

## Scene Path
```
res://algorithms/vectors/02_vector_addition/VectorAddition.tscn
```
