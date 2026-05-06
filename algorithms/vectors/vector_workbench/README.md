# Vector Workbench

Universal vector operation visualizer. Two draggable vectors (A and B) with live computed outputs for all major operations.

## Scene
`res://algorithms/vectors/vector_workbench/VectorWorkbench.tscn`

## Features

### Input Vectors (Draggable)
- **Vector A** (red-orange) — Grab the sphere at the tip to adjust
- **Vector B** (blue) — Grab the sphere at the tip to adjust

### Computed Results (Live)
- **A + B** (yellow) — Vector addition/resultant
- **A - B** (purple) — Vector subtraction  
- **A × B** (green) — Cross product (perpendicular to both)
- **proj_B(A)** (pink) — Projection of A onto B

### Visual Elements
- **Angle arc** — Shows angle θ between A and B (for dot product)
- **Parallelogram** — Shows area |A × B| (for cross product magnitude)

### Info Panel
Displays all computed values:
- Vector components and magnitudes
- A + B, A - B results
- Dot product (A · B) and angle θ
- Cross product (A × B) and its magnitude
- Projection of A onto B

## Controls

| Key | Action |
|-----|--------|
| 1 | Show all operations |
| 2 | Addition mode only |
| 3 | Dot product mode only |
| 4 | Cross product mode only |
| 5 | Projection mode only |
| R | Reset vectors to defaults |

## Concepts Demonstrated

1. **Vector Addition** — Tip-to-tail, resultant vector
2. **Vector Subtraction** — Adding the negative, displacement between tips
3. **Dot Product** — Scalar result, angle relationship, parallel component
4. **Cross Product** — Perpendicular vector, area of parallelogram, right-hand rule
5. **Projection** — Component of A in direction of B

## Pedagogical Notes

This scene works as a "sandbox" for understanding how vector operations relate to each other. By manipulating A and B and watching all results update simultaneously, learners can develop intuition for:

- Why dot product is zero when vectors are perpendicular
- Why cross product magnitude equals parallelogram area
- How projection "squishes" one vector onto another's direction
- The relationship between angle and dot product sign
