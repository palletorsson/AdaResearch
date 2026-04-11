# Increasing Randomness Wall

A wall of cubes where randomness increases gradually along a configurable direction -- from perfectly ordered to fully chaotic. This artifact teaches the concept of a **randomness gradient** -- how smoothly transitioning from zero entropy to maximum entropy within a single structure makes the effects of randomness visible and intuitive.

## How It Works

1. A template cube (`CubeBaseStaticBody3D`) is duplicated across a 3D grid of `wall_width x wall_height x wall_depth` positions.

2. For each cube, a **randomness factor** is computed based on its position along the chosen direction:
   - Left to Right: factor = `x / (width - 1)`
   - Right to Left: factor = `(width - 1 - x) / (width - 1)`
   - Bottom to Top: factor = `y / (height - 1)`
   - Top to Bottom: factor = `(height - 1 - y) / (height - 1)`

3. The factor is raised to the **third power** (cubic easing) for a more dramatic progression -- cubes stay ordered longer before chaos escalates.

4. The factor controls four randomness channels:
   - **Position jitter** -- Cubes shift from their grid positions by up to `cube_size * 0.5 * factor`.
   - **Rotation** -- Rotation ranges from zero to full `2*PI * factor` on all axes.
   - **Scale** -- Scale variation grows from uniform to the full `min_scale`--`max_scale` range.
   - **Removal** -- Cubes are randomly deleted with probability up to 30% at maximum factor.
   - **Color** -- Base gray lerps toward a fully random color proportional to the factor.

5. The wall can be regenerated with a new random seed via the `regenerate()` function.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `wall_width` | 20 | Number of cubes along X |
| `wall_height` | 8 | Number of cubes along Y |
| `wall_depth` | 1 | Number of cubes along Z |
| `random_seed` | 42 | Seed for reproducible results |
| `cube_size` | 1.0 | Spacing between cube centers |
| `min_scale` | 0.7 | Minimum scale at full randomness |
| `max_scale` | 1.3 | Maximum scale at full randomness |
| `randomness_scale_factor` | 1.0 | Global multiplier for randomness intensity |
| `randomness_direction` | Left to Right | Direction of increasing randomness |

## Features

- Four selectable randomness directions (left/right/bottom/top)
- Cubic easing for dramatic gradient progression
- Position, rotation, scale, color, and removal all controlled by a single gradient
- Reproducible results via configurable random seed
- Runtime regeneration with new seed
- Duplicates from a template StaticBody3D for physics interaction

## Files

| File | Description |
|------|-------------|
| `random_increase_wall.gd` | Gradient randomness wall generator |
| `random_increase_wall.tscn` | Scene file with template cube and wall node |
