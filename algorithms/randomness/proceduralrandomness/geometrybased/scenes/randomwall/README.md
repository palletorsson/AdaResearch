# Random Wall

A wall of cubes with uniform randomness applied to position, rotation, and scale. This artifact teaches the concept of **uniform random distribution in geometry** -- how applying independent random values to each cube's transform creates a natural, organic-looking structure from a regular grid, and how a fill percentage parameter controls density.

## How It Works

1. A template cube (`CubeBaseStaticBody3D`) is hidden and used as a blueprint.

2. The script iterates over a 3D grid (`wall_width x wall_height x wall_depth`). For each cell, a random check against `fill_percentage` determines whether a cube is placed -- this creates gaps and porosity.

3. Each placed cube receives:
   - **Position jitter** -- A small random offset (`position_jitter`) is added to each axis for a less mechanical appearance.
   - **Random rotation** -- If `random_rotation` is enabled, each axis gets a random value from 0 to `2*PI`.
   - **Random scale** -- If `random_scale` is enabled, a uniform scale factor is chosen between `min_scale` and `max_scale`.

4. The wall can be regenerated with a new random seed via the `regenerate()` function, which clears cubes in the "cube_wall" group and rebuilds.

5. A deterministic seed ensures the same wall is produced for a given `random_seed` value, making results reproducible.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `wall_width` | 10 | Number of cubes along X |
| `wall_height` | 6 | Number of cubes along Y |
| `wall_depth` | 2 | Number of cubes along Z |
| `random_seed` | 42 | Seed for reproducible layouts |
| `cube_size` | 1.0 | Grid spacing |
| `fill_percentage` | 0.75 | Probability of placing each cube (0.0--1.0) |
| `random_rotation` | true | Enable random rotation per cube |
| `random_scale` | true | Enable random scale per cube |
| `min_scale` | 0.7 | Minimum uniform scale |
| `max_scale` | 1.3 | Maximum uniform scale |
| `position_jitter` | 0.1 | Maximum random offset per axis |

## Features

- Fill percentage creates natural-looking density variation
- Independent random rotation on all three axes
- Uniform random scaling preserves cube proportions
- Deterministic seed for reproducible results
- Runtime regeneration support
- Template-based duplication from a StaticBody3D for physics

## Files

| File | Description |
|------|-------------|
| `random_wall.gd` | Uniform randomness wall generator |
| `random_wall.tscn` | Scene file with template cube and wall node |
