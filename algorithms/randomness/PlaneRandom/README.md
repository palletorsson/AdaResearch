# Plane Random

A dynamic terrain generator that creates a flat 20x20 quad grid and progressively deforms it by randomly lifting individual vertices up or down. The terrain updates continuously, producing an evolving landscape with smooth physics collision via HeightMapShape3D.

## Concept Taught

**Random perturbation and emergent terrain.** This artifact teaches how complex, organic-looking landscapes can emerge from the simplest possible random process: repeatedly picking a single vertex and nudging it up or down by a small amount. There is no Perlin noise, no fractal subdivision, no erosion simulation -- just pure uniform randomness applied one vertex at a time. Over hundreds of iterations, the accumulated perturbations produce rolling hills and valleys that look surprisingly natural. Students learn that randomness, applied incrementally, can build structure from nothing.

## How It Works

1. A flat quad grid is built with `(quads_x + 1) * (quads_z + 1)` vertices, centered at the origin.
2. UV coordinates are assigned for texturing. Triangle indices connect adjacent vertices into a mesh.
3. On ready, if `do_lift_on_ready` is true, the system runs `initial_rounds` (default 100) of random vertex lifting before the first frame renders.
4. Each lift picks a random vertex index and adjusts its Y position by a random value in the range `[-lift_range, +lift_range]`.
5. After the initial burst, a timer fires every `update_interval` seconds, lifting one more vertex per tick.
6. After each modification, the mesh is rebuilt using SurfaceTool (which auto-generates normals for smooth lighting) and the HeightMapShape3D collision is updated from the vertex height data.
7. A SimpleGrid shader is applied for visual style.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `quads_x` | int | 20 | Number of quads along the X axis |
| `quads_z` | int | 20 | Number of quads along the Z axis |
| `cell_size` | float | 1.0 | World-space size of each quad |
| `lift_range` | float | 0.5 | Maximum vertex displacement per lift (plus/minus) |
| `do_lift_on_ready` | bool | true | Run initial rounds of lifting at startup |
| `initial_rounds` | int | 100 | Number of random lifts applied before first frame |
| `update_interval` | float | 1.0 | Seconds between continuous vertex lifts |

## Features

- Procedural terrain from pure random vertex displacement
- HeightMapShape3D collision for walkable, physics-accurate terrain
- SurfaceTool auto-generates smooth normals after each mesh update
- Initial burst of deformation for immediate visual interest
- Continuous per-second updates create a living, shifting landscape
- SimpleGrid shader for clean visual presentation
- Centered grid origin for easy placement in scenes

## Files

| File | Purpose |
|------|---------|
| `plane_random.gd` | Grid construction, random vertex lifting, mesh rebuilding, and HeightMapShape3D collision updates |
