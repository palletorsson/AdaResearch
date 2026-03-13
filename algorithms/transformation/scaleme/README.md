# Scale Me

A vertical tower of cubes where each successive cube is larger than the one below it by a constant scale factor, creating an exponentially growing stack. The artifact teaches **exponential scaling** -- how repeated multiplication produces rapid growth -- and makes the abstract idea tangible by letting the learner see and walk around the resulting tower.

## Concept Taught

**Exponential growth through repeated scaling** is a foundational concept in mathematics and computer science. Starting from a small cube of size `start_size`, each subsequent cube is multiplied by `scale_factor`. After just a few iterations the cubes become dramatically larger, visually demonstrating how `size = start_size * scale_factor^n` behaves. The artifact also illustrates geometric stacking: each cube sits exactly on top of the previous one, requiring correct Y-offset computation.

## How It Works

1. The script runs in `@tool` mode so the tower is visible in the Godot editor.
2. `generate_cubes()` clears any existing children, then iterates `count` times.
3. Each iteration creates a `MeshInstance3D` with a unit `BoxMesh` scaled to `Vector3.ONE * size`.
4. The cube is positioned so its bottom face sits on top of the previous cube's top face (`y_offset + size / 2`).
5. If `alternating_colors` is enabled, even-indexed cubes use `color_a` and odd-indexed cubes use `color_b`.
6. After placing the cube, `y_offset` increases by the current size and `size` is multiplied by `scale_factor` for the next iteration.
7. The `regenerate` export button triggers a rebuild in the editor.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `start_size` | float | `0.2` | Size of the first (bottom) cube |
| `scale_factor` | float | `2.0` | Multiplier applied to each successive cube |
| `count` | int | `8` | Number of cubes in the tower |
| `alternating_colors` | bool | `true` | Alternate between two colors |
| `color_a` | Color | Red | Color for even-indexed cubes |
| `color_b` | Color | Blue | Color for odd-indexed cubes |
| `regenerate` | bool | `false` | Editor button to rebuild the tower |

## Features

- `@tool` script: tower is visible and editable in the Godot editor.
- Exponential size growth with configurable base and factor.
- Proper geometric stacking with accurate Y-offset accumulation.
- Alternating two-color scheme for visual clarity.
- One-click regeneration via the `regenerate` export.

## Files

- `scaleme.gd` -- Main script: exponential cube tower generation with editor support.
- `scaleme.tscn` -- Scene file.
