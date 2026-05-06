# Noise-Based Distortion

A 3D grid visualization that demonstrates how Perlin noise displaces objects from their regular positions, creating organic, flowing distortion patterns. An 8x8 grid of cubes is continuously warped by a time-varying 3D noise field, with displacement vectors shown as connecting lines.

## Concept Taught

Noise-based distortion is a foundational technique in computer graphics, used for terrain generation, water surface simulation, cloth deformation, and texture warping. This artifact teaches that applying a coherent noise function to a regular grid produces smooth, natural-looking deformations -- unlike pure random displacement, which would create visual chaos. The key insight is that spatially correlated randomness (where nearby points receive similar but not identical offsets) is what makes the result look organic rather than broken.

## How It Works

This scene uses the shared `RandomTransformations.gd` script, which manages four sub-visualizations via named child nodes. This scene provides the `NoiseBasedDistortion` child node.

1. **Grid construction** -- An 8x8 grid of `CSGBox3D` cubes (0.3 unit size) is created each frame, with base positions centered at integer coordinates.
2. **3D Perlin noise sampling** -- Each grid position is fed through a custom Perlin noise implementation (`noise_perlin`) at three different seed offsets (0, 100, 200) to produce X, Y, and Z displacement components. The noise inputs include the grid position (scaled by `noise_scale = 0.1`) and elapsed time (scaled by 0.5) for animation.
3. **Perlin noise implementation** -- The script contains a full gradient noise implementation with:
   - `fade()` -- quintic interpolation curve (6t^5 - 15t^4 + 10t^3)
   - `hash3d()` -- integer lattice hashing
   - `grad3d()` -- gradient direction selection from hash
   - Trilinear interpolation across the 3D lattice
4. **Displacement visualization** -- When a cube's displacement exceeds 0.1 units, a thin cylinder is drawn from the base position to the displaced position, showing the deformation vector.
5. **Color mapping** -- Each cube's color is determined by its displacement magnitude mapped through HSV space, making areas of high distortion visually distinct from calm regions.

## Parameters

The script uses internal variables rather than exports:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `noise_amplitude` | float | 1.0 | Multiplier for displacement vectors |

The noise sampling uses a hardcoded `noise_scale` of 0.1 and time scale of 0.5.

## Features

- 8x8 grid of cubes displaced by 3D Perlin noise
- Full custom Perlin noise implementation with quintic fade and gradient hashing
- Time-varying noise field creates continuous flowing animation
- Displacement vectors visualized as thin cylinders connecting base to displaced positions
- HSV color mapping based on distortion magnitude
- Emissive materials for visual clarity in dark environments

## Files

| File | Description |
|------|-------------|
| `noise_based_distortion.tscn` | Scene file with camera, directional light, and `NoiseBasedDistortion` child node |
| `../RandomTransformations.gd` | Shared script managing all four random transformation sub-demos |
