# Vector Forces & Newton's Second Law

Inspired by *The Nature of Code*, this lab turns vector arrows into force controllers that act on a floating sphere. Adjust gravity and thrust vectors directly; the simulation recomputes net force and acceleration according to Newton's second law.

## Highlights
- **Physics Ball** – A `RigidBody3D` sphere with custom drag and no default gravity.
- **Force Controllers** – Gravity and thrust arrows share the line primitive so you can reorient and resize forces in real time.
- **Dynamic Drag** – A semi-transparent arrow renders velocity-proportional drag as the sphere moves.
- **Telemetry Panel** – Net force, acceleration, and velocity vectors refresh every 0.1 seconds.

## Interaction Cheatsheet
- **Grab Gravity** – Rotate or resize the gravity arrow to modify constant acceleration.
- **Grab Thrust** – Use the orange arrow to create impulse-like pushes in any direction.
- **Watch Drag** – The blue drag arrow always opposes velocity; it disappears at rest.
- **Reset / Pause** – Press `R` to reset position and `Space` to zero out velocity.

## Learning Goals
1. Experience Newton's second law (`ΣF = m a`) through immediate feedback.
2. See how constant and transient forces combine in three dimensions.
3. Explore drag as a velocity-dependent opposing force.

## Scene Path
```
res://algorithms/vectors/05_vector_forces/VectorForces.tscn
```
