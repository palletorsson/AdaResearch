# Cross Product Demo

Interactive visualizer for the vector cross product, showing how two input vectors produce a perpendicular result vector whose magnitude equals the parallelogram area. Teaches the right-hand rule, the geometric meaning of cross products, and their role in computing surface normals and torques.

## How It Works

Two input vectors (A and B) are rendered as colored arrows from the origin. Their cross product is computed and displayed as a third arrow perpendicular to both. A semi-transparent parallelogram fills the area spanned by A and B, with its area numerically labeled. A rotation arc illustrates the right-hand rule (curl fingers from A toward B, thumb points in the result direction). Grabbable endpoint handles let users reposition vectors in VR. Info panels show the component values, magnitude formula, and right-hand rule description.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `max_vector_length` | float | `1.2` |
| `arrow_thickness` | float | `0.012` |
| `vector_a` | Vector3 | `(0.8, 0.0, 0.0)` |
| `vector_b` | Vector3 | `(0.0, 0.0, 0.8)` |

## Features

- Real-time cross product computation with three color-coded vector arrows
- Semi-transparent parallelogram showing the spanned area
- Right-hand rule rotation arc indicator
- Grabbable vector endpoint handles for VR interaction
- Five preset configurations (X cross Z, Z cross X, X cross Y, 3D, reset)
- Formula panel with component values and magnitude equation
- Ground plane and labeled axes via shared VectorVisuals utility

## Files

- `cross_product_demo.gd` -- Main script
- `cross_product_demo.tscn` -- Scene file
