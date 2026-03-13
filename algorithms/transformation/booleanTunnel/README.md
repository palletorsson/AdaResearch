# Boolean Tunnel

A procedural tunnel generator that places a sequence of hollow Boolean cubes along the Z-axis, each rotated incrementally to create a spiraling walkable corridor. Supports cone tapering, burst rotation patterns, and an optional teleporter at the end. The artifact teaches how iterative geometric transformations -- translation, rotation, and scaling -- combine to produce complex architectural forms from a single repeated primitive.

## Concept Taught

**Geometric transformation composition** is the idea that applying a small rotation and translation to each copy of a shape produces globally complex structures. By stacking rotated hollow cubes, a straight corridor becomes a helix; by interpolating scale, it becomes a narrowing cone. The tunnel makes these principles physically navigable -- the learner walks through the result of repeated matrix operations.

## How It Works

1. A `PackedScene` of a hollow Boolean cube is instantiated `num_segments` times.
2. Each segment is positioned along the Z-axis at `i * spacing` and rotated around Z by an accumulated angle.
3. Pivot compensation offsets X and Y so the tunnel remains centered despite bottom-pivot rotation.
4. In **burst mode**, rotation alternates between active bursts and flat (no-rotation) sections, creating staccato twists.
5. In **cone mode**, each segment is uniformly scaled by an interpolated factor from `start_scale` to `end_scale`.
6. The entire tunnel can be tilted via `tunnel_rotation_x` and `tunnel_rotation_z`.
7. When `enable_teleporter` is true, a teleporter scene is placed inside the last cube and connected to a destination.
8. The script supports `apply_grid_config(config)` for runtime configuration from the grid system.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cube_scene` | PackedScene | `booleanHollowCube.tscn` | The hollow cube prefab to repeat |
| `num_segments` | int | `18` | Number of cube segments in the tunnel |
| `spacing` | float | `3.0` | Z-axis distance between consecutive cubes |
| `rotation_per_segment` | float | `10.0` | Degrees of Z-rotation added per segment |
| `cube_height` | float | `4.0` | Height used for pivot compensation |
| `cube_base_rotation_z` | float | `0.0` | Base Z-rotation applied to every cube |
| `cone_mode` | bool | `false` | Enable cone tapering |
| `start_scale` | float | `1.0` | Scale at the tunnel entrance |
| `end_scale` | float | `0.4` | Scale at the tunnel exit |
| `tunnel_rotation_x` | float | `0.0` | Tilt the whole tunnel around X |
| `tunnel_rotation_z` | float | `0.0` | Tilt the whole tunnel around Z |
| `burst_mode` | bool | `false` | Alternate between rotating and flat sections |
| `burst_rotate_count` | int | `3` | Cubes per rotating burst |
| `burst_flat_count` | int | `3` | Flat cubes between bursts |
| `enable_teleporter` | bool | `false` | Place a teleporter at the tunnel exit |
| `teleport_destination` | Vector3 | `(0, 1, 0)` | Where the teleporter sends the player |
| `teleporter_label` | String | `"Exit"` | Label displayed on the teleporter |

## Features

- Procedural tunnel from repeated hollow Boolean cubes with incremental rotation.
- Pivot compensation keeps the tunnel axis-aligned despite asymmetric rotation.
- Burst mode for staccato twist patterns.
- Cone mode for tapering tunnels.
- Optional end-of-tunnel teleporter with player detection.
- Full `apply_grid_config` support for runtime parameterization from the Ada grid system.

## Files

- `booleanTunnel.gd` -- Main script: tunnel generation, burst/cone modes, teleporter logic, grid config.
- `boolean_tunnel.tscn` -- Scene file.
