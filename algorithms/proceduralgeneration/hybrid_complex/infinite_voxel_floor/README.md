# Infinite Voxel Floor

A player-following procedural floor that generates an endless landscape of noise-driven voxel columns with dynamic lighting and color. This artifact teaches the **sliding window** technique for infinite terrain -- how a fixed-size grid can appear infinite by re-centering on the player each frame, combined with Perlin noise for deterministic height generation and proximity-based lighting.

## How It Works

1. **Grid setup**: A `MultiMeshInstance3D` with `(2 * grid_radius + 1)^2` box instances creates a square grid of voxel columns.
2. **Player tracking**: Each frame, the grid snaps to the player's XZ position (rounded to `cube_size` increments), creating a sliding window that follows movement.
3. **Noise-driven height**: Each column's height is computed from `FastNoiseLite` Perlin noise at its world XZ position. The noise value (range -1 to 1) is mapped to a height using `height_scale`. Each box is scaled vertically to its height, with its origin at the base.
4. **Proximity lighting**: The distance from each voxel to the player determines a light factor (0 at `light_radius`, 1 at the player). This factor interpolates between `base_emission` and `highlight_emission`, making nearby voxels glow brightly.
5. **Color generation**: Each voxel's hue is derived from its noise value plus a time-varying offset, producing a slowly shifting color field. The emission factor boosts brightness for the proximity glow effect.
6. **Performance**: All voxels are rendered via a single `MultiMesh` draw call with per-instance colors and transforms, allowing thousands of voxels at minimal draw cost.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_radius` | int | 25 | Radius of the visible grid (total side = 2r+1) |
| `cube_size` | float | 1.0 | World-space size of each voxel |
| `height_scale` | float | 2.0 | Maximum column height |
| `noise_frequency` | float | 0.05 | Perlin noise frequency (lower = smoother terrain) |
| `color_speed` | float | 0.5 | Speed of the time-varying color shift |
| `light_radius` | float | 10.0 | Distance at which proximity glow fades to zero |
| `base_emission` | float | 2.0 | Emission level for distant voxels |
| `highlight_emission` | float | 8.0 | Emission level for voxels near the player |

## Features

- **Infinite terrain illusion** -- sliding window re-centers on the player every frame, so the floor extends endlessly in all directions
- **Deterministic noise** -- Perlin noise ensures the same world position always produces the same height, even as the grid scrolls
- **Per-instance color and emission** -- proximity-based glow creates a spotlight effect around the player
- **Tool script** -- `@tool` annotation allows preview in the Godot editor
- **MultiMesh performance** -- thousands of voxels in a single draw call
- **Reactive parameters** -- changing `grid_radius` or `cube_size` at runtime re-initializes the grid automatically

## Files

- `InfiniteVoxelFloor.gd` -- Complete implementation: MultiMesh setup, sliding window, noise sampling, proximity lighting, per-instance coloring
- `InfiniteVoxelFloor.tscn` -- Scene file
