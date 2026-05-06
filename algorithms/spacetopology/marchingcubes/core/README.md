# Marching Cubes — Core

Core implementation of the marching cubes isosurface extraction algorithm.

## Contents

- `MarchingCubesGenerator.gd` — Main generator: evaluates the scalar field on a voxel grid, determines cube configurations, and emits triangulated mesh geometry.
- `MarchingCubesLookupTables.gd` — The 256-entry edge and triangle lookup tables defining which edges are intersected for each cube configuration.
- `TerrainGenerator.gd` — Scalar field definition: provides density values at grid points for the marching cubes algorithm to polygonize.
- `VoxelChunk.gd` — Chunk-based voxel storage for spatially partitioned isosurface generation.

See the parent [Marching Cubes README](../README.md) for the full system architecture.
