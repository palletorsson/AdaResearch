# Vector Addition Demo

An interactive visualization of vector addition using the head-to-tail method and the parallelogram law. Two vectors A and B are drawn from the origin, and their sum C = A + B is shown as the diagonal of the completed parallelogram.

## How It Works

Vectors A and B are rendered as colored arrows from the origin. Ghost copies of each vector are placed head-to-tail (A shifted to the tip of B, and B shifted to the tip of A) to form a parallelogram. The resultant vector A + B is drawn as the diagonal from the origin to the opposite corner. A formula panel displays the component values and the magnitude of the result. Grabbable handle spheres at each vector's tip allow users to drag endpoints in VR, with the entire visualization updating in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_vector_length` | float | 1.2 |
| `arrow_thickness` | float | 0.006 |
| `vector_a` | Vector3 | (0.8, 0.3, 0.0) |
| `vector_b` | Vector3 | (0.2, 0.6, 0.3) |

## Features

- Parallelogram construction with ghost arrows showing head-to-tail placement
- Grabbable VR handles for dragging vector endpoints
- Live formula panel showing component values and resultant magnitude
- 4 preset configurations: Orthogonal, Acute, 3D, and Reset
- Ground plane and coordinate axes for spatial reference
- Animated glow pulses on handles and result arrow

## Files

- `vector_addition_demo.gd` -- Main script
- `vector_addition_demo.tscn` -- Scene file
