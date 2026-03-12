# Dot Product Projector

An interactive 3D visualizer for the dot product operation, showing how one vector projects onto another and teaching the geometric meaning of alignment between two directions.

## How It Works

Two vectors A and B are drawn as colored arrows from the origin. The dot product A . B = |A||B|cos(theta) is computed in real time, and the projection of A onto B is shown as a green arrow along B's direction. A dashed perpendicular line connects the tip of A to the projection point, and a purple arc displays the angle between the vectors. VR-grabbable handle spheres at each vector's tip allow direct manipulation, and preset buttons offer canonical configurations (aligned, orthogonal, opposed, acute, obtuse).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_vector_length` | float | `1.2` |
| `arrow_thickness` | float | `0.012` |
| `vector_a` | Vector3 | `Vector3(0.7, 0.5, 0.0)` |
| `vector_b` | Vector3 | `Vector3(0.9, 0.0, 0.0)` |

## Features

- Color-coded arrows for vectors A (coral), B (blue), projection (green), and perpendicular component (orange)
- Angle arc visualization with degree readout
- Interactive VR handles for dragging vector endpoints
- Five preset configurations: Aligned, Orthogonal, Opposed, Acute, Obtuse
- Live formula panel showing vector components, magnitudes, angle, and dot product
- Result panel color-coded by alignment (green=positive, red=negative, yellow=orthogonal)
- Ground plane and axis reference lines via VectorVisuals helper

## Files

- `dot_product_projector.gd` — Main script
- `dot_product_projector.tscn` — Scene file
