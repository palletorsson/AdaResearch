# Shear Matrix Demo

A wall panel that visualizes the shear transformation by showing a unit square alongside its sheared parallelogram, with the corresponding 2x2 shear matrix displayed below. Teaches how shearing distorts geometry while preserving area.

## How It Works

The artifact draws two shapes side by side using ImmediateMesh line primitives: an original unit square and its image under the shear matrix S = [[1, k], [0, 1]]. Each vertex (x, y) of the original square is mapped to (x + k*y, y), producing a parallelogram whose lean is controlled by the shear factor k. A directional arrow between the shapes indicates the transformation direction, and a label renders the matrix notation with the current shear factor value.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `shear_factor` | float | 0.5 |
| `shape_size` | float | 0.25 |
| `color_original` | Color | (0.3, 0.5, 1.0) |
| `color_sheared` | Color | (1.0, 0.6, 0.2) |
| `color_panel` | Color | (0.08, 0.08, 0.12) |
| `color_arrow` | Color | (0.7, 0.7, 0.8) |

## Features

- Side-by-side comparison of original and transformed shapes
- 2x2 shear matrix displayed in standard notation
- Diagonal reference lines for visual comparison of distortion
- Configurable shear factor via grid config

## Files

- `shear_matrix_demo.gd` -- Main script
- `shear_matrix_demo.tscn` -- Scene file
