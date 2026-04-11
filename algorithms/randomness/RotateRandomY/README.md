# Rotate Random Y

Randomly rotates MultiMesh cube instances around the Y axis only. An initial small random rotation is applied to every instance at startup, then each frame a single randomly chosen instance receives a small incremental Y rotation. The effect is a subtle, ongoing stir of gentle rotation across the grid.

## Concept Taught

**Single-axis randomness and the accumulation of small changes.** This artifact isolates randomness to a single degree of freedom -- rotation around the vertical (Y) axis. By constraining the random process to one axis, students can clearly observe how repeated small random perturbations accumulate over time. Initially, all cubes are nearly aligned. Frame by frame, individual cubes drift further from their original orientation. The result demonstrates the random walk on a circle: each cube's angle follows a one-dimensional random walk, and the overall grid slowly loses its uniformity as individual orientations diverge.

## How It Works

1. On ready, the script finds a MultiMeshInstance3D and applies a tiny initial random Y rotation (default plus/minus 0.01 degrees) to every instance -- barely visible but breaking perfect alignment.
2. Each frame, one random instance is selected.
3. That instance's transform basis is rotated around the Y axis by a random step between `min_step_y` and `max_step_y` degrees (default plus/minus 2 degrees).
4. Only one instance is rotated per frame, creating a slow, distributed stir across the grid.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `multimesh_path` | NodePath | "../GridMultiMesh" | Path to the MultiMeshInstance3D |
| `min_y_degrees` | float | -0.01 | Minimum initial Y rotation in degrees |
| `max_y_degrees` | float | 0.01 | Maximum initial Y rotation in degrees |
| `min_step_y` | float | -2.0 | Minimum per-frame Y rotation step in degrees |
| `max_step_y` | float | 2.0 | Maximum per-frame Y rotation step in degrees |

## Features

- Single-axis rotation isolates the Y degree of freedom for clear observation
- Initial micro-rotation breaks perfect grid alignment subtly
- One instance rotated per frame for a slow, natural-looking stir
- Automatic MultiMesh discovery via recursive node search
- Minimal computational cost -- one transform update per frame

## Files

| File | Purpose |
|------|---------|
| `RotateRandomY.gd` | Initial Y rotation setup and per-frame single-instance random Y rotation |
