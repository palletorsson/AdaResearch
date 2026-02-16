## Sequence Contract Audit

Checks explicit `maps[]` ownership only; map-name similarities are informational hints and never auto-assigned.

| Metric | Count |
|---|---:|
| `total_sequences` | 46 |
| `declared_entries` | 434 |
| `declared_unique_maps` | 434 |
| `map_folders_with_data` | 528 |
| `duplicate_entries_within_sequence` | 0 |
| `duplicates_across_sequences` | 0 |
| `missing_declared_maps` | 0 |
| `undeclared_map_folders` | 94 |
| `undeclared_prefix_hints` | 60 |
| `cross_sequence_prefix_hints` | 36 |

### Interpretation Notes

- `missing_declared_maps`: blocker. Sequence points to maps that do not exist on disk.
- `duplicate_entries_within_sequence`: blocker. Same map repeats in one sequence `maps[]`.
- `duplicates_across_sequences`: review case-by-case. Some shared maps are intentional.
- `undeclared_map_folders`: inventory queue. Maps exist but are not in any sequence.
- `*_prefix_hints`: informational only. Name similarity never assigns sequence ownership.

### undeclared_map_folders

- `Lab` has `map_data.json` but is not in any sequence `maps[]`
- `Oscillation_Animated_Cube` has `map_data.json` but is not in any sequence `maps[]`
- `Physics_1` has `map_data.json` but is not in any sequence `maps[]`
- `Physics_2` has `map_data.json` but is not in any sequence `maps[]`
- `Physics_3` has `map_data.json` but is not in any sequence `maps[]`
- `Physics_4` has `map_data.json` but is not in any sequence `maps[]`
- `Physics_5` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Context` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Line` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Line_Context` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Tests` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Zero` has `map_data.json` but is not in any sequence `maps[]`
- `Point_Zero_` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_4` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Godot` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Irregular` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Load` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Platonic` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Torus` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Tron_Grid_Navigation` has `map_data.json` but is not in any sequence `maps[]`
- `Primitives_Useful` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationCaveExplorer3dUi` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationCrystalRandom` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingcubesFlatLandscape` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingCubesInsideCave` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingcubesPortalLandscape` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingCubesSculpture` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingcubesTorusSculpture` has `map_data.json` but is not in any sequence `maps[]`
- `ProceduralGenerationMarchingCubesVovelNoise` has `map_data.json` but is not in any sequence `maps[]`
- `Random_0` has `map_data.json` but is not in any sequence `maps[]`

### undeclared_prefix_hints (info only)

- `Primitives_4` looks related to `primitives`(8)
- `Primitives_Godot` looks related to `primitives`(8)
- `Primitives_Irregular` looks related to `primitives`(8)
- `Primitives_Load` looks related to `primitives`(8)
- `Primitives_Platonic` looks related to `primitives`(8)
- `Primitives_Torus` looks related to `primitives`(8)
- `Primitives_Tron_Grid_Navigation` looks related to `primitives`(8)
- `Primitives_Useful` looks related to `primitives`(8)
- `ProceduralGenerationCaveExplorer3dUi` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationCrystalRandom` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingcubesFlatLandscape` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingCubesInsideCave` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingcubesPortalLandscape` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingCubesSculpture` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingcubesTorusSculpture` looks related to `proceduralgeneration`(8)
- `ProceduralGenerationMarchingCubesVovelNoise` looks related to `noise`(8), `proceduralgeneration`(8)
- `Randomness_Random_Transformations` looks related to `randomness`(8), `transformation`(8)
- `SoftBodies_Obsticals_Part1` looks related to `softbodies`(8)
- `TestMap_Unused_1` looks related to `unused`(8)
- `TestMap_Unused_10` looks related to `unused`(8)
- `TestMap_Unused_11` looks related to `unused`(8)
- `TestMap_Unused_12` looks related to `unused`(8)
- `TestMap_Unused_13` looks related to `unused`(8)
- `TestMap_Unused_14` looks related to `unused`(8)
- `TestMap_Unused_15` looks related to `unused`(8)
- `TestMap_Unused_16` looks related to `unused`(8)
- `TestMap_Unused_17` looks related to `unused`(8)
- `TestMap_Unused_18` looks related to `unused`(8)
- `TestMap_Unused_19` looks related to `unused`(8)
- `TestMap_Unused_2` looks related to `unused`(8)

### cross_sequence_prefix_hints (info only)

- `DataStructures_Union_Find_Disjoint_Set` owned by `datastructures`; also name-matches `joints`(8)
- `Pattern_Generation_Four` owned by `unused`; also name-matches `patterngeneration`(8)
- `Pattern_Generation_One` owned by `unused`; also name-matches `patterngeneration`(8)
- `Pattern_Generation_Seven` owned by `unused`; also name-matches `patterngeneration`(8)
- `Pattern_Generation_Six` owned by `unused`; also name-matches `patterngeneration`(8)
- `Pattern_Generation_Three` owned by `unused`; also name-matches `patterngeneration`(8)
- `Pattern_Generation_Two` owned by `unused`; also name-matches `patterngeneration`(8)
- `PhysicsSimulation_Particle_Systems` owned by `physicssimulation`; also name-matches `particles`(8)
- `Primitives_2` owned by `unused`; also name-matches `primitives`(8)
- `ProceduralGenerationBooleanPatterns` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationNetSpace` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationPortals` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationSixteenCellNet` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationTesseractErrorTunnel` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationWfcDungeonGenerator` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Delaunay_Triangulation` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_MarchingCave` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_MarchingGallery` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Marching_Cubes_Algorithm` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Markov_Chains` owned by `grammar_systems`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_N_grams` owned by `grammar_systems`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Poisson_Disk_Sampling` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Reaction_Diffusion_Systems` owned by `morphogenesis`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Space_Partitioning` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Voronoi_Diagrams` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Wave_Function_Collapse` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `RecursiveEmergence_Cellular_Automata_1D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `RecursiveEmergence_Cellular_Automata_2D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `RecursiveEmergence_Cellular_Automata_3D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `SearchPathfinding_Particle_Swarm_Optimization` owned by `searchpathfinding`; also name-matches `particles`(8)
