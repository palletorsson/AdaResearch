# Transform Composition

Demonstrates that matrix multiplication is non-commutative by showing how the order of rotation and translation produces different results. A house shape is transformed two ways -- rotate-then-translate (blue) and translate-then-rotate (red) -- landing in visibly different positions to prove that R*T does not equal T*R.

## How It Works

A 2D house outline (five vertices forming walls and a roof peak) is drawn in the XY plane. Two transformation orders are applied: Order A rotates the shape around the Y axis first, then translates along X; Order B translates first, then rotates. The composed 4x4 homogeneous matrices are displayed as labels, and ghost outlines show the intermediate step of each composition. An animation mode smoothly interpolates from identity to the full transform so users can watch the divergence unfold.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `rotation_angle` | float | 45.0 |
| `translate_dist` | float | 0.3 |

## Features

- Side-by-side comparison of R*T vs T*R with color-coded results
- Ghost outlines showing intermediate transformation steps
- Live 4x4 matrix display for both composition orders
- VR sliders for rotation angle (0-180 degrees) and translation distance (0-0.6)
- Animated step-through from identity to full transform
- Toggle buttons to show Order A, Order B, or both simultaneously

## Files

- `transform_composition.gd` -- Main script
- `transform_composition.tscn` -- Scene file
