# Random Up -- Biased Random Walk Palace Generator

A procedural 3D structure generator that builds upward-biased walkable palaces using a random walk algorithm. The artifact teaches how **biased probability** shapes the outcome of random processes -- by tuning a single parameter (`upward_bias`), the walk's character shifts from flat sprawl to towering vertical structures.

## How It Works

The algorithm starts at the origin and performs a series of random steps on a 3D integer grid. At each step, the system rolls a random number against `upward_bias` to decide whether to attempt an upward move or a horizontal one.

- **Horizontal moves** pick a random offset in the XZ plane (one cell in any of 8 directions) and place a standard cube.
- **Upward moves** place a slope-bridge piece that spans 3 cells horizontally while gaining 1 cell of elevation, creating a walkable ramp.

A spatial database (`_occupied_positions`) and a blocked-cell registry (`_blocked_positions`) prevent collisions. Slope bridges reserve airspace above their footprint so nothing clips through. A navigation graph tracks adjacency, and a flood-fill validator (`_validate_palace`) confirms that every placed cube is reachable from the origin.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cube_scene` | PackedScene | cube_scene.tscn | Standard 1m cube prefab |
| `slope_cube_scene` | PackedScene | slopecube.tscn | 3m slope-bridge prefab |
| `max_steps` | int | 50 | Total generation steps |
| `upward_bias` | float | 0.6 | Probability of attempting an upward move (0--1) |
| `horizontal_range` | int | 8 | Maximum X/Z deviation from origin |
| `seed` | int | 0 | RNG seed for reproducibility |

## Features

- Biased random walk with tunable upward probability
- Slope-bridge geometry for walkable vertical transitions
- Spatial collision detection with blocked-cell airspace reservation
- Navigation graph with flood-fill reachability validation
- Deterministic generation via explicit RNG seed

## Files

- `randomup.gd` -- Main generation script (biased walk, cube placement, validation)
- `slopecube.tscn` -- Slope-bridge scene used for upward moves
