# Marching Cave — Scripts

GDScript implementations for the marching cubes isosurface system, including terrain generators, VR sculpting, and gallery modes.

## Core API

- `MarchingCubesAPI.gd` — Core marching cubes algorithm: voxel field evaluation, edge interpolation, and triangle table mesh generation.

## Terrain Generators

All extend a common base for pluggable terrain shapes:

- `TerrainGeneratorBase.gd` — Abstract base class for terrain generation.
- `TerrainGenerator.gd` — Default noise-based terrain.
- `TerrainGeneratorFlat.gd` — Flat ground plane.
- `TerrainGeneratorFountain.gd` — Fountain-shaped terrain with radial falloff.
- `TerrainGeneratorGyroid.gd` — Gyroid minimal surface (triply periodic).
- `TerrainGeneratorOverhang.gd` — Terrain with overhanging cliff geometry.
- `TerrainGeneratorPortals.gd` — Portal-shaped cavities.
- `TerrainGeneratorUnifiedPortals.gd` — Unified portal variant.
- `TerrainGeneratorSculpt.gd` — User-sculptable terrain for VR interaction.
- `TerrainGeneratorShapes.gd` — Primitive shape gallery (sphere, torus, etc.).
- `TerrainGeneratorTorus.gd` — Torus-shaped isosurface.

## Demo Controllers

- `AnimatedNoiseExplorer.gd` — Animated noise field walkthrough.
- `MarchingCubesSculptVR.gd` — VR hand-sculpting controller.
- `MarchingShapesGallery.gd` — Gallery displaying multiple isosurface shapes.

## Subdirectory

- `Utils/` — Utility scripts (texture generation).

See the parent [Marching Cave README](../README.md) for the full isosurface pipeline.
