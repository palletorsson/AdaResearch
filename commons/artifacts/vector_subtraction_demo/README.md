# Vector Subtraction Demo

Visualizes vector subtraction using the identity A - B = A + (-B). Learners see vectors A and B drawn from the origin, the negated vector -B, and the tip-to-tail construction where -B is placed at A's tip to produce the result, teaching the geometric meaning of subtracting vectors in 3D space.

## How It Works

The artifact draws five arrows from the origin: vector A, vector B, the negation -B, a ghost copy of -B translated to A's tip (tip-to-tail), and the result vector A - B. Each arrow is built from a CylinderMesh shaft and a cone head, positioned and oriented to match the vector direction. Grabbable sphere handles at the tips of A and B let VR users drag vectors interactively, and a live formula panel displays all component values. Preset buttons (ORTHO, SAME, OPPOSE, RESET) snap the vectors to instructive configurations.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_vector_length` | float (0.1-5.0) | 1.2 |
| `arrow_thickness` | float (0.001-0.05) | 0.006 |
| `vector_a` | Vector3 | (0.8, 0.4, -0.1) |
| `vector_b` | Vector3 | (0.2, 0.7, 0.3) |
| `color_a` | Color | Red (1.0, 0.3, 0.3) |
| `color_b` | Color | Blue (0.3, 0.5, 1.0) |
| `color_neg_b` | Color | Light blue, semi-transparent |
| `color_result` | Color | Green (0.3, 1.0, 0.4) |
| `panel_color` | Color | Dark panel background |

## Features

- Interactive VR handles for dragging vector A and B endpoints
- Live formula panel showing A, B, -B, and A - B with numeric components
- Ghost (semi-transparent) arrows for -B to distinguish negation from originals
- Tip-to-tail construction arrow showing A + (-B) visually
- Four preset configurations accessible via VR buttons or keyboard (1/2/3/R)
- Coordinate axes with X/Y/Z labels for spatial reference

## Files

- `vector_subtraction_demo.gd` -- Main script
- `vector_subtraction_demo.tscn` -- Scene file
