# Grow Slimbs -- Skeleton-Based Morphogenesis

A procedural limb-growth system that demonstrates **space colonization algorithms** using Godot's `Skeleton3D` and bone hierarchy. The artifact grows branching limb structures from a central root toward attractor points, creating an organic skeletal form with skinned mesh segments.

## Concept Taught

**Space colonization** is a biologically-inspired algorithm for simulating how organisms develop branching structures. Originally modeled after vascular networks and tree growth, the algorithm places attractor points in space that guide growth nodes toward them. When a growth node gets close enough to an attractor, the attractor is consumed ("killed"). This process mimics how biological morphogens guide the formation of limbs, blood vessels, and root systems in nature.

## How It Works

1. A root bone is created at the origin with an initial `GrowthNode`.
2. Attractor points are distributed along four limb paths (two arms, two legs) using linear interpolation with slight random offsets.
3. Each growth step finds which attractors influence which nodes (based on `influence_radius`), computes an average growth direction, and spawns new growth nodes in that direction.
4. New bones are added to a `Skeleton3D` hierarchy, with parent-child relationships matching the growth tree.
5. Branching occurs probabilistically when a node is old enough, creating side shoots at random angles.
6. Attractors within `kill_distance` of any node are removed.
7. A skinned mesh is built from cylindrical segments between parent-child node pairs, with vertex weights for bone deformation.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `max_iterations` | int | 50 | Total growth steps before stopping |
| `growth_step` | float | 0.3 | Distance each new node grows per step |
| `branch_angle` | float | 45.0 | Maximum branching angle in degrees |
| `branch_probability` | float | 0.15 | Chance of spawning a side branch per step |
| `influence_radius` | float | 2.0 | How far an attractor can influence a node |
| `kill_distance` | float | 0.4 | Distance at which an attractor is consumed |
| `segment_thickness` | float | 0.08 | Base radius of mesh segments |

## Features

- Skeleton3D bone hierarchy mirrors the procedural growth tree
- Skinned mesh with per-vertex bone weights for smooth deformation
- Attractor visualization as semi-transparent red spheres
- Interactive controls: SPACE to start growth, R to reset
- Radius tapering -- child segments are 90% the radius of their parents, branches taper to 60%
- Cylindrical mesh segments with 8-sided cross-sections and proper normals

## Files

- `growslimbs.gd` -- Main script implementing the space colonization algorithm with skeleton and mesh generation
- `growslimbs.tscn` -- Scene file
