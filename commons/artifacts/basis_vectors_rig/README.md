# Basis Vectors Rig

Interactive 3D basis vector visualization that decomposes any point P into its components along the i, j, k unit vectors, teaching the fundamental linear algebra concept that P = x*i + y*j + z*k.

## How It Works

Three color-coded arrows (red=X, green=Y, blue=Z) represent the basis vectors, with a golden target point showing the position to decompose. Dashed component lines trace the path from the origin along each basis direction to reach the target, making the linear combination visually concrete. VR push buttons let the user select preset target points (pure X, pure Y, pure Z, XY diagonal, XYZ) or rotate the entire basis (reset, tilt 30 degrees, spin 45 degrees). A coordinates panel displays the decomposition formula and magnitude in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `axis_length` | float | `0.6` |
| `arrow_thickness` | float | `0.01` |
| `target_point` | Vector3 | `Vector3(0.35, 0.45, 0.25)` |

## Features

- RGB-coded basis arrows with glow shells and billboard labels
- Golden target point with pulsing glow animation
- MultiMesh component lines showing the decomposition path
- VR push buttons for point presets and basis rotations
- Real-time coordinate display with magnitude calculation
- Grabbable point handle for VR interaction
- Keyboard shortcuts for desktop testing (1-5 for points, R/T/Y for rotations)
- Ground plane via VectorVisuals helper

## Files

- `basis_vectors_rig.gd` -- Main script
- `basis_vectors_rig.tscn` -- Scene file
