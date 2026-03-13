# Rotate Scale Cubes

A field of hundreds of small cubes scattered inside a sphere, each spinning on its own random axis with a shared grid-shader wireframe material. The artifact teaches how **MultiMesh instancing** enables large-scale procedural scenes and how individual per-instance transformations (rotation and subtle scaling) create the appearance of a living, breathing particle cloud from a single mesh definition.

## Concept Taught

**Instanced rendering and per-object transformation** are core computer graphics concepts. Instead of creating hundreds of independent scene nodes, a `MultiMesh` stores one mesh and many transforms, updating them each frame on the CPU while the GPU draws them in a single batch. Each cube gets its own rotation axis and speed, demonstrating how diverse visual behavior emerges from uniform geometry plus varied linear algebra operations.

## How It Works

1. A `MultiMeshInstance3D` is created with `cube_count` instances of a small `BoxMesh`.
2. Each instance receives a random position inside a sphere of radius `spread_radius` and a random rotation axis stored in a parallel array.
3. A grid shader material (`SimpleGrid.gdshader`) gives every cube a wireframe + emission look, falling back to a standard emissive material if the shader cannot be loaded.
4. Every frame in `_process`, each instance's transform is rotated locally around its stored axis, scaled by a very subtle sine oscillation, and written back to the `MultiMesh`.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cube_count` | int | `500` | Total number of cubes |
| `spread_radius` | float | `10.0` | Radius of the placement sphere |
| `animation_speed` | float | `0.5` | Global rotation speed multiplier |

## Features

- Efficient MultiMesh rendering for hundreds of cubes in a single draw call.
- Per-instance random rotation axes for organic, non-uniform motion.
- Grid shader wireframe material with green wireframe lines and magenta emission.
- Subtle per-frame scale oscillation for a breathing effect.
- Dark background environment with directional lighting for visual contrast.

## Files

- `rotatescalecubes.gd` -- Main script: MultiMesh setup, shader material creation, per-frame animation.
- `rotatescalecubes.tscn` -- Scene file.
