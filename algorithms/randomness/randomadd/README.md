# Random Add

A spatial accumulation artifact that demonstrates randomness by progressively adding cubes at random grid-aligned positions within a bounding box. Over time, the empty space fills up as cubes appear at unpredictable locations, visualizing how random placement populates a discrete grid.

## Concept Taught

Random placement on a grid is one of the simplest demonstrations of uniform random sampling in discrete space. This artifact teaches several key concepts: how random positions are generated within bounds, how grid snapping constrains continuous randomness to a lattice, how collision detection prevents overlaps, and how a maximum count creates a natural stopping condition. The gradual fill-up process also illustrates the "birthday problem" dynamic -- as more positions are occupied, random attempts increasingly land on taken spots, making placement progressively harder.

## How It Works

1. **Cube scene loading** -- On `_ready()`, the script preloads the shared `pick_up_cube.tscn` scene from the commons library, reusing the same interactive cube used throughout the project.
2. **Timed spawning** -- A `Timer` node fires every `add_interval` seconds (default 1.0). On each timeout, the system attempts to place one cube.
3. **Random position generation** -- A position is drawn uniformly within the bounding box (`bounding_box_min` to `bounding_box_max`), then snapped to the nearest grid point using `round(value / cube_spacing) * cube_spacing`.
4. **Collision check** -- Before placing, the system checks all existing cube positions for a distance less than 0.1 units. If occupied, the attempt is skipped (no retry that frame).
5. **Cube instantiation** -- If the position is free, a cube instance is created, named with its index and coordinates, and added to the scene tree. The position is tracked in the `added_cubes` array.
6. **Stopping condition** -- When `current_cube_count` reaches `max_cubes`, the timer stops.
7. **Control API** -- Public methods allow external code to start/stop adding, clear all cubes, adjust the bounding box, change the interval, and query current state.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `bounding_box_min` | Vector3 | (0, 0, 0) | Lower corner of the placement volume |
| `bounding_box_max` | Vector3 | (10, 10, 10) | Upper corner of the placement volume |
| `cube_spacing` | float | 1.0 | Grid spacing for position snapping |
| `add_interval` | float | 1.0 | Seconds between placement attempts |
| `max_cubes` | int | 100 | Maximum number of cubes to place |

## Features

- Progressive random accumulation of cubes in 3D space
- Grid-aligned placement via coordinate snapping
- Collision detection prevents overlapping cubes
- Uses the shared `pick_up_cube.tscn` scene (VR-interactive cubes)
- Configurable bounding box, spacing, interval, and maximum count
- Public API for runtime control: `start_adding()`, `stop_adding()`, `clear_all_cubes()`, `set_bounding_box()`, `set_add_interval()`, `set_max_cubes()`
- Position query via `get_cube_positions()`

## Files

| File | Description |
|------|-------------|
| `RandomAdd.gd` | Main script -- timed spawning, random positioning, grid snapping, collision check |
