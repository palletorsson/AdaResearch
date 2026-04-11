# Plane Effects

A random-walk terrain deformation system where one or more "walkers" wander across a subdivided plane, raising the terrain height at each step. Over time, the walkers carve out mountain-like ridges and peaks from a flat surface, demonstrating how a random walk accumulates into structured topography.

This artifact teaches **random walk accumulation** -- each step is a random direction choice (`randi_range(-1, 1)` on both axes), but over many steps the walker traces out paths and builds terrain features. A border zone is preserved around the edges to maintain a flat walkable perimeter, contrasting the chaotic interior with ordered edges.

## How It Works

1. **Grid Initialization**: A vertex grid is built from the plane's dimensions and segment counts. Each vertex starts at `y = 0`. An indexed triangle list is generated for efficient mesh rebuilding.

2. **Walker Movement**: Each frame, every walker takes a random step of -1, 0, or +1 on both the X and Y grid axes. Walkers are clamped to stay within the interior region (outside the `border_size` margin). The walker raises the terrain height at its current position by `raise_amount`.

3. **Border Preservation**: Vertices within `border_size` segments of any edge are never modified, maintaining a flat border that could serve as a walkable area in the game grid.

4. **Mesh Rebuilding**: Each frame, the entire vertex grid is flattened into a `PackedVector3Array` and rebuilt using `SurfaceTool` with `generate_normals()` to ensure correct lighting as the terrain deforms. The mesh is committed back to the same `ArrayMesh`.

5. **Deferred Initialization**: The script waits for the plane's `MeshInstance3D` child to exist before initializing. It reads segment and size properties from the plane node, falling back to AABB inference if not available.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `border_size` | int | 20 | Width of the unmodified border zone (in grid segments) |
| `raise_amount` | float | 0.1 | Height increase per walker step |

## Features

- Random walk terrain generation with per-frame vertex modification
- Border preservation -- flat edges maintained for walkable grid areas
- Dynamic normal recalculation via SurfaceTool for correct lighting
- Indexed mesh geometry for efficient triangle construction
- Deferred initialization with frame-waiting for scene readiness
- Support for multiple simultaneous walkers
- Adaptable to any plane mesh with configurable segments and dimensions

## Files

| File | Description |
|------|-------------|
| `plane_manipulator.gd` | Main script -- walker logic, vertex grid, mesh rebuilding |
| `plane_manipulator.tscn` | Scene file with plane reference |
