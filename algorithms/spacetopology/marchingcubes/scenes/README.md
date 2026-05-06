# Marching Cubes — Scenes

Demo scenes and controllers for the marching cubes isosurface system.

## Contents

### Demo Scenes

- `fifteen_cases_demo.tscn` — Displays the 15 unique marching cubes cases (from 256 by symmetry).
- `marching_cubes_test.tscn` — Test scene for the core algorithm.
- `marching_cubes_terrain_demo.tscn` — Full terrain generation demo.
- `rhizome_cave_demo.tscn` — Rhizome-inspired cave structure (see `RHIZOME_CAVE_SIMPLIFIED.md` for design notes).

### Controllers

- `FifteenCasesController.gd` — Drives the 15-cases visualization.
- `MarchingCubesTestController.gd` — Test controller for algorithm validation.
- `TerrainDemoController.gd` — Controls terrain generation parameters.
- `RhizomeCaveDemoController.gd` — Controls the rhizome cave demo.

### Resources

- `terrain_environment.tres` — Environment resource (lighting, sky) for terrain demos.
- `RHIZOME_CAVE_SIMPLIFIED.md` — Design notes for the rhizome cave concept.

See the parent [Marching Cubes README](../README.md) for the full system architecture.
