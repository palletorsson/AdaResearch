# Rhizome -- Growth-Pattern Cave Generator

A two-part system that generates organic cave networks using a **rhizomatic growth model** combined with **marching cubes isosurface extraction**. The artifact teaches how biological growth patterns -- branching, merging, chamber formation -- can be modeled algorithmically and then converted into solid walkable geometry through voxel carving and mesh extraction.

## How It Works

### Rhizome Growth Pattern (`RhizomeGrowthPattern.gd`)

The growth model simulates underground root-like spreading through an iterative node-based system:

1. **Seed nodes** are placed as starting points with initial radius and energy.
2. Each iteration, active nodes attempt to branch based on `branch_probability` scaled by remaining energy.
3. **Branch direction** is generated from random spherical coordinates, biased horizontally by `vertical_bias` and influenced by the parent node's direction (30% weight). Upward movement is capped.
4. **Branch length** is randomly sampled between `min_branch_length` and `max_branch_length`.
5. **Merging**: Before creating a new node, the system checks whether the target position is within `merge_distance` of an existing node. If so, the two are connected instead of creating a duplicate -- this produces the non-hierarchical looping topology characteristic of rhizomes.
6. **Chambers**: Every 10 iterations, nodes with 2+ children are candidates for chamber expansion (probability `chamber_probability`), which multiplies their radius by 2--4x.
7. **Energy decay**: Each branch reduces the parent's energy by 30%, and children inherit 80% of the parent's energy, naturally limiting growth depth.

### Rhizome Cave Generator (`RhizomeCaveGenerator.gd`)

Converts the abstract growth network into solid geometry:

1. Creates a `RhizomeVoxelChunk` -- a 3D array of density values initialized to 1.0 (solid).
2. **Carves tunnels**: For each connection in the rhizome network, `carve_tunnel()` samples points along the segment and calls `carve_sphere()` at each, which applies a smooth density falloff (distance/radius) to create rounded passages with tapered radii.
3. **Carves chambers**: Chamber nodes get double-radius sphere carving for expanded spaces.
4. **Marching cubes**: The carved density field is processed voxel-by-voxel. For each voxel, 8 corner densities are read, a cube index determines the triangle configuration from lookup tables, edge vertices are interpolated, and normals are computed from density gradients.
5. The resulting mesh and collision shape are added to the scene tree.

The generator supports async operation with time-based yielding and progress signals.

## Parameters

### RhizomeGrowthPattern

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `branch_probability` | float | 0.7 | Chance of branching per active node per iteration |
| `merge_distance` | float | 8.0 | Distance threshold for connecting to existing nodes |
| `vertical_bias` | float | 0.3 | Vertical direction damping (lower = more horizontal) |
| `chamber_probability` | float | 0.2 | Chance of a multi-child node becoming a chamber |
| `max_depth` | int | 6 | Maximum branching depth |
| `min_branch_length` | float | 5.0 | Minimum branch segment length |
| `max_branch_length` | float | 20.0 | Maximum branch segment length |

### RhizomeCaveGenerator

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `threshold` | float | 0.5 | Marching cubes iso-level |
| `chunk_size` | Vector3i | (32, 32, 32) | Voxel grid dimensions |
| `voxel_scale` | float | 1.0 | Meters per voxel |

## Features

- Biologically-inspired rhizomatic growth with branching, merging, and chamber formation
- Non-hierarchical network topology (loops and cross-connections, not just trees)
- Energy-based growth limiting for natural tapering
- Spherical density carving with smooth falloff for rounded tunnels
- Full marching cubes mesh extraction with interpolated vertices and gradient normals
- Async generation with progress signals and time-budgeted yielding
- Collision shape generation for VR walkability
- Network export for serialization or analysis

## Files

- `RhizomeGrowthPattern.gd` -- Growth model (class_name RhizomeGrowthPattern, extends RefCounted)
- `RhizomeCaveGenerator.gd` -- Voxel carving and marching cubes extraction (class_name RhizomeCaveGenerator)
