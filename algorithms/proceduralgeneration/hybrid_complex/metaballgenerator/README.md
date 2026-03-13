# Metaball Generator

A procedural metaball system that uses the marching cubes algorithm to generate organic, blob-like surfaces in real time. Metaballs are implicit surfaces defined by overlapping scalar fields -- where two blobs get close enough, they merge smoothly into one continuous shape. The result resembles a lava lamp: soft forms that rise, sink, drift, and fuse together.

## Concept Taught

**Marching cubes and implicit surfaces.** This artifact teaches how continuous scalar fields can be converted into visible 3D meshes. Each metaball radiates a field value that falls off with distance squared. The marching cubes algorithm walks through a 3D grid, tests each cube's corners against a threshold (the iso-level), and emits triangles along the boundary where inside meets outside. Students see how a purely mathematical field becomes a tangible, animated surface -- and how changing the iso-level or ball count reshapes the geometry in real time.

## How It Works

1. A 3D grid of field values is allocated (default 64x32x64 cells at 0.5 unit spacing).
2. Multiple metaball sources are placed randomly within the grid bounds, each with position, strength, and radius.
3. Every frame (within the regeneration interval), each metaball updates its position using lava-lamp-style motion -- vertical bobbing with gentle horizontal drift.
4. The scalar field is recalculated for every grid point by summing contributions from all metaballs, using influence-radius culling to skip negligible contributions.
5. The marching cubes algorithm walks the grid one cube at a time. For each cube, it builds an 8-bit index from which corners exceed the iso-level, looks up the edge table and triangle table (Paul Bourke's complete 256-case tables), interpolates vertex positions along edges, and emits triangles.
6. The resulting mesh is committed to a reusable ArrayMesh with per-face normals.
7. A stepping system controls the animation: it runs for a configurable number of steps, each lasting a set duration, then stops.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | Vector3i | (64, 32, 64) | Resolution of the marching cubes grid |
| `cell_size` | float | 0.5 | World-space size of each grid cell |
| `iso_level` | float | 1.0 | Threshold for surface extraction |
| `metaball_count` | int | 8 | Number of metaball sources |
| `animation_speed` | float | 0.5 | Speed multiplier for metaball motion |
| `generate_on_ready` | bool | true | Auto-generate on scene load |
| `max_steps` | int | 5 | Number of simulation steps (0 = unlimited) |
| `step_duration` | float | 0.4 | Seconds per animation step |
| `surface_shader` | Shader | null | Optional shader for the surface material |

## Features

- Full Paul Bourke marching cubes implementation with all 256 triangle configurations
- Per-frame adaptive regeneration interval based on measured generation time
- Influence-radius culling skips metaballs too far away to affect a grid point
- Pre-computed grid positions avoid redundant math each frame
- Flat-array caching of metaball data for inner-loop speed
- Lava-lamp animation with vertical bobbing, horizontal drift, and gentle strength pulsing
- Step-based simulation with start, stop, single-step, and reset controls
- Applies PinkTeleport shader by default, falls back to a glossy organic material
- Public API: `regenerate()`, `set_metaball_count()`, `set_iso_level()`, `set_animation_speed()`, `do_single_step()`, `reset_simulation()`

## Files

| File | Purpose |
|------|---------|
| `metaballgenerator.gd` | Core marching cubes engine, metaball physics, mesh generation, stepping system |
| `metaballscene.gd` | Minimal scene wrapper that hosts the MetaballGenerator node |
